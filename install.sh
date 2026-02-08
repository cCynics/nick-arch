#!/bin/bash

# Nick's Arch Setup Script
# Run this after archinstall completes base installation

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

print_status() {
    echo -e "${GREEN}[*]${NC} $1"
}

print_error() {
    echo -e "${RED}[!]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

# Strip Windows CRLF line endings from all project files
print_status "Fixing line endings..."
find "$SCRIPT_DIR" -type f \( -name "*.sh" -o -name "*.txt" \) -exec sed -i 's/\r$//' {} +

# Read a package list file, strip comments/blanks/whitespace
read_packages() {
    sed 's/\r$//' "$1" | grep -v '^#' | grep -v '^[[:space:]]*$' | tr -d '\r'
}

# Install packages from a list file, one at a time so one bad package doesn't block the rest
install_packages() {
    local list_file="$1"
    local label="$2"
    local failed=()

    print_status "Installing $label packages..."
    while IFS= read -r pkg; do
        [ -z "$pkg" ] && continue
        if ! sudo pacman -S --needed --noconfirm "$pkg" 2>/dev/null; then
            print_warning "Failed to install: $pkg"
            failed+=("$pkg")
        fi
    done < <(read_packages "$list_file")

    if [ ${#failed[@]} -gt 0 ]; then
        print_warning "Failed packages from $label: ${failed[*]}"
    fi
}

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    print_error "Don't run this as root! Run as your user with sudo access."
    exit 1
fi

print_status "Starting Nick's Arch Setup..."

# ========================================
# PACMAN PACKAGES
# ========================================

print_status "Updating system..."
sudo pacman -Syu --noconfirm

install_packages "$SCRIPT_DIR/packages/essential.txt" "essential"
install_packages "$SCRIPT_DIR/packages/desktop.txt" "desktop"
install_packages "$SCRIPT_DIR/packages/dev.txt" "development"

# Enable multilib before gaming packages (needed for 32-bit libs)
print_status "Enabling multilib repository..."
sudo sed -i "/\[multilib\]/,/Include/"'s/^#//' /etc/pacman.conf
sudo pacman -Sy --noconfirm

install_packages "$SCRIPT_DIR/packages/gaming.txt" "gaming"

# ========================================
# GPU DRIVERS
# ========================================

print_status "Detecting GPU..."
if systemd-detect-virt --quiet 2>/dev/null; then
    VM_TYPE=$(systemd-detect-virt)
    print_warning "Running in a VM ($VM_TYPE) - installing VM guest drivers"
    case "$VM_TYPE" in
        oracle)
            sudo pacman -S --needed --noconfirm virtualbox-guest-utils
            sudo systemctl enable vboxservice.service
            ;;
        kvm|qemu)
            sudo pacman -S --needed --noconfirm qemu-guest-agent spice-vdagent
            ;;
        vmware)
            sudo pacman -S --needed --noconfirm open-vm-tools
            sudo systemctl enable vmtoolsd.service
            ;;
    esac
else
    print_status "Bare metal detected - installing GPU drivers"
    GPU_INFO=$(lspci | grep -i 'vga\|3d')
    if echo "$GPU_INFO" | grep -qi 'nvidia'; then
        print_status "NVIDIA GPU detected"
        sudo pacman -S --needed --noconfirm nvidia nvidia-utils lib32-nvidia-utils nvidia-settings
    elif echo "$GPU_INFO" | grep -qi 'amd\|radeon'; then
        print_status "AMD GPU detected"
        sudo pacman -S --needed --noconfirm vulkan-radeon lib32-vulkan-radeon
    elif echo "$GPU_INFO" | grep -qi 'intel'; then
        print_status "Intel GPU detected"
        sudo pacman -S --needed --noconfirm vulkan-intel lib32-vulkan-intel
    else
        print_warning "Could not detect GPU - install drivers manually"
    fi
fi

# ========================================
# AUR SETUP
# ========================================

print_status "Setting up AUR helper (paru)..."
if command -v paru &> /dev/null; then
    echo "paru is already installed"
else
    cd /tmp
    git clone https://aur.archlinux.org/paru.git
    cd paru
    makepkg -si --noconfirm
    cd ~
    rm -rf /tmp/paru
fi

print_status "Installing AUR packages..."
paru -S --needed --noconfirm vesktop-bin spotify

