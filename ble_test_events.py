#!/usr/bin/env python3
"""Test script to list TourBox Elite device"""

import sys
from evdev import InputDevice, ecodes, list_devices

def find_tourbox_device():
    """Find and display TourBox Elite device info"""

    # Find TourBox Elite device
    devices = [InputDevice(path) for path in list_devices()]
    tourbox = None

    print("Available input devices:")
    for device in devices:
        print(f"  - {device.name}: {device.path}")
        if 'TourBox Elite' in device.name:
            tourbox = device

    if not tourbox:
        print("\n❌ TourBox Elite device not found!")
        sys.exit(1)

    print(f"\n✅ Found TourBox Elite: {tourbox.path}")
    print(f"\nTo monitor events, run:")
    print(f"  sudo cat {tourbox.path} | hexdump -C")
    print(f"\nOr use:")
    print(f"  sudo evtest {tourbox.path}")
    print(f"\nOr use libinput:")
    print(f"  sudo libinput debug-events --device {tourbox.path}")

if __name__ == '__main__':
    find_tourbox_device()
