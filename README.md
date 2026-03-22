# Eden - Lipa Polepole Device Locking System

A production-ready Android device-locking system for pay-as-you-go compliance using Web3 blockchain payments.

## Architecture Overview

```
┌─────────────────┐      ┌──────────────────┐      ┌─────────────────┐
│  Android DPC    │◄────►│   Supabase DB    │◄────►│   Blockchain    │
│  (Device Owner) │      │  (PostgreSQL)    │      │    Listener     │
└─────────────────┘      └──────────────────┘      └─────────────────┘
                                                            │
                                                            ▼
                                                    ┌─────────────────┐
                                                    │  Eden Custom    │
                                                    │  Blockchain     │
                                                    └─────────────────┘
```

## Project Structure

```
eden/
├── android/                    # Android DPC Application
│   ├── app/
│   │   ├── src/main/
│   │   │   ├── java/ke/edenservices/eden/
│   │   │   │   ├── EdenDeviceAdminReceiver.kt
│   │   │   │   ├── MainActivity.kt
│   │   │   │   ├── LockoutActivity.kt
│   │   │   │   ├── DeviceEnforcementManager.kt
│   │   │   │   ├── SupabaseSyncWorker.kt
│   │   │   │   └── DeviceRetirementManager.kt
│   │   │   └── AndroidManifest.xml
│   │   └── build.gradle
│   └── provisioning/
│       ├── provisioning.json
│       └── generate_checksum.sh
├── backend/                    # Blockchain Listener
│   ├── eden_blockchain_listener.py
│   ├── web3_listener.py (legacy)
│   ├── requirements.txt
│   └── render.yaml
├── blockchain/                 # Custom Blockchain
│   ├── eden_blockchain.py
│   ├── eden_blockchain_server.py
│   ├── test_blockchain.py
│   ├── requirements.txt
│   └── render.yaml
├── database/                   # Supabase Configuration
│   ├── schema.sql
│   └── rls_policies.sql
└── docs/
    ├── DEPLOYMENT.md
    └── QR_SETUP.md
```

## Quick Start

### 1. Database Setup (Supabase)
```bash
# Run SQL scripts in Supabase SQL Editor
psql -h [your-supabase-host] -f database/schema.sql
psql -h [your-supabase-host] -f database/rls_policies.sql
```

### 2. Blockchain Deployment (Render)
```bash
# Deploy blockchain server
cd blockchain
# Deploy to Render using render.yaml

# Deploy listener
cd backend
# Deploy to Render using render.yaml
```

### 3. Android Build & Provisioning
```bash
cd android
./gradlew assembleRelease
cd provisioning
./generate_checksum.sh ../app/build/outputs/apk/release/eden.apk
# Use output to generate QR code
```

## Security Features

- ✅ Device Owner enforcement (no user bypass)
- ✅ Factory reset disabled
- ✅ Safe boot disabled
- ✅ ADB/Developer options blocked
- ✅ Uninstall protection
- ✅ Kiosk mode lockout
- ✅ Blockchain payment verification
- ✅ Automatic device retirement

## License

Proprietary - Eden Services KE
