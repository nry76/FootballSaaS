-- =====================================================================
-- 10_triggers.sql — rules that must hold no matter which client writes
-- (all SECURITY DEFINER, empty search_path)
-- =====================================================================

-- ---- players: age tiers, login rule, initial status --------------------
create function private.trg_player_rules() returns trigger
language plpgsql security definer set search_path = '' as $$
declare v_age int := private.age_on(NEW.date_of_birth);
begin
  if TG_OP = 'INSERT' and NEW.status = 'pending_consent' and v_age >= 18 then
    NEW.status := 'pending_verification';                 -- adults need no guardian consent
  end if;
  if NEW.profile_id is not null and NEW.status <> 'erased' then
    if v_age < 13 then
      raise exception 'players under 13 cannot have their own login (guardian acts for the child)'
        using errcode = 'check_violation';
    end if;
    if v_age < 18 and not private.has_consent(NEW.id, 'data_processing') then
      raise exception 'a 13-17 player login requires granted parental consent first'
        using errcode = 'check_violation';
    end if;
  end if;
  return NEW;
end $$;
create trigger player_rules before insert or update on players
  for each row execute function private.trg_player_rules();

-- ---- consent: direct-to-guardian email, one-way state machine -----------
create function private.trg_consent_guard() returns trigger
language plpgsql security definer set search_path = '' as $$
declare g public.player_guardians%rowtype;
begin
  if TG_OP = 'INSERT' then
    select * into g from public.player_guardians
      where id = NEW.guardian_id and club_id = NEW.club_id;
    if not found or g.player_id <> NEW.player_id then
      raise exception 'guardian does not belong to this player';
    end if;
    if not g.can_consent then raise exception 'this guardian is not authorised to consent'; end if;
    if exists (select 1 from public.players p join public.profiles pr on pr.id = p.profile_id
               where p.id = NEW.player_id and pr.email = g.email) then
      raise exception 'guardian email must differ from the player''s own login email';
    end if;
    NEW.sent_to_email := g.email;                           -- always the guardian's address on file
    NEW.status := 'pending';
    NEW.responded_at := null; NEW.revoked_at := null;
  else
    if NEW.player_id <> OLD.player_id or NEW.guardian_id <> OLD.guardian_id
       or NEW.token_hash <> OLD.token_hash or NEW.sent_to_email <> OLD.sent_to_email
       or NEW.type <> OLD.type then
      raise exception 'consent identity fields are immutable';
    end if;
    if NEW.status <> OLD.status and not (
         (OLD.status = 'pending' and NEW.status in ('granted','declined','expired'))
      or (OLD.status = 'granted' and NEW.status = 'revoked')) then
      raise exception 'invalid consent transition % -> %', OLD.status, NEW.status;
    end if;
  end if;
  return NEW;
end $$;
create trigger consent_guard before insert or update on parental_consents
  for each row execute function private.trg_consent_guard();

create function private.trg_consent_effects() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  perform private.recompute_player_status(NEW.player_id);
  if NEW.type = 'media' and NEW.status = 'revoked' then
    delete from public.media_player_tags where player_id = NEW.player_id;   -- un-tag on revocation
  end if;
  return NEW;
end $$;
create trigger consent_effects after insert or update on parental_consents
  for each row execute function private.trg_consent_effects();

-- ---- identity verification ---------------------------------------------
create function private.trg_identity_guard() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  if TG_OP = 'UPDATE' and NEW.status <> OLD.status and NEW.status in ('approved','rejected') then
    if NEW.reviewed_by is null then raise exception 'reviewed_by required'; end if;
    if NEW.reviewed_by = NEW.profile_id then raise exception 'cannot review your own verification'; end if;
    NEW.reviewed_at := now();
    NEW.purge_after := now() + interval '30 days';           -- images deleted by a scheduled job
  end if;
  return NEW;
end $$;
create trigger identity_guard before insert or update on identity_verifications
  for each row execute function private.trg_identity_guard();

create function private.trg_identity_effects() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  if NEW.player_id is not null then perform private.recompute_player_status(NEW.player_id); end if;
  return NEW;
end $$;
create trigger identity_effects after insert or update on identity_verifications
  for each row execute function private.trg_identity_effects();

