-- ==============================================================================
-- RLS & SECURITY VERIFICATION SUITE
-- Project: RooveyLearn - Digital Learning Platform for Mangrove Conservation
-- Description: Skenario uji terisolasi untuk dijalankan manual di Supabase SQL Editor.
-- Cakupan Uji:
--   1. Hak akses tabel & eksekusi RPC untuk role 'anon' (Poin a)
--   2. Isolasi data antar-pengguna & proteksi mutasi key user_module_progress (Poin f)
--   3. Blokir INSERT langsung ke assessment_results & certificates
--   4. Validasi payload submit_quiz & perhitungan skor dari bank soal (Poin c)
--   5. Penegakan urutan modul 1 -> 2 -> 3 -> 4 -> 5
--   6. Prasyarat modul 5 selesai sebelum submit_quiz('final') diizinkan (Poin d)
--   7. Pembatasan 3 percobaan kuis akhir per 24 jam (Poin e)
--   8. Syarat kelulusan dan idempotensi penerbitan sertifikat berbasis nilai terbaik
--   9. Verifikasi publik sertifikat tanpa data sensitif (Keputusan 4)
-- ==============================================================================

BEGIN;

-- ==============================================================================
-- SETUP: BUAT DATA DUMMY TEST & USERS
-- ==============================================================================
DO $$
DECLARE
    v_user_a UUID := 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
    v_user_b UUID := 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb';
BEGIN
    RAISE NOTICE '--- MEMULAI SETUP TEST FIXTURES ---';

    -- 1. Buat user dummy di auth.users (jika belum ada)
    INSERT INTO auth.users (id, email, raw_user_meta_data, role, aud)
    VALUES 
        (v_user_a, 'usera@rooveylearn.test', '{"name": "Peserta A", "community_name": "Pokdarwis Pesisir"}'::jsonb, 'authenticated', 'authenticated'),
        (v_user_b, 'userb@rooveylearn.test', '{"name": "Peserta B", "community_name": "Relawan Mangrove"}'::jsonb, 'authenticated', 'authenticated')
    ON CONFLICT (id) DO NOTHING;

    -- Trigger handle_new_user otomatis membuat baris profiles
    ASSERT (SELECT COUNT(*) FROM public.profiles WHERE id IN (v_user_a, v_user_b)) = 2,
        'FAIL: Trigger pembuatan profil otomatis gagal.';

    RAISE NOTICE 'SETUP BERHASIL: User A & User B siap diuji.';
END;
$$;

-- ==============================================================================
-- SKENARIO 1: HAK AKSES ROLE ANON (TABEL & RPC EXECUTION PRIVILEGES - Poin a)
-- ==============================================================================
DO $$
DECLARE
    v_count INT;
    v_error_caught BOOLEAN := false;
    v_public_cert JSONB;
