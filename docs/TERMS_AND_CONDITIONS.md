# SYARAT & KETENTUAN PEMINJAMAN RUANG
## Fakultas Ilmu Pendidikan Universitas Negeri Malang (FIP UM)

**Versi:** 1.0
**Tanggal berlaku:** `[ISI TANGGAL BERLAKU]`
**Status:** **DRAFT** — perlu ditinjau dan disahkan pihak FIP UM sebelum dipublikasikan.

> ⚠️ Dokumen ini adalah **draf**. Sebelum dipakai di produksi, bagian bertanda `[PERLU keputusan FIP UM]` harus diisi dan seluruh isi disetujui pejabat berwenang. Isi versi final juga harus disesuaikan dengan peraturan akademik/kemahasiswaan yang berlaku di FIP UM.

---

## Pasal 1 — Ketentuan Umum

1.1 Sistem Peminjaman Ruang FIP UM adalah layanan berbasis web untuk mengajukan peminjaman ruang kelas dan aula di lingkungan Fakultas Ilmu Pendidikan Universitas Negeri Malang.

1.2 Layanan ini hanya dapat digunakan oleh civitas akademika FIP UM dengan alamat email resmi berdomain **`@um.ac.id`** atau **`@um.ac.id`**.

1.3 Pendaftaran dengan email di luar domain tersebut akan ditolak oleh sistem.

1.4 Pengguna wajib memberikan data yang benar, lengkap, dan terkini saat mendaftar dan mengajukan peminjaman.

---

## Pasal 2 — Jam Operasional Peminjaman

2.1 Ruang hanya dapat dipinjam pada jam operasional berikut (Waktu Indonesia Barat):

| Hari | Jam Operasional |
|---|---|
| Senin – Kamis | 07.00 – 16.00 WIB |
| **Jumat** | **07.00 – 14.30 WIB** |
| Sabtu | 07.00 – 16.00 WIB |
| Minggu | 07.00 – 16.00 WIB |

2.2 Hari Jumat memiliki jam operasional lebih pendek mengikuti ketentuan jam dinas fakultas. Pengajuan yang melewati 14.30 WIB pada hari Jumat akan ditolak sistem.

2.3 Pemakaian ruang di luar jam operasional memerlukan izin tertulis tersendiri dari pihak fakultas dan **tidak** dapat diajukan melalui sistem.

2.4 `[PERLU keputusan FIP UM]` Ketentuan penggunaan ruang pada hari libur nasional.

---

## Pasal 3 — Ketentuan Pengajuan Peminjaman

3.1 Peminjaman diajukan dalam jendela waktu yang ditetapkan Fakultas, yaitu **tidak melewati batas minimal** sebelum tanggal kegiatan dan **tidak melebihi batas maksimal** hari ke depan. Kedua batas tersebut ditampilkan pada formulir pengajuan dan ditegakkan oleh sistem. `[Nilai teknis mengikuti BUSINESS_RULES.md §2 — tidak dicantumkan dalam dokumen ini]`

3.2 Durasi peminjaman **dibatasi oleh sistem** sesuai ketentuan teknis Fakultas. Batas tersebut **ditampilkan secara transparan** pada formulir pengajuan, dan peminjam dianggap telah mengetahui batas tersebut karena hanya dapat mengirim pengajuan yang lolos validasi sistem. `[Nilai teknis mengikuti BUSINESS_RULES.md §2 — tidak dicantumkan dalam dokumen ini]`

3.3 Waktu mulai dan waktu selesai harus berada pada tanggal yang sama (tidak boleh melintasi hari).

3.4 Jumlah peserta yang dicantumkan **tidak boleh melebihi kapasitas** ruang yang dipinjam.

3.5 Data yang wajib diisi meliputi: ruang, tanggal, jam mulai, jam selesai, nama kegiatan, jumlah peserta, nama penanggung jawab, dan nomor HP/WhatsApp yang dapat dihubungi.

3.6 Peminjam wajib mencentang pernyataan persetujuan Syarat & Ketentuan sebelum pengajuan dikirim. Persetujuan dicatat beserta waktu dan versi S&K yang berlaku.

---

## Pasal 4 — Ketersediaan dan Bentrok Jadwal

4.1 Sistem menerapkan prinsip **siapa cepat, dia dapat** (*first-come-first-served*).

4.2 Pengajuan berstatus **menunggu persetujuan (pending)** maupun **disetujui (approved)** dianggap **menempati** slot waktu tersebut dan memblokir pengajuan lain pada ruang dan waktu yang sama.

4.3 Pengajuan berstatus ditolak, dibatalkan, atau kedaluwarsa **tidak** memblokir slot.

