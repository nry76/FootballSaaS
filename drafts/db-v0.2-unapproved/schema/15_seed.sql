-- =====================================================================
-- 15_seed.sql — platform-level reference data (safe to commit; no secrets)
-- The UAE FA template values below are ILLUSTRATIVE, taken from the product
-- brief. Verify against the current league regulations before go-live.
-- =====================================================================

-- ---- permissions ------------------------------------------------------------
-- manager = everything. admin = day-to-day operations. coach = squad-scoped
-- features (squad scope is enforced by relationship policies, not by permission).
insert into role_permissions (role, permission)
select 'manager'::role_key, p from unnest(array[
  'club.settings','billing.manage','roles.manage','members.read','members.approve',
  'players.read','players.write','players.docs','players.medical',
  'squads.write','jerseys.manage','schedule.write','compliance.read','compliance.write',
  'fees.read','fees.write','gateways.manage','analytics.read','media.moderate',
  'staff.read','staff.write','staff.docs','safeguarding.review','audit.read',
  'integrations.manage','drills.write']) p
union all
select 'admin'::role_key, p from unnest(array[
  'members.read','members.approve','players.read','players.write','players.docs','players.medical',
  'squads.write','jerseys.manage','schedule.write','compliance.read','compliance.write',
  'fees.read','fees.write','analytics.read','media.moderate','staff.read','staff.docs','drills.write']) p
union all
select 'coach'::role_key, 'drills.write';

-- ---- example SaaS plans (prices are placeholders) -------------------------------
insert into platform_plans (code, name, monthly_price_fils, max_players) values
  ('starter','Starter',      0,      60),
  ('club',   'Club',    150000,     300),
  ('academy','Academy', 400000,    null);

-- ---- UAE FA template (ILLUSTRATIVE) -----------------------------------------------
insert into tpl_competitions (code, name, name_ar, age_group, min_squad_size)
values ('uaefa-youth-league-illustrative', 'UAE FA Youth League (U10/U12) — template', null, 'U10-U12', 11);

with c as (select id from tpl_competitions where code = 'uaefa-youth-league-illustrative')
insert into tpl_fine_rules (tpl_competition_id, kind, basis, amount_fils, description)
select c.id, k, b, a, d from c, (values
  ('incomplete_squad'::fine_kind,      'per_player'::fine_basis,    100000::bigint, 'AED 1,000 per missing player'),
  ('cancelled_match',                  'per_match',                 1000000,        'AED 10,000 per cancelled match'),
  ('missing_medical_staff',            'per_occurrence',            200000,         'AED 2,000 each time medical staff is missing from the match sheet')
) v(k, b, a, d);

with c as (select id from tpl_competitions where code = 'uaefa-youth-league-illustrative')
insert into tpl_checklist_items (tpl_competition_id, code, title, check_type, params, blocking, sort_order)
select c.id, code, title, ct, params::jsonb, blocking, so from c, (values
  ('squad_complete',  'Squad complete (minimum players on match sheet)', 'squad_size'::checklist_check, '{}',                                   true, 10),
  ('medical_staff',   'Medical staff listed on match sheet',             'medical_staff_listed',        '{"min_staff":1}',                     true, 20),
  ('player_docs',     'Player documents on file (ID + photo)',           'player_documents_on_file',    '{"doc_kinds":["emirates_id","photo"]}', true, 30),
  ('staff_certs',     'Coaching licence valid for listed staff',         'staff_certs_valid',           '{"doc_kinds":["coaching_licence"]}',  false, 40)
) v(code, title, ct, params, blocking, so);

with c as (select id from tpl_competitions where code = 'uaefa-youth-league-illustrative')
insert into tpl_deadlines (tpl_competition_id, kind, title, offset_minutes_before_kickoff)
select c.id, 'matchday_sheet', 'Match sheet submission (illustrative: 120 min before kickoff)', 120 from c;

-- ---- gentle achievements ---------------------------------------------------------------
insert into achievement_defs (code, kind, title, description, threshold) values
  ('att_4w',   'attendance_streak', 'Showing up',        'Attended training 4 weeks in a row',  4),
  ('att_8w',   'attendance_streak', 'Regular',           'Attended training 8 weeks in a row',  8),
  ('drill_3w', 'drill_streak',      'Practice habit',    'Did a drill every week for 3 weeks',  3),
  ('drills_10','drills_completed',  'Ten drills',        'Completed 10 drills',                 10),
  ('pb_any',   'personal_best',     'New personal best', 'Beat your own best on a drill',       null);
