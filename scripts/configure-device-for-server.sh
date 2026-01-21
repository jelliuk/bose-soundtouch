#!/bin/bash

# Script to configure a Bose SoundTouch device to use our server
# Usage: ./configure-device-for-server.sh <device_ip> <server_url> [account_id]

if [ $# -lt 2 ]; then
  echo "Usage: $0 <device_ip> <server_url> [account_id]"
  echo ""
  echo "Example:"
  echo "  $0 192.168.1.100 http://192.168.1.163:8090 default"
  echo ""
  echo "This script will:"
  echo "  1. Extract device information from the device"
  echo "  2. Upload it to your server"
  echo "  3. Provide instructions for device reconfiguration"
  echo ""
  echo "Note: Make sure your server is running at the specified URL"
  exit 1
fi

DEVICE_IP="$1"
SERVER_URL="$2"
ACCOUNT_ID="${3:-default}"

# Remove trailing slash from server URL
SERVER_URL="${SERVER_URL%/}"

TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

echo "========================================="
echo "Bose SoundTouch Device Configuration"
echo "========================================="
echo "Device IP:  $DEVICE_IP"
echo "Server URL: $SERVER_URL"
echo "Account ID: $ACCOUNT_ID"
echo ""

# Step 0: Verify server is accessible
echo "Step 0: Verifying server connectivity..."
echo ""

if curl -s -f "${SERVER_URL}/account/${ACCOUNT_ID}/devices" > /dev/null 2>&1; then
  echo "  ✓ Server is accessible"
else
  echo "  ✗ Cannot connect to server at: ${SERVER_URL}"
  echo ""
  echo "Make sure:"
  echo "  1. Server is running (npm start)"
  echo "  2. Server URL is correct: ${SERVER_URL}"
  echo "  3. Server is accessible from this machine"
  echo ""
  echo "Test with: curl ${SERVER_URL}/account/${ACCOUNT_ID}/devices"
  exit 1
fi
echo ""

# Step 1: Extract device information
echo "Step 1: Extracting device information..."
echo ""

echo "  - Getting device info..."
if curl -s "http://${DEVICE_IP}:8090/info" > "${TEMP_DIR}/DeviceInfo.xml"; then
  # Check if we got valid XML
  if grep -q "<info" "${TEMP_DIR}/DeviceInfo.xml"; then
    echo "    ✓ DeviceInfo.xml"
  else
    echo "    ✗ Invalid device info response"
    echo "    Response:"
    cat "${TEMP_DIR}/DeviceInfo.xml"
    exit 1
  fi
else
  echo "    ✗ Failed to get device info"
  echo ""
  echo "Make sure:"
  echo "  1. Device is powered on"
  echo "  2. Device IP is correct: $DEVICE_IP"
  echo "  3. Device is on same network"
  echo "  4. Device API is accessible on port 8090"
  exit 1
fi

# Extract device ID - try multiple patterns
DEVICE_ID=$(grep -o 'deviceID="[^"]*"' "${TEMP_DIR}/DeviceInfo.xml" | cut -d'"' -f2)
if [ -z "$DEVICE_ID" ]; then
  # Try alternative pattern
  DEVICE_ID=$(grep -o '<deviceID>[^<]*</deviceID>' "${TEMP_DIR}/DeviceInfo.xml" | sed 's/<[^>]*>//g')
fi

DEVICE_NAME=$(grep -o '<name>[^<]*</name>' "${TEMP_DIR}/DeviceInfo.xml" | sed 's/<[^>]*>//g' | head -1)

if [ -z "$DEVICE_ID" ]; then
  echo "    ✗ Could not extract device ID from response"
  echo "    DeviceInfo.xml content:"
  cat "${TEMP_DIR}/DeviceInfo.xml"
  exit 1
fi

echo "    Device ID: $DEVICE_ID"
echo "    Device Name: $DEVICE_NAME"
echo ""

echo "  - Getting presets..."
curl -s "http://${DEVICE_IP}:8090/presets" > "${TEMP_DIR}/Presets.xml"
echo "    ✓ Presets.xml"

echo "  - Getting recents..."
curl -s "http://${DEVICE_IP}:8090/recents" > "${TEMP_DIR}/Recents.xml"
echo "    ✓ Recents.xml"

echo ""

# Step 2: Upload to server
echo "Step 2: Uploading device data to server..."
echo ""

echo "  - Registering device..."
echo "    Sending to: ${SERVER_URL}/device/register"
echo "    Account ID: ${ACCOUNT_ID}"
echo "    Device ID: ${DEVICE_ID}"

# Send registration request with verbose output
RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "${SERVER_URL}/device/register" \
  -H "Content-Type: application/xml" \
  -H "X-Account-ID: ${ACCOUNT_ID}" \
  --data-binary "@${TEMP_DIR}/DeviceInfo.xml" 2>&1)

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

echo "    HTTP Status: $HTTP_CODE"

if [ "$HTTP_CODE" = "200" ] || echo "$BODY" | grep -qi "OK\|status"; then
  echo "    ✓ Device registered successfully"
