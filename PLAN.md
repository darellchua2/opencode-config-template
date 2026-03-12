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

### Phase 1: Research & Design
- [ ] Investigate OpenCode API for context usage metrics
- [ ] Research token counting approaches (approximate vs exact)
- [ ] Design configuration schema for context limits
- [ ] Evaluate compaction strategies (summarization, sliding window, priority-based)
- [ ] Document design decisions in technical spec

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
