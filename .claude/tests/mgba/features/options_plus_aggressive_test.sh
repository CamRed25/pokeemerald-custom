#!/usr/bin/env bash
# Aggressive crash test: rapid option toggling and edge cases.
#
# Tests more extreme scenarios:
# - Rapid consecutive toggles
# - Toggling multiple options in sequence
# - Saving after toggles
# - Re-entering the menu multiple times
#
# Usage: options_plus_aggressive_test.sh [path-to-rom]
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

echo "=== Aggressive Options Plus Crash Test ==="
echo "ROM: $ROM"
echo ""

mgba_start_display
trap mgba_stop EXIT

mgba_seed_save "$ROM" "$SCRIPT_DIR/../saves/has_starter.sav"
mgba_launch "$ROM"

mgba_is_alive || { echo "FAIL: Process died at launch"; exit 1; }

nav_skip_intro_to_main_menu
mgba_is_alive || { echo "FAIL: Process died during intro"; exit 1; }

nav_main_menu_to_options
mgba_is_alive || { echo "FAIL: Process died opening options"; exit 1; }

shot="$(mgba_screenshot "aggressive_01_initial")"
echo "[SCREENSHOT] Initial state: $shot"

# Test 1: Rapid down scrolling through entire menu
echo "[TEST 1] Rapid scrolling down through menu..."
for i in {1..10}; do
    mgba_key Down 0.1 0.3
    if ! mgba_is_alive; then
        echo "CRASH: Process died during down scroll iteration $i"
        exit 1
    fi
done
echo "[OK] Survived rapid down scrolling"

# Test 2: Rapid up scrolling back
echo "[TEST 2] Rapid scrolling up..."
for i in {1..10}; do
    mgba_key Up 0.1 0.3
    if ! mgba_is_alive; then
        echo "CRASH: Process died during up scroll iteration $i"
        exit 1
    fi
done
echo "[OK] Survived rapid up scrolling"

shot="$(mgba_screenshot "aggressive_02_after_scrolling")"
echo "[SCREENSHOT] After scrolling: $shot"

# Test 3: Rapid toggling of same option
echo "[TEST 3] Rapid toggling Match Calls (should be on top rows)..."
# Move to Battle Style
mgba_key Up 0.15 1
mgba_key Up 0.15 1
mgba_key Up 0.15 1
mgba_key Up 0.15 1
if ! mgba_is_alive; then
    echo "CRASH: Process died moving to Battle Style"
    exit 1
fi

# Move to Match Calls
mgba_key Down 0.15 1
if ! mgba_is_alive; then
    echo "CRASH: Process died moving to Match Calls"
    exit 1
fi

# Rapid toggle
echo "[INNER] Rapid toggling Match Calls 10 times..."
for i in {1..10}; do
    if [ $((i % 2)) -eq 0 ]; then
        mgba_key Right 0.1 0.2
    else
        mgba_key Left 0.1 0.2
    fi
    if ! mgba_is_alive; then
        echo "CRASH: Process died on Match Calls toggle $i"
        exit 1
    fi
done
echo "[OK] Match Calls survived 10 rapid toggles"

shot="$(mgba_screenshot "aggressive_03_after_match_calls_toggles")"
echo "[SCREENSHOT] After Match Calls toggles: $shot"

# Test 4: Move to Catch Mode and rapidly toggle it
echo "[TEST 4] Rapid toggling Catch Mode..."
mgba_key Down 0.15 1
mgba_key Down 0.15 1
mgba_key Down 0.15 1
if ! mgba_is_alive; then
    echo "CRASH: Process died moving to Catch Mode"
    exit 1
fi

for i in {1..10}; do
    if [ $((i % 2)) -eq 0 ]; then
        mgba_key Right 0.1 0.2
    else
        mgba_key Left 0.1 0.2
    fi
    if ! mgba_is_alive; then
        echo "CRASH: Process died on Catch Mode toggle $i"
        exit 1
    fi
done
echo "[OK] Catch Mode survived 10 rapid toggles"

shot="$(mgba_screenshot "aggressive_04_after_catch_mode_toggles")"
echo "[SCREENSHOT] After Catch Mode toggles: $shot"

# Test 5: Toggle every option in quick succession
echo "[TEST 5] Toggling all options in sequence..."
for row in {1..4}; do
    mgba_key Right 0.1 0.3
    if ! mgba_is_alive; then
        echo "CRASH: Process died toggling option row $row"
        exit 1
    fi
    mgba_key Down 0.15 0.3
    if ! mgba_is_alive; then
        echo "CRASH: Process died moving to next option after row $row"
        exit 1
    fi
done
echo "[OK] Toggled all options without crash"

shot="$(mgba_screenshot "aggressive_05_after_all_toggles")"
echo "[SCREENSHOT] After toggling all options: $shot"

# Test 6: Try to save/confirm options
echo "[TEST 6] Navigating to Save and confirming..."
mgba_key Down 0.15 1
if ! mgba_is_alive; then
    echo "CRASH: Process died moving to Save"
    exit 1
fi

mgba_key x 0.15 2
if ! mgba_is_alive; then
    echo "CRASH: Process died pressing A on Save"
    exit 1
fi

shot="$(mgba_screenshot "aggressive_06_after_save")"
echo "[SCREENSHOT] After pressing Save: $shot"

# Test 7: Re-enter the menu
echo "[TEST 7] Re-entering Options Plus menu..."
nav_main_menu_to_options
mgba_is_alive || { echo "CRASH: Process died re-entering options menu"; exit 1; }

shot="$(mgba_screenshot "aggressive_07_re_entered_menu")"
echo "[SCREENSHOT] Re-entered menu: $shot"

# Test 8: Do the same toggle sequence again
echo "[TEST 8] Repeating toggle sequence..."
mgba_key Down 0.15 1
mgba_key Down 0.15 1
mgba_key Down 0.15 1
if ! mgba_is_alive; then
    echo "CRASH: Process died navigating second time"
    exit 1
fi

mgba_key Right 0.15 1
if ! mgba_is_alive; then
    echo "CRASH: Process died toggling second time"
    exit 1
fi

mgba_key z 0.15 2
if ! mgba_is_alive; then
    echo "CRASH: Process died exiting second time"
    exit 1
fi

echo ""
echo "=== Test Complete ==="
echo "PASS: Completed aggressive toggle sequence without crash"
