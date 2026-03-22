-- Eden Supabase Database Schema - M-Kopa Style
-- Clean installation script

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Drop existing tables if they exist (clean slate)
DROP TABLE IF EXISTS device_lock_history CASCADE;
DROP TABLE IF EXISTS admin_activity_logs CASCADE;
DROP TABLE IF EXISTS device_sync_logs CASCADE;
DROP TABLE IF EXISTS payment_schedules CASCADE;
DROP TABLE IF EXISTS payment_transactions CASCADE;
DROP TABLE IF EXISTS enrollment_sessions CASCADE;
DROP TABLE IF EXISTS devices CASCADE;
DROP TABLE IF EXISTS customers CASCADE;
DROP TABLE IF EXISTS administrators CASCADE;
DROP TABLE IF EXISTS super_admins CASCADE;

-- Drop sequences
DROP SEQUENCE IF EXISTS customer_code_seq CASCADE;
DROP SEQUENCE IF EXISTS device_code_seq CASCADE;
DROP SEQUENCE IF EXISTS transaction_code_seq CASCADE;

-- Drop views
DROP VIEW IF EXISTS device_summary CASCADE;
DROP VIEW IF EXISTS payment_summary CASCADE;
DROP VIEW IF EXISTS customer_portfolio CASCADE;

-- ============================================================================
-- USER MANAGEMENT TABLES
-- ============================================================================

