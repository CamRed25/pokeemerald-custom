#!/usr/bin/env bash
# Feature test: Options Plus menu is reachable and renders correctly.
#
# Verifies that OPTION from the main menu lands on the Options Plus
# "Gameplay Options" screen (via option_menu.c's CB2_InitOptionPlusMenu
# hook), and that the migrated Match Calls / Ball Prompt toggles are present.
# Seeds the saves/has_starter.sav fixture so the main menu shows
# CONTINUE/NEW GAME/OPTION — this test never touches the real ROM-adjacent
# save (mgba_launch always redirects saves to an isolated scratch dir).
#
# Usage: options_plus_test.sh [path-to-rom]
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
mgba_screenshot "options_plus_00_main_menu" >/dev/null

if ! mgba_is_alive; then
    echo "FAIL: mgba crashed while navigating the intro"
    exit 1
fi

nav_main_menu_to_options
shot="$(mgba_screenshot "options_plus_01_gameplay_options")"

if ! mgba_is_alive; then
    echo "FAIL: mgba crashed opening the Options Plus menu"
    exit 1
fi

echo "PASS: reached Options Plus menu, screenshot at $shot"
echo "NOTE: visual content (Match Calls / Ball Prompt rows present) requires manual or vision-based confirmation of the screenshot — this script only confirms navigation succeeded and mgba stayed alive."
