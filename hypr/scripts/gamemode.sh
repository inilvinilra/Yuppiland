#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  VOID — Game Mode Toggle                                    ║
# ║  ~/.config/hypr/scripts/gamemode.sh                          ║
# ╚══════════════════════════════════════════════════════════════╝
set -euo pipefail

# Toggles animations, blur, and gaps off/on for maximum performance.
# State is tracked via a temp file.

STATE_FILE="/tmp/void-gamemode"

if [[ -f "$STATE_FILE" ]]; then
    # --- DISABLE GAME MODE ---
    hyprctl --batch "\
        keyword animations:enabled true;\
        keyword decoration:blur:enabled true;\
        keyword decoration:shadow:enabled true;\
        keyword decoration:dim_inactive true;\
        keyword general:gaps_in 6;\
        keyword general:gaps_out 14;\
        keyword general:border_size 1;\
        keyword decoration:rounding 5"
    rm "$STATE_FILE"
    notify-send "Game Mode" "OFF — effects restored" -t 2000
else
    # --- ENABLE GAME MODE ---
    hyprctl --batch "\
        keyword animations:enabled false;\
        keyword decoration:blur:enabled false;\
        keyword decoration:shadow:enabled false;\
        keyword decoration:dim_inactive false;\
        keyword general:gaps_in 0;\
        keyword general:gaps_out 0;\
        keyword general:border_size 0;\
        keyword decoration:rounding 0"
    touch "$STATE_FILE"
    notify-send "Game Mode" "ON — effects disabled" -t 2000
fi
