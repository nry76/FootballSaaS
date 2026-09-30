-- =====================================================================
-- 04_compliance_rules.sql — league rules: platform templates + club copies
--
-- TWO LAYERS
--   tpl_*  : maintained by the PLATFORM (UAE FA competitions, deadlines, fine
--            rules, checklist items). No club_id. Read-only to clubs.
--   the rest: club-owned COPIES made when a club subscribes to a template.
--            Clubs may edit or add rows. tpl_*_id remembers the origin and
--            tpl_competitions.version lets us tell a club "template updated".
--
-- Fine amounts in the brief (AED 1,000 / player, AED 10,000 / cancelled match,
-- AED 2,000 / missing medical) are DATA in tpl_fine_rules, never hardcoded.
-- =====================================================================

-- ---- platform templates ----------------------------------------------
create table tpl_competitions (
  id              uuid primary key default gen_random_uuid(),
  code            text not null unique,                -- 'uaefa-u12-2026'
  governing_body  text not null default 'UAE FA',
  name            text not null,
  name_ar         text,
  age_group       text,
  min_squad_size  integer check (min_squad_size > 0),
  version         integer not null default 1,
  active          boolean not null default true
);

create table tpl_deadlines (
  id                 uuid primary key default gen_random_uuid(),
  tpl_competition_id uuid not null references tpl_competitions(id) on delete cascade,
  kind               deadline_kind not null,
  title              text not null,
  title_ar           text,
  due_on             date,                              -- fixed calendar date, OR
  offset_minutes_before_kickoff integer,                -- relative to each match (matchday sheet)
  check ((due_on is not null) <> (offset_minutes_before_kickoff is not null))
);

create table tpl_fine_rules (
  id                 uuid primary key default gen_random_uuid(),
  tpl_competition_id uuid not null references tpl_competitions(id) on delete cascade,
  kind               fine_kind not null,
  basis              fine_basis not null,
  amount_fils        bigint not null check (amount_fils >= 0),
  currency           char(3) not null default 'AED',
  description        text
);

create table tpl_checklist_items (
  id                 uuid primary key default gen_random_uuid(),
  tpl_competition_id uuid not null references tpl_competitions(id) on delete cascade,
  code               text not null,
  title              text not null,
  title_ar           text,
  check_type         checklist_check not null,
  params             jsonb not null default '{}'::jsonb,   -- e.g. {"min_players":11} or {"doc_kinds":["emirates_id","photo"]}
  blocking           boolean not null default true,
  sort_order         integer not null default 0,
  unique (tpl_competition_id, code)
);

-- ---- club-owned copies -----------------------------------------------
create table competitions (
  id                uuid primary key default gen_random_uuid(),
  club_id           uuid not null,
  season_id         uuid not null,
  tpl_competition_id uuid references tpl_competitions(id) on delete set null,
  tpl_version       integer,
  governing_body    text not null default 'UAE FA',
  name              text not null,
  name_ar           text,
  min_squad_size    integer check (min_squad_size > 0),
  unique (club_id, id),
  foreign key (club_id, season_id) references seasons(club_id, id) on delete cascade
);

-- which squads play in which competition
create table squad_competitions (
  club_id        uuid not null,
  squad_id       uuid not null,
  competition_id uuid not null,
  primary key (squad_id, competition_id),
  foreign key (club_id, squad_id)       references squads(club_id, id) on delete cascade,
  foreign key (club_id, competition_id) references competitions(club_id, id) on delete cascade
);

create table competition_deadlines (
  id              uuid primary key default gen_random_uuid(),
  club_id         uuid not null,
  competition_id  uuid not null,
  tpl_deadline_id uuid references tpl_deadlines(id) on delete set null,
  kind            deadline_kind not null,
  title           text not null,
  title_ar        text,
  due_at          timestamptz not null,
  status          deadline_status not null default 'open',
  completed_at    timestamptz,
  completed_by    uuid,
  alert_offsets_hours integer[] not null default '{168,72,24}',   -- notify 7d, 3d, 1d before
  unique (club_id, id),
  foreign key (club_id, competition_id) references competitions(club_id, id) on delete cascade
);
create index on competition_deadlines (club_id, status, due_at);

create table fine_rules (
  id              uuid primary key default gen_random_uuid(),
  club_id         uuid not null,
  competition_id  uuid not null,
  tpl_fine_rule_id uuid references tpl_fine_rules(id) on delete set null,
  kind            fine_kind not null,
  basis           fine_basis not null,
  amount_fils     bigint not null check (amount_fils >= 0),
  currency        char(3) not null default 'AED',
  unique (club_id, id),
  foreign key (club_id, competition_id) references competitions(club_id, id) on delete cascade
);

create table checklist_items (
  id             uuid primary key default gen_random_uuid(),
  club_id        uuid not null,
  competition_id uuid not null,
  tpl_item_id    uuid references tpl_checklist_items(id) on delete set null,
  code           text not null,
  title          text not null,
  title_ar       text,
  check_type     checklist_check not null,
  params         jsonb not null default '{}'::jsonb,
  blocking       boolean not null default true,
  sort_order     integer not null default 0,
  active         boolean not null default true,
  unique (club_id, id),
  unique (competition_id, code),
  foreign key (club_id, competition_id) references competitions(club_id, id) on delete cascade
);
