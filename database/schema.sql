-- Eden Supabase Database Schema - M-Kopa Style
-- Multi-tenant system with Super Admin, Administrators, and Customers

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================================
-- USER MANAGEMENT TABLES
-- ============================================================================

-- Super Admins table (Top-level administrators)
CREATE TABLE IF NOT EXISTS super_admins (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email TEXT UNIQUE NOT NULL,
    full_name TEXT NOT NULL,
    phone TEXT,
    auth_user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Administrators table (Device enrollment agents)
CREATE TABLE IF NOT EXISTS administrators (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email TEXT UNIQUE NOT NULL,
    full_name TEXT NOT NULL,
    phone TEXT NOT NULL,
    auth_user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    created_by UUID REFERENCES super_admins(id),
    is_active BOOLEAN DEFAULT true,
    region TEXT,
    branch TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Customers table (Device owners/buyers)
CREATE TABLE IF NOT EXISTS customers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    customer_code TEXT UNIQUE NOT NULL,
    full_name TEXT NOT NULL,
    phone TEXT UNIQUE NOT NULL,
    email TEXT,
    national_id TEXT,
    address TEXT,
    enrolled_by UUID REFERENCES administrators(id),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================================================
-- DEVICE MANAGEMENT TABLES
-- ============================================================================

-- Devices table (Enhanced with customer linking)
CREATE TABLE IF NOT EXISTS devices (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    device_code TEXT UNIQUE NOT NULL,
    imei TEXT UNIQUE NOT NULL,
    customer_id UUID REFERENCES customers(id) ON DELETE SET NULL,
    enrolled_by UUID REFERENCES administrators(id),
    
    -- Device info
    device_model TEXT,
    android_version TEXT,
    serial_number TEXT,
    
    -- Financial info
    device_price DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
    down_payment DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
    loan_total DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
    loan_balance DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
    daily_payment DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
    payment_frequency TEXT DEFAULT 'daily', -- daily, weekly, monthly
    
    -- Lock status
    is_locked BOOLEAN NOT NULL DEFAULT true,
    lock_reason TEXT DEFAULT 'pending_payment',
    grace_period_days INTEGER DEFAULT 3,
    days_overdue INTEGER DEFAULT 0,
    
    -- Payment tracking
    last_payment_amount DECIMAL(10, 2),
    last_payment_date TIMESTAMP WITH TIME ZONE,
    next_payment_due TIMESTAMP WITH TIME ZONE,
    total_paid DECIMAL(10, 2) DEFAULT 0.00,
    
    -- Timestamps
    enrolled_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    activated_at TIMESTAMP WITH TIME ZONE,
    provisioned_at TIMESTAMP WITH TIME ZONE,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    retired_at TIMESTAMP WITH TIME ZONE,
    
    -- Status
    status TEXT DEFAULT 'enrolled', -- enrolled, active, locked, paid_off, retired
    
    -- Constraints
    CONSTRAINT positive_device_price CHECK (device_price >= 0),
    CONSTRAINT positive_loan_total CHECK (loan_total >= 0),
    CONSTRAINT positive_loan_balance CHECK (loan_balance >= 0),
    CONSTRAINT balance_not_exceed_total CHECK (loan_balance <= loan_total)
);

-- Payment transactions table
CREATE TABLE IF NOT EXISTS payment_transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    device_id UUID NOT NULL REFERENCES devices(id) ON DELETE CASCADE,
    wallet_address TEXT NOT NULL,
    amount DECIMAL(10, 2) NOT NULL,
    blockchain_timestamp BIGINT NOT NULL,
    processed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Constraints
    CONSTRAINT positive_amount CHECK (amount > 0)
);

-- Device sync logs (optional - for debugging)
CREATE TABLE IF NOT EXISTS device_sync_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    device_id UUID REFERENCES devices(id) ON DELETE CASCADE,
    imei TEXT NOT NULL,
    sync_type TEXT NOT NULL, -- 'status_check', 'payment_update', etc.
    sync_status TEXT NOT NULL, -- 'success', 'failed'
    details JSONB,
    synced_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_devices_imei ON devices(imei);
CREATE INDEX IF NOT EXISTS idx_devices_wallet ON devices(wallet_address);
CREATE INDEX IF NOT EXISTS idx_devices_locked ON devices(is_locked);
CREATE INDEX IF NOT EXISTS idx_transactions_device ON payment_transactions(device_id);
CREATE INDEX IF NOT EXISTS idx_transactions_wallet ON payment_transactions(wallet_address);
CREATE INDEX IF NOT EXISTS idx_sync_logs_device ON device_sync_logs(device_id);

-- Updated_at trigger function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply trigger to devices table
CREATE TRIGGER update_devices_updated_at
    BEFORE UPDATE ON devices
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Auto-lock trigger when balance increases
CREATE OR REPLACE FUNCTION auto_lock_on_balance()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.loan_balance > 0 THEN
        NEW.is_locked = true;
    ELSE
        NEW.is_locked = false;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_auto_lock
    BEFORE INSERT OR UPDATE OF loan_balance ON devices
    FOR EACH ROW
    EXECUTE FUNCTION auto_lock_on_balance();

-- Comments for documentation
COMMENT ON TABLE devices IS 'Stores device information and loan status';
COMMENT ON TABLE payment_transactions IS 'Logs all blockchain payment events';
COMMENT ON COLUMN devices.imei IS 'Device IMEI or Android ID';
COMMENT ON COLUMN devices.wallet_address IS 'Blockchain wallet address for payments';
COMMENT ON COLUMN devices.is_locked IS 'Current lock status of the device';

-- ============================================================================
-- ENROLLMENT & ACTIVATION TABLES
-- ============================================================================

-- Device enrollment sessions (QR code generation tracking)
CREATE TABLE IF NOT EXISTS enrollment_sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    device_id UUID REFERENCES devices(id) ON DELETE CASCADE,
    administrator_id UUID REFERENCES administrators(id),
    qr_code_data TEXT NOT NULL,
    qr_code_url TEXT,
    status TEXT DEFAULT 'pending', -- pending, completed, expired
    expires_at TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================================================
-- PAYMENT TABLES
-- ============================================================================

-- Payment transactions (Enhanced)
CREATE TABLE IF NOT EXISTS payment_transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    transaction_code TEXT UNIQUE NOT NULL,
    device_id UUID NOT NULL REFERENCES devices(id) ON DELETE CASCADE,
    customer_id UUID REFERENCES customers(id),
    
    -- Payment details
    amount DECIMAL(10, 2) NOT NULL,
    payment_method TEXT NOT NULL, -- mpesa, cash, bank, blockchain
    payment_reference TEXT,
    
    -- M-Pesa specific
    mpesa_receipt TEXT,
    mpesa_phone TEXT,
    
    -- Blockchain specific
    wallet_address TEXT,
    blockchain_tx_hash TEXT,
    blockchain_timestamp BIGINT,
    
    -- Status
    status TEXT DEFAULT 'pending', -- pending, completed, failed, reversed
    processed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    verified_at TIMESTAMP WITH TIME ZONE,
    
    -- Metadata
    notes TEXT,
    processed_by UUID REFERENCES administrators(id),
    
    -- Constraints
    CONSTRAINT positive_amount CHECK (amount > 0)
);

