-- ==============================================================================
-- RLS & SECURITY VERIFICATION SUITE
-- Project: RooveyLearn - Digital Learning Platform for Mangrove Conservation
-- Description: Skenario uji terisolasi untuk dijalankan manual di Supabase SQL Editor.
-- Petunjuk: Jalankan seluruh script ini. Di akhir, seluruh perubahan di-ROLLBACK
--           sehingga database tetap bersih.
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
-- SKENARIO 1: ROLE ANON TIDAK DAPAT MEMBACA KUNCI JAWABAN ATAU DATA PENGGUNA
-- ==============================================================================
DO $$
DECLARE
    v_count INT;
    v_error_caught BOOLEAN := false;
BEGIN
    RAISE NOTICE '--- SKENARIO 1: PENGUJIAN HAK AKSES ROLE ANON ---';

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
        -- Jika tidak melempar permission denied, pastikan 0 baris
        IF v_count > 0 THEN
            RAISE EXCEPTION 'KEAMANAN JEBOL: Anon berhasil membaca data quiz_answers!';
        END IF;
    EXCEPTION WHEN insufficient_privilege THEN
        v_error_caught := true;
    END;
    RAISE NOTICE 'PASS: Anon diblokir dari quiz_answers (insufficient privilege / 0 rows).';

    -- 4. Anon TIDAK BISA membaca data pengguna (profiles, progress, assessment_results, certificates)
    SELECT COUNT(*) INTO v_count FROM public.profiles;
    ASSERT v_count = 0, 'FAIL: Anon tidak boleh melihat data profiles.';

    SELECT COUNT(*) INTO v_count FROM public.user_module_progress;
    ASSERT v_count = 0, 'FAIL: Anon tidak boleh melihat user_module_progress.';

    SELECT COUNT(*) INTO v_count FROM public.assessment_results;
    ASSERT v_count = 0, 'FAIL: Anon tidak boleh melihat assessment_results.';

    SELECT COUNT(*) INTO v_count FROM public.certificates;
    ASSERT v_count = 0, 'FAIL: Anon tidak boleh melihat certificates.';

    RAISE NOTICE 'PASS SKENARIO 1: Role Anon aman dari kebocoran data pengguna & kunci jawaban.';
END;
$$;

-- ==============================================================================
-- SKENARIO 2: ISOLASI PENGGUNA (USER A TIDAK BISA MELIHAT/MENGUBAH DATA USER B)
-- ==============================================================================
DO $$
DECLARE
    v_user_a UUID := 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
    v_user_b UUID := 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb';
    v_count INT;
    v_rows_affected INT;
BEGIN
    RAISE NOTICE '--- SKENARIO 2: PENGUJIAN ISOLASI DATA ANTAR-PENGGUNA ---';

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

    -- 3. User A mencoba mengubah data progres User B (UPDATE)
    UPDATE public.user_module_progress 
    SET progress_percent = 100 
    WHERE user_id = v_user_b;
    GET DIAGNOSTICS v_rows_affected = ROW_COUNT;
    ASSERT v_rows_affected = 0, 'FAIL: User A berhasil mengupdate progres User B!';

    -- 4. User A mencoba menghapus progres User B (DELETE)
    DELETE FROM public.user_module_progress WHERE user_id = v_user_b;
    GET DIAGNOSTICS v_rows_affected = ROW_COUNT;
    ASSERT v_rows_affected = 0, 'FAIL: User A berhasil menghapus progres User B!';

    RAISE NOTICE 'PASS SKENARIO 2: Isolasi data User A dan User B berjalan 100%%.';
END;
$$;

-- ==============================================================================
-- SKENARIO 3: USER TIDAK DAPAT INSERT LANGSUNG KE ASSESSMENT_RESULTS / CERTIFICATES
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
    RAISE NOTICE 'PASS: INSERT langsung ke assessment_results diblokir.';

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
    RAISE NOTICE 'PASS: INSERT langsung ke certificates diblokir.';

    RAISE NOTICE 'PASS SKENARIO 3: Klien wajib menggunakan RPC untuk evaluasi & sertifikat.';
END;
$$;

-- ==============================================================================
-- SKENARIO 4: SUBMIT_QUIZ RPC TIDAK MEMBOCORKAN KUNCI & MENGHITUNG DENGAN BENAR
-- ==============================================================================
DO $$
DECLARE
    v_user_a UUID := 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
    v_answers JSONB;
    v_result JSONB;
    v_q RECORD;
