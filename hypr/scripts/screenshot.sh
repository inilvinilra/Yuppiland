#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  VOID — Screenshot Utility                                   ║
# ║  ~/.config/hypr/scripts/screenshot.sh                         ║
# ╚══════════════════════════════════════════════════════════════╝
set -euo pipefail

SCREENSHOT_DIR="$HOME/Pictures/Screenshots"
mkdir -p "$SCREENSHOT_DIR"

timestamp=$(date +%Y%m%d_%H%M%S)

case "${1:-}" in
    full)
        grim "$SCREENSHOT_DIR/${timestamp}.png"
        wl-copy < "$SCREENSHOT_DIR/${timestamp}.png"
        notify-send "Screenshot" "Full screen saved & copied" -t 2000
        ;;
    area)
        grim -g "$(slurp -d -b 00000088 -c 1a1a1a -s 00000000 -w 1)" - | tee "$SCREENSHOT_DIR/${timestamp}.png" | wl-copy
        notify-send "Screenshot" "Selection saved & copied" -t 2000
        ;;
    clipboard)
        grim -g "$(slurp -d -b 00000088 -c 1a1a1a -s 00000000 -w 1)" - | wl-copy
        notify-send "Screenshot" "Copied to clipboard" -t 2000
        ;;
    window)
        geo=$(hyprctl activewindow -j | jq -r '"\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"')
        grim -g "$geo" - | tee "$SCREENSHOT_DIR/${timestamp}.png" | wl-copy
        notify-send "Screenshot" "Window captured & copied" -t 2000
        ;;
    *)
        echo "Usage: $0 {full|area|clipboard|window}"
        ;;
esac
