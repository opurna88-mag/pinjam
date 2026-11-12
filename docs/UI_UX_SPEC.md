# Spesifikasi UI/UX — Sistem Peminjaman Ruang FIP UM

**Versi:** 1.1
**Organisasi:** Fakultas Ilmu Pendidikan, Universitas Negeri Malang
**Domain email login:** `@um.ac.id`
**Prinsip desain:** netral, bersih, rapi, responsif. **Tidak harus meniru** tampilan situs referensi. Fokus pada keterbacaan, kejelasan status, dan kemudahan di perangkat mobile.

---

## 1. Sitemap

```
PUBLIK (tanpa login)
├── /                          Home — hero + widget cek ketersediaan + kalender even
├── /galeri                    Galeri foto gedung/lingkungan + foto ruang
├── /syarat-ketentuan          Syarat & Ketentuan
├── /ruang                     Daftar & pencarian ruang
├── /ruang/[id]                Detail ruang (foto, fasilitas, kapasitas, jadwal)
├── /kalender                  Kalender Even bulanan/mingguan
├── /login                     Login
├── /register                  Register (domain email kampus)
├── /reset-password            Minta link reset
└── /update-password           Set password baru

USER (login)
├── /user                      Beranda user / ringkasan
├── /user/bookings             Riwayat & status booking
├── /user/bookings/new         Form pengajuan peminjaman
├── /user/bookings/[id]        Detail booking
└── /user/profile              Profil

ADMIN (login + role admin)
├── /admin                     Dashboard ringkasan
├── /admin/bookings            Semua booking + filter status
├── /admin/bookings/[id]       Detail + aksi approve/reject
├── /admin/rooms               Kelola ruang (CRUD)
├── /admin/rooms/[id]          Edit ruang + fasilitas + foto
├── /admin/gallery             Kelola galeri
└── /admin/users               Kelola pengguna & role
```

---

## 2. Design Token

### 2.1 Warna (netral + satu aksen)

| Token | Nilai | Pemakaian |
|---|---|---|
| `--bg` | `#FFFFFF` | Latar utama |
| `--surface` | `#F8FAFC` | Kartu, panel |
| `--border` | `#E2E8F0` | Garis, divider |
| `--text` | `#0F172A` | Teks utama |
| `--text-muted` | `#64748B` | Teks sekunder, caption |
| `--accent` | `#1E7A4D` | Tombol utama, link aktif |
| `--accent-hover` | `#186B42` | Hover tombol utama |
| `--danger` | `#DC2626` | Aksi destruktif, status rejected |
| `--warning` | `#D97706` | Status pending |
| `--success` | `#15803D` | Status approved |
| `--info` | `#2563EB` | Info, tooltip |

**Warna badge status:**

| Status | Background | Text |
|---|---|---|
| `pending` | `#FEF3C7` | `#92400E` |
| `approved` | `#DCFCE7` | `#166534` |
| `rejected` | `#FEE2E2` | `#991B1B` |
| `cancelled` | `#F1F5F9` | `#475569` |
| `expired` | `#F1F5F9` | `#64748B` |

### 2.2 Tipografi
- Font: **Inter** (fallback `system-ui, sans-serif`), dimuat via `next/font` dengan `display: swap`.
- Skala: `12 / 14 / 16 / 18 / 20 / 24 / 30 / 36` px. Body 16px, line-height 1.6, heading weight 600.

### 2.3 Spasi & Radius
- Skala spasi kelipatan 4px → 4, 8, 12, 16, 24, 32, 48, 64.
- Radius: `8px` untuk kartu & tombol, `999px` untuk badge/pill.
- Shadow kartu: `0 1px 2px rgba(15,23,42,0.06)`, hover `0 4px 12px rgba(15,23,42,0.10)`.

### 2.4 Breakpoint

| Nama | Lebar | Layout |
|---|---|---|
| `sm` | < 640px | 1 kolom, navbar hamburger, tabel jadi kartu |
| `md` | 640–1024px | 2 kolom grid |
| `lg` | ≥ 1024px | 3–4 kolom grid, sidebar dashboard tampil |

---

## 3. Komponen Inti

