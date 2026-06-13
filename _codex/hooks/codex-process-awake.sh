#!/usr/bin/env bash

set -euo pipefail

if [[ "$(uname -s)" != "Darwin" ]]; then
    exit 0
fi

caffeinate_bin="$(command -v caffeinate || true)"
if [[ -z "$caffeinate_bin" ]]; then
    exit 0
fi

state_root="${TMPDIR:-/tmp}/codex-process-awake"
mkdir -p "$state_root"

find_codex_pid() {
    local pid parent comm

    pid="$$"
    while parent="$(ps -p "$pid" -o ppid= 2>/dev/null | tr -d '[:space:]')" && [[ -n "$parent" && "$parent" != "0" ]]; do
        comm="$(ps -p "$parent" -o comm= 2>/dev/null || true)"
        comm="${comm##*/}"
        case "$comm" in
            codex | Codex)
                printf '%s\n' "$parent"
                return 0
                ;;
        esac
        pid="$parent"
    done

    return 1
}

is_caffeinate_pid() {
    local pid="$1"
    local comm

    [[ -n "$pid" ]] || return 1
    kill -0 "$pid" 2>/dev/null || return 1
    comm="$(ps -p "$pid" -o comm= 2>/dev/null || true)"
    [[ "${comm##*/}" == "caffeinate" ]]
}

codex_pid="$(find_codex_pid || true)"
if [[ -z "$codex_pid" ]]; then
    exit 0
fi

pid_file="$state_root/$codex_pid.pid"
if [[ -f "$pid_file" ]]; then
    existing_pid="$(tr -d '[:space:]' < "$pid_file")"
    if is_caffeinate_pid "$existing_pid"; then
        exit 0
    fi
fi

nohup "$caffeinate_bin" -dimsu -w "$codex_pid" >/dev/null 2>&1 &
printf '%s\n' "$!" > "$pid_file"
