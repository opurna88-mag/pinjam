export default async function UserBookingDetailPage({
  params,
}: {
  params: Promise<{ id: string }>
}) {
  const { id } = await params

  return (
    <div className="mx-auto max-w-3xl px-6 py-16">
      <h1 className="text-2xl font-semibold tracking-tight">Detail Peminjaman</h1>
      <p className="mt-2 text-neutral-600">
        Detail peminjaman <code className="text-sm">{id}</code>.
      </p>
    </div>
  )
}