4.4 Pengajuan yang tidak diproses oleh admin dalam **batas waktu kedaluwarsa** yang ditetapkan sistem akan **otomatis kedaluwarsa**, dan slot menjadi tersedia kembali bagi peminjam lain. `[Nilai batas mengikuti BUSINESS_RULES.md §3.4]`

4.5 Sistem menolak pengajuan yang bentrok dengan jadwal yang sudah menempati slot, dan peminjam wajib memilih waktu lain.

---

## Pasal 5 — Persetujuan, Penolakan, dan Pembatalan

5.1 Setiap pengajuan berstatus `pending` dan harus disetujui admin fakultas sebelum peminjaman sah.

5.2 Admin berwenang **menyetujui** atau **menolak** pengajuan, disertai alasan/catatan yang wajib diisi.

5.3 Alasan penolakan akan ditampilkan kepada peminjam melalui halaman riwayat, email, dan/atau WhatsApp.

5.4 Peminjam dapat **membatalkan** pengajuan:
   - kapan saja selama status masih `pending`;
   - selama status `approved`, paling lambat **sebelum batas waktu pembatalan** yang ditetapkan sistem. `[Nilai batas mengikuti BUSINESS_RULES.md §7]`

5.5 Pembatalan pada hari pelaksanaan (hari H) **tidak** dapat dilakukan melalui sistem; peminjam wajib menghubungi admin fakultas.

5.6 Perubahan jadwal (reschedule) dilakukan dengan **membatalkan** pengajuan lama lalu **mengajukan pengajuan baru**. Sistem tidak menyediakan fitur ubah jadwal langsung.

5.7 `[PERLU keputusan FIP UM]` Ketentuan sanksi apabila peminjam tidak hadir (no-show) tanpa pembatalan. Versi saat ini: **belum ada sanksi otomatis**.

---

## Pasal 6 — Kewajiban Peminjam

Peminjam wajib:

a. Menggunakan ruang **hanya** untuk kegiatan yang tercantum dalam pengajuan.
b. Menjaga kebersihan, ketertiban, dan keamanan ruang serta seluruh fasilitas di dalamnya.
c. Tidak memindahkan, meminjamkan, atau mengeluarkan fasilitas ruang tanpa izin.
d. Tidak menggunakan ruang untuk kegiatan yang bertentangan dengan peraturan fakultas/universitas, hukum yang berlaku, atau kegiatan politik praktis dan kampanye.
e. Mengakhiri penggunaan ruang sesuai jam selesai yang disetujui.
f. Mengembalikan kondisi ruang seperti semula, mematikan pendingin/AC, lampu, dan peralatan elektronik setelah selesai.
g. Bertanggung jawab penuh atas kerusakan atau kehilangan fasilitas yang terjadi akibat penggunaan oleh pihaknya.
h. Mematuhi arahan petugas/keamanan fakultas.

---

## Pasal 7 — Larangan

Peminjam **dilarang**:

a. Mengalihkan hak peminjaman kepada pihak lain tanpa persetujuan admin.
b. Memakai ruang melebihi kapasitas yang ditetapkan, kecuali dengan izin tertulis.
c. Membawa masuk peralatan yang berpotensi membahayakan atau merusak ruang.
d. Meninggalkan sampah, mengotori dinding/meja, atau melakukan aktivitas yang mengganggu kegiatan fakultas di sekitarnya.
e. Menggunakan ruang setelah jam operasional tanpa izin tertulis.
f. Melakukan aktivitas komersial atau pungutan biaya tanpa izin fakultas.

---

## Pasal 8 — Kerusakan dan Ganti Rugi

8.1 Peminjam bertanggung jawab atas segala kerusakan fasilitas yang timbul selama masa peminjaman.

8.2 Kerusakan akibat kelalaian peminjam dapat dikenakan **ganti rugi** sesuai ketentuan fakultas. `[PERLU keputusan FIP UM — besaran/prosedur ganti rugi]`

8.3 Fakultas berhak menonaktifkan sementara akun peminjam yang terbukti merusak fasilitas, hingga kewajiban ganti rugi diselesaikan.

---

## Pasal 9 — Pembatalan Sepihak oleh Fakultas

9.1 Fakultas berhak **membatalkan atau mengubah** peminjaman yang telah disetujui apabila:
   a. diperlukan untuk kegiatan resmi fakultas/universitas;
   b. terjadi keadaan darurat, pemeliharaan, atau perbaikan ruang;
   c. ditemukan pelanggaran terhadap Syarat & Ketentuan ini.

9.2 Fakultas akan menginformasikan pembatalan tersebut melalui sistem, email, dan/atau WhatsApp.

