---
name: playwright-responsive-audit-skill
description: "Methodology for auditing and fixing responsive UI defects in Next.js projects using Playwright. Defines 6 detection assertions, 3 fix-confidence tiers, and a closed detect-fix-re-verify loop. Loaded by responsive-audit-subagent. Not auto-triggered — invoked exclusively via permission.skill by the audit subagent."
license: Apache-2.0
compatibility: opencode
metadata:
  audience: developers
  workflow: testing
---

## What I do

I define the methodology for auditing and fixing responsive UI defects in Next.js (or any web) projects using Playwright. This is a **checker-and-fixer** capability: detect responsive issues, apply fixes by confidence tier, and emit permanent regression specs.

## When to use me

Loaded exclusively by `responsive-audit-subagent` via `permission.skill`. Not auto-triggered. The primary session orchestrates the closed loop and spawns the subagent per-iteration.

## Audit Process Overview

```
1. Configure viewport matrix (mobile, tablet, desktop)
2. For each target page:
   a. Navigate at each breakpoint
   b. Run 6 detection assertions
   c. Classify defects by fix-confidence tier
3. Apply fixes (Tier 1 auto, Tier 2 propose+verify, Tier 3 report)
4. Re-audit ALL viewports after each fix
5. Repeat until clean or iteration cap reached
6. Emit regression spec locking the fixed state
```

---

## 6 Detection Assertions

Each assertion runs at every breakpoint (mobile, tablet, desktop). Use Playwright's `page.evaluate()` for DOM measurements.

### 1. Horizontal Overflow Detection

Checks if the page content exceeds the viewport width, causing horizontal scroll.

```typescript
const hasHorizontalOverflow = await page.evaluate(() => {
  return document.documentElement.scrollWidth > document.documentElement.clientWidth;
});
```

**Pass:** `scrollWidth <= clientWidth` (no horizontal scroll)
**Fail:** Content extends beyond viewport — indicates elements with fixed widths or missing responsive constraints

### 2. Element Clipping Detection

Checks if interactive elements are partially or fully clipped by their containers.

```typescript
const clippedElements = await page.evaluate(() => {
  const interactive = document.querySelectorAll('button, a, input, select, textarea, [role="button"]');
  const clipped: string[] = [];
  interactive.forEach(el => {
    const rect = el.getBoundingClientRect();
    const parent = el.parentElement?.getBoundingClientRect();
    if (parent && (rect.right > parent.right || rect.bottom > parent.bottom || rect.left < parent.left)) {
      clipped.push(el.tagName + (el.className ? '.' + el.className.split(' ')[0] : ''));
    }
  });
  return clipped;
});
```

**Pass:** No interactive elements extend beyond parent bounds
**Fail:** Elements are clipped — indicates overflow-hidden containers hiding interactive content

### 3. Breakpoint Visibility Toggle Detection

Verifies that elements intended to show/hide at specific breakpoints (Tailwind `hidden md:block`, `md:hidden`) are in the correct state.

```typescript
const visibilityIssues = await page.evaluate((viewport) => {
  const issues: string[] = [];
  // Check elements with responsive visibility classes
  const responsiveEls = document.querySelectorAll('[class*="hidden"], [class*="md:"], [class*="lg:"]');
  responsiveEls.forEach(el => {
    const style = window.getComputedStyle(el);
    const isVisible = style.display !== 'none' && style.visibility !== 'hidden' && style.opacity !== '0';
    const classes = el.className;
    // Verify the visibility state matches what the breakpoint classes intend
    if (viewport === 'mobile' && classes.includes('hidden') && !classes.includes('sm:block') && isVisible) {
      issues.push(`Should be hidden on mobile: ${el.tagName}.${classes.split(' ')[0]}`);
    }
  });
  return issues;
}, viewportName);
```

**Pass:** All responsive visibility toggles are in the correct state for the current breakpoint
**Fail:** Elements that should be hidden are visible or vice versa

### 4. Tap-Target Size Detection (Touch Only)

Checks that interactive elements meet the minimum 44x44px tap-target requirement on touch devices.

