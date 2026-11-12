export default async function AdminBookingDetailPage({
  params,
}: {
  params: Promise<{ id: string }>
}) {
  const { id } = await params

  return (
    <div className="mx-auto max-w-3xl px-6 py-16">
      <h1 className="text-2xl font-semibold tracking-tight">
        Detail Peminjaman
      </h1>
      <p className="mt-2 text-neutral-600">
        Setujui atau tolak peminjaman <code className="text-sm">{id}</code>.
        Alasan wajib diisi.
      </p>
    </div>
  )
}