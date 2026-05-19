#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  VOID — Brightness Control (with notifications)              ║
# ║  ~/.config/hypr/scripts/brightness.sh                         ║
# ╚══════════════════════════════════════════════════════════════╝
set -euo pipefail

get_brightness() {
    brightnessctl -m | awk -F, '{print substr($4, 0, length($4)-1)}'
}

notify_brightness() {
    local val=$(get_brightness)
    local icon="󰃟"
    (( val >= 75 )) && icon="󰃠"
    (( val <= 25 )) && icon="󰃞"
    dunstify -a "void-brightness" -u low -r 9994 -h int:value:"$val" "$icon ${val}%"
}

case "${1:-}" in
    up)     brightnessctl set +5%  ; notify_brightness ;;
    down)   brightnessctl set 5%-  ; notify_brightness ;;
    *)      echo "Usage: $0 {up|down}" ;;
esac
