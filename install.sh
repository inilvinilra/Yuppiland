#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  VOID — Dotfiles Installer                                   ║
# ║  Run: chmod +x install.sh && ./install.sh                    ║
# ╚══════════════════════════════════════════════════════════════╝
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$HOME/.config"
BACKUP_DIR="$HOME/.config-backup-$(date +%Y%m%d_%H%M%S)"

# colors (ironic for a void installer)
R='\033[38;2;204;68;68m'
G='\033[38;2;136;136;136m'
W='\033[38;2;204;204;204m'
D='\033[38;2;85;85;85m'
N='\033[0m'

header() { echo -e "\n${W}── $1 ──${N}"; }
info()   { echo -e "${D}  → $1${N}"; }
ok()     { echo -e "${G}  ✓ $1${N}"; }
warn()   { echo -e "${R}  ! $1${N}"; }

echo -e "${W}"
echo "  ██╗   ██╗ ██████╗ ██╗██████╗ "
echo "  ██║   ██║██╔═══██╗██║██╔══██╗"
echo "  ██║   ██║██║   ██║██║██║  ██║"
echo "  ╚██╗ ██╔╝██║   ██║██║██║  ██║"
echo "   ╚████╔╝ ╚██████╔╝██║██████╔╝"
echo "    ╚═══╝   ╚═════╝ ╚═╝╚═════╝ "
echo -e "${D}  arch linux + hyprland dotfiles${N}"
echo ""

# ─────────────────────────────────────────────────────────────
# PHASE 1: DEPENDENCIES
# ─────────────────────────────────────────────────────────────

header "checking dependencies"

PACKAGES=(
    # core WM
    hyprland hyprpaper hypridle hyprlock xdg-desktop-portal-hyprland
    # bar & launcher
    waybar rofi-wayland
    # terminal
    kitty
    # audio
    pipewire wireplumber pipewire-pulse pipewire-alsa pavucontrol
    # notifications
    dunst libnotify
    # file manager & browser
    dolphin firefox
    # screenshots & clipboard
    grim slurp wl-clipboard cliphist
    # fetch & visualizer
    fastfetch cava
    # fonts & themes
    ttf-jetbrains-mono-nerd papirus-icon-theme bibata-cursor-theme
    # networking & bluetooth
    networkmanager bluez bluez-utils
    # utilities
    brightnessctl playerctl jq polkit-kde-agent
    # shell tools
    eza bat fzf
    # display manager
    sddm qt5-quickcontrols2
    # power management
    auto-cpufreq
    # fun
    cowsay
)

missing=()
for pkg in "${PACKAGES[@]}"; do
    if ! pacman -Qq "$pkg" &>/dev/null; then
        missing+=("$pkg")
    fi
done

