# PROMPT UNTUK TASK BARU

**Cara pakai:** copy blok di bawah → paste ke chat/task baru → ganti `<TUGAS>`.

> ⚠️ Task/chat baru **tidak bisa** memanggil chat lama. File di disk adalah satu-satunya jembatan konteks. Prompt ini menyuruh task baru membaca `docs/` sehingga konteks lama terserap penuh.

---

## PROMPT UTAMA (copy mulai dari sini)

```
Lanjutkan proyek di d:\latihan_jogja\pinjam

=== WAJIB: BACA FILE INI DULU SEBELUM MELAKUKAN APA PUN ===

1. docs\HANDOFF.md
   -> status proyek, 13 keputusan bisnis TERKUNCI, 6 hal menggantung,
      11 bug yang sudah diperbaiki, 9 aturan main.
      JANGAN tanya ulang hal yang sudah diputuskan di sini.

2. docs\BUSINESS_RULES.md
   -> SUMBER TUNGGAL angka batas (bagian 2). Jam operasional per hari.
      Aturan bentrok, auto-expired, approval, pembatalan, notifikasi.

3. docs\ARCHITECTURE.md
   -> stack teknologi, struktur folder lengkap, alur data, daftar endpoint,
      environment variables, integrasi eksternal.

4. docs\SRS.md
   -> kebutuhan fungsional F1-F11 + non-fungsional + acceptance criteria.
      Jangan menambah fitur di luar dokumen ini.

5. docs\DATABASE_DESIGN.md
   -> skema tabel, RLS policies, constraint EXCLUDE anti double-booking,
      fungsi SQL, view public_calendar, seed data.

6. docs\seed\SEED_GUIDE.md
   -> data dummy: 15 ruang FIP + 70 booking. Cara import & verifikasi.

Opsional sesuai kebutuhan:
- docs\API_SPEC.md          (detail endpoint, kode error, rate limit)
- docs\UI_UX_SPEC.md        (sitemap, design token, wireframe)
- docs\TESTING_PLAN.md      (80+ test case)
- docs\README_DEV.md        (setup Supabase SSR terbaru, migrasi, deploy)
- docs\TERMS_AND_CONDITIONS.md (draf S&K)

=== KONTEKS SINGKAT PROYEK ===

Sistem Peminjaman Ruang berbasis web untuk Fakultas Ilmu Pendidikan (FIP),
Universitas Negeri Malang.

Fakta kunci:
- Domain email login: @um.ac.id SAJA. Domain lain DITOLAK.
- Jam operasional: Senin-Kamis & Sabtu-Minggu 07.00-16.00
                    JUMAT 07.00-14.30 (lebih pendek!)
- Status "pending" MEMBLOKIR slot (first-come-first-served).
- Booking pending otomatis "expired" setelah 72 jam.
- Semua role (mahasiswa/dosen/admin) SETARA untuk peminjaman.
- Approval 1 level, semua admin setara, alasan WAJIB saat approve & reject.
- Kalender PUBLIK: tampilkan nama kegiatan + PJ.
  JANGAN tampilkan phone_number / admin_note.
- Notifikasi via Email + WhatsApp.
- Desain NETRAL/bersih, tidak harus mirip situs referensi.

Status saat ini:
- FASE DOKUMENTASI SELESAI (10 dokumen + 4 file data dummy).
- KODE APLIKASI BELUM DITULIS. Folder proyek hanya berisi docs\.

=== ATURAN KERAS (jangan dilanggar) ===

1. Angka batas (granularitas, durasi min/maks, jendela pengajuan)
   HANYA boleh ada di docs\BUSINESS_RULES.md bagian 2
   dan docs\TESTING_PLAN.md.
   Dokumen lain DILARANG menyalin angka -> wajib merujuk ke bagian 2.
   Kode wajib baca dari satu konstanta lib/booking-rules.ts.

2. JANGAN hardcode jam tutup. Baca dari tabel operating_hours.
   Ingat: Jumat tutup 14.30, bukan 16.00.

3. Anti double-booking WAJIB pakai constraint EXCLUDE USING gist
   di database. SELECT biasa di API tidak cukup (race condition).

4. phone_number dan admin_note tidak boleh keluar lewat endpoint publik.
   Kalender pakai view public_calendar, bukan policy tabel terbuka.

5. Jangan mengarang fitur di luar docs\SRS.md.
   Fitur baru -> tambahkan ke SRS dulu, baru implementasi.

6. Setiap perubahan skema -> catat di docs\DATABASE_DESIGN.md bagian 0 dulu.

7. Dokumen berbahasa Indonesia. Kode & komentar teknis berbahasa Inggris.

8. Struktur folder TANPA src/ (lihat ARCHITECTURE.md bagian 2).

=== TUGAS SAYA SEKARANG ===

<TUGAS>
```

