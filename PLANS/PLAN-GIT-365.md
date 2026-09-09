# PLAN: Purge stale docs (PLANS/audits/research) + refresh allowlist LEARNING

**Branch**: feat/GIT-365
**Issue**: https://github.com/darellchua2/opencode-config-template/issues/365
**Base**: main

## Acceptance Criteria

- [ ] All 6 fully-executed plans deleted from `PLANS/` (zero unchecked boxes verified at 3fb5a29)
- [ ] `docs/audits/skill-yaml-compliance-audit.md` deleted; `docs/prd/` untouched
- [ ] 4 superseded/unreferenced research files deleted; `research/ponytail-load-fix.md` kept
- [ ] `research/ponytail-load-fix.md` dangling pointer to `ponytail-agent-integration-audit.md` removed
- [ ] `LEARNINGS/decisions/skill-permission-allowlist.md` refreshed to registry truth (148 skills / 46 lean, verified 2026-09-09); dangling `PLANS/PLAN-GIT-270.md` / `PLAN-GIT-333.md` path refs dropped
- [ ] `LEARNINGS/_index.md` summary lines mirror the refresh (no "lean profile 30" remnants)
- [ ] README file-tree no longer lists `PLANS/` (dir vanishes from git when empty)
- [ ] Identifier sweep (basename slugs, not paths) across tracked files: zero dangling refs outside CHANGELOG.md historical citations (accepted repo precedent)
- [ ] `node deploy/build-registry.mjs --check` passes; full `bats tests/` green

## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---------------------|---------------------------|---------------------------------|-------------|
| `PLANS/*.md` (6 files) | — | README tree row (step 1.2); CHANGELOG citations (historical text only, accepted) | low |
| `README.md` tree row | 1.1 | README readers (doc-only; no test asserts tree rows) | low |
| `docs/audits/skill-yaml-compliance-audit.md` | — | none (grep-verified) | low |
| 4 `research/*.md` files | — | `research/ponytail-load-fix.md:126` (step 2.3); LEARNINGS tier-swap exemption note (directory-level, dir persists) | low |
| `research/ponytail-load-fix.md:126` | 2.2 | shipped plugins cite ponytail-load-fix.md itself, not the audit | low |
| `LEARNINGS/decisions/skill-permission-allowlist.md` | — | `LEARNINGS/_index.md` summaries (step 3.2) | low |
| `LEARNINGS/_index.md` | 3.1 | session autoinject manifest (read-only consumer) | low |
| Verification gate | 1.1–3.2 | CI (registry drift check, bats suites) | low |

## Implementation Phases

### Phase 1: Purge consumed plans
- [ ] **1.1** `git rm` the six executed plans: `PLANS/PLAN-356.md`, `PLANS/PLAN-DRAFT-skill-stack-simplification.md`, `PLANS/PLAN-GIT-349.md`, `PLANS/PLAN-GIT-350.md`, `PLANS/PLAN-GIT-351.md`, `PLANS/PLAN-GIT-357.md`
    — **Why:** all executed (zero unchecked boxes) and 1–2+ weeks old; repo lifecycle purges consumed plans in batches (31 already deleted, last purge 2026-08-27)
    — **Done when:** `ls PLANS/` returns empty (dir disappears from git)
    — **Consumers affected:** CHANGELOG.md plan-id citations are historical text, unaffected (accepted precedent); `plan-updater-skill` / `worktree-pipeline-skill` recreate `PLANS/` on demand (`mkdir -p`)
- [ ] **1.2** Remove the `├── PLANS/  # Execution plans (git-committed)` row from the README file tree
    — **Why:** with `PLANS/` empty the directory no longer exists in git; the tree must not document a nonexistent dir
    — **Done when:** the file-tree block in `README.md` contains no `PLANS/` row (prose citations like line 245/564 remain — historical, same precedent as CHANGELOG)
    — **Consumers affected:** none; no test asserts README tree rows

### Phase 2: Purge point-in-time audits + superseded research
- [ ] **2.1** `git rm docs/audits/skill-yaml-compliance-audit.md`
    — **Why:** point-in-time compliance audit against long-purged PLAN-GIT-254; referenced by zero tracked files
    — **Done when:** file gone; `docs/prd/` and `docs/audits/`'s siblings unaffected (`docs/prd/` persists)
    — **Consumers affected:** none (grep-verified: `skill-yaml-compliance` and `docs/audits` appear in no other tracked file)
