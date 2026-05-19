#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RUNTIME_DIR="$ROOT_DIR/.preview-runtime"
IMAGE_NAME="void-hyprland-preview:v2"
WAYLAND_SOCKET="${WAYLAND_DISPLAY:-wayland-0}"
XDG_RUNTIME="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"

log()  { printf '%s\n' "$*"; }
die()  { printf 'error: %s\n' "$*" >&2; exit 1; }

pick_runtime() {
    if command -v podman >/dev/null 2>&1; then
        echo "podman"
    elif command -v docker >/dev/null 2>&1; then
        echo "docker"
    else
        die "need podman or docker"
    fi
}

ensure_wayland() {
    [[ -S "$XDG_RUNTIME/$WAYLAND_SOCKET" ]] || die "wayland socket not found at $XDG_RUNTIME/$WAYLAND_SOCKET"
}

build_image() {
    local runtime="$1"

    mkdir -p "$RUNTIME_DIR/build"

    cat > "$RUNTIME_DIR/build/Containerfile" <<'EOF'
FROM docker.io/library/archlinux:latest

RUN pacman -Syu --noconfirm && \
    pacman -S --noconfirm --needed \
      hyprland xorg-xwayland kitty waybar dunst rofi-wayland \
      hyprpaper hyprlock hypridle wl-clipboard cliphist jq playerctl \
      brightnessctl pipewire pipewire-jack wireplumber ttf-jetbrains-mono-nerd \
      papirus-icon-theme adwaita-cursors mesa vulkan-icd-loader \
      libnotify dbus bash fastfetch eza bat fzf whois sudo less procps-ng

CMD ["/bin/bash"]
EOF

    if "$runtime" image exists "$IMAGE_NAME" >/dev/null 2>&1; then
        log "reusing existing preview image"
        return
    fi

    log "building preview image with $runtime"
    "$runtime" build -t "$IMAGE_NAME" "$RUNTIME_DIR/build"
}

