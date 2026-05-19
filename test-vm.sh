#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  VOID — QEMU Test VM                                        ║
# ║  Boot a VM to preview the full VOID desktop without          ║
# ║  touching your host system.                                  ║
# ╚══════════════════════════════════════════════════════════════╝
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VM_DIR="$DOTFILES_DIR/.vm"
DISK_IMG="$VM_DIR/void-test.qcow2"
DISK_SIZE="20G"
RAM="4G"
CPUS="4"
ISO_URL="https://geo.mirror.pkgbuild.com/iso/latest/archlinux-x86_64.iso"
ISO_FILE="$VM_DIR/archlinux.iso"

# ── COLORS ──
R="\033[38;2;204;68;68m"
G="\033[38;2;90;138;90m"
W="\033[38;2;232;232;232m"
D="\033[38;2;136;136;136m"
N="\033[0m"

info()  { echo -e "${D}  ▸ $1${N}"; }
ok()    { echo -e "${G}  ✓ $1${N}"; }
warn()  { echo -e "${R}  ✗ $1${N}"; }
header(){ echo -e "\n${W}  ── $1 ──${N}"; }

# ── DEPENDENCY CHECK ──
check_deps() {
    local missing=()
    for cmd in qemu-system-x86_64 qemu-img; do
        if ! command -v "$cmd" &>/dev/null; then
            missing+=("$cmd")
        fi
    done

    if [[ ${#missing[@]} -gt 0 ]]; then
        warn "missing: ${missing[*]}"
        echo -e "${D}  install with: sudo pacman -S qemu-full${N}"
        exit 1
    fi
    ok "qemu found"
}

# ── CREATE VM DIRECTORY ──
setup_vm_dir() {
    mkdir -p "$VM_DIR"
    # add .vm to gitignore if not already
    if ! grep -qF ".vm" "$DOTFILES_DIR/.gitignore" 2>/dev/null; then
        echo ".vm/" >> "$DOTFILES_DIR/.gitignore"
    fi
}

# ── DOWNLOAD ISO ──
download_iso() {
    if [[ -f "$ISO_FILE" ]]; then
        ok "ISO already downloaded"
        return
    fi

    header "downloading Arch Linux ISO"
    info "this may take a while (~900MB)"

    if command -v wget &>/dev/null; then
        wget -q --show-progress -O "$ISO_FILE" "$ISO_URL"
    elif command -v curl &>/dev/null; then
        curl -L --progress-bar -o "$ISO_FILE" "$ISO_URL"
    else
        warn "need wget or curl to download ISO"
        exit 1
    fi
    ok "ISO downloaded"
}

# ── CREATE DISK IMAGE ──
create_disk() {
    if [[ -f "$DISK_IMG" ]]; then
        ok "disk image exists ($(du -h "$DISK_IMG" | cut -f1))"
        return
    fi

    header "creating disk image"
    qemu-img create -f qcow2 "$DISK_IMG" "$DISK_SIZE" >/dev/null
    ok "created $DISK_SIZE qcow2 disk"
}

# ── CREATE CLOUD-INIT SETUP SCRIPT ──
create_setup_script() {
    cat > "$VM_DIR/void-setup.sh" << 'SETUP_EOF'
#!/usr/bin/env bash
# ── Run inside the VM to install VOID ──
set -euo pipefail

echo "══════════════════════════════════════"
echo "  VOID — VM Setup Script"
echo "══════════════════════════════════════"

# mount shared dotfiles
mkdir -p /mnt/dotfiles
mount -t 9p -o trans=virtio,version=9p2000.L dotfiles /mnt/dotfiles 2>/dev/null || {
    echo "ERROR: shared folder not mounted. Run VM with -virtfs option."
    exit 1
}

echo "[1/6] Installing base packages..."
pacman -Sy --noconfirm --needed \
    hyprland hyprpaper hypridle hyprlock \
    waybar rofi-wayland dunst \
    kitty firefox dolphin \
    sddm qt5-quickcontrols2 \
    pipewire pipewire-pulse wireplumber \
    xdg-desktop-portal-hyprland \
    ttf-jetbrains-mono-nerd papirus-icon-theme \
    playerctl brightnessctl jq polkit-kde-agent \
    grim slurp wl-clipboard cliphist \
    networkmanager bluez bluez-utils \
    cava fastfetch eza bat fzf \
    git base-devel >/dev/null 2>&1

echo "[2/6] Creating test user..."
useradd -m -G wheel -s /bin/bash void 2>/dev/null || true
echo "void:void" | chpasswd
echo "%wheel ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/wheel

echo "[3/6] Copying dotfiles..."
DOTFILES="/mnt/dotfiles"
CONFIG="/home/void/.config"
mkdir -p "$CONFIG"

cp -r "$DOTFILES/hypr" "$CONFIG/"
cp -r "$DOTFILES/waybar" "$CONFIG/"
cp -r "$DOTFILES/rofi" "$CONFIG/"
cp -r "$DOTFILES/kitty" "$CONFIG/"
cp -r "$DOTFILES/cava" "$CONFIG/"
cp -r "$DOTFILES/fastfetch" "$CONFIG/"
cp -r "$DOTFILES/dunst" "$CONFIG/"
cp -r "$DOTFILES/gtk-3.0" "$CONFIG/"
cp -r "$DOTFILES/gtk-4.0" "$CONFIG/"
mkdir -p "$CONFIG/nvim/colors"
cp "$DOTFILES/nvim/colors/void.lua" "$CONFIG/nvim/colors/"

# bash config
cp "$DOTFILES/bash/.bashrc_void" /home/void/.bashrc_void
echo "source ~/.bashrc_void" >> /home/void/.bashrc

# icons
mkdir -p /home/void/.icons
cp -r "$DOTFILES/icons/default" /home/void/.icons/

# permissions
chmod +x "$CONFIG/hypr/scripts/"*.sh
chmod +x "$CONFIG/waybar/scripts/"*.sh
chown -R void:void /home/void/

echo "[4/6] Installing SDDM theme..."
mkdir -p /usr/share/sddm/themes/void
cp -r "$DOTFILES/sddm/void/"* /usr/share/sddm/themes/void/
mkdir -p /etc/sddm.conf.d
echo -e "[Theme]\nCurrent=void" > /etc/sddm.conf.d/void.conf

echo "[5/6] Enabling services..."
systemctl enable sddm
systemctl enable NetworkManager

echo "[6/6] Creating wallpaper..."
mkdir -p "$CONFIG/hypr/wallpaper"
# pure black 1920x1080 PPM → PNG fallback
if command -v convert &>/dev/null; then
    convert -size 1920x1080 xc:#000000 "$CONFIG/hypr/wallpaper/void.png"
else
    # create minimal black PNG manually
    printf 'P6\n1920 1080\n255\n' > /tmp/black.ppm
    dd if=/dev/zero bs=3 count=$((1920*1080)) >> /tmp/black.ppm 2>/dev/null
    cp /tmp/black.ppm "$CONFIG/hypr/wallpaper/void.png"
fi
chown -R void:void /home/void/

echo ""
echo "══════════════════════════════════════"
echo "  VOID setup complete!"
echo "  Reboot to see SDDM → Hyprland"
echo "  Login: void / void"
echo "══════════════════════════════════════"
SETUP_EOF
    chmod +x "$VM_DIR/void-setup.sh"
    ok "setup script created"
}

# ── BOOT VM ──
boot_vm() {
    local extra_args=()

    case "$1" in
        install)
            header "booting VM with Arch ISO (install mode)"
            info "after boot: mount disk, pacstrap, arch-chroot"
            info "then run /mnt/dotfiles/void-setup.sh inside chroot"
            extra_args+=(
                -cdrom "$ISO_FILE"
                -boot d
            )
            ;;
        run)
            header "booting VM (normal mode)"
            info "login: void / void"
            ;;
        *)
            warn "unknown mode: $1"
            exit 1
            ;;
    esac

    echo ""
    info "VM specs: ${CPUS} cores, ${RAM} RAM, virtio-gpu"
    info "shared folder: dotfiles → /mnt/dotfiles (inside VM)"
    info "press Ctrl+Alt+G to release mouse grab"
    echo ""

    qemu-system-x86_64 \
        -enable-kvm \
        -cpu host \
        -smp "$CPUS" \
        -m "$RAM" \
        -drive file="$DISK_IMG",format=qcow2,if=virtio \
        -device virtio-gpu-pci \
        -display gtk,gl=on \
        -device virtio-keyboard-pci \
        -device virtio-mouse-pci \
        -audio driver=pipewire,model=hda \
        -nic user,model=virtio-net-pci \
        -virtfs local,path="$DOTFILES_DIR",mount_tag=dotfiles,security_model=mapped-xattr,id=dotfiles \
        -usb \
        -device usb-tablet \
        "${extra_args[@]}"
}

