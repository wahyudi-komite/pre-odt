# PROMPT PEMBUATAN APLIKASI MONITORING FUTSAL

Buatkan aplikasi web lengkap, siap digunakan, dan siap di-deploy untuk event futsal dengan nama persis:

# PRE ONE DAY TURNAMENT KEP

Penting: gunakan tulisan **“TURNAMENT”** sesuai nama resmi yang diberikan. Jangan otomatis mengubahnya menjadi “TOURNAMENT”.

Aplikasi digunakan untuk memonitor pertandingan futsal dengan ketentuan:

* Terdapat 7 area pertandingan.
* Setiap area memiliki 8 tim.
* Setiap area menggunakan sistem gugur.
* Setiap area menghasilkan Juara 1, Juara 2, dan Juara 3.
* Juara antararea tidak dipertandingkan kembali.
* Total pertandingan setiap area adalah 8 pertandingan.
* Total seluruh pertandingan adalah 56 pertandingan.
* Semua bagan pertandingan Area 1 sampai Area 7 ditampilkan dalam satu halaman monitoring.
* Setiap admin area dapat memasukkan hasil pertandingan melalui satu halaman admin yang sama.
* Admin memilih Area 1 sampai Area 7 setelah berhasil login.
* Tidak perlu akun terpisah untuk setiap area.
* Gunakan satu akun admin bersama melalui Supabase Authentication.
* Data disimpan di Supabase PostgreSQL.
* Frontend di-deploy menggunakan GitHub Pages.

Jangan hanya membuat contoh, mockup, atau potongan kode. Implementasikan seluruh aplikasi di workspace sampai lengkap.

---

# 1. TUJUAN UTAMA

Aplikasi memiliki dua halaman utama:

## A. Halaman Monitoring Publik

File:

```text
index.html
```

Fungsi:

* Dapat dibuka tanpa login.
* Menampilkan bagan pertandingan seluruh Area 1 sampai Area 7.
* Hanya dapat membaca data.
* Tidak dapat mengubah nama tim, skor, status, atau hasil pertandingan.
* Otomatis menerima update terbaru dari Supabase.
* Cocok ditampilkan pada laptop, monitor, proyektor, dan televisi event.

## B. Halaman Admin Bersama

File:

```text
admin.html
```

Fungsi:

* Digunakan bersama oleh seluruh admin area.
* Menggunakan satu akun Supabase Auth bersama.
* Setelah login, admin memilih Area 1 sampai Area 7.
* Admin hanya mengelola area yang sedang dipilih pada layar.
* Admin dapat mengganti area melalui tombol pemilih area.
* Admin dapat mengatur nama tim.
* Admin dapat memasukkan skor.
* Admin dapat memasukkan skor penalti.
* Admin dapat mengubah status pertandingan.
* Admin dapat memperbaiki hasil yang salah.
* Admin dapat melihat riwayat perubahan.
* Admin dapat logout.

Jangan membuat URL admin berbeda untuk setiap area.

Semua admin menggunakan:

```text
admin.html
```

Jangan menampilkan tautan menuju `admin.html` pada halaman publik.

---

# 2. TEKNOLOGI

Gunakan teknologi berikut:

* HTML5
* CSS3
* JavaScript Vanilla modern dengan ES Modules
* Supabase PostgreSQL
* Supabase Authentication
* Supabase Realtime
* Supabase JavaScript Client versi 2
* GitHub Pages

Prioritaskan aplikasi yang ringan dan mudah dipelihara.

Jangan gunakan:

* Angular
* React
* Vue
* Next.js
* Nuxt
* Backend Node.js
* Express
* PHP
* Laravel
* Firebase
* LocalStorage sebagai sumber utama data pertandingan
* File JSON sebagai sumber utama data
* Service role key di frontend
* Password admin di source code
* PIN yang ditulis langsung di JavaScript
* API berbayar
* Library UI yang besar
* Proses build yang rumit

Aplikasi harus dapat dijalankan tanpa:

```bash
npm install
```

Gunakan Supabase JavaScript Client melalui ESM CDN yang stabil dan tentukan versinya secara eksplisit. Jangan menggunakan URL CDN tanpa nomor versi.

Contoh pendekatan:

```javascript
import { createClient } from "https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2/+esm";
```

Pastikan seluruh import bekerja pada GitHub Pages.

---

# 3. ARSITEKTUR SISTEM

Gunakan arsitektur berikut:

```text
GitHub Pages
│
├── index.html
│   └── Monitoring publik seluruh area
│
├── admin.html
│   └── Login dan input hasil pertandingan
│
└── Supabase
    ├── PostgreSQL Database
    ├── Authentication
    ├── Row Level Security
    ├── Database Functions/RPC
    ├── Audit Log
    └── Realtime
```

Ketentuan keamanan:

* Pengunjung tanpa login hanya dapat membaca data publik.
* Pengunjung tanpa login tidak dapat menambah, mengubah, atau menghapus data.
* Pengguna yang login dengan akun admin bersama dapat memasukkan dan mengubah hasil.
* Tidak ada halaman pendaftaran akun.
* Tidak ada fungsi sign-up pada frontend.
* Akun admin dibuat secara manual melalui Supabase Dashboard.
* Jangan pernah memasukkan `service_role` key ke HTML atau JavaScript.
* Gunakan hanya Supabase Project URL dan publishable/anon key pada frontend.
* Seluruh tabel harus menggunakan Row Level Security.
* Operasi perubahan data dilakukan melalui RPC/database function yang tervalidasi.
* Jangan memberikan akses update langsung tanpa validasi terhadap kolom kritis pertandingan.

---

# 4. SISTEM LOGIN ADMIN

Gunakan satu akun admin bersama yang dibuat secara manual di Supabase Authentication.

Sediakan konfigurasi:

```javascript
export const APP_CONFIG = {
    supabaseUrl: "YOUR_SUPABASE_URL",
    supabasePublishableKey: "YOUR_SUPABASE_PUBLISHABLE_KEY",
    adminEmail: "YOUR_SHARED_ADMIN_EMAIL",
    eventName: "PRE ONE DAY TURNAMENT KEP",
    timezone: "Asia/Jakarta"
};
```

Email admin boleh tersimpan di konfigurasi frontend karena bukan password.

Password tidak boleh:

* Ditulis di source code.
* Ditulis di config.
* Disimpan manual menggunakan localStorage.
* Ditampilkan pada console.
* Dimasukkan ke URL.

Tampilan login admin cukup sederhana:

```text
PRE ONE DAY TURNAMENT KEP
ADMIN PERTANDINGAN

Nama Admin/Operator
[________________________]

Password Admin
[________________________]

[ MASUK ]
```

Admin tidak perlu mengetik email. Sistem menggunakan `adminEmail` dari konfigurasi dan password yang dimasukkan admin.

Gunakan:

```javascript
supabase.auth.signInWithPassword()
```

Setelah login:

* Simpan session menggunakan mekanisme resmi Supabase Auth.
* Jangan membuat session buatan sendiri.
* Arahkan ke tampilan pemilihan area.
* Tampilkan nama operator yang diisi.
* Simpan nama operator di localStorage hanya untuk kenyamanan pengisian audit, bukan untuk autentikasi.
* Tampilkan tombol logout.
* Gunakan `supabase.auth.signOut()` ketika logout.
* Jika session berakhir, kembalikan ke layar login.
* Jangan menampilkan isi password pada log atau pesan error.

Gunakan pesan login dalam bahasa Indonesia:

* “Password admin tidak sesuai.”
* “Tidak dapat terhubung ke server.”
* “Sesi telah berakhir. Silakan masuk kembali.”
* “Login berhasil.”

Jangan membuat fitur:

* Daftar akun.
* Lupa password publik.
* Login sosial.
* Login OTP.
* Login per area.

---

# 5. PILIHAN AREA ADMIN

Setelah login, tampilkan tujuh pilihan area dalam bentuk tombol besar:

```text
PILIH AREA PERTANDINGAN

[ AREA 1 ] [ AREA 2 ] [ AREA 3 ] [ AREA 4 ]
[ AREA 5 ] [ AREA 6 ] [ AREA 7 ]
```

Ketentuan:

* Admin wajib memilih area sebelum menginput data.
* Area terpilih harus terlihat jelas.
* Tampilkan konfirmasi saat admin berpindah area jika ada input yang belum disimpan.
* Simpan pilihan area terakhir pada localStorage.
* Ketika halaman dibuka kembali, tawarkan area terakhir tetapi tetap tampilkan nama area dengan jelas.
* Sediakan tombol “Ganti Area”.
* Seluruh tombol simpan harus menampilkan nama area yang sedang dikelola.

Contoh header:

```text
ADMIN PERTANDINGAN
AREA 3

Operator: Budi
Status koneksi: Online
Terakhir sinkron: 10:35:12 WIB

[ GANTI AREA ] [ MONITORING PUBLIK ] [ LOGOUT ]
```

Tombol monitoring publik membuka `index.html` pada tab baru.

Sebelum menyimpan, tampilkan dialog konfirmasi:

```text
Simpan hasil pertandingan Area 3?

SF1
Tim Garuda 3 - 1 Tim Rajawali

Pemenang: Tim Garuda
```

Tujuannya untuk mengurangi kesalahan memilih area.

---

# 6. STRUKTUR PERTANDINGAN SETIAP AREA

Setiap area memiliki delapan tim:

```text
Tim 1
Tim 2
Tim 3
Tim 4
Tim 5
Tim 6
Tim 7
Tim 8
```

Struktur sistem gugur:

## Perempat Final

```text
QF1: Tim 1 vs Tim 2
QF2: Tim 3 vs Tim 4
QF3: Tim 5 vs Tim 6
QF4: Tim 7 vs Tim 8
```

## Semifinal

```text
SF1: Pemenang QF1 vs Pemenang QF2
SF2: Pemenang QF3 vs Pemenang QF4
```

## Perebutan Juara 3

```text
TP: Tim kalah SF1 vs Tim kalah SF2
```

Gunakan kode pertandingan:

```text
TP
```

Tetapi pada tampilan tulis:

```text
Perebutan Juara 3
```

## Final

```text
F: Pemenang SF1 vs Pemenang SF2
```

## Penentuan Juara

```text
Juara 1 = Pemenang Final
Juara 2 = Tim kalah Final
Juara 3 = Pemenang Perebutan Juara 3
```

Setiap area memiliki total:

```text
4 Perempat Final
2 Semifinal
1 Perebutan Juara 3
1 Final
-------------------------
8 Pertandingan
```

Tujuh area memiliki total 56 pertandingan.

---

# 7. DATABASE SUPABASE

Buat file SQL lengkap:

```text
supabase/schema.sql
supabase/seed.sql
supabase/policies.sql
supabase/functions.sql
supabase/realtime.sql
```

SQL harus dapat dijalankan secara berurutan melalui Supabase SQL Editor.

Gunakan UUID sebagai primary key.

Aktifkan extension yang diperlukan, termasuk `pgcrypto` bila UUID menggunakan `gen_random_uuid()`.

---

# 8. TABEL TOURNAMENTS

Buat tabel `tournaments` dengan kolom minimal:

```text
id                  uuid primary key
name                text not null
slug                text unique not null
status              text not null
event_date          date nullable
venue               text nullable
timezone            text default 'Asia/Jakarta'
created_at          timestamptz
updated_at          timestamptz
```

Nilai seed:

```text
name: PRE ONE DAY TURNAMENT KEP
slug: pre-one-day-turnament-kep
status: active
timezone: Asia/Jakarta
```

Status turnamen:

```text
draft
active
finished
```

Tambahkan check constraint.

---

# 9. TABEL AREAS

Buat tabel `areas`:

```text
id                  uuid primary key
tournament_id       uuid references tournaments(id)
area_number         integer not null
name                text not null
display_order       integer not null
created_at          timestamptz
updated_at          timestamptz
```

Tambahkan ketentuan:

* `area_number` hanya 1 sampai 7.
* Kombinasi `tournament_id` dan `area_number` harus unique.
* Seed Area 1 sampai Area 7.
* Nama awal berupa `Area 1`, `Area 2`, dan seterusnya.

---

# 10. TABEL TEAMS

Buat tabel `teams`:

```text
id                  uuid primary key
area_id             uuid references areas(id)
seed_number         integer not null
name                text not null
short_name          text nullable
is_active           boolean default true
created_at          timestamptz
updated_at          timestamptz
```

Ketentuan:

* `seed_number` hanya 1 sampai 8.
* Kombinasi `area_id` dan `seed_number` harus unique.
* Nama tim tidak boleh kosong.
* Trim spasi sebelum menyimpan.
* Panjang nama tim maksimal 60 karakter.
* Seed delapan tim dummy untuk setiap area.

Pola dummy:

```text
Area 1: Tim A1-01 sampai Tim A1-08
Area 2: Tim A2-01 sampai Tim A2-08
Area 3: Tim A3-01 sampai Tim A3-08
Area 4: Tim A4-01 sampai Tim A4-08
Area 5: Tim A5-01 sampai Tim A5-08
Area 6: Tim A6-01 sampai Tim A6-08
Area 7: Tim A7-01 sampai Tim A7-08
```

---

# 11. TABEL MATCHES

Buat tabel `matches` dengan kolom:

```text
id                         uuid primary key
area_id                    uuid references areas(id)
match_code                 text not null
stage                      text not null
display_order              integer not null

team1_id                   uuid nullable references teams(id)
team2_id                   uuid nullable references teams(id)

source_team1_match_id      uuid nullable references matches(id)
source_team1_result        text nullable
source_team2_match_id      uuid nullable references matches(id)
source_team2_result        text nullable

score_team1                integer nullable
score_team2                integer nullable
penalty_team1              integer nullable
penalty_team2              integer nullable

status                     text not null default 'not_started'
winner_team_id             uuid nullable references teams(id)
loser_team_id              uuid nullable references teams(id)

scheduled_at               timestamptz nullable
started_at                 timestamptz nullable
finished_at                timestamptz nullable

updated_by_user_id         uuid nullable
updated_by_name            text nullable

version                    integer not null default 0
created_at                 timestamptz
updated_at                 timestamptz
```

Nilai `stage` yang valid:

```text
quarter_final
semi_final
third_place
final
```

Nilai `status` yang valid:

```text
not_started
live
finished
```

Nilai sumber tim:

```text
winner
loser
```

Tambahkan constraint:

* `score_team1 >= 0`
* `score_team2 >= 0`
* `penalty_team1 >= 0`
* `penalty_team2 >= 0`
* Kombinasi `area_id` dan `match_code` unique.
* `match_code` harus salah satu dari QF1, QF2, QF3, QF4, SF1, SF2, TP, F.
* Satu pertandingan tidak boleh memiliki tim yang sama pada kedua sisi.
* Pertandingan finished wajib memiliki skor.
* Jika skor utama seri dan status finished, skor penalti wajib diisi.
* Skor penalti tidak boleh seri.
* Jika skor utama tidak seri, penalty boleh null dan tidak digunakan menentukan pemenang.

---

# 12. HUBUNGAN BRACKET

Seed struktur pertandingan setiap area dengan hubungan berikut:

```text
QF1
team1 = seed 1
team2 = seed 2

QF2
team1 = seed 3
team2 = seed 4

QF3
team1 = seed 5
team2 = seed 6

QF4
team1 = seed 7
team2 = seed 8
```

Semifinal:

```text
SF1.team1 = winner QF1
SF1.team2 = winner QF2

SF2.team1 = winner QF3
SF2.team2 = winner QF4
```

Final:

```text
F.team1 = winner SF1
F.team2 = winner SF2
```

Perebutan Juara 3:

```text
TP.team1 = loser SF1
TP.team2 = loser SF2
```

Kolom peserta babak berikutnya tidak boleh diubah manual dari frontend.

Semua propagasi peserta dilakukan oleh fungsi database.

---

# 13. TABEL AUDIT LOG

Buat tabel `match_audit_logs`:

```text
id                  uuid primary key
match_id            uuid references matches(id)
area_id             uuid references areas(id)
action_type         text not null
old_data            jsonb nullable
new_data            jsonb nullable
operator_name       text not null
auth_user_id        uuid nullable
created_at          timestamptz
```

Nilai `action_type`:

```text
create
update
reset
force_update
```

Setiap perubahan pertandingan harus mencatat:

* Area.
* Kode pertandingan.
* Nilai sebelum perubahan.
* Nilai sesudah perubahan.
* Nama operator.
* User ID Supabase Auth.
* Waktu perubahan.

Audit log:

* Hanya dapat dibaca pengguna authenticated.
* Tidak dapat diubah dari frontend.
* Tidak dapat dihapus dari frontend.
* Ditampilkan maksimal 20 atau 30 perubahan terbaru untuk area terpilih.

---

# 14. FUNGSI DATABASE/RPC

Jangan bergantung hanya pada validasi JavaScript. Buat validasi utama di PostgreSQL.

Buat RPC berikut.

## A. `save_match_result`

Parameter minimal:

```text
p_match_id
p_score_team1
p_score_team2
p_penalty_team1
p_penalty_team2
p_status
p_operator_name
p_expected_version
p_force_reset_downstream default false
```

Fungsi harus:

1. Memastikan pengguna sudah authenticated.
2. Memastikan pertandingan ditemukan.
3. Mengunci row pertandingan selama transaksi.
4. Membandingkan `p_expected_version` dengan `matches.version`.
5. Menolak penyimpanan bila version berbeda.
6. Memvalidasi nama operator.
7. Memvalidasi status.
8. Memvalidasi skor.
9. Memastikan kedua peserta pertandingan sudah tersedia.
10. Menentukan pemenang dan tim kalah.
11. Memperbarui waktu pertandingan.
12. Menambah nilai version.
13. Menulis audit log.
14. Memperbarui peserta babak berikutnya.
15. Memperbarui `updated_at` turnamen.
16. Mengembalikan data pertandingan terbaru.

Aturan status:

### `not_started`

* Skor harus null.
* Penalti harus null.
* Winner dan loser harus null.
* `started_at` dan `finished_at` null.

### `live`

* Skor boleh diisi.
* Skor boleh seri.
* Pemenang belum ditetapkan.
* `started_at` diisi jika sebelumnya null.
* `finished_at` null.

### `finished`

* Skor utama wajib diisi.
* Jika skor utama tidak seri, tentukan winner dari skor terbesar.
* Jika skor utama seri, skor penalti wajib diisi.
* Penalti tidak boleh seri.
* Tentukan winner dan loser.
* Isi `finished_at`.

Jika status finished tetapi skor utama seri dan penalti kosong, kembalikan pesan:

```text
Skor utama seri. Masukkan hasil adu penalti.
```

Jika penalty seri:

```text
Skor adu penalti tidak boleh seri.
```

## B. Optimistic Concurrency

Gunakan kolom `version`.

Jika dua admin membuka pertandingan yang sama dan salah satunya lebih dahulu menyimpan, admin kedua tidak boleh menimpa data tanpa sadar.

Jika version berubah, kembalikan pesan:

```text
Data pertandingan telah diperbarui oleh admin lain. Muat ulang data sebelum menyimpan.
```

Frontend harus:

* Menutup loading state.
* Mengambil data terbaru.
* Menampilkan perbedaan.
* Tidak menimpa data otomatis.

