-- =====================================================================
-- 02_players_consent.sql — players, guardians, parental consent, verification
--
-- CHILD-SAFETY MODEL (hard requirement, enforced in DB, not in the UI)
--   * Age tiers, computed from date_of_birth (Asia/Dubai date):
--       under 13 : NO login. A guardian acts for the child. players.profile_id must be null.
--       13 - 17  : own login allowed, but only once verified parental consent is granted.
--       18+      : adult, manages own account.
--   * A player under 18 starts as status='pending_consent'. Until a
--     'data_processing' consent is GRANTED, private.is_processing_allowed()
--     is false and RESTRICTIVE RLS policies (11_rls.sql) block writing or
--     reading every player-linked table (ratings, attendance, media, medical,
--     messages, ...). Only the minimum needed to send the consent email
--     exists: first name, DOB, guardian name + email.
--   * Consent is granted ONLY by following a single-use link emailed directly
--     to the guardian's address. The link token is stored hashed. Clients can
--     never write consent status; an Edge Function (service role) does it.
-- =====================================================================

create table players (
  id             uuid primary key default gen_random_uuid(),
  club_id        uuid not null references clubs(id) on delete cascade,
  profile_id     uuid unique,                          -- player's OWN login (13+ only), else null
  first_name     text not null,
  last_name      text not null,
  first_name_ar  text,
  last_name_ar   text,
  date_of_birth  date not null,
  gender         text check (gender in ('male','female')),
  nationality    char(2),
  position_group position_group,                       -- drives goalkeeper-only jersey ranges
  status         player_status not null default 'pending_consent',
  engagement_enabled boolean not null default true,    -- guardian can switch streaks/badges off
  created_by     uuid,
  created_at     timestamptz not null default now(),
  anonymized_at  timestamptz,
  unique (club_id, id),
  foreign key (club_id, profile_id) references profiles(club_id, id) on delete set null (profile_id)
);
create index on players (club_id, status);
comment on column players.profile_id is
  'Set only for players 13+ with granted consent; enforced by trigger private.trg_player_login_rules().';

-- Guardians are people, not only accounts: the consent email goes to an
-- address that may not have an account yet.
create table player_guardians (
  id            uuid primary key default gen_random_uuid(),
  club_id       uuid not null,
  player_id     uuid not null,
  profile_id    uuid,                                  -- set once the guardian has an account
  full_name     text not null,
  email         citext not null,
  phone         text,
  relationship  text not null default 'parent',
  is_primary    boolean not null default false,
  can_consent   boolean not null default true,         -- legal guardian who may consent
  can_pay       boolean not null default true,
  email_verified_at timestamptz,
  unique (club_id, id),
  unique (player_id, email),
  foreign key (club_id, player_id)  references players(club_id, id) on delete cascade,
  foreign key (club_id, profile_id) references profiles(club_id, id) on delete set null (profile_id)
);
create unique index one_primary_guardian on player_guardians (player_id) where is_primary;
create index on player_guardians (club_id, profile_id);

create table parental_consents (
  id              uuid primary key default gen_random_uuid(),
  club_id         uuid not null,
  player_id       uuid not null,
  guardian_id     uuid not null,
  type            consent_type not null default 'data_processing',
  status          consent_status not null default 'pending',
  policy_version  text not null,                       -- which privacy-notice text was shown
  sent_to_email   citext not null,                     -- snapshot of the address actually emailed
  token_hash      text not null unique,                -- sha256 of the emailed one-time token; raw token never stored
  sent_at         timestamptz not null default now(),
  expires_at      timestamptz not null default now() + interval '14 days',
  responded_at    timestamptz,
  revoked_at      timestamptz,
  response_ip     inet,
  response_user_agent text,
  created_by      uuid,
  unique (club_id, id),
  check (status <> 'granted' or responded_at is not null),
  check (status <> 'revoked' or revoked_at is not null),
  foreign key (club_id, player_id)   references players(club_id, id) on delete cascade,
  foreign key (club_id, guardian_id) references player_guardians(club_id, id)
);
-- at most one live (pending or granted) consent per player per type
create unique index one_live_consent on parental_consents (player_id, type) where status in ('pending','granted');
create index on parental_consents (club_id, status);

-- Sensitive health data: separate table, narrower RLS.
create table player_medical (
  player_id      uuid primary key,
  club_id        uuid not null,
  allergies      text,
  conditions     text,
  medications    text,
  emergency_contact_name  text,
  emergency_contact_phone text,
  updated_at     timestamptz not null default now(),
  updated_by     uuid,
  foreign key (club_id, player_id) references players(club_id, id) on delete cascade
);

create table player_documents (
  id           uuid primary key default gen_random_uuid(),
  club_id      uuid not null,
  player_id    uuid not null,
  kind         player_doc_kind not null,
  storage_path text not null,                          -- private bucket, path starts with {club_id}/
  status       doc_status not null default 'pending',
  expires_on   date,
  verified_by  uuid,
  verified_at  timestamptz,
  uploaded_by  uuid,
  uploaded_at  timestamptz not null default now(),
  unique (club_id, id),
  foreign key (club_id, player_id) references players(club_id, id) on delete cascade
);
create index on player_documents (club_id, player_id, kind);

-- Photo + ID verification before a NEW staff or player account is approved.
create table identity_verifications (
  id            uuid primary key default gen_random_uuid(),
  club_id       uuid not null,
  kind          verification_kind not null,
  profile_id    uuid,                                  -- staff / guardian account being verified
  player_id     uuid,                                  -- player being verified
  status        verification_status not null default 'pending',
  id_doc_path   text,                                  -- private bucket
  selfie_path   text,                                  -- private bucket
  provider      text,                                  -- e.g. third-party eKYC, or 'manual'
  provider_ref  text,
  submitted_at  timestamptz not null default now(),
  reviewed_by   uuid,
  reviewed_at   timestamptz,
  rejection_reason text,
  purge_after   timestamptz,                           -- images deleted after decision + retention window
  check ((profile_id is not null)::int + (player_id is not null)::int = 1),
  foreign key (club_id, profile_id) references profiles(club_id, id) on delete cascade,
  foreign key (club_id, player_id)  references players(club_id, id) on delete cascade
);
create index on identity_verifications (club_id, status);
