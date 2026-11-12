# Desain Basis Data — Supabase (PostgreSQL)

**Versi:** 1.1
**Dokumen acuan:** `BUSINESS_RULES.md`, `API_SPEC.md`

Dokumen ini berisi skema tabel, relasi, dan Row Level Security (RLS). Semua perubahan skema harus direkam di sini sebelum dieksekusi melalui Supabase Migration.

---

## 0. Perubahan dari Versi 1.0

| # | Perubahan | Alasan |
|---|---|---|
| 1 | **FIX**: relasi `profiles ──< room_facilities` **DIHAPUS** → hanya `rooms ──< room_facilities` | Relasi v1.0 salah; tabel ini tidak punya `profile_id` |
| 2 | **FIX**: policy `rooms` "Only admin can manage rooms" (`for all`) dipecah jadi `INSERT`/`UPDATE`/`DELETE` terpisah dengan `WITH CHECK` | Policy lama bertabrakan dengan policy SELECT publik dan tidak benar-benar mengunci admin |
| 3 | **TAMBAH**: tabel `operating_hours` | Jam operasional per hari (Jumat 07.00–14.30) tidak boleh di-hardcode |
| 4 | **TAMBAH**: tabel `room_images` | Galeri multi-foto per ruang |
| 5 | **TAMBAH**: tabel `gallery_images` | Foto gedung/lingkungan FIP UM |
| 6 | **TAMBAH**: tabel `notification_logs` | Audit pengiriman email/WhatsApp + retry |
| 7 | **TAMBAH**: kolom `bookings` — `activity_name`, `participant_count`, `person_in_charge`, `phone_number`, `decided_at`, `terms_accepted_at`, `terms_version`, `cancel_reason` | Field form & jejak audit S&K |
| 8 | **TAMBAH**: `UNIQUE(room_id, facility)` pada `room_facilities` | Cegah fasilitas duplikat |
| 9 | **TAMBAH**: constraint `EXCLUDE USING gist` pada `bookings` | Anti double-booking kebal race condition |
| 10 | **TAMBAH**: status `expired` + `CHECK` daftar status | Auto-expired booking `pending` (batas: `BUSINESS_RULES.md` §3.4) |
| 11 | **TAMBAH**: fungsi `expire_stale_bookings()` + `pg_cron` | Mekanisme kedaluwarsa |
| 12 | **TAMBAH**: `profiles.phone_number` | Kontak |
| 13 | **TAMBAH**: trigger `handle_new_user` + validasi domain email | Auto-buat profil & batasi email kampus |
| 14 | **TAMBAH**: file `migrations/001_init.sql` — implementasi lengkap §4 (ekstensi → tabel → constraint → fungsi → trigger → RLS → view → pg_cron) | Sumber tunggal eksekusi skema, siap paste ke Supabase SQL Editor |

---

## 1. Tabel Utama

### 1.1 `profiles` (extends Supabase auth.users)

| Kolom | Tipe | Nullable | Keterangan |
|-------|------|----------|------------|
| id | uuid | NO | PK, references `auth.users(id)` ON DELETE CASCADE |
| full_name | text | YES | Nama lengkap |
| phone_number | text | YES | No. HP (v1.1 baru) |
| role | text | NO | `student` (default), `lecturer`, `admin` |
| created_at | timestamptz | NO | default `now()` |
| updated_at | timestamptz | NO | default `now()` |

### 1.2 `rooms`

| Kolom | Tipe | Nullable | Keterangan |
|-------|------|----------|------------|
| id | uuid | NO | PK, default `gen_random_uuid()` |
| name | text | NO | Nama ruang, contoh "RUANG RAPAT FIP" |
| code | text | NO | Kode unik, contoh "R-RAPAT-FIP" |
| capacity | integer | NO | Kapasitas, CHECK `> 0` |
| location | text | YES | Gedung / lantai |
| description | text | YES | Keterangan tambahan |
| image_url | text | YES | Foto cover utama (denormalisasi dari `room_images.is_cover`) |
| is_active | boolean | NO | default `true` |
| created_at | timestamptz | NO | default `now()` |
| updated_at | timestamptz | NO | default `now()` |

### 1.3 `room_facilities`

