# tsoa response examples: `@Example()` decorator, not `@example` JSDoc

**Category:** solution
**Confidence:** high (verified against tsoa-community official docs, 2026-08)

## The distinction

tsoa has **two** different example mechanisms that are easy to conflate:

| Want an example for… | Use this | Kind |
|----------------------|----------|------|
| Response body (default response) | `@Example<T>({...})` | TypeScript **decorator** on the method |
| Non-default response (e.g. error) | `@Response<T>(code, "desc", example)` | TypeScript **decorator** on the method |
| Parameter (`@Path`/`@Query`/…) | `@example name "value"` | **JSDoc tag** |
| Model / type / property | `@example ...` | **JSDoc tag** |

## Common mistake

Listing tsoa's example source as just "`@example` JSDoc tag" in a per-framework mapping
table. A developer following that for a **response body** silently gets nothing — the
response example requires the `@Example()` decorator.

## Correct mapping-table row (tsoa)

| Framework | Description source | Example source |
|-----------|--------------------|----------------|
| tsoa (TS) | JSDoc on controller method | `@Example()` / `@Response()` decorators (responses); `@example` JSDoc tag (params/props) |

## Evidence

- Branch `GIT-319`, `opencode_app/.opencode/skills/api-design-skill/SKILL.md:285` —
  tsoa row omitted the `@Example()` decorator (flagged Major in code review).

## Source

- https://tsoa-community.github.io/docs/examples.html
