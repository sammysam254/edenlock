#!/bin/bash

# Generate SHA-256 checksum for Android provisioning QR code
# Usage: ./generate_checksum.sh path/to/eden.apk

if [ -z "$1" ]; then
    echo "Usage: ./generate_checksum.sh <path-to-apk>"
    exit 1
fi

APK_PATH="$1"

if [ ! -f "$APK_PATH" ]; then
    echo "Error: APK file not found at $APK_PATH"
    exit 1
fi

echo "Generating SHA-256 checksum for: $APK_PATH"
echo ""

# Generate SHA-256 hash and convert to Base64 URL-safe format
CHECKSUM=$(openssl dgst -binary -sha256 "$APK_PATH" | openssl base64 | tr '+/' '-_' | tr -d '=')

echo "✓ Checksum generated successfully!"
echo ""
echo "CHECKSUM: $CHECKSUM"
echo ""
echo "Instructions:"
echo "1. Copy the checksum above"
echo "2. Replace 'REPLACE_WITH_APK_CHECKSUM' in provisioning.json"
echo "3. Update PROVISIONING_DEVICE_ADMIN_PACKAGE_DOWNLOAD_LOCATION with your APK URL"
echo "4. Update PROVISIONING_ADMIN_EXTRAS_BUNDLE with your Supabase credentials"
echo "5. Generate QR code from the JSON at: https://qr-code-generator.com"
echo ""
echo "QR Code Setup:"
echo "- Factory reset the Android device"
echo "- Tap the welcome screen 6 times"
echo "- Scan the generated QR code"
echo "- Device will download and provision Eden automatically"
