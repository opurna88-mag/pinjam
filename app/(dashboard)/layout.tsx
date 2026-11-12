export default function DashboardLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <div className="flex min-h-screen flex-col bg-neutral-50 text-neutral-900">
      <main className="flex-1">{children}</main>
    </div>
  )
}