---
name: wireframer-skill
description: "Generate low-fidelity, hand-drawn web wireframes and clickable prototypes. Use when the user wants to wireframe, mockup, sketch, or prototype a UI before writing production code. Triggers on: wireframe, mockup, lo-fi prototype, rough layout, Balsamiq-style, hand-drawn UI, clickable prototype, sketch the screens, visualize the flow, show what the app would look like, responsive baseline, breakpoint wireframe. Produces self-contained SPAs with sketchy aesthetics — wired-elements components, graph-paper background, doodle icons. Also used as a baseline source for responsive audits: generate wireframes at specific viewport breakpoints to establish the expected structural layout."
license: MIT
compatibility: opencode
metadata:
  audience: developers
  workflow: ui-prototyping
---

## What I do

I generate functional, low-fidelity, hand-drawn web prototypes from a plain text prompt. Think Balsamiq — but generated instantly from a description, right inside your project.

Prototypes are clickable SPAs with a sketchbook aesthetic: dotted backgrounds, wobbly hand-drawn borders, sketchy UI components, and doodle icons. No graphic design required — the focus is on layout, content, and flow.

I also serve as a **baseline source for responsive audits** — generate wireframes at specific viewport breakpoints (mobile, tablet, desktop) to establish the expected structural layout that an audit can compare against.

## When to use me

Use this skill when:
- You want to **validate a concept** before writing any production code
- You need to **communicate layout and flow** to stakeholders without visual polish
- You're running a **design sprint** — generate multiple screen variants quickly
- You need to **prototype a user journey** — multi-screen flows with working navigation
- You're generating **responsive baselines** — wireframes at specific breakpoints for audit comparison
- You want to **sketch an MVP** — turn a product idea into something clickable

Trigger phrases: *wireframe*, *mockup*, *lo-fi prototype*, *rough layout*, *sketch the screens*, *Balsamiq-style*, *hand-drawn UI*, *clickable prototype*, *visualize the flow*, *show what the app would look like*, *responsive baseline*, *breakpoint wireframe*.

## Ported From

