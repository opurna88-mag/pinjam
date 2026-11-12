# PROYEK: SISTEM PEMINJAMAN RUANG DIGITAL (Versi Rekayasa)

**Versi:** 1.1

## 0. Perubahan dari Versi 1.0

| # | Perubahan |
|---|---|
| 1 | Lingkup diperluas menjadi **replika penuh** — termasuk Landing, Galeri, Syarat & Ketentuan, Kalender Even publik, cek ketersediaan publik |
| 2 | Registrasi dibatasi email kampus `@um.ac.id` |
| 3 | Ditambahkan notifikasi **Email + WhatsApp** |
| 4 | Ditambahkan aturan jam operasional per hari (**Jumat 07.00–14.30**) |
| 5 | Ditambahkan auto-expired booking `pending` (nilai batas: `BUSINESS_RULES.md` §3.4) |
| 6 | Kuota & prioritas role dihapus — semua role setara untuk peminjaman |
| 7 | Timeline diperpanjang dari 4 menjadi **5 minggu** |

---

## 1. Latar Belakang
Peminjaman ruang di FIP UM masih dilakukan secara konvensional (antrian langsung, catatan manual, atau aplikasi lama yang terbatas). Sistem baru dibangun untuk mempercepat proses peminjaman, menghindari bentrok jadwal (*double booking*), serta memberikan transparansi status persetujuan kepada peminjam.

---

## 2. Tujuan
1. Membuat sistem peminjaman ruang berbasis web yang dapat diakses kapan saja.
2. Meminimalkan bentrok jadwal melalui validasi ketersediaan *real-time* yang dijaga di level database.
3. Menyediakan dashboard admin untuk menyetujui atau menolak peminjaman.
4. Memberikan transparansi penggunaan ruang melalui kalender publik.
5. Membangun sistem yang mudah dipelihara oleh tim kecil (2 orang developer).

---

## 3. Ruang Lingkup

**A. Halaman Publik (tanpa login)**
- Landing/Home dengan widget **Cek Ketersediaan Ruang**
- Galeri foto gedung/lingkungan FIP UM + foto per ruang
- Halaman **Syarat & Ketentuan**
- Daftar & detail ruang (foto, kapasitas, fasilitas)
- **Kalender Even** publik (bulanan/mingguan, filter ruang, modal detail acara)

**B. Autentikasi**
- Login, register (**hanya email kampus** `@um.ac.id`), reset password, verifikasi email

**C. Peminjaman**
- Form pengajuan: ruang, tanggal, jam mulai/selesai, nama kegiatan, jumlah peserta, PJ, no. HP
- Validasi jam operasional (Jumat tutup 14.30), durasi, granularitas, jendela pengajuan
- Persetujuan **Syarat & Ketentuan** (direkam per booking)
- Validasi bentrok dua lapis (API + constraint DB)
- Auto-expired booking `pending` yang tidak diproses admin (nilai batas: `BUSINESS_RULES.md` §3.4)

**D. Persetujuan & Riwayat**
- Admin approve/reject dengan **alasan wajib**
- Riwayat & status peminjaman pribadi, pembatalan (selama dalam batas pembatalan)

**E. Admin**
- Kelola ruang, fasilitas, galeri, pengguna & role
- Dashboard statistik peminjaman

**F. Notifikasi**
- Email **dan** WhatsApp untuk pengajuan, keputusan, kedaluwarsa, pembatalan

**Di luar lingkup (v2):**
- Pembayaran online
- QR Code validasi kehadiran
- Integrasi SSO/LDAP kampus
- Manajemen hari libur nasional
- Sanksi otomatis no-show

---

## 4. Metodologi Pengembangan
Pendekatan **Agile sederhana** dengan 3 sprint:

