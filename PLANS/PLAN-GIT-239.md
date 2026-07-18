**Issue**: #239
**Title**: Add autoresearch skill suite (core + 3 domains + 3 subagents) and retrofit existing skills with iteration protocol
**Branch**: feat/239-autoresearch-skill-suite
**Status**: In Progress (revised after opencode-tooling-subagent review — M1-M7, m1-m7, R1-R4 applied)

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

### Phase 1: Foundation — autoresearch-core-skill + THIRD_PARTY_LICENSES.md (10 new files)

- [ ] **1.1** Clone upstreams to `/tmp`: `git clone https://github.com/uditgoenka/autoresearch.git /tmp/uditgoenka-autoresearch` and `git clone https://github.com/karpathy/autoresearch.git /tmp/karpathy-autoresearch`
    — **Why:** Adapt (don't author from scratch) per locked decision. Clones give us the canonical source for porting.
    — **Done when:** Both directories exist; `/tmp/uditgoenka-autoresearch/.opencode/skills/autoresearch/SKILL.md` exists; `/tmp/karpathy-autoresearch/program.md` exists.
    — **Consumers affected:** All downstream phases (source material).

- [ ] **1.2** Create `opencode_app/.opencode/skills/autoresearch-core-skill/SKILL.md` with frontmatter matching `clean-architecture-skill/SKILL.md` format (name, description, **license: Apache-2.0** to match repo convention [M4], compatibility: opencode, metadata.protocol-source: true, metadata.audience, metadata.workflow). **Note [R3]:** `metadata.protocol-source` and `metadata.protocol` (used in retrofits) are informational-only — OpenCode's skill loader treats unknown `metadata.*` keys as passthrough; these fields have no runtime effect and are consumed only by the §6.1 maintainer grep. and body containing: 5-stage loop (Understand → Hypothesize → Experiment → Evaluate → Log & Iterate), evaluator contract section, stuck detection summary, prompt-injection boundary, autonomy directive block (NEVER STOP / NEVER ASK), and explicit attribution to uditgoenka/autoresearch (MIT) and karpathy/autoresearch (MIT).
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

- [ ] **1.5** Create `THIRD_PARTY_LICENSES.md` at repo root documenting upstream MIT-licensed sources we port from: **uditgoenka/autoresearch** (MIT — primary source for SKILL.md/scripts/evaluator-contract), **karpathy/autoresearch** (MIT — source for ML templates, program.md verbatim), **wjgoarxiv/autoresearch-skill** (MIT — inspiration for evaluator contract). For each: include the upstream's copyright line, the MIT license text verbatim, and a "What we ported" subsection listing specific files.
    — **Why [M5]:** Apache-2.0 §4(c) requires retaining upstream attribution notices when relicensing MIT content into Apache-2.0. A bare `<!-- See LICENSE -->` comment pointing at the repo's Apache file is insufficient — the original MIT terms must be preserved.
    — **Done when:** File exists at repo root; lists all 3 upstreams with verbatim MIT text; "What we ported" subsection per upstream references specific files (program.md, init_research.py, autoresearch-loop.sh, evaluator-contract.md).
    — **Consumers affected:** Legal review, downstream consumers, future contributors porting more content.

### Phase 2: Domain specializations + subagents (15 new files)

- [ ] **2.1** Create `opencode_app/.opencode/skills/autoresearch-ml-skill/SKILL.md` with triggers ("ml training", "val_bpb", "model optimization", "GPU", "nanochat"), Tier 1 declaration (local bash + Python), citation to `autoresearch-core-skill/references/*.md`, and frontmatter `metadata.protocol: autoresearch-default-on` (always-on, no env var needed since this IS autoresearch). Use `license: Apache-2.0` per repo convention [M4].
    — **Why:** ML specialization. Triggers must be specific to avoid collision with code-skill.
    — **Done when:** File exists; YAML validates; description starts with `[Requires NVIDIA GPU]`; cites at least 3 core references by path. (Forward-ref [R4]: templates including `CPU-FORKS.md` are gated by task 2.2's Done-when, not this task.)
    — **Consumers affected:** `autoresearch-ml-subagent.md`, `deploy/setup.sh`, `README.md`.

- [ ] **2.2** Port 3 ML templates to `opencode_app/.opencode/skills/autoresearch-ml-skill/templates/`:
    - `program.md` — verbatim from `/tmp/karpathy-autoresearch/program.md` with MIT license header prepended that **references `THIRD_PARTY_LICENSES.md`** (per task 1.5) for the full MIT text + copyright [M5]: `<!-- Source: karpathy/autoresearch (MIT). Full notice: THIRD_PARTY_LICENSES.md -->`.
    - `prepare.py.template` — derived from karpathy's `prepare.py`, parameterized with `{{MAX_SEQ_LEN}}`, `{{EVAL_TOKENS}}`, `{{VOCAB_SIZE}}` placeholders for non-H100 platforms.
    - `train.py.template` — derived from karpathy's `train.py` with the simplicity criterion block from program.md embedded as a comment header.
    - `CPU-FORKS.md` — lists karpathy's notable CPU/macOS/Windows/AMD forks with one-line install instructions each (miolini/autoresearch-macos, trevin-creator/autoresearch-mlx, jsegov/autoresearch-win-rtx, andyluo7/autoresearch).
    — **Why:** Templates give users a runnable starting point. Karpathy's program.md is referenced verbatim per attribution rules.
    — **Done when:** All 4 files exist; `program.md` contains the MIT header comment (referencing THIRD_PARTY_LICENSES.md) AND the original `LOOP FOREVER:` directive; `CPU-FORKS.md` lists all 4 forks from karpathy's README.
    — **Consumers affected:** `autoresearch-ml-subagent.md`.

- [ ] **2.3** Create `opencode_app/.opencode/skills/autoresearch-code-skill/SKILL.md` with triggers ("optimize code", "test coverage", "bundle size", "performance", "fix errors", "reduce runtime"), Tier 1 declaration, citation to core references, frontmatter `metadata.protocol: autoresearch-default-on`, `license: Apache-2.0` [M4]. Include skill-specific override: "TDD maps test-pass → `pass:true`, pass-count → `score`".
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

- [ ] **2.5** Create `opencode_app/.opencode/skills/autoresearch-research-skill/SKILL.md` with triggers ("literature review", "paper synthesis", "research papers", "survey"), Tier 2 declaration (web-only, no Bash), citation to core references, frontmatter `metadata.protocol: autoresearch-default-on`, `license: Apache-2.0` [M4]. Include skill-specific override: "Literature review uses agent-as-evaluator (Tier 2 fallback per uditgoenka spec) when no mechanical evaluator applies".
    — **Why:** Literature review is the one use case where mechanical evaluation may not apply; the skill must declare this honestly.
    — **Done when:** File exists; YAML validates; explicitly declares Tier 2 mode; contains the agent-evaluator override.
    — **Consumers affected:** `autoresearch-research-subagent.md`, `deploy/setup.sh`, `README.md`.

- [ ] **2.6** Create 2 research templates under `opencode_app/.opencode/skills/autoresearch-research-skill/templates/`:
    - `research.md.litreview-template` — living-state format with categories-covered tracking, paper count, gaps identified.
    - `paper-synthesis.template` — structured paper summary format (citation, abstract, methodology, key findings, limitations, relevance to research goal).
    — **Why:** Templates encode the lit-review-specific state shape that differs from code/ml research.md.
    — **Done when:** Both files exist; litreview template has a categories-covered tracking section.
    — **Consumers affected:** `autoresearch-research-subagent.md`.

- [ ] **2.7** Create `opencode_app/.opencode/agents/autoresearch-ml-subagent.md` modeled on `loop-operator-subagent.md` frontmatter (mode: subagent, model: zai-coding-plan/glm-5.1, steps: 50, permissions: read:allow, **edit as map form** `{"*": deny, "**/train.py": allow, "**/research*.md": allow, "**/research_log.md": allow, "**/*-results.tsv": allow}` [M7] — path-restriction enforced in permissions, not prose, glob:allow, grep:allow, bash:allow, task:{"*":deny, **explore: allow, general: allow**} [m1] — matches loop-operator-subagent.md:12-15 which allows both, skill:{"*":deny, autoresearch-core-skill:allow, autoresearch-ml-skill:allow, strategic-compact-skill:allow}). Include Prompt Defense Baseline verbatim from `loop-operator-subagent.md`. Include GPU preflight check (first body section): run `python -c "import torch; print(torch.cuda.is_available())"` or `nvidia-smi`; if both fail, return structured error pointing to CPU-FORKS.md and suggest rerouting to `autoresearch-code-subagent`. Include Return Contract (4-field).
    — **Why:** Subagent is the execution layer; correct model tier (glm-5.1 sound-reasoning) is mandatory per AGENTS.md; GPU preflight prevents confusing failures on non-GPU machines. **Map-form `edit` enforces the train.py-only constraint as a hard permission** (per code-review-subagent.md:8-10 pattern `edit: {"*": deny, "LEARNINGS/**": allow}`) — scalar `edit: allow` would grant full edit access despite prose constraints [M7].
    — **Done when:** File exists; YAML validates; model field is exactly `zai-coding-plan/glm-5.1` (NEVER glm-5.2); GPU preflight section is the first body section; Prompt Defense Baseline matches loop-operator-subagent.md exactly (diff = 0); `edit` permission is map form (not scalar); `task` block allows both `explore` and `general`.
    — **Consumers affected:** `deploy/setup.sh`, `deploy/.AGENTS.md`, `README.md`.

- [ ] **2.8** Create `opencode_app/.opencode/agents/autoresearch-code-subagent.md` modeled on `loop-operator-subagent.md` (model: glm-5.1, steps: 50, permissions: read:allow, edit:allow, glob:allow, grep:allow, bash:allow, task:{"*":deny, **explore: allow, general: allow**} [m1], skill:{"*":deny, autoresearch-core-skill:allow, autoresearch-code-skill:allow, continuous-learning-skill:allow, strategic-compact-skill:allow}). Prompt Defense Baseline verbatim. Include Git-as-memory section (commit before verify, auto-revert on failure). Include Return Contract.
    — **Why:** Code subagent has widest edit permissions; needs the strictest prompt defense.
    — **Done when:** File exists; YAML validates; model is glm-5.1; Git-as-memory section includes the exact `git reset --hard` revert pattern; `task` allows both explore + general.
    — **Consumers affected:** `deploy/setup.sh`, `deploy/.AGENTS.md`, `README.md`.

- [ ] **2.9** Create `opencode_app/.opencode/agents/autoresearch-research-subagent.md` modeled on `loop-operator-subagent.md` but with Tier 2 permissions (model: zai-coding-plan/glm-5-turbo — lighter, since no execution-critical decisions; steps: 30; permissions: read:allow, **edit as map form** `{"*": deny, "**/research*.md": allow, "**/research_log.md": allow, "**/*-results.tsv": allow}` [M7] — Tier 2 sandbox enforced as hard permission, glob:allow, grep:allow, bash:deny, **webfetch: allow, websearch: allow** [m2] — explicitly declared for auditability since this is a web-only agent, task:{"*":deny, **explore: allow, general: allow**} [m1], skill:{"*":deny, autoresearch-core-skill:allow, autoresearch-research-skill:allow, search-first-skill:allow, strategic-compact-skill:allow}). Prompt Defense Baseline verbatim. Include prompt-injection emphasis (web content is untrusted — extra emphasis since this subagent fetches external papers). Include Return Contract.
    — **Why:** Lighter model acceptable because no keep/revert execution decisions (Tier 2 web-only). Bash denied because literature review doesn't execute code. **`edit` map form is critical** — the prior `edit: allow` (scalar) would grant full write access, contradicting the Tier 2 sandbox framing and the explicit `bash: deny` hardening [M7]. Explicit `webfetch`/`websearch` declarations matter alongside `bash: deny` for symmetry [m2].
    — **Done when:** File exists; YAML validates; model is glm-5-turbo; `edit` is map form (not scalar `allow`); `bash: deny` in permissions; `webfetch: allow` and `websearch: allow` explicit; prompt-injection section explicitly mentions "papers, web pages, search results" as untrusted content classes.
    — **Consumers affected:** `deploy/setup.sh`, `deploy/.AGENTS.md`, `README.md`.

### Phase 3: Tier 1 retrofit — full loop pattern (7 skills)

For each skill below, apply the retrofit template: (a) add `metadata.protocol: autoresearch-opt-in` to frontmatter, (b) append `## Iteration Protocol (opt-in)` section with the auto-detection preamble, env-var gate, path citations, and skill-specific overrides. Existing content unchanged. **[m6]** The section preamble MUST use imperative gating language: "DO NOT execute any of the following unless `AUTORESEARCH_PROTOCOL=1` is set in your environment. When unset, this skill behaves exactly as documented in all sections below; the Iteration Protocol block is descriptive only." This is stronger than a soft "behaves as below unchanged" note and reduces (does not eliminate) the risk of agents following opt-in instructions when the env var is unset.

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

- [ ] **6.2** Create `tests/test_autoresearch_protocol.bats` (bats format, per existing harness `tests/cleanup_old_backups.bats`/`tests/parse_arguments.bats` [M6]) — for each retrofitted skill (Phases 3-5): assert (a) `## Iteration Protocol` section exists, (b) `metadata.protocol: autoresearch-opt-in` in frontmatter, (c) all path citations resolve (`autoresearch-core-skill/references/<name>.md` files exist). Use bats assertions: `assert_equal`, `assert_success`, `[ -f "$ref_file" ]`.
    — **Why [M6]:** The existing test harness is bats — `.md` test files are documentation-only and would not run. Smoke test catches missing sections, stale citations, frontmatter/section mismatch.
    — **Done when:** Test file exists at `tests/test_autoresearch_protocol.bats`; follows bats `@test` syntax used in `tests/cleanup_old_backups.bats`; documents the 3 assertions per retrofitted skill; `bats tests/test_autoresearch_protocol.bats` exits 0 (assuming retrofit complete).
    — **Consumers affected:** CI pipeline.

- [ ] **6.3** Create `tests/test_autoresearch_skills.bats` (bats format [M6]) — verify 4 new skills (autoresearch-core, -ml, -code, -research) and 3 new subagents (autoresearch-{ml,code,research}-subagent) load: (a) all 4 SKILL.md files have valid YAML frontmatter (use python3 + yaml.safe_load assertion), (b) all 3 agent files have `model: zai-coding-plan/glm-5.X` AND **never** `glm-5.2` (grep-based assertion), (c) all 3 agent files declare `permission.skill` allowing their respective domain skill (autoresearch-ml-subagent → autoresearch-ml-skill, etc.).
    — **Why [M6]:** Structural integrity gate before deployment. Bats format ensures it actually runs.
    — **Done when:** Test file exists at `tests/test_autoresearch_skills.bats`; uses bats `@test` blocks; documents all 3 assertions; `bats tests/test_autoresearch_skills.bats` exits 0.
    — **Consumers affected:** CI pipeline.

- [ ] **6.4** Create `tests/test_default_behavior.bats` (bats format [M6]) — for each retrofitted skill, verify default-behavior path still works when `AUTORESEARCH_PROTOCOL` is unset: (a) imperative-gating preamble language present ("DO NOT execute any of the following unless `AUTORESEARCH_PROTOCOL=1` is set" — stronger than prior soft "behaves as below unchanged" [m6]); (b) iteration-specific tokens (`{"pass":bool,"score":N}`, `results.tsv`, `git reset --hard`) appear ONLY inside the `## Iteration Protocol (opt-in)` section — **scope the grep to the section's line range** (lines between `## Iteration Protocol (opt-in)` header and next `^## ` header) to avoid false positives on adjacent default-behavior text [m7].
    — **Why [M6+m7]:** Risk 4 mitigation — guarantees no subtle behavior change when env var unset. Section-scoped grep avoids misfires on skills like tdd-workflow-skill whose default RED/GREEN "pass/fail" language neighbors `{"pass":bool,"score":N}`.
    — **Done when:** Test file exists at `tests/test_default_behavior.bats`; uses bats `@test` blocks; documents the 2 assertions; uses `awk` or `sed` to extract the Iteration Protocol section line range before grepping for tokens.
    — **Consumers affected:** CI pipeline, retrofitted-skill users.

- [ ] **6.5** Add a `test` job to `.github/workflows/release.yml` (or create new `.github/workflows/ci.yml` triggered on PR) that runs `bats tests/*.bats` on every PR to `main` or `dev` [M6]. Install bats in the runner via existing vendored copy at `tests/lib/bats-core/` (no apt install needed). Job should: (a) checkout, (b) discover `tests/*.bats`, (c) run each, (d) fail the workflow on any non-zero exit.
    — **Why [M6]:** Without a CI test job, even correct `.bats` files don't actually gate anything — the repo currently has zero test CI (verified: `.github/workflows/release.yml` runs only config.json validation + `bash -n setup.sh` + semantic-release).
    — **Done when:** Workflow file exists or updated; `test` job runs `bats tests/*.bats`; gates PR merge (status check required).
    — **Consumers affected:** All future PRs.

### Phase 7: Documentation sync + verification gate

- [ ] **7.1** Update all count locations in `deploy/setup.sh`: agents `37 → 40`, skills `107 → 111`. **[M1]** First run an **exhaustive** discovery grep that catches BOTH banner (`AGENTS (N):`/`SKILLS (N):`) AND prose (`N agents`/`N skills`) forms — the original PLAN-GIT-237 missed banner forms by using word-based regex:
    ```bash
    grep -nE "AGENTS \((36|37)\)|SKILLS \((106|107)\)|(36|37) agents?|(106|107) [Ss]kills?|(35|36) [Ss]ubagents?" deploy/setup.sh
    ```
    (Per review: verified stale banner locations at `deploy/setup.sh:503` `AGENTS (37):` and `:587` `SKILLS (107):` that the prior narrower regex would miss.) Update banner, status section, and any echo statements.
    — **Why:** Stale counts cause deployment mismatches. The banner-form miss is the exact same narrowness class PLAN-GIT-237 documented as a lesson learned — different word vs. parens flavor.
    — **Done when:** The expanded regex above exits 1 (zero matches); `grep -nE "AGENTS \(40\)|SKILLS \(111\)|(40) agents?|(111) [Ss]kills?|(39) [Ss]ubagents?" deploy/setup.sh` shows expected new counts.
    — **Consumers affected:** All user-space deployments.

- [ ] **7.2** Mirror updates in `deploy/setup.ps1`: agents `37 → 40`, skills `107 → 111`. Same exhaustive grep approach as 7.1 [M1]. Verified stale banner locations: `deploy/setup.ps1:338, 383, 1177, 1765`.
    — **Done when:** `grep -nE "AGENTS \((36|37)\)|SKILLS \((106|107)\)|(36|37) agents?|(106|107) [Ss]kills?|(35|36) [Ss]ubagents?" deploy/setup.ps1` exits 1.
    — **Consumers affected:** Windows deployments.

- [ ] **7.3** Update `README.md`:
    - Subagent count: **`37 subagent → 40 subagent`** at line ~23 [M2 — corrected from PLAN's erroneous `36 → 39`; actual is 37, target is +3 = 40]
    - Agent count reference: `37 agent → 40 agent` (line ~308)
    - Skill count: `107 skill → 111 skill` (line ~24), `107 skills → 111 skills` (line ~280)
    - Add 3 rows to Subagents table: `autoresearch-ml-subagent`, `autoresearch-code-subagent`, `autoresearch-research-subagent` with model tier, allowed skills, allowed task delegations
    - Add 4 rows to Skill Categories table: `autoresearch-core-skill`, `autoresearch-ml-skill`, `autoresearch-code-skill`, `autoresearch-research-skill`
    - **New section**: `## Iteration Protocol (opt-in)` near skill categories — explain `AUTORESEARCH_PROTOCOL=1` env var, `ar-enable`/`ar-disable` shell helpers, link to `autoresearch-core-skill/references/iteration-safety.md`, list which skills are retrofitted
    - **New column** in Skill Categories table: `Protocol` — values: `default-on` (3 domain skills), `opt-in` (retrofitted skills), `—` (untouched)
    — **Why [M2]:** README is the discovery surface — without the new section and column, the protocol is invisible (Risk 3 Layer D mitigation). The line-23 count correction is critical: the prior PLAN mis-stated the base as 36 when actual is 37, which would have left L23 stale.
    — **Done when:** `grep -nE "(36 subagent|37 subagent|37 agent|107 skill)" README.md` exits 1; `grep -nE "40 subagent|40 agent|111 skill" README.md` shows new counts; 3 subagent rows + 4 skill rows added; Iteration Protocol section exists; Protocol column populated for all skills.
    — **Consumers affected:** All repo consumers.

- [ ] **7.4** Update `opencode_app/README.md` (Docker standalone):
    - Agent count references: `37 → 40`
    - Skill count references: `107 → 111`
    - **Explicit-`task` count update [M3 — base count corrected]:** first re-verify the actual base count with `grep -l 'task:' opencode_app/.opencode/agents/*.md | wc -l` — review found the base is **23 of 37, 14 defaulters** (not 24/13 as previously claimed; `opencode_app/README.md:102` is itself drifted by 1). After adding the 3 new subagents (all have explicit `task:` blocks per tasks 2.7-2.9), the target is **`26 of 40, 14 defaulters`** (numerator 23+3=26, denominator 37+3=40, defaulters stay 14).
    — **Why:** Docker README mirrors user-space README. Compound update per PLAN-GIT-237 lesson, with corrected base [M3].
    — **Done when:** `grep -nE "(24 of 37|23 of 37|37 agent|107 skill)" opencode_app/README.md` exits 1; `grep -n "26 of 40" opencode_app/README.md` shows the corrected target.
    — **Consumers affected:** Docker standalone users.

- [ ] **7.5** Update `deploy/.AGENTS.md` — add 3 rows to the Subagent Routing Preferences table (positioned before "All other tasks"):
    - `| ML training / model optimization | \`autoresearch-ml-subagent\` | — | Karpathy-style autonomous ML experiments. Requires NVIDIA GPU. Triggers on "ml training", "val_bpb", "nanochat". |`
    - `| Code optimization / iterative improvement | \`autoresearch-code-subagent\` | — | Autonomous modify→verify→keep/revert loop for code, tests, bundle size, runtime. Triggers on "optimize", "iterate until", "improve coverage". |`
    - `| Literature review / paper synthesis | \`autoresearch-research-subagent\` | — | Tier 2 (web-only) research loop. No code execution. Triggers on "literature review", "paper synthesis", "research papers". |`
    — **Why:** Without routing rows, subagents deploy but are undiscoverable at runtime (PLAN-GIT-237 lesson).
    — **Done when:** `grep -n "autoresearch-.*-subagent" deploy/.AGENTS.md` returns ≥3 matches.
    — **Consumers affected:** All user-space deployments via setup.sh.

- [ ] **7.6** Update **both** CodeGraph Subagent Integration tables for consistency [m4]: `opencode_app/AGENTS.md` (Docker) AND `deploy/.AGENTS.md` (user-space — review found this table already stale, missing `linting`, `error-resolver`, `uiux-reviewer`). Add the 3 new subagents to both with `codegraph_files`, `codegraph_search` for code-subagent and research-subagent; nothing for ml-subagent (no codebase interaction). While editing `deploy/.AGENTS.md`, also backfill the 3 previously-missed entries (`linting-subagent`, `error-resolver-subagent`, `uiux-reviewer-subagent`) to bring it to parity with `opencode_app/AGENTS.md`.
    — **Why [m4]:** Without updating both tables, the split between the two parallel CodeGraph tables deepens. The Docker table already has 7 entries; the user-space table has only 5 (drifted). New subagents should land in both.
    — **Done when:** `grep -n "autoresearch-.*-subagent" opencode_app/AGENTS.md` returns ≥2 matches (code + research subagents); `grep -n "autoresearch-.*-subagent" deploy/.AGENTS.md` returns ≥2 matches; both tables now have the same set of subagents listed.
    — **Consumers affected:** Docker standalone users AND user-space deployments.

- [ ] **7.6.5** Update **repo-root `AGENTS.md` "Subagent Model Tiering" table** [m3] to append the 3 new subagent entries to their respective model tier rows:
    - Under `glm-5.1` row (currently: "reviewers, repo-ops-specialist, tdd, opentofu-explorer, loop-operator, opencode-tooling, technical-design-specialist"): append `, autoresearch-ml, autoresearch-code`
    - Under `glm-5-turbo` row (currently: "explorer, testing, setup, specialists, document creators, pr-workflow, ticket-creation, discovery-specialist, requirements-specialist"): append `, autoresearch-research`
    — **Why [m3]:** The Subagent Model Tiering table is the canonical mapping from subagent → model tier. Without these entries, the model assignment for the 3 new subagents is undocumented in the source-of-truth file (the routing table in `deploy/.AGENTS.md` covers routing, not model tier rationale).
    — **Done when:** `grep -n "autoresearch-ml\|autoresearch-code" AGENTS.md` returns ≥1 match in the glm-5.1 row context; `grep -n "autoresearch-research" AGENTS.md` returns ≥1 match in the glm-5-turbo row context.
    — **Consumers affected:** Contributors adding future subagents (model tier reference).

- [ ] **7.7** Update `deploy/setup.sh` to install `ar-enable` / `ar-disable` shell helpers **with shell-existence guards** [m5] (Risk 3 Layer C mitigation). Appending unconditionally would create a `.bashrc` on a zsh-only system (and vice versa), polluting the home directory. Helpers + guards:
    ```bash
    # Install only into rc files that already exist
    if [ -f "$HOME/.bashrc" ]; then
      grep -q 'ar-enable()' "$HOME/.bashrc" || cat <<'EOF' >> "$HOME/.bashrc"
    ar-enable()  { export AUTORESEARCH_PROTOCOL=1; echo "autoresearch protocol: ON"; }
    ar-disable() { unset AUTORESEARCH_PROTOCOL;   echo "autoresearch protocol: OFF"; }
    EOF
    fi
    if [ -f "$HOME/.zshrc" ]; then
      grep -q 'ar-enable()' "$HOME/.zshrc" || cat <<'EOF' >> "$HOME/.zshrc"
    ar-enable()  { export AUTORESEARCH_PROTOCOL=1; echo "autoresearch protocol: ON"; }
    ar-disable() { unset AUTORESEARCH_PROTOCOL;   echo "autoresearch protocol: OFF"; }
    EOF
    fi
    ```
    — **Why [m5]:** Removes "I forgot the env var name" friction (Risk 3) without polluting home dirs. The `[ -f ... ]` guard ensures we only append to rc files that already exist; the `grep -q` ensures idempotency (won't duplicate on re-run).
    — **Done when:** setup.sh contains the guarded install block; both helper functions defined; idempotent (re-running setup.sh doesn't duplicate entries).
    — **Consumers affected:** All users running setup.sh.

- [ ] **7.8** Final verification gate **[M1+M2 — expanded regex + corrected subagent count]**:
    ```bash
    # Stale counts — MUST exit 1 (zero matches). Expanded to catch banner AND prose forms.
    grep -rnE "AGENTS \((36|37)\)|SKILLS \((106|107)\)|(36|37) agents?|(106|107) [Ss]kills?|(35|36) [Ss]ubagents?" deploy/ README.md opencode_app/README.md opencode_app/AGENTS.md
    
    # New counts present — note subagent count is 40 (not 39 per M2 correction)
    grep -nE "AGENTS \(40\)|SKILLS \(111\)|40 agents?|111 [Ss]kills?|40 [Ss]ubagents?" deploy/setup.sh README.md
    
    # Explicit-task count corrected (26, not 27 per M3)
    grep -n "26 of 40" opencode_app/README.md
    
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
    — **Why:** Atomicity gate before PR. [M1] expanded regex catches both `AGENTS (37):` banner form and `37 agents` prose form (prior regex missed the banner — same class of bug as PLAN-GIT-237). [M2] subagent count corrected from 39 to 40 (the actual target after +3 from base 37).
    — **Done when:** All commands pass (stale-count grep exits 1, all others exit 0).
    — **Consumers affected:** All downstream consumers.

### Phase 8: Verification gates

**[R1 — restructured]** Tasks 8.1 and 8.2 are **pre-merge release gates** (run on the branch before opening the PR); 8.3 is post-merge (requires a non-GPU CI runner, which the repo doesn't currently have, so it stays manual). Moving 8.1/8.2 pre-merge avoids the cost of discovering retrofit defects in a follow-up fix commit after merge.

- [ ] **8.1 [PRE-MERGE]** Set `AUTORESEARCH_PROTOCOL=1`, invoke `tdd-workflow-skill` on a test repo with a coverage goal. Verify `<skill>-results.tsv` appears, evaluator contract is honored, no LLM self-judgment in keep/revert decisions.
    — **Why:** End-to-end validation that the retrofit actually works. Must run pre-merge so defects are caught before they hit `main`.
    — **Done when:** TSV file appears with ≥1 row; no crash; revert-on-failure works.
    — **Consumers affected:** All protocol-enabled users.

- [ ] **8.2 [PRE-MERGE]** With `AUTORESEARCH_PROTOCOL` unset, invoke `tdd-workflow-skill` on an iterative task. Verify auto-detection prompt appears once per session ("This looks iterative. Enable protocol? y/n"). Answer "n" and verify default behavior; answer "y" and verify protocol engages.
    — **Why:** Validates the Risk 3 Layer A auto-detection mechanism AND validates the m6 imperative-gating preamble actually works (Risk 4 residual limitation check).
    — **Done when:** Prompt appears once; both y/n paths behave correctly; no re-prompt after answer.
    — **Consumers affected:** All retrofitted-skill users.

- [ ] **8.3 [POST-MERGE, manual]** Invoke `autoresearch-ml-subagent` on a non-GPU machine. Verify preflight check returns structured error pointing to CPU-FORKS.md and suggesting reroute to `autoresearch-code-subagent`.
    — **Why:** Risk 6 graceful degradation. Stays post-merge because CI has no GPU; this is a manual verification on actual non-GPU hardware.
    — **Done when:** Subagent returns error within 1 step; error message names the 4 CPU forks; suggests reroute.

## Risks tracked (full list in issue #239)

| # | Risk | Mitigation summary |
|---|------|-------------------|
| 1 | Token budget across waves | Per-wave subagent isolation; **Wave 4 split into 4a/4b [R2]**; subagent-internal compaction checkpoints; smoke gates between phases |
| 2 | Citation drift | Phase 6.1 maintainer check + versioned references + CI gate via documentation-consistency-skill + **bats tests in CI [M6, task 6.5]** |
| 3 | Env var discoverability | 6-layer: auto-detection (3.x retrofits) + setup.sh banner + ar-enable helpers (7.7, **shell-guarded [m5]**) + README column (7.3) + metadata flag + default-on for domain skills |
| 4 | Subtle behavior change when unset | Mandatory imperative-gating preamble **[m6]** (Phase 6.4 test) + strict section ordering + maintainer grep (6.1). **Residual limitation acknowledged:** agents may still be subtly biased; Phase 8.2 verifies empirically. |
| 5 | Phase 5 boundary fuzzy | Deterministic selection criteria; hard cap 15; deferred-overflow issue |
| 6 | ML subagent GPU requirement | Preflight check (2.7); CPU-FORKS.md (2.2); graceful reroute to code-subagent |
| 7 | Reference versioning burden | `version: 1.0` per reference; SemVer policy; Phase 6.1 version-citation check |
| **8 (new)** | **Licensing/attribution [M4+M5]** | **All new skills use `license: Apache-2.0` (not MIT) per repo convention [M4]; `THIRD_PARTY_LICENSES.md` at repo root (task 1.5) preserves upstream MIT notices per Apache §4(c) [M5].** |
| **9 (new)** | **Subagent permission drift [M7]** | **All path-restricted subagents (ml, research) use map-form `edit: {"*": deny, "<pattern>": allow}` not scalar `edit: allow` — sandbox enforced in permissions, not prose.** |
| **10 (new)** | **Test CI missing [M6]** | **All tests converted to `.bats` format; new CI job (task 6.5) runs `bats tests/*.bats` on every PR.** |

## Delegation strategy

**[R2 — Wave 4 split]** The original plan called for one `opencode-tooling-subagent` invocation to retrofit all 15 Tier 3 skills. Per review: subagents run on glm-5.1 (200K context) and reading 15 SKILL.md files (some large — tdd-workflow-skill is 647 lines, verification-loop-skill 286) plus the cited references is tight. Wave 4 is now split into 4a (8 skills) + 4b (7 skills). **Note:** the compaction checkpoint below operates on the **primary** session's context — it cannot rescue a subagent that blows its **own** isolated 200K mid-wave. Each wave's prompt should instruct the subagent to use `strategic-compact-skill` internally if its own context > 60%.

| Wave | Subagent | Scope | Phases | Est. files |
|------|----------|-------|--------|------------|
| 1 | opencode-tooling-subagent | Foundation + domain build | 1 + 2 | 25 new (incl. THIRD_PARTY_LICENSES.md) |
| 2 | opencode-tooling-subagent | Tier 1 retrofit | 3 | 7 edits |
| 3 | opencode-tooling-subagent | Tier 2 retrofit | 4 | 8 edits |
| **4a** | opencode-tooling-subagent | **Tier 3 retrofit batch 1** (skills 1-8) | 5 (1-8) | ~8 edits |
| **4b** | opencode-tooling-subagent | **Tier 3 retrofit batch 2** (skills 9-15) | 5 (9-15) | ~7 edits |
| 5 | opencode-tooling-subagent | Maintenance + tests + CI | 6 | 4 new + 2 edits (incl. release.yml) |
| 6 | documentation-subagent | Docs sync | 7 | 7 edits (incl. AGENTS.md model tiering) |
| 7 | (manual / primary) | Pre-merge verification | 8.1, 8.2 | 0 edits |
| 8 | (manual / post-merge) | Post-merge verification | 8.3 | 0 edits |

**Compaction checkpoints:**
- **Primary session:** invoke `strategic-compact-skill` if primary context > 60% before spawning next wave.
- **Subagent internal:** each wave's prompt should instruct the subagent to invoke `strategic-compact-skill` if its own context > 60% mid-task (subagents can load skills per their `permission.skill` allowlist).

## Attribution

**[M4+M5 revisions]** All new skills declare `license: Apache-2.0` to match the repo's existing convention. Upstream MIT-licensed content is ported under the repo's Apache-2.0 license (MIT→Apache-2.0 relicensing is one-way compatible), with full upstream attribution preserved in `THIRD_PARTY_LICENSES.md` (task 1.5) per Apache-2.0 §4(c).

- **uditgoenka/autoresearch** (MIT) — primary source for SKILL.md body, scripts, evaluator contract, command structure. File-level attribution in `autoresearch-core-skill/SKILL.md` References section AND `THIRD_PARTY_LICENSES.md` entry.
- **karpathy/autoresearch** (MIT) — source for ML templates (program.md verbatim with license header referencing THIRD_PARTY_LICENSES.md). File-level attribution in `autoresearch-ml-skill/templates/program.md` AND `THIRD_PARTY_LICENSES.md` entry.
- **wjgoarxiv/autoresearch-skill** (MIT) — inspiration for the strict `{"pass":bool,"score":N}` evaluator contract (we adopt this on top of uditgoenka). Mentioned in `autoresearch-core-skill/SKILL.md` References AND `THIRD_PARTY_LICENSES.md` entry.

## Review changelog

This PLAN was reviewed by `opencode-tooling-subagent` against actual repo files. 18 findings (0 critical, 7 major, 7 minor, 4 recommendations) were applied. Key revisions:

- **[M1]** Expanded grep regex in tasks 7.1/7.2/7.8 to catch `AGENTS (N):` banner form (previously missed — same narrowness class as PLAN-GIT-237's case-sensitivity bug)
- **[M2]** Corrected task 7.3 line-23 count: base is 37 (not 36), target is 40 (not 39); task 7.8 gate updated accordingly
- **[M3]** Corrected task 7.4 explicit-perm base: actual is 23 of 37 (not 24); target is 26 of 40 (not 27 of 40)
- **[M4]** All new skills use `license: Apache-2.0` (not MIT) per repo convention
- **[M5]** Added task 1.5 (`THIRD_PARTY_LICENSES.md`) for Apache §4(c) compliance
- **[M6]** Tests converted from `.md` to `.bats`; added task 6.5 (CI test job)
- **[M7]** Subagent `edit` permissions converted from scalar `allow` to map form `{"*": deny, "<pattern>": allow}` for path-restricted subagents (ml, research) — enforced in permissions, not prose
- **[m1]** Added `general: allow` to all 3 new subagent `task:` blocks (matches loop-operator-subagent template)
- **[m2]** Research subagent explicitly declares `webfetch: allow, websearch: allow` for auditability
- **[m3]** Added task 7.6.5 to update repo-root AGENTS.md Subagent Model Tiering table
- **[m4]** Task 7.6 now updates BOTH CodeGraph tables (opencode_app/AGENTS.md AND deploy/.AGENTS.md); backfills 3 previously-missed entries in deploy/.AGENTS.md
- **[m5]** Task 7.7 shell helpers now guarded by `[ -f ~/.bashrc ]` / `[ -f ~/.zshrc ]` checks
- **[m6]** Retrofit preamble strengthened to imperative-gating language; Risk 4 acknowledged residual limitation
- **[m7]** Task 6.4 token-grep now scoped to Iteration Protocol section line range (avoids false positives)
- **[R1]** Tasks 8.1, 8.2 moved to pre-merge status; 8.3 stays post-merge (no GPU in CI)
- **[R2]** Wave 4 split into 4a (8 skills) + 4b (7 skills); added subagent-internal compaction checkpoint
- **[R3]** Task 1.2 documents that `metadata.protocol` / `metadata.protocol-source` are informational-only (no runtime effect, consumed only by maintainer grep)
- **[R4]** Task 2.1 Done-when cross-references task 2.2 for template gating
