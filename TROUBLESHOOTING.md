# Troubleshooting Guide

## Device Configuration Script Issues

### Error: "Registration failed"

**Symptoms:**
```
Step 2: Uploading device data to server...
  - Registering device...
    ✗ Registration failed
```

**Common Causes & Solutions:**

#### 1. Server Not Running

**Check:**
```bash
curl http://192.168.1.163:8090/account/default/devices
```

**Solution:**
```bash
# Start the server
npm start

# Verify it's running
curl http://localhost:8090/account/default/devices
```

#### 2. Wrong Server URL

**Problem:** Server URL is incorrect or has wrong format

**Check:**
```bash
# Test the URL directly
curl http://YOUR_SERVER_IP:8090/account/default/devices
```

**Solution:**
- Use correct format: `http://IP:PORT` (no trailing slash)
- Example: `http://192.168.1.163:8090`
- NOT: `http://192.168.1.163:8090/`

#### 3. Device Not Accessible

**Check:**
```bash
# Test device connectivity
curl http://192.168.1.128:8090/info
```

**Solution:**
- Verify device IP address
- Ensure device is powered on
- Check network connectivity: `ping 192.168.1.128`
- Ensure device and server are on same network

#### 4. Firewall Blocking Connection

**Check:**
```bash
# Test from server machine
curl http://DEVICE_IP:8090/info

# Test from device to server
# (requires telnet access to device)
```

**Solution:**
- Allow port 8090 in firewall
- Disable firewall temporarily to test
- Check router settings

### Quick Diagnostic Script

Use the test script to diagnose issues:

```bash
./scripts/test-device-connection.sh 192.168.1.128 http://192.168.1.163:8090
```

This will test:
1. Device connectivity
2. Server connectivity
3. Registration endpoint

## Web UI Issues

### Cannot Access Web UI

**Problem:** Browser shows "Cannot connect" at http://localhost:8090

**Solutions:**

1. **Server not running:**
   ```bash
   npm start
   ```

2. **Wrong URL:**
   - Use: `http://localhost:8090`
   - Or: `http://127.0.0.1:8090`
   - Or: `http://YOUR_SERVER_IP:8090`

3. **Port already in use:**
   ```bash
   # Check what's using port 8090
   lsof -i :8090
   
   # Use different port
   PORT=8091 npm start
   ```

### Web UI Loads But Shows No Devices

**Problem:** Device list is empty

**Solutions:**

1. **Devices not registered:**
   ```bash
   # Check registered devices
   curl http://localhost:8090/account/default/devices
   ```

2. **Wrong account ID:**
   - Check Settings tab
   - Verify account ID matches device configuration

3. **Refresh devices:**
   - Click "Refresh Devices" button in Web UI

## API Issues

### Preset Button Not Working

**Problem:** Device doesn't play when preset button pressed

**Diagnostic:**
```bash
# Check if preset exists
curl http://localhost:8090/device/DEVICE_ID/presets?presetId=1

# Test BMX resolution
curl -X POST http://localhost:8090/bmx/resolve \
  -H "Content-Type: application/xml" \
  -d '<ContentItem source="INTERNET_RADIO" type="station" stationId="s24939">
    <itemName>Test</itemName>
  </ContentItem>'
```

**Solutions:**

1. **Preset not configured:**
   - Use Web UI to configure preset
   - Or use API: `POST /storePreset`

2. **TuneIn station ID invalid:**
   - Search for station: `GET /tunein/search?query=BBC`
   - Use valid station ID

3. **Stream URL not accessible:**
   - Test stream URL in browser
   - Try different station

### TuneIn Search Returns No Results

**Problem:** Search returns empty results

**Diagnostic:**
```bash
curl "http://localhost:8090/tunein/search?query=BBC"
```

**Solutions:**

1. **No internet connection:**
   - Verify server has internet access
   - Test: `curl https://opml.radiotime.com/Browse.ashx?c=local`

2. **TuneIn API down:**
   - Try again later
   - Use direct stream URLs instead

3. **Search query too specific:**
   - Try broader search terms
   - Use browse categories instead

## Device Connection Issues

### Device Won't Connect to Server

**Problem:** Device doesn't appear in server logs

**Diagnostic:**
```bash
# Check server logs
npm start
# Look for: "Device registration: DEVICE_ID"

# Check device can reach server
# (requires telnet access)
telnet DEVICE_IP 17000
# Then: ping SERVER_IP
```

**Solutions:**

