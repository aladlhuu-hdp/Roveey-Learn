-- ==============================================================================
-- RLS & SECURITY VERIFICATION SUITE
-- Project: RooveyLearn - Digital Learning Platform for Mangrove Conservation
-- Description: Skenario uji terisolasi untuk dijalankan manual di Supabase SQL Editor.
-- Output: Menghasilkan tabel ringkasan hasil uji (No, Skenario, Status, Keterangan).
-- Keamanan: Dibungkus dalam transaksi BEGIN ... ROLLBACK sehingga database tetap bersih.
-- ==============================================================================

BEGIN;

-- ==============================================================================
-- 0. TABEL PENAMPUNG HASIL UJI (DIBUAT DALAM TRANSAKSI & DI-ROLLBACK DI AKHIR)
-- ==============================================================================
DROP TABLE IF EXISTS public.test_results;
CREATE TABLE public.test_results (
    no INT,
    skenario TEXT,
    status TEXT, -- 'PASS' atau 'FAIL'
    keterangan TEXT
);

-- Berikan izin akses pada tabel untuk semua role selama pengujian
GRANT ALL ON TABLE public.test_results TO anon, authenticated, public;

-- ==============================================================================
-- SETUP: BUAT DATA DUMMY TEST (FIXTURES)
-- ==============================================================================
DO $$
DECLARE
    v_user_a UUID := 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
    v_user_b UUID := 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb';
BEGIN
    -- 1. Buat user dummy di auth.users jika belum ada
    INSERT INTO auth.users (id, email, raw_user_meta_data, role, aud)
    VALUES 
        (v_user_a, 'usera@rooveylearn.test', '{"name": "Peserta A", "community_name": "Pokdarwis Pesisir"}'::jsonb, 'authenticated', 'authenticated'),
        (v_user_b, 'userb@rooveylearn.test', '{"name": "Peserta B", "community_name": "Relawan Mangrove"}'::jsonb, 'authenticated', 'authenticated')
    ON CONFLICT (id) DO NOTHING;

    -- 2. Pastikan profil pengguna tersedia di public.profiles
    INSERT INTO public.profiles (id, name, community_name)
    VALUES 
        (v_user_a, 'Peserta A', 'Pokdarwis Pesisir'),
        (v_user_b, 'Peserta B', 'Relawan Mangrove')
    ON CONFLICT (id) DO UPDATE SET 
        name = EXCLUDED.name,
        community_name = EXCLUDED.community_name;

    -- 3. Siapkan 5 soal pretest terkontrol untuk pengujian perhitungan skor (Skenario 4)
    INSERT INTO public.quiz_questions (id, quiz_type, question_text, options, order_index, is_active)
    VALUES 
        ('33333333-3333-3333-3333-333333333301', 'pretest', 'Soal Test Pretest 1', '["A","B","C","D"]'::jsonb, 1, true),
        ('33333333-3333-3333-3333-333333333302', 'pretest', 'Soal Test Pretest 2', '["A","B","C","D"]'::jsonb, 2, true),
        ('33333333-3333-3333-3333-333333333303', 'pretest', 'Soal Test Pretest 3', '["A","B","C","D"]'::jsonb, 3, true),
        ('33333333-3333-3333-3333-333333333304', 'pretest', 'Soal Test Pretest 4', '["A","B","C","D"]'::jsonb, 4, true),
        ('33333333-3333-3333-3333-333333333305', 'pretest', 'Soal Test Pretest 5', '["A","B","C","D"]'::jsonb, 5, true)
    ON CONFLICT (id) DO NOTHING;

    INSERT INTO public.quiz_answers (question_id, correct_option_index, explanation)
    VALUES 
        ('33333333-3333-3333-3333-333333333301', 0, 'Penjelasan Kunci 1'),
        ('33333333-3333-3333-3333-333333333302', 1, 'Penjelasan Kunci 2'),
        ('33333333-3333-3333-3333-333333333303', 2, 'Penjelasan Kunci 3'),
        ('33333333-3333-3333-3333-333333333304', 3, 'Penjelasan Kunci 4'),
        ('33333333-3333-3333-3333-333333333305', 0, 'Penjelasan Kunci 5')
    ON CONFLICT (question_id) DO NOTHING;
END;
$$;

-- ==============================================================================
-- SKENARIO 1: HAK AKSES ROLE ANON (TABEL & RPC GRANTS - Poin a)
-- ==============================================================================
DO $$
DECLARE
    v_count INT;
    v_error_caught BOOLEAN := false;
    v_public_cert JSONB;
    v_checks_total INT := 0;
    v_checks_passed INT := 0;
    v_status TEXT;
