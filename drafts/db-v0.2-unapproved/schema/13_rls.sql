-- =====================================================================
-- 13_rls.sql — Row-Level Security on EVERY table
--
-- Layers, in the order a request passes them:
--   1. TENANT WALL   every policy pins club_id = private.current_club_id().
--                    Non-approved accounts resolve to NULL => see nothing.
--   2. PERMISSION    manager/admin rights come from role_permissions.
--   3. RELATIONSHIP  coach = assigned squads only; parent = linked children;
--                    player = self. Never "everyone in the club".
--   4. CHILD GATE    RESTRICTIVE policies (AND-ed with all of the above): a
--                    minor's data is invisible and unwritable unless
--                    private.is_processing_allowed(player_id).
-- Tables with no policy for an operation deny it. Writes that must not come
-- from browsers (consent, payments, reports, RSVP, erasure) have no client
-- policy at all; they go through 11_rpc_views.sql / Edge Functions.
-- =====================================================================

-- ---- table privileges: RLS is the real gate ---------------------------
revoke all on all tables in schema public from anon;
grant select, insert, update, delete on all tables in schema public to authenticated;
grant all on all tables in schema public to service_role;
grant usage, select on all sequences in schema public to authenticated, service_role;
alter default privileges in schema public grant select, insert, update, delete on tables to authenticated;
alter default privileges in schema public grant all on tables to service_role;

do $$
declare t record;
begin
  for t in select tablename from pg_tables where schemaname = 'public' loop
    execute format('alter table public.%I enable row level security', t.tablename);
  end loop;
end $$;

-- ---- policy-writing helpers (dropped at the end of this file) ----------
create procedure private.pol_staff(tbl text, read_perm text, write_perm text)
language plpgsql as $$
begin
  execute format($f$create policy %1$I_staff_read on %1$I for select to authenticated
    using (club_id = (select private.current_club_id()) and (select private.has_permission(%2$L)))$f$, tbl, read_perm);
  execute format($f$create policy %1$I_staff_ins on %1$I for insert to authenticated
    with check (club_id = (select private.current_club_id()) and (select private.has_permission(%2$L)))$f$, tbl, write_perm);
  execute format($f$create policy %1$I_staff_upd on %1$I for update to authenticated
    using (club_id = (select private.current_club_id()) and (select private.has_permission(%2$L)))
    with check (club_id = (select private.current_club_id()) and (select private.has_permission(%2$L)))$f$, tbl, write_perm);
  execute format($f$create policy %1$I_staff_del on %1$I for delete to authenticated
    using (club_id = (select private.current_club_id()) and (select private.has_permission(%2$L)))$f$, tbl, write_perm);
end $$;

-- club-wide read for every approved member, permissioned write
create procedure private.pol_club_read(tbl text, write_perm text)
language plpgsql as $$
begin
  execute format($f$create policy %1$I_member_read on %1$I for select to authenticated
    using (club_id = (select private.current_club_id()))$f$, tbl);
  execute format($f$create policy %1$I_staff_ins on %1$I for insert to authenticated
    with check (club_id = (select private.current_club_id()) and (select private.has_permission(%2$L)))$f$, tbl, write_perm);
  execute format($f$create policy %1$I_staff_upd on %1$I for update to authenticated
    using (club_id = (select private.current_club_id()) and (select private.has_permission(%2$L)))
    with check (club_id = (select private.current_club_id()) and (select private.has_permission(%2$L)))$f$, tbl, write_perm);
  execute format($f$create policy %1$I_staff_del on %1$I for delete to authenticated
    using (club_id = (select private.current_club_id()) and (select private.has_permission(%2$L)))$f$, tbl, write_perm);
end $$;

-- platform reference data: readable by all signed-in users, writable by platform owner
create procedure private.pol_platform_ref(tbl text)
language plpgsql as $$
begin
  execute format($f$create policy %1$I_read on %1$I for select to authenticated using (true)$f$, tbl);
  execute format($f$create policy %1$I_owner_write on %1$I for all to authenticated
    using ((select private.is_platform_owner())) with check ((select private.is_platform_owner()))$f$, tbl);
end $$;

