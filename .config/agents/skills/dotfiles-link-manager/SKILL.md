---
name: dotfiles-link-manager
description: Maintain dotfiles symlink delivery in the ningen/dotfiles repository. Use when editing dotfiles-links.yaml, setup-dotfiles.sh, setup-dotfiles.ps1, adding .config-managed files or directories, distributing Codex user-level skills to ~/.agents/skills, or diagnosing skipped or broken symlinks across macOS, Linux, and Windows.
---

# Dotfiles Link Manager

Use this workflow when changing the symlink delivery layer in `/Users/ningen/ghq/github.com/ningen/dotfiles`.

## Link Model

- `dotfiles-links.yaml` is the source of truth.
- `dotfiles-links.local.yaml`, when present, is gitignored and read after `dotfiles-links.yaml`; use it for private local links such as private Codex skills.
- `setup-dotfiles.sh` applies `common`, `unix_only`, `macos_only`, and `vscode` sections on macOS/Linux.
- `setup-dotfiles.ps1` applies `common`, `windows_only`, and `vscode` sections on Windows.
- Existing non-symlink targets are intentionally skipped by the setup scripts.

## Adding Links

1. Add the source file or directory inside the repository first.
2. Choose the narrowest YAML section:
   - `common` for cross-platform home/config artifacts.
   - `unix_only` for macOS/Linux-only XDG artifacts.
   - `macos_only` or `windows_only` for platform-specific artifacts.
   - `vscode` for VS Code user settings.
3. Use `$CONFIG_DIR`, `$VSCODE_CONFIG_DIR`, `$HOME`, or `~` only in `target`; keep `source` repo-relative.
4. Use `type: directory` for directories and `type: file` for individual files.
5. For Codex user-level skills, add individual links like:

```yaml
  - source: .config/agents/skills/<skill-name>
    target: ~/.agents/skills/<skill-name>
    type: directory
```

Do not link the whole `~/.agents/skills` directory.
6. Public third-party Codex skills should be installed with `.config/agents/install-public-skills.sh`, not linked from `.config/agents/vendor`.
7. Private Codex skills should be stored under `.config/agents/private-skills/` and linked from `dotfiles-links.local.yaml`.
8. Repository-specific skills should not be linked from `dotfiles-links.yaml` unless they are useful across most repositories.

## Validation

- Inspect YAML indentation manually; the setup scripts use a simple parser.
- Run `bash -n setup-dotfiles.sh` after shell script edits.
- Run `pwsh -NoProfile -Command { $null = [scriptblock]::Create((Get-Content setup-dotfiles.ps1 -Raw)); "ps_ok" }` after PowerShell script edits when `pwsh` is available.
- On macOS/Linux, run `./setup-dotfiles.sh` only when the user wants to apply links.
- On Windows script edits, preserve PowerShell behavior for both Administrator and non-Administrator runs.
