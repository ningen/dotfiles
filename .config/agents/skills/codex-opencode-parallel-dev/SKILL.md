---
name: codex-opencode-parallel-dev
description: Orchestrate parallel software development from Codex through Herdr panes and bounded OpenCode workers using DeepSeek V4 Flash. Use for OpenCode worker delegation, Herdr-based parallel investigation or implementation, isolated Git worktree development, DeepSeek V4 Flash coding workers, parallel development, 並列開発, and Codex orchestration with external agents.
---

# Codex OpenCode Parallel Development

Keep Codex responsible for decomposition, ownership, integration, review judgment, and final communication. Use OpenCode workers only for bounded execution.

Load and follow `$herdr-interactive-runner` before controlling Herdr. Do not duplicate its pane lifecycle or secret-handling logic.

Read [references/worker-contract.md](references/worker-contract.md) before preparing worker tasks.

## Preflight

1. Verify `HERDR_ENV=1`, `herdr`, `jq`, and `opencode`.
2. Inspect `git status --short` without changing the worktree.
3. Split the request into independently verifiable tasks.
4. Record dependencies and assign explicit file or module ownership.
5. Keep dependent tasks sequential even when other tasks run in parallel.
6. Never stash, commit, discard, or overwrite user changes to prepare workers.

If Herdr is unavailable, do not control an external Herdr session. Explain the constraint and continue only with safe non-interactive checks.

## Select Workers

- Use `codex-scout` for repository searches, diagnosis, and evidence collection.
- Use `codex-implementer` for one bounded implementation in an isolated Git worktree.
- Use `codex-reviewer` for read-only review of a completed diff.
- Prefer existing Codex subagents for cheap mechanical reads when they are sufficient; use OpenCode when external visible execution or DeepSeek capacity is useful.

Do not allow OpenCode workers to spawn subagents, commit, push, merge, rebase, reset, switch branches, or control Git worktrees.

## Isolate Editing Workers

Allow read-only workers to share the current directory. Give every editing worker a separate detached Git worktree based on a clean committed revision.

If workers must see uncommitted changes from the main worktree, keep them read-only unless the user explicitly chooses how to establish a reproducible base. Do not silently copy, stash, or commit those changes.

Keep each worker worktree until Codex has reviewed and integrated or rejected its diff. Remove it only after it is clearly disposable.

## Launch Workers

1. Write one task contract per worker to a non-secret temporary file.
2. Keep the original tab dedicated to the orchestrating Codex pane.
3. Before launching two or more workers, create one unfocused Herdr tab named `workers:<short-task>` with `scripts/create-worker-tab.sh`. Record the returned `tab_id` and `root_pane_id`.
4. Use the new tab's initial pane as the run control pane or first worker, then split panes inside that tab by explicit pane ID.
5. Build a 2x2 layout deterministically: split the root pane right, split the root pane down, then split the right pane down. Keep at most four total panes per worker tab. Create another tab by phase or subsystem instead of shrinking the Codex tab or overloading one worker tab.
6. Use a single sibling pane only for one standalone interactive command; do not repeatedly split the Codex tab for orchestration.
7. For review tasks, prepare the diff or other raw evidence as an attachment instead of granting shell access.
8. Run the bundled launcher from each worker pane:

```bash
<skill-dir>/scripts/create-worker-tab.sh workers:<short-task> <working-directory>
<skill-dir>/scripts/run-worker.sh <agent> <working-directory> <task-file> [artifact-file ...]
```

9. Monitor panes independently with bounded reads and waits.
10. Stop or revise dependent tasks when an upstream worker changes an interface or reports a blocker.
11. Keep the worker tab until its outputs and diffs are integrated. Close or reuse it only when its state is clearly disposable.

The launcher defaults to `opencode-go/deepseek-v4-flash`. Override it only with an explicit task-local `OPENCODE_WORKER_MODEL` value.

## Integrate Results

1. Inspect each worker's commands, findings, risks, and diff.
2. Reject unrelated files and overlapping ownership.
3. Apply accepted changes from Codex; do not ask a worker to integrate its own result.
4. Resolve cross-worker assumptions in the main worktree.
5. Run builds, formatters, tests, and final validation from the integrated worktree. Do not grant implementers broad shell access for validation.
6. Report which worker results were accepted, revised, rejected, or blocked.

Treat a worker's successful exit as evidence, not proof. Codex owns the final correctness decision.
