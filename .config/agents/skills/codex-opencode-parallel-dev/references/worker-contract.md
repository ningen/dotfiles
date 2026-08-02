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

Require this final response:

```text
task:
commands:
findings:
risks:
next:
```

Under `commands`, include exact shell commands with exit statuses and native tool calls with success or failure status. Under `findings`, include changed files and validation results for implementation tasks. Keep logs concise and do not include secrets.

For `codex-scout` and `codex-reviewer`, provide repository status and diffs as task context or attached artifacts because shell execution is disabled. For `codex-implementer`, allow only Git status and diff inspection; leave builds, formatters, and tests to the Codex orchestrator.

Treat missing fields, unrelated edits, unreported failures, or ownership violations as a failed handoff.
