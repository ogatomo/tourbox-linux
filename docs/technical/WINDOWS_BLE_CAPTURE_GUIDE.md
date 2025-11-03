# Windows 10 Bluetooth Logging Guide

This guide explains how to capture BLE traffic from TourBox Console using Windows 10's built-in Bluetooth logging.

## Step 1: Enable Windows Bluetooth Logging

On your **Windows 10 machine**:

1. Open **Command Prompt as Administrator**
   - Press Windows key, type "cmd"
   - Right-click "Command Prompt" → "Run as administrator"

2. Start Bluetooth logging:
```cmd
logman start bth_hci -ow -o %TEMP%\bth_hci.etl -p {8a1f9517-3a8c-4a9e-a018-4f17a200f277} 0xffffffff 0xff -ets
```

3. You should see: `The command completed successfully.`

## Step 2: Capture the TourBox Initialization

1. Make sure TourBox Elite is powered on and in range
2. Open **TourBox Console** app
3. Let it connect and initialize the device
4. Interact with the device briefly (press some buttons to confirm it's working)
5. Wait about 30 seconds to ensure everything is captured

## Step 3: Stop Logging

Back in the **Administrator Command Prompt**:

```cmd
logman stop bth_hci -ets
```

## Step 4: Locate the Log File

The log file is at: `%TEMP%\bth_hci.etl`

To find it:
```cmd
echo %TEMP%
```

Usually it's something like: `C:\Users\YourName\AppData\Local\Temp\bth_hci.etl`

## Step 5: Analyze with Wireshark

1. **Install Wireshark on Windows** (if not already installed)
   - Download from: https://www.wireshark.org/download.html

2. **Open the ETL file**:
   - File → Open → browse to `bth_hci.etl`

3. **Filter for your TourBox**:
   - In the filter bar, try: `bluetooth` or `bthatt`
   - Look for your device address (D9:BE:1E:CC:40:D7 or similar)

4. **Look for GATT Write operations**:
   - Look for "ATT Write Request" or "Write Command"
   - Focus on the **first few packets after connection**
   - The unlock command should be in the first few writes

## What to Look For

In the Wireshark capture, you're looking for:
- **Write operations** to GATT characteristics (especially service fff0)
- **Early initialization packets** sent right after connection
- The byte sequence that unlocks the device (before `<!not_allow_config!>` disappears)

The pattern should be:
```
Connect to device
Write to characteristic xxx: [BYTE SEQUENCE] ← This is the unlock command!
Device responds with OK or similar
Normal operation begins
```

## Troubleshooting

**If ETL file won't open in Wireshark:**
- Try BTETLParse tool: https://github.com/microsoft/BTETLParse
- Or use a hardware BLE sniffer instead (nRF52840 dongle)

**If you see no Bluetooth traffic:**
- Make sure you started logging BEFORE opening TourBox Console
- Verify TourBox Console actually connected to the device
- Try running the capture again

**If the log is too noisy:**
- Filter by device address: `bluetooth.addr == d9:be:1e:cc:40:d7`
- Filter for writes only: `bthatt.opcode.method == 0x12` or `bthatt.opcode.method == 0x52`

## Next Steps

Once you identify the unlock command bytes:
1. Copy the hex values
2. Return to Linux
3. Implement them in your Python driver using `bleak`
4. Test if the device responds without `<!not_allow_config!>`

## Alternative: Hardware BLE Sniffer

If Windows logging doesn't work well, consider buying an nRF52840 USB dongle (~$10-15):
- Search Amazon for "nRF52840 dongle"
- Works with Nordic's nRF Sniffer + Wireshark
- Passively captures all BLE traffic
- More reliable for reverse engineering
