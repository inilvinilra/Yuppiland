#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  VOID — Screenshot Menu (Rofi)                              ║
# ║  ~/.config/hypr/scripts/screenshot-menu.sh                   ║
# ╚══════════════════════════════════════════════════════════════╝
set -euo pipefail

THEME="$HOME/.config/rofi/themes/void.rasi"
SCRIPT="$HOME/.config/hypr/scripts/screenshot.sh"

options="󰹑  full screen\n  select area\n  area → clipboard\n  active window"

choice=$(echo -e "$options" | rofi -dmenu \
    -p "screenshot" \
    -theme "$THEME" \
    -theme-str 'window { width: 260px; } listview { lines: 4; }' \
    -no-custom \
    -selected-row 0) || exit 0

case "$choice" in
    *"full screen"*)     "$SCRIPT" full ;;
    *"select area"*)     "$SCRIPT" area ;;
    *"clipboard"*)       "$SCRIPT" clipboard ;;
    *"active window"*)   "$SCRIPT" window ;;
esac
