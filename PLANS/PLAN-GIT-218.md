# PLAN: Add dev→uat→prod branch workflow setup orchestration to framework setup agents

**Issue**: [#218 — Add dev→uat→prod branch workflow setup orchestration to framework setup agents](https://github.com/darellchua2/opencode-config-template/issues/218)
**Branch**: `issue-218`
**Status**: Not Started
**Revision**: v2 — incorporates architecture-review findings (ISSUE-1 through ISSUE-12)

---

## Summary

Framework setup subagents (e.g., `nextjs-setup-subagent`) currently scaffold projects but have **zero branch-workflow awareness** — they delegate all git operations to the parent agent and have `bash: deny`. Meanwhile, the repository already contains complete `dev → uat → main` branch workflow knowledge in two skills:

1. **`version-bump-standard-skill`** — execution layer with 11-step onboarding checklist, 4 shell scripts, and 3 GitHub Actions templates
2. **`semantic-release-convention-skill`** — governance layer with tag formats, PR label rules, and release conventions

This plan creates a new **orchestration skill** (`git-branch-workflow-setup-skill`) that bridges the gap: it detects when a branch workflow is needed during project scaffolding, prompts the end user via the `question` tool to configure options, and delegates execution to `repo-ops-specialist-subagent`.

### Architecture (revised per review)

The orchestration follows **hub-and-spoke** through the primary agent — no subagent spawns another subagent for this flow:

```
Primary agent (build) invokes nextjs-setup-subagent
  → nextjs-setup scaffolds project
  → nextjs-setup checks for release-workflow files (via read/glob — bash:deny)
  → if missing: returns NEEDS_GIT_BRANCH_SETUP: true in Return Contract
Primary agent receives signal
  → loads git-branch-workflow-setup-skill (extract-then-delegate)
  → uses question tool to prompt user (with non-interactive fallback → Skip)
  → if user accepts: delegates to repo-ops-specialist-subagent with typed payload
  → repo-ops loads version-bump-standard-skill + semantic-release-convention-skill
  → repo-ops executes onboarding checklist (scripts, workflows, labels, protection)
```

**Key principle:** Setup subagents only *signal*; the primary agent *orchestrates*; `repo-ops-specialist` *executes*. This complies with the extract-then-delegate pattern and avoids requiring any subagent to spawn `repo-ops-specialist-subagent`.

---

## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---------------------|---------------------------|---------------------------------|-------------|
| `repo-ops-specialist-subagent.md` | No new deps; verify + add scaffold trigger phrases (Phase 0) | Primary agent (delegation target) | low |
| `deploy/.AGENTS.md` | Phase 0 (repo-ops reachable) | `build` primary agent (signal consumer) | medium |
| `git-branch-workflow-setup-skill/SKILL.md` | `version-bump-standard-skill` (execution ref), `semantic-release-convention-skill` (governance ref) | Primary agent (loads it); `deploy/setup.sh`, `deploy/setup.ps1` (count) | medium |
| `nextjs-setup-subagent.md` | Skill must exist for primary to load; agent only signals | Primary agents invoking nextjs-setup | low |
| `ticket-creation-subagent.md` | Skill must exist for primary to load; agent only signals | Primary agents using full-workflow mode | low |
| `deploy/setup.sh` | New skill must exist before incrementing count | User-space deploy consumers | low |
| `deploy/setup.ps1` | New skill must exist before incrementing count | Windows deploy consumers | low |
| `README.md` | New skill must exist before table update | Repo consumers reading docs | low |

---

## Implementation Phases

### Phase 0: Pre-flight Verification & Execution Agent Readiness

> **Why first (ISSUE-7):** If `repo-ops-specialist-subagent` cannot fulfill the delegation, Phases 1-2 build dependencies on an unfulfillable execution path. Verify and fix the executor before creating dependents.

- [ ] **0.1** Read `opencode_app/.opencode/agents/repo-ops-specialist-subagent.md` and verify it has `bash: allow` in its tool permissions
    — **Why:** The execution agent must run shell commands (git branch creation, `gh api` for branch protection) to fulfill the delegation payload.
    — **Done when:** Confirmed `bash: allow` exists (verified at line 10 — **PASS, no change needed**).
    — **Consumers affected:** `git-branch-workflow-setup-skill` (delegation target must have execution capability).

- [ ] **0.2** Verify `repo-ops-specialist-subagent.md` permits `version-bump-standard-skill` and `semantic-release-convention-skill` in its `permission.skill` allowlist
    — **Why:** These are the execution and governance skills the executor must invoke. Without permissions, delegation fails silently.
    — **Done when:** Both skills appear in the allowlist (verified at lines 16-17 — **PASS, no change needed**).
    — **Consumers affected:** `git-branch-workflow-setup-skill` (relies on repo-ops invoking these governed skills).

- [ ] **0.3** **GAP FIX:** Update `repo-ops-specialist-subagent.md` Trigger Phrases section (lines 47-55) to add scaffold-time triggers: `"project setup"`, `"scaffold setup"`, `"new project setup"`, and `"branch workflow setup"`
    — **Why (ISSUE-7):** The current trigger section includes `"repo setup"`, `"branch protection"`, `"release workflow"` etc. but NOT `"scaffold"` or `"project setup"`. When the primary agent needs to delegate branch-workflow execution at scaffold time, it must recognize `repo-ops-specialist` as the right agent. Adding these phrases ensures discoverability. Also add `git-branch-workflow-setup-skill: allow` to its `permission.skill` block so it can load the orchestration spec if needed.
    — **Done when:** Trigger Phrases include at least `"project setup"` and `"branch workflow setup"`; `git-branch-workflow-setup-skill` appears in the skill allowlist (Phase 1 creates the skill, but the permission entry can be added now since it's a no-op until the skill exists).
    — **Consumers affected:** Primary agent (must route to repo-ops at scaffold time).

---

### Phase 1: Create `git-branch-workflow-setup-skill`

- [ ] **1.1** Create directory `opencode_app/.opencode/skills/git-branch-workflow-setup-skill/` and `SKILL.md` with frontmatter (`name`, `description`, `license: Apache-2.0`, `compatibility: opencode`, metadata with `audience: agent` and `workflow: scaffolding` fields)
    — **Why:** Establishes the skill as a first-class member of the skill library with proper metadata for deploy script ingestion.
    — **Done when:** Directory exists and `SKILL.md` has valid frontmatter that `opencode` can parse.
    — **Consumers affected:** `deploy/setup.sh`, `deploy/setup.ps1` (count increment in Phase 3).

- [ ] **1.2** Author the **Detection Logic** section in SKILL.md — define the trigger condition as a broadened check (ISSUE-12): offer branch workflow setup when NONE of the following exist in the target project: `.github/workflows/bump-version-and-push-tag.yml`, any `.github/workflows/*release*`, any `.github/workflows/*semantic*`, `.releaserc*`, `release-please-config.json`, or `.changeset/`. Only the absence of ALL signals should trigger the offer.
    — **Why (ISSUE-12):** Checking only for `bump-version-and-push-tag.yml` is brittle — a project using semantic-release, release-please, or changesets won't have that file and would be offered a conflicting CanvasTekk workflow. Broadening detection prevents clobbering existing release tooling.
    — **Done when:** SKILL.md documents the detection condition as a clear multi-file boolean check with the full signal list, and the inverse (any signal present → skip).
    — **Consumers affected:** Primary agent (performs detection before prompting); `nextjs-setup-subagent`, `ticket-creation-subagent` (return the signal that triggers detection).

- [ ] **1.3** Author the **Question Tool Spec** section — write the exact `question` tool JSON payload with 4 options: (1) Standard `dev → uat → main`, (2) Custom branch names, (3) Trunk-based alternative, (4) Skip. Include descriptive text for each option. **Additionally (ISSUE-6):** document a non-interactive fallback — "If the `question` tool is unavailable, times out, or the context is non-interactive (CI, Docker batch), default to option (4) Skip and emit a warning. Never block the scaffolding flow."
    — **Why (ISSUE-6):** This configurator supports Docker standalone mode (web endpoint) and CI contexts where no user can answer interactively. Without a fallback, the flow hangs. The question tool is the user-facing interaction point; a spec ensures consistent behavior.
    — **Done when:** SKILL.md contains a copy-paste-ready `question` tool JSON block with all 4 options, their descriptions, AND a "Non-Interactive Fallback" subsection documenting the Skip default + warning behavior.
    — **Consumers affected:** Primary agent (invokes the question tool or applies the fallback).

- [ ] **1.4** Author the **Option Matrix** section — document the configurable choices as **cross-references** (ISSUE-5), NOT inline values: branch names (default `dev`/`uat`/`main` — see `version-bump-standard-skill` §Branch Flow), tag format (see `semantic-release-convention-skill` §Tag Mapping), PR workflow toggle (on/off), changelog integration (on/off — see `semantic-release-convention-skill` §Changelog). Each parameter's default and valid values must be expressed as `"see <skill> §<section>"` references.
    — **Why (ISSUE-5):** If defaults are inlined (e.g., "tag format defaults to `vX.Y.Z`"), that duplicates governance knowledge from `semantic-release-convention-skill`. Cross-references preserve a single source of truth.
    — **Done when:** SKILL.md has a table of configurable parameters where every default/valid-value cell is a cross-reference to the governing skill, with ZERO inline convention values.
    — **Consumers affected:** `repo-ops-specialist-subagent` (receives the configuration payload).

- [ ] **1.5** Author the **Delegation Spec** section — define the exact parameters to extract and pass to `repo-ops-specialist-subagent`: selected option, branch names (from user selection), tag format reference, CI template selection (which of the 3 YAML templates to deploy — by template filename, not content), and the onboarding checklist reference (point to `version-bump-standard-skill` §Onboarding Checklist, do NOT copy the steps).
    — **Why:** Prevents ambiguity when delegating. The execution agent needs a typed payload referencing the execution skill's sections, not free-form or duplicated instructions.
    — **Done when:** SKILL.md documents the delegation contract: parameter names, types, and section-references into `version-bump-standard-skill`. Contains ZERO copied checklist steps, ZERO inline YAML.
    — **Consumers affected:** `repo-ops-specialist-subagent` (execution target).

- [ ] **1.6** Author the **Governance References** section — document that this skill **defers** (not "enforces" — ISSUE-5) to `version-bump-standard-skill` for all execution logic and `semantic-release-convention-skill` for tag/label conventions. State an explicit content rule: "This skill MUST contain ZERO inline YAML templates, ZERO bash scripts, and ZERO label hex colors — all must be cross-references to the governing skills." Include cross-reference links.
    — **Why (ISSUE-5):** The original plan claimed to "enforce" deferral, but prose cannot mechanically prevent duplication. Making the constraint an explicit content rule with concrete prohibitions (no YAML, no scripts, no hex) gives the author and reviewers an auditable checklist. If governance changes, only the convention skill needs updating.
    — **Done when:** SKILL.md has a "Governance" section with explicit deferral statements, the zero-inline content rule, and cross-reference links to both skills.
    — **Consumers affected:** `version-bump-standard-skill`, `semantic-release-convention-skill` (governed peers).

- [ ] **1.7** Author the **Compatibility** section — document that this skill is invocable by any framework **setup agent** (not skill — ISSUE-4). Acknowledge that `nextjs-setup-subagent` is currently the **only** framework setup agent. Document the standard invocation pattern for future setup agents (e.g., a future `python-setup-subagent` or `go-setup-subagent`) to follow: "After scaffolding, check detection signals; if absent, return `NEEDS_GIT_BRANCH_SETUP: true`." Include one concrete invocation example (`nextjs-setup-subagent`).
    — **Why (ISSUE-4):** The original plan conflated skills (knowledge documents loaded BY agents) with agents (which can use tools/spawn subagents). `python-backend-skill` is a skill — it cannot invoke this skill or use the `question` tool. Only setup *agents* can. There are no other setup agents today, so the cross-framework claim must be reframed as a pattern for the future, not a validated multi-framework capability.
    — **Done when:** SKILL.md "Compatibility" section references setup *agents* only, acknowledges `nextjs-setup-subagent` as the sole current consumer, and provides a future-agent invocation template. `python-backend-skill` and other skills are NOT listed as consumers.
    — **Consumers affected:** Future framework setup agents (when created).

- [ ] **1.8** Author the **Skip-State Persistence** subsection (within Detection Logic or as its own section) — when the user selects "Skip", write a marker to prevent re-prompting: a `.opencode/branch-workflow-skipped` marker file OR a key in the project's opencode config. Document that future detection checks must look for this marker and suppress the prompt if present.
    — **Why (ISSUE-11):** Without persistence, a user who scaffolds a project and selects "Skip" will be re-prompted every time a setup agent runs (e.g., ticket-creation full-workflow). The marker ensures a one-time decision.
    — **Done when:** SKILL.md documents the marker file path, format, and the detection-update (check marker before offering).
    — **Consumers affected:** All agents that trigger detection (`nextjs-setup-subagent`, `ticket-creation-subagent`).

---

### Phase 2: Wire the Signal — Primary Agent + Framework Setup Subagents

> **Architecture note (ISSUE-1, ISSUE-2, ISSUE-3):** The primary agent (`build`) is the orchestration hub. Setup subagents only *signal*; they do NOT load the skill or spawn `repo-ops-specialist`. This complies with extract-then-delegate and avoids permission gaps.

- [ ] **2.1** **[CRITICAL — ISSUE-1]** Update `deploy/.AGENTS.md` — add a new section "## Branch Workflow Setup Signal" (after Subagent Routing Preferences) documenting: "When any subagent returns `NEEDS_GIT_BRANCH_SETUP: true` in its Return Contract, load `git-branch-workflow-setup-skill`, perform detection, and if triggered use the `question` tool (or non-interactive fallback) to prompt the user. If the user accepts, delegate execution to `repo-ops-specialist-subagent` with the typed payload from the skill's Delegation Spec."
    — **Why (ISSUE-1):** The `build` agent (config.json line 273) has `task: {"*":"allow"}` but receives behavioral instructions from `deploy/.AGENTS.md`. Without this section, the primary agent receives `NEEDS_GIT_BRANCH_SETUP: true` and has no instructions to act on it — the signal is produced with no consumer.
    — **Done when:** `deploy/.AGENTS.md` contains the "Branch Workflow Setup Signal" section with the full handling procedure.
    — **Consumers affected:** `build` primary agent (the signal consumer).

- [ ] **2.2** **[CRITICAL — ISSUE-1]** Mirror the signal-handling instructions in the repo-level `AGENTS.md` (root) — add the same "Branch Workflow Setup Signal" guidance to the routing/instructions so both deployed (`deploy/.AGENTS.md`) and repo-level contexts stay consistent.
    — **Why (ISSUE-1):** The repo `AGENTS.md` is the source of truth for repo-level work; `deploy/.AGENTS.md` is the deployed copy. Both must describe the signal handler to avoid drift.
    — **Done when:** Root `AGENTS.md` contains equivalent signal-handling guidance.
    — **Consumers affected:** Primary agent in repo-level context.

- [ ] **2.3** **[ISSUE-10]** Update the "Return Contract Convention" section in root `AGENTS.md` (and `deploy/.AGENTS.md` if it documents the convention) to describe optional signal fields: "`NEEDS_GIT_BRANCH_SETUP: true` is an accepted optional extension to the Return Contract, signaling that the primary agent should offer branch-workflow setup. Optional signal fields are additive and do not alter the required Status/Output/Summary/Issues fields."
    — **Why (ISSUE-10):** The repo documents a standardized return contract. Introducing a new signal field without documenting it as an accepted extension pattern creates ambiguity for future agent authors.
    — **Done when:** Return Contract Convention section documents optional signal fields with `NEEDS_GIT_BRANCH_SETUP` as the example.
    — **Consumers affected:** All subagent authors.

- [ ] **2.4** Update `opencode_app/.opencode/agents/nextjs-setup-subagent.md` — add a post-scaffold step to the workflow: "After scaffolding, use `glob`/`read` (not bash — agent has `bash: deny`) to check the detection signals from `git-branch-workflow-setup-skill` §Detection Logic. If all absent, include `NEEDS_GIT_BRANCH_SETUP: true` in the Return Contract." Do NOT add the skill to `permission.skill` (ISSUE-3).
    — **Why:** nextjs-setup is the primary trigger point. It has `read: allow`, `glob: allow`, `grep: allow` (lines 6-9) so it CAN check file existence without bash. It signals the parent; the parent owns skill loading (extract-then-delegate).
    — **Done when:** Agent `.md` documents the post-scaffold detection step and the `NEEDS_GIT_BRANCH_SETUP` return field. **`git-branch-workflow-setup-skill` is NOT in the skill allowlist** (ISSUE-3 — removed from original plan).
    — **Consumers affected:** Primary agent (handles the signal per 2.1).

- [ ] **2.5** **[CRITICAL — ISSUE-2]** Update `opencode_app/.opencode/agents/ticket-creation-subagent.md` — add an optional step: "After full-workflow branch creation, check detection signals. If all absent AND no `.opencode/branch-workflow-skipped` marker, return `NEEDS_GIT_BRANCH_SETUP: true` to the primary agent." Do NOT have ticket-creation invoke the skill or spawn `repo-ops-specialist` directly — it has `task: {"*": deny}` and cannot spawn repo-ops (ISSUE-2).
    — **Why (ISSUE-2):** ticket-creation-subagent's frontmatter specifies `task: {"*": deny, architecture-review-subagent: allow, explore: allow}`. `repo-ops-specialist-subagent` is NOT allowed. The original plan's "invoke the skill in the target project" would require spawning repo-ops, which is denied. Returning the signal to the primary agent (same pattern as nextjs-setup) is the architecturally consistent fix.
    — **Done when:** Agent `.md` documents the optional post-branch-creation signal return. **`git-branch-workflow-setup-skill` is NOT added to skill allowlist** (not needed — agent only signals). **No `task` permission changes** (deny-by-default posture preserved).
    — **Consumers affected:** Primary agent (handles the signal per 2.1).

---

### Phase 3: Documentation Sync (MANDATORY per AGENTS.md)

- [ ] **3.1** **[ISSUE-8, ISSUE-9]** Update `deploy/setup.sh` — add `git-branch-workflow-setup-skill` to the **Git/Workflow** category listing (NOT "Git/GitHub" — ISSUE-8), and fix pre-existing count drift: the listing at line 612 already shows `Git/Workflow (11)` with 11 items, but the banner (line 2263) and summary (line 2359) say `Git/Workflow (10)`. After adding the new skill: listing becomes 12, and banner/summary must be updated to `Git/Workflow (12)`.
    — **Why (ISSUE-8, ISSUE-9):** The correct category name is "Git/Workflow" (confirmed at setup.sh line 612, README.md line 291). The banner/summary have a pre-existing drift (10 vs 11). Adding the skill to 12 while fixing drift ensures consistency.
    — **Done when:** Skill appears in Git/Workflow category listing; line 612 count is 12; lines 2263 and 2359 updated to `Git/Workflow (12)`.
    — **Consumers affected:** All users running `./deploy/setup.sh`.

- [ ] **3.2** **[ISSUE-8, ISSUE-9]** Update `deploy/setup.ps1` — add `git-branch-workflow-setup-skill` to the **Git/Workflow** category listing, and fix pre-existing drift: line 405 listing says `Git/Workflow (10)` (drift — should match README's 11), line 1250 banner says `Git/Workflow (11)`, line 1729 summary says `Git/Workflow (10)`. After adding the new skill: all three must read `Git/Workflow (12)`.
    — **Why:** Windows deploy parity with setup.sh; fix existing drift.
    — **Done when:** Skill appears in Git/Workflow category; lines 405, 1250, and 1729 all read `Git/Workflow (12)`.
    — **Consumers affected:** All users running `deploy/setup.ps1`.

- [ ] **3.3** **[ISSUE-9]** Update total skill counts in both deploy scripts to match reality. Current actual directories: **81**; deploy scripts say **79** (pre-existing drift of +2). After adding the new skill: **82** directories. Update: `setup.sh` line 586 `SKILLS (79)` → `SKILLS (82)` and line 2355 `79 Skills Available` → `82 Skills Available`; `setup.ps1` line 382 `SKILLS (79)` → `SKILLS (82)` and line 1725 `79 Skills Available` → `82 Skills Available`.
    — **Why (ISSUE-9):** The total count was already wrong (79 declared vs 81 actual). This plan adds 1 skill (→82) and corrects the pre-existing drift in the same pass.
    — **Done when:** Both deploy scripts declare 82 skills total in all count locations.
    — **Consumers affected:** All deploy consumers.

- [ ] **3.4** Update `README.md` — add `git-branch-workflow-setup-skill` to the Skill Categories table under **Git/Workflow** (line 291), incrementing the category count from 11 to 12. Update any total skill count in README if present.
    — **Why:** Discoverability for repo consumers; AGENTS.md lists README.md as a mandatory sync target.
    — **Done when:** Row added to the Skill Categories table; Git/Workflow count reads 12.
    — **Consumers affected:** Repo consumers reading README.md.

- [ ] **3.5** Check if `opencode_app/README.md` lists skills; if so, add `git-branch-workflow-setup-skill` to the appropriate section
    — **Why:** AGENTS.md lists `opencode_app/README.md` as a sync target "if applicable." Docker-mode consumers need discoverability too.
    — **Done when:** Verified and updated, or confirmed not applicable (Docker README doesn't list individual skills).
    — **Consumers affected:** Docker-mode consumers.

- [ ] **3.6** Cross-verify all counts: `deploy/setup.sh` (82), `deploy/setup.ps1` (82), `README.md` (Git/Workflow 12), and actual directories (82). All must agree with no drift.
    — **Why:** Count drift breaks the `documentation-consistency-skill` audit and violates AGENTS.md mandatory sync triggers.
    — **Done when:** All files show 82 total skills and Git/Workflow 12, matching the actual directory count.
    — **Consumers affected:** All deploy and documentation consumers.

---

## Acceptance Criteria

1.  New skill `git-branch-workflow-setup-skill` exists with: broadened detection logic (ISSUE-12), question tool spec + non-interactive fallback (ISSUE-6), option matrix with cross-references only (ISSUE-5), delegation spec with zero inline YAML/scripts, governance deferral with zero-inline content rule (ISSUE-5), corrected compatibility section referencing agents not skills (ISSUE-4), and skip-state persistence (ISSUE-11)
2.  `repo-ops-specialist-subagent` trigger phrases include scaffold/project-setup context (ISSUE-7); `bash: allow` and both governance skills confirmed (Phase 0)
3.  Primary agent (`build`) has documented signal-handling instructions in `deploy/.AGENTS.md` AND root `AGENTS.md` (ISSUE-1)
4.  `nextjs-setup-subagent` returns `NEEDS_GIT_BRANCH_SETUP: true` via glob/read detection; skill NOT in its permission.skill (ISSUE-3)
5.  `ticket-creation-subagent` returns the signal to primary (does NOT spawn repo-ops — ISSUE-2); `task` permissions unchanged
6.  Return Contract Convention documents optional signal fields (ISSUE-10)
7.  Deploy scripts (`setup.sh`, `setup.ps1`) updated: Git/Workflow category (ISSUE-8), total count 82 with pre-existing drift fixed (ISSUE-9)
8.  `README.md` Skill Categories table updated (Git/Workflow 12)
9.  All counts synchronized across deploy scripts, README, and actual directories (no drift)

---

## Related Files

| File | Action | Phase |
|------|--------|-------|
| `opencode_app/.opencode/agents/repo-ops-specialist-subagent.md` | Update (trigger phrases + skill perm) | 0 |
| `opencode_app/.opencode/skills/git-branch-workflow-setup-skill/SKILL.md` | Create | 1 |
| `deploy/.AGENTS.md` | Update (signal handler + return contract) | 2 |
| `AGENTS.md` (root) | Update (signal handler + return contract) | 2 |
| `opencode_app/.opencode/agents/nextjs-setup-subagent.md` | Update (signal return only) | 2 |
| `opencode_app/.opencode/agents/ticket-creation-subagent.md` | Update (signal return only) | 2 |
| `deploy/setup.sh` | Update (category + counts + drift fix) | 3 |
| `deploy/setup.ps1` | Update (category + counts + drift fix) | 3 |
| `README.md` | Update (skill table) | 3 |
| `opencode_app/README.md` | Update (if applicable) | 3 |

---

## References

- **Execution knowledge:** `version-bump-standard-skill` — 11-step onboarding checklist, 4 shell scripts (`onboard-repo.sh`, `audit-repo.sh`, `setup-branch-protection.sh`, `create-labels.sh`), 3 GitHub Actions templates
- **Governance knowledge:** `semantic-release-convention-skill` — tag formats (`vX.Y.Z`), PR label rules (`major`/`minor`/`patch`), branch-aware release tagging, changelog generation standards
- **Documentation sync rules:** `AGENTS.md` → "Adding New Subagents or Skills" section with mandatory sync triggers
- **Related issue:** [#216](https://github.com/darellchua2/opencode-config-template/issues/216) — built out `version-bump-standard-skill` with workflow templates and onboarding scripts

---

## Risks & Mitigation

| Risk | Mitigation |
|------|------------|
| New skill duplicates knowledge from `version-bump-standard-skill` | Phase 1.6 establishes a zero-inline content rule (no YAML, no scripts, no hex colors); Phase 1.4-1.5 require cross-references only (ISSUE-5) |
| `repo-ops-specialist-subagent` missing scaffold-time triggers | Phase 0.3 adds trigger phrases before any dependent is built (ISSUE-7) |
| `NEEDS_GIT_BRANCH_SETUP` signal has no consumer | Phase 2.1-2.2 wire the primary agent handler in both `deploy/.AGENTS.md` and root `AGENTS.md` (ISSUE-1) |
| `ticket-creation-subagent` cannot spawn `repo-ops-specialist` | Phase 2.5 uses signal-return pattern instead of direct invocation; no `task` permission change (ISSUE-2) |
| Deploy count drift across setup.sh / setup.ps1 / README.md | Phase 3.6 cross-verifies all counts to 82; Phase 3.1-3.3 fix pre-existing drift (ISSUE-9) |
| `question` tool prompt too intrusive or blocks in non-interactive contexts | Detection logic (Phase 1.2) gates the prompt; non-interactive fallback defaults to Skip (Phase 1.3, ISSUE-6) |
| User re-prompted after selecting Skip | Phase 1.8 persists skip decision via marker file (ISSUE-11) |
| Detection conflicts with existing release tooling | Phase 1.2 broadened detection checks for any release workflow/tool, not just CanvasTekk's (ISSUE-12) |

---

## Architecture Review Issues Addressed

| Issue | Severity | Phase | Resolution |
|-------|----------|-------|------------|
| ISSUE-1: No primary agent signal consumer | Critical | 2.1, 2.2 | Added signal handler to `deploy/.AGENTS.md` + root `AGENTS.md` |
| ISSUE-2: ticket-creation cannot spawn repo-ops | Critical | 2.5 | Changed to signal-return pattern; no task perm change |
| ISSUE-3: Contradictory skill permission in nextjs-setup | Major | 2.4 | Removed — skill NOT added to nextjs-setup permission.skill |
| ISSUE-4: Skills-vs-agents confusion | Major | 1.7 | Rewrote to reference setup agents only; python-backend-skill removed |
| ISSUE-5: Governance deferral aspirational | Major | 1.4, 1.5, 1.6 | Zero-inline content rule + cross-references only |
| ISSUE-6: No non-interactive fallback | Major | 1.3 | Skip default + warning when question tool unavailable |
| ISSUE-7: Phase ordering (verify before dependents) | Major | Phase 0 | Moved verification to Phase 0; trigger phrase gap fixed |
| ISSUE-8: Category name "Git/GitHub" | Minor | 3.1, 3.2 | Corrected to "Git/Workflow" |
| ISSUE-9: Pre-existing count drift | Minor | 3.1-3.3 | Fixed Git/Workflow (10→12) and total (79→82) |
| ISSUE-10: Return contract extension undocumented | Minor | 2.3 | Documented optional signal fields in AGENTS.md |
| ISSUE-11: No skip-state persistence | Minor | 1.8 | Marker file `.opencode/branch-workflow-skipped` |
| ISSUE-12: Detection signal brittleness | Minor | 1.2 | Broadened to check any release tool/workflow |

---

*Tracking progress with ticket-plan-workflow-skill*