prepare_runtime() {
    local preview_home="$RUNTIME_DIR/home/preview"
    local config_home="$preview_home/.config"
    local hypr_dir="$config_home/hypr"

    mkdir -p "$preview_home" "$config_home"
    command rm -rf \
        "$hypr_dir" \
        "$config_home/waybar" \
        "$config_home/rofi" \
        "$config_home/kitty" \
        "$config_home/dunst" \
        "$preview_home/.xdg-runtime"
    mkdir -p "$hypr_dir" "$config_home/waybar" "$config_home/rofi" "$config_home/kitty" "$config_home/dunst" "$preview_home/.xdg-runtime"

    cp -r "$ROOT_DIR/hypr/." "$hypr_dir/"
    cp -r "$ROOT_DIR/waybar/." "$config_home/waybar/"
    cp -r "$ROOT_DIR/rofi/." "$config_home/rofi/"
    cp -r "$ROOT_DIR/kitty/." "$config_home/kitty/"
    cp -r "$ROOT_DIR/dunst/." "$config_home/dunst/"
    cp "$ROOT_DIR/bash/.bashrc_void" "$preview_home/.bashrc_void"
    printf 'source ~/.bashrc_void\n' > "$preview_home/.bashrc"
    printf '\nshell /bin/bash\n' >> "$config_home/kitty/kitty.conf"

    cat > "$config_home/waybar/config" <<'EOF'
{
    "layer": "top",
    "position": "top",
    "height": 28,
    "spacing": 0,
    "margin-top": 0,
    "margin-left": 0,
    "margin-right": 0,
    "exclusive": true,
    "fixed-center": true,

    "modules-left": [
        "hyprland/workspaces",
        "hyprland/window"
    ],

    "modules-center": [
        "clock"
    ],

    "modules-right": [
        "custom/separator",
        "custom/mic",
        "custom/separator",
        "pulseaudio",
        "custom/separator",
        "network",
        "custom/separator",
        "tray"
    ],

    "hyprland/workspaces": {
        "format": "{icon}",
        "format-icons": {
            "active": "●",
            "default": "○",
            "urgent": "◉"
        },
        "sort-by-number": true,
        "all-outputs": true
    },

    "hyprland/window": {
        "format": "{}",
        "max-length": 48,
        "separate-outputs": true,
        "rewrite": {
            "kitty": " terminal",
            "": ""
        }
    },

    "clock": {
        "format": "{:%a %d %b  %H:%M}",
        "format-alt": "{:%Y-%m-%d  %H:%M:%S}",
        "tooltip-format": "<tt><small>{calendar}</small></tt>",
        "interval": 1
    },

    "pulseaudio": {
        "format": "{icon} {volume}%",
        "format-muted": "󰝟 mute",
        "format-icons": {
            "default": ["󰕿", "󰖀", "󰕾"]
        },
        "scroll-step": 5,
        "tooltip": false
    },

    "network": {
        "format-wifi": "󰤨 {signalStrength}%",
        "format-ethernet": "󰈀 {ipaddr}",
        "format-disconnected": "󰤭 off",
        "tooltip-format": "{ifname}: {ipaddr}/{cidr}",
        "interval": 5
    },

    "tray": {
        "icon-size": 14,
        "spacing": 8,
        "show-passive-items": true
    },

    "custom/mic": {
        "format": "{}",
        "return-type": "json",
        "exec": "$HOME/.config/waybar/scripts/mic.sh",
        "interval": 2,
        "tooltip": false
    },

    "custom/separator": {
        "format": "│",
        "interval": "once",
        "tooltip": false
    }
}
EOF

    mkdir -p "$hypr_dir/wallpaper"
    if [[ -f "$ROOT_DIR/hypr/wallpaper/void.png" ]]; then
        cp "$ROOT_DIR/hypr/wallpaper/void.png" "$hypr_dir/wallpaper/void.png"
    elif [[ -f "$ROOT_DIR/image.png" ]]; then
        cp "$ROOT_DIR/image.png" "$hypr_dir/wallpaper/void.png"
    else
        die "no wallpaper source found for preview"
    fi

    cat > "$hypr_dir/hyprland.conf" <<'EOF'
# preview compatibility config for nested Hyprland

env = XCURSOR_SIZE,24
env = XCURSOR_THEME,Adwaita
env = QT_QPA_PLATFORM,wayland
env = GDK_BACKEND,wayland,x11,*
env = SDL_VIDEODRIVER,wayland
env = CLUTTER_BACKEND,wayland
env = XDG_CURRENT_DESKTOP,Hyprland
env = XDG_SESSION_TYPE,wayland
env = XDG_SESSION_DESKTOP,Hyprland
env = MOZ_ENABLE_WAYLAND,1

monitor = ,preferred,auto,1

input {
    kb_layout = us
    kb_options = caps:escape
    follow_mouse = 1
    sensitivity = 0
}

general {
    gaps_in = 6
    gaps_out = 14
    border_size = 1
    col.active_border = rgb(555555)
    col.inactive_border = rgb(1a1a1a)
    layout = dwindle
    resize_on_border = true
}

decoration {
    rounding = 5

    blur {
        enabled = true
        size = 6
        passes = 2
    }

    shadow {
        enabled = true
        range = 20
        render_power = 3
        color = rgba(00000088)
        offset = 0 4
    }

    dim_inactive = true
    dim_strength = 0.08
}

animations {
    enabled = true
    bezier = void, 0.16, 1, 0.3, 1
    animation = windows, 1, 3, void, popin 85%
    animation = border, 1, 4, void
    animation = fade, 1, 3, void
    animation = workspaces, 1, 3, void, slide
}

misc {
    disable_hyprland_logo = true
    disable_splash_rendering = true
    force_default_wallpaper = 0
}

cursor {
    inactive_timeout = 5
    hide_on_key_press = true
}

xwayland {
    force_zero_scaling = true
}

$mod = SUPER

bind = $mod, Return, exec, kitty
bind = $mod SHIFT, Return, exec, kitty --class kitty-float
bind = $mod, Q, killactive,
bind = $mod SHIFT, Q, exit,
bind = $mod, D, exec, rofi -show drun -theme ~/.config/rofi/themes/void.rasi
bind = $mod SHIFT, D, exec, rofi -show run -theme ~/.config/rofi/themes/void.rasi
bind = $mod, V, togglefloating,
bind = $mod, F, fullscreen, 0
bind = $mod SHIFT, F, fullscreen, 1
bind = $mod, E, exec, kitty --hold bash -lc "fastfetch; exec bash"
bind = $mod, period, exec, dunstctl close
bind = $mod SHIFT, period, exec, dunstctl close-all
bind = $mod, grave, exec, dunstctl history-pop

bind = $mod, h, movefocus, l
bind = $mod, j, movefocus, d
bind = $mod, k, movefocus, u
bind = $mod, l, movefocus, r

bind = $mod SHIFT, h, movewindow, l
bind = $mod SHIFT, j, movewindow, d
bind = $mod SHIFT, k, movewindow, u
bind = $mod SHIFT, l, movewindow, r

binde = $mod CTRL, h, resizeactive, -30 0
binde = $mod CTRL, j, resizeactive, 0 30
binde = $mod CTRL, k, resizeactive, 0 -30
binde = $mod CTRL, l, resizeactive, 30 0

bind = $mod, 1, workspace, 1
bind = $mod, 2, workspace, 2
bind = $mod, 3, workspace, 3
bind = $mod, 4, workspace, 4
bind = $mod, 5, workspace, 5

exec-once = hyprpaper
exec-once = waybar
exec-once = dunst
EOF
}

