#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"

R='\033[38;2;204;68;68m'
G='\033[38;2;136;136;136m'
W='\033[38;2;204;204;204m'
D='\033[38;2;85;85;85m'
N='\033[0m'

ok() { echo -e "${G}ok${N}   $1"; }
warn() { echo -e "${R}warn${N} $1"; }
info() { echo -e "${D}info${N} $1"; }
die() { echo -e "${R}error${N} $1" >&2; exit 1; }

usage() {
    cat <<'EOF'
VOID control

Usage:
  ./voidctl.sh health
  ./voidctl.sh sync
  ./voidctl.sh opacity solid|glass|ghost|focus
  ./voidctl.sh sddm

Commands:
  health    Validate commands, packages, assets, and common config syntax.
  sync      Copy current repo configs into ~/.config and reload live services.
  opacity   Apply a transparency preset to Hyprland, Kitty, Waybar, Rofi, Dunst.
  sddm      Install the VOID SDDM theme with the current wallpaper.
EOF
}

have() { command -v "$1" >/dev/null 2>&1; }

copy_dir() {
    local src="$1"
    local dst="$2"
    [[ -e "$src" ]] || return 0
    mkdir -p "$dst"
    cp -a "$src"/. "$dst"/
}

sync_configs() {
    mkdir -p "$CONFIG_DIR"
    copy_dir "$ROOT_DIR/hypr" "$CONFIG_DIR/hypr"
    copy_dir "$ROOT_DIR/waybar" "$CONFIG_DIR/waybar"
    copy_dir "$ROOT_DIR/rofi" "$CONFIG_DIR/rofi"
    copy_dir "$ROOT_DIR/kitty" "$CONFIG_DIR/kitty"
    copy_dir "$ROOT_DIR/fastfetch" "$CONFIG_DIR/fastfetch"
    copy_dir "$ROOT_DIR/dunst" "$CONFIG_DIR/dunst"
    copy_dir "$ROOT_DIR/gtk-3.0" "$CONFIG_DIR/gtk-3.0"
    copy_dir "$ROOT_DIR/gtk-4.0" "$CONFIG_DIR/gtk-4.0"
    copy_dir "$ROOT_DIR/qt6ct" "$CONFIG_DIR/qt6ct"

    mkdir -p "$CONFIG_DIR/icons" "$HOME/.icons"
    copy_dir "$ROOT_DIR/icons/default" "$CONFIG_DIR/icons/default"
    copy_dir "$ROOT_DIR/icons/default" "$HOME/.icons/default"

    cp -f "$ROOT_DIR/brave-flags.conf" "$CONFIG_DIR/brave-flags.conf" 2>/dev/null || true
    cp -f "$ROOT_DIR/chromium-flags.conf" "$CONFIG_DIR/chromium-flags.conf" 2>/dev/null || true
    cp -f "$ROOT_DIR/bash/.bashrc_void" "$HOME/.bashrc_void" 2>/dev/null || true

    mkdir -p "$CONFIG_DIR/hypr/wallpaper"
    if [[ -f "$ROOT_DIR/image copy.png" ]]; then
        cp -f "$ROOT_DIR/image copy.png" "$CONFIG_DIR/hypr/wallpaper/void.png"
    elif [[ -f "$ROOT_DIR/image.png" ]]; then
        cp -f "$ROOT_DIR/image.png" "$CONFIG_DIR/hypr/wallpaper/void.png"
    fi

    chmod +x "$CONFIG_DIR/hypr/scripts/"*.sh 2>/dev/null || true
    chmod +x "$CONFIG_DIR/waybar/scripts/"*.sh 2>/dev/null || true

    if have hyprctl && [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
        hyprctl reload >/dev/null || warn "Hyprland reload failed"
        pkill -x waybar 2>/dev/null || true
        pkill -x dunst 2>/dev/null || true
        setsid -f waybar >/tmp/void-waybar.log 2>&1 || true
        setsid -f dunst >/tmp/void-dunst.log 2>&1 || true
        pkill -x hyprpaper 2>/dev/null || true
        setsid -f hyprpaper >/tmp/void-hyprpaper.log 2>&1 || true
    fi

    ok "configs synced"
}

replace_value() {
    local file="$1"
    local pattern="$2"
    local replacement="$3"
    perl -0pi -e "s/${pattern}/${replacement}/g" "$file"
}

apply_opacity() {
    local profile="${1:-}"
    local kitty waybar rofi dunst active inactive codex_active codex_inactive

    case "$profile" in
        solid)
            kitty="0.94"; waybar="0.88"; rofi="cc"; dunst="10"
            active="0.94"; inactive="0.88"; codex_active="0.96"; codex_inactive="0.90"
            ;;
        glass)
            kitty="0.78"; waybar="0.60"; rofi="99"; dunst="26"
            active="0.82"; inactive="0.68"; codex_active="0.88"; codex_inactive="0.78"
            ;;
        ghost)
            kitty="0.68"; waybar="0.48"; rofi="80"; dunst="34"
            active="0.74"; inactive="0.56"; codex_active="0.82"; codex_inactive="0.68"
            ;;
        focus)
            kitty="0.82"; waybar="0.64"; rofi="aa"; dunst="22"
            active="0.88"; inactive="0.58"; codex_active="0.92"; codex_inactive="0.70"
            ;;
        *)
            die "unknown opacity profile: ${profile:-missing}"
            ;;
    esac

    replace_value "$ROOT_DIR/kitty/kitty.conf" 'background_opacity +[0-9.]+' "background_opacity      $kitty"
    replace_value "$ROOT_DIR/waybar/style.css" 'background-color: alpha\(@bg, [0-9.]+\);' "background-color: alpha(@bg, $waybar);"
    replace_value "$ROOT_DIR/rofi/themes/void.rasi" 'bg: +#[0-9a-fA-F]{8};' "bg:         #000000$rofi;"
    replace_value "$ROOT_DIR/dunst/dunstrc" 'transparency = [0-9]+' "transparency = $dunst"

    replace_value "$ROOT_DIR/hypr/hyprland.conf" 'opacity 0\.[0-9]+ 0\.[0-9]+ 1\.0' "opacity $active $inactive 1.0"
    replace_value "$ROOT_DIR/hypr/hyprland.conf" 'match:class (Codex|antigravity|cursor|VSCodium), opacity 0\.[0-9]+ 0\.[0-9]+ 1\.0' "match:class \\1, opacity $codex_active $codex_inactive 1.0"

    sync_configs
    ok "opacity profile applied: $profile"
}