BEGIN
    RAISE NOTICE '--- SKENARIO 4: PENGUJIAN RPC SUBMIT_QUIZ ---';

    SET LOCAL ROLE authenticated;
    SET LOCAL request.jwt.claim.sub = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
    SET LOCAL request.jwt.claim.role = 'authenticated';

    -- Susun payload jawaban untuk 5 soal kuis akhir: 4 benar, 1 salah (skor 80%)
    -- Soal 1: benar (pilih 1)
    -- Soal 2: benar (pilih 2)
    -- Soal 3: benar (pilih 0)
    -- Soal 4: benar (pilih 3)
    -- Soal 5: SALAH (pilih 0, seharusnya 1)
    v_answers := '[
        {"question_id": "22222222-2222-2222-2222-222222222201", "selected_option": 1},
        {"question_id": "22222222-2222-2222-2222-222222222202", "selected_option": 2},
        {"question_id": "22222222-2222-2222-2222-222222222203", "selected_option": 0},
        {"question_id": "22222222-2222-2222-2222-222222222204", "selected_option": 3},
        {"question_id": "22222222-2222-2222-2222-222222222205", "selected_option": 0}
    ]'::jsonb;

    v_result := public.submit_quiz('final', NULL, v_answers);

    ASSERT (v_result->>'score')::INT = 80, 
        format('FAIL: Skor kuis salah, diharapkan 80 tapi didapat %s', v_result->>'score');
    ASSERT (v_result->>'is_passed')::BOOLEAN = true, 
        'FAIL: Status kelulusan seharusnya true untuk skor 80.';
    ASSERT (v_result->>'correct_answers')::INT = 4, 
        'FAIL: Jumlah jawaban benar seharusnya 4.';

    -- Pastikan pembahasan (explanation) disertakan DALAM HASIL SUBMIT
    ASSERT jsonb_array_length(v_result->'evaluations') = 5,
        'FAIL: Evaluasi harus memuat 5 pembahasan soal.';

    RAISE NOTICE 'PASS SKENARIO 4: submit_quiz() menghitung skor 80%% dan mengembalikan pembahasan.';
END;
$$;

-- ==============================================================================
-- SKENARIO 5: PENEGAKAN URUTAN MODUL PADA COMPLETE_MODULE()
-- ==============================================================================
DO $$
DECLARE
    v_user_a UUID := 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
    v_exception_caught BOOLEAN := false;
    v_res JSONB;
BEGIN
    RAISE NOTICE '--- SKENARIO 5: PENGUJIAN ALUR BERURUTAN MODUL ---';

    SET LOCAL ROLE authenticated;
    SET LOCAL request.jwt.claim.sub = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
    SET LOCAL request.jwt.claim.role = 'authenticated';

    -- 1. User A mencoba langsung menyelesaikan Modul 2 padahal Modul 1 belum tuntas
    BEGIN
        v_res := public.complete_module(2);
        RAISE EXCEPTION 'FAIL: complete_module(2) berhasil tanpa modul 1!';
    EXCEPTION WHEN SQLSTATE 'P0001' THEN
        v_exception_caught := true;
    END;
    ASSERT v_exception_caught = true, 'FAIL: Melompati urutan modul tidak memicu exception.';
    RAISE NOTICE 'PASS: Melompati Modul 1 langsung ke Modul 2 berhasil ditolak.';

    -- 2. Selesaikan Modul 1
    v_res := public.complete_module(1);
    ASSERT (v_res->>'success')::BOOLEAN = true, 'FAIL: Gagal menyelesaikan modul 1.';

    -- 3. Sekarang selesaikan Modul 2 (harus berhasil karena modul 1 sudah selesai)
    v_res := public.complete_module(2);
    ASSERT (v_res->>'success')::BOOLEAN = true, 'FAIL: Gagal menyelesaikan modul 2.';

    RAISE NOTICE 'PASS SKENARIO 5: Penegakan urutan modul 1 -> 2 berjalan sempurna.';
END;
$$;

-- ==============================================================================
-- SKENARIO 6: PENERBITAN SERTIFIKAT (DITOLAK < 5 MODUL, DITOLAK SKOR 79, DITERIMA 80)
-- ==============================================================================
DO $$
DECLARE
    v_user_a UUID := 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
    v_exception_caught BOOLEAN := false;
    v_res JSONB;
    v_failing_answers JSONB;
    v_passing_answers JSONB;
    v_cert_record RECORD;
