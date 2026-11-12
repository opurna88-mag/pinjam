# Arsitektur Sistem — Sistem Peminjaman Ruang Digital FIP UM

**Versi:** 1.2
**Dokumen acuan:** `SRS.md`, `BUSINESS_RULES.md`, `DATABASE_DESIGN.md`, `API_SPEC.md`

## 0. Perubahan dari Versi 1.0

| # | Perubahan |
|---|---|
| 1 | **TAMBAH** `GET /api/rooms/available` ke tabel endpoint (sebelumnya dipakai di alur §3.3 tapi **tidak ada** di tabel §4) |
| 2 | **TAMBAH** endpoint publik baru: `/api/calendar`, `/api/gallery`, `/api/terms`, `/api/facilities` |
| 3 | **TAMBAH** endpoint auth: register, login, logout, reset-password, update-password |
| 4 | **TAMBAH** endpoint admin: users & role management |
| 5 | **TAMBAH** endpoint cron: expire-bookings, send-notifications |
| 6 | **TAMBAH** `middleware.ts` untuk refresh session Supabase |
| 7 | **TAMBAH** modul notifikasi (email + WhatsApp) & rate limiting |
| 8 | **TAMBAH** route publik untuk Landing, Galeri, S&K, Kalender |
| 9 | **TAMBAH** integrasi eksternal (SMTP/Resend, WhatsApp gateway, pg_cron) |

---

## 1. Stack Teknologi

| Layer | Teknologi | Versi |
|-------|-----------|-------|
| Framework | Next.js (App Router) | 15+ |
| Bahasa | TypeScript | 5.x |
| Styling | Tailwind CSS | 4.x |
| Komponen UI | shadcn/ui / Radix UI | Terbaru |
| Backend / API | Next.js Route Handlers | Built-in |
| Database | Supabase (PostgreSQL) | — |
| Auth | Supabase Auth | — |
| Storage | Supabase Storage | — |
| Scheduler DB | `pg_cron` | — |
| State Server | TanStack Query (React Query) | 5.x |
| Validasi | Zod | 3.x |
| Notifikasi Email | SMTP / Resend | — |
| Notifikasi WhatsApp | Gateway (Fonnte/Wablas/ lainnya) | — |
| Rate Limit | `@upstash/ratelimit` atau tabel `rate_limits` | — |
| Deployment | Vercel | — |

---

## 2. Struktur Folder (Next.js App Router)

> **Keputusan:** proyek **TIDAK** memakai `--src-dir`. Semua kode aplikasi berada langsung di root (`app/`, `components/`, `lib/`, dst.) agar konsisten dengan dokumen ini dan `README_DEV.md`.

```
pinjam/
├── app/
│   ├── (public)/
│   │   ├── page.tsx                  # Home / Landing
│   │   ├── galeri/page.tsx
│   │   ├── syarat-ketentuan/page.tsx
│   │   ├── ruang/page.tsx
│   │   ├── ruang/[id]/page.tsx
│   │   └── kalender/page.tsx
│   ├── (auth)/
│   │   ├── login/page.tsx
│   │   ├── register/page.tsx
│   │   ├── reset-password/page.tsx
│   │   └── update-password/page.tsx
│   ├── (dashboard)/
│   │   ├── user/
│   │   │   ├── page.tsx
│   │   │   ├── bookings/page.tsx
│   │   │   ├── bookings/new/page.tsx
│   │   │   ├── bookings/[id]/page.tsx
│   │   │   └── profile/page.tsx
│   │   └── admin/
│   │       ├── page.tsx
│   │       ├── bookings/page.tsx
│   │       ├── bookings/[id]/page.tsx
│   │       ├── rooms/page.tsx
│   │       ├── rooms/[id]/page.tsx
│   │       ├── gallery/page.tsx
│   │       └── users/page.tsx
│   ├── api/                          # lihat §4
│   ├── layout.tsx
│   └── globals.css
├── components/
│   ├── ui/                           # shadcn/ui
│   ├── layout/ (app-header.tsx, footer.tsx)
│   ├── booking-form.tsx
│   ├── room-card.tsx
│   ├── room-search-combobox.tsx
│   ├── availability-widget.tsx
│   ├── availability-result-panel.tsx
│   ├── calendar-view.tsx
│   ├── event-detail-modal.tsx
│   ├── status-badge.tsx
│   └── admin-decision-panel.tsx
├── lib/
│   ├── supabase/
│   │   ├── client.ts                 # Browser client
│   │   ├── server.ts                 # Server client
│   │   ├── middleware.ts             # Session refresh helper
│   │   └── admin.ts                  # Service role client (server only)
│   ├── validations/
│   │   ├── booking.ts                # Zod schema booking
│   │   ├── room.ts
│   │   └── auth.ts
│   ├── booking-rules.ts              # Jam operasional, durasi, jendela
│   ├── notifications/
│   │   ├── email.ts
│   │   └── whatsapp.ts
│   ├── api-error.ts                  # Pemetaan error code → HTTP
│   └── utils.ts
├── hooks/
│   ├── useBookings.ts
│   ├── useAuth.ts
│   └── useAvailability.ts
├── types/index.ts
├── middleware.ts                     # WAJIB (v1.1 baru)
├── public/
├── .env.local
├── tailwind.config.ts
├── tsconfig.json
├── next.config.ts
└── package.json
```