-- THE CHILD GATE. mode 'all' = select+insert+update, 'insert' = new rows only.
create procedure private.pol_child_gate(tbl text, player_col text, mode text default 'all')
language plpgsql as $$
begin
  if mode = 'all' then
    execute format($f$create policy %1$I_gate_sel on %1$I as restrictive for select to authenticated
      using (%2$I is null or (select private.is_processing_allowed(%2$I)))$f$, tbl, player_col);
    execute format($f$create policy %1$I_gate_upd on %1$I as restrictive for update to authenticated
      using (%2$I is null or (select private.is_processing_allowed(%2$I)))
      with check (%2$I is null or (select private.is_processing_allowed(%2$I)))$f$, tbl, player_col);
  end if;
  execute format($f$create policy %1$I_gate_ins on %1$I as restrictive for insert to authenticated
    with check (%2$I is null or (select private.is_processing_allowed(%2$I)))$f$, tbl, player_col);
end $$;

-- ---- platform reference data -------------------------------------------
call private.pol_platform_ref('platform_plans');
call private.pol_platform_ref('role_permissions');
call private.pol_platform_ref('tpl_competitions');
call private.pol_platform_ref('tpl_deadlines');
call private.pol_platform_ref('tpl_fine_rules');
call private.pol_platform_ref('tpl_checklist_items');
call private.pol_platform_ref('achievement_defs');

-- ---- tenants, billing, platform staff ------------------------------------
create policy clubs_read on clubs for select to authenticated
  using (id = (select private.current_club_id()) or (select private.is_platform_staff()));
create policy clubs_update on clubs for update to authenticated
  using ((id = (select private.current_club_id()) and (select private.has_permission('club.settings')))
         or (select private.is_platform_owner()))
  with check ((id = (select private.current_club_id()) and (select private.has_permission('club.settings')))
         or (select private.is_platform_owner()));
create policy clubs_owner_insert on clubs for insert to authenticated with check ((select private.is_platform_owner()));
create policy clubs_owner_delete on clubs for delete to authenticated using ((select private.is_platform_owner()));

create policy subs_read on club_subscriptions for select to authenticated
  using ((club_id = (select private.current_club_id()) and (select private.has_permission('billing.manage')))
         or (select private.is_platform_staff()));
create policy subs_owner_write on club_subscriptions for all to authenticated
  using ((select private.is_platform_owner())) with check ((select private.is_platform_owner()));
create policy invoices_read on platform_invoices for select to authenticated
  using ((club_id = (select private.current_club_id()) and (select private.has_permission('billing.manage')))
         or (select private.is_platform_staff()));
create policy invoices_owner_write on platform_invoices for all to authenticated
  using ((select private.is_platform_owner())) with check ((select private.is_platform_owner()));

create policy platform_staff_read on platform_staff for select to authenticated
  using (user_id = (select auth.uid()) or (select private.is_platform_owner()));
create policy platform_staff_write on platform_staff for all to authenticated
  using ((select private.is_platform_owner())) with check ((select private.is_platform_owner()));

create policy support_grants_read on support_access_grants for select to authenticated
  using ((club_id = (select private.current_club_id()) and (select private.has_permission('roles.manage')))
         or platform_user_id = (select auth.uid()));
create policy support_grants_insert on support_access_grants for insert to authenticated
  with check (club_id = (select private.current_club_id()) and (select private.has_permission('roles.manage'))
              and granted_by = (select auth.uid()));
create policy support_grants_revoke on support_access_grants for update to authenticated
  using (club_id = (select private.current_club_id()) and (select private.has_permission('roles.manage')))
  with check (club_id = (select private.current_club_id()) and (select private.has_permission('roles.manage')));

-- ---- accounts ------------------------------------------------------------
create policy profiles_read on profiles for select to authenticated
  using ((select private.can_see_profile(id)));
create policy profiles_update on profiles for update to authenticated
  using (id = (select auth.uid())
         or (club_id = (select private.current_club_id()) and (select private.has_permission('members.approve'))))
  with check (id = (select auth.uid())
         or (club_id = (select private.current_club_id()) and (select private.has_permission('members.approve'))));
-- no insert / delete policy: profiles are created and erased by Edge Functions (service role)

create policy profile_roles_read on profile_roles for select to authenticated
  using (profile_id = (select auth.uid())
         or (club_id = (select private.current_club_id()) and (select private.has_permission('members.read'))));
