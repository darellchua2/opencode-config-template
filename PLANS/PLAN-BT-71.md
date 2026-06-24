# PLAN-BT-71: Port 11 CAD Skills, Consolidate 3 Specialists into 1

**JIRA**: [BT-71](https://betekk.atlassian.net/browse/BT-71)
**Branch**: `BT-71-cad-skills-consolidation`
**Created**: 2026-06-24

## Overview

Port the 11 open-source CAD/engineering skills from `earthtojake/text-to-cad` into the OpenCode configurator repo, AND consolidate the 3 existing CAD/engineering specialist subagents into a single `cad-specialist-subagent` by extracting their domain knowledge into skills.

**Net Impact**: Agents 40 -> 38 | Skills 88 -> 102 | ~1420 lines moved from always-loaded agents to on-demand skills

---

## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---|---|---|---|
| `/tmp/text-to-cad/` (upstream clone) | — | All 11 text-to-cad skills | low |
| `skills/cad-*-skill/SKILL.md` (x11) | Upstream clone | cad-specialist-subagent, setup.sh | med |
| `skills/cad-*-skill/scripts/` (x11) | Upstream clone | SKILL.md workflow instructions | low |
| `skills/cad-*-skill/references/` (x11) | Upstream clone | SKILL.md progressive references | low |
| `skills/autodesk-aps-skill/SKILL.md` | autodesk-specialist-subagent.md (read before delete) | cad-specialist-subagent | med |
| `skills/civil-3d-skill/SKILL.md` | civil-3d-specialist-subagent.md (read before delete) | cad-specialist-subagent | med |
| `skills/open3d-skill/SKILL.md` | open3d-specialist-subagent.md (read before delete) | cad-specialist-subagent | med |
| `agents/cad-specialist-subagent.md` | All 14 skills exist | Primary agent routing, setup.sh | high |
| `agents/autodesk-specialist-subagent.md` (DELETE) | autodesk-aps-skill extracted | — | med |
| `agents/civil-3d-specialist-subagent.md` (DELETE) | civil-3d-skill extracted | — | med |
| `agents/open3d-specialist-subagent.md` (DELETE) | open3d-skill extracted | — | med |
| `deploy/setup.sh` | All skill/agent files in place | setup.ps1 mirror, deployment | high |
| `deploy/setup.ps1` | setup.sh changes | Windows deployment | med |
| `README.md` | All skills/agents finalized | Documentation consumers | med |

---

## Implementation Phases

### Phase 1: Clone Upstream & Port 11 Text-to-CAD Skills

- [ ] **1.1** Clone text-to-cad repo with sparse checkout
    - **Why:** All 11 skills depend on upstream scripts/references; must fetch before any porting
    - **Done when:** `/tmp/text-to-cad/skills/` directory exists with all 11 skill subdirectories
    - **Consumers affected:** All Phase 1 steps

- [ ] **1.2** Port `cad-generation-skill` (from upstream `cad`)
    - **Why:** Core CAD generation skill — STEP-first workflow, most referenced by other skills
    - **Done when:** `opencode_app/.opencode/skills/cad-generation-skill/` has SKILL.md + scripts/ + references/ with all `$skill-name` refs converted
    - **Consumers affected:** cad-specialist-subagent routing table, other skills that cross-reference `$cad`

- [ ] **1.3** Port `cad-viewer-skill` (from upstream `cad-viewer`)
    - **Why:** Required for the mandatory handoff pattern in cad-generation-skill and other skills
    - **Done when:** Directory exists with SKILL.md + scripts/viewer/ + references/
    - **Consumers affected:** cad-generation-skill handoff, urdf/srdf/sdf/gcode handoff

- [ ] **1.4** Port `cad-step-parts-skill` (from upstream `step-parts`)
    - **Why:** Off-the-shelf parts lookup — referenced by cad-generation-skill for assemblies
    - **Done when:** Directory exists with SKILL.md + scripts/ + references/
    - **Consumers affected:** cad-generation-skill assembly workflow

- [ ] **1.5** Port `cad-dxf-skill` (from upstream `dxf`)
    - **Why:** 2D drawing export — secondary workflow branching from CAD geometry
    - **Done when:** Directory exists with SKILL.md + scripts/ + references/
    - **Consumers affected:** cad-generation-skill (cross-references DXF workflow)

- [ ] **1.6** Port `cad-urdf-skill` (from upstream `urdf`)
    - **Why:** Robot description generation — first in the robotics skill chain (URDF -> SRDF -> SDF)
    - **Done when:** Directory exists with SKILL.md + scripts/ + references/ (6 reference files)
    - **Consumers affected:** cad-srdf-skill, cad-specialist robot description pipeline

- [ ] **1.7** Port `cad-srdf-skill` (from upstream `srdf`)
    - **Why:** MoveIt planning groups — depends on URDF existing
    - **Done when:** Directory exists with SKILL.md + scripts/ + references/
    - **Consumers affected:** cad-specialist robot description pipeline

- [ ] **1.8** Port `cad-sdf-skill` (from upstream `sdf`)
    - **Why:** Gazebo simulator models — completes the robotics chain
    - **Done when:** Directory exists with SKILL.md + scripts/ + references/
    - **Consumers affected:** cad-specialist robot description pipeline

- [ ] **1.9** Port `cad-sendcutsend-skill` (from upstream `sendcutsend`)
    - **Why:** Manufacturing validation — independent workflow
    - **Done when:** Directory exists with SKILL.md + scripts/ + references/
    - **Consumers affected:** cad-specialist sheet metal pipeline

- [ ] **1.10** Port `cad-gcode-skill` (from upstream `gcode`)
    - **Why:** Slicing meshes to G-code — prerequisite for bambu-labs skill
    - **Done when:** Directory exists with SKILL.md + scripts/ + references/
    - **Consumers affected:** cad-bambu-labs-skill, cad-specialist 3D print pipeline

- [ ] **1.11** Port `cad-bambu-labs-skill` (from upstream `bambu-labs`)
    - **Why:** Bambu Lab print management — depends on validated G-code from gcode skill
    - **Done when:** Directory exists with SKILL.md + scripts/ + references/
    - **Consumers affected:** cad-specialist 3D print pipeline

- [ ] **1.12** Port `cad-implicit-skill` (from upstream `implicit-cad`)
    - **Why:** Experimental GLSL SDF models — standalone, lowest priority
    - **Done when:** Directory exists with SKILL.md + scripts/ + references/
    - **Consumers affected:** none (experimental, self-contained)

- [ ] **1.13** Verify no `$skill-name` cross-references remain in any ported SKILL.md
    - **Why:** OpenCode uses the Skill tool, not `$` tokens — leftover refs will confuse the agent
    - **Done when:** `grep -r '\$cad\|\$dxf\|\$urdf\|\$srdf\|\$sdf\|\$gcode\|\$bambu\|\$sendcutsend\|\$step-parts\|\$implicit-cad\|\$cad-viewer' opencode_app/.opencode/skills/cad-*/SKILL.md` returns zero matches
    - **Consumers affected:** All skills (correctness gate)

### Phase 2: Extract Domain Knowledge into 3 Skills

- [ ] **2.1** Create `autodesk-aps-skill` from autodesk-specialist-subagent.md
    - **Why:** ~850 lines of API docs/code trapped in agent file; must extract BEFORE deleting the agent
    - **Done when:** `skills/autodesk-aps-skill/SKILL.md` exists with all sections: APS Overview, Authentication, Data Management, Model Derivative, Viewer, Design Automation, MCP config, Revit/Fusion/AutoCAD API, Webhooks, Common Scenarios, Doc References
    - **Consumers affected:** cad-specialist-subagent (routes to this skill)

- [ ] **2.2** Create `civil-3d-skill` from civil-3d-specialist-subagent.md
    - **Why:** ~200 lines of domain knowledge + MANDATORY version detection must be preserved as skill-level instruction
    - **Done when:** `skills/civil-3d-skill/SKILL.md` exists with version detection as first section + Core Expertise + API Usage + Version Notes + Workflow Templates + Doc References
    - **Consumers affected:** cad-specialist-subagent (routes to this skill)

- [ ] **2.3** Create `open3d-skill` from open3d-specialist-subagent.md
    - **Why:** ~370 lines of code examples + ML pipelines + MANDATORY version detection
    - **Done when:** `skills/open3d-skill/SKILL.md` exists with version detection as first section + Core Expertise + Performance + Project Structure + Workflow Templates + Doc References
    - **Consumers affected:** cad-specialist-subagent (routes to this skill)

### Phase 3: Create Consolidated cad-specialist-subagent

- [ ] **3.1** Create `cad-specialist-subagent.md` with frontmatter + Prompt Defense + Purpose + Trigger Phrases
    - **Why:** This is the single routing target for ALL CAD/engineering tasks; must have comprehensive triggers
    - **Done when:** File exists at `agents/cad-specialist-subagent.md` with model `glm-5-turbo`, `bash: allow`, `skill:` permission block listing all 14 skills
    - **Consumers affected:** Primary agent routing (AGENTS.md)

- [ ] **3.2** Add Skill Routing Table (14 skills) + Pipeline Patterns + Prerequisites + Default Assumptions + Return Contract
    - **Why:** The routing table is the core value — tells the agent which skill to load for each task type
    - **Done when:** File contains complete routing table, 4 pipeline patterns (Design-to-Manufacture, Sheet Metal, Robot Description, Assembly), prerequisites section, default assumptions (mm/XY/+Z)
    - **Consumers affected:** Primary agent, all CAD workflows

### Phase 4: Delete Old Specialists

- [ ] **4.1** Delete `autodesk-specialist-subagent.md`
    - **Why:** Domain knowledge extracted to autodesk-aps-skill in Step 2.1; keeping the old file creates routing confusion
    - **Done when:** File removed from `agents/` directory
    - **Consumers affected:** setup.sh agent listing, README.md subagent table

- [ ] **4.2** Delete `civil-3d-specialist-subagent.md`
    - **Why:** Domain knowledge extracted to civil-3d-skill in Step 2.2
    - **Done when:** File removed from `agents/` directory
    - **Consumers affected:** setup.sh agent listing, README.md subagent table

- [ ] **4.3** Delete `open3d-specialist-subagent.md`
    - **Why:** Domain knowledge extracted to open3d-skill in Step 2.3
    - **Done when:** File removed from `agents/` directory
    - **Consumers affected:** setup.sh agent listing, README.md subagent table

### Phase 5: Sync Documentation

- [ ] **5.1** Update `deploy/setup.sh` show_help() — agents section
    - **Why:** Banner must reflect reality; 3 specialists removed, 1 added
    - **Done when:** Agent count says 38, 3 old specialist lines removed, `cad-specialist` line added after `open3d-specialist` former position
    - **Consumers affected:** Anyone running `setup.sh --help`

- [ ] **5.2** Update `deploy/setup.sh` show_help() — skills section
    - **Why:** 14 new skills need to be listed in a new category
    - **Done when:** Skill count says 102, "CAD & Hardware Design (14)" category added with all 14 skill names
    - **Consumers affected:** Anyone running `setup.sh --help`

- [ ] **5.3** Update `deploy/setup.sh` print_summary() — agents + skills
    - **Why:** Post-setup summary must match show_help
    - **Done when:** Agent count says 38, CAD & Hardware Design echo block added with all 14 skills
    - **Consumers affected:** Post-setup user experience

- [ ] **5.4** Update `deploy/setup.sh` print_next_steps() — agents + skills
    - **Why:** Completion banner is the last thing users see
    - **Done when:** Agent count updated (39), "34 more agents", skill count says 102, CAD & Hardware Design (14) added to category list
    - **Consumers affected:** Post-setup user experience

- [ ] **5.5** Mirror all setup.sh changes in `deploy/setup.ps1`
    - **Why:** Windows parity — setup.ps1 must match setup.sh exactly
    - **Done when:** All 4 changes from 5.1-5.4 mirrored in PowerShell syntax
    - **Consumers affected:** Windows users running setup

- [ ] **5.6** Update `README.md` subagent table
    - **Why:** README is the primary documentation; must reflect consolidated specialist
    - **Done when:** 3 old specialist rows removed, `cad-specialist-subagent` row added
    - **Consumers affected:** Documentation readers

- [ ] **5.7** Update `README.md` skill categories table
    - **Why:** New CAD & Hardware Design category must be documented
    - **Done when:** "CAD & Hardware Design" row added with 14 skills listed
    - **Consumers affected:** Documentation readers

### Phase 6: Verification

- [ ] **6.1** Verify all 14 skill directories exist with SKILL.md
    - **Why:** Missing SKILL.md means the skill won't be discovered by OpenCode
    - **Done when:** `find opencode_app/.opencode/skills -name "SKILL.md" | wc -l` returns 102
    - **Consumers affected:** All skill consumers

- [ ] **6.2** Verify cad-specialist-subagent.md exists and old specialists are deleted
    - **Why:** Routing integrity — old specialists must not linger
    - **Done when:** `ls agents/cad-specialist-subagent.md` succeeds; `ls agents/autodesk-specialist-subagent.md agents/civil-3d-specialist-subagent.md agents/open3d-specialist-subagent.md` all fail
    - **Consumers affected:** Primary agent routing

- [ ] **6.3** Verify version detection blocks in civil-3d-skill and open3d-skill
    - **Why:** These skills handle version-sensitive APIs; missing version detection could cause incorrect guidance
    - **Done when:** Both SKILL.md files contain "MANDATORY" and "version" in their first section
    - **Consumers affected:** Users of Civil 3D and Open3D APIs

- [ ] **6.4** Verify setup.sh and setup.ps1 counts are consistent
    - **Why:** Inconsistent counts confuse users and break deployment verification
    - **Done when:** setup.sh says 38 agents / 102 skills; setup.ps1 says the same
    - **Consumers affected:** All deployment consumers

---

## Acceptance Criteria (from BT-71)

- [ ] 11 text-to-cad skill directories exist with SKILL.md + scripts/ + references/
- [ ] 3 extracted skill directories exist (autodesk-aps-skill, civil-3d-skill, open3d-skill)
- [ ] cad-specialist-subagent.md exists in agents/
- [ ] 3 old specialist files are deleted from agents/
- [ ] No `$skill-name` cross-references remain in any text-to-cad SKILL.md
- [ ] Version detection MANDATORY blocks present in civil-3d-skill and open3d-skill
- [ ] deploy/setup.sh agent count updated to 38 (show_help) / 39 (next_steps)
- [ ] deploy/setup.sh skill count updated to 102
- [ ] deploy/setup.ps1 mirrors setup.sh exactly
- [ ] README.md updated (3 old specialist rows removed, cad-specialist + CAD skills category added)

---

## Risks & Mitigation

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| Upstream scripts fail to clone (network/auth) | low | high | Use `--depth 1 --filter=blob:none --sparse` for minimal fetch; fallback to raw.githubusercontent.com webfetch |
| Some upstream skills lack scripts/ or references/ dirs | med | low | Check existence before copying; SKILL.md alone is still a valid skill |
| Cross-reference conversion misses edge cases | med | med | Grep verification in Step 1.13 catches all `$`-prefixed tokens |
| setup.sh line numbers drift during editing | high | med | Use string matching for edits, not line numbers; re-grep after each change |
| Version detection instructions lose MANDATORY emphasis in extraction | med | high | Verification Step 6.3 explicitly checks for "MANDATORY" keyword |
| Existing AGENTS.md routing references to old specialists | low | low | Already verified: no AGENTS.md files reference the 3 old specialists |

---

## Technical Notes

- All skills go in `opencode_app/.opencode/skills/` (source of truth for deployment)
- The agent goes in `opencode_app/.opencode/agents/`
- Skills are auto-discovered by SKILL.md presence — no explicit registration beyond banner counts
- The `_archived/` directory is excluded from deployment automatically
- The consolidated specialist uses `bash: allow` (runs Python CAD scripts) — differs from old specialists which had `bash: deny`
- `$skill-name` cross-references in upstream must be converted to "the `<skill-name>` (load via skill tool)" for OpenCode compatibility

---

*Tracking progress for [BT-71](https://betekk.atlassian.net/browse/BT-71) with ticket-plan-workflow-skill*