---

## 3. Alur Data (Data Flow)

### 3.1 Pengunjung cek ketersediaan (TANPA LOGIN) — v1.1 baru
1. Pengunjung mengisi widget di Home: jam mulai, jam selesai, ruangan (opsional).
2. Frontend memanggil `GET /api/rooms/available?start=...&end=...`.
3. API membuat server client → memanggil `expire_stale_bookings()` agar data basi tidak memblokir.
4. API memvalidasi rentang terhadap `operating_hours` (Jumat tutup 14.30).
5. API query `rooms` aktif + `bookings` berstatus `pending`/`approved` yang overlap.
6. Response: `{ available: [...], unavailable: [...] }` dengan alasan bentrok.

### 3.2 User membuat booking
1. User login (email kampus, terverifikasi) → halaman ruang / form booking.
2. Frontend validasi awal (jam operasional hari terpilih, durasi, jendela pengajuan — nilai dari `BUSINESS_RULES.md` §2).
3. Klik "Ajukan Peminjaman" → `POST /api/bookings`.
4. API Route:
   - Verifikasi sesi + `email_confirmed_at`.
   - Validasi Zod (semua field wajib termasuk `terms_accepted`).
   - Validasi bisnis: granularitas, durasi min/maks, jam operasional, kapasitas, jendela pengajuan (semua nilai dari `BUSINESS_RULES.md` §2 via `lib/booking-rules.ts`).
   - Cek bentrok (`SELECT`) untuk pesan error ramah.
   - `INSERT` dengan `status='pending'`, `terms_accepted_at=now()`, `terms_version`.
   - Jika DB menolak `23P01` (EXCLUDE constraint) → `409 SLOT_UNAVAILABLE`.
5. Response 201 dikirim ke frontend.
6. **Setelah response terkirim** (non-blocking): kirim email + WhatsApp ke pemilik, email ke admin, catat ke `notification_logs`.

### 3.3 Admin approve/reject
1. Admin buka dashboard → `GET /api/bookings?status=pending`.
2. Admin buka detail → isi alasan (wajib) → `PATCH /api/bookings/[id]`.
3. API verifikasi `public.is_admin()`.
4. Validasi `admin_note` minimal 5 karakter → `422` jika kosong.
5. Update `status`, `admin_note`, `approved_by`, `decided_at`.
6. Notifikasi email + WhatsApp asinkron ke pemilik.

### 3.4 User membatalkan booking
1. User buka riwayat → tombol Batal.
2. `PATCH /api/bookings/[id]/cancel`.
3. API cek: `pending` → boleh; `approved` → hanya bila masih dalam batas pembatalan (lihat `BUSINESS_RULES.md` §7).
4. Status → `cancelled`, `cancel_reason` tersimpan. Slot otomatis bebas (tidak memblokir constraint).

