#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  VOID — Waybar Media Player (playerctl)                      ║
# ║  ~/.config/waybar/scripts/mediaplayer.sh                      ║
# ╚══════════════════════════════════════════════════════════════╝

playerctl -a metadata --format '{"text": "{{artist}} — {{title}}", "tooltip": "{{playerName}}: {{artist}} — {{title}}", "alt": "{{status}}", "class": "{{status}}"}' -F 2>/dev/null || echo '{"text": "", "tooltip": "", "alt": "", "class": "stopped"}'
