#!/usr/bin/env bash
# Reusable navigation sequences built on top of harness.sh. Source harness.sh
# first, then this file, then call the nav_* functions below.
#
# These sequences were derived empirically against the current title-screen
# intro length and main-menu layout. If intro cutscenes or menu structure
# change meaningfully, these may need retuning — that's expected and fine;
# update in place rather than duplicating per-feature-test copies.

# Presses Start repeatedly to get from ROM boot (PRET x RHH splash) through
# the copyright screen, logo, and legendary title animation to the main
# menu (CONTINUE / NEW GAME / OPTION). Call right after mgba_launch.
nav_skip_intro_to_main_menu() {
    local presses="${1:-10}"
    local i
    for i in $(seq 1 "$presses"); do
        mgba_key Return 0.15 2
    done
}

# From the main menu with CONTINUE highlighted (the default cursor position
# when a save exists), moves down to OPTION and confirms it, landing on the
# Options Plus "Gameplay Options" screen.
nav_main_menu_to_options() {
    mgba_key Down 0.15 1.5
    mgba_key Down 0.15 1.5
    mgba_key x 0.15 2
}

# From the main menu with CONTINUE highlighted, just confirms it — for saves
# seeded via mgba_seed_save (e.g. saves/has_starter.sav).
nav_main_menu_continue() {
    mgba_key x 0.15 3
}

# From the overworld with a party (POKéMON is then the default first Start
# menu entry), opens the party menu, selects the first party slot, and opens
# its Summary screen.
nav_party_first_mon_summary() {
    mgba_key Return 0.15 1.5  # open Start menu
    mgba_key x 0.15 2         # confirm POKéMON (default highlighted)
    mgba_key x 0.15 1.5       # select first party slot
    mgba_key x 0.15 2         # confirm SUMMARY (default highlighted)
}

# Opens the (Unbound-style) overworld Start menu. Just Start — unlike the
# vanilla start menu, USM's icon bar doesn't require any extra input to show.
nav_open_usm() {
    mgba_key Return 0.15 2
}

# Opens the debug menu's Utilities > Scripts submenu and runs one of the 8
# ad-hoc test-script slots (data/scripts/debug.inc: Debug_EventScript_Script_N,
# wired via the debug menu). scriptNum is 1-8 (default 1). These slots are
# the standard place to wire up a throwaway runtime test for whatever's
# currently being verified — edit debug.inc, rebuild, then call this.
nav_debug_run_script() {
    local scriptNum="${1:-1}"
    nav_open_debug_menu
    for i in $(seq 1 5); do
        mgba_key Down 0.15 1
    done
    mgba_key x 0.15 1.5  # open Scripts submenu (Script 1 default highlighted)
    local i
    for ((i = 1; i < scriptNum; i++)); do
        mgba_key Down 0.15 1
    done
    mgba_key x 0.15 2  # run the script
}

# Opens the R+Start debug overworld menu (only present in non-`make release`
# builds — see include/constants/global.h DISABLED_ON_RELEASE). Under Xvfb,
# a short hold-R-tap-Start is unreliable (the combo sometimes isn't detected
# and the NORMAL start menu opens instead, silently derailing everything
# after it) — so this holds R well before and after the Start tap for a
# generous overlap window. Always verify with a screenshot after calling
# this rather than assuming it worked.
nav_open_debug_menu() {
    DISPLAY="$MGBA_DISPLAY" xdotool keydown s   # hold R
    sleep 0.6
    DISPLAY="$MGBA_DISPLAY" xdotool keydown Return
    sleep 0.3
    DISPLAY="$MGBA_DISPLAY" xdotool keyup Return
    sleep 0.4
    DISPLAY="$MGBA_DISPLAY" xdotool keyup s      # release R
    sleep 1.5
}

# Navigates to Utilities > Give X > Pokémon (Basic) from the debug menu,
# landing on the species picker. Caller is responsible for confirming
# species/level from there.
nav_debug_give_pokemon_basic() {
    nav_open_debug_menu
    mgba_key Down 0.15 1     # -> PC/Bag
    mgba_key Down 0.15 1     # -> Party
    mgba_key Down 0.15 1     # -> Give X
    mgba_key x 0.15 1.5      # open Give X submenu (Give item XYZ is first)
    mgba_key Down 0.15 1     # -> Pokémon (Basic)
    mgba_key x 0.15 1.5      # open species picker
}

# Opens the R+Start debug menu and navigates to PC/Bag > Access PC >
# SOMEONE'S PC, landing in the Pokémon Storage box UI (Move Pokémon).
# Requires the player to already be able to access a PC (any overworld
# location works — the debug menu doesn't require being near a real PC).
nav_debug_access_pokemon_storage() {
    nav_open_debug_menu
    mgba_key Down 0.15 1     # -> PC/Bag
    mgba_key x 0.15 1.5      # open PC/Bag submenu
    mgba_key x 0.15 2        # Access PC (default highlighted)
    mgba_key x 0.15 2.5      # advance "<name> booted up the PC." (long multichoice text needs extra settle)
    mgba_key x 0.15 2.5      # SOMEONE'S PC (default highlighted) -> Pokémon storage
    mgba_key x 0.15 2.5      # advance "Accessed SOMEONE'S PC."
    mgba_key x 0.15 2.5      # advance "POKéMON Storage System opened."
    mgba_key x 0.15 2.5      # Move Pokémon (default highlighted) -> box UI
}
