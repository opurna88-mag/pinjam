# SRS — Spesifikasi Kebutuhan Perangkat Lunak
## Sistem Peminjaman Ruang Digital (FIP UM)

**Versi:** 1.1
**Status:** Disetujui untuk implementasi
**Dokumen acuan wajib:** `BUSINESS_RULES.md`, `DATABASE_DESIGN.md`, `API_SPEC.md`, `UI_UX_SPEC.md`, `TERMS_AND_CONDITIONS.md`, `TESTING_PLAN.md`

## 0. Perubahan dari Versi 1.0

| # | Perubahan |
|---|---|
| 1 | **TAMBAH** modul publik: Halaman Landing/Home, Galeri, Syarat & Ketentuan, Kalender Even publik (F7–F10) |
| 2 | **UBAH** cek ketersediaan menjadi **dapat diakses publik tanpa login** (F3.2) |
| 3 | **TAMBAH** batasan registrasi hanya email kampus `@um.ac.id` (F1.1) |
| 4 | **TAMBAH** aturan jam operasional per hari — Jumat 07.00–14.30 (BR §1) |
| 5 | **TAMBAH** aturan durasi, granularitas, jendela pengajuan (BR §2) |
| 6 | **TAMBAH** status `expired` + auto-expired (batas waktu: `BUSINESS_RULES.md` §3.4) |
| 7 | **TAMBAH** field form booking: nama kegiatan, jumlah peserta, PJ, no. HP (F4.1, BR §8) |
| 8 | **TAMBAH** gerbang S&K per booking (F4.5) |
| 9 | **UBAH** alasan admin **wajib** saat approve **dan** reject (F5.2) |
| 10 | **TAMBAH** notifikasi Email + WhatsApp (F11) |
| 11 | **UBAH** kebijakan cancel: boleh saat pending/approved, selama dalam batas pembatalan (F4.4, BR §7) |
| 12 | **HAPUS** batasan kuota & prioritas role — semua role setara untuk peminjaman (BR §5) |

---

## 1. Pendahuluan

### 1.1 Tujuan Dokumen
Dokumen ini adalah **source of truth** untuk tim pengembangan. Semua fitur yang dibangun harus merujuk ke SRS ini. Fitur baru harus ditambahkan ke SRS terlebih dahulu sebelum diimplementasikan. Tujuan: mencegah *scope creep* dan mengurangi risiko hallucination AI dalam pembuatan kode.

### 1.2 Ruang Lingkup
Sistem web untuk peminjaman ruang kelas/aula FIP UM, akses melalui browser desktop & mobile. Mencakup halaman publik (informasi, galeri, S&K, cek ketersediaan, kalender) serta area terautentikasi (pengajuan, riwayat, dashboard admin).

---

## 2. Deskripsi Umum

### 2.1 Perspektif Produk
Aplikasi web mandiri berbasis Next.js App Router, terintegrasi Supabase (Auth + PostgreSQL + Storage), dideploy di Vercel.

### 2.2 Kelas Pengguna

| Kelas | Deskripsi |
|-------|-----------|
| **Pengunjung (publik)** | Tanpa login. Dapat melihat Home, Galeri, S&K, daftar ruang, cek ketersediaan, kalender even. |
| **Mahasiswa / Dosen** | Login. Dapat mengajukan booking, membatalkan, melihat riwayat. |
| **Admin** | Login. Dapat approve/reject, kelola ruang, fasilitas, galeri, pengguna. |

> **Catatan penting:** mahasiswa, dosen, dan admin memiliki **hak peminjaman yang setara** — tanpa kuota, tanpa prioritas. Role hanya membedakan hak administratif.

### 2.3 Batasan
- Tidak ada pembayaran online.
- Tidak ada integrasi LDAP/SSO kampus; registrasi dibatasi domain email.
- Data disimpan di Supabase Cloud.
- Hari libur nasional belum ditangani (`[ASUMSI]`).

---

## 3. Kebutuhan Fungsional

### 3.1 Autentikasi (Auth)

| ID | Fitur | Deskripsi | Prioritas |
|----|-------|-----------|-----------|
| F1.1 | Register | Daftar dengan email **hanya** berdomain `@um.ac.id` + password + nama lengkap. Domain lain ditolak. | Wajib |
| F1.2 | Login | Masuk dengan email & password. | Wajib |
| F1.3 | Logout | Keluar dari sesi. | Wajib |
| F1.4 | Reset Password | Reset via email. | Wajib |
| F1.5 | Role Based Access | Admin vs user dibedakan untuk hak administratif (RLS). | Wajib |
| F1.6 | Verifikasi Email | Email wajib diverifikasi sebelum dapat mengajukan booking. | Wajib |
| F1.7 | Rate Limit | Register maks 3x/menit per IP. | Wajib |

