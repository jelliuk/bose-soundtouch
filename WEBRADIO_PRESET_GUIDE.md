# Web Radio Preset Configuration Guide

## Overview

Web radio presets allow you to save and quickly access internet radio stations on your Bose SoundTouch devices. Each device supports up to 6 presets.

## How Preset Buttons Work

When a user presses a preset button on their Bose device:

1. **Device queries server**: `GET /device/{deviceId}/presets?presetId=1`
2. **Server returns preset details**: XML with station URL, name, artwork
3. **Device plays the stream**: Automatically starts playing the web radio station

This implementation matches the soundcork approach and ensures presets are stored persistently in the filesystem at `data/accounts/{accountId}/devices/{deviceId}/Presets.xml`.

## Method 1: Using the API (Recommended)

### Store a Web Radio Preset

Save a radio station to a preset slot (1-6):

```bash
curl -X POST "http://localhost:8090/storePreset?deviceId=device1&presetId=1" \
  -H "Content-Type: application/xml" \
  -d '<ContentItem source="INTERNET_RADIO" type="station" location="http://stream.example.com/radio">
  <itemName>My Favorite Radio</itemName>
  <containerArt>http://example.com/logo.jpg</containerArt>
</ContentItem>'
```

**Key Parameters:**
- `deviceId` - Your device identifier
- `presetId` - Preset slot number (1-6)
- `source="INTERNET_RADIO"` - Identifies this as internet radio
- `type="station"` - Content type
- `location="http://..."` - The stream URL
- `itemName` - Display name for the station
- `containerArt` - Optional logo/artwork URL

**What happens:**
1. Server stores preset in memory
2. Server saves preset to persistent storage: `data/accounts/default/devices/{deviceId}/Presets.xml`
3. When device presses preset button, it queries server and receives the preset details
4. Device automatically plays the web radio stream

### Test Preset Button

Simulate a device pressing preset button 1:

```bash
curl -X GET "http://localhost:8090/device/device1/presets?presetId=1&accountId=default"
```

This returns the preset details in XML format that the device uses to play the stream.

## Method 2: Configure Default Presets (Server-Side)

### Edit Preset Initializer

Modify `src/utils/presetInitializer.js` to add your custom stations:

```javascript
export function initializeDefaultPresets(device) {
  const defaultPresets = [
    {
      id: '1',
      name: 'BBC Radio 1',
      source: 'INTERNET_RADIO',
      type: 'station',
      location: 'http://stream.live.vc.bbcmedia.co.uk/bbc_radio_one',
      art: 'https://cdn-profiles.tunein.com/s24939/images/logog.png',
      createdOn: Date.now(),
      updatedOn: Date.now()
    },
    {
      id: '2',
      name: 'Your Custom Radio',
      source: 'INTERNET_RADIO',
      type: 'station',
      location: 'http://your-stream-url.com:8000/stream',
      art: 'http://your-logo-url.com/logo.png',
      createdOn: Date.now(),
      updatedOn: Date.now()
    },
    // Add up to 6 presets total
  ];

  device.setPresets(defaultPresets);
}
```

## Method 3: Runtime Preset Management

### Available Endpoints

The server provides complete preset management:

```bash
# Store a preset (saves to persistent storage)
POST /storePreset?deviceId={id}&presetId={1-6}

# Remove a specific preset
POST /removePreset?deviceId={id}&presetId={1-6}

# Remove all presets
POST /removeAllPresets?deviceId={id}

# Get all presets (for device)
GET /device/{deviceId}/presets?accountId={accountId}

# Get specific preset (for device preset button)
GET /device/{deviceId}/presets?presetId={1-6}&accountId={accountId}
```

### Complete Example

See `examples/test-preset-button.sh` for a complete test script that demonstrates:
1. Storing web radio presets
2. Storing Spotify presets
3. Querying specific presets (simulating button press)
4. Verifying persistent storage

## Popular Web Radio Streams

### BBC Radio Stations
```xml
<!-- BBC Radio 1 -->
<ContentItem source="INTERNET_RADIO" type="station" 
  location="http://stream.live.vc.bbcmedia.co.uk/bbc_radio_one">
  <itemName>BBC Radio 1</itemName>
</ContentItem>

<!-- BBC Radio 2 -->
<ContentItem source="INTERNET_RADIO" type="station" 
  location="http://stream.live.vc.bbcmedia.co.uk/bbc_radio_two">
  <itemName>BBC Radio 2</itemName>
</ContentItem>

<!-- BBC Radio 6 Music -->
<ContentItem source="INTERNET_RADIO" type="station" 
  location="http://stream.live.vc.bbcmedia.co.uk/bbc_6music">
  <itemName>BBC 6 Music</itemName>
</ContentItem>
```

### Jazz & Classical
```xml
<!-- Jazz Radio -->
<ContentItem source="INTERNET_RADIO" type="station" 
  location="http://jazz-wr01.ice.infomaniak.ch/jazz-wr01-128.mp3">
  <itemName>Jazz Radio</itemName>
</ContentItem>

<!-- Classical Radio -->
<ContentItem source="INTERNET_RADIO" type="station" 
  location="http://stream.live.vc.bbcmedia.co.uk/bbc_radio_three">
  <itemName>BBC Radio 3 (Classical)</itemName>
</ContentItem>
```

### Popular Stations
```xml
<!-- NPR -->
<ContentItem source="INTERNET_RADIO" type="station" 
  location="http://npr-ice.streamguys1.com/live.mp3">
  <itemName>NPR</itemName>
</ContentItem>

<!-- Smooth Jazz -->
<ContentItem source="INTERNET_RADIO" type="station" 
  location="http://smoothjazz.cdnstream1.com/2586_128.mp3">
  <itemName>Smooth Jazz</itemName>
</ContentItem>
```

