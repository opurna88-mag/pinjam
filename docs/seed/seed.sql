-- ============================================================
-- SEED DATA DUMMY — Sistem Peminjaman Ruang FIP UM
-- Sumber: docs/seed/rooms.csv + docs/seed/bookings.csv
-- Dokumen acuan: BUSINESS_RULES.md, DATABASE_DESIGN.md
-- ============================================================
-- ⚠️ Jalankan SETELAH tabel & RLS dibuat (DATABASE_DESIGN.md §4).
-- ⚠️ Data ini DUMMY: nama orang fiktif, kapasitas ruang estimasi.
-- ============================================================

-- ------------------------------------------------------------
-- 0. Bersihkan data lama (opsional, hati-hati di production)
-- ------------------------------------------------------------
-- delete from notification_logs;
-- delete from bookings;
-- delete from room_facilities;
-- delete from rooms;

-- ------------------------------------------------------------
-- 1. Jam operasional (Jumat tutup 14:30)
-- ------------------------------------------------------------
insert into operating_hours (day_of_week, open_time, close_time, is_open) values
  (1,'07:00','16:00',true),
  (2,'07:00','16:00',true),
  (3,'07:00','16:00',true),
  (4,'07:00','16:00',true),
  (5,'07:00','14:30',true),   -- Jumat
  (6,'07:00','16:00',true),
  (0,'07:00','16:00',true)
on conflict (day_of_week) do update
  set open_time = excluded.open_time,
      close_time = excluded.close_time,
      is_open = excluded.is_open,
      updated_at = now();

-- ------------------------------------------------------------
-- 2. Ruang (15 ruang dari Daftar peminjaman ruang FIP)
-- ------------------------------------------------------------
insert into rooms (name, code, capacity, location, is_active) values
  ('AULA FIP (Gedung D3)',              'AULA-FIP-D3',      150, 'Gedung D3 Lt.1',        true),
  ('HALL GKB',                          'HALL-GKB',         200, 'Gedung GKB Lt.1',       true),
  ('AULA D4 Lt.1 (D4.103/104)',         'AULA-D4-LT1',      120, 'Gedung D4 Lt.1',        true),
  ('AULA ORMAWA',                       'AULA-ORMAWA',       80, 'Gedung Ormawa',         true),
  ('RUANG RAPAT FIP',                   'R-RAPAT-FIP',       30, 'Gedung D3 Lt.2',        true),
  ('R. KONFREN D6.102',                 'R-KONFREN-D6102',   40, 'Gedung D6 Lt.1',        true),
  ('TALENT CENTER D6',                  'TALENT-CENTER-D6',  60, 'Gedung D6 Lt.1',        true),
  ('R. INOVASI',                        'R-INOVASI',         40, 'Gedung D3 Lt.1',        true),
  ('R. UJIAN TESIS',                    'R-TESIS',           20, 'Gedung D6 Lt.2',        true),
  ('R. UJIAN DISERTASI',                'R-DISERTASI',       20, 'Gedung D6 Lt.2',        true),
  ('R. SKRIPSI D6.403',                 'R-SKRIPSI-D6403',   15, 'Gedung D6 Lt.4',        true),
  ('R. SKRIPSI D6.408',                 'R-SKRIPSI-D6408',   15, 'Gedung D6 Lt.4',        true),
  ('R. BELAJAR S2/S3',                  'R-BELAJAR-S2S3',    20, 'Gedung D6 Lt.3',        true),
  ('PERPUSTAKAAN (UJIAN SKRIPSI)',      'PERPUS-UJIAN',      25, 'Gedung Perpustakaan Lt.2', true),
  ('GEDUNG B4 UPP 2',                   'UPP2-B4',           50, 'Gedung B4',             true)
on conflict (code) do update
  set name = excluded.name,
      capacity = excluded.capacity,
      location = excluded.location,
      updated_at = now();

