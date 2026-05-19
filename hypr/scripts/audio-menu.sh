#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  VOID — Audio Device Switcher (Rofi + wpctl)                ║
# ║  ~/.config/hypr/scripts/audio-menu.sh                        ║
# ╚══════════════════════════════════════════════════════════════╝
set -euo pipefail

THEME="$HOME/.config/rofi/themes/void.rasi"
THEME_STR='window { width: 420px; } listview { lines: 8; }'

notify() { notify-send "Audio" "$1" -t 3000; }

# --- LIST SINKS (output devices) ---
get_sinks() {
    wpctl status | awk '
        /Audio/,/Video/ {
            if (/Sinks:/) { section="sink"; next }
            if (/Sources:/) { section="source"; next }
            if (/Sink endpoints:/ || /Source endpoints:/ || /Streams:/) { section=""; next }
            if (section=="sink" && /│/) {
                line=$0
                gsub(/^[│ ]*/, "", line)
                if (line != "" && line !~ /^$/) print line
            }
        }
    '
}

# --- LIST SOURCES (input devices) ---
get_sources() {
    wpctl status | awk '
        /Audio/,/Video/ {
            if (/Sources:/) { section="source"; next }
            if (/Source endpoints:/ || /Streams:/ || /Sink endpoints:/) { section=""; next }
            if (section=="source" && /│/) {
                line=$0
                gsub(/^[│ ]*/, "", line)
                if (line != "" && line !~ /^$/) print line
            }
        }
    '
}

build_menu_line() {
    local kind="$1"
    local entry="$2"
    local is_default=""
    local line="$entry"

    if [[ "$line" == \** ]]; then
        is_default="yes"
        line="${line#\*}"
        line="${line# }"
    fi

    local id
    id=$(printf '%s\n' "$line" | sed -n 's/^\([0-9]\+\)\..*/\1/p')
    [[ -z "$id" ]] && return 1

    local name
    name=$(printf '%s\n' "$line" | sed -E 's/^[0-9]+\. *//; s/ *\[.*\]//; s/ *$//')
    [[ -z "$name" ]] && return 1

    if [[ "$kind" == "source" ]]; then
        printf '󰍬  %s%s\t__ID__=%s\t__TYPE__=source\n' "$name" "${is_default:+ ●}" "$id"
    else
        printf '󰕾  %s%s\t__ID__=%s\t__TYPE__=sink\n' "$name" "${is_default:+ ●}" "$id"
    fi
}

# --- BUILD MENU ---
menu="  OUTPUT DEVICES"

while IFS= read -r entry; do
    menu_line=$(build_menu_line sink "$entry") || continue
    menu="$menu\n$menu_line"
done < <(get_sinks)

menu="$menu\n\n󰍬  INPUT DEVICES"

while IFS= read -r entry; do
    menu_line=$(build_menu_line source "$entry") || continue
    menu="$menu\n$menu_line"
done < <(get_sources)

# --- SHOW MENU ---
choice=$(echo -e "$menu" | rofi -dmenu \
    -p "audio" \
    -theme "$THEME" \
    -theme-str "$THEME_STR" \
    -no-custom \
    -selected-row 0) || exit 0

# --- SKIP HEADERS ---
[[ "$choice" == *"OUTPUT DEVICES"* || "$choice" == *"INPUT DEVICES"* ]] && exit 0

# --- RESOLVE DEVICE ID ---
device_id=$(printf '%s\n' "$choice" | sed -n 's/.*__ID__=\([0-9]\+\).*/\1/p')
device_type=$(printf '%s\n' "$choice" | sed -n 's/.*__TYPE__=\([a-z]\+\).*/\1/p')
clean_name=$(printf '%s\n' "$choice" | sed -E 's/\t__ID__=.*$//; s/^[^ ]+  //; s/ ●$//')

if [[ -z "$device_id" || -z "$device_type" ]]; then
    notify "Could not find device metadata"
    exit 1
fi

if [[ "$device_type" == "source" ]]; then
    wpctl set-default "$device_id"
    notify "Input: $clean_name"
else
    wpctl set-default "$device_id"
    notify "Output: $clean_name"
fi
