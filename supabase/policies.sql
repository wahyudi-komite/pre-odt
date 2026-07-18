-- ============================================================
-- PRE ONE DAY TURNAMENT KEP — Row Level Security
-- ============================================================

-- -----------------------------------------------------------
-- TOURNAMENTS
-- -----------------------------------------------------------
ALTER TABLE tournaments ENABLE ROW LEVEL SECURITY;

CREATE POLICY tournaments_select_anon ON tournaments
    FOR SELECT USING (true);

CREATE POLICY tournaments_select_auth ON tournaments
    FOR SELECT USING (auth.role() = 'authenticated');

REVOKE INSERT, UPDATE, DELETE ON tournaments FROM anon, authenticated;

-- -----------------------------------------------------------
-- AREAS
-- -----------------------------------------------------------
ALTER TABLE areas ENABLE ROW LEVEL SECURITY;

CREATE POLICY areas_select_anon ON areas
    FOR SELECT USING (true);

CREATE POLICY areas_select_auth ON areas
    FOR SELECT USING (auth.role() = 'authenticated');

REVOKE INSERT, UPDATE, DELETE ON areas FROM anon, authenticated;

-- -----------------------------------------------------------
-- TEAMS
-- -----------------------------------------------------------
ALTER TABLE teams ENABLE ROW LEVEL SECURITY;

CREATE POLICY teams_select_anon ON teams
    FOR SELECT USING (true);

CREATE POLICY teams_select_auth ON teams
    FOR SELECT USING (auth.role() = 'authenticated');

REVOKE INSERT, UPDATE, DELETE ON teams FROM anon, authenticated;

-- -----------------------------------------------------------
-- MATCHES
-- -----------------------------------------------------------
ALTER TABLE matches ENABLE ROW LEVEL SECURITY;

CREATE POLICY matches_select_anon ON matches
    FOR SELECT USING (true);

CREATE POLICY matches_select_auth ON matches
    FOR SELECT USING (auth.role() = 'authenticated');

REVOKE INSERT, UPDATE, DELETE ON matches FROM anon, authenticated;

-- -----------------------------------------------------------
-- MATCH AUDIT LOGS
-- -----------------------------------------------------------
ALTER TABLE match_audit_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY audit_select_auth ON match_audit_logs
    FOR SELECT USING (auth.role() = 'authenticated');

REVOKE ALL ON match_audit_logs FROM anon;
REVOKE INSERT, UPDATE, DELETE ON match_audit_logs FROM authenticated;

-- -----------------------------------------------------------
-- RPC EXECUTION
-- -----------------------------------------------------------
REVOKE ALL ON FUNCTION save_match_result FROM anon;
REVOKE ALL ON FUNCTION reset_match_result FROM anon;
REVOKE ALL ON FUNCTION update_team_name FROM anon;
REVOKE ALL ON FUNCTION reset_area FROM anon;

GRANT EXECUTE ON FUNCTION save_match_result TO authenticated;
GRANT EXECUTE ON FUNCTION reset_match_result TO authenticated;
GRANT EXECUTE ON FUNCTION update_team_name TO authenticated;
GRANT EXECUTE ON FUNCTION reset_area TO authenticated;
