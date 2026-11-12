# Panduan Seed Data Dummy — Sistem Peminjaman Ruang FIP UM

**Versi:** 1.0
**Sumber data:** `Daftar peminjaman ruang FIP.xlsx` (20 sheet jadwal pemakaian ruang FIP)
**Dokumen acuan:** `BUSINESS_RULES.md`, `DATABASE_DESIGN.md`

---

## ⚠️ Penting: Data Ini DUMMY

| Aspek | Status |
|---|---|
| Nama ruang | ✅ **Asli** — diambil dari nama sheet file Excel FIP |
| Nama kegiatan | ✅ **Diadaptasi** dari kegiatan nyata di Excel |
| **Kapasitas ruang** | ❌ **ESTIMASI** — file Excel tidak mencantumkan kapasitas |
| **Lokasi/gedung** | ❌ **ESTIMASI** — sebagian ditebak dari kode ruang |
| Nama orang | ❌ **FIKTIF** — nama asli di Excel diganti |
| No. HP | ❌ **FIKTIF** — pola `0812xxxxxx` |
| Tanggal | ❌ **FIKTIF** — dalam rentang 14 Des 2026 – 12 Jan 2027 |

---

## 1. File dalam Folder Ini

| File | Isi |
|---|---|
| `rooms.csv` | 15 ruang FIP: `code, name, capacity, location, facilities, note` |
| `bookings.csv` | 70 booking: `no, room_code, date, start_time, end_time, activity_name, person_in_charge, phone_number, participant_count, status, admin_note, cancel_reason` |
| `seed.sql` | SQL siap jalan: `operating_hours` + `rooms` + `room_facilities` + `profiles` + `bookings` |
| `SEED_GUIDE.md` | Dokumen ini |

---

## 2. Ringkasan Data

### 2.1 Ruang (15)

| # | Code | Nama | Kapasitas | Gedung |
|---|---|---|---|---|
| 1 | AULA-FIP-D3 | AULA FIP (Gedung D3) | 150 | D3 Lt.1 |
| 2 | HALL-GKB | HALL GKB | 200 | GKB Lt.1 |
| 3 | AULA-D4-LT1 | AULA D4 Lt.1 (D4.103/104) | 120 | D4 Lt.1 |
| 4 | AULA-ORMAWA | AULA ORMAWA | 80 | Ormawa |
| 5 | R-RAPAT-FIP | RUANG RAPAT FIP | 30 | D3 Lt.2 |
| 6 | R-KONFREN-D6102 | R. KONFREN D6.102 | 40 | D6 Lt.1 |
| 7 | TALENT-CENTER-D6 | TALENT CENTER D6 | 60 | D6 Lt.1 |
| 8 | R-INOVASI | R. INOVASI | 40 | D3 Lt.1 |
| 9 | R-TESIS | R. UJIAN TESIS | 20 | D6 Lt.2 |
| 10 | R-DISERTASI | R. UJIAN DISERTASI | 20 | D6 Lt.2 |
| 11 | R-SKRIPSI-D6403 | R. SKRIPSI D6.403 | 15 | D6 Lt.4 |
| 12 | R-SKRIPSI-D6408 | R. SKRIPSI D6.408 | 15 | D6 Lt.4 |
| 13 | R-BELAJAR-S2S3 | R. BELAJAR S2/S3 | 20 | D6 Lt.3 |
| 14 | PERPUS-UJIAN | PERPUSTAKAAN (UJIAN SKRIPSI) | 25 | Perpustakaan Lt.2 |
| 15 | UPP2-B4 | GEDUNG B4 UPP 2 | 50 | B4 |

### 2.2 Booking (70)

| Status | Jumlah | Kegunaan uji |
|---|---|---|
| `approved` | 56 | Tampilan normal, kalender penuh, slot terblokir |
| `pending` | 11 | Dashboard admin, hitung mundur kedaluwarsa, blokir slot |
| `rejected` | 1 | Tampilan alasan penolakan di riwayat user |
| `cancelled` | 1 | Tampilan pembatalan, slot bebas |
| `expired` | 1 | Tampilan kedaluwarsa, slot bebas |

---

## 3. Validasi yang Sudah Dijalankan

Seluruh 70 booking sudah diverifikasi otomatis dan **LULUS 0 error**:

- ✅ `start_time` dan `end_time` **kelipatan 30 menit**
- ✅ `end_time > start_time`, tanggal sama
- ✅ Jam mulai ≥ 07:00
- ✅ Jam selesai ≤ 16:00, **kecuali Jumat ≤ 14:30**
- ✅ `participant_count` ≤ `rooms.capacity`
- ✅ **Tidak ada bentrok** pada ruang + tanggal + waktu yang sama (status `pending`/`approved`)
- ✅ Semua `room_code` ada di `rooms.csv`

---

## 4. Cara Import

### 4.1 Opsi A — Supabase SQL Editor (paling mudah)

1. Pastikan skema sudah dibuat: jalankan seluruh SQL dari `DATABASE_DESIGN.md` §4
   (ekstensi, tabel, RLS, constraint `bookings_no_overlap`, fungsi, view, `pg_cron`).
2. Buka **Supabase Dashboard → SQL Editor**.
3. Copy seluruh isi **`seed.sql`** → paste → **Run**.
4. Jalankan query verifikasi di §5.

