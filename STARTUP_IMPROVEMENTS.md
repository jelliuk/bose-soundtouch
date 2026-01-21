# Server Startup Improvements

## Changes Made

### 1. Removed Dummy Data from devices.json ✅

**Before:**
```json
{
  "devices": [
    {
      "id": "device1",
      "name": "Living Room Speaker",
      "host": "192.168.1.100",
      "port": 8090
    },
    {
      "id": "device2",
      "name": "Bedroom Speaker",
      "host": "192.168.1.101",
      "port": 8090
    }
  ]
}
```

**After:**
```json
{
  "devices": []
}
```

**Reason:** The dummy devices were confusing and not representative of actual registered devices. The real device data comes from the `data/` directory, not `devices.json`.

### 2. Enhanced Server Startup Display ✅

**Before:**
```
Bose SoundTouch Server running on port 8090
WebSocket notifications available at ws://localhost:8090/notifications
```

**After:**
```
======================================================================
🎵 Bose SoundTouch Server
======================================================================
Server:      http://localhost:8090
Web UI:      http://localhost:8090
Test Page:   http://localhost:8090/test.html
WebSocket:   ws://localhost:8090/notifications
======================================================================

📊 Server Statistics:
----------------------------------------------------------------------
Accounts:    1 (default)
Devices:     1

📱 Registered Devices:
----------------------------------------------------------------------
  • SoundTouch Arbeitszimmer
    ID:   08DF1F0EBF49
    Type: SoundTouch 20
    IP:   192.168.1.128
    Presets: 4

======================================================================
✅ Server ready - Waiting for connections...
======================================================================
```

### 3. Updated deviceManager.js ✅

**Changes:**
- Empty config created by default (no dummy devices)
- Better logging messages
- Only loads devices if they exist in config

**Before:**
```javascript
createDefaultConfig() {
  const defaultConfig = {
    devices: [
      {
        id: 'device1',
        name: 'Living Room Speaker',
        host: '192.168.1.100',
        port: 8090
      }
    ]
  };
  // ...
}
```

**After:**
```javascript
createDefaultConfig() {
  const defaultConfig = {
    devices: []
  };
  // ...
}
```

### 4. Added listAccounts() to FileStorage ✅

New method to support listing all accounts in the data directory:

```javascript
listAccounts() {
  const accountsPath = join(this.dataDir, 'accounts');
  if (!existsSync(accountsPath)) {
    return [];
  }
  return readdirSync(accountsPath);
}
```

## What the Startup Shows

### With Registered Devices (Your Current State)

```
======================================================================
🎵 Bose SoundTouch Server
======================================================================
Server:      http://localhost:8090
Web UI:      http://localhost:8090
Test Page:   http://localhost:8090/test.html
WebSocket:   ws://localhost:8090/notifications
======================================================================

📊 Server Statistics:
----------------------------------------------------------------------
Accounts:    1 (default)
Devices:     1

📱 Registered Devices:
----------------------------------------------------------------------
  • SoundTouch Arbeitszimmer
    ID:   08DF1F0EBF49
    Type: SoundTouch 20
    IP:   192.168.1.128
    Presets: 4

======================================================================
✅ Server ready - Waiting for connections...
======================================================================
```

### Without Registered Devices (Fresh Install)

```
======================================================================
🎵 Bose SoundTouch Server
======================================================================
Server:      http://localhost:8090
Web UI:      http://localhost:8090
Test Page:   http://localhost:8090/test.html
WebSocket:   ws://localhost:8090/notifications
======================================================================

📊 Server Statistics:
----------------------------------------------------------------------
Accounts:    1 (default)
Devices:     0

⚠️  No devices registered yet.
   Add devices via Web UI or use:
   ./scripts/configure-device-for-server.sh DEVICE_IP SERVER_URL

======================================================================
✅ Server ready - Waiting for connections...
======================================================================
```

## Benefits

1. **Clear Overview** - See all registered devices at startup
2. **Real Data** - Shows actual devices from `data/` directory, not dummy data
3. **Device Details** - Shows name, ID, type, IP, and preset count
4. **Easy Access** - All URLs displayed clearly
5. **Status at a Glance** - Know immediately if devices are registered
6. **Helpful Instructions** - Shows how to add devices if none exist

## Files Modified

1. **config/devices.json** - Removed dummy devices
2. **src/server.js** - Enhanced startup display with statistics
3. **src/deviceManager.js** - Empty config by default
4. **src/storage/fileStorage.js** - Added listAccounts() method

## Testing

To see the new startup display, restart your server:

```bash
# Stop current server (Ctrl+C)
# Start again
npm start
```

You should see the enhanced startup display with your actual device information.

## Notes

### About devices.json

The `devices.json` file is now primarily for **legacy/manual device configuration**. The real device data comes from the `data/` directory where devices register themselves.

**devices.json is used for:**
- Manual device configuration (optional)
- Legacy compatibility
- Pre-configuring devices before they register

**data/ directory is used for:**
- Actual device registration (primary)
- Device info, presets, recents, sources
- Persistent storage
- Cloud replacement functionality

Most users will have an empty `devices.json` and all their devices in `data/accounts/default/devices/`.

### Startup Information

The startup display now shows:
- ✅ Server URLs (main, Web UI, test page, WebSocket)
- ✅ Account count
- ✅ Device count
- ✅ Device details (name, ID, type, IP)
- ✅ Preset count per device
- ✅ Instructions if no devices

This gives you a complete overview of your server state at startup.

---

**Status:** All improvements implemented ✅
**Server will now show real device data on startup**
