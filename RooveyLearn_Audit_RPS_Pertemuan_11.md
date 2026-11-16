# Dokumen Audit Integrasi Backend dan API RooveyLearn

## Acuan Evaluasi RPS Pertemuan ke-11

**Proyek:** RooveyLearn --- Aplikasi Pembelajaran Digital untuk Edukasi
dan Konservasi Mangrove\
**Platform aplikasi:** Flutter / Dart\
**Platform backend:** Supabase\
**Mata kuliah:** Pemrograman Perangkat Bergerak\
**Tujuan dokumen:** Menjadi acuan audit source code, pengujian
integrasi, pengumpulan evidence, dan persiapan presentasi RPS Pertemuan
ke-11.

------------------------------------------------------------------------

## 1. Tujuan dan Ruang Lingkup

Dokumen ini merangkum kebutuhan evaluasi integrasi backend RooveyLearn
berdasarkan informasi RPS Pertemuan ke-11 yang diberikan serta
penjelasan teknis mengenai penggunaan Supabase.

Fokus audit meliputi:

1.  Stabilitas integrasi REST API atau layanan Backend as a Service
    (BaaS).
2.  Kualitas penanganan proses asynchronous, loading, state, dan error.
3.  Keberhasilan penyimpanan data (*persistence*) dan pemanfaatan
    kemampuan perangkat mobile.
4.  Authentication dan keamanan dasar.
5.  Pengumpulan evidence integrasi dan pengujian.
6.  Kesiapan demonstrasi dan presentasi hasil implementasi.

**Batasan penting:** Dokumen ini adalah pedoman audit. Dokumen ini tidak
menyatakan bahwa seluruh aspek telah diterapkan atau lulus pengujian.
Status setiap butir harus ditentukan setelah source code, konfigurasi
Supabase, database, dan aplikasi aktual diperiksa.

## 2. Interpretasi API pada Proyek RooveyLearn

### 2.1 Pengertian API

API (*Application Programming Interface*) adalah antarmuka yang
memungkinkan dua sistem perangkat lunak berkomunikasi dan bertukar data.

Dalam RooveyLearn:

-   Flutter merupakan aplikasi client yang digunakan pengguna.
-   Supabase merupakan platform backend.
-   API merupakan mekanisme yang digunakan Flutter untuk meminta atau
    mengirim data ke layanan backend.
-   PostgreSQL merupakan basis data yang digunakan Supabase untuk
    menyimpan data terstruktur.

API bukan nama platform backend. Supabase adalah platform backend yang
menyediakan beberapa layanan, termasuk REST API dan autentikasi.

### 2.2 Alur komunikasi data

Alur umum komunikasi aplikasi adalah:

1.  Pengguna melakukan tindakan di aplikasi, misalnya login, membuka
    modul, atau menyelesaikan kuis.
2.  Aplikasi Flutter menjalankan logika yang sesuai.
3.  Flutter mengirim permintaan ke Supabase melalui SDK atau HTTP API.
4.  Supabase memproses autentikasi atau operasi data.
5.  Supabase mengembalikan respons.
6.  Flutter memproses respons dan memperbarui tampilan.

Contoh alur penyimpanan hasil kuis:

1.  Pengguna menyelesaikan kuis.
2.  Aplikasi menghitung hasil sesuai aturan kuis.
3.  Aplikasi mengirim data hasil evaluasi ke Supabase.
4.  Supabase memvalidasi izin dan menyimpan data ke PostgreSQL.
5.  Aplikasi menerima respons.
6.  Halaman progres mengambil dan menampilkan data yang tersimpan.

### 2.3 Supabase dan REST API

Supabase menyediakan REST API berdasarkan skema PostgreSQL melalui
PostgREST. Aplikasi dapat mengakses data melalui operasi HTTP.

Contoh bentuk endpoint:

``` text
https://PROJECT_ID.supabase.co/rest/v1/learning_modules
```

Contoh metode HTTP:

  -----------------------------------------------------------------------
  Metode                  Fungsi                  Contoh penggunaan
                                                  RooveyLearn
  ----------------------- ----------------------- -----------------------
  GET                     Mengambil data          Mengambil daftar modul

  POST                    Menambahkan data        Menyimpan hasil kuis

  PATCH                   Memperbarui data        Memperbarui progres
                                                  modul

  DELETE                  Menghapus data          Menghapus data jika
                                                  diizinkan oleh
                                                  kebijakan akses
  -----------------------------------------------------------------------

Aplikasi tidak harus membuat server REST API sendiri. `supabase_flutter`
dapat digunakan sebagai client SDK untuk mengakses layanan Supabase.

