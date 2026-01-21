#!/bin/bash

# Quick test script to verify device and server connectivity
# Usage: ./test-device-connection.sh <device_ip> <server_url>

if [ $# -lt 2 ]; then
  echo "Usage: $0 <device_ip> <server_url>"
  echo ""
  echo "Example:"
  echo "  $0 192.168.1.128 http://192.168.1.163:8090"
  exit 1
fi

DEVICE_IP="$1"
SERVER_URL="${2%/}"  # Remove trailing slash

echo "========================================="
echo "Device & Server Connection Test"
echo "========================================="
echo ""

# Test 1: Device connectivity
echo "Test 1: Device Connectivity"
echo "  Testing: http://${DEVICE_IP}:8090/info"
echo ""

if curl -s -f -m 5 "http://${DEVICE_IP}:8090/info" > /tmp/device-info.xml 2>&1; then
  echo "  ✓ Device is accessible"
  
  # Extract device ID
  DEVICE_ID=$(grep -o 'deviceID="[^"]*"' /tmp/device-info.xml | cut -d'"' -f2)
  if [ -z "$DEVICE_ID" ]; then
    DEVICE_ID=$(grep -o '<deviceID>[^<]*</deviceID>' /tmp/device-info.xml | sed 's/<[^>]*>//g')
  fi
  
  DEVICE_NAME=$(grep -o '<name>[^<]*</name>' /tmp/device-info.xml | sed 's/<[^>]*>//g' | head -1)
  
  echo "  Device ID: ${DEVICE_ID:-Not found}"
  echo "  Device Name: ${DEVICE_NAME:-Not found}"
  echo ""
  
  echo "  Device Info XML (first 10 lines):"
  head -10 /tmp/device-info.xml | sed 's/^/    /'
  echo ""
else
  echo "  ✗ Cannot connect to device"
  echo ""
  echo "  Troubleshooting:"
  echo "    1. Verify device IP: $DEVICE_IP"
  echo "    2. Ensure device is powered on"
  echo "    3. Check network connectivity: ping $DEVICE_IP"
  echo "    4. Verify device API port 8090 is accessible"
  echo ""
  exit 1
fi

# Test 2: Server connectivity
echo "Test 2: Server Connectivity"
echo "  Testing: ${SERVER_URL}/account/default/devices"
echo ""

if curl -s -f -m 5 "${SERVER_URL}/account/default/devices" > /tmp/server-response.json 2>&1; then
  echo "  ✓ Server is accessible"
  echo ""
  echo "  Server Response:"
  cat /tmp/server-response.json | head -20 | sed 's/^/    /'
  echo ""
else
  echo "  ✗ Cannot connect to server"
  echo ""
  echo "  Troubleshooting:"
  echo "    1. Verify server URL: $SERVER_URL"
  echo "    2. Ensure server is running: npm start"
  echo "    3. Check server logs for errors"
  echo "    4. Test manually: curl ${SERVER_URL}/account/default/devices"
  echo ""
  exit 1
fi

# Test 3: Registration endpoint
echo "Test 3: Registration Endpoint"
echo "  Testing: ${SERVER_URL}/device/register"
echo ""

# Try to register with the actual device info
RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "${SERVER_URL}/device/register" \
  -H "Content-Type: application/xml" \
  -H "X-Account-ID: default" \
  --data-binary "@/tmp/device-info.xml" 2>&1)

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

echo "  HTTP Status: $HTTP_CODE"
echo "  Response:"
echo "$BODY" | sed 's/^/    /'
echo ""

if [ "$HTTP_CODE" = "200" ] || echo "$BODY" | grep -qi "OK\|status"; then
  echo "  ✓ Registration successful"
else
  echo "  ✗ Registration failed"
  echo ""
  echo "  This might be normal if the device is already registered."
  echo "  Check the response above for details."
fi

echo ""
echo "========================================="
echo "Test Complete"
echo "========================================="
echo ""

if [ -n "$DEVICE_ID" ]; then
  echo "Next steps:"
  echo "  1. Run the full configuration script:"
  echo "     ./scripts/configure-device-for-server.sh $DEVICE_IP $SERVER_URL"
  echo ""
  echo "  2. Or verify device is registered:"
  echo "     curl ${SERVER_URL}/account/default/devices"
  echo ""
fi

# Cleanup
rm -f /tmp/device-info.xml /tmp/server-response.json