BEGIN
    -- Simulasikan role anon
    SET LOCAL ROLE anon;
    PERFORM set_config('request.jwt.claims', '{"role": "anon"}', true);
    PERFORM set_config('request.jwt.claim.sub', '', true);
    PERFORM set_config('request.jwt.claim.role', 'anon', true);

    -- 1. Anon BISA membaca modul dan materi published
    SELECT COUNT(*) INTO v_count FROM public.learning_modules WHERE status = 'published';
    v_checks_total := v_checks_total + 1;
    IF NOT (v_count >= 5) THEN
        RAISE EXCEPTION 'Assertion failed: Anon gagal membaca modul published. Ditemukan: %', v_count;
    END IF;
    v_checks_passed := v_checks_passed + 1;

    SELECT COUNT(*) INTO v_count FROM public.learning_materials WHERE status = 'published';
    v_checks_total := v_checks_total + 1;
    IF NOT (v_count >= 5) THEN
        RAISE EXCEPTION 'Assertion failed: Anon gagal membaca materi published. Ditemukan: %', v_count;
    END IF;
    v_checks_passed := v_checks_passed + 1;

    -- 2. Anon BISA membaca pertanyaan kuis aktif (tanpa kunci)
    SELECT COUNT(*) INTO v_count FROM public.quiz_questions WHERE is_active = true;
    v_checks_total := v_checks_total + 1;
    IF NOT (v_count >= 5) THEN
        RAISE EXCEPTION 'Assertion failed: Anon gagal membaca daftar soal aktif. Ditemukan: %', v_count;
    END IF;
    v_checks_passed := v_checks_passed + 1;

    -- 3. Anon TIDAK BISA membaca tabel quiz_answers
    v_error_caught := false;
    BEGIN
        SELECT COUNT(*) INTO v_count FROM public.quiz_answers;
        IF v_count > 0 THEN
            RAISE EXCEPTION 'Anon berhasil membaca data quiz_answers.';
        END IF;
    EXCEPTION WHEN insufficient_privilege THEN
        v_error_caught := true;
    END;
    v_checks_total := v_checks_total + 1;
    IF NOT (v_error_caught = true) THEN
        RAISE EXCEPTION 'Assertion failed: quiz_answers tidak memblokir akses role anon.';
    END IF;
    v_checks_passed := v_checks_passed + 1;

    -- 4. Anon TIDAK BISA membaca data pengguna (profiles, progress, assessment_results, certificates)
    SELECT COUNT(*) INTO v_count FROM public.profiles;
    v_checks_total := v_checks_total + 1;
    IF NOT (v_count = 0) THEN
        RAISE EXCEPTION 'Assertion failed: Anon dapat melihat data profiles.';
    END IF;
    v_checks_passed := v_checks_passed + 1;

    SELECT COUNT(*) INTO v_count FROM public.user_module_progress;
    v_checks_total := v_checks_total + 1;
    IF NOT (v_count = 0) THEN
        RAISE EXCEPTION 'Assertion failed: Anon dapat melihat data user_module_progress.';
    END IF;
    v_checks_passed := v_checks_passed + 1;

    SELECT COUNT(*) INTO v_count FROM public.assessment_results;
    v_checks_total := v_checks_total + 1;
    IF NOT (v_count = 0) THEN
        RAISE EXCEPTION 'Assertion failed: Anon dapat melihat data assessment_results.';
    END IF;
    v_checks_passed := v_checks_passed + 1;

    SELECT COUNT(*) INTO v_count FROM public.certificates;
    v_checks_total := v_checks_total + 1;
    IF NOT (v_count = 0) THEN
        RAISE EXCEPTION 'Assertion failed: Anon dapat melihat data certificates.';
    END IF;
    v_checks_passed := v_checks_passed + 1;

    -- 5. Poin a: Anon DITOLAK eksekusi RPC privat
    v_error_caught := false;
    BEGIN
        PERFORM public.complete_module(1);
    EXCEPTION WHEN insufficient_privilege THEN
        v_error_caught := true;
    END;
    v_checks_total := v_checks_total + 1;
    IF NOT (v_error_caught = true) THEN
        RAISE EXCEPTION 'Assertion failed: complete_module tidak menolak role anon.';
    END IF;
    v_checks_passed := v_checks_passed + 1;

    v_error_caught := false;
    BEGIN
        PERFORM public.submit_quiz('final', NULL, '[]'::jsonb);
    EXCEPTION WHEN insufficient_privilege THEN
        v_error_caught := true;
    END;
    v_checks_total := v_checks_total + 1;
    IF NOT (v_error_caught = true) THEN
        RAISE EXCEPTION 'Assertion failed: submit_quiz tidak menolak role anon.';
    END IF;
    v_checks_passed := v_checks_passed + 1;

    v_error_caught := false;
    BEGIN
        PERFORM public.issue_certificate();
    EXCEPTION WHEN insufficient_privilege THEN
        v_error_caught := true;
    END;
    v_checks_total := v_checks_total + 1;
    IF NOT (v_error_caught = true) THEN
        RAISE EXCEPTION 'Assertion failed: issue_certificate tidak menolak role anon.';
    END IF;
    v_checks_passed := v_checks_passed + 1;

    -- 6. Poin a: Anon DIIZINKAN eksekusi RPC verify_certificate
    v_public_cert := public.verify_certificate('ROOVEY-NONEXISTENT');
    v_checks_total := v_checks_total + 1;
    IF NOT ((v_public_cert->>'valid')::BOOLEAN = false) THEN
        RAISE EXCEPTION 'Assertion failed: verify_certificate gagal dieksekusi role anon.';
    END IF;
    v_checks_passed := v_checks_passed + 1;

    -- Evaluasi status: HANYA PASS jika seluruh 12 assertion benar-benar tereksekusi dan lolos
    IF v_checks_passed = v_checks_total AND v_checks_total = 12 THEN
        v_status := 'PASS';
    ELSE
        RAISE EXCEPTION 'Inkonsistensi assertion: hanya % dari % pengecekan tercapai', v_checks_passed, v_checks_total;
    END IF;

    RESET ROLE;
    EXECUTE 'INSERT INTO public.test_results (no, skenario, status, keterangan) VALUES ($1, $2, $3, $4)'
    USING 1, 'Hak Akses Role Anon (Tabel & RPC Grants)', v_status, 'Lolos seluruh 12 assertion: Anon diblokir dari data pengguna & RPC privat; diizinkan baca materi & verifikasi sertifikat.';