```typescript
const smallTapTargets = await page.evaluate(() => {
  const interactive = document.querySelectorAll('button, a, input, select, textarea, [role="button"]');
  const small: { element: string; width: number; height: number }[] = [];
  interactive.forEach(el => {
    const rect = el.getBoundingClientRect();
    if (rect.width < 44 || rect.height < 44) {
      small.push({
        element: el.tagName + (el.className ? '.' + el.className.split(' ')[0] : ''),
        width: Math.round(rect.width),
        height: Math.round(rect.height),
      });
    }
  });
  return small;
});
```

**Pass:** All interactive elements are >= 44x44px
**Fail:** Tap targets are too small — add padding or increase size
**Note:** Only checked on touch viewports (`hasTouch: true`)

### 5. Text Truncation Detection

Detects text that is truncated or cut off in a way that loses meaningful content.

```typescript
const truncatedText = await page.evaluate(() => {
  const textElements = document.querySelectorAll('p, h1, h2, h3, h4, h5, h6, span, td, th, label');
  const truncated: string[] = [];
  textElements.forEach(el => {
    const style = window.getComputedStyle(el);
    if (style.textOverflow === 'ellipsis' || style.whiteSpace === 'nowrap') {
      if (el.scrollWidth > el.clientWidth) {
        truncated.push(el.tagName + ': "' + el.textContent?.substring(0, 30) + '..."');
      }
    }
  });
  return truncated;
});
```

**Pass:** No text is truncated with content loss
**Fail:** Text is cut off — may need wrapping, font-size adjustment, or responsive text classes

### 6. Layout-Shift Detection

Checks for Cumulative Layout Shift (CLS) caused by responsive breakpoint transitions or content reflow.

```typescript
// Run at page load and after a 2-second delay
const clsBefore = await page.evaluate(() => (window as any).__clsValue || 0);
await page.waitForTimeout(2000);
const clsAfter = await page.evaluate(() => (window as any).__clsValue || 0);
const layoutShift = clsAfter - clsBefore;
```

**Pass:** CLS delta < 0.1 (minimal layout shift)
**Fail:** Significant layout shift — content reflows after initial render

---

## 3 Fix-Confidence Tiers

Defects are classified by how confidently they can be auto-fixed:

### Tier 1: Auto-Fix (High Confidence)

Mechanical changes that don't alter component behavior or structure:

| Defect | Fix Pattern |
|---|---|
| Missing responsive grid | Add `grid-cols-1 sm:grid-cols-2 lg:grid-cols-4` |
| Fixed width causing overflow | Replace `w-[500px]` with `w-full max-w-[500px]` |
| Missing flex direction switch | Add `flex-col sm:flex-row` |
| Small tap targets | Add `min-w-[44px] min-h-[44px]` or `p-2` |
| Text not wrapping | Add `break-words` or remove `whitespace-nowrap` |
| Missing responsive text size | Add `text-sm md:text-base lg:text-lg` |

**Action:** Apply directly, no verification needed beyond re-audit.

### Tier 2: Propose + Verify (Medium Confidence)

Structural changes that alter layout behavior but follow established patterns:

| Defect | Fix Pattern |
|---|---|
| Table on mobile | Transform to card list: `<table>` → stacked `<div>` cards with labeled fields |
| Sidebar always visible | Add `hidden md:block` + hamburger toggle for mobile |
| Dialog/modal too small on mobile | Add responsive sizing: `w-[90vw] max-w-md` |
| Multi-column form | Stack on mobile: `grid-cols-1 md:grid-cols-2` |
| Horizontal tab overflow | Convert to scrollable tabs or dropdown on mobile |

**Action:** Apply the fix, then delegate screenshot capture to primary session for `image-analyzer-subagent` review. Verify visually before accepting.

### Tier 3: Report Only (Low Confidence)

Complex restructures that require human judgment or design decisions:

| Defect | Reason |
|---|---|
| Complex data visualization | May need alternative representation (table → chart → summary) |
| Multi-step wizard layout | Needs UX decision on mobile flow |
| Drag-and-drop interface | Needs touch alternative design |
| Custom canvas/SVG rendering | Needs viewport-aware scaling logic |
| Third-party widget overflow | May need wrapper or replacement |

