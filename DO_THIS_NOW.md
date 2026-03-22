# ⚡ DO THIS NOW - Get Your System Running

## 🎯 Follow These Exact Steps

### STEP 1: Set Up Database (5 minutes)

1. **Open Supabase SQL Editor:**
   ```
   https://supabase.com/dashboard/project/xrmriwtedyaqzwxouyfx/sql
   ```

2. **Copy this file content:**
   ```
   database/schema.sql
   ```

3. **Paste in SQL Editor and click RUN**

4. **Create your first Super Admin:**
   ```sql
   INSERT INTO super_admins (email, full_name, phone, is_active)
   VALUES ('admin@edenservices.ke', 'System Admin', '+254700000000', true);
   ```

✅ **Database is now ready!**

---

### STEP 2: Start Dashboard (5 minutes)

Open your terminal and run:

```bash
# Navigate to dashboard folder
cd dashboard

# Install dependencies (first time only)
npm install

# Start development server
npm run dev
```

**Wait for:**
```
✓ Ready in 3.2s
○ Local:   http://localhost:3000
```

✅ **Dashboard is now running!**

---

### STEP 3: Access Dashboards

Open in your browser:

**Super Admin Dashboard:**
```
http://localhost:3000/super-admin
```

**Administrator Dashboard:**
```
http://localhost:3000/admin
```

✅ **You should see the dashboard interface!**

---

### STEP 4: Create Your First Administrator

In Super Admin Dashboard:

1. Click **"+ Create New Administrator"**

2. Fill in:
   - **Full Name:** John Agent
   - **Email:** john@eden.ke
   - **Phone:** +254712345678
   - **Region:** Nairobi
   - **Branch:** CBD

3. Click **"Create Administrator"**

✅ **Administrator created!**

---

### STEP 5: Test Administrator Dashboard

1. Open **http://localhost:3000/admin**

2. You should see:
   - Dashboard with statistics
   - Navigation menu
   - Customer enrollment form
   - Device activation form

✅ **Administrator dashboard working!**

---

### STEP 6: Enroll Test Customer

In Administrator Dashboard:

1. Click **"Customers"** → **"Add New Customer"**

2. Fill in:
   - **Full Name:** Jane Doe
   - **Phone:** +254723456789
   - **National ID:** 12345678
   - **Address:** Nairobi, Kenya

3. Click **"Create Customer"**

4. Note the **Customer Code:** CUST001234

✅ **Customer enrolled!**

---

### STEP 7: Activate Test Device

In Administrator Dashboard:

1. Click **"Devices"** → **"Enroll New Device"**

2. Fill in:
   - **Select Customer:** Jane Doe
   - **Device Model:** Samsung Galaxy A14
   - **Device Price:** 15000
   - **Down Payment:** 3000
   - **Loan Amount:** 12000 (auto-calculated)
   - **Daily Payment:** 100
   - **Payment Frequency:** Daily

3. Click **"Generate QR Code"**

4. **QR Code appears!** This will be used to provision the device.

5. Note the **Device Code:** DEV001234

✅ **Device activated and QR code generated!**

---

### STEP 8: Build Android APK (Optional - 5 minutes)

If you want to test on a real device:

```bash
# Navigate to android folder
cd android

# Build release APK
./gradlew assembleRelease

# APK will be at:
# app/build/outputs/apk/release/eden.apk
```

✅ **APK built!**

---

### STEP 9: Test Payment Processing

In Administrator Dashboard:

1. Click **"Payments"** → **"Record Payment"**

2. Fill in:
   - **Select Device:** DEV001234 (Jane Doe)
   - **Amount:** 100
   - **Payment Method:** M-Pesa
   - **M-Pesa Receipt:** ABC123XYZ
   - **M-Pesa Phone:** +254723456789

3. Click **"Submit Payment"**

4. Check device details:
   - **Loan Balance:** 12000 → 11900 ✓
   - **Total Paid:** 0 → 100 ✓
   - **Last Payment:** Just now ✓

✅ **Payment processed successfully!**

---

## 🎉 SUCCESS! Your System is Working!