## C. Perubahan Hasil Babak Sebelumnya

Contoh:

* QF1 awalnya dimenangkan Tim A.
* SF1 sudah menerima Tim A.
* Hasil QF1 kemudian dikoreksi sehingga Tim B menang.

Jika pertandingan lanjutan belum dimulai:

* Perbarui peserta pertandingan berikutnya otomatis.

Jika pertandingan lanjutan sudah live atau finished:

* Jangan langsung mengubah hasil.
* Kembalikan informasi pertandingan yang terdampak.
* Frontend menampilkan peringatan.

Contoh peringatan:

```text
Perubahan hasil QF1 akan memengaruhi:

- SF1
- Final atau Perebutan Juara 3 yang bergantung pada SF1

Pertandingan terdampak yang sudah memiliki hasil akan direset.
```

Sediakan pilihan:

```text
[ BATAL ]
[ RESET PERTANDINGAN TERDAMPAK & SIMPAN ]
```

Jika admin menyetujui:

* Panggil RPC kembali dengan `p_force_reset_downstream = true`.
* Reset seluruh pertandingan downstream yang terdampak.
* Hapus skor, penalti, winner, loser, started_at, dan finished_at.
* Ubah status menjadi `not_started`.
* Perbarui peserta sesuai hasil terbaru.
* Catat seluruh reset di audit log.
* Lakukan dalam satu transaksi.

Jangan membiarkan bracket berada dalam kondisi peserta dan hasil yang tidak konsisten.

## D. `reset_match_result`

Parameter:

```text
p_match_id
p_operator_name
p_expected_version
p_reset_downstream default true
```

Fungsi:

* Hanya untuk authenticated user.
* Mengosongkan skor dan hasil pertandingan.
* Mengubah status menjadi `not_started`.
* Mereset pertandingan downstream jika diperlukan.
* Menulis audit log.
* Menambah version.
* Meminta konfirmasi di frontend.

## E. `update_team_name`

Parameter:

```text
p_team_id
p_team_name
p_operator_name
```

Aturan:

* Hanya authenticated user.
* Nama tidak boleh kosong.
* Maksimal 60 karakter.
* Trim whitespace.
* Tulis audit perubahan atau buat tabel audit tim terpisah.
* Jika pertandingan area sudah dimulai, nama masih boleh dikoreksi karena team ID tidak berubah.
* Perubahan nama langsung tampil di seluruh bracket.

## F. `reset_area`

Boleh disediakan untuk persiapan atau pengujian, tetapi letakkan di bagian “Pengaturan Lanjutan”.

Parameter:

```text
p_area_id
p_operator_name
p_confirmation_text
```

Hanya jalankan jika confirmation text persis:

```text
RESET AREA
```

Fungsi:

* Menghapus seluruh skor area.
* Mengembalikan seluruh status ke `not_started`.
* Menghapus peserta otomatis dari semifinal, final, dan perebutan juara 3.
* Mempertahankan nama tim.
* Menulis audit log.
* Meminta konfirmasi dua tahap di frontend.

---

# 15. DATABASE TRIGGER

Buat trigger untuk:

* Mengisi `created_at`.
* Mengisi `updated_at`.
* Memperbarui `tournaments.updated_at` ketika teams atau matches berubah.
* Menjaga `version`.
* Menolak winner atau loser yang tidak termasuk team1/team2.
* Menjaga konsistensi data pertandingan.

Untuk fungsi `SECURITY DEFINER`:

* Tetapkan `search_path` secara eksplisit.
* Validasi `auth.uid()`.
* Jangan menerima area ID dari frontend tanpa memverifikasi hubungan pertandingan.
* Jangan membuat fungsi yang dapat dipanggil pengguna anonim untuk menulis data.

---

# 16. ROW LEVEL SECURITY

Aktifkan RLS pada seluruh tabel.

## Akses Anonim

Role `anon` boleh SELECT:

* `tournaments`
* `areas`
* `teams`
* `matches`

Role `anon` tidak boleh:

* INSERT
* UPDATE
* DELETE
* Membaca audit log
* Memanggil RPC perubahan data

## Akses Authenticated

Role `authenticated` boleh:

* SELECT data turnamen.
* SELECT audit log.
* EXECUTE RPC yang memang disediakan untuk admin.

Jangan memberikan authenticated user akses langsung untuk mengubah kolom pertandingan kritis jika operasi tersebut melewati validasi RPC.

Revoke hak write langsung yang tidak diperlukan.

Buat pengujian SQL untuk memastikan:

1. Anon dapat membaca.
2. Anon tidak dapat mengubah skor.
3. Authenticated dapat menjalankan RPC.
4. Service role tidak digunakan di frontend.
5. Audit log tidak dapat diubah oleh authenticated user.

---

# 17. REALTIME

Aktifkan Supabase Realtime untuk tabel:

```text
tournaments
areas
teams
matches
```

Tambahkan tabel yang diperlukan ke publication Supabase Realtime.

Pada halaman publik:

* Subscribe perubahan `INSERT`, `UPDATE`, dan `DELETE`.
* Ketika pertandingan berubah, perbarui area terkait.
* Jangan me-reload seluruh halaman.
* Jangan mengembalikan posisi scroll ke atas.
* Tampilkan indikator koneksi realtime.

Status koneksi:

```text
Live
Menghubungkan
Offline
```

Gunakan fallback:

* Refresh data setiap 60 detik.
* Tombol “Refresh Data”.
* Jangan membuat subscription ganda.
* Hapus subscription ketika halaman ditutup atau diinisialisasi ulang.

Pada halaman admin:

* Subscribe terhadap pertandingan area terpilih.
* Jika pertandingan diperbarui admin lain, tampilkan data terbaru.
* Jika form sedang diedit, jangan menimpa input secara diam-diam.
* Tampilkan notifikasi bahwa data di server telah berubah.

---

# 18. HALAMAN MONITORING PUBLIK

Buat halaman publik modern dan profesional.

## Header

Tampilkan:

```text
PRE ONE DAY TURNAMENT KEP
Monitoring Pertandingan Futsal
```

Tambahkan:

* Ikon atau ilustrasi sederhana futsal.
* Badge “LIVE UPDATE”.
* Waktu update terakhir dalam WIB.
* Status koneksi realtime.
* Tombol fullscreen.
* Tombol refresh.
* Tombol Mode Display.

Jangan tampilkan tombol admin.

## Statistik Utama

Tampilkan:

