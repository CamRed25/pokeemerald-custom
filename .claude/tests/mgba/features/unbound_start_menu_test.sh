#!/usr/bin/env bash
# Feature test: Unbound Start Menu (USM) opens and its Save flow works.
#
# Verifies (via screenshots + liveness checks, not pixel comparison):
#  - Start opens the USM icon-bar menu (not the vanilla list menu)
#  - Navigating right lands on Save, and opening it reaches the save
#    confirmation dialog (save_dialog.c) without crashing
#
# Seeds saves/has_starter.sav so a party exists; never touches the real
# ROM-adjacent save. Selects NO on the save prompt — never actually writes.
#
# Usage: unbound_start_menu_test.sh [path-to-rom]
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

if ! mgba_is_alive; then
    echo "FAIL: mgba crashed continuing the fixture save"
    exit 1
fi

# --- Open USM ---
nav_open_usm
shot="$(mgba_screenshot "usm_01_menu")"

if ! mgba_is_alive; then
    echo "FAIL: mgba crashed opening the Unbound Start Menu"
    exit 1
fi
echo "PASS: opened Unbound Start Menu, screenshot at $shot"

# --- Navigate to Save and open the save dialog ---
mgba_key Right 0.15 1
mgba_key Right 0.15 1
mgba_key Right 0.15 1
mgba_key x 0.15 2
shot="$(mgba_screenshot "usm_02_save_dialog")"

if ! mgba_is_alive; then
    echo "FAIL: mgba crashed opening the Save dialog"
    exit 1
fi
echo "PASS: reached Save dialog via USM, screenshot at $shot"

# Cancel — select NO — never actually save from an automated test run.
mgba_key Down 0.15 1
mgba_key x 0.15 2

if ! mgba_is_alive; then
    echo "FAIL: mgba crashed canceling the Save dialog"
    exit 1
fi
echo "PASS: canceled Save dialog cleanly, no crash"

echo "NOTE: visual content correctness requires manual or vision-based confirmation of the screenshots — this script only confirms navigation succeeded and mgba stayed alive throughout."