## 3. Komponen Backend Supabase

  -----------------------------------------------------------------------
  Layanan                 Fungsi umum             Kemungkinan penerapan
                                                  di RooveyLearn
  ----------------------- ----------------------- -----------------------
  Supabase Auth           Autentikasi dan         Registrasi, login,
                          pengelolaan sesi        logout
                          pengguna                

  Supabase Database       Basis data PostgreSQL   Profil, modul, materi,
                                                  progres, hasil evaluasi

  Supabase REST API       Akses data melalui API  Operasi select, insert,
                                                  update, delete

  Supabase Storage        Penyimpanan berkas      Gambar, video, atau
                                                  aset pembelajaran jika
                                                  digunakan

  Supabase Realtime       Menerima perubahan data Sinkronisasi langsung
                          secara real-time        jika memang dibutuhkan
  -----------------------------------------------------------------------

Jangan menyatakan suatu layanan telah digunakan hanya karena layanan
tersebut tersedia di Supabase. Audit harus memastikan apakah layanan itu
benar-benar dipakai oleh source code dan konfigurasi proyek.

## 4. Area Audit Berdasarkan RPS Pertemuan ke-11

### 4.1 Stabilitas Integrasi REST API / Firebase / BaaS

**Tujuan audit:** Memastikan aplikasi dapat berkomunikasi dengan backend
secara konsisten dan menangani hasil permintaan.

Periksa hal-hal berikut:

-   [ ] Project URL Supabase dikonfigurasi dengan benar.
-   [ ] Client Supabase diinisialisasi sebelum digunakan.
-   [ ] Aplikasi dapat melakukan autentikasi.
-   [ ] Aplikasi dapat mengambil data dari tabel yang diperlukan.
-   [ ] Aplikasi dapat menyimpan data ke tabel yang diperlukan.
-   [ ] Aplikasi dapat memperbarui data jika fitur membutuhkannya.
-   [ ] Data yang tersimpan dapat diambil kembali.
-   [ ] Respons sukses diproses dengan benar.
-   [ ] Kegagalan jaringan atau backend tidak menyebabkan aplikasi
    berhenti secara tidak terkendali.
-   [ ] Permintaan yang sama tidak menyebabkan duplikasi data yang tidak
    diinginkan.

**Bukti yang disarankan:**

-   Screenshot konfigurasi project Supabase tanpa menampilkan secret.
-   Source code inisialisasi Supabase.
-   Source code operasi select/insert/update yang benar-benar digunakan.
-   Screenshot aplikasi yang menampilkan data hasil backend.
-   Screenshot tabel Supabase yang berisi data hasil pengujian.
-   Rekaman atau dokumentasi alur pengujian dari aplikasi ke backend.

### 4.2 Asynchronous, State, Loading, dan Error Handling

Komunikasi dengan backend bersifat asynchronous. Aplikasi perlu menunggu
respons tanpa menganggap data selalu tersedia seketika.

Empat kondisi antarmuka yang perlu diperiksa:

  -----------------------------------------------------------------------
  Kondisi                 Makna                   Perilaku UI yang
                                                  diharapkan
  ----------------------- ----------------------- -----------------------
  Loading                 Permintaan sedang       Menampilkan indikator
                          berlangsung             pemuatan

  Success                 Permintaan berhasil dan Menampilkan data
                          data tersedia           

  Empty                   Permintaan berhasil     Menampilkan empty state
                          tetapi hasil kosong     

  Error                   Permintaan gagal        Menampilkan pesan yang
                                                  sesuai dan opsi mencoba
                                                  kembali jika relevan
  -----------------------------------------------------------------------

Contoh pola implementasi:

``` dart
try {
  setState(() {
    isLoading = true;
    errorMessage = null;
  });

  final data = await supabase
      .from('learning_modules')
      .select();

  if (!mounted) return;

  setState(() {
    modules = data;
    isLoading = false;
  });
} catch (e) {
  if (!mounted) return;

  setState(() {
    isLoading = false;
    errorMessage = 'Gagal memuat data.';
  });
}
```

Kode tersebut merupakan contoh pola, bukan bukti bahwa implementasi
proyek sudah sesuai. Sesuaikan nama tabel, model data, dan pengelolaan
state dengan source code aktual.

**Checklist audit:**

-   [ ] Operasi jaringan menggunakan mekanisme asynchronous yang sesuai.
-   [ ] UI menampilkan loading ketika permintaan berlangsung.
-   [ ] State diperbarui setelah respons diterima.
-   [ ] Empty state tersedia ketika data kosong.
-   [ ] Error ditangani dan tidak hanya diabaikan.
-   [ ] Widget tidak memanggil `setState` setelah sudah tidak aktif
    (`mounted`).
-   [ ] Indikator loading dihentikan pada kondisi sukses maupun gagal.
-   [ ] Pengguna mendapat informasi yang dapat dipahami, bukan hanya
    pesan teknis mentah.

### 4.3 Persistence dan Mobile Capability

Persistence perlu dibedakan menjadi penyimpanan backend dan penyimpanan
lokal.

-   **Backend persistence:** data disimpan di Supabase dan dapat diakses
    kembali melalui jaringan dengan otorisasi yang sesuai.
