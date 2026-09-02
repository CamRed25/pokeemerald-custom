#!/usr/bin/env bash
# Feature test: Improved move-info panel with type and category icons
#
# Verifies:
#  - Type icon renders in B_WIN_MOVE_TYPE window (4 tiles wide, icon graphic)
#  - Category icon (physical/special/status) renders in B_WIN_MOVE_CATEGORY window
#  - Icons change when cycling through moves with different types/categories
#  - No visual corruption in surrounding battle UI (PP display, move names, etc.)
#
# Uses the debug menu's "Start Debug Battle" (Party -> Start Debug Battle)
# instead of walking into tall grass — a wild encounter isn't guaranteed
# every step, which made earlier grass-walk-based versions of this test
# nondeterministic. The debug battle is a trainer battle, but it reaches the
# same move-selection screen this feature touches.
#
# Usage: move_info_panel_test.sh [path-to-rom]
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

if [ ! -f "$SCRIPT_DIR/../saves/catch_mode_ready.sav" ]; then
    echo "FAIL: catch_mode_ready.sav fixture not found"
    exit 1
fi

mgba_start_display
trap mgba_stop EXIT

mgba_seed_save "$ROM" "$SCRIPT_DIR/../saves/catch_mode_ready.sav"
mgba_launch "$ROM"

if ! mgba_is_alive; then
    echo "FAIL: mgba process exited immediately after launch"
    exit 1
fi

echo "Loading fixture save..."
nav_skip_intro_to_main_menu 16
nav_main_menu_continue

if ! mgba_is_alive; then
    echo "FAIL: mgba crashed continuing from the fixture save"
    exit 1
fi

sleep 2
shot_overworld="$(mgba_screenshot "move_info_panel_01_overworld_start")"
echo "Overworld: $shot_overworld"

echo ""
echo "Step 1: Opening debug menu -> Party -> Start Debug Battle..."
nav_open_debug_menu
mgba_key Down 0.15 1   # -> PC/Bag
mgba_key Down 0.15 1   # -> Party
mgba_key x 0.15 1.5    # open Party submenu

for i in {1..10}; do
    mgba_key Down 0.15 1   # -> ... -> Start Debug Battle (10th entry)
done

sleep 1
shot_menu="$(mgba_screenshot "move_info_panel_02_party_menu_at_start_battle")"
echo "Party submenu (should be on 'Start Debug Battle'): $shot_menu"

mgba_key x 0.15 2      # confirm -> triggers debug battle immediately

sleep 3
shot_battle="$(mgba_screenshot "move_info_panel_03_debug_battle_started")"
echo "Debug battle started: $shot_battle"

if ! mgba_is_alive; then
    echo "FAIL: mgba crashed starting the debug battle"
    exit 1
fi

echo ""
echo "Step 2: Dismissing the challenge dialog to reach the action menu..."
mgba_key x 0.15 2

sleep 1
shot_action_menu="$(mgba_screenshot "move_info_panel_03b_action_menu")"
echo "Action menu (Battle/Bag/Pokemon/Run): $shot_action_menu"

echo "Selecting Battle to reach move selection..."
mgba_key x 0.15 2

sleep 1
shot_fight1="$(mgba_screenshot "move_info_panel_04_move_1")"
echo "Move-selection screen, move 1 (type + category icons should render): $shot_fight1"

if ! mgba_is_alive; then
    echo "FAIL: mgba crashed opening the FIGHT menu"
    exit 1
fi

echo ""
echo "Step 3: Cycling through moves..."
mgba_key Down 0.15 1
sleep 1
shot_fight2="$(mgba_screenshot "move_info_panel_05_move_2")"
echo "Move 2 (icons should have changed if type/category differ): $shot_fight2"

mgba_key Down 0.15 1
sleep 1
shot_fight3="$(mgba_screenshot "move_info_panel_06_move_3")"
echo "Move 3: $shot_fight3"

mgba_key Down 0.15 1
sleep 1
shot_fight4="$(mgba_screenshot "move_info_panel_07_move_4")"
echo "Move 4: $shot_fight4"

if ! mgba_is_alive; then
    echo "FAIL: mgba crashed cycling moves"
    exit 1
fi

echo ""
echo "PASS: Move-info panel test sequence completed. Review screenshots for visual verification."
echo "Key screenshots to check:"
echo "  - $shot_battle: Battle started"
echo "  - $shot_fight1, $shot_fight2, $shot_fight3, $shot_fight4: Move-info panel per move"
