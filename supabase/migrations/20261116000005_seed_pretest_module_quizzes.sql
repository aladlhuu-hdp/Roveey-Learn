-- ==============================================================================
-- MIGRATION 0005: BANK SOAL PRE-TEST, KUIS MODUL, ASESMEN AKHIR TAMBAHAN,
--                 DAN PENGAYAAN MATERI PER MODUL
-- Project: RooveyLearn
-- Catatan:
--   * Soal pre-test SENGAJA berbeda dari soal asesmen akhir agar pengukuran
--     peningkatan pemahaman (pre vs post) tidak bias.
--   * Konten adalah draf edukatif dan perlu direview oleh pengampu/ahli materi.
--   * Seluruh INSERT bersifat idempoten (ON CONFLICT ... DO UPDATE).
-- ID scheme:
--   pretest : 44444444-4444-4444-4444-4444444444PN   (N = 01..05)
--   module  : 55555555-5555-5555-5555-5555555555MQ   (M = modul 1..5, Q = 1..3)
--   final   : 22222222-2222-2222-2222-2222222222NN   (NN = 06..10, melanjutkan 01..05)
--   materi  : 11111111-1111-1111-1111-1111111112MO   (M = modul, O = urutan 2..3)
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- 1. PRE-TEST (5 SOAL)
-- ------------------------------------------------------------------------------
INSERT INTO public.quiz_questions (id, quiz_type, module_id, question_text, options, order_index, is_active) VALUES
('44444444-4444-4444-4444-444444444401'::uuid, 'pretest', NULL,
 'Di mana mangrove umumnya tumbuh?',
 '["Di puncak pegunungan", "Di wilayah pesisir yang dipengaruhi pasang surut", "Di gurun pasir", "Di danau air tawar dataran tinggi"]'::jsonb, 1, true),
('44444444-4444-4444-4444-444444444402'::uuid, 'pretest', NULL,
 'Akar napas (pneumatofor) pada mangrove berfungsi untuk...',
 '["Menyimpan air tawar", "Menarik serangga penyerbuk", "Membantu tumbuhan bernapas di lumpur yang miskin oksigen", "Menahan buah agar tidak jatuh"]'::jsonb, 2, true),
('44444444-4444-4444-4444-444444444403'::uuid, 'pretest', NULL,
 'Istilah "blue carbon" berkaitan dengan...',
 '["Karbon yang disimpan ekosistem pesisir dan laut seperti mangrove", "Pewarna biru dari daun mangrove", "Bahan bakar kapal nelayan", "Polusi plastik di laut"]'::jsonb, 3, true),
('44444444-4444-4444-4444-444444444404'::uuid, 'pretest', NULL,
 'Survival rate (SR) bibit mangrove dihitung dengan cara...',
 '["Jumlah bibit mati dikali dua", "Tinggi bibit dibagi jumlah daun", "Jumlah relawan dibagi luas lahan", "(Bibit hidup ÷ bibit awal ditanam) × 100%"]'::jsonb, 4, true),
('44444444-4444-4444-4444-444444444405'::uuid, 'pretest', NULL,
 'Mengapa waktu surut sering dipilih untuk menanam mangrove?',
 '["Karena bibit hanya bisa ditanam pada malam hari", "Agar lubang tanam dan substrat dapat dikerjakan dengan aman", "Supaya bibit langsung terendam air dalam", "Tidak ada alasan khusus"]'::jsonb, 5, true)
ON CONFLICT (id) DO UPDATE SET
    question_text = EXCLUDED.question_text,
    options = EXCLUDED.options,
    order_index = EXCLUDED.order_index,
    is_active = EXCLUDED.is_active;

