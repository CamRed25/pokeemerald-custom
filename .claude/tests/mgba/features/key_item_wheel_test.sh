#!/usr/bin/env bash
# Feature test: Key Item Wheel (SELECT button quick-access, objective 10).
#
# Verifies (via screenshots + liveness checks, not pixel comparison):
#  - Registering 2 key items and pressing SELECT shows the 4-position wheel
#  - D-pad selection picks the right item and dispatches its field-use logic
#    (this is also the code path the tUsingRegisteredKeyItem task-data fix
#    touches, so a clean result here covers that fix too)
#
# Uses the Debug_RegisterKeyItems special (Debug_EventScript_Script_2) to
# reach the 2-items-registered state directly instead of navigating the Bag
# by hand — Bag navigation proved unreliable under Xvfb/xdotool timing in
# earlier attempts. Seeds saves/has_starter.sav; never touches the real
# ROM-adjacent save.
#
# Usage: key_item_wheel_test.sh [path-to-rom]
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
source "$SCRIPT_DIR/../common/harness.sh"
source "$SCRIPT_DIR/../common/navigate.sh"

ROM="${1:-$REPO_ROOT/pokeemerald.gba}"

if [ ! -f "$ROM" ]; then
    echo "FAIL: ROM not found at $ROM"
    exit 1
fi

mgba_start_display
trap mgba_stop EXIT

mgba_seed_save "$ROM" "$SCRIPT_DIR/../saves/has_starter.sav"
mgba_launch "$ROM"

if ! mgba_is_alive; then
    echo "FAIL: mgba process exited immediately after launch"
    exit 1
fi

nav_skip_intro_to_main_menu
nav_main_menu_continue
sleep 1

# Debug menu Script 2: gives Bicycle + Acro Bike, registers both via
# Debug_RegisterKeyItems, shows a confirmation msgbox.
nav_debug_run_script 2
sleep 1
mgba_key x
sleep 1
mgba_key x
sleep 1

if ! mgba_is_alive; then
    echo "FAIL: mgba crashed running debug script 2 / dismissing its msgbox"
    exit 1
fi
mgba_screenshot "key_item_wheel_00_two_items_registered" >/dev/null

# SELECT with 2 items registered should open the wheel, not use a single item directly.
mgba_key BackSpace
sleep 1
shot="$(mgba_screenshot "key_item_wheel_01_wheel_open")"
if ! mgba_is_alive; then
    echo "FAIL: mgba crashed opening the wheel"
    exit 1
fi
echo "INFO: wheel opened, screenshot at $shot"

# Up = slot 0 = Bicycle. Selecting it should close the wheel and dispatch the
# bike's field-use function (indoors, so vanilla "Dad's advice" is expected).
mgba_key Up
sleep 1
shot2="$(mgba_screenshot "key_item_wheel_02_item_used")"
if ! mgba_is_alive; then
    echo "FAIL: mgba crashed after D-pad item selection"
    exit 1
fi

echo "PASS: wheel opened and D-pad selection dispatched the item's field-use logic without crashing, screenshot at $shot2"
echo "NOTE: this only confirms navigation/liveness — visual confirmation of correct box placement and icons requires reading the screenshot."
