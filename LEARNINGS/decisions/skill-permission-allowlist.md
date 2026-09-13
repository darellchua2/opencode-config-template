## Decision: Skill permission allowlist — shipped 148, lean profile 46, deploy default lean

**Context**: Primary session loads every skill's `description` into `<available_skills>` at startup (~148 skills = significant per-session token tax). GIT-333 added a deploy-time profile so downstream users choose visibility without hand-editing.
**Pattern**: Ship `"permission.skill": { "*": "deny", "<skill>": "allow" }` with **105 allows** in `opencode_app/opencode.json` (= the `full` profile, single source of truth). `deploy/skill-profiles.json` defines `lean` (**46 allows**, incl. `opencode-repo-setup-skill` added in GIT-333 Phase 7). `./deploy/setup.sh --skill-profile lean|full` (default **lean**) rewrites ONLY the deployed copy's `permission.skill` block via `deploy/apply-skill-profile.mjs` — the shipped file is never modified by deploys.
**Rationale**: 105 allows hides 43 subagent-only skills from the primary; the lean profile hides 59 more (102 total, ~3.9k tokens/session, measured 2026-08-14). Subagents are profile-immune: every skill has either a frontmatter `permission.skill: allow` consumer (41 self-scoped pre-GIT-333 + 17 added in GIT-333 Phase 1) or stays primary-visible in lean (pdf-specialist, opencode-repo-setup). New skills default to hidden until explicitly added. Counts verified against registry + profiles 2026-09-09 — they drift per skill-add; re-derive as `total − allows` before citing.
**Alternatives Considered**: Denylist (rejected — hides fewer skills, poor scaling). Hardcoding lean into opencode.json (rejected — this repo is an agnostic configurator; defaults belong to deploy-time selection, symmetric with `--provider`).
**Trade-offs**:
- Pro: ~3.9k tokens/session saved on default deploys (measured); one-line `deploy/skill-profiles.json` edit re-exposes any skill; `full` is always available
- Con: lean-hidden skills cannot be @-loaded by the primary until re-exposed (documented in README profile section)
- Con: new skills need a frontmatter consumer (or a profiles entry) to be visible anywhere
**Confidence**: 0.9
**Scope**: project
**Date**: 2026-08-14

**Superseded constraint (former "13 must-keep")**: pre-GIT-333, 13 skills had NO consumer subagent override and had to stay primary-visible. As of GIT-333 Phase 1 every skill has a frontmatter consumer or a lean slot — the constraint is lifted. Full 58-skill classification (41 self-scoped, 17 new allows, 0 intentionally-hidden): recorded in the GIT-333 plan appendix (plan since purged per repo lifecycle).

**References**:
- `opencode_app/opencode.json` — `permission.skill` block (105 allows + 1 deny = full profile)
- `deploy/skill-profiles.json` — lean profile (46 keys)
- `deploy/apply-skill-profile.mjs` — deploy-time rewriter (typo-guarded, fail-closed)
- `deploy/.AGENTS.md` — "Skill Permission Allowlist" documentation section
- Issue #270, PR #271; Issue #333

**Addendum (2026-09-13, V2-native conversion):** the `permission.skill` map is now a `permissions` rule array (`{action, resource, effect}`, last-match-wins) — the native V2 shape per the migration guide/permissions docs; the old map is only back-compat-normalized. The 105-allow full profile became 117 array rules (4 read + 7 action-glob + 106 skill); lean stays 46 skill allows (58 total rules on a default `-y` deploy). `apply-skill-profile.mjs` rewrites skill rules in the array, fail-closes if the config lacks it; `merge-packs.mjs` rule-merges by (action, resource) so pack allows still flip source denies. Agent frontmatter uses the same array form (33 files), actions renamed `bash`→`shell`, `task`→`subagent`.
