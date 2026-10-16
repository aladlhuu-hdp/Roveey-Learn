-- ==============================================================================
-- MIGRATION 04: SEED INITIAL DATA
-- Project: RooveyLearn - Digital Learning Platform for Mangrove Conservation
-- Reference: lib/models/learning_module.dart, lib/models/quiz_question.dart
-- ==============================================================================

-- ==============================================================================
-- 1. SEED LEARNING MODULES (1 s/d 5)
-- Sumber: learningModules pada Flutter prototype
-- ==============================================================================
INSERT INTO public.learning_modules (
    id,
    order_index,
    title,
    subtitle,
    description,
    takeaway,
    learning_objectives,
    duration_text,
    icon_name,
    status
) VALUES 
(
    1,
    1,
    'Kenali Mangrove',
    'Dasar ekosistem mangrove',
    'Mangrove adalah kelompok tumbuhan yang mampu hidup di wilayah pesisir yang dipengaruhi pasang surut. Setiap jenis memiliki karakteristik dan adaptasi yang berbeda.',
    'Mangrove bukan hanya pohon di tepi laut. Ia adalah bagian dari ekosistem pesisir yang saling terhubung.',
    '["Memahami definisi dan zona habitat mangrove", "Mengenal adaptasi akar dan daun terhadap salinitas", "Mengidentifikasi jenis mangrove dominan di pesisir Indonesia"]'::jsonb,
    '5 menit',
    'spa_rounded',
    'published'
),
(
    2,
    2,
    'Mengapa Mangrove Penting?',
    'Peran mangrove bagi pesisir',
    'Akar mangrove membantu menahan sedimen, menyediakan tempat berlindung bagi biota, dan dapat mengurangi energi gelombang. Ekosistem ini juga menyimpan karbon dalam biomassa dan sedimennya.',
    'Melindungi mangrove berarti ikut menjaga pesisir, habitat biota, dan sumber penghidupan masyarakat.',
    '["Memahami fungsi fisik peredam gelombang dan pencegah abrasi", "Memahami fungsi ekologis sebagai nursery ground dan penyerap karbon", "Mengetahui manfaat sosial-ekonomi bagi nelayan dan masyarakat pesisir"]'::jsonb,
    '6 menit',
    'public_rounded',
    'published'
),
(
    3,
    3,
    'Penanaman Mangrove',
    'Pemulihan dan penanaman',
    'Keberhasilan rehabilitasi dimulai dari memahami kondisi lokasi. Jenis, hidrologi, substrat, pasang surut, dan kondisi vegetasi yang ada perlu dipertimbangkan sebelum menentukan teknik penanaman.',
    'Jangan terburu-buru menanam. Pastikan lokasi memang sesuai dan penyebab kerusakan telah dipahami.',
    '["Melakukan asesmen awal kesesuaian substrat dan salinitas tanah", "Memilih bibit berkualitas sesuai zona pasang surut", "Menerapkan teknik penanaman dan pemancangan ajir yang benar"]'::jsonb,
    '8 menit',
    'grass_rounded',
    'published'
),
(
    4,
    4,
    'Pemeliharaan Bibit',
    'Perawatan bibit',
    'Penanaman bukan akhir pekerjaan. Bibit perlu diperiksa secara berkala untuk mengetahui gangguan, kerusakan, perubahan kondisi air, sampah, atau penyebab kematian.',
    'Pantau penyebab masalah terlebih dahulu sebelum memutuskan perawatan atau penanaman ulang.',
    '["Mengidentifikasi serangan hama seperti teritip, kepiting, dan lumut", "Membersihkan sampah lilitan dan sedimentasi berlebih", "Mengambil tindakan sulaman (penanaman ulang) yang terarah"]'::jsonb,
    '7 menit',
    'volunteer_activism_rounded',
    'published'
),
(
    5,
    5,
    'Monitoring Mangrove',
    'Pengamatan dan evaluasi',
    'Monitoring sederhana mencatat jumlah bibit yang hidup, pertumbuhan, kondisi lingkungan, waktu pengamatan, dan lokasi. Data yang konsisten membantu masyarakat mengevaluasi hasil rehabilitasi.',
    'Catatan lapangan yang konsisten membantu mengubah pengamatan menjadi dasar pengambilan keputusan.',
    '["Menghitung Survival Rate (tingkat kelangsungan hidup) bibit", "Mengukur parameter pertumbuhan tinggi dan jumlah daun", "Melakukan dokumentasi dan pelaporan berkala"]'::jsonb,
    '6 menit',
    'fact_check_rounded',
    'published'
)
ON CONFLICT (id) DO UPDATE SET
    order_index = EXCLUDED.order_index,
    title = EXCLUDED.title,
    subtitle = EXCLUDED.subtitle,
    description = EXCLUDED.description,
    takeaway = EXCLUDED.takeaway,
    learning_objectives = EXCLUDED.learning_objectives,
    duration_text = EXCLUDED.duration_text,
    icon_name = EXCLUDED.icon_name,
    status = EXCLUDED.status,
    updated_at = timezone('utc'::text, now());

