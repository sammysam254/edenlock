# QR Code Provisioning Setup Guide

Complete guide for setting up Android Device Owner provisioning via QR code.

## Overview

The QR code provisioning method allows you to set up Eden as Device Owner without Google Zero-Touch enrollment. This method uses Android's built-in provisioning system available on Android 7.0+.

## Prerequisites

- Android device (Android 7.0+, preferably 10+)
- Factory reset device (no Google accounts added)
- WiFi network credentials
- Generated QR code with provisioning JSON
- Hosted eden.apk file (HTTPS URL)

## Step-by-Step Guide

### 1. Prepare the APK

```bash
# Build release APK
cd android
./gradlew assembleRelease

# Generate SHA-256 checksum
cd provisioning
./generate_checksum.sh ../app/build/outputs/apk/release/eden.apk
```

**Output Example:**
```
✓ Checksum generated successfully!

CHECKSUM: Ry48jtYjTn8H_JlFLmVoMZzLVaQQy-Anz6JGiP7Qrxo

Instructions:
1. Copy the checksum above
2. Replace 'REPLACE_WITH_APK_CHECKSUM' in provisioning.json
...
```

### 2. Host the APK

Upload `eden.apk` to a publicly accessible HTTPS server:

**Option A: AWS S3**
```bash
aws s3 cp eden.apk s3://your-bucket/eden.apk --acl public-read
# URL: https://your-bucket.s3.amazonaws.com/eden.apk
```

**Option B: GitHub Releases**
1. Create a new release in your GitHub repo
2. Upload eden.apk as a release asset
3. Copy the download URL

**Option C: Your Own Server**
```bash
# Ensure HTTPS is enabled
scp eden.apk user@yourserver.com:/var/www/html/
# URL: https://yourserver.com/eden.apk
```

### 3. Configure provisioning.json

Edit `android/provisioning/provisioning.json`:

```json
{
  "android.app.extra.PROVISIONING_DEVICE_ADMIN_COMPONENT_NAME": "ke.edenservices.eden/.EdenDeviceAdminReceiver",
  "android.app.extra.PROVISIONING_DEVICE_ADMIN_SIGNATURE_CHECKSUM": "Ry48jtYjTn8H_JlFLmVoMZzLVaQQy-Anz6JGiP7Qrxo",
  "android.app.extra.PROVISIONING_DEVICE_ADMIN_PACKAGE_DOWNLOAD_LOCATION": "https://yourserver.com/eden.apk",
  "android.app.extra.PROVISIONING_SKIP_ENCRYPTION": false,
  "android.app.extra.PROVISIONING_LEAVE_ALL_SYSTEM_APPS_ENABLED": true,
  "android.app.extra.PROVISIONING_WIFI_SSID": "YourWiFiName",
  "android.app.extra.PROVISIONING_WIFI_PASSWORD": "YourWiFiPassword",
  "android.app.extra.PROVISIONING_WIFI_SECURITY_TYPE": "WPA",
  "android.app.extra.PROVISIONING_ADMIN_EXTRAS_BUNDLE": {
    "supabase_url": "https://abcdefgh.supabase.co",
    "supabase_key": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "wallet_address": "0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb"
  }
}
```

**Important Fields:**
- `PROVISIONING_DEVICE_ADMIN_SIGNATURE_CHECKSUM`: From step 1
- `PROVISIONING_DEVICE_ADMIN_PACKAGE_DOWNLOAD_LOCATION`: From step 2
- `PROVISIONING_WIFI_SSID`: Your WiFi network name (without quotes in SSID)
- `PROVISIONING_WIFI_PASSWORD`: Your WiFi password
- `supabase_url`: Your Supabase project URL
- `supabase_key`: Supabase ANON key (not service role)
- `wallet_address`: Unique wallet address for this device

### 4. Generate QR Code

**Method A: Online Generator (Recommended)**
1. Go to https://www.qr-code-generator.com/
2. Select "Text" type
3. Copy entire `provisioning.json` content
4. Paste into text field
5. Click "Create QR Code"
6. Download as PNG/SVG

**Method B: Command Line**
```bash
# Install qrencode
sudo apt-get install qrencode  # Linux
brew install qrencode          # macOS

# Generate QR code
cat provisioning.json | qrencode -o eden_qr.png -s 10
```

**Method C: Python Script**
```python
import qrcode
import json

with open('provisioning.json', 'r') as f:
    data = json.dumps(json.load(f))

qr = qrcode.QRCode(version=1, box_size=10, border=4)
qr.add_data(data)
qr.make(fit=True)

img = qr.make_image(fill_color="black", back_color="white")
img.save("eden_qr.png")
```

### 5. Provision the Device

**Step-by-Step:**

