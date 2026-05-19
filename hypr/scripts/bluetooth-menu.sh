#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  VOID — Bluetooth Menu (Rofi + bluetoothctl)                ║
# ║  ~/.config/hypr/scripts/bluetooth-menu.sh                    ║
# ╚══════════════════════════════════════════════════════════════╝
set -euo pipefail

THEME="$HOME/.config/rofi/themes/void.rasi"
THEME_STR='window { width: 380px; } listview { lines: 10; }'

notify() { notify-send "Bluetooth" "$1" -t 3000; }

# --- GET CURRENT STATE ---
bt_powered=$(bluetoothctl show | grep -q "Powered: yes" && echo "on" || echo "off")

# --- BUILD MENU ---
if [[ "$bt_powered" == "on" ]]; then
    toggle_label="󰂲  disable bluetooth"

    # start scan briefly
    bluetoothctl --timeout 3 scan on &>/dev/null &

    # get paired devices with connection status
    paired_devices=$(bluetoothctl devices Paired | while read -r _ mac name; do
        if bluetoothctl info "$mac" | grep -q "Connected: yes"; then
            echo "󰂱  $name  ● connected"
        else
            echo "󰂯  $name  ○ paired"
        fi
    done)

    # get discovered (non-paired) devices
    all_devices=$(bluetoothctl devices | awk '{print $2}')
    paired_macs=$(bluetoothctl devices Paired | awk '{print $2}')

    new_devices=""
    for mac in $all_devices; do
        if ! echo "$paired_macs" | grep -qx "$mac"; then
            name=$(bluetoothctl info "$mac" 2>/dev/null | grep "Name:" | sed 's/.*Name: //')
            [[ -n "$name" ]] && new_devices+="󰂰  $name  ◌ new\n"
        fi
    done

    menu="$toggle_label"
    [[ -n "$paired_devices" ]] && menu="$menu\n$paired_devices"
    [[ -n "$new_devices" ]] && menu="$menu\n$(echo -e "$new_devices" | sed '/^$/d')"
    menu="$menu\n󰑐  scan for devices"
else
    toggle_label="󰂯  enable bluetooth"
    menu="$toggle_label"
fi

# --- SHOW MENU ---
choice=$(echo -e "$menu" | rofi -dmenu \
    -p "bluetooth" \
    -theme "$THEME" \
    -theme-str "$THEME_STR" \
    -no-custom \
    -selected-row 0) || exit 0

# --- RESOLVE DEVICE MAC FROM NAME ---
get_mac() {
    local name="$1"
    bluetoothctl devices | while read -r _ mac rest; do
        if [[ "$rest" == "$name" ]]; then
            echo "$mac"
            return
        fi
    done
}

# --- HANDLE CHOICE ---
case "$choice" in
    *"disable bluetooth"*)
        bluetoothctl power off
        notify "Bluetooth disabled"
        ;;
    *"enable bluetooth"*)
        bluetoothctl power on
        notify "Bluetooth enabled"
        ;;
    *"scan for devices"*)
        notify "Scanning for 5 seconds..."
        bluetoothctl --timeout 5 scan on &>/dev/null
        # re-run menu
        exec "$0"
        ;;
    *"connected"*)
        device_name=$(echo "$choice" | sed 's/^[^ ]* *//;s/  ● connected$//')
        mac=$(get_mac "$device_name")
        if [[ -n "$mac" ]]; then
            # submenu: disconnect or remove
            action=$(echo -e "󰅙  disconnect\n󰆴  remove pairing" | rofi -dmenu \
                -p "$device_name" \
                -theme "$THEME" \
                -theme-str 'window { width: 280px; } listview { lines: 2; }' \
                -no-custom) || exit 0

            case "$action" in
                *disconnect*) bluetoothctl disconnect "$mac"; notify "Disconnected $device_name" ;;
                *remove*)     bluetoothctl remove "$mac"; notify "Removed $device_name" ;;
            esac
        fi
        ;;
    *"paired"*)
        device_name=$(echo "$choice" | sed 's/^[^ ]* *//;s/  ○ paired$//')
        mac=$(get_mac "$device_name")
        if [[ -n "$mac" ]]; then
            notify "Connecting to $device_name..."
            bluetoothctl connect "$mac" && notify "Connected to $device_name" || notify "Failed to connect"
        fi
        ;;
    *"new"*)
        device_name=$(echo "$choice" | sed 's/^[^ ]* *//;s/  ◌ new$//')
        mac=$(get_mac "$device_name")
        if [[ -n "$mac" ]]; then
            notify "Pairing $device_name..."
            bluetoothctl pair "$mac" && \
            bluetoothctl trust "$mac" && \
            bluetoothctl connect "$mac" && \
            notify "Paired & connected to $device_name" || \
            notify "Failed to pair $device_name"
        fi
        ;;
esac