| Kolom | Tipe | Nullable | Keterangan |
|-------|------|----------|------------|
| id | uuid | NO | PK |
| room_id | uuid | NO | references `rooms(id)` ON DELETE CASCADE |
| facility | text | NO | `AC`, `Proyektor`, `WiFi`, dst. |
| created_at | timestamptz | NO | default `now()` |

**Constraint:** `UNIQUE(room_id, facility)` — v1.1 baru.

### 1.4 `room_images` (v1.1 baru)

| Kolom | Tipe | Nullable | Keterangan |
|-------|------|----------|------------|
| id | uuid | NO | PK |
| room_id | uuid | NO | references `rooms(id)` ON DELETE CASCADE |
| url | text | NO | URL Supabase Storage |
| is_cover | boolean | NO | default `false` |
| sort_order | integer | NO | default `0` |
| created_at | timestamptz | NO | default `now()` |

**Constraint:** maksimal 1 cover per ruang → `CREATE UNIQUE INDEX ... WHERE is_cover = true`.

### 1.5 `gallery_images` (v1.1 baru — foto gedung/lingkungan)

| Kolom | Tipe | Nullable | Keterangan |
|-------|------|----------|------------|
| id | uuid | NO | PK |
| url | text | NO | URL Supabase Storage |
| caption | text | YES | Keterangan foto |
| sort_order | integer | NO | default `0` |
| created_at | timestamptz | NO | default `now()` |

### 1.6 `operating_hours` (v1.1 baru)

| Kolom | Tipe | Nullable | Keterangan |
|-------|------|----------|------------|
| day_of_week | smallint | NO | PK. 0=Minggu … 6=Sabtu (konvensi `EXTRACT(DOW)`) |
| open_time | time | NO | Jam buka WIB |
| close_time | time | NO | Jam tutup WIB (**Jumat `14:30`**) |
| is_open | boolean | NO | default `true`. Jika `false`, tidak boleh booking seharian |
| updated_at | timestamptz | NO | default `now()` |

### 1.7 `bookings`

| Kolom | Tipe | Nullable | Keterangan |
|-------|------|----------|------------|
| id | uuid | NO | PK, default `gen_random_uuid()` |
| user_id | uuid | NO | references `profiles(id)` |
| room_id | uuid | NO | references `rooms(id)` |
| start_time | timestamptz | NO | Waktu mulai |
| end_time | timestamptz | NO | Waktu selesai |
| activity_name | text | NO | Nama kegiatan (v1.1 baru) |
| participant_count | integer | NO | Jumlah peserta > 0 (v1.1 baru) |
| person_in_charge | text | NO | Nama PJ (v1.1 baru) |
| phone_number | text | NO | No. HP/WA (v1.1 baru) |
| purpose | text | YES | Deskripsi tambahan (opsional) |
| status | text | NO | `pending`, `approved`, `rejected`, `cancelled`, `expired` |
| admin_note | text | YES | **WAJIB** saat approve/reject (divalidasi di API) |
| approved_by | uuid | YES | references `profiles(id)` |
| decided_at | timestamptz | YES | Waktu keputusan admin (v1.1 baru) |
| terms_accepted_at | timestamptz | NO | Waktu setuju S&K (v1.1 baru) |
| terms_version | text | NO | Versi S&K yang disetujui (v1.1 baru) |
| cancel_reason | text | YES | Alasan pembatalan (v1.1 baru) |
| created_at | timestamptz | NO | default `now()` |
| updated_at | timestamptz | NO | default `now()` |

### 1.8 `notification_logs` (v1.1 baru)

| Kolom | Tipe | Nullable | Keterangan |
|-------|------|----------|------------|
| id | uuid | NO | PK |
| booking_id | uuid | YES | references `bookings(id)` ON DELETE CASCADE |
| user_id | uuid | YES | Penerima |
| channel | text | NO | `email` \| `whatsapp` |
| event | text | NO | `submitted` / `approved` / `rejected` / `expired` / `cancelled` |
| recipient | text | NO | Email atau nomor HP tujuan |
| status | text | NO | `sent` \| `failed` \| `pending` |
| attempts | smallint | NO | default `0`, maks 3 |
| error_message | text | YES | Pesan error provider |
| created_at | timestamptz | NO | default `now()` |

---

