#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  VOID — Power Menu (Rofi)                                    ║
# ║  ~/.config/hypr/scripts/power-menu.sh                         ║
# ╚══════════════════════════════════════════════════════════════╝
set -euo pipefail

options="  lock\n  logout\n  suspend\n  reboot\n  shutdown"

choice=$(echo -e "$options" | rofi -dmenu \
    -p "power" \
    -theme ~/.config/rofi/themes/void.rasi \
    -theme-str 'window { width: 220px; } listview { lines: 5; }' \
    -no-custom \
    -selected-row 0)

case "$choice" in
    *lock)      hyprlock ;;
    *logout)    hyprctl dispatch exit ;;
    *suspend)   systemctl suspend ;;
    *reboot)    systemctl reboot ;;
    *shutdown)  systemctl poweroff ;;
esac
