#!/bin/bash

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Create symbolic links
echo "Creating symbolic links..."

# Create local file
touch "$DOTFILES_DIR/.config/nix/nix-local.conf"

# Create config directories
mkdir -p ~/.config

# Detect OS and set VSCode config path
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    VSCODE_CONFIG_DIR="$HOME/Library/Application Support/Code/User"
else
    # Linux
    VSCODE_CONFIG_DIR="$HOME/.config/Code/User"
fi

mkdir -p "$VSCODE_CONFIG_DIR"

# Directory symlinks
ln -sfn "$DOTFILES_DIR/.config/git" ~/.config/git
ln -sfn "$DOTFILES_DIR/.config/nix" ~/.config/nix
ln -sfn "$DOTFILES_DIR/.config/nvim" ~/.config/nvim
ln -sfn "$DOTFILES_DIR/.config/hypr" ~/.config/hypr
ln -sfn "$DOTFILES_DIR/.config/waybar" ~/.config/waybar
ln -sfn "$DOTFILES_DIR/.config/discord/settings.json" ~/.config/discord/settings.json
ln -sfn "$DOTFILES_DIR/.config/tmux" ~/.config/tmux
ln -sfn "$DOTFILES_DIR/.config/kitty" ~/.config/kitty
ln -sfn "$DOTFILES_DIR/.config/emacs" ~/.config/emacs

# VSCode config
ln -sf "$DOTFILES_DIR/.config/vscode/settings.json" "$VSCODE_CONFIG_DIR/settings.json"
ln -sf "$DOTFILES_DIR/.config/vscode/keybindings.json" "$VSCODE_CONFIG_DIR/keybindings.json"

echo "Dotfiles setup completed!"
