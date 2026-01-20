# Preset Button Implementation

## Overview

This document explains how the preset button functionality works, matching the soundcork implementation approach.

## How It Works

### 1. User Stores a Preset

When a user wants to save a web radio station or Spotify playlist to a preset button:

```bash
POST /storePreset?deviceId=device1&presetId=1
Content-Type: application/xml

<ContentItem source="INTERNET_RADIO" type="station" location="http://stream.example.com/radio">
  <itemName>My Favorite Radio</itemName>
  <containerArt>http://example.com/logo.jpg</containerArt>
</ContentItem>
```

**What happens:**
1. `PresetStorageController.storePreset()` receives the request
2. Parses the XML content and extracts preset details
3. Updates the device's in-memory preset list
4. Converts presets to XML format
5. Saves to persistent storage: `data/accounts/{accountId}/devices/{deviceId}/Presets.xml`

### 2. User Presses Preset Button on Device

When the user presses preset button 1 on their physical Bose device:

```bash
GET /device/device1/presets?presetId=1&accountId=default
```

**What happens:**
1. Device sends HTTP GET request to server
2. `CloudReplacementController.getPresets()` receives the request
3. Loads `Presets.xml` from filesystem storage
4. Parses XML and finds preset with matching ID
5. Returns preset details in XML format
6. Device receives the response and automatically plays the stream

### 3. Device Plays the Stream

The device receives XML like this:

```xml
<presets>
  <preset id="1" createdOn="1234567890" updatedOn="1234567890">
    <ContentItem source="INTERNET_RADIO" type="station" location="http://stream.example.com/radio" sourceAccount="" isPresetable="true">
      <itemName>My Favorite Radio</itemName>
      <containerArt>http://example.com/logo.jpg</containerArt>
    </ContentItem>
  </preset>
</presets>
```

The device extracts the `location` URL and starts streaming the audio.

## Architecture

### Components

1. **PresetStorageController** (`src/controllers/presetStorageController.js`)
   - Handles storing, updating, and removing presets
   - Converts in-memory presets to XML format
   - Saves to persistent storage via FileStorage

2. **CloudReplacementController** (`src/controllers/cloudReplacementController.js`)
   - Handles device-initiated requests
   - Loads presets from persistent storage
   - Supports querying all presets or specific preset by ID

3. **FileStorage** (`src/storage/fileStorage.js`)
   - Manages filesystem operations
   - Stores XML files in soundcork-compatible structure
   - Path: `data/accounts/{accountId}/devices/{deviceId}/Presets.xml`

### Data Flow

```
User Action → API Request → Controller → Device Manager → Storage
                                              ↓
                                         In-Memory State
                                              ↓
                                         XML Conversion
                                              ↓
                                      Persistent Storage
                                              ↓
                                    data/accounts/.../Presets.xml

Device Button Press → API Request → Controller → Storage → Load XML
                                                              ↓
                                                         Parse & Filter
                                                              ↓
                                                      Return Preset XML
                                                              ↓
                                                      Device Plays Stream
```

## Storage Format

### In-Memory Format (JavaScript)

```javascript
{
  id: '1',
  name: 'BBC Radio 1',
  source: 'INTERNET_RADIO',
  type: 'station',
  location: 'http://stream.live.vc.bbcmedia.co.uk/bbc_radio_one',
  art: 'https://cdn-profiles.tunein.com/s24939/images/logog.png',
  sourceAccount: '',
  createdOn: 1234567890,
  updatedOn: 1234567890
}
```

### Persistent Storage Format (XML)

```xml
<presets>
  <preset id="1" createdOn="1234567890" updatedOn="1234567890">
    <ContentItem source="INTERNET_RADIO" type="station" location="http://stream.live.vc.bbcmedia.co.uk/bbc_radio_one" sourceAccount="" isPresetable="true">
      <itemName>BBC Radio 1</itemName>
      <containerArt>https://cdn-profiles.tunein.com/s24939/images/logog.png</containerArt>
    </ContentItem>
  </preset>
  <preset id="2" createdOn="1234567890" updatedOn="1234567890">
    <ContentItem source="SPOTIFY" type="playlist" location="spotify:playlist:37i9dQZF1DXcBWIGoYBM5M" sourceAccount="spotify_user" isPresetable="true">
      <itemName>Today's Top Hits</itemName>
      <containerArt>https://i.scdn.co/image/ab67706f00000002724554ed6bed6f051d9b0bfc</containerArt>
    </ContentItem>
  </preset>
</presets>
```

