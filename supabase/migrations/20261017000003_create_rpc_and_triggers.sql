-- ==============================================================================
-- MIGRATION 03: CREATE DATABASE TRIGGERS & RPC FUNCTIONS (SECURITY DEFINER)
-- Project: RooveyLearn - Digital Learning Platform for Mangrove Conservation
-- Reference: PROPOSAL_ROOVEYLEARN.md (Bab 3.4), AUDIT_ROOVEYLEARN.md (P0-02, P1-04)
-- ==============================================================================

-- ==============================================================================
-- 1. UTILITY TRIGGERS
-- ==============================================================================

-- 1.1 AUTO-UPDATE TIMESTAMPS
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER 
LANGUAGE plpgsql
SET search_path = public, pg_temp
AS $$
BEGIN
    NEW.updated_at = timezone('utc'::text, now());
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trigger_profiles_updated_at ON public.profiles;
CREATE TRIGGER trigger_profiles_updated_at
BEFORE UPDATE ON public.profiles
FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

DROP TRIGGER IF EXISTS trigger_learning_modules_updated_at ON public.learning_modules;
CREATE TRIGGER trigger_learning_modules_updated_at
BEFORE UPDATE ON public.learning_modules
FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

DROP TRIGGER IF EXISTS trigger_learning_materials_updated_at ON public.learning_materials;
CREATE TRIGGER trigger_learning_materials_updated_at
BEFORE UPDATE ON public.learning_materials
FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

DROP TRIGGER IF EXISTS trigger_quiz_questions_updated_at ON public.quiz_questions;
CREATE TRIGGER trigger_quiz_questions_updated_at
BEFORE UPDATE ON public.quiz_questions
FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

DROP TRIGGER IF EXISTS trigger_user_module_progress_updated_at ON public.user_module_progress;
CREATE TRIGGER trigger_user_module_progress_updated_at
BEFORE UPDATE ON public.user_module_progress
FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- 1.2 AUTO-CREATE PROFILE ON AUTH.USERS REGISTRATION (Rule 1)
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER 
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_raw_name TEXT;
    v_clean_name TEXT;
BEGIN
    v_raw_name := COALESCE(
        NEW.raw_user_meta_data->>'name',
        NEW.raw_user_meta_data->>'full_name',
        split_part(NEW.email, '@', 1)
    );
    v_clean_name := NULLIF(TRIM(v_raw_name), '');
    IF v_clean_name IS NULL THEN
        v_clean_name := 'Penjaga Pesisir';
    END IF;

    INSERT INTO public.profiles (
        id,
        name,
        community_name,
        avatar_url,
        created_at,
        updated_at
    ) VALUES (
        NEW.id,
        v_clean_name,
        NEW.raw_user_meta_data->>'community_name',
        NEW.raw_user_meta_data->>'avatar_url',
        timezone('utc'::text, now()),
        timezone('utc'::text, now())
    )
    ON CONFLICT (id) DO UPDATE SET
        name = EXCLUDED.name,
        community_name = COALESCE(EXCLUDED.community_name, public.profiles.community_name),
        avatar_url = COALESCE(EXCLUDED.avatar_url, public.profiles.avatar_url),
        updated_at = timezone('utc'::text, now());

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
AFTER INSERT ON auth.users
FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ==============================================================================
-- 2. CORE RPC FUNCTIONS (BUSINESS LOGIC ENFORCEMENT AT SERVER-SIDE)
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- 2.1 COMPLETE_MODULE RPC (Rule 7)
-- Menegakkan alur berurutan modul 1 -> 2 -> 3 -> 4 -> 5.
-- Pengguna dilarang menyelesaikan modul N jika modul (N-1) belum berstatus 'completed'.
-- ------------------------------------------------------------------------------
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

    -- TODO (Sprint 3 - Content & Quiz Integration):
    -- Menambahkan validasi kelulusan kuis formatif modul (score >= 80 pada assessment_results
    -- untuk assessment_type = 'module' AND module_id = p_module_id) sebelum modul dapat ditandai 'completed'.

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

COMMENT ON FUNCTION public.complete_module IS 'RPC penyelesaian modul dengan validasi urutan prasyarat di sisi server.';

