# PLAN: Fix agent/skill compliance findings from OpenCode best-practices audit

**Issue:** https://github.com/darellchua2/opencode-config-template/issues/280
**Branch:** `GIT-280`
**Created:** 2026-07-30

---

## Dependency & Consumer Map

_Before writing steps, list each touched file/module and who consumes it._

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---------------------|---------------------------|---------------------------------|-------------|
| `agents/startup-ceo-subagent.md` | — | office-document-primary-agent (task allow), primary session (@mention) | low |
| `agents/pptx-specialist-subagent.md` | — | startup-ceo-subagent (task allow), office-document-router-subagent (task allow) | low |
| `skills/threejs-nextjs-skill/SKILL.md` | — | primary session skill tool | low |
| `agents/image-analyzer-subagent.md` | — | pptx-specialist-subagent (task delegation), error-resolver-subagent, primary session | low |
| `agents/loop-operator-subagent.md` | — | linting-subagent (task delegation), testing-subagent (task delegation) | low |
| `agents/office-document-primary-agent.md` | — | primary session (@mention), tests/test_markitdown_skill.bats | medium (rename) |
| `skills/pptx-generate-slide-skill/SKILL.md` | — | pptx-specialist-subagent (skill allow) | low |
| `skills/pptx-template-modifier-skill/SKILL.md` | — | pptx-specialist-subagent (skill allow) | low |
| `agents/startup-founder-primary-agent.md` | — | README.md, deploy/agent-tiers.json | medium (rename) |
| `deploy/agent-tiers.json` | renames (Phase 5) | deploy/setup.sh model resolution | low |
| `README.md` | renames (Phase 5) | documentation readers | low |
| `tests/test_markitdown_skill.bats` | renames (Phase 5) | CI test suite | medium |

---

## Implementation Phases

### Phase 1: Fix YAML structural issues (WARNING)

- [ ] **1.1** Remove duplicate `task:` block from `startup-ceo-subagent.md` frontmatter (delete lines 14-15: the second `task:` key with `"pptx-specialist-subagent": allow`)
    — **Why:** The duplicate YAML key silently overwrites the first `task:` block, discarding the `"*": deny` catch-all and leaving all subagents implicitly allowed. This is a silent security-relevant permission leak.
    — **Done when:** Only one `task:` block remains with `"*": deny` + `"pptx-specialist-subagent": allow`; YAML parses without duplicate keys.
    — **Consumers affected:** office-document-primary-agent (which has startup-ceo-subagent in its task allow list); startup-ceo-subagent itself (its permission scoping is fixed).

- [ ] **1.2** Add `"*": deny` as the first entry in `pptx-specialist-subagent.md` `permission.task` block (before the existing `"image-analyzer-subagent": allow`)
    — **Why:** Without a deny-all catch, the implicit default may grant access to all subagents, breaking the deny-by-default pattern used by all other 37 agents. Last matching rule wins, so deny-all must come first.
    — **Done when:** `task:` block reads `"*": deny` then `"image-analyzer-subagent": allow`.
    — **Consumers affected:** startup-ceo-subagent and office-document-router-subagent (both have pptx-specialist-subagent in task allow); pptx-specialist-subagent itself (its delegation scope is now properly locked down).

### Phase 2: Fix skill frontmatter type violation (WARNING)

- [ ] **2.1** Convert `metadata.languages: [typescript, javascript]` and `metadata.frameworks: [three.js, react-three-fiber, next.js, react]` to comma-separated strings in `threejs-nextjs-skill/SKILL.md`
    — **Why:** The OpenCode skills spec requires `metadata` to be a string-to-string map. YAML inline arrays are silently ignored by the parser, losing the metadata values entirely.
    — **Done when:** Both fields are quoted strings (`"typescript, javascript"` and `"three.js, react-three-fiber, next.js, react"`); matches the pattern used by `react-nextjs-antipatterns-skill` and other skills.
    — **Consumers affected:** none (metadata is informational; no runtime consumer depends on the values).

### Phase 3: Add `hidden: true` to internal utility agents (INFO)

- [ ] **3.1** Add `hidden: true` to `image-analyzer-subagent.md` frontmatter
    — **Why:** This agent is described as a "shared image analysis utility for all agents" and is invoked exclusively via task delegation by other agents. It should not appear in the user `@` autocomplete menu, reducing autocomplete noise.
    — **Done when:** `hidden: true` is present in frontmatter; agent still invocable via Task tool.
    — **Consumers affected:** pptx-specialist-subagent, error-resolver-subagent (both delegate via task — unaffected since hidden only affects UI autocomplete, not Task tool invocation).

- [ ] **3.2** Add `hidden: true` to `loop-operator-subagent.md` frontmatter
    — **Why:** This is an internal autonomous loop execution operator invoked exclusively by `linting-subagent` and `testing-subagent`. Not intended for direct user invocation.
    — **Done when:** `hidden: true` is present in frontmatter.
    — **Consumers affected:** linting-subagent, testing-subagent (both delegate via task — unaffected).

- [ ] **3.3** Add `hidden: true` to `office-document-primary-agent.md` frontmatter (note: file will be renamed in Phase 5)
    — **Why:** This is an internal router that delegates to pptx/docx/xlsx subagents; it is not meant to be user-invoked directly. Adding `hidden: true` before the rename ensures the flag survives the `git mv`.
    — **Done when:** `hidden: true` is present in frontmatter.
    — **Consumers affected:** primary session (@mention users — will no longer see it in autocomplete, which is the desired behavior).

### Phase 4: Normalize line endings (INFO)