BEGIN
    RAISE NOTICE '--- SKENARIO 1: PENGUJIAN ROLE ANON (TABEL & RPC GRANTS) ---';

    -- Simulasikan koneksi sebagai anon (tamu tanpa login)
    SET LOCAL ROLE anon;
    SET LOCAL request.jwt.claim.sub = '';
    SET LOCAL request.jwt.claim.role = 'anon';

    -- 1. Anon BISA membaca modul dan materi yang published (untuk Mode Tamu)
    SELECT COUNT(*) INTO v_count FROM public.learning_modules WHERE status = 'published';
    ASSERT v_count >= 5, 'FAIL: Anon seharusnya bisa membaca katalog modul published.';

    SELECT COUNT(*) INTO v_count FROM public.learning_materials WHERE status = 'published';
    ASSERT v_count >= 5, 'FAIL: Anon seharusnya bisa membaca materi pembelajaran.';

    -- 2. Anon BISA membaca daftar soal (pertanyaan & opsi), tapi TANPA kunci
    SELECT COUNT(*) INTO v_count FROM public.quiz_questions WHERE is_active = true;
    ASSERT v_count >= 5, 'FAIL: Anon seharusnya bisa membaca teks soal.';

    -- 3. Anon TIDAK BISA membaca tabel kunci jawaban quiz_answers
    BEGIN
        SELECT COUNT(*) INTO v_count FROM public.quiz_answers;
        IF v_count > 0 THEN
            RAISE EXCEPTION 'KEAMANAN JEBOL: Anon berhasil membaca data quiz_answers!';
        END IF;
    EXCEPTION WHEN insufficient_privilege THEN
        v_error_caught := true;
    END;
    RAISE NOTICE 'PASS: Anon diblokir dari quiz_answers (insufficient privilege / 0 rows).';

    -- 4. Anon TIDAK BISA membaca data pengguna
    SELECT COUNT(*) INTO v_count FROM public.profiles;
    ASSERT v_count = 0, 'FAIL: Anon tidak boleh melihat data profiles.';

    SELECT COUNT(*) INTO v_count FROM public.user_module_progress;
    ASSERT v_count = 0, 'FAIL: Anon tidak boleh melihat user_module_progress.';

    SELECT COUNT(*) INTO v_count FROM public.assessment_results;
    ASSERT v_count = 0, 'FAIL: Anon tidak boleh melihat assessment_results.';

    SELECT COUNT(*) INTO v_count FROM public.certificates;
    ASSERT v_count = 0, 'FAIL: Anon tidak boleh melihat certificates.';

    -- 5. Poin a: Anon DITOLAK mengeksekusi RPC SECURITY DEFINER (complete_module, submit_quiz, issue_certificate)
    v_error_caught := false;
    BEGIN
        PERFORM public.complete_module(1);
        RAISE EXCEPTION 'FAIL: Anon berhasil mengeksekusi complete_module!';
    EXCEPTION WHEN insufficient_privilege THEN
        v_error_caught := true;
    END;
    ASSERT v_error_caught = true, 'FAIL: complete_module tidak memblokir eksekusi anon.';

    v_error_caught := false;
    BEGIN
        PERFORM public.submit_quiz('final', NULL, '[]'::jsonb);
        RAISE EXCEPTION 'FAIL: Anon berhasil mengeksekusi submit_quiz!';
    EXCEPTION WHEN insufficient_privilege THEN
        v_error_caught := true;
    END;
    ASSERT v_error_caught = true, 'FAIL: submit_quiz tidak memblokir eksekusi anon.';

    v_error_caught := false;
    BEGIN
        PERFORM public.issue_certificate();
        RAISE EXCEPTION 'FAIL: Anon berhasil mengeksekusi issue_certificate!';
    EXCEPTION WHEN insufficient_privilege THEN
        v_error_caught := true;
    END;
    ASSERT v_error_caught = true, 'FAIL: issue_certificate tidak memblokir eksekusi anon.';

    -- 6. Poin a: Anon DIIZINKAN mengeksekusi RPC verify_certificate (publik)
    v_public_cert := public.verify_certificate('ROOVEY-TEST-NOT-FOUND');
    ASSERT (v_public_cert->>'valid')::BOOLEAN = false, 'FAIL: verify_certificate gagal dijalankan oleh anon.';

    RAISE NOTICE 'PASS SKENARIO 1: Hak akses tabel dan RPC untuk role Anon terisolasi dengan aman.';
END;
$$;

-- ==============================================================================
-- SKENARIO 2: ISOLASI PENGGUNA & PROTEKSI MUTASI USER_MODULE_PROGRESS (Poin f)
-- ==============================================================================
DO $$
DECLARE
    v_user_a UUID := 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
    v_user_b UUID := 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb';
    v_count INT;
    v_rows_affected INT;
    v_error_caught BOOLEAN := false;
