# Security — PRE ONE DAY TURNAMENT KEP

## Kebijakan Keamanan

### Kredensial di Frontend

File `js/config.js` berisi:
- **Supabase Project URL** — publik, diperlukan browser untuk terhubung
- **Supabase anon/publishable key** — publik, aman karena dibatasi RLS
- **Email admin** — publik, karena bukan rahasia (password yang dijaga)

### Yang Tidak Boleh Masuk Repository

- `service_role` key Supabase
- Password admin
- Database password
- Session token
- Access token

### Keamanan Data

Keamanan data bergantung pada:

1. **Row Level Security (RLS)** — semua tabel memiliki RLS aktif
2. **Pembatasan akses anon** — hanya bisa SELECT
3. **Database Functions (RPC)** — semua perubahan melalui RPC yang tervalidasi
4. **Optimistic Concurrency** — mencegah overwrite data
5. **Audit Log** — semua perubahan tercatat

### Best Practice

- Jangan nonaktifkan RLS
- Jangan berikan akses update langsung ke tabel
- Jangan gunakan `service_role` key di browser
- Jangan simpan password di localStorage
- Jangan log password atau token
- Jangan gunakan query string untuk data sensitif
- Gunakan `textContent` bukan `innerHTML` untuk data dari database

### Reporting

Jika menemukan celah keamanan, laporkan melalui issues repository GitHub.
