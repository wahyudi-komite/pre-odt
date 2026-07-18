-- ============================================================
-- PRE ONE DAY TURNAMENT KEP — Database Schema
-- Execute in order: 1. schema.sql → 2. functions.sql
--                   3. policies.sql → 4. realtime.sql
--                   5. seed.sql → 6. verification.sql
-- ============================================================

CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- -----------------------------------------------------------
-- 1. TOURNAMENTS
-- -----------------------------------------------------------
CREATE TABLE tournaments (
    id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    name        text NOT NULL,
    slug        text UNIQUE NOT NULL,
    status      text NOT NULL DEFAULT 'draft',
    event_date  date,
    venue       text,
    timezone    text NOT NULL DEFAULT 'Asia/Jakarta',
    created_at  timestamptz NOT NULL DEFAULT now(),
    updated_at  timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT tournaments_status_check CHECK (status IN ('draft','active','finished'))
);

-- -----------------------------------------------------------
-- 2. AREAS
-- -----------------------------------------------------------
CREATE TABLE areas (
    id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    tournament_id   uuid NOT NULL REFERENCES tournaments(id) ON DELETE CASCADE,
    area_number     integer NOT NULL,
    name            text NOT NULL,
    display_order   integer NOT NULL,
    created_at      timestamptz NOT NULL DEFAULT now(),
    updated_at      timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT areas_number_check CHECK (area_number BETWEEN 1 AND 7),
    CONSTRAINT areas_tournament_number_unique UNIQUE (tournament_id, area_number)
);

-- -----------------------------------------------------------
-- 3. TEAMS
-- -----------------------------------------------------------
CREATE TABLE teams (
    id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    area_id         uuid NOT NULL REFERENCES areas(id) ON DELETE CASCADE,
    seed_number     integer NOT NULL,
    name            text NOT NULL,
    short_name      text,
    is_active       boolean NOT NULL DEFAULT true,
    created_at      timestamptz NOT NULL DEFAULT now(),
    updated_at      timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT teams_seed_check CHECK (seed_number BETWEEN 1 AND 8),
    CONSTRAINT teams_area_seed_unique UNIQUE (area_id, seed_number),
    CONSTRAINT teams_name_not_empty CHECK (char_length(trim(name)) > 0)
);

-- -----------------------------------------------------------
-- 4. MATCHES
-- -----------------------------------------------------------
CREATE TABLE matches (
    id                      uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    area_id                 uuid NOT NULL REFERENCES areas(id) ON DELETE CASCADE,
    match_code              text NOT NULL,
    stage                   text NOT NULL,
    display_order           integer NOT NULL,

    team1_id                uuid REFERENCES teams(id),
    team2_id                uuid REFERENCES teams(id),

    source_team1_match_id   uuid REFERENCES matches(id),
    source_team1_result     text,
    source_team2_match_id   uuid REFERENCES matches(id),
    source_team2_result     text,

    score_team1             integer,
    score_team2             integer,
    penalty_team1           integer,
    penalty_team2           integer,

    status                  text NOT NULL DEFAULT 'not_started',
    winner_team_id          uuid REFERENCES teams(id),
    loser_team_id           uuid REFERENCES teams(id),

    scheduled_at            timestamptz,
    started_at              timestamptz,
    finished_at             timestamptz,

    updated_by_user_id      uuid,
    updated_by_name         text,

    version                 integer NOT NULL DEFAULT 0,
    created_at              timestamptz NOT NULL DEFAULT now(),
    updated_at              timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT matches_stage_check CHECK (stage IN ('quarter_final','semi_final','third_place','final')),
    CONSTRAINT matches_status_check CHECK (status IN ('not_started','live','finished')),
    CONSTRAINT matches_code_check CHECK (match_code IN ('QF1','QF2','QF3','QF4','SF1','SF2','TP','F')),
    CONSTRAINT matches_area_code_unique UNIQUE (area_id, match_code),
    CONSTRAINT matches_score1_positive CHECK (score_team1 IS NULL OR score_team1 >= 0),
    CONSTRAINT matches_score2_positive CHECK (score_team2 IS NULL OR score_team2 >= 0),
    CONSTRAINT matches_penalty1_positive CHECK (penalty_team1 IS NULL OR penalty_team1 >= 0),
    CONSTRAINT matches_penalty2_positive CHECK (penalty_team2 IS NULL OR penalty_team2 >= 0),
    CONSTRAINT matches_different_teams CHECK (team1_id IS NULL OR team2_id IS NULL OR team1_id <> team2_id),
    CONSTRAINT matches_source_result_check CHECK (
        (source_team1_result IS NULL OR source_team1_result IN ('winner','loser'))
        AND (source_team2_result IS NULL OR source_team2_result IN ('winner','loser'))
    )
);

-- -----------------------------------------------------------
-- 5. MATCH AUDIT LOGS
-- -----------------------------------------------------------
CREATE TABLE match_audit_logs (
    id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    match_id        uuid NOT NULL REFERENCES matches(id) ON DELETE CASCADE,
    area_id         uuid NOT NULL REFERENCES areas(id) ON DELETE CASCADE,
    action_type     text NOT NULL,
    old_data        jsonb,
    new_data        jsonb,
    operator_name   text NOT NULL,
    auth_user_id    uuid,
    created_at      timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT audit_action_check CHECK (action_type IN ('create','update','reset','force_update'))
);

-- Indexes
CREATE INDEX idx_areas_tournament ON areas(tournament_id);
CREATE INDEX idx_teams_area ON teams(area_id);
CREATE INDEX idx_matches_area ON matches(area_id);
CREATE INDEX idx_matches_status ON matches(status);
CREATE INDEX idx_audit_match ON match_audit_logs(match_id);
CREATE INDEX idx_audit_area ON match_audit_logs(area_id);
CREATE INDEX idx_audit_created ON match_audit_logs(created_at DESC);
