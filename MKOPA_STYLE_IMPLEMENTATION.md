# 🏢 Eden M-Kopa Style Implementation Guide

Complete implementation of M-Kopa-style device financing system with multi-tenant dashboards.

## 🎯 System Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    Eden M-Kopa System                       │
└─────────────────────────────────────────────────────────────┘

┌──────────────────┐         ┌──────────────────┐
│  Super Admin     │────────►│  Administrators  │
│  Dashboard       │ Creates │  Dashboard       │
└──────────────────┘         └────────┬─────────┘
                                      │
                                      │ Enrolls
                                      ▼
                             ┌──────────────────┐
                             │    Customers     │
                             │   + Devices      │
                             └────────┬─────────┘
                                      │
                                      │ Uses
                                      ▼
                             ┌──────────────────┐
                             │  Android Device  │
                             │  (Locked/Unlocked)│
                             └──────────────────┘
```

## 📊 Database Schema (Enhanced)

### User Hierarchy

1. **Super Admins** - System owners
   - Create/manage administrators
   - View all system data
   - System configuration

2. **Administrators** - Field agents
   - Enroll customers
   - Activate devices
   - Process payments
   - View their portfolio

3. **Customers** - Device buyers
   - Own devices
   - Make payments
   - View payment history

### Key Tables

```sql
super_admins
├── id
├── email
├── full_name
└── is_active

administrators
├── id
├── email
├── full_name
├── phone
├── created_by (super_admin_id)
├── region
├── branch
└── is_active

customers
├── id
├── customer_code (auto: CUST001234)
├── full_name
├── phone
├── national_id
├── enrolled_by (administrator_id)
└── is_active

devices
├── id
├── device_code (auto: DEV001234)
├── imei
├── customer_id
├── enrolled_by (administrator_id)
├── device_price
├── down_payment
├── loan_total
├── loan_balance
├── daily_payment
├── is_locked
└── status

payment_transactions
├── id
├── transaction_code (auto: TXN20240115001234)
├── device_id
├── customer_id
├── amount
├── payment_method (mpesa, cash, bank)
├── mpesa_receipt
├── status
└── processed_by (administrator_id)
```

## 🔄 Complete Workflow

### 1. Super Admin Creates Administrator

**Super Admin Dashboard:**
```
1. Login to Super Admin Dashboard
2. Click "Create New Administrator"
3. Fill form:
   - Full Name
   - Email
   - Phone
   - Region
   - Branch
4. System creates:
   - Auth user account
   - Administrator record
   - Sends login credentials via email
```

### 2. Administrator Enrolls Customer & Device

**Administrator Dashboard:**
```
Step 1: Create Customer
- Full Name: John Doe
- Phone: +254712345678
- National ID: 12345678
- Address: Nairobi, Kenya

Step 2: Enroll Device
- Select Customer: John Doe
- Device Model: Samsung Galaxy A14
- Device Price: KES 15,000
- Down Payment: KES 3,000
- Loan Amount: KES 12,000
- Daily Payment: KES 100
- Payment Period: 120 days

Step 3: Generate QR Code
- System generates provisioning QR code
- QR contains:
  - Supabase credentials
  - Device ID
  - Customer ID
  - Loan details
```

### 3. Device Activation

**Field Agent Process:**
```
1. Install Eden APK on device
2. Factory reset device
3. Tap welcome screen 6 times
4. Scan generated QR code
5. Device provisions automatically:
   - Sets Device Owner
   - Applies restrictions
   - Links to customer account
   - Starts in LOCKED state
```

### 4. Payment Processing

**Administrator Dashboard:**
```
Option A: M-Pesa Payment
1. Customer sends M-Pesa to business number
2. Administrator receives M-Pesa notification
3. Administrator enters in dashboard:
   - Customer/Device
   - Amount
   - M-Pesa Receipt Number
   - M-Pesa Phone
4. System updates:
   - Device loan_balance
   - Payment transaction log
   - Device unlock if balance = 0

Option B: Cash Payment
1. Customer pays cash to agent
2. Administrator enters payment
3. System updates device

