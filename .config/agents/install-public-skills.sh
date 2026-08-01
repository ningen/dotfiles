#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
MANIFEST="${1:-$DOTFILES_DIR/.config/agents/public-skills.tsv}"

[[ -f "$MANIFEST" ]] || { echo "manifest not found: $MANIFEST" >&2; exit 1; }

remove_legacy_vendor_links() {
  local skills_dir="$HOME/.agents/skills" link target
  [[ -d "$skills_dir" ]] || return 0
  for link in "$skills_dir"/*; do
    [[ -L "$link" ]] || continue
    target="$(readlink "$link")"
    case "$target" in
      "$DOTFILES_DIR/.config/agents/vendor/"*)
        echo "REMOVE legacy vendor symlink: $link -> $target"
        rm "$link"
        ;;
    esac
  done
}

install_skill() {
  local source="$1" skill="$2"
  if [[ "$skill" == "*" ]]; then
    echo "INSTALL $source --skill '*'"
    npx -y skills add "$source" -g --agent codex --skill '*' -y --copy --full-depth </dev/null
  else
    echo "INSTALL $source --skill $skill"
    npx -y skills add "$source" -g --agent codex --skill "$skill" -y --copy --full-depth </dev/null
  fi
}

remove_legacy_vendor_links

while IFS=$'\t' read -r source skill extra || [[ -n "${source:-}" ]]; do
  [[ -n "${source:-}" ]] || continue
  [[ "$source" == \#* ]] && continue
  [[ -z "${extra:-}" ]] || { echo "invalid manifest row: $source $skill $extra" >&2; exit 1; }
  [[ -n "${skill:-}" ]] || { echo "missing skill for source: $source" >&2; exit 1; }
  install_skill "$source" "$skill"
done < "$MANIFEST"