INSERT INTO public.quiz_answers (question_id, correct_option_index, explanation) VALUES
('44444444-4444-4444-4444-444444444401'::uuid, 1, 'Mangrove tumbuh di zona intertidal pesisir yang tergenang saat pasang dan terbuka saat surut.'),
('44444444-4444-4444-4444-444444444402'::uuid, 2, 'Pneumatofor menyerap oksigen dari udara karena lumpur mangrove miskin oksigen (anoksik).'),
('44444444-4444-4444-4444-444444444403'::uuid, 0, 'Blue carbon adalah karbon yang ditangkap dan disimpan ekosistem pesisir seperti mangrove, lamun, dan rawa payau.'),
('44444444-4444-4444-4444-444444444404'::uuid, 3, 'SR = (jumlah bibit hidup ÷ jumlah bibit awal yang ditanam) × 100%.'),
('44444444-4444-4444-4444-444444444405'::uuid, 1, 'Saat surut, substrat terbuka sehingga lubang tanam, ajir, dan bibit dapat dipasang dengan aman dan rapi.')
ON CONFLICT (question_id) DO UPDATE SET
    correct_option_index = EXCLUDED.correct_option_index,
    explanation = EXCLUDED.explanation;

-- ------------------------------------------------------------------------------
-- 2. KUIS MODUL (3 SOAL PER MODUL, TOTAL 15)
-- ------------------------------------------------------------------------------
INSERT INTO public.quiz_questions (id, quiz_type, module_id, question_text, options, order_index, is_active) VALUES
-- Modul 1: Kenali Mangrove
('55555555-5555-5555-5555-555555555511'::uuid, 'module', 1,
 'Ciri utama lingkungan tempat hidup mangrove adalah...',
 '["Tergenang air tawar sepanjang tahun", "Dipengaruhi pasang surut air laut dan bersubstrat lumpur", "Tanah kering berbatu", "Bersalju pada musim dingin"]'::jsonb, 1, true),
('55555555-5555-5555-5555-555555555512'::uuid, 'module', 1,
 'Bagaimana sebagian jenis mangrove mengatasi kadar garam yang tinggi?',
 '["Menyimpan garam di dalam bunga", "Tidak pernah terkena air laut", "Menggugurkan seluruh akar setiap hari", "Mengeluarkan garam melalui kelenjar pada daun"]'::jsonb, 2, true),
('55555555-5555-5555-5555-555555555513'::uuid, 'module', 1,
 'Akar tunjang yang mencuat dari batang paling khas dimiliki oleh genus...',
 '["Avicennia", "Rhizophora", "Nypa", "Pinus"]'::jsonb, 3, true),
-- Modul 2: Mengapa Mangrove Penting?
('55555555-5555-5555-5555-555555555521'::uuid, 'module', 2,
 'Bagaimana mangrove melindungi garis pantai?',
 '["Meningkatkan tinggi gelombang", "Menghalangi masuknya ikan", "Akar yang rapat meredam energi gelombang dan menahan sedimen", "Mengeringkan air laut"]'::jsonb, 1, true),
('55555555-5555-5555-5555-555555555522'::uuid, 'module', 2,
 'Istilah "nursery ground" pada ekosistem mangrove berarti...',
 '["Daerah asuhan bagi anakan ikan, udang, dan kepiting", "Tempat pembibitan tanaman hias", "Lokasi wisata keluarga", "Gudang penyimpanan hasil tangkapan"]'::jsonb, 2, true),
('55555555-5555-5555-5555-555555555523'::uuid, 'module', 2,
 'Manfaat ekonomi mangrove bagi masyarakat pesisir antara lain...',
 '["Lahan tambang batu bara", "Tempat pembuangan sampah", "Tidak ada manfaat ekonomi", "Sumber hasil perikanan, produk olahan, dan ekowisata"]'::jsonb, 3, true),
-- Modul 3: Penanaman Mangrove
('55555555-5555-5555-5555-555555555531'::uuid, 'module', 3,
 'Langkah pertama sebelum menanam mangrove di lokasi baru adalah...',
 '["Langsung menanam sebanyak mungkin bibit", "Melakukan asesmen kesesuaian lokasi, hidrologi, dan substrat", "Menebang vegetasi yang ada", "Membangun jalur wisata"]'::jsonb, 1, true),
