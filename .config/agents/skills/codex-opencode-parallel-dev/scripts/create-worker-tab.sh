#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "usage: create-worker-tab.sh <label> [working-directory]" >&2
}

if [ "$#" -lt 1 ] || [ "$#" -gt 2 ]; then
  usage
  exit 64
fi

if [ "${HERDR_ENV:-}" != 1 ]; then
  echo "The orchestrating model is not running inside a Herdr-managed pane" >&2
  exit 69
fi

for required_command in herdr jq; do
  if ! command -v "$required_command" >/dev/null 2>&1; then
    echo "$required_command is not available on PATH" >&2
    exit 69
  fi
done

label=$1
task_cwd=${2:-$PWD}

if [ ! -d "$task_cwd" ]; then
  echo "working directory does not exist: $task_cwd" >&2
  exit 66
fi

current_pane=$(herdr pane current)
workspace_id=$(printf '%s\n' "$current_pane" | jq -er '.result.pane.workspace_id')
created_tab=$(herdr tab create --workspace "$workspace_id" --cwd "$task_cwd" --label "$label" --no-focus)
tab_id=$(printf '%s\n' "$created_tab" | jq -er '.result.tab.tab_id')
root_pane_id=$(printf '%s\n' "$created_tab" | jq -er '.result.root_pane.pane_id')

jq -n \
  --arg workspace_id "$workspace_id" \
  --arg tab_id "$tab_id" \
  --arg root_pane_id "$root_pane_id" \
  '{workspace_id: $workspace_id, tab_id: $tab_id, root_pane_id: $root_pane_id}'