-- ---- profiles: staff cannot be approved without a passed ID check --------
create function private.trg_profile_approval() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  if NEW.approval_status = 'approved' and OLD.approval_status is distinct from 'approved' then
    if (select auth.uid()) = NEW.id then raise exception 'cannot approve your own account'; end if;
    if exists (select 1 from public.profile_roles where profile_id = NEW.id and role in ('admin','coach'))
       and not exists (select 1 from public.identity_verifications v
                       where v.profile_id = NEW.id and v.kind = 'staff' and v.status = 'approved') then
      raise exception 'staff accounts need an approved photo + ID verification before approval';
    end if;
    NEW.approved_at := now();
    NEW.approved_by := coalesce(NEW.approved_by, (select auth.uid()));
  end if;
  return NEW;
end $$;
create trigger profile_approval before update of approval_status on profiles
  for each row execute function private.trg_profile_approval();

create function private.trg_role_guard() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  if NEW.role in ('admin','coach')
     and exists (select 1 from public.profiles where id = NEW.profile_id and approval_status = 'approved')
     and not exists (select 1 from public.identity_verifications v
                     where v.profile_id = NEW.profile_id and v.kind = 'staff' and v.status = 'approved') then
    raise exception 'staff roles need an approved photo + ID verification first';
  end if;
  return NEW;
end $$;
create trigger role_guard before insert on profile_roles
  for each row execute function private.trg_role_guard();

-- ---- squad membership: age band, jersey rules ---------------------------
create function private.trg_membership_rules() returns trigger
language plpgsql security definer set search_path = '' as $$
declare
  v_dob   date; v_pos public.position_group;
  v_from  int;  v_to  int; v_birth int;
  v_canon smallint;
begin
  select date_of_birth, position_group into v_dob, v_pos from public.players where id = NEW.player_id;
  select birth_year_from, birth_year_to into v_from, v_to from public.squads where id = NEW.squad_id;
  v_birth := extract(year from v_dob);

  -- playing up = younger than the squad's band; playing down = older
  NEW.membership_type := case
    when v_birth between v_from and v_to then 'primary'
    when v_birth > v_to   then 'playing_up'
    else                       'playing_down' end;

  select number into v_canon from public.player_jersey_numbers
    where player_id = NEW.player_id and season_id = NEW.season_id;

  -- default to the player's own number when it is free in this squad
  if TG_OP = 'INSERT' and NEW.jersey_number is null and v_canon is not null
     and not exists (select 1 from public.squad_memberships m
                     where m.squad_id = NEW.squad_id and m.jersey_number = v_canon and m.left_on is null)
     and not private.jersey_blocked(NEW.club_id, NEW.season_id, array[NEW.squad_id], v_canon, v_pos) then
    NEW.jersey_number := v_canon;
  end if;

  if NEW.jersey_number is not null and NEW.left_on is null then
    if private.jersey_blocked(NEW.club_id, NEW.season_id, array[NEW.squad_id], NEW.jersey_number, v_pos) then
      raise exception 'number % is reserved for this squad/position', NEW.jersey_number;
    end if;
    if v_canon is not null and NEW.jersey_number <> v_canon
       and coalesce(NEW.kit_exception_reason, '') = '' then
      raise exception 'player already owns number % this season; use it, or give kit_exception_reason (a second kit will be needed)', v_canon;
    end if;
  end if;
  return NEW;
end $$;
create trigger membership_rules before insert or update on squad_memberships
  for each row execute function private.trg_membership_rules();

-- A number given at squad level becomes the player's own number if they had none.
create function private.trg_membership_claim() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  if NEW.jersey_number is not null and NEW.left_on is null then
    insert into public.player_jersey_numbers (club_id, player_id, season_id, number, chosen_by)
    values (NEW.club_id, NEW.player_id, NEW.season_id, NEW.jersey_number, (select auth.uid()))
    on conflict (player_id, season_id) do nothing;
  end if;
  return NEW;
end $$;
create trigger membership_claim after insert or update of jersey_number on squad_memberships
  for each row execute function private.trg_membership_claim();

