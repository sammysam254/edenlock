# 🚀 Administrator Dashboard - Quick Start

Get started with the Eden Administrator Dashboard in 5 minutes!

---

## 📍 Access Dashboard

**Local Development:**
```
http://localhost:3000/admin
```

**Production:**
```
https://your-domain.com/admin
```

---

## 🎯 Quick Actions

### 1️⃣ Add Your First Customer (2 minutes)

1. Click **"Customers"** tab
2. Click **"+ Add New Customer"** button
3. Fill in:
   ```
   Full Name: Jane Doe
   Phone: +254712345678
   Email: jane@example.com (optional)
   National ID: 12345678 (optional)
   Address: Nairobi, Kenya (optional)
   ```
4. Click **"Create Customer"**
5. ✅ Customer code generated: `CUST001234`

---

### 2️⃣ Enroll Your First Device (3 minutes)

1. Click **"Devices"** tab
2. Click **"+ Enroll New Device"** button
3. Fill in:
   ```
   Select Customer: CUST001234 - Jane Doe
   Device IMEI: 123456789012345
   Device Model: Samsung Galaxy A14
   Device Price: 15000
   Down Payment: 3000
   Daily Payment: 100
   Payment Frequency: Daily
   ```
4. Click **"Enroll Device & Generate QR Code"**
5. ✅ Device code generated: `DEV001234`
6. ✅ QR code data displayed

---

### 3️⃣ Generate QR Code for Provisioning (2 minutes)

1. Copy the JSON payload from the popup
2. Go to https://www.qr-code-generator.com/
3. Select **"Text"** type
4. Paste the JSON payload
5. Click **"Create QR Code"**
6. Download or print the QR code
7. ✅ QR code ready for device provisioning

---

### 4️⃣ Provision Device (3 minutes)

1. Factory reset the device
2. During setup, tap the welcome screen **6 times**
3. QR code scanner appears
4. Scan the QR code you generated
5. Device downloads Eden APK automatically
6. Device provisions as Device Owner
7. ✅ Device is now locked and ready

---

### 5️⃣ Record Your First Payment (2 minutes)

1. Click **"Payments"** tab
2. Click **"+ Record Payment"** button
3. Fill in:
   ```
   Select Device: DEV001234 - Balance: KES 12,000
   Amount: 100
   Payment Method: M-Pesa
   M-Pesa Receipt: QA12BC3DEF
   M-Pesa Phone: +254712345678
   ```
4. Click **"Process Payment"**
5. ✅ Transaction code generated: `TXN20240322001234`
6. ✅ Device balance updated: `KES 11,900`

---

### 6️⃣ View Reports (1 minute)

1. Click **"Reports"** tab
2. See:
   - Today's Collection: `KES 100`
   - Monthly Collection: `KES 100`
   - Collection Rate: `0.83%`
   - Overdue Devices: `0`
3. ✅ Reports ready for review

---

## 🎨 Dashboard Navigation

```
┌─────────────────────────────────────────────────┐
│  Administrator Dashboard                        │
├─────────────────────────────────────────────────┤
│  [Dashboard] [Customers] [Devices] [Payments] [Reports]
└─────────────────────────────────────────────────┘

Dashboard Tab:
├─ Statistics Cards (4 metrics)
├─ Recent Enrollments (last 5)
└─ Recent Payments (last 5)

Customers Tab:
├─ Customer List (table)
└─ Add New Customer (form)

Devices Tab:
├─ Device List (table)
├─ Enroll New Device (form)
└─ QR Code Generation (popup)

Payments Tab:
├─ Payment History (table)
└─ Record Payment (form)

Reports Tab:
├─ Daily/Monthly Collection
├─ Collection Rate
├─ Overdue Devices
└─ Payment Method Breakdown
```

---

## 💡 Pro Tips

### Customer Management
✅ Always verify phone number format: `+254712345678`  
✅ Record national ID for identity verification  
✅ Get complete address for follow-up  

### Device Enrollment
✅ Double-check IMEI (15 digits)  
✅ Calculate daily payment based on customer's ability  
✅ Test QR code before giving device to customer  

### Payment Processing
✅ Always get M-Pesa receipt number  
✅ Record payment immediately  
✅ Add notes for special circumstances  

### Daily Operations
✅ Check dashboard home every morning  
✅ Review overdue devices daily  
✅ Record all payments same day  

---

## 🔥 Common Workflows

### Morning Routine (5 minutes)
```
1. Open Dashboard Home
2. Check statistics
3. Review overdue devices
4. Plan collection activities
```

### Customer Enrollment (10 minutes)
```
1. Create customer
2. Enroll device
3. Generate QR code
4. Provision device
5. Verify lock status
```

### Payment Collection (3 minutes)
```
1. Receive payment
2. Record in dashboard
3. Verify balance update
4. Confirm with customer
```

### End-of-Day (5 minutes)
```
1. Go to Reports
2. Check daily collection
3. Review overdue devices
4. Generate summary
```

---

## 📱 Mobile Access

The dashboard works on:
- ✅ Desktop computers
- ✅ Laptops
- ✅ Tablets (recommended)
- ✅ Smartphones

**Best Experience:** Tablet or laptop

---

## ⚡ Keyboard Shortcuts

```
Tab          - Navigate between fields
Enter        - Submit form
Esc          - Close popup
Ctrl/Cmd + R - Refresh page
```

---

## 🆘 Quick Help

### Issue: Customer not in dropdown
**Fix:** Refresh page or verify customer was created

### Issue: Device not locking
**Fix:** Wait 15 minutes for sync, then check

### Issue: Payment not updating balance
**Fix:** Verify payment in history, refresh devices list

### Issue: QR code not working
**Fix:** Verify device is factory reset, regenerate QR

---

## 📞 Support

**Technical Issues:**  
Email: support@edenservices.ke  
Phone: +254700000000

**Business Questions:**  
Contact your regional manager

---

## 🎓 Training Resources

- **Full User Guide:** `ADMINISTRATOR_DASHBOARD_GUIDE.md`
- **System Documentation:** `MKOPA_STYLE_IMPLEMENTATION.md`
- **Architecture:** `docs/ARCHITECTURE.md`
- **Deployment:** `docs/DEPLOYMENT.md`

---

## ✅ Checklist for First Day

- [ ] Log in to dashboard
- [ ] Explore all 5 sections
- [ ] Create test customer
- [ ] Enroll test device
- [ ] Generate QR code
- [ ] Provision test device
- [ ] Record test payment
- [ ] View reports
- [ ] Verify all features working

---

**You're ready to start! 🚀**

Open the dashboard and begin enrolling customers!

---

**Quick Start Version:** 1.0.0  
**Last Updated:** March 22, 2026  
**Support:** support@edenservices.ke
