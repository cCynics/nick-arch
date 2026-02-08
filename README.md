# Nick's Arch Linux Setup

Automated post-install script for my personal Arch Linux setup.

## Features

- **WM**: bspwm (X11) - RS3 compatible
- **Terminal**: Alacritty + Zsh + Starship
- **Dev Stack**: Python, C/C++, Node.js, Rust, PostgreSQL, Docker
- **Gaming**: Steam, Lutris, Wine, gamemode, mangohud
- **Theme**: Gruvbox ready (configs to come)

## Installation

### Step 1: Install Base System

1. Boot Arch ISO
2. Run `archinstall`
3. Choose:
   - UEFI / GRUB
   - ext4 filesystem
   - NetworkManager
   - pipewire
   - Create your user
4. Reboot into new system

### Step 2: Run This Script

```bash
# Connect to internet if needed
nmtui

# Clone this repo
git clone https://github.com/yourusername/nick-arch.git
cd nick-arch

# Make scripts executable
chmod +x install.sh scripts/*.sh

# Run it
./install.sh
```

### Step 3: Reboot

```bash
sudo reboot
```

### Step 4: First Login

After reboot, enable display manager and start:
```bash
sudo systemctl enable --now lightdm.service
```

Or use startx with your .xinitrc.

## What Gets Installed

| Category | Packages |
|----------|----------|
| CLI Tools | git, zsh, neovim, tmux, fzf, ripgrep, bat, eza, starship |
| Desktop | X11, bspwm, polybar, rofi, picom, dunst, thunar |
| Dev | gcc, clang, python, node, rust, postgresql, docker, vscode |
| Gaming | Steam, wine, lutris, gamemode, mangohud |
| AUR | vesktop, spotify |

## Post-Install

1. Configure bspwm: `~/.config/bspwm/bspwmrc`
2. Configure keybinds: `~/.config/sxhkd/sxhkdrc`
3. Setup zsh + starship prompt
4. Configure neovim
5. Setup polybar
6. Apply Gruvbox theme

## Notes

- Script assumes a fresh archinstall base
- Test in a VM before bare metal
- Can swap to oxwm later once it matures
- All dotfile configs will go in the `config/` directory
