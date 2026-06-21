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
| Number of skills | 3 | Faithful to mattpocock's engine/entry-point split; grill-with-docs is meaningless without its 2 engines |
| Naming convention | `-skill` suffix | Matches repo convention (e.g. `continuous-learning-skill`) |
| Skill format | Single self-contained `SKILL.md` | This repo uses single-file skills; CONTEXT-FORMAT + ADR-FORMAT inlined into domain-modeling-skill rather than separate files |
| Trigger metadata | `grilling`/`domain-modeling` = `auto`; `grill-with-docs` = `explicit-only` | Mirrors mattpocock's `disable-model-invocation` split |
| New category | "Planning & Alignment" (3 skills) | Grilling/domain-modeling don't fit existing categories cleanly |
| Skill count | 82 → 85 | +3 skills |

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

### Phase 2: OpenCode Compliance Review

- [ ] **2.1** Review all 3 skills with `opencode-tooling-subagent` for:
    - Frontmatter correctness (name, license, compatibility, metadata, version)
    - Trigger/invocation model (auto vs explicit-only)
    - Repo conventions alignment
    - Cross-skill references resolve
    - No `glm-5.2` leakage (skills are not subagents, but check model-tiering awareness)
- [ ] **2.2** Apply any fixes the subagent identifies

### Phase 3: Subagent Wiring

- [ ] **3.1** Determine which subagent(s) should use these skills:
    - Candidates: `prd-specialist-subagent` (discovery interview overlaps), `ticket-creation-subagent` (pre-ticket alignment), `code-review-subagent`/`architecture-review-subagent` (domain-model capture post-review)
    - Most natural fit: `prd-specialist-subagent` — grilling is the same relentless-interview pattern
- [ ] **3.2** Apply wiring (add skill reference to chosen subagent's `.md`)

### Phase 4: Deploy Script Updates

- [ ] **4.1** Update `deploy/setup.sh`:
    - Skill count: `SKILLS (82)` → `SKILLS (85)`
    - Add new category "Planning & Alignment (3)" to the skills listing
- [ ] **4.2** Update `deploy/setup.ps1` (parity):
    - Skill count: `SKILLS (82)` → `SKILLS (85)`
    - Add same category listing

### Phase 5: README Sync

- [ ] **5.1** Update `README.md` Skill Categories table (+ Planning & Alignment row)
- [ ] **5.2** Update `opencode_app/README.md` if it has a skills listing

### Phase 6: Code Review

- [ ] **6.1** Final code review (use `code-review-subagent`) to catch any remaining issues:
    - Frontmatter consistency across the 3 files
    - Count synchronization (setup.sh, setup.ps1, README.md)
    - No orphaned cross-references
    - Category placement correctness

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
