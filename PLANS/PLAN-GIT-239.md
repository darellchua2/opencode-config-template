**Issue**: #239
**Title**: Add autoresearch skill suite (core + 3 domains + 3 subagents) and retrofit existing skills with iteration protocol
**Branch**: feat/239-autoresearch-skill-suite
**Status**: In Progress

## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---------------------|---------------------------|---------------------------------|-------------|
| `opencode_app/.opencode/skills/autoresearch-core-skill/SKILL.md` | — | All 3 domain skills (cite references), all retrofitted skills (cite references), `deploy/setup.sh`, `README.md` | critical — single source of truth for iteration protocol |
| `opencode_app/.opencode/skills/autoresearch-core-skill/references/*.md` (5 files) | — | Tier 1-3 retrofitted skills, domain skills | critical — cited by path from ~25 skills |
| `opencode_app/.opencode/skills/autoresearch-core-skill/scripts/{init_research.py,autoresearch-loop.sh,check_progress.sh}` | SKILL.md above | All 3 domain skills (invoke scripts) | high |
| `opencode_app/.opencode/skills/autoresearch-ml-skill/SKILL.md` | core-skill | `autoresearch-ml-subagent.md` (loads it), `deploy/setup.sh`, `README.md` | high |
| `opencode_app/.opencode/skills/autoresearch-code-skill/SKILL.md` | core-skill | `autoresearch-code-subagent.md`, `deploy/setup.sh`, `README.md` | high |
| `opencode_app/.opencode/skills/autoresearch-research-skill/SKILL.md` | core-skill | `autoresearch-research-subagent.md`, `deploy/setup.sh`, `README.md` | high |
| `opencode_app/.opencode/agents/autoresearch-{ml,code,research}-subagent.md` (3 files) | Domain skills above | `deploy/setup.sh`, `deploy/.AGENTS.md`, `README.md`, `opencode_app/README.md`, `opencode_app/AGENTS.md` | high |
| 25 retrofitted skills (Phases 3-5) | core-skill references exist | Their existing consumers (unchanged), maintainer-skill audit | medium — opt-in via env var preserves default behavior |
| `deploy/setup.sh` | All new files above | CI/CD, user deployments | high — count math |
| `deploy/setup.ps1` | All new files above | Windows deployments | medium — mirror of setup.sh |
| `README.md` | All new files above | Onboarding | medium |
| `deploy/.AGENTS.md` | 3 new subagents above | All user-space deployments via setup.sh (routing) | critical — without routing rows, subagents are deployed but undiscoverable |

## Implementation Phases

### Phase 1: Foundation — autoresearch-core-skill (9 new files)

