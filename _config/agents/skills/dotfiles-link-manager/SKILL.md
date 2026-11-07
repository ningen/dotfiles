---
name: dotfiles-link-manager
description: Maintain dotfiles symlink delivery in the ningen/dotfiles repository. Use when editing dotfiles-links.yaml, setup-dotfiles.sh, adding .config-managed files or directories, distributing Codex user-level skills to ~/.agents/skills, or diagnosing skipped or broken symlinks across macOS, Linux, and WSL.
---

# Dotfiles Link Manager

Use this workflow when changing the symlink delivery layer in `~/ghq/github.com/ningen/dotfiles`.

## Link Model

- `dotfiles-links.yaml` is the source of truth.
- `dotfiles-links.local.yaml`, when present, is gitignored and read after `dotfiles-links.yaml`; use it for private local links such as private Codex skills.
- `setup-dotfiles.sh` applies `unix_only` plus the platform-specific `macos_only` or `wsl_only` sections, and `vscode` on macOS.
- Existing non-symlink targets are intentionally skipped by the setup script.

## Adding Links

1. Add the source file or directory inside the repository first.
2. Choose the narrowest YAML section:
   - `unix_only` for macOS/Linux/WSL XDG artifacts.
   - `macos_only` or `wsl_only` for platform-specific artifacts.
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

- Inspect YAML indentation manually; the setup script uses a simple parser.
- Run `bash -n setup-dotfiles.sh` after shell script edits.
- On macOS/Linux, run `./setup-dotfiles.sh` only when the user wants to apply links.
