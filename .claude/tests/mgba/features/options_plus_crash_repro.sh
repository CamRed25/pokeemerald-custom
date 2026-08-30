#!/usr/bin/env bash
# Crash reproduction test: Options Plus menu toggle sequence.
#
# Reproduces user-reported crash when toggling options in Options Plus menu.
# Expected sequence: Catch Mode ON → Match Calls toggle → potential crash
#
# This test methodically executes each input and checks mgba_is_alive after
# every single keypress to pinpoint exactly which action kills the process.
#
# Usage: options_plus_crash_repro.sh [path-to-rom]
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

echo "=== Options Plus Crash Reproduction Test ==="
echo "ROM: $ROM"
echo ""

mgba_start_display
trap mgba_stop EXIT

mgba_seed_save "$ROM" "$SCRIPT_DIR/../saves/has_starter.sav"
echo "[INIT] Launching ROM with fixture save..."
mgba_launch "$ROM"

if ! mgba_is_alive; then
    echo "FAIL: mgba exited immediately after launch"
    exit 1
fi
echo "[OK] Process alive after launch"

echo "[NAV] Skipping intro to main menu..."
nav_skip_intro_to_main_menu

if ! mgba_is_alive; then
    echo "FAIL: mgba crashed during intro skip"
    exit 1
fi
echo "[OK] Process alive at main menu"

echo "[NAV] Navigating to Options menu..."
nav_main_menu_to_options

if ! mgba_is_alive; then
    echo "FAIL: mgba crashed opening Options menu"
    exit 1
fi
echo "[OK] Process alive in Options menu"

shot="$(mgba_screenshot "crash_repro_01_initial_state")"
echo "[SCREENSHOT] Initial Options Plus menu: $shot"

if ! mgba_is_alive; then
    echo "FAIL: mgba crashed taking initial screenshot"
    exit 1
fi

echo ""
echo "=== Beginning toggle sequence ==="
echo "(Checking mgba_is_alive after every single keypress)"
echo ""

# We start at Battle Style. Need to navigate down to Catch Mode.
# Expected menu order: Battle Style / Match Calls / Ball Prompt / [Catch Mode?] / Save
# Let's first move down and observe

echo "[ACTION] Moving cursor Down (from Battle Style toward Match Calls)..."
mgba_key Down 0.15 1
if ! mgba_is_alive; then
    echo "CRASH: Process died after first Down"
    exit 1
fi
echo "[OK] Alive after Down #1"

echo "[ACTION] Moving cursor Down (Match Calls → Ball Prompt)..."
mgba_key Down 0.15 1
if ! mgba_is_alive; then
    echo "CRASH: Process died after Down #2"
    exit 1
fi
echo "[OK] Alive after Down #2"

echo "[ACTION] Moving cursor Down (Ball Prompt → Catch Mode or Save)..."
mgba_key Down 0.15 1
if ! mgba_is_alive; then
    echo "CRASH: Process died after Down #3"
    exit 1
fi
echo "[OK] Alive after Down #3"

shot="$(mgba_screenshot "crash_repro_02_after_three_downs")"
echo "[SCREENSHOT] After moving down 3 times: $shot"

if ! mgba_is_alive; then
    echo "CRASH: Process died while taking screenshot"
    exit 1
fi

# Now try to toggle the current option (should be Catch Mode or Save).
# Use Right key to toggle (typical for binary options).
echo "[ACTION] Pressing Right to toggle current option..."
mgba_key Right 0.15 1
if ! mgba_is_alive; then
    echo "CRASH: Process died after Right toggle"
    exit 1
fi
echo "[OK] Alive after Right toggle"

shot="$(mgba_screenshot "crash_repro_03_after_toggle")"
echo "[SCREENSHOT] After Right toggle: $shot"

if ! mgba_is_alive; then
    echo "CRASH: Process died while taking screenshot"
    exit 1
fi

# Now navigate back up to Match Calls
echo "[ACTION] Moving cursor Up (back toward Match Calls)..."
mgba_key Up 0.15 1
if ! mgba_is_alive; then
    echo "CRASH: Process died after first Up"
    exit 1