-   **Local persistence:** data disimpan pada perangkat pengguna.
-   **Session persistence:** sesi autentikasi dipertahankan sesuai
    mekanisme penyimpanan sesi yang digunakan SDK.
-   **Mobile capability:** aplikasi menangani kondisi perangkat mobile,
    seperti koneksi yang berubah-ubah, lifecycle aplikasi, dan
    perpindahan antarhalaman.

Contoh pemetaan penyimpanan yang dapat digunakan sebagai rancangan:

  -----------------------------------------------------------------------
  Jenis data                          Lokasi penyimpanan yang
                                      direncanakan
  ----------------------------------- -----------------------------------
  Identitas autentikasi               Supabase Auth

  Informasi profil                    Supabase Database

  Materi pembelajaran                 Supabase Database atau aset
                                      aplikasi, sesuai keputusan
                                      arsitektur

  Hasil kuis                          Supabase Database

  Progres modul                       Supabase Database

  Sesi autentikasi                    Mekanisme sesi yang dikelola
                                      Supabase SDK

  State sementara antarmuka           State aplikasi Flutter
  -----------------------------------------------------------------------

Pemetaan tersebut harus dicocokkan dengan implementasi aktual. Jika
aplikasi juga menggunakan penyimpanan lokal, jelaskan data apa yang
disimpan, alasannya, dan bagaimana sinkronisasinya dilakukan.

**Checklist audit:**

-   [ ] Data penting tetap tersedia setelah aplikasi ditutup dan dibuka
    kembali.
-   [ ] Data pengguna dikaitkan dengan identitas akun yang benar.
-   [ ] Aplikasi menangani kondisi tanpa koneksi.
-   [ ] Aplikasi tidak mengklaim mendukung offline mode jika belum ada
    mekanisme offline.
-   [ ] Perilaku saat sesi berakhir atau token kedaluwarsa ditangani.
-   [ ] Lifecycle aplikasi tidak menyebabkan permintaan atau pembaruan
    state yang bermasalah.

### 4.4 Authentication dan Security Dasar

#### A. Authentication

Supabase Auth menangani proses registrasi, login, logout, dan
pengelolaan sesi pengguna.

Contoh login:

``` dart
final response = await supabase.auth.signInWithPassword(
  email: email,
  password: password,
);
```

Setelah autentikasi berhasil, Supabase menyediakan identitas pengguna
dan sesi autentikasi. Aplikasi dapat menggunakan identitas tersebut
untuk mengakses data yang diizinkan.

#### B. Token

Supabase Auth menggunakan access token berbentuk JWT untuk
merepresentasikan sesi dan identitas pengguna pada permintaan yang
memerlukan autentikasi.

Audit harus memeriksa bahwa aplikasi tidak membuat asumsi bahwa pengguna
sudah terautentikasi hanya berdasarkan tampilan UI. Status sesi harus
diperiksa melalui mekanisme autentikasi.

#### C. API Key dan Secret

Aplikasi client dapat menggunakan publishable key Supabase sesuai
dokumentasi. Publishable key bukan pengganti autentikasi dan bukan
mekanisme pembatasan akses data.

Jangan memasukkan `service_role` key atau secret key ke dalam aplikasi
Flutter. Aplikasi mobile dapat diperiksa dan diekstrak oleh pihak lain.

#### D. HTTPS

Komunikasi dengan layanan Supabase harus menggunakan HTTPS agar data
terlindungi selama transmisi.

#### E. Row Level Security (RLS)

RLS adalah mekanisme keamanan PostgreSQL yang membatasi baris data yang
dapat diakses berdasarkan kebijakan yang ditentukan.

Contoh prinsip kebijakan:

-   Pengguna hanya dapat membaca progres miliknya.
-   Pengguna hanya dapat membuat atau memperbarui data yang memang
    menjadi haknya.
-   Pengguna tidak dapat membaca atau mengubah hasil evaluasi pengguna
    lain.
-   Data publik, seperti materi pembelajaran, hanya dapat diakses sesuai
    kebijakan yang ditentukan.

**Checklist audit keamanan:**

-   [ ] Registrasi dan login menggunakan Supabase Auth jika memang
    menjadi rancangan sistem.
-   [ ] Logout mengakhiri sesi dengan benar.
-   [ ] Status sesi diperiksa sebelum mengakses fitur yang memerlukan
    login.
-   [ ] Tidak ada service role key atau secret key di source code
    aplikasi.
-   [ ] Komunikasi menggunakan HTTPS.
-   [ ] RLS diaktifkan pada tabel yang terekspos dan memuat data yang
    perlu dibatasi.
-   [ ] Policy diuji menggunakan lebih dari satu akun pengguna.
-   [ ] Pengguna tidak dapat mengakses data milik akun lain.
-   [ ] Validasi penting tidak hanya mengandalkan kontrol antarmuka.