-- ==============================================================================
-- 2. SEED INITIAL LEARNING MATERIALS
-- Menyediakan materi bacaan awal per modul
-- ==============================================================================
INSERT INTO public.learning_materials (
    id,
    module_id,
    title,
    content,
    takeaway,
    media_type,
    order_index,
    status
) VALUES
(
    '11111111-1111-1111-1111-111111111101'::uuid,
    1,
    'Dasar Ekosistem Mangrove',
    'Mangrove adalah kelompok tumbuhan yang mampu hidup di wilayah pesisir yang dipengaruhi pasang surut air laut. Tumbuhan ini memiliki adaptasi fisiologis dan morfologis yang luar biasa, seperti sistem perakaran khusus (akar napas/pneumatofor, akar tunjang, dan akar lutut) untuk bernapas pada substrat berlumpur yang miskin oksigen serta kelenjar garam pada daun untuk mengeluarkan kelebihan kadar garam.',
    'Mangrove bukan hanya pohon di tepi laut. Ia adalah bagian dari ekosistem pesisir yang saling terhubung.',
    'text',
    1,
    'published'
),
(
    '11111111-1111-1111-1111-111111111102'::uuid,
    2,
    'Peran Vital Mangrove bagi Kawasan Pesisir',
    'Akar mangrove yang rapat berfungsi sebagai perangkap sedimen alami dan memecah energi ombak sehingga melindungi garis pantai dari bahaya abrasi dan erosi. Selain sebagai pelindung fisik, hutan mangrove menyediakan daerah asuhan (nursery ground), tempat mencari makan (feeding ground), dan tempat pemijahan (spawning ground) bagi kepiting bakau, udang, dan ikan. Mangrove juga termasuk ekosistem karbon biru (blue carbon) dengan kapasitas penyimpanan karbon per hektar yang jauh lebih tinggi daripada hutan daratan.',
    'Melindungi mangrove berarti ikut menjaga pesisir, habitat biota, dan sumber penghidupan masyarakat.',
    'text',
    1,
    'published'
),
(
    '11111111-1111-1111-1111-111111111103'::uuid,
    3,
    'Prinsip Keberhasilan Penanaman Mangrove',
    'Keberhasilan rehabilitasi dimulai dari pemahaman mendalam atas kondisi lokasi sebelum bibit ditanam. Kesalahan umum penanaman pesisir adalah menanam pada lokasi yang terlalu sering terendam atau memiliki salinitas ekstrem tanpa asesmen pendahuluan. Penentuan jenis pohon (Rhizophora, Avicennia, Sonneratia) harus dicocokkan dengan zonasi pantai, frekuensi genangan pasang surut, serta tipe sedimen lumpur atau pasir.',
    'Jangan terburu-buru menanam. Pastikan lokasi memang sesuai dan penyebab kerusakan telah dipahami.',
    'text',
    1,
    'published'
),
(
    '11111111-1111-1111-1111-111111111104'::uuid,
    4,
    'Protokol Perawatan dan Pemeliharaan Bibit',
    'Tahap pasca-penanaman (0-12 bulan pertama) merupakan masa kritis pertumbuhan bibit. Pemeriksaan berkala diperlukan untuk membersihkan sampah plastik atau jaring yang tersangkut pada batang, memeriksa serangan teritip (barnacles) yang dapat membebani bibit muda, dan mendeteksi bibit yang roboh akibat hempasan gelombang kencang. Apabila dijumpai bibit yang mati, lakukan pencatatan penyebab kematian sebelum memutuskan penyulaman (penanaman bibit pengganti).',
    'Pantau penyebab masalah terlebih dahulu sebelum memutuskan perawatan atau penanaman ulang.',
    'text',
    1,
    'published'
),
(
    '11111111-1111-1111-1111-111111111105'::uuid,
    5,
    'Pemantauan Lapangan dan Penghitungan Survival Rate',
    'Monitoring berkala dilakukan secara terstruktur (pada bulan ke-1, ke-3, ke-6, dan ke-12). Indikator utama keberhasilan pemulihan adalah Survival Rate (SR), yaitu persentase bibit hidup dibandingkan total bibit awal yang ditanam. Selain SR, catat pula tinggi tanaman, pertambahan helai daun, kondisi substrat, dan kehadiran biota pesisir sebagai indikator pulihnya rantai makanan ekosistem.',
    'Catatan lapangan yang konsisten membantu mengubah pengamatan menjadi dasar pengambilan keputusan.',
    'text',
    1,
    'published'
)
ON CONFLICT (id) DO UPDATE SET
    title = EXCLUDED.title,
    content = EXCLUDED.content,
    takeaway = EXCLUDED.takeaway,
    media_type = EXCLUDED.media_type,
    order_index = EXCLUDED.order_index,
    status = EXCLUDED.status,
    updated_at = timezone('utc'::text, now());

