# 📱 Administrator Dashboard - User Guide

Complete guide for field agents using the Eden Administrator Dashboard.

---

## 🌐 Access

**URL:** `http://localhost:3000/admin` (development)  
**Production:** `https://your-domain.com/admin`

**Login:** Use credentials provided by Super Admin

---

## 📊 Dashboard Sections

### 1. Dashboard Home

**Overview of your portfolio:**
- Total Devices enrolled
- Active Loans count
- Total Collected (KES)
- Overdue Devices count

**Recent Activity:**
- Last 5 device enrollments
- Last 5 payment transactions

**Use Case:** Quick overview of your daily operations

---

### 2. Customers Section

#### View All Customers
- Complete list of all customers you've enrolled
- Customer code, name, phone, national ID
- Active/Inactive status
- Creation date

#### Add New Customer

**Required Fields:**
- Full Name *
- Phone Number * (format: +254712345678)

**Optional Fields:**
- Email
- National ID
- Address

**Process:**
1. Click "Add New Customer"
2. Fill in customer details
3. Click "Create Customer"
4. System generates customer code (e.g., CUST001234)
5. Customer appears in list

**Example:**
```
Full Name: Jane Doe
Phone: +254712345678
Email: jane@example.com
National ID: 12345678
Address: Nairobi, Kenya
```

---

### 3. Devices Section

#### View All Devices
- Device code, IMEI, model
- Loan balance, daily payment
- Status (enrolled, active, locked, paid_off)
- Lock status (Locked/Unlocked)

#### Enroll New Device

**Step 1: Select Customer**
- Choose from dropdown of existing customers
- Shows customer code and name

**Step 2: Enter Device Details**
- Device IMEI * (15 digits)
- Device Model * (e.g., Samsung Galaxy A14)

**Step 3: Configure Loan Terms**
- Device Price (KES) *
- Down Payment (KES) *
- Daily Payment (KES) *
- Payment Frequency * (daily/weekly/monthly)
- Loan Total (auto-calculated)

**Step 4: Generate QR Code**
- Click "Enroll Device & Generate QR Code"
- System creates device record
- System generates device code (e.g., DEV001234)
- QR code data displayed

**Step 5: Provision Device**
- Copy QR code JSON
- Generate QR code using online tool
- Factory reset device
- Tap welcome screen 6 times
- Scan QR code
- Device provisions automatically

**Example:**
```
Customer: CUST001234 - Jane Doe
IMEI: 123456789012345
Model: Samsung Galaxy A14
Device Price: KES 15,000
Down Payment: KES 3,000
Loan Total: KES 12,000 (auto-calculated)
Daily Payment: KES 100
Payment Frequency: Daily
```

**QR Code Generation:**
1. Copy the JSON payload displayed
2. Go to https://www.qr-code-generator.com/
3. Select "Text" type
4. Paste JSON payload
5. Generate and download QR code
6. Print or display on tablet for scanning

---

### 4. Payments Section

#### View Payment History
- Transaction code, amount, method
- M-Pesa receipt (if applicable)
- Status (completed/pending)
- Processing date

#### Record Payment

**Step 1: Select Device**
- Choose from dropdown (shows only devices with balance > 0)
- Shows device code and current balance

**Step 2: Enter Payment Details**
- Amount (KES) *
- Payment Method * (M-Pesa, Cash, Bank, Blockchain)

**Step 3: Payment Method Specific Fields**

**For M-Pesa:**
- M-Pesa Receipt Number (e.g., QA12BC3DEF)
- M-Pesa Phone Number (e.g., +254712345678)

**For Cash:**
- Payment Reference (optional)
- Notes (optional)

**For Bank Transfer:**
- Payment Reference (bank reference number)
- Notes (optional)

**Step 4: Process Payment**
- Click "Process Payment"
- System generates transaction code (e.g., TXN20240322001234)
- System updates device loan balance
- System logs transaction
- Device auto-unlocks if balance reaches 0

**Example - M-Pesa Payment:**
```
Device: DEV001234 - Balance: KES 5,000
Amount: KES 100
Payment Method: M-Pesa
M-Pesa Receipt: QA12BC3DEF
M-Pesa Phone: +254712345678
Notes: Daily payment from customer
```

**Example - Cash Payment:**
```
Device: DEV001234 - Balance: KES 4,900
Amount: KES 500
Payment Method: Cash
Payment Reference: CASH-20240322-001
Notes: Customer paid at office
```

---

### 5. Reports Section

#### Daily Collection Summary
- Total collected today (KES)
- Number of payments today
- Real-time updates

#### Monthly Collection Summary
- Total collected this month (KES)
- Number of payments this month
- Month-to-date tracking

#### Collection Rate
- Percentage of loans collected
- Total collected vs total loans
- Performance indicator

#### Overdue Devices Report
- List of devices with overdue payments
- Days overdue
- Last payment date
- Outstanding balance

