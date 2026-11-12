# Rencana Pengujian (Testing Plan) — Sistem Peminjaman Ruang FIP UM

**Versi:** 1.0
**Dokumen acuan:** `BUSINESS_RULES.md`, `API_SPEC.md`, `SRS.md`

---

## 1. Strategi Pengujian

| Level | Alat | Cakupan |
|---|---|---|
| Unit test | **Vitest** | Fungsi validasi murni (`lib/validations/*`), formatter WIB, kalkulasi durasi |
| Integration test | **Vitest** + Supabase lokal | Route Handler + DB constraint (termasuk uji bebas bentrok) |
| E2E test | **Playwright** | Alur pengguna lintas halaman & lintas role |
| Manual / UAT | Checklist | Verifikasi dengan pihak FIP UM sebelum go-live |

**Lingkungan:** Supabase lokal (`supabase start`) untuk otomatis, staging untuk E2E.
**Data seed minimum:** 3 ruang (1 aula kapasitas 200, 2 kelas kapasitas 40), 3 user (student, lecturer, admin).

> 🔒 **Catatan nilai numerik:** test case di bawah **wajib** memakai angka konkret agar dapat diuji. Seluruh angka tersebut adalah **implementasi** dari `BUSINESS_RULES.md` §2 (bukan definisi baru). Bila §2 berubah, test case di bagian 2.2, 2.4, dan 2.6 **harus** disesuaikan. Dokumen lain (`SRS`, `API_SPEC`, `UI_UX_SPEC`, `TERMS_AND_CONDITIONS`) sengaja tidak memuat angka — hanya dokumen ini dan `BUSINESS_RULES.md` yang boleh.

---

## 2. Matriks Test Case Fungsional

### 2.1 Autentikasi (F1)

| ID | Skenario | Input | Ekspektasi |
|---|---|---|---|
| TC-AUTH-01 | Register email kampus `@um.ac.id` | `budi@um.ac.id` | 201, profil dibuat, role `student` |
| TC-AUTH-02 | Register email subdomain kampus | `siti@student.um.ac.id` | 201 (suffix `um.ac.id` cocok) |
| TC-AUTH-03 | Register email GMAIL | `budi@gmail.com` | **403 `EMAIL_DOMAIN_NOT_ALLOWED`** |
| TC-AUTH-04 | Domain mirip (evil suffix) | `budi@um.ac.id.evil.com` | 403 (suffix matching, bukan `contains`) |
| TC-AUTH-05 | Register password lemah | `12345678` | 400 `VALIDATION_ERROR` |
| TC-AUTH-06 | Login kredensial benar | — | 200 + cookie sesi |
| TC-AUTH-07 | Login password salah | — | 401 `UNAUTHENTICATED` |
| TC-AUTH-08 | Booking sebelum verifikasi email | `email_confirmed_at` null | 401 `EMAIL_NOT_VERIFIED` |
| TC-AUTH-09 | Reset password | email terdaftar | 200 (link terkirim) |
| TC-AUTH-10 | Akses `/admin` sebagai student | — | 403 / redirect |
| TC-AUTH-11 | Register 4x dalam 1 menit | — | Request ke-4 → 429 `RATE_LIMITED` |

### 2.2 Jam Operasional & Aturan Waktu

