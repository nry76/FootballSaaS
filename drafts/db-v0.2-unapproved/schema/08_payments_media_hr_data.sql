-- =====================================================================
-- 08_payments_media_hr_data.sql — payments, media, staff HR, data control,
--                                 integrations (reserved), audit
-- =====================================================================

-- ---- payments ---------------------------------------------------------
-- Each club plugs in ITS OWN gateway account (decision: platform never holds
-- the money). SECRET KEYS ARE NEVER STORED IN THESE TABLES: store them in
-- Supabase Vault (vault.secrets) and keep only the secret's uuid here.
create table payment_gateways (
  id             uuid primary key default gen_random_uuid(),
  club_id        uuid not null references clubs(id) on delete cascade,
  provider       gateway_provider not null,
  mode           gateway_mode not null default 'test',
  display_name   text not null,
  publishable_key text,                                   -- safe to expose to browsers
  secret_ref     uuid,                                    -- vault.secrets.id of the secret API key
  webhook_secret_ref uuid,                                -- vault.secrets.id of the webhook signing secret
  is_default     boolean not null default false,
  active         boolean not null default true,
  verified_at    timestamptz,
  unique (club_id, id)
);
create unique index one_default_gateway on payment_gateways (club_id) where is_default;

create table fee_plans (                                   -- the club's price list
  id           uuid primary key default gen_random_uuid(),
  club_id      uuid not null references clubs(id) on delete cascade,
  kind         charge_kind not null,
  name         text not null,
  name_ar      text,
  amount_fils  bigint not null check (amount_fils >= 0),
  currency     char(3) not null default 'AED',
  vat_rate_bps integer not null default 0 check (vat_rate_bps between 0 and 10000),   -- 500 = 5%
  recurrence   fee_recurrence not null default 'one_off',
  refundable   boolean not null default false,             -- kit deposits
  active       boolean not null default true,
  unique (club_id, id)
);

create table player_charges (                              -- one invoice line per player
  id            uuid primary key default gen_random_uuid(),
  club_id       uuid not null,
  player_id     uuid not null,
  fee_plan_id   uuid,
  season_id     uuid,
  match_id      uuid,                                       -- for match fees
  kind          charge_kind not null,
  description   text not null,
  amount_fils   bigint not null check (amount_fils > 0),
  vat_fils      bigint not null default 0 check (vat_fils >= 0),
  currency      char(3) not null default 'AED',
  due_on        date not null,
  status        charge_status not null default 'due',
  amount_paid_fils bigint not null default 0 check (amount_paid_fils >= 0),
  waived_by     uuid,
  waived_reason text,
  created_by    uuid,
  created_at    timestamptz not null default now(),
  unique (club_id, id),
  check (status <> 'waived' or (waived_by is not null and waived_reason is not null)),
  foreign key (club_id, player_id)   references players(club_id, id),        -- RESTRICT: financial records outlive erasure (player is anonymised, not deleted)
  foreign key (club_id, fee_plan_id) references fee_plans(club_id, id) on delete set null (fee_plan_id),
  foreign key (club_id, season_id)   references seasons(club_id, id)   on delete set null (season_id),
  foreign key (club_id, match_id)    references matches(club_id, event_id) on delete set null (match_id)
);
create index on player_charges (club_id, player_id, status);
create index on player_charges (club_id, due_on) where status in ('due','part_paid');

create table payments (
  id             uuid primary key default gen_random_uuid(),
  club_id        uuid not null,
  charge_id      uuid not null,
  gateway_id     uuid,
  amount_fils    bigint not null check (amount_fils > 0),
  currency       char(3) not null default 'AED',
  method         payment_method not null,
  status         payment_status not null default 'pending',
  refund_of      uuid,                                     -- points at the original payment for a refund row
  gateway_reference text,                                  -- provider's charge / intent id
  idempotency_key text not null,
  paid_by        uuid,                                     -- guardian or adult player profile
  recorded_by    uuid,                                     -- staff, for cash / bank transfer
  initiated_at   timestamptz not null default now(),
  completed_at   timestamptz,
  failure_reason text,
  unique (club_id, id),
  unique (club_id, idempotency_key),
  check (method <> 'cash' or recorded_by is not null),
  foreign key (club_id, charge_id)  references player_charges(club_id, id),
  foreign key (club_id, gateway_id) references payment_gateways(club_id, id) on delete set null (gateway_id),
  foreign key (club_id, refund_of)  references payments(club_id, id)
);
create index on payments (club_id, charge_id);
create unique index payments_gateway_ref on payments (gateway_id, gateway_reference) where gateway_reference is not null;

-- Raw gateway webhooks: idempotent receipt log. Service-role only (no RLS policy).
create table payment_webhook_events (
  id             uuid primary key default gen_random_uuid(),
  club_id        uuid not null references clubs(id) on delete cascade,
  gateway_id     uuid not null,
  provider_event_id text not null,
  payload        jsonb not null,
  received_at    timestamptz not null default now(),
  processed_at   timestamptz,
  error          text,
  unique (gateway_id, provider_event_id),
  foreign key (club_id, gateway_id) references payment_gateways(club_id, id) on delete cascade
);