## API Endpoints

### Store Preset
```
POST /storePreset?deviceId={id}&presetId={1-6}
Content-Type: application/xml

<ContentItem source="..." type="..." location="...">
  <itemName>...</itemName>
  <containerArt>...</containerArt>
</ContentItem>
```

### Get All Presets (Device Query)
```
GET /device/{deviceId}/presets?accountId={accountId}
```

### Get Specific Preset (Preset Button)
```
GET /device/{deviceId}/presets?presetId={1-6}&accountId={accountId}
```

### Remove Preset
```
POST /removePreset?deviceId={id}&presetId={1-6}
```

### Remove All Presets
```
POST /removeAllPresets?deviceId={id}
```

## Comparison with Soundcork

| Feature | Soundcork | This Implementation | Status |
|---------|-----------|---------------------|--------|
| Preset storage location | `data/accounts/{accountId}/devices/{deviceId}/Presets.xml` | Same | ✅ Matching |
| Device queries server | `GET /device/:deviceId/presets` | Same | ✅ Matching |
| Specific preset query | `?presetId=1` parameter | Same | ✅ Matching |
| XML format | Bose-compatible XML | Same | ✅ Matching |
| Persistent storage | Filesystem (XML files) | Same | ✅ Matching |
| In-memory caching | Yes | Yes | ✅ Matching |

## Testing

### Test Script

Run the complete test:

```bash
./examples/test-preset-button.sh
```

This script:
1. Stores a web radio preset to slot 1
2. Queries preset 1 (simulates button press)
3. Gets all presets
4. Stores a Spotify preset to slot 2
5. Queries preset 2 (simulates button press)
6. Verifies persistent storage

### Manual Testing

```bash
# Start server
npm start

# Store preset
curl -X POST "http://localhost:8090/storePreset?deviceId=test-device&presetId=1" \
  -H "Content-Type: application/xml" \
  -d '<ContentItem source="INTERNET_RADIO" type="station" location="http://stream.example.com/radio">
    <itemName>Test Radio</itemName>
  </ContentItem>'

# Simulate preset button press
curl -X GET "http://localhost:8090/device/test-device/presets?presetId=1&accountId=default"

# Check persistent storage
cat data/accounts/default/devices/test-device/Presets.xml
```

## Implementation Details

### PresetStorageController.storePreset()

1. Parses incoming XML
2. Extracts preset details (name, source, location, etc.)
3. Updates device's in-memory preset array
4. Calls `savePresetsToStorage()` to persist

### PresetStorageController.savePresetsToStorage()

1. Gets device's current presets from memory
2. Converts each preset to XML structure using xml2js Builder
3. Builds complete `<presets>` XML document
4. Calls `storage.savePresets()` to write to filesystem

### CloudReplacementController.getPresets()

1. Checks if `presetId` query parameter is present
2. If yes: loads XML, parses, filters to specific preset, returns single preset
3. If no: loads XML, returns all presets
4. If no presets exist: returns empty `<presets/>` element

## Benefits

1. **Persistent Storage**: Presets survive server restarts
2. **Soundcork Compatible**: Uses same storage structure and API
3. **Device-Initiated**: Devices query server (cloud replacement model)
4. **Flexible**: Supports web radio, Spotify, and other sources
5. **Standard Format**: Uses Bose-compatible XML format

## Future Enhancements

1. **Preset Sync**: Automatically sync presets across multiple devices
2. **Backup/Restore**: Export/import preset configurations
3. **Web UI**: Visual preset management interface
4. **Preset Sharing**: Share preset configurations between users
5. **Cloud Backup**: Optional cloud backup of presets