END;
$$;

-- ==============================================================================
-- SKENARIO 2: ISOLASI PENGGUNA & PROTEKSI MUTASI PROGRESS (Poin f)
-- ==============================================================================
DO $$
DECLARE
    v_user_a UUID := 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
    v_user_b UUID := 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb';
    v_count INT;
    v_rows_affected INT;
    v_error_caught BOOLEAN := false;
    v_checks_total INT := 0;
    v_checks_passed INT := 0;
    v_status TEXT;
BEGIN
    RESET ROLE;
    INSERT INTO public.user_module_progress (user_id, module_id, status, progress_percent)
    VALUES (v_user_b, 1, 'in_progress', 50)
    ON CONFLICT (user_id, module_id) DO UPDATE SET progress_percent = 50;

    -- Simulasikan login sebagai User A
    SET LOCAL ROLE authenticated;
    PERFORM set_config('request.jwt.claims', json_build_object('sub', v_user_a, 'role', 'authenticated')::text, true);
    PERFORM set_config('request.jwt.claim.sub', v_user_a::text, true);
    PERFORM set_config('request.jwt.claim.role', 'authenticated', true);

    -- 1. User A hanya membaca profil miliknya
    SELECT COUNT(*) INTO v_count FROM public.profiles;
    v_checks_total := v_checks_total + 1;
    IF NOT (v_count = 1) THEN
        RAISE EXCEPTION 'Assertion failed: User A melihat lebih dari 1 profil. Total: %', v_count;
    END IF;
    v_checks_passed := v_checks_passed + 1;

    SELECT COUNT(*) INTO v_count FROM public.profiles WHERE id = v_user_b;
    v_checks_total := v_checks_total + 1;
    IF NOT (v_count = 0) THEN
        RAISE EXCEPTION 'Assertion failed: User A bisa melihat profil User B.';
    END IF;
    v_checks_passed := v_checks_passed + 1;

    -- 2. User A tidak bisa membaca progres User B
    SELECT COUNT(*) INTO v_count FROM public.user_module_progress WHERE user_id = v_user_b;
    v_checks_total := v_checks_total + 1;
    IF NOT (v_count = 0) THEN
        RAISE EXCEPTION 'Assertion failed: User A bisa melihat progres User B.';
    END IF;
    v_checks_passed := v_checks_passed + 1;

    -- 3. User A mencoba UPDATE progres User B -> 0 rows affected
    UPDATE public.user_module_progress SET progress_percent = 100 WHERE user_id = v_user_b;
    GET DIAGNOSTICS v_rows_affected = ROW_COUNT;
    v_checks_total := v_checks_total + 1;
    IF NOT (v_rows_affected = 0) THEN
        RAISE EXCEPTION 'Assertion failed: User A berhasil mengupdate progres User B (baris terpengaruh: %)', v_rows_affected;
    END IF;
    v_checks_passed := v_checks_passed + 1;

    -- 4. User A membuat progres miliknya
    INSERT INTO public.user_module_progress (user_id, module_id, status, progress_percent)
    VALUES (v_user_a, 1, 'in_progress', 30)
    ON CONFLICT (user_id, module_id) DO UPDATE SET progress_percent = 30;

    -- 5. User A mencoba update status = 'completed' secara langsung -> Ditolak RLS WITH CHECK
    v_error_caught := false;
    BEGIN
        UPDATE public.user_module_progress 
        SET status = 'completed', progress_percent = 100
        WHERE user_id = v_user_a AND module_id = 1;
    EXCEPTION WHEN check_violation OR insufficient_privilege THEN
        v_error_caught := true;
    END;
    v_checks_total := v_checks_total + 1;
    IF NOT (v_error_caught = true) THEN
        RAISE EXCEPTION 'Assertion failed: RLS tidak memblokir penulisan langsung status completed.';
    END IF;
    v_checks_passed := v_checks_passed + 1;

    -- 6. User A mencoba mutasi user_id atau module_id -> Ditolak Trigger
    v_error_caught := false;
    BEGIN
        UPDATE public.user_module_progress 
        SET user_id = v_user_b
        WHERE user_id = v_user_a AND module_id = 1;
    EXCEPTION WHEN SQLSTATE '42501' THEN
        v_error_caught := true;
    END;
    v_checks_total := v_checks_total + 1;
    IF NOT (v_error_caught = true) THEN
        RAISE EXCEPTION 'Assertion failed: Trigger tidak memblokir mutasi user_id.';
    END IF;
    v_checks_passed := v_checks_passed + 1;

    v_error_caught := false;
    BEGIN
        UPDATE public.user_module_progress 
        SET module_id = 2
        WHERE user_id = v_user_a AND module_id = 1;
    EXCEPTION WHEN SQLSTATE '42501' THEN
        v_error_caught := true;
    END;
    v_checks_total := v_checks_total + 1;
    IF NOT (v_error_caught = true) THEN
        RAISE EXCEPTION 'Assertion failed: Trigger tidak memblokir mutasi module_id.';
    END IF;
    v_checks_passed := v_checks_passed + 1;

    -- Evaluasi status: HANYA PASS jika seluruh 7 assertion benar-benar tereksekusi dan lolos
    IF v_checks_passed = v_checks_total AND v_checks_total = 7 THEN
        v_status := 'PASS';
    ELSE
        RAISE EXCEPTION 'Inkonsistensi assertion: hanya % dari % pengecekan tercapai', v_checks_passed, v_checks_total;
    END IF;

    RESET ROLE;
    EXECUTE 'INSERT INTO public.test_results (no, skenario, status, keterangan) VALUES ($1, $2, $3, $4)'
    USING 2, 'Isolasi Pengguna & Proteksi Mutasi Progress (Poin f)', v_status, 'Lolos seluruh 7 assertion: User A terisolasi dari User B; mutasi user_id, module_id, dan status completed diblokir.';
