---
name: agent-browser
description: Browser automation via the agent-browser CLI. Use whenever a task needs a real web browser — open a website, navigate, click, fill forms, select options, upload files, scroll, take screenshots, extract data from rendered pages, test a web app, or automate a logged-in flow. Drives the local Chromium via CDP through the `agent-browser` command in bash. Load this skill before running the first browser command.
---

# agent-browser — browser automation CLI

`agent-browser` (installed at `/usr/bin/agent-browser`) is a fast browser
automation CLI for AI agents: Chrome/Chromium over CDP, no Playwright or
Puppeteer. Accessibility-tree snapshots with compact `@eN` refs let you
interact with pages in a few hundred tokens instead of parsing raw HTML.

## DSH-specific rules

- Every `bash` tool call runs in a **fresh shell**. Environment does not
  persist, so prepend the session export to every browser command (or chain
  the whole sequence into one bash call):
  `export AGENT_BROWSER_SESSION="<task-name>" && agent-browser ...`
- Use one **named session per task** (e.g. `dsh-<short-task>`). Never use the
  default unnamed session — it is shared machine-wide with other agents.
- Save screenshots into the session workspace, then view them with the
  `read_image` tool.
- Run `agent-browser close` (or `close --all`) when the task is done.

## The core loop

```bash
export AGENT_BROWSER_SESSION="dsh-mytask" && agent-browser open <url>
agent-browser snapshot -i       # interactive elements only, with @eN refs
agent-browser click @e3         # act on refs from the latest snapshot
agent-browser snapshot -i       # re-snapshot after ANY page change
```

Refs are reassigned on every snapshot and become **stale the moment the page
changes** (navigation, submit, dynamic re-render, dialog). Always re-snapshot
before the next ref interaction.

## Interacting

```bash
agent-browser click @e1            # also: dblclick, hover, focus
agent-browser fill @e2 "text"      # clear then type (type = without clearing)
agent-browser press Enter          # key or combo, e.g. Control+a
agent-browser check @e3            # uncheck, select @e4 "value"
agent-browser upload @e5 file.pdf
agent-browser scroll down 500      # up/down/left/right
```

Without a snapshot, use semantic locators: `agent-browser find role button
click --name "Submit"`, `find text "Sign In" click`, `find label "Email" fill
"a@b.c"`. Raw CSS selectors are the fallback: `agent-browser click "#submit"`.

## Waiting (pick the right one)

```bash
agent-browser wait @e1                    # element appears
agent-browser wait --text "Success"       # text appears
agent-browser wait --url "**/dashboard"   # URL matches glob
agent-browser wait --load networkidle     # SPA catch-all after navigation
```

Avoid bare `agent-browser wait 2000` except when debugging.

## Reading pages

```bash
agent-browser read <url>            # docs-friendly fetch, prefers markdown
agent-browser read                  # rendered DOM of the active tab
agent-browser get text @e1          # also: html, value, attr <n>, title, url, count
```

## Full version-matched reference

The CLI ships its own always-version-matched skills. For anything beyond the
basics — tabs, auth/cookies, downloads, iframes, network capture, multiple
parallel sessions, troubleshooting — run:

```bash
agent-browser skills get core --full   # complete command reference
agent-browser skills list              # specialized skills: electron, slack, dogfood, derive-client, ...
agent-browser skills get <name>        # load one specialized skill
```

Prefer these over guessing flags.
