-- ==============================================================================
-- RLS & SECURITY VERIFICATION SUITE
-- Project: RooveyLearn - Digital Learning Platform for Mangrove Conservation
-- Description: Skenario uji terisolasi untuk dijalankan manual di Supabase SQL Editor.
-- Output: Menghasilkan tabel ringkasan hasil uji (No, Skenario, Status, Keterangan).
-- Keamanan: Dibungkus dalam transaksi BEGIN ... ROLLBACK sehingga database tetap bersih.
-- ==============================================================================

BEGIN;

-- ==============================================================================
-- 0. TABEL TEMPORER PENAMPUNG HASIL UJI
-- ==============================================================================
CREATE TEMP TABLE IF NOT EXISTS test_results (
    no INT,
    skenario TEXT,
    status TEXT, -- 'PASS' atau 'FAIL'
    keterangan TEXT
) ON COMMIT DROP;

-- Berikan izin akses pada tabel temporer untuk semua role selama pengujian
GRANT ALL ON TABLE test_results TO anon, authenticated, public;

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
BEGIN
    -- Simulasikan role anon
    SET LOCAL ROLE anon;
    PERFORM set_config('request.jwt.claims', '{"role": "anon"}', true);
    PERFORM set_config('request.jwt.claim.sub', '', true);
    PERFORM set_config('request.jwt.claim.role', 'anon', true);

    -- 1. Anon BISA membaca modul dan materi published
    SELECT COUNT(*) INTO v_count FROM public.learning_modules WHERE status = 'published';
    ASSERT v_count >= 5, 'Anon gagal membaca modul published.';

    SELECT COUNT(*) INTO v_count FROM public.learning_materials WHERE status = 'published';
    ASSERT v_count >= 5, 'Anon gagal membaca materi published.';

    -- 2. Anon BISA membaca pertanyaan kuis aktif (tanpa kunci)
    SELECT COUNT(*) INTO v_count FROM public.quiz_questions WHERE is_active = true;
    ASSERT v_count >= 5, 'Anon gagal membaca daftar soal aktif.';

    -- 3. Anon TIDAK BISA membaca tabel quiz_answers
    BEGIN
        SELECT COUNT(*) INTO v_count FROM public.quiz_answers;
        IF v_count > 0 THEN
            RAISE EXCEPTION 'Anon berhasil membaca data quiz_answers.';
        END IF;
    EXCEPTION WHEN insufficient_privilege THEN
        v_error_caught := true;
    END;
    ASSERT v_error_caught = true, 'quiz_answers tidak memblokir akses anon.';

    -- 4. Anon TIDAK BISA membaca data pengguna (profiles, progress, assessment_results, certificates)
    SELECT COUNT(*) INTO v_count FROM public.profiles;
    ASSERT v_count = 0, 'Anon melihat data profiles.';

    SELECT COUNT(*) INTO v_count FROM public.user_module_progress;
    ASSERT v_count = 0, 'Anon melihat user_module_progress.';

    SELECT COUNT(*) INTO v_count FROM public.assessment_results;
    ASSERT v_count = 0, 'Anon melihat assessment_results.';

    SELECT COUNT(*) INTO v_count FROM public.certificates;
    ASSERT v_count = 0, 'Anon melihat certificates.';

    -- 5. Poin a: Anon DITOLAK eksekusi RPC privat
    v_error_caught := false;
    BEGIN
        PERFORM public.complete_module(1);
    EXCEPTION WHEN insufficient_privilege THEN
        v_error_caught := true;
    END;
    ASSERT v_error_caught = true, 'complete_module tidak menolak anon.';

    v_error_caught := false;
    BEGIN
        PERFORM public.submit_quiz('final', NULL, '[]'::jsonb);
    EXCEPTION WHEN insufficient_privilege THEN
        v_error_caught := true;
    END;
    ASSERT v_error_caught = true, 'submit_quiz tidak menolak anon.';

    v_error_caught := false;
    BEGIN
        PERFORM public.issue_certificate();
    EXCEPTION WHEN insufficient_privilege THEN
        v_error_caught := true;
    END;
    ASSERT v_error_caught = true, 'issue_certificate tidak menolak anon.';

    -- 6. Poin a: Anon DIIZINKAN eksekusi RPC verify_certificate
    v_public_cert := public.verify_certificate('ROOVEY-NONEXISTENT');
    ASSERT (v_public_cert->>'valid')::BOOLEAN = false, 'verify_certificate gagal dieksekusi anon.';

    RESET ROLE;
    INSERT INTO test_results (no, skenario, status, keterangan)
    VALUES (1, 'Hak Akses Role Anon (Tabel & RPC Grants)', 'PASS', 'Anon diblokir dari data pengguna & RPC privat; diizinkan baca materi & verifikasi sertifikat.');
