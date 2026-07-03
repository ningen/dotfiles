---
name: tmux-interactive-runner
description: Run interactive, password-gated, approval-gated, TUI, or long-running shell commands through tmux so the user can attach for input and Codex can monitor progress with capture-pane. Use for sudo, ssh, gpg, pass, op, login prompts, OTP prompts, nix build/check/update, dev servers, test suites, CI reproduction, commands expected to run for a long time, パスワード入力, 対話的コマンド, 長時間実行, and tmux経由.
---

# Tmux Interactive Runner

Use this workflow when a shell command may require human input or should keep running while Codex continues other work.

## When To Use

Run the command through `tmux` when it is likely to involve:

- Passwords, OTPs, hardware keys, browser/device login, `sudo`, `ssh`, `gpg`, `pass`, or `op`.
- Interactive prompts, approval gates, curses/TUI programs, or commands that do not behave well in plain captured output.
- Long-running work such as `nix build`, `nix flake check`, `nix run .#update`, broad test suites, CI reproduction, dependency builds, and dev servers.

Use normal command execution for quick, non-interactive read-only checks.

## Workflow

1. Choose a short task-specific session name, for example `codex-nix-check` or `codex-dev-server`.
2. Create the session:

```bash
tmux new-session -d -s <session-name>
```

3. Tell the user what will run and how to attach:

```bash
tmux attach -t <session-name>
```

4. Start the command inside the session:

```bash
tmux send-keys -t <session-name> '<command>' C-m
```

5. Monitor progress with:

```bash
tmux capture-pane -p -t <session-name>
```

6. If input is needed, ask the user to attach and type it directly in the tmux session. Do not ask the user to paste secrets into chat.
7. After completion, summarize the result and include the session name if the session remains useful. For dev servers, include the URL or port when known.

## Safety Rules

- Never request passwords, OTPs, tokens, recovery codes, private keys, or passphrases in chat.
- Treat `capture-pane` output as potentially sensitive; do not quote secrets or credential-like strings.
- If the user leaves a root shell, authenticated shell, or privileged prompt open, do not continue privileged work unless the user explicitly asked for the exact next action.
- Do not kill a tmux session that contains a still-useful long-running process unless the user asked you to stop it.
- For long-running jobs, keep the user informed with the session name, attach command, and current status.
