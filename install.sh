#!/bin/bash

# Nick's Arch Setup Script
# Run this after archinstall completes base installation

set -e  # Exit on error

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

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    print_error "Don't run this as root! Run as your user with sudo access."
    exit 1
fi

print_status "Starting Nick's Arch Setup..."

# Update system
print_status "Updating system..."
sudo pacman -Syu --noconfirm

# Install essential packages
print_status "Installing essential packages..."
sudo pacman -S --needed --noconfirm $(cat "$SCRIPT_DIR/packages/essential.txt" | grep -v '^#' | grep -v '^$')

print_status "Installing desktop packages..."
sudo pacman -S --needed --noconfirm $(cat "$SCRIPT_DIR/packages/desktop.txt" | grep -v '^#' | grep -v '^$')

print_status "Installing development packages..."
sudo pacman -S --needed --noconfirm $(cat "$SCRIPT_DIR/packages/dev.txt" | grep -v '^#' | grep -v '^$')

# Enable multilib before gaming packages (needed for 32-bit libs)
print_status "Enabling multilib repository..."
sudo sed -i "/\[multilib\]/,/Include/"'s/^#//' /etc/pacman.conf
sudo pacman -Sy --noconfirm

print_status "Installing gaming packages..."
sudo pacman -S --needed --noconfirm $(cat "$SCRIPT_DIR/packages/gaming.txt" | grep -v '^#' | grep -v '^$')

# Detect GPU and install appropriate drivers
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

# Setup AUR helper
print_status "Setting up AUR helper (paru)..."
bash "$SCRIPT_DIR/scripts/aur-setup.sh"

# Install AUR packages
print_status "Installing AUR packages..."
paru -S --needed --noconfirm vesktop-bin spotify

# Enable services
print_status "Enabling services..."
sudo systemctl enable --now bluetooth.service
sudo systemctl enable --now NetworkManager.service

# Setup development environments
print_status "Setting up development environments..."
bash "$SCRIPT_DIR/scripts/dev-setup.sh"

# Change default shell to zsh
print_status "Setting zsh as default shell..."
sudo chsh -s "$(which zsh)" "$USER"

# Setup gaming environment
print_status "Setting up gaming optimizations..."
bash "$SCRIPT_DIR/scripts/gaming-setup.sh"

# Create user directories
print_status "Creating XDG user directories..."
xdg-user-dirs-update

print_status "========================================="
print_status "Base installation complete!"
print_status "========================================="
print_warning "You should reboot now. After reboot, run dotfiles setup."
echo ""
echo "Next steps:"
echo "  1. Reboot your system"
echo "  2. Log back in"
echo "  3. Setup your dotfiles and WM config"
echo "  4. Start X with 'startx' or enable lightdm:"
echo "     sudo systemctl enable lightdm.service"
