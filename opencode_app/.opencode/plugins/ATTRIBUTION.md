# Attributions

## ponytail (`@dietrichgebert/ponytail`)

This directory (`plugins/ponytail/`) contains code vendored and adapted from the
[ponytail](https://github.com/DietrichGebert/ponytail) project by Dietrich Gebert.

- **Upstream:** https://github.com/DietrichGebert/ponytail
- **Pinned version:** v4.8.4 (tag `v4.8.4`)
- **License:** MIT (see full text below)
- **Files vendored:**
  - `SKILL.md` — the ponytail ruleset (copied verbatim from `skills/ponytail/SKILL.md`)
  - `instructions.cjs` — adapted from `hooks/ponytail-instructions.js` and
    `hooks/ponytail-config.js` (mode-filtering logic preserved; Claude-Code-specific
    config-file paths dropped; reads the co-located `SKILL.md`)
- **Adaptation rationale:** vendoring (vs `require("@dietrichgebert/ponytail")`) keeps
  the Docker container air-gapped (no runtime npm fetch), removes the stock OpenCode
  adapter from the dependency tree (double-injection guard), and lets the wrapper
  plugin (`../ponytail-scoped.mjs`) add agent-type-aware scoping that the upstream
  adapter does not support on OpenCode.

Re-vendor deliberately on upstream bumps: update `SKILL.md` from the new tag and
re-check `instructions.cjs` against the upstream instruction builder.

---

### MIT License (upstream ponytail)

```
MIT License

Copyright (c) Dietrich Gebert

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```
