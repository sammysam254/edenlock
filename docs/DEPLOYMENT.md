# Eden Deployment Guide

Complete deployment instructions for the Eden "Lipa Polepole" system.

## Prerequisites

- Android Studio (latest version)
- Python 3.11+
- Supabase account
- Render account (for backend hosting)
- Blockchain RPC endpoint (Polygon/BSC)
- Smart contract deployed with PaymentReceived event

## 1. Database Setup (Supabase)

### Step 1: Create Supabase Project
1. Go to https://supabase.com
2. Create a new project
3. Note your project URL and keys

### Step 2: Run Database Schema
```bash
# In Supabase SQL Editor, run:
cat database/schema.sql | pbcopy
# Paste and execute in SQL Editor

# Then run RLS policies:
cat database/rls_policies.sql | pbcopy
# Paste and execute in SQL Editor
```

### Step 3: Get Service Role Key
1. Go to Project Settings > API
2. Copy the `service_role` key (NOT the anon key)
3. Save for backend configuration

## 2. Backend Deployment (Render)

### Step 1: Prepare Repository
```bash
cd backend
cp .env.example .env
# Edit .env with your credentials
```

### Step 2: Deploy to Render
1. Push code to GitHub
2. Go to https://render.com
3. Create new "Background Worker"
4. Connect your repository
5. Set environment variables:
   - `RPC_URL`: Your blockchain RPC endpoint
   - `CONTRACT_ADDRESS`: Your smart contract address
   - `CHAIN_ID`: 137 (Polygon) or 56 (BSC)
   - `SUPABASE_URL`: Your Supabase project URL
   - `SUPABASE_SERVICE_KEY`: Service role key from Supabase
   - `POLL_INTERVAL`: 15 (seconds)

### Step 3: Verify Deployment
```bash
# Check logs in Render dashboard
# Should see: "✓ Eden Listener initialized"
```

## 3. Android App Build

### Step 1: Configure Signing
```bash
cd android

# Generate release keystore
keytool -genkey -v -keystore release.keystore -alias eden -keyalg RSA -keysize 2048 -validity 10000

# Set environment variables
export KEYSTORE_FILE=release.keystore
export KEYSTORE_PASSWORD=your_password
export KEY_ALIAS=eden
export KEY_PASSWORD=your_key_password
```

### Step 2: Build APK
```bash
./gradlew assembleRelease

# APK will be at:
# app/build/outputs/apk/release/eden.apk
```

### Step 3: Generate Checksum
```bash
cd provisioning
chmod +x generate_checksum.sh
./generate_checksum.sh ../app/build/outputs/apk/release/eden.apk

# Copy the output checksum
```

## 4. Provisioning Configuration

### Step 1: Update provisioning.json
```bash
cd android/provisioning
nano provisioning.json
```

Update these fields:
- `PROVISIONING_DEVICE_ADMIN_SIGNATURE_CHECKSUM`: Paste checksum from Step 3
- `PROVISIONING_DEVICE_ADMIN_PACKAGE_DOWNLOAD_LOCATION`: Your APK hosting URL
- `PROVISIONING_WIFI_SSID`: WiFi network name
- `PROVISIONING_WIFI_PASSWORD`: WiFi password
- `PROVISIONING_ADMIN_EXTRAS_BUNDLE`:
  - `supabase_url`: Your Supabase project URL
  - `supabase_key`: Supabase anon key (NOT service role)
  - `wallet_address`: Device's blockchain wallet address

### Step 2: Host APK
Upload `eden.apk` to a publicly accessible HTTPS URL:
- AWS S3
- Google Cloud Storage
- GitHub Releases
- Your own server

### Step 3: Generate QR Code
1. Copy entire `provisioning.json` content
2. Go to https://qr-code-generator.com
3. Select "Text" type
4. Paste JSON content
5. Generate and download QR code

## 5. Device Provisioning

### Factory Reset Method (Recommended)
1. Factory reset the Android device
2. On the welcome screen, tap 6 times quickly
3. Scan the QR code you generated
4. Device will:
   - Connect to WiFi
   - Download eden.apk
   - Install as Device Owner
   - Apply all restrictions
   - Launch Eden app

### ADB Method (Testing Only)
```bash
# For testing on non-factory-reset devices
adb install eden.apk

adb shell dpm set-device-owner ke.edenservices.eden/.EdenDeviceAdminReceiver

# Note: This only works on devices without accounts
```

## 6. Device Registration

After provisioning, register the device in Supabase:

```sql
INSERT INTO devices (imei, wallet_address, loan_total, loan_balance, is_locked)
VALUES (
    'device_android_id_here',
    '0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb',
    50000.00,
    50000.00,
    true
);
```

Or use the Android app's registration function (if implemented).

## 7. Testing

### Test Payment Flow
1. Send test payment to device's wallet address
2. Backend listener should detect payment
3. Supabase `loan_balance` should decrease
4. Device should unlock when balance reaches 0

### Test Lock Status
```bash
# Check device status in Supabase
SELECT * FROM devices WHERE imei = 'device_id';

# Manually trigger lock
UPDATE devices SET is_locked = true WHERE imei = 'device_id';
```

## 8. Monitoring

### Backend Logs (Render)
- View logs in Render dashboard
- Check for payment events
- Monitor errors

### Device Logs (Android)
```bash
adb logcat | grep -E "Eden|Supabase|DeviceAdmin"
```

### Supabase Logs
- Check device_sync_logs table
- Monitor payment_transactions table

## Security Checklist

- ✅ Use HTTPS for APK download
- ✅ Use service_role key only in backend
- ✅ Use anon key in Android app
- ✅ Enable RLS policies in Supabase
- ✅ Sign APK with production keystore
- ✅ Test factory reset protection
- ✅ Verify ADB is disabled on device
- ✅ Test kiosk mode lockout

## Troubleshooting

### Device Not Locking
- Check Supabase connection
- Verify WorkManager is running
- Check device_sync_logs

### Backend Not Detecting Payments
- Verify RPC_URL is correct
- Check CONTRACT_ADDRESS
- Ensure contract has PaymentReceived event
- Check Render logs

### QR Provisioning Failed
- Verify APK checksum matches
- Check APK download URL is accessible
- Ensure WiFi credentials are correct
- Try factory reset again

## Support

For issues, contact Eden Services KE support team.