| ID | Skenario | Input | Ekspektasi |
|---|---|---|---|
| TC-TIME-01 | Booking Senin 08.00–10.00 | hari kerja | 201 |
| TC-TIME-02 | Booking Senin 15.00–17.00 | lewat tutup | **422 `OUTSIDE_OPERATING_HOURS`** |
| TC-TIME-03 | Booking Jumat 13.00–15.00 | lewat 14.30 | **422 `OUTSIDE_OPERATING_HOURS`** |
| TC-TIME-04 | Booking Jumat 07.00–14.30 | tepat batas | 201 (inclusive) |
| TC-TIME-05 | Booking Jumat 14.30–15.00 | mulai tepat tutup | 422 |
| TC-TIME-06 | Booking Sabtu 09.00–11.00 | weekend buka | 201 |
| TC-TIME-07 | Booking Minggu 09.00–11.00 | weekend buka | 201 |
| TC-TIME-08 | Jam mulai sebelum 07.00 | 06.00 | 422 `OUTSIDE_OPERATING_HOURS` |
| TC-TIME-09 | Granularitas tidak valid | 08.15–09.15 | 422 `INVALID_GRANULARITY` |
| TC-TIME-10 | Durasi 30 menit (minimum) | 08.00–08.30 | 201 |
| TC-TIME-11 | Durasi > maks 8 jam | 07.00–16.00 (9 jam) | **422 `INVALID_DURATION`** |
| TC-TIME-12 | Lintas hari | 10 Mar 15.00 → 11 Mar 08.00 | 422 `VALIDATION_ERROR` |
| TC-TIME-13 | `end_time` < `start_time` | 10.00–09.00 | 400 `VALIDATION_ERROR` |
| TC-TIME-14 | Booking hari ini (user) | hari H | 422 `BOOKING_WINDOW_INVALID` |
| TC-TIME-15 | Booking hari ini (admin) | hari H | 201 (admin dikecualikan) |
| TC-TIME-16 | Booking H+31 | > 30 hari | 422 `BOOKING_WINDOW_INVALID` |
| TC-TIME-17 | Booking H+30 | tepat batas | 201 |

### 2.3 Anti Double Booking

| ID | Skenario | Ekspektasi |
|---|---|---|
| TC-DB-01 | Dua booking `approved` slot sama | Request ke-2 → **409 `SLOT_UNAVAILABLE`** |
| TC-DB-02 | Booking `pending` lalu user lain slot sama | Request ke-2 → **409** (pending memblokir) |
| TC-DB-03 | Slot `rejected`, user lain ajukan | 201 (tidak memblokir) |
| TC-DB-04 | Slot `cancelled`, user lain ajukan | 201 |
| TC-DB-05 | Slot `expired`, user lain ajukan | 201 |
| TC-DB-06 | Bersambung: 07.00–09.00 lalu 09.00–11.00 | Keduanya 201 (half-open) |
| TC-DB-07 | Overlap sebagian: 07.00–09.00 lalu 08.00–10.00 | Ke-2 → 409 |
| TC-DB-08 | Ruang berbeda, slot sama | Keduanya 201 |
| TC-DB-09 | **Race condition**: 2 request paralel slot sama | **Hanya 1 berhasil**, 1 gagal 409 |
| TC-DB-10 | Bypass API: insert langsung via SQL | Ditolak `EXCLUDE` constraint (`23P01`) |

### 2.4 Auto-Expired 72 Jam

| ID | Skenario | Ekspektasi |
|---|---|---|
| TC-EXP-01 | Booking dibuat, waktu dimajukan 71 jam | Masih `pending` |
| TC-EXP-02 | Waktu dimajukan 73 jam, cron dijalankan | Status → `expired` |
| TC-EXP-03 | Slot dari booking `expired` diajukan user lain | 201 (slot bebas) |
| TC-EXP-04 | Cron tidak jalan, `/api/rooms/available` dipanggil | Booking stale ikut di-expire |
| TC-EXP-05 | Booking `approved` berumur > 72 jam | **Tidak** berubah jadi `expired` |

### 2.5 Approval

| ID | Skenario | Ekspektasi |
|---|---|---|
| TC-APR-01 | Admin approve tanpa `admin_note` | **422 `ADMIN_NOTE_REQUIRED`** |
| TC-APR-02 | Admin reject tanpa `admin_note` | **422 `ADMIN_NOTE_REQUIRED`** |
| TC-APR-03 | `admin_note` 4 karakter | 422 |
| TC-APR-04 | Admin approve dengan catatan | 200, `approved`, `approved_by` & `decided_at` terisi |
| TC-APR-05 | Admin reject dengan catatan | 200, `rejected` |
| TC-APR-06 | Approve booking yang sudah `approved` | 409 `INVALID_STATUS_TRANSITION` |
| TC-APR-07 | Approve booking yang sudah `expired` | 409 |
| TC-APR-08 | Student mencoba PATCH approve | 403 `FORBIDDEN` |
| TC-APR-09 | Admin B approve booking yang disetujui Admin A | 200 (semua admin setara) |