# ========================================
# SERVICES
# ========================================

print_status "Enabling services..."
sudo systemctl enable --now bluetooth.service
sudo systemctl enable --now NetworkManager.service
sudo systemctl enable lightdm.service

# ========================================
# DEV ENVIRONMENT
# ========================================

print_status "Setting up Python tools..."
sudo pacman -S --needed --noconfirm python-pipx
pipx install poetry
pipx install black
pipx install pylint
pipx install mypy
pipx ensurepath

print_status "Setting up PostgreSQL..."
if pacman -Qi postgresql &>/dev/null; then
    sudo -u postgres initdb -D /var/lib/postgres/data 2>/dev/null || echo "PostgreSQL data directory already initialized"
    sudo systemctl enable postgresql.service
else
    print_warning "postgresql not installed, skipping"
fi

print_status "Setting up Docker..."
if pacman -Qi docker &>/dev/null; then
    sudo systemctl enable docker.service
    sudo usermod -aG docker "$USER"
else
    print_warning "docker not installed, skipping"
fi

print_status "Installing Rust..."
if command -v rustup &> /dev/null; then
    echo "Rust is already installed"
else
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source "$HOME/.cargo/env"
fi
cargo install cargo-watch cargo-edit

# ========================================
# GAMING
# ========================================

print_status "Setting up gaming..."
if getent group gamemode &>/dev/null; then
    sudo usermod -aG gamemode "$USER"
else
    print_warning "gamemode group does not exist, skipping"
fi

cat > ~/steam-launch-options.txt << 'EOF'
Steam Launch Options Reference
==============================

General performance boost:
  gamemoderun mangohud %command%

For Proton games (like RuneScape 3):
  gamemoderun mangohud %command%
  (Also set Proton version in Steam > Settings > Compatibility)

MangoHud toggle: press Right_Shift + F12 in-game

To check if gamemode is active:
  gamemoded -s
EOF

# ========================================
# DOTFILES / CONFIGS
# ========================================

print_status "Installing config files..."

# Create config directories
mkdir -p ~/.config/bspwm
mkdir -p ~/.config/sxhkd
mkdir -p ~/.config/polybar
mkdir -p ~/.config/picom
mkdir -p ~/.config/dunst
mkdir -p ~/.config/alacritty
mkdir -p ~/.config/rofi

# Copy configs (strip CRLF just in case)
for f in "$SCRIPT_DIR"/config/bspwm/* "$SCRIPT_DIR"/config/sxhkd/* "$SCRIPT_DIR"/config/polybar/* "$SCRIPT_DIR"/config/picom/* "$SCRIPT_DIR"/config/dunst/* "$SCRIPT_DIR"/config/alacritty/* "$SCRIPT_DIR"/config/rofi/*; do
    [ -f "$f" ] || continue
    dest="$HOME/.config/$(echo "$f" | sed "s|.*config/||")"
    mkdir -p "$(dirname "$dest")"
    sed 's/\r$//' "$f" > "$dest"
done

# Make bspwmrc and polybar launch script executable
chmod +x ~/.config/bspwm/bspwmrc
chmod +x ~/.config/polybar/launch.sh

# Setup xinitrc
sed 's/\r$//' "$SCRIPT_DIR/config/xinitrc" > ~/.xinitrc

# Screenshots directory
mkdir -p ~/Pictures/Screenshots

# Wallpaper
print_status "Installing wallpaper..."
mkdir -p ~/wallpaper
cp "$SCRIPT_DIR"/wallpaper/* ~/wallpaper/ 2>/dev/null || true

# ========================================
# FINAL SETUP
# ========================================

print_status "Setting zsh as default shell..."
sudo chsh -s "$(which zsh)" "$USER"

print_status "Creating XDG user directories..."
xdg-user-dirs-update

print_status "========================================="
print_status "Base installation complete!"
print_status "========================================="
echo ""
echo "Everything is installed and configured."
echo "Reboot, log in, and run 'startx' to launch bspwm."
echo ""
echo "Keybinds:"
echo "  super + Return     Open terminal"
echo "  super + d          App launcher (rofi)"
echo "  super + q          Close window"
echo "  super + b          Browser"
echo "  super + e          File manager"
echo "  super + 1-9        Switch desktop"
echo "  super + shift + r  Restart bspwm"