## 2. Relasi Antar Tabel (DIPERBAIKI)

```
profiles (1) ──< (N) bookings            (bookings.user_id)
profiles (1) ──< (N) bookings            (bookings.approved_by)
rooms    (1) ──< (N) bookings            (bookings.room_id)
rooms    (1) ──< (N) room_facilities     (room_facilities.room_id)
rooms    (1) ──< (N) room_images         (room_images.room_id)
bookings (1) ──< (N) notification_logs   (notification_logs.booking_id)
gallery_images                           (tabel mandiri, bukan relasi)
operating_hours                          (tabel referensi, bukan relasi)

⚠️ v1.0 salah menulis `profiles (1) ──< (N) room_facilities`.
   Tabel room_facilities TIDAK memiliki kolom profile_id.
```

---

## 3. Row Level Security (RLS) Policies

### 3.0 Helper function anti-rekursi (WAJIB)

Policy admin pada `profiles` tidak boleh query `profiles` langsung (rekursi). Gunakan:

```sql
create or replace function public.is_admin()
returns boolean
language sql
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid() and role = 'admin'
  );
$$;
```

### 3.1 `profiles`
- **SELECT**: user sendiri (`auth.uid() = id`) atau admin (`public.is_admin()`)
- **INSERT**: hanya user sendiri
- **UPDATE**: user sendiri atau admin

### 3.2 `rooms` (DIPERBAIKI — v1.0 bug)
v1.0 memakai `create policy ... for all using (is_active = true)` yang **bertabrakan** dengan policy SELECT publik dan tidak benar-benar mengunci admin. Diganti:

```sql
alter table rooms enable row level security;

create policy "rooms_select_public"
  on rooms for select
  using (is_active = true or public.is_admin());

create policy "rooms_insert_admin"
  on rooms for insert
  to authenticated
  with check (public.is_admin());

create policy "rooms_update_admin"
  on rooms for update
  to authenticated
  using (public.is_admin())
  with check (public.is_admin());

create policy "rooms_delete_admin"
  on rooms for delete
  to authenticated
  using (public.is_admin());
```

### 3.3 `room_facilities`, `room_images`, `gallery_images`
- **SELECT**: semua orang (publik)
- **INSERT/UPDATE/DELETE**: hanya admin

### 3.4 `operating_hours`
- **SELECT**: semua orang
- **UPDATE**: hanya admin

### 3.5 `bookings`
- **SELECT**: pemilik **ATAU** admin
- **INSERT**: hanya pemilik, `status` harus `pending`
- **UPDATE**: admin (status/admin_note) **ATAU** pemilik untuk cancel
- **DELETE**: hanya admin

```sql
alter table bookings enable row level security;

create policy "bookings_select_own_or_admin"
  on bookings for select
  to authenticated
  using (user_id = auth.uid() or public.is_admin());

create policy "bookings_insert_own"
  on bookings for insert
  to authenticated
  with check (user_id = auth.uid() and status = 'pending');

create policy "bookings_update_admin"
  on bookings for update
  to authenticated
  using (public.is_admin())
  with check (public.is_admin());

create policy "bookings_cancel_own"
  on bookings for update
  to authenticated
  using (user_id = auth.uid() and status in ('pending','approved'))
  with check (user_id = auth.uid() and status = 'cancelled');

create policy "bookings_delete_admin"
  on bookings for delete
  to authenticated
  using (public.is_admin());
```

### 3.6 `notification_logs`
- **SELECT**: hanya admin
- **INSERT**: service role (server-side) saja — tidak ada policy untuk `anon`/`authenticated`

### 3.7 Kalender publik — gunakan VIEW, bukan policy terbuka

Kalender publik **tidak boleh** membuka policy SELECT penuh pada `bookings` (akan membocorkan `phone_number`). Gunakan view dengan kolom terbatas:

```sql
create or replace view public.public_calendar as
select
  b.id,
  b.room_id,
  r.code  as room_code,
  r.name  as room_name,
  b.start_time,
  b.end_time,
  b.activity_name,
  b.person_in_charge,
  b.status
from bookings b
join rooms r on r.id = b.room_id
where b.status in ('pending','approved');
-- TIDAK ADA phone_number, admin_note, user_id
```

