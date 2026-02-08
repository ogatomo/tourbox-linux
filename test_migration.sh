#!/bin/bash
# TuxBox Config Migration Test Script
# Tests that ~/.config/tourbox/ is properly migrated to ~/.config/tuxbox/

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

PASS=0
FAIL=0

pass() {
    echo -e "${GREEN}PASS${NC}: $1"
    PASS=$((PASS + 1))
}

fail() {
    echo -e "${RED}FAIL${NC}: $1"
    FAIL=$((FAIL + 1))
}

echo "=========================================="
echo "TuxBox Config Migration Test"
echo "=========================================="
echo ""

# Create a temporary HOME directory
TEMP_HOME=$(mktemp -d)
export HOME="$TEMP_HOME"
echo "Using temp HOME: $TEMP_HOME"
echo ""

# Get the project directory (where this script lives)
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# --- Test 1: Fresh install (no old config) ---
echo "--- Test 1: Fresh install (no old config dir) ---"

RESULT=$("$SCRIPT_DIR/venv/bin/python" -c "
from tuxbox.profile_io import get_config_dir
d = get_config_dir()
print(d)
")

# get_config_dir() returns the path but doesn't create it on fresh install.
# Directory creation happens later via create_initial_config().
# Migration should be a no-op when neither dir exists.
if [ ! -d "$TEMP_HOME/.config/tourbox" ]; then
    pass "No old config dir (expected for fresh install)"
else
    fail "Old config dir should not exist on fresh install"
fi

if echo "$RESULT" | grep -q "tuxbox"; then
    pass "get_config_dir() returns tuxbox path"
else
    fail "get_config_dir() did not return tuxbox path"
fi

echo ""

# --- Clean up for Test 2 ---
rm -rf "$TEMP_HOME/.config/tuxbox" "$TEMP_HOME/.config/tourbox"

# --- Test 2: Migration from old config ---
echo "--- Test 2: Migration from old config dir ---"

# Create fake old config tree
mkdir -p "$TEMP_HOME/.config/tourbox/profiles"

cat > "$TEMP_HOME/.config/tourbox/config.conf" <<'CONF'
[device]
mac_address = AA:BB:CC:DD:EE:FF
modifier_delay = 30
CONF

cat > "$TEMP_HOME/.config/tourbox/profiles/default.profile" <<'PROF'
# TourBox Elite Profile
[profile]
name = Default

[mappings]
side = KEY_A
top = KEY_B
PROF

cat > "$TEMP_HOME/.config/tourbox/profiles/tourbox_gui.profile" <<'PROF'
# TourBox Elite Profile
[profile]
name = TourBox GUI
window_class = tourbox-gui
app_id = tourbox-gui

[mappings]
side = KEY_C
top = KEY_D
PROF

echo "Created old config tree at ~/.config/tourbox/"

# Run migration by calling get_config_dir()
RESULT=$("$SCRIPT_DIR/venv/bin/python" -c "
from tuxbox.profile_io import get_config_dir
d = get_config_dir()
print(d)
")

# Check new dir exists
if [ -d "$TEMP_HOME/.config/tuxbox" ]; then
    pass "New config dir created after migration"
else
    fail "New config dir NOT created after migration"
fi

# Check old dir renamed to backup
if [ -d "$TEMP_HOME/.config/tourbox.pre-v3-backup" ]; then
    pass "Old config dir renamed to tourbox.pre-v3-backup"
else
    fail "Old config dir NOT renamed to backup"
fi

# Check old dir no longer exists under original name
if [ ! -d "$TEMP_HOME/.config/tourbox" ]; then
    pass "Old ~/.config/tourbox/ removed"
else
    fail "Old ~/.config/tourbox/ still exists (should be renamed)"
fi

# Check config.conf was copied
if [ -f "$TEMP_HOME/.config/tuxbox/config.conf" ]; then
    pass "config.conf copied to new dir"
else
    fail "config.conf NOT copied to new dir"
fi

# Check profiles dir was copied
if [ -d "$TEMP_HOME/.config/tuxbox/profiles" ]; then
    pass "profiles/ dir copied to new dir"
else
    fail "profiles/ dir NOT copied to new dir"
fi

# Check default.profile was copied
if [ -f "$TEMP_HOME/.config/tuxbox/profiles/default.profile" ]; then
    pass "default.profile copied"
else
    fail "default.profile NOT copied"
fi

# Check GUI profile was renamed
if [ -f "$TEMP_HOME/.config/tuxbox/profiles/tuxbox_gui.profile" ]; then
    pass "tourbox_gui.profile renamed to tuxbox_gui.profile"
else
    fail "GUI profile NOT renamed (expected tuxbox_gui.profile)"
fi

# Check old GUI profile name is gone in new dir
if [ ! -f "$TEMP_HOME/.config/tuxbox/profiles/tourbox_gui.profile" ]; then
    pass "Old GUI profile name removed from new dir"
else
    fail "Old tourbox_gui.profile still exists in new dir"
fi

# Check GUI profile content was updated
if [ -f "$TEMP_HOME/.config/tuxbox/profiles/tuxbox_gui.profile" ]; then
    # Check window_class updated
    if grep -q "window_class = tuxbox-gui" "$TEMP_HOME/.config/tuxbox/profiles/tuxbox_gui.profile"; then
        pass "GUI profile window_class updated to tuxbox-gui"
    else
        fail "GUI profile window_class NOT updated"
    fi

    # Check app_id updated
    if grep -q "app_id = tuxbox-gui" "$TEMP_HOME/.config/tuxbox/profiles/tuxbox_gui.profile"; then
        pass "GUI profile app_id updated to tuxbox-gui"
    else
        fail "GUI profile app_id NOT updated"
    fi

    # Check profile name updated
    if grep -q "name = TuxBox GUI" "$TEMP_HOME/.config/tuxbox/profiles/tuxbox_gui.profile"; then
        pass "GUI profile name updated to TuxBox GUI"
    else
        fail "GUI profile name NOT updated"
    fi
fi

echo ""

# --- Clean up for Test 3 ---
rm -rf "$TEMP_HOME/.config/tuxbox" "$TEMP_HOME/.config/tourbox" "$TEMP_HOME/.config/tourbox.pre-v3-backup"

# --- Test 3: No migration when new dir already exists ---
echo "--- Test 3: No migration when new dir already exists ---"

# Create both old and new config dirs
mkdir -p "$TEMP_HOME/.config/tourbox/profiles"
mkdir -p "$TEMP_HOME/.config/tuxbox/profiles"

cat > "$TEMP_HOME/.config/tourbox/config.conf" <<'CONF'
[device]
mac_address = OLD:OLD:OLD:OLD:OLD:OLD
CONF

cat > "$TEMP_HOME/.config/tuxbox/config.conf" <<'CONF'
[device]
mac_address = NEW:NEW:NEW:NEW:NEW:NEW
CONF

# Run migration
RESULT=$("$SCRIPT_DIR/venv/bin/python" -c "
from tuxbox.profile_io import get_config_dir
d = get_config_dir()
print(d)
")

# Check that new config was NOT overwritten
if grep -q "NEW:NEW:NEW:NEW:NEW:NEW" "$TEMP_HOME/.config/tuxbox/config.conf"; then
    pass "Existing new config NOT overwritten"
else
    fail "Existing new config was overwritten by migration!"
fi

echo ""

# --- Cleanup ---
rm -rf "$TEMP_HOME"

# --- Summary ---
echo "=========================================="
TOTAL=$((PASS + FAIL))
echo "Results: $PASS/$TOTAL passed"
if [ $FAIL -gt 0 ]; then
    echo -e "${RED}$FAIL test(s) FAILED${NC}"
    exit 1
else
    echo -e "${GREEN}All tests passed!${NC}"
    exit 0
fi
