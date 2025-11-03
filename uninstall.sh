#!/bin/bash
# TourBox Elite Driver Uninstallation Script

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}TourBox Elite Driver Uninstallation${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Confirm uninstall
read -p "Are you sure you want to uninstall the TourBox driver? (y/N): " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Uninstallation cancelled."
    exit 0
fi

# Stop service if running
if systemctl --user is-active --quiet tourbox 2>/dev/null; then
    echo "Stopping TourBox service..."
    systemctl --user stop tourbox
    echo -e "${GREEN}✓${NC} Service stopped"
fi

# Disable service if enabled
if systemctl --user is-enabled --quiet tourbox 2>/dev/null; then
    echo "Disabling TourBox service..."
    systemctl --user disable tourbox
    echo -e "${GREEN}✓${NC} Service disabled"
fi

# Remove systemd service file
SERVICE_FILE="$HOME/.config/systemd/user/tourbox.service"
if [ -f "$SERVICE_FILE" ]; then
    echo "Removing systemd service..."
    rm "$SERVICE_FILE"
    systemctl --user daemon-reload
    echo -e "${GREEN}✓${NC} Service file removed"
fi

# Ask about config file
CONFIG_FILE="$HOME/.config/tourbox/mappings.conf"
if [ -f "$CONFIG_FILE" ]; then
    echo ""
    read -p "Remove config file ($CONFIG_FILE)? (y/N): " -n 1 -r
    echo ""

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm "$CONFIG_FILE"
        # Remove directory if empty
        rmdir "$HOME/.config/tourbox" 2>/dev/null || true
        echo -e "${GREEN}✓${NC} Config file removed"
    else
        echo -e "${YELLOW}!${NC} Config file kept"
    fi
fi

# Ask about PID file
PID_FILE="${XDG_RUNTIME_DIR:-/tmp}/tourbox.pid"
if [ -f "$PID_FILE" ]; then
    rm "$PID_FILE"
    echo -e "${GREEN}✓${NC} PID file removed"
fi

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}✓ Uninstallation Complete!${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo "Note: The driver files remain in:"
echo "  $(dirname "${BASH_SOURCE[0]}")"
echo ""
echo "To remove completely:"
echo "  rm -rf $(dirname "${BASH_SOURCE[0]}")"
echo ""