-- ------------------------------------------------------------
-- 3. Fasilitas per ruang
-- ------------------------------------------------------------
insert into room_facilities (room_id, facility)
select r.id, f.facility
from (values
  ('AULA-FIP-D3',     'AC'), ('AULA-FIP-D3',     'Proyektor'),
  ('AULA-FIP-D3',     'Sound System'), ('AULA-FIP-D3','Mic'),
  ('AULA-FIP-D3',     'WiFi'), ('AULA-FIP-D3',     'Panggung'),

  ('HALL-GKB',        'AC'), ('HALL-GKB',        'Proyektor'),
  ('HALL-GKB',        'Sound System'), ('HALL-GKB','Mic'),
  ('HALL-GKB',        'WiFi'), ('HALL-GKB',        'Panggung'),

  ('AULA-D4-LT1',     'AC'), ('AULA-D4-LT1',     'Proyektor'),
  ('AULA-D4-LT1',     'Sound System'), ('AULA-D4-LT1','Mic'),
  ('AULA-D4-LT1',     'WiFi'),

  ('AULA-ORMAWA',     'AC'), ('AULA-ORMAWA',     'Proyektor'),
  ('AULA-ORMAWA',     'Sound System'), ('AULA-ORMAWA','WiFi'),

  ('R-RAPAT-FIP',     'AC'), ('R-RAPAT-FIP',     'Proyektor'),
  ('R-RAPAT-FIP',     'WiFi'), ('R-RAPAT-FIP',    'Papan Tulis'),

  ('R-KONFREN-D6102', 'AC'), ('R-KONFREN-D6102', 'Proyektor'),
  ('R-KONFREN-D6102', 'WiFi'), ('R-KONFREN-D6102','Papan Tulis'),
  ('R-KONFREN-D6102', 'Mic'),

  ('TALENT-CENTER-D6','AC'), ('TALENT-CENTER-D6','Proyektor'),
  ('TALENT-CENTER-D6','WiFi'), ('TALENT-CENTER-D6','Sound System'),

  ('R-INOVASI',       'AC'), ('R-INOVASI',       'Proyektor'),
  ('R-INOVASI',       'WiFi'), ('R-INOVASI',      'Papan Tulis'),

  ('R-TESIS',         'AC'), ('R-TESIS',         'Proyektor'),
  ('R-TESIS',         'WiFi'), ('R-TESIS',        'Meja Ujian'),

  ('R-DISERTASI',     'AC'), ('R-DISERTASI',     'Proyektor'),
  ('R-DISERTASI',     'WiFi'), ('R-DISERTASI',    'Meja Ujian'),

  ('R-SKRIPSI-D6403', 'AC'), ('R-SKRIPSI-D6403', 'Proyektor'),
  ('R-SKRIPSI-D6403', 'WiFi'), ('R-SKRIPSI-D6403','Meja Ujian'),

  ('R-SKRIPSI-D6408', 'AC'), ('R-SKRIPSI-D6408', 'Proyektor'),
  ('R-SKRIPSI-D6408', 'WiFi'), ('R-SKRIPSI-D6408','Meja Ujian'),

  ('R-BELAJAR-S2S3',  'AC'), ('R-BELAJAR-S2S3',  'Proyektor'),
  ('R-BELAJAR-S2S3',  'WiFi'), ('R-BELAJAR-S2S3', 'Papan Tulis'),

  ('PERPUS-UJIAN',    'AC'), ('PERPUS-UJIAN',    'WiFi'),
  ('PERPUS-UJIAN',    'Meja Ujian'),

  ('UPP2-B4',         'AC'), ('UPP2-B4',         'Proyektor'),
  ('UPP2-B4',         'WiFi'), ('UPP2-B4',       'Sound System')
) as f(code, facility)
join rooms r on r.code = f.code
on conflict (room_id, facility) do nothing;

-- ------------------------------------------------------------
-- 4. Profil dummy (4 user uji)
-- ------------------------------------------------------------
-- ⚠️ Baris ini memerlukan baris di auth.users dengan id yang sama.
--    Buat user via Supabase Auth (Dashboard → Authentication → Add user),
--    atau pakai blok pembuatan auth.users di SEED_GUIDE.md (khusus lokal).
--    Domain email WAJIB @um.ac.id (BUSINESS_RULES.md §4.1).
-- ------------------------------------------------------------
insert into profiles (id, full_name, phone_number, role) values
  ('11111111-0000-0000-0000-000000000001', 'Administrator FIP', '081200000001', 'admin'),
  ('11111111-0000-0000-0000-000000000002', 'Dr. Siti Rahayu',   '081200000002', 'lecturer'),
  ('11111111-0000-0000-0000-000000000003', 'Rina Kusuma',       '081200000003', 'student'),
  ('11111111-0000-0000-0000-000000000004', 'Budi Santoso',      '081200000004', 'student')
