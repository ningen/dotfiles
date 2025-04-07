#!/bin/bash

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Create symbolic links
echo "Creating symbolic links..."

# Create config directories
mkdir -p ~/.config
mkdir -p ~/Library/Application\ Support/Code/User/

# Directory symlinks
ln -sfn "$DOTFILES_DIR/.config/git" ~/.config/git
ln -sfn "$DOTFILES_DIR/.config/nix" ~/.config/nix
ln -sfn "$DOTFILES_DIR/.config/nvim" ~/.config/nvim

# VSCode config
ln -sf "$DOTFILES_DIR/.config/vscode/settings.json" ~/Library/Application\ Support/Code/User/settings.json
ln -sf "$DOTFILES_DIR/.config/vscode/keybindings.json" ~/Library/Application\ Support/Code/User/keybindings.json

echo "Dotfiles setup completed!"