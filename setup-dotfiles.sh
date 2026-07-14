#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$DOTFILES_DIR/dotfiles-links.yaml"
DRY_RUN=false

usage() { echo "usage: $0 [--dry-run] [--config PATH]"; }
while (($#)); do
  case "$1" in
    --dry-run) DRY_RUN=true; shift ;;
    --config) [[ $# -ge 2 ]] || { usage >&2; exit 64; }; CONFIG_FILE="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) usage >&2; exit 64 ;;
  esac
done
[[ -f "$CONFIG_FILE" ]] || { echo "config not found: $CONFIG_FILE" >&2; exit 1; }

detect_platform() {
  if [[ "${OSTYPE:-}" == darwin* ]]; then echo macos; return; fi
  if [[ -r /proc/sys/kernel/osrelease ]] && grep -qi microsoft /proc/sys/kernel/osrelease; then echo wsl; return; fi
  if [[ -n "${WSL_INTEROP:-}" ]]; then echo wsl; return; fi
  if [[ "${OSTYPE:-}" == linux* ]]; then echo desktop_linux; return; fi
  echo unknown
}

PLATFORM="$(detect_platform)"
case "$PLATFORM" in
  macos) SECTIONS=(unix_only macos_only vscode); VSCODE_CONFIG_DIR="$HOME/Library/Application Support/Code/User" ;;
  wsl) SECTIONS=(unix_only wsl_only); VSCODE_CONFIG_DIR="$HOME/.config/Code/User" ;;
  desktop_linux) SECTIONS=(unix_only desktop_linux_only); VSCODE_CONFIG_DIR="$HOME/.config/Code/User" ;;
  *) echo "unsupported platform: $PLATFORM" >&2; exit 1 ;;
esac
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"

expand_target() {
  local value="$1"
  value="${value//\$CONFIG_DIR/$CONFIG_DIR}"
  value="${value//\$VSCODE_CONFIG_DIR/$VSCODE_CONFIG_DIR}"
  value="${value//\$HOME/$HOME}"
  value="${value/#\~/$HOME}"
  printf '%s\n' "$value"
}

parse_section() {
  local wanted="$1" section= source= target= type= active=false line
  while IFS= read -r line || [[ -n "$line" ]]; do
    [[ "$line" =~ ^[[:space:]]*(#.*)?$ ]] && continue
    if [[ "$line" =~ ^([a-z_]+):([[:space:]]*\[\])?[[:space:]]*$ ]]; then
      if $active && [[ -n "$source" && -n "$target" && -n "$type" ]]; then printf '%s|%s|%s\n' "$source" "$target" "$type"; fi
      section="${BASH_REMATCH[1]}"; [[ "$section" == "$wanted" ]] && active=true || active=false
      source= target= type=
    elif $active && [[ "$line" =~ ^[[:space:]]*-[[:space:]]+source:[[:space:]]*(.+)$ ]]; then
      if [[ -n "$source" && -n "$target" && -n "$type" ]]; then printf '%s|%s|%s\n' "$source" "$target" "$type"; fi
      source="${BASH_REMATCH[1]}"; target= type=
    elif $active && [[ "$line" =~ ^[[:space:]]+target:[[:space:]]*(.+)$ ]]; then target="${BASH_REMATCH[1]}"
    elif $active && [[ "$line" =~ ^[[:space:]]+type:[[:space:]]*(.+)$ ]]; then type="${BASH_REMATCH[1]}"
    fi
  done < "$CONFIG_FILE"
  if $active && [[ -n "$source" && -n "$target" && -n "$type" ]]; then printf '%s|%s|%s\n' "$source" "$target" "$type"; fi
}

LOCAL_SOURCE="$DOTFILES_DIR/.gitconfig.local"
LOCAL_EXAMPLE="$DOTFILES_DIR/.gitconfig.local.example"
if [[ ! -e "$LOCAL_SOURCE" ]]; then
  [[ -f "$LOCAL_EXAMPLE" ]] || { echo "missing source: $LOCAL_EXAMPLE" >&2; exit 1; }
  if $DRY_RUN; then echo "COPY $LOCAL_EXAMPLE -> $LOCAL_SOURCE"
  else cp "$LOCAL_EXAMPLE" "$LOCAL_SOURCE"
  fi
fi

records=()
missing=0
for section in "${SECTIONS[@]}"; do
  while IFS='|' read -r source target type; do
    [[ -n "$source" ]] || continue
    src="$DOTFILES_DIR/$source"; dest="$(expand_target "$target")"
    if [[ "$src" == "$LOCAL_SOURCE" && $DRY_RUN == true && ! -e "$src" ]]; then :
    elif [[ ! -e "$src" ]]; then echo "missing source: $src" >&2; missing=1
    fi
    [[ "$type" == file || "$type" == directory ]] || { echo "invalid type '$type' for $source" >&2; missing=1; }
    records+=("$src|$dest|$type")
  done < <(parse_section "$section")
done
((missing == 0)) || { echo "preflight failed; no links changed" >&2; exit 1; }

echo "platform=$PLATFORM sections=${SECTIONS[*]}"
for record in "${records[@]}"; do
  IFS='|' read -r src dest type <<< "$record"
  if [[ -L "$dest" ]]; then action=RELINK
  elif [[ -e "$dest" ]]; then echo "SKIP existing non-symlink: $dest"; continue
  else action=LINK
  fi
  if $DRY_RUN; then echo "$action $dest -> $src"; continue; fi
  mkdir -p "$(dirname "$dest")"
  [[ -L "$dest" ]] && rm "$dest"
  ln -s "$src" "$dest"
  echo "LINKED $dest -> $src"
done