on conflict (id) do update
  set full_name = excluded.full_name,
      phone_number = excluded.phone_number,
      role = excluded.role,
      updated_at = now();

-- ------------------------------------------------------------
-- 5. Bookings dummy (70 baris)
-- ------------------------------------------------------------
-- Status: approved=56, pending=11, cancelled=1, rejected=1, expired=1
-- Semua divalidasi: kelipatan 30 menit, dalam jam operasional
-- (Jumat maks 14:30), peserta <= kapasitas, tanpa bentrok ruang+waktu.
-- ------------------------------------------------------------
with seed(user_id, room_code, start_time, end_time, activity_name,
          participant_count, person_in_charge, phone_number,
          status, admin_note, cancel_reason) as (
values
  ('11111111-0000-0000-0000-000000000003', 'AULA-FIP-D3', '2026-12-14 08:00:00+07', '2026-12-14 11:00:00+07', 'Penandatanganan MoU Kerja Sama', 120, 'Dr. Agus Setiawan', '081234500011', 'approved', 'Disetujui. Ruang dan sound system siap.', null),
  ('11111111-0000-0000-0000-000000000004', 'AULA-FIP-D3', '2026-12-15 08:00:00+07', '2026-12-15 12:00:00+07', 'Rapat Senat Fakultas', 90, 'Prof. Hendra Wijaya', '081234500012', 'approved', 'Disetujui. Mohon koordinasi dengan petugas gedung.', null),
  ('11111111-0000-0000-0000-000000000003', 'AULA-FIP-D3', '2026-12-16 13:00:00+07', '2026-12-16 16:00:00+07', 'Sosialisasi Kontrak Kinerja', 110, 'Dr. Retno Palupi', '081234500013', 'approved', 'Disetujui.', null),
  ('11111111-0000-0000-0000-000000000004', 'AULA-FIP-D3', '2026-12-18 08:00:00+07', '2026-12-18 11:30:00+07', 'Seleksi Pilmapres Fakultas', 140, 'Dr. Siti Rahayu', '081234500014', 'approved', 'Disetujui. Perlu mic tambahan.', null),
  ('11111111-0000-0000-0000-000000000002', 'AULA-FIP-D3', '2026-12-21 07:00:00+07', '2026-12-21 12:00:00+07', 'Seminar Nasional Pendidikan', 150, 'Prof. Bambang Prasetyo', '081234500015', 'approved', 'Disetujui. Aula penuh, siapkan kursi cadangan.', null),
  ('11111111-0000-0000-0000-000000000003', 'AULA-FIP-D3', '2026-12-22 13:00:00+07', '2026-12-22 16:00:00+07', 'Workshop Penulisan Karya Ilmiah', 100, 'Dr. Maya Kartika', '081234500016', 'approved', 'Disetujui.', null),
  ('11111111-0000-0000-0000-000000000004', 'AULA-FIP-D3', '2026-12-28 08:00:00+07', '2026-12-28 10:00:00+07', 'Kunjungan Studi Banding', 80, 'Dr. Fajar Nugroho', '081234500017', 'pending', null, null),
  ('11111111-0000-0000-0000-000000000002', 'AULA-FIP-D3', '2027-01-05 09:00:00+07', '2027-01-05 12:00:00+07', 'Orientasi Mahasiswa Baru Program Magister', 130, 'Prof. Hendra Wijaya', '081234500012', 'pending', null, null),
  ('11111111-0000-0000-0000-000000000003', 'HALL-GKB', '2026-12-14 07:00:00+07', '2026-12-14 16:00:00+07', 'Pekan Raya Pendidikan', 190, 'Dr. Anisa Mahmudah', '081234500021', 'approved', 'Disetujui. Gunakan seluruh hall.', null),
  ('11111111-0000-0000-0000-000000000004', 'HALL-GKB', '2026-12-19 08:00:00+07', '2026-12-19 15:00:00+07', 'Job Fair Fakultas', 180, 'Dr. Iwan Kurniawan', '081234500022', 'approved', 'Disetujui.', null),
  ('11111111-0000-0000-0000-000000000002', 'HALL-GKB', '2026-12-20 08:00:00+07', '2026-12-20 13:00:00+07', 'Kegiatan Olahraga Mahasiswa', 150, 'Dr. Rizal Fahmi', '081234500023', 'approved', 'Disetujui.', null),
  ('11111111-0000-0000-0000-000000000003', 'HALL-GKB', '2027-01-09 08:00:00+07', '2027-01-09 12:00:00+07', 'Pameran Inovasi Pembelajaran', 160, 'Prof. Sri Wahyuni', '081234500024', 'pending', null, null),
  ('11111111-0000-0000-0000-000000000004', 'AULA-D4-LT1', '2026-12-15 08:00:00+07', '2026-12-15 12:00:00+07', 'Koordinasi Penyusunan MoU', 100, 'Dr. Agus Setiawan', '081234500011', 'approved', 'Disetujui.', null),
  ('11111111-0000-0000-0000-000000000002', 'AULA-D4-LT1', '2026-12-17 13:00:00+07', '2026-12-17 16:00:00+07', 'Ujian Kelayakan Disertasi', 60, 'Prof. Bambang Prasetyo', '081234500015', 'approved', 'Disetujui. Mohon ruang tenang.', null),
  ('11111111-0000-0000-0000-000000000003', 'AULA-D4-LT1', '2026-12-23 08:00:00+07', '2026-12-23 11:00:00+07', 'Rapat Koordinasi Wakil Dekan', 90, 'Dr. Retno Palupi', '081234500013', 'approved', 'Disetujui.', null),
  ('11111111-0000-0000-0000-000000000004', 'AULA-D4-LT1', '2027-01-07 09:00:00+07', '2027-01-07 12:00:00+07', 'Workshop Kurikulum Program Studi', 95, 'Dr. Maya Kartika', '081234500016', 'pending', null, null),
  ('11111111-0000-0000-0000-000000000002', 'AULA-ORMAWA', '2026-12-14 15:00:00+07', '2026-12-14 16:00:00+07', 'Rapat Koordinasi Organisasi Mahasiswa', 60, 'Dr. Rizal Fahmi', '081234500023', 'approved', 'Disetujui.', null),
  ('11111111-0000-0000-0000-000000000003', 'AULA-ORMAWA', '2026-12-16 07:00:00+07', '2026-12-16 09:00:00+07', 'Latihan Rutin Paduan Suara', 50, 'Dr. Nia Kurniasih', '081234500031', 'approved', 'Disetujui.', null),
  ('11111111-0000-0000-0000-000000000004', 'AULA-ORMAWA', '2026-12-19 08:00:00+07', '2026-12-19 14:00:00+07', 'Pelatihan Kepemimpinan Mahasiswa', 75, 'Dr. Iwan Kurniawan', '081234500022', 'approved', 'Disetujui.', null),
  ('11111111-0000-0000-0000-000000000002', 'AULA-ORMAWA', '2026-12-26 09:00:00+07', '2026-12-26 12:00:00+07', 'Rapat Evaluasi Kegiatan Semester', 55, 'Dr. Nia Kurniasih', '081234500031', 'cancelled', 'Kegiatan ditunda ke semester berikutnya', 'Acara dijadwalkan ulang'),
  ('11111111-0000-0000-0000-000000000003', 'R-RAPAT-FIP', '2026-12-14 08:00:00+07', '2026-12-14 10:00:00+07', 'Rapat Departemen', 28, 'Dr. Siti Rahayu', '081234500014', 'approved', 'Disetujui.', null),
  ('11111111-0000-0000-0000-000000000004', 'R-RAPAT-FIP', '2026-12-15 10:00:00+07', '2026-12-15 12:00:00+07', 'Rapat Koordinasi Bidang Akademik', 25, 'Dr. Retno Palupi', '081234500013', 'approved', 'Disetujui.', null),
  ('11111111-0000-0000-0000-000000000002', 'R-RAPAT-FIP', '2026-12-17 13:00:00+07', '2026-12-17 15:00:00+07', 'Rapat Evaluasi Program Kerja', 30, 'Prof. Hendra Wijaya', '081234500012', 'approved', 'Disetujui.', null),
  ('11111111-0000-0000-0000-000000000003', 'R-RAPAT-FIP', '2026-12-18 08:00:00+07', '2026-12-18 11:00:00+07', 'Rapat Pengisian Sister Dosen', 20, 'Dr. Agus Setiawan', '081234500011', 'approved', 'Disetujui.', null),
  ('11111111-0000-0000-0000-000000000004', 'R-RAPAT-FIP', '2026-12-22 09:00:00+07', '2026-12-22 11:00:00+07', 'Rapat Home Base Dosen', 26, 'Dr. Maya Kartika', '081234500016', 'approved', 'Disetujui.', null),
  ('11111111-0000-0000-0000-000000000002', 'R-RAPAT-FIP', '2026-12-29 08:00:00+07', '2026-12-29 10:00:00+07', 'Rapat Koordinasi Tendik', 18, 'Dr. Fajar Nugroho', '081234500017', 'pending', null, null),
  ('11111111-0000-0000-0000-000000000003', 'R-KONFREN-D6102', '2026-12-14 08:00:00+07', '2026-12-14 10:00:00+07', 'Monitoring Publikasi Ilmiah', 35, 'Prof. Sri Wahyuni', '081234500024', 'approved', 'Disetujui.', null),
  ('11111111-0000-0000-0000-000000000004', 'R-KONFREN-D6102', '2026-12-16 10:00:00+07', '2026-12-16 12:00:00+07', 'Koordinasi Jurnal Fakultas', 30, 'Dr. Anisa Mahmudah', '081234500021', 'approved', 'Disetujui.', null),
  ('11111111-0000-0000-0000-000000000002', 'R-KONFREN-D6102', '2026-12-21 13:00:00+07', '2026-12-21 15:30:00+07', 'Workshop Penulisan Berita Jurnalistik', 38, 'Dr. Rizal Fahmi', '081234500023', 'approved', 'Disetujui.', null),
  ('11111111-0000-0000-0000-000000000003', 'R-KONFREN-D6102', '2027-01-06 08:00:00+07', '2027-01-06 11:00:00+07', 'Rapat Penyusunan Borang Akreditasi', 40, 'Prof. Bambang Prasetyo', '081234500015', 'approved', 'Disetujui.', null),
  ('11111111-0000-0000-0000-000000000004', 'TALENT-CENTER-D6', '2026-12-15 13:00:00+07', '2026-12-15 16:00:00+07', 'Pelatihan Keterampilan Digital', 55, 'Dr. Iwan Kurniawan', '081234500022', 'approved', 'Disetujui.', null),
  ('11111111-0000-0000-0000-000000000002', 'TALENT-CENTER-D6', '2026-12-17 08:00:00+07', '2026-12-17 12:00:00+07', 'Kuliah Umum Kewirausahaan', 60, 'Dr. Nia Kurniasih', '081234500031', 'approved', 'Disetujui.', null),
  ('11111111-0000-0000-0000-000000000003', 'TALENT-CENTER-D6', '2026-12-24 09:00:00+07', '2026-12-24 11:00:00+07', 'Rapat Kesiapan Kerja Sama Industri', 40, 'Dr. Fajar Nugroho', '081234500017', 'approved', 'Disetujui.', null),
  ('11111111-0000-0000-0000-000000000004', 'R-INOVASI', '2026-12-14 10:00:00+07', '2026-12-14 12:00:00+07', 'Koordinasi Inovasi Pembelajaran', 35, 'Dr. Maya Kartika', '081234500016', 'approved', 'Disetujui.', null),
  ('11111111-0000-0000-0000-000000000002', 'R-INOVASI', '2026-12-16 13:00:00+07', '2026-12-16 16:00:00+07', 'Diskusi Kelompok Riset', 30, 'Prof. Sri Wahyuni', '081234500024', 'approved', 'Disetujui.', null),
  ('11111111-0000-0000-0000-000000000003', 'R-INOVASI', '2026-12-23 08:00:00+07', '2026-12-23 10:00:00+07', 'Presentasi Produk Inovasi Mahasiswa', 38, 'Dr. Anisa Mahmudah', '081234500021', 'pending', null, null),
  ('11111111-0000-0000-0000-000000000004', 'R-TESIS', '2026-12-14 08:00:00+07', '2026-12-14 10:00:00+07', 'Ujian Tesis S2 Sesi 1', 18, 'Prof. Hendra Wijaya', '081234500012', 'approved', 'Disetujui.', null),
  ('11111111-0000-0000-0000-000000000002', 'R-TESIS', '2026-12-14 13:00:00+07', '2026-12-14 15:00:00+07', 'Ujian Tesis S2 Sesi 2', 16, 'Prof. Hendra Wijaya', '081234500012', 'approved', 'Disetujui.', null),
  ('11111111-0000-0000-0000-000000000003', 'R-TESIS', '2026-12-15 09:00:00+07', '2026-12-15 11:00:00+07', 'Ujian Tesis S2 Sesi 1', 15, 'Prof. Bambang Prasetyo', '081234500015', 'approved', 'Disetujui.', null),
  ('11111111-0000-0000-0000-000000000004', 'R-TESIS', '2026-12-17 10:00:00+07', '2026-12-17 12:00:00+07', 'Ujian Tesis S2 Sesi 2', 14, 'Prof. Bambang Prasetyo', '081234500015', 'approved', 'Disetujui.', null),
  ('11111111-0000-0000-0000-000000000002', 'R-TESIS', '2026-12-21 08:00:00+07', '2026-12-21 10:30:00+07', 'Ujian Tesis S2 Sesi 1', 17, 'Prof. Sri Wahyuni', '081234500024', 'approved', 'Disetujui.', null),
  ('11111111-0000-0000-0000-000000000003', 'R-TESIS', '2026-12-22 13:00:00+07', '2026-12-22 15:00:00+07', 'Ujian Tesis S2 Sesi 2', 12, 'Prof. Sri Wahyuni', '081234500024', 'pending', null, null),
  ('11111111-0000-0000-0000-000000000004', 'R-DISERTASI', '2026-12-15 08:00:00+07', '2026-12-15 11:00:00+07', 'Ujian Disertasi S3', 19, 'Prof. Bambang Prasetyo', '081234500015', 'approved', 'Disetujui. Mohon penguji lengkap hadir.', null),
  ('11111111-0000-0000-0000-000000000002', 'R-DISERTASI', '2026-12-18 08:00:00+07', '2026-12-18 11:00:00+07', 'Ujian Disertasi S3', 18, 'Prof. Hendra Wijaya', '081234500012', 'approved', 'Disetujui.', null),
  ('11111111-0000-0000-0000-000000000003', 'R-DISERTASI', '2026-12-28 09:00:00+07', '2026-12-28 12:00:00+07', 'Ujian Kelayakan Disertasi', 16, 'Prof. Sri Wahyuni', '081234500024', 'approved', 'Disetujui.', null),
  ('11111111-0000-0000-0000-000000000004', 'R-SKRIPSI-D6403', '2026-12-14 08:00:00+07', '2026-12-14 09:30:00+07', 'Ujian Skripsi', 12, 'Dr. Siti Rahayu', '081234500014', 'approved', 'Disetujui.', null),
  ('11111111-0000-0000-0000-000000000002', 'R-SKRIPSI-D6403', '2026-12-14 10:00:00+07', '2026-12-14 11:30:00+07', 'Ujian Skripsi', 11, 'Dr. Siti Rahayu', '081234500014', 'approved', 'Disetujui.', null),
  ('11111111-0000-0000-0000-000000000003', 'R-SKRIPSI-D6403', '2026-12-15 13:00:00+07', '2026-12-15 14:30:00+07', 'Ujian Skripsi', 10, 'Dr. Fajar Nugroho', '081234500017', 'approved', 'Disetujui.', null),
  ('11111111-0000-0000-0000-000000000004', 'R-SKRIPSI-D6403', '2026-12-16 08:00:00+07', '2026-12-16 09:30:00+07', 'Seminar Proposal Skripsi', 14, 'Dr. Nia Kurniasih', '081234500031', 'approved', 'Disetujui.', null),
  ('11111111-0000-0000-0000-000000000002', 'R-SKRIPSI-D6403', '2026-12-21 10:00:00+07', '2026-12-21 11:30:00+07', 'Ujian Skripsi', 13, 'Dr. Nia Kurniasih', '081234500031', 'approved', 'Disetujui.', null),
  ('11111111-0000-0000-0000-000000000003', 'R-SKRIPSI-D6408', '2026-12-14 09:00:00+07', '2026-12-14 10:30:00+07', 'Ujian Skripsi', 12, 'Dr. Anisa Mahmudah', '081234500021', 'approved', 'Disetujui.', null),
  ('11111111-0000-0000-0000-000000000004', 'R-SKRIPSI-D6408', '2026-12-15 08:00:00+07', '2026-12-15 09:30:00+07', 'Ujian Skripsi', 11, 'Dr. Anisa Mahmudah', '081234500021', 'approved', 'Disetujui.', null),
  ('11111111-0000-0000-0000-000000000002', 'R-SKRIPSI-D6408', '2026-12-17 13:00:00+07', '2026-12-17 15:00:00+07', 'Seminar Proposal Skripsi', 14, 'Dr. Iwan Kurniawan', '081234500022', 'approved', 'Disetujui.', null),
  ('11111111-0000-0000-0000-000000000003', 'R-SKRIPSI-D6408', '2026-12-22 10:00:00+07', '2026-12-22 11:30:00+07', 'Ujian Skripsi', 10, 'Dr. Rizal Fahmi', '081234500023', 'pending', null, null),
  ('11111111-0000-0000-0000-000000000004', 'R-BELAJAR-S2S3', '2026-12-14 13:00:00+07', '2026-12-14 16:00:00+07', 'Kuliah Tetap Program Magister', 19, 'Prof. Hendra Wijaya', '081234500012', 'approved', 'Disetujui.', null),
  ('11111111-0000-0000-0000-000000000002', 'R-BELAJAR-S2S3', '2026-12-16 08:00:00+07', '2026-12-16 11:00:00+07', 'Kuliah Tetap Program Doktor', 17, 'Prof. Bambang Prasetyo', '081234500015', 'approved', 'Disetujui.', null),
  ('11111111-0000-0000-0000-000000000003', 'R-BELAJAR-S2S3', '2026-12-18 09:00:00+07', '2026-12-18 11:00:00+07', 'Koordinasi Dosen Pembimbing', 15, 'Dr. Maya Kartika', '081234500016', 'approved', 'Disetujui.', null),
  ('11111111-0000-0000-0000-000000000004', 'R-BELAJAR-S2S3', '2026-12-24 13:00:00+07', '2026-12-24 15:00:00+07', 'Presentasi Karya Ilmiah Mahasiswa Pascasarjana', 20, 'Prof. Sri Wahyuni', '081234500024', 'pending', null, null),
  ('11111111-0000-0000-0000-000000000002', 'PERPUS-UJIAN', '2026-12-15 08:00:00+07', '2026-12-15 10:00:00+07', 'Ujian Skripsi', 20, 'Dr. Retno Palupi', '081234500013', 'approved', 'Disetujui.', null),
  ('11111111-0000-0000-0000-000000000003', 'PERPUS-UJIAN', '2026-12-17 10:00:00+07', '2026-12-17 12:00:00+07', 'Ujian Skripsi', 18, 'Dr. Retno Palupi', '081234500013', 'approved', 'Disetujui.', null),
  ('11111111-0000-0000-0000-000000000004', 'UPP2-B4', '2026-12-14 08:00:00+07', '2026-12-14 11:00:00+07', 'Rapat Koordinasi Unit Pelayanan Pendidikan', 45, 'Dr. Agus Setiawan', '081234500011', 'approved', 'Disetujui.', null),
  ('11111111-0000-0000-0000-000000000002', 'UPP2-B4', '2026-12-19 13:00:00+07', '2026-12-19 16:00:00+07', 'Pelatihan Layanan Akademik', 40, 'Dr. Fajar Nugroho', '081234500017', 'approved', 'Disetujui.', null),
  ('11111111-0000-0000-0000-000000000003', 'UPP2-B4', '2026-12-26 08:00:00+07', '2026-12-26 10:00:00+07', 'Koordinasi Penerimaan Mahasiswa Baru', 35, 'Dr. Siti Rahayu', '081234500014', 'rejected', 'Maaf ruang sedang dalam perbaikan fasilitas pendingin ruangan.', null),
  ('11111111-0000-0000-0000-000000000004', 'AULA-D4-LT1', '2026-12-25 08:00:00+07', '2026-12-25 12:00:00+07', 'Seminar Proposal Skripsi', 85, 'Dr. Rizal Fahmi', '081234500023', 'expired', null, null),
  ('11111111-0000-0000-0000-000000000002', 'AULA-FIP-D3', '2027-01-08 08:00:00+07', '2027-01-08 10:30:00+07', 'Kuliah Umum Pendidikan Inklusif', 120, 'Prof. Sri Wahyuni', '081234500024', 'pending', null, null),
  ('11111111-0000-0000-0000-000000000003', 'HALL-GKB', '2027-01-12 09:00:00+07', '2027-01-12 15:00:00+07', 'Musyawarah Mahasiswa Fakultas', 175, 'Dr. Iwan Kurniawan', '081234500022', 'pending', null, null),
  ('11111111-0000-0000-0000-000000000004', 'R-RAPAT-FIP', '2027-01-08 13:00:00+07', '2027-01-08 14:30:00+07', 'Koordinasi Persiapan Akreditasi', 22, 'Dr. Anisa Mahmudah', '081234500021', 'approved', 'Disetujui.', null),
  ('11111111-0000-0000-0000-000000000002', 'R-KONFREN-D6102', '2027-01-09 08:00:00+07', '2027-01-09 11:00:00+07', 'Sosialisasi Panduan Tugas Akhir', 36, 'Dr. Nia Kurniasih', '081234500031', 'approved', 'Disetujui.', null),
  ('11111111-0000-0000-0000-000000000003', 'AULA-D4-LT1', '2027-01-09 13:00:00+07', '2027-01-09 16:00:00+07', 'Workshop Media Pembelajaran Digital', 90, 'Dr. Maya Kartika', '081234500016', 'approved', 'Disetujui.', null),
  ('11111111-0000-0000-0000-000000000004', 'TALENT-CENTER-D6', '2027-01-09 10:00:00+07', '2027-01-09 12:00:00+07', 'Klinik Konsultasi Karier', 45, 'Dr. Fajar Nugroho', '081234500017', 'approved', 'Disetujui.', null)
)
insert into bookings (
  user_id, room_id, start_time, end_time, activity_name,
  participant_count, person_in_charge, phone_number,
  status, admin_note, cancel_reason,
  terms_accepted_at, terms_version,
  approved_by, decided_at
)
select
  s.user_id::uuid, r.id,
  s.start_time::timestamptz, s.end_time::timestamptz,
  s.activity_name, s.participant_count, s.person_in_charge, s.phone_number,
  s.status, s.admin_note, s.cancel_reason,
  now(), '1.0',
  case when s.status in ('approved','rejected')
       then '11111111-0000-0000-0000-000000000001'::uuid else null end,
  case when s.status in ('approved','rejected') then now() else null end
from seed s
join rooms r on r.code = s.room_code
where not exists (
  select 1 from bookings b
  where b.room_id = r.id
    and b.start_time = s.start_time::timestamptz
    and b.end_time = s.end_time::timestamptz
);

-- ------------------------------------------------------------
-- 6. Verifikasi
-- ------------------------------------------------------------
-- select count(*) as total_rooms from rooms;                  -- harap: 15
-- select count(*) as total_facilities from room_facilities;    -- harap: 56
-- select status, count(*) from bookings group by status order by status;
-- select * from operating_hours where day_of_week = 5;         -- Jumat 14:30
-- select conname from pg_constraint where conname = 'bookings_no_overlap';

-- ============================================================
-- SELESAI
-- ============================================================