#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  VOID — Wallpaper Selector (Rofi)                            ║
# ║  ~/.config/hypr/scripts/wallpaper.sh                          ║
# ╚══════════════════════════════════════════════════════════════╝
set -euo pipefail

WALLPAPER_DIR="$HOME/.config/hypr/wallpaper"
HYPRPAPER_CONF="$HOME/.config/hypr/hyprpaper.conf"

# list images in wallpaper directory
wallpaper=$(find "$WALLPAPER_DIR" -type f \( -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" -o -name "*.webp" \) -printf "%f\n" | sort | rofi -dmenu \
    -p "wallpaper" \
    -theme ~/.config/rofi/themes/void.rasi \
    -theme-str 'window { width: 360px; } listview { lines: 6; }')

[[ -z "$wallpaper" ]] && exit 0

fullpath="$WALLPAPER_DIR/$wallpaper"

# update hyprpaper config
cat > "$HYPRPAPER_CONF" << EOF
# ╔══════════════════════════════════════════════════════════════╗
# ║  VOID — Hyprpaper Configuration                             ║
# ║  ~/.config/hypr/hyprpaper.conf                               ║
# ╚══════════════════════════════════════════════════════════════╝

wallpaper {
    monitor =
    path = $fullpath
    fit_mode = cover
}

splash = false
ipc = true
EOF

# reload hyprpaper
pkill hyprpaper 2>/dev/null || true
sleep 0.3
hyprpaper &
disown

notify-send "Wallpaper" "Set to $wallpaper" -t 2000
