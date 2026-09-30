-- =====================================================================
-- 11_rpc_views.sql — callable functions (public schema = Supabase RPC) + views
--
-- Clients get NO direct write access to: consent status, payments, message
-- reports, RSVP columns, jersey claims. Those go through these functions,
-- which re-check who the caller is. Functions marked SERVICE ONLY are for
-- Edge Functions using the service-role key.
-- =====================================================================

-- ---- jerseys ----------------------------------------------------------
create function public.available_jersey_numbers(
  p_player uuid, p_season uuid, p_target_squads uuid[] default '{}')
returns table (jersey_number smallint)
language plpgsql stable security definer set search_path = '' as $$
begin
  if not private.can_read_player(p_player) then
    raise exception 'not allowed' using errcode = '42501';
  end if;
  return query select a from private.available_numbers(p_player, p_season, p_target_squads) a;
end $$;

create function public.claim_jersey_number(p_player uuid, p_season uuid, p_number smallint)
returns void
language plpgsql security definer set search_path = '' as $$
declare v_club uuid; v_locked boolean; v_manager boolean := private.has_permission('jerseys.manage');
begin
  select club_id into v_club from public.players where id = p_player;
  if v_club is null or v_club is distinct from private.current_club_id() then
    raise exception 'not allowed' using errcode = '42501';
  end if;
  if not (v_manager or private.is_self_player(p_player) or private.is_guardian_of(p_player)) then
    raise exception 'not allowed' using errcode = '42501';
  end if;
  if not private.is_processing_allowed(p_player) then
    raise exception 'parental consent required' using errcode = '42501';
  end if;

  select locked into v_locked from public.player_jersey_numbers
    where player_id = p_player and season_id = p_season;
  if coalesce(v_locked, false) and not v_manager then
    raise exception 'number is locked (kit ordered); ask the club';
  end if;

  if not exists (select 1 from private.available_numbers(p_player, p_season, '{}') a where a = p_number) then
    raise exception 'number % is not available across all of this player''s squads', p_number;
  end if;

  insert into public.player_jersey_numbers (club_id, player_id, season_id, number, chosen_by)
  values (v_club, p_player, p_season, p_number, (select auth.uid()))
  on conflict (player_id, season_id) do update
    set number = excluded.number, chosen_by = excluded.chosen_by, chosen_at = now();

  update public.squad_memberships
     set jersey_number = p_number, kit_exception_reason = null
   where player_id = p_player and season_id = p_season and left_on is null;
end $$;

-- ---- scheduling -------------------------------------------------------
create function public.set_rsvp(p_event uuid, p_player uuid, p_status public.rsvp_status)
returns void
language plpgsql security definer set search_path = '' as $$
begin
  if not (private.is_self_player(p_player) or private.is_guardian_of(p_player)) then
    raise exception 'not allowed' using errcode = '42501';
  end if;
  if not private.is_processing_allowed(p_player) then
    raise exception 'parental consent required' using errcode = '42501';
  end if;
  update public.event_participants ep
     set rsvp = p_status, rsvp_by = (select auth.uid()), rsvp_at = now()
   where ep.event_id = p_event and ep.player_id = p_player
     and ep.club_id = private.current_club_id()
     and exists (select 1 from public.events e where e.id = p_event
                 and e.status = 'scheduled' and (e.rsvp_deadline is null or e.rsvp_deadline > now()));
  if not found then raise exception 'cannot RSVP to this event'; end if;
end $$;

-- ---- consent (SERVICE ONLY) --------------------------------------------
-- The emailed link carries a random token; only its sha256 is stored.
create function public.grant_parental_consent(p_token text, p_ip inet default null, p_user_agent text default null)
returns uuid
language plpgsql security definer set search_path = '' as $$
declare c public.parental_consents%rowtype;
begin
  select * into c from public.parental_consents
   where token_hash = encode(extensions.digest(p_token, 'sha256'), 'hex') for update;
  if not found then raise exception 'invalid consent link'; end if;
  if c.status <> 'pending' then raise exception 'consent link already used'; end if;
  if c.expires_at < now() then
    update public.parental_consents set status = 'expired' where id = c.id;
    raise exception 'consent link expired';
  end if;
  update public.parental_consents
     set status = 'granted', responded_at = now(), response_ip = p_ip, response_user_agent = p_user_agent
   where id = c.id;
  update public.player_guardians set email_verified_at = now() where id = c.guardian_id;
  return c.player_id;
