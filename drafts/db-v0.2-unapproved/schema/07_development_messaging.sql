-- =====================================================================
-- 07_development_messaging.sql — ratings, drills, gentle engagement,
--                                 messaging and safety reporting
--
-- ENGAGEMENT DESIGN RULES (child wellbeing)
--   * Nothing here ranks children against each other. There is deliberately
--     NO leaderboard table, and RLS only lets a player / their guardian / their
--     coaches read a player's achievements and streaks.
--   * Streaks are weekly and forgiving (grace_used_at); they reward showing up,
--     not perfection. players.engagement_enabled lets a guardian switch it all off.
-- =====================================================================

-- ---- ratings ----------------------------------------------------------
create table player_ratings (
  id         uuid primary key default gen_random_uuid(),
  club_id    uuid not null,
  player_id  uuid not null,
  squad_id   uuid,
  event_id   uuid,                                       -- optional: rating tied to a session / match
  rated_by   uuid not null,                              -- coach profile
  rated_on   date not null default current_date,
  note       text,
  unique (club_id, id),
  foreign key (club_id, player_id) references players(club_id, id) on delete cascade,
  foreign key (club_id, squad_id)  references squads(club_id, id)  on delete set null (squad_id),
  foreign key (club_id, event_id)  references events(club_id, id)  on delete set null (event_id),
  foreign key (club_id, rated_by)  references profiles(club_id, id)
);
create index on player_ratings (club_id, player_id, rated_on);

create table player_rating_scores (
  rating_id uuid not null,
  club_id   uuid not null,
  pillar    rating_pillar not null,
  score     smallint not null check (score between 1 and 5),
  comment   text,
  primary key (rating_id, pillar),
  foreign key (club_id, rating_id) references player_ratings(club_id, id) on delete cascade
);

-- ---- drills -----------------------------------------------------------
-- club_id NULL = platform library drill, readable by every club.
create table drills (
  id              uuid primary key default gen_random_uuid(),
  club_id         uuid references clubs(id) on delete cascade,
  title           text not null,
  title_ar        text,
  description     text,
  pillar          rating_pillar not null,
  difficulty      smallint not null default 1 check (difficulty between 1 and 3),
  duration_minutes integer check (duration_minutes > 0),
  video_path      text,
  metric_name     text,                                  -- e.g. 'juggles' — optional measurable result
  metric_unit     text,
  higher_is_better boolean not null default true,
  created_by      uuid,
  created_at      timestamptz not null default now()
);
create unique index drills_club_id_id on drills (club_id, id) where club_id is not null;
create unique index drills_id_unique_for_fk on drills (id);
create index on drills (club_id, pillar);

create table drill_assignments (                          -- an individual plan item
  id           uuid primary key default gen_random_uuid(),
  club_id      uuid not null,
  player_id    uuid not null,
  drill_id     uuid not null references drills(id),
  assigned_by  uuid not null,
  assigned_on  date not null default current_date,
  due_on       date,
  status       assignment_status not null default 'assigned',
  coach_note   text,
  unique (club_id, id),
  foreign key (club_id, player_id)   references players(club_id, id) on delete cascade,
  foreign key (club_id, assigned_by) references profiles(club_id, id)
);
create index on drill_assignments (club_id, player_id, status);

create table drill_completions (                          -- repeated logs = progress over time
  id            uuid primary key default gen_random_uuid(),
  club_id       uuid not null,
  assignment_id uuid not null,
  completed_at  timestamptz not null default now(),
  logged_by     uuid,                                     -- player or guardian
  duration_minutes integer check (duration_minutes > 0),
  result_value  numeric,                                  -- measured result, if the drill has a metric
  player_note   text,
  coach_feedback text,
  coach_reviewed_at timestamptz,
  foreign key (club_id, assignment_id) references drill_assignments(club_id, id) on delete cascade
);
create index on drill_completions (club_id, assignment_id, completed_at);

