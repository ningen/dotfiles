---
name: html-report-builder
description: Build a clean single-file HTML report styled with the Tailwind CSS CDN and open it in the OS default browser. Use when asked to summarize research or findings as a nice-looking web page, 調査結果やリサーチ結果を綺麗な HTML にまとめる, make an HTML report, create a レポートページ, turn research into a browsable document, or open the result in the default browser (including from WSL via explorer.exe).
---

# HTML Report Builder

Build one self-contained HTML report with Tailwind CSS via CDN and open it in the OS default browser.

## Workflow

1. **Research first.** Gather findings before writing HTML. Decide the report structure (overview, tool/topic sections, workflow steps, reference tables, pitfalls, sources).
2. **Write the HTML** as a single self-contained file in `/tmp/opencode/` (not in the repo) unless the user asks for a permanent location.
3. **Open it** with the platform's browser opener (see below).

## HTML Conventions

- Use Tailwind CDN: `<script src="https://cdn.tailwindcss.com"></script>`.
- Customize defaults via a `tailwind.config` script block: fonts (Inter / JetBrains Mono via Google Fonts), `fontFamily` extensions.
- Dark-first design: `bg-slate-950` body, `text-slate-200`, cards with `rounded-2xl border border-slate-800 bg-slate-900/50`.
- Write the page language to match the user (`lang="ja"` + Japanese copy when asked in Japanese).
- Accent colors per topic section (e.g. indigo for tool A, fuchsia for tool B) via small colored badges and section headers.
- Include a sticky top nav with anchor links when the report has 4+ sections.
- Code blocks: `bg-slate-950 border border-slate-800` with `font-mono text-xs`, comments in `text-slate-500`.
- Wrap long code lines with `overflow-x-auto`.
- Add a footer with research date, versions checked, and environment.

## Opening in a Browser

- **WSL / Ubuntu**: convert the path and open with the Windows default browser via explorer.exe. `cmd.exe` cannot use UNC paths as the working directory, so run from a Windows directory (e.g. `workdir=/mnt/c`) or just call explorer.exe with the UNC path:
  ```bash
  explorer.exe "$(wslpath -w /tmp/opencode/report.html)"
  ```
  If explorer.exe returns without error, confirm with the user that it opened (exit code is not reliable).
- **macOS**: `open /tmp/opencode/report.html`.
- **Linux desktop**: `xdg-open /tmp/opencode/report.html`.

## Validation

- Check the file exists and is non-trivial size before opening.
- Confirm with the user that the page rendered; note that Tailwind CDN needs network access.
