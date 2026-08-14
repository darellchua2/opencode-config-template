## Decision: Skill permission allowlist — "*":"deny" + 80 explicit allows

**Context**: Primary session loads every skill's `description` into `<available_skills>` at startup (~124 skills = significant per-session token tax).
**Pattern**: Use `"permission.skill": { "*": "deny", "<skill>": "allow" }` in `opencode_app/opencode.json`. The `"*": "deny"` catch-all goes first (lowest priority); specific allows go after (last-match-wins per [permissions docs](https://opencode.ai/docs/permissions/#granular-rules-object-syntax)).
**Rationale**: An allowlist of 80 primary-visible skills hides 44 subagent-only skills from the primary's `<available_skills>`, cutting ~44 descriptions (~200–400 tokens each) per session. New skills default to hidden until explicitly added.
**Alternatives Considered**: Denylist (deny only specific subagent-only skills). Rejected — only hides ~17 skills vs allowlist's ~44. Allowlist scales better (new skills auto-hidden).
**Trade-offs**: 
- Pro: ~2.6x more token savings than denylist; enforces hub-and-spoke routing
- Con: new skills are invisible to primary until manually added to allowlist; maintenance burden
- Con: must verify every denied skill has a consumer subagent with `permission.skill: allow` override (36 of 39 subagents are self-scoped)
**Confidence**: 0.9
**Scope**: project
**Date**: 2026-07-26

**Key constraint**: 13 skills have NO consumer subagent override — they MUST stay in the allowlist because denying them would make them inaccessible to ALL scoped subagents. These include: `pdf-specialist-skill`, `construction-bd-skill`, `startup-business-docs-skill`, `python-packaging-skill`, `csharp-linter-skill`, `java-linter-skill`, `typescript-dry-principle-skill`, `monorepo-management-skill`, `threejs-nextjs-skill`, etc.

> **SUPERSEDED (2026-08-14, GIT-333)**: the 13-must-keep constraint above is lifted. Every formerly-orphaned skill now has a frontmatter `permission.skill: allow` consumer (see `PLANS/PLAN-GIT-333.md` Appendix for the full 58-skill classification: 41 self-scoped, 17 new allows added in Phase 1, 0 intentionally-hidden) or remains primary-visible via the `lean` profile (`pdf-specialist-skill`). Denying the other 58 from the primary is now safe under the lean profile — subagents are profile-immune.

**References**:
- `opencode_app/opencode.json` — `permission.skill` block (80 allows + 1 deny)
- `deploy/.AGENTS.md` — "Skill Permission Allowlist" documentation section
- `PLANS/PLAN-GIT-270.md` — full implementation plan
- Issue #270, PR #271