**Peringatan:** Jangan mengklaim RLS sudah diterapkan sebelum memeriksa
konfigurasi dan menguji policy di Supabase.

## 5. Contoh Pola Implementasi Flutter

Contoh berikut merupakan referensi pola kode. Nama tabel, kolom, dan
aturan harus disesuaikan dengan database RooveyLearn yang sebenarnya.

### 5.1 Inisialisasi Supabase

``` dart
await Supabase.initialize(
  url: 'https://PROJECT_ID.supabase.co',
  publishableKey: 'YOUR_PUBLISHABLE_KEY',
);

final supabase = Supabase.instance.client;
```

Hal yang perlu diperiksa:

-   Inisialisasi dilakukan sebelum client digunakan.
-   URL mengarah ke project yang benar.
-   Key yang digunakan memang boleh berada pada aplikasi client.
-   Secret administratif tidak dimasukkan ke aplikasi.

### 5.2 Login

``` dart
final response = await supabase.auth.signInWithPassword(
  email: email,
  password: password,
);
```

Periksa respons, status autentikasi, dan penanganan error. Jangan
menampilkan password atau token ke log.

### 5.3 Mengambil data modul

``` dart
final modules = await supabase
    .from('learning_modules')
    .select()
    .order('order_number');
```

Data hasil query harus dipetakan ke model atau struktur data yang
digunakan aplikasi. Pastikan urutan dan field sesuai skema database
aktual.

### 5.4 Menyimpan hasil evaluasi

``` dart
await supabase
    .from('assessment_results')
    .insert({
      'user_id': userId,
      'score': 90,
      'assessment_type': 'module_quiz',
      'passed': true,
    });
```

Contoh ini mengasumsikan tabel dan kolom tersebut tersedia. Pastikan
`userId` berasal dari identitas pengguna yang terautentikasi dan policy
database mengizinkan operasi tersebut.

### 5.5 Mengambil kembali progres

``` dart
final progress = await supabase
    .from('user_module_progress')
    .select()
    .eq('user_id', userId);
```

Pastikan query dibatasi sesuai kebutuhan dan RLS tetap diterapkan pada
database. Filter di sisi aplikasi bukan pengganti keamanan RLS.

## 6. Rancangan Data yang Perlu Diaudit

Tabel berikut adalah rancangan konseptual yang dapat dibandingkan dengan
skema aktual Supabase. Tabel ini bukan klaim bahwa semua tabel telah
dibuat.

  Nama tabel yang diusulkan   Kegunaan
  --------------------------- ---------------------------------------------
  `profiles`                  Informasi tambahan pengguna
  `learning_modules`          Daftar dan metadata modul
  `learning_materials`        Materi di dalam modul
  `quiz_questions`            Pertanyaan dan pilihan kuis
  `assessment_results`        Hasil kuis dan asesmen
  `user_module_progress`      Status penyelesaian modul
  `simulation_attempts`       Hasil aktivitas simulasi jika perlu dicatat
  `certificates`              Informasi sertifikat digital

Audit skema database perlu memeriksa:

-   Primary key setiap tabel.
-   Foreign key dan relasi antartabel.
-   Tipe data setiap kolom.
-   Kolom yang wajib diisi.
-   Nilai default.
-   Constraint dan validasi.
-   Indeks untuk query yang sering digunakan.
-   RLS dan policy.
-   Konsistensi identitas pengguna.
-   Potensi duplikasi data.

Kunci jawaban kuis dan data sensitif lainnya perlu dilindungi agar tidak
dapat diakses secara bebas oleh client sebelum waktunya.

## 7. Skenario Pengujian Integrasi

Gunakan skenario berikut untuk menguji integrasi aplikasi dengan
Supabase.

  -----------------------------------------------------------------------
  ID                Skenario          Langkah pengujian Hasil yang
                                                        diharapkan
  ----------------- ----------------- ----------------- -----------------
  API-01            Inisialisasi      Jalankan aplikasi Client dapat
                    backend           dan inisialisasi  digunakan tanpa
                                      Supabase          error konfigurasi

  AUTH-01           Registrasi        Daftarkan akun    Akun diproses
                                      pengujian         oleh Supabase
                                                        Auth

  AUTH-02           Login valid       Login dengan      Pengguna
                                      kredensial benar  memperoleh sesi

  AUTH-03           Login tidak valid Login dengan      Aplikasi
                                      kredensial salah  menampilkan error
                                                        yang sesuai

  AUTH-04           Logout            Logout dari akun  Sesi berakhir dan
                                                        halaman
                                                        terlindungi tidak
                                                        dapat diakses

  DB-01             Mengambil modul   Buka halaman      Data modul
                                      Belajar           ditampilkan dari
                                                        sumber yang benar

  DB-02             Data kosong       Uji tabel atau    Empty state
                                      query tanpa hasil ditampilkan

  DB-03             Menyimpan hasil   Selesaikan kuis   Hasil tersimpan
                    kuis                                sesuai skema

  DB-04             Membaca progres   Buka halaman      Data progres yang
                                      Progres           tersimpan
                                                        ditampilkan

  DB-05             Persistensi       Tutup dan buka    Data backend
                                      kembali aplikasi, dapat diambil
                                      lalu login        kembali

  ASYNC-01          Loading           Uji permintaan    Indikator loading
                                      yang membutuhkan  terlihat
                                      waktu             

  ASYNC-02          Error jaringan    Putuskan koneksi  Error ditangani
                                      saat permintaan   tanpa crash

  SEC-01            Isolasi data      Login dengan dua  Setiap akun hanya
                                      akun berbeda      dapat mengakses
                                                        data yang
                                                        diizinkan

  SEC-02            RLS               Uji akses         Database menolak
                                      langsung terhadap akses yang tidak
                                      data yang bukan   diizinkan
                                      milik akun        

  MOBILE-01         Lifecycle         Pindah halaman    Tidak terjadi
                                      atau tutup        pembaruan state
                                      aplikasi saat     yang tidak valid
                                      request berjalan  
  -----------------------------------------------------------------------