---

## CONTOH PENGISIAN `<TUGAS>`

### Opsi A — Scaffold proyek
```
Scaffold proyek Next.js 15 + TypeScript + Tailwind + shadcn/ui + Supabase
client sesuai docs\ARCHITECTURE.md bagian 2. Buat struktur folder lengkap
dengan file kosong/placeholder, konfigurasi .env.local.example,
middleware.ts untuk refresh session, dan lib/supabase/client.ts +
server.ts + admin.ts memakai pola getAll/setAll terbaru.
Jangan menulis logika bisnis dulu.
```

### Opsi B — Migration SQL
```
Buat migration SQL lengkap dari docs\DATABASE_DESIGN.md bagian 4, siap
copy-paste ke Supabase SQL Editor. Urutan: ekstensi (pgcrypto, btree_gist,
pg_cron) -> tabel -> operating_hours seed (Jumat 14:30) -> constraint
EXCLUDE bookings_no_overlap -> fungsi is_admin/expire_stale_bookings/
enforce_email_domain/handle_new_user -> trigger -> RLS policies semua tabel
-> view public_calendar -> pg_cron job.
Simpan sebagai docs/migrations/001_init.sql
```

### Opsi C — Validasi + API booking
```
Implementasi lib/booking-rules.ts (semua konstanta dari BUSINESS_RULES.md
bagian 2) + lib/validations/booking.ts (Zod) + app/api/bookings/route.ts
(POST) dengan urutan validasi sesuai API_SPEC.md bagian 4.1. Tangkap
error 23P01 dari constraint EXCLUDE dan kembalikan 409 SLOT_UNAVAILABLE.
```

### Opsi D — Halaman publik
```
Implementasi halaman publik: app/(public)/page.tsx (Home + widget cek
ketersediaan), app/api/rooms/available/route.ts, app/(public)/kalender/page.tsx,
dan komponen terkait sesuai UI_UX_SPEC.md. Design token netral, responsive.
```

### Opsi E — Dashboard admin
```
Implementasi dashboard admin: app/(dashboard)/admin/page.tsx,
admin/bookings (list + detail + approve/reject), admin/rooms (CRUD).
Alasan admin WAJIB divalidasi minimal 5 karakter untuk approve dan reject.
```

### Opsi F — Notifikasi
```
Implementasi lib/notifications/email.ts + whatsapp.ts, kirim asinkron setelah
response (pola after()), catat ke notification_logs, retry maks 3x via
app/api/cron/send-notifications/route.ts.
Kegagalan tidak boleh menggagalkan booking.
```

---

## URUTAN YANG DISARANKAN

```
A (scaffold) -> B (migration) -> jalankan seed.sql -> C (validasi + API)
-> D (publik) -> E (admin) -> F (notifikasi) -> TESTING_PLAN
```

---

## PROMPT PENDEK (alternatif, kalau tidak mau copy panjang)

```
Lanjutkan proyek di d:\latihan_jogja\pinjam.
Baca docs\HANDOFF.md, docs\BUSINESS_RULES.md, docs\ARCHITECTURE.md,
docs\SRS.md, docs\DATABASE_DESIGN.md, docs\seed\SEED_GUIDE.md.
Patuhi semua keputusan & aturan di dalamnya. Kode belum ditulis.
Tugas: <TUGAS>
```

---

## PROMPT VERIFIKASI (kalau curiga ada yang tidak konsisten)

```
Baca docs\HANDOFF.md dan seluruh docs\*.md di d:\latihan_jogja\pinjam.
Lakukan audit konsistensi:
1. Pastikan tidak ada sisa "FEB", "Ekonomi", "Muhammadiyah", "D11.", "D12."
2. Pastikan tidak ada domain duplikat "@um.ac.id / @um.ac.id"
3. Pastikan angka batas HANYA ada di BUSINESS_RULES.md bagian 2
   dan TESTING_PLAN.md
4. Pastikan jam Jumat 14:30 konsisten di semua dokumen
5. Laporkan temuan dalam tabel: file, baris, masalah, saran perbaikan.
Jangan ubah file dulu, hanya laporkan.
```

---

## PROMPT REVIEW SEBELUM MULAI KODE

```
Baca docs\HANDOFF.md dan laporkan:
1. Apa saja 13 keputusan bisnis yang sudah terkunci?
2. Apa saja 6 hal yang masih menggantung dan butuh keputusan saya?
3. Apa saja 11 bug yang sudah diperbaiki agar tidak saya ulangi?
4. Apa saja 9 aturan main yang harus dipatuhi?
5. Menurut Anda, apa langkah paling tepat untuk tugas berikutnya dan mengapa?
Jangan tulis kode dulu.
```

---

*File ini pendamping `HANDOFF.md`. Perbarui bila ada dokumen baru.*