-- ==============================================================================
-- 3. SEED FINAL ASSESSMENT QUIZ QUESTIONS & ANSWERS (5 BUTIR SOAL KUIS AKHIR)
-- Diambil langsung dari quizQuestions pada prototipe Flutter
-- ==============================================================================

-- Soal 1
INSERT INTO public.quiz_questions (
    id,
    quiz_type,
    module_id,
    question_text,
    options,
    order_index,
    is_active
) VALUES (
    '22222222-2222-2222-2222-222222222201'::uuid,
    'final',
    NULL,
    'Apa yang membuat mangrove penting bagi ekosistem pesisir?',
    '["Hanya memperindah pemandangan", "Menyediakan habitat dan membantu menstabilkan sedimen", "Menghilangkan seluruh gelombang laut", "Mengubah air laut menjadi air tawar"]'::jsonb,
    1,
    true
) ON CONFLICT (id) DO UPDATE SET
    question_text = EXCLUDED.question_text,
    options = EXCLUDED.options,
    order_index = EXCLUDED.order_index,
    is_active = EXCLUDED.is_active;

INSERT INTO public.quiz_answers (
    question_id,
    correct_option_index,
    explanation
) VALUES (
    '22222222-2222-2222-2222-222222222201'::uuid,
    1,
    'Mangrove mendukung habitat biota dan membantu menahan sedimen.'
) ON CONFLICT (question_id) DO UPDATE SET
    correct_option_index = EXCLUDED.correct_option_index,
    explanation = EXCLUDED.explanation;

-- Soal 2
INSERT INTO public.quiz_questions (
    id,
    quiz_type,
    module_id,
    question_text,
    options,
    order_index,
    is_active
) VALUES (
    '22222222-2222-2222-2222-222222222202'::uuid,
    'final',
    NULL,
    'Apa yang sebaiknya diperiksa sebelum rehabilitasi?',
    '["Warna seragam relawan", "Jumlah bibit sebanyak-banyaknya", "Kesesuaian lokasi dan kondisi hidrologi", "Desain spanduk kegiatan"]'::jsonb,
    2,
    true
) ON CONFLICT (id) DO UPDATE SET
    question_text = EXCLUDED.question_text,
    options = EXCLUDED.options,
    order_index = EXCLUDED.order_index,
    is_active = EXCLUDED.is_active;

INSERT INTO public.quiz_answers (
    question_id,
    correct_option_index,
    explanation
) VALUES (
    '22222222-2222-2222-2222-222222222202'::uuid,
    2,
    'Kondisi lokasi menentukan jenis dan tindakan yang sesuai.'
) ON CONFLICT (question_id) DO UPDATE SET
    correct_option_index = EXCLUDED.correct_option_index,
    explanation = EXCLUDED.explanation;