* Total area: 7.
* Total tim: 56.
* Total pertandingan: 56.
* Pertandingan selesai.
* Pertandingan berlangsung.
* Pertandingan belum dimulai.

Hitung berdasarkan data database, bukan angka statis selain total konfigurasi.

## Ringkasan Juara

Buat tabel atau panel:

```text
Area | Juara 1 | Juara 2 | Juara 3 | Progress
```

Contoh:

```text
Area 1 | Tim Garuda | Tim Rajawali | Tim Elang | 100%
Area 2 | Belum Ditentukan | Belum Ditentukan | Belum Ditentukan | 50%
```

Progress:

```text
jumlah pertandingan finished / 8 × 100%
```

Tampilkan progress bar.

## Filter

Sediakan filter ringan:

* Semua Area.
* Area 1 sampai Area 7.
* Semua Status.
* Belum Dimulai.
* Berlangsung.
* Selesai.
* Pencarian nama tim.

Default:

```text
Semua Area
```

Filter tidak boleh mengubah data.

## Seluruh Area Tetap dalam Satu Halaman

Semua bagan harus dirender dalam satu dokumen halaman.

Jangan membuat:

```text
area1.html
area2.html
...
```

Gunakan card atau section:

```text
Area 1
Area 2
Area 3
Area 4
Area 5
Area 6
Area 7
```

---

# 19. TAMPILAN BAGAN PERTANDINGAN

Setiap area memiliki satu card bracket.

Struktur visual:

```text
PEREMPAT FINAL → SEMIFINAL → FINAL/JUARA 3 → PODIUM
```

Kolom pertama:

```text
QF1
QF2
QF3
QF4
```

Kolom kedua:

```text
SF1
SF2
```

Kolom ketiga:

```text
Final
Perebutan Juara 3
```

Kolom keempat:

```text
Juara 1
Juara 2
Juara 3
```

Buat garis konektor bracket menggunakan CSS jika memungkinkan.

Jangan menggunakan canvas yang menyulitkan responsivitas.

Setiap match card menampilkan:

* Kode pertandingan.
* Nama babak.
* Nama Tim 1.
* Skor Tim 1.
* Nama Tim 2.
* Skor Tim 2.
* Penalti jika ada.
* Badge status.
* Waktu pertandingan jika tersedia.
* Pemenang jika finished.
* Waktu update terakhir.

Contoh normal:

```text
QF1 — SELESAI

✓ Tim Garuda       3
  Tim Rajawali     1
```

Contoh penalti:

```text
QF2 — SELESAI

✓ Tim Elang        2 (5)
  Tim Macan        2 (4)

Menang adu penalti
```

Contoh belum tersedia:

```text
SF1 — BELUM DIMULAI

Menunggu Pemenang QF1
Menunggu Pemenang QF2
```

Contoh live:

```text
SF2 — BERLANGSUNG

Tim Biru           2
Tim Merah          2
```

Pemenang:

* Gunakan font lebih tebal.
* Beri ikon centang.
* Gunakan aksen hijau.
* Jangan menghilangkan tim yang kalah.
* Tim kalah tampil sedikit lebih redup.

---

# 20. PODIUM SETIAP AREA

Tampilkan:

```text
🥇 Juara 1
🥈 Juara 2
🥉 Juara 3
```

Jika belum ditentukan:

```text
Belum Ditentukan
```

Penentuan:

* Juara 1 dari winner Final.
* Juara 2 dari loser Final.
* Juara 3 dari winner TP.

Gunakan warna:

* Emas untuk Juara 1.
* Perak untuk Juara 2.
* Perunggu untuk Juara 3.

Jangan menentukan juara hanya berdasarkan skor yang dihitung di frontend. Gunakan hasil konsisten dari database.

---

# 21. MODE DISPLAY EVENT

Sediakan tombol:

```text
MODE DISPLAY
```

Saat aktif:

* Masuk fullscreen jika diizinkan browser.
* Sembunyikan filter yang tidak penting.
* Sembunyikan tombol teknis.
* Perbesar nama tim dan skor.
* Pertahankan badge koneksi.
* Pertahankan waktu update.
* Fokus pada bracket.
* Jangan melakukan reload halaman.
* Jangan mengubah posisi scroll saat update realtime.

Tambahkan opsi:

```text
[ Semua Area ]
[ Fokus Area ]
```

Dalam mode Semua Area:

* Seluruh area tetap tersedia pada satu halaman.
* Layout dibuat sepadat mungkin tanpa mengorbankan keterbacaan.

Dalam mode Fokus Area:

* Pengguna dapat memilih satu area untuk diperbesar.
* Ini hanya mode tampilan, bukan halaman atau URL area terpisah.

---

# 22. DESAIN VISUAL

Gunakan desain:

* Modern.
* Bersih.
* Sporty.
* Profesional.
* Cocok untuk event.
* Mudah dibaca dari jarak jauh.
* Tidak terlalu ramai.
* Tidak terlalu banyak animasi.
* Tidak menggunakan efek glow berlebihan.

Tema warna:

```text
Background utama: navy gelap
Card: navy lebih terang atau putih
Aksen utama: hijau lapangan futsal
Teks utama: putih atau sangat gelap sesuai card
Status live: oranye
Status selesai: hijau
Status belum dimulai: abu-abu
Juara 1: emas
Juara 2: perak
Juara 3: perunggu
Error: merah
```

Gunakan CSS custom properties:

```css
:root {
    --color-bg: ...;
    --color-surface: ...;
    --color-primary: ...;
    --color-live: ...;
    --color-success: ...;
    --color-danger: ...;
    --color-gold: ...;
    --color-silver: ...;
    --color-bronze: ...;
}
```

Gunakan font yang mudah dibaca, misalnya:

* Inter.
* Poppins.
* System font fallback.

Pastikan tetap terbaca jika Google Fonts gagal dimuat.

---

# 23. RESPONSIVE DESIGN

Aplikasi harus optimal pada:

* Smartphone.
* Tablet.
* Laptop.
* Monitor Full HD.
* Televisi Full HD.
* Monitor 2K.
* Monitor 4K.

## Desktop Besar

* Gunakan 2 card area per baris jika bracket masih terbaca.
* Area ketujuh boleh mengambil lebar penuh.
* Jangan memaksakan dua kolom jika nama tim menjadi terlalu kecil.

## Laptop

* Gunakan satu area per baris atau dua kolom sesuai ruang.
* Bracket tetap terbaca.

## Mobile

