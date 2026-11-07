#!/usr/bin/env sh
set -u

screen=""
if command -v hyprctl >/dev/null 2>&1 && command -v jq >/dev/null 2>&1; then
  cursor=$(hyprctl -j cursorpos 2>/dev/null) || cursor=""
  monitors=$(hyprctl -j monitors 2>/dev/null) || monitors=""
  if [ -n "$cursor" ] && [ -n "$monitors" ]; then
    cursor_x=$(printf '%s' "$cursor" | jq -r '.x')
    cursor_y=$(printf '%s' "$cursor" | jq -r '.y')
    screen=$(printf '%s' "$monitors" | jq -r \
      --argjson x "$cursor_x" \
      --argjson y "$cursor_y" \
      '.[] | select(.x <= $x and $x < (.x + .width) and .y <= $y and $y < (.y + .height)) | .name' \
      | head -n 1)
  fi
fi

toggle_panel() {
  if [ -n "$screen" ]; then
    qs -c audio ipc call audio toggleOn "$screen" 2>/dev/null
  else
    qs -c audio ipc call audio toggle 2>/dev/null
  fi
}

if toggle_panel; then
  exit 0
fi

qs -c audio -n -d >/dev/null 2>&1 || true

i=0
while [ "$i" -lt 30 ]; do
  sleep 0.1
  if toggle_panel; then
    exit 0
  fi
  i=$((i + 1))
done
