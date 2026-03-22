'use client'

import React, { useState, useEffect } from 'react'
import { supabase, Administrator } from '@/lib/supabase'

export default function SuperAdminDashboard() {
  const [administrators, setAdministrators] = useState<Administrator[]>([])
  const [loading, setLoading] = useState(true)
  const [showCreateForm, setShowCreateForm] = useState(false)
  const [formData, setFormData] = useState({
    email: '',
    full_name: '',
    phone: '',
    region: '',
    branch: ''
  })

  useEffect(() => {
    fetchAdministrators()
  }, [])

  const fetchAdministrators = async () => {
    try {
      const { data, error } = await supabase
        .from('administrators')
        .select('*')
        .order('created_at', { ascending: false })

      if (error) throw error
      setAdministrators(data || [])
    } catch (error) {
      console.error('Error fetching administrators:', error)
    } finally {
      setLoading(false)
    }
  }

  const createAdministrator = async (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault()
    try {
      // Generate random password
      const randomPassword = Math.random().toString(36).slice(-12) + 'A1!'
      
      // Create auth user first
      const { data: authData, error: authError } = await supabase.auth.signUp({
        email: formData.email,
        password: randomPassword,
        options: {
          data: {
            full_name: formData.full_name,
            role: 'administrator'
          }
        }
      })

      if (authError) throw authError

      // Create administrator record
      const { error: adminError } = await supabase
        .from('administrators')
        .insert([{
          email: formData.email,
          full_name: formData.full_name,
          phone: formData.phone,
          region: formData.region,
          branch: formData.branch,
          auth_user_id: authData.user?.id
        }])

      if (adminError) throw adminError

      alert('Administrator created successfully! Login credentials sent to email.')
      setShowCreateForm(false)
      setFormData({ email: '', full_name: '', phone: '', region: '', branch: '' })
      fetchAdministrators()
    } catch (error: any) {
      alert('Error creating administrator: ' + error.message)
    }
  }

  const toggleAdminStatus = async (id: string, currentStatus: boolean) => {
    try {
      const { error } = await supabase
        .from('administrators')
        .update({ is_active: !currentStatus })
        .eq('id', id)

      if (error) throw error
      fetchAdministrators()
    } catch (error) {
      console.error('Error updating administrator:', error)
    }
  }

  if (loading) {
    return <div className="flex items-center justify-center min-h-screen">
      <div className="text-xl">Loading...</div>
    </div>
  }

  return (
    <div className="min-h-screen bg-gray-50 p-8">
      <div className="max-w-7xl mx-auto">
        {/* Header */}
        <div className="bg-white rounded-lg shadow-md p-6 mb-6">
          <h1 className="text-3xl font-bold text-gray-900">Super Admin Dashboard</h1>
          <p className="text-gray-600 mt-2">Manage administrators and system settings</p>
        </div>

        {/* Stats */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-6">
          <div className="bg-white rounded-lg shadow-md p-6">
            <h3 className="text-gray-500 text-sm font-medium">Total Administrators</h3>
            <p className="text-3xl font-bold text-blue-600 mt-2">{administrators.length}</p>
          </div>
          <div className="bg-white rounded-lg shadow-md p-6">
            <h3 className="text-gray-500 text-sm font-medium">Active Administrators</h3>
            <p className="text-3xl font-bold text-green-600 mt-2">
              {administrators.filter(a => a.is_active).length}
            </p>
          </div>
          <div className="bg-white rounded-lg shadow-md p-6">
            <h3 className="text-gray-500 text-sm font-medium">Inactive Administrators</h3>
            <p className="text-3xl font-bold text-red-600 mt-2">
              {administrators.filter(a => !a.is_active).length}
            </p>
          </div>
        </div>

        {/* Create Administrator Button */}
        <div className="mb-6">
          <button
            onClick={() => setShowCreateForm(!showCreateForm)}
            className="bg-blue-600 text-white px-6 py-3 rounded-lg hover:bg-blue-700 font-medium"
          >
            {showCreateForm ? 'Cancel' : '+ Create New Administrator'}
          </button>
        </div>

        {/* Create Form */}
        {showCreateForm && (
          <div className="bg-white rounded-lg shadow-md p-6 mb-6">
            <h2 className="text-xl font-bold mb-4">Create New Administrator</h2>
            <form onSubmit={createAdministrator} className="space-y-4">
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">
                    Full Name *
                  </label>
                  <input
                    type="text"
                    required
                    value={formData.full_name}
                    onChange={(e) => setFormData({...formData, full_name: e.target.value})}
                    className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">
                    Email *
                  </label>
                  <input
                    type="email"
                    required
                    value={formData.email}
                    onChange={(e) => setFormData({...formData, email: e.target.value})}
                    className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">
                    Phone *
                  </label>
                  <input
                    type="tel"
                    required
                    value={formData.phone}
                    onChange={(e) => setFormData({...formData, phone: e.target.value})}
                    className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">
                    Region
                  </label>
                  <input
                    type="text"
                    value={formData.region}
                    onChange={(e) => setFormData({...formData, region: e.target.value})}
                    className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">
                    Branch
                  </label>
                  <input
                    type="text"
                    value={formData.branch}
                    onChange={(e) => setFormData({...formData, branch: e.target.value})}
                    className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
                  />
                </div>
              </div>
              <button
                type="submit"
                className="bg-green-600 text-white px-6 py-2 rounded-lg hover:bg-green-700 font-medium"
              >
                Create Administrator
              </button>
            </form>
          </div>
        )}

        {/* Administrators List */}
        <div className="bg-white rounded-lg shadow-md overflow-hidden">
          <div className="px-6 py-4 border-b border-gray-200">
            <h2 className="text-xl font-bold">Administrators</h2>
          </div>
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead className="bg-gray-50">
                <tr>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Name</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Email</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Phone</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Region</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Status</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-200">
                {administrators.map((admin) => (
                  <tr key={admin.id}>
                    <td className="px-6 py-4 whitespace-nowrap">{admin.full_name}</td>
                    <td className="px-6 py-4 whitespace-nowrap">{admin.email}</td>
                    <td className="px-6 py-4 whitespace-nowrap">{admin.phone}</td>
                    <td className="px-6 py-4 whitespace-nowrap">{admin.region || '-'}</td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <span className={`px-2 py-1 text-xs font-semibold rounded-full ${
                        admin.is_active ? 'bg-green-100 text-green-800' : 'bg-red-100 text-red-800'
                      }`}>
                        {admin.is_active ? 'Active' : 'Inactive'}
                      </span>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <button
                        onClick={() => toggleAdminStatus(admin.id, admin.is_active)}
                        className={`px-3 py-1 text-sm rounded ${
                          admin.is_active 
                            ? 'bg-red-100 text-red-700 hover:bg-red-200' 
                            : 'bg-green-100 text-green-700 hover:bg-green-200'
                        }`}
                      >
                        {admin.is_active ? 'Deactivate' : 'Activate'}
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      </div>
    </div>
  )
}