Catat hasil setiap pengujian dengan status **Pass**, **Fail**, atau
**Not Tested**. Sertakan tanggal, perangkat, versi aplikasi, akun uji
(tanpa password), dan bukti pendukung.

## 8. Evidence untuk Presentasi RPS Pertemuan ke-11

Evidence berikut disarankan untuk menunjukkan hasil integrasi.

  -----------------------------------------------------------------------
  No.                     Evidence                Bukti yang dikumpulkan
  ----------------------- ----------------------- -----------------------
  1                       Konfigurasi Supabase    Screenshot project dan
                                                  inisialisasi client
                                                  tanpa secret

  2                       Authentication          Demo registrasi, login,
                                                  dan logout

  3                       REST API                Potongan kode operasi
                                                  API dan respons

  4                       Database                Screenshot tabel dengan
                                                  data pengujian

  5                       Insert dan Select       Bukti menyimpan dan
                                                  mengambil data

  6                       Loading dan Error       Screenshot state
                                                  loading dan penanganan
                                                  error

  7                       Security                Screenshot RLS dan
                                                  policy yang telah diuji

  8                       Pengujian integrasi     Tabel skenario dan
                                                  hasil aktual

  9                       Evidence individu       Commit, source code,
                                                  dokumentasi, atau
                                                  bagian pekerjaan
                                                  masing-masing
  -----------------------------------------------------------------------

Jangan menampilkan password, access token, secret key, atau informasi
sensitif lain pada screenshot dan presentasi.

## 9. Rekomendasi Struktur Presentasi

Susunan slide yang disarankan:

  -----------------------------------------------------------------------
  Slide                   Topik                   Materi
  ----------------------- ----------------------- -----------------------
  1                       Identitas proyek        RooveyLearn, anggota,
                                                  dan tujuan aplikasi

  2                       Arsitektur sistem       Flutter, Supabase,
                                                  PostgreSQL, dan aliran
                                                  data

  3                       Backend Supabase        Auth, Database, REST
                                                  API, Storage jika
                                                  digunakan

  4                       Integrasi API           Operasi GET, POST,
                                                  PATCH, serta contoh
                                                  kode

  5                       Authentication dan      Session, JWT, HTTPS,
                          Security                publishable key, RLS

  6                       Asynchronous dan State  Loading, success, empty
                                                  state, error

  7                       Demonstrasi aplikasi    Login, mengambil modul,
                                                  menyimpan hasil,
                                                  melihat progres

  8                       Pengujian integrasi     Skenario, hasil, dan
                                                  evidence

  9                       Evaluasi                Kelebihan,
                                                  keterbatasan, dan
                                                  perbaikan

  10                      Kesimpulan              Hasil integrasi dan
                                                  status pencapaian
  -----------------------------------------------------------------------

Prioritaskan demonstrasi aliran data aktual dibandingkan hanya
menjelaskan teori.

## 10. Pertanyaan Dosen yang Perlu Dipersiapkan

### 10.1 Mengapa menggunakan Supabase daripada membuat backend sendiri?

Supabase dipilih karena menyediakan layanan backend terintegrasi,
meliputi PostgreSQL, autentikasi, REST API, dan penyimpanan berkas.
Dengan demikian, tim dapat berfokus pada pengembangan fitur aplikasi
tanpa harus membangun seluruh infrastruktur backend dari awal.

### 10.2 Apakah Supabase termasuk REST API?

Supabase merupakan platform Backend as a Service. Salah satu layanan
yang disediakan adalah REST API yang dibuat berdasarkan skema PostgreSQL
melalui PostgREST. Dengan demikian, Supabase adalah platform backend,
sedangkan REST API merupakan salah satu mekanisme komunikasi aplikasi
dengan backend.

