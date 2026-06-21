# PLAN: Import grill-with-docs skill suite from mattpocock/skills

**Ticket**: [BT-70](https://betekk.atlassian.net/browse/BT-70)
**Branch**: `feature/BT-70-grill-with-docs-skills`
**Status**: In Progress
**PRD**: None

---

## Summary

Import the `grill-with-docs` skill and its two supporting engines (`grilling`, `domain-modeling`) from [mattpocock/skills](https://github.com/mattpocock/skills), adapted to this repo's skill conventions. mattpocock's `grill-with-docs` is a thin user-invoked orchestrator that composes two model-invoked engines: `grilling` (relentless one-question-at-a-time interview) and `domain-modeling` (captures `CONTEXT.md` glossary + ADRs inline).

### Design Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Number of skills | 4 (3 planned + grill-me-skill added per review) | Faithful to mattpocock's engine/entry-point split; grill-with-docs is meaningless without its 2 engines; grill-me added to resolve dangling cross-references flagged by opencode-tooling-subagent |
| Naming convention | `-skill` suffix | Matches repo convention (e.g. `continuous-learning-skill`) |
| Skill format | Single self-contained `SKILL.md` | This repo uses single-file skills; CONTEXT-FORMAT + ADR-FORMAT inlined into domain-modeling-skill rather than separate files |
| Trigger metadata | `grilling`/`domain-modeling` = `auto`; `grill-with-docs`/`grill-me` = `explicit-only` | Mirrors mattpocock's `disable-model-invocation` split |
| New category | "Planning & Alignment" (4 skills) | Grilling/domain-modeling don't fit existing categories cleanly |
| Skill count | 82 → 86 | +4 skills |
| Subagent wiring | `prd-specialist-subagent` granted `grilling-skill` + `domain-modeling-skill` | Discovery interview = grilling pattern; domain term capture = domain-modeling |

### Architecture

```
User: "grill with docs"
  → Primary agent loads grill-with-docs-skill (explicit-only)
  → Orchestrates two model-invoked engines:
      grilling-skill (auto)        — interview loop, one question at a time
      domain-modeling-skill (auto) — CONTEXT.md + ADR capture inline
  → Result: alignment + durable artifacts (glossary + ADRs)
```

---

## Pre-existing Count Verification (2026-06-21)

- Declared skill count in setup.sh/setup.ps1: **82**
- Actual skill dirs (excl `_archived`/`scripts`) BEFORE this work: **82** (in sync)
- After adding 3 skills: actual = **85**
- Implementation rule: use verification command, sync declared → 85

---

## Implementation Phases

### Phase 1: Skill Creation (DONE)

- [x] **1.1** Created `grilling-skill/SKILL.md` — model-invoked interview engine
- [x] **1.2** Created `domain-modeling-skill/SKILL.md` — model-invoked doc-capture engine (CONTEXT-FORMAT + ADR-FORMAT inlined)
- [x] **1.3** Created `grill-with-docs-skill/SKILL.md` — user-invoked orchestrator
- [x] **1.4** Created `grill-me-skill/SKILL.md` — user-invoked orchestrator (added during Phase 2 review to resolve dangling refs)

### Phase 2: OpenCode Compliance Review (DONE)

- [x] **2.1** Reviewed all skills with `opencode-tooling-subagent` — verdict PASS-WITH-FIXES
- [x] **2.2** Applied fixes: created `grill-me-skill` (resolves 4 dangling refs); removed `" grill with docs"` trigger phrase from grilling-skill (prevents auto-engine hijacking the orchestrator's trigger)

### Phase 3: Subagent Wiring (DONE)

- [x] **3.1** Identified `prd-specialist-subagent` as the best fit (discovery interview = grilling; domain term capture = domain-modeling)
- [x] **3.2** Granted `grilling-skill: allow` + `domain-modeling-skill: allow` in prd-specialist-subagent permission.skill; added "Interview Enhancement Skills" guidance section

### Phase 4: Deploy Script Updates (DONE)

- [x] **4.1** Updated `deploy/setup.sh`: count 82→86, added "Planning & Alignment (4)" to help + Deploy-Skills summary + banner
- [x] **4.2** Updated `deploy/setup.ps1`: count 82→86, same category additions (parity)

### Phase 5: README Sync (DONE)

- [x] **5.1** Updated `README.md`: 82 skills/14 categories → 86 skills/15 categories; added Planning & Alignment row to Skill Categories table

### Phase 6: Code Review

- [ ] **6.1** Final code review to catch any remaining issues

---

## Acceptance Criteria

- [ ] 3 skills follow repo frontmatter conventions
- [ ] opencode-tooling-subagent confirms compliance
- [ ] Suitable subagent identified and wired
- [ ] setup.sh + setup.ps1 counts synchronized at 85
- [ ] README.md updated with new category
- [ ] Code review passes with no blocking issues
- [ ] Branch pushed with PLAN committed

---

## Notes

- mattpocock's `grill-me` (grilling without docs) was intentionally NOT imported — `grill-with-docs-skill` references it as a fallback but it doesn't exist yet. If the user wants parity, a future ticket can add `grill-me-skill`.
- The three skills reference each other in their "Integration with Other Skills" tables; all cross-references resolve within this set.
