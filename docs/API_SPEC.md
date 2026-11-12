# Spesifikasi API — Sistem Peminjaman Ruang FIP UM

**Versi:** 1.0
**Base URL (dev):** `http://localhost:3000/api`
**Dokumen terkait:** `BUSINESS_RULES.md`, `DATABASE_DESIGN.md`, `ARCHITECTURE.md`

---

## 1. Konvensi Umum

### 1.1 Format
- Content-Type: `application/json` (kecuali upload file → `multipart/form-data`).
- Timestamp: **ISO 8601 dengan offset**, contoh `2026-03-10T07:00:00+07:00`. Server menyimpan UTC.

**Sukses:**
```json
{ "success": true, "data": { }, "meta": { } }
```

**Gagal:**
```json
{
  "success": false,
  "error": {
    "code": "SLOT_UNAVAILABLE",
    "message": "Slot 10.00–12.00 pada RUANG RAPAT FIP sudah diajukan orang lain.",
    "details": { "conflict_start": "2026-03-10T10:00:00+07:00" }
  }
}
```

### 1.2 Autentikasi
- Sesi berbasis cookie Supabase (HTTP-only), dikelola `middleware.ts`.
- **Publik** → tanpa sesi. **User** → sesi valid. **Admin** → sesi valid + `profiles.role = 'admin'`.

### 1.3 Matriks Kode Error

| HTTP | Code | Kapan |
|------|------|-------|
| 400 | `VALIDATION_ERROR` | Body tidak sesuai skema (Zod) |
| 401 | `UNAUTHENTICATED` | Belum login / sesi habis |
| 401 | `EMAIL_NOT_VERIFIED` | Email belum diverifikasi |
| 403 | `FORBIDDEN` | Role tidak berhak |
| 403 | `EMAIL_DOMAIN_NOT_ALLOWED` | Domain bukan `@um.ac.id` |
| 403 | `CANCELLATION_WINDOW_CLOSED` | Batal melewati batas pembatalan |
| 404 | `NOT_FOUND` | Resource tidak ada |
| 409 | `SLOT_UNAVAILABLE` | Bentrok dengan booking lain |
| 409 | `INVALID_STATUS_TRANSITION` | Transisi status tidak diizinkan |
| 409 | `LAST_ADMIN` | Tidak boleh menurunkan admin terakhir |
| 422 | `TERMS_NOT_ACCEPTED` | S&K tidak dicentang |
| 422 | `ADMIN_NOTE_REQUIRED` | Alasan admin kosong |
| 422 | `CAPACITY_EXCEEDED` | Peserta > kapasitas ruang |
| 422 | `OUTSIDE_OPERATING_HOURS` | Di luar jam operasional hari tsb |
| 422 | `INVALID_DURATION` | Durasi di luar min/maks |
| 422 | `INVALID_GRANULARITY` | Bukan kelipatan granularitas |
| 422 | `BOOKING_WINDOW_INVALID` | Di luar jendela pengajuan |
| 429 | `RATE_LIMITED` | Terlalu banyak request |
| 500 | `INTERNAL_ERROR` | Kesalahan server |

### 1.4 Rate Limit

| Endpoint | Limit |
|---|---|
| `GET /api/rooms/available` | 60 req/menit per IP |
| `POST /api/bookings` | 5 req/menit per user |
| `POST /api/auth/register` | 3 req/menit per IP |
---

## 2. Ruang (Rooms)

### 2.1 `GET /api/rooms` — Publik
Daftar ruang aktif.

| Param | Tipe | Default | Keterangan |
|---|---|---|---|
| `q` | string | — | Cari di `name`, `code`, `location` |
| `location` | string | — | Filter gedung |
| `min_capacity` | int | — | Kapasitas minimal |
| `include_inactive` | bool | `false` | Hanya berlaku untuk admin |
| `page` / `limit` | int | 1 / 50 | Limit maks 100 |

```json
{
  "success": true,
  "data": [
    {
      "id": "uuid",
      "name": "RUANG RAPAT FIP",
      "code": "R-RAPAT-FIP",
      "capacity": 40,
      "location": "Gedung D3 Lt.2",
      "description": null,
      "cover_image_url": "https://.../cover.jpg",
      "is_active": true,
      "facilities": ["AC", "Proyektor", "WiFi"]
    }
  ],
  "meta": { "page": 1, "limit": 50, "total": 40 }
}
```

### 2.2 `GET /api/rooms/[id]` — Publik
Detail satu ruang termasuk **semua** foto dari `room_images`.

