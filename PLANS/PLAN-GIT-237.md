**Issue**: #237
**Title**: Add uiux-reviewer-subagent + uiux-review-skill (13-axis design review)
**Branch**: feat/uiux-reviewer-subagent
**Status**: In Progress

## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---------------------|---------------------------|---------------------------------|-------------|
| `opencode_app/.opencode/agents/uiux-reviewer-subagent.md` | — | `deploy/setup.sh`, `deploy/.AGENTS.md`, `README.md`, `opencode_app/README.md`, `opencode_app/AGENTS.md` | high |
| `opencode_app/.opencode/skills/uiux-review-skill/SKILL.md` | — | `deploy/setup.sh`, `README.md`, `opencode_app/README.md` | high |
| `deploy/setup.sh` | Both files above | CI/CD pipeline, user deployments | medium |
| `deploy/setup.ps1` | Both files above | Windows user deployments | medium |
| `README.md` | Both files above | Repo consumers, onboarding | low |
| `opencode_app/README.md` | Both files above | Docker standalone consumers | low |
| `deploy/.AGENTS.md` | Agent file above (routing row references it) | All user-space deployments via `deploy/setup.sh` (copies at L1625/L1629) | high — without routing row, agent is deployed but undiscoverable |
| `opencode_app/AGENTS.md` | Agent file above (CodeGraph table references it) | Docker standalone users (CodeGraph usage guidance) | medium |

## Implementation Phases

### Phase 1: Create Subagent

