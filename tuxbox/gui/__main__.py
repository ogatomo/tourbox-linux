#!/usr/bin/env python3
"""Entry point for TuxBox Configuration GUI

Run with: python -m tuxbox.gui
"""

import sys
from .main_window import main

if __name__ == '__main__':
    sys.exit(main())