1. **Device not configured:**
   - Follow DEVICE_CONFIGURATION_GUIDE.md
   - Verify config file changes
   - Reboot device

2. **Wrong server URL in device config:**
   - Check `/opt/Bose/etc/SoundTouchSdkPrivateCfg.xml`
   - All URLs should point to your server
   - Format: `http://SERVER_IP:8090`

3. **Network issues:**
   - Ensure device and server on same network
   - Check firewall rules
   - Verify DNS resolution

### Telnet Access Not Working

**Problem:** Cannot telnet to device

**Solutions:**

1. **Remote access not enabled:**
   - Create USB drive with `remote_services` file
   - Insert into device and reboot
   - Wait 30 seconds

2. **Wrong port:**
   - Use port 17000 (not 8090)
   - Command: `telnet DEVICE_IP 17000`

3. **Telnet not installed:**
   ```bash
   # macOS
   brew install telnet
   
   # Linux
   sudo apt-get install telnet
   ```

## Zone (Multiroom) Issues

### Cannot Create Zone

**Problem:** Zone creation fails

**Diagnostic:**
```bash
curl -X POST "http://localhost:8090/setZone?deviceId=device1" \
  -H "Content-Type: application/xml" \
  -d '<zone master="device1">
    <member role="MASTER" ipaddress="192.168.1.100"/>
    <member role="SLAVE" ipaddress="192.168.1.101"/>
  </zone>'
```

**Solutions:**

1. **Devices not on same network:**
   - Verify all devices have same subnet
   - Check router settings

2. **Wrong IP addresses:**
   - Verify device IPs
   - Use actual device IPs, not server IP

3. **Devices not registered:**
   - Register all devices first
   - Check: `GET /account/default/devices`

## Performance Issues

### Slow Response Times

**Problem:** API calls take long time

**Solutions:**

1. **Check server resources:**
   ```bash
   # Check CPU/memory
   top
   ```

2. **Restart server:**
   ```bash
   # Stop and restart
   npm start
   ```

3. **Check network:**
   ```bash
   # Test latency
   ping DEVICE_IP
   ```

### High Memory Usage

**Problem:** Server using too much memory

**Solutions:**

1. **Restart server:**
   ```bash
   npm start
   ```

2. **Check for memory leaks:**
   - Monitor over time
   - Report issue if persistent

## Common Error Messages

### "Device ID required"

**Cause:** Registration request missing device ID

**Solution:**
- Ensure DeviceInfo.xml has `deviceID` attribute
- Check XML format: `<info deviceID="...">`

### "Device not found"

**Cause:** Device not registered with server

**Solution:**
```bash
# Register device
./scripts/configure-device-for-server.sh DEVICE_IP SERVER_URL

# Or check registered devices
curl http://localhost:8090/account/default/devices
```

### "Unable to resolve stream"

**Cause:** BMX cannot resolve TuneIn station

**Solution:**
- Verify station ID is valid
- Check internet connectivity
- Try direct stream URL instead

### "Parse failed"

**Cause:** Invalid XML in request

**Solution:**
- Check XML syntax
- Ensure proper encoding
- Use examples from `examples/` directory

## Getting Help

### Enable Debug Logging

Add to server startup:
```bash
DEBUG=* npm start
```

### Check Server Logs

Look for error messages in console output

### Test with curl

Test API endpoints directly:
```bash
# Test device info
curl http://localhost:8090/info?deviceId=device1

# Test presets
curl http://localhost:8090/presets?deviceId=device1

# Test registration
curl -X POST http://localhost:8090/device/register \
  -H "Content-Type: application/xml" \
  -H "X-Account-ID: default" \
  -d '<info deviceID="test"><name>Test</name></info>'
```

### Run Test Suite

```bash
./test-api.sh
```

### Use Test Script

```bash
./scripts/test-device-connection.sh DEVICE_IP SERVER_URL
```

## Still Having Issues?

1. Check documentation:
   - README.md
   - DEVICE_CONFIGURATION_GUIDE.md
   - API_REFERENCE.md

2. Review examples:
   - examples/test-preset-button.sh
   - examples/configure-webradio-presets.sh

3. Check server is running:
   ```bash
   curl http://localhost:8090/account/default/devices
   ```

4. Verify device connectivity:
   ```bash
   curl http://DEVICE_IP:8090/info
   ```

5. Test with Web UI:
   - Open http://localhost:8090
   - Try operations through UI
   - Check browser console for errors