- [ ] **1.1** Create `opencode_app/.opencode/agents/uiux-reviewer-subagent.md` with frontmatter: description="Review-only UI/UX design review subagent. Applies a 13-axis rubric (6 AslanMazhidov + 5 RNT56 + Nielsen's 10 + anti-default AI cluster detection) to screenshots, source code, and live URLs. Delegates screenshot analysis to image-analyzer-subagent.", mode=subagent, model=glm-5.1, steps=30, permissions (read:allow, edit:deny+LEARNINGS/**:allow, glob:allow, grep:allow, bash:allow, task:deny+explore/general/image-analyzer-subagent:allow, skill:uiux-review-skill/frontend-design-skill/accessibility-a11y-skill/wireframer-skill/continuous-learning-skill/context-budget-skill:allow)
    — **Why:** Subagent is the orchestration layer — it must be created first so the skill it loads and the docs that reference it have a valid target.
    — **Done when:** File exists at the specified path; frontmatter parses without errors; `edit` denies `*` and allows only `LEARNINGS/**`; `task` denies `*` and allows only `explore`, `general`, `image-analyzer-subagent`; **YAML frontmatter validates**: `python3 -c "import yaml; d=open('opencode_app/.opencode/agents/uiux-reviewer-subagent.md').read(); yaml.safe_load(d.split('---')[1])" && echo OK` exits 0.
    — **Consumers affected:** `deploy/setup.sh` (agent copy), `README.md` (subagent table), `opencode_app/README.md` (agent listing)
- [ ] **1.2** Write the Prompt Defense Baseline block verbatim from `code-review-subagent.md`
    — **Why:** All subagents share the same security posture; deviations create inconsistency.
    — **Done when:** The 6 bullet points match code-review-subagent.md exactly (diff confirms zero changes).
    — **Consumers affected:** None (internal to subagent).
- [ ] **1.3** Write identity statement, core methodology, 5 workflow steps, screenshot delegation rule, severity rubric, CodeGraph integration, mandatory post-review learning gate, and Return Contract per the locked design spec
    — **Why:** These sections define the subagent's behavior — what it reviews, how it delegates, and how it returns results. The learning gate mirrors code-review-subagent for consistency.
    — **Done when:** All 9 body sections are present; workflow steps include Playwright at 3 breakpoints; severity rubric has 3 tiers (Critical/Major/Minor); Return Contract follows the standard 4-field format; learning gate has the 5-step triage structure.
    — **Consumers affected:** None (internal to subagent).
- [ ] **1.4** Add References section at the bottom with all 5 source repos and license annotations (MIT / PolyForm-NC inspiration-only / Apache 2.0)
    — **Why:** License compliance and attribution — PolyForm-NC is inspiration-only (no code copied), the rest are permissive.
    — **Done when:** All 5 repos listed with correct license tags; PolyForm-NC entry explicitly says "inspiration only — no code copied".
    — **Consumers affected:** None (documentation only).

### Phase 2: Create Skill

- [ ] **2.1** Create directory `opencode_app/.opencode/skills/uiux-review-skill/` and write `SKILL.md` with Section 1: Evidence-first methodology (capture → understanding → review → synthesis → QA gate → report)
    — **Why:** The skill contains the reusable domain knowledge. Evidence-first methodology is the foundational rule that gates all findings.
    — **Done when:** File exists; Section 1 present; includes the explicit gate rule: "Findings without an evidence reference (screenshot + viewport + selector) are rejected at the gate."; **YAML frontmatter validates**: `python3 -c "import yaml; d=open('opencode_app/.opencode/skills/uiux-review-skill/SKILL.md').read(); yaml.safe_load(d.split('---')[1])" && echo OK` exits 0.
    — **Consumers affected:** `uiux-reviewer-subagent.md` (loads this skill), `deploy/setup.sh` (skill copy), `README.md` (skill category).
- [ ] **2.2** Write Section 2: Playwright capture protocol (3 breakpoints, networkidle wait, full-page, a11y snapshot, computed-style extraction, reference to webapp-testing recon-then-action pattern)
    — **Why:** Defines the standardized capture sequence the subagent orchestrates. Ensures consistent evidence across all reviews.
    — **Done when:** All 3 breakpoints specified (1440x900, 768x1024, 375x812); networkidle wait mentioned; full-page and a11y snapshot included; design-token extraction (colors, fonts, spacing, radii, shadows) documented.
    — **Consumers affected:** `uiux-reviewer-subagent.md` (references protocol in workflow steps).
- [ ] **2.3** Write Section 3: 13-axis review rubric (axes 1-6 from AslanMazhidov, axes 7-11 from RNT56, axes 12-13 gap-fills: Nielsen's 10 heuristics + anti-default AI design detection)
    — **Why:** The 13-axis rubric is the core review instrument. Sources are attributed to maintain traceability and avoid license issues.
    — **Done when:** All 13 axes numbered and named; axes 1-6 credit AslanMazhidov; axes 7-11 credit RNT56; axis 12 maps Nielsen's 10 heuristics to concrete DOM/CSS checks; axis 13 flags the 3 AI design clusters (cream+serif, dark+acid-green, broadsheet).
    — **Consumers affected:** `uiux-reviewer-subagent.md` (applies rubric in workflow step 4).
- [ ] **2.4** Write Section 4: Finding schema (structured output with 10 fields: URL/file, viewport, selector, Axis, Observation, Impact, Recommendation, Severity, Evidence, Confidence)
    — **Why:** Standardized finding format ensures machine-parseable output and consistent review reports.
    — **Done when:** All 8+ fields documented with example values; Severity values restricted to Critical/Major/Minor; Confidence values restricted to High/Medium/Low.
    — **Consumers affected:** `uiux-reviewer-subagent.md` (uses schema in synthesis step).
- [ ] **2.5** Write Section 5: Severity rubric table (Critical=BLOCK, Major=WARN, Minor=NOTE with qualification and disposition)
    — **Why:** Severity disposition determines downstream action (must-fix vs defer vs informational).
    — **Done when:** 3-row table with Qualification and Disposition columns; Critical requires "must fix before release".
    — **Consumers affected:** `uiux-reviewer-subagent.md` (references in Return Contract Output).
- [ ] **2.6** Write Section 6: References with all 5 source repos and license annotations
    — **Why:** License compliance; PolyForm-NC marked as inspiration-only.
    — **Done when:** All 5 repos listed with correct licenses; PolyForm-NC explicitly annotated "inspiration only — no code copied".
    — **Consumers affected:** None (documentation only).

### Phase 3: Sync deploy/setup.sh

- [ ] **3.1** Update all **5** count locations in `deploy/setup.sh` (enumerated below — note L2219 was missed in the initial PLAN draft and is the same class of miss documented in PLAN-GIT-234):
    - **L503**: `AGENTS (36):` → `AGENTS (37):`
    - **L587**: `SKILLS (106):` → `SKILLS (107):`
    - **L1665**: `echo "✓ Configured 36 agents:"` → `echo "✓ Configured 37 agents:"`
    - **L2219**: `echo "✓ Configured 36 agents:"` → `echo "✓ Configured 37 agents:"` (the missed occurrence)
    - **L2408**: `echo "                     📦 106 Skills Available"` → `echo "                     📦 107 Skills Available"`
    — **Why:** setup.sh copies agents and skills to user-space — stale counts cause deployment mismatches. The case-sensitive original Done-when (`grep "AGENTS\|SKILLS"`) missed the lowercase `36 agents` echo strings at L1665/L2219/L2408 entirely.
    — **Done when:** Both checks pass:
      (a) `grep -niE "(36 agent|106 skill|35 subagent)" deploy/setup.sh` exits 1 (zero matches — case-insensitive catches all variants).
      (b) `grep -nE "(37 agent|107 skill)" deploy/setup.sh` shows the expected new counts.
    — **Consumers affected:** User-space deployments via `deploy/setup.sh`.
- [ ] **3.2** Verify `setup.sh` copies the new subagent and skill to the correct deploy targets
    — **Why:** Even with correct counts, if the copy logic doesn't cover the new files they won't deploy.
    — **Done when:** The subagent file path matches the existing agent copy glob/pattern; the skill directory matches the existing skill copy glob/pattern.
    — **Consumers affected:** All users running `deploy/setup.sh`.

### Phase 4: Sync deploy/setup.ps1

- [ ] **4.1** Update all 4 count locations in `deploy/setup.ps1`: `AGENTS (36)` → `AGENTS (37)` and `SKILLS (106)` → `SKILLS (107)` (lines ~338, ~383, ~1176, ~1763)
    — **Why:** Windows parity with setup.sh — stale counts on PowerShell break the deployment banner.
    — **Done when:** `grep -n "AGENTS\|SKILLS" deploy/setup.ps1` shows only 37 and 107 respectively; no 36 or 106 remain.
    — **Consumers affected:** Windows users running `deploy/setup.ps1`.
- [ ] **4.2** Verify `setup.ps1` copies the new subagent and skill to the correct deploy targets
    — **Why:** Mirror of step 3.2 — Windows copy logic must also cover the new files.
    — **Done when:** The subagent file path matches the existing agent copy pattern; the skill directory matches the existing skill copy pattern.
    — **Consumers affected:** All Windows users running `deploy/setup.ps1`.

### Phase 5: Sync README.md

- [ ] **5.1** Update subagent count references: `35 subagent` → `36 subagent` (line ~23), `106 skill` → `107 skill` (line ~24), `36 agent` → `37 agent` (line ~308), `106 skills` → `107 skills` (line ~280)
    — **Why:** README is the primary onboarding doc — stale counts confuse contributors.
    — **Done when:** `grep -nE "subagent|agent|skill" README.md` shows updated counts; no 35, 36, or 106 remain in count contexts.
    — **Consumers affected:** All repo consumers and contributors.
- [ ] **5.2** Add new row to the Subagents table: `uiux-reviewer-subagent | UI/UX design review | uiux-review-skill, frontend-design-skill, accessibility-a11y-skill, wireframer-skill | explore, general, image-analyzer-subagent`
    — **Why:** The Subagents table is the quick-reference for what each subagent does and what it can delegate to.
    — **Done when:** Row exists in the table with all 4 columns populated; follows the alphabetical or logical ordering of the existing table.
    — **Consumers affected:** All repo consumers.
- [ ] **5.3** Add `uiux-review-skill` to the appropriate category in the Skill Categories table
    — **Why:** Skills table is the discovery index — missing entries make the skill invisible.
    — **Done when:** `uiux-review-skill` appears in a category (likely "Design & UX" or "Review & Audit") with a description matching the 13-axis rubric scope.
    — **Consumers affected:** All repo consumers.

### Phase 5.5: Sync deploy/.AGENTS.md (user-space routing)

- [ ] **5.5** Sync `deploy/.AGENTS.md` — the user-space routing file deployed to `~/.config/opencode/AGENTS.md`. Without this step, the new subagent is deployed but **never routed to**, defeating its purpose.
    - **5.5a** Add row to the Subagent Routing Preferences table (between the `responsive-audit-subagent` row at L43 and the "All other tasks" row at L44):
      `| UI/UX design review | \`uiux-reviewer-subagent\` | — | 13-axis rubric (6 AslanMazhidov + 5 RNT56 + Nielsen 10 + anti-default AI). Review-only; delegates screenshot analysis to \`image-analyzer-subagent\`. Triggers on "design review", "UI audit", "UX review", "visual review". |`
    - **5.5b** Append `, uiux-reviewer` to the image-analyzer delegable-by list at L79 (currently ends with: `testing, code-review, architecture-review, pr-workflow, ticket-creation, opencode-tooling, responsive-audit`).
    — **Why:** The routing table is the runtime decision matrix the primary agent consults when spawning subagents. The image-analyzer delegation list documents which subagents have `image-analyzer-subagent: allow` in their `task:` permission — the new subagent declares exactly that, so the list is stale without this edit.
    — **Done when:** `grep -n "uiux-reviewer-subagent" deploy/.AGENTS.md` returns ≥2 matches (routing row + image-analyzer list); manual eyeball confirms the new routing row is positioned before "All other tasks".
    — **Consumers affected:** All user-space deployments via `deploy/setup.sh` (which copies this file at L1625/L1629).

### Phase 6: Sync opencode_app/README.md and opencode_app/AGENTS.md

- [ ] **6.1** Update all **3** stale count references in `opencode_app/README.md` (enumerated below — note L102 is a compound update that the original PLAN's vague "audit and update" wording would have missed):
    - **L25**: `├── agents/            # 36 agent .md files (single source of truth)` → `# 37 agent .md files (single source of truth)`
    - **L26**: `└── skills/            # 106 skill directories + scripts/ support + _archived/ legacy` → `# 107 skill directories + scripts/ support + _archived/ legacy`
    - **L102**: `- 23 of 36 agents have explicit \`task\` permissions; the remaining 13 default to full access` → `- 24 of 37 agents have explicit \`task\` permissions; the remaining 13 default to full access`
    — **Why:** Docker standalone README must match the user-space README — divergence causes confusion. The L102 update is **compound**: explicit-perm count grows `23 → 24` because the new agent has an explicit `task: {"*": deny, ...}` block; total grows `36 → 37`; defaulters stay at `13` because both numerator and denominator grew by 1 (`37 − 24 = 13`). The original PLAN's Done-when (`grep ... no stale 35/36/106`) would have caught the stale `36` at L102 but NOT the stale `23` — a partial update (fixing `36→37` but leaving `23`) would silently pass that gate.
    — **Done when:** `grep -nE "23 of 36|36 agent|106 skill" opencode_app/README.md` returns zero matches.
    — **Consumers affected:** Docker standalone users.

- [ ] **6.2** Sync `opencode_app/AGENTS.md` (Docker standalone agent instructions) — add the new subagent to the CodeGraph Subagent Integration table.
    - Add row to the CodeGraph Subagent Integration table (which currently lists 7 subagents: `explorer-subagent`, `code-review-subagent`, `architecture-review-subagent`, `technical-design-specialist-subagent`, `testing-subagent`, `linting-subagent`, `error-resolver-subagent`):
      `| \`uiux-reviewer-subagent\` | \`codegraph_impact\` (change radius before suggesting structural changes), \`codegraph_search\` (component lookup) |`
    — **Why:** The new subagent's body specifies a "CodeGraph integration" section (per step 1.3), meaning it uses CodeGraph at runtime. The Docker AGENTS.md documents which subagents use which CodeGraph tools — missing the new entry leaves Docker users without guidance on its CodeGraph usage.
    — **Done when:** `grep -n "uiux-reviewer-subagent" opencode_app/AGENTS.md` returns ≥1 match.
    — **Consumers affected:** Docker standalone users.

### Phase 7: Verification Gate

- [ ] **7.1** Run verification grep (case-insensitive, expanded scope includes both AGENTS.md files):
    ```bash
    grep -rniE "(3[56] agent|3[56] subagent|106 skill)" deploy/ README.md opencode_app/README.md opencode_app/AGENTS.md
    ```
    Must exit 1 (zero matches). The `-i` flag catches capitalized variants (`36 Agents`, `106 SKILLS`); the character class `3[56]` catches both `35` and `36`; the expanded scope now includes `opencode_app/AGENTS.md` (per step 6.2).
    — **Why:** This is the atomicity gate. Any stale count means a sync file was missed or miscounted. The original regex was case-sensitive (`36 agent|36 agents|106 skill|106 Skills`) and excluded the AGENTS.md files — too narrow.
    — **Done when:** Command exits 1 (no matches). If any hits remain, identify the file and line, and fix before proceeding.
    — **Consumers affected:** All downstream consumers — this is the release quality gate.
- [ ] **7.2** Verify both new files exist and are non-empty: `wc -l opencode_app/.opencode/agents/uiux-reviewer-subagent.md opencode_app/.opencode/skills/uiux-review-skill/SKILL.md`
    — **Why:** Confirms no empty file was accidentally committed.
    — **Done when:** Both files report >0 lines.
    — **Consumers affected:** `deploy/setup.sh` and `deploy/setup.ps1` (copy targets).