## Finding Stream URLs

### Method 1: TuneIn / Radio Browser
1. Visit https://www.radio-browser.info/
2. Search for your station
3. Copy the stream URL (usually ends in .mp3, .aac, or .pls)

### Method 2: Station Website
1. Visit the radio station's website
2. Look for "Listen Live" or "Stream"
3. Right-click and inspect the audio player
4. Find the stream URL in the network tab

### Method 3: VLC Media Player
1. Open VLC
2. Media → Open Network Stream
3. Paste the station URL
4. Tools → Codec Information
5. Copy the "Location" URL

## Stream URL Formats

### Direct Streams (Best)
```
http://stream.example.com:8000/live.mp3
http://stream.example.com/radio.aac
https://stream.example.com/station
```

### Playlist Files (May need parsing)
```
http://stream.example.com/station.pls
http://stream.example.com/station.m3u
```

## Complete Example: Adding a Custom Station

### 1. Test the Stream URL
```bash
# Test with curl
curl -I http://your-stream-url.com:8000/stream

# Or play with VLC/mpv
vlc http://your-stream-url.com:8000/stream
```

### 2. Play on Device
```bash
curl -X POST "http://localhost:8090/select?deviceId=device1" \
  -H "Content-Type: application/xml" \
  -d '<?xml version="1.0" encoding="UTF-8"?>
<ContentItem source="INTERNET_RADIO" type="station" 
  location="http://your-stream-url.com:8000/stream" 
  isPresetable="true">
  <itemName>My Custom Radio Station</itemName>
  <containerArt>http://your-logo.com/logo.png</containerArt>
</ContentItem>'
```

### 3. Store as Preset (with new endpoint)
```bash
curl -X POST "http://localhost:8090/storePreset?deviceId=device1&presetId=1" \
  -H "Content-Type: application/xml" \
  -d '<?xml version="1.0" encoding="UTF-8"?>
<ContentItem source="INTERNET_RADIO" type="station" 
  location="http://your-stream-url.com:8000/stream">
  <itemName>My Custom Radio Station</itemName>
  <containerArt>http://your-logo.com/logo.png</containerArt>
</ContentItem>'
```

### 4. Recall Preset
```bash
# Select preset by ID
curl -X POST "http://localhost:8090/select?deviceId=device1" \
  -H "Content-Type: application/xml" \
  -d '<?xml version="1.0" encoding="UTF-8"?>
<ContentItem source="INTERNET_RADIO" presetId="1">
  <itemName>My Custom Radio Station</itemName>
</ContentItem>'

# Or use key press
curl -X POST "http://localhost:8090/key?deviceId=device1" \
  -H "Content-Type: application/xml" \
  -d '<key state="press" sender="Remote">PRESET_1</key>'
```

## Preset Configuration File

For persistent storage, create a presets configuration file:

```json
// config/presets.json
{
  "device1": [
    {
      "id": "1",
      "name": "BBC Radio 1",
      "source": "INTERNET_RADIO",
      "type": "station",
      "location": "http://stream.live.vc.bbcmedia.co.uk/bbc_radio_one",
      "art": "https://cdn-profiles.tunein.com/s24939/images/logog.png"
    },
    {
      "id": "2",
      "name": "Jazz Radio",
      "source": "INTERNET_RADIO",
      "type": "station",
      "location": "http://jazz-wr01.ice.infomaniak.ch/jazz-wr01-128.mp3",
      "art": "https://cdn-profiles.tunein.com/s8379/images/logog.png"
    }
  ],
  "device2": [
    {
      "id": "1",
      "name": "Classical Music",
      "source": "INTERNET_RADIO",
      "type": "station",
      "location": "http://stream.live.vc.bbcmedia.co.uk/bbc_radio_three",
      "art": "https://cdn-profiles.tunein.com/s24941/images/logog.png"
    }
  ]
}
```

Load in `deviceManager.js`:

```javascript
loadPresets() {
  const presetsPath = './config/presets.json';
  if (existsSync(presetsPath)) {
    const presets = JSON.parse(readFileSync(presetsPath, 'utf8'));
    
    this.devices.forEach(device => {
      if (presets[device.id]) {
        device.setPresets(presets[device.id]);
        console.log(`Loaded ${presets[device.id].length} presets for ${device.name}`);
      }
    });
  }
}
```

## Troubleshooting

### Stream Won't Play
- **Check URL**: Verify the stream URL is accessible
- **Format**: Ensure it's a direct stream (MP3, AAC, OGG)
- **HTTPS**: Some devices may have issues with HTTPS streams
- **Firewall**: Check if the stream is blocked

### Preset Not Saving
- **Limit**: Maximum 6 presets per device
- **Persistence**: Current implementation is in-memory only
- **Solution**: Implement file-based or database storage

### Poor Audio Quality
- **Bitrate**: Look for higher bitrate streams (128kbps+)
- **Format**: MP3 and AAC are most compatible
- **Network**: Check your internet connection

## Best Practices

1. **Use Direct Streams**: Avoid .pls or .m3u playlist files
2. **Test First**: Always test the stream URL before saving
3. **Add Artwork**: Include station logos for better UX
4. **Descriptive Names**: Use clear, recognizable station names
5. **Organize**: Group similar stations (news, music, talk)
6. **Backup**: Keep a list of your stream URLs

## Integration with Real Bose Devices

When connecting to real Bose hardware, the preset configuration works the same way:

1. The server forwards the `/select` request to the device
2. The device plays the stream
3. User can save to preset using the Bose app or remote
4. Server can query `/presets` to get the saved presets

The advantage of this server is you can pre-configure presets before the device even connects!
