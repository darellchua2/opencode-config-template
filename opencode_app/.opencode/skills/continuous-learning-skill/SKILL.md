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

I extract and persist actionable knowledge from coding sessions:

1. **Pattern Extraction**: Identify recurring code patterns, architectural decisions, and problem-solving approaches used during a session
2. **Insight Capture**: Record why specific decisions were made (rationale, trade-offs, alternatives considered)
3. **Knowledge Storage**: Save extracted patterns in structured format for future reference by agents and developers
4. **Session Summaries**: Generate concise summaries of what was learned or decided during a session
5. **Cross-Session Learning**: Build a knowledge base that improves agent performance over time

## When to use me

Use this skill when:
- A coding session produces reusable patterns or decisions worth preserving
- You want agents to learn from past sessions and avoid repeating mistakes
- You need to document architectural decisions made during implementation
- You want to build a team knowledge base from day-to-day coding
- A complex debugging session reveals non-obvious solutions worth recording

**Trigger phrases**:
- "learn from this session"
- "extract patterns"
- "save what we learned"
- "capture this decision"
- "remember this approach"

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

| Category | Examples |
|----------|----------|
| **Pattern** | "Repository pattern for data access", "Error boundary in React" |
| **Decision** | "Chose SQLite over PostgreSQL for local-first", "Used Zod for validation" |
| **Solution** | "Fix race condition with mutex", "Handle circular deps with lazy import" |
| **Convention** | "Use kebab-case for file names", "Route handlers return Result type" |
| **Anti-pattern** | "Avoid mutable global state in tests", "Don't nest promises" |

### Step 3: Structure the Knowledge

Format each learning as a structured entry:

```markdown
## [Category]: [Title]

**Context**: When/where this applies
**Pattern**: What the pattern or decision is
**Rationale**: Why this approach was chosen
**Code Example**: (if applicable)
**References**: Related files, docs, or external links
**Confidence**: high | medium | low
**Date**: When this was learned
```

### Step 4: Store and Index

Save to the project or user knowledge base:

- Project-level patterns: Store in project documentation or `.opencode/learnings/`
- User-level patterns: Store in user config `~/.config/opencode/learnings/`
- Index entries for quick retrieval by category or keyword

### Step 5: Suggest Applications

After storing, suggest where this knowledge could be applied:

- Similar codebases or projects
- Future sessions with related tasks
- Skills or agents that could benefit from this knowledge

## Learning Formats

### Short-Form (Quick Capture)

For quick captures during active development:

```markdown
### Decision: Use path aliases for imports

- **Why**: Avoids `../../../` relative paths, cleaner imports
- **Config**: tsconfig.json paths + next.config.js alias
- **Pattern**: `@/components/...` maps to `src/components/...`
```

### Long-Form (Detailed Analysis)

For complex architectural decisions or multi-step solutions:

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
3. Document why each step exists
4. Save as a reusable pattern

### End-of-Session Summary

```
"Summarize everything worth remembering from this session"
```

The skill will:
1. Scan all files changed in this session
2. Identify patterns, decisions, and solutions
3. Generate a structured summary
4. Store in the knowledge base

## References

- `strategic-compact` - Manages context window efficiently
- `verification-loop` - Verifies implementations against requirements
- `eval-harness` - Evaluates code and skill quality
