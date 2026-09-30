-- =====================================================================
-- 00_types.sql — extensions, schemas, enums
-- Target: Supabase Postgres (15+). Money is stored in fils (1 AED = 100 fils)
-- as bigint, never as float.
-- =====================================================================
-- Supabase keeps extensions in the `extensions` schema (already on the search_path).
create schema if not exists extensions;
create extension if not exists citext   with schema extensions;
create extension if not exists pgcrypto with schema extensions;

-- `private` holds helper functions used by RLS policies. It is NOT exposed
-- through the Supabase API (only `public` is), so helpers cannot be called
-- as RPC by clients. Callable RPCs live in `public` and are listed in 09.
create schema if not exists private;

-- ---- identity / access ------------------------------------------------
create type role_key          as enum ('manager','admin','coach','player','parent');
create type approval_status   as enum ('pending','approved','rejected','suspended');
create type platform_role     as enum ('owner','support');
create type club_status       as enum ('trial','active','past_due','suspended','closed');

-- ---- players / consent ------------------------------------------------
create type player_status     as enum ('pending_consent','pending_verification','active','inactive','archived','erased');
create type position_group    as enum ('goalkeeper','defender','midfielder','forward');
create type consent_type      as enum ('data_processing','messaging','media');
create type consent_status    as enum ('pending','granted','declined','revoked','expired');
create type verification_kind as enum ('staff','player','guardian');
create type verification_status as enum ('pending','approved','rejected','expired');
create type doc_status        as enum ('pending','verified','rejected','expired');
create type player_doc_kind   as enum ('emirates_id','passport','birth_certificate','photo','medical_clearance','fa_registration','other');
create type staff_doc_kind    as enum ('emirates_id','passport','visa','coaching_licence','first_aid_cert','safeguarding_cert','background_check','medical_licence','contract','other');

-- ---- squads / scheduling ---------------------------------------------
create type squad_staff_role  as enum ('head_coach','assistant_coach','goalkeeper_coach','team_manager','medical');
create type membership_type   as enum ('primary','playing_up','playing_down');
create type jersey_reserve_reason as enum ('retired','goalkeeper','staff_hold','other');
create type event_type        as enum ('training','match','other');
create type event_status      as enum ('scheduled','cancelled','completed');
create type rsvp_status       as enum ('no_response','going','not_going','maybe');
create type attendance_status as enum ('present','late','absent','excused');

-- ---- compliance -------------------------------------------------------
create type deadline_kind     as enum ('registration','squad_list','transfer_window','document_upload','fee_payment','matchday_sheet','other');
create type deadline_status   as enum ('open','done','missed','waived');
create type fine_kind         as enum ('incomplete_squad','cancelled_match','missing_medical_staff','other');
create type fine_basis        as enum ('per_player','per_match','per_occurrence');
create type fine_status       as enum ('at_risk','issued','appealed','paid','waived');
create type checklist_check   as enum ('squad_size','medical_staff_listed','player_documents_on_file','staff_certs_valid','manual');
create type check_state       as enum ('pending','pass','fail','waived');
create type checklist_status  as enum ('open','ready','blocked','submitted');

-- ---- development / engagement ----------------------------------------
create type rating_pillar     as enum ('technical','physical','tactical','decision_making','personality_creativity');
create type assignment_status as enum ('assigned','in_progress','completed','skipped');
create type achievement_kind  as enum ('attendance_streak','drill_streak','drills_completed','personal_best','season_milestone');

-- ---- messaging / safety ----------------------------------------------
create type conversation_kind as enum ('coach_player','coach_parent','squad_announcement');
create type report_reason     as enum ('bullying','inappropriate_content','contact_outside_app','pressure_or_threats','other');
create type report_status     as enum ('open','under_review','actioned','dismissed');

-- ---- payments ---------------------------------------------------------
create type charge_kind       as enum ('membership','academy','match_fee','kit_deposit','other');
create type charge_status     as enum ('due','part_paid','paid','waived','void');   -- "overdue" is DERIVED, see v_player_charge_status
create type fee_recurrence    as enum ('one_off','monthly','termly','seasonal');
create type payment_status    as enum ('pending','succeeded','failed','refunded');
create type payment_method    as enum ('card','apple_pay','google_pay','samsung_pay','bank_transfer','cash');
create type gateway_provider  as enum ('stripe','telr','tap','paytabs','checkout_com','other');
create type gateway_mode      as enum ('test','live');

-- ---- media / data control / misc -------------------------------------
create type media_kind        as enum ('photo','video');
create type media_visibility  as enum ('staff_only','squad','club');
create type media_state       as enum ('pending','approved','removed');
create type deletion_scope    as enum ('account_only','player_data','account_and_player_data');
create type deletion_status   as enum ('requested','cooling_off','processing','completed','cancelled');
create type notification_channel as enum ('in_app','email','push','sms');
create type job_status        as enum ('queued','running','succeeded','failed','cancelled');
