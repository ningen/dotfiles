---
name: codex-user-skill-author
description: Create, update, validate, and symlink-deliver personal Codex user-level skills from the ningen/dotfiles repository. Use when adding or revising skills under .config/agents/skills, editing SKILL.md or agents/openai.yaml, deciding whether a workflow belongs in AGENTS.md vs a skill, or wiring user-level skills into ~/.agents/skills through dotfiles-links.yaml.
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

When the symlink delivery changes, also inspect `dotfiles-links.yaml` and run `./setup-dotfiles.sh` only when the user wants to apply links on this machine.
