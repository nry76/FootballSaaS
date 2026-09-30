-- =====================================================================
-- 06_compliance_runtime.sql — per-match checklists and fines ledger
-- =====================================================================

create table matchday_checklists (
  id           uuid primary key default gen_random_uuid(),
  club_id      uuid not null,
  match_id     uuid not null unique,
  status       checklist_status not null default 'open',
  generated_at timestamptz not null default now(),
  submitted_at timestamptz,
  submitted_by uuid,
  unique (club_id, id),
  foreign key (club_id, match_id) references matches(club_id, event_id) on delete cascade
);

create table matchday_checklist_results (
  checklist_id      uuid not null,
  checklist_item_id uuid not null,
  club_id           uuid not null,
  state             check_state not null default 'pending',
  auto_evaluated    boolean not null default false,      -- true when computed from roster / docs / match sheet
  detail            jsonb not null default '{}'::jsonb,  -- e.g. {"have":9,"need":11,"missing_players":[...]}
  checked_at        timestamptz,
  checked_by        uuid,
  note              text,
  primary key (checklist_id, checklist_item_id),
  foreign key (club_id, checklist_id)      references matchday_checklists(club_id, id) on delete cascade,
  foreign key (club_id, checklist_item_id) references checklist_items(club_id, id) on delete cascade
);

-- Fines: predicted ("at_risk", drives dashboard "AED X at risk") and actual.
create table fines (
  id            uuid primary key default gen_random_uuid(),
  club_id       uuid not null,
  competition_id uuid not null,
  fine_rule_id  uuid,
  match_id      uuid,
  squad_id      uuid,
  kind          fine_kind not null,
  units         integer not null default 1 check (units > 0),   -- players short / matches / occurrences
  amount_fils   bigint not null check (amount_fils >= 0),
  currency      char(3) not null default 'AED',
  status        fine_status not null default 'at_risk',
  issued_on     date,
  league_reference text,
  note          text,
  created_at    timestamptz not null default now(),
  foreign key (club_id, competition_id) references competitions(club_id, id) on delete cascade,
  foreign key (club_id, fine_rule_id)   references fine_rules(club_id, id) on delete set null (fine_rule_id),
  foreign key (club_id, match_id)       references matches(club_id, event_id) on delete set null (match_id),
  foreign key (club_id, squad_id)       references squads(club_id, id) on delete set null (squad_id)
);
create index on fines (club_id, status);

-- Generic outbox for deadline alerts, payment reminders, RSVP nudges, ...
-- A scheduled job inserts rows; a worker sends and stamps sent_at.
create table notifications (
  id            uuid primary key default gen_random_uuid(),
  club_id       uuid not null,
  recipient_id  uuid not null,
  channel       notification_channel not null default 'in_app',
  kind          text not null,                           -- 'deadline_due','fee_overdue','rsvp_reminder',...
  payload       jsonb not null default '{}'::jsonb,
  dedupe_key    text,                                    -- e.g. 'deadline:{id}:72h' so the job is idempotent
  scheduled_for timestamptz not null default now(),
  sent_at       timestamptz,
  read_at       timestamptz,
  foreign key (club_id, recipient_id) references profiles(club_id, id) on delete cascade,
  unique (recipient_id, channel, dedupe_key)
);
create index on notifications (club_id, recipient_id, read_at);
create index on notifications (scheduled_for) where sent_at is null;
