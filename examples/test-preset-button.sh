#!/bin/bash

# Test Preset Button Flow
# This simulates what happens when a user presses a preset button on their Bose device

SERVER="http://localhost:8090"
DEVICE_ID="test-device-001"
ACCOUNT_ID="default"

echo "=== Testing Preset Button Flow ==="
echo ""

# Step 1: Store a web radio preset (simulating user configuring preset via app)
echo "1. Storing web radio preset to slot 1..."
curl -X POST "${SERVER}/storePreset?deviceId=${DEVICE_ID}&presetId=1" \
  -H "Content-Type: application/xml" \
  -d '<ContentItem source="INTERNET_RADIO" type="station" location="http://stream.example.com/radio">
    <itemName>My Favorite Radio</itemName>
    <containerArt>http://example.com/art.jpg</containerArt>
  </ContentItem>'
echo ""
echo ""

# Step 2: Device presses preset button 1 and queries server
echo "2. Device presses preset button 1 and queries server..."
curl -X GET "${SERVER}/device/${DEVICE_ID}/presets?presetId=1&accountId=${ACCOUNT_ID}" \
  -H "Content-Type: application/xml"
echo ""
echo ""

# Step 3: Get all presets
echo "3. Getting all presets for device..."
curl -X GET "${SERVER}/device/${DEVICE_ID}/presets?accountId=${ACCOUNT_ID}" \
  -H "Content-Type: application/xml"
echo ""
echo ""

# Step 4: Store another preset (Spotify)
echo "4. Storing Spotify preset to slot 2..."
curl -X POST "${SERVER}/storePreset?deviceId=${DEVICE_ID}&presetId=2" \
  -H "Content-Type: application/xml" \
  -d '<ContentItem source="SPOTIFY" type="playlist" location="spotify:playlist:37i9dQZF1DXcBWIGoYBM5M" sourceAccount="spotify_user">
    <itemName>Today'\''s Top Hits</itemName>
    <containerArt>https://i.scdn.co/image/ab67706f00000002724554ed6bed6f051d9b0bfc</containerArt>
  </ContentItem>'
echo ""
echo ""

# Step 5: Device queries preset 2
echo "5. Device presses preset button 2 and queries server..."
curl -X GET "${SERVER}/device/${DEVICE_ID}/presets?presetId=2&accountId=${ACCOUNT_ID}" \
  -H "Content-Type: application/xml"
echo ""
echo ""

echo "=== Test Complete ==="
echo ""
echo "The preset data is now stored in: data/accounts/${ACCOUNT_ID}/devices/${DEVICE_ID}/Presets.xml"
