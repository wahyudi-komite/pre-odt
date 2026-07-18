-- ============================================================
-- PRE ONE DAY TURNAMENT KEP — Database Functions & Triggers
-- ============================================================

-- -----------------------------------------------------------
-- TRIGGER: auto-update updated_at
-- -----------------------------------------------------------
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS trigger AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_tournaments_updated_at
    BEFORE UPDATE ON tournaments
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER trg_areas_updated_at
    BEFORE UPDATE ON areas
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER trg_teams_updated_at
    BEFORE UPDATE ON teams
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER trg_matches_updated_at
    BEFORE UPDATE ON matches
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- -----------------------------------------------------------
-- TRIGGER: update tournaments.updated_at on related changes
-- -----------------------------------------------------------
CREATE OR REPLACE FUNCTION touch_tournament()
RETURNS trigger AS $$
DECLARE
    t_id uuid;
BEGIN
    IF TG_OP = 'DELETE' THEN
        t_id := (SELECT tournament_id FROM areas WHERE id = OLD.area_id);
    ELSE
        t_id := (SELECT tournament_id FROM areas WHERE id = NEW.area_id);
    END IF;
    UPDATE tournaments SET updated_at = now() WHERE id = t_id;
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_touch_tournament_teams
    AFTER INSERT OR UPDATE OR DELETE ON teams
    FOR EACH ROW EXECUTE FUNCTION touch_tournament();

CREATE TRIGGER trg_touch_tournament_matches
    AFTER INSERT OR UPDATE OR DELETE ON matches
    FOR EACH ROW EXECUTE FUNCTION touch_tournament();

-- -----------------------------------------------------------
-- HELPER: get the downstream match (F or TP) for a given source
-- -----------------------------------------------------------
CREATE OR REPLACE FUNCTION get_downstream_match(p_match_id uuid)
RETURNS TABLE(match_id uuid, match_code text, position text, result_type text) AS $$
BEGIN
    RETURN QUERY
    SELECT m.id, m.match_code, 'team1', m.source_team1_result
    FROM matches m
    WHERE m.source_team1_match_id = p_match_id
    UNION ALL
    SELECT m.id, m.match_code, 'team2', m.source_team2_result
    FROM matches m
    WHERE m.source_team2_match_id = p_match_id;
END;
$$ LANGUAGE plpgsql STABLE;

-- -----------------------------------------------------------
-- HELPER: get downstream match codes for conflict detection
-- -----------------------------------------------------------
CREATE OR REPLACE FUNCTION get_downstream_chain(p_match_id uuid)
RETURNS TABLE(match_id uuid, match_code text) AS $$
BEGIN
    RETURN QUERY
    WITH RECURSIVE chain AS (
        SELECT id, match_code, source_team1_match_id, source_team2_match_id
        FROM matches
        WHERE source_team1_match_id = p_match_id OR source_team2_match_id = p_match_id
        UNION ALL
        SELECT m.id, m.match_code, m.source_team1_match_id, m.source_team2_match_id
        FROM matches m
        INNER JOIN chain c ON (m.source_team1_match_id = c.id OR m.source_team2_match_id = c.id)
    )
    SELECT id, match_code FROM chain;
END;
$$ LANGUAGE plpgsql STABLE;

