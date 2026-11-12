export const metadata = { title: 'Kalender Kegiatan — Peminjaman Ruang FIP UM' }

export default function KalenderPage() {
  return (
    <div className="mx-auto max-w-5xl px-6 py-16">
      <h1 className="text-2xl font-semibold tracking-tight">
        Kalender Kegiatan
      </h1>
      <p className="mt-2 text-neutral-600">
        Jadwal pemakaian ruang FIP UM. Hanya nama kegiatan dan penanggung jawab
        yang ditampilkan.
      </p>
    </div>
  )
}