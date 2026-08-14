# Redocly `operation-description` is OFF by default in `recommended`

**Category:** solution
**Confidence:** high (verified against official Redocly 2.x docs, 2026-08)

## Claim that was wrong

"Redocly's default `recommended` ruleset already enforces `operation-description` as an error."

## Reality

- The `operation-description` rule's default severity is **`off`** — explicitly stated on
  the rule page: *"Default `off` (in `recommended` configuration)."*
- The Recommended ruleset page lists Errors and Warnings separately.
  `operation-description` appears in **neither** list.
  - Contrast: `operation-summary` IS an Error in recommended.
  - Contrast: `tag-description` IS a Warning in recommended.
  - `operation-description` is absent → off.

## Practical consequence

With zero config (or `extends: recommended`), `redocly lint` does **not** flag a missing
operation description. To actually enforce it, a project's `redocly.yaml` must explicitly
set:

```yaml
extends:
  - recommended
rules:
  operation-description: error
```

## Drafting implication for skills/docs

A per-field "every operation MUST have a description" mandate is the **load-bearing** net
unless/until the user opts into the rule. Do NOT frame it as "a primer that just keeps the
lint gate green" — out of the box, the lint gate does not check this.

If you want the lint gate to be the real net, point users at `recommended-strict` AND an
explicit `operation-description: error` override, or just mandate the override.

## Evidence

- Branch `GIT-319`, `opencode_app/.opencode/skills/api-design-skill/SKILL.md:295-298` —
  made the false claim (flagged BLOCK in code review).

## Sources

- https://redocly.com/docs/cli/rules/oas/operation-description
- https://redocly.com/docs/cli/rules/recommended
