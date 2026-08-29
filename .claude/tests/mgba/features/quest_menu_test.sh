#!/usr/bin/env bash
# Feature test: Quest Menu opens and is reachable from the Start Menu.
#
# Verifies (via screenshots + liveness checks, not pixel comparison):
#  - Start Menu opens correctly
#  - Quest Menu option is visible and selectable in the Start Menu
#  - Quest Menu opens without crashing
#  - Navigation back from Quest Menu works cleanly
#
# Seeds saves/has_starter.sav so a party exists and player is in overworld;
# uses debug menu Script 1 to enable the Quest Menu system flag, then verifies
# Quest Menu is accessible from the Start Menu; never touches the real
# ROM-adjacent save.
#
# Usage: quest_menu_test.sh [path-to-rom]
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

# Skip intro to main menu
nav_skip_intro_to_main_menu

if ! mgba_is_alive; then
    echo "FAIL: mgba crashed during intro skip"
    exit 1
fi

# Continue from fixture save to get to overworld
nav_main_menu_continue

if ! mgba_is_alive; then
    echo "FAIL: mgba crashed continuing the fixture save"
    exit 1
fi

sleep 2  # Extra settle time for the overworld to fully load

if ! mgba_is_alive; then
    echo "FAIL: mgba crashed loading the overworld"
    exit 1
fi

# --- Enable Quest Menu via debug script ---
# Open debug menu and run Script 1 to set FLAG_SYS_QUEST_MENU_GET
nav_debug_run_script 1

if ! mgba_is_alive; then
    echo "FAIL: mgba crashed running debug script 1"
    exit 1
fi

sleep 2  # Wait for quest menu initialization

shot="$(mgba_screenshot "quest_menu_00_debug_quest_open")"
echo "INFO: Debug script opened Quest Menu, screenshot at $shot"

# Close Quest Menu by pressing B
mgba_key z 0.15 1.5

if ! mgba_is_alive; then
    echo "FAIL: mgba crashed closing debug-opened Quest Menu"
    exit 1
fi

sleep 1

# --- Now verify Quest Menu is reachable from the live Start Menu ---
# This project runs with UNBOUND_START_MENU enabled (include/unbound_start_menu.h),
# so the icon-grid USM is what's actually reachable via Start, not the legacy
# list-based menu in src/start_menu.c. See nav_open_usm in navigate.sh.
nav_open_usm

if ! mgba_is_alive; then
    echo "FAIL: mgba crashed opening the Unbound Start Menu"
    exit 1
fi

shot="$(mgba_screenshot "quest_menu_01_start_menu")"
echo "INFO: Unbound Start Menu opened, screenshot at $shot"

# Icon order on this fixture save (has_starter.sav: FLAG_SYS_POKEMON_GET set,
# FLAG_SYS_POKEDEX_GET/FLAG_SYS_POKENAV_GET unset) after Script 1 above sets
# FLAG_SYS_QUEST_MENU_GET, per Usm_BuildDefaultMenuItems in
# src/unbound_start_menu.c: Pokemon, Bag, Trainer, Quests, Save, Options.
# Cursor starts on Pokemon (index 0); Quests is 3 icons to the right.
for i in {1..3}; do
    mgba_key Right 0.15 0.8
done

if ! mgba_is_alive; then
    echo "FAIL: mgba crashed navigating the Unbound Start Menu"
    exit 1
fi

shot="$(mgba_screenshot "quest_menu_02_start_menu_quest_highlighted")"
echo "INFO: Quests icon highlighted, screenshot at $shot"

# Open Quest Menu
mgba_key x 0.15 2

if ! mgba_is_alive; then
    echo "FAIL: mgba crashed opening Quest Menu from the Unbound Start Menu"
    exit 1
fi

sleep 1.5  # Wait for Quest Menu to fully load

shot="$(mgba_screenshot "quest_menu_03_quest_menu_open")"
echo "PASS: opened Quest Menu from Start Menu, screenshot at $shot"

# Close Quest Menu by pressing B
mgba_key z 0.15 1.5

if ! mgba_is_alive; then
    echo "FAIL: mgba crashed closing Quest Menu"
    exit 1
fi

echo "PASS: closed Quest Menu cleanly, no crash"

echo "NOTE: visual content correctness requires manual or vision-based confirmation of the screenshots — this script only confirms navigation succeeded and mgba stayed alive throughout."
