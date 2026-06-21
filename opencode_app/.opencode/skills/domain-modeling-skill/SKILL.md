---
name: domain-modeling-skill
description: Actively build and sharpen a project's domain model. Use when the user wants to pin down domain terminology or a ubiquitous language, record an architectural decision, or when another skill needs to maintain CONTEXT.md and ADRs inline. Changes the model — not merely reads it.
license: Apache-2.0
compatibility: opencode
metadata:
  audience: developers, agents
  workflow: documentation, domain-design
  trigger: auto
version: 1
---

## What I do

I actively build and sharpen the project's domain model as you design. This is the **active** discipline — challenging terms, inventing edge-case scenarios, and writing the glossary and decisions down the moment they crystallise.

Merely *reading* `CONTEXT.md` for vocabulary is NOT this skill — that's a one-line habit any skill can do. I am for when you're **changing** the model, not just consuming it.

1. **Challenge terms** against the existing glossary and surface contradictions immediately
2. **Sharpen fuzzy language** by proposing precise canonical terms
3. **Stress-test with scenarios** that probe edge cases and force precision about concept boundaries
4. **Cross-reference with code** — when the user states how something works, verify the code agrees
5. **Update CONTEXT.md inline** — capture resolved terms immediately, never batch them
6. **Offer ADRs sparingly** — only when a decision is hard-to-reverse, surprising, and a real trade-off

I am the **docs engine** (model-invoked). `grill-with-docs-skill` pairs me with `grilling-skill` so docs are captured during the interview.

## When to use me

Use this skill when:
- The user introduces or disputes domain terminology
- A ubiquitous language needs to be established or sharpened
- An architectural decision has just been made and may warrant an ADR
- Another skill (e.g. `grill-with-docs-skill`) delegates doc maintenance during a session
- Code contradicts the user's stated understanding of how the system works

**Trigger phrases**:
- "let's define our terms"
- "that should be an ADR"
- "update CONTEXT.md"
- "is that the right word for"
- "capture this decision"
- "ubiquitous language"

## File Structure

### Single-context repos (most repos)

```
/
├── CONTEXT.md
├── docs/
│   └── adr/
│       ├── 0001-event-sourced-orders.md
│       └── 0002-postgres-for-write-model.md
└── src/
```

### Multi-context repos

If a `CONTEXT-MAP.md` exists at the root, the repo has multiple contexts. The map points to where each one lives:

```
/
├── CONTEXT-MAP.md
├── docs/
│   └── adr/                          # system-wide decisions
├── src/
│   ├── ordering/
│   │   ├── CONTEXT.md
│   │   └── docs/adr/                 # context-specific decisions
│   └── billing/
│       ├── CONTEXT.md
│       └── docs/adr/
```

### Create files lazily

Only create files when you have something to write:
- No `CONTEXT.md` → create one when the first term is resolved
- No `docs/adr/` → create it when the first ADR is needed

**Inference rules:**
- If `CONTEXT-MAP.md` exists → read it to find contexts
- If only a root `CONTEXT.md` exists → single context
- If neither exists → create a root `CONTEXT.md` lazily when the first term resolves

When multiple contexts exist, infer which one the current topic relates to. If unclear, ask.

## Core Workflow

### Step 1: Challenge against the glossary

When the user uses a term that conflicts with the existing language in `CONTEXT.md`, call it out immediately:

> "Your glossary defines 'cancellation' as X, but you seem to mean Y — which is it?"

### Step 2: Sharpen fuzzy language

When the user uses vague or overloaded terms, propose a precise canonical term:

> "You're saying 'account' — do you mean the Customer or the User? Those are different things."

### Step 3: Discuss concrete scenarios

When domain relationships are being discussed, stress-test them with specific scenarios. Invent scenarios that probe edge cases and force the user to be precise about the boundaries between concepts.

### Step 4: Cross-reference with code

When the user states how something works, check whether the code agrees. If you find a contradiction, surface it:

> "Your code cancels entire Orders, but you just said partial cancellation is possible — which is right?"

### Step 5: Update CONTEXT.md inline

When a term is resolved, update `CONTEXT.md` right there. Do not batch these up — capture them as they happen. Use the **CONTEXT.md Format** below.

`CONTEXT.md` must be **totally devoid of implementation details**. Do not treat it as a spec, a scratch pad, or a repository for implementation decisions. It is a glossary and nothing else.

### Step 6: Offer ADRs sparingly

Only offer to create an ADR when **all three** are true:

1. **Hard to reverse** — the cost of changing your mind later is meaningful
2. **Surprising without context** — a future reader will wonder "why did they do it this way?"
3. **The result of a real trade-off** — there were genuine alternatives and you picked one for specific reasons

If any of the three is missing, **skip the ADR**. Use the **ADR Format** below.

## CONTEXT.md Format

### Structure

```md
# {Context Name}

{One or two sentence description of what this context is and why it exists.}

## Language

**Order**:
{A one or two sentence description of the term}
_Avoid_: Purchase, transaction

**Invoice**:
A request for payment sent to a customer after delivery.
_Avoid_: Bill, payment request

**Customer**:
A person or organization that places orders.
_Avoid_: Client, buyer, account
```

