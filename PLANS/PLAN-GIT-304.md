# PLAN-GIT-304: npx-installable skill/agent registry — "opencode-skill add" CLI (GitHub-only distribution)

**Issue**: https://github.com/darellchua2/opencode-config-template/issues/304
**Branch**: `feat/304-npx-skill-installer`
**Created**: 2026-08-04
**Revised**: 2026-08-04 (after opencode-tooling review — see Revision Log)

## Problem

Today this repo distributes via `git clone` only: `./deploy/setup.sh` (full global deploy)
and `opencode-init` (project-scoped curated subset). Neither is a one-command install.
The goal is an `npx github:Simonmensi/opencode-config-template add <skill|subagent>`
experience — the shadcn/ui model (copy source into the user's config) — wired for opencode's
native skill/agent discovery. Individual skills should also be independently installable
now, with a path to per-skill remote publishing later.

## Solution

### Architectural insight (the lazy lever)

`npx github:owner/repo` clones the repo into an npm cache dir and runs the `bin`. The
installer's `__dirname` IS the repo, so it reads `opencode_app/.opencode/{skills,agents}/`
locally — **NO HTTP fetch layer needed**. The existing `deploy/init.mjs` resolver
(transitive closure, presets, manifest, prune, conflict detection, model-tier injection)
is reused almost as-is. This is an EXTENSION of the existing installer, not a
remote-fetch rewrite.

### Framing

This is an **"opencode skill/agent registry + CLI installer"** — explicitly NOT a "plugin."
opencode "plugins" are TypeScript runtime hooks (e.g. this repo's `ponytail-scoped.ts`,
`learnings-autoinject.ts`); a skill is just a file on a discovery path
(`~/.config/opencode/skills/<name>/SKILL.md`, `.opencode/skills/`, plus `.claude/`/`.agents/`
compat). There is no "skill plugin" concept. The repo stays framed as a
"configurator / distribution hub."

### Architecture

```
end user (anywhere)
   │
   ▼
npx github:Simonmensi/opencode-config-template add solid-principles-skill
   │  npm clones repo into cache → runs bin (deploy/init.mjs)
   │  init.mjs reads opencode_app/.opencode/ locally (it IS the repo)
   │  deploy/source.mjs isolates all reads (future-proofing seam for HTTP fetch)
   ▼
~/.config/opencode/skills/solid-principles-skill/  ✓ auto-discovered by opencode
```

### Critical opencode semantics (verified against opencode.ai/docs)

1. **Agents/skills are auto-discovered** from `~/.config/opencode/{agents,skills}/` and
   `<project>/.opencode/{agents,skills}/` — a file drop is sufficient; config.json is
   untouched in the common case.
2. **`permission.skill` can have a strict allowlist** (`{"*":"deny","<name>":"allow"}`) —
   if present, newly installed skills are hidden until added to the allowlist.
3. **Configs MERGE, they do not replace** — modifying a hand-edited config.json is risky;
   user-scope MCP merges are the riskiest and the repo has a LEARNING
   (`LEARNINGS/anti-patterns/jsonc-comments-in-opencode-json.md`) about config corruption.
4. **Project config = full generation** (existing `init.mjs` behavior) — writes
   `.opencode/opencode.json` with permission+MCPs, manifest-owned, clean because project
   overrides global.

### Locked design decisions (from multi-round design session)

1. **Distribution:** GitHub-only (`npx github:Simonmensi/opencode-config-template`), NO npm
   publish. Root `package.json` with `bin` so npx resolves a binary.
2. **Installable units:** Skills AND subagents.
3. **Default install target:** USER config (`~/.config/opencode/{skills,agents}/`).
   `--project [dir]` opts into `./.opencode/`.
4. **Config strategy (HYBRID):** User scope = pure file-drop by default (opencode
   auto-discovers). `--permit` opts into backup+merge of **permission entries only**.
   MCPs are **always warn-and-print** at user scope — never auto-merged even with
   `--permit`. Project scope = full config generation (existing behavior). Rationale:
   scope-appropriate service — file-drop at user scope, full generation at project scope.
   Never maintain a second global config and never clobber a hand-edited one without a
   backup.
5. **Deps:** `add <subagent>` pulls transitive deps (required skills + delegate chain) by
   default; `--no-deps` opts out.
6. **YAGNI cuts (deferred):** no separate `bin/cli.mjs` (point `bin` at `init.mjs` +
   new flags); no per-item `metadata.scope` hints (a `--project` toggle covers it); no
   frontmatter-stripping pipeline (audit shows zero non-standard fields); `--permit` does
   NOT merge MCPs.
7. **Future-proofing:** isolate ALL source reads in a single `deploy/source.mjs` module so
   the eventual flip to per-skill HTTP remote fetch is a one-file change.

---

## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
| ------------------ | ------------------------- | ------------------------------- | ----------- |
| `package.json` (new root) | — | npx resolution, CI lint guards | low (minimal) |
| `deploy/source.mjs` (new) | `opencode_app/.opencode/{skills,agents}/` | `init.mjs` (all read operations) | med (new abstraction) |
| `deploy/init.mjs` (refactor) | `source.mjs`, `registry.json`, presets | npx `add` verb, `opencode-init` preset path | high (core refactor) |
| `~/.config/opencode/.skill-manifest.json` (new) | `init.mjs` writer | `init.mjs` `--remove`/`--prune` | low (data) |
| `.opencode-init.manifest.json` (existing) | `init.mjs` writer | `init.mjs` `--prune` (project scope) | none (unchanged) |
| `deploy/build-site.mjs` (new) | `registry.json` | CI `pages` job | med (new tool) |
| `/docs/` (static site output) | `build-site.mjs` | GitHub Pages | low (generated) |
| `.github/workflows/release.yml` (edit) | all deploy targets | CI | low (additive jobs) |
| `README.md` (edit) | — | users | low |
| `AGENTS.md` (edit) | — | agents, users | low |
| `deploy/setup.sh` / `setup.ps1` (edit) | — | global deploy users | low (one-liner) |
| `.releaserc.json` (edit) | — | semantic-release | low (assets list) |

---

## Implementation Phases

### Phase 1: Root `package.json` + CI lint guards

- [x] **1.1** Create root `package.json` (new, minimal): `{"type":"module","bin":{"opencode-skill":"./deploy/init.mjs"}}`, zero deps, NOT published to npm.
    — **Why:** npx requires a `bin` entry to resolve a binary. Zero deps keeps the clone lean.
    — **Done when:** `node -e "import('./package.json', {with:{type:'json'}}).then(d=>console.log(d.bin))"` prints `{"opencode-skill":"./deploy/init.mjs"}`; `jq .type package.json` prints `"module"`.
    — **Consumers affected:** npx resolution, all downstream phases.
    — **Done:** Created minimal package.json (name/version/private/type/bin); no `files` array — npm packs everything not gitignored, CI guard catches future regressions; files: package.json; fixes: none.

- [x] **1.2** Add CI lint guards to `.github/workflows/release.yml`: `node --check deploy/init.mjs deploy/source.mjs`, `jq . package.json`, and `npm pack --dry-run` asserting `opencode_app/.opencode/` is included in the tarball. These are ADDITIVE — no conflict with existing semantic-release job.
    — **Why:** Prevents syntax errors in .mjs files and catches silent breakage if a `files`/`.npmignore` excludes the source tree.
    — **Done when:** All three checks pass on `main`; a PR with a broken `init.mjs` fails CI.
    — **Consumers affected:** CI, developer confidence.
    — **Done:** Added "Lint .mjs + package.json + npx tarball guard" step to `test` job (after drift guard); currently checks `node --check deploy/init.mjs` only (source.mjs added in Phase 2); also regenerated registry.json to fix pre-existing drift (responsive-audit-subagent description from dab6ab5); files: .github/workflows/release.yml, deploy/registry.json; fixes: none.

### Phase 2: Source isolation module

- [x] **2.1** Create `deploy/source.mjs` (new): exports `readSkill(name)`, `readAgent(stem)`, `listAvailable(type)` — all reading from `opencode_app/.opencode/{skills,agents}/` via a parametrized `sourceRoot` (default `path.resolve(import.meta.dirname, '..')`). Return `{ content, frontmatter, path }`. This is the future-proofing seam — single module the eventual HTTP fetch path swaps in behind.
    — **Why:** When per-skill HTTP fetch is needed later, only this file changes. Everything else calls `source.readSkill("tdd-workflow-skill")` regardless of transport.
    — **Done when:** `source.listAvailable('skills')` returns all skill names; `source.readSkill('tdd-workflow-skill')` returns `{ content, frontmatter, path }`; `sourceRoot` parametrization tested with a custom path.
    — **Consumers affected:** `init.mjs` (all read operations).
    — **Done:** Created deploy/source.mjs with readSkill/readAgent/listAvailable; used `dirname(fileURLToPath(import.meta.url))` instead of `import.meta.dirname` for Node 20 CI compat (matches init.mjs/build-registry.mjs); readSkill returns extra `dir` field for cp; added self-check via `node deploy/source.mjs`; files: deploy/source.mjs, .github/workflows/release.yml (added source.mjs to lint check); fixes: none.

### Phase 3: Refactor `deploy/init.mjs` — add `add` verb + new flags

- [ ] **3.1** Export reusable functions from `init.mjs`: `resolveSelection`, `writeInstall`, `injectModelLine`, `doPrune`. Currently these are internal; exporting enables both the `add` path and the existing `opencode-init` preset path to share logic without duplication.
    — **Why:** The `add` verb needs the resolver and writer; exporting is cheaper than extracting to a separate module (everything stays in one file, just public).
    — **Done when:** `import { resolveSelection } from './deploy/init.mjs'` works from a test script; existing `opencode-init` symlink still works unchanged.
    — **Consumers affected:** future test imports, Phase 3.3.

- [ ] **3.2** Parametrize `sourceRoot` in `init.mjs` (default `path.resolve(import.meta.dirname, '..')` derived from `__dirname`-equivalent). Under npx clone, this points at the repo root (correct). Under dev symlink, this also resolves correctly.
    — **Why:** npx clones into a cache dir; the installer must work from any location without hardcoding paths.
    — **Done when:** `init.mjs` resolves source tree correctly under both `node deploy/init.mjs` (dev) and `npx github:...` (cache clone).
    — **Consumers affected:** all read operations.

- [ ] **3.3** Add new dispatch: `add <name>` as a top-level verb (alongside existing `--preset`/`--agents`/`--skills` flags). Destination = **user scope by default** (`~/.config/opencode/{skills,agents}/`); `--project [dir]` opts into project scope (existing behavior). Wire to `source.mjs` reads + existing resolver + writer.
    — **Why:** The `add` verb is the primary UX surface for `npx` invocation. User-scope default matches the shadcn model (drop into home config).
    — **Done when:** `npx github:... add solid-principles-skill --dry-run` prints the target path; real mode writes the skill directory.
    — **Consumers affected:** end users, UX flows A/B/C/D/E/F.

- [ ] **3.4** Add `--permit` flag (user scope only): timestamped backup of `config.json` (`config.json.bak-<ts>`) → deep-merge `permission.skill` entries only (add the new skill/agent name as `"allow"`). Does NOT merge MCP blocks — ever. Does NOT merge any other config keys. Resulting config must pass JSON parse.
    — **Why:** Users with a strict allowlist need their config updated; but MCP merges are the riskiest operation (repo has a LEARNING on config corruption), so `--permit` is scoped to the safe subset.
    — **Done when:** `--permit` creates backup; merges only `permission.skill`; `python3 -c "import json; json.load(open(...))"` passes on the result; without `--permit`, config.json is untouched.
    — **Consumers affected:** users with strict allowlists (UX flow C/D).

- [ ] **3.5** Add `--remove` flag (alias existing `--prune`, but operates against the correct scope's manifest): user scope reads `~/.config/opencode/.skill-manifest.json`; project scope reads `.opencode-init.manifest.json`. Safe no-op if manifest doesn't exist or entry isn't found (with explanation).
    — **Why:** Users need uninstall; manifest-scoping means `remove` never touches `setup.sh`-installed files or hand-edited files.
    — **Done when:** `add X` then `remove X` removes X; `remove X` after `setup.sh` is a safe no-op with a message; `--prune` still works for project scope.
    — **Consumers affected:** users, uninstall safety.

- [ ] **3.6** Add strict-allowlist detection: if `config.json` has `permission.skill: {"*":"deny"}`, warn "installed but HIDDEN — add `"name":"allow"` or re-run with --permit" and print the exact JSON line. Add MCP warn-and-print at user scope: print the MCP JSON snippet; suggest `--project`.
    — **Why:** Without detection, users install a skill and it silently doesn't appear (confusing). MCP warn-and-print prevents the repo's config-corruption LEARNING from recurring.
    — **Done when:** strict allowlist triggers warning + exact line printed; MCP requirement triggers snippet print; neither auto-modifies config at user scope.
    — **Consumers affected:** users (UX flows C/E).

- [ ] **3.7** Verify backwards-compat: `opencode-init --preset review --yes` works unchanged; all existing flags (`--skills`, `--agents`, `--preset`, `--yes`, `--dry-run`, `--prune`, `--list`, `--expand`, `--describe`, `--help`) still function.
    — **Why:** The refactor must not break the existing installer. Preset path is the primary use case for `opencode-init` today.
    — **Done when:** `opencode-init --preset review --yes --dry-run` produces identical output to pre-refactor baseline; existing CI tests pass.
    — **Consumers affected:** existing `opencode-init` users.

### Phase 4: Manifests

- [ ] **4.1** Implement user-scope manifest: `~/.config/opencode/.skill-manifest.json` records every user-scope install (skill name, agent stem, timestamp, source paths). Created on first `add` at user scope; read by `--remove`.
    — **Why:** Manifest-scoped removal means `remove` never touches files from `setup.sh` or hand-edited files. Two manifests = clean separation.
    — **Done when:** `add solid-principles-skill` creates/updates the manifest; `remove solid-principles-skill` reads it and removes only manifest-owned entries.
    — **Consumers affected:** `--remove` (Phase 3.5).

- [ ] **4.2** Document manifest-scoped `remove` behavior: safe no-op after `setup.sh` (no user-scope manifest entries to remove); document in `--help` output and README.
    — **Why:** Users who ran `setup.sh` first may expect `remove` to undo it; setting honest expectations prevents confusion.
    — **Done when:** `--help` and README explain the manifest boundary; error message on no-op is clear.
    — **Consumers affected:** users, docs.

### Phase 5: Catalog site builder

- [ ] **5.1** Create `deploy/build-site.mjs` (new, zero-dep, mirrors `build-registry.mjs` ethos): reads `deploy/registry.json` → emits a catalog page (38 agents + 126 skills, category filter + search, cards link to GitHub source paths) + serves `registry.json` as a static JSON API. Output to `/docs` for GitHub Pages.
    — **Why:** A browsable catalog lets users discover skills/agents without reading source. Static JSON API enables future tooling. Zero-dep mirrors the repo's build-registry.mjs approach.
    — **Done when:** `node deploy/build-site.mjs` generates `/docs/index.html` with filterable cards + `/docs/registry.json`; page loads in a browser with working category filter + search.
    — **Consumers affected:** GitHub Pages, users.

### Phase 6: GitHub Pages + CI

- [ ] **6.1** Add `pages` job to `.github/workflows/release.yml`: `actions/upload-pages-artifact@v3` + `actions/deploy-pages@v4`, on push to `main`, after the release job, gated `if: github.ref == 'refs/heads/main'`. Triggers `build-site.mjs` in a build step, uploads `/docs` as the artifact.
    — **Why:** Publishes the catalog automatically on every `main` push. Gating to `main` prevents PRs from triggering deploys.
    — **Done when:** Merge to `main` triggers Pages deploy; catalog is live at the repo's GitHub Pages URL.
    — **Consumers affected:** users, documentation.

- [ ] **6.2** Verify all CI lint steps pass (from Phase 1.2): `node --check deploy/init.mjs deploy/source.mjs`, `jq . package.json`, `npm pack --dry-run` guard. Ensure they run in the existing test job, not just the pages job.
    — **Why:** Lint guards must run on every PR, not just on `main` pushes. The `npm pack` guard catches silent source exclusion.
    — **Done when:** All three checks pass on `main`; a PR with a syntax error in `source.mjs` fails CI before merge.
    — **Consumers affected:** CI, developer confidence.

### Phase 7: Docs + sync surface

- [ ] **7.1** Update `README.md`: add `npx github:Simonmensi/opencode-config-template add` section with the UX flow table (flows A–F), scope-appropriate-config explanation (file-drop vs full generation), and `--permit`/`--remove` documentation. Cross-link issue #304.
    — **Why:** Users need to discover the new install method and understand the config strategy.
    — **Done when:** Section exists with all 6 UX flows documented; scope strategy explained; issue linked.
    — **Consumers affected:** users.

- [ ] **7.2** Update `AGENTS.md`: add the new distribution channel under "Repository Purpose" — frame as "registry/CLI installer", NOT plugin. Add routing guidance for the `add` verb.
    — **Why:** Agents need to understand the new distribution model for correct framing in generated configs and user interactions.
    — **Done when:** "Repository Purpose" mentions the npx registry/CLI channel; plugin framing explicitly avoided.
    — **Consumers affected:** agents, users.

- [ ] **7.3** Update `deploy/setup.sh` + `deploy/setup.ps1`: add one-liner noting the `opencode-init` symlink coexists with the new `npx` entry (purely additive; no behavior change).
    — **Why:** Users who run `setup.sh` should know the `npx` path exists as an alternative for individual installs.
    — **Done when:** Both scripts mention the coexistence; existing `setup.sh` behavior unchanged.
    — **Consumers affected:** global deploy users.

- [ ] **7.4** Update `.releaserc.json`: add `package.json`, `deploy/source.mjs`, `deploy/build-site.mjs` to `@semantic-release/git` `assets` so release commits capture them.
    — **Why:** New files must be included in release commits or they'll be missing from tagged releases.
    — **Done when:** `semantic-release` dry-run shows the new files in the release commit assets.
    — **Consumers affected:** release pipeline.

- [ ] **7.5** Verify `node deploy/build-registry.mjs --check` passes (no drift — this plan adds ZERO skills/agents, so the registry stays valid).
    — **Why:** The repo's CI drift guard must remain green. No counts change, no registry drift.
    — **Done when:** `node deploy/build-registry.mjs --check` exits 0.
    — **Consumers affected:** CI.

---

## UX Flows (spec)

```bash
# A. Clean-slate user (main audience) — zero config touch
$ npx github:Simonmensi/opencode-config-template add solid-principles-skill
→ ~/.config/opencode/skills/solid-principles-skill/  ✓ auto-discovered

# B. Subagent (pulls required skills by default)
$ npx github:Simonmensi/opencode-config-template add tdd-subagent
→ ~/.config/opencode/agents/tdd-subagent.md + skills/tdd-workflow-skill/

# C. Strict-allowlist base detected (user ran setup.sh)
$ npx github:Simonmensi/opencode-config-template add my-custom-skill
→ ⚠ Strict allowlist detected — installed but HIDDEN.
  Add "my-custom-skill":"allow" to permission.skill, or re-run with --permit.

# D. --permit (opt-in, backup + merge permission only)
$ npx github:Simonmensi/opencode-config-template add my-custom-skill --permit
→ backup config.json.bak-<ts> → merge permission entry → ✓

# E. Skill needs an MCP (always warn-and-print at user scope)
$ npx github:Simonmensi/opencode-config-template add markitdown-mcp-skill
→ ⚠ Needs 'markitdown' MCP. Paste this snippet into config.json,
  or re-run with --project to write it to ./.opencode/opencode.json.

# F. Project scope (full-service — existing init.mjs behavior)
$ npx github:Simonmensi/opencode-config-template add nextjs-specialist-subagent --project
→ ./.opencode/{agents,skills}/ + .opencode/opencode.json (permission+MCPs) + models.json + AGENTS.md
```

---

## Acceptance Criteria

- [ ] `npx github:Simonmensi/opencode-config-template add solid-principles-skill` (dry-run and real) writes to `~/.config/opencode/skills/` with zero config.json touch on a clean slate.
- [ ] `add <subagent>` auto-pulls required skills; `--no-deps` installs one file.
- [ ] `--project` path writes `.opencode/opencode.json` + `models.json` + slim `AGENTS.md` (existing behavior preserved).
- [ ] `--permit` creates a timestamped backup then merges only permission entries; resulting config.json passes `python3 -c "import json; json.load(open(...))"`.
- [ ] Strict-allowlist detected → warning + exact line printed; MCP needed → snippet printed (never auto-merged at user scope).
- [ ] `remove <name>` removes only manifest-owned entries; safe no-op (with explanation) after `setup.sh`.
- [ ] Existing `opencode-init --preset review --yes` works unchanged (backwards-compat).
- [ ] `node deploy/build-registry.mjs --check` passes (no drift).
- [ ] GitHub Pages deploys a catalog of all agents+skills; `registry.json` served as static API.
- [ ] CI lint steps (`node --check`, `jq . package.json`, `npm pack --dry-run` guard) pass.

## Out of Scope (follow-ups)

- Verb surface ergonomics (`add/list/info/remove` as first-class verbs) — flags cover MVP.
- Per-item `metadata.scope` hints.
- Frontmatter-stripping pipeline.
- `--permit` merging MCP blocks.
- Slim install branch (to shrink the npx clone).
- Per-skill HTTP remote fetch + shadcn-style remote registry JSON (the `source.mjs` seam makes this a future one-file change).
- npm publish.

---

## Revision Log

**2026-08-04 (initial plan — after opencode-tooling review)** —
Plan created from a multi-round design session reviewed by `opencode-tooling-subagent`. Key review outcomes incorporated:
- (1) **Framing = registry/CLI installer, NOT plugin.** opencode "plugins" are TypeScript runtime hooks; skills are files on discovery paths. No "skill plugin" concept exists.
- (2) **Future-proofing = single `source.mjs` module**, NOT speculative registry `files[]`/`fetchUrl` fields on each skill/agent. The seam is the read layer, not per-item metadata.
- (3) **`bin` → `init.mjs` directly.** Cut the separate `bin/cli.mjs` — it's an unnecessary indirection layer; `init.mjs` already parses args and dispatches.
- (4) **Drop frontmatter-stripping pipeline.** Audit (`docs/audits/skill-yaml-compliance-audit.md`) shows zero non-standard fields — nothing to strip, and rewriting-on-import is a surprising side-effect.
- (5) **Drop per-item `metadata.scope` hints.** A `--project` toggle covers the same need with zero per-item metadata overhead.
- (6) **User-target MCP = warn-and-print.** Don't auto-merge MCPs into the hand-edited global config — the repo has a LEARNING on config corruption (`LEARNINGS/anti-patterns/jsonc-comments-in-opencode-json.md`). `--permit` merges ONLY permission entries; MCPs always printed for manual action or `--project`.
- (7) **CI guards + `.releaserc.json` assets + `pages` job.** Lint steps (`node --check`, `jq .`, `npm pack --dry-run`) catch breakage; Pages deploys the catalog; release config captures new files.