end $$;

create function public.decline_parental_consent(p_token text)
returns void
language plpgsql security definer set search_path = '' as $$
begin
  update public.parental_consents set status = 'declined', responded_at = now()
   where token_hash = encode(extensions.digest(p_token, 'sha256'), 'hex')
     and status = 'pending' and expires_at > now();
  if not found then raise exception 'invalid or used consent link'; end if;
end $$;

-- Guardian revokes from inside the app (they are logged in).
create function public.revoke_parental_consent(p_consent uuid)
returns void
language plpgsql security definer set search_path = '' as $$
begin
  update public.parental_consents c set status = 'revoked', revoked_at = now()
   where c.id = p_consent and c.status = 'granted'
     and c.club_id = private.current_club_id()
     and exists (select 1 from public.player_guardians g
                 where g.id = c.guardian_id and g.profile_id = (select auth.uid()));
  if not found then raise exception 'not allowed' using errcode = '42501'; end if;
end $$;

-- ---- safety reporting --------------------------------------------------
create function public.report_message(p_message uuid, p_reason public.report_reason, p_details text default null)
returns uuid
language plpgsql security definer set search_path = '' as $$
declare m public.messages%rowtype; v_id uuid;
begin
  select * into m from public.messages where id = p_message and club_id = private.current_club_id();
  if not found or not exists (select 1 from public.conversation_participants cp
                              where cp.conversation_id = m.conversation_id and cp.profile_id = (select auth.uid())) then
    raise exception 'not allowed' using errcode = '42501';
  end if;
  insert into public.message_reports (club_id, message_id, reported_by, reason, details, message_snapshot)
  values (m.club_id, m.id, (select auth.uid()), p_reason, p_details, m.body)
  on conflict (message_id, reported_by) do update set details = coalesce(excluded.details, public.message_reports.details)
  returning id into v_id;
  return v_id;
end $$;

-- Reviewer action: hide a message and/or lock the thread. Nothing is deleted.
create function public.resolve_message_report(
  p_report uuid, p_status public.report_status, p_note text, p_hide_message boolean default false, p_lock_conversation boolean default false)
returns void
language plpgsql security definer set search_path = '' as $$
declare r public.message_reports%rowtype;
begin
  if not private.has_permission('safeguarding.review') then
    raise exception 'not allowed' using errcode = '42501';
  end if;
  select * into r from public.message_reports where id = p_report and club_id = private.current_club_id();
  if not found then raise exception 'unknown report'; end if;
  update public.message_reports set status = p_status, outcome_note = p_note,
         reviewed_by = (select auth.uid()), reviewed_at = now() where id = p_report;
  if p_hide_message then
    update public.messages set hidden_at = now(), hidden_by = (select auth.uid()), hidden_reason = p_note where id = r.message_id;
  end if;
  if p_lock_conversation then
    update public.conversations set locked_at = now()
     where id = (select conversation_id from public.messages where id = r.message_id);
  end if;
end $$;

-- ---- data control (self-serve) ------------------------------------------
create function public.request_data_deletion(
  p_scope public.deletion_scope, p_player uuid default null)
returns uuid
language plpgsql security definer set search_path = '' as $$
declare v_uid uuid := (select auth.uid()); v_club uuid := private.current_club_id(); v_id uuid;
begin
  if v_club is null then raise exception 'not allowed' using errcode = '42501'; end if;
  if p_player is not null then
    -- a guardian for a minor, or the adult player themself
    if not (private.is_guardian_of(p_player)
            or (private.is_self_player(p_player)
                and (select private.age_on(date_of_birth) >= 18 from public.players where id = p_player))) then
      raise exception 'not allowed' using errcode = '42501';
    end if;
    insert into public.data_deletion_requests (club_id, requested_by, subject_player_id, scope)
    values (v_club, v_uid, p_player, p_scope) returning id into v_id;
  else
    insert into public.data_deletion_requests (club_id, requested_by, subject_profile_id, scope)
    values (v_club, v_uid, v_uid, p_scope) returning id into v_id;
  end if;
  return v_id;
end $$;