END;
$$;

-- ==============================================================================
-- SKENARIO 3: BLOKIR INSERT LANGSUNG KE ASSESSMENT_RESULTS / CERTIFICATES
-- ==============================================================================
DO $$
DECLARE
    v_user_a UUID := 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
    v_blocked BOOLEAN := false;
    v_checks_total INT := 0;
    v_checks_passed INT := 0;
    v_status TEXT;
BEGIN
    SET LOCAL ROLE authenticated;
    PERFORM set_config('request.jwt.claims', json_build_object('sub', v_user_a, 'role', 'authenticated')::text, true);
    PERFORM set_config('request.jwt.claim.sub', v_user_a::text, true);
    PERFORM set_config('request.jwt.claim.role', 'authenticated', true);

    -- 1. Coba INSERT langsung ke assessment_results
    BEGIN
        INSERT INTO public.assessment_results (
            user_id, assessment_type, score, total_questions, correct_answers, is_passed
        ) VALUES (
            v_user_a, 'final', 100, 5, 5, true
        );
    EXCEPTION WHEN insufficient_privilege OR check_violation THEN
        v_blocked := true;
    END;
    v_checks_total := v_checks_total + 1;
    IF NOT (v_blocked = true) THEN
        RAISE EXCEPTION 'Assertion failed: RLS tidak memblokir INSERT langsung ke assessment_results.';
    END IF;
    v_checks_passed := v_checks_passed + 1;

    -- 2. Coba INSERT langsung ke certificates
    v_blocked := false;
    BEGIN
        INSERT INTO public.certificates (
            user_id, certificate_number, assessment_result_id, final_score
        ) VALUES (
            v_user_a, 'PALSU-123456', gen_random_uuid(), 100
        );
    EXCEPTION WHEN insufficient_privilege OR check_violation THEN
        v_blocked := true;
    END;
    v_checks_total := v_checks_total + 1;
    IF NOT (v_blocked = true) THEN
        RAISE EXCEPTION 'Assertion failed: RLS tidak memblokir INSERT langsung ke certificates.';
    END IF;
    v_checks_passed := v_checks_passed + 1;

    -- Evaluasi status: HANYA PASS jika seluruh 2 assertion benar-benar tereksekusi dan lolos
    IF v_checks_passed = v_checks_total AND v_checks_total = 2 THEN
        v_status := 'PASS';
    ELSE
        RAISE EXCEPTION 'Inkonsistensi assertion: hanya % dari % pengecekan tercapai', v_checks_passed, v_checks_total;
    END IF;

    RESET ROLE;
    EXECUTE 'INSERT INTO public.test_results (no, skenario, status, keterangan) VALUES ($1, $2, $3, $4)'
    USING 3, 'Blokir INSERT Langsung Hasil & Sertifikat', v_status, 'Lolos seluruh 2 assertion: Klien diblokir dari INSERT langsung ke assessment_results dan certificates.';
END;
$$;

-- ==============================================================================
-- SKENARIO 4: VALIDASI PAYLOAD SUBMIT_QUIZ & PERHITUNGAN SKOR BANK (Poin c)
-- ==============================================================================
DO $$
DECLARE
    v_user_a UUID := 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
    v_res JSONB;
    v_error_caught BOOLEAN := false;
    v_partial_answer JSONB;
    v_duplicate_answer JSONB;
    v_invalid_qid_answer JSONB;
    v_checks_total INT := 0;
    v_checks_passed INT := 0;
    v_status TEXT;
