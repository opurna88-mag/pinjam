# Aturan Bisnis — Sistem Peminjaman Ruang FIP UM

**Versi:** 1.0
**Status:** Hasil keputusan pemangku kepentingan
**Dokumen terkait:** `SRS.md`, `DATABASE_DESIGN.md`, `API_SPEC.md`

Dokumen ini adalah **sumber kebenaran tunggal** untuk aturan bisnis. Setiap validasi (frontend, API Route, constraint database) WAJIB merujuk ke sini. Jika ada perubahan, ubah dokumen ini dulu, baru kode.

> Tanda `[ASUMSI]` berarti nilai belum dikonfirmasi resmi pihak FIP UM dan masih dapat berubah.

---

## 1. Kalender & Jam Operasional

### 1.1 Jam operasional per hari

| Hari | Jam Operasional | Keterangan |
|------|-----------------|------------|
| Senin | 07.00 – 16.00 WIB | Jam dinas |
| Selasa | 07.00 – 16.00 WIB | Jam dinas |
| Rabu | 07.00 – 16.00 WIB | Jam dinas |
| Kamis | 07.00 – 16.00 WIB | Jam dinas |
| **Jumat** | **07.00 – 14.30 WIB** | **Dipadatkan mengikuti jam dinas Jumat** |
| Sabtu | 07.00 – 16.00 WIB | Tetap buka |
| Minggu | 07.00 – 16.00 WIB | Tetap buka |

**Aturan turunan:**
- `start_time` tidak boleh sebelum jam buka dan `end_time` tidak boleh setelah jam tutup pada tanggal terkait.
- Slot **tidak boleh melintasi batas hari** (`start_time` dan `end_time` harus di tanggal yang sama).
- Zona waktu sistem: **Asia/Jakarta (WIB, UTC+7)**. Disimpan UTC, ditampilkan WIB.
- Hari libur nasional **belum** ditangani di versi ini (`[ASUMSI]`).

### 1.2 Lokasi penyimpanan aturan
Aturan disimpan di tabel `operating_hours` — **tidak di-hardcode** di banyak file.

| day_of_week | open_time | close_time |
|---|---|---|
| 1 (Senin) | 07:00 | 16:00 |
| 2 (Selasa) | 07:00 | 16:00 |
| 3 (Rabu) | 07:00 | 16:00 |
| 4 (Kamis) | 07:00 | 16:00 |
| **5 (Jumat)** | **07:00** | **14:30** |
| 6 (Sabtu) | 07:00 | 16:00 |
| 0 (Minggu) | 07:00 | 16:00 |

---

## 2. Aturan Durasi & Granularitas (FINAL — SUMBER TUNGGAL)

> 🔒 **KUNCI:** Tabel di bagian ini adalah **satu-satunya tempat** nilai-nilai berikut didefinisikan.
> Dokumen lain (`SRS.md`, `TERMS_AND_CONDITIONS.md`, `UI_UX_SPEC.md`, `API_SPEC.md`) **DILARANG** menyalin angka — wajib merujuk ke `BUSINESS_RULES.md` §2.
> Komponen kode juga **tidak boleh** hardcode: baca dari satu konstanta konfigurasi (`lib/booking-rules.ts`) yang bersumber dari tabel ini.
> Jika nilai berubah, cukup ubah tabel ini + konstanta tersebut. `TESTING_PLAN.md` wajib disesuaikan karena test case butuh nilai konkret.

| Parameter | Nilai | Catatan |
|-----------|-------|---------|
| Granularitas waktu | 30 menit | Slot mulai/berakhir pada kelipatan :00 atau :30 |
| Durasi minimum | 30 menit | |
| Durasi maksimum | 8 jam | Dipakai 8 jam agar ada jeda dari 07.00–16.00 |
| Jendela pengajuan minimum | H-1 | Paling lambat 1 hari sebelum tanggal acara |
| Jendela pengajuan maksimum | 30 hari ke depan | |
| Booking hari yang sama | Tidak boleh | Konsisten dengan aturan H-1 |
| Lintas hari (overnight) | Tidak boleh | |
| Beda aturan kelas vs aula | Tidak ada | Semua ruang sama |

