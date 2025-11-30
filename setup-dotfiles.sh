#!/bin/bash

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Detect OS
detect_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo "linux"
    elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" || "$OSTYPE" == "win32" ]]; then
        echo "windows"
    else
        echo "unknown"
    fi
}

OS_TYPE=$(detect_os)

# Set XDG_CONFIG_HOME based on OS
if [[ -n "$XDG_CONFIG_HOME" ]]; then
    CONFIG_DIR="$XDG_CONFIG_HOME"
else
    case "$OS_TYPE" in
        windows)
            # Windows: Use APPDATA if available, otherwise default to a reasonable path
            if [[ -n "$APPDATA" ]]; then
                CONFIG_DIR="$APPDATA"
            else
                CONFIG_DIR="$HOME/AppData/Roaming"
            fi
            ;;
        *)
            # macOS and Linux default
            CONFIG_DIR="$HOME/.config"
            ;;
    esac
fi

echo "OS detected: $OS_TYPE"
echo "Config directory: $CONFIG_DIR"

# Create symbolic links
echo "Creating symbolic links..."

# Create local file (only for non-Windows as nix is not available on Windows)
if [[ "$OS_TYPE" != "windows" ]]; then
    touch "$DOTFILES_DIR/.config/nix/nix-local.conf"
fi

# Create config directories
mkdir -p "$CONFIG_DIR"

# Detect OS and set VSCode config path
case "$OS_TYPE" in
    macos)
        VSCODE_CONFIG_DIR="$HOME/Library/Application Support/Code/User"
        ;;
    windows)
        if [[ -n "$APPDATA" ]]; then
            VSCODE_CONFIG_DIR="$APPDATA/Code/User"
        else
            VSCODE_CONFIG_DIR="$HOME/AppData/Roaming/Code/User"
        fi
        ;;
    *)
        VSCODE_CONFIG_DIR="$HOME/.config/Code/User"
        ;;
esac

mkdir -p "$VSCODE_CONFIG_DIR"

# Function to create symlinks (with fallback for Windows)
create_link() {
    local src="$1"
    local dest="$2"

    # Create parent directory if it doesn't exist
    mkdir -p "$(dirname "$dest")"

    # Try to create symlink
    if ln -sfn "$src" "$dest" 2>/dev/null; then
        echo "✓ Linked: $dest"
    else
        # Fallback: copy instead of symlink (for Windows without proper permissions)
        echo "! Symlink failed, copying instead: $dest"
        if [[ -d "$src" ]]; then
            cp -r "$src" "$dest"
        else
            cp "$src" "$dest"
        fi
    fi
}

# Directory symlinks (skip nix/hypr/waybar on Windows as they're Linux/macOS specific)
if [[ "$OS_TYPE" != "windows" ]]; then
    create_link "$DOTFILES_DIR/.config/nix" "$CONFIG_DIR/nix"
    create_link "$DOTFILES_DIR/.config/hypr" "$CONFIG_DIR/hypr"
    create_link "$DOTFILES_DIR/.config/waybar" "$CONFIG_DIR/waybar"
fi

# Common config directories
create_link "$DOTFILES_DIR/.config/git" "$CONFIG_DIR/git"
create_link "$DOTFILES_DIR/.config/nvim" "$CONFIG_DIR/nvim"
create_link "$DOTFILES_DIR/.config/tmux" "$CONFIG_DIR/tmux"
create_link "$DOTFILES_DIR/.config/kitty" "$CONFIG_DIR/kitty"
create_link "$DOTFILES_DIR/.config/emacs" "$CONFIG_DIR/emacs"
create_link "$DOTFILES_DIR/.config/wezterm" "$CONFIG_DIR/wezterm"

# Discord (special handling for file)
create_link "$DOTFILES_DIR/.config/discord/settings.json" "$CONFIG_DIR/discord/settings.json"

# VSCode config
create_link "$DOTFILES_DIR/.config/vscode/settings.json" "$VSCODE_CONFIG_DIR/settings.json"
create_link "$DOTFILES_DIR/.config/vscode/keybindings.json" "$VSCODE_CONFIG_DIR/keybindings.json"

echo ""
echo "Dotfiles setup completed!"
echo "Config directory: $CONFIG_DIR"