('55555555-5555-5555-5555-555555555532'::uuid, 'module', 3,
 'Mengapa jenis mangrove harus dicocokkan dengan zonasi pantai?',
 '["Agar warna daun seragam", "Supaya harga bibit lebih murah", "Setiap jenis memiliki toleransi berbeda terhadap genangan, salinitas, dan substrat", "Karena aturan estetika kawasan"]'::jsonb, 2, true),
('55555555-5555-5555-5555-555555555533'::uuid, 'module', 3,
 'Ajir (tiang bambu) dipasang di samping bibit untuk...',
 '["Menopang bibit agar tidak roboh terbawa arus dan gelombang", "Menandai lokasi wisata", "Mengusir burung", "Menambah nutrisi tanah"]'::jsonb, 3, true),
-- Modul 4: Pemeliharaan Bibit
('55555555-5555-5555-5555-555555555541'::uuid, 'module', 4,
 'Masa paling kritis bagi bibit mangrove adalah...',
 '["Setelah pohon berumur 20 tahun", "Sekitar 0–12 bulan pertama setelah tanam", "Saat pohon berbunga pertama kali", "Tidak ada masa kritis"]'::jsonb, 1, true),
('55555555-5555-5555-5555-555555555542'::uuid, 'module', 4,
 'Sampah plastik atau jaring yang tersangkut pada bibit sebaiknya...',
 '["Dibiarkan karena melindungi bibit", "Ditambah agar bibit lebih kuat", "Dibakar di lokasi", "Dibersihkan secara berkala agar bibit tidak tertekan atau patah"]'::jsonb, 2, true),
('55555555-5555-5555-5555-555555555543'::uuid, 'module', 4,
 'Sebelum melakukan penyulaman (mengganti bibit yang mati), apa yang perlu dilakukan?',
 '["Mencatat dan memahami penyebab kematian bibit", "Menanam jenis apa saja yang tersedia", "Menunggu lima tahun", "Memindahkan seluruh bibit yang hidup"]'::jsonb, 3, true),
-- Modul 5: Monitoring & Evaluasi
('55555555-5555-5555-5555-555555555551'::uuid, 'module', 5,
 'Dari 200 bibit yang ditanam, 150 masih hidup. Berapa survival rate-nya?',
 '["50%", "65%", "75%", "150%"]'::jsonb, 1, true),
('55555555-5555-5555-5555-555555555552'::uuid, 'module', 5,
 'Data apa yang sebaiknya dicatat saat monitoring selain survival rate?',
 '["Merek sepatu relawan", "Tinggi tanaman, jumlah daun, kondisi substrat, dan biota", "Jumlah unggahan di media sosial", "Harga bibit di pasar"]'::jsonb, 2, true),
('55555555-5555-5555-5555-555555555553'::uuid, 'module', 5,
 'Mengapa monitoring dilakukan secara berkala (misalnya bulan ke-1, 3, 6, dan 12)?',
 '["Supaya laporan terlihat tebal", "Karena bibit hanya tumbuh pada bulan tertentu", "Tidak perlu dilakukan berkala", "Agar perubahan kondisi dapat dibandingkan dan tindakan diambil tepat waktu"]'::jsonb, 3, true)
ON CONFLICT (id) DO UPDATE SET
    module_id = EXCLUDED.module_id,
    question_text = EXCLUDED.question_text,
    options = EXCLUDED.options,
    order_index = EXCLUDED.order_index,
    is_active = EXCLUDED.is_active;