### 3.5 Auto-expired `pending`
1. `pg_cron` menjalankan `expire_stale_bookings()` secara berkala.
2. Booking `pending` yang melewati batas kedaluwarsa → `expired` (nilai batas: `BUSINESS_RULES.md` §3.4, konstanta `lib/booking-rules.ts`).
3. Slot otomatis bebas karena constraint hanya berlaku untuk `pending`/`approved`.
4. Endpoint ketersediaan juga memanggil fungsi ini agar konsisten walau cron tertunda.
5. Notifikasi `expired` dikirim ke pemilik.

### 3.6 Kalender publik
1. `GET /api/calendar?room_id=&from=&to=` (tanpa login).
2. API memakai **view** `public_calendar` (kolom terbatas) via server client.
3. Response tidak mengandung `phone_number`, `admin_note`, `user_id`, email.

### 3.7 Registrasi dengan domain email terbatas
1. User submit form register → `POST /api/auth/register`.
2. API validasi domain (`ALLOWED_EMAIL_DOMAINS`) → `403 EMAIL_DOMAIN_NOT_ALLOWED` bila gagal.
3. Trigger DB `enforce_email_domain` menjadi lapis kedua (otoritatif).
4. `handle_new_user` membuat baris di `profiles` dengan role `student`.
5. Email verifikasi dikirim; user belum dapat booking sebelum verifikasi.

---

## 4. API Endpoint (Route Handlers)

> Daftar lengkap lengkap dengan skema request/response ada di `API_SPEC.md`. Tabel ini ringkasan.

| Method | Endpoint | Deskripsi | Akses |
|--------|----------|-----------|-------|
| GET | `/api/rooms` | Daftar ruang aktif | Publik |
| GET | `/api/rooms/[id]` | Detail ruang + foto | Publik |
| **GET** | **`/api/rooms/available`** | **Cek ketersediaan rentang waktu** | **Publik** |
| POST | `/api/rooms` | Tambah ruang | Admin |
| PUT | `/api/rooms/[id]` | Edit ruang | Admin |
| DELETE | `/api/rooms/[id]` | Hapus/nonaktifkan ruang | Admin |
| POST | `/api/rooms/[id]/facilities` | Set fasilitas ruang | Admin |
| GET | `/api/facilities` | Daftar fasilitas unik | Publik |
| GET | `/api/bookings` | Daftar booking | User/Admin |
| POST | `/api/bookings` | Buat booking | User |
| GET | `/api/bookings/[id]` | Detail booking | Pemilik/Admin |
| PATCH | `/api/bookings/[id]` | Approve/reject | Admin |
| PATCH | `/api/bookings/[id]/cancel` | Batalkan | Pemilik |
| DELETE | `/api/bookings/[id]` | Hapus booking | Admin |
| GET | `/api/calendar` | Kalender even | Publik |
| GET | `/api/gallery` | Galeri foto | Publik |
| POST | `/api/gallery` | Upload foto | Admin |
| DELETE | `/api/gallery/[id]` | Hapus foto | Admin |
| GET | `/api/terms` | Konten S&K + versi | Publik |
| GET | `/api/auth/session` | Cek sesi | Publik |
| POST | `/api/auth/register` | Register (domain kampus) | Publik |
| POST | `/api/auth/login` | Login | Publik |
| POST | `/api/auth/logout` | Logout | User |
| POST | `/api/auth/reset-password` | Kirim link reset | Publik |
| POST | `/api/auth/update-password` | Set password baru | Publik |
| GET | `/api/profile` | Profil sendiri | User |
| PATCH | `/api/profile` | Update profil | User |
| GET | `/api/admin/users` | Daftar user | Admin |
| PATCH | `/api/admin/users/[id]/role` | Ubah role | Admin |
| POST | `/api/cron/expire-bookings` | Auto-expire | Internal |
| POST | `/api/cron/send-notifications` | Retry notifikasi | Internal |

---

## 5. Keamanan (Security)