create function private.trg_player_jersey_rules() returns trigger
language plpgsql security definer set search_path = '' as $$
declare v_squads uuid[]; v_pos public.position_group;
begin
  select position_group into v_pos from public.players where id = NEW.player_id;
  select coalesce(array_agg(squad_id), '{}') into v_squads from public.squad_memberships
    where player_id = NEW.player_id and season_id = NEW.season_id and left_on is null;

  if private.jersey_blocked(NEW.club_id, NEW.season_id, v_squads, NEW.number, v_pos) then
    raise exception 'number % is reserved', NEW.number;
  end if;
  if exists (select 1 from public.squad_memberships m
             where m.squad_id = any (v_squads) and m.jersey_number = NEW.number
               and m.left_on is null and m.player_id <> NEW.player_id) then
    raise exception 'number % is already worn by another player in one of this player''s squads', NEW.number;
  end if;
  if TG_OP = 'UPDATE' and OLD.locked and NEW.number <> OLD.number
     and not private.has_permission('jerseys.manage') then
    raise exception 'number is locked (kit ordered)';
  end if;
  return NEW;
end $$;
create trigger player_jersey_rules before insert or update of number on player_jersey_numbers
  for each row execute function private.trg_player_jersey_rules();

-- ---- events: seed RSVP rows for squad members ---------------------------
create function private.trg_event_seed() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  insert into public.event_participants (event_id, player_id, club_id)
  select NEW.id, sm.player_id, NEW.club_id
  from public.squad_memberships sm
  where sm.squad_id = NEW.squad_id and sm.left_on is null
    and private.is_processing_allowed(sm.player_id)
  on conflict do nothing;
  return NEW;
end $$;
create trigger event_seed after insert on events
  for each row execute function private.trg_event_seed();

create function private.trg_membership_events() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  if NEW.left_on is null and private.is_processing_allowed(NEW.player_id) then
    insert into public.event_participants (event_id, player_id, club_id)
    select e.id, NEW.player_id, NEW.club_id from public.events e
    where e.squad_id = NEW.squad_id and e.status = 'scheduled' and e.starts_at > now()
    on conflict do nothing;
  end if;
  return NEW;
end $$;
create trigger membership_events after insert on squad_memberships
  for each row execute function private.trg_membership_events();

-- ---- drills: a club may only assign its own or platform drills -----------
create function private.trg_drill_scope() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  if not exists (select 1 from public.drills d
                 where d.id = NEW.drill_id and (d.club_id is null or d.club_id = NEW.club_id)) then
    raise exception 'drill belongs to another club';
  end if;
  return NEW;
end $$;
create trigger drill_scope before insert or update of drill_id on drill_assignments
  for each row execute function private.trg_drill_scope();

-- ---- messaging safety ---------------------------------------------------
create function private.trg_message_rules() returns trigger
language plpgsql security definer set search_path = '' as $$
declare
  c        public.conversations%rowtype;
  v_dob    date; v_profile uuid;
begin
  select * into c from public.conversations where id = NEW.conversation_id and club_id = NEW.club_id;
  if not found then raise exception 'unknown conversation'; end if;
  if c.locked_at is not null then raise exception 'conversation is locked'; end if;
  if not exists (select 1 from public.conversation_participants cp
                 where cp.conversation_id = c.id and cp.profile_id = NEW.sender_id) then
    raise exception 'sender is not a participant';
  end if;

  if c.kind = 'squad_announcement' and not exists (
       select 1 from public.squad_staff ss where ss.squad_id = c.squad_id and ss.profile_id = NEW.sender_id) then
    raise exception 'only squad staff can post announcements';
  end if;

  if c.player_id is not null then
    if not private.is_processing_allowed(c.player_id) then
      raise exception 'no verified parental consent on file for this player';
    end if;
    select date_of_birth, profile_id into v_dob, v_profile from public.players where id = c.player_id;

    if c.kind = 'coach_player' then
      if v_profile is null then raise exception 'this player has no login; message the guardian instead'; end if;
      if private.age_on(v_dob) < 18 then
        if not private.has_consent(c.player_id, 'messaging') then
          raise exception 'messaging consent required before contacting a minor';
        end if;
        if not exists (select 1 from public.conversation_participants cp
                       join public.player_guardians g on g.profile_id = cp.profile_id and g.player_id = c.player_id
                       where cp.conversation_id = c.id and cp.is_observer) then
          raise exception 'a guardian must be an observer on every coach<->minor conversation';
        end if;
      end if;
    end if;
  end if;
  return NEW;