9.3 Fakultas **tidak** bertanggung jawab atas kerugian tidak langsung yang timbul akibat pembatalan sebagaimana ayat (1).

---

## Pasal 10 — Data Pribadi dan Publikasi Informasi

10.1 Pengguna menyetujui bahwa data berikut **ditampilkan secara publik** pada kalender kegiatan untuk mendukung transparansi penggunaan ruang:
   - **nama kegiatan**;
   - **nama penanggung jawab**;
   - ruang, tanggal, dan jam penggunaan.

10.2 Data berikut **tidak** ditampilkan secara publik dan hanya dapat diakses oleh pemilik data serta admin fakultas:
   - **nomor HP/WhatsApp**;
   - **catatan/alasan admin**;
   - alamat email.

10.3 Data pengguna digunakan semata-mata untuk keperluan administrasi peminjaman dan komunikasi terkait status pengajuan.

10.4 Pengguna berhak mengajukan koreksi atau penghapusan data pribadi dengan menghubungi admin fakultas, dengan tetap memperhatikan ketentuan pengarsipan fakultas.

10.5 `[PERLU keputusan FIP UM]` Rujukan kebijakan perlindungan data pribadi yang berlaku (mis. UU No. 27 Tahun 2022 tentang Pelindungan Data Pribadi).

---

## Pasal 11 — Notifikasi

11.1 Sistem mengirimkan notifikasi melalui **email** dan **WhatsApp** pada nomor yang dicantumkan peminjam, untuk kejadian: pengajuan diterima, disetujui, ditolak, kedaluwarsa, atau dibatalkan.

11.2 Peminjam bertanggung jawab memastikan nomor HP dan email yang dicantumkan **aktif dan benar**. Kegagalan penerimaan notifikasi akibat data yang salah **bukan** tanggung jawab fakultas.

11.3 Status resmi peminjaman selalu dapat diperiksa pada halaman **Riwayat Peminjaman** di sistem dan menjadi acuan utama.

---

## Pasal 12 — Ketersediaan Layanan

12.1 Fakultas berupaya menjaga layanan tersedia, namun **tidak menjamin** layanan bebas gangguan sepenuhnya.

12.2 Gangguan akibat pemeliharaan sistem, gangguan jaringan, atau force majeure akan diinformasikan melalui kanal resmi fakultas.

12.3 `[PERLU keputusan FIP UM]` Prosedur pengajuan darurat apabila sistem tidak dapat diakses.

---

## Pasal 13 — Perubahan Syarat & Ketentuan

13.1 Fakultas berhak mengubah Syarat & Ketentuan ini sewaktu-waktu.

13.2 Perubahan berlaku sejak tanggal berlaku versi baru yang dicantumkan pada dokumen ini.

13.3 Setiap pengajuan peminjaman mencatat versi S&K yang disetujui pada saat pengajuan, sehingga perubahan versi tidak berlaku surut terhadap pengajuan yang sudah dikirim.

---

## Pasal 14 — Penutup

14.1 Hal-hal yang belum diatur dalam Syarat & Ketentuan ini akan ditetapkan lebih lanjut oleh pihak Fakultas Ilmu Pendidikan Universitas Negeri Malang.

14.2 Dengan mencentang pernyataan persetujuan dan mengirimkan pengajuan peminjaman, peminjam menyatakan telah **membaca, memahami, dan menyetujui** seluruh isi Syarat & Ketentuan ini.

---

## Daftar Bagian yang Perlu keputusan FIP UM Sebelum Finalisasi

| No | Bagian | Yang perlu diputuskan |
|---|---|---|
| 1 | Header dokumen | Tanggal berlaku versi 1.0 |
| 2 | Pasal 2.4 | Ketentuan pemakaian pada hari libur nasional |
| 3 | Pasal 5.7 | Ada/tidaknya sanksi no-show |
| 4 | Pasal 8.2 | Besaran & prosedur ganti rugi kerusakan |
| 5 | Pasal 10.5 | Rujukan kebijakan perlindungan data pribadi |
| 6 | Pasal 12.3 | Prosedur pengajuan darurat saat sistem down |
| 7 | Seluruh | Persetujuan & tanda tangan pejabat berwenang |

> **Catatan:** Pasal 3.1 & 3.2 **tidak** lagi memerlukan keputusan angka. Seluruh nilai teknis (granularitas, durasi min/maks, jendela pengajuan) **hanya** didefinisikan di `BUSINESS_RULES.md` §2 dan ditampilkan ke pengguna melalui validasi formulir. Dokumen hukum ini sengaja tidak mencantumkan angka agar tidak perlu direvisi setiap kali ketentuan teknis berubah.

---

*Draf versi 1.0 — disusun sebagai lampiran `BUSINESS_RULES.md`.*