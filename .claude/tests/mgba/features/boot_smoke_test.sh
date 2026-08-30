#!/usr/bin/env bash
# Boot smoke test: does the ROM boot and stay alive without crashing?
# Usage: boot_smoke_test.sh [path-to-rom]  (defaults to pokeemerald.gba at repo root)
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
source "$SCRIPT_DIR/../common/harness.sh"

ROM="${1:-$REPO_ROOT/pokeemerald.gba}"

if [ ! -f "$ROM" ]; then
    echo "FAIL: ROM not found at $ROM"
    exit 1
fi

mgba_start_display
trap mgba_stop EXIT

mgba_launch "$ROM"

if ! mgba_is_alive; then
    echo "FAIL: mgba process exited immediately after launch"
    cat "$MGBA_TEST_HOME/mgba.stderr.log" 2>/dev/null
    exit 1
fi

sleep 3

if ! mgba_is_alive; then
    echo "FAIL: mgba crashed within the first few seconds of boot"
    cat "$MGBA_TEST_HOME/mgba.stderr.log" 2>/dev/null
    exit 1
fi

shot="$(mgba_screenshot "boot_smoke_$(date +%Y%m%d_%H%M%S)")"

if ! mgba_is_alive; then
    echo "FAIL: mgba crashed after screenshot"
    exit 1
fi

echo "PASS: ROM booted and stayed alive, screenshot at $shot"