EXCEPTION WHEN OTHERS THEN
    RESET ROLE;
    INSERT INTO test_results (no, skenario, status, keterangan)
    VALUES (1, 'Hak Akses Role Anon (Tabel & RPC Grants)', 'FAIL', SQLERRM);
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
    ASSERT v_count = 1, 'User A melihat lebih dari 1 profil.';

    SELECT COUNT(*) INTO v_count FROM public.profiles WHERE id = v_user_b;
    ASSERT v_count = 0, 'User A bisa melihat profil User B.';

    -- 2. User A tidak bisa membaca progres User B
    SELECT COUNT(*) INTO v_count FROM public.user_module_progress WHERE user_id = v_user_b;
    ASSERT v_count = 0, 'User A bisa melihat progres User B.';

    -- 3. User A mencoba UPDATE progres User B -> 0 rows affected
    UPDATE public.user_module_progress SET progress_percent = 100 WHERE user_id = v_user_b;
    GET DIAGNOSTICS v_rows_affected = ROW_COUNT;
    ASSERT v_rows_affected = 0, 'User A berhasil mengupdate progres User B.';

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
    ASSERT v_error_caught = true, 'RLS tidak memblokir penulisan langsung status completed.';

    -- 6. User A mencoba mutasi user_id atau module_id -> Ditolak Trigger
    v_error_caught := false;
    BEGIN
        UPDATE public.user_module_progress 
        SET user_id = v_user_b
        WHERE user_id = v_user_a AND module_id = 1;
    EXCEPTION WHEN SQLSTATE '42501' THEN
        v_error_caught := true;
    END;
    ASSERT v_error_caught = true, 'Trigger tidak memblokir mutasi user_id.';

    v_error_caught := false;
    BEGIN
        UPDATE public.user_module_progress 
        SET module_id = 2
        WHERE user_id = v_user_a AND module_id = 1;
    EXCEPTION WHEN SQLSTATE '42501' THEN
        v_error_caught := true;
    END;
    ASSERT v_error_caught = true, 'Trigger tidak memblokir mutasi module_id.';

    RESET ROLE;
    INSERT INTO test_results (no, skenario, status, keterangan)
    VALUES (2, 'Isolasi Pengguna & Proteksi Mutasi Progress (Poin f)', 'PASS', 'User A terisolasi dari User B; mutasi user_id, module_id, dan status completed diblokir.');
EXCEPTION WHEN OTHERS THEN
    RESET ROLE;
    INSERT INTO test_results (no, skenario, status, keterangan)
    VALUES (2, 'Isolasi Pengguna & Proteksi Mutasi Progress (Poin f)', 'FAIL', SQLERRM);
END;
$$;

-- ==============================================================================
-- SKENARIO 3: BLOKIR INSERT LANGSUNG KE ASSESSMENT_RESULTS / CERTIFICATES
-- ==============================================================================
DO $$
DECLARE
    v_user_a UUID := 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
    v_blocked BOOLEAN := false;
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
    ASSERT v_blocked = true, 'RLS tidak memblokir INSERT langsung ke assessment_results.';

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
    ASSERT v_blocked = true, 'RLS tidak memblokir INSERT langsung ke certificates.';

    RESET ROLE;
    INSERT INTO test_results (no, skenario, status, keterangan)
    VALUES (3, 'Blokir INSERT Langsung Hasil & Sertifikat', 'PASS', 'Klien diblokir dari INSERT langsung ke assessment_results dan certificates.');