BEGIN
    RAISE NOTICE '--- SKENARIO 2: ISOLASI DATA & PROTEKSI MUTASI PROGRESS (Poin f) ---';

    -- Siapkan data progres untuk User B (dibuat via system)
    RESET ROLE;
    INSERT INTO public.user_module_progress (user_id, module_id, status, progress_percent)
    VALUES (v_user_b, 1, 'in_progress', 50)
    ON CONFLICT (user_id, module_id) DO UPDATE SET progress_percent = 50;

    -- Simulasikan login sebagai User A
    SET LOCAL ROLE authenticated;
    SET LOCAL request.jwt.claim.sub = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
    SET LOCAL request.jwt.claim.role = 'authenticated';

    -- 1. User A membaca profil: hanya miliknya sendiri
    SELECT COUNT(*) INTO v_count FROM public.profiles;
    ASSERT v_count = 1, 'FAIL: User A seharusnya hanya membaca 1 baris profil miliknya.';

    SELECT COUNT(*) INTO v_count FROM public.profiles WHERE id = v_user_b;
    ASSERT v_count = 0, 'FAIL: User A tidak boleh melihat profil User B.';

    -- 2. User A tidak bisa membaca progres User B
    SELECT COUNT(*) INTO v_count FROM public.user_module_progress WHERE user_id = v_user_b;
    ASSERT v_count = 0, 'FAIL: User A tidak boleh melihat baris progres User B.';

    -- 3. User A mencoba mengubah data progres User B (UPDATE) -> 0 rows affected
    UPDATE public.user_module_progress 
    SET progress_percent = 100 
    WHERE user_id = v_user_b;
    GET DIAGNOSTICS v_rows_affected = ROW_COUNT;
    ASSERT v_rows_affected = 0, 'FAIL: User A berhasil mengupdate progres User B!';

    -- 4. Poin f: User A membuat baris progres miliknya (in_progress)
    INSERT INTO public.user_module_progress (user_id, module_id, status, progress_percent)
    VALUES (v_user_a, 1, 'in_progress', 30)
    ON CONFLICT (user_id, module_id) DO UPDATE SET progress_percent = 30;

    -- 5. Poin f: User A mencoba mengubah status menjadi 'completed' via direct UPDATE -> DITOLAK RLS
    v_error_caught := false;
    BEGIN
        UPDATE public.user_module_progress 
        SET status = 'completed', progress_percent = 100
        WHERE user_id = v_user_a AND module_id = 1;
        RAISE EXCEPTION 'FAIL: Klien berhasil menulis status completed secara langsung!';
    EXCEPTION WHEN check_violation OR insufficient_privilege THEN
        v_error_caught := true;
    END;
    ASSERT v_error_caught = true, 'FAIL: RLS tidak memblokir penulisan status completed langsung.';

    -- 6. Poin f: User A mencoba mengubah user_id atau module_id pada baris miliknya -> DITOLAK TRIGGER
    v_error_caught := false;
    BEGIN
        UPDATE public.user_module_progress 
        SET user_id = v_user_b
        WHERE user_id = v_user_a AND module_id = 1;
        RAISE EXCEPTION 'FAIL: Klien berhasil memutasi user_id pada progress!';
    EXCEPTION WHEN SQLSTATE '42501' THEN
        v_error_caught := true;
    END;
    ASSERT v_error_caught = true, 'FAIL: Trigger tidak memblokir mutasi user_id.';

    v_error_caught := false;
    BEGIN
        UPDATE public.user_module_progress 
        SET module_id = 2
        WHERE user_id = v_user_a AND module_id = 1;
        RAISE EXCEPTION 'FAIL: Klien berhasil memutasi module_id pada progress!';
    EXCEPTION WHEN SQLSTATE '42501' THEN
        v_error_caught := true;
    END;
    ASSERT v_error_caught = true, 'FAIL: Trigger tidak memblokir mutasi module_id.';

    RAISE NOTICE 'PASS SKENARIO 2: Isolasi antar-pengguna dan proteksi integritas progress terverifikasi.';
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
    RAISE NOTICE '--- SKENARIO 3: PENGUJIAN BLOKIR INSERT LANGSUNG ---';

    SET LOCAL ROLE authenticated;
    SET LOCAL request.jwt.claim.sub = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
    SET LOCAL request.jwt.claim.role = 'authenticated';

    -- 1. Coba INSERT langsung ke assessment_results
    BEGIN
        INSERT INTO public.assessment_results (
            user_id, assessment_type, score, total_questions, correct_answers, is_passed
        ) VALUES (
            v_user_a, 'final', 100, 5, 5, true
        );
        RAISE EXCEPTION 'FAIL: Klien berhasil INSERT langsung ke assessment_results!';
    EXCEPTION WHEN insufficient_privilege THEN
        v_blocked := true;
    END;
    ASSERT v_blocked = true, 'FAIL: Kebijakan RLS tidak memblokir INSERT assessment_results.';

    -- 2. Coba INSERT langsung ke certificates
    v_blocked := false;
    BEGIN
        INSERT INTO public.certificates (
            user_id, certificate_number, assessment_result_id, final_score
        ) VALUES (
            v_user_a, 'PALSU-123456', gen_random_uuid(), 100
        );
        RAISE EXCEPTION 'FAIL: Klien berhasil INSERT langsung ke certificates!';
    EXCEPTION WHEN insufficient_privilege THEN
        v_blocked := true;
    END;
    ASSERT v_blocked = true, 'FAIL: Kebijakan RLS tidak memblokir INSERT certificates.';

    RAISE NOTICE 'PASS SKENARIO 3: Klien wajib menggunakan RPC untuk evaluasi & sertifikat.';
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
    RAISE NOTICE '--- SKENARIO 4: VALIDASI PAYLOAD & PERHITUNGAN SKOR BANK (Poin c) ---';

    SET LOCAL ROLE authenticated;
    SET LOCAL request.jwt.claim.sub = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
    SET LOCAL request.jwt.claim.role = 'authenticated';

    -- 1. Poin c: Tolak jika ada ID butir soal duplikat
    v_duplicate_answer := '[
        {"question_id": "22222222-2222-2222-2222-222222222201", "selected_option": 1},
        {"question_id": "22222222-2222-2222-2222-222222222201", "selected_option": 1}
    ]'::jsonb;
    
    v_error_caught := false;
    BEGIN
        PERFORM public.submit_quiz('final', NULL, v_duplicate_answer);
        RAISE EXCEPTION 'FAIL: submit_quiz menerima soal duplikat!';
    EXCEPTION WHEN SQLSTATE '22023' THEN
        v_error_caught := true;
    END;
    ASSERT v_error_caught = true, 'FAIL: submit_quiz tidak menolak payload soal duplikat.';
    RAISE NOTICE 'PASS: Payload soal duplikat berhasil ditolak.';

    -- 2. Poin c: Tolak jika ID butir soal tidak terdaftar pada kuis
    v_invalid_qid_answer := '[
        {"question_id": "99999999-9999-9999-9999-999999999999", "selected_option": 1}
    ]'::jsonb;
    
    v_error_caught := false;
    BEGIN
        PERFORM public.submit_quiz('final', NULL, v_invalid_qid_answer);
        RAISE EXCEPTION 'FAIL: submit_quiz menerima soal yang tidak terdaftar!';
    EXCEPTION WHEN SQLSTATE '22023' THEN
        v_error_caught := true;
    END;
    ASSERT v_error_caught = true, 'FAIL: submit_quiz tidak menolak ID soal asing.';
    RAISE NOTICE 'PASS: ID soal yang bukan milik kuis berhasil ditolak.';

    -- 3. Poin c: Kirim 1 jawaban benar dari 5 soal di bank -> harus menghasilkan skor 20%
    -- Untuk tes ini, kita gunakan paket soal pretest (tambahkan dummy pretest sementara di fixture)
    RESET ROLE;
    INSERT INTO public.quiz_questions (id, quiz_type, question_text, options, order_index, is_active)
    VALUES 
        ('33333333-3333-3333-3333-333333333301', 'pretest', 'Soal Test 1', '["A","B","C","D"]'::jsonb, 1, true),
        ('33333333-3333-3333-3333-333333333302', 'pretest', 'Soal Test 2', '["A","B","C","D"]'::jsonb, 2, true),
        ('33333333-3333-3333-3333-333333333303', 'pretest', 'Soal Test 3', '["A","B","C","D"]'::jsonb, 3, true),
        ('33333333-3333-3333-3333-333333333304', 'pretest', 'Soal Test 4', '["A","B","C","D"]'::jsonb, 4, true),
        ('33333333-3333-3333-3333-333333333305', 'pretest', 'Soal Test 5', '["A","B","C","D"]'::jsonb, 5, true)
    ON CONFLICT (id) DO NOTHING;

    INSERT INTO public.quiz_answers (question_id, correct_option_index, explanation)
    VALUES 
        ('33333333-3333-3333-3333-333333333301', 0, 'Penjelasan 1'),
        ('33333333-3333-3333-3333-333333333302', 1, 'Penjelasan 2'),
        ('33333333-3333-3333-3333-333333333303', 2, 'Penjelasan 3'),
        ('33333333-3333-3333-3333-333333333304', 3, 'Penjelasan 4'),
        ('33333333-3333-3333-3333-333333333305', 0, 'Penjelasan 5')
    ON CONFLICT (question_id) DO NOTHING;

    SET LOCAL ROLE authenticated;
    SET LOCAL request.jwt.claim.sub = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
    SET LOCAL request.jwt.claim.role = 'authenticated';

    -- User hanya mengirim 1 jawaban benar (soal 1 opsi 0), 4 soal lainnya tidak dikirim
    v_partial_answer := '[
        {"question_id": "33333333-3333-3333-3333-333333333301", "selected_option": 0}
    ]'::jsonb;

    v_res := public.submit_quiz('pretest', NULL, v_partial_answer);

    ASSERT (v_res->>'total_questions')::INT = 5, 
        format('FAIL: Total soal seharusnya 5 (dari bank), didapat %s', v_res->>'total_questions');
    ASSERT (v_res->>'correct_answers')::INT = 1, 
        format('FAIL: Jumlah benar seharusnya 1, didapat %s', v_res->>'correct_answers');
    ASSERT (v_res->>'score')::INT = 20, 
        format('FAIL: Skor 1 dari 5 seharusnya 20, didapat %s', v_res->>'score');

    RAISE NOTICE 'PASS: 1 jawaban benar dari 5 soal di bank menghasilkan skor persis 20%%.';
    RAISE NOTICE 'PASS SKENARIO 4: Seluruh validasi payload & perhitungan skor dari bank terverifikasi.';
