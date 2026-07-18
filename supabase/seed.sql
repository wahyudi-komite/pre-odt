-- ============================================================
-- PRE ONE DAY TURNAMENT KEP — Seed Data
-- ============================================================

-- -----------------------------------------------------------
-- 1. TOURNAMENT
-- -----------------------------------------------------------
INSERT INTO tournaments (name, slug, status, timezone)
VALUES ('PRE ONE DAY TURNAMENT KEP', 'pre-one-day-turnament-kep', 'active', 'Asia/Jakarta');

-- -----------------------------------------------------------
-- 2. AREAS
-- -----------------------------------------------------------
INSERT INTO areas (tournament_id, area_number, name, display_order)
SELECT t.id, v.n, 'Area ' || v.n, v.n
FROM tournaments t
CROSS JOIN (VALUES (1),(2),(3),(4),(5),(6),(7)) AS v(n)
WHERE t.slug = 'pre-one-day-turnament-kep'
ORDER BY v.n;

-- -----------------------------------------------------------
-- 3. TEAMS (8 per area, 56 total)
-- -----------------------------------------------------------
DO $$
DECLARE
    a RECORD;
    s INTEGER;
BEGIN
    FOR a IN SELECT id, area_number FROM areas ORDER BY area_number LOOP
        FOR s IN 1..8 LOOP
            INSERT INTO teams (area_id, seed_number, name)
            VALUES (a.id, s, 'Tim A' || a.area_number || '-' || lpad(s::text, 2, '0'));
        END LOOP;
    END LOOP;
END;
$$;

-- -----------------------------------------------------------
-- 4. MATCHES (8 per area, 56 total)
-- -----------------------------------------------------------
DO $$
DECLARE
    a RECORD;
    t1 uuid;
    t2 uuid;
    t3 uuid;
    t4 uuid;
    t5 uuid;
    t6 uuid;
    t7 uuid;
    t8 uuid;
BEGIN
    FOR a IN SELECT id, area_number FROM areas ORDER BY area_number LOOP
        -- Get team IDs for this area
        SELECT id INTO t1 FROM teams WHERE area_id = a.id AND seed_number = 1;
        SELECT id INTO t2 FROM teams WHERE area_id = a.id AND seed_number = 2;
        SELECT id INTO t3 FROM teams WHERE area_id = a.id AND seed_number = 3;
        SELECT id INTO t4 FROM teams WHERE area_id = a.id AND seed_number = 4;
        SELECT id INTO t5 FROM teams WHERE area_id = a.id AND seed_number = 5;
        SELECT id INTO t6 FROM teams WHERE area_id = a.id AND seed_number = 6;
        SELECT id INTO t7 FROM teams WHERE area_id = a.id AND seed_number = 7;
        SELECT id INTO t8 FROM teams WHERE area_id = a.id AND seed_number = 8;

        -- Quarter Finals (QF)
        INSERT INTO matches (area_id, match_code, stage, display_order, team1_id, team2_id)
        VALUES (a.id, 'QF1', 'quarter_final', 1, t1, t2);

        INSERT INTO matches (area_id, match_code, stage, display_order, team1_id, team2_id)
        VALUES (a.id, 'QF2', 'quarter_final', 2, t3, t4);

        INSERT INTO matches (area_id, match_code, stage, display_order, team1_id, team2_id)
        VALUES (a.id, 'QF3', 'quarter_final', 3, t5, t6);

        INSERT INTO matches (area_id, match_code, stage, display_order, team1_id, team2_id)
        VALUES (a.id, 'QF4', 'quarter_final', 4, t7, t8);

        -- Semi Finals (SF) — participants come from QF winners
        INSERT INTO matches (area_id, match_code, stage, display_order,
            source_team1_match_id, source_team1_result, source_team2_match_id, source_team2_result)
        SELECT a.id, 'SF1', 'semi_final', 5,
            m1.id, 'winner', m2.id, 'winner'
        FROM matches m1, matches m2
        WHERE m1.area_id = a.id AND m1.match_code = 'QF1'
          AND m2.area_id = a.id AND m2.match_code = 'QF2';

        INSERT INTO matches (area_id, match_code, stage, display_order,
            source_team1_match_id, source_team1_result, source_team2_match_id, source_team2_result)
        SELECT a.id, 'SF2', 'semi_final', 6,
            m1.id, 'winner', m2.id, 'winner'
        FROM matches m1, matches m2
        WHERE m1.area_id = a.id AND m1.match_code = 'QF3'
          AND m2.area_id = a.id AND m2.match_code = 'QF4';

        -- Third Place (TP) — participants come from SF losers
        INSERT INTO matches (area_id, match_code, stage, display_order,
            source_team1_match_id, source_team1_result, source_team2_match_id, source_team2_result)
        SELECT a.id, 'TP', 'third_place', 7,
            m1.id, 'loser', m2.id, 'loser'
        FROM matches m1, matches m2
        WHERE m1.area_id = a.id AND m1.match_code = 'SF1'
          AND m2.area_id = a.id AND m2.match_code = 'SF2';

        -- Final (F) — participants come from SF winners
        INSERT INTO matches (area_id, match_code, stage, display_order,
            source_team1_match_id, source_team1_result, source_team2_match_id, source_team2_result)
        SELECT a.id, 'F', 'final', 8,
            m1.id, 'winner', m2.id, 'winner'
        FROM matches m1, matches m2
        WHERE m1.area_id = a.id AND m1.match_code = 'SF1'
          AND m2.area_id = a.id AND m2.match_code = 'SF2';
    END LOOP;
END;
$$;