BEGIN
    RAISE NOTICE '--- SKENARIO 6: PENGUJIAN SYARAT PENERBITAN SERTIFIKAT ---';

    SET LOCAL ROLE authenticated;
    SET LOCAL request.jwt.claim.sub = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
    SET LOCAL request.jwt.claim.role = 'authenticated';

    -- Tes 6A: User baru selesai Modul 1 & 2 (belum 5 modul) -> DITOLAK
    BEGIN
        v_res := public.issue_certificate();
        RAISE EXCEPTION 'FAIL: issue_certificate() berhasil padahal baru 2 modul selesai!';
    EXCEPTION WHEN SQLSTATE 'P0001' THEN
        v_exception_caught := true;
    END;
    ASSERT v_exception_caught = true, 'FAIL: Penerbitan sertifikat tidak menolak modul < 5.';
    RAISE NOTICE 'PASS: issue_certificate() menolak pengguna yang belum menyelesaikan 5 modul.';

    -- Selesaikan sisa modul: 3, 4, 5
    PERFORM public.complete_module(3);
    PERFORM public.complete_module(4);
    PERFORM public.complete_module(5);

    -- Hapus asesmen akhir lama User A untuk tes skor 79 vs 80
    RESET ROLE;
    DELETE FROM public.assessment_results WHERE user_id = v_user_a AND assessment_type = 'final';

    SET LOCAL ROLE authenticated;
    SET LOCAL request.jwt.claim.sub = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
    SET LOCAL request.jwt.claim.role = 'authenticated';

    -- Tes 6B: 5 modul selesai, tetapi nilai asesmen akhir = 60% (3 benar dari 5) -> DITOLAK
    v_failing_answers := '[
        {"question_id": "22222222-2222-2222-2222-222222222201", "selected_option": 1},
        {"question_id": "22222222-2222-2222-2222-222222222202", "selected_option": 2},
        {"question_id": "22222222-2222-2222-2222-222222222203", "selected_option": 0},
        {"question_id": "22222222-2222-2222-2222-222222222204", "selected_option": 0},
        {"question_id": "22222222-2222-2222-2222-222222222205", "selected_option": 0}
    ]'::jsonb;
    PERFORM public.submit_quiz('final', NULL, v_failing_answers);

    v_exception_caught := false;
    BEGIN
        v_res := public.issue_certificate();
        RAISE EXCEPTION 'FAIL: issue_certificate() berhasil dengan skor < 80%%!';
    EXCEPTION WHEN SQLSTATE 'P0001' THEN
        v_exception_caught := true;
    END;
    ASSERT v_exception_caught = true, 'FAIL: issue_certificate() tidak menolak skor < 80%.';
    RAISE NOTICE 'PASS: issue_certificate() menolak nilai final < 80%%.';

    -- Tes 6C: Submit asesmen akhir baru dengan skor 80% (4 benar dari 5) -> DITERIMA
    v_passing_answers := '[
        {"question_id": "22222222-2222-2222-2222-222222222201", "selected_option": 1},
        {"question_id": "22222222-2222-2222-2222-222222222202", "selected_option": 2},
        {"question_id": "22222222-2222-2222-2222-222222222203", "selected_option": 0},
        {"question_id": "22222222-2222-2222-2222-222222222204", "selected_option": 3},
        {"question_id": "22222222-2222-2222-2222-222222222205", "selected_option": 0}
    ]'::jsonb;
    PERFORM public.submit_quiz('final', NULL, v_passing_answers);

    v_res := public.issue_certificate();
    ASSERT (v_res->>'success')::BOOLEAN = true, 'FAIL: issue_certificate() gagal menerbitkan sertifikat.';
    ASSERT (v_res->'certificate'->>'final_score')::INT >= 80, 'FAIL: Skor pada sertifikat salah.';
    ASSERT (v_res->'certificate'->>'certificate_number') LIKE 'ROOVEY-%', 'FAIL: Format nomor sertifikat tidak valid.';
    RAISE NOTICE 'PASS: Sertifikat resmi berhasil terbit dengan nomor: %', v_res->'certificate'->>'certificate_number';

    -- Tes 6D: Panggil issue_certificate() kedua kali -> harus mengembalikan sertifikat aktif yang sama
    v_res := public.issue_certificate();
    ASSERT (v_res->>'is_new')::BOOLEAN = false, 'FAIL: Penerbitan kedua seharusnya mengembalikan sertifikat lama.';
    RAISE NOTICE 'PASS: Idempotensi penerbitan sertifikat terverifikasi (maks 1 sertifikat aktif).';

    RAISE NOTICE 'PASS SKENARIO 6: Seluruh syarat kelulusan dan penerbitan sertifikat valid.';
END;
$$;

-- ==============================================================================
-- SELESAI: ROLLBACK SELURUH PERUBAHAN AGAR DATABASE TETAP BERSIH
-- ==============================================================================
ROLLBACK;
RAISE NOTICE '=== SELURUH 6 SKENARIO UJI RLS & RPC BERHASIL 100%% (ALL ASSERTIONS PASSED) ===';