- **Sprint 1** — Setup, Auth (domain email), CRUD Ruang & Fasilitas, halaman publik dasar (Home, Daftar Ruang, Detail Ruang)
- **Sprint 2** — Widget cek ketersediaan, form peminjaman + seluruh validasi bisnis, constraint anti double-booking, riwayat user
- **Sprint 3** — Dashboard admin, approval, kalender even, galeri, S&K, notifikasi email+WhatsApp, auto-expire booking `pending`
- **Sprint 4** — Testing (unit/integration/E2E), UAT dengan FIP UM, deploy, dokumentasi, handover

## 5. Teknologi yang Digunakan

| Layer | Teknologi | Alasan |
|-------|-----------|--------|
| Frontend | Next.js (App Router) + TypeScript | Satu bahasa, SEO-friendly, cepat dikembangkan |
| Styling | Tailwind CSS + shadcn/ui | UI responsive, komponen siap pakai |
| Backend / API | Next.js Route Handlers + Zod | Fullstack satu proyek, validasi konsisten |
| Database | Supabase (PostgreSQL) | Relasional, RLS, `pg_cron`, constraint `EXCLUDE` |
| Auth | Supabase Auth | Siap pakai, mendukung verifikasi email |
| Storage | Supabase Storage | Foto galeri & ruang |
| Notifikasi | SMTP/Resend + WhatsApp Gateway | Email + WA |
| Deployment | Vercel | Gratis, CI/CD otomatis |

---

## 6. Anggota Tim
- Developer 1: Frontend & UI/UX
- Developer 2: Backend & Database
(Keduanya berbagi tanggung jawab pada integrasi dan testing)

---

## 7. Timeline Estimasi

| Minggu | Aktivitas |
|--------|-----------|
| 1 | Setup proyek, skema DB + RLS, Auth dengan domain email, halaman publik dasar |
| 2 | Widget cek ketersediaan publik, form peminjaman, validasi bisnis, anti double-booking |
| 3 | Riwayat user, dashboard admin, approval, kalender even, galeri, S&K |
| 4 | Notifikasi email + WhatsApp, auto-expire booking `pending`, testing |
| 5 | UAT dengan FIP UM, perbaikan bug, dokumentasi, deploy, handover |

---

## 8. Biaya Estimasi

| Komponen | Estimasi |
|---|---|
| Domain & hosting (Vercel) | Gratis |
| Supabase (tier gratis) | Gratis; Pro ~USD 25/bln jika perlu `pg_cron` intensif & storage lebih besar |
| SMTP/Resend | Gratis s.d. 3.000 email/bln, lalu berbayar |
| WhatsApp gateway | ± Rp 100.000 – Rp 300.000/bln |
| **Total operasional awal** | **± Rp 0 – Rp 400.000/bulan** |

---

## 9. Risiko & Mitigasi

| Risiko | Mitigasi |
|---|---|
| Race condition double booking | Constraint `EXCLUDE USING gist` di database (bukan hanya validasi API) |
| Data 40 ruang belum tersedia | Seed 3 ruang untuk development; data final diinput admin |
| Aturan durasi belum final | Ditandai `[ASUMSI]` di dokumen; mudah diubah lewat konfigurasi |
| Provider WhatsApp berubah kebijakan | Abstraksi di `lib/notifications/whatsapp.ts` |
| Cron terlambat berjalan | Fungsi expire juga dipanggil saat request ketersediaan |
| Email/WA gagal terkirim | Retry maks 3x + `notification_logs`, tidak menggagalkan booking |

---

## 10. Hasil yang Diharapkan
1. Aplikasi web peminjaman ruang yang terdeploy dan dapat diakses publik.
2. Halaman publik (Home, Galeri, S&K, Kalender) yang informatif.
3. Dokumentasi teknis lengkap: `SRS`, `ARCHITECTURE`, `DATABASE_DESIGN`, `API_SPEC`, `UI_UX_SPEC`, `BUSINESS_RULES`, `TERMS_AND_CONDITIONS`, `TESTING_PLAN`, `README_DEV`.
4. Laporan progres mingguan bagi atasan.

---

*Disusun oleh: Tim Pengembangan Sistem Peminjaman Ruang*
*Versi 1.1*