---
name: verify-ui-with-screenshots
description: Capture and return UI screenshots for visual verification, logged-in Chrome or Computer Use checks, desktop/app state inspection, before/after UI review, and turning observed UI flows into E2E test cases. Use when the user asks Codex to take a screenshot, include a screenshot image in the response, verify a rendered UI, inspect current Chrome or desktop app state, reproduce visual issues, or create Playwright/Cypress-style E2E tests from an observed UI flow.
---

# Verify UI With Screenshots

## Overview

Capture the target UI, return the image in the chat with a Markdown image tag, and use the visible state to verify behavior or design. For E2E work, treat screenshots as evidence of the flow, then inspect the app structure and write stable tests using the repo's existing framework.

## Workflow

1. Pick the narrowest surface:
   - Use Browser for local dev servers, file-backed previews, and public pages without sign-in.
   - Use Chrome when the flow needs the user's logged-in Chrome state.
   - Use Computer Use for desktop apps, OS UI, or the current graphical app state.
   - Use shell screenshot capture only when an actual image file must be returned in the response.
2. Capture the current state once before acting. For Computer Use, call `get_app_state` first so Codex can see the UI and accessibility tree.
3. Save a PNG outside the repo, preferably under `${TMPDIR:-/tmp}` or `/private/tmp`, unless the user explicitly asks to keep an artifact in the project.
4. Return the screenshot with an absolute-path Markdown image tag:

```md
![UI screenshot](/absolute/path/to/screenshot.png)
```

5. Summarize only the relevant visible observations. Do not describe unrelated private content in the screenshot.
6. If changing code, rerun the same UI flow and attach an after screenshot when it helps review the fix.

## macOS Screenshot Script

Use `scripts/capture-macos-screenshot.sh` when a PNG file is needed for the final response.

Full display:

```bash
.config/agents/skills/verify-ui-with-screenshots/scripts/capture-macos-screenshot.sh --mode screen
```

Front window or named app region:

```bash
.config/agents/skills/verify-ui-with-screenshots/scripts/capture-macos-screenshot.sh --mode front-window --app "Google Chrome"
```

The script prints the absolute PNG path. If the shell or OS blocks screen capture, rerun with a scoped approval request. If macOS reports it cannot create the image, ask the user to grant Screen Recording permission to Codex, then retry. `--mode front-window` also needs Accessibility permission because it reads the front window bounds through System Events; fall back to `--mode screen` when that permission is unavailable.

## UI Verification

- Prefer a screenshot plus concrete observations over a generic "looks good".
- Mention visible regressions by element label, approximate location, and state.
- For local web apps, use Browser/Chrome inspection for console, network, DOM, roles, and computed styles when needed.
- Do not rely on screenshots alone for functional correctness; run the app's tests or create targeted checks when the workflow matters.

## E2E Test Creation

When the user wants E2E tests from an observed UI flow:

- First observe the flow visually and note the user-visible states.
- Inspect the repository for the existing E2E framework before adding anything.
- Prefer stable locators such as role, label, visible text, and existing `data-testid` attributes.
- Use screenshots to document states and debug failures, not as the only assertion, unless the user explicitly wants visual regression snapshots.
- Keep generated tests narrow: one flow, one expected outcome, and setup/teardown consistent with the repo.

## Safety

- Screenshots can include account names, tokens, URLs, browser tabs, notifications, and private app content.
- Keep captures scoped and use the minimum necessary surface.
- Do not commit screenshots unless the user asks.
- Stay present for account, payment, security, credential, or admin flows.
