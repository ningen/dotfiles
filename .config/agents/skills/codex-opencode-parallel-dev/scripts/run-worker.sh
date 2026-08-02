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

for required_command in opencode jq tee; do
  if ! command -v "$required_command" >/dev/null 2>&1; then
    echo "$required_command is not available on PATH" >&2
    exit 69
  fi
done

if [ ! -d "$worker_dir" ]; then
  echo "working directory does not exist: $worker_dir" >&2
  exit 66
fi

if [ "$agent" = codex-implementer ]; then
  for required_command in git tar; do
    if ! command -v "$required_command" >/dev/null 2>&1; then
      echo "$required_command is not available on PATH" >&2
      exit 69
    fi
  done
  if ! git -C "$worker_dir" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "implementer working directory is not a Git worktree: $worker_dir" >&2
    exit 65
  fi
  git_dir=$(git -C "$worker_dir" rev-parse --path-format=absolute --git-dir)
  git_common_dir=$(git -C "$worker_dir" rev-parse --path-format=absolute --git-common-dir)
  if [ "$git_dir" = "$git_common_dir" ]; then
    echo "implementer requires a linked Git worktree: $worker_dir" >&2
    exit 65
  fi
  if git -C "$worker_dir" symbolic-ref --quiet HEAD >/dev/null 2>&1; then
    echo "implementer requires a detached Git worktree: $worker_dir" >&2
    exit 65
  fi
  if [ -n "$(git -C "$worker_dir" status --porcelain=v1 --untracked-files=all)" ]; then
    echo "implementer requires a clean isolated Git worktree: $worker_dir" >&2
    exit 65
  fi
fi

if [ ! -f "$task_file" ] || [ ! -s "$task_file" ]; then
  echo "task file is missing or empty: $task_file" >&2
  exit 66
fi

model=${OPENCODE_WORKER_MODEL:-opencode-go/deepseek-v4-flash}
format=${OPENCODE_WORKER_FORMAT:-json}
task_prompt=$(<"$task_file")
attachments=()

if [ "$format" != json ]; then
  echo "OPENCODE_WORKER_FORMAT must be json so worker results can be collected" >&2
  exit 64
fi

validate_id() {
  case "$2" in
    "" | "." | ".." | *[!a-zA-Z0-9._-]*)
      echo "$1 must contain only letters, digits, dots, underscores, or hyphens: $2" >&2
      exit 64
      ;;
  esac
}

started_at=$(date -u +%Y-%m-%dT%H:%M:%SZ)
default_run_id=$(date -u +%Y%m%dT%H%M%SZ)-$$
run_id=${OPENCODE_WORKER_RUN_ID:-$default_run_id}
worker_id=${OPENCODE_WORKER_ID:-$agent-$$}
artifact_root=${OPENCODE_WORKER_ARTIFACT_ROOT:-${TMPDIR:-/tmp}/codex-runs}

validate_id OPENCODE_WORKER_RUN_ID "$run_id"
validate_id OPENCODE_WORKER_ID "$worker_id"

for artifact_file in "$@"; do
  if [ ! -f "$artifact_file" ]; then
    echo "artifact file does not exist: $artifact_file" >&2
    exit 66
  fi
  attachments+=(--file "$artifact_file")
done

run_dir=$artifact_root/$run_id
result_dir=$run_dir/$worker_id

umask 077
if [ -L "$artifact_root" ]; then
  echo "worker artifact root must not be a symbolic link: $artifact_root" >&2
  exit 73
fi
mkdir -p "$run_dir"
if ! mkdir "$result_dir"; then
  echo "worker result directory already exists: $result_dir" >&2
  exit 73
fi
cp "$task_file" "$result_dir/task.md"

jq -n \
  --arg run_id "$run_id" \
  --arg worker_id "$worker_id" \
  --arg agent "$agent" \
  --arg model "$model" \
  --arg working_directory "$worker_dir" \
  --arg result_directory "$result_dir" \
  --arg started_at "$started_at" \
  '{
    status: "running",
    run_id: $run_id,
    worker_id: $worker_id,
    agent: $agent,
    model: $model,
    working_directory: $working_directory,
    result_directory: $result_directory,
    started_at: $started_at
  }' >"$result_dir/result.json.tmp"
mv "$result_dir/result.json.tmp" "$result_dir/result.json"

finalized=false
# shellcheck disable=SC2329 # Invoked by the EXIT trap.
finalize_incomplete() {
  launcher_exit=$?
  if [ "$finalized" != true ] && [ -f "$result_dir/result.json" ]; then
    set +e
    jq \
      --arg completed_at "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
      --argjson launcher_exit_code "$launcher_exit" \
      '. + {
        status: "collector_interrupted",
        completed_at: $completed_at,
        launcher_exit_code: $launcher_exit_code
      }' "$result_dir/result.json" >"$result_dir/result.json.tmp"
    mv "$result_dir/result.json.tmp" "$result_dir/result.json"
  fi
}
trap finalize_incomplete EXIT