EXCEPTION WHEN OTHERS THEN
    RESET ROLE;
    INSERT INTO test_results (no, skenario, status, keterangan)
    VALUES (3, 'Blokir INSERT Langsung Hasil & Sertifikat', 'FAIL', SQLERRM);
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
    ASSERT v_error_caught = true, 'submit_quiz tidak menolak soal duplikat.';

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
    ASSERT v_error_caught = true, 'submit_quiz tidak menolak ID soal asing.';

    -- 3. Poin c: Kirim 1 jawaban benar dari 5 soal di bank -> menghasilkan skor 20%
    v_partial_answer := '[
        {"question_id": "33333333-3333-3333-3333-333333333301", "selected_option": 0}
    ]'::jsonb;

    v_res := public.submit_quiz('pretest', NULL, v_partial_answer);

    ASSERT (v_res->>'total_questions')::INT = 5, 'Total soal seharusnya 5 (sesuai bank).';
    ASSERT (v_res->>'correct_answers')::INT = 1, 'Jumlah benar seharusnya 1.';
    ASSERT (v_res->>'score')::INT = 20, 'Skor 1 benar dari 5 soal seharusnya 20%.';

    RESET ROLE;
    INSERT INTO test_results (no, skenario, status, keterangan)
    VALUES (4, 'Validasi Payload & Skor dari Bank Soal (Poin c)', 'PASS', 'Tolak duplikat & ID asing; 1 benar dari 5 soal bank menghasilkan skor 20%.');
EXCEPTION WHEN OTHERS THEN
    RESET ROLE;
    INSERT INTO test_results (no, skenario, status, keterangan)
    VALUES (4, 'Validasi Payload & Skor dari Bank Soal (Poin c)', 'FAIL', SQLERRM);
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
    ASSERT v_exception_caught = true, 'Melompati urutan modul tidak ditolak.';

    -- 2. Selesaikan Modul 1
    v_res := public.complete_module(1);
    ASSERT (v_res->>'success')::BOOLEAN = true, 'Gagal menyelesaikan modul 1.';

    -- 3. Selesaikan Modul 2
    v_res := public.complete_module(2);
    ASSERT (v_res->>'success')::BOOLEAN = true, 'Gagal menyelesaikan modul 2.';

    RESET ROLE;
    INSERT INTO test_results (no, skenario, status, keterangan)
    VALUES (5, 'Penegakan Urutan Modul Bertahap', 'PASS', 'Melompati modul ditolak; modul 1 dan 2 selesai berurutan.');
EXCEPTION WHEN OTHERS THEN
    RESET ROLE;
    INSERT INTO test_results (no, skenario, status, keterangan)
    VALUES (5, 'Penegakan Urutan Modul Bertahap', 'FAIL', SQLERRM);
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
    ASSERT v_exception_caught = true, 'submit_quiz(final) tidak menolak modul < 5.';

    -- Selesaikan Modul 3, 4, 5
    PERFORM public.complete_module(3);
    PERFORM public.complete_module(4);
    PERFORM public.complete_module(5);

    -- Setelah seluruh 5 modul selesai, kuis akhir diizinkan
    v_res := public.submit_quiz('final', NULL, v_answers);
    ASSERT (v_res->>'quiz_type') = 'final', 'submit_quiz(final) gagal setelah 5 modul tuntas.';

    RESET ROLE;
    INSERT INTO test_results (no, skenario, status, keterangan)
    VALUES (6, 'Prasyarat 5 Modul untuk Kuis Akhir (Poin d)', 'PASS', 'Kuis akhir ditolak saat modul < 5; diizinkan setelah kelima modul berstatus completed.');
EXCEPTION WHEN OTHERS THEN
    RESET ROLE;
    INSERT INTO test_results (no, skenario, status, keterangan)
    VALUES (6, 'Prasyarat 5 Modul untuk Kuis Akhir (Poin d)', 'FAIL', SQLERRM);
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

    -- Percobaan ke-4 dalam 24 jam harus DITOLAK dengan kode P0003
    v_exception_caught := false;
    BEGIN
        PERFORM public.submit_quiz('final', NULL, v_answers);
    EXCEPTION WHEN SQLSTATE 'P0003' THEN
        v_exception_caught := true;
    END;
    ASSERT v_exception_caught = true, 'Percobaan ke-4 tidak memicu limit exception P0003.';

    RESET ROLE;
    INSERT INTO test_results (no, skenario, status, keterangan)
    VALUES (7, 'Pembatasan 3 Percobaan Kuis Akhir / 24 Jam (Poin e)', 'PASS', 'Percobaan ke-1 s/d 3 diizinkan; percobaan ke-4 ditolak dengan exception P0003.');
