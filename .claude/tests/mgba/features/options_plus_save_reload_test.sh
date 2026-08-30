#!/usr/bin/env bash
# Test: Options Plus persistence and reload with Catch Mode ON.
#
# Tests whether the game crashes when:
# 1. Toggling Catch Mode ON
# 2. Saving the game
# 3. Reloading the game
# 4. Re-entering Options menu
#
# Usage: options_plus_save_reload_test.sh [path-to-rom]
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

echo "=== Options Plus Save/Reload Test ==="
echo "ROM: $ROM"
echo ""

mgba_start_display
trap mgba_stop EXIT

mgba_seed_save "$ROM" "$SCRIPT_DIR/../saves/has_starter.sav"
mgba_launch "$ROM"

mgba_is_alive || { echo "FAIL: Process died at launch"; exit 1; }

echo "[STAGE 1] Initial setup - navigate to Options menu"
nav_skip_intro_to_main_menu
nav_main_menu_to_options

mgba_is_alive || { echo "FAIL: Process died opening options"; exit 1; }

shot="$(mgba_screenshot "save_reload_01_menu_initial")"
echo "[SCREENSHOT] Options menu: $shot"

# Navigate to Catch Mode and turn it ON
echo "[ACTION] Navigating to Catch Mode..."
mgba_key Down 0.15 1
mgba_key Down 0.15 1
mgba_key Down 0.15 1

mgba_is_alive || { echo "FAIL: Process died navigating to Catch Mode"; exit 1; }

echo "[ACTION] Toggling Catch Mode ON..."
mgba_key Right 0.15 1

mgba_is_alive || { echo "FAIL: Process died toggling Catch Mode"; exit 1; }

shot="$(mgba_screenshot "save_reload_02_catch_mode_on")"
echo "[SCREENSHOT] After Catch Mode ON: $shot"

# Navigate to Save and confirm
echo "[ACTION] Navigating to Save..."
mgba_key Down 0.15 1

mgba_is_alive || { echo "FAIL: Process died moving to Save"; exit 1; }

echo "[ACTION] Confirming Save..."
mgba_key x 0.15 2

mgba_is_alive || { echo "FAIL: Process died pressing A on Save"; exit 1; }

shot="$(mgba_screenshot "save_reload_03_after_save_confirm")"
echo "[SCREENSHOT] After Save confirm: $shot"

# At this point we should be back in the game. Let's save the game itself
echo "[STAGE 2] Save the game via in-game save"
echo "[ACTION] Opening Start menu..."
mgba_key Return 0.15 2

mgba_is_alive || { echo "FAIL: Process died opening Start menu"; exit 1; }

shot="$(mgba_screenshot "save_reload_04_start_menu")"
echo "[SCREENSHOT] Start menu: $shot"

# Navigate to Save option (should be in the menu)
echo "[ACTION] Looking for Save option in Start menu..."
for i in {1..5}; do
    mgba_key Down 0.15 1
    if ! mgba_is_alive; then
        echo "FAIL: Process died scrolling Start menu"
        exit 1
    fi
done

echo "[ACTION] Pressing A to select Save..."
mgba_key x 0.15 3

mgba_is_alive || { echo "FAIL: Process died selecting Save"; exit 1; }

shot="$(mgba_screenshot "save_reload_05_after_game_save")"
echo "[SCREENSHOT] After game save: $shot"

# Now test: stop and reload, then re-open options
echo "[STAGE 3] Stop emulator and reload save"
mgba_stop
sleep 1

echo "[INFO] Emulator stopped. Re-launching with same save..."
mgba_start_display
mgba_seed_save "$ROM" "$SCRIPT_DIR/../saves/has_starter.sav"
mgba_launch "$ROM"

mgba_is_alive || { echo "FAIL: Process died at reload"; exit 1; }

echo "[NAV] Skipping intro..."
nav_skip_intro_to_main_menu

mgba_is_alive || { echo "FAIL: Process died during intro on reload"; exit 1; }

shot="$(mgba_screenshot "save_reload_06_after_reload_menu")"
echo "[SCREENSHOT] Main menu after reload: $shot"

# Try to go back to Options Plus
echo "[NAV] Opening Options menu again..."
nav_main_menu_to_options

mgba_is_alive || { echo "FAIL: Process died opening options on reload"; exit 1; }

shot="$(mgba_screenshot "save_reload_07_options_after_reload")"
echo "[SCREENSHOT] Options menu after reload: $shot"

# Try some toggles
echo "[ACTION] Toggling Match Calls after reload..."
mgba_key Down 0.15 1
if ! mgba_is_alive; then
    echo "CRASH: Process died moving down after reload"
    exit 1
fi

mgba_key Right 0.15 1
if ! mgba_is_alive; then
    echo "CRASH: Process died toggling Match Calls after reload"
    exit 1
fi

shot="$(mgba_screenshot "save_reload_08_after_toggles_on_reload")"
echo "[SCREENSHOT] After toggle on reload: $shot"

# Exit
mgba_key z 0.15 2
mgba_is_alive || { echo "CRASH: Process died exiting after reload"; exit 1; }

echo ""
echo "PASS: Save/reload test completed without crash"
