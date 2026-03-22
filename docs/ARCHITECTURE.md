# Eden System Architecture

Complete technical architecture documentation for the Eden "Lipa Polepole" system.

## System Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                         Eden Ecosystem                          │
└─────────────────────────────────────────────────────────────────┘

┌──────────────────┐         ┌──────────────────┐         ┌──────────────────┐
│  Android Device  │◄───────►│   Supabase DB    │◄───────►│  Python Backend  │
│   (Device Owner) │  HTTPS  │   (PostgreSQL)   │  HTTPS  │  (Web3 Listener) │
└──────────────────┘         └──────────────────┘         └──────────────────┘
        │                             │                             │
        │                             │                             │
        ▼                             ▼                             ▼
┌──────────────────┐         ┌──────────────────┐         ┌──────────────────┐
│  Lock/Unlock UI  │         │  Device Records  │         │  Smart Contract  │
│  Kiosk Mode      │         │  Payment Logs    │         │  (Polygon/BSC)   │
│  Restrictions    │         │  Sync Logs       │         │  PaymentReceived │
└──────────────────┘         └──────────────────┘         └──────────────────┘
```

## Component Architecture

### 1. Android DPC (Device Policy Controller)

**Technology Stack:**
- Language: Kotlin
- Min SDK: 28 (Android 9.0)
- Target SDK: 34 (Android 14)
- Architecture: MVVM-lite

**Core Components:**

#### EdenDeviceAdminReceiver
- Extends `DeviceAdminReceiver`
- Handles provisioning callbacks
- Applies hardened restrictions
- Manages Device Owner lifecycle

**Key Methods:**
```kotlin
onProfileProvisioningComplete() // Initial setup
onEnabled()                     // Admin enabled
onDisabled()                    // Admin disabled (retirement)
```

#### DeviceEnforcementManager
- Singleton object
- Applies all security restrictions
- Verifies enforcement status

**Restrictions Applied:**
- `DISALLOW_FACTORY_RESET` - Prevents factory reset
- `DISALLOW_SAFE_BOOT` - Blocks safe mode
- `DISALLOW_DEBUGGING_FEATURES` - Disables ADB/Developer options
- `setUninstallBlocked()` - Prevents app uninstallation
- `setLockTaskPackages()` - Enables kiosk mode

#### LockoutActivity
- Full-screen kiosk mode
- Uses `startLockTask()` for pinning
- Displays payment information
- Polls Supabase every 30 seconds
- Auto-unlocks when payment confirmed

#### SupabaseSyncWorker
- Background WorkManager task
- Runs every 15 minutes
- Syncs lock status from Supabase
- Triggers lockout if needed

#### DeviceRetirementManager
- Handles loan completion
- Removes all restrictions
- Clears Device Owner status
- Triggers self-uninstallation

### 2. Supabase Database

**Technology Stack:**
- Database: PostgreSQL 15+
- Auth: Row Level Security (RLS)
- API: REST + Realtime (optional)

**Schema Design:**

#### devices table
```sql
id              UUID PRIMARY KEY
imei            TEXT UNIQUE NOT NULL
wallet_address  TEXT NOT NULL
loan_total      DECIMAL(10,2)
loan_balance    DECIMAL(10,2)
is_locked       BOOLEAN DEFAULT true
last_payment_*  Tracking fields
timestamps      created/updated/retired
```

**Indexes:**
- `idx_devices_imei` - Fast device lookup
- `idx_devices_wallet` - Payment matching
- `idx_devices_locked` - Lock status queries

#### payment_transactions table
```sql
id                  UUID PRIMARY KEY
device_id           UUID REFERENCES devices
wallet_address      TEXT
amount              DECIMAL(10,2)
blockchain_timestamp BIGINT
processed_at        TIMESTAMP
```

**Triggers:**
- `update_updated_at_column` - Auto-update timestamps
- `auto_lock_on_balance` - Auto-lock when balance > 0

**RLS Policies:**
- Devices can only read their own data
- Service role has full access
- Anon key restricted to SELECT on own device

### 3. Python Web3 Listener

**Technology Stack:**
- Language: Python 3.11+
- Framework: Web3.py
- Hosting: Render (Background Worker)
- Database Client: Supabase Python SDK

**Architecture:**

```python
EdenWeb3Listener
├── __init__()           # Initialize Web3 + Supabase
├── listen()             # Main event loop
├── process_payment()    # Handle PaymentReceived events
└── _log_payment()       # Record transaction
```

**Event Flow:**
1. Poll blockchain every 15 seconds
2. Scan for `PaymentReceived` events
3. Extract wallet address and amount
4. Query Supabase for matching device
5. Calculate new loan balance
6. Update device record
7. Log transaction

**Error Handling:**
- Automatic retry on connection failures
- Exponential backoff for RPC errors
- Transaction logging for audit trail

### 4. Smart Contract

**Technology Stack:**
- Language: Solidity 0.8.20+
- Networks: Polygon, BSC, Ethereum
- Standard: Custom payment contract

**Event Signature:**
```solidity
event PaymentReceived(
    address indexed wallet,  // Device wallet
    uint256 amount,          // Payment in Wei
    uint256 timestamp        // Block timestamp
)
```

**Functions:**
- `makePayment(address deviceWallet)` - Accept payment
- `withdraw()` - Owner withdraws funds
- `getTotalPaid(address)` - Query payment history

## Data Flow

### Payment Flow

```
1. User sends crypto to device wallet
   └─> Smart Contract.makePayment()
       └─> Emits PaymentReceived event

2. Python Listener detects event
   └─> Queries Supabase for device
       └─> Calculates new balance
           └─> Updates device record

