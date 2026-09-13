# learnings-autoinject

A local OpenCode plugin that auto-injects a compact **manifest** of a project's
`LEARNINGS/*.md` files into the system prompt at session start, so the model
knows what learned knowledge exists without spending a tool call on `glob`.

It does **not** inject full file bodies — only titles + paths + a one-line
summary. The model `read()`s specific files on demand.

## Why

`opencode-superlocalmemory` already auto-injects its **vector store** on the
first message, but the git-committed `LEARNINGS/*.md` markdown files are never
surfaced automatically. `continuous-learning-skill` documents the gap:
*"OpenCode does NOT auto-scan LEARNINGS/ directories."* This plugin automates
the discovery step.

## Toggle (enabled by default)

| Control | Effect |
|---------|--------|
| `LEARNINGS_AUTOINJECT_DEFAULT=off` | Disable globally (default `on`) |
| `/learnings-off` | Disable for the current session |
| `/learnings-on` | Re-enable for the current session |
| `/learnings` | Report current state + file count |
| `/learnings-refresh` | Re-scan `LEARNINGS/` and rebuild the manifest on the next turn |

Per-session overrides take precedence over the env-var default.

## Env vars

| Var | Default | Purpose |
|-----|---------|---------|
| `LEARNINGS_AUTOINJECT_DEFAULT` | `on` | Global on/off |
| `LEARNINGS_AUTOINJECT_USER` | `off` | Also scan `~/.config/opencode/learnings/` (user-level) |
| `LEARNINGS_AUTOINJECT_OFF` | *(built-in regex)* | Agent names to exclude (read-only/research agents) |
| `LEARNINGS_AUTOINJECT_MAX` | `30` | Cap on files included in the manifest |

## Agent scoping

Read-only/research agents (`explore`, `general`, `explorer-subagent`,
requirements/discovery specialists, etc.) skip injection — they don't act on
LEARNINGS. The off-set regex mirrors `ponytail-scoped.ts` and can be overridden
via `LEARNINGS_AUTOINJECT_OFF`.

## What gets injected

```
<LEARNINGS AUTOINJECT — project: my-app>
Available learnings (use `read()` on a path for full detail):
- decisions/sqlite-over-postgres.md — Chose SQLite for local-first
- anti-patterns/mutable-default-args.md — Avoid mutable default args in Python
Source: LEARNINGS/ (2 project). Refresh: /learnings-refresh
</LEARNINGS AUTOINJECT>
```

~200-400 tokens for a typical 5-file repo.

## Hooks

Dual entrypoint (V2 `setup()` + V1 `server()` in one default export), per the
[V2 plugin dual-support pattern](https://opencode.ai/v2/docs/build/plugins/):
V2 loads `setup(ctx)`; V1 ≥ 1.18.29 calls `server()` and receives the legacy
hook map. V1 < 1.18.29 expects function exports and will not load the object
form.

| V2 registration (in `setup`) | Replaces V1 hook | Role |
|------|------|------|
| `ctx.command.transform` | `config` + `command.execute.before` | Register the 4 `/learnings-*` commands; the toggle/refresh side effects now run inside each command's `execute()` |
| `ctx.session.hook("context")` | `experimental.chat.system.transform` (+ `chat.message` cache) | Core: append manifest (idempotent, off-set-gated). `event.agent` is native on the context hook, so the sessionID→agent cache is V1-only |

## Compatibility

- No `opencode.json` change — local plugins are glob-discovered (V2 keeps auto-discovery of `.opencode/plugins/`).
- No conflict with `opencode-superlocalmemory` (different store: markdown vs vectors; different hook: `ctx.session.hook("context")` here vs `tui.prompt.append` in that V1-era npm plugin — its V2 port is tracked separately).
- Requires `LEARNINGS/` to exist in the project root; absent → skips silently.

See `research/ponytail-load-fix.md` for why this file is `.ts` (not `.mjs`).
