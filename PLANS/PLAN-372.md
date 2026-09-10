# PLAN: Move uiux-reviewer-subagent to vision tier (native multimodal)

**Branch**: feat/372
**Issue**: https://github.com/darellchua2/opencode-config-template/issues/372
**Base**: main

## Acceptance Criteria

- [ ] `deploy/agent-tiers.json`: `uiux-reviewer-subagent` → `vision` (+ short `$comment` NOTE, house style)
- [ ] `uiux-reviewer-subagent.md` frontmatter `description`: native multimodal reading, image-analyzer delegation on failure/request
- [ ] `uiux-reviewer-subagent.md` Step 3 (~line 74): mandatory-delegation rule → native-first, delegate on request/failure
- [ ] `uiux-reviewer-subagent.md` §Screenshot Delegation Rule (~lines 107-109): replace text-only claims with hybrid rule + `Status: partial` escape hatch
- [ ] `uiux-review-skill/SKILL.md:65`: evidence gate accepts native multimodal reading OR image-analyzer evidence; still rejects vision-unbacked claims
- [ ] Root `AGENTS.md` tier table: uiux removed from reasoning row, added to vision row (+ fallback sentence)
- [ ] `deploy/registry.json` regenerated (`node deploy/build-registry.mjs`)
- [ ] `node deploy/resolve-models.mjs --dry-run` → uiux resolves to `zai-coding-plan/glm-5.3-flash`, guard exit 0
- [ ] `node deploy/build-registry.mjs --check` → no drift
- [ ] `rg "text-only"` on the two edited uiux files → no stale hits

## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---------------------|---------------------------|---------------------------------|-------------|
| `deploy/agent-tiers.json` | — | `resolve-models.mjs` (deploy-time model injection), `build-registry.mjs` (embeds `tier`), README/AGENTS tier tables (human docs) | med — a typo'd tier name breaks deploy resolution; guard in 1.2 fail-fasts |
| `opencode_app/.opencode/agents/uiux-reviewer-subagent.md` | `deploy/agent-tiers.json` (model injected at deploy time) | `deploy/registry.json` (generated: description, delegatesTo, tier), `responsive-audit-subagent.md` + `worktree-pipeline-skill` (delegation references — unchanged, still true) | med — description flows into registry, so 1.3 must run after 2.1… therefore registry regen is re-run in 4.2 |
| `opencode_app/.opencode/skills/uiux-review-skill/SKILL.md` | — | `uiux-reviewer-subagent.md` (loads it as rubric source of truth), `deploy/registry.json` (requiresSkills) | low |
| `AGENTS.md` (root, tier table) | `deploy/agent-tiers.json` (mirrors it) | human readers; `deploy/.AGENTS.md` does NOT contain the table (verified) | low |
| `deploy/registry.json` | generated from agent-tiers.json + agent/skill frontmatter | installer (`init.mjs`, `setup.sh` counts), CI `--check` drift gate | low (generated artifact) |

**Cross-module consumers exist** (deploy tooling consumes the tier registry) → architecture review selected at Step 7. No frontend signal (no tsx/jsx/vue/svelte/css) → uiux review skipped. Freshly generated PLAN → requirements review selected.

## Implementation Phases