create policy profile_roles_write on profile_roles for all to authenticated
  using (club_id = (select private.current_club_id()) and (select private.has_permission('roles.manage')))
  with check (club_id = (select private.current_club_id()) and (select private.has_permission('roles.manage')));

call private.pol_club_read('seasons', 'club.settings');
call private.pol_club_read('venues',  'schedule.write');

-- ---- players & family -----------------------------------------------------
create policy players_read on players for select to authenticated
  using ((select private.can_read_player(id)));
create policy players_ins on players for insert to authenticated
  with check (club_id = (select private.current_club_id()) and (select private.has_permission('players.write')));
create policy players_upd on players for update to authenticated
  using (club_id = (select private.current_club_id()) and (select private.has_permission('players.write')))
  with check (club_id = (select private.current_club_id()) and (select private.has_permission('players.write')));
-- no delete policy: erasure = public.erase_player() (service role)

create policy guardians_read on player_guardians for select to authenticated
  using ((select private.can_read_player(player_id)));
create policy guardians_write on player_guardians for all to authenticated
  using (club_id = (select private.current_club_id()) and (select private.has_permission('players.write')))
  with check (club_id = (select private.current_club_id()) and (select private.has_permission('players.write')));

-- consent: readable by staff who manage players and by the guardian; NEVER writable from clients
create policy consents_read on parental_consents for select to authenticated
  using (club_id = (select private.current_club_id())
         and ((select private.has_permission('players.write')) or (select private.is_guardian_of(player_id))));

create policy medical_read on player_medical for select to authenticated
  using (club_id = (select private.current_club_id())
         and ((select private.has_permission('players.medical'))
              or (select private.is_guardian_of(player_id))
              or (select private.is_self_adult(player_id))
              or (select private.is_medical_staff_of(player_id))));
create policy medical_write on player_medical for all to authenticated
  using (club_id = (select private.current_club_id())
         and ((select private.has_permission('players.medical')) or (select private.is_guardian_of(player_id))))
  with check (club_id = (select private.current_club_id())
         and ((select private.has_permission('players.medical')) or (select private.is_guardian_of(player_id))));

create policy pdocs_read on player_documents for select to authenticated
  using (club_id = (select private.current_club_id())
         and ((select private.has_permission('players.docs'))
              or (select private.is_guardian_of(player_id)) or (select private.is_self_player(player_id))));
create policy pdocs_ins on player_documents for insert to authenticated
  with check (club_id = (select private.current_club_id()) and uploaded_by = (select auth.uid())
         and ((select private.has_permission('players.docs'))
              or (select private.is_guardian_of(player_id)) or (select private.is_self_player(player_id))));
create policy pdocs_upd on player_documents for update to authenticated       -- verification is staff-only
  using (club_id = (select private.current_club_id()) and (select private.has_permission('players.docs')))
  with check (club_id = (select private.current_club_id()) and (select private.has_permission('players.docs')));
create policy pdocs_del on player_documents for delete to authenticated
  using (club_id = (select private.current_club_id())
         and ((select private.has_permission('players.docs')) or (uploaded_by = (select auth.uid()) and status = 'pending')));

create policy idv_read on identity_verifications for select to authenticated
  using (club_id = (select private.current_club_id())
         and ((select private.has_permission('members.approve'))
              or profile_id = (select auth.uid())
              or (player_id is not null and ((select private.is_guardian_of(player_id)) or (select private.is_self_player(player_id))))));
create policy idv_ins on identity_verifications for insert to authenticated
  with check (club_id = (select private.current_club_id()) and status = 'pending'
         and (profile_id = (select auth.uid())
              or (player_id is not null and ((select private.is_guardian_of(player_id)) or (select private.is_self_player(player_id))))));
create policy idv_review on identity_verifications for update to authenticated
  using (club_id = (select private.current_club_id()) and (select private.has_permission('members.approve')))
  with check (club_id = (select private.current_club_id()) and (select private.has_permission('members.approve')));

-- ---- squads & jerseys --------------------------------------------------------
call private.pol_club_read('squads',      'squads.write');
call private.pol_club_read('squad_staff', 'squads.write');
call private.pol_club_read('jersey_reservations', 'jerseys.manage');

create policy memberships_read on squad_memberships for select to authenticated
  using ((select private.can_read_player(player_id)));
create policy memberships_write on squad_memberships for all to authenticated
  using (club_id = (select private.current_club_id()) and (select private.has_permission('squads.write')))
  with check (club_id = (select private.current_club_id()) and (select private.has_permission('squads.write')));