### 10.3 Apakah aplikasi menggunakan API meskipun tidak membuat API sendiri?

Ya. Aplikasi tetap menggunakan API karena pengambilan dan pengiriman
data ke Supabase berlangsung melalui komunikasi API. Tim menggunakan
Supabase Flutter SDK sebagai client untuk mengakses layanan yang
disediakan Supabase sehingga tidak perlu membangun REST API server
secara manual.

### 10.4 Bagaimana jika koneksi internet terputus?

Permintaan ke backend tidak dapat diselesaikan ketika koneksi terputus.
Aplikasi perlu menangani kondisi tersebut melalui indikator loading,
pesan kesalahan, dan mekanisme percobaan ulang jika sesuai. Dukungan
offline dan sinkronisasi data hanya boleh diklaim jika benar-benar telah
diimplementasikan.

### 10.5 Bagaimana memastikan data pengguna tidak dapat diakses pengguna lain?

Autentikasi Supabase digunakan untuk mengidentifikasi pengguna,
sedangkan Row Level Security pada PostgreSQL dapat membatasi akses data
berdasarkan identitas tersebut. Klaim ini harus didukung konfigurasi dan
hasil pengujian policy yang nyata.

### 10.6 Apa perbedaan Supabase Auth dan tabel profiles?

Supabase Auth mengelola identitas dan proses autentikasi pengguna. Tabel
`profiles` menyimpan informasi tambahan, misalnya nama atau informasi
profil lain. Keduanya dapat dihubungkan melalui user ID.

### 10.7 Bagaimana menguji bahwa integrasi backend berhasil?

Pengujian dilakukan melalui autentikasi, pengambilan data modul,
penyimpanan hasil evaluasi, dan pengambilan kembali progres. Hasil yang
ditampilkan aplikasi dibandingkan dengan data yang tersimpan pada
Supabase.

### 10.8 Apa yang terjadi jika API mengembalikan error?

Aplikasi menangani kegagalan melalui mekanisme error handling. Status
loading dihentikan dan pengguna memperoleh informasi yang sesuai.
Aplikasi harus tetap stabil dan tidak berhenti secara tidak terkendali.

### 10.9 Apakah data kuis dan progres disimpan di perangkat atau backend?

Jawaban harus mengikuti implementasi aktual. Jika data disimpan di
Supabase, jelaskan bahwa data dikaitkan dengan akun pengguna dan dapat
diambil kembali melalui jaringan. Jika sebagian data disimpan lokal,
jelaskan peran penyimpanan lokal dan mekanisme sinkronisasinya.

## 11. Pembagian Fokus Presentasi Tim

Usulan pembagian untuk enam anggota:

  -----------------------------------------------------------------------
  Anggota                             Fokus presentasi
  ----------------------------------- -----------------------------------
  Al Adlhu Sodri Niwrad               Gambaran proyek, arsitektur sistem,
                                      koordinasi integrasi

  Rahmat Ramadhan                     Supabase, PostgreSQL, dan desain
                                      database

  Saimon                              REST API dan komunikasi Flutter
                                      dengan Supabase

  Bima Hulistiawan                    Authentication, session, token, dan
                                      security

  Amelya Nur Salsabila                UI/UX, asynchronous state, loading,
                                      dan error handling

  Olan Maulana                        Pengujian integrasi, evidence, dan
                                      evaluasi sistem
  -----------------------------------------------------------------------

Pembagian ini merupakan usulan. Sesuaikan dengan pekerjaan teknis yang
benar-benar dilakukan setiap anggota. Setiap anggota sebaiknya dapat
menjelaskan kontribusi dan evidence pekerjaannya sendiri.

## 12. Matriks Audit Source Code