BEGIN
    SET LOCAL ROLE authenticated;
    PERFORM set_config('request.jwt.claims', json_build_object('sub', v_user_a, 'role', 'authenticated')::text, true);
    PERFORM set_config('request.jwt.claim.sub', v_user_a::text, true);
    PERFORM set_config('request.jwt.claim.role', 'authenticated', true);

    -- 1. Poin c: Tolak jika ID soal duplikat dalam lembar jawaban
    v_duplicate_answer := '[
        {"question_id": "33333333-3333-3333-3333-333333333301", "selected_option": 0},
        {"question_id": "33333333-3333-3333-3333-333333333301", "selected_option": 0}
    ]'::jsonb;
    
    v_error_caught := false;
    BEGIN
        PERFORM public.submit_quiz('pretest', NULL, v_duplicate_answer);
    EXCEPTION WHEN SQLSTATE '22023' THEN
        v_error_caught := true;
    END;
    v_checks_total := v_checks_total + 1;
    IF NOT (v_error_caught = true) THEN
        RAISE EXCEPTION 'Assertion failed: submit_quiz tidak menolak soal duplikat.';
    END IF;
    v_checks_passed := v_checks_passed + 1;

    -- 2. Poin c: Tolak jika ID soal tidak terdaftar pada paket kuis
    v_invalid_qid_answer := '[
        {"question_id": "99999999-9999-9999-9999-999999999999", "selected_option": 1}
    ]'::jsonb;
    
    v_error_caught := false;
    BEGIN
        PERFORM public.submit_quiz('pretest', NULL, v_invalid_qid_answer);
    EXCEPTION WHEN SQLSTATE '22023' THEN
        v_error_caught := true;
    END;
    v_checks_total := v_checks_total + 1;
    IF NOT (v_error_caught = true) THEN
        RAISE EXCEPTION 'Assertion failed: submit_quiz tidak menolak ID soal asing.';
    END IF;
    v_checks_passed := v_checks_passed + 1;

    -- 3. Poin c: Kirim 1 jawaban benar dari 5 soal di bank -> menghasilkan skor 20%
    v_partial_answer := '[
        {"question_id": "33333333-3333-3333-3333-333333333301", "selected_option": 0}
    ]'::jsonb;

    v_res := public.submit_quiz('pretest', NULL, v_partial_answer);

    v_checks_total := v_checks_total + 1;
    IF NOT ((v_res->>'total_questions')::INT = 5) THEN
        RAISE EXCEPTION 'Assertion failed: Total soal seharusnya 5 (sesuai bank). Diterima: %', (v_res->>'total_questions');
    END IF;
    v_checks_passed := v_checks_passed + 1;

    v_checks_total := v_checks_total + 1;
    IF NOT ((v_res->>'correct_answers')::INT = 1) THEN
        RAISE EXCEPTION 'Assertion failed: Jumlah benar seharusnya 1. Diterima: %', (v_res->>'correct_answers');
    END IF;
    v_checks_passed := v_checks_passed + 1;

    v_checks_total := v_checks_total + 1;
    IF NOT ((v_res->>'score')::INT = 20) THEN
        RAISE EXCEPTION 'Assertion failed: Skor 1 benar dari 5 soal seharusnya 20%%. Diterima: %', (v_res->>'score');
    END IF;
    v_checks_passed := v_checks_passed + 1;

    -- Evaluasi status: HANYA PASS jika seluruh 5 assertion benar-benar tereksekusi dan lolos
    IF v_checks_passed = v_checks_total AND v_checks_total = 5 THEN
        v_status := 'PASS';
    ELSE
        RAISE EXCEPTION 'Inkonsistensi assertion: hanya % dari % pengecekan tercapai', v_checks_passed, v_checks_total;
    END IF;

    RESET ROLE;
    EXECUTE 'INSERT INTO public.test_results (no, skenario, status, keterangan) VALUES ($1, $2, $3, $4)'
    USING 4, 'Validasi Payload & Skor dari Bank Soal (Poin c)', v_status, 'Lolos seluruh 5 assertion: Tolak duplikat & ID asing; 1 benar dari 5 soal bank menghasilkan skor 20%.';
END;
$$;

-- ==============================================================================
-- SKENARIO 5: ALUR BERURUTAN MODUL (complete_module)
-- ==============================================================================
DO $$
DECLARE
    v_user_a UUID := 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
    v_exception_caught BOOLEAN := false;
    v_res JSONB;
    v_checks_total INT := 0;
    v_checks_passed INT := 0;
    v_status TEXT;
BEGIN
    SET LOCAL ROLE authenticated;
    PERFORM set_config('request.jwt.claims', json_build_object('sub', v_user_a, 'role', 'authenticated')::text, true);
    PERFORM set_config('request.jwt.claim.sub', v_user_a::text, true);
    PERFORM set_config('request.jwt.claim.role', 'authenticated', true);

    -- 1. Coba selesaikan Modul 2 sebelum Modul 1 -> Ditolak P0001
    BEGIN
        v_res := public.complete_module(2);
    EXCEPTION WHEN SQLSTATE 'P0001' THEN
        v_exception_caught := true;
    END;
    v_checks_total := v_checks_total + 1;
    IF NOT (v_exception_caught = true) THEN
        RAISE EXCEPTION 'Assertion failed: Melompati urutan modul tidak ditolak.';
    END IF;
    v_checks_passed := v_checks_passed + 1;

    -- 2. Selesaikan Modul 1
    v_res := public.complete_module(1);
    v_checks_total := v_checks_total + 1;
    IF NOT ((v_res->>'success')::BOOLEAN = true) THEN
        RAISE EXCEPTION 'Assertion failed: Gagal menyelesaikan modul 1.';
    END IF;
    v_checks_passed := v_checks_passed + 1;

    -- 3. Selesaikan Modul 2
    v_res := public.complete_module(2);
    v_checks_total := v_checks_total + 1;
    IF NOT ((v_res->>'success')::BOOLEAN = true) THEN
        RAISE EXCEPTION 'Assertion failed: Gagal menyelesaikan modul 2.';
    END IF;
    v_checks_passed := v_checks_passed + 1;

    -- Evaluasi status: HANYA PASS jika seluruh 3 assertion benar-benar tereksekusi dan lolos
    IF v_checks_passed = v_checks_total AND v_checks_total = 3 THEN
        v_status := 'PASS';
    ELSE
        RAISE EXCEPTION 'Inkonsistensi assertion: hanya % dari % pengecekan tercapai', v_checks_passed, v_checks_total;
    END IF;

    RESET ROLE;
    EXECUTE 'INSERT INTO public.test_results (no, skenario, status, keterangan) VALUES ($1, $2, $3, $4)'
    USING 5, 'Penegakan Urutan Modul Bertahap', v_status, 'Lolos seluruh 3 assertion: Melompati modul ditolak; modul 1 dan 2 selesai berurutan.';
