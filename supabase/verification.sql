-- ============================================================
-- PRE ONE DAY TURNAMENT KEP — Verification Queries
-- ============================================================

SELECT '1. Tournament created' AS test, count(*)::text AS result FROM tournaments
UNION ALL
SELECT '2. Areas (7)', count(*)::text FROM areas
UNION ALL
SELECT '3. Teams (56)', count(*)::text FROM teams
UNION ALL
SELECT '4. Teams per area', (SELECT string_agg(cnt::text, ', ') FROM (
    SELECT count(*) AS cnt FROM teams GROUP BY area_id ORDER BY count(*)
) t) AS result
UNION ALL
SELECT '5. Matches (56)', count(*)::text FROM matches
UNION ALL
SELECT '6. Matches per area', (SELECT string_agg(cnt::text, ', ') FROM (
    SELECT count(*) AS cnt FROM matches GROUP BY area_id ORDER BY count(*)
) t) AS result
UNION ALL
SELECT '7. QF teams set', count(*)::text FROM matches WHERE match_code LIKE 'QF%' AND team1_id IS NOT NULL AND team2_id IS NOT NULL
UNION ALL
SELECT '8. SF/TP/F teams null', count(*)::text FROM matches WHERE match_code IN ('SF1','SF2','TP','F') AND team1_id IS NULL AND team2_id IS NULL
UNION ALL
SELECT '9. RPC save_match_result', count(*)::text FROM pg_proc WHERE proname = 'save_match_result'
UNION ALL
SELECT '10. RPC reset_match_result', count(*)::text FROM pg_proc WHERE proname = 'reset_match_result'
UNION ALL
SELECT '11. RPC update_team_name', count(*)::text FROM pg_proc WHERE proname = 'update_team_name'
UNION ALL
SELECT '12. RPC reset_area', count(*)::text FROM pg_proc WHERE proname = 'reset_area';