### 3.2 Manajemen Ruang (Admin)

| ID | Fitur | Deskripsi | Prioritas |
|----|-------|-----------|-----------|
| F2.1 | Tambah Ruang | Nama, kode, kapasitas, lokasi, deskripsi, fasilitas. | Wajib |
| F2.2 | Edit Ruang | Ubah data ruang. | Wajib |
| F2.3 | Nonaktifkan/Hapus Ruang | Nonaktifkan (`is_active=false`) atau hapus jika belum ada booking. | Wajib |
| F2.4 | Daftar Ruang | Melihat semua ruang (termasuk nonaktif). | Wajib |
| F2.5 | Kelola Fasilitas | Atur daftar fasilitas per ruang (tanpa duplikat). | Wajib |

### 3.3 Halaman Publik & Cek Ketersediaan

| ID | Fitur | Deskripsi | Prioritas |
|----|-------|-----------|-----------|
| F3.1 | Cari Ruang | Cari berdasarkan nama/kode/lokasi/kapasitas. **Tanpa login.** | Wajib |
| F3.2 | Cek Ketersediaan (**PUBLIK**) | Pengunjung memilih rentang waktu dan melihat ruang mana yang tersedia/tidak. **Tanpa login.** | Wajib |
| F3.3 | Detail Ruang | Foto (multi), kapasitas, fasilitas, lokasi, status. | Wajib |
| F3.4 | Widget Cek Ketersediaan di Home | 3 input: jam mulai, jam selesai, pilih ruangan + tombol cek. | Wajib |
| F3.5 | Panel Hasil | Dua panel: "Ruangan Tersedia" & "Ruangan Tidak Tersedia" (dengan alasan). | Wajib |

### 3.4 Peminjaman (Booking)

| ID | Fitur | Deskripsi | Prioritas |
|----|-------|-----------|-----------|
| F4.1 | Buat Booking | Field wajib: ruang, tanggal, jam mulai, jam selesai, nama kegiatan, jumlah peserta, PJ, no. HP. | Wajib |
| F4.2 | Validasi Bentrok | Tolak jika slot ditempati booking `pending`/`approved`. Dijaga API **dan** constraint DB. | Wajib |
| F4.3 | Status Booking | `pending`, `approved`, `rejected`, `cancelled`, **`expired`**. | Wajib |
| F4.4 | Batalkan Booking | Boleh saat `pending` kapan saja; saat `approved` selama masih dalam batas pembatalan (`BUSINESS_RULES.md` §7). Hari H ditolak. | Wajib |
| F4.5 | Persetujuan S&K | Wajib mencentang S&K; rekam `terms_accepted_at` + `terms_version`. | Wajib |
| F4.6 | Validasi Jam Operasional | Tolak di luar jam operasional (Jumat tutup **14.30**). | Wajib |
| F4.7 | Validasi Durasi & Granularitas | Sesuai `BUSINESS_RULES.md` §2 (sumber tunggal — jangan hardcode angka di SRS). | Wajib |
| F4.8 | Validasi Jendela Pengajuan | Sesuai `BUSINESS_RULES.md` §2. Admin dikecualikan. | Wajib |
| F4.9 | Validasi Kapasitas | Jumlah peserta ≤ kapasitas ruang. | Wajib |
| F4.10 | Auto-Expired | Booking `pending` yang melewati batas kedaluwarsa → otomatis `expired` (`BUSINESS_RULES.md` §3.4). | Wajib |
| F4.11 | Rate Limit | Maks 5 booking/menit per user. | Wajib |

### 3.5 Persetujuan (Approval)

| ID | Fitur | Deskripsi | Prioritas |
|----|-------|-----------|-----------|
| F5.1 | Daftar Booking Masuk | Admin melihat semua booking, filter status/ruang/tanggal. | Wajib |
| F5.2 | Setujui / Tolak | Ubah status + **alasan wajib** (min 5 karakter) untuk approve **dan** reject. | Wajib |
| F5.3 | Jejak Keputusan | Rekam `approved_by` dan `decided_at`. | Wajib |
| F5.4 | Hitung Mundur Kedaluwarsa | Tampilkan sisa waktu sebelum kedaluwarsa pada detail booking. | Opsional |

### 3.6 Riwayat Peminjaman (User)