* Card area tersusun vertikal.
* Bracket boleh memiliki horizontal scroll di dalam card.
* Header dibuat ringkas.
* Tombol memiliki ukuran sentuh yang cukup.
* Score input admin menggunakan keyboard numerik.
* Jangan membuat seluruh body mengalami horizontal overflow.

Gunakan breakpoint berdasarkan kebutuhan desain, bukan hanya perangkat tertentu.

---

# 24. HALAMAN ADMIN

Setelah area dipilih, tampilkan tiga tab:

```text
[ INPUT SKOR ]
[ NAMA TIM ]
[ RIWAYAT ]
```

Tambahkan tab keempat opsional:

```text
[ PENGATURAN ]
```

## Tab Input Skor

Kelompokkan pertandingan:

```text
PEREMPAT FINAL
QF1
QF2
QF3
QF4

SEMIFINAL
SF1
SF2

PEREBUTAN JUARA 3
TP

FINAL
F
```

Setiap pertandingan berupa card input.

Contoh:

```text
QF1 — PEREMPAT FINAL

Tim Garuda
[ 3 ]

Tim Rajawali
[ 1 ]

Status
[ Belum Dimulai ▼ ]

[ SIMPAN ]
```

Untuk mempermudah penggunaan, boleh sediakan tombol cepat:

```text
[ BELUM DIMULAI ]
[ MULAI / LIVE ]
[ SELESAI ]
```

Tetapi state akhir tetap harus jelas.

## Input Skor

Gunakan:

```html
<input type="number" min="0" step="1" inputmode="numeric">
```

Ketentuan:

* Hanya angka bulat.
* Tidak boleh negatif.
* Tidak menerima desimal.
* Tidak boleh kosong jika status finished.
* Tombol simpan memiliki loading state.
* Cegah double submit.
* Disable tombol selama request berlangsung.

## Penalti

Jika:

```text
score_team1 === score_team2
```

dan status:

```text
finished
```

munculkan:

```text
HASIL ADU PENALTI

Penalti Tim 1 [ ]
Penalti Tim 2 [ ]
```

Jika skor utama berubah tidak seri:

* Kosongkan tampilan penalti.
* Jangan gunakan penalti lama.

## Pertandingan Belum Siap

SF1 belum dapat diinput jika QF1 atau QF2 belum finished.

SF2 belum dapat diinput jika QF3 atau QF4 belum finished.

Final dan Perebutan Juara 3 belum dapat diinput jika kedua semifinal belum finished.

Tampilkan:

```text
Pertandingan belum tersedia.
Menunggu hasil QF1 dan QF2.
```

Jangan hanya menonaktifkan tanpa penjelasan.

## Konfirmasi Penyimpanan

Sebelum simpan, tampilkan modal berisi:

* Area.
* Kode pertandingan.
* Nama tim.
* Skor.
* Penalti jika ada.
* Status.
* Pemenang jika selesai.
* Nama operator.

Tombol:

```text
[ BATAL ]
[ YA, SIMPAN ]
```

## Hasil Simpan

Jika berhasil:

```text
Hasil berhasil disimpan.

Pemenang: Tim Garuda
Tim Garuda masuk ke Semifinal 1.
```

Jika status live:

```text
Status pertandingan berhasil diubah menjadi Berlangsung.
```

Jika gagal:

* Tampilkan pesan yang mudah dipahami.
* Jangan hanya menampilkan object error Supabase.
* Log detail teknis hanya melalui `console.error`, tanpa password atau token.

---

# 25. TAB NAMA TIM

Tampilkan delapan tim area terpilih:

```text
Seed 1 [ Tim Garuda    ]
Seed 2 [ Tim Rajawali  ]
...
Seed 8 [ Tim Elang     ]
```

Ketentuan:

* Simpan satu tim per tombol atau sediakan “Simpan Semua”.
* Validasi nama kosong.
* Trim spasi.
* Maksimal 60 karakter.
* Tampilkan jumlah karakter jika mendekati batas.
* Tampilkan preview pasangan QF.
* Perubahan nama langsung terlihat pada halaman monitoring.
* ID tim tidak berubah ketika nama diperbarui.

Tambahkan peringatan:

```text
Pastikan nama tim dan urutan pasangan pertandingan sudah benar.
```

Jangan menyediakan drag-and-drop jika membuat aplikasi lebih rumit.

---

# 26. TAB RIWAYAT

Tampilkan perubahan terbaru area terpilih.

Kolom:

```text
Waktu
Operator
Pertandingan
Aksi
Data Sebelum
Data Sesudah
```

Gunakan format waktu WIB.

Untuk mobile, gunakan card bukan tabel lebar.

Contoh:

```text
18 Juli 2026, 10:35 WIB
Operator: Budi
Area 3 — QF1
Perubahan: 2-1 menjadi 3-1
```

Sediakan tombol:

```text
Muat Lebih Banyak
```

Jangan tampilkan UUID mentah kepada pengguna.

---

# 27. PENGATURAN LANJUTAN

Buat bagian yang tidak langsung terbuka.

Fitur:

* Reset satu pertandingan.
* Reset pertandingan beserta downstream.
* Reset seluruh area.
* Refresh data.
* Lihat status koneksi.

Untuk reset area:

1. Tampilkan peringatan.
2. Admin harus mengetik `RESET AREA`.
3. Tampilkan nama area.
4. Minta konfirmasi kedua.
5. Jalankan RPC.
6. Tampilkan hasil.
7. Jangan menghapus nama tim.

---

# 28. KONDISI OFFLINE DAN ERROR

Aplikasi harus menangani:

* Internet terputus.
* Supabase tidak dapat diakses.
* Session berakhir.
* Realtime disconnect.
* Data gagal dimuat.
* Data berubah oleh admin lain.
* Request timeout.
* Data database tidak lengkap.

Tampilkan banner:

```text
Koneksi terputus. Data yang terlihat mungkin bukan data terbaru.
```

Ketentuan:

* Jangan mengizinkan simpan saat offline.
* Jangan menyimpan hasil pertandingan secara lokal lalu menyinkronkan diam-diam.
* Jangan berisiko mengirim data lama setelah koneksi kembali.
* Setelah online kembali, ambil ulang data server.
* Tampilkan tombol “Coba Lagi”.
* Data monitoring terakhir boleh tetap terlihat dengan label offline.

---

# 29. LOADING, EMPTY STATE, DAN FEEDBACK

Sediakan:

* Skeleton loading.
* Spinner kecil pada tombol.
* Toast success.
* Toast warning.
* Toast error.
* Empty state.
* Error state.
* Confirm modal.

Contoh empty state:

```text
Data pertandingan belum tersedia.
```

Contoh error:

```text
Data gagal dimuat.
Periksa koneksi lalu coba kembali.
```

Jangan menggunakan `alert()` browser untuk alur utama.

Buat komponen modal dan toast menggunakan HTML, CSS, dan JavaScript.

---

# 30. FORMAT WAKTU

Database menyimpan waktu sebagai `timestamptz`.

Frontend menampilkan waktu dalam:

```text
Asia/Jakarta
WIB
id-ID
```

Gunakan `Intl.DateTimeFormat`.

Contoh:

```text
18 Juli 2026, 10.35 WIB
```

Jangan menyimpan waktu lokal sebagai string manual di database.

---

# 31. AKSESIBILITAS

Pastikan:

* Semua input memiliki label.
* Modal dapat ditutup dengan Escape.
* Focus tidak hilang ketika modal dibuka.
* Tombol dapat digunakan melalui keyboard.
* Kontras warna memadai.
* Status tidak hanya dibedakan berdasarkan warna.
* Gunakan ikon dan teks.
* Gunakan `aria-live` untuk toast penting.
* Gunakan heading hierarchy yang benar.
* Gunakan semantic HTML.

---

# 32. STRUKTUR FOLDER

Gunakan struktur berikut:

```text
pre-one-day-turnament-kep/
├── index.html
├── admin.html
├── 404.html
├── .nojekyll
├── README.md
├── SETUP_SUPABASE.md
├── SECURITY.md
│
├── assets/
│   ├── icons/
│   └── images/
│
├── css/
│   ├── base.css
│   ├── public.css
│   └── admin.css
│
├── js/
│   ├── config.js
│   ├── supabase-client.js
│   ├── utils.js
│   ├── bracket-engine.js
│   ├── data-service.js
│   ├── realtime-service.js
│   ├── public-app.js
│   └── admin-app.js
│
└── supabase/
    ├── schema.sql
    ├── functions.sql
    ├── policies.sql
    ├── realtime.sql
    ├── seed.sql
    └── verification.sql
```

Keterangan:

* `config.js`: konfigurasi publik Supabase.
* `supabase-client.js`: inisialisasi client.
* `utils.js`: format waktu, sanitasi tampilan, debounce, error mapping.
* `bracket-engine.js`: helper tampilan bracket, bukan sumber otoritas hasil.
* `data-service.js`: query read dan pemanggilan RPC.
* `realtime-service.js`: subscribe/unsubscribe.
* `public-app.js`: halaman monitoring.
* `admin-app.js`: login dan administrasi.
* `verification.sql`: query pengujian database dan RLS.
* `.nojekyll`: memastikan GitHub Pages menyajikan file statis tanpa proses Jekyll.

Hindari file JavaScript yang terlalu besar.

Pisahkan fungsi sesuai tanggung jawab.

---

# 33. KEAMANAN FRONTEND

Pastikan:

* Gunakan `textContent`, bukan `innerHTML`, untuk data nama tim yang berasal dari database.
* Jika menggunakan template HTML, lakukan escaping yang benar.
* Jangan memasukkan password ke localStorage.
* Jangan memasukkan access token ke URL.
* Jangan log session lengkap.
* Jangan log password.
* Jangan log refresh token.
* Jangan gunakan service role key.
* Jangan menonaktifkan RLS.
* Jangan menganggap halaman admin yang tidak ditautkan sebagai perlindungan keamanan.
* Jangan mengandalkan validasi frontend saja.
* Jangan menyimpan data pertandingan di localStorage sebagai sumber utama.
* Jangan menggunakan query string untuk skor atau password.

---

# 34. PUBLIC CONFIG

Karena aplikasi berjalan pada GitHub Pages, `config.js` dapat berisi:

* Supabase URL.
* Supabase publishable/anon key.
* Email akun admin bersama.
* Nama event.
* Timezone.

Jelaskan dalam `SECURITY.md` bahwa:

* Publishable/anon key memang digunakan di browser.
* Keamanan data bergantung pada grants, RLS, dan RPC.
* Service role key tidak boleh masuk repository.
* Password admin tidak boleh masuk repository.
* Database password tidak boleh masuk repository.

Sediakan placeholder yang jelas dan jangan memasukkan kredensial nyata.

---

# 35. README

Buat `README.md` lengkap dalam bahasa Indonesia.

Isi:

1. Deskripsi aplikasi.
2. Fitur utama.
3. Arsitektur.
4. Struktur pertandingan.
5. Struktur folder.
6. Cara menjalankan lokal.
7. Cara konfigurasi Supabase.
8. Cara membuat akun admin bersama.
9. Cara mengganti config.
10. Cara deploy GitHub Pages.
11. Cara mengubah nama tim.
12. Cara memasukkan skor.
13. Cara memasukkan penalti.
14. Cara reset pertandingan.
15. Cara melihat audit log.
16. Troubleshooting.
17. Keamanan dasar.

Cara menjalankan lokal:

```bash
python -m http.server 8080
```

Lalu buka:

```text
http://localhost:8080
```

Jangan menyarankan membuka `index.html` dengan double-click karena ES Modules dapat bermasalah melalui protokol file.

---

# 36. SETUP SUPABASE

Buat `SETUP_SUPABASE.md` dengan langkah sangat rinci:

## Langkah 1

Buat project Supabase baru.

## Langkah 2

Buka SQL Editor.

## Langkah 3

Jalankan file secara urut:

```text
1. schema.sql
2. functions.sql
3. policies.sql
4. realtime.sql
5. seed.sql
6. verification.sql
```

Pastikan urutan sesuai dependency aktual. Jika implementasi membutuhkan urutan berbeda, sesuaikan dokumentasi dan struktur file.

## Langkah 4

Buka Authentication.

Buat satu user admin secara manual.

Contoh:

```text
Email: email admin yang valid
Password: password kuat yang akan dibagikan kepada admin area
```

Jangan membuat akun melalui frontend.

## Langkah 5

Pastikan public sign-up tidak digunakan oleh aplikasi.

Jelaskan konfigurasi Auth yang perlu diperiksa.

## Langkah 6

Salin:

```text
Project URL
Publishable key atau anon key
```

Masukkan ke:

```text
js/config.js
```

## Langkah 7

Masukkan email akun admin bersama ke:

```text
adminEmail
```

## Langkah 8

Uji:

* Public monitoring dapat membaca.
* Admin dapat login.
* Pengunjung tidak dapat menulis.
* Realtime berjalan.
* Audit log tercatat.

---

# 37. DEPLOYMENT GITHUB PAGES

Buat panduan:

1. Buat repository GitHub.
2. Push seluruh source code.
3. Pastikan `.nojekyll` ada.
4. Buka repository Settings.
5. Pilih Pages.
6. Pilih Deploy from a branch.
7. Pilih branch `main`.
8. Pilih folder `/root`.
9. Simpan.
10. Buka URL GitHub Pages.

Pastikan seluruh path menggunakan relative path.

Contoh benar:

```text
./css/base.css
./js/public-app.js
```

Hindari path yang selalu dimulai dari root domain jika dapat menyebabkan masalah pada project site GitHub Pages.

Aplikasi harus bekerja pada pola URL:

```text
https://username.github.io/pre-one-day-turnament-kep/
```

Bukan hanya pada root domain.

---

# 38. DATA DUMMY DAN SEED

Seed:

* 1 turnamen.
* 7 area.
* 56 tim.
* 56 pertandingan.
* Semua pertandingan awalnya `not_started`.
* QF memiliki peserta awal.
* SF, TP, dan F memiliki peserta null tetapi memiliki source match.
* Seluruh skor null.
* Seluruh winner dan loser null.

Jangan memberikan contoh hasil selesai pada seed produksi utama.

Boleh membuat file opsional:

```text
supabase/demo-data.sql
```

yang mengisi beberapa skor untuk pengujian.

Jangan menjalankan demo data otomatis pada setup produksi.

---

# 39. TESTING MANUAL

Buat checklist pengujian di README.

## Public

* Seluruh 7 area tampil.
* Seluruh 56 pertandingan tersedia.
* Public tidak dapat mengubah data.
* Filter area bekerja.
* Pencarian tim bekerja.
* Fullscreen bekerja.
* Realtime bekerja.
* Fallback refresh bekerja.
* Mobile responsive.
* Tidak ada console error.

## Admin

* Login password benar berhasil.
* Password salah ditolak.
* Session bertahan setelah refresh.
* Logout berhasil.
* Pemilihan 7 area bekerja.
* Perubahan area meminta konfirmasi jika ada input belum disimpan.
* Nama tim dapat diubah.
* Skor live dapat disimpan.
* Hasil finished dapat disimpan.
* Skor seri meminta penalti.
* Penalti seri ditolak.
* Skor negatif ditolak.
* Double submit dicegah.
* QF winner masuk semifinal yang benar.
* SF winner masuk final.
* SF loser masuk perebutan Juara 3.
* Final menghasilkan Juara 1 dan 2.
* TP menghasilkan Juara 3.
* Audit log tercatat.
* Perubahan upstream menangani downstream.
* Optimistic concurrency bekerja.
* Reset pertandingan bekerja.
* Reset area bekerja.

## Realtime

Buka dua browser:

```text
Browser A: admin.html
Browser B: index.html
```

Simpan skor dari Browser A.

Pastikan Browser B berubah tanpa reload penuh.

Buka admin pada dua perangkat dan uji konflik version.

---

# 40. ACCEPTANCE CRITERIA

Aplikasi dianggap selesai hanya jika:

1. Seluruh file source code tersedia.
2. Tidak ada placeholder fungsi yang belum dibuat.
3. Tidak ada komentar `TODO` pada fungsi utama.
4. Seluruh SQL dapat dijalankan.
5. Seed menghasilkan tepat 7 area.
6. Setiap area memiliki tepat 8 tim.
7. Setiap area memiliki tepat 8 pertandingan.
8. Total tim tepat 56.
9. Total pertandingan tepat 56.
10. Public dapat membaca data tanpa login.
11. Public tidak dapat menulis data.
12. Admin dapat login dengan satu akun bersama.
13. Admin dapat memilih Area 1 sampai Area 7.
14. Admin dapat memasukkan skor melalui satu halaman yang sama.
15. Bracket diperbarui otomatis.
16. Pemenang dan tim kalah diproses dengan benar.
17. Penalti diproses dengan benar.
18. Juara 1, 2, dan 3 diproses dengan benar.
19. Perubahan tampil realtime.
20. Tidak menggunakan service role key di frontend.
21. Tidak menyimpan password di source code.
22. Tidak membutuhkan backend tambahan.
23. Tidak membutuhkan `npm install`.
24. Dapat berjalan di GitHub Pages.
25. Dapat digunakan pada smartphone.
26. Tidak ada error JavaScript pada console.
27. Error database ditangani dengan pesan yang jelas.
28. README dan panduan setup tersedia dalam bahasa Indonesia.

---

# 41. URUTAN PENGERJAAN

Kerjakan dengan urutan:

1. Analisis requirement.
2. Buat struktur folder.
3. Buat schema database.
4. Buat function dan RPC.
5. Buat RLS dan grants.
6. Buat seed.
7. Buat verification SQL.
8. Buat Supabase client.
9. Buat data service.
10. Buat realtime service.
11. Buat halaman publik.
12. Buat halaman admin.
13. Buat bracket engine untuk rendering.
14. Buat responsive CSS.
15. Buat loading dan error states.
16. Buat dokumentasi.
17. Jalankan pemeriksaan syntax.
18. Lakukan pengujian manual semampunya.
19. Periksa seluruh hubungan bracket.
20. Laporkan file yang dibuat dan langkah konfigurasi berikutnya.

---

# 42. INSTRUKSI TERAKHIR

Implementasikan aplikasi secara nyata di workspace.

Jangan hanya menjelaskan cara membuatnya.

Jangan berhenti setelah membuat tampilan.

Jangan menggunakan data statis sebagai pengganti Supabase.

Jangan menyederhanakan autentikasi menjadi PIN hardcoded.

Jangan menggunakan service role key pada browser.

Jangan mengubah nama event.

Gunakan bahasa Indonesia pada seluruh antarmuka dan dokumentasi.

Setelah implementasi selesai:

* Periksa ulang kode.
* Periksa ulang SQL.
* Periksa ulang RLS.
* Periksa ulang bracket.
* Periksa ulang relative path GitHub Pages.
* Periksa ulang responsivitas.
* Periksa ulang error handling.
* Berikan daftar file yang berhasil dibuat.
* Berikan langkah yang harus dilakukan pengguna di Supabase.
* Berikan langkah deployment GitHub Pages.
* Jelaskan bagian konfigurasi yang masih berupa placeholder.

Prioritas utama:

```text
1. Ketepatan alur pertandingan
2. Kemudahan input admin area
3. Keamanan perubahan data
4. Realtime monitoring
5. Keterbacaan display
6. Kesederhanaan deployment
7. Desain visual
```
