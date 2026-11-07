#!/usr/bin/env bash
set -euo pipefail

mode="${1:-area}"
export XDG_SCREENSHOTS_DIR="${XDG_SCREENSHOTS_DIR:-$HOME/Pictures/Screenshots}"
mkdir -p "$XDG_SCREENSHOTS_DIR"

exec grimblast --freeze copysave "$mode"
