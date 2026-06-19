# PLAN: Add dev→uat→prod branch workflow setup orchestration to framework setup agents

**Issue**: [#218 — Add dev→uat→prod branch workflow setup orchestration to framework setup agents](https://github.com/darellchua2/opencode-config-template/issues/218)
**Branch**: `issue-218`
**Status**: Not Started

---

## Summary

Framework setup subagents (e.g., `nextjs-setup-subagent`) currently scaffold projects but have **zero branch-workflow awareness** — they delegate all git operations to the parent agent and have `bash: deny`. Meanwhile, the repository already contains complete `dev → uat → main` branch workflow knowledge in two skills:

1. **`version-bump-standard-skill`** — execution layer with 11-step onboarding checklist, 4 shell scripts, and 3 GitHub Actions templates
2. **`semantic-release-convention-skill`** — governance layer with tag formats, PR label rules, and release conventions

This plan creates a new **orchestration skill** (`git-branch-workflow-setup-skill`) that bridges the gap: it detects when a branch workflow is needed during project scaffolding, prompts the end user via the `question` tool to configure options, and delegates execution to `repo-ops-specialist-subagent`.

---

## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---------------------|---------------------------|---------------------------------|-------------|
| `git-branch-workflow-setup-skill/SKILL.md` | `version-bump-standard-skill` (execution ref), `semantic-release-convention-skill` (governance ref) | `nextjs-setup-subagent`, `ticket-creation-subagent`, any future framework setup agent | medium |
| `nextjs-setup-subagent.md` | `git-branch-workflow-setup-skill` must exist first | Parent agents invoking nextjs-setup | low |
| `ticket-creation-subagent.md` | `git-branch-workflow-setup-skill` must exist first | Parent agents using full-workflow mode | low |
| `repo-ops-specialist-subagent.md` | No new deps; verify-only | `git-branch-workflow-setup-skill` (delegation target) | low |
| `deploy/setup.sh` | New skill must exist before incrementing count | User-space deploy consumers | low |
| `deploy/setup.ps1` | New skill must exist before incrementing count | Windows deploy consumers | low |
| `README.md` | New skill must exist before table update | Repo consumers reading docs | low |

---

## Implementation Phases

### Phase 1: Create `git-branch-workflow-setup-skill`

- [ ] **1.1** Create directory `opencode_app/.opencode/skills/git-branch-workflow-setup-skill/` and `SKILL.md` with frontmatter (`name`, `description`, `license: Apache-2.0`, `compatibility: opencode`, metadata with `audience: agent` and `workflow: scaffolding` fields)
    — **Why:** Establishes the skill as a first-class member of the skill library with proper metadata for deploy script ingestion.
    — **Done when:** Directory exists and `SKILL.md` has valid frontmatter that `opencode` can parse.
    — **Consumers affected:** `deploy/setup.sh`, `deploy/setup.ps1` (count increment in Phase 4).

- [ ] **1.2** Author the **Detection Logic** section in SKILL.md — define the trigger condition: offer branch workflow setup when `.github/workflows/bump-version-and-push-tag.yml` does not exist in the target project directory
    — **Why:** Without explicit detection criteria, the skill would either always fire (annoying) or never fire (useless). The workflow YAML is the canonical signal that a repo already has the release workflow.
    — **Done when:** SKILL.md documents the detection condition as a clear boolean check (`file_exists(.github/workflows/bump-version-and-push-tag.yml) → skip; not exists → offer`).
    — **Consumers affected:** `nextjs-setup-subagent`, `ticket-creation-subagent` (they call this detection logic).

- [ ] **1.3** Author the **Question Tool Spec** section — write the exact `question` tool JSON payload with 4 options: (1) Standard `dev → uat → main`, (2) Custom branch names, (3) Trunk-based alternative, (4) Skip. Include descriptive text for each option.
    — **Why:** This is the user-facing interaction point. A spec ensures consistent behavior across all framework setup agents that invoke this skill.
    — **Done when:** SKILL.md contains a copy-paste-ready `question` tool JSON block with all 4 options and their descriptions.
    — **Consumers affected:** Any agent that invokes `git-branch-workflow-setup-skill` at scaffold time.

- [ ] **1.4** Author the **Option Matrix** section — document the configurable choices users can make after selecting the standard or custom path: branch names (dev/uat/main or custom), tag format (v-prefix or none), PR workflow toggle (on/off), changelog integration (on/off)
    — **Why:** Users who select "Custom branch names" need a structured input format. The matrix ensures the delegation payload to `repo-ops-specialist-subagent` is complete and typed.
    — **Done when:** SKILL.md has a table or structured list of all configurable parameters with their defaults and valid values.
    — **Consumers affected:** `repo-ops-specialist-subagent` (receives the configuration payload).

- [ ] **1.5** Author the **Delegation Spec** section — define the exact parameters to extract and pass to `repo-ops-specialist-subagent`: onboarding checklist steps from `version-bump-standard-skill`, branch names (from user selection), tag format, CI template selection (which of the 3 YAML templates to deploy)
    — **Why:** Prevents ambiguity when delegating. The execution agent needs a typed payload, not free-form instructions.
    — **Done when:** SKILL.md documents the delegation contract: parameter names, types, defaults, and which `version-bump-standard-skill` checklist steps map to each option.
    — **Consumers affected:** `repo-ops-specialist-subagent` (execution target).

- [ ] **1.6** Author the **Governance References** section — document that this skill defers to `version-bump-standard-skill` for all execution logic and `semantic-release-convention-skill` for tag/label conventions. Include cross-reference links and a note that this skill does NOT duplicate knowledge.
    — **Why:** Prevents knowledge duplication and ensures a single source of truth for release conventions. If governance changes, only the convention skill needs updating.
    — **Done when:** SKILL.md has a "Governance" section with explicit deferral statements and cross-reference links to both skills.
    — **Consumers affected:** `version-bump-standard-skill`, `semantic-release-convention-skill` (governed peers).

- [ ] **1.7** Author the **Cross-Framework Applicability** section — document that the skill is framework-agnostic and can be invoked by `nextjs-setup-subagent`, `python-backend-skill`, or any future framework setup agent. Include invocation examples for 2+ frameworks.
    — **Why:** Without explicit cross-framework documentation, future framework agents may not discover or use this skill, leading to fragmented branch workflow setup patterns.
    — **Done when:** SKILL.md contains a "Compatibility" section listing supported frameworks and an invocation example per framework.
    — **Consumers affected:** Future framework setup agents (e.g., Python, Go, Rust scaffolders).

---

### Phase 2: Enhance Framework Setup Subagents

- [ ] **2.1** Update `opencode_app/.opencode/agents/nextjs-setup-subagent.md` — add a post-scaffold step to the agent's workflow: "After scaffolding, check if `.github/workflows/bump-version-and-push-tag.yml` exists in the target project. If not, return `NEEDS_GIT_BRANCH_SETUP: true` to the parent agent in the return contract."
    — **Why:** This is the primary trigger point. `nextjs-setup-subagent` is the most-used framework setup agent, making it the highest-value integration target.
    — **Done when:** Agent `.md` file documents the post-scaffold detection step and the `NEEDS_GIT_BRANCH_SETUP` return contract field.
    — **Consumers affected:** Parent agents that invoke `nextjs-setup-subagent` (they must handle the return signal).

- [ ] **2.2** Update `opencode_app/.opencode/agents/nextjs-setup-subagent.md` — add `git-branch-workflow-setup-skill` to the `permission.skill` allowlist in the agent frontmatter
    — **Why:** Without this permission, the subagent cannot invoke the skill even if it detects the need.
    — **Done when:** `git-branch-workflow-setup-skill: allow` appears in the skill permissions block.
    — **Consumers affected:** `nextjs-setup-subagent` itself (skill invocation capability).

- [ ] **2.3** Update `opencode_app/.opencode/agents/ticket-creation-subagent.md` — add an optional step: "After full-workflow branch creation, offer branch-workflow setup to the user via `question` tool. If user accepts, invoke `git-branch-workflow-setup-skill` in the target project directory."
    — **Why:** Users creating tickets with full workflow may also want branch workflow setup. This provides a secondary entry point beyond framework scaffolding.
    — **Done when:** Agent `.md` file documents the optional post-branch-creation step with the `question` tool integration.
    — **Consumers affected:** Users invoking `ticket-creation-subagent` in full-workflow mode.

- [ ] **2.4** Update `opencode_app/.opencode/agents/ticket-creation-subagent.md` — add `git-branch-workflow-setup-skill` to the `permission.skill` allowlist
    — **Why:** Without this permission, the ticket-creation subagent cannot invoke the skill when the user accepts the offer.
    — **Done when:** `git-branch-workflow-setup-skill: allow` appears in the skill permissions block.
    — **Consumers affected:** `ticket-creation-subagent` itself (skill invocation capability).

---

### Phase 3: Verify Execution Agent

- [ ] **3.1** Read `opencode_app/.opencode/agents/repo-ops-specialist-subagent.md` and verify it has `bash: allow` in its tool permissions
    — **Why:** The execution agent must be able to run shell commands (git branch creation, gh api calls for branch protection) to fulfill the delegation payload.
    — **Done when:** Confirmed `bash: allow` exists in the agent's frontmatter permissions block.
    — **Consumers affected:** `git-branch-workflow-setup-skill` (delegation target must have execution capability).

- [ ] **3.2** Verify `repo-ops-specialist-subagent.md` permits `version-bump-standard-skill` and `semantic-release-convention-skill` in its `permission.skill` allowlist
    — **Why:** These are the execution and governance skills that `repo-ops-specialist-subagent` must invoke to complete the branch workflow setup. Without permissions, delegation fails silently.
    — **Done when:** Both skills appear in the allowlist, or gaps are documented for fix.
    — **Consumers affected:** `git-branch-workflow-setup-skill` (relies on repo-ops invoking these governed skills).

- [ ] **3.3** Verify `repo-ops-specialist-subagent.md` documents the `dev → uat → main` flow in its expertise/trigger section, and confirm it is invokable at project-setup time (trigger phrases include scaffold/setup context, not just "repo setup")
    — **Why:** If the agent only triggers on "repo setup" phrases but not "scaffold" or "project setup," the delegation from framework agents will fail because the parent won't know to invoke repo-ops.
    — **Done when:** Trigger section includes scaffold/setup phrases, or gaps are documented for fix.
    — **Consumers affected:** `git-branch-workflow-setup-skill` (delegation target must be reachable at scaffold time).

- [ ] **3.4** If any gaps found in 3.1-3.3, update `repo-ops-specialist-subagent.md` to fix them (add missing permissions, trigger phrases, or documentation)
    — **Why:** Ensures the delegation chain is complete: framework agent → git-branch-workflow-setup-skill → repo-ops-specialist-subagent → version-bump-standard-skill.
    — **Done when:** All gaps resolved or confirmed as no-op (no changes needed).
    — **Consumers affected:** `git-branch-workflow-setup-skill`, `nextjs-setup-subagent`, `ticket-creation-subagent`.

---

### Phase 4: Documentation Sync (MANDATORY per AGENTS.md)

- [ ] **4.1** Update `deploy/setup.sh` — add `git-branch-workflow-setup-skill` to the Git/GitHub category listing and increment total skill count from 79 to 80
    — **Why:** User-space deploy must include the new skill; AGENTS.md mandates count synchronization as a mandatory sync trigger when adding new skills.
    — **Done when:** Skill appears in the Git/GitHub category; total count reads 80; no other counts are changed.
    — **Consumers affected:** All users running `./deploy/setup.sh`.

- [ ] **4.2** Update `deploy/setup.ps1` — add `git-branch-workflow-setup-skill` to the Git/GitHub category listing and increment total skill count from 79 to 80
    — **Why:** Windows deploy parity with setup.sh; AGENTS.md mandates both scripts stay synchronized.
    — **Done when:** Skill appears in the Git/GitHub category; total count reads 80.
    — **Consumers affected:** All users running `deploy/setup.ps1`.

- [ ] **4.3** Update `README.md` — add `git-branch-workflow-setup-skill` to the Skill Categories table under the Git/GitHub category
    — **Why:** Discoverability for repo consumers browsing the README; AGENTS.md lists README.md as a mandatory sync target.
    — **Done when:** Row added to the Skill Categories table with correct name, description, and category.
    — **Consumers affected:** Repo consumers reading README.md.

- [ ] **4.4** Check if `opencode_app/README.md` lists skills; if so, add `git-branch-workflow-setup-skill` to the appropriate section
    — **Why:** AGENTS.md lists `opencode_app/README.md` as a sync target "if applicable." Docker-mode consumers need discoverability too.
    — **Done when:** Verified and updated, or confirmed not applicable (Docker README doesn't list individual skills).
    — **Consumers affected:** Docker-mode consumers.

- [ ] **4.5** Cross-verify all counts: `deploy/setup.sh`, `deploy/setup.ps1`, and `README.md` skill count must all read 80
    — **Why:** Count drift breaks the `documentation-consistency-skill` audit and violates AGENTS.md mandatory sync triggers.
    — **Done when:** All three files show 80 skills with no drift.
    — **Consumers affected:** All deploy and documentation consumers.

---

## Acceptance Criteria

1.  New skill `git-branch-workflow-setup-skill` exists at `opencode_app/.opencode/skills/git-branch-workflow-setup-skill/SKILL.md` with detection logic + question tool spec + delegation spec + governance references
2.  `nextjs-setup-subagent` signals `NEEDS_GIT_BRANCH_SETUP: true` after scaffolding when branch workflow is missing
3.  `ticket-creation-subagent` optionally offers branch-workflow setup during full-workflow
4.  `repo-ops-specialist-subagent` confirmed as execution agent with `bash: allow` + skill permissions + scaffold trigger phrases
5.  Deploy scripts (`setup.sh`, `setup.ps1`) updated with new skill count (80) and category listing
6.  `README.md` Skill Categories table updated
7.  All counts synchronized across all 3 files (no drift)

---

## Related Files

| File | Action | Phase |
|------|--------|-------|
| `opencode_app/.opencode/skills/git-branch-workflow-setup-skill/SKILL.md` | Create | 1 |
| `opencode_app/.opencode/agents/nextjs-setup-subagent.md` | Update | 2 |
| `opencode_app/.opencode/agents/ticket-creation-subagent.md` | Update | 2 |
| `opencode_app/.opencode/agents/repo-ops-specialist-subagent.md` | Verify/Update | 3 |
| `deploy/setup.sh` | Update | 4 |
| `deploy/setup.ps1` | Update | 4 |
| `README.md` | Update | 4 |
| `opencode_app/README.md` | Update (if applicable) | 4 |

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
| New skill duplicates knowledge from `version-bump-standard-skill` | Phase 1.6 enforces governance deferral; skill only orchestrates, never duplicates |
| `repo-ops-specialist-subagent` missing permissions for scaffold-time invocation | Phase 3 verifies all 3 prerequisites (bash, skill permissions, trigger phrases) before proceeding |
| Deploy count drift across setup.sh / setup.ps1 / README.md | Phase 4.5 cross-verifies all 3 counts; AGENTS.md mandates sync as a mandatory trigger |
| `question` tool prompt too intrusive during scaffolding | Detection logic (Phase 1.2) gates the prompt — only fires when workflow YAML is missing |
| Framework agents don't return `NEEDS_GIT_BRANCH_SETUP` signal | Phase 2 explicitly adds the return contract field to the agent `.md` files with examples |

---

*Tracking progress with ticket-plan-workflow-skill*
