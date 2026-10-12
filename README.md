# RooveyLearn — Flutter app (revisi UI Stitch)

Paket ini berisi source Flutter yang telah direvisi berdasarkan tujuh referensi Google Stitch. Fitur inti dan empat key SharedPreferences dipertahankan; tiga aktivitas lapangan baru ditambahkan.

## Isi paket
- `lib/main.dart` — source aplikasi lengkap dalam satu file.
- `pubspec.yaml` — konfigurasi Flutter dan dependency yang sudah digunakan (`shared_preferences: ^2.5.3`); tidak ada dependency baru.
- `analysis_options.yaml` — aturan lint Flutter.
- `DESIGN_IMPLEMENTATION_NOTES.md` — pemetaan desain, asumsi aktivitas, dan catatan kompatibilitas.

## Cara menerapkan tanpa mengganti folder Android
Paket ini sengaja tidak membawa folder `android/`, karena folder tersebut harus tetap berasal dari proyek Flutter yang sudah berjalan di komputer pengguna.

1. Unduh dan ekstrak ZIP ini.
2. Buka folder proyek RooveyLearn yang sudah berjalan melalui Android Studio.
3. Salin folder `lib` dari paket ini untuk menggantikan `lib` lama, lalu salin `pubspec.yaml` dan `analysis_options.yaml` ke folder proyek yang sama. Jika sistem file menanyakan apakah ingin mengganti file, pilih penggantian untuk file-file tersebut saja.
4. Biarkan folder `android/`, konfigurasi lokal, dan file proyek lain tetap seperti semula.
5. Di Android Studio, lakukan **Pub get** melalui panel Flutter/Pubspec atau prompt sinkronisasi yang muncul. Setelah itu jalankan aplikasi seperti biasa dari tombol **Run**.

Jangan menghapus atau mengganti folder proyek yang sudah berjalan. Source ini memakai dependency `shared_preferences` yang sudah tercantum pada proyek sebelumnya.

## Perubahan
- Palet dan komponen diselaraskan dengan sistem visual Coastal Editorial dari Stitch.
- Halaman pembelajaran menampilkan tiga aktivitas interaktif baru.
- Penyelesaian modul kini menampilkan layar ringkasan dengan XP yang benar-benar diperoleh.
- Catatan progres diperbaiki agar menjelaskan penyimpanan lokal dengan akurat.
- Aturan XP, kelulusan kuis, sertifikat, dan key SharedPreferences tetap dipertahankan.

## Batas pengujian
Flutter/Dart SDK tidak tersedia pada lingkungan penyusunan paket ini. Karena itu, `flutter analyze`, build APK, dan uji perangkat belum dapat diklaim berhasil. Lihat `DESIGN_IMPLEMENTATION_NOTES.md` untuk asumsi teknis dan batas verifikasi.