END;
$$;

-- ==============================================================================
-- SKENARIO 6: PRASYARAT 5 MODUL UNTUK SUBMIT_QUIZ('final') (Poin d)
-- ==============================================================================
DO $$
DECLARE
    v_user_a UUID := 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
    v_exception_caught BOOLEAN := false;
    v_answers JSONB;
    v_res JSONB;
    v_checks_total INT := 0;
    v_checks_passed INT := 0;
    v_status TEXT;
BEGIN
    SET LOCAL ROLE authenticated;
    PERFORM set_config('request.jwt.claims', json_build_object('sub', v_user_a, 'role', 'authenticated')::text, true);
    PERFORM set_config('request.jwt.claim.sub', v_user_a::text, true);
    PERFORM set_config('request.jwt.claim.role', 'authenticated', true);

    v_answers := '[
        {"question_id": "22222222-2222-2222-2222-222222222201", "selected_option": 1}
    ]'::jsonb;

    -- User A baru selesai Modul 1 & 2. Modul 3, 4, 5 belum selesai -> Ditolak P0001
    v_exception_caught := false;
    BEGIN
        PERFORM public.submit_quiz('final', NULL, v_answers);
    EXCEPTION WHEN SQLSTATE 'P0001' THEN
        v_exception_caught := true;
    END;
    v_checks_total := v_checks_total + 1;
    IF NOT (v_exception_caught = true) THEN
        RAISE EXCEPTION 'Assertion failed: submit_quiz(final) tidak menolak modul < 5.';
    END IF;
    v_checks_passed := v_checks_passed + 1;

    -- Selesaikan Modul 3, 4, 5
    PERFORM public.complete_module(3);
    PERFORM public.complete_module(4);
    PERFORM public.complete_module(5);

    -- Setelah seluruh 5 modul selesai, kuis akhir diizinkan
    v_res := public.submit_quiz('final', NULL, v_answers);
    v_checks_total := v_checks_total + 1;
    IF NOT ((v_res->>'quiz_type') = 'final') THEN
        RAISE EXCEPTION 'Assertion failed: submit_quiz(final) gagal setelah 5 modul tuntas.';
    END IF;
    v_checks_passed := v_checks_passed + 1;

    -- Evaluasi status: HANYA PASS jika seluruh 2 assertion benar-benar tereksekusi dan lolos
    IF v_checks_passed = v_checks_total AND v_checks_total = 2 THEN
        v_status := 'PASS';
    ELSE
        RAISE EXCEPTION 'Inkonsistensi assertion: hanya % dari % pengecekan tercapai', v_checks_passed, v_checks_total;
    END IF;

    RESET ROLE;
    EXECUTE 'INSERT INTO public.test_results (no, skenario, status, keterangan) VALUES ($1, $2, $3, $4)'
    USING 6, 'Prasyarat 5 Modul untuk Kuis Akhir (Poin d)', v_status, 'Lolos seluruh 2 assertion: Kuis akhir ditolak saat modul < 5; diizinkan setelah kelima modul berstatus completed.';
END;
$$;

-- ==============================================================================
-- SKENARIO 7: BATASAN 3 PERCOBAAN KUIS AKHIR PER 24 JAM (Poin e)
-- ==============================================================================
DO $$
DECLARE
    v_user_a UUID := 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
    v_answers JSONB;
    v_exception_caught BOOLEAN := false;
    v_i INT;
    v_checks_total INT := 0;
    v_checks_passed INT := 0;
    v_status TEXT;
