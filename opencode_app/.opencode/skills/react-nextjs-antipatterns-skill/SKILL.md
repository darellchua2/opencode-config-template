---
name: react-nextjs-antipatterns-skill
description: Detect and fix React 19 and Next.js 16 runtime anti-patterns — hydration mismatches, StrictMode double-execution, memory leaks from module-scope caches, stale derived state, fail-open RBAC, revalidatePath error swallowing, fragment keys, useMemo dep issues, and more
license: Apache-2.0
compatibility: opencode
metadata:
  audience: developers
  workflow: code-quality
  languages: [typescript, javascript]
  frameworks: [react, nextjs]
---

## What I do

I detect and fix runtime anti-patterns specific to React 19 and Next.js 16 that cause production incidents:

1. **Critical Anti-Patterns**: Production-breaking issues — swallowed redirects, fail-open RBAC, stale derived state, StrictMode double-execution, dead route navigation
2. **Memory & Performance**: Unbounded caches, useCallback/useMemo dependency traps, stale ref accumulators
3. **React-Specific**: Fragment keys, unsafe event handlers, visibility toggle inconsistencies, duplicated mappings, type drift
4. **Next.js-Specific**: Hydration mismatch elimination, cookie prefix management
5. **Recommended Patterns**: Hook decomposition, theme-driven component design
6. **Testing**: Playwright project routing

## When to use me

Use this skill when:
- Debugging hydration mismatches or SSR rendering issues
- Auditing middleware for fail-open access control vulnerabilities
- Fixing stale state after external data mutations
- Investigating memory growth in long-lived SPAs
- Cleaning up duplicated status/type mappings across components
- Setting up Playwright multi-browser project routing
- Reviewing React/Next.js code for production-readiness

## Related Skills

- **accessibility-a11y-skill**: ARIA patterns for dynamic error banners. This skill handles React anti-patterns.
- **frontend-design-skill**: UI aesthetics and layout. This skill handles runtime correctness.
- **uiux-review-skill**: Peer — axis 12 (Nielsen heuristic 4: consistency and standards) catches React components that drift from design-system patterns at runtime; axis 13 (anti-default AI cluster detection) flags generic-looking output. Use this skill for runtime anti-patterns; use `uiux-review-skill` for visual/UX review of the rendered output.
- **typescript-dry-principle-skill**: Duplicate type definitions and status mappings. This skill covers the React-specific runtime impacts.
- **security-audit-skill**: Fail-open RBAC auditing. This skill covers the React/middleware implementation patterns.
- **performance-optimization-skill**: Module-scope cache leaks and N+1 queries. This skill covers the React-specific aspects.

---

## Section A: Critical Anti-Patterns (Production-Breaking)

### A1. `revalidatepath-inside-generic-try-catch` — Swallowed Redirects

`revalidatePath()` and `redirect()` throw non-Error objects with a `digest` property. Generic try/catch swallows them silently.

**Before (broken):**
```tsx
try {
  revalidatePath('/dashboard')
} catch (e) {
  // Silently swallows redirect — page never refreshes
  console.error('Failed to revalidate')
}
```

**After (correct):**
```tsx
try {
  revalidatePath('/dashboard')
} catch (e) {
  if (e && typeof e === 'object' && 'digest' in e) {
    const digest = e.digest as string
    if (digest.startsWith('NEXT_REDIRECT') || digest.startsWith('NEXT_REVALIDATE')) {
      throw e // Re-throw Next.js internal signals
    }
  }
  console.error('Revalidation failed', e)
}
```

### A2. `fail-open-rbac-middleware` — Default-Allow Access Control

When RBAC role extraction fails, requests pass through instead of being denied.

**Before (vulnerable):**
```tsx
export function middleware(request: NextRequest) {
  const role = extractRole(request) // May throw or return null
  if (role === 'admin') {
    return NextResponse.next()
  }
  return NextResponse.next() // BUG: passes through on error
}
```

**After (secure):**
```tsx
export function middleware(request: NextRequest) {
  const role = extractRole(request)
  if (!isValidRole(role)) {
    return NextResponse.json({ error: 'Forbidden' }, { status: 403 })
  }
  return NextResponse.next() // Only proceed if explicitly valid
}
```

