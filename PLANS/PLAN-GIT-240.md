# PLAN-GIT-240 — Consolidate Next.js Subagents

> **STATUS: RESOLVED** — Completed via [PR #241](https://github.com/darellchua2/opencode-config-template/pull/241) (commit `10ebe7a`, merged 2026-07-18). Issue [#240](https://github.com/darellchua2/opencode-config-template/issues/240) CLOSED. This plan is retained for historical reference; checkboxes below reflect the plan-as-drafted, not post-merge state.

**Branch:** `refactor/issue-240-consolidate-nextjs-subagents`
**Issue:** [#240](https://github.com/darellchua2/opencode-config-template/issues/240)
**Title:** [Refactor] Consolidate nextjs-setup-subagent + nextjs-mcp-advisor-subagent into nextjs-specialist-subagent
**Labels:** `refactor`, `documentation`, `subagent`, `patch`

## Goal

Consolidate two redundant Next.js subagents (`nextjs-setup-subagent` + `nextjs-mcp-advisor-subagent`) into one `nextjs-specialist-subagent`, extract MCP documentation into a new `nextjs-devtools-mcp-skill`, and sync all documentation files.

## Rationale Summary

1. Both originals use same model (`glm-5-turbo`) + same `bash: deny` posture — split is the root redundancy
2. The MCP advisor's 350+ lines are documentation dressed as an agent; should be a skill (extract-then-delegate)
3. MCP tools are gated centrally in `opencode.json` `tools` block, not via per-agent frontmatter grants
4. Trigger-phrase overlap with `code-review-subagent`, `error-resolver-subagent`, `react-nextjs-antipatterns-skill`
5. Net context savings: 464 lines → ~380 (agent 85 + skill 280 loaded on-demand)

## Execution Strategy

- **Phase A** — `opencode-tooling-subagent` (bash: deny) creates files + syncs docs
- **Phase B** — Primary session executes hard-deletes via `git rm`
- **Phase C** — Primary session verification

## Phase A — opencode-tooling-subagent (no bash)

- [ ] **A1.** Create `opencode_app/.opencode/skills/nextjs-devtools-mcp-skill/SKILL.md` (Draft 2 from issue appendix)
- [ ] **A2.** Create `opencode_app/.opencode/agents/nextjs-specialist-subagent.md` (Draft 1 from issue appendix)
- [ ] **A3.** Update `opencode_app/.opencode/skills/git-branch-workflow-setup-skill/SKILL.md:158` — rename `nextjs-setup-subagent` → `nextjs-specialist-subagent`
- [ ] **A4.** Update `README.md`:
  - [ ] A4a. Line 280: `107 skills` → `108 skills`
  - [ ] A4b. Line 288: `Framework-Specific (7)` → `(8)`, append `nextjs-devtools-mcp`
  - [ ] A4c. Line 308: `37 agent .md files` → `36 agent .md files`
  - [ ] A4d. Line 338: Replace `nextjs-setup-subagent` row with `nextjs-specialist-subagent` row
  - [ ] A4e. Line 347: Remove `nextjs-mcp-advisor-subagent` row
  - [ ] A4f. Line 23: `# 37 subagent .md files` → `# 36 subagent .md files` (directory tree)
  - [ ] A4g. Line 24: `# 107 skill directories` → `# 108 skill directories` (directory tree)
- [ ] **A5.** Update `deploy/setup.sh`:
  - [ ] A5a. Lines 537–538: Replace 2 banner lines with single `nextjs-specialist` line
  - [ ] A5b. Line 587: `SKILLS (107)` → `(108)`
  - [ ] A5c. Lines 603–606: `Framework-Specific (7)` → `(8)` + new skill
  - [ ] A5d. Lines 2273–2279: Add `nextjs-devtools-mcp` to banner
  - [ ] A5e. Line 503: `AGENTS (37):` → `AGENTS (36):`
  - [ ] A5f. Line 1666: `Configured 37 agents:` → `Configured 36 agents:`
  - [ ] A5g. Line 2220: `Configured 37 agents:` → `Configured 36 agents:`
  - [ ] A5h. Line 2272: `Framework-Specific (7):` → `(8):` (banner header)
  - [ ] A5i. Line 2398: `Agents (37):` → `Agents (36):`
  - [ ] A5j. Line 2410: `📦 107 Skills Available` → `📦 108 Skills Available`
  - [ ] A5k. Line 2413: `Framework-Specific (7)` → `(8)` (summary banner)
- [ ] **A6.** Update `deploy/setup.ps1`:
  - [ ] A6a. Line 372: Replace `nextjs-mcp-advisor` with `nextjs-specialist`
  - [ ] A6b. Line 373: Remove `nextjs-setup` line
  - [ ] A6c. Lines 399–402: Mirror Framework-Specific (7)→(8)
  - [ ] A6d. Line 1187: VERIFY `next-devtools` line untouched
  - [ ] A6e. Lines 1265–1268: Mirror banner change
  - [ ] A6f. Line 338: `AGENTS (37):` → `AGENTS (36):`
  - [ ] A6g. Line 383: `SKILLS (107):` → `SKILLS (108):`
  - [ ] A6h. Line 1177: `Configured 37 agents:` → `Configured 36 agents:`
  - [ ] A6i. Line 1264: `Framework-Specific (7):` → `(8):` (banner header)
  - [ ] A6j. Line 1753: `Agents (37):` → `Agents (36):`
  - [ ] A6k. Line 1765: `107 Skills Available` → `108 Skills Available`
  - [ ] A6l. Line 1768: `Framework-Specific (7)` → `(8)` (summary banner)
- [ ] **A7.** Update `opencode_app/README.md`:
  - [ ] A7a. Line 25: `37 agent .md files` → `36 agent .md files`
  - [ ] A7b. Line 102: `24 of 37 agents` → `23 of 36 agents` (corrects pre-existing off-by-one; verified actual count is 23)
  - [ ] A7c. Line 26: `# 107 skill directories` → `# 108 skill directories` (directory tree)
- [ ] **A8.** Phase A verification audit (all 6 checks from issue §4.A8 must pass)

## Phase B — Primary session (requires bash)

- [ ] **B1.** `git rm opencode_app/.opencode/agents/nextjs-setup-subagent.md`
- [ ] **B2.** `git rm opencode_app/.opencode/agents/nextjs-mcp-advisor-subagent.md`
- [ ] **B3.** Verify `ls opencode_app/.opencode/agents/ | wc -l` reports **36**
- [ ] **B4.** Stale-ref sweep returns **zero hits** for BOTH:
  - Agent names: `grep -rE "nextjs-(setup-subagent|mcp-advisor)" opencode_app/ deploy/ README.md | grep -v "_archived/"`
  - Stale counts: `grep -rnE '\(37\)|37 agent|37 subagent|107 skill|107 Skill|Framework-Specific \(7\)' README.md deploy/setup.sh deploy/setup.ps1 opencode_app/README.md`

## Phase C — Final verification

- [ ] **C1.** Re-run all Phase A Step A8 audits — all must pass
- [ ] **C2.** Confirm acceptance criteria (issue §6, 14-point checklist) all satisfied
- [ ] **C3.** Commit + push branch

## Phase D — Review + Merge

- [ ] **D1.** Post-implementation review by `opencode-tooling-subagent` (blast-radius outliers)
- [ ] **D2.** PR creation + merge via `pr-workflow-subagent`
- [ ] **D3.** Close issue #240

## Acceptance Criteria

- [ ] `nextjs-specialist-subagent.md` exists with Draft 1 content
- [ ] `nextjs-devtools-mcp-skill/SKILL.md` exists with Draft 2 content
- [ ] Old agent files no longer exist
- [ ] Agent count: 36
- [ ] Skill count: 108
- [ ] Zero stale references to `nextjs-(setup-subagent|mcp-advisor)` outside `_archived/`
- [ ] `opencode_app/opencode.json` lines 178, 260 untouched
- [ ] `deploy/config.json` lines 178, 260 untouched

## Risk Notes

- **Low risk:** Hard deletes supplant originals (consolidated agent is strict superset)
- **Medium risk:** `opencode_app/README.md:102` "X of 36" requires manual recount
- **Migration:** Users with prior `setup.sh` deployments retain stale files harmlessly
