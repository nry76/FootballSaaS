-- =====================================================================
-- 09_helpers.sql — functions used by RLS policies and triggers (schema private)
--
-- All are SECURITY DEFINER with an empty search_path (every reference is
-- schema-qualified) so they read the tables they need without depending on
-- the caller's own RLS, and cannot be hijacked via search_path.
-- Policies call them as `(select private.fn())` where possible so Postgres
-- evaluates them once per statement, not once per row.
-- =====================================================================

create function private.today() returns date
language sql stable as $$ select (now() at time zone 'Asia/Dubai')::date $$;

create function private.age_on(dob date, on_date date default private.today()) returns integer
language sql stable as $$ select extract(year from age(on_date::timestamp, dob::timestamp))::int $$;

create function private.is_platform_staff() returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (select 1 from public.platform_staff where user_id = (select auth.uid()))
$$;

create function private.is_platform_owner() returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (select 1 from public.platform_staff
                 where user_id = (select auth.uid()) and platform_role = 'owner')
$$;

-- The caller's tenant. Non-approved profiles resolve to NULL => they see nothing.
-- Platform support resolves to a club ONLY while a club-approved, unexpired grant exists.
create function private.current_club_id() returns uuid
language sql stable security definer set search_path = '' as $$
  select coalesce(
    (select p.club_id from public.profiles p
      where p.id = (select auth.uid()) and p.approval_status = 'approved'),
    (select g.club_id from public.support_access_grants g
      where g.platform_user_id = (select auth.uid())
        and g.revoked_at is null and g.expires_at > now()
      order by g.created_at desc limit 1)
  )
$$;

create function private.has_role(r public.role_key) returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from public.profile_roles pr
    join public.profiles p on p.id = pr.profile_id and p.approval_status = 'approved'
    where pr.profile_id = (select auth.uid()) and pr.role = r)
$$;

-- Permission check for club staff. Support staff under a grant get READ-ONLY
-- compliance / fees / analytics and nothing else (no players, medical, HR, messages).
create function private.has_permission(perm text) returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (
      select 1 from public.profile_roles pr
      join public.profiles p on p.id = pr.profile_id and p.approval_status = 'approved'
      join public.role_permissions rp on rp.role = pr.role
      where pr.profile_id = (select auth.uid()) and rp.permission = perm)
    or (perm in ('compliance.read','fees.read','analytics.read')
        and exists (select 1 from public.support_access_grants g
                    where g.platform_user_id = (select auth.uid())
                      and g.revoked_at is null and g.expires_at > now()))
$$;