-- ---- media ------------------------------------------------------------
create table media_assets (
  id            uuid primary key default gen_random_uuid(),
  club_id       uuid not null,
  event_id      uuid,                                       -- "organised by game"
  squad_id      uuid,
  kind          media_kind not null,
  storage_path  text not null,
  thumbnail_path text,
  caption       text,
  visibility    media_visibility not null default 'staff_only',
  state         media_state not null default 'pending',
  uploaded_by   uuid not null,
  uploaded_at   timestamptz not null default now(),
  unique (club_id, id),
  foreign key (club_id, event_id)    references events(club_id, id) on delete set null (event_id),
  foreign key (club_id, squad_id)    references squads(club_id, id) on delete set null (squad_id),
  foreign key (club_id, uploaded_by) references profiles(club_id, id)
);
create index on media_assets (club_id, event_id);

-- Tagging a minor requires granted 'media' consent (trigger in 10_triggers.sql).
create table media_player_tags (
  asset_id  uuid not null,
  player_id uuid not null,
  club_id   uuid not null,
  primary key (asset_id, player_id),
  foreign key (club_id, asset_id)  references media_assets(club_id, id) on delete cascade,
  foreign key (club_id, player_id) references players(club_id, id) on delete cascade
);

-- ---- staff HR ---------------------------------------------------------
create table staff_profiles (
  profile_id  uuid primary key,
  club_id     uuid not null,
  job_title   text,
  employment_type text check (employment_type in ('full_time','part_time','contractor','volunteer')),
  start_date  date,
  end_date    date,
  is_medical  boolean not null default false,              -- may be listed as medical staff on a match sheet
  emergency_contact_name  text,
  emergency_contact_phone text,
  foreign key (club_id, profile_id) references profiles(club_id, id) on delete cascade
);

create table staff_documents (
  id           uuid primary key default gen_random_uuid(),
  club_id      uuid not null,
  profile_id   uuid not null,
  kind         staff_doc_kind not null,
  title        text,
  issuer       text,
  issued_on    date,
  expires_on   date,
  storage_path text not null,
  status       doc_status not null default 'pending',
  verified_by  uuid,
  verified_at  timestamptz,
  uploaded_at  timestamptz not null default now(),
  unique (club_id, id),
  foreign key (club_id, profile_id) references profiles(club_id, id) on delete cascade
);
create index on staff_documents (club_id, profile_id, kind);

create table staff_doc_requirements (                       -- what each role must hold; drives "own compliance record"
  club_id   uuid not null references clubs(id) on delete cascade,
  role      role_key not null,
  doc_kind  staff_doc_kind not null,
  required  boolean not null default true,
  primary key (club_id, role, doc_kind)
);

-- ---- data control -----------------------------------------------------
create table data_deletion_requests (
  id               uuid primary key default gen_random_uuid(),
  club_id          uuid not null,
  requested_by     uuid not null,                           -- the user (or a guardian on behalf of a child)
  subject_profile_id uuid,
  subject_player_id  uuid,
  scope            deletion_scope not null,
  status           deletion_status not null default 'cooling_off',
  requested_at     timestamptz not null default now(),
  cooling_off_until timestamptz not null default now() + interval '7 days',   -- self-serve undo window
  completed_at     timestamptz,
  cancelled_at     timestamptz,
  retained         jsonb not null default '{}'::jsonb,       -- what was legally retained (e.g. financial records) and why
  check ((subject_profile_id is not null) or (subject_player_id is not null)),
  foreign key (club_id, requested_by)       references profiles(club_id, id),
  foreign key (club_id, subject_profile_id) references profiles(club_id, id) on delete set null (subject_profile_id),
  foreign key (club_id, subject_player_id)  references players(club_id, id)
);

create table audit_log (
  id          bigint generated always as identity primary key,
  club_id     uuid,
  actor_id    uuid,
  actor_kind  text not null default 'user' check (actor_kind in ('user','system','platform_support')),
  action      text not null,
  entity      text not null,
  entity_id   text,
  at          timestamptz not null default now(),
  meta        jsonb not null default '{}'::jsonb              -- ids and field names only; NEVER personal data values
);
create index on audit_log (club_id, at desc);

-- ---- RESERVED: external integrations (FANet.ae document upload, later) --
-- Nothing reads or writes these yet. They exist so the later integration
-- needs no migration of core tables.
create table integration_connections (
  id             uuid primary key default gen_random_uuid(),
  club_id        uuid not null references clubs(id) on delete cascade,
  provider       text not null,                             -- 'fanet'
  status         text not null default 'disabled',
  config         jsonb not null default '{}'::jsonb,
  credential_ref uuid,                                       -- vault.secrets.id, never the credential itself
  unique (club_id, id),
  unique (club_id, provider)
);

create table external_refs (                                -- maps our rows to the outside system's ids
  club_id       uuid not null references clubs(id) on delete cascade,
  provider      text not null,
  entity        text not null,                              -- 'players','player_documents','matches',...
  entity_id     uuid not null,
  external_id   text not null,
  last_synced_at timestamptz,
  sync_status   text,
  primary key (provider, entity, entity_id)
);

create table integration_jobs (
  id            uuid primary key default gen_random_uuid(),
  club_id       uuid not null,
  connection_id uuid not null,
  kind          text not null,                              -- 'fanet_document_upload'
  payload       jsonb not null default '{}'::jsonb,
  status        job_status not null default 'queued',
  attempts      integer not null default 0,
  last_error    text,
  scheduled_for timestamptz not null default now(),
  foreign key (club_id, connection_id) references integration_connections(club_id, id) on delete cascade
);
