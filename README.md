# RooveyLearn — Platform Edukasi Konservasi Mangrove

RooveyLearn adalah aplikasi mobile edukasi konservasi mangrove berbasis Flutter dengan backend Supabase (PostgreSQL, RLS, Auth, dan Database Functions).

---

## 1. Konfigurasi Lingkungan (`env.json`)

RooveyLearn menggunakan konfigurasi `--dart-define-from-file=env.json` untuk menghubungkan aplikasi ke backend Supabase secara aman. Kunci kredensial tidak pernah di-hardcode ke dalam kode sumber.

### Langkah Pengaturan:
1. Salin template `env.example.json` menjadi `env.json`:
   ```bash
   cp env.example.json env.json
   ```
2. Isi nilai kredensial proyek Supabase Anda pada `env.json`:
   ```json
   {
     "SUPABASE_URL": "https://<project-ref>.supabase.co",
     "SUPABASE_ANON_KEY": "<your-anon-key>"
   }
   ```
   > **PERINGATAN KEAMANAN:**
   > - Gunakan hanya **anon key** (public/publishable key).
   > - **DILARANG KERAS** menggunakan `service_role` key pada aplikasi klien.
   > - File `env.json` sudah tercatat di `.gitignore` dan tidak boleh di-commit ke repositori Git.

---

## 2. Cara Menjalankan Aplikasi

Pastikan dependency telah terinstal:
```bash
flutter pub get
```

### Menjalankan di Emulator / Perangkat Nyata:
```bash
flutter run --dart-define-from-file=env.json
```

### Menjalankan Analisis & Unit/Widget Test:
```bash
flutter analyze
flutter test
```

---

## 3. Aturan Akses & Integrasi Backend (Sprint 2b)

### A. Pengguna Terdaftar (Authenticated):
- **Autentikasi**: Registrasi dengan nama dan email. Trigger server `handle_new_user` otomatis mengisi tabel `profiles` dari metadata pendaftaran. Sesi dipulihkan otomatis saat aplikasi dibuka kembali.
- **Alur Belajar Bertahap**: Modul 1 terbuka sejak awal. Modul berikutnya (N > 1) hanya dapat diselesaikan jika modul sebelumnya (N - 1) telah berstatus `completed` di database (validasi server-side via RPC `complete_module`).
- **Kuis & Asesmen**: Soal diambil dari tabel `quiz_questions` tanpa kunci jawaban. Jawaban dikirim ke server via RPC `submit_quiz`. Skor, status kelulusan (>= 80%), dan pembahasan dikembalikan langsung dari respons server. Asesmen akhir dibatasi maksimal 3 kali percobaan per 24 jam.
- **Sertifikat Digital**: Diterbitkan lewat RPC `issue_certificate` jika seluruh 5 modul selesai dan nilai asesmen akhir minimal 80%. Nomor sertifikat unik berformat `ROOVEY-YYYYMMDD-XXXXXX`.
- **Simulasi Lapangan**: Hasil pengambilan keputusan dan simulasi dicatat ke tabel `simulation_attempts`.

### B. Mode Tamu (Guest Mode):
- **Diperbolehkan**: Menjelajahi ensiklopedia ekosistem pesisir, membaca seluruh isi 5 modul pembelajaran, dan mencoba simulasi interaktif tanpa pencatatan riwayat.
- **Dibatasi**: Tidak dapat mengikuti pre-test, kuis modul, asesmen akhir, menandai modul selesai, melihat progres tersimpan, atau menerbitkan sertifikat.
- **AuthGate**: Setiap aksi yang dibatasi akan memunculkan komponen `AuthGate` / modal "Masuk untuk menyimpan progres" yang mengarahkan tamu untuk masuk atau mendaftar akun.

---

## 4. Panduan & Checklist Pengujian Manual

Lakukan verifikasi manual berikut pada emulator atau perangkat fisik Android/iOS:

| No | Fitur / Skenario Uji | Prosedur Uji | Ekspektasi Hasil |
|---|---|---|---|
| 1 | **Registrasi Akun Baru** | Isi nama lengkap, email baru, dan kata sandi (min 6 kar). Tekan "Daftar Akun Baru". | Akun berhasil dibuat, sesi aktif, nama profil muncul di Beranda dan tabel `profiles` server. |
| 2 | **Login & Restore Sesi** | Masuk dengan email & password. Tutup aplikasi (kill app) lalu buka kembali. | Sesi langsung pulih tanpa perlu login ulang; progres termuat dari server. |
| 3 | **Mode Tamu (Jelajah)** | Di layar selamat datang, pilih "Jelajah tanpa akun". Buka tab Jelajah dan Belajar. | Muncul banner kuning "Mode Tamu". Tamu bisa membaca semua 5 modul secara bebas. |
| 4 | **AuthGate pada Mode Tamu** | Dalam mode tamu, coba tekan banner pre-test, tombol selesaikan modul, atau tab Progres. | Aksi diblokir dan muncul modal "Masuk untuk Menyimpan Progres" dengan tombol Masuk/Daftar. |
| 5 | **Pre-test Handling** | Login dengan akun baru, buka Pre-test. | Jika bank `pretest` belum diisi di DB, muncul tampilan ramah "Pre-test Belum Tersedia" tanpa crash/fallback. |
| 6 | **Penyelesaian Modul Berurutan** | Selesaikan Modul 1. Coba selesaikan Modul 3 langsung tanpa Modul 2. | Server menolak via kode `P0001`. Aplikasi menampilkan pesan ramah: "Alur belajar bertahap: Anda harus menyelesaikan modul sebelumnya terlebih dahulu." |
| 7 | **Asesmen Akhir (Kelulusan)** | Selesaikan kelima modul berurutan, lalu kerjakan kuis akhir. Jawab benar >= 80%. | Evaluasi server sukses: skor dihitung dari bank soal, muncul pembahasan per soal, status LULUS. |
| 8 | **Rate Limit Asesmen Akhir** | Kerjakan kuis akhir sebanyak 3 kali dalam 24 jam. Coba ikuti untuk kali ke-4. | Server menolak via kode `P0003`. Muncul pesan: "Batas percobaan tercapai. Anda hanya dapat mengikuti Asesmen Akhir maksimal 3 kali dalam 24 jam." |
| 9 | **Penerbitan Sertifikat** | Setelah lulus 5 modul dan kuis akhir >= 80%, buka tab Progres. | Sertifikat digital terbit dengan nomor unik `ROOVEY-YYYYMMDD-XXXXXX`, nama peserta, dan skor terbaik. |
| 10 | **Simulasi Lapangan** | Jalankan simulasi lapangan saat login vs tamu. | Pengguna login: tercatat di `simulation_attempts`. Tamu: tidak ada data tersimpan ke server. |
| 11 | **Koneksi Terputus / Mode Pesawat** | Aktifkan mode pesawat saat aplikasi berjalan, coba akses modul atau kirim kuis. | Muncul state error ramah: "Gagal terhubung ke server. Periksa koneksi internet Anda dan coba lagi" beserta tombol "Coba Lagi". |
