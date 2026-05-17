---
name: continuous-learning-skill
description: Extract and store reusable patterns, decisions, and insights from coding sessions for future reference and skill improvement
license: Apache-2.0
compatibility: opencode
metadata:
  audience: developers, agents
  workflow: learning, optimization
  trigger: explicit-only
---

## What I do

I extract and persist actionable knowledge from coding sessions using a dual-strategy approach:

1. **Pattern Extraction**: Identify recurring code patterns, architectural decisions, and problem-solving approaches
2. **Insight Capture**: Record why specific decisions were made (rationale, trade-offs, alternatives considered)
3. **Dual Storage**: Save to both `supermemory` (searchable, primary) and markdown files (curated, reviewable)
4. **Session Summaries**: Generate concise summaries of what was learned or decided
5. **Cross-Session Learning**: Build a knowledge base that improves agent performance over time

## When to use me

Use this skill when:
- A coding session produces reusable patterns or decisions worth preserving
- A code review or architecture review identifies systemic patterns
- You want agents to learn from past sessions and avoid repeating mistakes
- You need to document architectural decisions made during implementation
- A complex debugging session reveals non-obvious solutions worth recording
- A review agent detects the same issue in 3+ files (systemic pattern)

**Trigger phrases**:
- "learn from this session"
- "extract patterns"
- "save what we learned"
- "capture this decision"
- "remember this approach"

## Dual Storage Strategy

Knowledge is stored in TWO places with different strengths:

### Primary: `supermemory` (searchable, always available)

| Property | Detail |
|----------|--------|
| Tool | `supermemory` (mode: `add`) |
| Access | `supermemory` (mode: `search`) |
| Scope | `project` for project-specific, `user` for cross-project |
| Best for | Quick facts, decisions, anti-patterns, solutions |
| Strength | Relevance-based search, no file I/O needed |

**When to use supermemory ONLY (no markdown file):**
- Quick capture during active development
- Simple decisions ("Chose Zod for validation")
- Anti-patterns ("Avoid mutable default args in Python")
- Solutions ("Fix race condition with mutex")
- Facts about the project ("Uses Drizzle ORM, not Prisma")

### Secondary: `LEARNINGS/` markdown files (curated, reviewable, git-committed)

| Property | Detail |
|----------|--------|
| Location (project) | `LEARNINGS/<category>/<slug>.md` at repo root |
| Location (user) | `~/.config/opencode/learnings/<category>/<slug>.md` |
| Best for | Detailed patterns, formal ADRs, team conventions |
| Strength | Human-readable, git-history, PR-reviewable |

**When to use markdown files (also write to supermemory):**
- Complex architectural decisions with trade-offs
- Detailed pattern descriptions with code examples
- Team conventions that need documentation
- Anti-patterns with thorough explanations and alternatives
- Knowledge that benefits from human review and version history

## Storage Locations

```
Project-level (auto-provisioned, git-committed, shared with team):
  <project-root>/LEARNINGS/
  ├── _index.md                 # Auto-generated index
  ├── patterns/                 # Reusable approaches worth replicating
  ├── decisions/                # "We chose X over Y because..." (ADR-lite)
  ├── anti-patterns/            # Things to avoid
  ├── solutions/                # Non-obvious fixes worth remembering
  └── conventions/              # Team-agreed coding standards

User-level (created by setup.sh/setup.ps1, personal, cross-project):
  ~/.config/opencode/learnings/
  ├── _index.md
  ├── patterns/
  ├── decisions/
  ├── anti-patterns/
  ├── solutions/
  └── conventions/

Searchable memory (primary, always available):
  supermemory tool — mode: add/search, scope: project/user
```

### Auto-Provisioning

The `LEARNINGS/` directory does NOT need to exist before this skill runs. When writing a markdown learning file, **first check if the directory structure exists, and create it if missing**:

1. Check if `<project-root>/LEARNINGS/` exists (use `glob` for `LEARNINGS/_index.md`)
2. If missing, create the full structure:
   - `LEARNINGS/_index.md` (from template below)
   - `LEARNINGS/patterns/`, `LEARNINGS/decisions/`, `LEARNINGS/anti-patterns/`, `LEARNINGS/solutions/`, `LEARNINGS/conventions/`
   - Each subfolder gets a `.gitkeep` file
