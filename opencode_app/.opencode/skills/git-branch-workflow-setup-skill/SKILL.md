---
name: git-branch-workflow-setup-skill
description: Orchestrate dev→uat→main branch workflow setup during project initialization. Detects when release branch structure is needed, prompts the end user via the question tool for configuration choices, and delegates execution to repo-ops-specialist-subagent. Centralizes branch-workflow decision-making for all framework setup agents.
license: Apache-2.0
compatibility: opencode
metadata:
  audience: agent
  workflow: scaffolding
---

## What I do

I am an **orchestration skill** — I do NOT execute branch setup myself. I provide the primary agent with:

1. **Detection logic** — when to offer branch-workflow setup
2. **Question tool spec** — the exact prompt to present to the user
3. **Option matrix** — what the user can configure (as cross-references)
4. **Delegation spec** — the typed payload to pass to `repo-ops-specialist-subagent`

The primary agent loads me, extracts these parameters, prompts the user, then delegates execution to `repo-ops-specialist-subagent` (which has `bash: allow` and the execution skills).

## When to use me

Invoke me when **any subagent returns `NEEDS_GIT_BRANCH_SETUP: true`** in its Return Contract. This signal indicates a project was just scaffolded (or a ticket workflow completed) and may benefit from a release branch structure.

## Governance

> **Content Rule:** This skill MUST contain ZERO inline YAML templates, ZERO bash scripts, and ZERO label hex colors. All execution logic and conventions are cross-references to the governing skills. This rule is auditable — if any inline template/script/hex is found, it is a defect.

This skill **defers** to:

| Aspect | Governing Skill | Section Reference |
|--------|-----------------|-------------------|
| Execution (scripts, workflows, onboarding) | `version-bump-standard-skill` | §Onboarding Checklist, §Templates & Scripts, §Workflow Templates, §Branch Flow |
| Tag formats & label conventions | `semantic-release-convention-skill` | §5. Release Tag Convention, §Branch-Aware Tag Mapping, §3. PR Label Rules |
| Changelog generation | `semantic-release-convention-skill` | §6. GitHub Actions Requirements |

**Why deferral (not duplication):** If governance changes (e.g., tag format, label colors), only the governing skill needs updating. This skill never needs to change for convention updates.

## Detection Logic

Before offering branch-workflow setup, check for **existing release tooling**. Offer setup ONLY when ALL of the following are absent from the target project:

| Signal | Path / Pattern | Meaning |
|--------|----------------|---------|
| CanvasTekk release workflow | `.github/workflows/bump-version-and-push-tag.yml` | Already uses the CanvasTekk version-bump standard |
| Any release workflow | `.github/workflows/*release*` | Uses some release automation |
| Any semantic workflow | `.github/workflows/*semantic*` | Uses semantic-release or similar |
| semantic-release config | `.releaserc*` | Uses semantic-release CLI |
| release-please config | `release-please-config.json` | Uses Google's release-please |
| Changesets | `.changeset/**` | Uses changesets for versioning |

**Decision rule:**
- If ANY signal is present → **Skip** (do not offer — existing tooling would conflict)
- If ALL signals are absent → **Proceed** to Skip-State check, then offer

### Skip-State Persistence

Before offering, also check for a skip marker:

- **Marker path:** `.opencode/branch-workflow-skipped` (in the target project)
- **If marker exists** → Skip silently (user previously declined; do not re-prompt)
- **When user selects "Skip"** → Primary agent creates `.opencode/branch-workflow-skipped` (empty file) so future setup runs do not re-prompt

## Question Tool Spec

When detection passes (all signals absent, no skip marker), present this prompt to the user via the `question` tool:

```json
{
  "questions": [
    {
      "question": "Would you like to set up a release branch workflow (dev → uat → main) for this project?",
      "header": "Branch Workflow Setup",
      "multiple": false,
      "options": [
        {
          "label": "Standard dev → uat → main",
          "description": "Set up the CanvasTekk release standard: dev/uat/main branches, PR-label-driven versioning, branch enforcement workflows, labels, and branch protection."
        },
        {
          "label": "Custom branch names",
          "description": "Same workflow but with custom branch names (e.g., develop/staging/production instead of dev/uat/main)."
        },
        {
          "label": "Trunk-based alternative",
          "description": "Single main branch with feature branches and release tags (no dev/uat intermediaries)."
        },
        {
          "label": "Skip",
          "description": "Do not set up a branch workflow now. A skip marker will be written to avoid re-prompting."
        }
      ]
    }
  ]
}
```

### Non-Interactive Fallback

> **ISSUE-6:** This configurator supports Docker standalone mode (web endpoint) and CI contexts where no user can answer interactively.

If the `question` tool is **unavailable, times out, or the context is non-interactive** (CI pipeline, Docker batch mode):

