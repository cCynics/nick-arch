#!/bin/bash

set -e

# Setup Python
echo "Setting up Python environment..."
sudo pacman -S --needed --noconfirm python-pipx
pipx install poetry
pipx install black
pipx install pylint
pipx install mypy

# Setup PostgreSQL
echo "Setting up PostgreSQL..."
sudo systemctl enable postgresql.service
sudo -u postgres initdb -D /var/lib/postgres/data 2>/dev/null || echo "PostgreSQL data directory already initialized"

# Setup Docker
echo "Setting up Docker..."
sudo systemctl enable docker.service
sudo usermod -aG docker "$USER"

# Setup Rust (needed for oxwm later + useful tools)
echo "Installing Rust..."
if command -v rustup &> /dev/null; then
    echo "Rust is already installed"
else
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source "$HOME/.cargo/env"
fi

# Install some useful Rust tools
cargo install cargo-watch cargo-edit

echo "Development environment setup complete"
echo "NOTE: Log out and back in for docker group to take effect"