3. Then write the learning file to the appropriate subfolder
4. Then append to `_index.md`

**`_index.md` template for auto-provisioning:**
```markdown
# LEARNINGS Index

<!-- AUTO-GENERATED — manual edits to the listing below will be overwritten on next learning write -->

## Folder Structure

| Folder | Purpose | Example |
|--------|---------|---------|
| `patterns/` | Reusable code/architecture patterns worth replicating | `event-driven-modules.md` |
| `decisions/` | Architectural decisions with rationale (ADR-lite) | `sqlite-over-postgres-local.md` |
| `anti-patterns/` | Things to avoid, with explanations | `mutable-default-args-python.md` |
| `solutions/` | Non-obvious fixes and workarounds worth remembering | `race-condition-mutex-fix.md` |
| `conventions/` | Team-agreed coding standards and naming rules | `kebab-case-files.md` |

## Entries

<!-- Entries are appended here automatically when new learnings are saved -->

<!-- No entries yet -->
```

**Important**: OpenCode does NOT auto-scan `LEARNINGS/` directories. Agents discover learnings through:
1. AGENTS.md instructions (auto-loaded at session start) — tells agents where to look
2. `supermemory` search — primary retrieval mechanism
3. Explicit `glob`/`read` tool calls — for detailed markdown review

## Core Workflow

### Step 1: Analyze Session Context

Review the current session for extractable knowledge:

- Files created or modified
- Decisions made and rationale
- Errors encountered and solutions applied
- Patterns used (design patterns, code structures, naming conventions)
- Dependencies added or configured
- Configuration changes and why

### Step 2: Categorize Findings

Classify extracted knowledge into categories:

| Category | Folder | Examples | Default Storage |
|----------|--------|----------|----------------|
| **Pattern** | `patterns/` | "Repository pattern for data access", "Error boundary in React" | supermemory + markdown |
| **Decision** | `decisions/` | "Chose SQLite over PostgreSQL for local-first" | supermemory + markdown |
| **Solution** | `solutions/` | "Fix race condition with mutex" | supermemory only |
| **Convention** | `conventions/` | "Use kebab-case for file names" | supermemory + markdown |
| **Anti-pattern** | `anti-patterns/` | "Avoid mutable global state in tests" | supermemory only |

**Rule of thumb**: If it has trade-offs or code examples, write a markdown file too. If it's a one-liner insight, supermemory is sufficient.

### Step 3: Write to Supermemory (ALWAYS)

Every learning goes to supermemory first:

```
supermemory(mode: "add", content: "<structured learning>", scope: "project"|"user", type: "learned-pattern"|"decision"|"preference")
```

Format for supermemory content:
```
[Category]: [Title]
Context: [When/where this applies]
Detail: [What the pattern/decision is]
Rationale: [Why this approach]
Confidence: [high/medium/low]
Files: [related file paths, if any]
```

### Step 4: Write Markdown File (IF warranted)

For complex learnings, also create a markdown file:

```markdown
## [Category]: [Title]

**Context**: When/where this applies
**Pattern**: What the pattern or decision is
**Rationale**: Why this approach was chosen
**Alternatives Considered**: What else was evaluated
**Trade-offs**: Pros and cons of this approach
**Code Example**: (if applicable)
**References**: Related files, docs, or external links
**Confidence**: high | medium | low
**Date**: YYYY-MM-DD
```

**File naming**: Use descriptive slugs (e.g., `event-driven-modules.md`), not dated or numbered prefixes. The category is determined by the subfolder.

**Choosing scope**:
- Project-level (`LEARNINGS/`): Team conventions, project-specific decisions, architecture patterns
- User-level (`~/.config/opencode/learnings/`): Personal preferences, cross-project patterns, tool configurations

### Step 5: Update Index

After writing a markdown file, append an entry to the relevant `_index.md`:

```markdown
### [Title]

- **Category**: pattern | decision | anti-pattern | solution | convention
- **File**: `<category>/<slug>.md`
- **Summary**: One-line summary
- **Date**: YYYY-MM-DD
```

### Step 6: Suggest Applications

