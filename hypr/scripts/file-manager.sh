#!/usr/bin/env bash
set -euo pipefail

pick_manager() {
    local candidates=(
        "thunar"
        "dolphin"
        "pcmanfm"
        "nautilus"
        "nemo"
    )

    local manager
    for manager in "${candidates[@]}"; do
        if command -v "$manager" >/dev/null 2>&1; then
            printf '%s\n' "$manager"
            return 0
        fi
    done

    return 1
}

manager=$(pick_manager) || {
    notify-send "Files" "No supported file manager found" -t 3000
    exit 1
}

exec "$manager" "$@"
