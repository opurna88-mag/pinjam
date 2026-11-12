# HANDOFF — Titik Serah Terima Proyek

**Terakhir diperbarui:** 11 Desember 2026
**Tujuan file ini:** memungkinkan melanjutkan pekerjaan di **sesi/chat baru** tanpa perlu membaca ulang percakapan lama.

> 📋 **Prompt siap-paste untuk task baru:** lihat **`PROMPT_TASK_BARU.md`** — berisi prompt utama, contoh pengisian tugas (A–F), prompt pendek, prompt verifikasi, dan prompt review.

---

## 1. Apa Proyek Ini

Sistem Peminjaman Ruang berbasis web untuk **Fakultas Ilmu Pendidikan (FIP), Universitas Negeri Malang**.

| Item | Nilai |
|---|---|
| Organisasi | FIP — Fakultas Ilmu Pendidikan |
| Universitas | Universitas Negeri Malang (asumsi dari domain `um.ac.id`) |
| Domain email login | `@um.ac.id` **saja** |
| Referensi tampilan | https://peminjaman.feb-um.com/ (hanya referensi fitur, **desain netral**) |
| Lokasi file kerja | `d:\latihan_jogja\pinjam\docs\` |

---

## 2. Status: FASE DOKUMENTASI — SELESAI ✅

**Kode aplikasi belum ditulis sama sekali.** Folder proyek hanya berisi `docs/`.

### 2.1 Daftar File (15 file)

**Dokumen utama (10)**

| File | Versi | Fungsi |
|---|---|---|
| `SRS.md` | 1.1 | Spesifikasi kebutuhan, F1–F11, acceptance criteria |
| `ARCHITECTURE.md` | 1.2 | Stack, struktur folder, alur data, endpoint, env var |
| `DATABASE_DESIGN.md` | 1.1 | Skema tabel, RLS, constraint anti-bentrok, SQL migrasi |
| `API_SPEC.md` | 1.0 | 31 endpoint + matriks error + rate limit |
| `BUSINESS_RULES.md` | 1.0 | **SUMBER TUNGGAL angka batas** (§2), jam operasional, dll |
| `UI_UX_SPEC.md` | 1.1 | Sitemap, design token, wireframe, aksesibilitas |
| `TERMS_AND_CONDITIONS.md` | 1.0 | Draf S&K 14 pasal (tanpa angka teknis) |
| `TESTING_PLAN.md` | 1.0 | 80+ test case (satu-satunya tempat angka konkret test) |
| `README_DEV.md` | 1.1 | Panduan setup, Supabase SSR terbaru, migrasi, deploy |
| `PROPOSAL.md` | 1.1 | Latar belakang, lingkup, timeline 5 minggu, biaya, risiko |

**Data dummy (4)** — di `docs/seed/`

| File | Isi |
|---|---|
| `rooms.csv` | **15 ruang FIP** (nama asli dari Excel, kapasitas estimasi) |
| `bookings.csv` | **70 booking** (approved=56, pending=11, rejected/cancelled/expired=1 masing-masing) |
| `seed.sql` | SQL siap jalan: `operating_hours` + `rooms` + `room_facilities` + `profiles` + `bookings` |
| `SEED_GUIDE.md` | Cara import, verifikasi, reset, transformasi Excel |

---

## 3. Keputusan Bisnis yang Sudah DIKUNCI

Jangan tanya ulang — semua ini sudah disetujui pemangku kepentingan.

| # | Topik | Keputusan |
|---|---|---|
| 1 | Cakupan | **Replika penuh** — Landing, Galeri, S&K, Cek Ketersediaan publik, Kalender Even, Login/Register, dashboard admin |
| 2 | Registrasi | Hanya `@um.ac.id`. Domain lain **ditolak** |
| 3 | Jam operasional | Senin–Kamis & Sabtu–Minggu **07.00–16.00**; **Jumat 07.00–14.30** |
| 4 | Bentrok `pending` | **Memblokir slot** (first-come-first-served) |
| 5 | Auto-expired | **72 jam** → status `expired`, slot bebas |
| 6 | Kuota & prioritas role | **Tidak ada** — mahasiswa/dosen/admin setara untuk peminjaman |
| 7 | Field booking | ruang, tanggal, jam mulai, jam selesai, nama kegiatan, jumlah peserta, PJ, no. HP, centang S&K |
| 8 | Approval | **1 level**, semua admin setara, **alasan wajib** saat approve & reject |
| 9 | Kalender | **Publik**, nama kegiatan & PJ tampil; no. HP & catatan admin **disembunyikan** |
| 10 | Galeri | Foto gedung/lingkungan + foto per ruang, dikelola admin |
| 11 | Notifikasi | **Email + WhatsApp** |
| 12 | Cancel | Boleh saat `pending`; saat `approved` maks **H-1**; **tanpa sanksi no-show** |
| 13 | Desain | **Netral/bersih**, tidak harus mirip situs referensi |

### Angka batas — hanya di `BUSINESS_RULES.md` §2 🔒

> 🔗 **Rujukan:** seluruh angka batas (granularitas, durasi minimum/maksimum, dan
> jendela pengajuan) **didefinisikan hanya** di **`BUSINESS_RULES.md` §2**.
> File ini sengaja **tidak menyalin nilai apa pun** — buka dokumen tersebut.
>
> - Test case konkret boleh menuliskan nilai → **`TESTING_PLAN.md`**.
> - Kode wajib membaca dari satu sumber: **`lib/booking-rules.ts`**.
> - Jam operasional per hari (termasuk Jumat) → **`BUSINESS_RULES.md` §1** / tabel `operating_hours`.

---

## 4. ⚠️ Yang Masih Menggantung

| # | Soal | Dampak | Tindakan |
|---|---|---|---|
| 1 | **Kapasitas & lokasi ruang masih ESTIMASI** | File Excel FIP tidak mencantumkan kapasitas. Semua baris di `rooms.csv` ditandai `[ESTIMASI]` | Minta data resmi FIP |
| 2 | **Nama universitas "Universitas Negeri Malang" adalah ASUMSI** | Muncul di `TERMS_AND_CONDITIONS.md` baris 2, 14, 196 | Konfirmasi ke pihak FIP |
| 3 | Hari libur nasional | Belum ditangani | Bisa ditambah tabel `holidays` di v2 |
| 4 | Provider WhatsApp & SMTP | Belum dipilih | `Fonnte`/`Wablas` + `Resend`/`SMTP` |
| 5 | Batas foto galeri | `[ASUMSI]` 2 MB, maks 5 foto/ruang | Konfirmasi |
| 6 | Nama orang di data dummy | Fiktif (nama asli Excel diganti) | Tidak perlu tindakan |

---

## 5. Perbaikan Bug yang Sudah Dilakukan (jangan diulang)

| # | Bug lama | Sudah diperbaiki |
|---|---|---|
| 1 | Relasi `profiles ──< room_facilities` salah | → `rooms ──< room_facilities` |
| 2 | Policy `rooms for all using (is_active=true)` bertabrakan | → 4 policy terpisah + `WITH CHECK` |
| 3 | Tanpa `UNIQUE(room_id, facility)` | → ditambahkan |
| 4 | Anti double-booking hanya pseudo-logic | → `EXCLUDE USING gist` + `btree_gist` |
| 5 | `--src-dir` kontradiksi dengan struktur folder | → dihapus, tanpa `src/` |
| 6 | `npm install -D shadcn/ui` perintah salah | → `npx shadcn@latest init` |
| 7 | `cookies()` sinkron + `cookieStore.get()` deprecated | → `await cookies()` + `getAll`/`setAll` |
| 8 | Tidak ada `middleware.ts` (session mati) | → ditambahkan |
| 9 | `/api/rooms/available` hilang dari tabel endpoint | → ditambahkan + 20 endpoint baru |
| 10 | Policy admin rekursif | → helper `public.is_admin()` SECURITY DEFINER |
| 11 | Kalender publik akan bocor `phone_number` | → view `public_calendar` kolom terbatas |

---

## 6. Cara Melanjutkan di Chat Baru

### Langkah 1 — Paste prompt ini

```
Lanjutkan proyek di d:\latihan_jogja\pinjam.