#### Payment Method Breakdown
- M-Pesa transactions and total
- Cash transactions and total
- Bank transfer transactions and total
- Blockchain transactions and total

**Use Case:** End-of-day reporting, monthly summaries, identifying overdue accounts

---

## 🔄 Common Workflows

### Workflow 1: New Customer & Device Enrollment

**Time Required:** 5-10 minutes

1. **Create Customer**
   - Go to Customers section
   - Click "Add New Customer"
   - Enter customer details
   - Submit form

2. **Enroll Device**
   - Go to Devices section
   - Click "Enroll New Device"
   - Select the customer you just created
   - Enter device IMEI and model
   - Configure loan terms
   - Submit form

3. **Generate QR Code**
   - Copy QR code JSON from popup
   - Generate QR code using online tool
   - Save or print QR code

4. **Provision Device**
   - Factory reset device
   - Tap welcome screen 6 times
   - Scan QR code
   - Wait for provisioning to complete

5. **Verify**
   - Device should show in "Locked" status
   - Customer should see device in their account

### Workflow 2: Daily Payment Collection

**Time Required:** 2-3 minutes per payment

1. **Receive Payment**
   - Customer sends M-Pesa or pays cash
   - Note M-Pesa receipt number if applicable

2. **Record Payment**
   - Go to Payments section
   - Click "Record Payment"
   - Select device from dropdown
   - Enter payment amount
   - Select payment method
   - Enter M-Pesa receipt (if M-Pesa)
   - Add notes if needed
   - Submit form

3. **Verify**
   - Check payment appears in payment history
   - Check device balance updated
   - Device unlocks automatically if balance = 0

### Workflow 3: End-of-Day Reporting

**Time Required:** 5 minutes

1. **Go to Reports Section**

2. **Review Daily Collection**
   - Check total collected today
   - Verify number of payments

3. **Check Overdue Devices**
   - Review overdue devices list
   - Note devices requiring follow-up
   - Plan collection activities

4. **Review Payment Methods**
   - Check M-Pesa vs Cash breakdown
   - Verify all receipts recorded

---

## 💡 Tips & Best Practices

### Customer Enrollment
- ✅ Always verify phone number format (+254...)
- ✅ Record national ID for identity verification
- ✅ Get complete address for follow-up
- ✅ Verify customer information before submission

### Device Enrollment
- ✅ Double-check IMEI number (15 digits)
- ✅ Verify device model matches physical device
- ✅ Calculate daily payment based on customer's ability to pay
- ✅ Explain loan terms to customer before enrollment
- ✅ Test QR code before giving device to customer

### Payment Processing
- ✅ Always get M-Pesa receipt number for M-Pesa payments
- ✅ Verify payment amount matches customer's claim
- ✅ Record payment immediately to avoid disputes
- ✅ Add notes for any special circumstances
- ✅ Give customer confirmation after recording

### Daily Operations
- ✅ Check dashboard home every morning
- ✅ Review overdue devices daily
- ✅ Follow up with overdue customers
- ✅ Record all payments same day
- ✅ Generate end-of-day report

---

## ⚠️ Troubleshooting

### Issue: Customer not appearing in dropdown
**Solution:** Refresh the page or go back to Customers section to verify customer was created

### Issue: Device not locking after enrollment
**Solution:** 
1. Check device has internet connection
2. Wait 15 minutes for background sync
3. Manually refresh status on device
4. Contact technical support if issue persists

### Issue: Payment not updating device balance
**Solution:**
1. Verify payment was submitted successfully
2. Check payment appears in payment history
3. Refresh devices list
4. Contact technical support if balance not updated

### Issue: QR code not working during provisioning
**Solution:**
1. Verify device is factory reset
2. Ensure QR code is generated correctly
3. Check internet connection during provisioning
4. Try generating new QR code
5. Verify APK URL is accessible

### Issue: Cannot see some devices
**Solution:**
1. Verify you're logged in with correct account
2. Check device was enrolled by you
3. Refresh the page
4. Contact Super Admin if device should be visible

---

## 📞 Support

### For Technical Issues
- Check troubleshooting section above
- Contact Super Admin
- Email: support@edenservices.ke
- Phone: +254700000000

### For Business Questions
- Contact your regional manager
- Refer to training materials
- Attend weekly team meetings

---

## 🔐 Security Reminders

- ✅ Never share your login credentials
- ✅ Always log out when leaving computer
- ✅ Verify customer identity before enrollment
- ✅ Keep M-Pesa receipts for audit
- ✅ Report suspicious activity immediately
- ✅ Follow data protection guidelines

---

## 📱 Mobile Access

The Administrator Dashboard is mobile-responsive and can be accessed from:
- Desktop computers
- Laptops
- Tablets
- Smartphones

**Recommended:** Use tablet or laptop for best experience

---

**Dashboard Version:** 1.0.0  
**Last Updated:** March 22, 2026  
**Support:** support@edenservices.ke
