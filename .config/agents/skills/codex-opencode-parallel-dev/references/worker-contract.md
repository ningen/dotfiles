# Worker Contract

Give every worker a single bounded task with this input structure:

```text
task:
mode: scout | implement | review
working_directory:
owned_paths:
read_only_paths:
acceptance_criteria:
validation:
allowed_tools_or_commands:
constraints:
```

State that paths outside `owned_paths` are read-only. For scout and review tasks, leave `owned_paths` empty and prohibit all edits.

For every implementation task, put the exact relevant formatter, lint, test, or build commands under `validation`. Use `not applicable` only when the change has no meaningful executable validation, and state why. Implementers may use broad shell access inside their isolated worktree for task-scoped investigation and validation, but must not mutate Git history, branches, worktrees, or external state.

Require this final response:

```text
task:
commands:
findings:
risks:
next:
```

Under `commands`, include exact shell commands with exit statuses and native tool calls with success or failure status. Under `findings`, include changed files and the result of every required validation command for implementation tasks. Keep logs concise and do not include secrets.

For `codex-scout` and `codex-reviewer`, provide repository status and diffs as task context or attached artifacts because shell execution is disabled. For `codex-implementer`, allow project-local shell commands and require worker-side validation before handoff. The orchestrating model must still rerun the relevant validation after integrating accepted worker changes.

Treat missing fields, missing required validation, unrelated edits, unreported failures, or ownership violations as a failed handoff.