Gunakan matriks ini ketika melakukan pemeriksaan proyek.

  ------------------------------------------------------------------------------------------
  No.         Area             File atau            Kriteria audit   Status      Catatan /
                               konfigurasi yang                                  Evidence
                               diperiksa                                         
  ----------- ---------------- -------------------- ---------------- ----------- -----------
  1           Dependency       `pubspec.yaml`       SDK dan          Belum       
                                                    dependency       diperiksa   
                                                    Supabase sesuai              
                                                    kebutuhan                    

  2           Inisialisasi     `main.dart` atau     Supabase         Belum       
                               file konfigurasi     diinisialisasi   diperiksa   
                                                    sebelum                      
                                                    digunakan                    

  3           Konfigurasi      File                 URL dan          Belum       
                               environment/config   publishable key  diperiksa   
                                                    dikelola dengan              
                                                    benar                        

  4           Authentication   Auth service /       Login,           Belum       
                               halaman login        registrasi,      diperiksa   
                                                    logout, dan sesi             

  5           API read         Repository / service Query select     Belum       
                                                    berjalan dan     diperiksa   
                                                    hasil diproses               

  6           API write        Repository / service Insert/update    Belum       
                                                    berjalan sesuai  diperiksa   
                                                    skema                        

  7           Model            Direktori models     Mapping respons  Belum       
                                                    dan tipe data    diperiksa   
                                                    konsisten                    

  8           State            Page / controller /  State loading,   Belum       
                               provider yang        success, empty,  diperiksa   
                               digunakan            error                        

  9           Lifecycle        Widget yang          Aman terhadap    Belum       
                               menjalankan request  widget yang      diperiksa   
                                                    sudah dispose                

  10          Database         Supabase Dashboard   Tabel, relasi,   Belum       
                                                    constraint, dan  diperiksa   
                                                    indeks                       

  11          Security         Supabase Dashboard   RLS dan policy   Belum       
                                                    sesuai kebutuhan diperiksa   

  12          Persistence      Alur simpan dan      Data dapat       Belum       
                               ambil data           diambil kembali  diperiksa   

  13          Mobile           Aplikasi pada        Penanganan       Belum       
                               perangkat            koneksi dan      diperiksa   
                                                    lifecycle                    

  14          Error            Service dan UI       Error tidak      Belum       
                                                    diabaikan dan    diperiksa   
                                                    pesan informatif             

  15          Testing          Dokumen pengujian    Skenario diuji   Belum       
                                                    dan hasil        diperiksa   
                                                    dicatat                      
  ------------------------------------------------------------------------------------------

Status yang disarankan:

-   **Pass:** sudah diperiksa dan memenuhi kriteria.
-   **Fail:** sudah diperiksa tetapi belum memenuhi kriteria.
-   **Partial:** sebagian sudah diterapkan.
-   **Not Tested:** belum diuji.
-   **Not Applicable:** tidak relevan dengan arsitektur yang digunakan,
    disertai alasan.

## 13. Urutan Audit yang Direkomendasikan

Agar audit efisien, lakukan pemeriksaan dengan urutan berikut:

1.  Periksa dependency dan konfigurasi Supabase.
2.  Temukan titik inisialisasi Supabase.
3.  Telusuri seluruh pemanggilan `Supabase.instance.client` atau client
    yang digunakan.
4.  Identifikasi operasi autentikasi.
5.  Identifikasi query select, insert, update, dan delete.
6.  Cocokkan nama tabel dan kolom di source code dengan skema Supabase.
7.  Periksa pemetaan respons ke model aplikasi.
8.  Periksa loading, error, empty state, dan lifecycle.
9.  Periksa RLS dan policy di Supabase Dashboard.
10. Uji alur data menggunakan akun pengujian.
11. Catat hasil pengujian dan kumpulkan evidence.
12. Perbarui matriks audit sebelum presentasi.

## 14. Hal yang Tidak Boleh Diklaim Tanpa Bukti

Untuk menjaga akurasi presentasi, hindari klaim berikut sebelum
diverifikasi:

-   Mengatakan semua data sudah tersimpan di Supabase jika masih ada
    data yang hanya berada di state lokal.
-   Mengatakan aplikasi mendukung offline mode jika belum ada
    penyimpanan dan sinkronisasi offline.
-   Mengatakan keamanan data sudah diterapkan jika RLS belum
    dikonfigurasi dan diuji.
-   Mengatakan REST API stabil tanpa pengujian sukses, error, dan
    konektivitas.
-   Mengatakan semua fitur sudah terintegrasi jika masih menggunakan
    data dummy atau statis.
-   Mengatakan sertifikat atau progres tersimpan permanen jika belum
    diuji setelah aplikasi ditutup dan dibuka kembali.
-   Mengatakan seluruh operasi memakai REST API secara manual jika
    sebenarnya menggunakan SDK. Penggunaan SDK tetap mengakses layanan
    API, tetapi cara implementasinya berbeda.

## 15. Kesimpulan

Evaluasi RPS Pertemuan ke-11 pada proyek RooveyLearn perlu membuktikan
bahwa aplikasi Flutter terintegrasi dengan backend Supabase secara
benar, stabil, dan aman. Pembuktian tidak cukup melalui penjelasan bahwa
kelompok menggunakan Supabase. Tim perlu menunjukkan proses autentikasi,
pengambilan dan penyimpanan data, penanganan asynchronous, persistence,
serta pengamanan akses.

Supabase berperan sebagai platform backend yang menyediakan layanan
autentikasi, PostgreSQL, dan REST API. Flutter berperan sebagai aplikasi
client yang berkomunikasi dengan layanan tersebut melalui Supabase
Flutter SDK.

Hasil audit akhir harus didasarkan pada source code, konfigurasi
backend, dan pengujian aktual. Setiap aspek perlu diberi status dan
evidence sehingga tim dapat menjelaskan dengan jujur bagian yang sudah
selesai, sebagian selesai, belum diuji, atau masih menjadi rencana
pengembangan.

------------------------------------------------------------------------

## 16. Referensi Teknis