> `GET /api/calendar` mengakses view ini lewat **server client** (service role), bukan anon client.

---

## 4. Contoh Query (SQL) — DIPERBAIKI & DIPERLUAS

### 4.1 Ekstensi & tabel `rooms`

```sql
create extension if not exists "pgcrypto";
create extension if not exists "btree_gist";   -- WAJIB untuk EXCLUDE constraint

create table rooms (
  id uuid default gen_random_uuid() primary key,
  name text not null,
  code text not null unique,
  capacity integer not null check (capacity > 0),
  location text,
  description text,
  image_url text,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
```

### 4.2 `operating_hours` + seed (Jumat 14:30)

```sql
create table operating_hours (
  day_of_week smallint primary key check (day_of_week between 0 and 6),
  open_time   time not null,
  close_time  time not null,
  is_open     boolean not null default true,
  updated_at  timestamptz not null default now(),
  check (close_time > open_time)
);

insert into operating_hours (day_of_week, open_time, close_time, is_open) values
  (1, '07:00', '16:00', true),  -- Senin
  (2, '07:00', '16:00', true),  -- Selasa
  (3, '07:00', '16:00', true),  -- Rabu
  (4, '07:00', '16:00', true),  -- Kamis
  (5, '07:00', '14:30', true),  -- Jumat  <-- lebih pendek
  (6, '07:00', '16:00', true),  -- Sabtu
  (0, '07:00', '16:00', true);  -- Minggu
```

### 4.3 `bookings` + anti double-booking (EXCLUDE constraint)

```sql
create table bookings (
  id uuid default gen_random_uuid() primary key,
  user_id uuid not null references profiles(id) on delete cascade,
  room_id uuid not null references rooms(id) on delete restrict,
  start_time timestamptz not null,
  end_time   timestamptz not null,
  activity_name text not null,
  participant_count integer not null check (participant_count > 0),
  person_in_charge text not null,
  phone_number text not null,
  purpose text,
  status text not null default 'pending'
    check (status in ('pending','approved','rejected','cancelled','expired')),
  admin_note text,
  approved_by uuid references profiles(id),
  decided_at timestamptz,
  terms_accepted_at timestamptz not null default now(),
  terms_version text not null default '1.0',
  cancel_reason text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (end_time > start_time)
);

-- ⛔ KUNCI ANTI DOUBLE-BOOKING (kebal race condition)
-- hanya status pending & approved yang memblokir slot
alter table bookings
  add constraint bookings_no_overlap
  exclude using gist (
    room_id with =,
    tstzrange(start_time, end_time, '[)') with &&
  ) where (status in ('pending','approved'));

-- Index untuk query performa
create index bookings_room_time_idx on bookings (room_id, start_time, end_time);
create index bookings_user_idx on bookings (user_id, created_at desc);
create index bookings_status_idx on bookings (status);
```

> **Penting:** predikat `WHERE (status in ('pending','approved'))` membuat booking `rejected`, `cancelled`, dan `expired` **otomatis** tidak memblokir slot — sesuai `BUSINESS_RULES.md` §3.1.

### 4.4 Fungsi auto-expired booking `pending`

```sql
create or replace function public.expire_stale_bookings()
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  affected integer;
begin
  update bookings
     set status = 'expired',
         updated_at = now()
   where status = 'pending'
     and now() > created_at + interval '72 hours';

  get diagnostics affected = row_count;
  return affected;
end;
$$;

-- Jadwalkan tiap 10 menit (butuh ekstensi pg_cron, tersedia di Supabase)
select cron.schedule(
  'expire-stale-bookings',
  '*/10 * * * *',
  $$ select public.expire_stale_bookings(); $$
);
```

---

### 4.5 Trigger auto-profil + validasi domain email

```sql
create or replace function public.enforce_email_domain()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if not (new.email ilike '%@um.ac.id') then
    raise exception 'EMAIL_DOMAIN_NOT_ALLOWED'
      using hint = 'Gunakan email @um.ac.id';
  end if;
  return new;
end;
$$;

create trigger enforce_email_domain_trigger
  before insert on auth.users
  for each row execute function public.enforce_email_domain();

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, full_name, role)
  values (new.id, coalesce(new.raw_user_meta_data->>'full_name', ''), 'student')
  on conflict (id) do nothing;
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();
```