| Komponen | Deskripsi |
|---|---|
| `AppHeader` | Logo + nav: Home, Galeri, S&K, Kalender + tombol Login/Register atau menu akun |
| `HeroAvailabilityWidget` | 3 input: Tanggal & Jam Mulai, Tanggal & Jam Selesai, Pilih Ruangan + tombol "Cek Ketersediaan" |
| `RoomSearchCombobox` | Dropdown ruang dengan pencarian ketik (kode/nama), dikelompokkan per gedung |
| `AvailabilityResultPanel` | Dua tab: "Ruangan Tersedia" & "Ruangan Tidak Tersedia" (alasan + jam bentrok) |
| `RoomCard` | Foto cover, kode, nama, lokasi, kapasitas, chip fasilitas, tombol Detail/Pinjam |
| `BookingForm` | Ruang, tanggal, jam mulai/selesai, nama kegiatan, jumlah peserta, PJ, no. HP, checkbox S&K |
| `TimeSlotPicker` | Jam sesuai jam operasional hari terpilih; otomatis menyesuaikan **Jumat 07.00–14.30** |
| `StatusBadge` | Badge status dengan warna §2.1 |
| `CalendarView` | Mode bulan/minggu, filter ruang, klik slot → modal Detail Acara |
| `EventDetailModal` | Nama kegiatan, PJ, ruang, jam, status. Tidak menampilkan no. HP/adm. note |
| `AdminDecisionPanel` | Tombol Setujui/Tolak + textarea alasan wajib + counter karakter |
| `GalleryGrid` | Grid masonry + lightbox |
| `EmptyState` | Ikon + judul + penjelasan + CTA |
| `Toast` | Notifikasi in-app (sukses/gagal/info) |

---

## 4. Wireframe Ringkas

### 4.1 Home `/`
```
┌──────────────────────────────────────────────┐
│ HEADER: Logo | Home Galeri S&K Kalender | Login │
├──────────────────────────────────────────────┤
│ HERO                                         │
│  H1: Peminjaman Ruang FIP UM                 │
│  Sub: Cek ketersediaan & ajukan peminjaman   │
│  ┌──────────────── Card Widget ────────────┐ │
│  │ Tgl & Jam Mulai │ Tgl & Jam Selesai     │ │
│  │ Pilih Ruangan ▾ │ [Cek Ketersediaan]    │ │
│  └─────────────────────────────────────────┘ │
├──────────────────────────────────────────────┤
│ HASIL CEK: [Tersedia (n)] [Tidak Tersedia (m)]│
│  grid RoomCard / list alasan tidak tersedia  │
├──────────────────────────────────────────────┤
│ KALENDER EVEN (bulan berjalan) + filter ruang│
├──────────────────────────────────────────────┤
│ FOOTER: alamat, kontak, link S&K             │
└──────────────────────────────────────────────┘
```

### 4.2 Form Pengajuan `/user/bookings/new`
```
Ruang: R-RAPAT-FIP — RUANG RAPAT FIP (40 orang)
Tanggal: [date picker]     (info: sesuai jendela pengajuan)
Jam Mulai:  [07:00 ▾]      (slot sesuai granularitas)
Jam Selesai:[09:30 ▾]      (info: sesuai batas durasi; perhatikan jam tutup hari terpilih)
Nama Kegiatan: [__________________]
Jumlah Peserta: [___]      (maks sesuai kapasitas ruang)
Penanggung Jawab: [__________________]
No. HP/WhatsApp: [0812________]
[✓] Saya telah membaca dan menyetujui Syarat & Ketentuan
        [Ajukan Peminjaman]
```

> 🔒 **Sumber nilai:** semua angka (granularitas, durasi min/maks, jendela pengajuan) berasal dari `BUSINESS_RULES.md` §2. Wireframe ini hanya menunjukkan **posisi** hint — teks aktual dibangun dari konstanta `lib/booking-rules.ts`, **bukan** ditulis ulang di JSX.
Validasi inline per field, pesan error di bawah field. Tombol disabled sampai field wajib terisi. Ringkasan di atas tombol submit: *"Anda akan meminjam R-RAPAT-FIP pada Selasa, 10 Mar 2026, 07.00–09.30 WIB."*

### 4.3 Dashboard Admin `/admin`
Kartu statistik: **Pending** (badge merah jika > 0), Approved hari ini, Total booking bulan ini, Ruang aktif. Tabel booking `pending` di bawahnya dengan aksi cepat.