| ID | Fitur | Deskripsi | Prioritas |
|----|-------|-----------|-----------|
| F6.1 | Lihat Riwayat | Semua booking milik user + status terkini + alasan admin. | Wajib |
| F6.2 | Detail Booking | Rincian lengkap + tombol batal bila memenuhi syarat. | Wajib |

### 3.7 Halaman Landing / Home (PUBLIK)

| ID | Fitur | Deskripsi | Prioritas |
|----|-------|-----------|-----------|
| F7.1 | Hero + Widget | Judul, subjudul, dan widget cek ketersediaan. | Wajib |
| F7.2 | Cuplikan Ruang | Grid kartu ruang unggulan / terbaru. | Wajib |
| F7.3 | Cuplikan Kalender | Kalender even bulan berjalan. | Wajib |
| F7.4 | Navigasi Publik | Home, Galeri, S&K, Kalender, Login/Register. | Wajib |
| F7.5 | Footer | Alamat, kontak, tautan S&K. | Wajib |

### 3.8 Galeri (PUBLIK)

| ID | Fitur | Deskripsi | Prioritas |
|----|-------|-----------|-----------|
| F8.1 | Galeri Lingkungan | Foto gedung/lingkungan FIP UM. | Wajib |
| F8.2 | Galeri Ruang | Multi-foto per ruang + carousel di detail ruang. | Wajib |
| F8.3 | Upload Foto (Admin) | Admin upload/hapus foto; maks 2 MB, JPG/PNG/WebP `[ASUMSI]`. | Wajib |
| F8.4 | Lightbox | Tampilan foto layar penuh. | Opsional |

### 3.9 Syarat & Ketentuan (PUBLIK)

| ID | Fitur | Deskripsi | Prioritas |
|----|-------|-----------|-----------|
| F9.1 | Halaman S&K | `/syarat-ketentuan` dapat diakses tanpa login. | Wajib |
| F9.2 | Versi S&K | S&K memiliki nomor versi yang direkam pada setiap booking. | Wajib |

### 3.10 Kalender Even (PUBLIK)

| ID | Fitur | Deskripsi | Prioritas |
|----|-------|-----------|-----------|
| F10.1 | Kalender Publik | Dapat diakses tanpa login. | Wajib |
| F10.2 | Mode Bulanan & Mingguan | Navigasi antar periode. | Wajib |
| F10.3 | Filter Ruang | Filter per ruang atau semua ruang. | Wajib |
| F10.4 | Detail Acara | Modal berisi nama kegiatan, PJ, ruang, jam, status. | Wajib |
| F10.5 | Privasi | **Tidak** menampilkan no. HP, catatan admin, email pemilik. | Wajib |

### 3.11 Notifikasi

| ID | Fitur | Deskripsi | Prioritas |
|----|-------|-----------|-----------|
| F11.1 | Email | Notifikasi pengajuan, approve, reject, expired, cancel. | Wajib |
| F11.2 | WhatsApp | Notifikasi ke nomor peminjam untuk event yang sama. | Wajib |
| F11.3 | Email ke Admin | Notifikasi booking baru masuk. | Wajib |
| F11.4 | Asinkron & Retry | Pengiriman tidak memblokir transaksi; retry maks 3x; kegagalan dicatat. | Wajib |

---

## 4. Kebutuhan Non-Fungsional

| ID | Kategori | Deskripsi |
|----|----------|-----------|
| NF1 | Keamanan | Password di-hash Supabase Auth. RLS mencegah user mengakses data orang lain. Service key hanya server-side. |
| NF2 | Kinerja | LCP < 2.5 detik pada 4G; `GET /api/rooms/available` < 800ms untuk 100 ruang. |
| NF3 | Kompatibilitas | Responsive desktop & mobile (Chrome, Safari, Edge terbaru). |
| NF4 | Ketersediaan | Sistem berjalan 24/7 kecuali maintenance Supabase/Vercel. |
| NF5 | Skalabilitas | Minimal 100 ruang dan 1.000 booking aktif. |
| NF6 | Privasi | `phone_number` & `admin_note` tidak pernah keluar lewat endpoint publik. |
| NF7 | Aksesibilitas | WCAG 2.1 level AA; kontras ≥ 4.5:1. |
| NF8 | Rate Limiting | Diterapkan pada endpoint publik & mutasi (lihat `API_SPEC.md` §1.4). |
| NF9 | Auditabilitas | Keputusan admin, versi S&K, dan log notifikasi tersimpan. |

---

## 5. Antarmuka Eksternal