fi
echo "[OK] Alive after Up #1"

echo "[ACTION] Moving cursor Up..."
mgba_key Up 0.15 1
if ! mgba_is_alive; then
    echo "CRASH: Process died after Up #2"
    exit 1
fi
echo "[OK] Alive after Up #2"

echo "[ACTION] Moving cursor Up..."
mgba_key Up 0.15 1
if ! mgba_is_alive; then
    echo "CRASH: Process died after Up #3"
    exit 1
fi
echo "[OK] Alive after Up #3"

shot="$(mgba_screenshot "crash_repro_04_back_at_top")"
echo "[SCREENSHOT] After moving back up: $shot"

if ! mgba_is_alive; then
    echo "CRASH: Process died while taking screenshot"
    exit 1
fi

# Now toggle Match Calls (should be Right/Left)
echo "[ACTION] Pressing Right to toggle Match Calls..."
mgba_key Right 0.15 1
if ! mgba_is_alive; then
    echo "CRASH: Process died after toggling Match Calls"
    exit 1
fi
echo "[OK] Alive after Match Calls toggle #1"

shot="$(mgba_screenshot "crash_repro_05_after_match_calls_toggle")"
echo "[SCREENSHOT] After toggling Match Calls: $shot"

if ! mgba_is_alive; then
    echo "CRASH: Process died while taking screenshot"
    exit 1
fi

# Toggle it again to flip back
echo "[ACTION] Pressing Left to toggle Match Calls back..."
mgba_key Left 0.15 1
if ! mgba_is_alive; then
    echo "CRASH: Process died after second Match Calls toggle"
    exit 1
fi
echo "[OK] Alive after Match Calls toggle #2"

# Try toggling Ball Prompt
echo "[ACTION] Moving cursor Down to Ball Prompt..."
mgba_key Down 0.15 1
if ! mgba_is_alive; then
    echo "CRASH: Process died moving to Ball Prompt"
    exit 1
fi
echo "[OK] Alive after moving Down"

echo "[ACTION] Pressing Right to toggle Ball Prompt..."
mgba_key Right 0.15 1
if ! mgba_is_alive; then
    echo "CRASH: Process died toggling Ball Prompt"
    exit 1
fi
echo "[OK] Alive after Ball Prompt toggle"

# Cycle through the menu options with down/up
echo "[ACTION] Scrolling down past current..."
for i in {1..4}; do
    mgba_key Down 0.15 0.8
    if ! mgba_is_alive; then
        echo "CRASH: Process died during Down scroll iteration $i"
        exit 1
    fi
    echo "[OK] Alive after Down scroll #$i"
done

echo "[ACTION] Scrolling back up..."
for i in {1..4}; do
    mgba_key Up 0.15 0.8
    if ! mgba_is_alive; then
        echo "CRASH: Process died during Up scroll iteration $i"
        exit 1
    fi
    echo "[OK] Alive after Up scroll #$i"
done

shot="$(mgba_screenshot "crash_repro_06_after_scrolling")"
echo "[SCREENSHOT] After scrolling through menu: $shot"

if ! mgba_is_alive; then
    echo "CRASH: Process died while taking screenshot"
    exit 1
fi

# Try to exit the menu (press B)
echo "[ACTION] Pressing B to exit Options menu..."
mgba_key z 0.15 2
if ! mgba_is_alive; then
    echo "CRASH: Process died pressing B to exit"
    exit 1
fi
echo "[OK] Alive after B press"

shot="$(mgba_screenshot "crash_repro_07_after_exit")"
echo "[SCREENSHOT] After attempting to exit: $shot"

if ! mgba_is_alive; then
    echo "CRASH: Process died while taking final screenshot"
    exit 1
fi

echo ""
echo "=== Test Complete ==="
echo "PASS: Completed full toggle sequence without crash"
echo "All screenshots saved to: $SCREENSHOT_DIR"
