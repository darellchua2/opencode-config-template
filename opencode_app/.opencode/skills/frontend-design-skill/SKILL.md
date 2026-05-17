---
name: frontend-design-skill
description: Create distinctive, production-grade frontend interfaces with high design quality that avoid generic AI aesthetics. Use this skill when building web components, pages, landing pages, dashboards, React components, HTML/CSS layouts, or when styling/beautifying any web UI.
license: Apache-2.0
compatibility: opencode
metadata:
  audience: developers
  workflow: design
  languages: "html, css, javascript, typescript, react, vue"
---

## What I do

I guide creation of distinctive, production-grade frontend interfaces that avoid generic "AI slop" aesthetics:

1. **Design Thinking**: Analyze context and commit to a bold aesthetic direction before coding
2. **Typography**: Select distinctive, characterful font pairings that elevate the design
3. **Color & Theme**: Create cohesive palettes with CSS variables and intentional contrast
4. **Motion & Interaction**: Implement animations, micro-interactions, and scroll-triggered effects
5. **Spatial Composition**: Design unexpected layouts with asymmetry, overlap, and grid-breaking elements
6. **Visual Details**: Add atmosphere through backgrounds, textures, patterns, and layered effects
7. **Production Code**: Deliver working HTML/CSS/JS, React, Vue, or other framework code

## When to use me

Use this skill when:
- Building any web component, page, or application
- Creating landing pages, dashboards, or marketing sites
- Styling or beautifying existing web UI
- Designing React components, Vue components, or HTML/CSS layouts
- Generating posters, artifacts, or visual web content
- The user asks to "make it look good" or "design a UI"
- Creating frontend prototypes or demos
- Refreshing an existing interface with better aesthetics

## Prerequisites

- Frontend framework context (React, Vue, plain HTML/CSS/JS, etc.)
- Understanding of the interface's purpose and target audience
- Technical constraints (if any): performance, accessibility, framework version

## Dependencies

| Dependency | Installation | When Needed |
|---|---|---|
| Google Fonts | `<link>` tag in HTML head | Custom typography (always) |
| Motion | `npm install motion` | React animations |
| Playwright | `npm install -g playwright` | Cross-browser testing |

## Anti-Patterns to AVOID

NEVER produce generic AI-generated aesthetics:

- **Fonts**: Avoid Inter, Roboto, Arial, system-ui, and other overused families. If the user doesn't specify a preference, choose a different display font each time rather than always reaching for the same one
- **Colors**: No purple gradients on white backgrounds. No timid, evenly-distributed pastels. No default Tailwind blue as primary
- **Layouts**: No predictable 3-column card grids. No cookie-cutter hero sections. No template-looking structures
- **Patterns**: No generic gradient backgrounds. No default card-with-shadow components. No "modern" rounded everything
- **Themes**: Vary between light and dark themes. Never default to the same aesthetic direction

## Design Thinking Framework

Before writing any code, analyze these four dimensions:

### 1. Purpose

- What problem does this interface solve?
- Who uses it and in what context?
- What emotion should it evoke?

### 2. Tone — Choose a BOLD Direction

Pick an extreme aesthetic. Options for inspiration:

- Brutally minimal
- Maximalist chaos
- Retro-futuristic
- Organic / natural
- Luxury / refined
- Playful / toy-like
- Editorial / magazine
- Brutalist / raw
- Art deco / geometric
- Soft / pastel
- Industrial / utilitarian
- Cyberpunk / neon
- Swiss / international
- Vaporwave / synthwave
- Corporate brutalism
- Neo-brutalism
- Glassmorphism (backdrop-filter blur + semi-transparent layers, not just opacity reduction)

Use these for inspiration but design one that is true to the specific context. The key is **intentionality, not intensity**. Bold maximalism and refined minimalism both work when executed with conviction.

### 3. Constraints

- Framework requirements (React, Vue, vanilla JS)
- Performance budget
- Accessibility requirements
- Browser support
- Responsive breakpoints

### 4. Differentiation