### A3. `derived-state-props-without-sync` — Stale useState from Props

`useState` initialized from props becomes stale when the parent updates the prop.

**Before (stale):**
```tsx
function EditDialog({ initialName }: { initialName: string }) {
  const [name, setName] = useState(initialName)
  // name stays "old" even after parent passes new initialName
}
```

**After (synced):**
```tsx
function EditDialog({ initialName }: { initialName: string }) {
  const [name, setName] = useState(initialName)

  useEffect(() => {
    setName(initialName)
  }, [initialName])
  // OR use a controlled component with `key={initialName}` to remount
}
```

### A4. `ref-guard-early-return` — StrictMode Double-Execution

`useRef(false)` guard with early returns before setting ref causes double-execution in React StrictMode.

**Before (buggy):**
```tsx
function useInit() {
  const started = useRef(false)

  useEffect(() => {
    if (someCondition) return // Early return BEFORE setting ref
    if (started.current) return
    started.current = true
    init() // Runs twice in StrictMode
  }, [])
}
```

**After (correct):**
```tsx
function useInit() {
  const started = useRef(false)

  useEffect(() => {
    if (started.current) return
    started.current = true // Set ref FIRST, before any logic
    if (someCondition) return
    init()
  }, [])
}
```

### A5. `route-removal-misses-runtime-nav` — Dead Route References

Import-based dead code analysis misses runtime navigation to deleted routes.

**Detection pattern:**
```bash
# After removing a route, grep for runtime references
rg "router\.push\(['\"](/old-route)" --type ts --type tsx
rg "href=['\"](/old-route)" --type ts --type tsx
rg "router\.replace\(['\"](/old-route)" --type ts --type tsx
```

---

## Section B: Memory & Performance

### B1. `module-scope-map-cache` — Unbounded Module-Level Map

Module-level `Map` grows without bound in SPA lifecycle.

**Before (leak):**
```tsx
const userCache = new Map<string, User>()

function getUser(id: string) {
  if (!userCache.has(id)) {
    userCache.set(id, fetchUser(id))
  }
  return userCache.get(id)
}
```

**After (bounded):**
```tsx
const MAX_CACHE_SIZE = 100
const userCache = new Map<string, User>()

function getUser(id: string) {
  if (userCache.has(id)) return userCache.get(id)!

  if (userCache.size >= MAX_CACHE_SIZE) {
    const firstKey = userCache.keys().next().value
    userCache.delete(firstKey) // LRU eviction
  }

  const user = fetchUser(id)
  userCache.set(id, user)
  return user
}
```

### B2. `loading-state-in-usecallback-deps` — Unnecessary Callback Recreation

Including loading booleans in `useCallback` deps causes unnecessary recreation.

**Before (inefficient):**
```tsx
const handleSubmit = useCallback(() => {
  if (loading) return
  submit()
}, [loading, submit]) // Recreates on every loading toggle
```

**After (efficient):**
```tsx
const handleSubmit = useCallback(() => {
  submit()
}, [submit])

// Disable in the JSX instead
<button onClick={handleSubmit} disabled={loading}>Submit</button>
```

### B3. `inline-computed-usememo-dep` — New Reference Every Render

Inline ternary/computed values as `useMemo` deps create new references every render.

**Before (stale):**
```tsx
const sorted = useMemo(() => sortItems(items), [items.length > 0 ? items : []])
// Inline ternary creates new array reference each render — memo never hits
```

**After (correct):**
```tsx
const effectiveItems = useMemo(() => (items.length > 0 ? items : []), [items])
const sorted = useMemo(() => sortItems(effectiveItems), [effectiveItems])
```

### B4. `reset-refs-on-effect-restart` — Stale Ref Accumulators

`useRef` accumulators in `useEffect` carry over from previous lifecycles.

**Before (buggy):**
```tsx
useEffect(() => {
  const counter = useRef(0)
  counter.current++ // Carries stale value on re-mount
}, [dependency])
```