After storing, suggest where this knowledge could be applied:

- Similar codebases or projects
- Future sessions with related tasks
- Skills or agents that could benefit from this knowledge

## Post-Review Integration

When invoked by review agents (architecture-review, code-review), follow this behavior:

1. **Detect systemic patterns**: If the same issue appears in 3+ files, create a learning entry
2. **Capture decisions**: If the review recommends an architectural approach, record it
3. **Record anti-patterns**: If the review finds code that should be avoided, save it
4. **Note good patterns**: If the review finds exemplary code, flag it for replication
5. **Write to both stores**: supermemory (always) + markdown (if warranted by complexity)

## Learning Formats

### Short-Form (Quick Capture — supermemory only)

```
Decision: Use path aliases for imports
Why: Avoids ../../../ relative paths, cleaner imports
Config: tsconfig.json paths + next.config.js alias
Pattern: @/components/... maps to src/components/...
```

### Long-Form (Detailed Analysis — supermemory + markdown file)

```markdown
## Pattern: Event-Driven Module Communication

### Context
Modules need to communicate without tight coupling. Direct imports
create circular dependency issues in a growing codebase.

### Pattern
Use an event bus for cross-module communication:
- Publisher modules emit typed events
- Subscriber modules listen for specific event types
- No direct imports between modules

### Rationale
- Decouples modules completely
- Easy to add new subscribers without modifying publishers
- Testable in isolation
- Trade-off: harder to trace execution flow

### Code Example
[Relevant code snippet]

### References
- src/events/bus.ts
- src/modules/user/events.ts
```

## Retrieval Guide

When an agent needs to recall past learnings:

1. **First**: Search supermemory by relevance
   ```
   supermemory(mode: "search", query: "authentication pattern", scope: "project")
   ```

2. **For details**: Read the markdown file referenced in the supermemory result
   ```
   read(filePath: "LEARNINGS/patterns/event-driven-modules.md")
   ```

3. **For browsing**: Glob the learnings directory
   ```
   glob(pattern: "LEARNINGS/**/*.md")
   ```

## Integration with Other Skills

| Skill | Integration |
|-------|-------------|
| `verification-loop` | Verify learned patterns are correctly applied |
| `strategic-compact` | Compact session context but preserve learned insights |
| `eval-harness` | Evaluate if learned patterns improve code quality |
| `code-smells` | Patterns may reference anti-patterns detected by this skill |
| `design-patterns` | Learned patterns may align with or extend GoF patterns |

## Best Practices

### What to Capture

- Non-obvious solutions (things you had to research)
- Project-specific conventions discovered during development
- Performance optimizations and their measured impact
- Error patterns and their resolutions
- Architecture decisions and their trade-offs
- Systemic code review findings (same issue in 3+ files)

### What NOT to Capture

- Trivial or obvious code patterns
- Things already well-documented in standard references
- Temporary workarounds without long-term value
- Sensitive information (API keys, credentials, internal URLs)

### Quality Criteria

- Each learning should be **actionable**: someone can apply it
- Include **context**: when/where this applies
- Provide **rationale**: why this approach was chosen
- Set **confidence**: how certain are we this is correct

## Example Usage

### Mid-Session Capture

```
"Extract what we learned about the authentication flow"
```

The skill will:
1. Review the session's auth-related changes
2. Extract the flow pattern (middleware -> session check -> redirect)
3. Save to supermemory (always) and markdown (if complex)
4. Update index if markdown file was created

### Post-Review Capture

```
"After code review, save the recurring null-check pattern as an anti-pattern"
```

The skill will:
1. Review the findings from the code review
2. Identify systemic patterns (3+ occurrences)
3. Save anti-patterns to supermemory + markdown
4. Save good patterns for replication
5. Update index

### End-of-Session Summary

```
"Summarize everything worth remembering from this session"
```

The skill will:
1. Scan all files changed in this session
2. Identify patterns, decisions, and solutions
3. Generate a structured summary
4. Save to supermemory + markdown (where warranted)
5. Update index

## References

- `strategic-compact` - Manages context window efficiently
- `verification-loop` - Verifies implementations against requirements
- `eval-harness` - Evaluates code and skill quality