EXCEPTION WHEN OTHERS THEN
    RESET ROLE;
    INSERT INTO test_results (no, skenario, status, keterangan)
    VALUES (7, 'Pembatasan 3 Percobaan Kuis Akhir / 24 Jam (Poin e)', 'FAIL', SQLERRM);
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
    ASSERT v_exception_caught = true, 'issue_certificate tidak menolak skor 79%.';

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
    ASSERT (v_res->>'success')::BOOLEAN = true, 'issue_certificate gagal menerbitkan sertifikat.';
    ASSERT (v_res->'certificate'->>'final_score')::INT = 80, 'Nilai sertifikat tidak sesuai nilai terbaik.';

    -- Verifikasi kolom assessment_result_id pada tabel certificates tercatat
    RESET ROLE;
    SELECT * INTO v_cert_record FROM public.certificates WHERE user_id = v_user_a AND status = 'active';
    ASSERT v_cert_record.assessment_result_id IS NOT NULL, 'assessment_result_id tidak tercatat pada certificates.';
    ASSERT v_cert_record.final_score = 80, 'final_score pada certificates salah.';

    -- Idempotensi: Panggilan kedua mengembalikan sertifikat aktif yang sama
    SET LOCAL ROLE authenticated;
    PERFORM set_config('request.jwt.claims', json_build_object('sub', v_user_a, 'role', 'authenticated')::text, true);
    PERFORM set_config('request.jwt.claim.sub', v_user_a::text, true);
    PERFORM set_config('request.jwt.claim.role', 'authenticated', true);

    v_res := public.issue_certificate();
    ASSERT (v_res->>'is_new')::BOOLEAN = false, 'Penerbitan kedua seharusnya mengembalikan sertifikat aktif.';

    RESET ROLE;
    INSERT INTO test_results (no, skenario, status, keterangan)
    VALUES (8, 'Penerbitan Sertifikat Berbasis Nilai Terbaik (Keputusan 1)', 'PASS', 'Skor 79 ditolak; skor 80 diterima; assessment_result_id tercatat; pemanggilan berulang idempotent.');
EXCEPTION WHEN OTHERS THEN
    RESET ROLE;
    INSERT INTO test_results (no, skenario, status, keterangan)
    VALUES (8, 'Penerbitan Sertifikat Berbasis Nilai Terbaik (Keputusan 1)', 'FAIL', SQLERRM);
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
BEGIN
    SELECT certificate_number INTO v_cert_num FROM public.certificates WHERE user_id = v_user_a AND status = 'active';

    -- Simulasikan role anon (publik)
    SET LOCAL ROLE anon;
    PERFORM set_config('request.jwt.claims', '{"role": "anon"}', true);
    PERFORM set_config('request.jwt.claim.sub', '', true);
    PERFORM set_config('request.jwt.claim.role', 'anon', true);

    v_verify_res := public.verify_certificate(v_cert_num);

    ASSERT (v_verify_res->>'valid')::BOOLEAN = true, 'Sertifikat valid gagal diverifikasi publik.';
    ASSERT (v_verify_res->>'participant_name') = 'Peserta A', 'Nama peserta salah.';
    ASSERT (v_verify_res->>'program_name') = 'Dasar Pengelolaan Mangrove', 'Nama program salah.';
    ASSERT (v_verify_res ? 'certificate_number') = true, 'certificate_number tidak ada.';
    ASSERT (v_verify_res ? 'issued_at') = true, 'issued_at tidak ada.';
    ASSERT (v_verify_res ? 'status') = true, 'status tidak ada.';

    -- Keputusan 4: Pastikan TIDAK ADA user_id, email, atau nilai numerik yang bocor
    ASSERT (v_verify_res ? 'user_id') = false, 'KEAMANAN JEBOL: user_id bocor di verifikasi publik.';
    ASSERT (v_verify_res ? 'email') = false, 'KEAMANAN JEBOL: email bocor di verifikasi publik.';
    ASSERT (v_verify_res ? 'final_score') = false, 'KEAMANAN JEBOL: nilai ujian bocor di verifikasi publik.';

    RESET ROLE;
    INSERT INTO test_results (no, skenario, status, keterangan)
    VALUES (9, 'Verifikasi Publik Sertifikat Terbatas (Keputusan 4)', 'PASS', 'Verifikasi berhasil tanpa membocorkan user_id, email, atau nilai numerik.');
EXCEPTION WHEN OTHERS THEN
    RESET ROLE;
    INSERT INTO test_results (no, skenario, status, keterangan)
    VALUES (9, 'Verifikasi Publik Sertifikat Terbatas (Keputusan 4)', 'FAIL', SQLERRM);
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
FROM test_results
ORDER BY no ASC;

-- ==============================================================================
-- SELESAI: BERSIHKAN DATABASE DENGAN ROLLBACK
-- ==============================================================================
ROLLBACK;
