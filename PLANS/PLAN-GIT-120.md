# Plan: Add Documentation Update Workflow for New Subagents/Skills

## Issue Reference
- **Number**: #120
- **URL**: https://github.com/darellchua2/opencode-config-template/issues/120
- **Labels**: enhancement, documentation

## Overview

Create a standardized workflow that ensures when a new subagent or skill is added to this repository, the following files are automatically reviewed and updated with accurate information:

1. **AGENTS.md** - Document the new subagent/skill purpose and routing
2. **setup.sh** - Update skill/agent counts and listings
3. **setup.ps1** - Update skill/agent counts and listings
4. **README.md** - Update tables reflecting current skills/agents

## Acceptance Criteria

- [ ] Create a new skill `documentation-sync-skill` in `skills/` folder
- [ ] Skill provides checklist for updating all 4 documentation files
- [ ] Skill documents the exact line ranges in each file that need updates
- [ ] Skill includes validation commands to verify counts are accurate
- [ ] Update AGENTS.md to include guidance on using this workflow
- [ ] Create a subagent `documentation-sync-subagent` for automated sync tasks

## Scope

- `skills/documentation-sync-workflow/SKILL.md` (new)
- `agents/documentation-sync-subagent.md` (new)
- `AGENTS.md` (add workflow section)
- `config.json` (add subagent entry if created)

---

## Implementation Phases

### Phase 1: Research & Analysis
- [ ] Identify all locations in setup.sh that reference skill/agent counts (lines 503-558)
- [ ] Identify all locations in setup.ps1 that reference skill/agent counts (lines 304-337)
- [ ] Identify all tables in README.md that list skills/agents (lines 132-142, 156-177)
- [ ] Review AGENTS.md for any existing documentation workflow guidance
- [ ] Determine what information needs to be synced for each new addition

### Phase 2: Create Documentation Sync Skill
- [ ] Create `skills/documentation-sync-workflow/SKILL.md`
- [ ] Define skill metadata (category: Documentation)
- [ ] Document the 4 files that need updating
- [ ] Include line ranges for each file section
- [ ] Add validation commands (grep counts, wc -l, etc.)
- [ ] Include examples of before/after updates

### Phase 3: Create Documentation Sync Subagent
- [ ] Create `agents/documentation-sync-subagent.md`
- [ ] Define subagent purpose: automated documentation synchronization
- [ ] Add trigger phrases: "sync docs", "update documentation", "verify doc counts"
- [ ] Set appropriate permissions (read, write, edit, glob, grep, bash)
- [ ] Include the documentation-sync-workflow skill

### Phase 4: Update AGENTS.md
- [ ] Add new section: "## Adding New Subagents or Skills"
- [ ] Document the 4-file update workflow
- [ ] Reference the documentation-sync-workflow skill
- [ ] Include checklist for manual updates

### Phase 5: Validation
- [ ] Verify skill file follows existing skill patterns
- [ ] Verify subagent file follows existing subagent patterns
- [ ] Test that line numbers documented are accurate
- [ ] Verify validation commands work correctly

---

## Technical Notes

### Files Requiring Updates When Adding Skills/Agents

| File | Section | Current Lines | Update Type |
|------|---------|---------------|-------------|
| `setup.sh` | SKILLS listing | 523-556 | Add skill to category |
| `setup.sh` | Skill count | 523 | Increment count |
| `setup.sh` | AGENTS listing | 503-509 | Add agent if applicable |
| `setup.ps1` | SKILLS listing | 305-337 | Add skill to category |
| `setup.ps1` | Skill count | 304 | Increment count |
| `README.md` | Skill Categories table | 132-142 | Add row to table |
| `README.md` | Subagents table | 156-177 | Add row if new subagent |
| `AGENTS.md` | Task Delegation Order | varies | Add routing if needed |

### Validation Commands

```bash
# Count skills in skills/ directory
ls -d skills/*/ | wc -l

# Count agents in agents/ directory
ls agents/*.md | wc -l

# Verify skill counts in setup.sh match reality
grep -c "SKILLS" setup.sh

# Check README.md tables are formatted correctly
grep -c "|.*\`.*\`.*|" README.md
```

### Current Counts (as of issue creation)
- **Skills**: 49 across 9 categories
- **Agents**: 20 (2 primary + 18 subagents)

### Skill Categories (current)
1. Framework (7)
2. Language-Specific (4)
3. Framework-Specific (7)
4. OpenCode Meta (4)
5. OpenTofu (7)
6. Git/Workflow (7)
7. Documentation (2)
8. JIRA (4)
9. Code Quality (7)

## Dependencies
- Existing skill patterns in `skills/` folder
- Existing subagent patterns in `agents/` folder
- Accurate line numbers in setup.sh and setup.ps1

## Risks & Mitigation

| Risk | Mitigation |
|------|------------|
| Line numbers drift as files change | Use grep patterns instead of hard-coded line numbers |
| Manual workflow may be forgotten | Add subagent trigger phrases for proactive reminders |
| Counts may get out of sync | Include validation commands in the skill |

## Success Metrics
- New skill and subagent files follow existing patterns
- AGENTS.md includes clear guidance on documentation updates
- All 4 files have documented update locations
- Validation commands accurately detect mismatches
