# Panduan Implementasi (README Dev)

**Versi:** 1.1
**Dokumen acuan:** `ARCHITECTURE.md`, `DATABASE_DESIGN.md`, `API_SPEC.md`, `SRS.md`

## 0. Perubahan dari Versi 1.0 (perbaikan bug)

| # | Masalah v1.0 | Perbaikan v1.1 |
|---|---|---|
| 1 | `npx create-next-app --src-dir` **bertentangan** dengan struktur folder di `ARCHITECTURE.md` (tanpa `src/`) | **Hapus `--src-dir`** � semua kode di root |
| 2 | `npm install -D shadcn/ui` **perintah salah** | Ganti `npx shadcn@latest init` |
| 3 | `createServerClient` hanya memakai `cookieStore.get()` dan `cookies()` sinkron � **deprecated** | Pakai `getAll`/`setAll` + `await cookies()` (Next 15) |
| 4 | Tidak ada `middleware.ts` untuk refresh session � **session akan expired** | Ditambahkan �3.3 |
| 5 | Tidak ada env untuk domain email, cron, notifikasi | Ditambahkan �2.3 |
| 6 | Tidak ada langkah seed `operating_hours` (Jumat 14:30) | Ditambahkan �5 |

---

## 1. Prasyarat

- Node.js **v18.18+** (disarankan v20 LTS)
- Akun Supabase
- Akun Vercel
- Git
- (Opsional) Supabase CLI: `npm i -g supabase`

---

## 2. Setup Awal

### 2.1 Inisialisasi Proyek
```bash
npx create-next-app@latest pinjam \
  --typescript \
  --tailwind \
  --eslint \
  --app \
  --import-alias "@/*"
```

> ?? **JANGAN** memakai `--src-dir`. Struktur final mengikuti `ARCHITECTURE.md` �2 (`app/`, `components/`, `lib/` di root).

### 2.2 Install Dependensi
```bash
npm install @supabase/supabase-js @supabase/ssr
npm install @tanstack/react-query
npm install zod clsx tailwind-merge
npm install @upstash/ratelimit @upstash/redis   # rate limiting
npm install resend                              # atau nodemailer untuk SMTP

# Inisialisasi shadcn/ui (BUKAN "npm i -D shadcn/ui")
npx shadcn@latest init
```

### 2.3 Environment Variables
Buat `.env.local` di root:

```env
NEXT_PUBLIC_SUPABASE_URL=https://xxx.supabase.co
NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY=sb_publishable_xxx
SUPABASE_SECRET_KEY=sb_secret_xxx

ALLOWED_EMAIL_DOMAINS=um.ac.id
CRON_SECRET=random-secret-string

SMTP_HOST=smtp.example.com
SMTP_PORT=587
SMTP_USER=noreply@um.ac.id
SMTP_PASS=your_smtp_password
MAIL_FROM="Peminjaman FIP UM <noreply@um.ac.id>"

WA_API_URL=https://api.fonnte.com/send
WA_API_KEY=your_wa_api_key
WA_SENDER=6281xxxxxxxxx

UPSTASH_REDIS_REST_URL=
UPSTASH_REDIS_REST_TOKEN=
```

> ?? `SUPABASE_SECRET_KEY` **hanya** untuk server-side. Jangan pernah diimpor ke komponen `"use client"`.

---

## 3. Konfigurasi Supabase Client (pola terbaru)

### 3.1 `lib/supabase/client.ts` (Browser)
```ts
'use client'

import { createBrowserClient } from '@supabase/ssr'

export function createClient() {
  return createBrowserClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY!
  )
}
```

### 3.2 `lib/supabase/server.ts` (Server / Route Handler)
```ts
import { createServerClient } from '@supabase/ssr'
import { cookies } from 'next/headers'

export async function createClient() {
  const cookieStore = await cookies()   // ?? async di Next 15

  return createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY!,
    {
      cookies: {
        getAll() {
          return cookieStore.getAll()
        },
        setAll(cookiesToSet) {
          try {
            cookiesToSet.forEach(({ name, value, options }) =>
              cookieStore.set(name, value, options)
            )
          } catch {
            // dipanggil dari Server Component � aman diabaikan,
            // refresh session ditangani middleware
          }
        },
      },
    }
  )
}
```

