#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  VOID — Waybar Mic Status                                    ║
# ║  ~/.config/waybar/scripts/mic.sh                              ║
# ╚══════════════════════════════════════════════════════════════╝

muted=$(wpctl get-volume @DEFAULT_AUDIO_SOURCE@ 2>/dev/null | grep -c MUTED)

if [[ "$muted" -eq 1 ]]; then
    echo '{"text": "󰍭 off", "class": "muted"}'
else
    vol=$(wpctl get-volume @DEFAULT_AUDIO_SOURCE@ 2>/dev/null | awk '{printf "%.0f", $2 * 100}')
    echo "{\"text\": \"󰍬 ${vol}%\", \"class\": \"active\"}"
fi