if [[ ${#missing[@]} -gt 0 ]]; then
    warn "missing ${#missing[@]} packages:"
    for pkg in "${missing[@]}"; do
        echo -e "${D}    - $pkg${N}"
    done
    echo ""
    read -rp "  install missing packages? [Y/n] " answer
    answer=${answer:-Y}
    if [[ "$answer" =~ ^[Yy]$ ]]; then
        sudo pacman -S --needed "${missing[@]}"
        ok "packages installed"
    else
        warn "skipping package install — some things may not work"
    fi
else
    ok "all packages installed"
fi

# ─────────────────────────────────────────────────────────────
# PHASE 2: BACKUP
# ─────────────────────────────────────────────────────────────

header "backing up existing configs"

DIRS_TO_LINK=(
    "hypr"
    "waybar"
    "rofi/themes"
    "kitty"
    "cava"
    "fastfetch"
    "dunst"
    "gtk-3.0"
    "gtk-4.0"
)

needs_backup=false
for dir in "${DIRS_TO_LINK[@]}"; do
    target="$CONFIG_DIR/$dir"
    if [[ -e "$target" ]] && [[ ! -L "$target" ]]; then
        needs_backup=true
        break
    fi
done

if $needs_backup; then
    mkdir -p "$BACKUP_DIR"
    for dir in "${DIRS_TO_LINK[@]}"; do
        target="$CONFIG_DIR/$dir"
        if [[ -e "$target" ]] && [[ ! -L "$target" ]]; then
            mkdir -p "$(dirname "$BACKUP_DIR/$dir")"
            mv "$target" "$BACKUP_DIR/$dir"
            info "backed up $dir"
        fi
    done
    ok "backup saved to $BACKUP_DIR"
else
    ok "no existing configs to backup"
fi

# ─────────────────────────────────────────────────────────────
# PHASE 3: SYMLINK
# ─────────────────────────────────────────────────────────────

header "creating symlinks"

link_config() {
    local src="$DOTFILES_DIR/$1"
    local dst="$CONFIG_DIR/$2"
    mkdir -p "$(dirname "$dst")"
    ln -sfn "$src" "$dst"
    ok "linked $2"
}

link_config "hypr"         "hypr"
link_config "waybar"       "waybar"
link_config "rofi/themes"  "rofi/themes"
link_config "kitty"        "kitty"
link_config "cava"         "cava"
link_config "fastfetch"    "fastfetch"
link_config "dunst"        "dunst"
link_config "gtk-3.0"      "gtk-3.0"
link_config "gtk-4.0"      "gtk-4.0"
# cursor theme goes to ~/.icons (XDG spec), not ~/.config/icons
mkdir -p "$HOME/.icons"
ln -sfn "$DOTFILES_DIR/icons/default" "$HOME/.icons/default"
ok "linked ~/.icons/default"

# neovim colorscheme
mkdir -p "$CONFIG_DIR/nvim/colors"
ln -sfn "$DOTFILES_DIR/nvim/colors/void.lua" "$CONFIG_DIR/nvim/colors/void.lua"
ok "linked nvim void colorscheme"

# ─────────────────────────────────────────────────────────────
# PHASE 4: BASH
# ─────────────────────────────────────────────────────────────

header "configuring shell"

BASHRC_LINE="source $DOTFILES_DIR/bash/.bashrc_void"
if ! grep -qF "$BASHRC_LINE" "$HOME/.bashrc" 2>/dev/null; then
    echo "" >> "$HOME/.bashrc"
    echo "# --- VOID ---" >> "$HOME/.bashrc"
    echo "$BASHRC_LINE" >> "$HOME/.bashrc"
    ok "added void bash config to ~/.bashrc"
else
    ok "bash config already sourced"
fi

# ─────────────────────────────────────────────────────────────
# PHASE 5: PERMISSIONS
# ─────────────────────────────────────────────────────────────

header "setting permissions"

chmod +x "$DOTFILES_DIR/hypr/scripts/"*.sh
chmod +x "$DOTFILES_DIR/waybar/scripts/"*.sh
ok "scripts marked executable"

# ─────────────────────────────────────────────────────────────
# PHASE 6: WALLPAPER DIRECTORY
# ─────────────────────────────────────────────────────────────

header "wallpaper setup"

mkdir -p "$DOTFILES_DIR/hypr/wallpaper"
if [[ ! -f "$DOTFILES_DIR/hypr/wallpaper/void.png" ]]; then
    warn "place your wallpaper at: $DOTFILES_DIR/hypr/wallpaper/void.png"
    info "creating a pure black fallback wallpaper..."
    if command -v convert &>/dev/null; then
        convert -size 1920x1080 xc:#000000 "$DOTFILES_DIR/hypr/wallpaper/void.png"
        ok "created 1920x1080 black wallpaper"
    else
        warn "install imagemagick to auto-generate fallback wallpaper"
    fi
else
    ok "wallpaper found"
fi

# ─────────────────────────────────────────────────────────────
# PHASE 7: SCREENSHOTS DIRECTORY
# ─────────────────────────────────────────────────────────────

mkdir -p "$HOME/Pictures/Screenshots"
ok "screenshots directory ready"

# ─────────────────────────────────────────────────────────────
# PHASE 8: SDDM THEME
# ─────────────────────────────────────────────────────────────

header "SDDM theme"

if command -v sddm &>/dev/null; then
    echo ""
    read -rp "  install void SDDM theme? (requires sudo) [Y/n] " sddm_answer
    sddm_answer=${sddm_answer:-Y}
    if [[ "$sddm_answer" =~ ^[Yy]$ ]]; then
        sudo mkdir -p /usr/share/sddm/themes/void
        sudo cp -r "$DOTFILES_DIR/sddm/void/"* /usr/share/sddm/themes/void/
        # set theme in sddm config
        sudo mkdir -p /etc/sddm.conf.d
        echo -e "[Theme]\nCurrent=void" | sudo tee /etc/sddm.conf.d/void.conf > /dev/null
        ok "SDDM void theme installed"
    else
        info "skipping SDDM theme"
    fi
else
    info "sddm not installed — skipping theme"
fi

# ─────────────────────────────────────────────────────────────
# PHASE 9: FIREFOX CHROME
# ─────────────────────────────────────────────────────────────

header "Firefox chrome"

FF_PROFILE_DIR="$HOME/.mozilla/firefox"
if [[ -d "$FF_PROFILE_DIR" ]]; then
    # find the default profile directory
    FF_PROFILE=$(find "$FF_PROFILE_DIR" -maxdepth 1 -name '*.default-release' -type d | head -1)
    [[ -z "$FF_PROFILE" ]] && FF_PROFILE=$(find "$FF_PROFILE_DIR" -maxdepth 1 -name '*.default' -type d | head -1)

    if [[ -n "$FF_PROFILE" ]]; then
        mkdir -p "$FF_PROFILE/chrome"
        ln -sfn "$DOTFILES_DIR/firefox/chrome/userChrome.css" "$FF_PROFILE/chrome/userChrome.css"
        ln -sfn "$DOTFILES_DIR/firefox/chrome/userContent.css" "$FF_PROFILE/chrome/userContent.css"
        ok "linked Firefox chrome to $(basename "$FF_PROFILE")"
        info "enable in about:config: toolkit.legacyUserProfileCustomizations.stylesheets = true"
    else
        warn "no Firefox profile found — run Firefox once first, then re-run installer"
    fi
else
    info "Firefox not yet run — skipping chrome install"
fi

# ─────────────────────────────────────────────────────────────
# DONE
# ─────────────────────────────────────────────────────────────

echo ""
echo -e "${W}  ──────────────────────────────────${N}"
echo -e "${W}  VOID installed successfully${N}"
echo -e "${D}  ──────────────────────────────────${N}"
echo ""
echo -e "${D}  next steps:${N}"
echo -e "${D}    1. place wallpaper at hypr/wallpaper/void.png${N}"
echo -e "${D}    2. log out and select Hyprland session${N}"
echo -e "${D}    3. or reload with: hyprctl reload${N}"
echo -e "${D}    4. nvim: set colorscheme void in your init.lua${N}"
echo -e "${D}    5. firefox: enable toolkit.legacyUserProfileCustomizations.stylesheets${N}"
echo ""
