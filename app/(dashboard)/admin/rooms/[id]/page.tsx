export default async function AdminRoomDetailPage({
  params,
}: {
  params: Promise<{ id: string }>
}) {
  const { id } = await params

  return (
    <div className="mx-auto max-w-3xl px-6 py-16">
      <h1 className="text-2xl font-semibold tracking-tight">Ubah Ruang</h1>
      <p className="mt-2 text-neutral-600">
        Detail ruang <code className="text-sm">{id}</code>.
      </p>
    </div>
  )
}