END;
$$;

-- ==============================================================================
-- SKENARIO 5: ALUR BERURUTAN MODUL (1 -> 2 -> 3 -> 4 -> 5)
-- ==============================================================================
DO $$
DECLARE
    v_user_a UUID := 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
    v_exception_caught BOOLEAN := false;
    v_res JSONB;
BEGIN
    RAISE NOTICE '--- SKENARIO 5: PENEGAKAN URUTAN MODUL (complete_module) ---';

    SET LOCAL ROLE authenticated;
    SET LOCAL request.jwt.claim.sub = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
    SET LOCAL request.jwt.claim.role = 'authenticated';

    -- User A mencoba langsung menyelesaikan Modul 2 padahal Modul 1 belum tuntas
    BEGIN
        v_res := public.complete_module(2);
        RAISE EXCEPTION 'FAIL: complete_module(2) berhasil tanpa modul 1!';
    EXCEPTION WHEN SQLSTATE 'P0001' THEN
        v_exception_caught := true;
    END;
    ASSERT v_exception_caught = true, 'FAIL: Melompati urutan modul tidak memicu exception.';

    -- Selesaikan Modul 1
    v_res := public.complete_module(1);
    ASSERT (v_res->>'success')::BOOLEAN = true, 'FAIL: Gagal menyelesaikan modul 1.';

    -- Sekarang selesaikan Modul 2
    v_res := public.complete_module(2);
    ASSERT (v_res->>'success')::BOOLEAN = true, 'FAIL: Gagal menyelesaikan modul 2.';

    RAISE NOTICE 'PASS SKENARIO 5: Penegakan urutan modul bertahap 1 -> 2 valid.';
