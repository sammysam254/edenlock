# 🚀 Eden M-Kopa System - Quick Start Guide

Get your complete M-Kopa-style system running in 30 minutes!

## ✅ What You're Building

A complete device financing system like M-Kopa with:
- Super Admin Dashboard (create administrators)
- Administrator Dashboard (enroll devices, process payments)
- Android Device Locking System
- Automatic payment tracking
- QR code provisioning

## 📋 Prerequisites

- Node.js 18+ installed
- Python 3.11+ installed
- Android Studio (for building APK)
- Supabase account (already configured)

## 🎯 Step-by-Step Setup

### Step 1: Set Up Database (5 minutes)

1. Go to [Supabase SQL Editor](https://supabase.com/dashboard/project/xrmriwtedyaqzwxouyfx/sql)

2. Copy and paste `database/schema.sql` content

3. Click "Run" to execute

4. Create first Super Admin:
```sql
INSERT INTO super_admins (email, full_name, phone, is_active)
VALUES ('admin@edenservices.ke', 'System Admin', '+254700000000', true);
```

### Step 2: Start Dashboard (5 minutes)

```bash
# Navigate to dashboard folder
cd dashboard

# Install dependencies
npm install

# Start development server
npm run dev
```

Dashboard will be available at:
- Super Admin: http://localhost:3000/super-admin
- Administrator: http://localhost:3000/admin

### Step 3: Create Your First Administrator (2 minutes)

1. Open http://localhost:3000/super-admin
2. Click "Create New Administrator"
3. Fill in details:
   - Name: John Agent
   - Email: john@eden.ke
   - Phone: +254712345678
   - Region: Nairobi
   - Branch: CBD
4. Click "Create Administrator"

### Step 4: Test Administrator Dashboard (3 minutes)

1. Open http://localhost:3000/admin
2. Login with administrator credentials
3. You should see:
   - Dashboard with statistics
   - Customer enrollment form
   - Device activation form
   - Payment processing form

### Step 5: Enroll Test Customer (2 minutes)

In Administrator Dashboard:
1. Click "Customers" → "Add New Customer"
2. Fill in:
   - Name: Jane Doe
   - Phone: +254723456789
   - National ID: 12345678
   - Address: Nairobi
3. Click "Create Customer"
4. Customer Code generated: CUST001234

### Step 6: Activate Test Device (3 minutes)

In Administrator Dashboard:
1. Click "Devices" → "Enroll New Device"
2. Fill in:
   - Select Customer: Jane Doe
   - Device Model: Samsung Galaxy A14
   - Device Price: KES 15,000
   - Down Payment: KES 3,000
   - Loan Amount: KES 12,000
   - Daily Payment: KES 100
3. Click "Generate QR Code"
4. QR code is generated for device provisioning

### Step 7: Build Android APK (5 minutes)

```bash
# Navigate to android folder
cd android

# Build release APK
./gradlew assembleRelease

# APK location:
# app/build/outputs/apk/release/eden.apk
```

### Step 8: Test Device Provisioning (5 minutes)

1. Install eden.apk on Android device
2. Factory reset the device
3. During setup, tap welcome screen 6 times
4. Scan the QR code generated in Step 6
5. Device provisions automatically:
   - Sets Device Owner
   - Applies restrictions
   - Links to customer
   - Starts in LOCKED state

### Step 9: Process Test Payment (2 minutes)

In Administrator Dashboard:
1. Click "Payments" → "Record Payment"
2. Fill in:
   - Select Device: DEV001234 (Jane Doe)
   - Amount: KES 100
   - Payment Method: M-Pesa
   - M-Pesa Receipt: ABC123XYZ
   - Phone: +254723456789
3. Click "Submit Payment"
4. System updates:
   - Loan Balance: 12,000 → 11,900
   - Transaction logged

### Step 10: Verify Device Sync (3 minutes)

On Android device:
1. Wait 15 minutes (or restart app)
2. Device syncs with Supabase
3. Checks loan balance
4. Since balance > 0, device stays LOCKED
5. Shows payment screen with:
   - Outstanding balance
   - Payment instructions
   - Refresh button

## 🎉 Success! Your System is Running

You now have:
- ✅ Super Admin Dashboard running
- ✅ Administrator Dashboard running
- ✅ Database configured
- ✅ First administrator created
- ✅ Test customer enrolled
- ✅ Test device activated
- ✅ Payment processed
- ✅ Device syncing

## 📊 What Happens Next?

### Daily Operations

**Administrator:**
1. Enroll new customers
2. Activate devices
3. Generate QR codes
4. Process payments
5. Monitor portfolio

**Customer:**
1. Makes daily payment (KES 100)
2. Device automatically unlocks when paid

**System:**
1. Tracks all payments
2. Updates device status
3. Locks/unlocks automatically
4. Generates reports

### After 120 Days (Full Payment)

When customer pays KES 12,000:
1. Loan Balance = 0
2. Device automatically unlocks
3. Restrictions removed
4. Device Owner cleared
5. App uninstalls
6. Device fully unlocked

## 🔧 Troubleshooting

### Dashboard not starting?
```bash
# Check Node.js version
node --version  # Should be 18+

# Reinstall dependencies
rm -rf node_modules package-lock.json
npm install
```

### Database errors?
- Verify Supabase URL and key in `.env.local`
- Check SQL schema executed successfully
- Verify RLS policies applied

### Android build fails?
```bash
# Clean build
./gradlew clean

# Rebuild
./gradlew assembleRelease
```

### Device not syncing?
- Check Supabase credentials in QR code
- Verify device has internet connection
- Check Android logs: `adb logcat | grep Eden`

## 📚 Next Steps

### Production Deployment

1. **Deploy Dashboard to Vercel:**
```bash
npm run build
vercel deploy
```

2. **Upload APK to Server:**
- Upload eden.apk to your server
- Update `NEXT_PUBLIC_APK_DOWNLOAD_URL`

3. **Configure M-Pesa:**
- Set up M-Pesa Paybill
- Configure webhook
- Integrate with dashboard

4. **Train Your Team:**
- Super Admin training
- Administrator training
- Customer support training

### Customization

- Modify payment terms
- Add more device models
- Customize dashboard branding
- Add SMS notifications
- Integrate with accounting software

## 📞 Support

### Documentation
- `MKOPA_STYLE_IMPLEMENTATION.md` - Complete guide
- `IMPLEMENTATION_STATUS.md` - System overview
- `docs/` folder - Technical docs

### Common Questions

**Q: How do I add more administrators?**
A: Use Super Admin Dashboard → Create New Administrator

**Q: Can I change payment terms?**
A: Yes, edit when enrolling device (daily payment, loan amount, etc.)

**Q: How do I manually unlock a device?**
A: Administrator Dashboard → Devices → Select Device → Manual Unlock

**Q: What if customer loses device?**
A: Device remains locked, can be tracked via IMEI

**Q: How do I generate reports?**
A: Dashboard → Reports → Select report type

## 🎯 Success Metrics

After setup, you should see:
- ✅ Dashboard accessible
- ✅ Administrators can login
- ✅ Customers can be enrolled
- ✅ Devices can be activated
- ✅ QR codes generate successfully
- ✅ Payments can be processed
- ✅ Devices sync automatically
- ✅ Lock/unlock works

## 🚀 You're Ready!

Your Eden M-Kopa system is now fully operational. Start enrolling real customers and devices!

**Happy Financing! 💰📱**

---

**Need Help?** Check `MKOPA_STYLE_IMPLEMENTATION.md` for detailed documentation.