create function public.cancel_data_deletion(p_request uuid)
returns void
language plpgsql security definer set search_path = '' as $$
begin
  update public.data_deletion_requests
     set status = 'cancelled', cancelled_at = now()
   where id = p_request and requested_by = (select auth.uid())
     and status = 'cooling_off' and cooling_off_until > now();
  if not found then raise exception 'cannot cancel (window passed or not yours)'; end if;
end $$;

-- SERVICE ONLY. Anonymises the player row (kept so retained financial records
-- keep a valid FK), deletes every personal record, and RETURNS the storage
-- paths so the Edge Function can delete the files. The DOB is coarsened to
-- 1 January of the birth year.
create function public.erase_player(p_player uuid) returns text[]
language plpgsql security definer set search_path = '' as $$
declare v_paths text[]; v_profile uuid;
begin
  select profile_id into v_profile from public.players where id = p_player;

  select coalesce(array_agg(p), '{}') into v_paths from (
    select storage_path p from public.player_documents where player_id = p_player
    union all select id_doc_path from public.identity_verifications where player_id = p_player and id_doc_path is not null
    union all select selfie_path from public.identity_verifications where player_id = p_player and selfie_path is not null) s;

  delete from public.drill_completions where assignment_id in (select id from public.drill_assignments where player_id = p_player);
  delete from public.drill_assignments  where player_id = p_player;
  delete from public.player_rating_scores where rating_id in (select id from public.player_ratings where player_id = p_player);
  delete from public.player_ratings     where player_id = p_player;
  delete from public.player_achievements where player_id = p_player;
  delete from public.player_streaks      where player_id = p_player;
  delete from public.event_participants  where player_id = p_player;
  delete from public.match_sheet_players where player_id = p_player;
  delete from public.media_player_tags   where player_id = p_player;
  delete from public.player_documents    where player_id = p_player;
  delete from public.identity_verifications where player_id = p_player;
  delete from public.player_medical      where player_id = p_player;
  delete from public.squad_memberships   where player_id = p_player;
  delete from public.player_jersey_numbers where player_id = p_player;

  if v_profile is not null then
    update public.messages set body = '[deleted]', attachment_path = null where sender_id = v_profile;
    delete from public.conversation_participants where profile_id = v_profile;
  end if;

  update public.parental_consents
     set response_ip = null, response_user_agent = null,
         sent_to_email = ('erased+' || id || '@invalid')
   where player_id = p_player;
  update public.player_guardians
     set full_name = 'Erased', email = ('erased+' || id || '@invalid'),
         phone = null, profile_id = null, can_consent = false
   where player_id = p_player;

  update public.players set
     first_name = 'Erased', last_name = 'Player', first_name_ar = null, last_name_ar = null,
     date_of_birth = make_date(extract(year from date_of_birth)::int, 1, 1),
     gender = null, nationality = null, position_group = null, profile_id = null,
     status = 'erased', anonymized_at = now()
   where id = p_player;
  return v_paths;
end $$;

-- SERVICE ONLY. Scrubs a staff / guardian / adult-player ACCOUNT. The Edge
-- Function then deletes the auth.users row. Tombstone profile stays.
create function public.erase_profile(p_profile uuid) returns text[]
language plpgsql security definer set search_path = '' as $$
declare v_paths text[];
begin
  select coalesce(array_agg(p), '{}') into v_paths from (
    select storage_path p from public.staff_documents where profile_id = p_profile
    union all select id_doc_path from public.identity_verifications where profile_id = p_profile and id_doc_path is not null
    union all select selfie_path from public.identity_verifications where profile_id = p_profile and selfie_path is not null) s;

  delete from public.staff_documents where profile_id = p_profile;
  delete from public.staff_profiles  where profile_id = p_profile;
  delete from public.identity_verifications where profile_id = p_profile;
  delete from public.notifications where recipient_id = p_profile;
  delete from public.conversation_participants where profile_id = p_profile;
  delete from public.profile_roles where profile_id = p_profile;
  update public.messages set body = '[deleted]', attachment_path = null where sender_id = p_profile;

  -- a guardian who leaves withdraws their consents (child data is hidden until a new guardian consents)
  update public.parental_consents set status = 'revoked', revoked_at = now()
   where status = 'granted' and guardian_id in (select id from public.player_guardians where profile_id = p_profile);
  update public.player_guardians
     set full_name = 'Erased', email = ('erased+' || id || '@invalid'),
         phone = null, profile_id = null, can_consent = false
   where profile_id = p_profile;

  update public.profiles set full_name = 'Erased user', full_name_ar = null,
         email = ('erased+' || id || '@invalid'), phone = null, approval_status = 'suspended'
   where id = p_profile;
  return v_paths;