**After (correct):**
```tsx
const counter = useRef(0)

useEffect(() => {
  counter.current = 0 // Reset at TOP of effect body
  // ... then use counter
}, [dependency])
```

---

## Section C: React-Specific

### C1. `fragment-key-in-map` — Missing List Keys

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

### C2. `unsafe-json-parse-event-handler` — UI Crash on Malformed Data

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

### C3. `inconsistent-visibility-toggle-strategy` — Mixed Hide Approaches

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

### C4. `duplicated-status-mappings` — Copy-Paste Status Logic

Near-identical status→icon/color switch statements in 3+ files.

**Before (duplicated):**
```tsx
// FileA.tsx
const icon = status === 'active' ? '✅' : status === 'pending' ? '⏳' : '❌'
// FileB.tsx — same logic copy-pasted
// FileC.tsx — same logic copy-pasted
```

**After (shared utility):**
```tsx
// utils/status.ts
export function getStatusIcon(status: string, size: 'sm' | 'md' = 'md') {
  const icons = { active: '✅', pending: '⏳', failed: '❌' }
  return icons[status] ?? '❓'
}

// All files import from utils/status.ts
```

### C5. `duplicate-type-definitions` — Drifting Local Types

Local component types duplicating canonical types drift apart.

**Before (drifts):**
```tsx
// ComponentA.tsx
interface User { id: string; name: string } // Local definition

// types/user.ts (canonical)
export interface User { id: string; name: string; email: string }
// ComponentA's User is missing `email` — drifts silently
```

**After (single source):**
```tsx
// ComponentA.tsx
import type { User } from '@/types/user'
// Always imports canonical definition
```

---

## Section D: Next.js-Specific

### D1. `ssr-false-eliminates-hydration-mismatch` — No More `typeof window` Guards

Wrap browser-API components in `next/dynamic({ ssr: false })` to eliminate hydration mismatches.

```tsx
import dynamic from 'next/dynamic'

const MapComponent = dynamic(() => import('./Map'), { ssr: false })

// No need for: if (typeof window === 'undefined') return null
// next/dynamic handles SSR exclusion cleanly
```

### D2. `chunked-cookie-secure-prefix-mismatch` — Shared Cookie Utility Only

Always use a shared cookie utility — never roll your own `__Secure-` prefix logic.

```tsx
// utils/cookies.ts — single implementation
export function setSecureCookie(name: string, value: string, opts?: CookieOptions) {
  const prefix = location.protocol === 'https:' ? '__Secure-' : ''
  document.cookie = `${prefix}${name}=${value}; ${serializeOpts(opts)}`
}

// Never implement prefix logic inline — chunked cookies + manual prefix = mismatch
```

---

## Section E: Recommended Patterns

### E1. `hook-decomposition-complex-component` — Focused Hooks

Decompose complex components into focused hooks with typed interfaces.

```tsx
// Before: 300-line component doing everything
function ReportForm() { /* state + validation + submit + persistence */ }

// After: focused hooks
function useReportState(initial?: Report) { /* state management */ }
function useReportValidation(values: Report) { /* field validation */ }
function useReportSubmit() { /* API calls + error handling */ }

function ReportForm({ initial }: { initial?: Report }) {
  const { values, setField } = useReportState(initial)
  const errors = useReportValidation(values)
  const { submit, isSubmitting } = useReportSubmit()
  // Component is now ~50 lines of clean JSX
}
```

### E2. `folder-tabs-theme-driven` — CSS Custom Properties

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

---

## Section F: Testing

### F1. `browserName-playwright-project-routing` — Project vs Browser

`browserName` is the browser engine, not the project name. Use `testInfo.project.name` for multi-project routing.

**Before (wrong routing):**
```ts
test('works in all projects', ({ browserName }) => {
  if (browserName === 'chromium') {
    // BUG: matches all chromium-based projects, not the specific one
  }
})
```

**After (correct routing):**
```ts
test('works in all projects', ({}, testInfo) => {
  if (testInfo.project.name === 'desktop-chrome') {
    // Correctly matches specific project config
  }
})
```