### 4.4 Detail Booking Admin — panel keputusan
```
┌ Detail Booking ──────────────────────────┐
│ Status: pending (badge)                  │
│ Ruang, tanggal, jam, kegiatan, peserta   │
│ PJ + No. HP (khusus admin)               │
│ Diajukan: 07 Mar 2026 10:12              │
│ Kedaluwarsa dalam: 71 jam                │
├──────────────────────────────────────────┤
│ Alasan/Catatan Admin *  (wajib, min 5)   │
│ [textarea...............................]│
│ [Setujui]   [Tolak]                      │
└──────────────────────────────────────────┘
```

---

## 5. State & Perilaku

| State | Perilaku |
|---|---|
| Loading | Skeleton card/baris, bukan spinner penuh halaman |
| Empty (belum ada booking) | `EmptyState` + CTA "Ajukan Peminjaman" |
| Empty (hasil cek kosong) | "Tidak ada ruang tersedia pada waktu tersebut" + saran ubah jam |
| Error validasi | Inline merah di bawah field + `aria-invalid` |
| Error server | Toast merah + tombol "Coba lagi" |
| Rate limited | Toast "Terlalu banyak percobaan, coba lagi dalam 1 menit" |
| Slot bentrok | Toast + highlight jam yang bentrok di form |

**Perilaku khusus:**
- Setelah ruang & jam dipilih → sistem otomatis cek ketersediaan sebelum submit (debounce 400ms).
- Tanggal **Jumat** → pilihan jam berhenti di **14.30**, dengan hint "Jumat tutup lebih awal (14.30)".
- Tanggal di luar jendela pengajuan dinonaktifkan di date picker.
- Jumlah peserta > kapasitas → field error langsung.

---

## 6. Aksesibilitas

- Kontras teks minimal **4.5:1** (WCAG AA).
- Semua input punya `<label>` terhubung `htmlFor`.
- Fokus terlihat jelas (`outline` 2px `--accent`, offset 2px).
- Modal: focus trap, `Esc` menutup, `role="dialog"` + `aria-modal="true"`.
- Navigasi keyboard penuh; tabel punya caption.
- Gambar punya `alt` deskriptif; foto ruang diberi `alt` "Foto RUANG RAPAT FIP".

---

## 7. Performa

- Target LCP < 2.5s pada 4G (sesuai NF2 di SRS).
- Gambar: `next/image` dengan `sizes`, format WebP, lazy-load di bawah fold.
- Kalender: render server-side untuk bulan berjalan, client-side untuk navigasi.

---

## 8. Spesifikasi Galeri

- Halaman `/galeri` punya dua seksi bertab:
  1. **Lingkungan Kampus** — grid masonry foto gedung/lingkungan FIP UM.
  2. **Ruangan** — grid per ruang; klik ruang → detail ruang dengan carousel foto.
- Upload (admin): drag & drop, preview, progress bar.
- Batas `[ASUMSI]`: maks 5 foto per ruang, 2 MB per foto, JPG/PNG/WebP.
- Lightbox: panah kiri/kanan, swipe di mobile, `Esc` menutup.
- Foto kosong → placeholder abu-abu + ikon gedung + teks "Foto belum tersedia".

---

## 9. Spesifikasi Kalender Even

- Mode **Bulanan**: grid 7 kolom; setiap hari maks 3 event + "＋n lainnya".
- Mode **Mingguan**: kolom waktu 07.00–16.00 (Jumat berakhir 14.30), event sebagai blok berwarna sesuai status.
- Filter: dropdown ruang (default semua), tombol "Hari ini", navigasi ‹ ›.
- Klik event → `EventDetailModal`: nama kegiatan, PJ, ruang, jam, status.
- **Tidak** menampilkan no. HP atau catatan admin.
- Legenda warna status di atas kalender.
- Mobile: tampilan agenda list per hari, bukan grid sempit.

---

## 10. Halaman Syarat & Ketentuan

- URL publik `/syarat-ketentuan`, konten dari `TERMS_AND_CONDITIONS.md`.
- Tampil sebagai artikel dengan daftar bernomor, lebar baca maks 72ch.
- Tombol "Kembali" dan anchor daftar isi.
- Di form booking, tautan S&K membuka modal S&K agar user tidak kehilangan isian form.

---

*Versi 1.0*