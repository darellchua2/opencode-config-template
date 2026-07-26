## Anti-pattern: // comments in opencode_app/opencode.json break CI

**Context**: When editing `opencode_app/opencode.json`
**Pattern**: NEVER add `//` comment lines. The file must be valid standard JSON.
**Rationale**: opencode itself supports JSONC (strips comments at runtime), but the CI bats tests (`tests/test_mcp_count_consistency.bats`) parse the file with Python's `json.load()`, which does NOT support comments. Adding `//` category headers causes `json.decoder.JSONDecodeError` and CI failure.
**Alternatives Considered**: JSONC comments improve readability of the 80-entry allowlist. But CI compatibility trumps readability — the file must pass both parsers.
**Trade-offs**: Slightly less readable config (no inline documentation) vs. CI stability.
**Confidence**: 0.9
**Scope**: project
**Date**: 2026-07-26

**Evidence**:
- PR #271 added `// --- Category (N) ---` comments → CI run 30209072881 failed
- PR #272 removed all 10 comment lines → CI run 30209138797 passed
- Error: `json.decoder.JSONDecodeError: Expecting property name enclosed in double quotes: line 26 column 7`

**Fix command** (if comments accidentally re-added):
```bash
sed -i '/^\s*\/\//d' opencode_app/opencode.json
python3 -c "import json; json.load(open('opencode_app/opencode.json')); print('valid')"
```