### 2.6 Pembatalan

| ID | Skenario | Ekspektasi |
|---|---|---|
| TC-CAN-01 | User cancel booking `pending` | 200 → `cancelled` |
| TC-CAN-02 | User cancel `approved`, 2 hari sebelum acara | 200 |
| TC-CAN-03 | User cancel `approved`, hari H | **403 `CANCELLATION_WINDOW_CLOSED`** |
| TC-CAN-04 | User cancel `approved`, tepat H-1 | 200 (batas inklusif) |
| TC-CAN-05 | User A cancel booking User B | 404 (RLS sembunyikan) |
| TC-CAN-06 | Admin cancel booking siapa pun | 200, `admin_note` wajib |
| TC-CAN-07 | Setelah cancel, slot dipesan user lain | 201 |

### 2.7 Field & Validasi Form

| ID | Skenario | Ekspektasi |
|---|---|---|
| TC-VAL-01 | Peserta 41 pada ruang kapasitas 40 | **422 `CAPACITY_EXCEEDED`** |
| TC-VAL-02 | Peserta 0 atau negatif | 400 `VALIDATION_ERROR` |
| TC-VAL-03 | `phone_number` `08123` (terlalu pendek) | 400 |
| TC-VAL-04 | `phone_number` `+6281234567890` | 201 |
| TC-VAL-05 | `phone_number` `6281234567890` | 201 |
| TC-VAL-06 | `activity_name` 2 karakter | 400 |
| TC-VAL-07 | `terms_accepted` = `false` | **422 `TERMS_NOT_ACCEPTED`** |
| TC-VAL-08 | `terms_accepted` = `true` | `terms_accepted_at` & `terms_version` terisi di DB |
| TC-VAL-09 | `room_id` ruang `is_active=false` | 422/409 |

### 2.8 Kalender & Privasi

| ID | Skenario | Ekspektasi |
|---|---|---|
| TC-CAL-01 | Akses `/kalender` & `GET /api/calendar` tanpa login | 200 |
| TC-CAL-02 | Response kalender memuat `phone_number` | **TIDAK ADA** |
| TC-CAL-03 | Response kalender memuat `admin_note` | **TIDAK ADA** |
| TC-CAL-04 | Response kalender memuat email pemilik | **TIDAK ADA** |
| TC-CAL-05 | `activity_name` & `person_in_charge` tampil | Ada (transparansi penuh) |
| TC-CAL-06 | Filter `room_id` | Hanya event ruang tsb |
| TC-CAL-07 | Event di luar jam operasional (Jumat 14.30–16.00) | Tidak ada |

### 2.9 Galeri

| ID | Skenario | Ekspektasi |
|---|---|---|
| TC-GAL-01 | `GET /api/gallery` tanpa login | 200, ada grup `campus` & `rooms` |
| TC-GAL-02 | Admin upload foto 3 MB | Ditolak (maks 2 MB `[ASUMSI]`) |
| TC-GAL-03 | Admin upload file `.pdf` | Ditolak 400 |
| TC-GAL-04 | Student upload foto | 403 `FORBIDDEN` |
| TC-GAL-05 | Admin upload > 5 foto untuk 1 ruang | Ditolak `[ASUMSI]` |
| TC-GAL-06 | Hapus foto | Metadata & file Storage terhapus |

### 2.10 Notifikasi

