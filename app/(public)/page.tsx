export const metadata = {
  title: 'Peminjaman Ruang FIP UM',
  description:
    'Sistem Peminjaman Ruang Fakultas Ilmu Pendidikan, Universitas Negeri Malang.',
}

export default function HomePage() {
  return (
    <div className="mx-auto max-w-5xl px-6 py-16">
      <h1 className="text-3xl font-semibold tracking-tight">
        Peminjaman Ruang FIP UM
      </h1>
      <p className="mt-3 max-w-2xl text-neutral-600">
        Ajukan peminjaman ruang, cek ketersediaan, dan lihat kalender kegiatan
        Fakultas Ilmu Pendidikan Universitas Negeri Malang.
      </p>

      <div className="mt-10 rounded-lg border border-neutral-200 p-6">
        <h2 className="text-lg font-medium">Cek Ketersediaan</h2>
        <p className="mt-2 text-sm text-neutral-500">
          Widget cek ketersediaan akan ditampilkan di sini.
        </p>
      </div>
    </div>
  )
}