**Pengecualian:** Admin **tidak** terikat aturan H-1, 30 hari, dan durasi maksimum — boleh booking darurat untuk hari yang sama.

---

## 3. Aturan Ketersediaan & Bentrok (Anti Double Booking)

### 3.1 Status yang MEMBLOKIR slot

| Status | Memblokir slot? |
|--------|-----------------|
| `pending` | **YA** |
| `approved` | **YA** |
| `rejected` | Tidak |
| `cancelled` | Tidak |
| `expired` | Tidak |

**Konsekuensi:** strategi **first-come-first-served**. Pengguna A yang mengajukan lebih dulu memblokir slot; Pengguna B langsung ditolak (`409 SLOT_UNAVAILABLE`). Admin dapat menolak booking A sehingga slot terbuka untuk B.

### 3.2 Rumus deteksi bentrok
Dua rentang `[a_start, a_end)` dan `[b_start, b_end)` **bentrok** jika:

```
a_start < b_end  AND  a_end > b_start
```

Rentang bersifat *half-open*: 10.00–11.00 dan 11.00–12.00 **tidak** bentrok.

### 3.3 Dua lapis proteksi (WAJIB keduanya)

**Lapis 1 — Database (otoritatif)**
Constraint `EXCLUDE USING gist` pada `bookings` memakai `tstzrange(start_time, end_time)` dengan predikat `WHERE status IN ('pending','approved')`. Kebal terhadap race condition request paralel.

**Lapis 2 — API Route (pesan error ramah)**
Sebelum insert, API melakukan `SELECT` cek bentrok untuk pesan spesifik ("Slot 10.00–12.00 sudah diajukan orang lain"). Jika lolos karena race, DB menolak dengan error `23P01` (`exclusion_violation`) → API mengembalikan `409`.

> ⚠️ Lapis 1 tidak boleh dilewati. Query `SELECT` saja tidak cukup — dua request paralel dapat sama-sama lolos pengecekan.

### 3.4 Kedaluwarsa otomatis `pending` — 72 jam
- Booking `pending` otomatis menjadi `expired` jika **72 jam (3 hari)** berlalu sejak `created_at` tanpa diproses admin.
- Slot kembali tersedia seketika status menjadi `expired`.
- Mekanisme: PostgreSQL function `expire_stale_bookings()` + `pg_cron` (tiap 10 menit) **dan** pemanggilan fungsi yang sama di awal query daftar/cek ketersediaan, agar UI tidak menampilkan data basi walau cron tertunda.
- Basis waktu adalah `created_at` (waktu pengajuan), **bukan** waktu acara.
- `[ASUMSI]` Booking yang waktu acaranya sudah lewat dan belum `approved` juga dianggap `expired`.

---

## 4. Registrasi & Autentikasi

### 4.1 Batasan domain email
- Registrasi **hanya** untuk domain: `um.ac.id`.
- Domain lain ditolak: *"Pendaftaran hanya untuk civitas akademika FIP UM. Gunakan email @um.ac.id."*
- Validasi di **dua tempat**: form registrasi (UX) dan Supabase Auth Hook / `POST /api/auth/register` (otoritatif).
- Daftar domain disimpan di env var `ALLOWED_EMAIL_DOMAINS` agar mudah diubah tanpa ubah kode.

### 4.2 Verifikasi & role
- Email harus diverifikasi sebelum dapat membuat booking (`email_confirmed_at` tidak null).
- Role default saat register: `student`. Role `lecturer`/`admin` hanya dapat diberikan admin.
- Tidak ada pilihan role saat register.

---

## 5. Hak Akses (Semua Role Setara untuk Peminjaman)

**Tidak ada perbedaan hak peminjaman antar role.** Mahasiswa, dosen, dan admin sama-sama boleh mengajukan booking.

| Parameter | Mahasiswa | Dosen | Admin |
|---|---|---|---|
| Ajukan booking | ✅ | ✅ | ✅ |
| Kuota booking aktif | Tak terbatas | Tak terbatas | Tak terbatas |
| Prioritas saat bentrok | Setara | Setara | Setara |
| Dikecualikan dari aturan H-1 | ❌ | ❌ | ✅ |
| Approve/reject booking | ❌ | ❌ | ✅ |
| Kelola ruang, fasilitas, galeri | ❌ | ❌ | ✅ |
| Kelola pengguna & role | ❌ | ❌ | ✅ |