BEGIN
    RESET ROLE;
    DELETE FROM public.assessment_results WHERE user_id = v_user_a AND assessment_type = 'final';

    SET LOCAL ROLE authenticated;
    PERFORM set_config('request.jwt.claims', json_build_object('sub', v_user_a, 'role', 'authenticated')::text, true);
    PERFORM set_config('request.jwt.claim.sub', v_user_a::text, true);
    PERFORM set_config('request.jwt.claim.role', 'authenticated', true);

    v_answers := '[
        {"question_id": "22222222-2222-2222-2222-222222222201", "selected_option": 1}
    ]'::jsonb;

    -- Lakukan 3 percobaan (diizinkan)
    FOR v_i IN 1..3 LOOP
        PERFORM public.submit_quiz('final', NULL, v_answers);
    END LOOP;
    v_checks_total := v_checks_total + 1;
    IF NOT (v_i = 4) THEN
        RAISE EXCEPTION 'Assertion failed: 3 percobaan kuis awal tidak selesai.';
    END IF;
    v_checks_passed := v_checks_passed + 1;

    -- Percobaan ke-4 dalam 24 jam harus DITOLAK dengan kode P0003
    v_exception_caught := false;
    BEGIN
        PERFORM public.submit_quiz('final', NULL, v_answers);
    EXCEPTION WHEN SQLSTATE 'P0003' THEN
        v_exception_caught := true;
    END;
    v_checks_total := v_checks_total + 1;
    IF NOT (v_exception_caught = true) THEN
        RAISE EXCEPTION 'Assertion failed: Percobaan ke-4 tidak memicu limit exception P0003.';
    END IF;
    v_checks_passed := v_checks_passed + 1;

    -- Evaluasi status: HANYA PASS jika seluruh 2 assertion benar-benar tereksekusi dan lolos
    IF v_checks_passed = v_checks_total AND v_checks_total = 2 THEN
        v_status := 'PASS';
    ELSE
        RAISE EXCEPTION 'Inkonsistensi assertion: hanya % dari % pengecekan tercapai', v_checks_passed, v_checks_total;
    END IF;

    RESET ROLE;
    EXECUTE 'INSERT INTO public.test_results (no, skenario, status, keterangan) VALUES ($1, $2, $3, $4)'
    USING 7, 'Pembatasan 3 Percobaan Kuis Akhir / 24 Jam (Poin e)', v_status, 'Lolos seluruh 2 assertion: Percobaan ke-1 s/d 3 diizinkan; percobaan ke-4 ditolak dengan exception P0003.';
END;
$$;

-- ==============================================================================
-- SKENARIO 8: PENERBITAN SERTIFIKAT BERBASIS NILAI TERBAIK (Keputusan 1)
-- ==============================================================================
DO $$
DECLARE
    v_user_a UUID := 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
    v_res JSONB;
    v_cert_record RECORD;
    v_exception_caught BOOLEAN := false;
    v_checks_total INT := 0;
    v_checks_passed INT := 0;
    v_status TEXT;
BEGIN
    RESET ROLE;
    DELETE FROM public.certificates WHERE user_id = v_user_a;
    DELETE FROM public.assessment_results WHERE user_id = v_user_a AND assessment_type = 'final';

    -- 1. Simulasi nilai asesmen akhir = 79% (< 80%)
    INSERT INTO public.assessment_results (
        user_id, assessment_type, score, total_questions, correct_answers, is_passed
    ) VALUES (
        v_user_a, 'final', 79, 100, 79, false
    );

    SET LOCAL ROLE authenticated;
    PERFORM set_config('request.jwt.claims', json_build_object('sub', v_user_a, 'role', 'authenticated')::text, true);
    PERFORM set_config('request.jwt.claim.sub', v_user_a::text, true);
    PERFORM set_config('request.jwt.claim.role', 'authenticated', true);

    -- Coba terbitkan sertifikat dengan nilai 79 -> Ditolak P0001
    v_exception_caught := false;
    BEGIN
        v_res := public.issue_certificate();
    EXCEPTION WHEN SQLSTATE 'P0001' THEN
        v_exception_caught := true;
    END;
    v_checks_total := v_checks_total + 1;
    IF NOT (v_exception_caught = true) THEN
        RAISE EXCEPTION 'Assertion failed: issue_certificate tidak menolak skor 79%%.';
    END IF;
    v_checks_passed := v_checks_passed + 1;

    -- 2. Simulasi pencapaian nilai kelulusan = 80% (Best Score)
    RESET ROLE;
    INSERT INTO public.assessment_results (
        user_id, assessment_type, score, total_questions, correct_answers, is_passed
    ) VALUES (
        v_user_a, 'final', 80, 100, 80, true
    );

    SET LOCAL ROLE authenticated;
    PERFORM set_config('request.jwt.claims', json_build_object('sub', v_user_a, 'role', 'authenticated')::text, true);
    PERFORM set_config('request.jwt.claim.sub', v_user_a::text, true);
    PERFORM set_config('request.jwt.claim.role', 'authenticated', true);

    -- Terbitkan sertifikat -> Berhasil
    v_res := public.issue_certificate();
    v_checks_total := v_checks_total + 1;
    IF NOT ((v_res->>'success')::BOOLEAN = true AND (v_res->'certificate'->>'final_score')::INT = 80) THEN
        RAISE EXCEPTION 'Assertion failed: issue_certificate gagal menerbitkan sertifikat dengan nilai terbaik 80.';
    END IF;
    v_checks_passed := v_checks_passed + 1;

    -- Verifikasi kolom assessment_result_id pada tabel certificates tercatat
    RESET ROLE;
    SELECT * INTO v_cert_record FROM public.certificates WHERE user_id = v_user_a AND status = 'active';
    v_checks_total := v_checks_total + 1;
    IF NOT (v_cert_record.assessment_result_id IS NOT NULL AND v_cert_record.final_score = 80) THEN
        RAISE EXCEPTION 'Assertion failed: assessment_result_id atau final_score salah pada tabel certificates.';
    END IF;
    v_checks_passed := v_checks_passed + 1;

    -- Idempotensi: Panggilan kedua mengembalikan sertifikat aktif yang sama
    SET LOCAL ROLE authenticated;
    PERFORM set_config('request.jwt.claims', json_build_object('sub', v_user_a, 'role', 'authenticated')::text, true);
    PERFORM set_config('request.jwt.claim.sub', v_user_a::text, true);
    PERFORM set_config('request.jwt.claim.role', 'authenticated', true);

    v_res := public.issue_certificate();
    v_checks_total := v_checks_total + 1;
    IF NOT ((v_res->>'is_new')::BOOLEAN = false) THEN
        RAISE EXCEPTION 'Assertion failed: Penerbitan kedua seharusnya mengembalikan sertifikat aktif (is_new = false).';
    END IF;
    v_checks_passed := v_checks_passed + 1;

    -- Evaluasi status: HANYA PASS jika seluruh 4 assertion benar-benar tereksekusi dan lolos
    IF v_checks_passed = v_checks_total AND v_checks_total = 4 THEN
        v_status := 'PASS';
    ELSE
        RAISE EXCEPTION 'Inkonsistensi assertion: hanya % dari % pengecekan tercapai', v_checks_passed, v_checks_total;
    END IF;

    RESET ROLE;
    EXECUTE 'INSERT INTO public.test_results (no, skenario, status, keterangan) VALUES ($1, $2, $3, $4)'
    USING 8, 'Penerbitan Sertifikat Berbasis Nilai Terbaik (Keputusan 1)', v_status, 'Lolos seluruh 4 assertion: Skor 79 ditolak; skor 80 diterima; assessment_result_id tercatat; pemanggilan berulang idempotent.';