```json
{
  "success": true,
  "data": {
    "id": "uuid",
    "name": "RUANG RAPAT FIP",
    "code": "R-RAPAT-FIP",
    "capacity": 40,
    "location": "Gedung D3 Lt.2",
    "description": "Ruang kelas reguler dengan proyektor.",
    "is_active": true,
    "facilities": ["AC", "Proyektor", "WiFi"],
    "images": [
      { "id": "uuid", "url": "https://.../1.jpg", "is_cover": true, "sort_order": 0 }
    ]
  }
}
```

### 2.3 `GET /api/rooms/available` — Publik
⚠️ **Endpoint ini sebelumnya hilang dari tabel di `ARCHITECTURE.md`.** Dipakai widget "Cek Ketersediaan Ruang" di halaman Home, **tanpa login**.

| Param | Tipe | Keterangan |
|---|---|---|
| `start` | ISO8601 | Tanggal & jam mulai (wajib) |
| `end` | ISO8601 | Tanggal & jam selesai (wajib) |

```json
{
  "success": true,
  "data": {
    "available": [
      { "id": "uuid", "code": "R-RAPAT-FIP", "name": "RUANG RAPAT FIP", "capacity": 40, "location": "Gedung D3 Lt.2" }
    ],
    "unavailable": [
      {
        "id": "uuid",
        "code": "AULA FIP (Gedung D3)",
        "name": "AULA FIP (Gedung D3)",
        "capacity": 200,
        "location": "Gedung D10",
        "reason": "BOOKED",
        "conflict": {
          "start_time": "2026-03-10T08:00:00+07:00",
          "end_time": "2026-03-10T12:00:00+07:00",
          "activity_name": "Seminar Nasional Pendidikan"
        }
      }
    ]
  }
}
```

Mengembalikan `422 OUTSIDE_OPERATING_HOURS` jika rentang di luar jam operasional (contoh: Jumat 15.00–16.00). Sebelum query, endpoint memanggil `expire_stale_bookings()`.

### 2.4 `POST /api/rooms` — Admin
```json
{
  "name": "RUANG RAPAT FIP",
  "code": "R-RAPAT-FIP",
  "capacity": 40,
  "location": "Gedung D3 Lt.2",
  "description": "Opsional",
  "is_active": true,
  "facilities": ["AC", "Proyektor", "WiFi"]
}
```
`code` unik (409 jika duplikat), `capacity` > 0.

### 2.5 `PUT /api/rooms/[id]` — Admin
Body sama, semua field opsional.

### 2.6 `DELETE /api/rooms/[id]` — Admin
Ditolak `409 CONFLICT` jika masih ada booking `pending`/`approved` di masa depan. Disarankan `is_active: false` daripada hapus.

---

## 3. Fasilitas

| Method | Endpoint | Akses | Deskripsi |
|---|---|---|---|
| GET | `/api/facilities` | Publik | Daftar fasilitas unik untuk filter |
| POST | `/api/rooms/[id]/facilities` | Admin | Replace seluruh daftar fasilitas ruang |

`POST` body: `{ "facilities": ["AC", "Proyektor"] }`. Constraint `UNIQUE(room_id, facility)` mencegah duplikat.

---

## 4. Peminjaman (Bookings)

### 4.1 `POST /api/bookings` — User (login + email terverifikasi)

```json
{
  "room_id": "uuid",
  "start_time": "2026-03-10T07:00:00+07:00",
  "end_time": "2026-03-10T09:30:00+07:00",
  "activity_name": "Rapat Himpunan Mahasiswa",
  "participant_count": 35,
  "person_in_charge": "Budi Santoso",
  "phone_number": "081234567890",
  "terms_accepted": true
}
```

> 🔒 **Sumber nilai:** seluruh angka batas (granularitas, durasi min/maks, jendela pengajuan) **tidak** didefinisikan di dokumen ini — lihat `BUSINESS_RULES.md` §2. API wajib membaca dari konstanta `lib/booking-rules.ts`.

**Urutan validasi (penting agar pesan error tepat):**
1. `VALIDATION_ERROR` — skema Zod
2. `TERMS_NOT_ACCEPTED`
3. Tanggal sama & `start < end`
4. `INVALID_GRANULARITY` — bukan kelipatan granularitas
5. `INVALID_DURATION` — durasi di luar min/maks (admin bebas batas maks)
6. `BOOKING_WINDOW_INVALID` — di luar jendela pengajuan (admin bebas)
7. `OUTSIDE_OPERATING_HOURS` — sesuai jam hari tersebut, **Jumat tutup 14.30**
8. `CAPACITY_EXCEEDED`
9. `SLOT_UNAVAILABLE` — cek bentrok → `INSERT`; jika `EXCLUDE` constraint menolak (`23P01`) → tetap `SLOT_UNAVAILABLE`