| Antarmuka | Deskripsi |
|-----------|-----------|
| Supabase Auth | Login, register, session, verifikasi email, reset password. |
| Supabase Database | PostgreSQL + RLS + `pg_cron`. |
| Supabase Storage | Bucket `room-images` & `gallery`. |
| Supabase Edge/Hook | Validasi domain email saat signup. |
| SMTP / Resend | Pengiriman email notifikasi. |
| WhatsApp Gateway | Pengiriman notifikasi WhatsApp (provider via env var). |
| Vercel | Hosting, deployment otomatis, Vercel Cron. |

---

## 6. Use Case Singkat

**Pengunjung (tanpa login):**
1. Buka Home → isi widget cek ketersediaan (jam mulai, jam selesai, ruangan) → lihat hasil tersedia/tidak.
2. Jelajahi Galeri & Kalender Even untuk melihat kegiatan yang sudah dijadwalkan.
3. Baca Syarat & Ketentuan.

**User flow peminjaman:**
1. Login (email kampus) → pilih ruang → pilih tanggal & jam (dibatasi jam operasional hari tersebut) → isi field kegiatan → centang S&K → ajukan.
2. Status `pending`; menerima notifikasi email + WhatsApp.
3. Pantau status di riwayat; batal bila perlu (selama masih dalam batas pembatalan untuk yang sudah approved).

**Admin flow persetujuan:**
1. Login → dashboard: lihat booking `pending` beserta hitung mundur kedaluwarsa.
2. Buka detail → isi alasan (wajib) → Setujui / Tolak.
3. User menerima notifikasi Email + WhatsApp berisi keputusan & alasan.

**Sistem (otomatis):**
1. Setiap 10 menit: booking `pending` yang melewati batas kedaluwarsa → `expired`, slot bebas (nilai batas: `BUSINESS_RULES.md` §3.4).
2. Notifikasi terkirim asinkron dengan retry maks 3x.

---

## 7. Kriteria Penerimaan (Acceptance Criteria)

- [ ] Registrasi dengan email di luar `@um.ac.id` **ditolak**.
- [ ] Pengunjung tanpa login dapat melihat hasil cek ketersediaan dan kalender.
- [ ] Booking ditolak bila di luar jam operasional; khusus **Jumat setelah 14.30 ditolak**.
- [ ] Booking ditolak bila durasi tidak sesuai ketentuan (`BUSINESS_RULES.md` §2).
- [ ] User dapat membuat booking pada slot yang tersedia dan menerima status `pending`.
- [ ] Sistem mencegah double booking, termasuk pada request paralel (constraint DB terbukti aktif).
- [ ] Booking `pending` yang melewati batas kedaluwarsa otomatis menjadi `expired` dan slot kembali tersedia (batas: `BUSINESS_RULES.md` §3.4).
- [ ] Admin **tidak bisa** approve/reject tanpa mengisi alasan.
- [ ] User dapat melihat status (pending/approved/rejected/cancelled/expired) beserta alasan admin.
- [ ] User dapat membatalkan booking `pending` kapan saja dan `approved` selama masih dalam batas pembatalan (`BUSINESS_RULES.md` §7).
- [ ] Halaman Galeri menampilkan foto lingkungan kampus dan foto per ruang.
- [ ] Halaman Syarat & Ketentuan dapat diakses publik.
- [ ] Kalender publik menampilkan nama kegiatan & PJ, **tidak** menampilkan no. HP.
- [ ] Notifikasi Email dan WhatsApp terkirim untuk pengajuan & keputusan admin.
- [ ] Aplikasi dapat diakses melalui URL publik setelah deploy.

---

## 8. Soal Terbuka

| ID | Soal | Status |
|----|------|--------|
| SRS-O1 | Granularitas, durasi, jendela pengajuan | **FINAL** — mengikuti `BUSINESS_RULES.md` §2 |
| SRS-O2 | Data 15 ruang FIP (kapasitas & fasilitas) | **TERJAWAB** — lihat `docs/seed/rooms.csv` |
| SRS-O3 | Hari libur nasional | `[ASUMSI]` belum ditangani |
| SRS-O4 | Provider WhatsApp & SMTP | Perlu dipilih |
| SRS-O5 | Batas ukuran foto galeri | `[ASUMSI]` 2 MB / maks 5 foto per ruang |

---

*Catatan: dokumen ini harus diperbarui setiap kali ada perubahan fitur. Tim pengembangan dilarang menambahkan fitur yang tidak tercatat di SRS tanpa persetujuan atasan.*

*Versi 1.1 — perubahan dari 1.0 dirangkum di §0.*