END;
$$;

-- ==============================================================================
-- SKENARIO 9: VERIFIKASI PUBLIK SERTIFIKAT TANPA DATA SENSITIF (Keputusan 4)
-- ==============================================================================
DO $$
DECLARE
    v_user_a UUID := 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
    v_cert_num TEXT;
    v_verify_res JSONB;
    v_checks_total INT := 0;
    v_checks_passed INT := 0;
    v_status TEXT;
BEGIN
    SELECT certificate_number INTO v_cert_num FROM public.certificates WHERE user_id = v_user_a AND status = 'active';

    -- Simulasikan role anon (publik)
    SET LOCAL ROLE anon;
    PERFORM set_config('request.jwt.claims', '{"role": "anon"}', true);
    PERFORM set_config('request.jwt.claim.sub', '', true);
    PERFORM set_config('request.jwt.claim.role', 'anon', true);

    v_verify_res := public.verify_certificate(v_cert_num);

    v_checks_total := v_checks_total + 1;
    IF NOT ((v_verify_res->>'valid')::BOOLEAN = true) THEN
        RAISE EXCEPTION 'Assertion failed: Sertifikat valid gagal diverifikasi publik.';
    END IF;
    v_checks_passed := v_checks_passed + 1;

    v_checks_total := v_checks_total + 1;
    IF NOT ((v_verify_res->>'participant_name') = 'Peserta A' AND (v_verify_res->>'program_name') = 'Dasar Pengelolaan Mangrove') THEN
        RAISE EXCEPTION 'Assertion failed: Data nama peserta atau nama program tidak sesuai.';
    END IF;
    v_checks_passed := v_checks_passed + 1;

    v_checks_total := v_checks_total + 1;
    IF NOT ((v_verify_res ? 'certificate_number') AND (v_verify_res ? 'issued_at') AND (v_verify_res ? 'status')) THEN
        RAISE EXCEPTION 'Assertion failed: Atribut sertifikat publik tidak lengkap.';
    END IF;
    v_checks_passed := v_checks_passed + 1;

    -- Keputusan 4: Pastikan TIDAK ADA user_id, email, atau nilai numerik yang bocor
    v_checks_total := v_checks_total + 1;
    IF NOT ((v_verify_res ? 'user_id') = false AND (v_verify_res ? 'email') = false AND (v_verify_res ? 'final_score') = false) THEN
        RAISE EXCEPTION 'Assertion failed: Kebocoran data privat terdeteksi pada RPC verify_certificate.';
    END IF;
    v_checks_passed := v_checks_passed + 1;

    -- Evaluasi status: HANYA PASS jika seluruh 4 assertion benar-benar tereksekusi dan lolos
    IF v_checks_passed = v_checks_total AND v_checks_total = 4 THEN
        v_status := 'PASS';
    ELSE
        RAISE EXCEPTION 'Inkonsistensi assertion: hanya % dari % pengecekan tercapai', v_checks_passed, v_checks_total;
    END IF;

    RESET ROLE;
    EXECUTE 'INSERT INTO public.test_results (no, skenario, status, keterangan) VALUES ($1, $2, $3, $4)'
    USING 9, 'Verifikasi Publik Sertifikat Terbatas (Keputusan 4)', v_status, 'Lolos seluruh 4 assertion: Verifikasi berhasil tanpa membocorkan user_id, email, atau nilai numerik.';
END;
$$;

-- ==============================================================================
-- TAMPILKAN TABEL HASIL PENGUJIAN KE SQL EDITOR SUPABASE
-- ==============================================================================
SELECT 
    no AS "No",
    skenario AS "Skenario Uji",
    status AS "Status",
    keterangan AS "Keterangan"
FROM public.test_results
ORDER BY no ASC;

-- ==============================================================================
-- SELESAI: BERSIHKAN DATABASE DENGAN ROLLBACK
-- ==============================================================================
ROLLBACK;