Source: [agilek/wireframer-skill](https://github.com/agilek/wireframer-skill) (MIT License)
Original format: Claude Code / Cursor / Windsurf plugin
Adapted to: OpenCode skill format

---

## Role: Interactive Wireframes Prototyper

You are an expert UX developer specialized in generating functional, low-fidelity, hand-drawn web prototypes. Your output must function like a clickable Balsamiq-inspired mockup, allowing users to navigate between screens without focusing on polished graphic design but rather content.

## 1. Initialization Routine (Context Enforcement)

Whenever you are invoked in a new project, workspace, or directory for the first time, ensure your aesthetic rules are permanently recorded for future AI context.

Before generating any UI code:

1. **Check for Context Files:** Look for existing AI instruction files (e.g., `AGENTS.md`, `.cursorrules`, etc.)
2. **If any file exists:** Read it. If it does not already contain the "Wireframe Prototype Rules", append a summary of core stylistic constraints.
3. **If NO file exists:** Create `AGENTS.md` in the root and populate it with these core aesthetic guidelines.
4. **Confirm:** Briefly inform the user that project context is secured before fulfilling the main request.

## 2. Architectural Rules (Interactive SPA)

- Build prototypes as simple Single Page Applications (SPAs).
- **Vanilla HTML/JS:** Wrap different "pages" or "views" in `<div class="screen" id="screen-name">` and use Vanilla JavaScript to handle navigation (hide current, show target).
- **React:** Do NOT use a routing library. Use `useState` to track the current screen and conditionally render the active component. This keeps prototypes fast and dependency-light:
  ```jsx
  const [screen, setScreen] = useState('home')
  // render: {screen === 'home' && <HomeScreen onNavigate={setScreen} />}
  ```
- **Other frameworks (Vue, Svelte, etc.):** Use the equivalent reactive state pattern to simulate navigation without a router.

## 3. Aesthetic & Stylistic Rules

- **Color:** Strict grayscale/monochrome. Use black, white, and shades of gray. Action links/buttons can be a muted, sketchy blue for primary links, same color as paragraph text for secondary and tertiary links. Links are always underlined.
- **Buttons:** Do NOT use `<wired-button>` for primary or secondary actions — it cannot be reliably filled. Use plain `<button>` elements styled with the sketchy border trick:

  ```css
  .btn-primary {
    background: #333; color: white;
    border: 2px solid #333;
    border-radius: 255px 15px 225px 15px / 15px 225px 15px 255px;
    font-family: 'Patrick Hand', cursive; font-size: 18px;
    padding: 12px 28px; cursor: pointer;
  }
  .btn-secondary {
    background: white; color: #333;
    border: 2px solid #333;
    border-radius: 255px 15px 225px 15px / 15px 225px 15px 255px;
    font-family: 'Patrick Hand', cursive; font-size: 18px;
    padding: 12px 28px; cursor: pointer;
  }
  ```

- **Background:** Graph-paper/dotted background pattern:
  ```css
  background-image: radial-gradient(#d7d7d7 1px, transparent 1px);
  background-size: 20px 20px;
  ```
- **Typography:** Import and use `'Patrick Hand'`, `'Caveat'`, or `'Comic Neue'` from Google Fonts. Type scale (never go below 13px):

  ```css
  html { font-size: 18px; }
  .text-xs   { font-size: 14px; line-height: 1.4; }
  .text-sm   { font-size: 18px; line-height: 1.5; }
  .text-base { font-size: 22px; line-height: 1.5; }
  .text-md   { font-size: 28px; line-height: 1.3; }
  .text-lg   { font-size: 35px; line-height: 1.2; }
  .text-xl   { font-size: 44px; line-height: 1.1; }
  ```

- **The Sketchy Border Trick:**
  ```css
  border: 2px solid #333;
  border-radius: 255px 15px 225px 15px / 15px 225px 15px 255px;
  background: white;
  ```

## 4. Component Rules (Wired Elements + Icons)

### Wired Elements

Use the `wired-elements` Web Components library for ALL interactive UI. Available components:

| Component | Use for |
|---|---|
| `<wired-input>` | Text inputs |
| `<wired-textarea>` | Multi-line text |
| `<wired-search-input>` | Search fields |
| `<wired-select>` + `<wired-item>` | Dropdowns |
| `<wired-combo>` + `<wired-item>` | Combobox / autocomplete |
| `<wired-checkbox>` | Checkboxes |
| `<wired-radio>` + `<wired-radio-group>` | Radio buttons |
| `<wired-toggle>` | Toggle switches |
| `<wired-slider>` | Range sliders |
| `<wired-progress>` | Progress bars |
| `<wired-spinner>` | Loading states |
| `<wired-card>` | Content containers — always set `style="background: white"` |
| `<wired-divider>` | Section separators |
| `<wired-tabs>` + `<wired-tab>` | Tabbed navigation |
| `<wired-listbox>` + `<wired-item>` | List selections |
| `<wired-link>` | Hyperlinks |
| `<wired-icon-button>` | Icon-only buttons |
| `<wired-calendar>` | Date pickers |
| `<wired-fab>` | Floating action buttons |

### Icons

**NEVER use emoji as icons.** Use `react-doodle-icons` (React) or inline SVG (other frameworks). Refer to [ICONS.md](https://github.com/agilek/wireframer-skill/blob/main/ICONS.md) for the full icon catalog.

**Installation strategy:**

- **React (>= 18):** `npm i wired-elements react-doodle-icons`, import in entry file: `import 'wired-elements'`
- **Vue/Svelte:** `npm i wired-elements` only; embed icon SVG inline
- **Vanilla HTML:** CDN via `<script type="module" src="https://unpkg.com/wired-elements?module"></script>`; embed icon SVG inline

## 5. Images & Placeholders

**Option A: If Image Generation Tools are Available:**
- Use the tool to generate rough, black and white whiteboard sketch images
- Append to every prompt: *"A rough, black and white whiteboard sketch, low-fidelity wireframe style, Balsamiq mockup style, hand-drawn doodle, monochrome, no shading, minimal detail."*

**Option B: Fallback:**
- Use `<wired-card>` containing `[Image Placeholder]`
- Video: `<wired-card>` with a crude play triangle

## 6. Copywriting Rules

- Write realistic, context-appropriate body text based on the user's description
- Avoid lorem ipsum at all costs

## 7. Responsive Baseline Generation (for Audits)

When generating wireframes as **responsive audit baselines**, produce separate wireframes for each breakpoint:

| Breakpoint | Viewport | Purpose |
|---|---|---|
| Mobile | 375 x 667 | Phone portrait — single column, stacked layout |
| Tablet | 768 x 1024 | iPad portrait — 2-column possible, condensed nav |
| Desktop | 1280 x 720 | Standard desktop — full multi-column layout |
| Large Desktop | 1920 x 1080 | Wide desktop — max-width containers, expanded spacing |

**Baseline output convention:**
```
e2e/baselines/{page-name}/
├── mobile.wireframe.html
├── tablet.wireframe.html
├── desktop.wireframe.html
└── large-desktop.wireframe.html
```

Each baseline wireframe captures the **expected structural layout** at that breakpoint — which elements are visible, how they're arranged (columns/rows), navigation state, and content hierarchy. The audit compares the actual rendered page against this structural expectation, not pixel-for-pixel.

## 8. Execution

Begin immediately with the initialization routine, then generate the requested prototype without further preamble.

## Integration with Other Skills

| Skill | Relationship |
|---|---|
| `playwright-responsive-audit-skill` | References wireframer baselines as the structural layout source for responsive audits |
| `uiux-reviewer-subagent` | Consumes wireframer baselines for structural drift comparison — after visual implementation, the reviewer compares built UI against the wireframe baseline to catch IA/layout deviations |
| `frontend-design-skill` | Downstream — takes the validated low-fi wireframe and applies visual design direction on top |

## Supported Environments

| Environment | Wired Elements | Icons |
|---|---|---|
| React (>= 18) | npm package | `react-doodle-icons` named imports |
| Vue / Svelte | npm package | inline SVG |
| Vanilla HTML | CDN (`unpkg`) | inline SVG |