end $$;

-- ---- compliance engine ---------------------------------------------------
-- Builds / refreshes the pre-matchday checklist from the club's checklist_items,
-- evaluating the automatic checks against the match sheet, roster and documents.
create function public.evaluate_matchday_checklist(p_match uuid) returns uuid
language plpgsql security definer set search_path = '' as $$
declare
  m        record; v_cl uuid; it record;
  v_state  public.check_state; v_detail jsonb;
  v_have   int; v_need int; v_missing jsonb; v_kinds text[];
  v_status public.checklist_status;
begin
  select mt.club_id, mt.competition_id, e.squad_id, e.starts_at, c.min_squad_size
    into m
    from public.matches mt
    join public.events e on e.id = mt.event_id
    join public.competitions c on c.id = mt.competition_id
   where mt.event_id = p_match;
  if not found or m.club_id is distinct from private.current_club_id() then
    raise exception 'not allowed' using errcode = '42501';
  end if;
  if not (private.has_permission('compliance.write') or private.is_squad_staff(m.squad_id)) then
    raise exception 'not allowed' using errcode = '42501';
  end if;

  insert into public.matchday_checklists (club_id, match_id) values (m.club_id, p_match)
    on conflict (match_id) do nothing;
  select id into v_cl from public.matchday_checklists where match_id = p_match;

  for it in select * from public.checklist_items
             where competition_id = m.competition_id and active order by sort_order loop
    v_state := null;
    if it.check_type = 'squad_size' then
      v_need := coalesce((it.params ->> 'min_players')::int, m.min_squad_size, 0);
      select count(*) into v_have from public.match_sheet_players where match_id = p_match;
      v_state := case when v_have >= v_need then 'pass' else 'fail' end;
      v_detail := jsonb_build_object('have', v_have, 'need', v_need);

    elsif it.check_type = 'medical_staff_listed' then
      v_need := coalesce((it.params ->> 'min_staff')::int, 1);
      select count(distinct profile_id) into v_have from public.match_sheet_staff
        where match_id = p_match and role = 'medical';
      v_state := case when v_have >= v_need then 'pass' else 'fail' end;
      v_detail := jsonb_build_object('have', v_have, 'need', v_need);

    elsif it.check_type = 'player_documents_on_file' then
      select coalesce(array_agg(k), array['emirates_id','photo']) into v_kinds
        from jsonb_array_elements_text(coalesce(it.params -> 'doc_kinds', '[]')) k;
      select coalesce(jsonb_agg(jsonb_build_object('player_id', msp.player_id, 'missing', miss.kinds)), '[]')
        into v_missing
        from public.match_sheet_players msp
        cross join lateral (
          select array_agg(k) kinds from unnest(v_kinds) k
          where not exists (select 1 from public.player_documents d
                            where d.player_id = msp.player_id and d.kind::text = k and d.status = 'verified'
                              and (d.expires_on is null or d.expires_on >= m.starts_at::date))) miss
        where miss.kinds is not null and msp.match_id = p_match;
      v_state := case when jsonb_array_length(v_missing) = 0 then 'pass' else 'fail' end;
      v_detail := jsonb_build_object('players_missing_documents', v_missing);

    elsif it.check_type = 'staff_certs_valid' then
      select coalesce(array_agg(k), array['coaching_licence']) into v_kinds
        from jsonb_array_elements_text(coalesce(it.params -> 'doc_kinds', '[]')) k;
      select coalesce(jsonb_agg(jsonb_build_object('profile_id', s.profile_id, 'missing', miss.kinds)), '[]')
        into v_missing
        from (select distinct profile_id from public.match_sheet_staff where match_id = p_match) s
        cross join lateral (
          select array_agg(k) kinds from unnest(v_kinds) k
          where not exists (select 1 from public.staff_documents d
                            where d.profile_id = s.profile_id and d.kind::text = k and d.status = 'verified'
                              and (d.expires_on is null or d.expires_on >= m.starts_at::date))) miss
        where miss.kinds is not null;
      v_state := case when jsonb_array_length(v_missing) = 0 then 'pass' else 'fail' end;
      v_detail := jsonb_build_object('staff_missing_certs', v_missing);
    end if;

    if v_state is not null then      -- automatic checks only; manual items are never overwritten
      insert into public.matchday_checklist_results
        (club_id, checklist_id, checklist_item_id, state, auto_evaluated, detail, checked_at)
      values (m.club_id, v_cl, it.id, v_state, true, v_detail, now())
      on conflict (checklist_id, checklist_item_id) do update
        set state = case when matchday_checklist_results.state = 'waived' then 'waived' else excluded.state end,
            detail = excluded.detail, checked_at = excluded.checked_at, auto_evaluated = true;
    else
      insert into public.matchday_checklist_results (club_id, checklist_id, checklist_item_id)
      values (m.club_id, v_cl, it.id) on conflict do nothing;
    end if;
  end loop;

  select case
           when bool_or(r.state = 'fail' and i.blocking) then 'blocked'
           when bool_and(r.state in ('pass','waived') or not i.blocking) then 'ready'
           else 'open' end::public.checklist_status
    into v_status
    from public.matchday_checklist_results r
    join public.checklist_items i on i.id = r.checklist_item_id
   where r.checklist_id = v_cl;
  update public.matchday_checklists set status = coalesce(v_status, 'open')
   where id = v_cl and status <> 'submitted';
  return v_cl;