You now have:
- ✅ Database configured
- ✅ Super Admin dashboard running
- ✅ Administrator dashboard running
- ✅ Administrator account created
- ✅ Customer enrolled
- ✅ Device activated
- ✅ QR code generated
- ✅ Payment processed

---

## 📱 What Happens on the Android Device?

When you provision a device with the QR code:

1. **Device provisions automatically**
   - Sets Device Owner
   - Applies restrictions
   - Links to customer (Jane Doe)
   - Links to device (DEV001234)

2. **Device starts LOCKED**
   - Shows payment screen
   - Displays outstanding balance: KES 11,900
   - Shows payment instructions
   - Cannot exit app (kiosk mode)

3. **Device syncs every 15 minutes**
   - Checks loan balance from Supabase
   - If balance > 0: Stays locked
   - If balance = 0: Unlocks automatically

4. **After 120 days (KES 12,000 paid)**
   - Loan balance = 0
   - Device unlocks
   - Restrictions removed
   - App uninstalls
   - Device fully unlocked

---

## 🔄 Daily Operations

### As Administrator:

**Morning:**
1. Login to dashboard
2. Check pending payments
3. View overdue devices

**During Day:**
1. Enroll new customers
2. Activate new devices
3. Process payments as they come
4. Generate QR codes for new devices

**Evening:**
1. Review daily collection
2. Check device statuses
3. Generate daily report

---

## 📊 View Your Statistics

In Administrator Dashboard, you can see:
- Total customers enrolled
- Total devices activated
- Total revenue collected
- Outstanding loans
- Collection rate
- Overdue devices

---

## 🎓 Next Steps

### For Production:

1. **Deploy Dashboard to Vercel:**
   ```bash
   cd dashboard
   npm run build
   vercel deploy
   ```

2. **Upload APK to Server:**
   - Upload eden.apk to your hosting
   - Update `NEXT_PUBLIC_APK_DOWNLOAD_URL`

3. **Configure M-Pesa:**
   - Set up Paybill/Till number
   - Configure webhook for automatic payments
   - Integrate with dashboard

4. **Train Your Team:**
   - Super Admin training
   - Administrator training
   - Customer support procedures

### For Testing:

1. **Create more administrators**
2. **Enroll more customers**
3. **Activate more devices**
4. **Process multiple payments**
5. **Test device provisioning**
6. **Verify lock/unlock**

---

## 🆘 Troubleshooting

### Dashboard won't start?
```bash
# Check Node.js version
node --version  # Should be 18+

# Reinstall dependencies
rm -rf node_modules
npm install
```

### Can't see data in dashboard?
- Check Supabase credentials in `.env.local`
- Verify database schema executed
- Check browser console for errors

### Database errors?
- Verify you ran `schema.sql` in Supabase
- Check Supabase project is active
- Verify credentials are correct

---

## 📞 Need Help?

### Documentation:
- `QUICK_START_GUIDE.md` - Detailed setup
- `MKOPA_STYLE_IMPLEMENTATION.md` - Complete guide
- `START_BUILDING.md` - System overview

### Check:
- Browser console (F12) for errors
- Terminal for error messages
- Supabase dashboard for database issues

---

## ✅ Verification Checklist

Make sure you completed:
- [ ] Database schema executed in Supabase
- [ ] Super Admin created
- [ ] Dashboard running (npm run dev)
- [ ] Super Admin dashboard accessible
- [ ] Administrator dashboard accessible
- [ ] Administrator account created
- [ ] Customer enrolled (CUST001234)
- [ ] Device activated (DEV001234)
- [ ] QR code generated
- [ ] Payment processed
- [ ] Loan balance updated

---

## 🎯 You're Done!

Your M-Kopa-style system is now fully operational!

**Start enrolling real customers and devices!**

---

**Questions?** Read `MKOPA_STYLE_IMPLEMENTATION.md` for complete documentation.

**Ready to deploy?** Read `docs/DEPLOYMENT.md` for production setup.

**Need training?** Check the training sections in documentation.

---

**🚀 Happy Building!**

*Built for Eden Services KE*