> `get`/`set`/`remove` **sudah deprecated** di `@supabase/ssr`. Wajib memakai `getAll`/`setAll`.

### 3.3 `lib/supabase/middleware.ts` + `middleware.ts` (WAJIB � v1.1 baru)
```ts
// lib/supabase/middleware.ts
import { createServerClient } from '@supabase/ssr'
import { NextResponse, type NextRequest } from 'next/server'

export async function updateSession(request: NextRequest) {
  let response = NextResponse.next({ request })

  const supabase = createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY!,
    {
      cookies: {
        getAll() {
          return request.cookies.getAll()
        },
        setAll(cookiesToSet) {
          cookiesToSet.forEach(({ name, value }) =>
            request.cookies.set(name, value)
          )
          response = NextResponse.next({ request })
          cookiesToSet.forEach(({ name, value, options }) =>
            response.cookies.set(name, value, options)
          )
        },
      },
    }
  )

  // WAJIB: refresh token
  const { data: { user } } = await supabase.auth.getUser()

  // Proteksi route dashboard
  const path = request.nextUrl.pathname
  const isProtected = path.startsWith('/user') || path.startsWith('/admin')
  if (isProtected && !user) {
    const url = request.nextUrl.clone()
    url.pathname = '/login'
    url.searchParams.set('next', path)
    return NextResponse.redirect(url)
  }

  return response
}
```

```ts
// middleware.ts (root)
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

### 3.4 `lib/supabase/admin.ts` (Service Role � server only)
```ts
import { createClient as createSupabaseClient } from '@supabase/supabase-js'