run_preview() {
    local runtime="$1"
    local preview_home="$RUNTIME_DIR/home/preview"
    local socket_mount="$XDG_RUNTIME/$WAYLAND_SOCKET:/home/preview/.xdg-runtime/$WAYLAND_SOCKET"
    local -a run_args=()

    if [[ "$runtime" == "podman" ]]; then
        run_args+=(
            --rm
            --interactive
            --tty
            --name void-hyprland-preview
            --userns keep-id
            --security-opt label=disable
        )
    else
        run_args+=(
            --rm
            --interactive
            --tty
            --name void-hyprland-preview
            --user "$(id -u):$(id -g)"
        )
    fi

    if [[ -d /dev/dri ]]; then
        run_args+=(--device /dev/dri)
    fi

    run_args+=(
        -e XDG_RUNTIME_DIR=/home/preview/.xdg-runtime
        -e WAYLAND_DISPLAY="$WAYLAND_SOCKET"
        -e HOME=/home/preview
        -e SHELL=/bin/bash
        -e HYPRLAND_NO_SD_NOTIFY=1
        -e XCURSOR_THEME=Adwaita
        -e XCURSOR_SIZE=24
        -e QT_QPA_PLATFORM=wayland
        -e GDK_BACKEND=wayland,x11,*
        -e SDL_VIDEODRIVER=wayland
        -e MOZ_ENABLE_WAYLAND=1
        -e WLR_BACKENDS=wayland
        -e WLR_NO_HARDWARE_CURSORS=1
        -v "$socket_mount"
        -v "$preview_home:/home/preview"
    )

    log "starting nested Hyprland preview"
    "$runtime" run "${run_args[@]}" "$IMAGE_NAME" \
        /bin/bash -lc 'mkdir -p "$XDG_RUNTIME_DIR" && chmod 700 "$XDG_RUNTIME_DIR" && dbus-run-session Hyprland'
}

main() {
    local runtime
    runtime="$(pick_runtime)"
    ensure_wayland
    prepare_runtime
    build_image "$runtime"
    run_preview "$runtime"
}

main "$@"