- [ ] **4.1** Convert Windows `\r\n` to Unix `\n` line endings in `pptx-generate-slide-skill/SKILL.md`
    — **Why:** Inconsistent with the other 123 skill files which use Unix LF. CRLF can cause git diff noise, confuse some YAML parsers, and break shell scripts that read the file.
    — **Done when:** `file` reports `ASCII text` (not `with CRLF line terminators`); `rg '\r'` returns no matches in the file.
    — **Consumers affected:** pptx-specialist-subagent (loads this skill — unaffected by line ending change).

- [ ] **4.2** Convert Windows `\r\n` to Unix `\n` line endings in `pptx-template-modifier-skill/SKILL.md`
    — **Why:** Same rationale as 4.1 — consistency with the rest of the skill corpus.
    — **Done when:** `file` reports `ASCII text`; `rg '\r'` returns no matches.
    — **Consumers affected:** pptx-specialist-subagent (loads this skill — unaffected).

### Phase 5: Rename agents to match `mode: subagent` (INFO)

- [ ] **5.1** `git mv` `startup-founder-primary-agent.md` to `startup-founder-subagent.md`
    — **Why:** The filename contains "primary" but the agent has `mode: subagent`. OpenCode uses the filename as the agent name in the picker, so the "primary" label is misleading to users browsing the agent list.
    — **Done when:** File exists at new path with git rename tracked; old path no longer exists.
    — **Consumers affected:** README.md, deploy/agent-tiers.json (both reference the old name — updated in steps 5.3 and 5.4).

- [ ] **5.2** `git mv` `office-document-primary-agent.md` to `office-document-router-subagent.md`
    — **Why:** Same rationale as 5.1 — filename says "primary" but `mode: subagent`. The "router" suffix better describes its actual role (routes to pptx/docx/xlsx subagents).
    — **Done when:** File exists at new path with git rename tracked; old path no longer exists.
    — **Consumers affected:** README.md, deploy/agent-tiers.json, tests/test_markitdown_skill.bats (all reference old name — updated in steps 5.3, 5.4, 5.5).

- [ ] **5.3** Update `deploy/agent-tiers.json`: rename keys `"office-document-primary-agent"` → `"office-document-router-subagent"` and `"startup-founder-primary-agent"` → `"startup-founder-subagent"`
    — **Why:** The tier map keys must match the agent filenames for deploy-time model resolution. Stale keys would cause the renamed agents to fall back to the default tier model instead of their assigned `fast` tier.
    — **Done when:** Both JSON keys match the new filenames; JSON is valid.
    — **Consumers affected:** deploy/setup.sh (reads this file during `--models-only` resolution).

- [ ] **5.4** Update `README.md`: replace both old agent names with new names in the Subagents table
    — **Why:** Documentation must match reality — readers consulting the README to find agents would not find the renamed files under their old names.
    — **Done when:** `rg "startup-founder-primary-agent\|office-document-primary-agent" README.md` returns no matches; both rows use new names.
    — **Consumers affected:** none (documentation only).

- [ ] **5.5** Update `tests/test_markitdown_skill.bats`: replace `"office-document-primary-agent"` with `"office-document-router-subagent"` in both the array and file-existence assertion
    — **Why:** The test hard-references the old filename in two places. Without updating, the test would fail looking for a file that no longer exists.
    — **Done when:** `rg "office-document-primary-agent" tests/test_markitdown_skill.bats` returns no matches; test passes.
    — **Consumers affected:** CI test suite (test would fail without this update).

### Phase 6: Verification

- [ ] **6.1** Verify no stale references to old agent names remain anywhere in the repo
    — **Why:** Ensures the rename is complete and no dangling references will cause runtime or test failures.
    — **Done when:** `rg "startup-founder-primary-agent\|office-document-primary-agent" --glob '!PLANS/PLAN-GIT-27[0-9].md'` returns zero matches (excluding historical PLAN files which are immutable records).
    — **Consumers affected:** none (verification only).

- [ ] **6.2** Run the existing test suite to confirm nothing broke
    — **Why:** Frontmatter changes and renames could have unintended side effects on tests or config parsing. Running the suite validates all changes holistically.
    — **Done when:** `bats tests/` passes (or reports only pre-existing failures unrelated to this change).
    — **Consumers affected:** none (verification only).

---

## Step Authoring Rules
- **Atomic**: one reversible concern per step; if a step does two things, split it.
- **Rationale mandatory**: every step MUST have a **Why**; a step without rationale is malformed and blocks commit.
- **Completion signal**: every step MUST have an objective **Done when** check, not a subjective "done".
- **Consumers explicit**: list affected consumers so reviewers/execution know blast radius; write "none" if truly isolated.

## Technical Notes
- All fixes are frontmatter-only or file rename — no prompt body changes.
- `deploy/setup.sh` and `deploy/setup.ps1` use glob discovery (`agents/*.md`) — no hard references to agent filenames, so no changes needed there.
- `opencode.json` has no references to either renamed agent.
- Historical PLAN files (`PLAN-GIT-277.md`, `PLAN-GIT-278.md`) reference old agent names but are immutable records and should NOT be updated.

## Dependencies
- None — all changes are self-contained within this repo.

## Risks & Mitigation
- **Risk:** Renaming agents could break `permission.task` references in other agent files.
  **Mitigation:** Checked — `grep` confirms no other agent's `permission.task` references `startup-founder-primary-agent` or `office-document-primary-agent` by name (only `deploy/agent-tiers.json`, `README.md`, and `tests/` reference them).
- **Risk:** `hidden: true` could prevent programmatic Task invocation.
  **Mitigation:** Per opencode.ai docs, `hidden` only affects `@` autocomplete UI visibility; Task tool invocation is unaffected.

## Success Metrics
- 100% frontmatter compliance across all 38 agents and 124 skills
- Zero stale references to old agent names (excluding historical PLANS)
- All existing tests pass
