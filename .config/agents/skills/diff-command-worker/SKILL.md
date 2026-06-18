---
name: diff-command-worker
description: Use when Codex should delegate low-cost read-only command execution, git diff inspection, searches, and log collection to a worker and return structured results to a stronger orchestration model.
---

# Diff Command Worker

Use this workflow when a task needs command output, git diff inspection, repository search, or log collection that can be handled by a cheaper worker model while the main orchestration model keeps ownership of reasoning and decisions.

## Delegation Policy

- Keep orchestration, planning, code review judgment, and final user communication in the strongest available model.
- Delegate mechanical execution to the cheapest capable worker model when the runtime supports subagent model selection.
- Prefer this worker for `git diff`, `git status`, `rg`, `sed`, `nl`, `ls`, and targeted command output gathering.
- Do not use this worker for code edits, commits, destructive commands, dependency installation, or broad design decisions.

## Worker Contract

Ask the worker to return:

```text
task:
commands:
findings:
risks:
next:
```

Require exact command names, exit statuses, and concise highlights from stdout or stderr. The worker should not paste large logs unless the exact content is needed for diagnosis.

If a command would require elevated permissions, network access, or a destructive action, the worker should stop and return the constraint instead of attempting a workaround.