-- -----------------------------------------------------------
-- RPC: save_match_result
-- -----------------------------------------------------------
CREATE OR REPLACE FUNCTION save_match_result(
    p_match_id              uuid,
    p_score_team1           integer,
    p_score_team2           integer,
    p_penalty_team1         integer DEFAULT NULL,
    p_penalty_team2         integer DEFAULT NULL,
    p_status                text DEFAULT 'finished',
    p_operator_name         text DEFAULT NULL,
    p_expected_version      integer DEFAULT 0,
    p_force_reset_downstream boolean DEFAULT false
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_match         RECORD;
    v_winner_id     uuid;
    v_loser_id      uuid;
    v_downstream    RECORD;
    v_old_data      jsonb;
    v_new_data      jsonb;
    v_started_at    timestamptz;
    v_finished_at   timestamptz;
    v_now           timestamptz := now();
    v_conflict      RECORD;
    v_conflict_list text[];
BEGIN
    -- 1. Must be authenticated
    IF auth.role() = 'anon' THEN
        RAISE EXCEPTION 'Tidak memiliki akses.' USING ERRCODE = '42501';
    END IF;

    -- 2. Find match with lock
    SELECT * INTO v_match
    FROM matches
    WHERE id = p_match_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Pertandingan tidak ditemukan.' USING ERRCODE = 'P0001';
    END IF;

    -- 3. Validate operator name
    IF p_operator_name IS NULL OR trim(p_operator_name) = '' THEN
        RAISE EXCEPTION 'Nama operator wajib diisi.' USING ERRCODE = 'P0001';
    END IF;

    -- 4. Validate status
    IF p_status NOT IN ('not_started','live','finished') THEN
        RAISE EXCEPTION 'Status pertandingan tidak valid.' USING ERRCODE = 'P0001';
    END IF;

    -- 5. Validate version (optimistic concurrency)
    IF v_match.version <> p_expected_version THEN
        RAISE EXCEPTION 'Data pertandingan telah diperbarui oleh admin lain. Muat ulang data sebelum menyimpan.'
            USING ERRCODE = 'P0001';
    END IF;

    -- 6. Check participants are set
    IF v_match.team1_id IS NULL OR v_match.team2_id IS NULL THEN
        RAISE EXCEPTION 'Peserta pertandingan belum lengkap.' USING ERRCODE = 'P0001';
    END IF;

    -- 7. Validate based on status
    IF p_status = 'not_started' THEN
        IF p_score_team1 IS NOT NULL OR p_score_team2 IS NOT NULL THEN
            RAISE EXCEPTION 'Skor harus kosong untuk status Belum Dimulai.' USING ERRCODE = 'P0001';
        END IF;
        v_winner_id := NULL;
        v_loser_id := NULL;
        v_started_at := NULL;
        v_finished_at := NULL;
    ELSIF p_status = 'live' THEN
        v_winner_id := NULL;
        v_loser_id := NULL;
        v_started_at := COALESCE(v_match.started_at, v_now);
        v_finished_at := NULL;
    ELSIF p_status = 'finished' THEN
        IF p_score_team1 IS NULL OR p_score_team2 IS NULL THEN
            RAISE EXCEPTION 'Skor utama wajib diisi untuk pertandingan selesai.' USING ERRCODE = 'P0001';
        END IF;

        IF p_score_team1 = p_score_team2 THEN
            IF p_penalty_team1 IS NULL OR p_penalty_team2 IS NULL THEN
                RAISE EXCEPTION 'Skor utama seri. Masukkan hasil adu penalti.' USING ERRCODE = 'P0001';
            END IF;
            IF p_penalty_team1 = p_penalty_team2 THEN
                RAISE EXCEPTION 'Skor adu penalti tidak boleh seri.' USING ERRCODE = 'P0001';
            END IF;

            IF p_penalty_team1 > p_penalty_team2 THEN
                v_winner_id := v_match.team1_id;
                v_loser_id := v_match.team2_id;
            ELSE
                v_winner_id := v_match.team2_id;
                v_loser_id := v_match.team1_id;
            END IF;
        ELSE
            IF p_score_team1 > p_score_team2 THEN
                v_winner_id := v_match.team1_id;
                v_loser_id := v_match.team2_id;
            ELSE
                v_winner_id := v_match.team2_id;
                v_loser_id := v_match.team1_id;
            END IF;
        END IF;

        v_started_at := COALESCE(v_match.started_at, v_now);
        v_finished_at := v_now;
    END IF;

    -- 8. Check downstream conflicts before proceeding
    IF p_status = 'finished' AND NOT p_force_reset_downstream THEN
        FOR v_conflict IN
            SELECT d.match_id, d.match_code
            FROM get_downstream_chain(p_match_id) d
            JOIN matches m ON m.id = d.match_id
            WHERE m.status IN ('live', 'finished')
        LOOP
            v_conflict_list := array_append(v_conflict_list, v_conflict.match_code);
        END LOOP;

        IF array_length(v_conflict_list, 1) > 0 THEN
            RAISE EXCEPTION 'Perubahan hasil akan memengaruhi: %. Pertandingan terdampak yang sudah memiliki hasil akan direset. Gunakan RESET PERTANDINGAN TERDAMPAK & SIMPAN untuk melanjutkan.',
                array_to_string(v_conflict_list, ', ') USING ERRCODE = 'P0001';
        END IF;
    END IF;

    -- 9. Save old data for audit
    v_old_data := row_to_json(v_match)::jsonb;

    -- 10. Update match
    UPDATE matches SET
        score_team1     = p_score_team1,
        score_team2     = p_score_team2,
        penalty_team1   = p_penalty_team1,
        penalty_team2   = p_penalty_team2,
        status          = p_status,
        winner_team_id  = v_winner_id,
        loser_team_id   = v_loser_id,
        started_at      = v_started_at,
        finished_at     = v_finished_at,
        updated_by_user_id = auth.uid(),
        updated_by_name = p_operator_name,
        version         = v_match.version + 1,
        updated_at      = v_now
    WHERE id = p_match_id
    RETURNING * INTO v_match;

    -- 11. Write audit log
    v_new_data := row_to_json(v_match)::jsonb;
    INSERT INTO match_audit_logs (match_id, area_id, action_type, old_data, new_data, operator_name, auth_user_id)
    VALUES (p_match_id, v_match.area_id, 'update', v_old_data, v_new_data, p_operator_name, auth.uid());

    -- 12. Propagate to downstream matches if finished
    IF p_status = 'finished' AND v_winner_id IS NOT NULL THEN
        FOR v_downstream IN SELECT * FROM get_downstream_match(p_match_id) LOOP
            IF v_downstream.result_type = 'winner' THEN
                IF v_downstream.position = 'team1' THEN
                    UPDATE matches SET team1_id = v_winner_id
                    WHERE id = v_downstream.match_id AND team1_id IS DISTINCT FROM v_winner_id;
                ELSIF v_downstream.position = 'team2' THEN
                    UPDATE matches SET team2_id = v_winner_id
                    WHERE id = v_downstream.match_id AND team2_id IS DISTINCT FROM v_winner_id;
                END IF;
            ELSIF v_downstream.result_type = 'loser' AND v_loser_id IS NOT NULL THEN
                IF v_downstream.position = 'team1' THEN
                    UPDATE matches SET team1_id = v_loser_id
                    WHERE id = v_downstream.match_id AND team1_id IS DISTINCT FROM v_loser_id;
                ELSIF v_downstream.position = 'team2' THEN
                    UPDATE matches SET team2_id = v_loser_id
                    WHERE id = v_downstream.match_id AND team2_id IS DISTINCT FROM v_loser_id;
                END IF;
            END IF;
        END LOOP;
    END IF;

    -- 13. Handle downstream resets if forced
    IF p_force_reset_downstream THEN
        FOR v_downstream IN SELECT id, match_code FROM matches
            WHERE (source_team1_match_id = p_match_id OR source_team2_match_id = p_match_id)
              AND status IN ('live','finished')
        LOOP
            PERFORM reset_single_match(v_downstream.id, p_operator_name, 0, false);
        END LOOP;
    END IF;

    -- 14. Touch tournament
    UPDATE tournaments SET updated_at = v_now
    WHERE id = (SELECT tournament_id FROM areas WHERE id = v_match.area_id);

    -- 15. Return updated match
    RETURN jsonb_build_object(
        'ok', true,
        'match', row_to_json(v_match)::jsonb,
        'winner_id', v_winner_id,
        'loser_id', v_loser_id
    );
END;
$$;

-- -----------------------------------------------------------
-- INTERNAL: reset_single_match (called by save_match_result)
-- -----------------------------------------------------------
CREATE OR REPLACE FUNCTION reset_single_match(
    p_match_id          uuid,
    p_operator_name     text,
    p_expected_version  integer,
    p_reset_downstream  boolean DEFAULT true
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_match     RECORD;
    v_old_data  jsonb;
    v_new_data  jsonb;
    v_down      RECORD;
    v_now       timestamptz := now();
BEGIN
    SELECT * INTO v_match FROM matches WHERE id = p_match_id FOR UPDATE;
    IF NOT FOUND THEN RETURN; END IF;

    IF v_match.version <> p_expected_version AND p_expected_version > 0 THEN
        RAISE EXCEPTION 'Data pertandingan telah diperbarui oleh admin lain. Muat ulang data sebelum menyimpan.'
            USING ERRCODE = 'P0001';
    END IF;

    v_old_data := row_to_json(v_match)::jsonb;

    UPDATE matches SET
        score_team1     = NULL,
        score_team2     = NULL,
        penalty_team1   = NULL,
        penalty_team2   = NULL,
        status          = 'not_started',
        winner_team_id  = NULL,
        loser_team_id   = NULL,
        started_at      = NULL,
        finished_at     = NULL,
        updated_by_user_id = auth.uid(),
        updated_by_name = p_operator_name,
        version         = v_match.version + 1,
        updated_at      = v_now
    WHERE id = p_match_id
    RETURNING * INTO v_match;

    v_new_data := row_to_json(v_match)::jsonb;
    INSERT INTO match_audit_logs (match_id, area_id, action_type, old_data, new_data, operator_name, auth_user_id)
    VALUES (p_match_id, v_match.area_id, 'reset', v_old_data, v_new_data, p_operator_name, auth.uid());

    IF p_reset_downstream THEN
        FOR v_down IN SELECT id FROM matches
            WHERE source_team1_match_id = p_match_id OR source_team2_match_id = p_match_id
        LOOP
            PERFORM reset_single_match(v_down.id, p_operator_name, 0, true);
        END LOOP;
    END IF;
END;
$$;

-- -----------------------------------------------------------
-- RPC: reset_match_result
-- -----------------------------------------------------------
CREATE OR REPLACE FUNCTION reset_match_result(
    p_match_id          uuid,
    p_operator_name     text,
    p_expected_version  integer,
    p_reset_downstream  boolean DEFAULT true
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_match RECORD;
BEGIN
    IF auth.role() = 'anon' THEN
        RAISE EXCEPTION 'Tidak memiliki akses.' USING ERRCODE = '42501';
    END IF;

    SELECT * INTO v_match FROM matches WHERE id = p_match_id FOR UPDATE;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Pertandingan tidak ditemukan.' USING ERRCODE = 'P0001';
    END IF;

    IF v_match.version <> p_expected_version THEN
        RAISE EXCEPTION 'Data pertandingan telah diperbarui oleh admin lain. Muat ulang data sebelum menyimpan.'
            USING ERRCODE = 'P0001';
    END IF;

    PERFORM reset_single_match(p_match_id, p_operator_name, p_expected_version, p_reset_downstream);

    RETURN jsonb_build_object('ok', true, 'message', 'Pertandingan berhasil direset.');
END;
$$;

-- -----------------------------------------------------------
-- RPC: update_team_name
-- -----------------------------------------------------------
CREATE OR REPLACE FUNCTION update_team_name(
    p_team_id       uuid,
    p_team_name     text,
    p_operator_name text
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_old_name  text;
    v_new_name  text;
    v_team      RECORD;
    v_match_id  uuid;
BEGIN
    IF auth.role() = 'anon' THEN
        RAISE EXCEPTION 'Tidak memiliki akses.' USING ERRCODE = '42501';
    END IF;

    v_new_name := trim(p_team_name);
    IF v_new_name = '' THEN
        RAISE EXCEPTION 'Nama tim tidak boleh kosong.' USING ERRCODE = 'P0001';
    END IF;
    IF char_length(v_new_name) > 60 THEN
        RAISE EXCEPTION 'Nama tim maksimal 60 karakter.' USING ERRCODE = 'P0001';
    END IF;

    SELECT * INTO v_team FROM teams WHERE id = p_team_id FOR UPDATE;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Tim tidak ditemukan.' USING ERRCODE = 'P0001';
    END IF;

    v_old_name := v_team.name;

    UPDATE teams SET name = v_new_name, updated_at = now()
    WHERE id = p_team_id;

    SELECT id INTO v_match_id FROM matches WHERE area_id = v_team.area_id ORDER BY display_order LIMIT 1;

    INSERT INTO match_audit_logs (match_id, area_id, action_type, old_data, new_data, operator_name, auth_user_id)
    VALUES (
        COALESCE(v_match_id, gen_random_uuid()),
        v_team.area_id,
        'update',
        jsonb_build_object('team_id', p_team_id, 'old_name', v_old_name),
        jsonb_build_object('team_id', p_team_id, 'new_name', v_new_name),
        p_operator_name,
        auth.uid()
    );

    RETURN jsonb_build_object('ok', true, 'name', v_new_name);
END;
$$;

-- -----------------------------------------------------------
-- RPC: reset_area
-- -----------------------------------------------------------
CREATE OR REPLACE FUNCTION reset_area(
    p_area_id           uuid,
    p_operator_name     text,
    p_confirmation_text text
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_match     RECORD;
    v_old_data  jsonb;
    v_new_data  jsonb;
    v_now       timestamptz := now();
    v_uid       uuid;
BEGIN
    IF auth.role() = 'anon' THEN
        RAISE EXCEPTION 'Tidak memiliki akses.' USING ERRCODE = '42501';
    END IF;

    IF p_confirmation_text <> 'RESET AREA' THEN
        RAISE EXCEPTION 'Teks konfirmasi tidak sesuai.' USING ERRCODE = 'P0001';
    END IF;

    v_uid := auth.uid();

    FOR v_match IN SELECT * FROM matches WHERE area_id = p_area_id ORDER BY display_order FOR UPDATE LOOP
        v_old_data := row_to_json(v_match)::jsonb;

        IF v_match.match_code IN ('SF1','SF2','TP','F') THEN
            UPDATE matches SET
                score_team1 = NULL, score_team2 = NULL,
                penalty_team1 = NULL, penalty_team2 = NULL,
                status = 'not_started',
                winner_team_id = NULL, loser_team_id = NULL,
                team1_id = NULL, team2_id = NULL,
                started_at = NULL, finished_at = NULL,
                updated_by_name = p_operator_name,
                updated_by_user_id = v_uid,
                version = version + 1,
                updated_at = v_now
            WHERE id = v_match.id
            RETURNING * INTO v_match;
        ELSE
            UPDATE matches SET
                score_team1 = NULL, score_team2 = NULL,
                penalty_team1 = NULL, penalty_team2 = NULL,
                status = 'not_started',
                winner_team_id = NULL, loser_team_id = NULL,
                started_at = NULL, finished_at = NULL,
                updated_by_name = p_operator_name,
                updated_by_user_id = v_uid,
                version = version + 1,
                updated_at = v_now
            WHERE id = v_match.id
            RETURNING * INTO v_match;
        END IF;

        v_new_data := row_to_json(v_match)::jsonb;
        INSERT INTO match_audit_logs (match_id, area_id, action_type, old_data, new_data, operator_name, auth_user_id)
        VALUES (v_match.id, p_area_id, 'reset', v_old_data, v_new_data, p_operator_name, v_uid);
    END LOOP;

    UPDATE tournaments SET updated_at = v_now
    WHERE id = (SELECT tournament_id FROM areas WHERE id = p_area_id);

    RETURN jsonb_build_object('ok', true, 'message', 'Area berhasil direset.');
END;
$$;
