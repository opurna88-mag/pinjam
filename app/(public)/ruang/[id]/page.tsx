export default async function RuangDetailPage({
  params,
}: {
  params: Promise<{ id: string }>
}) {
  const { id } = await params

  return (
    <div className="mx-auto max-w-5xl px-6 py-16">
      <h1 className="text-2xl font-semibold tracking-tight">Detail Ruang</h1>
      <p className="mt-2 text-neutral-600">
        Detail untuk ruang <code className="text-sm">{id}</code> akan
        ditampilkan di sini.
      </p>
    </div>
  )
}