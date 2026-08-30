#!/usr/bin/env bash
# Shared mGBA runtime test harness.
#
# Drives the real mgba.appimage GUI inside an isolated Xvfb virtual display,
# using xdotool for input injection and ImageMagick's `import` for
# screenshots. Uses an isolated XDG_CONFIG_HOME so automated runs never touch
# the user's real mGBA profile, library, MRU list, or saves.
#
# Source this file from a test script, then call the mgba_* functions below.
# Always `trap mgba_stop EXIT` after mgba_start_display so the Xvfb/mgba
# processes are cleaned up even if the test fails partway through.

MGBA_TEST_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MGBA_APPIMAGE="${MGBA_APPIMAGE:-$HOME/AppImages/mgba.appimage}"
MGBA_DISPLAY="${MGBA_DISPLAY:-:97}"
MGBA_TEST_HOME="$MGBA_TEST_ROOT/common/.mgba-home"
SCREENSHOT_DIR="$MGBA_TEST_ROOT/screenshots"

MGBA_PID=""
XVFB_PID=""
WM_PID=""

mgba_start_display() {
    mkdir -p "$MGBA_TEST_HOME/.config"
    Xvfb "$MGBA_DISPLAY" -screen 0 1024x768x24 >/dev/null 2>&1 &
    XVFB_PID=$!
    sleep 1
    if ! kill -0 "$XVFB_PID" 2>/dev/null; then
        echo "FAIL: Xvfb failed to start on $MGBA_DISPLAY" >&2
        exit 1
    fi
    # A window manager is required for reliable window focus/activation —
    # without one, Qt won't reliably accept synthetic key events and
    # xdotool windowactivate fails (_NET_ACTIVE_WINDOW unsupported).
    DISPLAY="$MGBA_DISPLAY" openbox >/dev/null 2>&1 &
    WM_PID=$!
    sleep 1
}

# mgba_seed_save <rom-path> <fixture-sav-path>
# Copies a fixture .sav (e.g. from .claude/tests/mgba/saves/) into the
# isolated live-saves directory so the next mgba_launch of that ROM starts
# from it. Call BEFORE mgba_launch. The fixture is never modified in place.
mgba_seed_save() {
    local rom="$1"
    local fixture="$2"
    mkdir -p "$MGBA_TEST_HOME/live-saves"
    cp "$fixture" "$MGBA_TEST_HOME/live-saves/$(basename "${rom%.gba}").sav"
}

# mgba_launch <rom-path> [savestate-path]
#
# IMPORTANT: savegamePath is forced to an isolated scratch directory so
# runs NEVER read or write a .sav next to the real ROM — mGBA's default is
# same-directory-as-ROM, which would mean touching the user's own game save.
mgba_launch() {
    local rom="$1"
    local savestate="${2:-}"
    mkdir -p "$MGBA_TEST_HOME/live-saves"
    local args=(-C useBios=0 -C "savegamePath=$MGBA_TEST_HOME/live-saves")
    if [ -n "$savestate" ]; then
        args+=(-t "$savestate")
    fi
    DISPLAY="$MGBA_DISPLAY" XDG_CONFIG_HOME="$MGBA_TEST_HOME/.config" \
        "$MGBA_APPIMAGE" "${args[@]}" "$rom" >"$MGBA_TEST_HOME/mgba.stdout.log" 2>"$MGBA_TEST_HOME/mgba.stderr.log" &
    MGBA_PID=$!
    sleep 2
    mgba_focus
}

mgba_is_alive() {
    [ -n "$MGBA_PID" ] && kill -0 "$MGBA_PID" 2>/dev/null
}

mgba_window_id() {
    # Search by PID without --onlyvisible; windows may be temporarily unfocused
    # during menu transitions but still valid for screenshot capture.
    # Retry briefly if the window isn't immediately found.
    local win
    local tries=0
    while [ $tries -lt 3 ]; do
        win="$(DISPLAY="$MGBA_DISPLAY" xdotool search --pid "$MGBA_PID" 2>/dev/null | head -1)"
        if [ -n "$win" ]; then
            echo "$win"
            return 0
        fi
        tries=$((tries + 1))
        sleep 0.1
    done
    return 1
}

# Activate the mgba window so it holds real X input focus. Needed once after
# launch (and safe to call again if focus is ever lost) — without a WM
# actively focusing it, Qt ignores synthetic key events.
mgba_focus() {
    local win
    win="$(mgba_window_id)"
    [ -z "$win" ] && return 1
    DISPLAY="$MGBA_DISPLAY" xdotool windowactivate --sync "$win" 2>/dev/null
}

# mgba_key <xdotool-key-name> [hold-seconds, default 0.15] [settle-seconds, default 1]
# GBA default mapping: A=x  B=z  L=a  R=s  Start=Return  Select=BackSpace
#                       D-pad=Up/Down/Left/Right
#
# Under Xvfb, xdotool's atomic `key` command is unreliable here — presses
# silently fail to register more often than not. Explicit keydown/sleep/keyup
# with a real hold duration is what actually works reliably; always go
# through this function rather than calling xdotool key directly.
mgba_key() {
    local key="$1"
    local hold="${2:-0.15}"
    local settle="${3:-1}"
    DISPLAY="$MGBA_DISPLAY" xdotool keydown "$key"
    sleep "$hold"
    DISPLAY="$MGBA_DISPLAY" xdotool keyup "$key"
    sleep "$settle"
}

# mgba_screenshot <name-without-extension>
# Ensures window is focused before capture to avoid black/stale screenshots.
# Uses `-window root` as ImageMagick 7.x doesn't reliably work with numeric window IDs.
mgba_screenshot() {
    local name="$1"
    mkdir -p "$SCREENSHOT_DIR"
    # Focus the window to ensure it's active and properly rendered.
    mgba_focus || true
    sleep 0.2
    # Capture entire virtual desktop; mGBA window will be in it. No window-id
    # lookup needed here — the post-capture file check below is the real gate.
    DISPLAY="$MGBA_DISPLAY" import -window root "$SCREENSHOT_DIR/$name.png" 2>/dev/null
    if [ -f "$SCREENSHOT_DIR/$name.png" ] && [ -s "$SCREENSHOT_DIR/$name.png" ]; then
        echo "$SCREENSHOT_DIR/$name.png"
        return 0
    else
        echo "WARN: screenshot capture failed for $name" >&2
        return 1
    fi
}

mgba_stop() {
    if [ -n "$MGBA_PID" ]; then
        kill "$MGBA_PID" 2>/dev/null
        wait "$MGBA_PID" 2>/dev/null
    fi
    if [ -n "$WM_PID" ]; then
        kill "$WM_PID" 2>/dev/null
        wait "$WM_PID" 2>/dev/null
    fi
    if [ -n "$XVFB_PID" ]; then
        kill "$XVFB_PID" 2>/dev/null
        wait "$XVFB_PID" 2>/dev/null
    fi
}