Role dibedakan **hanya** untuk hak administratif (approval & master data), bukan hak peminjaman.

---

## 6. Alur Persetujuan (Approval)

### 6.1 Struktur approver
- **Satu level.** Semua akun dengan `profiles.role = 'admin'` berwenang dan **setara**.
- Tidak ada hierarki gedung atau super admin di versi ini.
- Admin mana pun dapat memproses booking mana pun.

### 6.2 Kewajiban alasan (`admin_note`)
- `admin_note` **WAJIB** (NOT NULL, minimal 5 karakter) baik saat **approve** maupun **reject**.
- Validasi API mengembalikan `422 ADMIN_NOTE_REQUIRED` jika kosong.
- `approved_by` dan `decided_at` terisi otomatis.

### 6.3 Transisi status yang diizinkan

```
pending  ──approve──> approved
pending  ──reject───> rejected
pending  ──cancel───> cancelled      (oleh pemilik)
pending  ──72 jam───> expired        (otomatis)
approved ─cancel────> cancelled      (oleh pemilik, maks H-1)

Transisi lain DITOLAK → 409 INVALID_STATUS_TRANSITION
```

### 6.4 SLA pemrosesan `[ASUMSI]`
Target admin memproses dalam 24 jam. Jika tidak diproses dalam 72 jam → otomatis `expired` (§3.4).

---

## 7. Pembatalan (Cancel) & Reschedule

| Aturan | Detail |
|---|---|
| Batal saat `pending` | ✅ Kapan saja |
| Batal saat `approved` | ✅ Maksimal **H-1** sebelum `start_time` |
| Batal pada hari H | ❌ `403 CANCELLATION_WINDOW_CLOSED` |
| Reschedule | ❌ Tidak ada fitur khusus — **batalkan** lalu **ajukan booking baru** |
| Sanksi no-show | ❌ Tidak ada sanksi |
| Pembatalan oleh admin | ✅ Kapan saja, `admin_note` wajib |

---

## 8. Field Wajib Pengajuan Peminjaman

| Field | Tipe | Wajib | Keterangan |
|---|---|---|---|
| `room_id` | uuid | ✅ | Ruangan yang dipinjam |
| `start_time` | timestamptz | ✅ | Tanggal + jam mulai |
| `end_time` | timestamptz | ✅ | Tanggal + jam selesai |
| `activity_name` | text | ✅ | Nama kegiatan (3–200 karakter) |
| `participant_count` | integer | ✅ | Harus ≤ `rooms.capacity` dan > 0 |
| `person_in_charge` | text | ✅ | Nama penanggung jawab (3–120 karakter) |
| `phone_number` | text | ✅ | Format Indonesia `^(\+62\|62\|0)8\d{7,12}$` |
| `terms_accepted` | boolean | ✅ | Harus `true` |

**Validasi tambahan:**
- `participant_count` > `rooms.capacity` → `422 CAPACITY_EXCEEDED`.
- `terms_accepted` tidak dicentang → `422 TERMS_NOT_ACCEPTED`.

---

## 9. Gerbang Syarat & Ketentuan (S&K)

- Setiap pengajuan **wajib** mencentang S&K; teks di `TERMS_AND_CONDITIONS.md`.
- Persetujuan direkam **per booking** di `bookings.terms_accepted_at` (bukan sekali per akun), karena isi S&K dapat berubah dan perlu jejak audit.
- Versi S&K yang disetujui direkam di `bookings.terms_version`.
- Halaman `/syarat-ketentuan` dapat diakses publik tanpa login.

---

## 10. Kalender Even (Transparansi Penuh)

- Kalender **dapat diakses publik tanpa login**.
- Ditampilkan per slot terisi: `activity_name`, `person_in_charge`, jam mulai/selesai, nama ruang, status (`pending`/`approved`).
- **TIDAK ditampilkan ke publik:** `phone_number`, `admin_note`. Hanya pemilik booking & admin.
- Tampilan: mode **bulanan** dan **mingguan**, filter per ruang atau semua ruang, modal "Detail Acara" saat slot diklik.

---

## 11. Galeri

