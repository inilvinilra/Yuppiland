#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  VOID — WiFi Menu (Rofi + nmcli)                            ║
# ║  ~/.config/hypr/scripts/wifi-menu.sh                         ║
# ╚══════════════════════════════════════════════════════════════╝
set -euo pipefail

THEME="$HOME/.config/rofi/themes/void.rasi"
THEME_STR='window { width: 380px; } listview { lines: 10; }'

notify() { notify-send "WiFi" "$1" -t 3000; }

# --- GET CURRENT STATE ---
wifi_status=$(nmcli radio wifi)
current_ssid=$(nmcli -t -f active,ssid dev wifi | grep '^yes' | cut -d: -f2) || true
active_device=$(nmcli -t -f DEVICE,TYPE,STATE dev status | awk -F: '$2 == "wifi" && $3 == "connected" { print $1; exit }') || true

# --- BUILD MENU ---
if [[ "$wifi_status" == "enabled" ]]; then
    toggle_label="󰤭  disable wifi"
else
    toggle_label="󰤨  enable wifi"
fi

menu="$toggle_label"

if [[ "$wifi_status" == "enabled" ]]; then
    # rescan (non-blocking, ignore errors)
    nmcli dev wifi rescan 2>/dev/null || true
    sleep 0.5

    # list available networks, deduplicated, sorted by signal
    networks=$(nmcli -t -f ssid,signal,security dev wifi list | \
        awk -F: '!seen[$1]++ && $1!=""' | \
        sort -t: -k2 -rn | \
        while IFS=: read -r ssid signal security; do
            # signal icon
            icon="󰤯"
            (( signal >= 75 )) && icon="󰤨"
            (( signal >= 50 && signal < 75 )) && icon="󰤥"
            (( signal >= 25 && signal < 50 )) && icon="󰤢"

            # lock icon for secured networks
            lock=""
            [[ -n "$security" && "$security" != "--" ]] && lock=" 󰌾"

            # mark current
            marker=""
            [[ "$ssid" == "$current_ssid" ]] && marker=" ●"

            echo "$icon  $ssid  ${signal}%${lock}${marker}"
        done)

    if [[ -n "$networks" ]]; then
        menu="$menu\n$networks"
    fi

    # disconnect option if connected
    if [[ -n "$current_ssid" ]]; then
        menu="$menu\n󰅙  disconnect ($current_ssid)"
    fi
fi

# --- SHOW MENU ---
choice=$(echo -e "$menu" | rofi -dmenu \
    -p "wifi" \
    -theme "$THEME" \
    -theme-str "$THEME_STR" \
    -no-custom \
    -selected-row 0) || exit 0

# --- HANDLE CHOICE ---
case "$choice" in
    *"disable wifi"*)
        nmcli radio wifi off
        notify "WiFi disabled"
        ;;
    *"enable wifi"*)
        nmcli radio wifi on
        notify "WiFi enabled"
        ;;
    *"disconnect"*)
        if [[ -n "${active_device:-}" ]]; then
            nmcli dev disconnect "$active_device" 2>/dev/null || nmcli con down "$current_ssid" 2>/dev/null
        else
            nmcli con down "$current_ssid" 2>/dev/null
        fi
        notify "Disconnected from $current_ssid"
        ;;
    *)
        # extract ssid (between first icon and signal percentage)
        ssid=$(echo "$choice" | sed 's/^[^ ]* *//;s/  [0-9]*%.*$//')

        if [[ -z "$ssid" ]]; then
            exit 0
        fi

        # check if we have a saved connection
        if nmcli -t -f name con show | grep -qx "$ssid"; then
            notify "Connecting to $ssid..."
            nmcli con up "$ssid" && notify "Connected to $ssid" || notify "Failed to connect"
        else
            # prompt for password
            password=$(rofi -dmenu \
                -p "password" \
                -theme "$THEME" \
                -theme-str 'window { width: 380px; } listview { lines: 0; } entry { placeholder: "enter password..."; }' \
                -password) || exit 0

            if [[ -n "$password" ]]; then
                notify "Connecting to $ssid..."
                nmcli dev wifi connect "$ssid" password "$password" && \
                    notify "Connected to $ssid" || \
                    notify "Failed to connect to $ssid"
            fi
        fi
        ;;
esac
