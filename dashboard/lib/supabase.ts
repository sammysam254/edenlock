import { createClient } from '@supabase/supabase-js'

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL!
const supabaseAnonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!

export const supabase = createClient(supabaseUrl, supabaseAnonKey)

// Types
export interface SuperAdmin {
  id: string
  email: string
  full_name: string
  phone?: string
  is_active: boolean
  created_at: string
}

export interface Administrator {
  id: string
  email: string
  full_name: string
  phone: string
  is_active: boolean
  region?: string
  branch?: string
  created_by?: string
  created_at: string
}

export interface Customer {
  id: string
  customer_code: string
  full_name: string
  phone: string
  email?: string
  national_id?: string
  address?: string
  enrolled_by?: string
  is_active: boolean
  created_at: string
}

export interface Device {
  id: string
  device_code: string
  imei: string
  customer_id?: string
  enrolled_by?: string
  device_model?: string
  device_price: number
  down_payment: number
  loan_total: number
  loan_balance: number
  daily_payment: number
  is_locked: boolean
  status: string
  enrolled_at: string
  activated_at?: string
}

export interface PaymentTransaction {
  id: string
  transaction_code: string
  device_id: string
  customer_id?: string
  amount: number
  payment_method: string
  payment_reference?: string
  mpesa_receipt?: string
  mpesa_phone?: string
  status: string
  processed_at: string
}