**Action:** Document as a follow-up item with severity and recommended approach. Do not auto-fix.

---

## Closed-Loop Iteration Pattern

```
┌──────────────────────────────────────┐
│ ITERATION N                           │
├──────────────────────────────────────┤
│ 1. DETECT: Run 6 assertions           │
│    at all breakpoints                 │
│ 2. DIAGNOSE: Classify defects         │
│    into Tier 1/2/3                    │
│ 3. FIX: Apply Tier 1 auto-fixes       │
│    Apply Tier 2 (with verify)         │
│    Skip Tier 3 (report only)          │
│ 4. RE-VERIFY: Re-run ALL assertions   │
│    at ALL breakpoints                 │
│ 5. DELTA: Compare defect count        │
│    vs previous iteration              │
│ 6. DECISION:                          │
│    - If defects remain AND delta > 0: │
│      increment N, go to 1             │
│    - If defects == 0: DONE            │
│    - If delta == 0 (no improvement):  │
│      STOP — escalate remaining        │
│    - If N >= MAX_ITERATIONS (5):      │
│      STOP — report remaining          │
└──────────────────────────────────────┘
```

**Max iterations:** 5. If no progress is made in an iteration (delta == 0), stop and escalate remaining Tier 2/3 defects.

---

## Regression Spec Emission

After the audit completes (all fixable defects resolved), emit a Playwright regression spec:

**File:** `e2e/responsive/{page-name}.responsive.spec.ts`

**Structure:**
```typescript
import { test, expect, devices } from '@playwright/test';

const breakpoints = [
  { name: 'mobile', viewport: { width: 375, height: 667 }, hasTouch: true },
  { name: 'tablet', viewport: { width: 768, height: 1024 }, hasTouch: true },
  { name: 'desktop', viewport: { width: 1280, height: 720 } },
];

for (const bp of breakpoints) {
  test.describe(`${bp.name} responsive`, () => {
    test.use({ viewport: bp.viewport, hasTouch: bp.hasTouch });

    test('no horizontal overflow', async ({ page }) => {
      await page.goto('/target-page');
      const hasOverflow = await page.evaluate(() =>
        document.documentElement.scrollWidth > document.documentElement.clientWidth
      );
      expect(hasOverflow).toBe(false);
    });

    test('no clipped interactive elements', async ({ page }) => { /* ... */ });
    test('correct breakpoint visibility', async ({ page }) => { /* ... */ });
    test('tap-targets >= 44px', async ({ page }) => { /* ... */ });
    test('no text truncation', async ({ page }) => { /* ... */ });
    test('minimal layout shift', async ({ page }) => { /* ... */ });
  });
}
```

---

## Viewport Matrix Configuration

Reference for `playwright.config.ts` projects:

```typescript
projects: [
  {
    name: 'desktop-chromium',
    use: {
      ...devices['Desktop Chrome'],
      viewport: { width: 1280, height: 720 },
    },
  },
  {
    name: 'mobile-chrome',
    use: {
      ...devices['Pixel 5'],
      viewport: { width: 375, height: 667 },
      hasTouch: true,
    },
  },
  {
    name: 'tablet',
    use: {
      ...devices['iPad (gen 7)'],
      viewport: { width: 768, height: 1024 },
      hasTouch: true,
    },
  },
],
```

All projects should use `storageState: 'e2e/.auth/user.json'` for authenticated pages.

---

## Integration with Other Skills

| Skill | Relationship |
|---|---|
| `wireframer-skill` | Baseline source — generates lo-fi wireframes at breakpoints for structural layout reference |
| `verification-loop-skill` | Used by primary session to verify fixes across iterations |

## Integration with Subagents

| Subagent | Relationship |
|---|---|
| `image-analyzer-subagent` | Receives screenshots for visual verification of Tier 2 fixes |
| `loop-operator-subagent` | Primary session uses this to manage the closed-loop iteration |
