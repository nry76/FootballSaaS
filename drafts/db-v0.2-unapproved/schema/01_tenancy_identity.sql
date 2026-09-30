-- =====================================================================
-- 01_tenancy_identity.sql — clubs (tenants), SaaS billing, accounts, roles
--
-- TENANCY RULES (apply to every table in this schema)
--   1. Every tenant-owned table has `club_id uuid not null`.
--   2. Every parent table exposes UNIQUE (club_id, id) and children reference
--      it with a COMPOSITE FK (club_id, parent_id). The database itself then
--      refuses a row that points at another club's data, even if app code or
--      a policy has a bug.
--   3. RLS is enabled on every table (see 11_rls.sql).
--   4. One account per club: profiles.club_id is a single NOT NULL column.
-- =====================================================================

-- ---- platform layer (not tenant-scoped) ------------------------------
create table platform_plans (
  id                 uuid primary key default gen_random_uuid(),
  code               text not null unique,               -- 'starter','club','academy'
  name               text not null,
  monthly_price_fils bigint not null check (monthly_price_fils >= 0),
  max_players        integer check (max_players > 0),    -- null = unlimited
  features           jsonb not null default '{}'::jsonb,
  active             boolean not null default true
);

create table platform_staff (
  user_id       uuid primary key references auth.users(id) on delete cascade,
  platform_role platform_role not null default 'support',
  created_at    timestamptz not null default now()
);
comment on table platform_staff is
  'Platform owner / support. Deliberately NOT a club role: platform staff have no default access to any club''s player data (see support_access_grants).';

-- ---- tenants ----------------------------------------------------------
create table clubs (
  id             uuid primary key default gen_random_uuid(),
  name           text not null,
  name_ar        text,
  slug           text not null unique check (slug ~ '^[a-z0-9-]{3,40}$'),
  emirate        text,                                    -- 'abu_dhabi','dubai',...
  country        char(2) not null default 'AE',
  timezone       text not null default 'Asia/Dubai',
  default_locale text not null default 'en' check (default_locale in ('en','ar')),
  tax_reg_number text,                                    -- UAE TRN for VAT invoices
  status         club_status not null default 'trial',
  created_at     timestamptz not null default now()
);

create table club_subscriptions (           -- what the club pays US (the SaaS fee)
  club_id              uuid primary key references clubs(id) on delete cascade,
  plan_id              uuid not null references platform_plans(id),
  status               club_status not null default 'trial',
  current_period_start date,
  current_period_end   date,
  billing_email        citext,
  external_customer_ref text                              -- our own billing provider's id
);

create table platform_invoices (
  id           uuid primary key default gen_random_uuid(),
  club_id      uuid not null references clubs(id) on delete cascade,
  amount_fils  bigint not null check (amount_fils >= 0),
  currency     char(3) not null default 'AED',
  issued_on    date not null default current_date,
  paid_on      date,
  external_ref text
);

-- ---- accounts ---------------------------------------------------------
-- One row per auth user per club. Supabase auth emails are globally unique,
-- so "one account per club" means one email per club (see docs/OPEN_QUESTIONS.md).
-- profiles.id = auth.users.id. There is intentionally NO foreign key to auth.users:
-- when a person erases their account we delete the auth user (credentials, email)
-- but keep a scrubbed "tombstone" profile so attribution columns (rated_by,
-- created_by, ...) and audit history stay valid. Rows are created only by the
-- invite / sign-up Edge Function (service role); clients cannot insert profiles.
create table profiles (
  id              uuid primary key,
  club_id         uuid not null references clubs(id) on delete cascade,
  full_name       text not null,
  full_name_ar    text,
  email           citext not null,
  phone           text,
  locale          text not null default 'en' check (locale in ('en','ar')),
  approval_status approval_status not null default 'pending',
  approved_by     uuid,
  approved_at     timestamptz,
  created_at      timestamptz not null default now(),
  unique (club_id, id),
  unique (club_id, email)
);
comment on column profiles.approval_status is
  'Gate: RLS treats any non-approved profile as having NO club access (private.current_club_id() returns null).';

-- Roles are a SET per profile so a small-club owner can be manager + admin
-- (+ coach, + parent) without a hardcoded single role.
create table role_permissions (             -- platform-static mapping, seeded in 13_seed.sql
  role       role_key not null,
  permission text not null,
  primary key (role, permission)
);

create table profile_roles (
  profile_id uuid not null,
  club_id    uuid not null,
  role       role_key not null,
  granted_by uuid,
  granted_at timestamptz not null default now(),
  primary key (profile_id, role),
  foreign key (club_id, profile_id) references profiles(club_id, id) on delete cascade
);
create index on profile_roles (club_id);

create table seasons (
  id        uuid primary key default gen_random_uuid(),
  club_id   uuid not null references clubs(id) on delete cascade,
  name      text not null,                     -- '2026/27'
  starts_on date not null,
  ends_on   date not null,
  age_cutoff_date date not null,               -- date on which a player's age group is fixed
  is_current boolean not null default false,
  check (ends_on > starts_on),
  unique (club_id, id),
  unique (club_id, name)
);
create unique index one_current_season_per_club on seasons (club_id) where is_current;

-- Time-boxed, club-approved window for platform support to see tenant data.
create table support_access_grants (
  id           uuid primary key default gen_random_uuid(),
  club_id      uuid not null references clubs(id) on delete cascade,
  platform_user_id uuid not null references platform_staff(user_id) on delete cascade,
  granted_by   uuid not null,
  reason       text not null,
  expires_at   timestamptz not null,
  revoked_at   timestamptz,
  created_at   timestamptz not null default now(),
  check (expires_at <= created_at + interval '7 days'),
  foreign key (club_id, granted_by) references profiles(club_id, id)
);
