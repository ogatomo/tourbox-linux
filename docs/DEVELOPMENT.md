# TourBox Elite Driver - Development Guide

This guide is for developers who want to work on, debug, or contribute to the TourBox Elite driver.

## 📋 Table of Contents

- [Development Setup](#development-setup)
- [Running the Driver](#running-the-driver)
- [Debugging](#debugging)
- [Project Structure](#project-structure)
- [Development Workflow](#development-workflow)
- [Testing](#testing)
- [Contributing](#contributing)

## 🛠️ Development Setup

### Installation

For complete installation instructions including prerequisites, system dependencies, and setup, see the [README.md](../README.md).

The README covers:
- System requirements and dependencies
- Finding your TourBox MAC address
- Installation via `install.sh`
- Manual installation steps
- Additional requirements for KDE Plasma and GNOME

### Developer-Specific Setup

For development work, install the package in editable mode:

```bash
# Navigate to repository
cd /path/to/tourboxelite

# Install in editable/development mode
./venv/bin/pip install -e .
```

This allows you to modify the code and test changes without reinstalling the package.

## 🚀 Running the Driver

### Running Directly (Recommended for Development)

Stop the systemd service first to avoid conflicts:

```bash
# Stop the service if it's running
systemctl --user stop tourbox
```

Run directly in your terminal:

```bash
# Basic run
./venv/bin/python -m tourboxelite.device_ble

# With verbose logging (shows all button events)
./venv/bin/python -m tourboxelite.device_ble -v

# Specify MAC address via command line (overrides config)
./venv/bin/python -m tourboxelite.device_ble D9:BE:1E:CC:40:D7

# Specify custom config file
./venv/bin/python -m tourboxelite.device_ble -c /path/to/custom/config.conf

# Combine options
./venv/bin/python -m tourboxelite.device_ble -v -c custom.conf
```

**Press `Ctrl+C` to stop.**

### Running as a Service (Production Mode)

```bash
# Start service
systemctl --user start tourbox

# View live logs
journalctl --user -u tourbox -f

# Stop service
systemctl --user stop tourbox

# Restart service (after code changes)
systemctl --user restart tourbox
```

### Command Line Options

```bash
./venv/bin/python -m tourboxelite.device_ble --help
```

Available options:
- `mac_address` - Bluetooth MAC address (optional, overrides config file)
- `-c, --config` - Path to custom config file
- `-v, --verbose` - Enable verbose/debug logging

## 🐛 Debugging

### Verbose Logging

Enable verbose logging to see detailed button events:

```bash
./venv/bin/python -m tourboxelite.device_ble -v
```

Output shows:
- Button press/release events with hex codes
- Profile switching events
- Window focus changes
- BLE connection status
- Input event generation

Example output:
```
2025-11-01 21:56:19,217 - tourboxelite.config_loader - INFO - Loading profiles from /home/scott/.config/tourbox/mappings.conf
2025-11-01 21:56:19,218 - __main__ - INFO - Loaded 4 profiles
2025-11-01 21:56:19,234 - tourboxelite.window_monitor - INFO - Detected Wayland compositor: kde
2025-11-01 21:56:19,234 - __main__ - INFO - Connecting to TourBox Elite at D9:BE:1E:CC:40:D7...

Button #1: 44 -> 4 events  # Knob CW rotation
Button #2: c4 -> 2 events  # Knob CW stop
```

### Debug Button Codes

To see raw button codes without mapping them, use the test script:

```bash
# Stop the service first
systemctl --user stop tourbox

# Run the BLE test script
cd /path/to/tourboxelite
./venv/bin/python ble_test_tourbox.py

# Press buttons and observe hex codes
# Press Ctrl+C when done

# Restart the service
systemctl --user start tourbox
```

See the [BUTTON_MAPPING_GUIDE.md](BUTTON_MAPPING_GUIDE.md) for complete instructions on capturing and documenting button codes.

### Test Window Detection

Test window focus detection without running the full driver:

```bash
./venv/bin/python -m tourboxelite.window_monitor
```

This shows:
- Current focused window
- Window class/app_id
- Window title
- Which profile would be activated

### Monitor Bluetooth Events

```bash
# Watch Bluetooth logs
journalctl -f | grep -i blue

# Monitor BLE connection
bluetoothctl
# Then: info D9:BE:1E:CC:40:D7
```

### Check Input Device

```bash
# List input devices (TourBox should appear when driver is running)
ls -la /dev/input/by-id/

# Monitor events from TourBox
sudo evtest
# Select "TourBox Elite" from the list
```

## 📁 Project Structure

```
tourboxelite/
├── tourboxelite/              # Main package
│   ├── __init__.py           # Version info
│   ├── device_ble.py         # Main BLE driver (TourBoxBLE class)
│   ├── config_loader.py      # Config file parsing and profile management
│   ├── window_monitor.py     # Wayland window detection
│   └── default_mappings.conf # Default configuration template
├── docs/                     # Documentation
│   ├── CONFIG_GUIDE.md       # Configuration documentation
│   ├── DEVELOPMENT.md        # This file
│   ├── BUTTON_MAPPING_GUIDE.md  # Button reference for protocol work
│   └── technical/            # Technical documentation
│       ├── TOURBOX_ELITE_PROTOCOL_SOLVED.md  # BLE protocol docs
│       ├── KDOTOOL_INFO.md   # KDE window detection info
│       ├── LOG_MANAGEMENT.md # Logging documentation
│       └── WINDOWS_BLE_CAPTURE_GUIDE.md  # Windows BLE capture guide
├── ble_test_tourbox.py       # BLE test script for capturing button codes
├── ble_test_events.py        # Test script for BLE events
├── monitor_keys.py           # Utility to monitor key events
├── install.sh                # Installation script
├── uninstall.sh             # Uninstallation script
├── install_config.sh        # Config installer (for manual setup)
├── setup.py                  # Python package setup
├── setup.cfg                 # Python package metadata
├── requirements.txt          # Python dependencies
├── LICENSE.txt               # License file
└── README.md                 # User documentation
```

### Key Files

**`device_ble.py`** - Main driver logic
- `TourBoxBLE` class - Main driver
- BLE connection handling
- Button event processing
- Profile switching
- Virtual input device creation

**`config_loader.py`** - Configuration
- Parse INI config files
- Profile management
- Button mapping creation
- Button code definitions
- Capability detection

**`window_monitor.py`** - Window detection (Wayland)
- KDE/Plasma support (KWin via D-Bus)
- GNOME support (Mutter via D-Bus extension)
- Sway support
- Hyprland support

**`ble_test_tourbox.py`** - BLE test script
- Captures raw button codes
- Used for reverse engineering protocol
- See BUTTON_MAPPING_GUIDE.md

## 🔄 Development Workflow

### Making Changes

1. **Stop the service** to avoid conflicts:
   ```bash
   systemctl --user stop tourbox
   ```

2. **Make your changes** to the code

3. **Test directly** with verbose logging:
   ```bash
   ./venv/bin/python -m tourboxelite.device_ble -v
   ```

4. **Test your changes** by pressing buttons on the TourBox

5. **Verify** the output shows expected behavior

6. **Restart service** when done testing:
   ```bash
   systemctl --user restart tourbox
   ```

### Editing Configuration

```bash
# Edit config
nano ~/.config/tourbox/mappings.conf

# Test changes immediately
./venv/bin/python -m tourboxelite.device_ble -v

# Or restart service
systemctl --user restart tourbox
```

### Adding New Button Mappings

1. **Find the button code** - Run with verbose mode and press the button:
   ```bash
   ./venv/bin/python -m tourboxelite.device_ble -v
   # Press the button
   # Look for: "Unknown button code: XX" or "Button #N: XX -> Y events"
   ```

2. **Add to `config_loader.py`** in the `BUTTON_CODES` dict:
   ```python
   BUTTON_CODES = {
       'new_button': (0xXX, 0xYY),  # press, release
       # or for rotary:
       'new_rotary_cw': (0xXX, 0xYY),  # rotate, stop
   }
   ```

3. **Add to config file** `default_mappings.conf`:
   ```ini
   [buttons]
   new_button = KEY_SOMETHING

   [rotary]
   new_rotary_cw = KEY_VOLUMEUP
   ```

4. **Test** the new mapping

### Adding New Keys

If you need a key that's not in `KEY_NAMES`:

1. **Find the evdev key code**:
   ```python
   import evdev.ecodes as e
   print(e.KEY_YOURKEY)  # Get the code
   ```

2. **Add to `config_loader.py`** in the `KEY_NAMES` dict:
   ```python
   KEY_NAMES = {
       'KEY_YOURKEY': e.KEY_YOURKEY,
   }
   ```

3. **Use in config**:
   ```ini
   side = KEY_YOURKEY
   ```

### Adding Profile Support for New Compositor

Edit `window_monitor.py`:

1. **Detect the compositor** in `detect_compositor()`:
   ```python
   def detect_compositor():
       # Add detection logic
       if os.environ.get('YOUR_COMPOSITOR_VAR'):
           return 'your_compositor'
   ```

2. **Implement window monitoring**:
   ```python
   async def monitor_your_compositor(self):
       # Implement window focus detection
       # Call self.callback(window_info) when window changes
   ```

3. **Add to `start_monitoring()`**:
   ```python
   if self.compositor == 'your_compositor':
       await self.monitor_your_compositor()
   ```

## 🧪 Testing

### Manual Testing Checklist

- [ ] All buttons respond correctly
- [ ] Rotary controls (knob, scroll, dial) work smoothly
- [ ] Keys don't get stuck when rotating knobs
- [ ] Profile switching works (if using Wayland)
- [ ] Window detection is accurate
- [ ] Service starts on login
- [ ] Config changes apply after restart
- [ ] Driver reconnects after TourBox power cycle

### Test Profile Switching

```bash
# Run with verbose logging
./venv/bin/python -m tourboxelite.device_ble -v

# Switch between applications (VSCode, Firefox, etc.)
# Watch console for profile switch messages:
# "🎮 Switched to profile: vscode"
```

### Test Button Events

```bash
# Run driver
./venv/bin/python -m tourboxelite.device_ble -v

# In another terminal, monitor input events
sudo evtest
# Select "TourBox Elite"
# Press buttons and verify events are generated
```

### Test Configuration Parsing

```python
# Quick test in Python
from tourboxelite.config_loader import load_profiles

profiles = load_profiles('~/.config/tourbox/mappings.conf')
for p in profiles:
    print(f"Profile: {p.name}")
    print(f"  Mapping: {p.mapping}")
```

## 🔬 Reverse Engineering & Protocol Work

### Button Mapping Guide

If you're working on supporting a new TourBox model or reverse-engineering the protocol, see [BUTTON_MAPPING_GUIDE.md](BUTTON_MAPPING_GUIDE.md).

This guide explains how to:
- Discover which raw BLE hex codes correspond to physical buttons
- Map button codes to Linux input events
- Test and document a new TourBox device
- Contribute protocol documentation

**Note:** This is a developer guide for protocol work, not for end users configuring their buttons (that's [CONFIG_GUIDE.md](CONFIG_GUIDE.md)).

### Protocol Documentation

See [TOURBOX_ELITE_PROTOCOL_SOLVED.md](technical/TOURBOX_ELITE_PROTOCOL_SOLVED.md) for complete BLE protocol documentation.

## 🔍 Common Development Tasks

### Capture Raw Button Data

```python
# Temporarily add to device_ble.py handle_button_event():
def handle_button_event(self, sender: int, data: bytearray):
    data_bytes = bytes(data)
    print(f"RAW: {data_bytes.hex()}")  # See all raw data
```

### Test BLE Connection Only

```python
# Simple test script
import asyncio
from bleak import BleakClient

async def test_connection():
    mac = "D9:BE:1E:CC:40:D7"
    async with BleakClient(mac) as client:
        print(f"Connected: {client.is_connected}")
        services = await client.get_services()
        for service in services:
            print(f"Service: {service.uuid}")

asyncio.run(test_connection())
```

### Dump Current Config

```bash
# See effective configuration
cat ~/.config/tourbox/mappings.conf

# Or parse it programmatically
./venv/bin/python -c "
from tourboxelite.config_loader import load_profiles
import pprint
profiles = load_profiles()
for p in profiles:
    print(f'\n{p.name}:')
    pprint.pprint(p.mapping)
"
```

### Check Dependencies

```bash
# List installed packages
./venv/bin/pip list

# Check specific package version
./venv/bin/pip show bleak
```

## 📝 Code Style

- Follow PEP 8 style guidelines
- Use type hints where appropriate
- Add docstrings to functions and classes
- Keep functions focused and concise
- Add comments for complex logic

Example:
```python
async def handle_button_event(self, sender: int, data: bytearray):
    """Handle button press/release events from TourBox

    Args:
        sender: GATT characteristic handle
        data: Raw button data (1 byte indicating button/state)
    """
    # Implementation
```

## 🤝 Contributing

### Before Submitting

1. Test your changes thoroughly
2. Update documentation if needed
3. Follow existing code style
4. Add comments for non-obvious code
5. Test with both simple mode and profile mode

### Commit Messages

Use clear, descriptive commit messages:
```
Good:
- "Fix rotary control key release for knob zoom"
- "Add support for Hyprland window detection"
- "Update config parser to handle inline comments"

Bad:
- "fix bug"
- "update"
- "changes"
```

## 🆘 Getting Help

### Enable Maximum Logging

```python
# Edit device_ble.py main():
logging.basicConfig(
    level=logging.DEBUG,  # Change from INFO to DEBUG
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
```

### Common Issues

**"No module named 'tourboxelite'"**
```bash
# Install in editable mode
./venv/bin/pip install -e .
```

**"Permission denied: /run/tourbox.pid"**
```bash
# Use user runtime directory (already fixed in code)
# Or set manually:
pidfile=/tmp/tourbox.pid ./venv/bin/python -m tourboxelite.device_ble
```

**"Connection failed"**
- Check TourBox is powered on
- Check Bluetooth is enabled: `bluetoothctl power on`
- Try pairing: `bluetoothctl pair D9:BE:1E:CC:40:D7`
- Check MAC address is correct in config

**Keys get stuck after rotation**
- This was fixed - make sure you have latest `config_loader.py`
- Rotary controls should have stop events: `(0x44, 0xc4)`

## 📚 Additional Resources

- [Bleak Documentation](https://bleak.readthedocs.io/) - Python BLE library
- [evdev Documentation](https://python-evdev.readthedocs.io/) - Linux input events
- [D-Bus Tutorial](https://dbus.freedesktop.org/doc/dbus-tutorial.html) - For window detection
- [systemd Service Guide](https://www.freedesktop.org/software/systemd/man/systemd.service.html)

## 📄 License

MIT License - See [LICENSE.txt](../LICENSE.txt) file for details.