BACA DULU file berikut sebelum melakukan apa pun:
- docs/HANDOFF.md  (status & keputusan terkunci)
- docs/BUSINESS_RULES.md  (sumber tunggal angka batas)
- docs/ARCHITECTURE.md  (stack & struktur folder)
- docs/SRS.md  (fitur F1-F11)
- docs/seed/SEED_GUIDE.md  (data dummy)

Konteks singkat: sistem peminjaman ruang untuk FIP Universitas Negeri Malang,
domain email @um.ac.id, dokumen v1.1 sudah lengkap, data dummy 15 ruang + 70 booking
sudah ada di docs/seed/. Kode aplikasi BELUM ditulis.

Tugas saya sekarang: <isi tugas Anda di sini>
```

### Langkah 2 — Pilih tugas berikutnya

| Opsi | Tugas | Estimasi |
|---|---|---|
| **A** | Scaffold proyek Next.js 15 + Tailwind + shadcn + Supabase client sesuai `ARCHITECTURE.md` §2 | 1 sesi |
| **B** | Buat migration SQL lengkap (ekstensi, tabel, RLS, constraint, fungsi, view, pg_cron) siap copy-paste ke Supabase | 1 sesi |
| **C** | Implementasi validasi `lib/booking-rules.ts` + Zod schema + API route `/api/bookings` | 1–2 sesi |
| **D** | Implementasi halaman publik: Home + widget cek ketersediaan + Kalender Even | 1–2 sesi |
| **E** | Implementasi dashboard admin (approval + kelola ruang) | 1–2 sesi |
| **F** | Implementasi notifikasi email + WhatsApp + cron auto-expire | 1 sesi |

### Langkah 3 — Urutan yang disarankan

```
A (scaffold) → B (migration) → seed.sql → C (validasi + API) → D (publik) → E (admin) → F (notifikasi)
```

---

## 7. Aturan Main Saat Melanjutkan

1. **Jangan mengarang fitur** di luar `SRS.md` — tambahkan ke SRS dulu.
2. **Jangan menyalin angka batas** ke dokumen/file baru — rujuk `BUSINESS_RULES.md` §2.
3. **Jangan hardcode** jam tutup — baca dari tabel `operating_hours`.
4. **Ingat Jumat tutup 14:30**, bukan 16:00.
5. **`pending` memblokir slot** — jangan dianggap kosong.
6. **Anti double-booking wajib** pakai `EXCLUDE` constraint DB, bukan hanya `SELECT` di API.
7. **`phone_number` & `admin_note`** tidak boleh keluar lewat endpoint publik.
8. Dokumen berbahasa **Indonesia**; kode & komentar teknis **Inggris**.
9. Setiap perubahan skema → catat di `DATABASE_DESIGN.md` §0 dulu.

---

*File ini dibuat otomatis sebagai titik serah terima. Perbarui bila ada keputusan baru.*