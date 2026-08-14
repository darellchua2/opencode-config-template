## Decision: Skill permission allowlist — shipped 88, lean profile 30, deploy default lean

**Context**: Primary session loads every skill's `description` into `<available_skills>` at startup (~131 skills = significant per-session token tax). GIT-333 added a deploy-time profile so downstream users choose visibility without hand-editing.
**Pattern**: Ship `"permission.skill": { "*": "deny", "<skill>": "allow" }` with **88 allows** in `opencode_app/opencode.json` (= the `full` profile, single source of truth). `deploy/skill-profiles.json` defines `lean` (**30 allows**, incl. `opencode-repo-setup-skill` added in GIT-333 Phase 7). `./deploy/setup.sh --skill-profile lean|full` (default **lean**) rewrites ONLY the deployed copy's `permission.skill` block via `deploy/apply-skill-profile.mjs` — the shipped file is never modified by deploys.
**Rationale**: 88 allows hides 43 subagent-only skills from the primary; the lean profile hides 58 more (~3.9k tokens/session, measured). Subagents are profile-immune: every skill has either a frontmatter `permission.skill: allow` consumer (41 self-scoped pre-GIT-333 + 17 added in GIT-333 Phase 1) or stays primary-visible in lean (pdf-specialist, opencode-repo-setup). New skills default to hidden until explicitly added.
**Alternatives Considered**: Denylist (rejected — hides fewer skills, poor scaling). Hardcoding lean into opencode.json (rejected — this repo is an agnostic configurator; defaults belong to deploy-time selection, symmetric with `--provider`).
**Trade-offs**:
- Pro: ~3.9k tokens/session saved on default deploys (measured); one-line `deploy/skill-profiles.json` edit re-exposes any skill; `full` is always available
- Con: lean-hidden skills cannot be @-loaded by the primary until re-exposed (documented in README profile section)
- Con: new skills need a frontmatter consumer (or a profiles entry) to be visible anywhere
**Confidence**: 0.9
**Scope**: project
**Date**: 2026-08-14

**Superseded constraint (former "13 must-keep")**: pre-GIT-333, 13 skills had NO consumer subagent override and had to stay primary-visible. As of GIT-333 Phase 1 every skill has a frontmatter consumer or a lean slot — the constraint is lifted. Full 58-skill classification: `PLANS/PLAN-GIT-333.md` Appendix (41 self-scoped, 17 new allows, 0 intentionally-hidden).

**References**:
- `opencode_app/opencode.json` — `permission.skill` block (88 allows + 1 deny = full profile)
- `deploy/skill-profiles.json` — lean profile (30 keys)
- `deploy/apply-skill-profile.mjs` — deploy-time rewriter (typo-guarded, fail-closed)
- `deploy/.AGENTS.md` — "Skill Permission Allowlist" documentation section
- `PLANS/PLAN-GIT-270.md` — original allowlist implementation
- `PLANS/PLAN-GIT-333.md` — profile mechanism + Phase 1 consumer safety net
- Issue #270, PR #271; Issue #333