end $$;
create trigger message_rules before insert on messages
  for each row execute function private.trg_message_rules();

-- ---- media: no tagging of a minor without media consent ------------------
create function private.trg_media_tag_rules() returns trigger
language plpgsql security definer set search_path = '' as $$
declare v_dob date;
begin
  select date_of_birth into v_dob from public.players where id = NEW.player_id;
  if private.age_on(v_dob) < 18 and not private.has_consent(NEW.player_id, 'media') then
    raise exception 'no media consent for this minor';
  end if;
  return NEW;
end $$;
create trigger media_tag_rules before insert on media_player_tags
  for each row execute function private.trg_media_tag_rules();

-- ---- payments: keep the charge in step with its payments -----------------
create function private.trg_payment_apply() returns trigger
language plpgsql security definer set search_path = '' as $$
declare
  ch  public.player_charges%rowtype;
  v_net bigint;
begin
  select * into ch from public.player_charges where id = NEW.charge_id and club_id = NEW.club_id for update;
  if ch.status in ('waived','void') then return NEW; end if;

  select coalesce(sum(case when refund_of is null then amount_fils else -amount_fils end), 0)
    into v_net
    from public.payments
   where charge_id = NEW.charge_id and club_id = NEW.club_id and status = 'succeeded';

  update public.player_charges set
    amount_paid_fils = greatest(v_net, 0),
    status = case when v_net >= amount_fils + vat_fils then 'paid'
                  when v_net > 0                      then 'part_paid'
                  else 'due' end
  where id = NEW.charge_id;
  return NEW;
end $$;
create trigger payment_apply after insert or update of status on payments
  for each row execute function private.trg_payment_apply();

-- ---- audit (ids + field NAMES only, never values) ------------------------
create function private.trg_audit() returns trigger
language plpgsql security definer set search_path = '' as $$
declare
  v_new jsonb := case when TG_OP <> 'DELETE' then to_jsonb(NEW) end;
  v_old jsonb := case when TG_OP <> 'INSERT' then to_jsonb(OLD) end;
  v_row jsonb := coalesce(v_new, v_old);
  v_changed jsonb := '[]';
begin
  if TG_OP = 'UPDATE' then
    select coalesce(jsonb_agg(n.key), '[]') into v_changed
    from jsonb_each(v_new) n where n.value is distinct from v_old -> n.key;
  end if;
  insert into public.audit_log (club_id, actor_id, actor_kind, action, entity, entity_id, meta)
  values ((v_row ->> 'club_id')::uuid,
          (select auth.uid()),
          case when (select auth.uid()) is null then 'system' else 'user' end,
          TG_OP, TG_TABLE_NAME,
          coalesce(v_row ->> 'id', v_row ->> 'player_id', v_row ->> 'profile_id'),
          jsonb_build_object('fields', v_changed));
  return coalesce(NEW, OLD);
end $$;

do $$
declare t text;
begin
  foreach t in array array['parental_consents','player_documents','identity_verifications','player_medical',
      'profile_roles','profiles','payment_gateways','support_access_grants','data_deletion_requests',
      'player_charges','message_reports','staff_documents','competition_deadlines','fines']
  loop
    execute format('create trigger audit_%1$s after insert or update or delete on %1$I
                    for each row execute function private.trg_audit()', t);
  end loop;
end $$;

-- ---- profiles: identity fields are not user-editable ---------------------
create function private.trg_profile_protect() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  if NEW.id <> OLD.id or NEW.club_id <> OLD.club_id then
    raise exception 'id and club_id are immutable';
  end if;
  if (NEW.approval_status is distinct from OLD.approval_status
      or NEW.approved_by is distinct from OLD.approved_by
      or NEW.approved_at is distinct from OLD.approved_at
      or NEW.email is distinct from OLD.email)
     and (select auth.uid()) is not null                       -- service role / system bypasses
     and not private.has_permission('members.approve') then
    raise exception 'not allowed to change approval or email';
  end if;
  return NEW;
end $$;
create trigger profile_protect before update on profiles
  for each row execute function private.trg_profile_protect();