- Galeri **publik**, tanpa login.
- Dua jenis konten: (1) **foto gedung/lingkungan FIP UM**, (2) **foto per ruang**.
- Hanya admin yang dapat upload/hapus foto.
- `[ASUMSI]` maks 5 foto per ruang, maks 2 MB per foto, format JPG/PNG/WebP.

---

## 12. Notifikasi

| Event | Email | WhatsApp | Penerima |
|---|---|---|---|
| Booking diajukan | ✅ | ✅ | Pemilik |
| Booking di-approve | ✅ | ✅ | Pemilik |
| Booking di-reject | ✅ | ✅ | Pemilik (+ alasan admin) |
| Booking expired 72 jam | ✅ | ✅ | Pemilik |
| Booking dibatalkan | ✅ | — | Pemilik |
| Booking masuk (pending) | ✅ | — | Semua admin |

- WhatsApp memakai nomor `bookings.phone_number`.
- Pengiriman **asinkron** (tidak memblokir respons API) dengan retry maksimal 3x.
- Kegagalan notifikasi **tidak boleh** menggagalkan transaksi booking — dicatat di tabel `notification_logs`.

---

## 13. Master Data

### 13.1 Ruang
- Data **15 ruang FIP** (AULA FIP, HALL GKB, AULA D4 Lt.1, AULA ORMAWA, R. RAPAT FIP, R. KONFREN D6.102, TALENT CENTER D6, R. INOVASI, R. UJIAN TESIS, R. UJIAN DISERTASI, R. SKRIPSI D6.403, R. SKRIPSI D6.408, R. BELAJAR S2/S3, PERPUSTAKAAN, GEDUNG B4 UPP 2) bersumber dari **`Daftar peminjaman ruang FIP.xlsx`**.
- Status: **TERSEDIA** di `docs/seed/rooms.csv` + `docs/seed/seed.sql`.
- ⚠️ **Kapasitas & lokasi adalah ESTIMASI** — file Excel tidak mencantumkannya. Wajib diverifikasi pihak FIP (`docs/seed/SEED_GUIDE.md` §2.1).
- Ruang dengan `is_active = false` tidak muncul di pencarian publik tapi tetap muncul di riwayat booking lama.

### 13.2 Fasilitas
- Disimpan di `room_facilities` (many-to-many ke `rooms`) dengan `UNIQUE(room_id, facility)`.
- Contoh: `AC`, `Proyektor`, `WiFi`, `Sound System`, `Papan Tulis`, `Mic`.

---

## 14. Checklist Validasi untuk Implementasi

```
[ ] User terautentikasi & email terverifikasi
[ ] terms_accepted === true
[ ] start_time < end_time
[ ] start_time dan end_time di tanggal (WIB) yang sama
[ ] Tanggal acara >= hari ini + 1 hari          (kecuali admin)
[ ] Tanggal acara <= hari ini + 30 hari          (kecuali admin)
[ ] start_time >= open_time hari tersebut
[ ] end_time   <= close_time hari tersebut      (Jumat: 14:30)
[ ] start_time & end_time kelipatan 30 menit
[ ] durasi >= 30 menit dan <= 8 jam             (maks tidak berlaku untuk admin)
[ ] participant_count <= rooms.capacity
[ ] Tidak ada booking pending/approved yang bentrok (cek API + EXCLUDE constraint DB)
[ ] room.is_active === true
```

---

## 15. Soal Terbuka / Menunggu Konfirmasi

| ID | Soal | Status |
|----|------|--------|
| BR-O1 | Granularitas & durasi min/maks | **FINAL — didefinisikan di §2** |
| BR-O2 | Jendela pengajuan | **FINAL — didefinisikan di §2** |
| BR-O3 | Hari libur nasional belum ditangani | `[ASUMSI]` |
| BR-O4 | Data ruang FIP | **TERJAWAB** — 15 ruang di `docs/seed/rooms.csv` (kapasitas masih estimasi) |
| BR-O5 | Batas maks foto & ukuran file galeri | `[ASUMSI]` |
| BR-O6 | Alasan wajib saat approve | Dikonfirmasi: ya, wajib |

---

*Versi 1.0 — disusun dari hasil keputusan pemangku kepentingan.*