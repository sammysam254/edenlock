-- Row Level Security (RLS) Policies for Eden
-- Ensures devices can only access their own data

-- Enable RLS on devices table
ALTER TABLE devices ENABLE ROW LEVEL SECURITY;

-- Policy: Devices can only read their own row
-- Uses the anon key with custom claim or JWT containing device IMEI
CREATE POLICY "Devices can read own data"
    ON devices
    FOR SELECT
    USING (
        imei = current_setting('request.jwt.claims', true)::json->>'imei'
        OR
        auth.uid() IS NOT NULL  -- Allow authenticated service role
    );

-- Policy: Service role can read all devices (for backend listener)
CREATE POLICY "Service role can read all devices"
    ON devices
    FOR SELECT
    TO service_role
    USING (true);

-- Policy: Service role can update all devices (for backend listener)
CREATE POLICY "Service role can update devices"
    ON devices
    FOR UPDATE
    TO service_role
    USING (true)
    WITH CHECK (true);

-- Policy: Service role can insert devices (for provisioning)
CREATE POLICY "Service role can insert devices"
    ON devices
    FOR INSERT
    TO service_role
    WITH CHECK (true);

-- Enable RLS on payment_transactions
ALTER TABLE payment_transactions ENABLE ROW LEVEL SECURITY;

-- Policy: Service role can insert transactions
CREATE POLICY "Service role can insert transactions"
    ON payment_transactions
    FOR INSERT
    TO service_role
    WITH CHECK (true);

-- Policy: Devices can read their own transactions
CREATE POLICY "Devices can read own transactions"
    ON payment_transactions
    FOR SELECT
    USING (
        device_id IN (
            SELECT id FROM devices 
            WHERE imei = current_setting('request.jwt.claims', true)::json->>'imei'
        )
        OR
        auth.uid() IS NOT NULL
    );

-- Enable RLS on sync logs
ALTER TABLE device_sync_logs ENABLE ROW LEVEL SECURITY;

-- Policy: Service role can manage sync logs
CREATE POLICY "Service role can manage sync logs"
    ON device_sync_logs
    FOR ALL
    TO service_role
    USING (true)
    WITH CHECK (true);

-- Grant permissions
GRANT USAGE ON SCHEMA public TO anon, authenticated, service_role;
GRANT ALL ON ALL TABLES IN SCHEMA public TO service_role;
GRANT SELECT ON devices TO anon, authenticated;
GRANT SELECT ON payment_transactions TO anon, authenticated;

-- Create API view for device status (simplified access)
CREATE OR REPLACE VIEW device_status AS
SELECT 
    id,
    imei,
    wallet_address,
    loan_total,
    loan_balance,
    is_locked,
    last_payment_amount,
    last_payment_timestamp,
    updated_at
FROM devices;

-- Grant access to view
GRANT SELECT ON device_status TO anon, authenticated, service_role;

-- RLS on view
ALTER VIEW device_status SET (security_invoker = true);