echo "worker artifacts: $result_dir" >&2

opencode_args=(
  run
  --model "$model"
  --agent "$agent"
  --dir "$worker_dir"
  --format "$format"
)
if [ "${#attachments[@]}" -gt 0 ]; then
  opencode_args+=("${attachments[@]}")
fi
opencode_args+=(-- "$task_prompt")

set +e
opencode "${opencode_args[@]}" | tee "$result_dir/events.jsonl"
pipeline_status=("${PIPESTATUS[@]}")
opencode_status=${pipeline_status[0]}
tee_status=${pipeline_status[1]}

jq -rs '
  [.[] | select(.type == "text") | .part.text? // empty]
  | last // empty
' "$result_dir/events.jsonl" >"$result_dir/summary.md"
summary_parse_exit=$?
if [ "$summary_parse_exit" -ne 0 ]; then
  : >"$result_dir/summary.md"
fi

git_status_exit=0
git_diff_exit=0
untracked_list_exit=0
untracked_archive_exit=0
if [ "$agent" = codex-implementer ]; then
  git -C "$worker_dir" status --short --untracked-files=all >"$result_dir/git-status.txt"
  git_status_exit=$?
  git -C "$worker_dir" diff HEAD --binary --no-ext-diff >"$result_dir/changes.patch"
  git_diff_exit=$?
  git -C "$worker_dir" ls-files --others --exclude-standard -z >"$result_dir/untracked-files.zlist"
  untracked_list_exit=$?
  tar \
    -C "$worker_dir" \
    --null \
    --files-from="$result_dir/untracked-files.zlist" \
    --create \
    --file="$result_dir/untracked-files.tar"
  untracked_archive_exit=$?
fi

completed_at=$(date -u +%Y-%m-%dT%H:%M:%SZ)
completed_at_exit=$?
event_count=$(wc -l <"$result_dir/events.jsonl")
event_count_exit=$?
set -e

summary_parse_ok=false
if [ "$summary_parse_exit" -eq 0 ]; then
  summary_parse_ok=true
fi
summary_present=false
if [ "$summary_parse_ok" = true ] && [ -s "$result_dir/summary.md" ]; then
  summary_present=true
fi

collector_exit=0
for collector_step_exit in \
  "$summary_parse_exit" \
  "$git_status_exit" \
  "$git_diff_exit" \
  "$untracked_list_exit" \
  "$untracked_archive_exit" \
  "$completed_at_exit" \
  "$event_count_exit"; do
  if [ "$collector_step_exit" -ne 0 ] && [ "$collector_exit" -eq 0 ]; then
    collector_exit=$collector_step_exit
  fi
done

result_status=completed
if [ "$collector_exit" -ne 0 ]; then
  result_status=collector_error
elif [ "$tee_status" -ne 0 ]; then
  result_status=output_error
elif [ "$opencode_status" -ne 0 ]; then
  result_status=worker_failed
fi

jq -n \
  --arg status "$result_status" \
  --arg run_id "$run_id" \
  --arg worker_id "$worker_id" \
  --arg agent "$agent" \
  --arg model "$model" \
  --arg working_directory "$worker_dir" \
  --arg result_directory "$result_dir" \
  --arg started_at "$started_at" \
  --arg completed_at "$completed_at" \
  --argjson exit_code "$opencode_status" \
  --argjson tee_exit_code "$tee_status" \
  --argjson collector_exit_code "$collector_exit" \
  --argjson event_count "$event_count" \
  --argjson summary_parse_ok "$summary_parse_ok" \
  --argjson summary_present "$summary_present" \
  --argjson attachment_count "$#" \
  '{
    status: $status,
    run_id: $run_id,
    worker_id: $worker_id,
    agent: $agent,
    model: $model,
    working_directory: $working_directory,
    result_directory: $result_directory,
    started_at: $started_at,
    completed_at: $completed_at,
    exit_code: $exit_code,
    tee_exit_code: $tee_exit_code,
    collector_exit_code: $collector_exit_code,
    event_count: $event_count,
    summary_parse_ok: $summary_parse_ok,
    summary_present: $summary_present,
    attachment_count: $attachment_count,
    files: {
      task: "task.md",
      events: "events.jsonl",
      summary: "summary.md",
      git_status: (if $agent == "codex-implementer" then "git-status.txt" else null end),
      tracked_changes: (if $agent == "codex-implementer" then "changes.patch" else null end),
      untracked_list: (if $agent == "codex-implementer" then "untracked-files.zlist" else null end),
      untracked_archive: (if $agent == "codex-implementer" then "untracked-files.tar" else null end)
    }
  }' >"$result_dir/result.json.tmp"
mv "$result_dir/result.json.tmp" "$result_dir/result.json"

finalized=true
trap - EXIT

if [ "$tee_status" -ne 0 ]; then
  exit "$tee_status"
fi
if [ "$collector_exit" -ne 0 ]; then
  exit 74
fi
exit "$opencode_status"
