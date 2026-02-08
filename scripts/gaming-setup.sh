#!/bin/bash

set -e

# Enable gamemode for current user
echo "Setting up gamemode..."
sudo usermod -aG gamemode "$USER"

# Create Steam launch options info
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

echo "Gaming setup complete!"
echo "Check ~/steam-launch-options.txt for Steam launch options"
