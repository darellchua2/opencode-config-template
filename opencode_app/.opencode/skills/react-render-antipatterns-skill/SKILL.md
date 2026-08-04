<!--
  Provenance (maintainer-only, not rendered to model context):
  - fragment-key-in-map : canvastekk-frontend-nextjs/LEARNINGS/
  - unsafe-json-parse-event-handler : canvastekk-frontend-nextjs/LEARNINGS/
  - inconsistent-visibility-toggle-strategy : canvastekk-frontend-nextjs/LEARNINGS/
  - folder-tabs-theme-driven : canvastekk-frontend-nextjs/LEARNINGS/
  Split from react-nextjs-antipatterns-skill (PLAN-GIT-312, B1 split).
-->

---
name: react-render-antipatterns-skill
description: Detect and fix React render-time anti-patterns — missing fragment keys in .map(), unsafe JSON.parse in event handlers, inconsistent visibility toggle strategies, and theme-driven component design with CSS custom properties
license: Apache-2.0
compatibility: opencode
metadata:
  audience: developers
  workflow: code-quality
  languages: typescript, javascript
  frameworks: react
category: Framework-Specific
---

## What I do

I detect and fix anti-patterns specific to React render-time behavior that cause production incidents:

1. **JSX Render Pitfalls**: Missing fragment keys in `.map()`, unsafe JSON.parse in drag-and-drop handlers
2. **State-Driven Render Issues**: Inconsistent visibility toggle strategies mixing hard-removal with runtime filtering
3. **Recommended Pattern**: Theme-driven component design using CSS custom properties only

## When to use me

Use this skill when:
- Debugging React key warnings in list rendering
- Fixing UI crashes from malformed drag-and-drop data
- Auditing inconsistent component visibility patterns
- Implementing theme-driven (light/dark mode) component design
- Reviewing React render-time code for production-readiness

## Related Skills

- **react-hooks-antipatterns-skill**: Peer — covers hook lifecycle anti-patterns (stale state, StrictMode double-execution, useCallback/useMemo traps). This skill covers render-time anti-patterns.
- **accessibility-a11y-skill**: ARIA patterns for dynamic error banners. This skill handles React render correctness.
- **frontend-design-skill**: UI aesthetics and layout. This skill handles runtime correctness.
- **uiux-review-skill**: Visual/UX review of rendered output. This skill handles the code-level anti-patterns that cause render bugs.

---

## A. JSX Render Pitfalls

### A1. `fragment-key-in-map` — Missing List Keys

`<>` shorthand Fragment in `.map()` can't accept `key`.

**Before (warning):**
```tsx
{items.map((item) => (
  <>
    <span>{item.name}</span>
    <span>{item.value}</span>
  </>
))}
```

**After (correct):**
```tsx
import { Fragment } from 'react'

{items.map((item) => (
  <Fragment key={item.id}>
    <span>{item.name}</span>
    <span>{item.value}</span>
  </Fragment>
))}
```

### A2. `unsafe-json-parse-event-handler` — UI Crash on Malformed Data

`JSON.parse` in drag-and-drop handlers crashes UI on malformed data.

**Before (crashes):**
```tsx
function onDrop(e: DragEvent) {
  const data = JSON.parse(e.dataTransfer.getData('text')) // Throws on bad data
  handleDrop(data)
}
```

**After (safe):**
```tsx
function onDrop(e: DragEvent) {
  try {
    const data = JSON.parse(e.dataTransfer.getData('text'))
    handleDrop(data)
  } catch {
    showToast('Invalid drag data')
  }
}
```

---

## B. State-Driven Render Issues

### B1. `inconsistent-visibility-toggle-strategy` — Mixed Hide Approaches

Mixing hard-removal with runtime `isXxxVisible()` filtering causes confusion.

**Before (inconsistent):**
```tsx
// File A: hard-removes from array
items = items.filter(i => i.id !== removedId)

// File B: runtime filter
{items.filter(i => isFeatureVisible(i.id)).map(...)}
```

**After (consistent):**
```tsx
// Standardize on runtime flag everywhere
const visibleItems = items.filter(i => isVisible(i.id))
{visibleItems.map(...)}
```

---

## C. Recommended Pattern

### C1. `folder-tabs-theme-driven` — CSS Custom Properties

CSS custom properties only — no hardcoded colors, automatic light/dark mode.

```tsx
// Component uses only CSS variables
<div className="tab-bar" style={{ '--tab-active-bg': 'var(--color-primary)' }}>
  <button className="tab active">Overview</button>
</div>

/* CSS */
.tab { background: var(--tab-bg, transparent); }
.tab.active { background: var(--tab-active-bg); color: var(--tab-active-fg); }

/* Theme switch is automatic via :root[data-theme] */
:root[data-theme="dark"] { --color-primary: #6366f1; }
:root[data-theme="light"] { --color-primary: #4f46e5; }
```