- [ ] **2.2** `git rm` four research files: `research/mcp-11811-implementation-audit.md`, `research/research-opencode-11811-stateless-mcp.md`, `research/ponytail-agent-integration-audit.md`, `research/research-zai-glm-5v-turbo-opencode-access.md`
    — **Why:** upstream-opencode investigation notes and a superseded prior audit, referenced by name nowhere; the glm-5v-turbo vision rationale is already shipped in `zai-vision-analysis-skill` + root `AGENTS.md` (user-approved deletion)
    — **Done when:** `research/` contains exactly `ponytail-load-fix.md`
    — **Consumers affected:** `research/ponytail-load-fix.md:126` cites one of them (fixed in 2.3); `LEARNINGS/patterns/tier-model-swap-blast-radius.md` exemption note says "research/" directory-level — dir persists, note stays valid
- [ ] **2.3** Edit `research/ponytail-load-fix.md` (~line 126) to drop the dangling pointer to `research/ponytail-agent-integration-audit.md`
    — **Why:** the cited file is deleted in 2.2; the one live research doc must stay self-consistent (3 shipped plugin files cite it)
    — **Done when:** `rg ponytail-agent-integration-audit` over tracked files returns zero matches
    — **Consumers affected:** `ponytail-scoped.ts`, `learnings-autoinject.ts/.README.md` cite `ponytail-load-fix.md` itself — prose-only edit, citation intact

### Phase 3: Refresh stale LEARNINGS
- [ ] **3.1** Update `LEARNINGS/decisions/skill-permission-allowlist.md`: volatile counts 88 shipped / 30 lean → 148 skills / 46 lean (deploy/registry.json + deploy/skill-profiles.json, verified 2026-09-09); hedge derived counts; drop `PLANS/PLAN-GIT-270.md` / `PLANS/PLAN-GIT-333.md` path references
    — **Why:** the stored numbers are factually wrong for the current repo (148/46) and would mislead future review/plan sessions; the mechanism decision itself still governs
    — **Done when:** file states 148/46 as current counts and contains no path refs to the two purged plans
    — **Consumers affected:** `_index.md` summary (3.2)
- [ ] **3.2** Mirror the count refresh in the auto-generated `LEARNINGS/_index.md` entry title + summary for the allowlist decision
    — **Why:** `_index` is the per-session autoinjected manifest; stale numbers propagate to every session until next learning write
    — **Done when:** `rg 'lean profile 30|88' LEARNINGS/` returns no allowlist-count matches
    — **Consumers affected:** session autoinject (read-only consumer of `_index`)

### Phase 4: Verification gate
- [ ] **4.1** Identifier sweep: `rg` each deleted file's basename slug (e.g. `skill-yaml-compliance-audit`, `mcp-11811-implementation-audit`, `research-opencode-11811-stateless-mcp`, `ponytail-agent-integration-audit`, `research-zai-glm-5v-turbo-opencode-access`, `PLAN-GIT-349`, `PLAN-GIT-350`, `PLAN-GIT-351`, `PLAN-GIT-357`, `PLAN-356`, `PLAN-DRAFT-skill-stack-simplification`) across tracked files
    — **Why:** repo learning: sweep by identifier, not filename/path — path greps miss namesakes and identifier greps catch prose citations
    — **Done when:** zero matches outside `CHANGELOG.md` (historical citations, accepted precedent)
    — **Consumers affected:** all future doc readers
- [ ] **4.2** Run `node deploy/build-registry.mjs --check`
    — **Why:** frontmatter untouched, so the committed registry must show zero drift
    — **Done when:** exit 0
    — **Consumers affected:** CI (fails on drift)
- [ ] **4.3** Run full `bats tests/`
    — **Why:** count-drift and MCP-consistency suites guard the surfaces this purge could indirectly touch
    — **Done when:** all suites green
    — **Consumers affected:** CI, release-please

## Technical Notes

- Documentation-only change; zero shipped code touched.
- Keep: `research/ponytail-load-fix.md` (cited by 3 shipped plugin files), tsoa/redocly LEARNINGS (baked into `api-design-skill:286` + `openapi-contract-adherence-skill:148`), `MIGRATION.md`, `CHANGELOG.md` (release-please generated), vendored `tests/lib/bats-core/` docs (user decision: vendor dir pristine).
- Historical citations to purged plans in README prose and CHANGELOG stay (repo precedent from prior purge commits).

## Dependencies

None — standalone docs purge.

## Risks & Mitigation

- **A live namesake survives a filename-level check** → mitigated by identifier-level sweep (4.1), per repo learning.
- **Empty `PLANS/` breaks plan tooling assumptions** → mitigated: both consumer skills `mkdir -p PLANS` on demand.
- **Stale-count edit introduces new wrong numbers** → counts verified against `deploy/registry.json` + `deploy/skill-profiles.json` immediately before the edit.