### Rules

- **Be opinionated.** When multiple words exist for the same concept, pick the best one and list the others under `_Avoid_`.
- **Keep definitions tight.** One or two sentences max. Define what it IS, not what it does.
- **Only include project-specific terms.** General programming concepts (timeouts, error types, utility patterns) don't belong. Before adding a term, ask: is this a concept unique to this context, or a general programming concept? Only the former belongs.
- **Group terms under subheadings** when natural clusters emerge. If all terms belong to a single cohesive area, a flat list is fine.

### Multi-context map

```md
# Context Map

## Contexts

- [Ordering](./src/ordering/CONTEXT.md) — receives and tracks customer orders
- [Billing](./src/billing/CONTEXT.md) — generates invoices and processes payments

## Relationships

- **Ordering → Billing**: Ordering emits `OrderPlaced` events; Billing consumes them to generate invoices
- **Ordering ↔ Billing**: Shared types for `CustomerId` and `Money`
```

## ADR Format

ADRs live in `docs/adr/` and use sequential numbering: `0001-slug.md`, `0002-slug.md`, etc. Create the directory lazily.

### Template

```md
# {Short title of the decision}

{1-3 sentences: what's the context, what did we decide, and why.}
```

That's it. An ADR can be a single paragraph. The value is in recording *that* a decision was made and *why* — not in filling out sections.

### Optional sections

Only include these when they add genuine value. Most ADRs won't need them:

- **Status** frontmatter (`proposed | accepted | deprecated | superseded by ADR-NNNN`) — useful when decisions are revisited
- **Considered Options** — only when the rejected alternatives are worth remembering
- **Consequences** — only when non-obvious downstream effects need to be called out

### Numbering

Scan `docs/adr/` for the highest existing number and increment by one.

### What qualifies for an ADR

All three of these must be true (hard to reverse + surprising + real trade-off). If a decision is easy to reverse, skip it — you'll just reverse it. If it's not surprising, nobody will wonder why. If there was no real alternative, there's nothing to record.

| Qualifies | Example |
|-----------|---------|
| **Architectural shape** | "We're using a monorepo." "The write model is event-sourced, the read model is projected into Postgres." |
| **Integration patterns between contexts** | "Ordering and Billing communicate via domain events, not synchronous HTTP." |
| **Technology choices that carry lock-in** | Database, message bus, auth provider, deployment target — not every library, just ones that would take a quarter to swap out |
| **Boundary and scope decisions** | "Customer data is owned by the Customer context; others reference it by ID only." The explicit no-s are as valuable as the yes-s. |
| **Deliberate deviations from the obvious path** | "We're using manual SQL instead of an ORM because X." Stops the next engineer from "fixing" something that was deliberate. |
| **Constraints not visible in code** | "We can't use AWS because of compliance." "Response times must be under 200ms because of the partner API contract." |
| **Rejected alternatives when non-obvious** | If you considered GraphQL and picked REST for subtle reasons, record it — otherwise someone will suggest GraphQL again in six months. |

## Rules

- **Never put implementation details in CONTEXT.md.** It is a glossary, not a spec.
- **Capture inline, not in batches.** Resolved terms and decisions are written the moment they crystallise.
- **Be opinionated about language.** Pick the best word; list the others under `_Avoid_`.
- **Don't create ADRs reflexively.** The three-criteria gate exists to keep signal high.
- **Verify claims against code.** The user's mental model and the code can drift; your job is to catch it.

## Integration with Other Skills

| Skill | Integration |
|-------|-------------|
| `grill-with-docs-skill` | Orchestrates `grilling-skill` + me to capture docs during an interview |
| `grilling-skill` | The interview engine whose resolved terms I write down |
| `continuous-learning-skill` | ADRs and glossary entries feed into long-term learning storage |
| `architecture-review-subagent` | Review findings may surface decisions worth recording as ADRs |

## Example Usage

### During a grilling session

```
User: "When an order is cancelled, we refund the original payment method."
Agent: "Quick glossary check — your CONTEXT.md defines 'cancellation' as voiding before fulfillment.
        You just described refunding a *delivered* order, which sounds different. Is that
        'return'? I'll add both terms if they're distinct."
```

The skill will:
1. Cross-reference the claim against the existing `CONTEXT.md`
2. Surface the contradiction
3. Propose precise terms (`cancellation` vs `return`)
4. Update `CONTEXT.md` inline once resolved

### Offer an ADR

```
Agent: "We've decided ordering and billing communicate via domain events rather than
        synchronous HTTP. That's hard to reverse, surprising (most teams default to HTTP),
        and a real trade-off (eventual consistency). Want me to record it as ADR-0003?"
```

## References

- `grill-with-docs-skill` - User-facing command that pairs `grilling-skill` with me
- `grilling-skill` - The interview engine I capture docs from
- `continuous-learning-skill` - Long-term storage for decisions
