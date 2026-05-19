#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  VOID — Waybar Updates Counter (pacman)                      ║
# ║  ~/.config/waybar/scripts/updates.sh                          ║
# ╚══════════════════════════════════════════════════════════════╝

if ! command -v checkupdates >/dev/null 2>&1; then
    echo '{"text": "󰏗 ?", "tooltip": "checkupdates not found (install pacman-contrib)", "class": "warning"}'
    exit 0
fi

count=$(checkupdates 2>/dev/null | wc -l)
list=$(checkupdates 2>/dev/null | head -20 | awk '{print $1 " " $2 " → " $4}')

if [[ "$count" -gt 0 ]]; then
    tooltip=$(echo "$list" | sed ':a;N;$!ba;s/\n/\\n/g')
    echo "{\"text\": \"󰏗 ${count}\", \"tooltip\": \"${tooltip}\", \"class\": \"pending\"}"
else
    echo '{"text": "󰏗 0", "tooltip": "System is up to date", "class": "current"}'
fi