Option C: Bank Transfer
1. Customer transfers to bank
2. Administrator verifies and enters
3. System updates device
```

### 5. Device Lock/Unlock

**Automatic Process:**
```
Device Sync (Every 15 minutes):
1. Android WorkManager runs
2. Fetches device status from Supabase
3. Checks loan_balance

If loan_balance > 0:
   - is_locked = true
   - Launch LockoutActivity
   - Enter kiosk mode
   - Show payment screen

If loan_balance = 0:
   - is_locked = false
   - Exit kiosk mode
   - Retire device
   - Remove restrictions
   - Uninstall app
```

## 🖥️ Dashboard Features

### Super Admin Dashboard

**URL:** `/super-admin`

**Features:**
- ✅ Create/manage administrators
- ✅ View all system statistics
- ✅ Activate/deactivate administrators
- ✅ View all devices and customers
- ✅ System-wide reports
- ✅ Payment analytics

**Key Metrics:**
- Total Administrators
- Total Customers
- Total Devices
- Total Revenue
- Outstanding Loans
- Payment Collection Rate

### Administrator Dashboard

**URL:** `/admin`

**Features:**
- ✅ Enroll new customers
- ✅ Activate devices
- ✅ Generate QR codes
- ✅ Process payments
- ✅ View portfolio
- ✅ Customer management
- ✅ Payment history

**Key Sections:**

1. **Dashboard Home**
   - My Statistics
   - Recent Enrollments
   - Pending Payments
   - Overdue Devices

2. **Customers**
   - List all customers
   - Add new customer
   - View customer details
   - Customer payment history

3. **Devices**
   - List all devices
   - Enroll new device
   - Generate QR code
   - View device status
   - Lock/unlock manually

4. **Payments**
   - Record payment
   - Payment history
   - M-Pesa integration
   - Generate receipts

5. **Reports**
   - Daily collection
   - Monthly summary
   - Overdue report
   - Commission report

## 📱 Android App Flow

### First Installation (Before Enrollment)

```
1. User installs Eden APK
2. App shows "Device Not Enrolled" screen
3. Instructions to contact agent
4. Agent generates QR code
5. User factory resets device
6. Scans QR code during setup
7. Device provisions as Device Owner
```

### After Enrollment

```
If Loan Balance > 0:
   ┌─────────────────────┐
   │  DEVICE LOCKED      │
   │                     │
   │  Outstanding:       │
   │  KES 5,000          │
   │                     │
   │  Pay to:            │
   │  Paybill: 123456    │
   │  Account: DEV001234 │
   │                     │
   │  [Refresh Status]   │
   └─────────────────────┘
   
   - Cannot exit app
   - Home button disabled
   - Back button disabled
   - Settings blocked

If Loan Balance = 0:
   ┌─────────────────────┐
   │  CONGRATULATIONS!   │
   │                     │
   │  Device Paid Off    │
   │                     │
   │  Unlocking device...│
   └─────────────────────┘
   
   - Restrictions removed
   - Device Owner cleared
   - App uninstalls
   - Device fully unlocked
```

## 🔐 Security Features

### Device Level
- ✅ Device Owner enforcement
- ✅ Factory reset disabled
- ✅ Safe boot disabled
- ✅ ADB disabled
- ✅ Uninstall blocked
- ✅ Kiosk mode

### Dashboard Level
- ✅ Role-based access control
- ✅ Supabase Auth integration
- ✅ Row Level Security (RLS)
- ✅ Activity logging
- ✅ IP tracking

### Payment Security
- ✅ Transaction codes
- ✅ M-Pesa verification
- ✅ Duplicate prevention
- ✅ Audit trail

## 📊 Supabase Configuration

### 1. Run Database Schema

```sql
-- In Supabase SQL Editor
-- Copy and paste database/schema.sql
-- Execute
```

### 2. Set Up Row Level Security

```sql
-- In Supabase SQL Editor
-- Copy and paste database/rls_policies.sql
-- Execute
```

### 3. Create First Super Admin

```sql
-- Manually create first super admin
INSERT INTO super_admins (email, full_name, phone, is_active)
VALUES ('admin@edenservices.ke', 'System Administrator', '+254700000000', true);
```

### 4. Configure Auth

```
Supabase Dashboard > Authentication > Settings:
- Enable Email Auth
- Disable Email Confirmations (for testing)
- Set Site URL
- Configure Email Templates
```

## 🚀 Deployment Steps

### 1. Deploy Database

```bash
# Run in Supabase SQL Editor
cat database/schema.sql
# Copy and execute