### 4.6 Cek bentrok (dipakai API sebelum INSERT)

```sql
select 1
  from bookings
 where room_id = p_room_id
   and status in ('pending','approved')
   and start_time < p_end
   and end_time   > p_start
 limit 1;
```

> Ini hanya untuk pesan error ramah. **Constraint `EXCLUDE` tetap otoritatif.** API wajib menangkap SQLSTATE `23P01` dan menerjemahkannya ke `409 SLOT_UNAVAILABLE`.

---

## 5. Supabase Storage

| Bucket | Publik baca | Upload | Path | Batas |
|---|---|---|---|---|
| `room-images` | ✅ | admin | `room-images/{room_id}/{filename}` | maks 2 MB, JPG/PNG/WebP `[ASUMSI]` |
| `gallery` | ✅ | admin | `gallery/campus/{filename}` / `gallery/rooms/{room_id}/{filename}` | maks 2 MB, JPG/PNG/WebP `[ASUMSI]` |

```sql
create policy "gallery_public_read"
  on storage.objects for select
  using (bucket_id in ('gallery','room-images'));

create policy "gallery_admin_write"
  on storage.objects for all
  to authenticated
  using (bucket_id in ('gallery','room-images') and public.is_admin())
  with check (bucket_id in ('gallery','room-images') and public.is_admin());
```

Batasan ukuran & MIME juga ditegakkan di **bucket settings** Supabase (`allowed_mime_types`, `file_size_limit`), bukan hanya validasi frontend.

---

## 6. Seed Data — 15 Ruang FIP (TERSEDIA)

Sumber: **`Daftar peminjaman ruang FIP.xlsx`** (20 sheet jadwal pemakaian ruang FIP).

> ✅ Seed lengkap siap jalan ada di **`docs/seed/seed.sql`**.
> 📄 Data mentah: `docs/seed/rooms.csv`, `docs/seed/bookings.csv`.
> 📘 Panduan import & verifikasi: `docs/seed/SEED_GUIDE.md`.

Ringkasan 15 ruang:

| Code | Nama | Kapasitas |
|---|---|---|
| AULA-FIP-D3 | AULA FIP (Gedung D3) | 150 |
| HALL-GKB | HALL GKB | 200 |
| AULA-D4-LT1 | AULA D4 Lt.1 (D4.103/104) | 120 |
| AULA-ORMAWA | AULA ORMAWA | 80 |
| R-RAPAT-FIP | RUANG RAPAT FIP | 30 |
| R-KONFREN-D6102 | R. KONFREN D6.102 | 40 |
| TALENT-CENTER-D6 | TALENT CENTER D6 | 60 |
| R-INOVASI | R. INOVASI | 40 |
| R-TESIS | R. UJIAN TESIS | 20 |
| R-DISERTASI | R. UJIAN DISERTASI | 20 |
| R-SKRIPSI-D6403 | R. SKRIPSI D6.403 | 15 |
| R-SKRIPSI-D6408 | R. SKRIPSI D6.408 | 15 |
| R-BELAJAR-S2S3 | R. BELAJAR S2/S3 | 20 |
| PERPUS-UJIAN | PERPUSTAKAAN (UJIAN SKRIPSI) | 25 |
| UPP2-B4 | GEDUNG B4 UPP 2 | 50 |

> ⚠️ **Kapasitas & lokasi adalah ESTIMASI** — file Excel FIP tidak mencantumkannya. Wajib diverifikasi pihak FIP sebelum go-live.
> Semua baris di `rooms.csv` diberi tanda `[ESTIMASI] kapasitas & lokasi` pada kolom `note`.

Contoh insert minimal (versi lengkap ada di `docs/seed/seed.sql`):

```sql
insert into rooms (name, code, capacity, location) values
  ('AULA FIP (Gedung D3)', 'AULA-FIP-D3', 150, 'Gedung D3 Lt.1'),
  ('HALL GKB',             'HALL-GKB',    200, 'Gedung GKB Lt.1'),
  ('RUANG RAPAT FIP',      'R-RAPAT-FIP',  30, 'Gedung D3 Lt.2')
on conflict (code) do nothing;
```

---

*Versi 1.1 — perubahan dari 1.0 dirangkum di §0.*