3. Android WorkManager syncs
   └─> Fetches updated device status
       └─> Checks is_locked flag
           └─> Unlocks if balance = 0
```

### Lock Flow

```
1. Device boots / WorkManager runs
   └─> SupabaseSyncWorker.doWork()
       └─> Fetches device status
           └─> Checks is_locked flag

2. If is_locked = true
   └─> Launch LockoutActivity
       └─> Enter kiosk mode (startLockTask)
           └─> Display payment screen
               └─> Poll status every 30s

3. If is_locked = false
   └─> Exit kiosk mode
       └─> DeviceRetirementManager.retireDevice()
           └─> Remove restrictions
               └─> Clear Device Owner
                   └─> Trigger uninstall
```

### Provisioning Flow

```
1. Factory reset device
   └─> Tap welcome screen 6 times
       └─> Scan QR code

2. Android reads provisioning.json
   └─> Connects to WiFi
       └─> Downloads eden.apk
           └─> Verifies SHA-256 checksum

3. Installs as Device Owner
   └─> Calls onProfileProvisioningComplete()
       └─> Extracts admin extras (Supabase creds)
           └─> Applies hardened restrictions
               └─> Launches MainActivity
```

## Security Architecture

### Device-Level Security

**Bypass Prevention:**
- Factory reset disabled via `DISALLOW_FACTORY_RESET`
- Safe boot disabled via `DISALLOW_SAFE_BOOT`
- ADB disabled via `DISALLOW_DEBUGGING_FEATURES`
- Uninstall blocked via `setUninstallBlocked()`
- Kiosk mode prevents app switching

**Attack Vectors Mitigated:**
- ✅ Factory reset → Blocked by Device Owner
- ✅ Safe mode boot → Disabled
- ✅ ADB commands → Developer options blocked
- ✅ App uninstall → Uninstall protection
- ✅ Task switching → Kiosk mode lock
- ✅ Settings access → Restricted by DPM

### Network Security

**HTTPS Everywhere:**
- APK download: HTTPS only
- Supabase API: HTTPS
- Blockchain RPC: HTTPS/WSS

**API Security:**
- Android uses anon key (read-only)
- Backend uses service role key (full access)
- RLS policies enforce data isolation

### Data Security

**Sensitive Data Storage:**
- Supabase credentials in SharedPreferences (MODE_PRIVATE)
- No hardcoded keys in source code
- ProGuard obfuscation in release builds

**Database Security:**
- Row Level Security (RLS) enabled
- Devices can only access own data
- Service role for backend operations

## Scalability

### Horizontal Scaling

**Backend:**
- Stateless Python listener
- Can run multiple instances
- Each monitors same contract
- Idempotent payment processing

**Database:**
- Supabase auto-scales
- Connection pooling
- Read replicas for high load

### Performance Optimization

**Android:**
- WorkManager for efficient background sync
- Coroutines for non-blocking I/O
- Minimal battery impact

**Backend:**
- Event-based polling (not continuous)
- Batch processing for multiple events
- Efficient RPC usage

**Database:**
- Indexed queries
- Materialized views for analytics
- Automatic vacuuming

## Monitoring & Observability

### Logging

**Android:**
```kotlin
Log.i(TAG, "Device locked - Balance: $balance")
Log.e(TAG, "Sync failed", exception)
```

**Backend:**
```python
logger.info("Payment detected: {wallet} paid {amount}")
logger.error("RPC connection failed", exc_info=True)
```

**Database:**
- `device_sync_logs` table
- `payment_transactions` table
- Supabase dashboard metrics

### Metrics

**Key Metrics:**
- Payment processing latency
- Device sync success rate
- Lock/unlock events
- Backend uptime
- RPC response time

### Alerting

**Critical Alerts:**
- Backend listener down
- RPC connection failures
- Database connection errors
- Payment processing failures

## Disaster Recovery

### Backup Strategy

**Database:**
- Supabase automatic daily backups
- Point-in-time recovery
- Export to S3 for long-term storage

**Code:**
- Git version control
- Tagged releases
- APK archive

### Recovery Procedures

**Backend Failure:**
1. Check Render logs
2. Verify RPC endpoint
3. Restart worker
4. Replay missed blocks

**Database Corruption:**
1. Restore from backup
2. Replay transactions from blockchain
3. Verify device states

**Device Issues:**
1. Remote unlock via Supabase
2. Manual Device Owner removal (if accessible)
3. Factory reset as last resort

## Compliance & Legal

### Data Privacy

- GDPR compliant (if operating in EU)
- Minimal PII collection (IMEI only)
- User consent during provisioning
- Right to data deletion

### Financial Regulations

- Not a financial institution
- Device locking service only
- Payments handled by blockchain
- Transparent terms of service

## Future Enhancements

### Planned Features

1. **Realtime Sync**
   - Use Supabase Realtime instead of polling
   - Instant lock/unlock updates

2. **Multi-Currency Support**
   - Accept multiple tokens (USDC, USDT, DAI)
   - Dynamic exchange rates

3. **Payment Plans**
   - Flexible payment schedules
   - Grace periods
   - Partial payments

4. **Admin Dashboard**
   - Web-based device management
   - Analytics and reporting
   - Bulk operations

5. **Biometric Unlock**
   - Temporary unlock with fingerprint
   - Emergency access codes

### Technical Debt

- Add comprehensive unit tests
- Implement CI/CD pipeline
- Add crash reporting (Firebase Crashlytics)
- Implement analytics (Mixpanel/Amplitude)
- Add remote config for feature flags

## Conclusion

The Eden system provides a robust, secure, and scalable solution for device-locking enforcement using blockchain payments. The architecture ensures bypass prevention through Device Owner mode while maintaining flexibility for legitimate unlocking via verified payments.
