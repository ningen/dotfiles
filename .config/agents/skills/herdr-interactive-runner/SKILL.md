---
name: herdr-interactive-runner
description: Run interactive, password-gated, approval-gated, TUI, or long-running shell commands in a sibling Herdr pane so the user can provide input and Codex can monitor output. Use for sudo, ssh, gpg, pass, op, login prompts, OTP prompts, nix build/check/update, dev servers, broad test suites, CI reproduction, commands expected to run for a long time, Herdr-managed execution, パスワード入力, 対話的コマンド, 長時間実行, and herdr経由. Requires HERDR_ENV=1; do not control a Herdr session from outside Herdr.
---

# Herdr Interactive Runner

Run interactive or long-lived commands in a sibling Herdr pane while keeping the current agent pane available for orchestration.

## Guardrail

Before any Herdr control command, verify the current agent is already running in a Herdr-managed pane:

```bash
test "${HERDR_ENV:-}" = 1
```

If this fails, do not run bare `herdr`, attach to a session, or control a focused pane from outside Herdr. Tell the user to start or resume Codex inside Herdr, then use normal command execution only when it is safe and non-interactive.

Do not create a nested Herdr session when the check passes. Control the current session with `--current` and the pane ID returned by each creation command.

## Workflow

1. Use normal command execution for quick, non-interactive read-only checks.
2. For interactive or long-running work, create a sibling pane without stealing focus:

```bash
created=$(herdr pane split --current --direction right --cwd "$PWD" --no-focus)
pane_id=$(printf '%s\n' "$created" | jq -r '.result.pane.pane_id')
test -n "$pane_id" && test "$pane_id" != null
```

3. Give the pane a short task-specific label:

```bash
herdr pane rename "$pane_id" <label>
```

4. Tell the user which command will run and that input belongs in pane `<pane_id>`. Never ask them to paste secrets into chat.
5. Submit the command atomically:

```bash
herdr pane run "$pane_id" '<command>'
```

Prefer `pane run` over separate `send-text` and `send-keys` calls.

6. Monitor recent unwrapped output:

```bash
herdr pane read "$pane_id" --source recent-unwrapped --lines 120
```

Use bounded waits when a stable output marker is known:

```bash
herdr pane wait-output "$pane_id" --match '<text>' --timeout 30000
```

Otherwise poll with bounded intervals and keep the user updated. Inspect process state when completion is unclear:

```bash
herdr pane process-info --pane "$pane_id"
```

7. After completion, summarize the result and retain the pane when its output or shell remains useful. Close it only when the user asked or it is clearly disposable and no privileged/authenticated shell remains.

## Input And Safety

- Let the user type passwords, OTPs, passphrases, approvals, and other sensitive input directly into the Herdr pane.
- Treat pane output as potentially sensitive. Do not quote credential-like values.
- Do not send input to a password, approval, root, or authenticated prompt on the user's behalf unless the user explicitly authorized that exact action and no secret is involved.
- Do not reuse another pane merely because it appears idle. Create a dedicated sibling pane unless the user identifies an existing pane.
- Use the pane ID returned by Herdr JSON; never predict IDs or rely on the currently focused UI pane.
- For dev servers, report the URL or port when known. For unfinished work, report the pane ID and current state.
