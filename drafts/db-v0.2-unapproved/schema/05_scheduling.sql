-- =====================================================================
-- 05_scheduling.sql — venues, events (training/match), RSVP + attendance,
--                     match sheet
-- =====================================================================

create table venues (
  id       uuid primary key default gen_random_uuid(),
  club_id  uuid not null references clubs(id) on delete cascade,
  name     text not null,
  address  text,
  maps_url text,
  unique (club_id, id)
);

create table events (
  id            uuid primary key default gen_random_uuid(),
  club_id       uuid not null,
  squad_id      uuid not null,
  type          event_type not null,
  title         text not null,
  starts_at     timestamptz not null,
  ends_at       timestamptz not null,
  venue_id      uuid,
  location_note text,
  status        event_status not null default 'scheduled',
  cancelled_by_club boolean,                            -- a club-cancelled match can trigger a fine
  cancelled_reason  text,
  rsvp_deadline timestamptz,
  created_by    uuid,
  created_at    timestamptz not null default now(),
  check (ends_at > starts_at),
  check (status <> 'cancelled' or cancelled_by_club is not null),
  unique (club_id, id),
  foreign key (club_id, squad_id) references squads(club_id, id) on delete cascade,
  foreign key (club_id, venue_id) references venues(club_id, id) on delete set null (venue_id)
);
create index on events (club_id, squad_id, starts_at);

-- 1:1 extension of events where type = 'match'
create table matches (
  event_id        uuid primary key,
  club_id         uuid not null,
  competition_id  uuid not null,
  opponent_name   text not null,
  home_away       text not null check (home_away in ('home','away','neutral')),
  goals_for       smallint,
  goals_against   smallint,
  league_match_ref text,                                -- FANet / league fixture id (reserved for integration)
  unique (club_id, event_id),
  foreign key (club_id, event_id)       references events(club_id, id) on delete cascade,
  foreign key (club_id, competition_id) references competitions(club_id, id)
);

-- One row per (event, player): RSVP from player/guardian, attendance from coach.
create table event_participants (
  event_id     uuid not null,
  player_id    uuid not null,
  club_id      uuid not null,
  rsvp         rsvp_status not null default 'no_response',
  rsvp_by      uuid,
  rsvp_at      timestamptz,
  attendance   attendance_status,                       -- null until the coach marks it
  attendance_by uuid,
  attendance_at timestamptz,
  note         text,
  primary key (event_id, player_id),
  foreign key (club_id, event_id)  references events(club_id, id)  on delete cascade,
  foreign key (club_id, player_id) references players(club_id, id) on delete cascade
);
create index on event_participants (club_id, player_id);

-- The official match sheet (what the league checks).
create table match_sheet_players (
  match_id      uuid not null,
  player_id     uuid not null,
  club_id       uuid not null,
  jersey_number smallint check (jersey_number between 1 and 99),
  is_starter    boolean not null default false,
  primary key (match_id, player_id),
  unique (match_id, jersey_number),
  foreign key (club_id, match_id)  references matches(club_id, event_id) on delete cascade,
  foreign key (club_id, player_id) references players(club_id, id) on delete cascade
);

create table match_sheet_staff (
  match_id   uuid not null,
  profile_id uuid not null,
  club_id    uuid not null,
  role       squad_staff_role not null,                 -- 'medical' rows satisfy the medical-staff check
  primary key (match_id, profile_id, role),
  foreign key (club_id, match_id)   references matches(club_id, event_id) on delete cascade,
  foreign key (club_id, profile_id) references profiles(club_id, id) on delete cascade
);
