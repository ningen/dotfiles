#!/usr/bin/env bash
set -euo pipefail

SELF="$(readlink -f "$0")"
THEME="${XDG_CONFIG_HOME:-$HOME/.config}/rofi/cheatsheet.rasi"

if [[ -z "${ROFI_RETV:-}" ]]; then
  exec rofi \
    -show hyprcheat \
    -modes "hyprcheat:$SELF" \
    -theme "$THEME" \
    -matching fuzzy \
    -sorting-method fzf \
    -i \
    -selected-row 1
fi

if [[ "$ROFI_RETV" != "0" ]]; then
  exit 0
fi

binds="$(hyprctl binds -j)"
rows="$(
  jq -r '
    def hasbit($m; $n): (($m / $n | floor) % 2) == 1;

    def mods($m):
      [
        if hasbit($m; 64) then "SUPER" else empty end,
        if hasbit($m; 4) then "CTRL" else empty end,
        if hasbit($m; 8) then "ALT" else empty end,
        if hasbit($m; 1) then "SHIFT" else empty end
      ];

    def keyname:
      {
        "Return": "Enter",
        "mouse:272": "LMB",
        "mouse:273": "RMB",
        "mouse_down": "Scroll ↓",
        "mouse_up": "Scroll ↑",
        "XF86AudioRaiseVolume": "Vol +",
        "XF86AudioLowerVolume": "Vol -",
        "XF86AudioMute": "Mute",
        "XF86AudioMicMute": "Mic Mute",
        "XF86MonBrightnessUp": "Bright +",
        "XF86MonBrightnessDown": "Bright -",
        "XF86AudioNext": "Next",
        "XF86AudioPrev": "Prev",
        "XF86AudioPlay": "Play",
        "XF86AudioPause": "Pause"
      }[.] // .;

    def keylabel:
      if . == "left" then "←"
      elif . == "right" then "→"
      elif . == "up" then "↑"
      elif . == "down" then "↓"
      else keyname end;

    def rank:
      {
        "Launch": 1,
        "Window": 2,
        "Focus": 3,
        "Workspace": 4,
        "Media": 5,
        "System": 6,
        "Help": 7
      }[.] // 99;

    def chip_color:
      if . == "SUPER" then "#7aa2f7"
      elif . == "SHIFT" then "#bb9af7"
      elif . == "CTRL" then "#7dcfff"
      elif . == "ALT" then "#9ece6a"
      else "#c0caf5" end;

    def chip:
      "<span foreground=\"" + chip_color + "\" background=\"#414868\" weight=\"bold\"> " + (. | @html) + " </span>";

    def keycaps($keys):
      $keys | map(chip) | join("<span foreground=\"#565f89\"> + </span>");

    [
      to_entries[]
      | .key as $index
      | .value
      | select(.description != "")
      | .description as $desc
      | (($desc | capture("^(?<category>[^:]+): (?<label>.*)$")) // { category: "Other", label: $desc }) as $entry
      | (mods(.modmask) + [.key | keylabel]) as $keys
      | {
          index: $index,
          rank: ($entry.category | rank),
          category: $entry.category,
          header: "<span foreground=\"#565f89\">──</span> <span foreground=\"#7dcfff\" weight=\"bold\">" + ($entry.category | ascii_upcase | @html) + "</span>",
          row: (keycaps($keys) + "  <span foreground=\"#c0caf5\">" + ($entry.label | @html) + "</span>"),
          search: (([$entry.category] + $keys + [$entry.label]) | join(" "))
        }
    ]
    | sort_by([.rank, .index])[]
    | [.category, .header, .row, .search]
    | @tsv
  ' <<<"$binds"
)"

printf '\0prompt\x1fHyprland keybinds\n'
printf '\0message\x1ftype to filter · esc to close\n'
printf '\0markup-rows\x1ftrue\n'
printf '\0no-custom\x1ftrue\n'

if [[ -z "$rows" ]]; then
  printf '%s\n' "No described keybinds found"
  exit 0
fi

last_category=""
while IFS=$'\t' read -r category header row search; do
  if [[ "$category" != "$last_category" ]]; then
    printf '\u200b\0display\x1f%s\0nonselectable\x1ftrue\n' "$header"
    last_category="$category"
  fi
  printf '%s\0display\x1f%s\n' "$search" "$row"
done <<<"$rows"
