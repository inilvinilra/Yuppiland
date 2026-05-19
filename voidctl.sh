#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
THEME_DIR="$ROOT_DIR/themes"
WALLPAPER_DIR="$ROOT_DIR/assets/wallpapers"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/void"
STATE_FILE="$STATE_DIR/current-theme"
WALLPAPER_STATE_FILE="$STATE_DIR/current-wallpaper"

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
  ./voidctl.sh install [pkg_user.lst]
  ./voidctl.sh apply [theme] [wallpaper]
  ./voidctl.sh sync
  ./voidctl.sh firefox
  ./voidctl.sh theme list|current|apply <name>
  ./voidctl.sh wallpaper list|current|apply <name|path>
  ./voidctl.sh opacity solid|glass|ghost|focus
  ./voidctl.sh sddm

Commands:
  health    Validate commands, packages, assets, and common config syntax.
  install   Run the host installer from this repository.
  apply     Apply a theme and wallpaper, then sync live configs.
  sync      Copy current repo configs into ~/.config and reload live services.
  firefox   Link Firefox userChrome.css and userContent.css into the default profile.
  theme     List, show, or apply VOID theme packs.
  wallpaper List, show, or apply VOID wallpaper assets.
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

current_wallpaper_path() {
    if [[ -f "$WALLPAPER_STATE_FILE" ]]; then
        local saved
        saved="$(cat "$WALLPAPER_STATE_FILE")"
        [[ -f "$saved" ]] && printf '%s\n' "$saved" && return 0
    fi

    if [[ -f "$ROOT_DIR/hypr/wallpaper/void.png" ]]; then
        printf '%s\n' "$ROOT_DIR/hypr/wallpaper/void.png"
    elif [[ -f "$WALLPAPER_DIR/void-contours.jpg" ]]; then
        printf '%s\n' "$WALLPAPER_DIR/void-contours.jpg"
    elif [[ -f "$ROOT_DIR/image copy.png" ]]; then
        printf '%s\n' "$ROOT_DIR/image copy.png"
    elif [[ -f "$ROOT_DIR/image.png" ]]; then
        printf '%s\n' "$ROOT_DIR/image.png"
    else
        return 1
    fi
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
    copy_dir "$ROOT_DIR/cava" "$CONFIG_DIR/cava"

    mkdir -p "$CONFIG_DIR/icons" "$HOME/.icons"
    copy_dir "$ROOT_DIR/icons/default" "$CONFIG_DIR/icons/default"
    copy_dir "$ROOT_DIR/icons/default" "$HOME/.icons/default"

    mkdir -p "$CONFIG_DIR/nvim/colors"
    cp -f "$ROOT_DIR/nvim/colors/void.lua" "$CONFIG_DIR/nvim/colors/void.lua" 2>/dev/null || true

    cp -f "$ROOT_DIR/brave-flags.conf" "$CONFIG_DIR/brave-flags.conf" 2>/dev/null || true
    cp -f "$ROOT_DIR/chromium-flags.conf" "$CONFIG_DIR/chromium-flags.conf" 2>/dev/null || true
    cp -f "$ROOT_DIR/bash/.bashrc_void" "$HOME/.bashrc_void" 2>/dev/null || true

    mkdir -p "$CONFIG_DIR/hypr/wallpaper"
    local wallpaper
    if wallpaper="$(current_wallpaper_path)"; then
        cp -f "$wallpaper" "$CONFIG_DIR/hypr/wallpaper/void.png"
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

theme_conf() {
    local theme="$1"
    local conf="$THEME_DIR/$theme/theme.conf"
    [[ -f "$conf" ]] || die "theme not found: $theme"
    printf '%s\n' "$conf"
}

load_theme() {
    local conf="$1"
    local key value
    while IFS='=' read -r key value; do
        [[ -z "$key" || "$key" == \#* ]] && continue
        key="${key//[^a-zA-Z0-9_]/}"
        printf -v "$key" '%s' "$value"
    done < "$conf"
}

set_waybar_colors() {
    local file="$ROOT_DIR/waybar/colors.css"

    replace_value "$file" '@define-color bg +#[0-9a-fA-F]{6};' "@define-color bg       $bg;"
    replace_value "$file" '@define-color surface +#[0-9a-fA-F]{6};' "@define-color surface  $surface;"
    replace_value "$file" '@define-color overlay +#[0-9a-fA-F]{6};' "@define-color overlay  $overlay;"
    replace_value "$file" '@define-color muted +#[0-9a-fA-F]{6};' "@define-color muted    $muted;"
    replace_value "$file" '@define-color subtle +#[0-9a-fA-F]{6};' "@define-color subtle   $subtle;"
    replace_value "$file" '@define-color subtext +#[0-9a-fA-F]{6};' "@define-color subtext  $subtext;"
    replace_value "$file" '@define-color text +#[0-9a-fA-F]{6};' "@define-color text     $text;"
    replace_value "$file" '@define-color bright +#[0-9a-fA-F]{6};' "@define-color bright   $bright;"
    replace_value "$file" '@define-color white +#[0-9a-fA-F]{6};' "@define-color white    $white;"
    replace_value "$file" '@define-color red +#[0-9a-fA-F]{6};' "@define-color red      $red;"
    replace_value "$file" '@define-color yellow +#[0-9a-fA-F]{6};' "@define-color yellow   $yellow;"
    replace_value "$file" '@define-color green +#[0-9a-fA-F]{6};' "@define-color green    $green;"
}

apply_theme_values() {
    local conf="$1"
    load_theme "$conf"

    set_waybar_colors

    replace_value "$ROOT_DIR/kitty/kitty.conf" '^background_opacity +[0-9.]+' "background_opacity      $kitty_opacity"
    replace_value "$ROOT_DIR/kitty/kitty.conf" '^foreground +#[0-9a-fA-F]{6}' "foreground              $text"
    replace_value "$ROOT_DIR/kitty/kitty.conf" '^background +#[0-9a-fA-F]{6}' "background              $bg"
    replace_value "$ROOT_DIR/kitty/kitty.conf" '^selection_background +#[0-9a-fA-F]{6}' "selection_background     $text"

    replace_value "$ROOT_DIR/waybar/style.css" 'background-color: alpha\(@bg, [0-9.]+\);' "background-color: alpha(@bg, $waybar_opacity);"
    replace_value "$ROOT_DIR/waybar/style.css" 'background-color: alpha\(@surface, [0-9.]+\);' "background-color: alpha(@surface, $tooltip_opacity);"

    replace_value "$ROOT_DIR/rofi/themes/void.rasi" 'bg: +#[0-9a-fA-F]{8};' "bg:         ${bg}${rofi_alpha};"
    replace_value "$ROOT_DIR/rofi/themes/void.rasi" 'bg-solid: +#[0-9a-fA-F]{6};' "bg-solid:   $surface;"
    replace_value "$ROOT_DIR/rofi/themes/void.rasi" 'border-col: +#[0-9a-fA-F]{6};' "border-col: $overlay;"
    replace_value "$ROOT_DIR/rofi/themes/void.rasi" 'muted: +#[0-9a-fA-F]{6};' "muted:      $muted;"
    replace_value "$ROOT_DIR/rofi/themes/void.rasi" 'subtle: +#[0-9a-fA-F]{6};' "subtle:     $subtle;"
    replace_value "$ROOT_DIR/rofi/themes/void.rasi" 'fg: +#[0-9a-fA-F]{6};' "fg:         $text;"
    replace_value "$ROOT_DIR/rofi/themes/void.rasi" 'bright: +#[0-9a-fA-F]{6};' "bright:     $bright;"
    replace_value "$ROOT_DIR/rofi/themes/void.rasi" 'sel-bg: +#[0-9a-fA-F]{6};' "sel-bg:     $overlay;"
    replace_value "$ROOT_DIR/rofi/themes/void.rasi" 'sel-fg: +#[0-9a-fA-F]{6};' "sel-fg:     $bright;"
    replace_value "$ROOT_DIR/rofi/themes/void.rasi" 'urgent: +#[0-9a-fA-F]{6};' "urgent:     $red;"

    replace_value "$ROOT_DIR/dunst/dunstrc" 'transparency = [0-9]+' "transparency = $dunst_transparency"
    replace_value "$ROOT_DIR/dunst/dunstrc" 'background = "#[0-9a-fA-F]{6}"' "background = \"$surface\""
    replace_value "$ROOT_DIR/dunst/dunstrc" 'foreground = "#[0-9a-fA-F]{6}"' "foreground = \"$text\""
    replace_value "$ROOT_DIR/dunst/dunstrc" 'frame_color = "#[0-9a-fA-F]{6}"' "frame_color = \"$overlay\""
    replace_value "$ROOT_DIR/dunst/dunstrc" 'highlight = "#[0-9a-fA-F]{6}"' "highlight = \"$text\""

    replace_value "$ROOT_DIR/hypr/hyprland.conf" 'size = [0-9]+\\n        passes = [0-9]+' "size = $blur_size\\n        passes = $blur_passes"
    replace_value "$ROOT_DIR/hypr/hyprland.conf" 'dim_strength = [0-9.]+' "dim_strength = $dim_strength"
    replace_value "$ROOT_DIR/hypr/hyprland.conf" 'opacity 0\.[0-9]+ 0\.[0-9]+ 1\.0' "opacity $window_active $window_inactive 1.0"
    replace_value "$ROOT_DIR/hypr/hyprland.conf" 'match:class (Codex|antigravity|cursor|VSCodium), opacity 0\.[0-9]+ 0\.[0-9]+ 1\.0' "match:class \\1, opacity $editor_active $editor_inactive 1.0"

    if [[ -n "${wallpaper:-}" && -f "$ROOT_DIR/$wallpaper" ]]; then
        mkdir -p "$ROOT_DIR/hypr/wallpaper"
        cp -f "$ROOT_DIR/$wallpaper" "$ROOT_DIR/hypr/wallpaper/void.png"
    fi
}

theme_list() {
    local theme conf name desc
    shopt -s nullglob
    for conf in "$THEME_DIR"/*/theme.conf; do
        theme="$(basename "$(dirname "$conf")")"
        name=""
        desc=""
        while IFS='=' read -r key value; do
            case "$key" in
                name) name="$value" ;;
                description) desc="$value" ;;
            esac
        done < "$conf"
        printf '%-14s %s%s\n' "$theme" "${name:-$theme}" "${desc:+ - $desc}"
    done
}

theme_current() {
    if [[ -f "$STATE_FILE" ]]; then
        cat "$STATE_FILE"
    else
        echo "unknown"
    fi
}

theme_apply() {
    local theme="$1"
    local conf
    conf="$(theme_conf "$theme")"
    apply_theme_values "$conf"
    mkdir -p "$STATE_DIR"
    printf '%s\n' "$theme" > "$STATE_FILE"
    sync_configs
    ok "theme applied: $theme"
}

theme_command() {
    local action="${1:-}"
    case "$action" in
        list) theme_list ;;
        current) theme_current ;;
        apply) [[ -n "${2:-}" ]] || die "missing theme name"; theme_apply "$2" ;;
        *) die "usage: ./voidctl.sh theme list|current|apply <name>" ;;
    esac
}

wallpaper_list() {
    shopt -s nullglob
    for file in "$WALLPAPER_DIR"/*.{jpg,jpeg,png,webp}; do
        [[ -f "$file" ]] || continue
        printf '%s\n' "$(basename "$file")"
    done
}

wallpaper_current() {
    if current_wallpaper_path >/dev/null; then
        current_wallpaper_path
    else
        echo "unknown"
    fi
}

wallpaper_apply() {
    local input="$1"
    local do_sync="${2:-sync}"
    local src=""

    if [[ -f "$input" ]]; then
        src="$(realpath "$input")"
    elif [[ -f "$WALLPAPER_DIR/$input" ]]; then
        src="$WALLPAPER_DIR/$input"
    elif [[ -f "$WALLPAPER_DIR/$input.jpg" ]]; then
        src="$WALLPAPER_DIR/$input.jpg"
    elif [[ -f "$WALLPAPER_DIR/$input.png" ]]; then
        src="$WALLPAPER_DIR/$input.png"
    else
        die "wallpaper not found: $input"
    fi

    mkdir -p "$ROOT_DIR/hypr/wallpaper" "$STATE_DIR"
    cp -f "$src" "$ROOT_DIR/hypr/wallpaper/void.png"
    printf '%s\n' "$src" > "$WALLPAPER_STATE_FILE"

    if [[ "$do_sync" == "sync" && -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]] && have hyprctl; then
        sync_configs
    fi

    ok "wallpaper applied: $(basename "$src")"
}

wallpaper_command() {
    local action="${1:-}"
    case "$action" in
        list) wallpaper_list ;;
        current) wallpaper_current ;;
        apply) [[ -n "${2:-}" ]] || die "missing wallpaper name/path"; wallpaper_apply "$2" ;;
        *) die "usage: ./voidctl.sh wallpaper list|current|apply <name|path>" ;;
    esac
}

apply_opacity() {
    local profile="${1:-}"

    case "$profile" in
        solid) theme_apply void-solid; return ;;
        glass) theme_apply void-glass; return ;;
        ghost) theme_apply void-ghost; return ;;
        focus) theme_apply void-focus; return ;;
        *) die "unknown opacity profile: ${profile:-missing}" ;;
    esac

    die "unknown opacity profile: ${profile:-missing}"
}

health() {
    local failures=0
    local commands=(
        Hyprland hyprctl hyprpaper hyprlock waybar rofi kitty fastfetch
        dunst notify-send grim slurp wl-copy wl-paste cliphist jq
        wpctl brightnessctl playerctl nmcli bluetoothctl sddm
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
    [[ -d "$ROOT_DIR/assets/wallpapers" ]] && ok "wallpaper asset directory present" || { warn "missing assets/wallpapers"; failures=$((failures + 1)); }
    [[ -f "$ROOT_DIR/sddm/void/Main.qml" ]] && ok "SDDM theme present" || { warn "missing SDDM theme"; failures=$((failures + 1)); }
    [[ -f "$ROOT_DIR/firefox/chrome/userChrome.css" ]] && ok "Firefox chrome present" || { warn "missing Firefox chrome"; failures=$((failures + 1)); }
    [[ -f "$ROOT_DIR/nvim/colors/void.lua" ]] && ok "Neovim colorscheme present" || { warn "missing Neovim colorscheme"; failures=$((failures + 1)); }
    if current_wallpaper_path >/dev/null; then
        ok "wallpaper asset present"
    else
        warn "missing wallpaper asset"
        failures=$((failures + 1))
    fi

    if bash -n "$ROOT_DIR"/hypr/scripts/*.sh "$ROOT_DIR"/waybar/scripts/*.sh "$ROOT_DIR/voidctl.sh" "$ROOT_DIR/install.sh"; then
        ok "shell scripts parse"
    else
        warn "shell script parse failed"
        failures=$((failures + 1))
    fi

    if jq empty "$ROOT_DIR/waybar/config" >/dev/null; then
        ok "waybar config parses"
    else
        warn "waybar config parse failed"
        failures=$((failures + 1))
    fi

    if have fastfetch; then
        fastfetch --config "$ROOT_DIR/fastfetch/config.jsonc" >/dev/null && ok "fastfetch config parses"
    else
        info "fastfetch not installed; skipping config parse"
    fi

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
    local wallpaper
    if wallpaper="$(current_wallpaper_path)"; then
        sudo cp -f "$wallpaper" /usr/share/sddm/themes/void/background.png
    fi
    printf '[Theme]\nCurrent=void\n\n[General]\nGreeterEnvironment=QT_QPA_PLATFORM=wayland,QT_QPA_PLATFORMTHEME=qt6ct\n' |
        sudo tee /etc/sddm.conf.d/10-void-theme.conf >/dev/null
    ok "SDDM theme installed"
}

link_firefox_chrome() {
    local profile_dir="$HOME/.mozilla/firefox"
    local profile=""

    [[ -d "$profile_dir" ]] || die "Firefox profile directory not found. Run Firefox once first."

    profile="$(find "$profile_dir" -maxdepth 1 -name '*.default-release' -type d | head -1)"
    [[ -n "$profile" ]] || profile="$(find "$profile_dir" -maxdepth 1 -name '*.default' -type d | head -1)"
    [[ -n "$profile" ]] || die "No Firefox default profile found."

    mkdir -p "$profile/chrome"
    ln -sfn "$ROOT_DIR/firefox/chrome/userChrome.css" "$profile/chrome/userChrome.css"
    ln -sfn "$ROOT_DIR/firefox/chrome/userContent.css" "$profile/chrome/userContent.css"
    ok "Firefox chrome linked to $(basename "$profile")"
    info "Set toolkit.legacyUserProfileCustomizations.stylesheets=true in about:config"
}

host_install() {
    bash "$ROOT_DIR/install.sh" "$@"
}

apply_suite() {
    local theme="${1:-void-glass}"
    local wallpaper="${2:-void-contours.jpg}"

    wallpaper_apply "$wallpaper" "nosync"
    theme_apply "$theme"
    ok "VOID suite applied: theme=$theme wallpaper=$wallpaper"
    info "Optional: ./voidctl.sh sddm"
    info "Optional: ./voidctl.sh firefox"
}

case "${1:-}" in
    health) health ;;
    install) shift; host_install "$@" ;;
    apply) shift; apply_suite "$@" ;;
    sync) sync_configs ;;
    firefox) link_firefox_chrome ;;
    theme) shift; theme_command "$@" ;;
    wallpaper) shift; wallpaper_command "$@" ;;
    opacity) apply_opacity "${2:-}" ;;
    sddm) install_sddm ;;
    -h|--help|help|"") usage ;;
    *) die "unknown command: $1" ;;
esac
