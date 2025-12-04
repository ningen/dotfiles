#!/bin/bash

set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$DOTFILES_DIR/dotfiles-links.yaml"

# Detect OS
detect_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo "linux"
    else
        echo "unknown"
    fi
}

OS_TYPE=$(detect_os)

# Set XDG_CONFIG_HOME based on OS
if [[ -n "$XDG_CONFIG_HOME" ]]; then
    CONFIG_DIR="$XDG_CONFIG_HOME"
else
    CONFIG_DIR="$HOME/.config"
fi

# Set VSCode config path
case "$OS_TYPE" in
    macos)
        VSCODE_CONFIG_DIR="$HOME/Library/Application Support/Code/User"
        ;;
    *)
        VSCODE_CONFIG_DIR="$HOME/.config/Code/User"
        ;;
esac

echo "========================================="
echo "Dotfiles Setup"
echo "========================================="
echo "OS detected: $OS_TYPE"
echo "Config directory: $CONFIG_DIR"
echo "VSCode directory: $VSCODE_CONFIG_DIR"
echo "========================================="
echo ""

# Create local file (only for non-Windows as nix is not available on Windows)
if [[ "$OS_TYPE" != "windows" ]]; then
    mkdir -p "$DOTFILES_DIR/.config/nix"
    touch "$DOTFILES_DIR/.config/nix/nix-local.conf"
fi

# Create config directories
mkdir -p "$CONFIG_DIR"
mkdir -p "$VSCODE_CONFIG_DIR"

# Function to expand variables in string
expand_vars() {
    local str="$1"
    str="${str//\$CONFIG_DIR/$CONFIG_DIR}"
    str="${str//\$VSCODE_CONFIG_DIR/$VSCODE_CONFIG_DIR}"
    echo "$str"
}

# Function to create symlink
create_link() {
    local src="$1"
    local dest="$2"
    local type="$3"

    # Expand source path (relative to DOTFILES_DIR)
    src="$DOTFILES_DIR/$src"

    # Expand variables in destination path
    dest=$(expand_vars "$dest")

    # Create parent directory if it doesn't exist
    mkdir -p "$(dirname "$dest")"

    # Remove existing symlink or file/directory if it exists
    if [[ -L "$dest" ]]; then
        rm "$dest"
    elif [[ -e "$dest" ]]; then
        echo "⚠ Warning: $dest already exists and is not a symlink. Skipping."
        return 1
    fi

    # Create symlink
    if ln -sfn "$src" "$dest"; then
        echo "✓ Linked: $dest -> $src"
        return 0
    else
        echo "✗ Failed to link: $dest"
        return 1
    fi
}

# Simple YAML parser for our specific format
parse_yaml_section() {
    local section="$1"
    local current_section=""
    local in_target_section=false
    local source=""
    local target=""
    local type=""

    while IFS= read -r line; do
        # Skip comments and empty lines
        [[ "$line" =~ ^#.*$ ]] && continue
        [[ -z "$line" ]] && continue

        # Check if this is a section header (no leading spaces)
        if [[ "$line" =~ ^([a-z_]+):$ ]]; then
            current_section="${BASH_REMATCH[1]}"
            if [[ "$current_section" == "$section" ]]; then
                in_target_section=true
            else
                in_target_section=false
            fi
            continue
        fi

        # Skip if not in target section
        [[ "$in_target_section" == false ]] && continue

        # Parse list items
        if [[ "$line" =~ ^[[:space:]]*-[[:space:]]+source:[[:space:]]*(.+)$ ]]; then
            # New item, process previous if exists
            if [[ -n "$source" && -n "$target" && -n "$type" ]]; then
                echo "$source|$target|$type"
            fi
            source="${BASH_REMATCH[1]}"
            target=""
            type=""
        elif [[ "$line" =~ ^[[:space:]]+target:[[:space:]]*(.+)$ ]]; then
            target="${BASH_REMATCH[1]}"
        elif [[ "$line" =~ ^[[:space:]]+type:[[:space:]]*(.+)$ ]]; then
            type="${BASH_REMATCH[1]}"
        fi
    done < "$CONFIG_FILE"

    # Output last item if exists
    if [[ -n "$source" && -n "$target" && -n "$type" ]]; then
        echo "$source|$target|$type"
    fi
}

# Process common links
echo "Creating common links..."
while IFS='|' read -r source target type; do
    create_link "$source" "$target" "$type"
done < <(parse_yaml_section "common")

echo ""

# Process unix_only links
if [[ "$OS_TYPE" == "macos" || "$OS_TYPE" == "linux" ]]; then
    echo "Creating Unix-specific links..."
    while IFS='|' read -r source target type; do
        create_link "$source" "$target" "$type"
    done < <(parse_yaml_section "unix_only")
    echo ""
fi

# Process VSCode links
echo "Creating VSCode links..."
while IFS='|' read -r source target type; do
    create_link "$source" "$target" "$type"
done < <(parse_yaml_section "vscode")

echo ""
echo "========================================="
echo "✓ Dotfiles setup completed!"
echo "========================================="