INSERT INTO public.quiz_answers (question_id, correct_option_index, explanation) VALUES
('55555555-5555-5555-5555-555555555511'::uuid, 1, 'Mangrove hidup di zona pasang surut dengan substrat lumpur atau pasir berlumpur yang payau hingga asin.'),
('55555555-5555-5555-5555-555555555512'::uuid, 3, 'Jenis seperti Avicennia memiliki kelenjar garam pada daun untuk membuang kelebihan garam.'),
('55555555-5555-5555-5555-555555555513'::uuid, 1, 'Rhizophora (bakau) dikenali dari akar tunjangnya; Avicennia (api-api) memiliki akar napas berbentuk pensil.'),
('55555555-5555-5555-5555-555555555521'::uuid, 2, 'Jalinan akar meredam energi gelombang dan memerangkap sedimen sehingga mengurangi abrasi.'),
('55555555-5555-5555-5555-555555555522'::uuid, 0, 'Nursery ground adalah tempat anakan biota laut berlindung dan tumbuh sebelum ke laut lepas.'),
('55555555-5555-5555-5555-555555555523'::uuid, 3, 'Mangrove menopang perikanan (kepiting, udang, ikan), produk olahan (sirup, dodol), dan ekowisata.'),
('55555555-5555-5555-5555-555555555531'::uuid, 1, 'Asesmen lokasi memastikan kondisi hidrologi, elevasi, dan substrat sesuai sebelum penanaman.'),
('55555555-5555-5555-5555-555555555532'::uuid, 2, 'Menanam jenis yang tidak sesuai zonasi adalah penyebab umum kegagalan rehabilitasi.'),
('55555555-5555-5555-5555-555555555533'::uuid, 0, 'Ajir menahan bibit muda dari hempasan arus dan gelombang hingga akarnya cukup kuat.'),
('55555555-5555-5555-5555-555555555541'::uuid, 1, 'Tahun pertama setelah tanam adalah masa kritis; bibit rentan hanyut, roboh, dan terserang hama.'),
('55555555-5555-5555-5555-555555555542'::uuid, 3, 'Sampah dan jaring menambah beban serta menghambat fotosintesis sehingga harus dibersihkan rutin.'),
('55555555-5555-5555-5555-555555555543'::uuid, 0, 'Penyebab kematian (hama, genangan, arus, substrat) menentukan apakah penyulaman akan berhasil.'),
('55555555-5555-5555-5555-555555555551'::uuid, 2, 'SR = 150 ÷ 200 × 100% = 75%.'),
('55555555-5555-5555-5555-555555555552'::uuid, 1, 'Indikator pertumbuhan dan kondisi lingkungan membantu menjelaskan mengapa bibit hidup atau mati.'),
('55555555-5555-5555-5555-555555555553'::uuid, 3, 'Data berkala memungkinkan perbandingan antarwaktu dan keputusan pemeliharaan yang tepat.')
ON CONFLICT (question_id) DO UPDATE SET
    correct_option_index = EXCLUDED.correct_option_index,
    explanation = EXCLUDED.explanation;

-- ------------------------------------------------------------------------------
-- 3. ASESMEN AKHIR TAMBAHAN (SOAL 6–10, TOTAL MENJADI 10 SOAL)
-- ------------------------------------------------------------------------------
INSERT INTO public.quiz_questions (id, quiz_type, module_id, question_text, options, order_index, is_active) VALUES
('22222222-2222-2222-2222-222222222206'::uuid, 'final', NULL,
 'Jenis mangrove yang memiliki akar napas (pneumatofor) berbentuk seperti pensil adalah...',
 '["Rhizophora", "Avicennia", "Cocos nucifera", "Pandanus"]'::jsonb, 6, true),
('22222222-2222-2222-2222-222222222207'::uuid, 'final', NULL,
 'Manakah yang merupakan kesalahan umum dalam rehabilitasi mangrove?',
 '["Melakukan monitoring berkala", "Melibatkan masyarakat setempat", "Menanam di lokasi yang terlalu lama tergenang tanpa asesmen", "Mencatat penyebab kematian bibit"]'::jsonb, 7, true),
('22222222-2222-2222-2222-222222222208'::uuid, 'final', NULL,
 'Mengapa ekosistem mangrove penting dalam mitigasi perubahan iklim?',
 '["Menyimpan karbon dalam jumlah besar di biomassa dan sedimen", "Menghasilkan lebih banyak gas rumah kaca", "Menurunkan permukaan laut secara langsung", "Mengubah arah angin muson"]'::jsonb, 8, true),
