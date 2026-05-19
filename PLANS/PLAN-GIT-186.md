# PLAN-GIT-186: Remove Duplicate code-quality-subagent

**Issue**: [#186](https://github.com/darellchua2/opencode-config-template/issues/186)
**Branch**: `cleanup/186-remove-code-quality-subagent`
**Type**: cleanup (removal)
**Priority**: minor

## Overview

Remove `code-quality-subagent` — a strict subset of `code-review-subagent` with no unique capabilities. The `code-review-subagent` uses a better model (glm-5.1 vs glm-4.7), has 7 skills (vs 3), supports subagent delegation, and has a comprehensive 176-line workflow with risk-based depth and severity scoring.

## Rationale

| Aspect              | `code-review-subagent` | `code-quality-subagent` |
|---------------------|------------------------|-------------------------|
| Model               | glm-5.1                | glm-4.7 (older)         |
| Skills              | 7                      | 3 (subset)              |
| Task delegation     | explore + general      | None                    |
| Workflow depth      | Risk-based, 176 lines  | Basic, 41 lines         |
| Post-review learning| Yes (supermemory + LEARNINGS/) | No             |

No code path or agent references `code-quality-subagent` as a dependency. Safe to remove.

## Architecture Review Notes

> Review conducted by `architecture-review-subagent` on branch `cleanup/186-remove-code-quality-subagent`.

**Verdict**: Plan is architecturally sound but had **7 missed update locations** (now incorporated below).

### Key Findings from Review

1. **Dependency Safety**: Zero inbound dependencies confirmed. No agent's `task` permission references `code-quality-subagent`. Safe to remove.
2. **Skill `workflow: code-quality` metadata** in 6 skill files is a **category tag**, NOT a reference to the subagent. No changes needed to skill files.
3. **Deployment Impact**: LOW. Existing deployments leave a benign stale `.md` file. Dynamic counting in setup scripts auto-adjusts.
4. **Hardcoded counts missed**: 6 locations in setup.sh/setup.ps1 show "36 agents" in help text/banners (not caught in original plan). Also 1 permission distribution count in AGENTS.md.

## Scope

### Files to Modify

| # | File | Change |
|---|------|--------|
| 1 | `opencode_app/.opencode/agents/code-quality-subagent.md` | **DELETE** |
| 2 | `setup.sh` | Remove from agent listing (line ~507), update 4 hardcoded "36" → "35" (lines 500, 1658, 2213, 2349) |
| 3 | `setup.ps1` | Remove from agent listing (line ~336), update 2 hardcoded "36" → "35" (lines 329, 1734) |
| 4 | `README.md` | Remove row from Subagents table (line 256), update tree comment (line 22: 32→31), remove from Code Quality Subagents table (line 360), update "3 new subagents" text (line 356: 3→2) |
| 5 | `AGENTS.md` | Update tree comment (line 49: 32→31), update narrative (line 66: 32→31), update permission table (line 184: 22→21) |

### Files NOT Modified

- Skill files — `workflow: code-quality` metadata is a category tag, not an agent reference
- `config.json` — agents are file-based, not listed in config
- `opencode_app/AGENTS.md` — no references found
- `.opencode/agents/` (project-level) — not affected

## Phases

### Phase 1: Delete Agent File
- [ ] Delete `opencode_app/.opencode/agents/code-quality-subagent.md`

### Phase 2: Update Setup Scripts
- [ ] Remove `code-quality` entry from setup.sh agent listing (~line 507)
- [ ] setup.sh: Update "36" → "35" in help listing header (line 500)
- [ ] setup.sh: Update "36" → "35" in post-setup confirmation (line 1658)
- [ ] setup.sh: Update "36" → "35" in status check output (line 2213)
- [ ] setup.sh: Update "36" → "35" in quick start banner (line 2349)
- [ ] Remove `code-quality` entry from setup.ps1 agent listing (~line 336)
- [ ] setup.ps1: Update "36" → "35" in help listing header (line 329)
- [ ] setup.ps1: Update "36" → "35" in post-setup banner (line 1734)

### Phase 3: Update Documentation
- [ ] README.md: Remove row from main Subagents table (line 256)
- [ ] README.md: Update tree comment "32 subagent" → "31 subagent" (line 22)
- [ ] README.md: Remove `code-quality-subagent` row from Code Quality Subagents table (line 360)
- [ ] README.md: Update "3 new subagents" → "2 new subagents" (line 356)
- [ ] AGENTS.md: Update tree comment "32 subagent" → "31 subagent" (line 49)
- [ ] AGENTS.md: Update narrative "All 32 subagent" → "All 31 subagent" (line 66)
- [ ] AGENTS.md: Update permission table "No task field" count 22 → 21 (line 184)

### Phase 4: Verify Consistency
- [ ] Grep for any remaining `code-quality-subagent` references across repo
- [ ] Verify subagent count is 31 everywhere it appears
- [ ] Run `ls opencode_app/.opencode/agents/ | wc -l` to confirm 31 files
- [ ] Verify no agent's `task` permission references `code-quality-subagent`
- [ ] Verify setup.sh/setup.ps1 show "35 agents" in help text

## Acceptance Criteria

- [ ] `code-quality-subagent.md` no longer exists
- [ ] No references to `code-quality-subagent` remain in any file
- [ ] Subagent count is consistently 31 across README.md, AGENTS.md
- [ ] Agent total count is consistently 35 in setup.sh, setup.ps1 help text
- [ ] Permission distribution table sums to 31 (1 + 9 + 21)
- [ ] setup.sh and setup.ps1 deploy exactly 31 agent files
- [ ] `code-review-subagent` remains and is unaffected