| ID | Skenario | Ekspektasi |
|---|---|---|
| TC-NOT-01 | Booking diajukan | Email + WhatsApp terkirim ke pemilik |
| TC-NOT-02 | Admin approve | Email + WhatsApp berisi status & catatan |
| TC-NOT-03 | WhatsApp provider down | Booking tetap 201, error tercatat di `notification_logs` |
| TC-NOT-04 | Retry notifikasi | Maksimal 3x percobaan |
| TC-NOT-05 | Booking baru masuk | Email ke semua admin |

### 2.11 Otorisasi & RLS

| ID | Skenario | Ekspektasi |
|---|---|---|
| TC-AUTHZ-01 | Student `GET /api/bookings` | Hanya booking miliknya |
| TC-AUTHZ-02 | Student buka booking milik orang lain | 404 |
| TC-AUTHZ-03 | Student `POST /api/rooms` | 403 |
| TC-AUTHZ-04 | Student `DELETE /api/rooms/[id]` | 403 |
| TC-AUTHZ-05 | Akses tabel `bookings` langsung via anon key | RLS menolak baris orang lain |
| TC-AUTHZ-06 | Admin `GET /api/bookings` | Semua booking |
| TC-AUTHZ-07 | Demote admin terakhir | 409 `LAST_ADMIN` |

---

## 3. Uji Manual / UAT (dengan pihak FIP UM)

| ID | Skenario | Kriteria Lulus |
|---|---|---|
| UAT-01 | Pengunjung cek ketersediaan tanpa login | Hasil muncul < 3 detik, ruang terisi tampil dengan alasan |
| UAT-02 | Cek ketersediaan Jumat 15.00 | Ditolak: "di luar jam operasional Jumat (07.00–14.30)" |
| UAT-03 | Mahasiswa ajukan peminjaman lengkap | Berhasil, email + WhatsApp masuk, status `pending` |
| UAT-04 | Admin approve dengan alasan | User menerima notifikasi berisi alasan |
| UAT-05 | Admin reject dengan alasan | User melihat alasan di riwayat & notifikasi |
| UAT-06 | Booking 73 jam tidak diproses | Otomatis `expired`, slot bisa dipakai orang lain |
| UAT-07 | Kalender publik | Nama kegiatan & PJ terlihat; no. HP tidak terlihat |
| UAT-08 | Halaman Galeri | Foto gedung + foto ruang rapi di desktop & mobile |
| UAT-09 | Halaman S&K | Terbaca, dapat diakses tanpa login |
| UAT-10 | Responsif mobile 375px | Semua halaman usable, tidak ada scroll horizontal |
| UAT-11 | Register email non-kampus | Ditolak dengan pesan jelas |

---

## 4. Uji Non-Fungsional

| ID | Aspek | Target | Cara uji |
|---|---|---|---|
| NF-T-01 | Performa | LCP < 2.5s pada 4G | Lighthouse |
| NF-T-02 | Kinerja API | `GET /api/rooms/available` < 800ms (100 ruang) | k6 / Artillery |
| NF-T-03 | Aksesibilitas | axe-core 0 critical issue | `@axe-core/playwright` |
| NF-T-04 | Cross-browser | Chrome, Safari, Edge terbaru | Playwright projects |
| NF-T-05 | Responsif | 375 / 768 / 1280 / 1920 px | Manual + screenshot test |
| NF-T-06 | Keamanan | Service key tidak ada di bundle client | Grep build output + `npm audit` |

---

## 5. Definition of Done

- [ ] Semua test case §2 lulus di CI.
- [ ] Coverage fungsi validasi ≥ 90%.
- [ ] Tidak ada test di-skip tanpa alasan terdokumentasi.
- [ ] UAT §3 ditandatangani pihak FIP UM.
- [ ] Race condition (TC-DB-09, TC-DB-10) terbukti ditangani constraint DB, bukan hanya SELECT.

---

## 6. Perintah Menjalankan Pengujian

```bash
npm run test          # Vitest unit test
npm run test:watch    # Watch mode
npm run test:coverage # Coverage report
npm run test:e2e      # Playwright E2E
npm run test:e2e:ui   # Playwright UI mode
```

---

*Versi 1.0*