('22222222-2222-2222-2222-222222222209'::uuid, 'final', NULL,
 'Penyulaman dalam pemeliharaan mangrove berarti...',
 '["Memotong cabang pohon dewasa", "Memberi pupuk kimia", "Memindahkan tambak", "Mengganti bibit yang mati dengan bibit baru"]'::jsonb, 9, true),
('22222222-2222-2222-2222-222222222210'::uuid, 'final', NULL,
 'Peran masyarakat pesisir yang paling tepat dalam pengelolaan mangrove adalah...',
 '["Terlibat aktif dalam penanaman, pemeliharaan, dan pemantauan", "Hanya menonton kegiatan", "Menebang mangrove untuk kayu bakar tanpa batas", "Menyerahkan sepenuhnya kepada pihak luar"]'::jsonb, 10, true)
ON CONFLICT (id) DO UPDATE SET
    question_text = EXCLUDED.question_text,
    options = EXCLUDED.options,
    order_index = EXCLUDED.order_index,
    is_active = EXCLUDED.is_active;

INSERT INTO public.quiz_answers (question_id, correct_option_index, explanation) VALUES
('22222222-2222-2222-2222-222222222206'::uuid, 1, 'Avicennia (api-api) memiliki pneumatofor yang mencuat dari lumpur seperti pensil.'),
('22222222-2222-2222-2222-222222222207'::uuid, 2, 'Tanpa asesmen, bibit sering ditanam di elevasi/genangan yang tidak sesuai sehingga mati.'),
('22222222-2222-2222-2222-222222222208'::uuid, 0, 'Mangrove termasuk ekosistem blue carbon dengan simpanan karbon per hektar yang sangat tinggi.'),
('22222222-2222-2222-2222-222222222209'::uuid, 3, 'Penyulaman adalah penanaman ulang untuk mengganti bibit yang mati setelah penyebabnya dipahami.'),
('22222222-2222-2222-2222-222222222210'::uuid, 0, 'Keberhasilan jangka panjang bergantung pada keterlibatan aktif masyarakat setempat.')
ON CONFLICT (question_id) DO UPDATE SET
    correct_option_index = EXCLUDED.correct_option_index,
    explanation = EXCLUDED.explanation;

-- ------------------------------------------------------------------------------
-- 4. PENGAYAAN MATERI (2 SUB-BAB TAMBAHAN PER MODUL)
-- ------------------------------------------------------------------------------
INSERT INTO public.learning_materials (id, module_id, title, content, takeaway, media_type, order_index, status) VALUES
-- Modul 1
('11111111-1111-1111-1111-111111111212'::uuid, 1,
 'Jenis-Jenis Mangrove di Pesisir Indonesia',
 'Indonesia memiliki keanekaragaman jenis mangrove yang tinggi. Beberapa jenis yang paling sering dijumpai:

• Rhizophora (bakau) – memiliki akar tunjang yang melengkung dari batang dan propagul panjang berbentuk tombak.
• Avicennia (api-api) – memiliki akar napas (pneumatofor) seperti pensil yang mencuat dari lumpur; daunnya dapat mengeluarkan garam.
• Sonneratia (pidada) – akar napas berbentuk kerucut, sering tumbuh di bagian paling depan yang berhadapan dengan laut.
• Bruguiera (tanjang) – memiliki akar lutut dan tumbuh di bagian yang lebih jarang tergenang.
• Nypa fruticans (nipah) – palem yang tumbuh di tepian sungai payau.',
 'Kenali jenis dari bentuk akar, daun, dan buahnya sebelum memilih bibit.',
 'text', 2, 'published'),