# ── USAGE ──
usage() {
    echo -e "${W}  VOID Test VM${N}"
    echo ""
    echo -e "${D}  usage: $0 <command>${N}"
    echo ""
    echo -e "  ${W}commands:${N}"
    echo -e "    ${G}setup${N}      download ISO + create disk image"
    echo -e "    ${G}install${N}    boot ISO to install Arch in VM"
    echo -e "    ${G}run${N}        boot installed VM (normal)"
    echo -e "    ${G}snapshot${N}   save VM state snapshot"
    echo -e "    ${G}restore${N}    restore last snapshot"
    echo -e "    ${G}reset${N}      delete VM disk (start fresh)"
    echo -e "    ${G}status${N}     show VM disk info"
    echo ""
    echo -e "${D}  workflow:${N}"
    echo -e "${D}    1. ./test-vm.sh setup${N}"
    echo -e "${D}    2. ./test-vm.sh install${N}"
    echo -e "${D}       → inside VM: partition disk, pacstrap, arch-chroot${N}"
    echo -e "${D}       → run: mount -t 9p -o trans=virtio dotfiles /mnt/dotfiles${N}"
    echo -e "${D}       → run: bash /mnt/dotfiles/.vm/void-setup.sh${N}"
    echo -e "${D}    3. ./test-vm.sh run${N}"
    echo ""
}

