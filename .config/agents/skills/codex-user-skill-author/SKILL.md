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

- Public third-party skills are installed with the Skills CLI, not vendored into this repository.
- Track public install intent in `/Users/ningen/ghq/github.com/ningen/dotfiles/.config/agents/public-skills.tsv`.
- Apply public installs with:

```bash
.config/agents/install-public-skills.sh
```

- Use `*` in the manifest only when the whole public skill collection should be installed:

```text
cloudflare/skills	*
mattpocock/skills	grill-me
```

- Do not add public third-party skill collections as Git submodules under `.config/agents/vendor`.
- If local behavior needs to differ from a public skill, create a wrapper skill in `.config/agents/skills/<skill-name>` instead of editing copied upstream files.
- Private skills may live under `.config/agents/private-skills/<skill-name>`, which is gitignored. Link them from `dotfiles-links.local.yaml` so private names and contents do not need to appear in Git.
- The `quick_validate.py` check is required for authored or wrapper skills. Public third-party skills are validated by `npx skills ls -g -a codex --json` after install.

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

When the symlink delivery changes, also inspect `dotfiles-links.yaml` and any local `dotfiles-links.local.yaml`. Run `./setup-dotfiles.sh` only when the user wants to apply links on this machine.