- What makes this UNFORGETTABLE?
- What is the one thing someone will remember about this interface?
- What would make someone screenshot and share it?

## Frontend Aesthetics Guidelines

### Typography

Choose fonts that are beautiful, unique, and interesting:

- **Display fonts**: Select distinctive choices that elevate the aesthetic. Consider:
  - Google Fonts: Playfair Display, Instrument Serif, Space Mono, Syne
  - Fontshare (free): Clash Display, Satoshi, Panchang
  - Self-hosted: Any licensed typeface from independent foundries
- **Body fonts**: Pair with a refined, readable complement. Consider DM Sans (Google Fonts), Satoshi, Cabinet Grotesk, General Sans (Fontshare), or similar
- **Pairing strategy**: One expressive display font + one clean body font. Contrast is key
- **Scale**: Use a deliberate type scale (e.g., 1.25x or 1.333x modular scale). Make headings dramatically larger than body text
- **Weight**: Exploit font weight contrast. Bold headings paired with light body text create hierarchy

### Color & Theme

- **CSS variables**: Define all colors as CSS custom properties for consistency
- **Dominant colors**: Bold dominant colors with sharp accents outperform timid palettes
- **Contrast**: High contrast between elements creates visual interest
- **Palette size**: 3-5 colors maximum. One dominant, one accent, neutrals for rest
- **Theme consistency**: Commit fully to light OR dark. Do not compromise
- **Color psychology**: Choose colors that reinforce the aesthetic direction, not just "look nice"

### Motion & Interaction

- **CSS-only first**: For HTML projects, prefer CSS animations and transitions
- **React Motion library**: Use Motion (framer-motion successor) when available in React
- **High-impact moments**: One well-orchestrated page load with staggered reveals (using `animation-delay`) creates more delight than scattered micro-interactions
- **Scroll-triggering**: Use IntersectionObserver for scroll-based reveals
- **Hover states**: Surprising and delightful hover effects that reinforce the aesthetic
- **Easing**: Use custom cubic-bezier curves, never default `ease` or `linear`
- **Duration**: 200-400ms for micro, 500-800ms for reveals, 1000ms+ for hero animations

### Spatial Composition

- **Unexpected layouts**: Break the grid intentionally
- **Asymmetry**: Off-center elements create visual tension and interest
- **Overlap**: Layer elements to create depth
- **Diagonal flow**: Guide the eye along non-horizontal paths
- **Negative space**: Generous whitespace OR controlled density — commit to one
- **Grid-breaking**: Elements that intentionally break out of the grid create focal points

### Backgrounds & Visual Details

- **Atmosphere**: Create depth rather than defaulting to solid colors
- **Textures**: Subtle noise, grain overlays, or paper textures add richness
- **Patterns**: Geometric patterns, grid lines, or dot patterns for structure
- **Layered transparencies**: Glassmorphism, frosted effects, or layered translucency
- **Shadows**: Dramatic shadows (not subtle `box-shadow: 0 2px 4px`) for depth
- **Decorative elements**: Borders, dividers, corner accents, or ornamental details
- **Custom cursors**: Context-appropriate cursor modifications
- **Gradient meshes**: Complex, multi-stop gradients for background depth

## Steps

### Step 1: Analyze Requirements

1. Read the user's request carefully — component, page, or application
2. Identify the purpose, audience, and context
3. Note any technical constraints (framework, performance, accessibility)
4. Ask clarifying questions if the aesthetic direction is ambiguous

### Step 2: Choose Aesthetic Direction

1. Select a BOLD aesthetic direction from the Tone options (or create a new one)
2. Define the "one memorable thing" — the signature visual element
3. Choose font pairings that match the direction
4. Build a 3-5 color palette with CSS variables
5. Decide on motion strategy: minimal and refined OR rich and expressive

### Step 3: Implement Structure

1. Create the HTML/component structure with semantic markup
2. Apply the layout composition (asymmetric, grid-breaking, etc.)
3. Implement responsive breakpoints with intentional mobile design
4. Ensure the structure supports the chosen aesthetic, not fights against it

### Step 4: Apply Visual Design

