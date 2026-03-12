# Plan: Implement Context Compaction for Subagents

## Issue Reference
- **Number**: #77
- **URL**: https://github.com/darellchua2/opencode-config-template/issues/77
- **Labels**: enhancement

## Overview
Add automatic context compaction capability to subagents when they reach configurable context limits. This will prevent subagents from hitting context window limits during long-running tasks and improve overall efficiency.

## Acceptance Criteria
- [ ] Subagents can monitor their context usage
- [ ] Configurable context limit thresholds per subagent type
- [ ] Automatic compaction triggers when threshold is reached
- [ ] Compaction preserves critical information (task state, recent context)
- [ ] No data loss during compaction process
- [ ] Tests for compaction functionality
- [ ] Documentation for configuration options

## Scope
- `agents/` - Subagent definitions and configurations
- `config.json` - Context limit configuration
- Documentation in README or AGENTS.md

---

## Sub-issues

| # | Title | Description |
|---|-------|-------------|
| #79 | Context usage monitoring | Track token usage in subagents |
| #80 | Compaction strategy | Implement compaction mechanism |
| #82 | Configuration | Per-subagent context limits |
| #81 | Documentation | Update docs with compaction info |

---

## Implementation Phases

### Phase 1: Research & Design ✅
- [x] Investigate OpenCode API for context usage metrics
- [x] Research token counting approaches (approximate vs exact)
- [x] Design configuration schema for context limits
- [x] Evaluate compaction strategies (summarization, sliding window, priority-based)
- [x] Document design decisions in technical spec

**Key Discovery**: OpenCode has **built-in context compaction** at the global level.

#### Existing OpenCode Compaction Feature

OpenCode already implements context compaction with these configuration options:

```json
{
  "compaction": {
    "auto": true,      // Automatically compact when context is full (default: true)
    "prune": true,     // Remove old tool outputs to save tokens (default: true)
    "reserved": 10000  // Token buffer for compaction
  }
}
```

OpenCode also has a built-in **compaction agent** (hidden, runs automatically):
- Compacts long context into smaller summaries
- Runs automatically when needed
- Not selectable in UI

#### Research Conclusions

1. **Global compaction exists**: OpenCode handles context compaction at the session level
2. **Subagents inherit**: Subagents likely inherit compaction from parent session
3. **Gap**: No per-subagent compaction configuration currently exists
4. **Recommendation**: Document existing feature and propose per-subagent extensions if needed

#### Revised Scope

Based on research, the implementation should focus on:
1. **Document existing compaction** - Add README section explaining global compaction
2. **Test subagent compaction** - Verify subagents benefit from global compaction
3. **Propose per-subagent config** (if needed) - Optional per-agent compaction settings
4. **Close sub-issues** - May not need separate implementations

### Phase 2: Context Monitoring (#79)
- [ ] Implement token counting utility
- [ ] Add context tracking to subagent execution
- [ ] Expose context usage as metric
- [ ] Implement warning threshold detection
- [ ] Add logging for context usage

### Phase 3: Compaction Strategy (#80)
- [ ] Implement base compaction interface
- [ ] Implement sliding window strategy
- [ ] Implement summarization strategy (optional, may need LLM)
- [ ] Implement priority-based retention
- [ ] Add compaction trigger logic
- [ ] Ensure critical state preservation

### Phase 4: Configuration (#82)
- [ ] Add context limit fields to config.json schema
- [ ] Implement default limits
- [ ] Add per-subagent override capability
- [ ] Add configuration validation
- [ ] Test configuration loading

### Phase 5: Testing
- [ ] Unit tests for token counting
- [ ] Unit tests for compaction strategies
- [ ] Integration tests for end-to-end flow
- [ ] Edge case tests (empty context, max size)
- [ ] Performance tests for large contexts

### Phase 6: Documentation (#81)
- [ ] Update README.md with feature overview
- [ ] Add configuration examples
- [ ] Update AGENTS.md with best practices
- [ ] Add troubleshooting guide
- [ ] Create migration guide (if needed)

---

## Technical Notes

### Context Compaction Approaches

**1. Sliding Window**
- Keep last N messages
- Simple and predictable
- May lose important early context

**2. Summarization**
- Use LLM to summarize old messages
- Preserves semantic information
- Requires additional LLM call

**3. Priority-Based Retention**
- Tag messages with priority levels
- Keep high-priority messages longer
- More complex to implement

### Token Counting

**Approximate Method:**
- 4 characters ≈ 1 token (rough estimate)
- Fast but imprecise
- Good for threshold detection

**Exact Method:**
- Use tiktoken or similar library
- Accurate but slower
- Better for critical applications

### Critical Information to Preserve

During compaction, always retain:
1. Current task description
2. Most recent 3-5 messages
3. Tool results that are still relevant
4. State variables and context

---

## Dependencies
- OpenCode API capabilities for context introspection
- Token counting library (if exact counting needed)
- LLM access for summarization (if that strategy is chosen)

## Risks & Mitigation

| Risk | Impact | Mitigation |
|------|--------|------------|
| Context loss during compaction | High | Preserve critical info, test thoroughly |
| Performance overhead | Medium | Use approximate counting, async compaction |
| Configuration complexity | Low | Sensible defaults, clear documentation |
| LLM summarization cost | Medium | Make summarization optional, use cheaper models |

## Success Metrics
- Subagents can complete long-running tasks without context errors
- Compaction overhead < 5% of total execution time
- Zero data loss in production use
- Clear configuration and documentation

---

## Research Findings (Phase 1 Complete)

### OpenCode Built-in Compaction

OpenCode already provides context compaction at the global level:

| Feature | Status | Description |
|---------|--------|-------------|
| `compaction.auto` | ✅ Exists | Auto-compact when context full |
| `compaction.prune` | ✅ Exists | Remove old tool outputs |
| `compaction.reserved` | ✅ Exists | Token buffer for compaction |
| Compaction Agent | ✅ Exists | Hidden system agent for compaction |
| Per-subagent config | ❌ Missing | No per-agent compaction settings |

### Configuration Example

```json
{
  "$schema": "https://opencode.ai/config.json",
  "compaction": {
    "auto": true,
    "prune": true,
    "reserved": 10000
  }
}
```

### Updated Implementation Approach

Since global compaction exists, the scope changes to:

1. **Documentation** (Primary)
   - Add compaction section to README.md
   - Explain how global compaction affects subagents
   - Provide configuration examples

2. **Verification** (Secondary)
   - Test that subagents benefit from global compaction
   - Verify no context errors in long-running subagent tasks

3. **Enhancement Proposal** (Optional)
   - Propose per-subagent compaction config if needed
   - Consider adding `agent.*.compaction` to config schema

### Recommendation

**Close sub-issues #79, #80, #82** - Global compaction handles these concerns.

**Keep #81** - Documentation still needed.

**New approach**: Document existing feature rather than re-implement.
