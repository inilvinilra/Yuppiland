# VOID
<img width="1920" height="1200" alt="image" src="https://github.com/user-attachments/assets/cb6e7394-c670-4a2c-b605-110dff6dfa23" />

> pure black monochrome Arch Linux + Hyprland desktop suite

```
  ██╗   ██╗ ██████╗ ██╗██████╗
  ██║   ██║██╔═══██╗██║██╔══██╗
  ██║   ██║██║   ██║██║██║  ██║
  ╚██╗ ██╔╝██║   ██║██║██║  ██║
   ╚████╔╝ ╚██████╔╝██║██████╔╝
    ╚═══╝   ╚═════╝ ╚═╝╚═════╝
```

## Stack

| Component | Package | Config |
|-----------|---------|--------|
| OS | Arch Linux x86_64 | — |
| WM | Hyprland | `hypr/hyprland.conf` |
| Wallpaper | hyprpaper | `hypr/hyprpaper.conf` |
| Idle | hypridle | `hypr/hypridle.conf` |
| Lock | hyprlock | `hypr/hyprlock.conf` |
| Bar | waybar | `waybar/config` |
| Launcher | rofi-wayland | `rofi/themes/void.rasi` |
| Terminal | kitty | `kitty/kitty.conf` |
| Visualizer | cava | `cava/config` |
| Fetch | fastfetch | `fastfetch/config.jsonc` |
| Notifications | dunst | `dunst/dunstrc` |
| Shell | bash | `bash/.bashrc_void` |
| Screenshots | grim + slurp | `hypr/scripts/screenshot.sh` |
| Clipboard | cliphist + wl-clipboard | — |
| CPU | auto-cpufreq (optional) | `system/auto-cpufreq.conf` |
| Control | voidctl | `voidctl.sh` |

## Palette

```
#000000  ████  background
#080808  ████  surface
#1a1a1a  ████  overlay/borders
#2a2a2a  ████  muted
#555555  ████  subtle
#888888  ████  subtext
#cccccc  ████  text
#e8e8e8  ████  bright
```

Status only: `#cc4444` red · `#c8a84b` yellow · `#5a8a5a` green

## Install

```bash
git clone https://github.com/inilvinilra/Yuppiland.git ~/Desktop/Yuppiland
cd ~/Desktop/Yuppiland
chmod +x install.sh
./install.sh
```

Optional extra packages can be installed alongside VOID:

```bash
./install.sh pkg_user.lst
```

The installer will:
1. Check and install missing packages via pacman
2. Backup existing `~/.config` directories
3. Symlink all configs to `~/.config/`
4. Source `.bashrc_void` from `~/.bashrc`
5. Set script permissions
6. Create wallpaper and screenshot directories

## VOID Control

```bash
./voidctl.sh health
./voidctl.sh sync
./voidctl.sh opacity glass
./voidctl.sh sddm
```

Opacity presets:

| Preset | Feel |
|--------|------|
| `solid` | readable, mostly opaque |
| `glass` | balanced transparency |
| `ghost` | very transparent |
| `focus` | focused window readable, inactive windows airy |

HyDE parity work is tracked in `ROADMAP.md`.

## Keybindings

### Core
| Key | Action |
|-----|--------|
| `Super + Return` | Terminal (kitty) |
| `Super + Shift + Return` | Floating terminal |
| `Super + D` | App launcher (rofi drun) |
| `Super + Shift + D` | Run prompt (rofi run) |
| `Super + Q` | Close window |
| `Super + Shift + Q` | Exit Hyprland |
| `Super + V` | Toggle floating |
| `Super + F` | Fullscreen |
| `Super + E` | File manager |
| `Super + B` | Browser |
| `Super + L` | Lock screen |
| `Super + R` | Resize mode (hjkl/arrows, Esc to exit) |

### Workspaces
| Key | Action |
|-----|--------|
| `Super + 1-0` | Switch workspace |
| `Super + Shift + 1-0` | Move window to workspace |
| `Super + -` | Scratchpad terminal |
| `Super + =` | Scratchpad monitor |

