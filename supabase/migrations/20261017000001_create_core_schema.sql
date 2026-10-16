-- ==============================================================================
-- MIGRATION 01: CREATE CORE SCHEMA
-- Project: RooveyLearn - Digital Learning Platform for Mangrove Conservation
-- Reference: PROPOSAL_ROOVEYLEARN.md (Bab 3.4 & 2.4), AUDIT_ROOVEYLEARN.md
-- ==============================================================================

-- 1. EXTENSIONS
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ==============================================================================
-- 2. TABLE DEFINITIONS (8 Core Tables + 1 Protected Answer Table)
-- ==============================================================================

-- 2.1 PROFILES
-- Menyimpan data profil peserta didik yang berelasi 1:1 dengan auth.users.
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    community_name TEXT,
    avatar_url TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

COMMENT ON TABLE public.profiles IS 'Profil peserta didik yang terhubung langsung ke akun Supabase Auth.';
COMMENT ON COLUMN public.profiles.id IS 'ID pengguna sama dengan auth.users.id.';

-- 2.2 LEARNING_MODULES
-- Menyimpan katalog 5 modul pembelajaran konservasi mangrove.
CREATE TABLE IF NOT EXISTS public.learning_modules (
    id INT PRIMARY KEY,
    order_index INT UNIQUE NOT NULL,
    title TEXT NOT NULL,
    subtitle TEXT,
    description TEXT NOT NULL,
    takeaway TEXT,
    learning_objectives JSONB NOT NULL DEFAULT '[]'::jsonb,
    duration_text TEXT NOT NULL DEFAULT '5 menit',
    icon_name TEXT,
    status TEXT NOT NULL DEFAULT 'published' CHECK (status IN ('draft', 'published', 'archived')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

COMMENT ON TABLE public.learning_modules IS 'Daftar 5 modul pembelajaran utama konservasi mangrove.';

-- 2.3 LEARNING_MATERIALS
-- Menyimpan materi detail per modul (teks, media pendukung, ringkasan).
CREATE TABLE IF NOT EXISTS public.learning_materials (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    module_id INT NOT NULL REFERENCES public.learning_modules(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    content TEXT NOT NULL,
    takeaway TEXT,
    media_type TEXT NOT NULL DEFAULT 'text' CHECK (media_type IN ('text', 'image', 'video', 'animation')),
    media_url TEXT,
    order_index INT NOT NULL DEFAULT 1,
    status TEXT NOT NULL DEFAULT 'published' CHECK (status IN ('draft', 'published', 'archived')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    CONSTRAINT uq_material_module_order UNIQUE (module_id, order_index)
);

COMMENT ON TABLE public.learning_materials IS 'Materi digital teks dan media pendukung untuk setiap modul.';

-- 2.4 QUIZ_QUESTIONS
-- Menyimpan bank soal kuis yang mendukung 3 kategori: 'pretest', 'module', dan 'final'.
-- CATATAN KEAMANAN: Kunci jawaban (correct_option_index) dan penjelasan (explanation)
-- sengaja dipisahkan ke tabel quiz_answers agar TIDAK BISA dibaca klien sama sekali.
CREATE TABLE IF NOT EXISTS public.quiz_questions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    quiz_type TEXT NOT NULL CHECK (quiz_type IN ('pretest', 'module', 'final')),
    module_id INT REFERENCES public.learning_modules(id) ON DELETE CASCADE,
    question_text TEXT NOT NULL,
    options JSONB NOT NULL,
    order_index INT NOT NULL DEFAULT 1,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    CONSTRAINT check_module_quiz_relation CHECK (
        (quiz_type = 'module' AND module_id IS NOT NULL) OR 
        (quiz_type IN ('pretest', 'final'))
    )
);

COMMENT ON TABLE public.quiz_questions IS 'Bank soal kuis (pretest, kuis modul, dan asesmen akhir). Tidak memuat kunci jawaban.';

-- 2.5 QUIZ_ANSWERS (PROTECTED TABLE)
-- TABEL TAMBAHAN YANG DIPERLUKAN UNTUK MEMENUHI ATURAN KEAMANAN (P0-02 & Aturan Desain Poin 3).
-- Rationale: Jika kolom kunci diletakkan di quiz_questions, query supabase.from('quiz_questions').select('*')
-- oleh klien berpotensi membocorkan kunci. Dengan memisahkannya ke tabel terisolasi tanpa policy SELECT
-- untuk anon/authenticated, kunci jawaban 100% aman di server dan hanya diakses oleh RPC penilaian.
CREATE TABLE IF NOT EXISTS public.quiz_answers (
    question_id UUID PRIMARY KEY REFERENCES public.quiz_questions(id) ON DELETE CASCADE,
    correct_option_index INT NOT NULL CHECK (correct_option_index >= 0),
    explanation TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

COMMENT ON TABLE public.quiz_answers IS 'Kunci jawaban dan penjelasan yang terisolasi ketat dari akses klien (hanya diakses via SECURITY DEFINER RPC).';

-- 2.6 USER_MODULE_PROGRESS
-- Mencatat progres penyelesaian modul tiap pengguna dan waktu penyelesaian.
CREATE TABLE IF NOT EXISTS public.user_module_progress (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    module_id INT NOT NULL REFERENCES public.learning_modules(id) ON DELETE CASCADE,
    status TEXT NOT NULL DEFAULT 'in_progress' CHECK (status IN ('not_started', 'in_progress', 'completed')),
    progress_percent INT NOT NULL DEFAULT 0 CHECK (progress_percent >= 0 AND progress_percent <= 100),
    started_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    completed_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    CONSTRAINT uq_user_module UNIQUE (user_id, module_id)
);

COMMENT ON TABLE public.user_module_progress IS 'Status penyelesaian modul bertahap per pengguna.';

-- 2.7 ASSESSMENT_RESULTS
-- Menyimpan riwayat hasil evaluasi (pre-test, kuis modul, dan asesmen akhir).
-- Klien DILARANG INSERT/UPDATE langsung. Hanya dicatat oleh RPC submit_quiz.
CREATE TABLE IF NOT EXISTS public.assessment_results (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    assessment_type TEXT NOT NULL CHECK (assessment_type IN ('pretest', 'module', 'final')),
    module_id INT REFERENCES public.learning_modules(id) ON DELETE SET NULL,
    score INT NOT NULL CHECK (score >= 0 AND score <= 100),
    total_questions INT NOT NULL CHECK (total_questions > 0),
    correct_answers INT NOT NULL CHECK (correct_answers >= 0),
    is_passed BOOLEAN NOT NULL DEFAULT false,
    attempt_number INT NOT NULL DEFAULT 1,
    submitted_answers JSONB NOT NULL DEFAULT '[]'::jsonb,
    completed_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

COMMENT ON TABLE public.assessment_results IS 'Riwayat evaluasi kuis resmi yang dihitung oleh server.';

-- 2.8 SIMULATION_ATTEMPTS
-- Mencatat riwayat latihan simulasi pengambilan keputusan dan prosedur lapangan.
CREATE TABLE IF NOT EXISTS public.simulation_attempts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    simulation_type TEXT NOT NULL CHECK (simulation_type IN (
        'decision_making',
        'planting_sequence',
        'sequence_diagnostic',
        'refractometer_calibration'
    )),
    module_id INT REFERENCES public.learning_modules(id) ON DELETE SET NULL,
    payload JSONB NOT NULL DEFAULT '{}'::jsonb,
    is_success BOOLEAN NOT NULL,
    score INT CHECK (score >= 0 AND score <= 100),
    feedback_given TEXT,
    xp_earned INT NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

COMMENT ON TABLE public.simulation_attempts IS 'Log percobaan simulasi interaktif lapangan oleh pengguna.';

-- 2.9 CERTIFICATES
-- Menyimpan sertifikat kelulusan program.
-- Klien DILARANG INSERT/UPDATE langsung. Hanya diterbitkan oleh RPC issue_certificate.
CREATE TABLE IF NOT EXISTS public.certificates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    certificate_number TEXT UNIQUE NOT NULL,
    assessment_result_id UUID NOT NULL REFERENCES public.assessment_results(id),
    final_score INT NOT NULL CHECK (final_score >= 80 AND final_score <= 100),
    status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'revoked')),
    issued_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- Aturan: Satu pengguna maksimal satu sertifikat aktif
CREATE UNIQUE INDEX IF NOT EXISTS unique_active_user_certificate 
ON public.certificates(user_id) 
WHERE (status = 'active');

COMMENT ON TABLE public.certificates IS 'Sertifikat kelulusan resmi dengan verifikasi server.';

-- ==============================================================================
-- 3. INDEXES FOR PERFORMANCE, FOREIGN KEYS, & RLS FILTERING
-- ==============================================================================

-- Profiles
CREATE INDEX IF NOT EXISTS idx_profiles_created_at ON public.profiles(created_at);

-- Learning Modules & Materials
CREATE INDEX IF NOT EXISTS idx_modules_status_order ON public.learning_modules(status, order_index);
CREATE INDEX IF NOT EXISTS idx_materials_module_status ON public.learning_materials(module_id, status, order_index);

-- Quiz Questions & Answers
CREATE INDEX IF NOT EXISTS idx_quiz_questions_type_module ON public.quiz_questions(quiz_type, module_id, is_active);
CREATE INDEX IF NOT EXISTS idx_quiz_questions_active_order ON public.quiz_questions(is_active, order_index);
CREATE INDEX IF NOT EXISTS idx_quiz_answers_question_id ON public.quiz_answers(question_id);

-- User Progress & Results (Heavy RLS filtering on user_id)
CREATE INDEX IF NOT EXISTS idx_module_progress_user_module ON public.user_module_progress(user_id, module_id);
CREATE INDEX IF NOT EXISTS idx_module_progress_user_status ON public.user_module_progress(user_id, status);

CREATE INDEX IF NOT EXISTS idx_assessment_results_user_type ON public.assessment_results(user_id, assessment_type);
CREATE INDEX IF NOT EXISTS idx_assessment_results_user_passed ON public.assessment_results(user_id, is_passed);

CREATE INDEX IF NOT EXISTS idx_simulation_attempts_user_type ON public.simulation_attempts(user_id, simulation_type);
CREATE INDEX IF NOT EXISTS idx_simulation_attempts_created_at ON public.simulation_attempts(created_at DESC);

-- Certificates
CREATE INDEX IF NOT EXISTS idx_certificates_user_status ON public.certificates(user_id, status);
CREATE INDEX IF NOT EXISTS idx_certificates_cert_number ON public.certificates(certificate_number);
