-- =====================================================================
-- 03_squads_jerseys.sql — squads, staff assignment, multi-squad membership,
--                         player-level jersey numbers
--
-- JERSEY NUMBER MODEL
--   player_jersey_numbers     = the PLAYER's number for a season (ownership
--                               lives here, one row per player per season).
--   squad_memberships         = which squads the player is in. A player can be
--                               in several squads (playing up / down). The
--                               number worn in a squad is squad_memberships.
--                               jersey_number, and a UNIQUE index guarantees
--                               nobody else in THAT squad wears it.
--   jersey_reservations       = club-reserved numbers/ranges (retired, goalkeeper).
--
--   Nudge rule: when a player joins a second squad, the app calls
--   public.available_jersey_numbers(player, season, [target squads]) which
--   returns only numbers free in EVERY squad the player is in or is about to
--   join, minus reservations. Choosing from that list keeps one number = one
--   kit. Using a different number in the second squad is allowed but needs
--   kit_exception_reason, and shows up in v_jersey_conflicts as "extra kit".
-- =====================================================================

create table squads (
  id              uuid primary key default gen_random_uuid(),
  club_id         uuid not null,
  season_id       uuid not null,
  name            text not null,                       -- 'U12 A'
  name_ar         text,
  age_group       text not null,                       -- 'U12'
  birth_year_from integer not null,                    -- players born in [from, to] are "in age band"
  birth_year_to   integer not null,
  gender          text check (gender in ('male','female','mixed')),
  archived_at     timestamptz,
  check (birth_year_to >= birth_year_from),
  unique (club_id, id),
  unique (club_id, id, season_id),
  foreign key (club_id, season_id) references seasons(club_id, id) on delete cascade
);
create index on squads (club_id, season_id);

-- Which staff may see / manage a squad. Coach RLS is driven by this table.
create table squad_staff (
  squad_id   uuid not null,
  profile_id uuid not null,
  club_id    uuid not null,
  role       squad_staff_role not null,
  primary key (squad_id, profile_id, role),
  foreign key (club_id, squad_id)   references squads(club_id, id) on delete cascade,
  foreign key (club_id, profile_id) references profiles(club_id, id) on delete cascade
);
create index on squad_staff (club_id, profile_id);

-- Player-level number ownership (one number per player per season).
create table player_jersey_numbers (
  id         uuid primary key default gen_random_uuid(),
  club_id    uuid not null,
  player_id  uuid not null,
  season_id  uuid not null,
  number     smallint not null check (number between 1 and 99),
  chosen_by  uuid,
  chosen_at  timestamptz not null default now(),
  locked     boolean not null default false,           -- true once the kit is ordered
  unique (player_id, season_id),
  unique (club_id, id),
  foreign key (club_id, player_id) references players(club_id, id) on delete cascade,
  foreign key (club_id, season_id) references seasons(club_id, id) on delete cascade
);

create table squad_memberships (
  id            uuid primary key default gen_random_uuid(),
  club_id       uuid not null,
  squad_id      uuid not null,
  season_id     uuid not null,
  player_id     uuid not null,
  membership_type membership_type not null default 'primary',   -- auto-set by trigger from birth year vs squad band
  jersey_number smallint check (jersey_number between 1 and 99),
  kit_exception_reason text,                            -- required when jersey_number <> player's own number
  joined_on     date not null default current_date,
  left_on       date,
  unique (club_id, id),
  check (left_on is null or left_on >= joined_on),
  foreign key (club_id, squad_id, season_id) references squads(club_id, id, season_id) on delete cascade,
  foreign key (club_id, player_id)           references players(club_id, id) on delete cascade
);
-- a player appears once per squad while active
create unique index one_active_membership on squad_memberships (squad_id, player_id) where left_on is null;
-- nobody else in the same squad can wear the same number
create unique index one_number_per_squad  on squad_memberships (squad_id, jersey_number)
  where jersey_number is not null and left_on is null;
create index on squad_memberships (club_id, player_id);

create table jersey_reservations (
  id             uuid primary key default gen_random_uuid(),
  club_id        uuid not null,
  season_id      uuid,                                  -- null = every season
  squad_id       uuid,                                  -- null = every squad in the club
  number_from    smallint not null check (number_from between 1 and 99),
  number_to      smallint not null check (number_to   between 1 and 99),
  reason         jersey_reserve_reason not null,
  only_position_group position_group,                   -- e.g. 'goalkeeper': only GKs may take these numbers
  note           text,
  check (number_to >= number_from),
  foreign key (club_id, season_id) references seasons(club_id, id) on delete cascade,
  foreign key (club_id, squad_id)  references squads(club_id, id)  on delete cascade
);
comment on column jersey_reservations.only_position_group is
  'null = nobody may take the numbers (retired / staff hold). Set = only players in that position group may.';