-- ---- gentle engagement ------------------------------------------------
create table achievement_defs (                            -- platform catalogue
  id          uuid primary key default gen_random_uuid(),
  code        text not null unique,
  kind        achievement_kind not null,
  title       text not null,
  title_ar    text,
  description text,
  threshold   integer                                     -- e.g. 4 (weeks in a row)
);

create table player_achievements (
  id         uuid primary key default gen_random_uuid(),
  club_id    uuid not null,
  player_id  uuid not null,
  def_id     uuid not null references achievement_defs(id),
  season_id  uuid,
  earned_at  timestamptz not null default now(),
  unique (player_id, def_id, season_id),
  foreign key (club_id, player_id) references players(club_id, id) on delete cascade
);

create table player_streaks (
  player_id     uuid not null,
  club_id       uuid not null,
  kind          text not null check (kind in ('training_attendance','weekly_drills')),
  current_weeks integer not null default 0,
  best_weeks    integer not null default 0,
  last_counted_week date,
  grace_used_at date,                                     -- one forgiven miss per period
  primary key (player_id, kind),
  foreign key (club_id, player_id) references players(club_id, id) on delete cascade
);

-- ---- messaging --------------------------------------------------------
create table conversations (
  id          uuid primary key default gen_random_uuid(),
  club_id     uuid not null,
  kind        conversation_kind not null,
  squad_id    uuid,
  player_id   uuid,                                       -- the child this conversation is about
  created_by  uuid not null,
  created_at  timestamptz not null default now(),
  locked_at   timestamptz,                                -- set by safeguarding reviewer
  unique (club_id, id),
  foreign key (club_id, squad_id)   references squads(club_id, id) on delete cascade,
  foreign key (club_id, player_id)  references players(club_id, id) on delete cascade,
  foreign key (club_id, created_by) references profiles(club_id, id)
);

create table conversation_participants (
  conversation_id uuid not null,
  profile_id      uuid not null,
  club_id         uuid not null,
  is_observer     boolean not null default false,          -- guardian oversight on a coach<->minor thread
  last_read_at    timestamptz,
  primary key (conversation_id, profile_id),
  foreign key (club_id, conversation_id) references conversations(club_id, id) on delete cascade,
  foreign key (club_id, profile_id)      references profiles(club_id, id) on delete cascade
);

-- Messages are append-only: no UPDATE / DELETE policy exists. Moderators hide
-- (hidden_at) rather than delete, so evidence survives.
create table messages (
  id              uuid primary key default gen_random_uuid(),
  club_id         uuid not null,
  conversation_id uuid not null,
  sender_id       uuid not null,
  body            text not null check (length(body) between 1 and 4000),
  attachment_path text,
  sent_at         timestamptz not null default now(),
  hidden_at       timestamptz,
  hidden_by       uuid,
  hidden_reason   text,
  unique (club_id, id),
  foreign key (club_id, conversation_id) references conversations(club_id, id) on delete cascade,
  foreign key (club_id, sender_id)       references profiles(club_id, id)
);
create index on messages (conversation_id, sent_at);

create table message_reports (
  id            uuid primary key default gen_random_uuid(),
  club_id       uuid not null,
  message_id    uuid not null,
  reported_by   uuid not null,
  reason        report_reason not null,
  details       text,
  message_snapshot text not null,                          -- copy of the text at report time
  status        report_status not null default 'open',
  reviewed_by   uuid,
  reviewed_at   timestamptz,
  outcome_note  text,
  escalated_to_platform boolean not null default false,
  created_at    timestamptz not null default now(),
  unique (message_id, reported_by),
  foreign key (club_id, message_id)  references messages(club_id, id),
  foreign key (club_id, reported_by) references profiles(club_id, id)
);
create index on message_reports (club_id, status);
comment on table message_reports is
  'Readable only by holders of safeguarding.review (manager). The reported sender, including a coach, can never read reports about their own messages.';
