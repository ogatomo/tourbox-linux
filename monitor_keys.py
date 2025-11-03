#!/usr/bin/env python3
"""Monitor TourBox key events to debug stuck keys"""

import sys
import struct
from evdev import ecodes

def monitor_device(device_path):
    """Monitor key events from device"""

    # Event struct format: timeval (2 longs), type (short), code (short), value (int)
    # On 64-bit: 16 bytes (timeval) + 2 + 2 + 4 = 24 bytes
    event_format = 'llHHI'
    event_size = struct.calcsize(event_format)

    print(f"Monitoring {device_path}")
    print("Press TourBox buttons and watch for KEY_B and KEY_E events")
    print("Look for stuck keys (PRESS without RELEASE)\n")

    try:
        with open(device_path, 'rb') as device:
            while True:
                data = device.read(event_size)
                if len(data) < event_size:
                    break

                tv_sec, tv_usec, ev_type, ev_code, ev_value = struct.unpack(event_format, data)

                if ev_type == ecodes.EV_KEY:
                    key_name = ecodes.KEY.get(ev_code, f"KEY_{ev_code}")

                    # Only show B, E, and modifier keys
                    if ev_code in [ecodes.KEY_B, ecodes.KEY_E, ecodes.KEY_LEFTCTRL, ecodes.KEY_LEFTSHIFT, ecodes.KEY_LEFTALT]:
                        if ev_value == 1:
                            print(f"⬇️  {key_name:20s} PRESS")
                        elif ev_value == 0:
                            print(f"⬆️  {key_name:20s} RELEASE")

    except KeyboardInterrupt:
        print("\nExiting...")
    except PermissionError:
        print(f"\n❌ Permission denied. Run with sudo:")
        print(f"   sudo ./venv/bin/python {sys.argv[0]}")
        sys.exit(1)

if __name__ == '__main__':
    monitor_device('/dev/input/event15')
