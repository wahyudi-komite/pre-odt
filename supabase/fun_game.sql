-- ============================================================
-- PRE ONE DAY TURNAMENT KEP — Fun Game (replaces Tambang/Area 7)
-- Run AFTER schema.sql, functions.sql, policies.sql, realtime.sql
-- ============================================================

-- -----------------------------------------------------------
-- 1. FUN GAME ENTRIES TABLE
-- -----------------------------------------------------------
CREATE TABLE fun_game_entries (
    id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    area_id         uuid NOT NULL REFERENCES areas(id) ON DELETE CASCADE,
    phase           text NOT NULL,
    team_id         uuid NOT NULL REFERENCES teams(id),

    -- Tarik Tambang
    tt_wins         integer NOT NULL DEFAULT 0,
    tt_points       integer GENERATED ALWAYS AS (tt_wins * 2) STORED,

    -- Lomba Sarung
    sarung_rank     integer,
    sarung_points   integer NOT NULL DEFAULT 0,

    -- Lomba Bola
    bola_rank       integer,
    bola_points     integer NOT NULL DEFAULT 0,

    -- Total & Final Rank
    total_points    integer GENERATED ALWAYS AS (
        (tt_wins * 2) + COALESCE(sarung_points, 0) + COALESCE(bola_points, 0)
    ) STORED,
    final_rank      integer,

    version         integer NOT NULL DEFAULT 0,
    updated_by_name text,
    updated_by_user_id uuid,
    created_at      timestamptz NOT NULL DEFAULT now(),
    updated_at      timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT fg_phase_check CHECK (phase IN ('batch_1', 'batch_2', 'final')),
    CONSTRAINT fg_tt_wins_positive CHECK (tt_wins >= 0),
    CONSTRAINT fg_sarung_rank_check CHECK (sarung_rank IS NULL OR sarung_rank BETWEEN 1 AND 4),
    CONSTRAINT fg_bola_rank_check CHECK (bola_rank IS NULL OR bola_rank BETWEEN 1 AND 4),
    CONSTRAINT fg_final_rank_check CHECK (final_rank IS NULL OR final_rank BETWEEN 1 AND 4),
    CONSTRAINT fg_area_phase_team_unique UNIQUE (area_id, phase, team_id)
);

CREATE INDEX idx_fg_area ON fun_game_entries(area_id);
CREATE INDEX idx_fg_phase ON fun_game_entries(phase);
CREATE INDEX idx_fg_team ON fun_game_entries(team_id);

-- -----------------------------------------------------------
-- 2. TRIGGER: auto-calculate sarung_points and bola_points from rank
--    Rank 1=3, Rank 2=2, Rank 3=1, Rank 4=0
-- -----------------------------------------------------------
CREATE OR REPLACE FUNCTION calc_fun_game_points()
RETURNS trigger AS $$
BEGIN
    -- Sarung points from rank
    NEW.sarung_points := CASE NEW.sarung_rank
        WHEN 1 THEN 3
        WHEN 2 THEN 2
        WHEN 3 THEN 1
        WHEN 4 THEN 0
        ELSE 0
    END;

    -- Bola points from rank
    NEW.bola_points := CASE NEW.bola_rank
        WHEN 1 THEN 3
        WHEN 2 THEN 2
        WHEN 3 THEN 1
        WHEN 4 THEN 0
        ELSE 0
    END;

    NEW.updated_at := now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_calc_fun_game_points
    BEFORE INSERT OR UPDATE ON fun_game_entries
    FOR EACH ROW EXECUTE FUNCTION calc_fun_game_points();