end $$;

-- Turns failing checks into predicted ("at_risk") fines using the club's fine rules,
-- and a club-cancelled match into a cancelled_match fine. Idempotent per match.
create function public.refresh_at_risk_fines(p_match uuid) returns integer
language plpgsql security definer set search_path = '' as $$
declare m record; n int := 0; rule record; v_cl uuid; v_units int;
begin
  select mt.club_id, mt.competition_id, e.squad_id, e.status, e.cancelled_by_club
    into m from public.matches mt join public.events e on e.id = mt.event_id
   where mt.event_id = p_match;
  if not found or m.club_id is distinct from private.current_club_id()
     or not (private.has_permission('compliance.write') or private.is_squad_staff(m.squad_id)) then
    raise exception 'not allowed' using errcode = '42501';
  end if;

  delete from public.fines where match_id = p_match and status = 'at_risk';
  select id into v_cl from public.matchday_checklists where match_id = p_match;

  for rule in select * from public.fine_rules where competition_id = m.competition_id loop
    v_units := 0;
    if rule.kind = 'cancelled_match' and m.status = 'cancelled' and coalesce(m.cancelled_by_club, false) then
      v_units := 1;
    elsif rule.kind = 'incomplete_squad' and v_cl is not null then
      select coalesce(max((r.detail ->> 'need')::int - (r.detail ->> 'have')::int), 0) into v_units
        from public.matchday_checklist_results r join public.checklist_items i on i.id = r.checklist_item_id
       where r.checklist_id = v_cl and i.check_type = 'squad_size' and r.state = 'fail';
      if rule.basis <> 'per_player' then v_units := least(v_units, 1); end if;
    elsif rule.kind = 'missing_medical_staff' and v_cl is not null then
      select count(*) into v_units
        from public.matchday_checklist_results r join public.checklist_items i on i.id = r.checklist_item_id
       where r.checklist_id = v_cl and i.check_type = 'medical_staff_listed' and r.state = 'fail';
    end if;
    if v_units > 0 then
      insert into public.fines (club_id, competition_id, fine_rule_id, match_id, squad_id, kind, units, amount_fils, currency, status)
      values (m.club_id, m.competition_id, rule.id, p_match, m.squad_id, rule.kind, v_units,
              rule.amount_fils * v_units, rule.currency, 'at_risk');
      n := n + 1;
    end if;
  end loop;
  return n;
end $$;