1. Apply typography with deliberate scale and weight contrast
2. Set color palette via CSS variables
3. Add backgrounds, textures, and atmospheric effects
4. Implement spatial composition with intentional spacing
5. Add decorative elements that reinforce the aesthetic

### Step 5: Add Motion & Polish

1. Implement page-load animations with staggered delays
2. Add scroll-triggered reveals via IntersectionObserver
3. Create hover states that surprise and delight
4. Apply custom easing curves (never default `ease`)
5. Add micro-interactions only where they enhance the experience

### Step 6: Refine & Verify

1. Review at multiple viewport sizes
2. Check color contrast for accessibility (WCAG AA minimum)
3. Verify all animations respect `prefers-reduced-motion`
4. Ensure the design feels cohesive — every element serves the aesthetic
5. Confirm the result does NOT look like generic AI output

## Best Practices

### General Design Principles

- **Intentionality over intensity**: Every design choice should have a reason
- **Match complexity to vision**: Maximalist designs need elaborate code; minimalist designs need restraint and precision
- **Cohesion**: All elements should feel like they belong to the same design system
- **Surprise**: Include at least one unexpected element that makes the design memorable
- **Restraint**: If choosing minimalism, precision in spacing, typography, and subtle details matters more than effects

### Technology-Specific Notes

**React Projects**:
- Use Motion library for animations (successor to framer-motion)
- Leverage CSS modules or styled-components for scoped styles
- Use CSS custom properties for theming

**HTML/CSS Projects**:
- Prefer CSS-only animations over JavaScript
- Use CSS Grid and Flexbox for layout
- Leverage `@keyframes` for complex animations

**Vue Projects**:
- Use Vue transitions for enter/leave animations
- Combine with CSS custom properties for theming
- Leverage `<TransitionGroup>` for list animations

## Common Issues

### Design Looks Generic

**Issue**: The output looks like a typical AI-generated page with purple gradients and Inter font.

**Solution**:
- Go back to Step 2 and choose a more specific, extreme aesthetic direction
- Replace all default fonts with distinctive alternatives
- Replace the color palette with something intentional and cohesive
- Add at least one unexpected layout element

### Fonts Not Loading

**Issue**: Custom web fonts fail to load.

**Solution**:
- Use `<link>` tags for Google Fonts, not `@import`
- Include `font-display: swap` in font-face declarations
- Always define a specific fallback stack (not just `sans-serif`)
- Consider self-hosting fonts for reliability

### Animations Feel Janky

**Issue**: Animations stutter or feel unnatural.

**Solution**:
- Only animate `transform` and `opacity` properties (GPU-accelerated)
- Use `will-change` sparingly for known animated elements
- Apply custom cubic-bezier easing curves
- Keep animation durations between 200-800ms
- Use `requestAnimationFrame` for JS-driven animations

### Design Works on Desktop Only

**Issue**: The design breaks on mobile or feels cramped.

**Solution**:
- Design mobile-first, then enhance for desktop
- Use relative units (rem, em, vh/vw) instead of fixed pixels
- Test at 375px, 768px, and 1024px minimum
- Stack layouts vertically on mobile, use horizontal space on desktop

## Verification Commands

After implementing a frontend design, validate the output:

```bash
# Validate HTML structure
npx -y html-validate index.html

# Check accessibility (WCAG AA)
npx -y pa11y index.html

# Lighthouse performance audit
npx -y lighthouse http://localhost:3000 --output=json

# Verify responsive breakpoints (manual test)
# Test at: 375px, 768px, 1024px, 1440px
```

**Verification Checklist**:
- [ ] Design matches chosen aesthetic direction
- [ ] Typography uses distinctive fonts (not Inter/Roboto/Arial/system-ui)
- [ ] Color palette defined via CSS custom properties
- [ ] At least one memorable/signature design element present
- [ ] Animations respect `prefers-reduced-motion` media query
- [ ] Responsive at 375px, 768px, 1024px minimum
- [ ] WCAG AA color contrast passes
- [ ] Result does NOT look like generic AI output
