# PRE ONE DAY TURNAMENT KEP

Aplikasi monitoring pertandingan futsal untuk event **PRE ONE DAY TURNAMENT KEP** dengan 7 area sistem gugur.

## Fitur Utama

- Monitoring publik 7 area dalam satu halaman
- Bracket sistem gugur (Perempat Final → Semifinal → Final/Perebutan Juara 3 → Podium)
- Input skor dan adu penalti
- Realtime update melalui Supabase Realtime
- Audit log setiap perubahan
- Optimistic concurrency (mencegah konflik data)
- Admin bersama dengan satu akun
- Mode display untuk layar event
- Responsive design (smartphone sampai 4K)

## Arsitektur

```
GitHub Pages
│
├── index.html    → Monitoring publik
├── admin.html    → Login dan admin
└── Supabase
    ├── PostgreSQL Database
    ├── Authentication
    ├── Row Level Security
    ├── Database Functions (RPC)
    └── Realtime
```

## Struktur Pertandingan

Setiap area memiliki 8 tim dengan sistem gugur:

| Babak | Kode | Pertandingan |
|-------|------|--------------|
| Perempat Final | QF1–QF4 | 4 pertandingan |
| Semifinal | SF1–SF2 | 2 pertandingan |
| Perebutan Juara 3 | TP | 1 pertandingan |
| Final | F | 1 pertandingan |

**Total:** 7 area × 8 pertandingan = **56 pertandingan**

## Struktur Folder

```
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

## Cara Menjalankan Lokal

```bash
python -m http.server 8080
```

Lalu buka http://localhost:8080

> Jangan membuka file `index.html` langsung dengan double-click karena ES Modules memerlukan server HTTP.

## Konfigurasi Supabase

Buka `SETUP_SUPABASE.md` untuk panduan lengkap.

Langkah singkat:

1. Buat project Supabase baru
2. Buka SQL Editor dan jalankan file secara urut:
   - `supabase/schema.sql`
   - `supabase/functions.sql`
   - `supabase/policies.sql`
   - `supabase/realtime.sql`
   - `supabase/seed.sql`
   - `supabase/verification.sql`
3. Buat satu user admin di Authentication
4. Salin Project URL dan anon key ke `js/config.js`
5. Masukkan email admin ke `adminEmail` di `js/config.js`

## Membuat Akun Admin

1. Buka Supabase Dashboard → Authentication → Users
2. Klik "Add User"
3. Masukkan email dan password kuat
4. Simpan
5. Masukkan email tersebut ke `js/config.js` → `adminEmail`

## Mengganti Config

Semua konfigurasi publik ada di `js/config.js`:

```javascript
export const APP_CONFIG = {
    supabaseUrl: "https://xxxxx.supabase.co",
    supabasePublishableKey: "eyJhbGciOi...",
    adminEmail: "admin@example.com",
    eventName: "PRE ONE DAY TURNAMENT KEP",
    timezone: "Asia/Jakarta"
};
```

## Deploy GitHub Pages

1. Push ke repository GitHub
2. Pastikan `.nojekyll` ada di root
3. Buka Settings → Pages
4. Pilih "Deploy from a branch"
5. Pilih branch `main`, folder `/root`
6. Simpan

Aplikasi akan tersedia di `https://username.github.io/pre-one-day-turnament-kep/`

## Cara Mengubah Nama Tim

1. Buka `admin.html`
2. Login dengan akun admin
3. Pilih area
4. Buka tab "NAMA TIM"
5. Ubah nama tim
6. Klik "Simpan" atau "Simpan Semua"

## Cara Memasukkan Skor

1. Buka `admin.html`
2. Login dan pilih area
3. Di tab "INPUT SKOR", masukkan skor
4. Pilih status (Belum Dimulai / Mulai / Selesai)
5. Jika skor seri dan status Selesai, masukkan skor penalti
6. Klik "SIMPAN"
7. Konfirmasi data

## Cara Memasukkan Penalti

1. Masukkan skor utama sama untuk kedua tim
2. Pilih status "SELESAI"
3. Input penalti akan muncul otomatis
4. Masukkan skor penalti (tidak boleh seri)
5. Klik "SIMPAN"

## Cara Reset Pertandingan

1. Buka tab "PENGATURAN"
2. Pilih pertandingan dari dropdown
3. "Reset Satu Pertandingan" untuk reset tanpa efek ke bawah
4. "Reset & Downstream" untuk reset beserta pertandingan turunan

## Cara Melihat Audit Log

1. Buka tab "RIWAYAT"
2. Lihat perubahan terbaru (maksimal 30)

## Troubleshooting

**Data tidak muncul:** Pastikan konfigurasi Supabase di `js/config.js` sudah benar.

**Login gagal:** Pastikan akun admin sudah dibuat di Supabase Authentication.

**Realtime tidak berjalan:** Pastikan tabel sudah ditambahkan ke publikasi realtime.

**ES Modules error:** Jalankan aplikasi melalui HTTP server (bukan file://).

## Keamanan Dasar

- Jangan commit `service_role` key ke repository
- Jangan commit password admin ke repository
- Jangan nonaktifkan RLS
- Jangan berikan akses publik ke `admin.html`
- Gunakan password yang kuat untuk akun admin