**Response 201:**
```json
{
  "success": true,
  "data": {
    "id": "uuid",
    "status": "pending",
    "room": { "id": "uuid", "code": "R-RAPAT-FIP", "name": "RUANG RAPAT FIP" },
    "start_time": "2026-03-10T07:00:00+07:00",
    "end_time": "2026-03-10T09:30:00+07:00",
    "activity_name": "Rapat Himpunan Mahasiswa",
    "participant_count": 35,
    "person_in_charge": "Budi Santoso",
    "phone_number": "081234567890",
    "terms_accepted_at": "2026-03-07T10:12:00+07:00",
    "terms_version": "1.0",
    "expires_at": "2026-03-10T10:12:00+07:00"
  }
}
```

> `terms_accepted` diperlakukan sebagai gate boolean; server menulis `terms_accepted_at = now()` dan `terms_version` dari versi S&K aktif.
> Notifikasi email & WhatsApp dikirim **asinkron** setelah response 201 terkirim.

### 4.2 `GET /api/bookings` — User / Admin

| Query | User | Admin |
|---|---|---|
| `status` | boleh, hanya miliknya | boleh, semua |
| `room_id` | boleh | boleh |
| `user_id` | diabaikan (selalu `auth.uid()`) | boleh |
| `from`, `to` | boleh | boleh |
| `page`, `limit` | boleh | boleh |

Field `phone_number` & `admin_note` hanya muncul untuk pemilik atau admin.

### 4.3 `GET /api/bookings/[id]` — Pemilik / Admin
`404` jika bukan pemilik dan bukan admin (RLS menyembunyikan row → 404, bukan 403, agar tidak membocorkan keberadaan data).

### 4.4 `PATCH /api/bookings/[id]` — Approve / Reject (Admin)

```json
{ "status": "approved", "admin_note": "Disetujui, ruang siap digunakan." }
```

- Hanya `pending` → `approved` / `rejected`; selain itu `409 INVALID_STATUS_TRANSITION`.
- `admin_note` **WAJIB** untuk approve **dan** reject, min 5 karakter → `422 ADMIN_NOTE_REQUIRED`.
- Server menulis `approved_by = auth.uid()`, `decided_at = now()`.
- Notifikasi email + WhatsApp asinkron ke pemilik.

### 4.5 `PATCH /api/bookings/[id]/cancel` — Pemilik
Body: `{ "cancel_reason": "Acara dibatalkan" }`

- `pending` → boleh kapan saja.
- `approved` → hanya jika masih dalam batas pembatalan, selain itu `403 CANCELLATION_WINDOW_CLOSED` (lihat `BUSINESS_RULES.md` §7).
- Status akhir `cancelled`.

### 4.6 `DELETE /api/bookings/[id]` — Admin
Hard delete. Untuk audit harian disarankan `cancel`.

---

## 5. Kalender Even

### `GET /api/calendar` — Publik

| Param | Tipe | Keterangan |
|---|---|---|
| `room_id` | uuid | Opsional, filter satu ruang |
| `from` | date | Default: awal bulan berjalan |
| `to` | date | Maks 62 hari dari `from` |

```json
{
  "success": true,
  "data": [
    {
      "id": "uuid",
      "room_id": "uuid",
      "room_code": "AULA FIP (Gedung D3)",
      "room_name": "AULA FIP (Gedung D3)",
      "start_time": "2026-03-10T08:00:00+07:00",
      "end_time": "2026-03-10T12:00:00+07:00",
      "activity_name": "Seminar Nasional Pendidikan",
      "person_in_charge": "Dr. Siti Aminah",
      "status": "approved"
    }
  ]
}
```

**TIDAK boleh keluar dari endpoint ini:** `phone_number`, `admin_note`, `user_id`, email pemilik.

---

## 6. Galeri

| Method | Endpoint | Akses | Deskripsi |
|---|---|---|---|
| GET | `/api/gallery` | Publik | Foto lingkungan kampus + foto ruang |
| POST | `/api/gallery` | Admin | Upload (multipart/form-data) |
| DELETE | `/api/gallery/[id]` | Admin | Hapus file + metadata |

`GET` params: `type` (`campus` \| `room` \| `all`, default `all`), `room_id`, `page`, `limit`.