- **Auth**: Semua API mutatif memvalidasi sesi Supabase. `middleware.ts` me-refresh session di setiap request.
- **RLS**: Semua akses tabel diatur Supabase RLS (lihat `DATABASE_DESIGN.md` §3).
- **Email kampus**: Validasi domain di API **dan** trigger DB `enforce_email_domain`.
- **Validasi Input**: Semua body request divalidasi Zod sebelum menyentuh DB.
- **Anti double-booking**: constraint `EXCLUDE USING gist` di DB (otoritatif), API hanya untuk pesan error.
- **Privasi kalender**: akses lewat view `public_calendar`, bukan policy tabel terbuka.
- **Secret key**: `SUPABASE_SECRET_KEY` **hanya** dipakai di server (`lib/supabase/admin.ts`) — tidak pernah diimpor ke komponen client.
- **Rate limiting**: diterapkan pada endpoint publik & mutasi (lihat `API_SPEC.md` §1.4).
- **CORS**: dibatasi hanya domain production.
- **Upload file**: validasi MIME + ukuran di API **dan** bucket settings Supabase.

### 5.1 `middleware.ts` (v1.1 baru — WAJIB)
```ts
// middleware.ts
import { type NextRequest } from 'next/server'
import { updateSession } from '@/lib/supabase/middleware'

export async function middleware(request: NextRequest) {
  return await updateSession(request)
}

export const config = {
  matcher: [
    '/((?!_next/static|_next/image|favicon.ico|.*\\.(?:svg|png|jpg|jpeg|webp|gif)$).*)',
  ],
}
```

Pola `updateSession` harus memakai `getAll`/`setAll` (bukan `get` saja — deprecated di `@supabase/ssr` terbaru) dan `await cookies()` karena `cookies()` sudah async di Next 15. Detail di `README_DEV.md` §3.

---

## 6. Integrasi Eksternal (v1.1 baru)

| Integrasi | Kegunaan | Konfigurasi |
|---|---|---|
| SMTP / Resend | Email notifikasi | `SMTP_HOST`, `SMTP_PORT`, `SMTP_USER`, `SMTP_PASS`, `MAIL_FROM` (atau `RESEND_API_KEY`) |
| WhatsApp Gateway | Notifikasi WhatsApp | `WA_API_URL`, `WA_API_KEY`, `WA_SENDER` |
| `pg_cron` | Auto-expire booking `pending` | Ekstensi Supabase (nilai batas: `BUSINESS_RULES.md` §3.4) |
| Vercel Cron | Alternatif pemanggil `/api/cron/*` | `vercel.json` |
| Upstash Ratelimit | Rate limiting | `UPSTASH_REDIS_REST_URL`, `UPSTASH_REDIS_REST_TOKEN` |

**Pola pengiriman notifikasi (non-blocking):**
```ts
// setelah response dikirim
after(async () => {
  await Promise.allSettled([
    sendEmail(payload),
    sendWhatsApp(payload),
  ])
})
```
Kegagalan dicatat ke `notification_logs` dengan `status='failed'` dan di-retry oleh `/api/cron/send-notifications` (maks 3x).

---

## 7. Environment Variables

```env
NEXT_PUBLIC_SUPABASE_URL=
NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY=
SUPABASE_SECRET_KEY=

ALLOWED_EMAIL_DOMAINS=um.ac.id
CRON_SECRET=

SMTP_HOST=
SMTP_PORT=
SMTP_USER=
SMTP_PASS=
MAIL_FROM=

WA_API_URL=
WA_API_KEY=
WA_SENDER=

UPSTASH_REDIS_REST_URL=
UPSTASH_REDIS_REST_TOKEN=
```

> `NEXT_PUBLIC_*` aman di browser. Selain itu **hanya** server-side.

---

## 8. Deployment

1. Push kode ke GitHub.
2. Hubungkan repo ke Vercel.
3. Set seluruh environment variable di §7 (Production, Preview, Development).
4. Jalankan migration SQL (`DATABASE_DESIGN.md`) melalui Supabase SQL Editor / CLI, termasuk ekstensi `btree_gist`, `pgcrypto`, `pg_cron`.
5. Buat bucket `room-images` & `gallery`, set public read + MIME + size limit.
6. Deploy otomatis pada setiap push ke `main`.
7. Verifikasi: `pg_cron` job terdaftar, endpoint `/api/cron/expire-bookings` merespons dengan `x-cron-secret` benar.

---

*Versi 1.1 — perubahan dari 1.0 dirangkum di §0.*