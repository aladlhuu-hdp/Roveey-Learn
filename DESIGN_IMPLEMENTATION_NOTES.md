# RooveyLearn — Catatan Implementasi Stitch

## Sistem visual
- Palet mengikuti panduan **Coastal Editorial**: tidal teal `#145B56`, deep estuary `#203A38`, shell white `#F7F6F0`, sea mist `#E7F0EC`, soft lime `#D5E66D`, slate `#697673`, dan outline `#DCE4DF`.
- Menggunakan font sistem Flutter; tidak ada font, gambar, API, atau dependency visual eksternal baru.
- Kartu aktivitas dan kontrol baru memakai border tipis, permukaan putih, metadata kecil, dan radius yang lebih terkendali.
- Navigasi utama tetap empat tab: Beranda, Jelajah, Belajar, Progres.

## Screenshot yang dipetakan
1. `interactive_learning_path`: inspirasi hierarki learning path, ringkasan progres, dan struktur navigasi.
2. `lesson_active_activity`: pola checkpoint pilihan ganda dan feedback jawaban.
3. `lesson_feedback_explanation`: penjelasan setelah menjawab serta tombol melanjutkan.
4. `lesson_completion_xp`: halaman penyelesaian modul, XP aktual, dan progres modul.
5. `tidal_planting_sequencing_activity`: daftar langkah yang dapat diurutkan ulang.
6. `sequence_feedback_correction`: diagnosis beberapa langkah yang salah posisi dan penjelasan koreksi.
7. `porewater_refractometer_reading`: instrumen refraktometer, kontrol kalibrasi, opsi nilai, dan konfirmasi.

## Aktivitas baru
- **Urutkan langkah penanaman:** drag-and-drop empat langkah. Jawaban diperiksa terhadap urutan yang didefinisikan di source code. Pengguna dapat mengulang dan membuka diagnostik setelah urutan benar.
- **Diagnostik urutan:** pengguna memilih dua langkah yang salah posisi. Feedback menandai langkah yang perlu dipindahkan dan menjelaskan alasannya.
- **Kalibrasi refraktometer:** slider mengubah offset pembacaan contoh, lalu pengguna memilih hasil observasi. Nilai awal 35 PSU, target koreksi 32 PSU, dan pilihan 24/32/38/45 PSU adalah asumsi simulasi edukatif, bukan data lapangan.
- Ketiga aktivitas tidak memberikan XP dan tidak menulis data progres baru, sesuai aturan yang diminta.

## Kompatibilitas progres
Key SharedPreferences yang dipertahankan tanpa perubahan:
- `progress_xp_v1`
- `progress_quiz_score_v1`
- `progress_completed_modules_v1`
- `progress_explored_topics_v1`

Perhitungan yang ada dipertahankan: modul +20 XP hanya pada penyelesaian pertama; simulasi +15 XP untuk jawaban benar dan +5 XP untuk salah; kuis menyimpan skor dalam persen dan menambah XP dengan `skor ~/ 10`; sertifikat memerlukan lima modul selesai dan nilai kuis minimal 80%.

## Batas verifikasi
Source telah diperiksa dan direvisi, tetapi lingkungan pengerjaan ini tidak memiliki Flutter/Dart SDK sehingga `flutter analyze`, build APK, dan uji pada perangkat Android belum dijalankan. Pengujian akhir tetap perlu dilakukan pada proyek lokal yang sudah memiliki folder `android/`.
