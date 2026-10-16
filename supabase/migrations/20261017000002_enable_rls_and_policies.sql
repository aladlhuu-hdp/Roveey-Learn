-- ==============================================================================
-- MIGRATION 02: ENABLE ROW LEVEL SECURITY (RLS) & EXPLICIT ACCESS POLICIES
-- Project: RooveyLearn - Digital Learning Platform for Mangrove Conservation
-- Reference: PROPOSAL_ROOVEYLEARN.md (Bab 3.4), AUDIT_ROOVEYLEARN.md (P0-02)
-- ==============================================================================

-- ==============================================================================
-- 1. ENABLE RLS ON ALL TABLES (Mandatory per Rule 9)
-- ==============================================================================
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.learning_modules ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.learning_materials ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.quiz_questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.quiz_answers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_module_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.assessment_results ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.simulation_attempts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.certificates ENABLE ROW LEVEL SECURITY;

-- ==============================================================================
-- 2. EXPLICIT POLICIES PER TABLE AND OPERATION
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- 2.1 PROFILES POLICIES
-- Aturan: Pengguna hanya dapat membaca, mengubah, dan menghapus profil mereka sendiri.
-- ------------------------------------------------------------------------------
CREATE POLICY profiles_select_own 
ON public.profiles 
FOR SELECT 
TO authenticated 
USING (auth.uid() = id);

CREATE POLICY profiles_insert_own 
ON public.profiles 
FOR INSERT 
TO authenticated 
WITH CHECK (auth.uid() = id);

CREATE POLICY profiles_update_own 
ON public.profiles 
FOR UPDATE 
TO authenticated 
USING (auth.uid() = id) 
WITH CHECK (auth.uid() = id);

CREATE POLICY profiles_delete_own 
ON public.profiles 
FOR DELETE 
TO authenticated 
USING (auth.uid() = id);

-- ------------------------------------------------------------------------------
-- 2.2 LEARNING_MODULES POLICIES
-- Aturan: Publik ('anon' dan 'authenticated') hanya boleh membaca modul yang published.
-- Operasi INSERT/UPDATE/DELETE dilarang untuk role pengguna (hanya service_role).
-- ------------------------------------------------------------------------------
CREATE POLICY modules_select_published 
ON public.learning_modules 
FOR SELECT 
TO anon, authenticated 
USING (status = 'published');

-- Tidak ada policy INSERT/UPDATE/DELETE untuk anon atau authenticated.

-- ------------------------------------------------------------------------------
-- 2.3 LEARNING_MATERIALS POLICIES
-- Aturan: Publik ('anon' dan 'authenticated') hanya boleh membaca materi yang published.
-- Operasi INSERT/UPDATE/DELETE dilarang untuk role pengguna.
-- ------------------------------------------------------------------------------
CREATE POLICY materials_select_published 
ON public.learning_materials 
FOR SELECT 
TO anon, authenticated 
USING (status = 'published');

-- Tidak ada policy INSERT/UPDATE/DELETE untuk anon atau authenticated.

-- ------------------------------------------------------------------------------
-- 2.4 QUIZ_QUESTIONS POLICIES
-- Aturan: Publik ('anon' dan 'authenticated') hanya boleh membaca soal yang aktif.
-- Catatan: Tabel ini TIDAK memuat kunci jawaban atau pembahasan.
-- ------------------------------------------------------------------------------
CREATE POLICY questions_select_active 
ON public.quiz_questions 
FOR SELECT 
TO anon, authenticated 
USING (is_active = true);

-- Tidak ada policy INSERT/UPDATE/DELETE untuk anon atau authenticated.

-- ------------------------------------------------------------------------------
-- 2.5 QUIZ_ANSWERS (PROTECTED TABLE) POLICIES
-- Aturan P0-02 & Poin 3: KUNCI JAWABAN TIDAK BOLEH DAPAT DIBACA KLIEN.
-- Hak akses dicabut sepenuhnya dari role 'anon' dan 'authenticated'.
-- Tidak ada policy SELECT yang dibuat, sehingga PostgREST default-deny.
-- Akses evaluasi hanya diperbolehkan lewat database function SECURITY DEFINER.
-- ------------------------------------------------------------------------------
REVOKE ALL ON public.quiz_answers FROM anon, authenticated;

-- ------------------------------------------------------------------------------
-- 2.6 USER_MODULE_PROGRESS POLICIES
-- Aturan Poin 7: Pengguna hanya mengakses progres miliknya.
-- Status 'completed' DILARANG diisi langsung via PostgREST INSERT/UPDATE klien.
-- Penyelesaian modul WAJIB melalui RPC complete_module() agar urutan modul ditegakkan.
-- ------------------------------------------------------------------------------
CREATE POLICY progress_select_own 
ON public.user_module_progress 
FOR SELECT 
TO authenticated 
USING (auth.uid() = user_id);

CREATE POLICY progress_insert_own 
ON public.user_module_progress 
FOR INSERT 
TO authenticated 
WITH CHECK (
    auth.uid() = user_id AND 
    status != 'completed'
);

CREATE POLICY progress_update_own 
ON public.user_module_progress 
FOR UPDATE 
TO authenticated 
USING (auth.uid() = user_id) 
WITH CHECK (
    auth.uid() = user_id AND 
    status != 'completed'
);

CREATE POLICY progress_delete_own 
ON public.user_module_progress 
FOR DELETE 
TO authenticated 
USING (auth.uid() = user_id);

-- ------------------------------------------------------------------------------
-- 2.7 ASSESSMENT_RESULTS POLICIES
-- Aturan Poin 5: Klien DILARANG INSERT/UPDATE langsung ke assessment_results.
-- Hanya RPC submit_quiz() dengan hak SECURITY DEFINER yang dapat mencatat hasil.
-- Pengguna authenticated hanya boleh SELECT riwayat evaluasi miliknya sendiri.
-- ------------------------------------------------------------------------------
CREATE POLICY assessment_select_own 
ON public.assessment_results 
FOR SELECT 
TO authenticated 
USING (auth.uid() = user_id);

-- Tidak ada policy INSERT, UPDATE, atau DELETE untuk anon atau authenticated.

-- ------------------------------------------------------------------------------
-- 2.8 SIMULATION_ATTEMPTS POLICIES
-- Aturan Poin 8: Pengguna boleh INSERT dan SELECT baris miliknya sendiri.
-- Pengguna TIDAK boleh UPDATE atau DELETE baris mana pun (log aktivitas bersifat immutable).
-- ------------------------------------------------------------------------------
CREATE POLICY simulation_select_own 
ON public.simulation_attempts 
FOR SELECT 
TO authenticated 
USING (auth.uid() = user_id);

CREATE POLICY simulation_insert_own 
ON public.simulation_attempts 
FOR INSERT 
TO authenticated 
WITH CHECK (auth.uid() = user_id);

-- Tidak ada policy UPDATE atau DELETE untuk menjaga integritas data audit simulasi.

-- ------------------------------------------------------------------------------
-- 2.9 CERTIFICATES POLICIES
-- Aturan Poin 5 & 6: Klien DILARANG INSERT/UPDATE langsung ke certificates.
-- Penerbitan sertifikat hanya dapat dilakukan via RPC issue_certificate() server.
-- Pengguna hanya dapat SELECT sertifikat aktif miliknya sendiri.
-- ------------------------------------------------------------------------------
CREATE POLICY certificates_select_own 
ON public.certificates 
FOR SELECT 
TO authenticated 
USING (auth.uid() = user_id);

-- Tidak ada policy INSERT, UPDATE, atau DELETE untuk anon atau authenticated.