create policy pjersey_read on player_jersey_numbers for select to authenticated
  using ((select private.can_read_player(player_id)));
create policy pjersey_write on player_jersey_numbers for all to authenticated
  using (club_id = (select private.current_club_id()) and (select private.has_permission('jerseys.manage')))
  with check (club_id = (select private.current_club_id()) and (select private.has_permission('jerseys.manage')));

-- ---- compliance --------------------------------------------------------------
call private.pol_staff('competitions',          'compliance.read', 'compliance.write');
call private.pol_staff('squad_competitions',    'compliance.read', 'compliance.write');
call private.pol_staff('competition_deadlines', 'compliance.read', 'compliance.write');
call private.pol_staff('fine_rules',            'compliance.read', 'compliance.write');
call private.pol_staff('fines',                 'compliance.read', 'compliance.write');
call private.pol_staff('checklist_items',       'compliance.read', 'compliance.write');
-- coaches may read the checklist definitions
create policy checklist_items_coach_read on checklist_items for select to authenticated
  using (club_id = (select private.current_club_id()) and (select private.has_role('coach')));

-- ---- scheduling -----------------------------------------------------------------
create policy events_read on events for select to authenticated
  using (club_id = (select private.current_club_id())
         and ((select private.has_permission('schedule.write'))
              or (select private.is_squad_staff(squad_id))
              or exists (select 1 from squad_memberships sm      -- RLS-filtered: only my own / my children's rows
                         where sm.squad_id = events.squad_id and sm.left_on is null)));
create policy events_write on events for all to authenticated
  using (club_id = (select private.current_club_id()) and (select private.can_manage_squad(squad_id)))
  with check (club_id = (select private.current_club_id()) and (select private.can_manage_squad(squad_id)));

create policy matches_read on matches for select to authenticated
  using (exists (select 1 from events e where e.id = matches.event_id));      -- inherits events RLS
create policy matches_write on matches for all to authenticated
  using (club_id = (select private.current_club_id())
         and exists (select 1 from events e where e.id = matches.event_id and (select private.can_manage_squad(e.squad_id))))
  with check (club_id = (select private.current_club_id())
         and exists (select 1 from events e where e.id = matches.event_id and (select private.can_manage_squad(e.squad_id))));

create policy participants_read on event_participants for select to authenticated
  using ((select private.can_read_player(player_id)));
create policy participants_write on event_participants for all to authenticated   -- coach marks attendance; RSVP goes through set_rsvp()
  using (club_id = (select private.current_club_id())
         and exists (select 1 from events e where e.id = event_participants.event_id and (select private.can_manage_squad(e.squad_id))))
  with check (club_id = (select private.current_club_id())
         and exists (select 1 from events e where e.id = event_participants.event_id and (select private.can_manage_squad(e.squad_id))));