### Utilities
| Key | Action |
|-----|--------|
| `Print` | Screenshot → clipboard |
| `Shift + Print` | Screenshot full → file |
| `Super + Print` | Screenshot area → file |
| `Super + Shift + Print` | Screenshot window |
| `Super + Shift + S` | Screenshot menu (rofi) |
| `Super + Shift + V` | Clipboard history |
| `Super + Shift + E` | Power menu |

### Rofi Menus
| Key | Action |
|-----|--------|
| `Super + N` | WiFi menu |
| `Super + Shift + B` | Bluetooth menu |
| `Super + A` | Audio device switcher |
| `Super + ;` | Emoji picker |
| `Super + Shift + G` | Game mode toggle |

### Media
| Key | Action |
|-----|--------|
| `XF86Audio*` | Volume up/down/mute |
| `XF86MonBrightness*` | Brightness up/down |
| `XF86Audio{Play,Next,Prev}` | Media controls |

## Structure

```
.
├── hypr/
│   ├── hyprland.conf       # compositor config
│   ├── hyprpaper.conf      # wallpaper daemon
│   ├── hypridle.conf       # idle management
│   ├── hyprlock.conf       # lock screen
│   ├── scripts/
│   │   ├── power-menu.sh      # rofi power menu
│   │   ├── volume.sh          # volume + OSD notification
│   │   ├── brightness.sh     # brightness + OSD notification
│   │   ├── screenshot.sh     # grim + slurp wrapper
│   │   ├── screenshot-menu.sh # rofi screenshot picker
│   │   ├── wifi-menu.sh      # rofi wifi/network menu
│   │   ├── bluetooth-menu.sh # rofi bluetooth menu
│   │   ├── audio-menu.sh     # rofi audio sink switcher
│   │   ├── emoji-picker.sh   # rofi emoji picker
│   │   ├── gamemode.sh       # toggle performance mode
│   │   └── wallpaper.sh      # rofi wallpaper picker
│   └── wallpaper/
│       └── void.png        # place wallpaper here
├── waybar/
│   ├── config              # modules & layout
│   ├── style.css           # styling
│   ├── colors.css          # color variables
│   └── scripts/
│       ├── mediaplayer.sh   # playerctl status for bar
│       ├── mic.sh           # microphone status
│       └── updates.sh       # pacman update count
├── nvim/
│   └── colors/
│       └── void.lua         # neovim colorscheme
├── firefox/
│   └── chrome/
│       ├── userChrome.css   # browser UI theme
│       └── userContent.css  # new tab & about: pages
├── sddm/
│   └── void/
│       ├── Main.qml         # login screen layout
│       ├── theme.conf        # theme config
│       └── metadata.desktop  # SDDM metadata
├── rofi/
│   └── themes/
│       └── void.rasi       # launcher theme
├── kitty/
│   └── kitty.conf          # terminal config
├── cava/
│   └── config              # audio visualizer
├── fastfetch/
│   └── config.jsonc        # system fetch
├── dunst/
│   └── dunstrc             # notifications
├── bash/
│   └── .bashrc_void        # shell config
├── gtk-3.0/
│   └── settings.ini        # GTK3 theming
├── gtk-4.0/
│   └── settings.ini        # GTK4 theming
├── icons/
│   └── default/
│       └── index.theme     # cursor theme
├── system/
│   └── auto-cpufreq.conf   # CPU governor
├── voidctl.sh              # health, sync, opacity, SDDM helper
├── ROADMAP.md              # HyDE parity and VOID direction
├── install.sh              # automated installer
└── README.md
```

## Font

JetBrains Mono Nerd Font — everywhere. No exceptions.

## Rules

- No color outside the palette
- No border radius above 6px
- No gradients, no glow, no neon
- Everything is a text file
- `hyprctl reload` to apply WM changes
- `pkill waybar && waybar &` to reload bar

## License

Do whatever you want. It's void.
