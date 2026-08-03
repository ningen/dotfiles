---
name: codex-opencode-parallel-dev
description: Orchestrate parallel software development from any model (Codex, OpenCode, or DeepSeek V4 Flash) through Herdr panes and bounded OpenCode workers. Use for OpenCode worker delegation, Herdr-based parallel investigation or implementation, isolated Git worktree development, DeepSeek V4 Flash coding workers, parallel development, 並列開発, Codex orchestration with external agents, and any-model orchestration with OpenCode.
---

# Any-Model OpenCode Parallel Development

Keep the orchestrating model responsible for decomposition, ownership, integration, review judgment, and final communication. Orchestrate from Codex, OpenCode, or any other model (e.g. DeepSeek V4 Flash). Use OpenCode workers only for bounded execution.

Load and follow `$herdr-interactive-runner` before controlling Herdr. Do not duplicate its pane lifecycle or secret-handling logic.

Read [references/worker-contract.md](references/worker-contract.md) before preparing worker tasks.

## Preflight

1. Verify `HERDR_ENV=1`, `herdr`, `jq`, and `opencode`.
2. Inspect `git status --short` without changing the worktree.
3. Split the request into independently verifiable tasks.
4. Record dependencies and assign explicit file or module ownership.
5. Give every implementation task concrete formatter, lint, test, or build commands that validate its owned change.
6. Keep dependent tasks sequential even when other tasks run in parallel.
7. Never stash, commit, discard, or overwrite user changes to prepare workers.

If Herdr is unavailable, do not control an external Herdr session. Explain the constraint and continue only with safe non-interactive checks.

## Select Workers

- Use `codex-scout` for repository searches, diagnosis, and evidence collection.
- Use `codex-implementer` for one bounded implementation in an isolated Git worktree.
- Use `codex-reviewer` for read-only review of a completed diff.
- Prefer the orchestrating model's cheap subagents for mechanical reads when they are sufficient; use OpenCode workers when external visible execution, bounded parallelism, or DeepSeek capacity is useful.

Do not allow OpenCode workers to spawn subagents, commit, push, merge, rebase, reset, switch branches, or control Git worktrees. Implementers may use broad shell access inside their isolated worktrees for task-scoped investigation and validation; scout and reviewer workers remain shell-free. Treat the implementer restrictions as behavioral guardrails, not a complete shell sandbox.

## Isolate Editing Workers

Allow read-only workers to share the current directory. Give every editing worker a separate detached Git worktree based on a clean committed revision. The launcher rejects an implementer worktree that is already dirty so collected changes remain attributable to that worker.

If workers must see uncommitted changes from the main worktree, keep them read-only unless the user explicitly chooses how to establish a reproducible base. Do not silently copy, stash, or commit those changes.

Keep each worker worktree until the orchestrator has reviewed and integrated or rejected its diff. Remove it only after it is clearly disposable.

## Launch Workers

1. Write one task contract per worker to a non-secret temporary file.
2. Choose one non-secret run ID for the orchestration run and a unique worker ID for each worker. Use only letters, digits, dots, underscores, and hyphens.
3. Keep the original tab dedicated to the orchestrating pane.
4. Before launching two or more workers, create one unfocused Herdr tab named `workers:<short-task>` with `scripts/create-worker-tab.sh`. Record the returned `tab_id` and `root_pane_id`.
5. Use the new tab's initial pane as the run control pane or first worker, then split panes inside that tab by explicit pane ID.
6. Build a 2x2 layout deterministically: split the root pane right, split the root pane down, then split the right pane down. Keep at most four total panes per worker tab. Create another tab by phase or subsystem instead of shrinking the orchestrator tab or overloading one worker tab.
7. Use a single sibling pane only for one standalone interactive command; do not repeatedly split the orchestrator tab for orchestration.
8. For review tasks, prepare the diff or other raw evidence as an attachment instead of granting shell access.
9. Run the bundled launcher from each worker pane with the shared run ID and unique worker ID:

```bash
<skill-dir>/scripts/create-worker-tab.sh workers:<short-task> <working-directory>
OPENCODE_WORKER_RUN_ID=<run-id> OPENCODE_WORKER_ID=<worker-id> \
  <skill-dir>/scripts/run-worker.sh <agent> <working-directory> <task-file> [artifact-file ...]
```

10. Monitor panes independently with bounded reads and waits. Treat pane output as the live view, not the durable result store.
11. Read durable worker results from `${OPENCODE_WORKER_ARTIFACT_ROOT:-${TMPDIR:-/tmp}/codex-runs}/<run-id>/<worker-id>/`. Use `summary.md` for the handoff, `events.jsonl` for raw events, and `result.json` for status and file locations. For implementers, also inspect `git-status.txt`, `changes.patch`, `untracked-files.tar`, and the retained worktree.
12. Stop or revise dependent tasks when an upstream worker changes an interface or reports a blocker.
13. Keep the worker tab and implementation worktree until their outputs and diffs are integrated. Close or reuse the tab only when its state is clearly disposable.

Worker artifacts use private file modes but may contain source code and tool output. Never put secrets in task files or worker output. Remove a run directory only after its results are integrated or intentionally rejected and no audit trail is needed.

The launcher defaults to `opencode-go/deepseek-v4-flash`. Override it only with an explicit task-local `OPENCODE_WORKER_MODEL` value.

## Integrate Results

1. Inspect each worker's commands, findings, risks, and diff.
2. Reject unrelated files and overlapping ownership.
3. Require each implementer to run the task's relevant formatter, lint, tests, or build in its isolated worktree before handoff. Treat missing required validation or an unexplained failure as a failed handoff.
4. Apply accepted changes from the orchestrator; do not ask a worker to integrate its own result.
5. Resolve cross-worker assumptions in the main worktree.
6. Rerun builds, formatters, tests, and final validation from the integrated worktree. Worker validation does not replace integrated validation.
7. Report which worker results were accepted, revised, rejected, or blocked.

Treat a worker's successful exit as evidence, not proof. The orchestrating model owns the final correctness decision.