('11111111-1111-1111-1111-111111111213'::uuid, 1,
 'Zonasi dan Habitat Mangrove',
 'Mangrove tumbuh berzona mengikuti frekuensi genangan pasang surut dan jenis substrat:

• Zona depan (paling dekat laut): sering tergenang, substrat lumpur berpasir – umumnya Avicennia dan Sonneratia.
• Zona tengah: tergenang saat pasang normal, lumpur tebal – umumnya Rhizophora.
• Zona belakang (ke arah darat): jarang tergenang, salinitas lebih rendah – Bruguiera, Xylocarpus, dan nipah di tepi sungai.

Ekosistem mangrove terhubung dengan padang lamun dan terumbu karang; kerusakan satu ekosistem berdampak pada yang lain.',
 'Setiap jenis punya "rumahnya" sendiri. Zonasi menentukan jenis yang cocok ditanam.',
 'text', 3, 'published'),
-- Modul 2
('11111111-1111-1111-1111-111111111222'::uuid, 2,
 'Blue Carbon dan Ketahanan Iklim',
 'Mangrove menyerap karbon dioksida melalui fotosintesis dan menyimpannya di batang, akar, serta sedimen lumpur di bawahnya. Karena sedimennya jarang terurai, karbon dapat tersimpan selama ratusan tahun. Inilah yang disebut blue carbon.

Ketika mangrove ditebang atau dikonversi menjadi tambak, karbon yang tersimpan dilepaskan kembali ke atmosfer. Menjaga mangrove berarti menjaga "bank karbon" alami sekaligus meningkatkan ketahanan pesisir terhadap badai, abrasi, dan kenaikan muka air laut.',
 'Mangrove yang sehat menyimpan karbon dan melindungi desa dari dampak perubahan iklim.',
 'text', 2, 'published'),
('11111111-1111-1111-1111-111111111223'::uuid, 2,
 'Manfaat Sosial dan Ekonomi bagi Masyarakat',
 'Bagi masyarakat pesisir, mangrove adalah sumber penghidupan:

• Perikanan – kepiting bakau, udang, kerang, dan ikan bergantung pada mangrove sebagai daerah asuhan.
• Produk olahan – buah pidada dan nipah dapat diolah menjadi sirup, dodol, atau keripik; daun nipah untuk atap dan anyaman.
• Ekowisata – jalur tracking, wisata perahu, dan edukasi mangrove membuka lapangan kerja bagi Pokdarwis.
• Perlindungan permukiman – sabuk hijau mangrove mengurangi kerusakan saat gelombang tinggi.

Pemanfaatan harus lestari: ambil secukupnya dan jangan menebang pohon induk.',
 'Mangrove lestari = penghidupan berkelanjutan bagi generasi berikutnya.',
 'text', 3, 'published'),
-- Modul 3
('11111111-1111-1111-1111-111111111232'::uuid, 3,
 'Memilih Bibit dan Propagul Berkualitas',
 'Bibit dapat berasal dari propagul (buah yang sudah berkecambah di pohon) atau dari persemaian.

Ciri propagul yang baik:
• Matang, ditandai warna kulit lebih gelap dan mudah lepas dari pohon induk.
• Tidak berlubang, tidak busuk, dan bebas serangan hama.
• Berasal dari pohon induk sehat di lokasi yang kondisinya mirip lokasi tanam.

Bibit persemaian siap tanam umumnya berumur 3–6 bulan dengan 4–6 helai daun dan batang yang kokoh.',
 'Bibit yang sehat dan sesuai jenis lokasi adalah separuh dari keberhasilan.',
 'text', 2, 'published'),
('11111111-1111-1111-1111-111111111233'::uuid, 3,
 'Teknik, Jarak, dan Waktu Penanaman',
 'Langkah penanaman sederhana:
1. Tanam saat air surut agar lubang tanam mudah dikerjakan.
2. Buat lubang sedalam ±1/3 panjang propagul atau sedalam polybag.
3. Pasang ajir bambu di samping bibit dan ikat longgar agar bibit tidak roboh.
4. Gunakan jarak tanam yang umum dipakai, misalnya 1 × 1 m atau 2 × 2 m, disesuaikan dengan jenis dan kondisi lokasi.

Kesalahan umum: menanam di lokasi yang terlalu lama tergenang, menanam satu jenis untuk semua zona, menanam di musim gelombang tinggi, dan tidak menyiapkan pemeliharaan setelah tanam.',
 'Menanam itu mudah; menanam di tempat dan waktu yang tepat adalah kuncinya.',
 'text', 3, 'published'),
