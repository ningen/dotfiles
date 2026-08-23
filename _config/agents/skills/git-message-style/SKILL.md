---
name: git-message-style
description: Standardize Git commit messages, pull request titles, PR bodies, merge messages, changelog entries, and release notes. Use when Codex is asked to commit changes, suggest a commit message, rewrite a commit history summary, open or draft a pull request, write a PR description, prepare release notes, or review whether Git/PR wording follows a consistent style.
---

# Git Message Style

Use this workflow to write clear Git and PR messages that explain the change without sounding inflated or vague.

## Rule Selection

1. Prefer repository rules from `CONTRIBUTING.md`, commitlint config, release tooling, prior PR templates, or project-specific documentation.
2. If no rule exists, use Conventional Commits light:

```text
type(scope): imperative summary
```

3. Omit `scope` when it would be noisy.
4. Use body text only when the subject cannot explain the risk, reason, migration, or validation.

## Commit Subject

- Use one of `feat`, `fix`, `docs`, `refactor`, `test`, `ci`, `build`, `perf`, `style`, `chore`, or `revert`.
- Prefer `feat`, `fix`, `docs`, `refactor`, `test`, `ci`, or `build`; use `chore` only when the change has no clearer type.
- Write the summary in imperative mood: `add`, `fix`, `remove`, `rename`, `update`.
- Keep it specific, lowercase after the type, and without a trailing period.
- Aim for 50 characters; stay under 72 unless the repository history clearly accepts longer subjects.
- Mention the user-visible or maintainer-visible unit of change, not the files touched.

Good:

```text
feat(skills): add natural writing editor
fix(nix): pin missing language server package
docs: remove gemini web search guidance
```

Avoid:

```text
update files
fixed
chore: various improvements
```

## Commit Body

Include a body when context matters. Keep paragraphs wrapped around 72 columns.

Use this order when relevant:

1. What changed.
2. Why it changed.
3. Risk, compatibility, or migration notes.
4. Validation performed.

Do not restate the subject in prose. Do not add a body just to fill space.

## Pull Requests

- PR title: follow the commit subject style, or summarize multiple commits with the same grammar.
- PR body: write short sections for what changed, why, validation, and follow-up only when each section has substance.
- Keep generated PR prose concrete: mention files, commands, user impact, and remaining risk.
- Avoid vague filler such as "This PR improves the overall experience" unless the improvement is named.

## Before Committing

1. Inspect `git status -sb` and the staged diff.
2. Confirm the staged scope matches the message.
3. Choose the smallest honest type and scope.
4. Write the message after validation is known when the validation result belongs in the body.
