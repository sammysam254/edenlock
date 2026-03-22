export default function Home() {
  return (
    <main className="flex min-h-screen flex-col items-center justify-center p-24">
      <div className="text-center">
        <h1 className="text-4xl font-bold mb-4">Eden Dashboard</h1>
        <p className="text-xl mb-8">Device Management System</p>
        <div className="flex gap-4 justify-center">
          <a
            href="/super-admin"
            className="bg-blue-600 text-white px-6 py-3 rounded-lg hover:bg-blue-700"
          >
            Super Admin Dashboard
          </a>
          <a
            href="/admin"
            className="bg-green-600 text-white px-6 py-3 rounded-lg hover:bg-green-700"
          >
            Administrator Dashboard
          </a>
        </div>
      </div>
    </main>
  )
}
