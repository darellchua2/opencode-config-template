# PLAN-GIT-350 — pr-workflow-subagent delegates docstring sweep to documentation-subagent

**Issue:** https://github.com/darellchua2/opencode-config-template/issues/350
**Branch:** feat/GIT-350 (from origin/main @ b07bba8, includes #349/#352)
**Worktree:** /home/silentx/VSCODE/worktrees/GIT-350

## Overview

`pr-workflow-subagent` mentions `docstring-generator` only as a quality-check note (lines 77, 82) but never delegates an actual docstring pass. Grant `documentation-subagent` task permission and add workflow step 2.5: pre-PR diff-scope docstring sweep, committed before PR creation.

## Re-validation vs issue (worktree @ b07bba8)

- Frontmatter `permission.task` (lines 16-20): `"*": deny`, explore, general, image-analyzer-subagent — no documentation-subagent. Confirmed needed.
- Workflow (lines 112-122): steps 1-8, no docstring delegation step. Confirmed needed.
- Issue technical note says registry changes "only if description changes" — **incomplete**: `delegatesTo = keysOf(perm.task)` (build-registry.mjs:140), so adding the allow entry changes `pr-workflow-subagent.delegatesTo` AND `documentation-subagent.requiredBy` (reverse edge, build-registry.mjs:155-159). Registry regen + commit is REQUIRED even with description untouched.
- Issue note "documentation-subagent (tier: docs → glm-4.7)" is stale post-#349 — docs tier is now `glm-5.3-flash`. No file impact; PLAN wording uses the current tier only.
- `docstring-generator-skill` is allowed by documentation-subagent.md frontmatter (line 17) — the subagent owns the knowledge; pr-workflow only delegates (hub-and-spoke, no skill-content duplication).
- No bats test asserts pr-workflow's task permission list or delegatesTo membership (only nextjs-pr-workflow SKILL.md tests and init.bats generated-output/code-review-subagent tests match; init.bats delegatesTo pin is code-review-subagent `>= 4`, unaffected).
- **Capability ceiling:** documentation-subagent has `bash: deny` — it cannot compute the diff, run linters, or commit. pr-workflow (bash allowed) must own those steps (architecture-review Major 2).

## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---------------------|---------------------------|---------------------------------|-------------|
| `opencode_app/.opencode/agents/pr-workflow-subagent.md` (frontmatter) | — | deploy/registry.json (delegatesTo/requiredBy edges), deploy/init.mjs resolveSelection closure | med — see Risk |
| `pr-workflow-subagent.md` (workflow step 2.5 + delegation bullet + :110 note) | frontmatter allow | agent runtime behavior only | low |
| `deploy/registry.json` | frontmatter edit | build-registry.mjs --check gate, init.mjs add-flow | med — enlarges individual installs |
| `deploy/init.mjs` (resolver) | registry edge | `npx … add pr-workflow-subagent` installs | med — closure bundle (Risk §1) |
| `README.md` delegation row (~606) | registry edge | readers, docs-match-config | low — row already stale |

## Implementation Phases

### Phase 1: Agent file + README

- [x] **1.1** Frontmatter `permission.task`: insert `"documentation-subagent": "allow"` after `"*": deny` (alphabetical: documentation-subagent < explore)
    — **Why:** task permission gates the Task-tool delegation; without it the step would be denied at runtime
    — **Done when:** `rg -n '"documentation-subagent": "allow"' opencode_app/.opencode/agents/pr-workflow-subagent.md` shows the key inside the task block (between `"*": deny` and `explore`)
    — **Consumers affected:** OpenCode runtime, build-registry.mjs, init.mjs
- [x] **1.2** Workflow list: insert step **2.5** between step 2 (framework-specific quality checks) and step 3 (coverage badges). Wording pins the division of labor (delegate has `bash: deny`):
    - pr-workflow computes the PR-diff file list (`git diff --name-only <base>...HEAD`), and passes ONLY that list in the Task prompt
    - documentation-subagent scans those files for new/changed public symbols missing docstrings and fills them per language standard (Python PEP 257, Javadoc, JSDoc/TSDoc, C# XML) — docstrings only, no README/coverage work
    - pr-workflow re-runs lint (and tests where doctests exist) after the edits, then commits docstring additions with semantic format before PR creation
    — **Why:** the issue's core ask — docstring gaps in new code are currently only "validated", never filled; the split respects the delegate's permission ceiling (it cannot git-diff, lint, or commit) and keeps gate output honest (docstring edits are exactly what docstring linters key on)
    — **Done when:** step 2.5 exists; names documentation-subagent; restricts scope to PR-diff files only; names all four language standards; parent computes diff + commits, subagent only reads/edits; requires lint re-run + pre-PR semantic commit
    — **Consumers affected:** every "create pr" flow run by this agent
- [x] **1.3** "Built-in Subagent Delegation" section: add one bullet delegating the diff-scope docstring sweep to `documentation-subagent`; update the section's closing note (line ~110), which currently enumerates only explore/general, to include documentation-subagent. (Pre-existing gap: image-analyzer-subagent is allowed but also absent from this section — leave it; fixing it is out of scope.)
    — **Why:** the section documents this agent's delegation habits; adding a new delegate without a bullet leaves frontmatter and body inconsistent (docs-match-config)
    — **Done when:** section lists documentation-subagent alongside explore/general; note mentions it
    — **Consumers affected:** maintainers, agent self-description
- [x] **1.4** `README.md` ~line 606: pr-workflow-subagent row's delegation column → `documentation-subagent, explore, general, image-analyzer-subagent` (row is already stale — missing image-analyzer)
    — **Why:** same docs-match-config rule; the new edge makes the stale row actively wrong
    — **Done when:** row matches new registry delegatesTo (sorted)
    — **Consumers affected:** readers, doc-consistency

### Phase 2: Registry + gates

- [x] **2.1** `node deploy/build-registry.mjs`; verify diff is exactly: `pr-workflow-subagent.delegatesTo` gains `"documentation-subagent"`, `documentation-subagent.requiredBy` gains `"pr-workflow-subagent"`, plus generatedAt timestamp. Commit registry.json with the agent-file commit (atomic)
    — **Why:** registry must track the new delegation edge; --check gate fails otherwise
    — **Done when:** `node deploy/build-registry.mjs --check` exits 0; `git diff deploy/registry.json` shows only the two edges + timestamp
    — **Consumers affected:** CI gate, registry consumers (init.mjs graph closure)
- [x] **2.2** Gates: `python3` JSON-parse `deploy/registry.json` + edited agent file YAML sanity (rg within frontmatter); run all `tests/*.bats` (submodule initialized)
    — **Why:** standard verification gates for config-adjacent changes
    — **Done when:** parses clean; all suites pass
    — **Consumers affected:** CI parity

### Phase 3: Commit / push

- [x] **3.1** Commit (atomic: agent .md + README.md + registry.json): `feat(agents): delegate pre-PR docstring sweep to documentation-subagent` with `Closes #350`; push `feat/GIT-350`
    — **Why:** semantic, atomic history; body ≤72 chars
    — **Done when:** branch pushed, PR can be opened

## Decisions

- Registry regen is required (issue's "only if description changes" note is wrong for permission-driven edges) — folded into Phase 2.
- No skill frontmatter additions to pr-workflow: documentation-subagent loads its own skills (docstring-generator-skill); delegation, not duplication.
- Step numbered "2.5" (not renumbering 3-8) to match the issue wording and minimize diff.
- Division of labor: parent computes diff + commits + re-lints; delegate only reads/edits docstrings (delegate has `bash: deny`).
- **Install-closure bundle ACCEPTED and documented** (architecture-review Major 1): the registry edge makes `npx … add pr-workflow-subagent` resolve the transitive closure — 3 agents / 16 skills (was 2/10) and the markitdown MCP force-enabled via dependency-map.json. The closure exists to keep delegates functional; documented here + README row (1.4). Pruning markitdown-mcp-skill from documentation-subagent's allowlist, if ever desired, is a separate ticket with its own blast radius.

## Risk

Med (bounded): the registry edge changes the `add pr-workflow-subagent` install bundle (see Decisions) — accepted, documented. All other surfaces are low: single agent file + one README row + mechanical registry regen; no test pins the permission list; code-review-subagent's `delegates >= 4` init.bats assertion unaffected.