-- -----------------------------------------------------------
-- 3. RPC: save_fun_game_entry
-- -----------------------------------------------------------
CREATE OR REPLACE FUNCTION save_fun_game_entry(
    p_entry_id          uuid,
    p_tt_wins           integer DEFAULT 0,
    p_sarung_rank       integer DEFAULT NULL,
    p_bola_rank         integer DEFAULT NULL,
    p_final_rank        integer DEFAULT NULL,
    p_operator_name     text DEFAULT NULL,
    p_expected_version  integer DEFAULT 0
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_entry     RECORD;
    v_old_data  jsonb;
    v_new_data  jsonb;
    v_now       timestamptz := now();
BEGIN
    -- 1. Must be authenticated
    IF auth.role() = 'anon' THEN
        RAISE EXCEPTION 'Tidak memiliki akses.' USING ERRCODE = '42501';
    END IF;

    -- 2. Validate operator name
    IF p_operator_name IS NULL OR trim(p_operator_name) = '' THEN
        RAISE EXCEPTION 'Nama operator wajib diisi.' USING ERRCODE = 'P0001';
    END IF;

    -- 3. Find entry with lock
    SELECT * INTO v_entry
    FROM fun_game_entries
    WHERE id = p_entry_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Entry Fun Game tidak ditemukan.' USING ERRCODE = 'P0001';
    END IF;

    -- 4. Optimistic concurrency
    IF v_entry.version <> p_expected_version THEN
        RAISE EXCEPTION 'Data telah diperbarui oleh admin lain. Muat ulang data sebelum menyimpan.'
            USING ERRCODE = 'P0001';
    END IF;

    -- 5. Save old data for audit
    v_old_data := row_to_json(v_entry)::jsonb;

    -- 6. Update entry
    UPDATE fun_game_entries SET
        tt_wins         = COALESCE(p_tt_wins, 0),
        sarung_rank     = p_sarung_rank,
        bola_rank       = p_bola_rank,
        final_rank      = p_final_rank,
        updated_by_name = p_operator_name,
        updated_by_user_id = auth.uid(),
        version         = v_entry.version + 1,
        updated_at      = v_now
    WHERE id = p_entry_id
    RETURNING * INTO v_entry;

    -- 7. Audit log (reuse match_audit_logs with a special action_type)
    v_new_data := row_to_json(v_entry)::jsonb;

    -- Use area's first match for audit reference, or create a dummy entry
    INSERT INTO match_audit_logs (
        match_id, area_id, action_type, old_data, new_data, operator_name, auth_user_id
    )
    SELECT
        COALESCE(
            (SELECT id FROM matches WHERE area_id = v_entry.area_id ORDER BY display_order LIMIT 1),
            gen_random_uuid()
        ),
        v_entry.area_id,
        'update',
        v_old_data,
        v_new_data,
        p_operator_name,
        auth.uid();

    -- 8. Touch tournament
    UPDATE tournaments SET updated_at = v_now
    WHERE id = (SELECT tournament_id FROM areas WHERE id = v_entry.area_id);

    -- 9. Return updated entry
    RETURN jsonb_build_object(
        'ok', true,
        'entry', row_to_json(v_entry)::jsonb
    );
END;
$$;

-- -----------------------------------------------------------
-- 4. RPC: save_fun_game_batch
--    Save all entries in a batch/final at once
-- -----------------------------------------------------------
CREATE OR REPLACE FUNCTION save_fun_game_batch(
    p_entries       jsonb,
    p_operator_name text
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_item      jsonb;
    v_entry     RECORD;
    v_old_data  jsonb;
    v_new_data  jsonb;
    v_now       timestamptz := now();
    v_count     integer := 0;
    v_area_id   uuid;
BEGIN
    IF auth.role() = 'anon' THEN
        RAISE EXCEPTION 'Tidak memiliki akses.' USING ERRCODE = '42501';
    END IF;

    IF p_operator_name IS NULL OR trim(p_operator_name) = '' THEN
        RAISE EXCEPTION 'Nama operator wajib diisi.' USING ERRCODE = 'P0001';
    END IF;

    FOR v_item IN SELECT * FROM jsonb_array_elements(p_entries)
    LOOP
        SELECT * INTO v_entry
        FROM fun_game_entries
        WHERE id = (v_item->>'id')::uuid
        FOR UPDATE;

        IF NOT FOUND THEN CONTINUE; END IF;

        IF v_entry.version <> (v_item->>'expected_version')::integer THEN
            RAISE EXCEPTION 'Data entry % telah diperbarui oleh admin lain. Muat ulang.',
                v_entry.id USING ERRCODE = 'P0001';
        END IF;

        v_old_data := row_to_json(v_entry)::jsonb;
        v_area_id := v_entry.area_id;

        UPDATE fun_game_entries SET
            tt_wins         = COALESCE((v_item->>'tt_wins')::integer, 0),
            sarung_rank     = (v_item->>'sarung_rank')::integer,
            bola_rank       = (v_item->>'bola_rank')::integer,
            final_rank      = (v_item->>'final_rank')::integer,
            updated_by_name = p_operator_name,
            updated_by_user_id = auth.uid(),
            version         = v_entry.version + 1,
            updated_at      = v_now
        WHERE id = v_entry.id
        RETURNING * INTO v_entry;

        v_new_data := row_to_json(v_entry)::jsonb;

        INSERT INTO match_audit_logs (
            match_id, area_id, action_type, old_data, new_data, operator_name, auth_user_id
        )
        SELECT
            COALESCE(
                (SELECT id FROM matches WHERE area_id = v_entry.area_id ORDER BY display_order LIMIT 1),
                gen_random_uuid()
            ),
            v_entry.area_id,
            'update',
            v_old_data,
            v_new_data,
            p_operator_name,
            auth.uid();

        v_count := v_count + 1;
    END LOOP;

    -- Touch tournament
    IF v_area_id IS NOT NULL THEN
        UPDATE tournaments SET updated_at = v_now
        WHERE id = (SELECT tournament_id FROM areas WHERE id = v_area_id);
    END IF;

    RETURN jsonb_build_object('ok', true, 'updated', v_count);
END;
$$;

-- -----------------------------------------------------------
-- 5. RPC: promote_fun_game_finalists
--    Create final entries from Top-2 of each batch
-- -----------------------------------------------------------
CREATE OR REPLACE FUNCTION promote_fun_game_finalists(
    p_area_id           uuid,
    p_operator_name     text,
    p_batch1_team_ids   uuid[],
    p_batch2_team_ids   uuid[]
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_tid   uuid;
    v_now   timestamptz := now();
BEGIN
    IF auth.role() = 'anon' THEN
        RAISE EXCEPTION 'Tidak memiliki akses.' USING ERRCODE = '42501';
    END IF;

    IF p_operator_name IS NULL OR trim(p_operator_name) = '' THEN
        RAISE EXCEPTION 'Nama operator wajib diisi.' USING ERRCODE = 'P0001';
    END IF;

    -- Validate: exactly 2 teams from each batch
    IF array_length(p_batch1_team_ids, 1) <> 2 THEN
        RAISE EXCEPTION 'Harus memilih tepat 2 tim dari Batch 1.' USING ERRCODE = 'P0001';
    END IF;
    IF array_length(p_batch2_team_ids, 1) <> 2 THEN
        RAISE EXCEPTION 'Harus memilih tepat 2 tim dari Batch 2.' USING ERRCODE = 'P0001';
    END IF;

    -- Delete existing final entries for this area
    DELETE FROM fun_game_entries
    WHERE area_id = p_area_id AND phase = 'final';

    -- Insert final entries for batch 1 qualifiers
    FOREACH v_tid IN ARRAY p_batch1_team_ids
    LOOP
        INSERT INTO fun_game_entries (area_id, phase, team_id, updated_by_name, updated_by_user_id)
        VALUES (p_area_id, 'final', v_tid, p_operator_name, auth.uid());
    END LOOP;

    -- Insert final entries for batch 2 qualifiers
    FOREACH v_tid IN ARRAY p_batch2_team_ids
    LOOP
        INSERT INTO fun_game_entries (area_id, phase, team_id, updated_by_name, updated_by_user_id)
        VALUES (p_area_id, 'final', v_tid, p_operator_name, auth.uid());
    END LOOP;

    -- Audit log
    INSERT INTO match_audit_logs (
        match_id, area_id, action_type, old_data, new_data, operator_name, auth_user_id
    )
    SELECT
        COALESCE(
            (SELECT id FROM matches WHERE area_id = p_area_id ORDER BY display_order LIMIT 1),
            gen_random_uuid()
        ),
        p_area_id,
        'update',
        '{}'::jsonb,
        jsonb_build_object(
            'action', 'promote_finalists',
            'batch1', p_batch1_team_ids,
            'batch2', p_batch2_team_ids
        ),
        p_operator_name,
        auth.uid();

    -- Touch tournament
    UPDATE tournaments SET updated_at = v_now
    WHERE id = (SELECT tournament_id FROM areas WHERE id = p_area_id);

    RETURN jsonb_build_object('ok', true, 'message', 'Finalis berhasil dipromosikan.');
END;
$$;

-- -----------------------------------------------------------
-- 6. RPC: reset_fun_game
-- -----------------------------------------------------------
CREATE OR REPLACE FUNCTION reset_fun_game(
    p_area_id           uuid,
    p_phase             text DEFAULT NULL,
    p_operator_name     text DEFAULT NULL,
    p_confirmation_text text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_entry     RECORD;
    v_old_data  jsonb;
    v_now       timestamptz := now();
    v_count     integer := 0;
BEGIN
    IF auth.role() = 'anon' THEN
        RAISE EXCEPTION 'Tidak memiliki akses.' USING ERRCODE = '42501';
    END IF;

    IF p_confirmation_text <> 'RESET FUN GAME' THEN
        RAISE EXCEPTION 'Teks konfirmasi tidak sesuai.' USING ERRCODE = 'P0001';
    END IF;

    FOR v_entry IN
        SELECT * FROM fun_game_entries
        WHERE area_id = p_area_id
          AND (p_phase IS NULL OR phase = p_phase)
        FOR UPDATE
    LOOP
        v_old_data := row_to_json(v_entry)::jsonb;

        IF v_entry.phase = 'final' THEN
            -- Delete final entries on reset
            DELETE FROM fun_game_entries WHERE id = v_entry.id;
        ELSE
            -- Reset batch entries to zero
            UPDATE fun_game_entries SET
                tt_wins = 0,
                sarung_rank = NULL,
                bola_rank = NULL,
                final_rank = NULL,
                updated_by_name = p_operator_name,
                updated_by_user_id = auth.uid(),
                version = version + 1,
                updated_at = v_now
            WHERE id = v_entry.id;
        END IF;

        INSERT INTO match_audit_logs (
            match_id, area_id, action_type, old_data, new_data, operator_name, auth_user_id
        )
        SELECT
            COALESCE(
                (SELECT id FROM matches WHERE area_id = p_area_id ORDER BY display_order LIMIT 1),
                gen_random_uuid()
            ),
            p_area_id,
            'reset',
            v_old_data,
            '{}'::jsonb,
            p_operator_name,
            auth.uid();

        v_count := v_count + 1;
    END LOOP;

    UPDATE tournaments SET updated_at = v_now
    WHERE id = (SELECT tournament_id FROM areas WHERE id = p_area_id);

    RETURN jsonb_build_object('ok', true, 'message', 'Fun Game berhasil direset.', 'reset_count', v_count);
END;
$$;

-- -----------------------------------------------------------
-- 7. ROW LEVEL SECURITY (RLS)
-- -----------------------------------------------------------
ALTER TABLE fun_game_entries ENABLE ROW LEVEL SECURITY;

-- Public read
CREATE POLICY "Fun game entries are viewable by everyone"
    ON fun_game_entries FOR SELECT
    USING (true);

-- Authenticated write
CREATE POLICY "Fun game entries are editable by authenticated users"
    ON fun_game_entries FOR ALL
    USING (auth.role() = 'authenticated')
    WITH CHECK (auth.role() = 'authenticated');

-- -----------------------------------------------------------
-- 8. ENABLE REALTIME
-- -----------------------------------------------------------
ALTER PUBLICATION supabase_realtime ADD TABLE fun_game_entries;

-- -----------------------------------------------------------
-- 9. SEED: Create initial Fun Game entries for Area 7
-- -----------------------------------------------------------
DO $$
DECLARE
    v_area_id uuid;
    v_team RECORD;
BEGIN
    -- Get Area 7 ID
    SELECT a.id INTO v_area_id
    FROM areas a
    JOIN tournaments t ON t.id = a.tournament_id
    WHERE t.slug = 'pre-one-day-turnament-kep'
      AND a.area_number = 7;

    IF v_area_id IS NULL THEN
        RAISE NOTICE 'Area 7 not found, skipping Fun Game seed.';
        RETURN;
    END IF;

    -- Batch 1: Teams with seed_number 1-4
    FOR v_team IN
        SELECT id, seed_number FROM teams
        WHERE area_id = v_area_id AND seed_number BETWEEN 1 AND 4
        ORDER BY seed_number
    LOOP
        INSERT INTO fun_game_entries (area_id, phase, team_id)
        VALUES (v_area_id, 'batch_1', v_team.id)
        ON CONFLICT (area_id, phase, team_id) DO NOTHING;
    END LOOP;

    -- Batch 2: Teams with seed_number 5-8
    FOR v_team IN
        SELECT id, seed_number FROM teams
        WHERE area_id = v_area_id AND seed_number BETWEEN 5 AND 8
        ORDER BY seed_number
    LOOP
        INSERT INTO fun_game_entries (area_id, phase, team_id)
        VALUES (v_area_id, 'batch_2', v_team.id)
        ON CONFLICT (area_id, phase, team_id) DO NOTHING;
    END LOOP;

    RAISE NOTICE 'Fun Game seeded for Area 7: 4 batch_1 + 4 batch_2 entries.';
END;
$$;
