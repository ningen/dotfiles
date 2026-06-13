---
name: codex-user-skill-author
description: Create, update, validate, and symlink-deliver personal Codex user-level skills from the ningen/dotfiles repository. Use when adding or revising skills under .config/agents/skills, importing third-party skills under .config/agents/vendor as Git submodules, editing SKILL.md or agents/openai.yaml, deciding whether a workflow belongs in AGENTS.md vs a skill, or wiring user-level skills into ~/.agents/skills through dotfiles-links.yaml.
---

# Codex User Skill Author

Use this workflow to maintain user-level Codex skills as dotfiles-managed artifacts.

## Placement

- Store skill sources in `/Users/ningen/ghq/github.com/ningen/dotfiles/.config/agents/skills/<skill-name>`.
- Deliver each skill with an individual symlink from `dotfiles-links.yaml`:

```yaml
  - source: .config/agents/skills/<skill-name>
    target: ~/.agents/skills/<skill-name>
    type: directory
```

- Do not symlink the entire `~/.agents/skills` directory; leave room for unmanaged local experiments.
- Use `.agents/skills` only for repo-scoped workflows. Use this `.config/agents/skills` layout for user-level workflows that should follow the person across repositories.

## External Skills

- Store third-party skill collections as Git submodules under `/Users/ningen/ghq/github.com/ningen/dotfiles/.config/agents/vendor/<owner-or-project>-<repo>`, preserving the upstream layout, license, and metadata.
- Add submodules with a stable path, for example:

```bash
git submodule add https://github.com/cloudflare/skills.git .config/agents/vendor/cloudflare-skills
```

- Deliver submodule-backed skills with individual `dotfiles-links.yaml` entries that point at the upstream skill directory, for example:

```yaml
  - source: .config/agents/vendor/cloudflare-skills/skills/<skill-name>
    target: ~/.agents/skills/<skill-name>
    type: directory
```

- Do not link the whole vendor collection or the whole `~/.agents/skills` directory.
- Keep upstream files unmodified. If local behavior needs to differ, prefer a wrapper skill in `.config/agents/skills/<skill-name>` instead of committing edits inside the submodule.
- Use `.gitmodules` and the submodule gitlink as the source of truth for upstream URL and pinned commit. Update with `git submodule update --remote .config/agents/vendor/<owner-or-project>-<repo>`, then inspect and commit the changed gitlink.
- The `quick_validate.py` check is required for authored or wrapper skills. Submodule-backed third-party skills may use upstream frontmatter that the local validator does not recognize, so validate their delivery by checking that each linked directory contains `SKILL.md` and that `dotfiles-links.yaml` points to the intended skill directory.

## Authoring

1. Prefer one focused skill per repeatable workflow.
2. Name folders with lowercase letters, digits, and hyphens only.
3. Keep `SKILL.md` concise. Put only non-obvious procedure, routing, and validation rules in the body.
4. Put all triggering language in the frontmatter `description`, especially file names, commands, and task phrases the user is likely to say.
5. Include only `name` and `description` in `SKILL.md` frontmatter.
6. Add `agents/openai.yaml` with `interface.display_name`, `interface.short_description`, and `interface.default_prompt`; make `default_prompt` explicitly mention `$<skill-name>`.
7. Add scripts or references only when they avoid repeated fragile work. Do not create README, quick reference, changelog, or process notes inside a skill.

## Validation

After editing a skill, run:

```bash
python3 /Users/ningen/.codex/skills/.system/skill-creator/scripts/quick_validate.py .config/agents/skills/<skill-name>
```

If validation fails with `ModuleNotFoundError: No module named 'yaml'`, rerun it with a Python interpreter that includes PyYAML:

```bash
nix shell --impure --expr 'let pkgs = import <nixpkgs> {}; in pkgs.python3.withPackages (ps: [ ps.pyyaml ])' -c python /Users/ningen/.codex/skills/.system/skill-creator/scripts/quick_validate.py .config/agents/skills/<skill-name>
```

Do not rely on `nix shell nixpkgs#python3Packages.pyyaml -c python3 ...` for this check; it can still pick up the system Python instead of a Python environment with PyYAML installed.

When the symlink delivery changes, also inspect `dotfiles-links.yaml` and run `./setup-dotfiles.sh` only when the user wants to apply links on this machine.