- [ ] **1.1** Clone upstreams to `/tmp`: `git clone https://github.com/uditgoenka/autoresearch.git /tmp/uditgoenka-autoresearch` and `git clone https://github.com/karpathy/autoresearch.git /tmp/karpathy-autoresearch`
    — **Why:** Adapt (don't author from scratch) per locked decision. Clones give us the canonical source for porting.
    — **Done when:** Both directories exist; `/tmp/uditgoenka-autoresearch/.opencode/skills/autoresearch/SKILL.md` exists; `/tmp/karpathy-autoresearch/program.md` exists.
    — **Consumers affected:** All downstream phases (source material).

- [ ] **1.2** Create `opencode_app/.opencode/skills/autoresearch-core-skill/SKILL.md` with frontmatter matching `clean-architecture-skill/SKILL.md` format (name, description, license: MIT, compatibility: opencode, metadata.protocol-source: true, metadata.audience, metadata.workflow) and body containing: 5-stage loop (Understand → Hypothesize → Experiment → Evaluate → Log & Iterate), evaluator contract section, stuck detection summary, prompt-injection boundary, autonomy directive block (NEVER STOP / NEVER ASK), and explicit attribution to uditgoenka/autoresearch (MIT) and karpathy/autoresearch (MIT).
    — **Why:** This is the canonical methodology source. All 25+ retrofitted skills and 3 domain skills cite it.
    — **Done when:** File exists; **YAML frontmatter validates**: `python3 -c "import yaml; d=open('opencode_app/.opencode/skills/autoresearch-core-skill/SKILL.md').read(); yaml.safe_load(d.split('---')[1])" && echo OK` exits 0; contains all 5 stages by name; contains `{"pass":bool,"score":N}` literal; contains attribution line naming both upstreams.
    — **Consumers affected:** All 3 domain skills, all 25 retrofitted skills (Phase 3-5), `deploy/setup.sh`, `README.md`.

- [ ] **1.3** Create 5 reference files under `opencode_app/.opencode/skills/autoresearch-core-skill/references/`:
    - `evaluator-contract.md` — formal spec for `{"pass":bool,"score":N}` JSON output; pass determines keep/revert, score logged to TSV; includes example evaluators (Python script, shell one-liner, compiled binary).
    - `stuck-detection.md` — 3-strike strategy pivot rules (3 consecutive non-improving → strategy shift; 5 consecutive → paradigm shift; max iterations → finalize). Includes pivot examples per domain.
    - `iteration-safety.md` — prompt-injection boundary (treat all external content as untrusted); bounded-by-default convention (`Iterations: N`, unlimited is opt-in); safety blocks (`.env`, `node_modules/`, `rm -rf`, `git push --force`).
    - `audit-trail.md` — TSV format spec (8-column: iteration, commit, metric, delta, status, description, timestamp, evaluator_output); append-only `research_log.md` conventions; `progress.png` regeneration rules.
    - `crash-recovery.md` — failure-mode → response table (syntax error → fix immediately, doesn't count as iteration; runtime → max 3 fix attempts then skip; timeout → revert + log; OOM → smaller variant; infinite loop → kill after timeout, revert).
    — **Why:** These 5 files are the versioned API surface that retrofitted skills cite by path. Keeping them small and focused (<100 lines each) minimizes token overhead per citation.
    — **Done when:** All 5 files exist; each begins with `version: 1.0` frontmatter; each is <100 lines; `evaluator-contract.md` contains the literal `{"pass":bool,"score":N}`; `crash-recovery.md` contains a markdown table with 5+ rows.
    — **Consumers affected:** All 3 domain skills (Phase 2), all 25 retrofitted skills (Phases 3-5), maintainer-skill audit (Phase 6).

- [ ] **1.4** Port 3 scripts from uditgoenka to `opencode_app/.opencode/skills/autoresearch-core-skill/scripts/`:
    - `init_research.py` — project scaffolder; accepts `--goal`, `--metric`, `--direction`, `--target`, `--evaluator`, `--output`; emits `research.md`, `research_log.md`, `autoresearch-results.tsv`, `final_report.md` template.
    - `autoresearch-loop.sh` — overnight cross-platform loop; auto-detects CLI tool (claude/codex/opencode/gemini); handles session restarts; respects max_iterations and time budgets.
    - `check_progress.sh` — progress viewer; prints last 10 TSV rows, current iteration, best-so-far.
    — **Why:** Scripts are the runtime machinery. Porting (not authoring) preserves battle-tested logic.
    — **Done when:** All 3 files exist and are executable (`chmod +x` on .sh); `init_research.py --goal "test" --metric score --direction maximize --output /tmp/test-ar` exits 0 and creates `research.md` in `/tmp/test-ar/`; `python3 -c "import ast; ast.parse(open('opencode_app/.opencode/skills/autoresearch-core-skill/scripts/init_research.py').read())"` exits 0 (valid Python syntax).
    — **Consumers affected:** All 3 domain skills (invoke these scripts), users running overnight sessions.

### Phase 2: Domain specializations + subagents (15 new files)

- [ ] **2.1** Create `opencode_app/.opencode/skills/autoresearch-ml-skill/SKILL.md` with triggers ("ml training", "val_bpb", "model optimization", "GPU", "nanochat"), Tier 1 declaration (local bash + Python), citation to `autoresearch-core-skill/references/*.md`, and frontmatter `metadata.protocol: autoresearch-default-on` (always-on, no env var needed since this IS autoresearch).
    — **Why:** ML specialization. Triggers must be specific to avoid collision with code-skill.
    — **Done when:** File exists; YAML validates; description starts with `[Requires NVIDIA GPU]`; cites at least 3 core references by path.
    — **Consumers affected:** `autoresearch-ml-subagent.md`, `deploy/setup.sh`, `README.md`.

- [ ] **2.2** Port 3 ML templates to `opencode_app/.opencode/skills/autoresearch-ml-skill/templates/`:
    - `program.md` — verbatim from `/tmp/karpathy-autoresearch/program.md` with MIT license header prepended (`<!-- Source: karpathy/autoresearch (MIT). See LICENSE. -->`).
    - `prepare.py.template` — derived from karpathy's `prepare.py`, parameterized with `{{MAX_SEQ_LEN}}`, `{{EVAL_TOKENS}}`, `{{VOCAB_SIZE}}` placeholders for non-H100 platforms.
    - `train.py.template` — derived from karpathy's `train.py` with the simplicity criterion block from program.md embedded as a comment header.
    - `CPU-FORKS.md` — lists karpathy's notable CPU/macOS/Windows/AMD forks with one-line install instructions each (miolini/autoresearch-macos, trevin-creator/autoresearch-mlx, jsegov/autoresearch-win-rtx, andyluo7/autoresearch).
    — **Why:** Templates give users a runnable starting point. Karpathy's program.md is referenced verbatim per attribution rules.
    — **Done when:** All 4 files exist; `program.md` contains the MIT header comment AND the original `LOOP FOREVER:` directive; `CPU-FORKS.md` lists all 4 forks from karpathy's README.
    — **Consumers affected:** `autoresearch-ml-subagent.md`.

- [ ] **2.3** Create `opencode_app/.opencode/skills/autoresearch-code-skill/SKILL.md` with triggers ("optimize code", "test coverage", "bundle size", "performance", "fix errors", "reduce runtime"), Tier 1 declaration, citation to core references, frontmatter `metadata.protocol: autoresearch-default-on`. Include skill-specific override: "TDD maps test-pass → `pass:true`, pass-count → `score`".
    — **Why:** Code specialization. Trigger overlap with `tdd-workflow-skill` resolved by this skill being autonomous-loop-flavored (the other is single-cycle).
    — **Done when:** File exists; YAML validates; cites core references; contains the TDD mapping override.
    — **Consumers affected:** `autoresearch-code-subagent.md`, `deploy/setup.sh`, `README.md`.

- [ ] **2.4** Create 3 code templates under `opencode_app/.opencode/skills/autoresearch-code-skill/templates/`:
    - `benchmark.py.template` — emits `{"pass":bool,"score":N}` JSON; parameterized `{{COMMAND}}`, `{{METRIC_NAME}}`, `{{TARGET_VALUE}}`.
    - `research.md.code-template` — inline Goal/Scope/Metric/Verify/Guard format with examples for coverage, bundle size, runtime.
    - `guard.example.sh` — example safety-net command pattern (e.g., `npm test` must always pass while optimizing bundle size).
    — **Why:** Templates remove cold-start friction for the most common code-optimization use cases.
    — **Done when:** All 3 files exist; `benchmark.py.template` outputs valid JSON when run with placeholder substitution.
    — **Consumers affected:** `autoresearch-code-subagent.md`.

- [ ] **2.5** Create `opencode_app/.opencode/skills/autoresearch-research-skill/SKILL.md` with triggers ("literature review", "paper synthesis", "research papers", "survey"), Tier 2 declaration (web-only, no Bash), citation to core references, frontmatter `metadata.protocol: autoresearch-default-on`. Include skill-specific override: "Literature review uses agent-as-evaluator (Tier 2 fallback per uditgoenka spec) when no mechanical evaluator applies".
    — **Why:** Literature review is the one use case where mechanical evaluation may not apply; the skill must declare this honestly.
    — **Done when:** File exists; YAML validates; explicitly declares Tier 2 mode; contains the agent-evaluator override.
    — **Consumers affected:** `autoresearch-research-subagent.md`, `deploy/setup.sh`, `README.md`.

- [ ] **2.6** Create 2 research templates under `opencode_app/.opencode/skills/autoresearch-research-skill/templates/`:
    - `research.md.litreview-template` — living-state format with categories-covered tracking, paper count, gaps identified.
    - `paper-synthesis.template` — structured paper summary format (citation, abstract, methodology, key findings, limitations, relevance to research goal).
    — **Why:** Templates encode the lit-review-specific state shape that differs from code/ml research.md.
    — **Done when:** Both files exist; litreview template has a categories-covered tracking section.
    — **Consumers affected:** `autoresearch-research-subagent.md`.

- [ ] **2.7** Create `opencode_app/.opencode/agents/autoresearch-ml-subagent.md` modeled on `loop-operator-subagent.md` frontmatter (mode: subagent, model: zai-coding-plan/glm-5.1, steps: 50, permissions: read:allow, edit:allow with `**/train.py:allow` constraint noted in body, glob:allow, grep:allow, bash:allow, task:{"*":deny, explore:allow}, skill:{"*":deny, autoresearch-core-skill:allow, autoresearch-ml-skill:allow, strategic-compact-skill:allow}). Include Prompt Defense Baseline verbatim from `loop-operator-subagent.md`. Include GPU preflight check (first body section): run `python -c "import torch; print(torch.cuda.is_available())"` or `nvidia-smi`; if both fail, return structured error pointing to CPU-FORKS.md and suggest rerouting to `autoresearch-code-subagent`. Include Return Contract (4-field).
    — **Why:** Subagent is the execution layer; correct model tier (glm-5.1 sound-reasoning) is mandatory per AGENTS.md; GPU preflight prevents confusing failures on non-GPU machines.
    — **Done when:** File exists; YAML validates; model field is exactly `zai-coding-plan/glm-5.1` (NEVER glm-5.2); GPU preflight section is the first body section; Prompt Defense Baseline matches loop-operator-subagent.md exactly (diff = 0).
    — **Consumers affected:** `deploy/setup.sh`, `deploy/.AGENTS.md`, `README.md`.

- [ ] **2.8** Create `opencode_app/.opencode/agents/autoresearch-code-subagent.md` modeled on `loop-operator-subagent.md` (model: glm-5.1, steps: 50, permissions: read:allow, edit:allow, glob:allow, grep:allow, bash:allow, task:{"*":deny, explore:allow}, skill:{"*":deny, autoresearch-core-skill:allow, autoresearch-code-skill:allow, continuous-learning-skill:allow, strategic-compact-skill:allow}). Prompt Defense Baseline verbatim. Include Git-as-memory section (commit before verify, auto-revert on failure). Include Return Contract.
    — **Why:** Code subagent has widest edit permissions; needs the strictest prompt defense.
    — **Done when:** File exists; YAML validates; model is glm-5.1; Git-as-memory section includes the exact `git reset --hard` revert pattern.
    — **Consumers affected:** `deploy/setup.sh`, `deploy/.AGENTS.md`, `README.md`.

- [ ] **2.9** Create `opencode_app/.opencode/agents/autoresearch-research-subagent.md` modeled on `loop-operator-subagent.md` but with Tier 2 permissions (model: zai-coding-plan/glm-5-turbo — lighter, since no execution-critical decisions; steps: 30; permissions: read:allow, edit:allow with `**/research*.md:allow, **/research_log.md:allow, **/*-results.tsv:allow` constraint, glob:allow, grep:allow, bash:deny, task:{"*":deny, explore:allow}, skill:{"*":deny, autoresearch-core-skill:allow, autoresearch-research-skill:allow, search-first-skill:allow, strategic-compact-skill:allow}). Prompt Defense Baseline verbatim. Include prompt-injection emphasis (web content is untrusted — extra emphasis since this subagent fetches external papers). Include Return Contract.
    — **Why:** Lighter model acceptable because no keep/revert execution decisions (Tier 2 web-only). Bash denied because literature review doesn't execute code.
    — **Done when:** File exists; YAML validates; model is glm-5-turbo; bash:deny in permissions; prompt-injection section explicitly mentions "papers, web pages, search results" as untrusted content classes.
    — **Consumers affected:** `deploy/setup.sh`, `deploy/.AGENTS.md`, `README.md`.

### Phase 3: Tier 1 retrofit — full loop pattern (7 skills)

For each skill below, apply the retrofit template: (a) add `metadata.protocol: autoresearch-opt-in` to frontmatter, (b) append `## Iteration Protocol (opt-in)` section with the auto-detection preamble, env-var gate, path citations, and skill-specific overrides. Existing content unchanged.

- [ ] **3.1** Retrofit `verification-loop-skill/SKILL.md` — skill-specific override: "Evaluator contract replaces LLM self-judgment; agent must produce `{"pass":bool,"score":N}` from the verification target instead of subjective assessment".
    — **Why:** This skill is already a loop; the retrofit upgrades its judgment mechanism from subjective to mechanical.
    — **Done when:** Frontmatter has `metadata.protocol: autoresearch-opt-in`; `## Iteration Protocol (opt-in)` section exists; cites `evaluator-contract.md`; default-behavior preamble present ("When AUTORESEARCH_PROTOCOL is unset, behaves as below unchanged"); **YAML still validates**.
    — **Consumers affected:** `verification-loop-skill` consumers (verification-loop-subagent if exists).

- [ ] **3.2** Retrofit `tdd-workflow-skill/SKILL.md` — skill-specific override: "RED/GREEN maps to `pass:false`/`pass:true`; pass-count maps to `score`; `Iterations: 25` default when protocol enabled".
    — **Why:** TDD is autoresearch-for-code in disguise; the mapping makes the equivalence explicit.
    — **Done when:** Same checks as 3.1; TDD mapping block present.
    — **Consumers affected:** `tdd-subagent`.

- [ ] **3.3** Retrofit `eval-harness-skill/SKILL.md` — skill-specific override: "Adds TSV audit trail (`eval-harness-results.tsv`) and overnight persistence via `autoresearch-loop.sh`".
    — **Why:** Eval harness explicitly evaluates; retrofit adds the iteration machinery around it.
    — **Done when:** Same checks as 3.1; TSV filename override present.
    — **Consumers affected:** None directly (eval harness typically invoked by other skills).

- [ ] **3.4** Retrofit `continuous-learning-skill/SKILL.md` — skill-specific override: "Subjective confidence scores → mechanical `{"pass":bool,"score":N}` from a validation eval (e.g., does the learned pattern reproduce on a held-out test?)".
    — **Why:** Learning without mechanical validation is speculation; retrofit adds the eval gate.
    — **Done when:** Same checks as 3.1.
    — **Consumers affected:** Many subagents that invoke continuous-learning for post-task learning.

- [ ] **3.5** Retrofit `deprecated-code-cleanup-skill/SKILL.md` — skill-specific override: "Adds git-as-memory: commit before each tier-N removal; auto-revert if typecheck fails after removal".
    — **Why:** This skill is already tier-aware; retrofit adds the git safety net.
    — **Done when:** Same checks as 3.1; git-as-memory override present.
    — **Consumers affected:** None directly.

- [ ] **3.6** Retrofit `linting-workflow-skill/SKILL.md` — skill-specific override: "Adds stuck-detection (3-strike pivot to different rule category) and crash recovery table (syntax → fix immediately, etc.)".
    — **Why:** Linting fix cycles currently have no plateau detection.
    — **Done when:** Same checks as 3.1.
    — **Consumers affected:** `linting-subagent`.

- [ ] **3.7** Retrofit `coverage-readme-workflow-skill/SKILL.md` — skill-specific override: "Converts one-shot coverage display into full iteration loop targeting a coverage percentage; emits `coverage-results.tsv`".
    — **Why:** Currently one-shot; retrofit unlocks the iterative-improvement use case.
    — **Done when:** Same checks as 3.1; iteration-loop override present.
    — **Consumers affected:** `coverage-subagent`.

### Phase 4: Tier 2 retrofit — partial patterns (8 skills)

For each skill below, append a shorter `## Iteration Protocol (opt-in)` section citing only the relevant references (not all 4). No full loop pattern — just the specific patterns each skill adopts.

- [ ] **4.1** Retrofit `documentation-consistency-skill/SKILL.md` — cites `audit-trail.md` + `crash-recovery.md` only.
    — **Done when:** Frontmatter flag present; section cites exactly 2 references.
- [ ] **4.2** Retrofit `error-resolver-workflow-skill/SKILL.md` — adds falsifiable-hypothesis protocol (port from uditgoenka's `/autoresearch:debug`); cites `evaluator-contract.md`.
    — **Done when:** Falsifiable-hypothesis section present; cites evaluator-contract.
- [ ] **4.3** Retrofit `opencode-skills-maintainer-skill/SKILL.md` — cites `evaluator-contract.md` + `stuck-detection.md`; adds the citation-drift check rule (Phase 6 task 6.1 must align with this).
    — **Done when:** Cites both references; citation-drift rule section present.
- [ ] **4.4** Retrofit `plan-execution-skill/SKILL.md` — cites `stuck-detection.md`; adds bounded-by-default (`Iterations: N`) language.
    — **Done when:** Cites stuck-detection; Iterations language present.
- [ ] **4.5** Retrofit `pr-creation-workflow-skill/SKILL.md` — adds Guard pattern (verify vs guard separation); cites `evaluator-contract.md`.
    — **Done when:** Guard-vs-verify distinction documented; cites evaluator-contract.
- [ ] **4.6** Retrofit `pr-merge-workflow-skill/SKILL.md` — cites `crash-recovery.md`; adds CI auto-fix crash recovery table.
    — **Done when:** Cites crash-recovery; CI failure-mode table present.
- [ ] **4.7** Retrofit `react-nextjs-antipatterns-skill/SKILL.md` — adds detect→fix cycle with revert; cites `evaluator-contract.md` + `audit-trail.md`.
    — **Done when:** Cites both references; detect→fix→revert cycle documented.
- [ ] **4.8** Retrofit `playwright-responsive-audit-skill/SKILL.md` — adds TSV trail + evaluator contract (already a closed loop per its description); cites `audit-trail.md` + `evaluator-contract.md`.
    — **Done when:** Cites both references; TSV filename override present.

### Phase 5: Tier 3 retrofit — light safety pass (~12-15 skills)

For each skill below, add (a) prompt-injection boundary paragraph citing `iteration-safety.md`, (b) bounded-by-default note where applicable. **Selection criteria:** skill must match at least one of (i) description contains "search/fetch/research/audit/web/external", (ii) has "loop/iterate/until" pattern, (iii) frontmatter declares WebFetch/WebSearch. **Hard cap: 15 skills.**

- [ ] **5.1** Apply Tier 3 retrofit (in this order, stop at cap):
    1. `search-first-skill` — fetches external content; full Tier 3 treatment
    2. `api-design-skill` — fetches API docs; prompt-injection boundary
    3. `security-audit-skill` — handles untrusted code; prompt-injection boundary
    4. `code-smells-skill` — iterative detection; bounded-by-default
    5. `performance-optimization-skill` — iterative profiling; bounded-by-default
    6. `typescript-dry-principle-skill` — iterative refactor; bounded-by-default
    7. `solid-principles-skill` — iterative review; bounded-by-default
    8. `clean-code-skill` — iterative review; bounded-by-default
    9. `test-generator-framework-skill` — iterative gen; bounded-by-default
    10. `python-pytest-creator-skill` — iterative gen; bounded-by-default
    11. `nextjs-unit-test-creator-skill` — iterative gen; bounded-by-default
    12. `nextjs-pr-workflow-skill` — phased workflow; bounded-by-default
    13. `mermaid-diagram-creator-skill` — iterative refinement; bounded-by-default
    14. `wireframer-skill` — iterative design; bounded-by-default
    15. `frontend-design-skill` — iterative design; bounded-by-default
    — **Why:** Cap of 15 enforced per Risk 5 mitigation. Borderline cases (e.g., `pr-workflow-subagent`-adjacent skills) deferred to a follow-up issue.
    — **Done when:** Each retrofitted skill has prompt-injection boundary paragraph citing `iteration-safety.md` by path; bounded-by-default note where applicable; **YAML still validates** for each.
    — **Consumers affected:** All consumers of these 15 skills (behavior unchanged by default).

### Phase 6: Maintenance + tests

- [ ] **6.1** Update `opencode-skills-maintainer-skill/SKILL.md` to add new audit rule: "Citation drift — flag any SKILL.md containing iteration-related keywords (`{"pass"`, `Iterations:`, `results.tsv`, `keep/revert`, `stuck detection`) WITHOUT a corresponding `autoresearch-core-skill/references/` citation. Also verify `metadata.protocol: autoresearch-opt-in` frontmatter is present iff `## Iteration Protocol` section is present."
    — **Why:** Without an automated check, citation drift is inevitable (Risk 2).
    — **Done when:** Rule section added; rule logic describes both keyword-presence-without-citation and frontmatter-section mismatch detection.
    — **Consumers affected:** Future skill edits (gated by this audit).

- [ ] **6.2** Create `tests/test_autoresearch_protocol.smoke.md` — for each retrofitted skill (Phases 3-5): assert (a) `## Iteration Protocol` section exists, (b) `metadata.protocol: autoresearch-opt-in` in frontmatter, (c) all path citations resolve (`autoresearch-core-skill/references/<name>.md` files exist).
    — **Why:** Smoke test catches missing sections, stale citations, frontmatter/section mismatch.
    — **Done when:** Test file exists; documents the 3 assertions per retrofitted skill; runnable via existing test harness.
    — **Consumers affected:** CI pipeline.

- [ ] **6.3** Create `tests/test_autoresearch_skills.smoke.md` — verify 4 new skills (autoresearch-core, -ml, -code, -research) and 3 new subagents (autoresearch-{ml,code,research}-subagent) load: (a) all 4 SKILL.md files have valid YAML frontmatter, (b) all 3 agent files have `model: zai-coding-plan/glm-5.X` (never `glm-5.2`), (c) all 3 agent files declare `permission.skill` allowing their respective domain skill.
    — **Why:** Structural integrity gate before deployment.
    — **Done when:** Test file exists; documents all 3 assertions; runnable via existing test harness.
    — **Consumers affected:** CI pipeline.

- [ ] **6.4** Create `tests/test_default_behavior.smoke.md` — for each retrofitted skill, verify default-behavior path still works when `AUTORESEARCH_PROTOCOL` is unset: (a) mandatory preamble language present ("When AUTORESEARCH_PROTOCOL is unset, behaves as below unchanged"), (b) iteration-specific tokens (`{"pass":bool,"score":N}`, `results.tsv`, `git reset --hard`) appear ONLY inside `## Iteration Protocol` section, not in default-behavior sections.
    — **Why:** Risk 4 mitigation — guarantees no subtle behavior change when env var unset.
    — **Done when:** Test file exists; documents the 2 assertions; runnable via existing test harness.
    — **Consumers affected:** CI pipeline, retrofitted-skill users.

### Phase 7: Documentation sync + verification gate

- [ ] **7.1** Update all count locations in `deploy/setup.sh`: agents `37 → 40`, skills `107 → 111`. Run `grep -niE "(37 agent|107 skill|36 subagent)" deploy/setup.sh` to find all occurrences first (case-insensitive — per PLAN-GIT-237 lesson learned). Update banner, status section, and any echo statements.
    — **Why:** Stale counts cause deployment mismatches.
    — **Done when:** `grep -niE "(37 agent|107 skill|36 subagent)" deploy/setup.sh` exits 1 (zero matches); `grep -nE "(40 agent|111 skill)" deploy/setup.sh` shows expected new counts.
    — **Consumers affected:** All user-space deployments.

- [ ] **7.2** Mirror updates in `deploy/setup.ps1`: agents `37 → 40`, skills `107 → 111`. Same case-insensitive grep approach.
    — **Done when:** `grep -niE "(37 agent|107 skill|36 subagent)" deploy/setup.ps1` exits 1.
    — **Consumers affected:** Windows deployments.

- [ ] **7.3** Update `README.md`:
    - Subagent count: `36 subagent → 39 subagent` (line ~23), `37 agent → 40 agent` (line ~308)
    - Skill count: `107 skill → 111 skill` (line ~24), `107 skills → 111 skills` (line ~280)
    - Add 3 rows to Subagents table: `autoresearch-ml-subagent`, `autoresearch-code-subagent`, `autoresearch-research-subagent` with model tier, allowed skills, allowed task delegations
    - Add 4 rows to Skill Categories table: `autoresearch-core-skill`, `autoresearch-ml-skill`, `autoresearch-code-skill`, `autoresearch-research-skill`
    - **New section**: `## Iteration Protocol (opt-in)` near skill categories — explain `AUTORESEARCH_PROTOCOL=1` env var, `ar-enable`/`ar-disable` shell helpers, link to `autoresearch-core-skill/references/iteration-safety.md`, list which skills are retrofitted
    - **New column** in Skill Categories table: `Protocol` — values: `default-on` (3 domain skills), `opt-in` (retrofitted skills), `—` (untouched)
    — **Why:** README is the discovery surface — without the new section and column, the protocol is invisible (Risk 3 Layer D mitigation).
    — **Done when:** All count references updated; 3 subagent rows + 4 skill rows added; Iteration Protocol section exists; Protocol column populated for all skills.
    — **Consumers affected:** All repo consumers.

- [ ] **7.4** Update `opencode_app/README.md` (Docker standalone):
    - Agent count references: `37 → 40`
    - Skill count references: `107 → 111`
    - Explicit-perm count update: `24 of 37 → 27 of 40` (3 new subagents all have explicit `task:` blocks; numerator +3, denominator +3, defaulters unchanged at 13)
    — **Why:** Docker README mirrors user-space README. Compound update per PLAN-GIT-237 lesson.
    — **Done when:** `grep -nE "24 of 37|37 agent|107 skill" opencode_app/README.md` exits 1.
    — **Consumers affected:** Docker standalone users.

- [ ] **7.5** Update `deploy/.AGENTS.md` — add 3 rows to the Subagent Routing Preferences table (positioned before "All other tasks"):
    - `| ML training / model optimization | \`autoresearch-ml-subagent\` | — | Karpathy-style autonomous ML experiments. Requires NVIDIA GPU. Triggers on "ml training", "val_bpb", "nanochat". |`
    - `| Code optimization / iterative improvement | \`autoresearch-code-subagent\` | — | Autonomous modify→verify→keep/revert loop for code, tests, bundle size, runtime. Triggers on "optimize", "iterate until", "improve coverage". |`
    - `| Literature review / paper synthesis | \`autoresearch-research-subagent\` | — | Tier 2 (web-only) research loop. No code execution. Triggers on "literature review", "paper synthesis", "research papers". |`
    — **Why:** Without routing rows, subagents deploy but are undiscoverable at runtime (PLAN-GIT-237 lesson).
    — **Done when:** `grep -n "autoresearch-.*-subagent" deploy/.AGENTS.md` returns ≥3 matches.
    — **Consumers affected:** All user-space deployments via setup.sh.

- [ ] **7.6** Update `opencode_app/AGENTS.md` (Docker) — add the 3 new subagents to the CodeGraph Subagent Integration table with `codegraph_files`, `codegraph_search` for code-subagent and research-subagent; nothing for ml-subagent (no codebase interaction).
    — **Why:** Docker AGENTS.md documents CodeGraph usage per subagent.
    — **Done when:** `grep -n "autoresearch-.*-subagent" opencode_app/AGENTS.md` returns ≥2 matches (code + research subagents).
    — **Consumers affected:** Docker standalone users.

- [ ] **7.7** Update `deploy/setup.sh` to install `ar-enable` / `ar-disable` shell helpers to `~/.bashrc` and `~/.zshrc` (Risk 3 Layer C mitigation). Helpers:
    ```bash
    ar-enable()  { export AUTORESEARCH_PROTOCOL=1; echo "autoresearch protocol: ON"; }
    ar-disable() { unset AUTORESEARCH_PROTOCOL;   echo "autoresearch protocol: OFF"; }
    ```
    — **Why:** Removes "I forgot the env var name" friction (Risk 3).
    — **Done when:** setup.sh contains both function definitions in the install block; idempotent (won't duplicate on re-run); guarded by `grep -q ar-enable ~/.bashrc` check.
    — **Consumers affected:** All users running setup.sh.

- [ ] **7.8** Final verification gate:
    ```bash
    # Stale counts (must exit 1 — zero matches)
    grep -rniE "(37 agent|107 skill|36 subagent)" deploy/ README.md opencode_app/README.md opencode_app/AGENTS.md
    
    # New counts present
    grep -nE "(40 agent|111 skill|39 subagent)" deploy/setup.sh README.md
    
    # All new files non-empty
    wc -l opencode_app/.opencode/skills/autoresearch-{core,ml,code,research}-skill/SKILL.md
    wc -l opencode_app/.opencode/agents/autoresearch-{ml,code,research}-subagent.md
    
    # All YAML valid
    for f in opencode_app/.opencode/skills/autoresearch-*-skill/SKILL.md opencode_app/.opencode/agents/autoresearch-*-subagent.md; do
      python3 -c "import yaml; d=open('$f').read(); yaml.safe_load(d.split('---')[1])" && echo "OK: $f" || echo "FAIL: $f"
    done
    
    # No subagent uses glm-5.2
    grep -l "glm-5.2" opencode_app/.opencode/agents/autoresearch-*-subagent.md && echo "FAIL: glm-5.2 leak" || echo "OK: no glm-5.2"
    ```
    — **Why:** Atomicity gate before PR.
    — **Done when:** All commands pass (stale-count grep exits 1, all others exit 0).
    — **Consumers affected:** All downstream consumers.

### Phase 8: Sample invocation verification (post-merge pre-release)

- [ ] **8.1** Set `AUTORESEARCH_PROTOCOL=1`, invoke `tdd-workflow-skill` on a test repo with a coverage goal. Verify `<skill>-results.tsv` appears, evaluator contract is honored, no LLM self-judgment in keep/revert decisions.
    — **Why:** End-to-end validation that the retrofit actually works.
    — **Done when:** TSV file appears with ≥1 row; no crash; revert-on-failure works.
    — **Consumers affected:** All protocol-enabled users.

- [ ] **8.2** With `AUTORESEARCH_PROTOCOL` unset, invoke `tdd-workflow-skill` on an iterative task. Verify auto-detection prompt appears once per session ("This looks iterative. Enable protocol? y/n"). Answer "n" and verify default behavior; answer "y" and verify protocol engages.
    — **Why:** Validates the Risk 3 Layer A auto-detection mechanism.
    — **Done when:** Prompt appears once; both y/n paths behave correctly; no re-prompt after answer.
    — **Consumers affected:** All retrofitted-skill users.

- [ ] **8.3** Invoke `autoresearch-ml-subagent` on a non-GPU machine. Verify preflight check returns structured error pointing to CPU-FORKS.md and suggesting reroute to `autoresearch-code-subagent`.
    — **Why:** Risk 6 graceful degradation.
    — **Done when:** Subagent returns error within 1 step; error message names the 4 CPU forks; suggests reroute.

## Risks tracked (full list in issue #239)

| # | Risk | Mitigation summary |
|---|------|-------------------|
| 1 | Token budget across waves | Per-wave subagent isolation; bulk-edit for Tier 3; smoke gates between phases |
| 2 | Citation drift | Phase 6.1 maintainer check + versioned references + CI gate via documentation-consistency-skill |
| 3 | Env var discoverability | 6-layer: auto-detection (3.x retrofits) + setup.sh banner + ar-enable helpers (7.7) + README column (7.3) + metadata flag + default-on for domain skills |
| 4 | Subtle behavior change when unset | Mandatory preamble (Phase 6.4 test) + strict section ordering + maintainer grep (6.1) |
| 5 | Phase 5 boundary fuzzy | Deterministic selection criteria; hard cap 15; deferred-overflow issue |
| 6 | ML subagent GPU requirement | Preflight check (2.7); CPU-FORKS.md (2.2); graceful reroute to code-subagent |
| 7 | Reference versioning burden | `version: 1.0` per reference; SemVer policy; Phase 6.1 version-citation check |

## Delegation strategy

| Wave | Subagent | Scope | Phases | Est. files |
|------|----------|-------|--------|------------|
| 1 | opencode-tooling-subagent | Foundation + domain build | 1 + 2 | 24 new |
| 2 | opencode-tooling-subagent | Tier 1 retrofit | 3 | 7 edits |
| 3 | opencode-tooling-subagent | Tier 2 retrofit | 4 | 8 edits |
| 4 | opencode-tooling-subagent | Tier 3 retrofit (bulk) | 5 | ~15 edits |
| 5 | opencode-tooling-subagent | Maintenance + tests | 6 | 4 new + 1 edit |
| 6 | documentation-subagent | Docs sync | 7 | 6 edits |
| 7 | (manual / primary) | Sample invocation verification | 8 | 0 edits |

**Compaction checkpoint between waves** — invoke `strategic-compact-skill` if primary context > 60% before spawning next wave.

## Attribution

- **uditgoenka/autoresearch** (MIT) — primary source for SKILL.md body, scripts, evaluator contract, command structure. File-level attribution in `autoresearch-core-skill/SKILL.md` References section.
- **karpathy/autoresearch** (MIT) — source for ML templates (program.md verbatim with license header). File-level attribution in `autoresearch-ml-skill/templates/program.md`.
- **wjgoarxiv/autoresearch-skill** (MIT) — inspiration for the strict `{"pass":bool,"score":N}` evaluator contract (we adopt this on top of uditgoenka). Mentioned in `autoresearch-core-skill/SKILL.md` References.