### 4.2 Opsi B — Supabase CLI

```bash
supabase link --project-ref <project-ref>
supabase db execute --file docs/seed/seed.sql
```

### 4.3 Opsi C — Import CSV via Studio (terbatas)

1. **Table Editor → `rooms` → Insert → Import from CSV** → pilih `rooms.csv`
   ⚠️ Kolom `facilities` dan `note` tidak map ke tabel `rooms`. Import hanya `code, name, capacity, location`.
2. Fasilitas: jalankan blok `room_facilities` dari `seed.sql` (butuh `rooms` sudah ada).
3. `bookings.csv` **tidak bisa** diimport langsung — perlu mapping `room_code → room_id`, `date+time → timestamptz`, dan `user_id`. **Gunakan `seed.sql`.**

---

## 5. Verifikasi Setelah Import

```sql
-- 1. Jumlah ruang harus 15
select count(*) as total_rooms from rooms;

-- 2. Jumlah fasilitas harus 56
select count(*) as total_facilities from room_facilities;

-- 3. Distribusi status booking harus sesuai tabel 2.2
select status, count(*) from bookings group by status order by status;

-- 4. Jumat harus tutup 14:30
select day_of_week, open_time, close_time from operating_hours where day_of_week = 5;

-- 5. Constraint anti double-booking harus ada
select conname from pg_constraint where conname = 'bookings_no_overlap';

-- 6. Pastikan tidak ada bentrok (harus 0 baris)
select a.id, b.id, a.room_id, a.start_time
from bookings a
join bookings b
  on a.room_id = b.room_id
 and a.id < b.id
 and a.status in ('pending','approved')
 and b.status in ('pending','approved')
 and a.start_time < b.end_time
 and a.end_time > b.start_time;
```

---

## 6. Catatan Penting soal `profiles`

Blok `insert into profiles` memerlukan baris di `auth.users` dengan `id` yang sama:

| id | Email yang harus dibuat | Role |
|---|---|---|
| `11111111-0000-0000-0000-000000000001` | `admin@um.ac.id` | `admin` |
| `11111111-0000-0000-0000-000000000002` | `siti.rahayu@um.ac.id` | `lecturer` |
| `11111111-0000-0000-0000-000000000003` | `rina.kusuma@um.ac.id` | `student` |
| `11111111-0000-0000-0000-000000000004` | `budi.santoso@um.ac.id` | `student` |

**Cara membuat (pilih salah satu):**

**A. Via Supabase Dashboard (disarankan)**
Authentication → Users → **Add user** → isi email → centang "Auto Confirm User".
UUID akan di-generate Supabase — ubah `id` di `seed.sql` agar cocok.

**B. Jalankan `seed.sql` tanpa blok profiles**, lalu ganti `user_id` di `bookings` dengan UUID user asli:
```sql
update bookings
   set user_id = (select id from profiles where role = 'student' limit 1)
 where user_id = '11111111-0000-0000-0000-000000000003';
```

> ⚠️ Trigger `enforce_email_domain` **menolak** email selain `@um.ac.id` — pastikan user uji memakai domain tersebut.

---

## 7. Reset / Bersihkan Data Dummy

```sql
delete from notification_logs;
delete from bookings;
delete from room_facilities;
delete from room_images;
delete from gallery_images;
delete from rooms;
delete from profiles where id::text like '11111111-%';
```

---

## 8. Transformasi dari File Excel Asli

| Kegiatan di `Daftar peminjaman ruang FIP.xlsx` | → Kegiatan dummy |
|---|---|
| `Ujian Skripsi` (S1 PNF) | `Ujian Skripsi` |
| `Ujian tesis S2` | `Ujian Tesis S2 Sesi 1` / `Sesi 2` |
| `Ujian disertasi S3 MP` | `Ujian Disertasi S3` |
| `Rapat Dep TEP` / `Rapat Departemen PGSD` | `Rapat Departemen` |
| `Seminar usulan skripsi` | `Seminar Proposal Skripsi` |
| `Monitoring Publikasi Ilmiah` | `Monitoring Publikasi Ilmiah` |
| `Koordinasi Penyusunan MOU` | `Koordinasi Penyusunan MoU` |
| `PKKMB S1,S2,S3` | `Orientasi Mahasiswa Baru Program Magister` |
| `Kegiatan Pilmapres 2025` | `Seleksi Pilmapres Fakultas` |
| `Benchmarking Universitas Sari Mulia` | `Kunjungan Studi Banding` |
| `Workshop Penulisan Berita Jurnalistik` | `Workshop Penulisan Berita Jurnalistik` |
| `Kuliah Tetap FIK` | `Kuliah Tetap Program Magister` |

**Perbaikan kualitas data yang dilakukan:**
- `JUMLAH PESERTA: "24  orang"` → `24` (integer)
- `JUMLAH PESERTA: "150 kursi"` → `150`
- `WAKTU: "07,00 - 09,00"` → `07:00` / `09:00` (koma → titik dua)
- `WAKTU: "09,30 -"` (tidak lengkap) → diisi durasi wajar
- `WAKTU: "08-00-10.00"` → `08:00` / `10:00`
- Tanggal `"Jum'at, 20 Februari 2026"` → format ISO `2026-02-20`
- Kegiatan bertanda `(cancel)` → status `cancelled`

---

*Versi 1.0*