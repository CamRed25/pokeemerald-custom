#!/usr/bin/env bash
# Feature test: SwSh Party Menu, Summary Screen, and PC Storage System.
#
# Verifies (via screenshots + liveness checks, not pixel comparison):
#  - Start > POKéMON opens the SwSh-style party list
#  - Selecting a party mon > SUMMARY opens the SwSh-style summary screen
#  - The debug menu's PC/Bag > Access PC > SOMEONE'S PC path reaches the
#    SwSh-style PC box UI (Move Pokémon)
#
# Uses the debug overworld menu (R+Start) for the PC/storage path — this
# only exists in non-`make release` builds (DISABLED_ON_RELEASE in
# include/constants/global.h). Seeds saves/has_starter.sav so a party
# already exists; never touches the real ROM-adjacent save.
#
# Usage: swsh_ui_test.sh [path-to-rom]
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

# --- Party Menu + Summary Screen ---
nav_party_first_mon_summary
shot="$(mgba_screenshot "swsh_ui_01_summary")"

if ! mgba_is_alive; then
    echo "FAIL: mgba crashed opening party menu / summary screen"
    exit 1
fi
echo "PASS: reached SwSh Summary screen via party menu, screenshot at $shot"

# Back out to overworld: summary -> party submenu -> party list -> Start menu -> overworld.
# All four levels are needed — leaving the Start menu open silently absorbs
# the next R+Start debug-menu combo instead of opening the debug menu.
mgba_key z 0.15 1
mgba_key z 0.15 1
mgba_key z 0.15 1
mgba_key z 0.15 1.5

# --- PC / Pokémon Storage System ---
nav_debug_access_pokemon_storage
shot="$(mgba_screenshot "swsh_ui_02_storage_box")"

if ! mgba_is_alive; then
    echo "FAIL: mgba crashed opening the PC storage box UI"
    exit 1
fi
echo "PASS: reached SwSh Storage box UI via debug PC access, screenshot at $shot"

echo "NOTE: visual content correctness requires manual or vision-based confirmation of the screenshots — this script only confirms navigation succeeded and mgba stayed alive throughout."