### Phase 1: Tier registry + resolution guard
- [ ] **1.1** In `deploy/agent-tiers.json`, change line 16 to `"uiux-reviewer-subagent": "vision"` and append one `$comment` NOTE sentence documenting the move (house style of the #294/#357 NOTEs)
    — **Why:** tier registry is the source of truth; every other surface (model injection, registry, docs) derives from it, so it must flip first
    — **Done when:** file is valid JSON, the entry reads `"vision"`, and the `$comment` NOTE names the reviewer and the vision rationale
    — **Consumers affected:** `resolve-models.mjs`, `build-registry.mjs`, AGENTS.md tier table
- [ ] **1.2** Run `node deploy/resolve-models.mjs --agents-src opencode_app/.opencode/agents --agents-dest /tmp/opencode/plan-372 --tiers deploy/agent-tiers.json --default-map deploy/models.default.json --provider-models deploy/provider-models.json --dry-run` and confirm the guard exits 0 with `uiux-reviewer-subagent` resolving to `zai-coding-plan/glm-5.3-flash`
    — **Why:** fail-fast proof that the tier move resolves cleanly under the Z.AI default map and every provider guard, before any prose or generated files change
    — **Done when:** command exit 0 and its output line for `uiux-reviewer-subagent` shows `zai-coding-plan/glm-5.3-flash`
    — **Consumers affected:** none (verification only)

### Phase 2: Agent prose — hybrid vision policy
- [ ] **2.1** In `opencode_app/.opencode/agents/uiux-reviewer-subagent.md`, rewrite the frontmatter `description` to: review-only UI/UX design review — 13-axis rubric over screenshots, source, live URLs; native multimodal screenshot reading with image-analyzer delegation on failure or request
    — **Why:** the description drives invocation routing AND flows into `deploy/registry.json`; leaving "delegates screenshots to image-analyzer" would understate the new native capability in both places
    — **Done when:** description reads ≤1024 chars, preserves the review-trigger phrasing, and mentions native multimodal reading
    — **Consumers affected:** `deploy/registry.json` (regenerated in 4.2), primary-session routing
- [ ] **2.2** Rewrite Step 3 (~line 74): replace the "Mandatory delegation rule: the primary session is text-only — you MUST NOT attempt to interpret screenshot pixels yourself" block with native-first interpretation of captured screenshots at each breakpoint, delegating to `image-analyzer-subagent` via the Task tool only when explicitly requested or when native perception fails, keeping the expected-output finding-schema contract
    — **Why:** the operative workflow step still mandates universal delegation, which would leave the vision-tier capability unused and contradict 2.1
    — **Done when:** Step 3 states native interpretation as primary, delegation as conditional, and retains the rubric-question + finding-schema handoff text for the delegated path
    — **Consumers affected:** `uiux-review-skill` §evidence gate (aligned in 3.1)
- [ ] **2.3** Rewrite §Screenshot Delegation Rule (~lines 107-109) from the text-only hard constraint to the hybrid rule — mirror `error-resolver-subagent.md:64-71` phrasing: runs on `zai-coding-plan/glm-5.3-flash` and sees screenshots directly; delegate to `image-analyzer-subagent` on explicit request or native-perception failure; if both paths are unavailable report `Status: partial` with `Issues: visual findings unavailable` — never fabricate visual findings; also reword the line-103 reference to "the `image-analyzer-subagent` delegation rule" to match
    — **Why:** these are the hard-constraint statements that forbid what the new model can do; stale text-only claims would make the agent self-describe a false capability limit
    — **Done when:** `rg -n "text-only" opencode_app/.opencode/agents/uiux-reviewer-subagent.md` returns no hits and the no-fabrication escape hatch survives
    — **Consumers affected:** `responsive-audit-subagent.md` + `worktree-pipeline-skill` delegation references (verified still-true: delegation path continues to exist)

### Phase 3: Skill evidence gate
- [ ] **3.1** In `opencode_app/.opencode/skills/uiux-review-skill/SKILL.md` line 65, change the evidence check to accept screenshot evidence from native multimodal reviewer reading OR `image-analyzer-subagent`, rejecting only visual findings with no vision-derived backing (fabricated or code-inferred pixel claims)
    — **Why:** the current gate ("If screenshot interpreted inline, **reject**") would invalidate the reviewer's own native vision evidence — the exact capability this change ships
    — **Done when:** the gate names both valid evidence sources and keeps an explicit reject condition for vision-unbacked claims
    — **Consumers affected:** `uiux-reviewer-subagent` (its rubric source of truth)

### Phase 4: Docs, generated artifacts, verification gate
- [ ] **4.1** In root `AGENTS.md`, remove `uiux` from the reasoning row's reviewer list, add `uiux-reviewer-subagent` to the vision row's agent list, and fold it into the vision-fallback sentence
    — **Why:** the tier table is the human-facing mirror of `agent-tiers.json`; drifting tables misroute future tier decisions
    — **Done when:** `rg -n "language/uiux" AGENTS.md` returns nothing and the vision row names `uiux-reviewer-subagent`
    — **Consumers affected:** human readers; none programmatic
- [ ] **4.2** Regenerate `deploy/registry.json` via `node deploy/build-registry.mjs`, then run `node deploy/build-registry.mjs --check` (expect clean) and `rg -n "text-only" opencode_app/.opencode/agents/uiux-reviewer-subagent.md opencode_app/.opencode/skills/uiux-review-skill/SKILL.md` (expect no hits)
    — **Why:** the registry embeds `tier` and `description` and CI runs a `--check` drift gate — an unregenerated registry fails CI; the second regen (after Phase 2/3 prose) captures the new description
    — **Done when:** registry diff shows only the uiux tier/description fields, `--check` exits 0, and the stale-claim grep is empty
    — **Consumers affected:** installer registry consumers (`init.mjs`, `setup.sh` counts — counts unchanged)

## Technical Notes

- Source agent `.md` files ship no `model:` — the resolver injects it at deploy time from the tier registry. Nothing to edit in deployed copies.
- Blast radius pre-audited per `LEARNINGS/patterns/tier-model-swap-blast-radius.md`: all 7 surfaces. Explicitly NO change: `deploy/provider-presets.json` (every preset already maps the vision tier), `deploy/provider-models.json` (`glm-5.3-flash` natively mapped under `zai-coding-plan`), `deploy/setup.sh`/`setup.ps1` (no per-agent model echoes for uiux), README counts/tables (no per-agent model claims for uiux), and the "text-only" claims in `frontend-design-skill`/`image-analyzer-subagent`/`error-resolver-subagent` (they describe the primary session or their own fallbacks — still true).
- Vision policy (ticket decision): hybrid — native interpretation primary; delegation mandatory only on explicit request or native-perception failure (mirrors `error-resolver-subagent`).
- No dependency changes → no `npm install`/lockfile work. No runtime code → verification gate is the registry `--check` + resolver dry-run + grep sweeps.

## Dependencies

None — single contained change, no blocked-by tickets.

## Risks & Mitigation

| Risk | Mitigation |
|------|------------|
| Tier name typo breaks deploy resolution | Step 1.2 resolver dry-run guard immediately after the JSON edit |
| Registry drift fails CI | Step 4.2 regen + `--check` in the same phase; repo rule: registry committed with the change |
| Stale text-only prose left in sibling skills | Post-change grep sweep (4.2) scoped to the two edited uiux files; sibling claims verified still-true in Technical Notes |
| Reviewer hallucinating pixels if native perception silently unavailable | Hybrid rule keeps the no-fabrication escape hatch: both paths unavailable → `Status: partial` |
