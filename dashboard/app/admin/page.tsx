'use client'

import { useState, useEffect, FormEvent } from 'react'
import { supabase } from '@/lib/supabase'

// Types
interface Customer {
  id: string
  customer_code: string
  full_name: string
  phone: string
  email?: string
  national_id?: string
  address?: string
  is_active: boolean
  created_at: string
}

interface Device {
  id: string
  device_code: string
  imei: string
  customer_id?: string
  device_model?: string
  device_price: number
  down_payment: number
  loan_total: number
  loan_balance: number
  daily_payment: number
  is_locked: boolean
  status: string
  last_payment_date?: string
  last_payment_amount?: number
  total_paid?: number
  days_overdue?: number
  enrolled_at: string
}

interface PaymentTransaction {
  id: string
  transaction_code: string
  device_id: string
  amount: number
  payment_method: string
  mpesa_receipt?: string
  status: string
  processed_at: string
}

type Section = 'dashboard' | 'customers' | 'devices' | 'payments' | 'reports'

export default function AdministratorDashboard() {
  const [activeSection, setActiveSection] = useState<Section>('dashboard')
  const [customers, setCustomers] = useState<Customer[]>([])
  const [devices, setDevices] = useState<Device[]>([])
  const [payments, setPayments] = useState<PaymentTransaction[]>([])
  const [loading, setLoading] = useState(true)

  // Statistics
  const [stats, setStats] = useState({
    totalDevices: 0,
    activeLoans: 0,
    totalCollected: 0,
    overdueDevices: 0
  })

  useEffect(() => {
    fetchData()
  }, [])

  const fetchData = async () => {
    setLoading(true)
    await Promise.all([
      fetchCustomers(),
      fetchDevices(),
      fetchPayments()
    ])
    setLoading(false)
  }

  const fetchCustomers = async () => {
    try {
      const { data, error } = await supabase
        .from('customers')
        .select('*')
        .order('created_at', { ascending: false })

      if (error) throw error
      setCustomers(data || [])
    } catch (error) {
      console.error('Error fetching customers:', error)
    }
  }

  const fetchDevices = async () => {
    try {
      const { data, error } = await supabase
        .from('devices')
        .select('*')
        .order('enrolled_at', { ascending: false })

      if (error) throw error
      setDevices(data || [])

      // Calculate statistics
      const totalDevices = data?.length || 0
      const activeLoans = data?.filter(d => d.loan_balance > 0).length || 0
      const totalCollected = data?.reduce((sum, d) => sum + (d.total_paid || 0), 0) || 0
      const overdueDevices = data?.filter(d => d.days_overdue > 0).length || 0

      setStats({ totalDevices, activeLoans, totalCollected, overdueDevices })
    } catch (error) {
      console.error('Error fetching devices:', error)
    }
  }

  const fetchPayments = async () => {
    try {
      const { data, error } = await supabase
        .from('payment_transactions')
        .select('*')
        .order('processed_at', { ascending: false })
        .limit(50)

      if (error) throw error
      setPayments(data || [])
    } catch (error) {
      console.error('Error fetching payments:', error)
    }
  }

  if (loading) {
    return (
      <div className="flex items-center justify-center min-h-screen">
        <div className="text-xl">Loading...</div>
      </div>
    )
  }

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Navigation */}
      <nav className="bg-white shadow-md">
        <div className="max-w-7xl mx-auto px-4">
          <div className="flex justify-between items-center h-16">
            <h1 className="text-2xl font-bold text-gray-900">Administrator Dashboard</h1>
            <div className="flex space-x-4">
              <button
                onClick={() => setActiveSection('dashboard')}
                className={`px-4 py-2 rounded ${activeSection === 'dashboard' ? 'bg-blue-600 text-white' : 'text-gray-600 hover:bg-gray-100'}`}
              >
                Dashboard
              </button>
              <button
                onClick={() => setActiveSection('customers')}
                className={`px-4 py-2 rounded ${activeSection === 'customers' ? 'bg-blue-600 text-white' : 'text-gray-600 hover:bg-gray-100'}`}
              >
                Customers
              </button>
              <button
                onClick={() => setActiveSection('devices')}
                className={`px-4 py-2 rounded ${activeSection === 'devices' ? 'bg-blue-600 text-white' : 'text-gray-600 hover:bg-gray-100'}`}
              >
                Devices
              </button>
              <button
                onClick={() => setActiveSection('payments')}
                className={`px-4 py-2 rounded ${activeSection === 'payments' ? 'bg-blue-600 text-white' : 'text-gray-600 hover:bg-gray-100'}`}
              >
                Payments
              </button>
              <button
                onClick={() => setActiveSection('reports')}
                className={`px-4 py-2 rounded ${activeSection === 'reports' ? 'bg-blue-600 text-white' : 'text-gray-600 hover:bg-gray-100'}`}
              >
                Reports
              </button>
            </div>
          </div>
        </div>
      </nav>

      {/* Content */}
      <div className="max-w-7xl mx-auto px-4 py-8">
        {activeSection === 'dashboard' && (
          <DashboardHome stats={stats} devices={devices} payments={payments} />
        )}
        {activeSection === 'customers' && (
          <CustomersSection customers={customers} onRefresh={fetchCustomers} />
        )}
        {activeSection === 'devices' && (
          <DevicesSection devices={devices} customers={customers} onRefresh={fetchDevices} />
        )}
        {activeSection === 'payments' && (
          <PaymentsSection payments={payments} devices={devices} customers={customers} onRefresh={fetchPayments} />
        )}
        {activeSection === 'reports' && (
          <ReportsSection devices={devices} payments={payments} />
        )}
      </div>
    </div>
  )
}

