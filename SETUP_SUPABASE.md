# Setup Supabase — PRE ONE DAY TURNAMENT KEP

Panduan lengkap konfigurasi Supabase untuk aplikasi monitoring futsal.

---

## Langkah 1 — Buat Project Supabase

1. Buka https://supabase.com
2. Login atau daftar
3. Klik "New Project"
4. Masukkan nama project (contoh: `pre-odt-kep`)
5. Set password database (simpan password ini)
6. Pilih region terdekat (Asia Southeast 1 atau Singapore)
7. Klik "Create new project"
8. Tunggu sampai selesai (beberapa menit)

## Langkah 2 — Buka SQL Editor

1. Di dashboard Supabase, klik "SQL Editor" di sidebar kiri
2. Klik "New Query"

## Langkah 3 — Jalankan File SQL

Jalankan file dalam urutan berikut. Copy paste isi setiap file ke SQL Editor lalu klik "Run".

### 3.1 — schema.sql

Buka file `supabase/schema.sql`, copy seluruh isi, paste ke SQL Editor, lalu Run.

Membuat tabel:
- `tournaments` — data turnamen
- `areas` — 7 area pertandingan
- `teams` — 56 tim
- `matches` — 56 pertandingan
- `match_audit_logs` — catatan perubahan

### 3.2 — functions.sql

Buka file `supabase/functions.sql`, copy seluruh isi, paste ke SQL Editor, lalu Run.

Membuat fungsi:
- `save_match_result` — menyimpan skor pertandingan
- `reset_match_result` — mereset pertandingan
- `update_team_name` — mengubah nama tim
- `reset_area` — mereset seluruh area
- Trigger untuk updated_at

### 3.3 — policies.sql

Buka file `supabase/policies.sql`, copy seluruh isi, paste ke SQL Editor, lalu Run.

Mengaktifkan Row Level Security pada semua tabel dan memberikan akses:
- Anonim (publik) hanya bisa SELECT
- Authenticated bisa menjalankan RPC

### 3.4 — realtime.sql

Buka file `supabase/realtime.sql`, copy seluruh isi, paste ke SQL Editor, lalu Run.

Menambahkan tabel ke publikasi realtime agar perubahan langsung terlihat.

### 3.5 — seed.sql

Buka file `supabase/seed.sql`, copy seluruh isi, paste ke SQL Editor, lalu Run.

Mengisi data awal:
- 1 turnamen
- 7 area
- 56 tim (8 per area)
- 56 pertandingan (8 per area)

### 3.6 — verification.sql

Buka file `supabase/verification.sql`, copy seluruh isi, paste ke SQL Editor, lalu Run.

Menampilkan hasil verifikasi untuk memastikan semua data sudah benar.

> Jika ada error, periksa pesan error dan pastikan file dijalankan sesuai urutan.

## Langkah 4 — Buat User Admin

1. Di sidebar kiri, klik "Authentication"
2. Klik tab "Users"
3. Klik "Add User"
4. Masukkan:
   - **Email:** email admin yang valid (contoh: `admin@example.com`)
   - **Password:** password kuat (minimal 6 karakter)
5. Klik "Create user"
6. Simpan email dan password ini

> Jangan membuat akun melalui frontend aplikasi.

## Langkah 5 — Periksa Konfigurasi Auth

1. Di Authentication → Settings → General
2. Pastikan "Enable email confirmations" sesuai kebutuhan
3. Nonaktifkan "Allow new users to sign up" jika tidak ingin pendaftaran publik
4. Pastikan "Redirect URLs" sesuai domain GitHub Pages nantinya

## Langkah 6 — Salin Kredensial

1. Di sidebar kiri, klik "Project Settings" (ikon gigi)
2. Klik "API"
3. Salin:
   - **Project URL** (contoh: `https://abc123.supabase.co`)
   - **anon public key** (string panjang mulai `eyJ...`)

## Langkah 7 — Masukkan ke Config

Buka file `js/config.js`:

```javascript
export const APP_CONFIG = {
    supabaseUrl: "https://abc123.supabase.co",           // Ganti dengan Project URL
    supabasePublishableKey: "eyJhbGciOiJIUzI1NiIs...",  // Ganti dengan anon key
    adminEmail: "admin@example.com",                     // Ganti dengan email admin
    eventName: "PRE ONE DAY TURNAMENT KEP",
    timezone: "Asia/Jakarta"
};
```

## Langkah 8 — Uji Aplikasi

Jalankan aplikasi:

```bash
python -m http.server 8080
```

### Uji Publik

1. Buka http://localhost:8080
2. Pastikan 7 area tampil
3. Pastikan 56 tim dan 56 pertandingan ada

### Uji Admin

1. Buka http://localhost:8080/admin.html
2. Login dengan email dan password yang dibuat di Langkah 4
3. Masukkan nama operator
4. Pilih area
5. Ubah skor pertandingan
6. Klik simpan

### Uji Realtime

1. Buka `index.html` di tab lain
2. Buka `admin.html` di tab lain
3. Simpan skor dari admin
4. Pastikan halaman publik berubah tanpa reload

### Uji Keamanan

1. Buka Supabase SQL Editor
2. Jalankan:

```sql
-- Sebagai anon (tanpa login), coba INSERT
SET ROLE anon;
INSERT INTO matches (area_id, match_code, stage, display_order) VALUES (...);
-- Harus error: permission denied
```

## Catatan Penting

- `anon key` yang digunakan di frontend memang publishable — keamanan data bergantung pada RLS dan RPC
- `service_role key` **tidak boleh** digunakan di frontend
- Password admin **tidak boleh** disimpan di source code
- Jangan nonaktifkan RLS pada tabel mana pun
- Semua perubahan data harus melalui RPC, bukan direct table access



npx browser-sync start --server --files "**/*.html,**/*.css,**/*.js" --port 8080 --no-open