export function createAdminClient() {
  if (typeof window !== 'undefined') {
    throw new Error('createAdminClient hanya boleh dipakai di server')
  }
  return createSupabaseClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.SUPABASE_SECRET_KEY!,
    { auth: { persistSession: false } }
  )
}
```

### 3.5 Catatan API Key (migrasi dari key lama)

Supabase mendeprecate key lama (`anon` dan `service_role`) akhir 2026. Gunakan key baru:

| Key lama | Key baru | Prefix | Dipakai di |
|---|---|---|---|
| `NEXT_PUBLIC_SUPABASE_ANON_KEY` | `NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY` | `sb_publishable_` | Browser, aman dipublikasikan, tetap dibatasi RLS |
| `SUPABASE_SERVICE_ROLE_KEY` | `SUPABASE_SECRET_KEY` | `sb_secret_` | Server saja, **bypass RLS** — jangan pernah expose ke client |

Key baru **bukan JWT** → dikirim lewat header `apikey`, bukan `Authorization: Bearer`. `@supabase/ssr` ≥ 0.6 sudah menangani ini otomatis.

Bila project Supabase Anda masih hanya menyediakan key lama, key lama masih berfungsi sampai deprecation selesai — tapi kode sebaiknya sudah pakai nama baru.

---
---

## 4. Jalankan Proyek Secara Lokal

```bash
npm run dev
```

Buka http://localhost:3000

---

## 5. Migrasi Basis Data

Jalankan SQL dari `DATABASE_DESIGN.md` �4 melalui **Supabase SQL Editor** atau Supabase CLI, **dengan urutan ini**:

1. **Ekstensi**
   ```sql
   create extension if not exists "pgcrypto";
   create extension if not exists "btree_gist";   -- WAJIB untuk EXCLUDE constraint
   ```
2. **Tabel**: `profiles`, `rooms`, `room_facilities`, `room_images`, `gallery_images`, `operating_hours`, `bookings`, `notification_logs`
3. **Seed `operating_hours`** � ?? **jangan lupa Jumat `14:30`**
   ```sql
   insert into operating_hours (day_of_week, open_time, close_time, is_open) values
     (1,'07:00','16:00',true),(2,'07:00','16:00',true),
     (3,'07:00','16:00',true),(4,'07:00','16:00',true),
     (5,'07:00','14:30',true),   -- Jumat
     (6,'07:00','16:00',true),(0,'07:00','16:00',true);
   ```
4. **Constraint anti double-booking**
   ```sql
   alter table bookings
     add constraint bookings_no_overlap
     exclude using gist (
       room_id with =,
       tstzrange(start_time, end_time, '[)') with &&
     ) where (status in ('pending','approved'));
   ```
5. **Function `public.is_admin()`**, **`expire_stale_bookings()`**, **`enforce_email_domain()`**, **`handle_new_user()`** + trigger
6. **RLS policies** (semua tabel) � pastikan RLS **enabled**
7. **View `public_calendar`**
8. **`pg_cron` job** tiap 10 menit
9. **Bucket Storage**: `room-images` & `gallery` (public read, MIME & size limit)

**Verifikasi cepat:**
```sql
-- RLS harus aktif di semua tabel
select tablename, rowsecurity from pg_tables where schemaname = 'public';
-- Constraint anti bentrok harus ada
select conname from pg_constraint where conname = 'bookings_no_overlap';
-- Jumat harus 14:30
select * from operating_hours where day_of_week = 5;
```

```bash
# Alternatif via Supabase CLI
supabase link --project-ref <ref>
supabase db push
```

> **Catatan:** seeding **15 ruang FIP** sudah tersedia di `docs/seed/seed.sql` (lihat `docs/seed/SEED_GUIDE.md`). Jalankan setelah skema selesai dibuat.

---

## 6. Pembagian Tugas Tim (2 Orang)

| Developer | Tanggung Jawab Utama |
|-----------|----------------------|
| Dev 1 | Frontend: seluruh halaman (publik + dashboard), form booking, widget ketersediaan, kalender, galeri, design token |
| Dev 2 | Backend: Route Handlers, validasi Zod, constraint & RLS, cron auto-expire, notifikasi email/WhatsApp, rate limit |

Keduanya berbagi tanggung jawab pada integrasi, testing (`TESTING_PLAN.md`), dan deployment.

---

## 7. Deployment ke Vercel

1. Push semua kode ke GitHub.
2. Vercel ? Add New Project ? Import repo.
3. Set **seluruh** environment variable dari �2.3 (Production, Preview, Development).
4. Jalankan migration (�5) di Supabase production.
5. Deploy.
6. Verifikasi pasca-deploy:
   - `/api/rooms/available` dapat diakses tanpa login
   - `/api/calendar` tidak mengembalikan `phone_number`
   - Register `@gmail.com` ditolak
   - Booking Jumat 15.00 ditolak
   - `pg_cron` job aktif

---

## 8. Perintah Penting

| Perintah | Fungsi |
|----------|--------|
| `npm run dev` | Development server |
| `npm run build` | Build production |
| `npm run start` | Jalankan production build lokal |
| `npm run lint` | ESLint |
| `npm run test` | Unit/integration test (Vitest) |
| `npm run test:e2e` | E2E test (Playwright) |

---

## 9. Catatan Anti-Hallucination

Setiap kali menggunakan AI untuk generate kode:
1. Bandingkan dengan **SRS.md** (fitur apa yang seharusnya ada).
2. Bandingkan dengan **DATABASE_DESIGN.md** (nama tabel & kolom harus persis).
3. Bandingkan dengan **BUSINESS_RULES.md** (jam operasional, durasi, batas kedaluwarsa, aturan cancel).
4. Bandingkan dengan **API_SPEC.md** (kode error & bentuk response).
5. Jangan terima kode yang menambahkan fitur di luar SRS tanpa diskusi tim.

**Jebakan yang sering muncul:**
- ? Hardcode jumlah slot granularitas di banyak file ? ? baca dari `lib/booking-rules.ts` (bersumber `BUSINESS_RULES.md` �2)
- ? Menyalin angka durasi/jendela pengajuan ke dokumen lain ? ? hanya di `BUSINESS_RULES.md` �2, dokumen lain merujuk
- ? Lupa bahwa **Jumat tutup 14:30**
- ? Membuka policy SELECT polos pada `bookings` untuk kalender ? ? pakai view `public_calendar`
- ? Hanya mengandalkan `SELECT` cek bentrok tanpa constraint `EXCLUDE`
- ? Menganggap `pending` tidak memblokir slot ? ? `pending` **memblokir**
- ? Menampilkan/mengembalikan `phone_number` di endpoint publik

---

*Versi 1.1 � perubahan dari 1.0 dirangkum di �0.*