else
  echo "    ✗ Registration failed"
  echo ""
  echo "Response body:"
  echo "$BODY"
  echo ""
  echo "Debug information:"
  echo "  Server URL: ${SERVER_URL}/device/register"
  echo "  Account ID: ${ACCOUNT_ID}"
  echo "  Device ID: ${DEVICE_ID}"
  echo ""
  echo "DeviceInfo.xml (first 20 lines):"
  head -20 "${TEMP_DIR}/DeviceInfo.xml"
  echo ""
  echo "Troubleshooting:"
  echo "  1. Check server logs for errors"
  echo "  2. Verify server is running: curl ${SERVER_URL}/account/${ACCOUNT_ID}/devices"
  echo "  3. Try manual registration:"
  echo "     curl -X POST '${SERVER_URL}/device/register' \\"
  echo "       -H 'Content-Type: application/xml' \\"
  echo "       -H 'X-Account-ID: ${ACCOUNT_ID}' \\"
  echo "       --data-binary '@${TEMP_DIR}/DeviceInfo.xml'"
  exit 1
fi

echo "  - Uploading presets..."
curl -s -X POST "${SERVER_URL}/device/${DEVICE_ID}/presets" \
  -H "Content-Type: application/xml" \
  -H "X-Account-ID: ${ACCOUNT_ID}" \
  --data-binary "@${TEMP_DIR}/Presets.xml" > /dev/null
echo "    ✓ Presets uploaded"

echo "  - Uploading recents..."
curl -s -X POST "${SERVER_URL}/device/${DEVICE_ID}/recents" \
  -H "Content-Type: application/xml" \
  -H "X-Account-ID: ${ACCOUNT_ID}" \
  --data-binary "@${TEMP_DIR}/Recents.xml" > /dev/null
echo "    ✓ Recents uploaded"

echo ""
echo "========================================="
echo "Device data uploaded successfully!"
echo "========================================="
echo ""

# Step 3: Instructions for device reconfiguration
echo "Step 3: Configure device to use your server"
echo ""
echo "⚠️  IMPORTANT: The following steps require physical access to the device"
echo ""
echo "1. Prepare USB drive:"
echo "   - Format USB drive as FAT32"
echo "   - Create empty file: touch /path/to/usb/remote_services"
echo ""
echo "2. Enable remote access:"
echo "   - Power off device"
echo "   - Insert USB drive into device"
echo "   - Power on device"
echo "   - Wait 30 seconds"
echo ""
echo "3. Connect to device:"
echo "   telnet ${DEVICE_IP} 17000"
echo "   (login as 'root', no password)"
echo ""
echo "4. Make filesystem writable:"
echo "   mount -o remount,rw /dev/root /"
echo ""
echo "5. Backup original config:"
echo "   cp /opt/Bose/etc/SoundTouchSdkPrivateCfg.xml /opt/Bose/etc/SoundTouchSdkPrivateCfg.xml.backup"
echo ""
echo "6. Edit configuration:"
echo "   vi /opt/Bose/etc/SoundTouchSdkPrivateCfg.xml"
echo ""
echo "   Change ALL server URLs to: ${SERVER_URL}"
echo ""
echo "   Example:"
echo "   <server name=\"marge\" url=\"${SERVER_URL}\"/>"
echo "   <server name=\"bmx\" url=\"${SERVER_URL}\"/>"
echo "   <server name=\"stats\" url=\"${SERVER_URL}\"/>"
echo "   <server name=\"swUpdate\" url=\"${SERVER_URL}\"/>"
echo ""
echo "7. Reboot device:"
echo "   reboot"
echo ""
echo "8. Verify connection:"
echo "   Check server logs for: 'Device registration: ${DEVICE_ID}'"
echo ""
echo "========================================="
echo ""
echo "Need help? See DEVICE_CONFIGURATION_GUIDE.md"
echo ""

# Save instructions to file
INSTRUCTIONS_FILE="${TEMP_DIR}/device-${DEVICE_ID}-instructions.txt"
cat > "$INSTRUCTIONS_FILE" << EOF
Bose SoundTouch Device Configuration Instructions
Device: $DEVICE_NAME ($DEVICE_ID)
IP: $DEVICE_IP
Server: $SERVER_URL
Account: $ACCOUNT_ID

TELNET COMMANDS:
================

# Connect
telnet ${DEVICE_IP}
# Login: root (no password)

# Make writable
mount -o remount,rw /dev/root /

# Backup
cp /opt/Bose/etc/SoundTouchSdkPrivateCfg.xml /opt/Bose/etc/SoundTouchSdkPrivateCfg.xml.backup

# Edit (change all URLs to ${SERVER_URL})
vi /opt/Bose/etc/SoundTouchSdkPrivateCfg.xml

# Reboot
reboot

VERIFICATION:
=============

# Check device appears in server
curl "${SERVER_URL}/account/${ACCOUNT_ID}/devices"

# Check device can get its config
curl "${SERVER_URL}/device/${DEVICE_ID}/config"

# Check presets
curl "${SERVER_URL}/device/${DEVICE_ID}/presets"

EOF

cp "$INSTRUCTIONS_FILE" "./device-${DEVICE_ID}-instructions.txt"
echo "Instructions saved to: device-${DEVICE_ID}-instructions.txt"
echo ""