# ── SNAPSHOT MANAGEMENT ──
snapshot_save() {
    if [[ ! -f "$DISK_IMG" ]]; then
        warn "no disk image found"
        exit 1
    fi
    header "saving snapshot"
    qemu-img snapshot -c "void-$(date +%Y%m%d_%H%M%S)" "$DISK_IMG"
    ok "snapshot saved"
    qemu-img snapshot -l "$DISK_IMG" | tail -5
}

snapshot_restore() {
    if [[ ! -f "$DISK_IMG" ]]; then
        warn "no disk image found"
        exit 1
    fi
    local latest
    latest=$(qemu-img snapshot -l "$DISK_IMG" 2>/dev/null | tail -1 | awk '{print $2}')
    if [[ -z "$latest" ]]; then
        warn "no snapshots found"
        exit 1
    fi
    header "restoring snapshot: $latest"
    qemu-img snapshot -a "$latest" "$DISK_IMG"
    ok "restored"
}

# ── MAIN ──
main() {
    echo -e "\n${W}  ╔══════════════╗${N}"
    echo -e "${W}  ║  VOID  TEST  ║${N}"
    echo -e "${W}  ╚══════════════╝${N}"

    case "${1:-}" in
        setup)
            check_deps
            setup_vm_dir
            download_iso
            create_disk
            create_setup_script
            echo ""
            ok "ready! next: ./test-vm.sh install"
            ;;
        install)
            check_deps
            setup_vm_dir
            create_setup_script
            [[ ! -f "$ISO_FILE" ]] && download_iso
            [[ ! -f "$DISK_IMG" ]] && create_disk
            boot_vm install
            ;;
        run)
            check_deps
            [[ ! -f "$DISK_IMG" ]] && { warn "no disk image — run setup first"; exit 1; }
            boot_vm run
            ;;
        snapshot)
            snapshot_save
            ;;
        restore)
            snapshot_restore
            ;;
        reset)
            header "resetting VM"
            rm -f "$DISK_IMG"
            ok "disk image deleted"
            info "run ./test-vm.sh setup to recreate"
            ;;
        status)
            header "VM status"
            if [[ -f "$DISK_IMG" ]]; then
                qemu-img info "$DISK_IMG"
                echo ""
                info "snapshots:"
                qemu-img snapshot -l "$DISK_IMG" 2>/dev/null || info "none"
            else
                info "no disk image"
            fi
            ;;
        *)
            usage
            ;;
    esac
}

main "$@"