END;
$$;

-- ==============================================================================
-- SKENARIO 6: PRASYARAT KELIMA MODUL UNTUK SUBMIT_QUIZ('final') (Poin d)
-- ==============================================================================
DO $$
DECLARE
    v_user_a UUID := 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
    v_exception_caught BOOLEAN := false;
    v_answers JSONB;
    v_res JSONB;
BEGIN
    RAISE NOTICE '--- SKENARIO 6: PRASYARAT 5 MODUL SEBELUM KUIS AKHIR (Poin d) ---';

    SET LOCAL ROLE authenticated;
    SET LOCAL request.jwt.claim.sub = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
    SET LOCAL request.jwt.claim.role = 'authenticated';

    -- User A baru menyelesaikan modul 1 dan 2. Modul 3, 4, 5 belum selesai.
    v_answers := '[
        {"question_id": "22222222-2222-2222-2222-222222222201", "selected_option": 1}
    ]'::jsonb;

    v_exception_caught := false;
    BEGIN
        PERFORM public.submit_quiz('final', NULL, v_answers);
        RAISE EXCEPTION 'FAIL: submit_quiz(final) berhasil padahal baru 2 modul selesai!';
    EXCEPTION WHEN SQLSTATE 'P0001' THEN
        v_exception_caught := true;
    END;
    ASSERT v_exception_caught = true, 'FAIL: submit_quiz(final) tidak menolak modul < 5.';
    RAISE NOTICE 'PASS: submit_quiz(final) berhasil menolak pengguna yang belum menyelesaikan 5 modul.';

    -- Sekarang selesaikan sisa modul: 3, 4, 5
    PERFORM public.complete_module(3);
    PERFORM public.complete_module(4);
    PERFORM public.complete_module(5);

    -- Setelah 5 modul selesai, kuis akhir diizinkan
    v_res := public.submit_quiz('final', NULL, v_answers);
    ASSERT (v_res->>'quiz_type') = 'final', 'FAIL: submit_quiz(final) gagal setelah 5 modul selesai.';

    RAISE NOTICE 'PASS SKENARIO 6: Prasyarat 5 modul sebelum asesmen akhir berhasil ditegakkan.';
