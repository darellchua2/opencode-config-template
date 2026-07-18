---
name: autoresearch-code-skill
description: "Autonomous code optimization loop — modify → verify (benchmark) → keep/revert against any code metric (test coverage, bundle size, runtime, error count). TDD-flavored: test-pass maps to pass, pass-count maps to score."
license: Apache-2.0
compatibility: opencode
metadata:
  audience: developers
  workflow: autonomous-iteration
  protocol: autoresearch-default-on
---

## What I do

I run an autonomous code-optimization loop. Each iteration: read the audit trail → hypothesize one atomic code change → apply → commit → run the benchmark evaluator → keep the commit if `{"pass":true,"score":N}` shows improvement (and the guard stays green), else `git reset --hard HEAD~1`. I am Tier 1 (mechanical evaluator) — every keep/revert decision comes from a program, never from LLM self-judgment. I overlap with `tdd-workflow-skill`, but I am autonomous-loop-flavored (iterate to a target overnight) where TDD is single-cycle (write-one-test-then-implement).

## Triggers

Load me (or route to `autoresearch-code-subagent`) when the user says any of:

- "optimize code", "optimize until", "iteratively improve"
- "test coverage", "increase coverage to N%"
- "bundle size", "reduce bundle"
- "performance", "reduce runtime", "speed up"
- "fix errors", "reduce error count", "drive failures to zero"
- "autoresearch code", "git-as-memory optimization"

Do **not** trigger for ML training (→ `autoresearch-ml-skill`) or literature review (→ `autoresearch-research-skill`).

## Citations

- `autoresearch-core-skill/references/evaluator-contract.md` — the `{"pass":bool,"score":N}` shape my benchmark evaluator emits.
- `autoresearch-core-skill/references/stuck-detection.md` — 3-strike pivot (switch from micro-opt to algorithmic change; target a different hotspot).
- `autoresearch-core-skill/references/iteration-safety.md` — Verify/Guard separation; never modify `.env`, `node_modules/`, or run `rm -rf`.
- `autoresearch-core-skill/references/audit-trail.md` — the 8-column TSV I append to (`<skill>-results.tsv`).
- `autoresearch-core-skill/references/crash-recovery.md` — syntax error → free fix; guard failure → revert.

## Skill-specific overrides

1. **TDD mapping (the key override).** When the metric is "test pass-count":
   - `pass: true`  **GREEN** (all targeted tests pass)
   - `pass: false`  **RED** (any targeted test fails)
   - `score`  **pass-count** (number of tests passing)
   - This makes `tdd-workflow-skill` and this skill mechanically equivalent when the metric is test-pass; the difference is I iterate to a target autonomously rather than running one RED→GREEN cycle.
2. **Verify vs Guard.** Verify emits `{"pass":bool,"score":N}` (e.g. `pytest --cov` → coverage %). Guard is a separate command that must stay green (e.g. `npm test`). A failing guard forces revert **regardless of Verify** — you cannot trade test-green for bundle-size.
3. **Tier 1** (mechanical evaluator). No agent-as-evaluator fallback.
4. **Git-as-memory.** Commit before Verify so revert is one command. Never edit the working tree without committing first — an uncommitted change cannot be cleanly reverted.
5. **Bounded-by-default.** `Iterations: 25` default. Lower for fast benchmarks (e.g. `Iterations: 10` for `npm run build` cycles).

## Templates

- `autoresearch-code-skill/templates/benchmark.py.template` — emits `{"pass":bool,"score":N}` JSON; parameterized `{{COMMAND}}`, `{{METRIC_NAME}}`, `{{TARGET_VALUE}}`.
- `autoresearch-code-skill/templates/research.md.code-template` — inline Goal/Scope/Metric/Verify/Guard format with worked examples (coverage, bundle size, runtime).
- `autoresearch-code-skill/templates/guard.example.sh` — example safety-net pattern (`npm test` must pass while optimizing bundle size).

## NEVER STOP / NEVER ASK

Inherits the core autonomy directive. Once the loop has begun, do not pause to ask whether to continue. The evaluator answers keep/revert mechanically; the human expects you to work until the predicate is met, the plateau+ceiling both trip, or max iterations is reached.

## References

- **uditgoenka/autoresearch** (MIT) — methodology source (command structure, TSV format, keep/revert pattern). Full notice: `THIRD_PARTY_LICENSES.md`.
- **karpathy/autoresearch** (MIT) — source for the git-as-memory pattern (commit → verify → keep/reset). Full notice: `THIRD_PARTY_LICENSES.md`.
- **wjgoarxiv/autoresearch-skill** (MIT) — inspiration for the strict `{"pass":bool,"score":N}` evaluator contract. Full notice: `THIRD_PARTY_LICENSES.md`.
