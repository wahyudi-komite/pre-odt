-- ============================================================
-- PRE ONE DAY TURNAMENT KEP — Verification Queries
-- Run after all SQL files to verify correct setup
-- ============================================================

-- 1. Tournament created
SELECT '1.1 Tournament' AS test, count(*)::text AS result FROM tournaments
UNION ALL
-- 2. Areas (7)
SELECT '2.1 Areas count', count(*)::text FROM areas
UNION ALL
-- 3. Teams per area (8 each = 56)
SELECT '3.1 Total teams', count(*)::text FROM teams
UNION ALL
SELECT '3.2 Teams per area', (SELECT string_agg(cnt::text, ', ') FROM (
    SELECT count(*) AS cnt FROM teams GROUP BY area_id ORDER BY count(*)
) t) AS result
UNION ALL
-- 4. Matches per area (8 each = 56)
SELECT '4.1 Total matches', count(*)::text FROM matches
UNION ALL
SELECT '4.2 Matches per area', (SELECT string_agg(cnt::text, ', ') FROM (
    SELECT count(*) AS cnt FROM matches GROUP BY area_id ORDER BY count(*)
) t) AS result
UNION ALL
-- 5. Match codes
SELECT '5.1 Match codes check', count(*)::text FROM matches WHERE match_code IN ('QF1','QF2','QF3','QF4','SF1','SF2','TP','F')
UNION ALL
-- 6. RLS enabled
SELECT '6.1 RLS tournaments', relhasrowlevelsecurity::text FROM pg_class WHERE relname = 'tournaments'
UNION ALL
SELECT '6.2 RLS areas', relhasrowlevelsecurity::text FROM pg_class WHERE relname = 'areas'
UNION ALL
SELECT '6.3 RLS teams', relhasrowlevelsecurity::text FROM pg_class WHERE relname = 'teams'
UNION ALL
SELECT '6.4 RLS matches', relhasrowlevelsecurity::text FROM pg_class WHERE relname = 'matches'
UNION ALL
SELECT '6.5 RLS match_audit_logs', relhasrowlevelsecurity::text FROM pg_class WHERE relname = 'match_audit_logs'
UNION ALL
-- 7. QF teams are set, SF/TP/F teams are null
SELECT '7.1 QF teams set', count(*)::text FROM matches WHERE match_code LIKE 'QF%' AND team1_id IS NOT NULL AND team2_id IS NOT NULL
UNION ALL
SELECT '7.2 SF teams null', count(*)::text FROM matches WHERE match_code LIKE 'SF%' AND team1_id IS NULL AND team2_id IS NULL
UNION ALL
SELECT '7.3 TP teams null', count(*)::text FROM matches WHERE match_code = 'TP' AND team1_id IS NULL AND team2_id IS NULL
UNION ALL
SELECT '7.4 F teams null', count(*)::text FROM matches WHERE match_code = 'F' AND team1_id IS NULL AND team2_id IS NULL
UNION ALL
-- 8. All matches not_started
SELECT '8.1 All not_started', count(*)::text FROM matches WHERE status = 'not_started';

-- 9. RPC functions exist
SELECT '9.1 save_match_result' AS test, count(*)::text AS result FROM pg_proc WHERE proname = 'save_match_result'
UNION ALL
SELECT '9.2 reset_match_result', count(*)::text FROM pg_proc WHERE proname = 'reset_match_result'
UNION ALL
SELECT '9.3 update_team_name', count(*)::text FROM pg_proc WHERE proname = 'update_team_name'
UNION ALL
SELECT '9.4 reset_area', count(*)::text FROM pg_proc WHERE proname = 'reset_area';