-- ---- grants: who may call what -----------------------------------------
revoke execute on all functions in schema public from public, anon, authenticated;
grant execute on function
  public.available_jersey_numbers(uuid, uuid, uuid[]),
  public.claim_jersey_number(uuid, uuid, smallint),
  public.set_rsvp(uuid, uuid, public.rsvp_status),
  public.revoke_parental_consent(uuid),
  public.report_message(uuid, public.report_reason, text),
  public.resolve_message_report(uuid, public.report_status, text, boolean, boolean),
  public.request_data_deletion(public.deletion_scope, uuid),
  public.cancel_data_deletion(uuid),
  public.evaluate_matchday_checklist(uuid),
  public.refresh_at_risk_fines(uuid)
to authenticated;
-- SERVICE ONLY (Edge Functions with the service-role key)
grant execute on function
  public.grant_parental_consent(text, inet, text),
  public.decline_parental_consent(text),
  public.erase_player(uuid),
  public.erase_profile(uuid)
to service_role;

-- ---- views (security_invoker: RLS of the caller applies) ------------------
create view v_player_charge_status with (security_invoker = true) as
select c.*,
       (c.amount_fils + c.vat_fils - c.amount_paid_fils) as outstanding_fils,
       case when c.status in ('paid','waived','void') then c.status::text
            when c.due_on < private.today() then 'overdue'
            else c.status::text end as display_status      -- paid | due | part_paid | overdue | waived
from player_charges c;

create view v_jersey_conflicts with (security_invoker = true) as
select sm.club_id, sm.player_id, sm.season_id, pj.number as player_number,
       sm.squad_id, sm.jersey_number as squad_number, sm.kit_exception_reason,
       (sm.jersey_number is null)              as needs_number,
       (sm.jersey_number is distinct from pj.number and sm.jersey_number is not null) as needs_extra_kit
from squad_memberships sm
left join player_jersey_numbers pj on pj.player_id = sm.player_id and pj.season_id = sm.season_id
where sm.left_on is null
  and (sm.jersey_number is null or sm.jersey_number is distinct from pj.number);

create view v_fee_collection_monthly with (security_invoker = true) as
select club_id, date_trunc('month', due_on)::date as month,
       sum(amount_fils + vat_fils) filter (where status <> 'void')            as billed_fils,
       sum(amount_paid_fils)                                                  as collected_fils,
       sum(amount_fils + vat_fils - amount_paid_fils)
         filter (where status in ('due','part_paid') and due_on < private.today()) as overdue_fils,
       count(*) filter (where status = 'waived')                              as waived_count
from player_charges group by club_id, date_trunc('month', due_on);

create view v_attendance_monthly with (security_invoker = true) as
select e.club_id, e.squad_id, date_trunc('month', e.starts_at)::date as month,
       count(*) filter (where ep.attendance in ('present','late')) as attended,
       count(*) filter (where ep.attendance is not null)           as marked,
       round(100.0 * count(*) filter (where ep.attendance in ('present','late'))
             / nullif(count(*) filter (where ep.attendance is not null), 0), 1) as attendance_pct
from events e join event_participants ep on ep.event_id = e.id
where e.type = 'training' and e.status <> 'cancelled'
group by e.club_id, e.squad_id, date_trunc('month', e.starts_at);

create view v_staff_compliance with (security_invoker = true) as
select p.club_id, p.id as profile_id, p.full_name, r.role, req.doc_kind,
       d.expires_on,
       case when d.id is null then 'missing'
            when d.status <> 'verified' then d.status::text
            when d.expires_on < private.today() then 'expired'
            when d.expires_on < private.today() + 30 then 'expiring_soon'
            else 'ok' end as state
from profiles p
join profile_roles r on r.profile_id = p.id
join staff_doc_requirements req on req.club_id = p.club_id and req.role = r.role and req.required
left join lateral (select * from staff_documents sd
                   where sd.profile_id = p.id and sd.kind = req.doc_kind
                   order by sd.expires_on desc nulls first limit 1) d on true;

create view v_player_season_stats with (security_invoker = true) as
select pl.club_id, pl.id as player_id,
       count(*) filter (where ep.attendance in ('present','late')) as sessions_attended,
       count(*) filter (where ep.attendance is not null)           as sessions_marked,
       (select count(*) from drill_completions dc
          join drill_assignments da on da.id = dc.assignment_id where da.player_id = pl.id) as drill_logs
from players pl
left join event_participants ep on ep.player_id = pl.id
group by pl.club_id, pl.id;