```json
{
  "success": true,
  "data": {
    "campus": [
      { "id": "uuid", "url": "https://.../fip-1.jpg", "caption": "Gedung FIP UM", "sort_order": 0 }
    ],
    "rooms": [
      {
        "room_id": "uuid",
        "room_code": "R-RAPAT-FIP",
        "room_name": "RUANG RAPAT FIP",
        "images": [ { "id": "uuid", "url": "https://.../d11-101-1.jpg", "is_cover": true } ]
      }
    ]
  }
}
```

`POST` fields: `file` (JPG/PNG/WebP, maks 2 MB `[ASUMSI]`), `type` (`campus` \| `room`), `room_id` (wajib jika `type=room`), `caption` (opsional). Upload ke Supabase Storage bucket `gallery`.

---

## 7. Auth

| Method | Endpoint | Akses | Deskripsi |
|---|---|---|---|
| POST | `/api/auth/register` | Publik | Register + validasi domain email kampus |
| POST | `/api/auth/login` | Publik | Login email+password |
| POST | `/api/auth/logout` | User | Hapus sesi |
| POST | `/api/auth/reset-password` | Publik | Kirim link reset |
| POST | `/api/auth/update-password` | Publik (token) | Set password baru |
| GET | `/api/auth/session` | Publik | `{ "data": { "user": null } }` jika belum login |

### `POST /api/auth/register`
```json
{ "email": "budi@um.ac.id", "password": "Rahasia123!", "full_name": "Budi Santoso" }
```
- Domain bukan `@um.ac.id` → `403 EMAIL_DOMAIN_NOT_ALLOWED`.
- Password minimal 8 karakter, kombinasi huruf & angka.
- User **tidak** dapat booking sebelum email diverifikasi.

---

## 8. S&K & Profil

| Method | Endpoint | Akses | Deskripsi |
|---|---|---|---|
| GET | `/api/terms` | Publik | `{ "version": "1.0", "effective_date": "...", "content_md": "..." }` |
| GET | `/api/profile` | User | Profil sendiri |
| PATCH | `/api/profile` | User | Update `full_name`, `phone_number` |
| GET | `/api/admin/users` | Admin | Daftar user + role |
| PATCH | `/api/admin/users/[id]/role` | Admin | Ubah role |

Ubah role: menurunkan admin terakhir → `409 LAST_ADMIN`.

---

## 9. Cron / Maintenance

| Method | Endpoint | Akses | Deskripsi |
|---|---|---|---|
| POST | `/api/cron/expire-bookings` | Internal (`x-cron-secret`) | Jalankan `expire_stale_bookings()`, tiap 10 menit |
| POST | `/api/cron/send-notifications` | Internal | Retry antrean notifikasi gagal |

---

## 10. Ringkasan Seluruh Endpoint

| Method | Endpoint | Akses |
|---|---|---|
| GET | `/api/rooms` | Publik |
| GET | `/api/rooms/[id]` | Publik |
| **GET** | **`/api/rooms/available`** | **Publik** |
| POST | `/api/rooms` | Admin |
| PUT | `/api/rooms/[id]` | Admin |
| DELETE | `/api/rooms/[id]` | Admin |
| POST | `/api/rooms/[id]/facilities` | Admin |
| GET | `/api/facilities` | Publik |
| GET | `/api/bookings` | User / Admin |
| POST | `/api/bookings` | User |
| GET | `/api/bookings/[id]` | Pemilik / Admin |
| PATCH | `/api/bookings/[id]` | Admin |
| PATCH | `/api/bookings/[id]/cancel` | Pemilik |
| DELETE | `/api/bookings/[id]` | Admin |
| GET | `/api/calendar` | Publik |
| GET | `/api/gallery` | Publik |
| POST | `/api/gallery` | Admin |
| DELETE | `/api/gallery/[id]` | Admin |
| GET | `/api/terms` | Publik |
| GET | `/api/auth/session` | Publik |
| POST | `/api/auth/register` | Publik |
| POST | `/api/auth/login` | Publik |
| POST | `/api/auth/logout` | User |
| POST | `/api/auth/reset-password` | Publik |
| POST | `/api/auth/update-password` | Publik |
| GET | `/api/profile` | User |
| PATCH | `/api/profile` | User |
| GET | `/api/admin/users` | Admin |
| PATCH | `/api/admin/users/[id]/role` | Admin |
| POST | `/api/cron/expire-bookings` | Internal |
| POST | `/api/cron/send-notifications` | Internal |

---

*Versi 1.0*