1.  Flutter. *Architecting Flutter Apps*.
    https://docs.flutter.dev/app-architecture
2.  Supabase. *Use Supabase with Flutter*.
    https://supabase.com/docs/guides/getting-started/quickstarts/flutter
3.  Supabase. *Build a User Management App with Flutter*.
    https://supabase.com/docs/guides/getting-started/tutorials/with-flutter
4.  Supabase. *Data REST API*. https://supabase.com/docs/guides/api
5.  Supabase. *Database Overview*.
    https://supabase.com/docs/guides/database/overview
6.  Supabase. *Row Level Security*.
    https://supabase.com/docs/guides/database/postgres/row-level-security
7.  Supabase. *Auth Architecture*. https://supabase.com/docs/guides/auth
8.  Supabase Flutter package. https://pub.dev/packages/supabase_flutter

**Catatan sumber:** Rincian kriteria RPS dalam dokumen ini diambil dari
gambar Pertemuan ke-11 yang diberikan. Penjelasan implementasi Supabase
dan praktik audit merupakan uraian teknis pendukung. Skema tabel, contoh
kode, dan checklist merupakan acuan yang harus diverifikasi terhadap
proyek RooveyLearn aktual.

## 13. Hasil Audit Source Code Aktual (commit `47805dd` + penyesuaian RPS 11)

Pemeriksaan statis source code dan migrasi pada branch `sync/rps11-audit`. Butir yang membutuhkan Supabase Dashboard atau perangkat nyata **tidak diklaim lulus**.

| No. | Area | Temuan pada kode | Status |
| --- | --- | --- | --- |
| 1 | Dependency | `supabase_flutter ^2.18.3`, `provider`, `shared_preferences` di `pubspec.yaml` | Sesuai |
| 2 | Inisialisasi | `main.dart`: `Supabase.initialize(url, publishableKey)` sebelum `runApp`, hanya jika `SupabaseConfig.isConfigured` | Sesuai |
| 3 | Konfigurasi | URL/key via `--dart-define-from-file=env.json`; `env.json` ada di `.gitignore`; hanya `env.example.json` yang di-commit; tidak ada `service_role` di `lib/` | Sesuai (verifikasi key manual) |
| 4 | Authentication | `auth_service.dart`: register, `signInWithPassword`, signOut, `authStateChanges`; `AuthGate`/`RequireLogin` untuk fitur terproteksi | Sesuai |
| 5 | API read | `learning_repository.dart` (modul, soal), `progress_service.dart` (progres, sertifikat) | Sesuai |
| 6 | API write | RPC `submit_quiz`, `complete_module`, `issue_certificate`; insert `simulation_attempts` | Sesuai |
| 7 | Model | `lib/models/*` (LearningModule, QuizQuestion, UserProfile, dll.) | Sesuai |
| 8 | State | `AppController` (`isLoading`, `errorMessage`), `AppErrorMapper`; pesan error kini dipetakan ke bahasa pengguna | Sesuai (diperbaiki) |
| 9 | Lifecycle | Pemeriksaan `mounted` dipakai pada alur async di halaman | Sebagian, perlu uji perangkat |
| 10 | Database | Migrasi `20261017000001`–`20261116000006` (skema, RLS, RPC, seed) | Sesuai di migrasi; dashboard Not Tested |
| 11 | Security (RLS) | Policy didefinisikan di migrasi `...0002`; tes `supabase/tests/rls_verification.sql` | Not Tested di Supabase live |
| 12 | Persistence | Progres di Supabase; flag welcome/topik eksplorasi di `shared_preferences`; tidak ada mode offline | Sesuai, tanpa klaim offline |
| 13 | Mobile | Penanganan error jaringan via `AppErrorMapper`; izin INTERNET Android ada | Not Tested di perangkat |

### Penyesuaian kode untuk RPS 11

- `app_controller.dart`: `errorMessage` memakai `AppErrorMapper.toUserMessage` (tidak lagi menampilkan `e.toString()` mentah).
- `auth_service.dart`: `catch` kosong kini dicatat lewat `debugPrint` (B-18).
- `account_form_screen.dart`, `welcome_screen.dart`: teks "akun tersimpan lokal" diganti agar sesuai arsitektur Supabase; teks "Lupa kata sandi" tidak lagi menyesatkan (B-15, B-16, B-17).
- `app_shell.dart`: tap pada pre-test yang sudah selesai kini memberi umpan balik SnackBar (B-14).

### Status skenario uji (bagian 7)

Uji otomatis `flutter test`: 23 lulus, 1 gagal (`records simulation attempt...`, `pumpAndSettle timed out`) — kegagalan yang sama juga terjadi pada commit `47805dd` sebelum penyesuaian (sudah ada sebelumnya). Skenario SEC-01, SEC-02, ASYNC-02, MOBILE-01, dan DB-05 berstatus **Not Tested** hingga diuji manual dengan dua akun dan perangkat nyata.
