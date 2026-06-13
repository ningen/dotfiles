#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: capture-macos-screenshot.sh [--mode screen|front-window] [--app APP_NAME] [--output PATH]

Captures a macOS screenshot and prints the absolute PNG path.

Examples:
  capture-macos-screenshot.sh --mode screen
  capture-macos-screenshot.sh --mode front-window --app "Google Chrome"
  capture-macos-screenshot.sh --mode screen --output /private/tmp/codex-ui.png
USAGE
}

mode="screen"
app_name=""
output_path=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --mode)
      mode="${2:-}"
      shift 2
      ;;
    --app)
      app_name="${2:-}"
      shift 2
      ;;
    --output)
      output_path="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "This script currently supports macOS only." >&2
  exit 2
fi

if ! command -v screencapture >/dev/null 2>&1; then
  echo "screencapture was not found." >&2
  exit 2
fi

if [[ -z "$output_path" ]]; then
  timestamp="$(date +%Y%m%d-%H%M%S)"
  output_path="${TMPDIR:-/tmp}/codex-ui-screenshot-${timestamp}.png"
fi

case "$output_path" in
  /*) ;;
  *) output_path="$(pwd)/$output_path" ;;
esac

mkdir -p "$(dirname "$output_path")"

case "$mode" in
  screen)
    screencapture -x "$output_path"
    ;;
  front-window)
    if [[ -n "$app_name" ]]; then
      osascript - "$app_name" <<'APPLESCRIPT' >/dev/null
on run argv
  tell application (item 1 of argv) to activate
end run
APPLESCRIPT
      sleep 0.35
    fi

    if ! bounds="$(osascript <<'APPLESCRIPT' 2>&1
tell application "System Events"
  set frontProc to first application process whose frontmost is true
  if not (exists window 1 of frontProc) then error "Frontmost app has no window"
  set {xPos, yPos} to position of window 1 of frontProc
  set {winWidth, winHeight} to size of window 1 of frontProc
  return (xPos as integer) & "," & (yPos as integer) & "," & (winWidth as integer) & "," & (winHeight as integer)
end tell
APPLESCRIPT
)"; then
      echo "Could not read front window bounds. Grant Accessibility permission to Codex, or use --mode screen. osascript said: $bounds" >&2
      exit 1
    fi

    if [[ ! "$bounds" =~ ^-?[0-9]+,-?[0-9]+,[0-9]+,[0-9]+$ ]]; then
      echo "Could not determine front window bounds: $bounds" >&2
      exit 1
    fi

    screencapture -x -R "$bounds" "$output_path"
    ;;
  *)
    echo "Unsupported mode: $mode" >&2
    usage >&2
    exit 2
    ;;
esac

if [[ ! -s "$output_path" ]]; then
  echo "Screenshot was not created or is empty: $output_path" >&2
  exit 1
fi

printf '%s\n' "$output_path"