-- Super Admins table
CREATE TABLE super_admins (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email TEXT UNIQUE NOT NULL,
    full_name TEXT NOT NULL,
    phone TEXT,
    auth_user_id UUID,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Administrators table
CREATE TABLE administrators (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email TEXT UNIQUE NOT NULL,
    full_name TEXT NOT NULL,
    phone TEXT NOT NULL,
    auth_user_id UUID,
    created_by UUID REFERENCES super_admins(id),
    is_active BOOLEAN DEFAULT true,
    region TEXT,
    branch TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Customers table
CREATE TABLE customers (
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

-- Devices table
CREATE TABLE devices (
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
    payment_frequency TEXT DEFAULT 'daily',
    
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
    status TEXT DEFAULT 'enrolled',
    
    -- Constraints
    CONSTRAINT positive_device_price CHECK (device_price >= 0),
    CONSTRAINT positive_loan_total CHECK (loan_total >= 0),
    CONSTRAINT positive_loan_balance CHECK (loan_balance >= 0),
    CONSTRAINT balance_not_exceed_total CHECK (loan_balance <= loan_total)
);

-- ============================================================================
-- ENROLLMENT & ACTIVATION TABLES
-- ============================================================================

-- Enrollment sessions
CREATE TABLE enrollment_sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    device_id UUID REFERENCES devices(id) ON DELETE CASCADE,
    administrator_id UUID REFERENCES administrators(id),
    qr_code_data TEXT NOT NULL,
    qr_code_url TEXT,
    status TEXT DEFAULT 'pending',
    expires_at TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================================================
-- PAYMENT TABLES
-- ============================================================================

-- Payment transactions
CREATE TABLE payment_transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    transaction_code TEXT UNIQUE NOT NULL,
    device_id UUID NOT NULL REFERENCES devices(id) ON DELETE CASCADE,
    customer_id UUID REFERENCES customers(id),
    
    -- Payment details
    amount DECIMAL(10, 2) NOT NULL,
    payment_method TEXT NOT NULL,
    payment_reference TEXT,
    
    -- M-Pesa specific
    mpesa_receipt TEXT,
    mpesa_phone TEXT,
    
    -- Status
    status TEXT DEFAULT 'completed',
    processed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    verified_at TIMESTAMP WITH TIME ZONE,
    
    -- Metadata
    notes TEXT,
    processed_by UUID REFERENCES administrators(id),
    
    CONSTRAINT positive_amount CHECK (amount > 0)
);

-- Payment schedules
CREATE TABLE payment_schedules (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    device_id UUID REFERENCES devices(id) ON DELETE CASCADE,
    customer_id UUID REFERENCES customers(id),
    
    due_date DATE NOT NULL,
    amount_due DECIMAL(10, 2) NOT NULL,
    amount_paid DECIMAL(10, 2) DEFAULT 0.00,
    status TEXT DEFAULT 'pending',
    
    paid_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================================================
-- AUDIT & LOGGING TABLES
-- ============================================================================

-- Device sync logs
CREATE TABLE device_sync_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    device_id UUID REFERENCES devices(id) ON DELETE CASCADE,
    imei TEXT NOT NULL,
    sync_type TEXT NOT NULL,
    sync_status TEXT NOT NULL,
    details JSONB,
    synced_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Admin activity logs
CREATE TABLE admin_activity_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    admin_id UUID,
    admin_type TEXT NOT NULL,
    action TEXT NOT NULL,
    resource_type TEXT,
    resource_id UUID,
    details JSONB,
    ip_address TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Device lock history
CREATE TABLE device_lock_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    device_id UUID REFERENCES devices(id) ON DELETE CASCADE,
    action TEXT NOT NULL,
    reason TEXT,
    triggered_by TEXT,
    admin_id UUID,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================================================
-- INDEXES
-- ============================================================================

CREATE INDEX idx_devices_customer ON devices(customer_id);
CREATE INDEX idx_devices_enrolled_by ON devices(enrolled_by);
CREATE INDEX idx_devices_imei ON devices(imei);
CREATE INDEX idx_devices_status ON devices(status);
CREATE INDEX idx_devices_locked ON devices(is_locked);

CREATE INDEX idx_customers_phone ON customers(phone);
CREATE INDEX idx_customers_code ON customers(customer_code);
CREATE INDEX idx_customers_enrolled_by ON customers(enrolled_by);

CREATE INDEX idx_administrators_email ON administrators(email);
CREATE INDEX idx_administrators_active ON administrators(is_active);

CREATE INDEX idx_transactions_device ON payment_transactions(device_id);
CREATE INDEX idx_transactions_customer ON payment_transactions(customer_id);
CREATE INDEX idx_transactions_status ON payment_transactions(status);

CREATE INDEX idx_schedules_device ON payment_schedules(device_id);
CREATE INDEX idx_schedules_due_date ON payment_schedules(due_date);

CREATE INDEX idx_sync_logs_device ON device_sync_logs(device_id);
CREATE INDEX idx_activity_logs_admin ON admin_activity_logs(admin_id);
CREATE INDEX idx_lock_history_device ON device_lock_history(device_id);

-- ============================================================================
-- SEQUENCES
-- ============================================================================

CREATE SEQUENCE customer_code_seq START 1000;
CREATE SEQUENCE device_code_seq START 1000;
CREATE SEQUENCE transaction_code_seq START 1;

-- ============================================================================
-- TRIGGERS
-- ============================================================================

-- Auto-update updated_at
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

-- Generate customer code
CREATE OR REPLACE FUNCTION generate_customer_code()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.customer_code IS NULL OR NEW.customer_code = '' THEN
        NEW.customer_code = 'CUST' || LPAD(nextval('customer_code_seq')::TEXT, 6, '0');
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_generate_customer_code
    BEFORE INSERT ON customers
    FOR EACH ROW
    EXECUTE FUNCTION generate_customer_code();

-- Generate device code
CREATE OR REPLACE FUNCTION generate_device_code()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.device_code IS NULL OR NEW.device_code = '' THEN
        NEW.device_code = 'DEV' || LPAD(nextval('device_code_seq')::TEXT, 6, '0');
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_generate_device_code
    BEFORE INSERT ON devices
    FOR EACH ROW
    EXECUTE FUNCTION generate_device_code();

-- Generate transaction code
CREATE OR REPLACE FUNCTION generate_transaction_code()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.transaction_code IS NULL OR NEW.transaction_code = '' THEN
        NEW.transaction_code = 'TXN' || TO_CHAR(NOW(), 'YYYYMMDD') || LPAD(nextval('transaction_code_seq')::TEXT, 6, '0');
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_generate_transaction_code
    BEFORE INSERT ON payment_transactions
    FOR EACH ROW
    EXECUTE FUNCTION generate_transaction_code();

-- ============================================================================
-- VIEWS
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
    COALESCE(SUM(d.device_price), 0) AS total_device_value,
    COALESCE(SUM(d.loan_balance), 0) AS total_outstanding,
    COALESCE(SUM(d.total_paid), 0) AS total_paid,
    c.created_at
FROM customers c
LEFT JOIN devices d ON c.id = d.customer_id
GROUP BY c.id;

-- ============================================================================
-- COMMENTS
-- ============================================================================

COMMENT ON TABLE super_admins IS 'Top-level administrators who manage the system';
COMMENT ON TABLE administrators IS 'Field agents who enroll devices and customers';
COMMENT ON TABLE customers IS 'Device buyers/owners';
COMMENT ON TABLE devices IS 'Enrolled devices with payment tracking';
COMMENT ON TABLE payment_transactions IS 'All payment records';
COMMENT ON TABLE payment_schedules IS 'Expected payment schedule';

-- Success message
DO $$
BEGIN
    RAISE NOTICE '✓ Eden M-Kopa Database Schema Created Successfully!';
    RAISE NOTICE '✓ 13 Tables Created';
    RAISE NOTICE '✓ 3 Views Created';
    RAISE NOTICE '✓ All Triggers and Functions Created';
    RAISE NOTICE '';
    RAISE NOTICE 'Next Step: Create your first Super Admin:';
    RAISE NOTICE 'INSERT INTO super_admins (email, full_name, phone, is_active)';
    RAISE NOTICE 'VALUES (''admin@edenservices.ke'', ''System Admin'', ''+254700000000'', true);';
END $$;