END;
$$;

-- ==============================================================================
-- SKENARIO 7: RATE-LIMITING 3 PERCOBAAN FINAL KUIS PER 24 JAM (Poin e)
-- ==============================================================================
DO $$
DECLARE
    v_user_a UUID := 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
    v_answers JSONB;
    v_exception_caught BOOLEAN := false;
    v_i INT;
BEGIN
    RAISE NOTICE '--- SKENARIO 7: BATAS 3 PERCOBAAN KUIS AKHIR PER 24 JAM (Poin e) ---';

    -- Bersihkan riwayat final quiz User A agar tes terkontrol
    RESET ROLE;
    DELETE FROM public.assessment_results WHERE user_id = v_user_a AND assessment_type = 'final';

    SET LOCAL ROLE authenticated;
    SET LOCAL request.jwt.claim.sub = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
    SET LOCAL request.jwt.claim.role = 'authenticated';

    v_answers := '[
        {"question_id": "22222222-2222-2222-2222-222222222201", "selected_option": 1}
    ]'::jsonb;

    -- Lakukan 3 percobaan berturut-turut (harus berhasil)
    FOR v_i IN 1..3 LOOP
        PERFORM public.submit_quiz('final', NULL, v_answers);
    END LOOP;
    RAISE NOTICE 'PASS: Percobaan ke-1, ke-2, dan ke-3 berhasil disubmit.';

    -- Percobaan ke-4 dalam 24 jam harus DITOLAK dengan kode P0003
    v_exception_caught := false;
    BEGIN
        PERFORM public.submit_quiz('final', NULL, v_answers);
        RAISE EXCEPTION 'FAIL: Percobaan ke-4 kuis akhir dalam 24 jam diizinkan!';
    EXCEPTION WHEN SQLSTATE 'P0003' THEN
        v_exception_caught := true;
    END;
    ASSERT v_exception_caught = true, 'FAIL: Percobaan ke-4 tidak memicu limit exception P0003.';

    RAISE NOTICE 'PASS SKENARIO 7: Rate-limit 3 percobaan kuis akhir per 24 jam berfungsi 100%%.';
END;
$$;

-- ==============================================================================
-- SKENARIO 8: SYARAT PENERBITAN SERTIFIKAT BERBASIS NILAI TERBAIK (Keputusan 1)
-- ==============================================================================
DO $$
DECLARE
    v_user_a UUID := 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
    v_res JSONB;
    v_answers_80 JSONB;
    v_cert_record RECORD;