-- Payment schedules (Expected payments)
CREATE TABLE IF NOT EXISTS payment_schedules (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    device_id UUID REFERENCES devices(id) ON DELETE CASCADE,
    customer_id UUID REFERENCES customers(id),
    
    -- Schedule details
    due_date DATE NOT NULL,
    amount_due DECIMAL(10, 2) NOT NULL,
    amount_paid DECIMAL(10, 2) DEFAULT 0.00,
    status TEXT DEFAULT 'pending', -- pending, paid, overdue, waived
    
    -- Tracking
    paid_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================================================
-- AUDIT & LOGGING TABLES
-- ============================================================================

-- Device sync logs
CREATE TABLE IF NOT EXISTS device_sync_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    device_id UUID REFERENCES devices(id) ON DELETE CASCADE,
    imei TEXT NOT NULL,
    sync_type TEXT NOT NULL,
    sync_status TEXT NOT NULL,
    details JSONB,
    synced_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Admin activity logs
CREATE TABLE IF NOT EXISTS admin_activity_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    admin_id UUID,
    admin_type TEXT NOT NULL, -- super_admin, administrator
    action TEXT NOT NULL,
    resource_type TEXT,
    resource_id UUID,
    details JSONB,
    ip_address TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Device lock/unlock history
CREATE TABLE IF NOT EXISTS device_lock_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    device_id UUID REFERENCES devices(id) ON DELETE CASCADE,
    action TEXT NOT NULL, -- locked, unlocked
    reason TEXT,
    triggered_by TEXT, -- system, admin, payment
    admin_id UUID,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================================================
-- INDEXES FOR PERFORMANCE
-- ============================================================================

CREATE INDEX IF NOT EXISTS idx_devices_customer ON devices(customer_id);
CREATE INDEX IF NOT EXISTS idx_devices_enrolled_by ON devices(enrolled_by);
CREATE INDEX IF NOT EXISTS idx_devices_imei ON devices(imei);
CREATE INDEX IF NOT EXISTS idx_devices_status ON devices(status);
CREATE INDEX IF NOT EXISTS idx_devices_locked ON devices(is_locked);

CREATE INDEX IF NOT EXISTS idx_customers_phone ON customers(phone);
CREATE INDEX IF NOT EXISTS idx_customers_code ON customers(customer_code);
CREATE INDEX IF NOT EXISTS idx_customers_enrolled_by ON customers(enrolled_by);

CREATE INDEX IF NOT EXISTS idx_administrators_email ON administrators(email);
CREATE INDEX IF NOT EXISTS idx_administrators_active ON administrators(is_active);

CREATE INDEX IF NOT EXISTS idx_transactions_device ON payment_transactions(device_id);
CREATE INDEX IF NOT EXISTS idx_transactions_customer ON payment_transactions(customer_id);
CREATE INDEX IF NOT EXISTS idx_transactions_status ON payment_transactions(status);
CREATE INDEX IF NOT EXISTS idx_transactions_date ON payment_transactions(processed_at);

CREATE INDEX IF NOT EXISTS idx_schedules_device ON payment_schedules(device_id);
CREATE INDEX IF NOT EXISTS idx_schedules_due_date ON payment_schedules(due_date);
CREATE INDEX IF NOT EXISTS idx_schedules_status ON payment_schedules(status);

CREATE INDEX IF NOT EXISTS idx_sync_logs_device ON device_sync_logs(device_id);
CREATE INDEX IF NOT EXISTS idx_activity_logs_admin ON admin_activity_logs(admin_id);
CREATE INDEX IF NOT EXISTS idx_lock_history_device ON device_lock_history(device_id);

-- ============================================================================
-- TRIGGERS
-- ============================================================================

-- Auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_devices_updated_at
    BEFORE UPDATE ON devices
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_customers_updated_at
    BEFORE UPDATE ON customers
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_administrators_updated_at
    BEFORE UPDATE ON administrators
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_super_admins_updated_at
    BEFORE UPDATE ON super_admins
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Auto-lock device when balance > 0
CREATE OR REPLACE FUNCTION auto_lock_on_balance()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.loan_balance > 0 THEN
        NEW.is_locked = true;
        NEW.status = 'locked';
    ELSE
        NEW.is_locked = false;
        NEW.status = 'paid_off';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_auto_lock
    BEFORE INSERT OR UPDATE OF loan_balance ON devices
    FOR EACH ROW
    EXECUTE FUNCTION auto_lock_on_balance();

-- Generate customer code automatically
CREATE OR REPLACE FUNCTION generate_customer_code()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.customer_code IS NULL THEN
        NEW.customer_code = 'CUST' || LPAD(nextval('customer_code_seq')::TEXT, 6, '0');
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE SEQUENCE IF NOT EXISTS customer_code_seq START 1000;

CREATE TRIGGER trigger_generate_customer_code
    BEFORE INSERT ON customers
    FOR EACH ROW
    EXECUTE FUNCTION generate_customer_code();

-- Generate device code automatically
CREATE OR REPLACE FUNCTION generate_device_code()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.device_code IS NULL THEN
        NEW.device_code = 'DEV' || LPAD(nextval('device_code_seq')::TEXT, 6, '0');
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE SEQUENCE IF NOT EXISTS device_code_seq START 1000;

CREATE TRIGGER trigger_generate_device_code
    BEFORE INSERT ON devices
    FOR EACH ROW
    EXECUTE FUNCTION generate_device_code();

-- Generate transaction code automatically
CREATE OR REPLACE FUNCTION generate_transaction_code()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.transaction_code IS NULL THEN
        NEW.transaction_code = 'TXN' || TO_CHAR(NOW(), 'YYYYMMDD') || LPAD(nextval('transaction_code_seq')::TEXT, 6, '0');
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE SEQUENCE IF NOT EXISTS transaction_code_seq START 1;

CREATE TRIGGER trigger_generate_transaction_code
    BEFORE INSERT ON payment_transactions
    FOR EACH ROW
    EXECUTE FUNCTION generate_transaction_code();

-- ============================================================================
-- VIEWS FOR REPORTING
-- ============================================================================

-- Device summary view
CREATE OR REPLACE VIEW device_summary AS
SELECT 
    d.id,
    d.device_code,
    d.imei,
    d.status,
    d.is_locked,
    c.customer_code,
    c.full_name AS customer_name,
    c.phone AS customer_phone,
    a.full_name AS enrolled_by_name,
    d.device_price,
    d.loan_total,
    d.loan_balance,
    d.total_paid,
    d.last_payment_date,
    d.next_payment_due,
    d.days_overdue,
    d.enrolled_at,
    d.activated_at
FROM devices d
LEFT JOIN customers c ON d.customer_id = c.id
LEFT JOIN administrators a ON d.enrolled_by = a.id;

-- Payment summary view
CREATE OR REPLACE VIEW payment_summary AS
SELECT 
    pt.id,
    pt.transaction_code,
    pt.amount,
    pt.payment_method,
    pt.status,
    pt.processed_at,
    d.device_code,
    c.customer_code,
    c.full_name AS customer_name,
    a.full_name AS processed_by_name
FROM payment_transactions pt
LEFT JOIN devices d ON pt.device_id = d.id
LEFT JOIN customers c ON pt.customer_id = c.id
LEFT JOIN administrators a ON pt.processed_by = a.id;

-- Customer portfolio view
CREATE OR REPLACE VIEW customer_portfolio AS
SELECT 
    c.id,
    c.customer_code,
    c.full_name,
    c.phone,
    c.is_active,
    COUNT(d.id) AS total_devices,
    SUM(d.device_price) AS total_device_value,
    SUM(d.loan_balance) AS total_outstanding,
    SUM(d.total_paid) AS total_paid,
    c.created_at
FROM customers c
LEFT JOIN devices d ON c.id = d.customer_id
GROUP BY c.id;

-- Comments
COMMENT ON TABLE super_admins IS 'Top-level administrators who manage the system';
COMMENT ON TABLE administrators IS 'Field agents who enroll devices and customers';
COMMENT ON TABLE customers IS 'Device buyers/owners';
COMMENT ON TABLE devices IS 'Enrolled devices with payment tracking';
COMMENT ON TABLE payment_transactions IS 'All payment records';
COMMENT ON TABLE payment_schedules IS 'Expected payment schedule';
