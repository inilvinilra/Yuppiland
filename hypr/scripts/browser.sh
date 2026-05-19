#!/usr/bin/env bash
set -euo pipefail

pick_browser() {
    local candidates=(
        "brave"
        "zen-browser"
        "zen"
        "firefox"
        "chromium"
        "ungoogled-chromium"
    )

    local browser
    for browser in "${candidates[@]}"; do
        if command -v "$browser" >/dev/null 2>&1; then
            printf '%s\n' "$browser"
            return 0
        fi
    done

    return 1
}

browser=$(pick_browser) || {
    notify-send "Browser" "No supported browser found" -t 3000
    exit 1
}

exec "$browser" "$@"