cat database/rls_policies.sql
# Copy and execute
```

### 2. Deploy Dashboards

```bash
cd dashboard

# Install dependencies
npm install

# Create .env.local
cp .env.local.example .env.local
# Edit with your Supabase credentials

# Run development
npm run dev

# Build for production
npm run build

# Deploy to Vercel
vercel deploy
```

### 3. Build Android App

```bash
cd android

# Update provisioning.json template
# Build APK
./gradlew assembleRelease

# Upload APK to server
# Update NEXT_PUBLIC_APK_DOWNLOAD_URL in dashboard
```

### 4. Configure M-Pesa (Optional)

```
1. Register M-Pesa Paybill/Till Number
2. Set up M-Pesa API credentials
3. Configure webhook for automatic payment detection
4. Update dashboard with M-Pesa integration
```

## 📈 Usage Statistics

### Administrator Performance Metrics

```sql
-- Devices enrolled by administrator
SELECT 
    a.full_name,
    COUNT(d.id) as total_devices,
    SUM(d.device_price) as total_value,
    SUM(d.total_paid) as collected
FROM administrators a
LEFT JOIN devices d ON a.id = d.enrolled_by
GROUP BY a.id;
```

### Payment Collection Rate

```sql
-- Overall collection rate
SELECT 
    SUM(loan_total) as total_loans,
    SUM(total_paid) as total_collected,
    ROUND((SUM(total_paid) / SUM(loan_total) * 100), 2) as collection_rate
FROM devices;
```

### Overdue Devices

```sql
-- Devices with overdue payments
SELECT 
    d.device_code,
    c.full_name as customer,
    d.loan_balance,
    d.days_overdue,
    d.next_payment_due
FROM devices d
JOIN customers c ON d.customer_id = c.id
WHERE d.days_overdue > 0
ORDER BY d.days_overdue DESC;
```

## 🎓 Training Guide

### For Super Admins

1. **System Setup**
   - Configure Supabase
   - Create first administrator
   - Set up payment methods

2. **Administrator Management**
   - Create administrator accounts
   - Assign regions/branches
   - Monitor performance
   - Deactivate if needed

3. **Reporting**
   - View system-wide metrics
   - Export reports
   - Analyze trends

### For Administrators

1. **Customer Enrollment**
   - Collect customer information
   - Verify national ID
   - Create customer account

2. **Device Activation**
   - Select customer
   - Enter device details
   - Set payment terms
   - Generate QR code
   - Provision device

3. **Payment Processing**
   - Receive payment
   - Enter in dashboard
   - Verify M-Pesa receipt
   - Confirm device unlock

4. **Customer Support**
   - Check device status
   - View payment history
   - Manual unlock (if authorized)
   - Handle disputes

## 🔧 Customization

### Payment Terms

Edit in Administrator Dashboard:
- Daily payment amount
- Payment frequency (daily/weekly/monthly)
- Grace period days
- Down payment percentage

### Device Models

Add supported devices:
```sql
INSERT INTO device_models (name, price, category)
VALUES ('Samsung Galaxy A14', 15000, 'smartphone');
```

### Regions & Branches

Configure in Super Admin Dashboard:
- Add regions
- Add branches
- Assign administrators

## 📞 Support

### For Technical Issues
- Check Supabase logs
- Review Android logcat
- Check dashboard console

### For Business Issues
- Contact Super Admin
- Review payment records
- Check customer details

---

**This implementation provides a complete M-Kopa-style device financing system with:**
- ✅ Multi-tenant dashboards
- ✅ Role-based access
- ✅ Device enrollment
- ✅ Payment processing
- ✅ Automatic lock/unlock
- ✅ Complete audit trail

**Ready for production deployment!**