1. Default to **option (4) Skip**
2. Emit a warning: `"Branch workflow setup skipped — non-interactive context detected. Re-run in interactive mode to configure."`
3. Write the skip marker (`.opencode/branch-workflow-skipped`)
4. **Never block** the scaffolding flow

## Option Matrix

When the user selects "Standard" or "Custom", the following parameters are configurable. **Defaults and valid values are cross-referenced** to governance skills — this skill does not define new conventions:

| Parameter | Default | Valid Values | Reference |
|-----------|---------|--------------|-----------|
| Branch names | `dev`, `uat`, `main` | Any 3 distinct names (custom path) | `version-bump-standard-skill` §Branch Flow |
| Tag format | Branch-aware | `v-prefix` or `no-prefix` | `semantic-release-convention-skill` §Branch-Aware Tag Mapping |
| PR workflow toggle | On | `on` / `off` | `semantic-release-convention-skill` §3. PR Label Rules |
| Changelog integration | On | `on` / `off` | `semantic-release-convention-skill` §6. GitHub Actions Requirements |
| Branch enforcement workflows | On | `on` / `off` | `version-bump-standard-skill` §Workflow Templates (templates 2 & 3) |
| CI template selection | All 3 templates | `bump-version-and-push-tag.yml`, `enforce-dev-to-uat.yml`, `enforce-uat-to-main.yml` (by filename) | `version-bump-standard-skill` §Workflow Templates |

For "Trunk-based alternative": only tag format and changelog parameters apply; branch enforcement workflows are off.

## Delegation Spec

When the user accepts (options 1, 2, or 3), delegate execution to `repo-ops-specialist-subagent` with this typed payload:

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `option` | enum: `standard` \| `custom` \| `trunk-based` | Yes | The user's selection |
| `branchNames` | object: `{ dev, uat, main }` | Yes (standard/custom) | Branch name strings; defaults per §Option Matrix |
| `tagFormat` | string | Yes | `"v-prefix"` or `"no-prefix"` |
| `prWorkflow` | boolean | Yes | Whether to enforce PR label rules |
| `changelog` | boolean | Yes | Whether to set up changelog generation |
| `branchEnforcement` | boolean | Yes | Whether to deploy branch enforcement workflows |
| `ciTemplates` | string[] | Yes | Filenames of templates to deploy (from `version-bump-standard-skill` §Workflow Templates) |
| `checklist` | reference | Yes | Point to `version-bump-standard-skill` §Onboarding Checklist — do NOT copy steps |

**Delegation instruction:** Pass the payload above to `repo-ops-specialist-subagent` via the Task tool. The executor loads `version-bump-standard-skill` (execution) and `semantic-release-convention-skill` (governance) itself — they are already in its `permission.skill` allowlist.

### Failure Handling

If `repo-ops-specialist-subagent` returns `Status: failed` or `Status: partial`:

1. Do NOT write the skip marker (the user may want to retry)
2. Surface the error to the user with the executor's **Issues** field
3. Offer retry or skip — only write the skip marker if the user explicitly chooses skip

## Compatibility

This skill is invocable by any framework **setup agent** (an `.opencode/agents/*.md` file with tool/spawn capabilities). It is NOT invocable by skills (skills are knowledge documents loaded BY agents; they cannot use the `question` tool or spawn subagents).

### Current Consumers

| Consumer | Type | Status |
|----------|------|--------|
| `nextjs-setup-subagent` | Setup agent | **Active** — signals `NEEDS_GIT_BRANCH_SETUP: true` after scaffolding |

### Future Setup Agents

When a new framework setup agent is created (e.g., `python-setup-subagent`, `go-setup-subagent`), add this invocation pattern to its workflow:

```
After scaffolding:
1. Use glob/read to check detection signals (see §Detection Logic)
2. Check for skip marker (.opencode/branch-workflow-skipped)
3. If all signals absent AND no skip marker:
     Include in Return Contract: NEEDS_GIT_BRANCH_SETUP: true
4. The primary agent handles the rest (loads this skill, prompts user, delegates)
```

> **Note:** `python-backend-skill` is a **skill**, not an agent — it cannot invoke this skill. Only a future `python-setup-subagent` (agent) could.

## Invocation Flow

```
Setup agent scaffolds project
  → checks detection signals (glob/read — no bash needed)
  → if absent: returns NEEDS_GIT_BRANCH_SETUP: true
Primary agent receives signal
  → loads THIS skill (git-branch-workflow-setup-skill)
  → performs detection (§Detection Logic)
  → if triggered: calls question tool (§Question Tool Spec) or applies fallback (§Non-Interactive Fallback)
  → if user accepts: delegates to repo-ops-specialist-subagent (§Delegation Spec)
  → if user skips: writes skip marker
```