BEGIN
    RAISE NOTICE '--- SKENARIO 8: PENERBITAN SERTIFIKAT BERBASIS NILAI TERBAIK ---';

    -- Siapkan riwayat asesmen User A: nilai 80% (4 benar dari 5)
    RESET ROLE;
    DELETE FROM public.certificates WHERE user_id = v_user_a;
    DELETE FROM public.assessment_results WHERE user_id = v_user_a AND assessment_type = 'final';

    SET LOCAL ROLE authenticated;
    SET LOCAL request.jwt.claim.sub = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
    SET LOCAL request.jwt.claim.role = 'authenticated';

    v_answers_80 := '[
        {"question_id": "22222222-2222-2222-2222-222222222201", "selected_option": 1},
        {"question_id": "22222222-2222-2222-2222-222222222202", "selected_option": 2},
        {"question_id": "22222222-2222-2222-2222-222222222203", "selected_option": 0},
        {"question_id": "22222222-2222-2222-2222-222222222204", "selected_option": 3}
    ]'::jsonb;
    PERFORM public.submit_quiz('final', NULL, v_answers_80);

    -- Terbitkan sertifikat
    v_res := public.issue_certificate();
    ASSERT (v_res->>'success')::BOOLEAN = true, 'FAIL: issue_certificate gagal.';
    ASSERT (v_res->'certificate'->>'final_score')::INT = 80, 'FAIL: Skor sertifikat tidak sama dengan nilai terbaik.';
    ASSERT (v_res->'certificate'->>'certificate_number') LIKE 'ROOVEY-%', 'FAIL: Format nomor sertifikat tidak valid.';

    -- Cek penyimpanan di tabel certificates (assessment_result_id harus tercatat)
    SELECT * INTO v_cert_record FROM public.certificates WHERE user_id = v_user_a AND status = 'active';
    ASSERT v_cert_record.assessment_result_id IS NOT NULL, 'FAIL: assessment_result_id tidak tercatat pada tabel certificates.';
    ASSERT v_cert_record.final_score = 80, 'FAIL: final_score pada tabel certificates salah.';

    -- Idempotensi: Panggilan ulang mengembalikan sertifikat aktif yang sama
    v_res := public.issue_certificate();
    ASSERT (v_res->>'is_new')::BOOLEAN = false, 'FAIL: Penerbitan kedua seharusnya mengembalikan sertifikat yang ada.';

    RAISE NOTICE 'PASS SKENARIO 8: Sertifikat berhasil terbit berbasis nilai terbaik & assessment_result_id tercatat.';
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
    RAISE NOTICE '--- SKENARIO 9: VERIFIKASI PUBLIK SERTIFIKAT (Keputusan 4) ---';

    SELECT certificate_number INTO v_cert_num FROM public.certificates WHERE user_id = v_user_a AND status = 'active';

    -- Simulasikan koneksi sebagai anon (publik)
    SET LOCAL ROLE anon;
    SET LOCAL request.jwt.claim.sub = '';
    SET LOCAL request.jwt.claim.role = 'anon';

    v_verify_res := public.verify_certificate(v_cert_num);

    ASSERT (v_verify_res->>'valid')::BOOLEAN = true, 'FAIL: Sertifikat valid gagal diverifikasi.';
    ASSERT (v_verify_res->>'participant_name') = 'Peserta A', 'FAIL: Nama peserta pada verifikasi salah.';
    ASSERT (v_verify_res->>'program_name') = 'Dasar Pengelolaan Mangrove', 'FAIL: Nama program pada verifikasi salah.';
    ASSERT (v_verify_res ? 'certificate_number') = true, 'FAIL: certificate_number harus ada.';
    ASSERT (v_verify_res ? 'issued_at') = true, 'FAIL: issued_at harus ada.';
    ASSERT (v_verify_res ? 'status') = true, 'FAIL: status harus ada.';

    -- Keputusan 4: Pastikan TIDAK ADA user_id, email, atau nilai numerik yang bocor
    ASSERT (v_verify_res ? 'user_id') = false, 'KEAMANAN JEBOL: user_id bocor di verifikasi publik!';
    ASSERT (v_verify_res ? 'email') = false, 'KEAMANAN JEBOL: email bocor di verifikasi publik!';
    ASSERT (v_verify_res ? 'final_score') = false, 'KEAMANAN JEBOL: nilai ujian bocor di verifikasi publik!';

    RAISE NOTICE 'PASS SKENARIO 9: Verifikasi sertifikat publik aman dan tidak membocorkan data privat.';
END;
$$;

-- ==============================================================================
-- SELESAI: ROLLBACK SELURUH PERUBAHAN AGAR DATABASE TETAP BERSIH
-- ==============================================================================
ROLLBACK;
RAISE NOTICE '=== SELURUH 9 SKENARIO UJI RLS & RPC BERHASIL 100%% (ALL ASSERTIONS PASSED) ===';