-- Modul 4
('11111111-1111-1111-1111-111111111242'::uuid, 4,
 'Faktor Lingkungan dan Gangguan pada Bibit',
 'Beberapa gangguan yang sering menyebabkan bibit mati:

• Arus dan gelombang kuat – bibit hanyut atau roboh; perkuat ajir atau pasang pemecah ombak sederhana.
• Genangan terlalu lama – bibit membusuk; evaluasi elevasi lokasi.
• Hama – kepiting memakan propagul muda, teritip menempel dan membebani batang.
• Sampah dan jaring – menutupi daun dan mematahkan batang.
• Hewan ternak dan aktivitas manusia – injakan dan penggembalaan.

Lakukan patroli rutin minimal sebulan sekali pada tahun pertama.',
 'Kenali gangguan sejak dini agar tindakan pemeliharaan tepat sasaran.',
 'text', 2, 'published'),
('11111111-1111-1111-1111-111111111243'::uuid, 4,
 'Penyulaman (Replanting)',
 'Penyulaman adalah mengganti bibit yang mati dengan bibit baru. Agar tidak mengulang kegagalan:

1. Hitung jumlah bibit mati dan catat lokasinya.
2. Identifikasi penyebab kematian (hama, genangan, arus, substrat).
3. Perbaiki penyebabnya terlebih dahulu – misalnya ganti jenis yang lebih sesuai atau perkuat ajir.
4. Lakukan penyulaman pada musim yang tenang dan saat surut.

Penyulaman umumnya dilakukan bila survival rate turun di bawah target kelompok (misalnya di bawah 70–80%).',
 'Jangan sekadar menanam ulang — perbaiki dulu penyebab bibit mati.',
 'text', 3, 'published'),
-- Modul 5
('11111111-1111-1111-1111-111111111252'::uuid, 5,
 'Menghitung Survival Rate',
 'Survival rate (SR) menunjukkan persentase bibit yang bertahan hidup:

SR = (jumlah bibit hidup ÷ jumlah bibit awal yang ditanam) × 100%

Contoh: kelompok menanam 500 bibit. Pada bulan ke-6 tersisa 400 bibit hidup.
SR = 400 ÷ 500 × 100% = 80%.

Gunakan plot pengamatan (misalnya 10 × 10 m) bila area tanam sangat luas, lalu hitung SR pada setiap plot dan ambil rata-ratanya.',
 'SR adalah indikator paling sederhana untuk menilai keberhasilan penanaman.',
 'text', 2, 'published'),
('11111111-1111-1111-1111-111111111253'::uuid, 5,
 'Dokumentasi, Pencatatan Lokasi, dan Pelaporan',
 'Monitoring yang baik terdokumentasi dengan rapi:

• Foto titik tetap – ambil foto dari titik dan arah yang sama setiap kali monitoring agar perubahan mudah dibandingkan.
• Koordinat lokasi – catat titik GPS setiap plot menggunakan aplikasi peta di ponsel.
• Lembar lapangan – tanggal, jumlah bibit hidup/mati, tinggi rata-rata, jumlah daun, kondisi substrat, dan biota yang dijumpai.
• Laporan – rangkum hasil dalam tabel sederhana dan sampaikan kepada kelompok, pemerintah desa, atau pendamping.',
 'Data yang tercatat rapi membuat keputusan kelompok lebih tepat dan dapat dipertanggungjawabkan.',
 'text', 3, 'published')
ON CONFLICT (id) DO UPDATE SET
    title = EXCLUDED.title,
    content = EXCLUDED.content,
    takeaway = EXCLUDED.takeaway,
    media_type = EXCLUDED.media_type,
    order_index = EXCLUDED.order_index,
    status = EXCLUDED.status,
    updated_at = timezone('utc'::text, now());