// Dashboard Home Component
function DashboardHome({ stats, devices, payments }: any) {
  const recentDevices = devices.slice(0, 5)
  const recentPayments = payments.slice(0, 5)

  return (
    <div className="space-y-6">
      {/* Statistics Cards */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-6">
        <div className="bg-white rounded-lg shadow-md p-6">
          <h3 className="text-gray-500 text-sm font-medium">Total Devices</h3>
          <p className="text-3xl font-bold text-blue-600 mt-2">{stats.totalDevices}</p>
        </div>
        <div className="bg-white rounded-lg shadow-md p-6">
          <h3 className="text-gray-500 text-sm font-medium">Active Loans</h3>
          <p className="text-3xl font-bold text-orange-600 mt-2">{stats.activeLoans}</p>
        </div>
        <div className="bg-white rounded-lg shadow-md p-6">
          <h3 className="text-gray-500 text-sm font-medium">Total Collected</h3>
          <p className="text-3xl font-bold text-green-600 mt-2">
            KES {stats.totalCollected.toLocaleString()}
          </p>
        </div>
        <div className="bg-white rounded-lg shadow-md p-6">
          <h3 className="text-gray-500 text-sm font-medium">Overdue Devices</h3>
          <p className="text-3xl font-bold text-red-600 mt-2">{stats.overdueDevices}</p>
        </div>
      </div>

      {/* Recent Enrollments */}
      <div className="bg-white rounded-lg shadow-md p-6">
        <h2 className="text-xl font-bold mb-4">Recent Enrollments</h2>
        <div className="overflow-x-auto">
          <table className="w-full">
            <thead className="bg-gray-50">
              <tr>
                <th className="px-4 py-2 text-left text-xs font-medium text-gray-500">Device Code</th>
                <th className="px-4 py-2 text-left text-xs font-medium text-gray-500">Model</th>
                <th className="px-4 py-2 text-left text-xs font-medium text-gray-500">Loan Balance</th>
                <th className="px-4 py-2 text-left text-xs font-medium text-gray-500">Status</th>
                <th className="px-4 py-2 text-left text-xs font-medium text-gray-500">Enrolled</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-200">
              {recentDevices.map((device: Device) => (
                <tr key={device.id}>
                  <td className="px-4 py-3">{device.device_code}</td>
                  <td className="px-4 py-3">{device.device_model || 'N/A'}</td>
                  <td className="px-4 py-3">KES {device.loan_balance.toLocaleString()}</td>
                  <td className="px-4 py-3">
                    <span className={`px-2 py-1 text-xs rounded-full ${
                      device.is_locked ? 'bg-red-100 text-red-800' : 'bg-green-100 text-green-800'
                    }`}>
                      {device.is_locked ? 'Locked' : 'Unlocked'}
                    </span>
                  </td>
                  <td className="px-4 py-3">{new Date(device.enrolled_at).toLocaleDateString()}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>

      {/* Recent Payments */}
      <div className="bg-white rounded-lg shadow-md p-6">
        <h2 className="text-xl font-bold mb-4">Recent Payments</h2>
        <div className="overflow-x-auto">
          <table className="w-full">
            <thead className="bg-gray-50">
              <tr>
                <th className="px-4 py-2 text-left text-xs font-medium text-gray-500">Transaction Code</th>
                <th className="px-4 py-2 text-left text-xs font-medium text-gray-500">Amount</th>
                <th className="px-4 py-2 text-left text-xs font-medium text-gray-500">Method</th>
                <th className="px-4 py-2 text-left text-xs font-medium text-gray-500">Status</th>
                <th className="px-4 py-2 text-left text-xs font-medium text-gray-500">Date</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-200">
              {recentPayments.map((payment: PaymentTransaction) => (
                <tr key={payment.id}>
                  <td className="px-4 py-3">{payment.transaction_code}</td>
                  <td className="px-4 py-3">KES {payment.amount.toLocaleString()}</td>
                  <td className="px-4 py-3 uppercase">{payment.payment_method}</td>
                  <td className="px-4 py-3">
                    <span className={`px-2 py-1 text-xs rounded-full ${
                      payment.status === 'completed' ? 'bg-green-100 text-green-800' : 'bg-yellow-100 text-yellow-800'
                    }`}>
                      {payment.status}
                    </span>
                  </td>
                  <td className="px-4 py-3">{new Date(payment.processed_at).toLocaleDateString()}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  )
}

// Customers Section Component
function CustomersSection({ customers, onRefresh }: any) {
  const [showForm, setShowForm] = useState(false)
  const [formData, setFormData] = useState({
    full_name: '',
    phone: '',
    email: '',
    national_id: '',
    address: ''
  })

  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault()
    try {
      const { error } = await supabase
        .from('customers')
        .insert([formData])

      if (error) throw error

      alert('Customer created successfully!')
      setShowForm(false)
      setFormData({ full_name: '', phone: '', email: '', national_id: '', address: '' })
      onRefresh()
    } catch (error: any) {
      alert('Error creating customer: ' + error.message)
    }
  }

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <h2 className="text-2xl font-bold">Customers</h2>
        <button
          onClick={() => setShowForm(!showForm)}
          className="bg-blue-600 text-white px-6 py-2 rounded-lg hover:bg-blue-700"
        >
          {showForm ? 'Cancel' : '+ Add New Customer'}
        </button>
      </div>

      {showForm && (
        <div className="bg-white rounded-lg shadow-md p-6">
          <h3 className="text-xl font-bold mb-4">Add New Customer</h3>
          <form onSubmit={handleSubmit} className="space-y-4">
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <label className="block text-sm font-medium mb-2">Full Name *</label>
                <input
                  type="text"
                  required
                  value={formData.full_name}
                  onChange={(e) => setFormData({...formData, full_name: e.target.value})}
                  className="w-full px-4 py-2 border rounded-lg"
                />
              </div>
              <div>
                <label className="block text-sm font-medium mb-2">Phone *</label>
                <input
                  type="tel"
                  required
                  value={formData.phone}
                  onChange={(e) => setFormData({...formData, phone: e.target.value})}
                  className="w-full px-4 py-2 border rounded-lg"
                  placeholder="+254712345678"
                />
              </div>
              <div>
                <label className="block text-sm font-medium mb-2">Email</label>
                <input
                  type="email"
                  value={formData.email}
                  onChange={(e) => setFormData({...formData, email: e.target.value})}
                  className="w-full px-4 py-2 border rounded-lg"
                />
              </div>
              <div>
                <label className="block text-sm font-medium mb-2">National ID</label>
                <input
                  type="text"
                  value={formData.national_id}
                  onChange={(e) => setFormData({...formData, national_id: e.target.value})}
                  className="w-full px-4 py-2 border rounded-lg"
                />
              </div>
              <div className="md:col-span-2">
                <label className="block text-sm font-medium mb-2">Address</label>
                <textarea
                  value={formData.address}
                  onChange={(e) => setFormData({...formData, address: e.target.value})}
                  className="w-full px-4 py-2 border rounded-lg"
                  rows={3}
                />
              </div>
            </div>
            <button
              type="submit"
              className="bg-green-600 text-white px-6 py-2 rounded-lg hover:bg-green-700"
            >
              Create Customer
            </button>
          </form>
        </div>
      )}

      <div className="bg-white rounded-lg shadow-md overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full">
            <thead className="bg-gray-50">
              <tr>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500">Customer Code</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500">Name</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500">Phone</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500">National ID</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500">Status</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500">Created</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-200">
              {customers.map((customer: Customer) => (
                <tr key={customer.id}>
                  <td className="px-6 py-4">{customer.customer_code}</td>
                  <td className="px-6 py-4">{customer.full_name}</td>
                  <td className="px-6 py-4">{customer.phone}</td>
                  <td className="px-6 py-4">{customer.national_id || 'N/A'}</td>
                  <td className="px-6 py-4">
                    <span className={`px-2 py-1 text-xs rounded-full ${
                      customer.is_active ? 'bg-green-100 text-green-800' : 'bg-red-100 text-red-800'
                    }`}>
                      {customer.is_active ? 'Active' : 'Inactive'}
                    </span>
                  </td>
                  <td className="px-6 py-4">{new Date(customer.created_at).toLocaleDateString()}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  )
}

// Devices Section Component (continued in next part)

// Devices Section Component
function DevicesSection({ devices, customers, onRefresh }: any) {
  const [showForm, setShowForm] = useState(false)
  const [showQR, setShowQR] = useState(false)
  const [qrData, setQrData] = useState('')
  const [formData, setFormData] = useState({
    customer_id: '',
    imei: '',
    device_model: '',
    device_price: '',
    down_payment: '',
    daily_payment: '',
    payment_frequency: 'daily'
  })

  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault()
    try {
      const devicePrice = parseFloat(formData.device_price)
      const downPayment = parseFloat(formData.down_payment)
      const loanTotal = devicePrice - downPayment

      const { data, error } = await supabase
        .from('devices')
        .insert([{
          customer_id: formData.customer_id,
          imei: formData.imei,
          device_model: formData.device_model,
          device_price: devicePrice,
          down_payment: downPayment,
          loan_total: loanTotal,
          loan_balance: loanTotal,
          daily_payment: parseFloat(formData.daily_payment),
          payment_frequency: formData.payment_frequency,
          is_locked: true,
          status: 'enrolled'
        }])
        .select()

      if (error) throw error

      alert('Device enrolled successfully!')
      
      // Generate QR code data
      if (data && data[0]) {
        generateQRCode(data[0])
      }

      setShowForm(false)
      setFormData({
        customer_id: '',
        imei: '',
        device_model: '',
        device_price: '',
        down_payment: '',
        daily_payment: '',
        payment_frequency: 'daily'
      })
      onRefresh()
    } catch (error: any) {
      alert('Error enrolling device: ' + error.message)
    }
  }

  const generateQRCode = (device: any) => {
    const qrPayload = {
      "android.app.extra.PROVISIONING_DEVICE_ADMIN_COMPONENT_NAME": "ke.edenservices.eden/.EdenDeviceAdminReceiver",
      "android.app.extra.PROVISIONING_DEVICE_ADMIN_SIGNATURE_CHECKSUM": "YOUR_APK_CHECKSUM",
      "android.app.extra.PROVISIONING_DEVICE_ADMIN_PACKAGE_DOWNLOAD_LOCATION": "https://your-server.com/eden.apk",
      "android.app.extra.PROVISIONING_SKIP_ENCRYPTION": false,
      "android.app.extra.PROVISIONING_LEAVE_ALL_SYSTEM_APPS_ENABLED": true,
      "android.app.extra.PROVISIONING_ADMIN_EXTRAS_BUNDLE": {
        "supabase_url": process.env.NEXT_PUBLIC_SUPABASE_URL,
        "supabase_key": process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY,
        "device_id": device.id,
        "device_code": device.device_code
      }
    }

    setQrData(JSON.stringify(qrPayload, null, 2))
    setShowQR(true)
  }

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <h2 className="text-2xl font-bold">Devices</h2>
        <button
          onClick={() => setShowForm(!showForm)}
          className="bg-blue-600 text-white px-6 py-2 rounded-lg hover:bg-blue-700"
        >
          {showForm ? 'Cancel' : '+ Enroll New Device'}
        </button>
      </div>

      {showForm && (
        <div className="bg-white rounded-lg shadow-md p-6">
          <h3 className="text-xl font-bold mb-4">Enroll New Device</h3>
          <form onSubmit={handleSubmit} className="space-y-4">
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <label className="block text-sm font-medium mb-2">Select Customer *</label>
                <select
                  required
                  value={formData.customer_id}
                  onChange={(e) => setFormData({...formData, customer_id: e.target.value})}
                  className="w-full px-4 py-2 border rounded-lg"
                >
                  <option value="">-- Select Customer --</option>
                  {customers.map((customer: Customer) => (
                    <option key={customer.id} value={customer.id}>
                      {customer.customer_code} - {customer.full_name}
                    </option>
                  ))}
                </select>
              </div>
              <div>
                <label className="block text-sm font-medium mb-2">Device IMEI *</label>
                <input
                  type="text"
                  required
                  value={formData.imei}
                  onChange={(e) => setFormData({...formData, imei: e.target.value})}
                  className="w-full px-4 py-2 border rounded-lg"
                  placeholder="123456789012345"
                />
              </div>
              <div>
                <label className="block text-sm font-medium mb-2">Device Model *</label>
                <input
                  type="text"
                  required
                  value={formData.device_model}
                  onChange={(e) => setFormData({...formData, device_model: e.target.value})}
                  className="w-full px-4 py-2 border rounded-lg"
                  placeholder="Samsung Galaxy A14"
                />
              </div>
              <div>
                <label className="block text-sm font-medium mb-2">Device Price (KES) *</label>
                <input
                  type="number"
                  required
                  step="0.01"
                  value={formData.device_price}
                  onChange={(e) => setFormData({...formData, device_price: e.target.value})}
                  className="w-full px-4 py-2 border rounded-lg"
                  placeholder="15000"
                />
              </div>
              <div>
                <label className="block text-sm font-medium mb-2">Down Payment (KES) *</label>
                <input
                  type="number"
                  required
                  step="0.01"
                  value={formData.down_payment}
                  onChange={(e) => setFormData({...formData, down_payment: e.target.value})}
                  className="w-full px-4 py-2 border rounded-lg"
                  placeholder="3000"
                />
              </div>
              <div>
                <label className="block text-sm font-medium mb-2">Daily Payment (KES) *</label>
                <input
                  type="number"
                  required
                  step="0.01"
                  value={formData.daily_payment}
                  onChange={(e) => setFormData({...formData, daily_payment: e.target.value})}
                  className="w-full px-4 py-2 border rounded-lg"
                  placeholder="100"
                />
              </div>
              <div>
                <label className="block text-sm font-medium mb-2">Payment Frequency *</label>
                <select
                  required
                  value={formData.payment_frequency}
                  onChange={(e) => setFormData({...formData, payment_frequency: e.target.value})}
                  className="w-full px-4 py-2 border rounded-lg"
                >
                  <option value="daily">Daily</option>
                  <option value="weekly">Weekly</option>
                  <option value="monthly">Monthly</option>
                </select>
              </div>
              <div>
                <label className="block text-sm font-medium mb-2">Loan Total</label>
                <input
                  type="text"
                  disabled
                  value={formData.device_price && formData.down_payment 
                    ? `KES ${(parseFloat(formData.device_price) - parseFloat(formData.down_payment)).toLocaleString()}`
                    : 'KES 0'}
                  className="w-full px-4 py-2 border rounded-lg bg-gray-100"
                />
              </div>
            </div>
            <button
              type="submit"
              className="bg-green-600 text-white px-6 py-2 rounded-lg hover:bg-green-700"
            >
              Enroll Device & Generate QR Code
            </button>
          </form>
        </div>
      )}

      {showQR && (
        <div className="bg-white rounded-lg shadow-md p-6">
          <h3 className="text-xl font-bold mb-4">QR Code Provisioning Data</h3>
          <p className="text-sm text-gray-600 mb-4">
            Use this JSON to generate a QR code for device provisioning. 
            The device should be factory reset, then tap the welcome screen 6 times and scan this QR code.
          </p>
          <div className="bg-gray-100 p-4 rounded-lg overflow-x-auto">
            <pre className="text-xs">{qrData}</pre>
          </div>
          <div className="mt-4 flex space-x-4">
            <button
              onClick={() => navigator.clipboard.writeText(qrData)}
              className="bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700"
            >
              Copy to Clipboard
            </button>
            <button
              onClick={() => setShowQR(false)}
              className="bg-gray-600 text-white px-4 py-2 rounded-lg hover:bg-gray-700"
            >
              Close
            </button>
          </div>
        </div>
      )}

      <div className="bg-white rounded-lg shadow-md overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full">
            <thead className="bg-gray-50">
              <tr>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500">Device Code</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500">IMEI</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500">Model</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500">Loan Balance</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500">Daily Payment</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500">Status</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500">Lock Status</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-200">
              {devices.map((device: Device) => (
                <tr key={device.id}>
                  <td className="px-6 py-4">{device.device_code}</td>
                  <td className="px-6 py-4">{device.imei}</td>
                  <td className="px-6 py-4">{device.device_model || 'N/A'}</td>
                  <td className="px-6 py-4">KES {device.loan_balance.toLocaleString()}</td>
                  <td className="px-6 py-4">KES {device.daily_payment.toLocaleString()}</td>
                  <td className="px-6 py-4">
                    <span className="px-2 py-1 text-xs rounded-full bg-blue-100 text-blue-800">
                      {device.status}
                    </span>
                  </td>
                  <td className="px-6 py-4">
                    <span className={`px-2 py-1 text-xs rounded-full ${
                      device.is_locked ? 'bg-red-100 text-red-800' : 'bg-green-100 text-green-800'
                    }`}>
                      {device.is_locked ? 'Locked' : 'Unlocked'}
                    </span>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  )
}

// Payments Section Component
function PaymentsSection({ payments, devices, customers, onRefresh }: any) {
  const [showForm, setShowForm] = useState(false)
  const [formData, setFormData] = useState({
    device_id: '',
    amount: '',
    payment_method: 'mpesa',
    mpesa_receipt: '',
    mpesa_phone: '',
    payment_reference: '',
    notes: ''
  })

  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault()
    try {
      // Get device to update loan balance
      const { data: deviceData, error: deviceError } = await supabase
        .from('devices')
        .select('loan_balance, customer_id')
        .eq('id', formData.device_id)
        .single()

      if (deviceError) throw deviceError

      const paymentAmount = parseFloat(formData.amount)
      const newBalance = Math.max(0, deviceData.loan_balance - paymentAmount)

      // Insert payment transaction
      const { error: paymentError } = await supabase
        .from('payment_transactions')
        .insert([{
          device_id: formData.device_id,
          customer_id: deviceData.customer_id,
          amount: paymentAmount,
          payment_method: formData.payment_method,
          mpesa_receipt: formData.mpesa_receipt || null,
          mpesa_phone: formData.mpesa_phone || null,
          payment_reference: formData.payment_reference || null,
          notes: formData.notes || null,
          status: 'completed'
        }])

      if (paymentError) throw paymentError

      // Update device loan balance
      const { error: updateError } = await supabase
        .from('devices')
        .update({
          loan_balance: newBalance,
          last_payment_amount: paymentAmount,
          last_payment_date: new Date().toISOString(),
          total_paid: deviceData.loan_balance - newBalance
        })
        .eq('id', formData.device_id)

      if (updateError) throw updateError

      alert('Payment processed successfully!')
      setShowForm(false)
      setFormData({
        device_id: '',
        amount: '',
        payment_method: 'mpesa',
        mpesa_receipt: '',
        mpesa_phone: '',
        payment_reference: '',
        notes: ''
      })
      onRefresh()
    } catch (error: any) {
      alert('Error processing payment: ' + error.message)
    }
  }

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <h2 className="text-2xl font-bold">Payments</h2>
        <button
          onClick={() => setShowForm(!showForm)}
          className="bg-blue-600 text-white px-6 py-2 rounded-lg hover:bg-blue-700"
        >
          {showForm ? 'Cancel' : '+ Record Payment'}
        </button>
      </div>

      {showForm && (
        <div className="bg-white rounded-lg shadow-md p-6">
          <h3 className="text-xl font-bold mb-4">Record Payment</h3>
          <form onSubmit={handleSubmit} className="space-y-4">
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <label className="block text-sm font-medium mb-2">Select Device *</label>
                <select
                  required
                  value={formData.device_id}
                  onChange={(e) => setFormData({...formData, device_id: e.target.value})}
                  className="w-full px-4 py-2 border rounded-lg"
                >
                  <option value="">-- Select Device --</option>
                  {devices.filter((d: Device) => d.loan_balance > 0).map((device: Device) => (
                    <option key={device.id} value={device.id}>
                      {device.device_code} - Balance: KES {device.loan_balance.toLocaleString()}
                    </option>
                  ))}
                </select>
              </div>
              <div>
                <label className="block text-sm font-medium mb-2">Amount (KES) *</label>
                <input
                  type="number"
                  required
                  step="0.01"
                  value={formData.amount}
                  onChange={(e) => setFormData({...formData, amount: e.target.value})}
                  className="w-full px-4 py-2 border rounded-lg"
                  placeholder="100"
                />
              </div>
              <div>
                <label className="block text-sm font-medium mb-2">Payment Method *</label>
                <select
                  required
                  value={formData.payment_method}
                  onChange={(e) => setFormData({...formData, payment_method: e.target.value})}
                  className="w-full px-4 py-2 border rounded-lg"
                >
                  <option value="mpesa">M-Pesa</option>
                  <option value="cash">Cash</option>
                  <option value="bank">Bank Transfer</option>
                  <option value="blockchain">Blockchain</option>
                </select>
              </div>
              {formData.payment_method === 'mpesa' && (
                <>
                  <div>
                    <label className="block text-sm font-medium mb-2">M-Pesa Receipt Number</label>
                    <input
                      type="text"
                      value={formData.mpesa_receipt}
                      onChange={(e) => setFormData({...formData, mpesa_receipt: e.target.value})}
                      className="w-full px-4 py-2 border rounded-lg"
                      placeholder="QA12BC3DEF"
                    />
                  </div>
                  <div>
                    <label className="block text-sm font-medium mb-2">M-Pesa Phone Number</label>
                    <input
                      type="tel"
                      value={formData.mpesa_phone}
                      onChange={(e) => setFormData({...formData, mpesa_phone: e.target.value})}
                      className="w-full px-4 py-2 border rounded-lg"
                      placeholder="+254712345678"
                    />
                  </div>
                </>
              )}
              <div>
                <label className="block text-sm font-medium mb-2">Payment Reference</label>
                <input
                  type="text"
                  value={formData.payment_reference}
                  onChange={(e) => setFormData({...formData, payment_reference: e.target.value})}
                  className="w-full px-4 py-2 border rounded-lg"
                />
              </div>
              <div className="md:col-span-2">
                <label className="block text-sm font-medium mb-2">Notes</label>
                <textarea
                  value={formData.notes}
                  onChange={(e) => setFormData({...formData, notes: e.target.value})}
                  className="w-full px-4 py-2 border rounded-lg"
                  rows={3}
                />
              </div>
            </div>
            <button
              type="submit"
              className="bg-green-600 text-white px-6 py-2 rounded-lg hover:bg-green-700"
            >
              Process Payment
            </button>
          </form>
        </div>
      )}

      <div className="bg-white rounded-lg shadow-md overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full">
            <thead className="bg-gray-50">
              <tr>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500">Transaction Code</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500">Amount</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500">Method</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500">M-Pesa Receipt</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500">Status</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500">Date</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-200">
              {payments.map((payment: PaymentTransaction) => (
                <tr key={payment.id}>
                  <td className="px-6 py-4">{payment.transaction_code}</td>
                  <td className="px-6 py-4">KES {payment.amount.toLocaleString()}</td>
                  <td className="px-6 py-4 uppercase">{payment.payment_method}</td>
                  <td className="px-6 py-4">{payment.mpesa_receipt || 'N/A'}</td>
                  <td className="px-6 py-4">
                    <span className={`px-2 py-1 text-xs rounded-full ${
                      payment.status === 'completed' ? 'bg-green-100 text-green-800' : 'bg-yellow-100 text-yellow-800'
                    }`}>
                      {payment.status}
                    </span>
                  </td>
                  <td className="px-6 py-4">{new Date(payment.processed_at).toLocaleDateString()}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  )
}

// Reports Section Component
function ReportsSection({ devices, payments }: any) {
  const today = new Date()
  const todayStr = today.toISOString().split('T')[0]

  // Daily collection
  const todayPayments = payments.filter((p: PaymentTransaction) => 
    p.processed_at.startsWith(todayStr)
  )
  const dailyCollection = todayPayments.reduce((sum: number, p: PaymentTransaction) => sum + p.amount, 0)

  // Monthly collection
  const monthStr = today.toISOString().substring(0, 7)
  const monthPayments = payments.filter((p: PaymentTransaction) => 
    p.processed_at.startsWith(monthStr)
  )
  const monthlyCollection = monthPayments.reduce((sum: number, p: PaymentTransaction) => sum + p.amount, 0)

  // Overdue devices
  const overdueDevices = devices.filter((d: Device) => d.days_overdue > 0)

  // Collection rate
  const totalLoans = devices.reduce((sum: number, d: Device) => sum + d.loan_total, 0)
  const totalCollected = devices.reduce((sum: number, d: Device) => sum + (d.total_paid || 0), 0)
  const collectionRate = totalLoans > 0 ? (totalCollected / totalLoans * 100).toFixed(2) : '0.00'

  return (
    <div className="space-y-6">
      <h2 className="text-2xl font-bold">Reports</h2>

      {/* Summary Cards */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-6">
        <div className="bg-white rounded-lg shadow-md p-6">
          <h3 className="text-gray-500 text-sm font-medium">Today's Collection</h3>
          <p className="text-3xl font-bold text-green-600 mt-2">
            KES {dailyCollection.toLocaleString()}
          </p>
          <p className="text-sm text-gray-500 mt-1">{todayPayments.length} payments</p>
        </div>
        <div className="bg-white rounded-lg shadow-md p-6">
          <h3 className="text-gray-500 text-sm font-medium">Monthly Collection</h3>
          <p className="text-3xl font-bold text-blue-600 mt-2">
            KES {monthlyCollection.toLocaleString()}
          </p>
          <p className="text-sm text-gray-500 mt-1">{monthPayments.length} payments</p>
        </div>
        <div className="bg-white rounded-lg shadow-md p-6">
          <h3 className="text-gray-500 text-sm font-medium">Collection Rate</h3>
          <p className="text-3xl font-bold text-purple-600 mt-2">{collectionRate}%</p>
          <p className="text-sm text-gray-500 mt-1">
            KES {totalCollected.toLocaleString()} / {totalLoans.toLocaleString()}
          </p>
        </div>
        <div className="bg-white rounded-lg shadow-md p-6">
          <h3 className="text-gray-500 text-sm font-medium">Overdue Devices</h3>
          <p className="text-3xl font-bold text-red-600 mt-2">{overdueDevices.length}</p>
          <p className="text-sm text-gray-500 mt-1">Require attention</p>
        </div>
      </div>

      {/* Overdue Devices Table */}
      <div className="bg-white rounded-lg shadow-md p-6">
        <h3 className="text-xl font-bold mb-4">Overdue Devices</h3>
        <div className="overflow-x-auto">
          <table className="w-full">
            <thead className="bg-gray-50">
              <tr>
                <th className="px-4 py-2 text-left text-xs font-medium text-gray-500">Device Code</th>
                <th className="px-4 py-2 text-left text-xs font-medium text-gray-500">Model</th>
                <th className="px-4 py-2 text-left text-xs font-medium text-gray-500">Balance</th>
                <th className="px-4 py-2 text-left text-xs font-medium text-gray-500">Days Overdue</th>
                <th className="px-4 py-2 text-left text-xs font-medium text-gray-500">Last Payment</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-200">
              {overdueDevices.map((device: Device) => (
                <tr key={device.id}>
                  <td className="px-4 py-3">{device.device_code}</td>
                  <td className="px-4 py-3">{device.device_model || 'N/A'}</td>
                  <td className="px-4 py-3">KES {device.loan_balance.toLocaleString()}</td>
                  <td className="px-4 py-3">
                    <span className="px-2 py-1 text-xs rounded-full bg-red-100 text-red-800">
                      {device.days_overdue} days
                    </span>
                  </td>
                  <td className="px-4 py-3">
                    {device.last_payment_date 
                      ? new Date(device.last_payment_date).toLocaleDateString()
                      : 'Never'}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>

      {/* Payment Method Breakdown */}
      <div className="bg-white rounded-lg shadow-md p-6">
        <h3 className="text-xl font-bold mb-4">Payment Method Breakdown (This Month)</h3>
        <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
          {['mpesa', 'cash', 'bank', 'blockchain'].map(method => {
            const methodPayments = monthPayments.filter((p: PaymentTransaction) => p.payment_method === method)
            const methodTotal = methodPayments.reduce((sum: number, p: PaymentTransaction) => sum + p.amount, 0)
            return (
              <div key={method} className="border rounded-lg p-4">
                <h4 className="text-sm font-medium text-gray-500 uppercase">{method}</h4>
                <p className="text-2xl font-bold text-gray-900 mt-2">
                  KES {methodTotal.toLocaleString()}
                </p>
                <p className="text-sm text-gray-500 mt-1">{methodPayments.length} transactions</p>
              </div>
            )
          })}
        </div>
      </div>
    </div>
  )
}
