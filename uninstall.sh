#!/bin/bash
# TuxBox TourBox Driver Uninstallation Script
# Handles both old (tourbox*) and new (tuxbox*) artifact names

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}TuxBox TourBox Driver Uninstallation${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Confirm uninstall
read -p "Are you sure you want to uninstall the TuxBox driver? (y/N): " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Uninstallation cancelled."
    exit 0
fi

# Check if systemd is available
HAS_SYSTEMD=false
if command -v systemctl &> /dev/null && systemctl --user status &> /dev/null; then
    HAS_SYSTEMD=true
fi

if [ "$HAS_SYSTEMD" = "true" ]; then
    # Stop and disable both old and new service names
    for SERVICE_NAME in tourbox tuxbox; do
        if systemctl --user is-active --quiet "$SERVICE_NAME" 2>/dev/null; then
            echo "Stopping $SERVICE_NAME service..."
            systemctl --user stop "$SERVICE_NAME"
            echo -e "${GREEN}✓${NC} $SERVICE_NAME service stopped"
        fi

        if systemctl --user is-enabled --quiet "$SERVICE_NAME" 2>/dev/null; then
            echo "Disabling $SERVICE_NAME service..."
            systemctl --user disable "$SERVICE_NAME"
            echo -e "${GREEN}✓${NC} $SERVICE_NAME service disabled"
        fi

        SERVICE_FILE="$HOME/.config/systemd/user/$SERVICE_NAME.service"
        if [ -f "$SERVICE_FILE" ]; then
            echo "Removing $SERVICE_NAME systemd service file..."
            rm "$SERVICE_FILE"
            echo -e "${GREEN}✓${NC} $SERVICE_NAME service file removed"
        fi
    done

    # Reload daemon once after removing service files
    systemctl --user daemon-reload
else
    # Non-systemd system - try to stop any running driver process (old and new module names)
    for PROC_PATTERN in "python.*tourboxelite" "python.*tuxbox"; do
        if pgrep -f "$PROC_PATTERN" > /dev/null 2>&1; then
            echo "Stopping driver process matching '$PROC_PATTERN'..."
            pkill -f "$PROC_PATTERN" 2>/dev/null || true
            echo -e "${GREEN}✓${NC} Driver process stopped"
        fi
    done
    echo -e "${YELLOW}!${NC} Non-systemd system - please remove any init scripts you created manually"
fi

# Ask about config files - handle both old and new config directory names
CONFIG_DIRS=()
for DIR_NAME in tourbox tuxbox; do
    DIR="$HOME/.config/$DIR_NAME"
    if [ -d "$DIR" ]; then
        CONFIG_DIRS+=("$DIR")
    fi
done

if [ ${#CONFIG_DIRS[@]} -gt 0 ]; then
    echo ""
    echo "Configuration directories found:"
    for CONFIG_DIR in "${CONFIG_DIRS[@]}"; do
        echo "  $CONFIG_DIR"
        PROFILES_DIR="$CONFIG_DIR/profiles"
        CONFIG_FILE="$CONFIG_DIR/config.conf"
        LEGACY_CONFIG_FILE="$CONFIG_DIR/mappings.conf"

        if [ -d "$PROFILES_DIR" ]; then
            PROFILE_COUNT=$(ls -1 "$PROFILES_DIR"/*.profile 2>/dev/null | wc -l)
            echo "    - $PROFILE_COUNT profile(s) in profiles/"
        fi
        [ -f "$CONFIG_FILE" ] && echo "    - config.conf (device settings)"
        [ -f "$LEGACY_CONFIG_FILE" ] && echo "    - mappings.conf (legacy config)"
    done

    read -p "Remove all configuration files? (y/N): " -n 1 -r
    echo ""

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        for CONFIG_DIR in "${CONFIG_DIRS[@]}"; do
            PROFILES_DIR="$CONFIG_DIR/profiles"
            CONFIG_FILE="$CONFIG_DIR/config.conf"
            LEGACY_CONFIG_FILE="$CONFIG_DIR/mappings.conf"

            # Remove profiles directory
            if [ -d "$PROFILES_DIR" ]; then
                rm -rf "$PROFILES_DIR"
                echo -e "${GREEN}✓${NC} Profiles directory removed: $PROFILES_DIR"
            fi
            # Remove config files
            [ -f "$CONFIG_FILE" ] && rm "$CONFIG_FILE"
            [ -f "$LEGACY_CONFIG_FILE" ] && rm "$LEGACY_CONFIG_FILE"
            # Remove any backup files
            rm -f "$CONFIG_DIR"/*.backup.* 2>/dev/null
            rm -f "$CONFIG_DIR"/*.legacy 2>/dev/null
            # Remove directory if empty
            rmdir "$CONFIG_DIR" 2>/dev/null || true
        done
        echo -e "${GREEN}✓${NC} Configuration removed"
    else
        echo -e "${YELLOW}!${NC} Configuration kept"
    fi
fi

# Remove PID files - both old and new names
for PID_NAME in tourbox tuxbox; do
    PID_FILE="${XDG_RUNTIME_DIR:-/tmp}/$PID_NAME.pid"
    if [ -f "$PID_FILE" ]; then
        rm "$PID_FILE"
        echo -e "${GREEN}✓${NC} PID file removed: $PID_FILE"
    fi
done

# Remove GUI launcher scripts - both old and new names
for LAUNCHER_NAME in tourbox-gui tuxbox-gui; do
    LAUNCHER_FILE="/usr/local/bin/$LAUNCHER_NAME"
    if [ -f "$LAUNCHER_FILE" ]; then
        echo "Removing GUI launcher: $LAUNCHER_FILE..."
        sudo rm "$LAUNCHER_FILE"
        echo -e "${GREEN}✓${NC} Launcher script removed: $LAUNCHER_FILE"
    fi
done

# Remove desktop entries - both old and new names
DESKTOP_REMOVED=false
for DESKTOP_NAME in tourbox-gui tuxbox-gui; do
    DESKTOP_FILE="/usr/share/applications/$DESKTOP_NAME.desktop"
    if [ -f "$DESKTOP_FILE" ]; then
        echo "Removing desktop entry: $DESKTOP_FILE..."
        sudo rm "$DESKTOP_FILE"
        echo -e "${GREEN}✓${NC} Desktop entry removed: $DESKTOP_FILE"
        DESKTOP_REMOVED=true
    fi
done
if [ "$DESKTOP_REMOVED" = "true" ]; then
    sudo update-desktop-database /usr/share/applications/ 2>/dev/null || true
fi

# Remove application icons - both old and new names
for ICON_NAME in tourbox-icon tuxbox-icon; do
    ICON_FILE="/usr/share/pixmaps/$ICON_NAME.png"
    if [ -f "$ICON_FILE" ]; then
        echo "Removing application icon: $ICON_FILE..."
        sudo rm "$ICON_FILE"
        echo -e "${GREEN}✓${NC} Application icon removed: $ICON_FILE"
    fi
done

# Get installation directory
INSTALL_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Ask about removing installation directory
echo ""
read -p "Remove installation directory ($INSTALL_DIR)? (y/N): " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${GREEN}✓ Uninstallation Complete!${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
    echo "Removing installation directory..."

    # We can't delete the directory while this script is running from it,
    # so we use exec to replace this process with a cleanup command
    cd /tmp
    exec sh -c "rm -rf '$INSTALL_DIR' && echo 'Installation directory removed.'"
else
    echo -e "${YELLOW}!${NC} Installation directory kept: $INSTALL_DIR"
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${GREEN}✓ Uninstallation Complete!${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
fi