health() {
    local failures=0
    local commands=(
        Hyprland hyprctl hyprpaper hyprlock waybar rofi kitty fastfetch
        dunst notify-send grim slurp wl-copy wl-paste cliphist jq
        wpctl brightnessctl playerctl nmcli bluetoothctl
    )

    for cmd in "${commands[@]}"; do
        if have "$cmd"; then ok "command: $cmd"; else warn "missing command: $cmd"; failures=$((failures + 1)); fi
    done

    local packages=(
        hyprland hyprpaper hyprlock xdg-desktop-portal-hyprland
        waybar rofi kitty fastfetch dunst libnotify
        grim slurp wl-clipboard cliphist jq pacman-contrib
        qt6ct thunar tumbler file-roller papirus-icon-theme
    )

    if have pacman; then
        for pkg in "${packages[@]}"; do
            if pacman -Qq "$pkg" >/dev/null 2>&1; then ok "package: $pkg"; else warn "missing package: $pkg"; failures=$((failures + 1)); fi
        done
    fi

    [[ -f "$ROOT_DIR/hypr/hyprland.conf" ]] && ok "hyprland config present" || { warn "missing hyprland config"; failures=$((failures + 1)); }
    [[ -f "$ROOT_DIR/hypr/hyprpaper.conf" ]] && ok "hyprpaper config present" || { warn "missing hyprpaper config"; failures=$((failures + 1)); }
    [[ -f "$ROOT_DIR/image copy.png" || -f "$ROOT_DIR/image.png" ]] && ok "wallpaper asset present" || { warn "missing wallpaper asset"; failures=$((failures + 1)); }

    bash -n "$ROOT_DIR"/hypr/scripts/*.sh "$ROOT_DIR"/waybar/scripts/*.sh "$ROOT_DIR/voidctl.sh" && ok "shell scripts parse"
    jq empty "$ROOT_DIR/waybar/config" >/dev/null && ok "waybar config parses"
    fastfetch --config "$ROOT_DIR/fastfetch/config.jsonc" >/dev/null && ok "fastfetch config parses"

    if [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]] && have hyprctl; then
        hyprctl reload >/dev/null && ok "hyprland reloads"
    else
        info "Hyprland session not detected; skipping live reload check"
    fi

    if (( failures > 0 )); then
        warn "$failures health check item(s) need attention"
        return 1
    fi

    ok "health check clean"
}

install_sddm() {
    [[ -d "$ROOT_DIR/sddm/void" ]] || die "missing sddm/void"
    sudo rm -rf /usr/share/sddm/themes/void
    sudo mkdir -p /usr/share/sddm/themes/void /etc/sddm.conf.d
    sudo cp -r "$ROOT_DIR/sddm/void/"* /usr/share/sddm/themes/void/
    if [[ -f "$ROOT_DIR/image copy.png" ]]; then
        sudo cp -f "$ROOT_DIR/image copy.png" /usr/share/sddm/themes/void/background.png
    elif [[ -f "$ROOT_DIR/image.png" ]]; then
        sudo cp -f "$ROOT_DIR/image.png" /usr/share/sddm/themes/void/background.png
    fi
    printf '[Theme]\nCurrent=void\n\n[General]\nGreeterEnvironment=QT_QPA_PLATFORM=wayland,QT_QPA_PLATFORMTHEME=qt6ct\n' |
        sudo tee /etc/sddm.conf.d/10-void-theme.conf >/dev/null
    ok "SDDM theme installed"
}

case "${1:-}" in
    health) health ;;
    sync) sync_configs ;;
    opacity) apply_opacity "${2:-}" ;;
    sddm) install_sddm ;;
    -h|--help|help|"") usage ;;
    *) die "unknown command: $1" ;;
esac