-- match sheet + checklists: staff of that squad only (families do not see other children's sheet rows)
create policy msheet_players_rw on match_sheet_players for all to authenticated
  using (club_id = (select private.current_club_id())
         and exists (select 1 from events e where e.id = match_sheet_players.match_id and (select private.can_manage_squad(e.squad_id))))
  with check (club_id = (select private.current_club_id())
         and exists (select 1 from events e where e.id = match_sheet_players.match_id and (select private.can_manage_squad(e.squad_id))));
create policy msheet_staff_rw on match_sheet_staff for all to authenticated
  using (club_id = (select private.current_club_id())
         and exists (select 1 from events e where e.id = match_sheet_staff.match_id and (select private.can_manage_squad(e.squad_id))))
  with check (club_id = (select private.current_club_id())
         and exists (select 1 from events e where e.id = match_sheet_staff.match_id and (select private.can_manage_squad(e.squad_id))));
create policy checklists_rw on matchday_checklists for all to authenticated
  using (club_id = (select private.current_club_id())
         and exists (select 1 from events e where e.id = matchday_checklists.match_id and (select private.can_manage_squad(e.squad_id))))
  with check (club_id = (select private.current_club_id())
         and exists (select 1 from events e where e.id = matchday_checklists.match_id and (select private.can_manage_squad(e.squad_id))));
create policy checklist_results_rw on matchday_checklist_results for all to authenticated
  using (exists (select 1 from matchday_checklists c where c.id = matchday_checklist_results.checklist_id))   -- inherits
  with check (club_id = (select private.current_club_id())
         and exists (select 1 from matchday_checklists c where c.id = matchday_checklist_results.checklist_id));

create policy notifications_own on notifications for select to authenticated
  using (recipient_id = (select auth.uid()));
create policy notifications_mark_read on notifications for update to authenticated
  using (recipient_id = (select auth.uid())) with check (recipient_id = (select auth.uid()));

-- ---- development & engagement -------------------------------------------------------
create policy ratings_read on player_ratings for select to authenticated
  using ((select private.can_read_player(player_id)));
create policy ratings_ins on player_ratings for insert to authenticated
  with check (club_id = (select private.current_club_id()) and rated_by = (select auth.uid())
              and (select private.is_coach_of_player(player_id)));
create policy ratings_own on player_ratings for update to authenticated
  using (rated_by = (select auth.uid())) with check (rated_by = (select auth.uid()));
create policy ratings_del on player_ratings for delete to authenticated
  using (rated_by = (select auth.uid()));
create policy rscores_read on player_rating_scores for select to authenticated
  using (exists (select 1 from player_ratings r where r.id = player_rating_scores.rating_id));   -- inherits
create policy rscores_write on player_rating_scores for all to authenticated
  using (exists (select 1 from player_ratings r where r.id = player_rating_scores.rating_id and r.rated_by = (select auth.uid())))
  with check (club_id = (select private.current_club_id())
              and exists (select 1 from player_ratings r where r.id = player_rating_scores.rating_id and r.rated_by = (select auth.uid())));

create policy drills_read on drills for select to authenticated
  using (club_id is null or club_id = (select private.current_club_id()));
create policy drills_write on drills for all to authenticated
  using (club_id = (select private.current_club_id()) and (select private.has_permission('drills.write')))
  with check (club_id = (select private.current_club_id()) and (select private.has_permission('drills.write')));
create policy drills_platform_write on drills for all to authenticated
  using (club_id is null and (select private.is_platform_owner()))
  with check (club_id is null and (select private.is_platform_owner()));

create policy assignments_read on drill_assignments for select to authenticated
  using ((select private.can_read_player(player_id)));
create policy assignments_ins on drill_assignments for insert to authenticated
  with check (club_id = (select private.current_club_id()) and assigned_by = (select auth.uid())
              and (select private.is_coach_of_player(player_id)));
create policy assignments_upd on drill_assignments for update to authenticated
  using (club_id = (select private.current_club_id()) and (select private.is_coach_of_player(player_id)))
  with check (club_id = (select private.current_club_id()) and (select private.is_coach_of_player(player_id)));
create policy assignments_del on drill_assignments for delete to authenticated
  using (club_id = (select private.current_club_id()) and (select private.is_coach_of_player(player_id)));

create policy completions_read on drill_completions for select to authenticated
  using (exists (select 1 from drill_assignments a where a.id = drill_completions.assignment_id));   -- inherits
create policy completions_ins on drill_completions for insert to authenticated
  with check (club_id = (select private.current_club_id()) and logged_by = (select auth.uid())
    and exists (select 1 from drill_assignments a where a.id = drill_completions.assignment_id
                and ((select private.is_self_player(a.player_id)) or (select private.is_guardian_of(a.player_id))
                     or (select private.is_coach_of_player(a.player_id)))));
create policy completions_coach_upd on drill_completions for update to authenticated   -- coach feedback
  using (exists (select 1 from drill_assignments a where a.id = drill_completions.assignment_id
                 and (select private.is_coach_of_player(a.player_id))))
  with check (exists (select 1 from drill_assignments a where a.id = drill_completions.assignment_id
                 and (select private.is_coach_of_player(a.player_id))));

-- achievements / streaks: readable by the child, their guardians and coaches. NO cross-player read path exists.
create policy achievements_read on player_achievements for select to authenticated
  using ((select private.can_read_player(player_id)));
create policy streaks_read on player_streaks for select to authenticated
  using ((select private.can_read_player(player_id)));

-- ---- messaging & safety -------------------------------------------------------------------
create policy conversations_read on conversations for select to authenticated
  using ((select private.in_conversation(id))
         or ((select private.has_permission('safeguarding.review')) and club_id = (select private.current_club_id())
             and exists (select 1 from messages m join message_reports r on r.message_id = m.id
                         where m.conversation_id = conversations.id)));
create policy participants_conv_read on conversation_participants for select to authenticated
  using ((select private.in_conversation(conversation_id))
         or ((select private.has_permission('safeguarding.review')) and club_id = (select private.current_club_id())));
create policy participants_mark_read on conversation_participants for update to authenticated
  using (profile_id = (select auth.uid())) with check (profile_id = (select auth.uid()));

create policy messages_read on messages for select to authenticated
  using (club_id = (select private.current_club_id())
         and (((select private.in_conversation(conversation_id)) and hidden_at is null)
              or ((select private.has_permission('safeguarding.review'))
                  and exists (select 1 from message_reports r where r.message_id = messages.id))));
create policy messages_send on messages for insert to authenticated
  with check (club_id = (select private.current_club_id()) and sender_id = (select auth.uid())
              and (select private.in_conversation(conversation_id)));
-- no update / delete policy: messages are append-only

create policy reports_read on message_reports for select to authenticated
  using (club_id = (select private.current_club_id())
         and ((select private.has_permission('safeguarding.review')) or reported_by = (select auth.uid())));

-- ---- payments ----------------------------------------------------------------------------------
call private.pol_staff('payment_gateways', 'gateways.manage', 'gateways.manage');
call private.pol_staff('fee_plans',        'fees.read',       'fees.write');

create policy charges_read on player_charges for select to authenticated
  using (club_id = (select private.current_club_id())
         and ((select private.has_permission('fees.read'))
              or (select private.is_guardian_of(player_id)) or (select private.is_self_adult(player_id))));
create policy charges_ins on player_charges for insert to authenticated
  with check (club_id = (select private.current_club_id()) and (select private.has_permission('fees.write')));
create policy charges_upd on player_charges for update to authenticated
  using (club_id = (select private.current_club_id()) and (select private.has_permission('fees.write')))
  with check (club_id = (select private.current_club_id()) and (select private.has_permission('fees.write')));

create policy payments_read on payments for select to authenticated
  using (exists (select 1 from player_charges c where c.id = payments.charge_id));       -- inherits charge visibility
create policy payments_offline_ins on payments for insert to authenticated              -- staff recording cash / bank transfer
  with check (club_id = (select private.current_club_id()) and (select private.has_permission('fees.write'))
              and method in ('cash','bank_transfer') and recorded_by = (select auth.uid()));
-- online card / wallet payments are written only by the payment Edge Function (service role);
-- payment_webhook_events has NO policy at all.

-- ---- media -----------------------------------------------------------------------------------------
create policy media_read on media_assets for select to authenticated
  using (club_id = (select private.current_club_id())
         and ((select private.has_permission('media.moderate')) or uploaded_by = (select auth.uid())
              or (squad_id is not null and (select private.is_squad_staff(squad_id)))
              or (state = 'approved' and visibility = 'club')
              or (state = 'approved' and visibility = 'squad'
                  and exists (select 1 from squad_memberships sm where sm.squad_id = media_assets.squad_id and sm.left_on is null))));
create policy media_ins on media_assets for insert to authenticated
  with check (club_id = (select private.current_club_id()) and uploaded_by = (select auth.uid())
              and ((select private.has_permission('media.moderate')) or (squad_id is not null and (select private.is_squad_staff(squad_id)))));
create policy media_upd on media_assets for update to authenticated
  using (club_id = (select private.current_club_id()) and ((select private.has_permission('media.moderate')) or uploaded_by = (select auth.uid())))
  with check (club_id = (select private.current_club_id()) and ((select private.has_permission('media.moderate')) or uploaded_by = (select auth.uid())));
create policy media_del on media_assets for delete to authenticated
  using (club_id = (select private.current_club_id()) and ((select private.has_permission('media.moderate')) or uploaded_by = (select auth.uid())));

create policy tags_read on media_player_tags for select to authenticated
  using ((select private.can_read_player(player_id)));
create policy tags_write on media_player_tags for all to authenticated
  using (club_id = (select private.current_club_id())
         and exists (select 1 from media_assets a where a.id = media_player_tags.asset_id
                     and ((select private.has_permission('media.moderate')) or a.uploaded_by = (select auth.uid()))))
  with check (club_id = (select private.current_club_id())
         and exists (select 1 from media_assets a where a.id = media_player_tags.asset_id
                     and ((select private.has_permission('media.moderate')) or a.uploaded_by = (select auth.uid()))));

-- ---- staff HR ----------------------------------------------------------------------------------------------
create policy staff_profiles_read on staff_profiles for select to authenticated
  using (profile_id = (select auth.uid())
         or (club_id = (select private.current_club_id()) and (select private.has_permission('staff.read'))));
create policy staff_profiles_write on staff_profiles for all to authenticated
  using (club_id = (select private.current_club_id()) and (select private.has_permission('staff.write')))
  with check (club_id = (select private.current_club_id()) and (select private.has_permission('staff.write')));

create policy staff_docs_read on staff_documents for select to authenticated
  using (profile_id = (select auth.uid())
         or (club_id = (select private.current_club_id()) and (select private.has_permission('staff.docs'))));
create policy staff_docs_ins on staff_documents for insert to authenticated
  with check (club_id = (select private.current_club_id()) and status = 'pending'
              and (profile_id = (select auth.uid()) or (select private.has_permission('staff.docs'))));
create policy staff_docs_verify on staff_documents for update to authenticated
  using (club_id = (select private.current_club_id()) and (select private.has_permission('staff.docs')))
  with check (club_id = (select private.current_club_id()) and (select private.has_permission('staff.docs')));
create policy staff_docs_del on staff_documents for delete to authenticated
  using (club_id = (select private.current_club_id())
         and ((select private.has_permission('staff.docs')) or (profile_id = (select auth.uid()) and status = 'pending')));

create policy staff_reqs_read on staff_doc_requirements for select to authenticated
  using (club_id = (select private.current_club_id()));
create policy staff_reqs_write on staff_doc_requirements for all to authenticated
  using (club_id = (select private.current_club_id()) and (select private.has_permission('staff.write')))
  with check (club_id = (select private.current_club_id()) and (select private.has_permission('staff.write')));

-- ---- data control, audit, integrations ------------------------------------------------------------------------
create policy deletion_read on data_deletion_requests for select to authenticated
  using (requested_by = (select auth.uid())
         or (club_id = (select private.current_club_id()) and (select private.has_permission('roles.manage'))));
-- no client write policy: request_data_deletion() / cancel_data_deletion()

create policy audit_read on audit_log for select to authenticated
  using (club_id = (select private.current_club_id()) and (select private.has_permission('audit.read')));

create policy integ_conn_rw on integration_connections for all to authenticated
  using (club_id = (select private.current_club_id()) and (select private.has_permission('integrations.manage')))
  with check (club_id = (select private.current_club_id()) and (select private.has_permission('integrations.manage')));
create policy integ_refs_read on external_refs for select to authenticated
  using (club_id = (select private.current_club_id()) and (select private.has_permission('integrations.manage')));
create policy integ_jobs_read on integration_jobs for select to authenticated
  using (club_id = (select private.current_club_id()) and (select private.has_permission('integrations.manage')));

-- ---- THE CHILD GATE (restrictive; ANDed with everything above) ---------------------------------------------------
call private.pol_child_gate('squad_memberships',       'player_id');
call private.pol_child_gate('player_jersey_numbers',   'player_id');
call private.pol_child_gate('player_medical',          'player_id');
call private.pol_child_gate('player_documents',        'player_id');
call private.pol_child_gate('identity_verifications',  'player_id');
call private.pol_child_gate('event_participants',      'player_id');
call private.pol_child_gate('match_sheet_players',     'player_id');
call private.pol_child_gate('player_ratings',          'player_id');
call private.pol_child_gate('drill_assignments',       'player_id');
call private.pol_child_gate('player_achievements',     'player_id');
call private.pol_child_gate('player_streaks',          'player_id');
call private.pol_child_gate('media_player_tags',       'player_id');
call private.pol_child_gate('conversations',           'player_id');
call private.pol_child_gate('player_charges',          'player_id', 'insert');   -- no NEW billing for a child without consent

drop procedure private.pol_staff(text, text, text);
drop procedure private.pol_club_read(text, text);
drop procedure private.pol_platform_ref(text);
drop procedure private.pol_child_gate(text, text, text);

-- functions created above must stay callable by policies
grant execute on all functions in schema private to authenticated, service_role;
