# Eden Quick Start Guide

Get Eden up and running in 30 minutes.

## Prerequisites Checklist

- [ ] Android Studio installed
- [ ] Python 3.11+ installed
- [ ] Supabase account created
- [ ] Render account created
- [ ] Blockchain RPC endpoint (Polygon/BSC)
- [ ] Smart contract deployed (or use test contract)

## 5-Step Deployment

### Step 1: Database Setup (5 minutes)

```bash
# 1. Create Supabase project at https://supabase.com
# 2. Copy your project URL and keys
# 3. Run schema in SQL Editor

cat database/schema.sql
# Copy and paste into Supabase SQL Editor, execute

cat database/rls_policies.sql
# Copy and paste into Supabase SQL Editor, execute

# 4. Note your credentials:
SUPABASE_URL=https://xxxxx.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
SUPABASE_SERVICE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

### Step 2: Backend Deployment (10 minutes)

```bash
# 1. Create .env file
cd backend
cp .env.example .env

# 2. Edit .env with your values
nano .env

# 3. Push to GitHub
git init
git add .
git commit -m "Initial commit"
git remote add origin https://github.com/yourusername/eden.git
git push -u origin main

# 4. Deploy on Render
# - Go to https://render.com
# - New > Background Worker
# - Connect GitHub repo
# - Set environment variables from .env
# - Deploy

# 5. Verify logs show:
# "✓ Eden Listener initialized"
```

### Step 3: Android Build (10 minutes)

```bash
cd android

# 1. Generate keystore
keytool -genkey -v -keystore release.keystore \
  -alias eden -keyalg RSA -keysize 2048 -validity 10000

# 2. Set environment variables
export KEYSTORE_FILE=release.keystore
export KEYSTORE_PASSWORD=your_password
export KEY_ALIAS=eden
export KEY_PASSWORD=your_key_password

# 3. Build APK
./gradlew assembleRelease

# 4. APK location:
# app/build/outputs/apk/release/eden.apk
```

### Step 4: QR Code Generation (3 minutes)

```bash
cd provisioning

# 1. Generate checksum
./generate_checksum.sh ../app/build/outputs/apk/release/eden.apk

# 2. Copy checksum output

# 3. Upload APK to hosting (choose one):
# - AWS S3: aws s3 cp eden.apk s3://bucket/eden.apk --acl public-read
# - GitHub Releases: Upload as release asset
# - Your server: scp eden.apk user@server:/var/www/html/

# 4. Edit provisioning.json
nano provisioning.json
# Update:
# - CHECKSUM (from step 1)
# - DOWNLOAD_LOCATION (from step 3)
# - WiFi credentials
# - Supabase credentials
# - Wallet address

# 5. Generate QR code at https://qr-code-generator.com
# - Copy entire provisioning.json content
# - Paste into "Text" field
# - Download QR code
```

### Step 5: Device Provisioning (2 minutes)

```bash
# 1. Factory reset Android device
# 2. On welcome screen, tap 6 times
# 3. Scan QR code
# 4. Wait for automatic setup
# 5. Verify "Device Protection Active"
```

## Testing the System

### Test 1: Verify Device Lock

```sql
-- In Supabase SQL Editor
UPDATE devices 
SET is_locked = true, loan_balance = 1000.00 
WHERE imei = 'your_device_imei';
```

Wait 15 minutes (or restart app), device should lock.

### Test 2: Simulate Payment

```javascript
// Using Remix or ethers.js
const tx = await contract.makePayment(
  "0xDeviceWalletAddress",
  { value: ethers.utils.parseEther("0.1") }
);
await tx.wait();
```

Backend should detect payment and update Supabase.

### Test 3: Verify Unlock

```sql
-- Check updated balance
SELECT * FROM devices WHERE imei = 'your_device_imei';
-- loan_balance should be reduced
-- is_locked should be false if balance = 0
```

Device should unlock automatically.

## Common Issues

### Issue: QR Scanner Not Appearing
**Solution:** Try tapping different areas, or enable via ADB:
```bash
adb shell settings put global device_provisioning_mobile_data_enabled 1
```

### Issue: Checksum Verification Failed
**Solution:** Regenerate checksum and update provisioning.json:
```bash
./generate_checksum.sh path/to/eden.apk
```

### Issue: Backend Not Detecting Payments
**Solution:** Check Render logs, verify RPC_URL and CONTRACT_ADDRESS

### Issue: Device Not Syncing
**Solution:** Check Supabase credentials in app, verify network connection

## Next Steps

1. **Read Full Documentation**
   - `docs/DEPLOYMENT.md` - Complete deployment guide
   - `docs/QR_SETUP.md` - Detailed QR provisioning
   - `docs/ARCHITECTURE.md` - System architecture
   - `docs/SMART_CONTRACT.md` - Contract deployment

2. **Production Checklist**
   - [ ] Use production Supabase project
   - [ ] Deploy backend to production Render plan
   - [ ] Use mainnet blockchain (Polygon/BSC)
   - [ ] Secure keystore and credentials
   - [ ] Test on multiple devices
   - [ ] Set up monitoring and alerts

3. **Customize**
   - Update app branding (logo, colors)
   - Modify loan terms and payment logic
   - Add custom features (SMS notifications, etc.)
   - Implement admin dashboard

## Support

For issues or questions:
- Check documentation in `docs/` folder
- Review code comments
- Contact Eden Services KE support

## Security Reminder

- Never commit `.env` files
- Never share QR codes publicly (contain WiFi passwords)
- Use HTTPS for all endpoints
- Rotate Supabase keys periodically
- Keep keystore secure

---

**Congratulations!** You now have a fully functional Eden device-locking system. 🎉
