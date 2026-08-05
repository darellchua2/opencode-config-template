# PLAN-GIT-317 — Recommend ripgrep as optional dependency

**Issue:** https://github.com/darellchua2/opencode-config-template/issues/317
**Branch:** `feat/rg-optional-deps`

## Overview

Surface `rg` (ripgrep) as a recommended optional dependency at three touchpoints: the setup script (warn on missing), README (Prerequisites section), and the deployed AGENTS.md (tool-routing preference). `rg` is optional — agents and scripts already fall back to `grep` when absent — so no hard dependency is introduced.

## Acceptance Criteria

- `setup.sh` warns (does NOT fail) when `rg` is absent, with one-line install hints for apt/brew/pacman
- README Prerequisites section mentions `rg` as recommended
- `deploy/.AGENTS.md` MCP Tool Routing section lists `rg` preference as the first bullet
- No edits to agent behavior, skill files, or runtime code — this is a docs/tooling-recommendation change only

## Scope

- `deploy/setup.sh` (`check_dependencies()` function)
- `README.md` (Prerequisites section, ~line 292)
- `deploy/.AGENTS.md` (MCP Tool Routing section, ~line 39)

---

## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---------------------|---------------------------|---------------------------------|-------------|
| `deploy/setup.sh`   | —                         | Users running `./deploy/setup.sh` | low |
| `README.md`         | —                         | Repo visitors, new contributors | low |
| `deploy/.AGENTS.md` | —                         | All opencode sessions (deployed to `~/.config/opencode/AGENTS.md`) | low |

All three phases are independent (one logical commit each) and touch different files. No phase depends on another.

## Implementation Phases

### Phase 1: `deploy/setup.sh` — Warn when `rg` is missing

**Commit:** `feat(deploy): warn when rg missing in setup.sh`

- [ ] **1.1** Add `rg` optional-dependency check in `check_dependencies()` after the existing `git` check (~line 1688)
    — **Why:** Matches the existing "optional but recommended" pattern for `git`; users need to know `rg` is preferred without blocking setup
    — **Done when:** `setup.sh` prints a warning with install hints when `command_exists rg` returns false
    — **Consumers affected:** Users running `./deploy/setup.sh` (informational only)

- [ ] **1.2** Include one-line install hints in the warning message for Debian/Ubuntu (`apt install ripgrep`), macOS (`brew install ripgrep`), and Arch (`pacman -S ripgrep`)
    — **Why:** Reduces friction — users can copy-paste the install command instead of searching
    — **Done when:** Warning output contains all three package-manager hints
    — **Consumers affected:** Users running `./deploy/setup.sh`

**Verification (shell test):**
```bash
# Mock rg as missing, run the dependency check function in isolation
PATH_BACKUP="$PATH"
export PATH="$(echo "$PATH" | tr ':' '\n' | grep -v 'ripgrep' | tr '\n' ':')"
unset -f rg 2>/dev/null
# Source setup.sh functions, then call check_dependencies
# Expected: WARN message about rg with install hints, exit code 0
export PATH="$PATH_BACKUP"
```

### Phase 2: `README.md` — Add `rg` to Prerequisites

**Commit:** `docs(readme): add rg to prerequisites`

- [ ] **2.1** Add one bullet to the Prerequisites section (~line 292, after the GitHub CLI line):
    `> ripgrep (`rg`) recommended for faster content search; falls back to `grep` if absent.`
    — **Why:** README is the first place new contributors look for setup requirements; surfacing `rg` here sets expectations early
    — **Done when:** The bullet appears in the rendered Prerequisites section between the GitHub CLI entry and the "Install GitHub CLI" subsection
    — **Consumers affected:** Repo visitors and new contributors reading the README

**Verification:**
```bash
grep -n 'ripgrep' README.md
# Expected: one match in the Prerequisites section (~line 293)
```

### Phase 3: `deploy/.AGENTS.md` — Prefer `rg` over `grep` in tooling routing

**Commit:** `docs(agents): prefer rg over grep in tooling routing`

- [ ] **3.1** Insert a new bullet as the **first item** under "MCP Tool Routing" (line 39, before "Web fetch"):
    `- **Content search:** prefer `rg` over `grep` when available (faster, respects `.gitignore`); agents already fall back to `grep` automatically if `rg` is absent.`
    — **Why:** `rg` preference is about built-in tool selection, not an MCP server, so it should lead the routing section; placing it first signals priority to the model
    — **Done when:** The new bullet appears at line 40 (first under `## MCP Tool Routing`), before the existing "Web fetch" bullet
    — **Consumers affected:** All opencode sessions that read `~/.config/opencode/AGENTS.md` after deploy

**Verification:**
```bash
grep -n 'ripgrep\|prefer.*rg\|Content search' deploy/.AGENTS.md
# Expected: one match at the top of MCP Tool Routing section
```

---

## Risks & Mitigation

| Risk | Likelihood | Mitigation |
|------|-----------|------------|
| `rg` check pattern differs from existing optional checks | Low | Follow the exact `git` check pattern in `check_dependencies()` |
| README Prerequisites section layout shifts | Low | Insert immediately after the GitHub CLI line; verify with `grep` |
| AGENTS.md bullet ordering confuses the model | Low | Place `rg` first because it is about built-in tools, not MCP servers |

## Success Metrics

- `setup.sh` runs successfully (exit 0) with and without `rg` installed
- README renders correctly with the new Prerequisite entry
- `deploy/.AGENTS.md` deploys cleanly via `setup.sh`