-- ------------------------------------------------------------------------------
-- 2.2 SUBMIT_QUIZ RPC (Rule 3, 4, c, d, e)
-- Menghitung skor kuis di server secara aman tanpa mengekspos kunci jawaban sebelumnya.
-- Jawaban benar dan penjelasan hanya dikembalikan DALAM HASIL SUBMIT.
-- Poin c: Skor dihitung dari total soal aktif di bank untuk kuis terkait.
-- Poin d: Kuis 'final' mensyaratkan kelima modul sudah 'completed'.
-- Poin e: Batasan maksimal 3 percobaan final kuis per 24 jam.
-- ------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.submit_quiz(
    p_quiz_type TEXT,
    p_module_id INT DEFAULT NULL,
    p_answers JSONB DEFAULT '[]'::jsonb
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    -- Konstanta batas percobaan asesmen akhir per 24 jam (Poin e)
    c_max_final_attempts_per_24h CONSTANT INT := 3;

    v_user_id UUID;
    v_total_bank_questions INT := 0;
    v_correct_count INT := 0;
    v_score INT := 0;
    v_is_passed BOOLEAN := false;
    v_attempt_number INT := 1;
    v_assessment_id UUID;
    v_evaluations JSONB := '[]'::jsonb;
    v_q RECORD;
    v_selected_option INT;
    v_is_correct BOOLEAN;

    -- Variabel validasi payload (Poin c)
    v_submitted_count INT := 0;
    v_distinct_submitted_count INT := 0;
    v_invalid_qid TEXT;

    -- Variabel prasyarat modul (Poin d)
    v_completed_modules_count INT := 0;
    v_total_modules_count INT := 0;

    -- Variabel rate-limit (Poin e)
    v_recent_final_attempts INT := 0;
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Akses ditolak: Pengguna belum terautentikasi.' 
            USING ERRCODE = '42501';
    END IF;

    -- Validasi jenis kuis
    IF p_quiz_type NOT IN ('pretest', 'module', 'final') THEN
        RAISE EXCEPTION 'Jenis evaluasi tidak valid: % (harus pretest, module, atau final).', p_quiz_type
            USING ERRCODE = '22023';
    END IF;

    IF p_quiz_type = 'module' AND p_module_id IS NULL THEN
        RAISE EXCEPTION 'module_id wajib diisi untuk kuis bertipe module.' 
            USING ERRCODE = '22023';
    END IF;

    -- Poin d: Verifikasi prasyarat untuk asesmen akhir ('final'): seluruh 5 modul harus 'completed'
    IF p_quiz_type = 'final' THEN
        SELECT COUNT(*) INTO v_total_modules_count
        FROM public.learning_modules
        WHERE status = 'published';

        IF v_total_modules_count = 0 THEN
            v_total_modules_count := 5;
        END IF;

        SELECT COUNT(DISTINCT lm.id) INTO v_completed_modules_count
        FROM public.learning_modules lm
        JOIN public.user_module_progress ump ON ump.module_id = lm.id
        WHERE ump.user_id = v_user_id
          AND ump.status = 'completed'
          AND lm.status = 'published';

        IF v_completed_modules_count < v_total_modules_count THEN
            RAISE EXCEPTION 'Akses ditolak: Asesmen akhir hanya dapat diikuti setelah menyelesaikan seluruh % modul pembelajaran wajib (baru selesai: % modul).',
                v_total_modules_count, v_completed_modules_count
                USING ERRCODE = 'P0001';
        END IF;

        -- Poin e: Batasan maksimal 3 percobaan asesmen akhir per 24 jam
        SELECT COUNT(*) INTO v_recent_final_attempts
        FROM public.assessment_results
        WHERE user_id = v_user_id
          AND assessment_type = 'final'
          AND completed_at >= (timezone('utc'::text, now()) - INTERVAL '24 hours');

        IF v_recent_final_attempts >= c_max_final_attempts_per_24h THEN
            RAISE EXCEPTION 'Batas maksimal % percobaan asesmen akhir per 24 jam telah tercapai. Silakan coba kembali nanti.',
                c_max_final_attempts_per_24h
                USING ERRCODE = 'P0003';
        END IF;
    END IF;

    -- Poin c: Validasi ID duplikat pada lembar jawaban
    IF jsonb_array_length(p_answers) > 0 THEN
        SELECT COUNT(*), COUNT(DISTINCT elem->>'question_id')
        INTO v_submitted_count, v_distinct_submitted_count
        FROM jsonb_array_elements(p_answers) AS elem;

        IF v_submitted_count != v_distinct_submitted_count THEN
            RAISE EXCEPTION 'Format lembar jawaban tidak valid: terdapat ID butir soal duplikat.'
                USING ERRCODE = '22023';
        END IF;

        -- Poin c: Tolak ID soal yang bukan milik paket kuis / modul yang diminta
        SELECT elem->>'question_id' INTO v_invalid_qid
        FROM jsonb_array_elements(p_answers) AS elem
        WHERE NOT EXISTS (
            SELECT 1 FROM public.quiz_questions qq
            WHERE qq.id = (elem->>'question_id')::UUID
              AND qq.quiz_type = p_quiz_type
              AND (p_quiz_type != 'module' OR qq.module_id = p_module_id)
              AND qq.is_active = true
        )
        LIMIT 1;

        IF v_invalid_qid IS NOT NULL THEN
            RAISE EXCEPTION 'Soal dengan ID % tidak terdaftar pada paket kuis % (module: %).',
                v_invalid_qid, p_quiz_type, p_module_id
                USING ERRCODE = '22023';
        END IF;
    END IF;

    -- Poin c: Hitung total soal aktif dari BANK SOAL untuk kuis ini
    SELECT COUNT(*) INTO v_total_bank_questions
    FROM public.quiz_questions
    WHERE quiz_type = p_quiz_type
      AND (p_quiz_type != 'module' OR module_id = p_module_id)
      AND is_active = true;

    IF v_total_bank_questions = 0 THEN
        RAISE EXCEPTION 'Paket soal untuk kuis % (module: %) belum tersedia.', p_quiz_type, p_module_id
            USING ERRCODE = 'P0002';
    END IF;

    -- Iterasi SELURUH butir soal di bank untuk kuis ini
    -- Soal yang tidak dijawab pengguna dihitung SALAH
    FOR v_q IN
        SELECT 
            q.id AS question_id,
            q.question_text,
            q.options,
            q.order_index,
            a.correct_option_index,
            a.explanation
        FROM public.quiz_questions q
        JOIN public.quiz_answers a ON a.question_id = q.id
        WHERE q.quiz_type = p_quiz_type
          AND (p_quiz_type != 'module' OR q.module_id = p_module_id)
          AND q.is_active = true
        ORDER BY q.order_index ASC
    LOOP
        -- Cari apakah user mengirim jawaban untuk soal ini
        SELECT (elem->>'selected_option')::INT INTO v_selected_option
        FROM jsonb_array_elements(p_answers) AS elem
        WHERE (elem->>'question_id')::UUID = v_q.question_id
        LIMIT 1;

        IF v_selected_option IS NOT NULL AND v_selected_option = v_q.correct_option_index THEN
            v_is_correct := true;
            v_correct_count := v_correct_count + 1;
        ELSE
            v_is_correct := false;
        END IF;

        -- Susun penjelasan jawaban untuk dikembalikan setelah evaluasi
        v_evaluations := v_evaluations || jsonb_build_object(
            'question_id', v_q.question_id,
            'question_text', v_q.question_text,
            'selected_option', v_selected_option,
            'correct_option_index', v_q.correct_option_index,
            'is_correct', v_is_correct,
            'explanation', v_q.explanation
        );
    END LOOP;

    -- Poin c: Hitung skor dari TOTAL SOAL DI BANK (bukan total jawaban terkirim)
    v_score := ROUND((v_correct_count::NUMERIC / v_total_bank_questions::NUMERIC) * 100);
    
    -- Aturan kelulusan (>= 80% untuk module & final; pretest bersifat diagnostik)
    IF p_quiz_type = 'pretest' THEN
        v_is_passed := true;
    ELSE
        v_is_passed := (v_score >= 80);
    END IF;

    -- Hitung nomor percobaan pengguna untuk kuis ini
    SELECT COALESCE(MAX(attempt_number), 0) + 1 INTO v_attempt_number
    FROM public.assessment_results
    WHERE user_id = v_user_id 
      AND assessment_type = p_quiz_type
      AND ((p_module_id IS NULL AND module_id IS NULL) OR module_id = p_module_id);

    -- Simpan hasil evaluasi secara aman di server
    INSERT INTO public.assessment_results (
        user_id,
        assessment_type,
        module_id,
        score,
        total_questions,
        correct_answers,
        is_passed,
        attempt_number,
        submitted_answers,
        completed_at
    ) VALUES (
        v_user_id,
        p_quiz_type,
        p_module_id,
        v_score,
        v_total_bank_questions,
        v_correct_count,
        v_is_passed,
        v_attempt_number,
        p_answers,
        timezone('utc'::text, now())
    ) RETURNING id INTO v_assessment_id;

    RETURN jsonb_build_object(
        'assessment_id', v_assessment_id,
        'quiz_type', p_quiz_type,
        'module_id', p_module_id,
        'score', v_score,
        'total_questions', v_total_bank_questions,
        'correct_answers', v_correct_count,
        'is_passed', v_is_passed,
        'attempt_number', v_attempt_number,
        'evaluations', v_evaluations
    );
END;
$$;

COMMENT ON FUNCTION public.submit_quiz IS 'RPC penilaian kuis server-side: menghitung nilai dari bank soal, validasi kuis final, dan rate limit.';

-- ------------------------------------------------------------------------------
-- 2.3 ISSUE_CERTIFICATE RPC (Rule 6 & Keputusan 1)
-- Memvalidasi prasyarat penerbitan sertifikat:
-- 1. Kelima modul pembelajaran harus berstatus 'completed'.
-- 2. Asesmen akhir telah dikerjakan dengan nilai minimal 80%.
-- 3. Menggunakan nilai TERBAIK (best score) dan mencatat assessment_result_id terkait.
-- 4. Satu pengguna maksimal satu sertifikat aktif.
-- ------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.issue_certificate()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_user_id UUID;
    v_user_name TEXT;
    v_completed_modules_count INT;
    v_total_required_modules INT;
    v_existing_cert RECORD;
    v_best_assessment RECORD;
    v_latest_assessment RECORD;
    v_new_cert_number TEXT;
    v_cert_record RECORD;
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Akses ditolak: Pengguna belum terautentikasi.' 
            USING ERRCODE = '42501';
    END IF;

    -- Ambil nama pengguna
    SELECT name INTO v_user_name
    FROM public.profiles
    WHERE id = v_user_id;

    -- Cek jika sudah memiliki sertifikat aktif (Idempotent)
    SELECT * INTO v_existing_cert
    FROM public.certificates
    WHERE user_id = v_user_id AND status = 'active'
    LIMIT 1;

    IF v_existing_cert.id IS NOT NULL THEN
        RETURN jsonb_build_object(
            'success', true,
            'is_new', false,
            'message', 'Sertifikat digital Anda sudah terbit.',
            'certificate', jsonb_build_object(
                'certificate_id', v_existing_cert.id,
                'certificate_number', v_existing_cert.certificate_number,
                'participant_name', v_user_name,
                'final_score', v_existing_cert.final_score,
                'issued_at', v_existing_cert.issued_at
            )
        );
    END IF;

    -- Syarat 1: Verifikasi kelima modul selesai
    SELECT COUNT(*) INTO v_total_required_modules
    FROM public.learning_modules
    WHERE status = 'published';

    IF v_total_required_modules = 0 THEN
        v_total_required_modules := 5;
    END IF;

    SELECT COUNT(DISTINCT lm.id) INTO v_completed_modules_count
    FROM public.learning_modules lm
    JOIN public.user_module_progress ump ON ump.module_id = lm.id
    WHERE ump.user_id = v_user_id
      AND ump.status = 'completed'
      AND lm.status = 'published';

    IF v_completed_modules_count < v_total_required_modules THEN
        RAISE EXCEPTION 'Syarat belum terpenuhi: Anda baru menyelesaikan % dari % modul pembelajaran wajib.',
            v_completed_modules_count, v_total_required_modules
            USING ERRCODE = 'P0001';
    END IF;

    -- Syarat 2 (Keputusan 1): Menggunakan nilai TERBAIK asesmen akhir (score >= 80%)
    SELECT id, score INTO v_best_assessment
    FROM public.assessment_results
    WHERE user_id = v_user_id 
      AND assessment_type = 'final'
      AND score >= 80
    ORDER BY score DESC, completed_at DESC
    LIMIT 1;

    IF v_best_assessment.id IS NULL THEN
        SELECT score INTO v_latest_assessment
        FROM public.assessment_results
        WHERE user_id = v_user_id AND assessment_type = 'final'
        ORDER BY completed_at DESC
        LIMIT 1;

        IF v_latest_assessment.score IS NOT NULL THEN
            RAISE EXCEPTION 'Syarat belum terpenuhi: Nilai asesmen akhir minimal 80%% (nilai terbaik Anda saat ini: %s%%). Silakan coba kembali.',
                v_latest_assessment.score
                USING ERRCODE = 'P0001';
        ELSE
            RAISE EXCEPTION 'Syarat belum terpenuhi: Anda belum mengikuti Asesmen Akhir.'
                USING ERRCODE = 'P0001';
        END IF;
    END IF;

    -- Generate Nomor Sertifikat Unik: ROOVEY-YYYYMMDD-XXXXXX
    v_new_cert_number := 'ROOVEY-' || 
                         to_char(timezone('utc'::text, now()), 'YYYYMMDD') || '-' || 
                         UPPER(SUBSTR(md5(random()::text || clock_timestamp()::text), 1, 6));

    -- Terbitkan sertifikat dengan mencatat assessment_result_id terkait (Keputusan 1)
    INSERT INTO public.certificates (
        user_id,
        certificate_number,
        assessment_result_id,
        final_score,
        status,
        issued_at
    ) VALUES (
        v_user_id,
        v_new_cert_number,
        v_best_assessment.id,
        v_best_assessment.score,
        'active',
        timezone('utc'::text, now())
    ) RETURNING * INTO v_cert_record;

    RETURN jsonb_build_object(
        'success', true,
        'is_new', true,
        'message', 'Selamat! Sertifikat digital RooveyLearn berhasil diterbitkan.',
        'certificate', jsonb_build_object(
            'certificate_id', v_cert_record.id,
            'certificate_number', v_cert_record.certificate_number,
            'participant_name', v_user_name,
            'program_name', 'Dasar Pengelolaan Mangrove',
            'final_score', v_cert_record.final_score,
            'issued_at', v_cert_record.issued_at
        )
    );
END;
$$;

COMMENT ON FUNCTION public.issue_certificate IS 'RPC penerbitan sertifikat digital berbasis nilai terbaik asesmen akhir.';

-- ------------------------------------------------------------------------------
-- 2.4 VERIFY_CERTIFICATE RPC (Keputusan 4)
-- Verifikasi publik sertifikat.
-- Hanya mengembalikan: nomor sertifikat, nama peserta, nama program, tanggal terbit, status.
-- DILARANG mengembalikan user_id, email, atau nilai numerik.
-- ------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.verify_certificate(p_certificate_number TEXT)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_cert RECORD;
BEGIN
    SELECT 
        c.certificate_number,
        c.status,
        c.issued_at,
        p.name AS participant_name
    INTO v_cert
    FROM public.certificates c
    JOIN public.profiles p ON p.id = c.user_id
    WHERE c.certificate_number = TRIM(p_certificate_number)
      AND c.status = 'active';

    IF v_cert.certificate_number IS NULL THEN
        RETURN jsonb_build_object(
            'valid', false,
            'message', 'Nomor sertifikat tidak ditemukan atau tidak aktif.'
        );
    END IF;

    RETURN jsonb_build_object(
        'valid', true,
        'certificate_number', v_cert.certificate_number,
        'participant_name', v_cert.participant_name,
        'program_name', 'Dasar Pengelolaan Mangrove',
        'issued_at', v_cert.issued_at,
        'status', v_cert.status
    );
END;
$$;

COMMENT ON FUNCTION public.verify_certificate IS 'RPC verifikasi publik sertifikat (tanpa data pribadi/user_id).';

-- ==============================================================================
-- 3. FUNCTION EXECUTION PRIVILEGES (Point a)
-- Cabut default EXECUTE dari PUBLIC dan anon pada seluruh SECURITY DEFINER.
-- GRANT EXECUTE hanya ke authenticated, kecuali verify_certificate yang boleh anon.
-- ==============================================================================

-- Fungsi trigger internal: tidak boleh dieksekusi langsung oleh role mana pun
REVOKE ALL ON FUNCTION public.handle_updated_at() FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.handle_new_user() FROM PUBLIC, anon, authenticated;

-- complete_module: hanya authenticated
REVOKE ALL ON FUNCTION public.complete_module(INT) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.complete_module(INT) TO authenticated;

-- submit_quiz: hanya authenticated
REVOKE ALL ON FUNCTION public.submit_quiz(TEXT, INT, JSONB) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.submit_quiz(TEXT, INT, JSONB) TO authenticated;

-- issue_certificate: hanya authenticated
REVOKE ALL ON FUNCTION public.issue_certificate() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.issue_certificate() TO authenticated;

-- verify_certificate: boleh anon dan authenticated
REVOKE ALL ON FUNCTION public.verify_certificate(TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.verify_certificate(TEXT) TO anon, authenticated;
