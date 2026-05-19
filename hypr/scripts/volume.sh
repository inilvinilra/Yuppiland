#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  VOID — Volume Control (with notifications)                  ║
# ║  ~/.config/hypr/scripts/volume.sh                             ║
# ╚══════════════════════════════════════════════════════════════╝
set -euo pipefail

get_volume() {
    wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{printf "%.0f", $2 * 100}'
}

get_mute() {
    wpctl get-volume @DEFAULT_AUDIO_SINK@ | grep -q MUTED && echo "yes" || echo "no"
}

notify_volume() {
    local vol=$(get_volume)
    local muted=$(get_mute)
    local icon=""

    if [[ "$muted" == "yes" ]]; then
        icon="󰝟"
        dunstify -a "void-volume" -u low -r 9993 -h int:value:0 "$icon muted"
    elif (( vol >= 66 )); then
        icon=""
        dunstify -a "void-volume" -u low -r 9993 -h int:value:"$vol" "$icon ${vol}%"
    elif (( vol >= 33 )); then
        icon=""
        dunstify -a "void-volume" -u low -r 9993 -h int:value:"$vol" "$icon ${vol}%"
    else
        icon=""
        dunstify -a "void-volume" -u low -r 9993 -h int:value:"$vol" "$icon ${vol}%"
    fi
}

case "${1:-}" in
    up)     wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+ ; notify_volume ;;
    down)   wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-        ; notify_volume ;;
    mute)   wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle       ; notify_volume ;;
    *)      echo "Usage: $0 {up|down|mute}" ;;
esac