1. **Factory Reset the Device**
   - Settings > System > Reset > Factory data reset
   - OR hold Power + Volume Down during boot

2. **Start Setup Wizard**
   - Device will boot to "Welcome" screen
   - DO NOT connect to WiFi yet
   - DO NOT add any Google accounts

3. **Trigger QR Scanner**
   - Tap the welcome screen **6 times quickly**
   - QR scanner should appear
   - If not, try tapping different areas or restart

4. **Scan QR Code**
   - Point camera at the QR code you generated
   - Device will read the provisioning data

5. **Automatic Provisioning**
   - Device connects to WiFi
   - Downloads eden.apk from your URL
   - Verifies checksum
   - Installs Eden as Device Owner
   - Applies all restrictions
   - Launches Eden app

6. **Verify Success**
   - Eden app should launch automatically
   - Status should show "✓ Device Protection Active"
   - Try accessing Settings (should be restricted)
   - Try uninstalling Eden (should be blocked)

## Troubleshooting

### QR Scanner Not Appearing

**Solution 1: Try Different Tap Patterns**
- Tap 6 times on the "Welcome" text
- Tap 6 times on the Android logo
- Tap 6 times on empty space

**Solution 2: Check Android Version**
```bash
adb shell getprop ro.build.version.release
# Must be 7.0 or higher
```

**Solution 3: Enable via ADB**
```bash
adb shell settings put global device_provisioning_mobile_data_enabled 1
```

### Checksum Verification Failed

**Cause:** APK checksum doesn't match provisioning.json

**Solution:**
```bash
# Regenerate checksum
./generate_checksum.sh path/to/eden.apk

# Update provisioning.json with new checksum
# Regenerate QR code
```

### APK Download Failed

**Cause:** APK URL not accessible or not HTTPS

**Solution:**
- Verify URL is accessible: `curl -I https://yourserver.com/eden.apk`
- Ensure HTTPS (not HTTP)
- Check firewall/CORS settings
- Try different hosting provider

### WiFi Connection Failed

**Cause:** Wrong WiFi credentials or security type

**Solution:**
- Verify SSID is exact (case-sensitive)
- Check password is correct
- Verify security type: WPA, WPA2, or WEP
- For open networks, omit password field

### Device Owner Not Set

**Cause:** Device has existing accounts or previous Device Owner

**Solution:**
```bash
# Check for accounts
adb shell dumpsys account

# Remove all accounts via Settings
# Then factory reset again

# Check for existing Device Owner
adb shell dpm list-owners
# Should be empty before provisioning
```

## Advanced Configuration

### Multiple Devices with Different Wallets

Create separate provisioning.json files:

```bash
# Device 1
cp provisioning.json provisioning_device1.json
# Edit wallet_address to: 0xAAA...
# Generate QR: qr_device1.png

# Device 2
cp provisioning.json provisioning_device2.json
# Edit wallet_address to: 0xBBB...
# Generate QR: qr_device2.png
```

### Custom WiFi per Location

```json
{
  "android.app.extra.PROVISIONING_WIFI_SSID": "LocationA_WiFi",
  "android.app.extra.PROVISIONING_WIFI_PASSWORD": "password123",
  ...
}
```

### Skip WiFi (Use Mobile Data)

```json
{
  "android.app.extra.PROVISIONING_USE_MOBILE_DATA": true,
  // Remove WIFI_SSID and WIFI_PASSWORD
  ...
}
```

## Security Best Practices

1. **Protect QR Codes**
   - Don't share QR codes publicly
   - Each QR contains WiFi password and Supabase keys
   - Generate unique QR per device if possible

2. **Use HTTPS Only**
   - Never use HTTP for APK download
   - Ensures APK integrity during download

3. **Rotate Keys**
   - Regenerate Supabase keys periodically
   - Update provisioning.json and QR codes

4. **Verify Checksum**
   - Always verify checksum after building APK
   - Mismatch will cause provisioning failure

## Testing Checklist

- [ ] APK builds successfully
- [ ] Checksum generated correctly
- [ ] APK hosted on HTTPS URL
- [ ] provisioning.json updated with correct values
- [ ] QR code generated and readable
- [ ] Device factory reset
- [ ] QR scanner appears (6 taps)
- [ ] QR code scans successfully
- [ ] WiFi connects automatically
- [ ] APK downloads and installs
- [ ] Eden launches as Device Owner
- [ ] Restrictions applied (Settings blocked, etc.)
- [ ] Supabase connection works
- [ ] Device appears in Supabase database

## Reference

- [Android Enterprise Provisioning](https://developers.google.com/android/management/provision-device)
- [QR Code Provisioning](https://developers.google.com/android/management/provision-device#qr_code_method)
- [Device Owner Mode](https://developer.android.com/work/dpc/dedicated-devices/device-owner)