create function private.is_squad_staff(p_squad uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (select 1 from public.squad_staff ss
                 where ss.squad_id = p_squad and ss.profile_id = (select auth.uid())
                   and ss.club_id = private.current_club_id())
$$;

create function private.is_coach_of_player(p_player uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from public.squad_staff ss
    join public.squad_memberships sm on sm.squad_id = ss.squad_id and sm.left_on is null
    where ss.profile_id = (select auth.uid()) and sm.player_id = p_player
      and ss.club_id = private.current_club_id())
$$;

create function private.is_guardian_of(p_player uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (select 1 from public.player_guardians g
                 where g.player_id = p_player and g.profile_id = (select auth.uid())
                   and g.club_id = private.current_club_id())
$$;

create function private.is_self_player(p_player uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (select 1 from public.players p
                 where p.id = p_player and p.profile_id = (select auth.uid())
                   and p.club_id = private.current_club_id())
$$;

-- Has the guardian granted this consent type (and not revoked it)?
create function private.has_consent(p_player uuid, p_type public.consent_type) returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (select 1 from public.parental_consents c
                 where c.player_id = p_player and c.type = p_type
                   and c.status = 'granted' and c.revoked_at is null)
$$;

-- THE child-safety gate. True when the player is an adult, or a minor with a
-- granted, unrevoked 'data_processing' consent. Erased players never qualify.
create function private.is_processing_allowed(p_player uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from public.players p
    where p.id = p_player and p.status <> 'erased'
      and (private.age_on(p.date_of_birth) >= 18
           or private.has_consent(p.id, 'data_processing')))
$$;

-- Who may read a player's data at all: manager/admin (players.read), the
-- player's own coaches, the player (13+), or a linked guardian.
create function private.can_read_player(p_player uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from public.players p
    where p.id = p_player and p.club_id = private.current_club_id() and p.status <> 'erased')
  and (private.has_permission('players.read')
       or private.is_coach_of_player(p_player)
       or private.is_self_player(p_player)
       or private.is_guardian_of(p_player))
$$;

-- Reserved-number test used by triggers and the availability function.
create function private.jersey_blocked(
  p_club uuid, p_season uuid, p_squads uuid[], p_number smallint, p_position public.position_group
) returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from public.jersey_reservations r
    where r.club_id = p_club
      and p_number between r.number_from and r.number_to
      and (r.season_id is null or r.season_id = p_season)
      and (r.squad_id  is null or r.squad_id = any (p_squads))
      and (r.only_position_group is null or r.only_position_group is distinct from p_position))
$$;

-- Numbers 1..99 free in EVERY squad the player is in (this season) plus any
-- squads they are about to join, minus club reservations. This is what powers
-- "show numbers available across BOTH squads at once".
create function private.available_numbers(p_player uuid, p_season uuid, p_targets uuid[] default '{}')
returns setof smallint
language plpgsql stable security definer set search_path = '' as $$
declare
  v_club   uuid;
  v_pos    public.position_group;
  v_squads uuid[];
begin
  select club_id, position_group into v_club, v_pos from public.players where id = p_player;
  if v_club is null then raise exception 'unknown player'; end if;

  select coalesce(array_agg(distinct s.sid), '{}') into v_squads from (
    select squad_id as sid from public.squad_memberships
      where player_id = p_player and season_id = p_season and left_on is null
    union
    select id from public.squads
      where id = any (p_targets) and club_id = v_club and season_id = p_season
  ) s;

  return query
    select g::smallint from generate_series(1, 99) g
    where not exists (
            select 1 from public.squad_memberships m
            where m.squad_id = any (v_squads) and m.jersey_number = g
              and m.left_on is null and m.player_id <> p_player)
      and not private.jersey_blocked(v_club, p_season, v_squads, g::smallint, v_pos)
    order by g;
end $$;

-- Keeps players.status in step with consent + identity verification.
--   minor without granted consent -> pending_consent
--   else no approved ID check     -> pending_verification
--   else                          -> active
create function private.recompute_player_status(p_player uuid) returns void
language plpgsql security definer set search_path = '' as $$
declare
  p          public.players%rowtype;
  v_new      public.player_status;
begin
  select * into p from public.players where id = p_player;
  if not found or p.status in ('inactive','archived','erased') then return; end if;

  v_new := case
    when private.age_on(p.date_of_birth) < 18 and not private.has_consent(p_player, 'data_processing')
      then 'pending_consent'
    when not exists (select 1 from public.identity_verifications v
                     where v.player_id = p_player and v.status = 'approved')
      then 'pending_verification'
    else 'active' end;

  if v_new <> p.status then
    update public.players set status = v_new where id = p_player;
  end if;
end $$;

create function private.in_conversation(p_conv uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (select 1 from public.conversation_participants cp
                 where cp.conversation_id = p_conv and cp.profile_id = (select auth.uid()))
$$;

-- Manager/admin (schedule.write) or a staff member assigned to this squad.
create function private.can_manage_squad(p_squad uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (select 1 from public.squads s
                 where s.id = p_squad and s.club_id = private.current_club_id())
     and (private.has_permission('schedule.write') or private.is_squad_staff(p_squad))
$$;

create function private.is_medical_staff_of(p_player uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from public.squad_staff ss
    join public.squad_memberships sm on sm.squad_id = ss.squad_id and sm.left_on is null
    where ss.profile_id = (select auth.uid()) and ss.role = 'medical'
      and sm.player_id = p_player and ss.club_id = private.current_club_id())
$$;

create function private.is_self_adult(p_player uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (select 1 from public.players p
                 where p.id = p_player and p.profile_id = (select auth.uid())
                   and p.club_id = private.current_club_id()
                   and private.age_on(p.date_of_birth) >= 18)
$$;

-- Who may see another account's name/contact: self; manager/admin; people who
-- share a squad relationship (coach <-> that squad's families); people in the same conversation.
create function private.can_see_profile(p_target uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  select p_target = (select auth.uid())
      or exists (select 1 from public.profiles t
                 where t.id = p_target and t.club_id = private.current_club_id()
                   and (private.has_permission('members.read')
                     -- viewer is staff of a squad that target's child / target plays in
                     or exists (select 1 from public.squad_staff me
                                join public.squad_memberships sm on sm.squad_id = me.squad_id and sm.left_on is null
                                left join public.player_guardians g on g.player_id = sm.player_id
                                left join public.players pl on pl.id = sm.player_id
                                where me.profile_id = (select auth.uid())
                                  and (g.profile_id = p_target or pl.profile_id = p_target))
                     -- viewer is a family member of a squad that target staffs
                     or exists (select 1 from public.squad_staff st
                                join public.squad_memberships sm on sm.squad_id = st.squad_id and sm.left_on is null
                                where st.profile_id = p_target
                                  and (private.is_guardian_of(sm.player_id) or private.is_self_player(sm.player_id)))
                     or exists (select 1 from public.conversation_participants a
                                join public.conversation_participants b on b.conversation_id = a.conversation_id
                                where a.profile_id = (select auth.uid()) and b.profile_id = p_target)))
$$;

revoke all on all functions in schema private from public, anon;
grant usage on schema private to authenticated, service_role;
grant execute on all functions in schema private to authenticated, service_role;
