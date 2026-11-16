-- ==============================================================================
-- MIGRATION 0006: WAJIB LULUS KUIS MODUL SEBELUM MODUL DITANDAI SELESAI
-- Project: RooveyLearn
-- Menyelesaikan TODO Sprint 3 pada complete_module:
--   Jika modul memiliki soal kuis modul aktif, pengguna harus memiliki minimal
--   satu assessment_results bertipe 'module' untuk modul tersebut dengan
--   is_passed = true (skor >= 80%). Jika tidak, RPC menolak dengan ERRCODE P0004.
--   Modul tanpa soal kuis aktif tetap dapat diselesaikan (kompatibilitas mundur).
-- ==============================================================================

CREATE OR REPLACE FUNCTION public.complete_module(p_module_id INT)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_user_id UUID;
    v_target_order INT;
    v_module_title TEXT;
    v_prev_module_id INT;
    v_prev_completed_count INT;
    v_has_module_quiz BOOLEAN;
    v_has_passed_module_quiz BOOLEAN;
    v_result RECORD;
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Akses ditolak: Pengguna belum terautentikasi.'
            USING ERRCODE = '42501';
    END IF;

    -- Ambil informasi modul target
    SELECT order_index, title INTO v_target_order, v_module_title
    FROM public.learning_modules
    WHERE id = p_module_id AND status = 'published';

    IF v_target_order IS NULL THEN
        RAISE EXCEPTION 'Modul dengan ID % tidak ditemukan atau belum dipublikasikan.', p_module_id
            USING ERRCODE = 'P0002';
    END IF;

    -- Validasi urutan: Jika modul > 1, pastikan modul urutan sebelumnya telah 'completed'
    IF v_target_order > 1 THEN
        SELECT id INTO v_prev_module_id
        FROM public.learning_modules
        WHERE order_index = (v_target_order - 1) AND status = 'published';

        SELECT COUNT(*) INTO v_prev_completed_count
        FROM public.user_module_progress
        WHERE user_id = v_user_id
          AND module_id = v_prev_module_id
          AND status = 'completed';

        IF v_prev_completed_count = 0 THEN
            RAISE EXCEPTION 'Alur belajar bertahap: Anda harus menyelesaikan modul sebelumnya (Modul %) terlebih dahulu.', (v_target_order - 1)
                USING ERRCODE = 'P0001';
        END IF;
    END IF;

    -- Validasi kelulusan kuis modul (>= 80%) bila modul memiliki bank soal aktif
    SELECT EXISTS (
        SELECT 1 FROM public.quiz_questions
        WHERE quiz_type = 'module'
          AND module_id = p_module_id
          AND is_active = true
    ) INTO v_has_module_quiz;

    IF v_has_module_quiz THEN
        SELECT EXISTS (
            SELECT 1 FROM public.assessment_results
            WHERE user_id = v_user_id
              AND assessment_type = 'module'
              AND module_id = p_module_id
              AND is_passed = true
        ) INTO v_has_passed_module_quiz;

        IF NOT v_has_passed_module_quiz THEN
            RAISE EXCEPTION 'Kuis modul belum lulus: kerjakan kuis Modul % dengan nilai minimal 80%% terlebih dahulu.', v_target_order
                USING ERRCODE = 'P0004';
        END IF;
    END IF;

    -- Catat / Perbarui progres modul menjadi completed
    INSERT INTO public.user_module_progress (
        user_id,
        module_id,
        status,
        progress_percent,
        started_at,
        completed_at,
        updated_at
    ) VALUES (
        v_user_id,
        p_module_id,
        'completed',
        100,
        timezone('utc'::text, now()),
        timezone('utc'::text, now()),
        timezone('utc'::text, now())
    )
    ON CONFLICT (user_id, module_id) DO UPDATE SET
        status = 'completed',
        progress_percent = 100,
        completed_at = COALESCE(public.user_module_progress.completed_at, timezone('utc'::text, now())),
        updated_at = timezone('utc'::text, now())
    RETURNING * INTO v_result;

    RETURN jsonb_build_object(
        'success', true,
        'message', format('Selamat! Modul %s (%s) berhasil diselesaikan.', v_target_order, v_module_title),
        'progress', jsonb_build_object(
            'id', v_result.id,
            'module_id', v_result.module_id,
            'status', v_result.status,
            'progress_percent', v_result.progress_percent,
            'completed_at', v_result.completed_at
        )
    );
END;
$$;

COMMENT ON FUNCTION public.complete_module IS 'RPC penyelesaian modul: validasi urutan prasyarat dan kelulusan kuis modul (>= 80%) di sisi server.';
