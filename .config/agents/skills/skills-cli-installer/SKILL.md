---
name: skills-cli-installer
description: Install, list, verify, and update Codex agent skills from official or community GitHub repositories with `npx skills add`. Use when a user asks to install a skill via the Skills CLI, asks for official Hunk or Herdr skills, or wants to confirm a skill is placed under `~/.agents/skills`.
---

# Skills CLI Installer

## Overview

Use the Skills CLI through `npx skills` when installing upstream agent skills from GitHub repositories into the user's Codex skills directory. Always verify the filesystem placement and the Skills CLI registry output before claiming the skill is installed.

## Standard Workflow

1. List the skills exposed by the repository:

   ```bash
   npx -y skills add <owner>/<repo> -l --full-depth
   ```

2. Install only the requested skill unless the user explicitly asks for every skill:

   ```bash
   npx -y skills add <owner>/<repo> -g --agent codex --skill <skill-name> -y --copy --full-depth
   ```

3. Verify placement on disk:

   ```bash
   test -f ~/.agents/skills/<skill-name>/SKILL.md
   sed -n '1,24p' ~/.agents/skills/<skill-name>/SKILL.md
   ```

4. Verify the Skills CLI sees the installed Codex skill:

   ```bash
   npx -y skills ls -g -a codex --json
   ```

Check that the expected `name`, `path`, `source`, and `sourceUrl` are present. Do not report success until both filesystem and CLI checks pass.

## Known Official Skills

### Hunk

Hunk's official Codex review skill is `hunk-review` from `modem-dev/hunk`.

```bash
npx -y skills add modem-dev/hunk -l --full-depth
npx -y skills add modem-dev/hunk -g --agent codex --skill hunk-review -y --copy --full-depth
test -f ~/.agents/skills/hunk-review/SKILL.md
```

### Herdr

Herdr's official Codex skill is `herdr` from `herdrdev/herdr`.

```bash
npx -y skills add herdrdev/herdr -l --full-depth
npx -y skills add herdrdev/herdr -g --agent codex --skill herdr -y --copy --full-depth
test -f ~/.agents/skills/herdr/SKILL.md
```

## Operational Notes

- Use `-g --agent codex` for user-level Codex skills.
- Use `--copy` so the installed skill is copied into `~/.agents/skills` rather than depending on a temporary repository path.
- Use `--full-depth` when a repository may keep skills below a top-level `skills/` directory.
- Review any Skills CLI security or risk assessment output and mention material warnings in the final result.
- Do not edit copied upstream official skills directly. Reinstall or update them with the Skills CLI when the upstream source changes.
- Installing all skills from a repository can add broad behavior; do that only when the user asks for all of them.

## Update And Removal

List current global Codex skills:

```bash
npx -y skills ls -g -a codex --json
```

Update an installed skill when the upstream source should be refreshed:

```bash
npx -y skills update -g <skill-name>
```

Remove a skill only when the user explicitly asks:

```bash
npx -y skills rm -g <skill-name>
```