-- Soal 3
INSERT INTO public.quiz_questions (
    id,
    quiz_type,
    module_id,
    question_text,
    options,
    order_index,
    is_active
) VALUES (
    '22222222-2222-2222-2222-222222222203'::uuid,
    'final',
    NULL,
    'Apa tindakan yang tepat saat banyak bibit mati?',
    '["Catat kondisi lalu cari penyebabnya", "Tanam ulang tanpa memeriksa", "Berhenti melakukan monitoring", "Pindahkan semua bibit ke laut dalam"]'::jsonb,
    3,
    true
) ON CONFLICT (id) DO UPDATE SET
    question_text = EXCLUDED.question_text,
    options = EXCLUDED.options,
    order_index = EXCLUDED.order_index,
    is_active = EXCLUDED.is_active;

INSERT INTO public.quiz_answers (
    question_id,
    correct_option_index,
    explanation
) VALUES (
    '22222222-2222-2222-2222-222222222203'::uuid,
    0,
    'Mengetahui penyebab membantu tim memilih tindakan perbaikan.'
) ON CONFLICT (question_id) DO UPDATE SET
    correct_option_index = EXCLUDED.correct_option_index,
    explanation = EXCLUDED.explanation;

-- Soal 4
INSERT INTO public.quiz_questions (
    id,
    quiz_type,
    module_id,
    question_text,
    options,
    order_index,
    is_active
) VALUES (
    '22222222-2222-2222-2222-222222222204'::uuid,
    'final',
    NULL,
    'Survival rate menunjukkan ...',
    '["Jumlah jenis ikan yang terlihat", "Tinggi pasang tertinggi", "Jumlah relawan yang hadir", "Persentase bibit yang bertahan hidup"]'::jsonb,
    4,
    true
) ON CONFLICT (id) DO UPDATE SET
    question_text = EXCLUDED.question_text,
    options = EXCLUDED.options,
    order_index = EXCLUDED.order_index,
    is_active = EXCLUDED.is_active;

INSERT INTO public.quiz_answers (
    question_id,
    correct_option_index,
    explanation
) VALUES (
    '22222222-2222-2222-2222-222222222204'::uuid,
    3,
    'Survival rate adalah proporsi bibit hidup dibanding jumlah bibit awal.'
) ON CONFLICT (question_id) DO UPDATE SET
    correct_option_index = EXCLUDED.correct_option_index,
    explanation = EXCLUDED.explanation;

-- Soal 5
INSERT INTO public.quiz_questions (
    id,
    quiz_type,
    module_id,
    question_text,
    options,
    order_index,
    is_active
) VALUES (
    '22222222-2222-2222-2222-222222222205'::uuid,
    'final',
    NULL,
    'Apa manfaat monitoring yang konsisten?',
    '["Menghilangkan kebutuhan merawat bibit", "Membantu mengevaluasi pertumbuhan dan hasil rehabilitasi", "Menjamin semua bibit tumbuh tanpa risiko", "Menggantikan semua observasi lapangan"]'::jsonb,
    5,
    true
) ON CONFLICT (id) DO UPDATE SET
    question_text = EXCLUDED.question_text,
    options = EXCLUDED.options,
    order_index = EXCLUDED.order_index,
    is_active = EXCLUDED.is_active;

INSERT INTO public.quiz_answers (
    question_id,
    correct_option_index,
    explanation
) VALUES (
    '22222222-2222-2222-2222-222222222205'::uuid,
    1,
    'Data pengamatan yang konsisten mendukung evaluasi dan keputusan selanjutnya.'
) ON CONFLICT (question_id) DO UPDATE SET
    correct_option_index = EXCLUDED.correct_option_index,
    explanation = EXCLUDED.explanation;

-- ==============================================================================
-- 4. PLACEHOLDER / TODO: PRETEST & MODULE QUIZZES (P1-01 & P1-02)
-- ==============================================================================
-- TODO (Sprint 3 - Content Enhancement):
-- 1. Penambahan paket soal kuis 'pretest' (5-10 butir soal diagnostik awal).
-- 2. Penambahan paket soal kuis 'module' per modul 1 s/d 5 (masing-masing 3-5 butir soal formatif).
-- 3. Penambahan variasi bank soal asesmen akhir ('final') menjadi 10 butir terverifikasi ilmiah.
