-- =====================================================================
-- 12_rpc_more.sql — conversations and engagement preferences
-- =====================================================================

-- Only a coach can open a conversation (coach -> player / parent / squad).
-- Participants are computed, not client-supplied, so a child can never be added
-- to a thread without their guardians, and guardians are auto-added as OBSERVERS
-- on every coach<->minor thread (the messages trigger enforces this too).
create function public.start_conversation(
  p_kind public.conversation_kind, p_player uuid default null, p_squad uuid default null)
returns uuid
language plpgsql security definer set search_path = '' as $$
declare v_uid uuid := (select auth.uid()); v_club uuid := private.current_club_id(); v_id uuid; v_squad uuid := p_squad;
begin
  if v_club is null then raise exception 'not allowed' using errcode = '42501'; end if;

  if p_kind = 'squad_announcement' then
    if v_squad is null or not private.is_squad_staff(v_squad) then
      raise exception 'not allowed' using errcode = '42501';
    end if;
  else
    if p_player is null or not private.is_coach_of_player(p_player) then
      raise exception 'not allowed' using errcode = '42501';
    end if;
    if not private.is_processing_allowed(p_player) then
      raise exception 'no verified parental consent on file' using errcode = '42501';
    end if;
  end if;

  insert into public.conversations (club_id, kind, squad_id, player_id, created_by)
  values (v_club, p_kind, v_squad, p_player, v_uid) returning id into v_id;

  insert into public.conversation_participants (conversation_id, profile_id, club_id) values (v_id, v_uid, v_club);

  if p_kind = 'coach_player' then
    insert into public.conversation_participants (conversation_id, profile_id, club_id)
      select v_id, profile_id, v_club from public.players where id = p_player and profile_id is not null;
    insert into public.conversation_participants (conversation_id, profile_id, club_id, is_observer)
      select v_id, g.profile_id, v_club, true from public.player_guardians g
       where g.player_id = p_player and g.profile_id is not null
      on conflict do nothing;
  elsif p_kind = 'coach_parent' then
    insert into public.conversation_participants (conversation_id, profile_id, club_id)
      select v_id, g.profile_id, v_club from public.player_guardians g
       where g.player_id = p_player and g.profile_id is not null
      on conflict do nothing;
  else
    insert into public.conversation_participants (conversation_id, profile_id, club_id)
      select v_id, x.profile_id, v_club from (
        select g.profile_id from public.squad_memberships sm
          join public.player_guardians g on g.player_id = sm.player_id
         where sm.squad_id = v_squad and sm.left_on is null and private.is_processing_allowed(sm.player_id)
        union
        select pl.profile_id from public.squad_memberships sm
          join public.players pl on pl.id = sm.player_id
         where sm.squad_id = v_squad and sm.left_on is null and private.is_processing_allowed(sm.player_id)) x
       where x.profile_id is not null
      on conflict do nothing;
  end if;
  return v_id;
end $$;

-- Guardian switches streaks / achievements off (or on) for their child.
create function public.set_engagement(p_player uuid, p_enabled boolean) returns void
language plpgsql security definer set search_path = '' as $$
begin
  if not (private.is_guardian_of(p_player) or private.is_self_adult(p_player)) then
    raise exception 'not allowed' using errcode = '42501';
  end if;
  update public.players set engagement_enabled = p_enabled where id = p_player;
end $$;

revoke execute on function public.start_conversation(public.conversation_kind, uuid, uuid),
                           public.set_engagement(uuid, boolean) from public, anon;
grant  execute on function public.start_conversation(public.conversation_kind, uuid, uuid),
                           public.set_engagement(uuid, boolean) to authenticated;
