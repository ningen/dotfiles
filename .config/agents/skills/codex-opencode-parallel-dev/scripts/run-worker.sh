#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "usage: run-worker.sh <codex-scout|codex-implementer|codex-reviewer> <working-directory> <task-file> [artifact-file ...]" >&2
}

if [ "$#" -lt 3 ]; then
  usage
  exit 64
fi

agent=$1
worker_dir=$2
task_file=$3
shift 3

case "$agent" in
  codex-scout | codex-implementer | codex-reviewer) ;;
  *)
    echo "unsupported worker agent: $agent" >&2
    usage
    exit 64
    ;;
esac

if ! command -v opencode >/dev/null 2>&1; then
  echo "opencode is not available on PATH" >&2
  exit 69
fi

if [ ! -d "$worker_dir" ]; then
  echo "working directory does not exist: $worker_dir" >&2
  exit 66
fi

if [ ! -f "$task_file" ] || [ ! -s "$task_file" ]; then
  echo "task file is missing or empty: $task_file" >&2
  exit 66
fi

model=${OPENCODE_WORKER_MODEL:-opencode-go/deepseek-v4-flash}
format=${OPENCODE_WORKER_FORMAT:-json}
task_prompt=$(<"$task_file")
attachments=()

for artifact_file in "$@"; do
  if [ ! -f "$artifact_file" ]; then
    echo "artifact file does not exist: $artifact_file" >&2
    exit 66
  fi
  attachments+=(--file "$artifact_file")
done

exec opencode run \
  --model "$model" \
  --agent "$agent" \
  --dir "$worker_dir" \
  --format "$format" \
  "${attachments[@]}" \
  -- \
  "$task_prompt"
