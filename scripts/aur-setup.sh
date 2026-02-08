#!/bin/bash

set -e

# Check if paru is already installed
if command -v paru &> /dev/null; then
    echo "paru is already installed"
    exit 0
fi

# Install paru
echo "Installing paru from AUR..."
cd /tmp
git clone https://aur.archlinux.org/paru.git
cd paru
makepkg -si --noconfirm
cd ~
rm -rf /tmp/paru

echo "paru installed successfully"
