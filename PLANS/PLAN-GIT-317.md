# PLAN-GIT-317 — Recommend ripgrep as optional dependency

**Issue:** https://github.com/darellchua2/opencode-config-template/issues/317
**Branch:** `feat/rg-optional-deps`

## Overview

Surface `rg` (ripgrep) as a recommended optional dependency at four touchpoints: both setup scripts (warn on missing — `setup.sh` + `setup.ps1` for platform parity), README (Prerequisites section), and the deployed AGENTS.md (new "Built-in Tool Preferences" section, kept separate from MCP Tool Routing since `rg` is a shell binary, not an MCP tool). `rg` is optional — agents and scripts already fall back to `grep` when absent — so no hard dependency is introduced.

**Rev. 2** — incorporates reviewer feedback (architecture + opencode-tooling): adds Phase 1b (Windows parity), relocates AGENTS.md bullet to a dedicated section (SRP), fixes broken Phase 1 verification mock.

## Acceptance Criteria

- `setup.sh` warns (does NOT fail) when `rg` is absent, with one-line install hints for apt/brew/pacman
- `setup.ps1` mirrors the warn (Windows parity mandated by repo AGENTS.md), with install hints for winget/scoop/choco
- README Prerequisites section mentions `rg` as recommended
- `deploy/.AGENTS.md` has a new `## Built-in Tool Preferences` section (between MCP Tool Routing and CodeGraph) containing the `rg` preference — NOT inside MCP Tool Routing, since `rg` is a shell binary, not an MCP tool
- No edits to agent behavior, skill files, or runtime code — this is a docs/tooling-recommendation change only

## Scope

- `deploy/setup.sh` (`check_dependencies()` function, ~line 1688)
- `deploy/setup.ps1` (`Test-Dependencies` function, ~line 1017) — Windows mirror
- `README.md` (Prerequisites section, ~line 292)
- `deploy/.AGENTS.md` (new `## Built-in Tool Preferences` section, inserted between MCP Tool Routing and CodeGraph at ~line 45)

---

## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---------------------|---------------------------|---------------------------------|-------------|
| `deploy/setup.sh`   | —                         | Users running `./deploy/setup.sh` (macOS/Linux) | low |
| `deploy/setup.ps1`  | Mirrors `setup.sh` (Windows parity mandated by repo AGENTS.md) | Users running `.\deploy\setup.ps1` (Windows) | low |
| `README.md`         | —                         | Repo visitors, new contributors | low |
| `deploy/.AGENTS.md` | —                         | All opencode sessions (deployed to `~/.config/opencode/AGENTS.md`) | low |

All phases are independent (one logical commit each, except Phase 1 + 1b which share a commit) and touch different files.

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
# setup.sh is source-safe (guard at line ~3793), so source it in a subshell,
# override command_exists to simulate rg missing, then call check_dependencies.
# The previous mock (unset -f rg + grep -v 'ripgrep' on PATH) was a no-op:
# rg is a binary (not a shell function) and /usr/bin/rg contains no "ripgrep" string.
(
  source ./deploy/setup.sh
  command_exists() { [ "$1" = "rg" ] && return 1; command -v "$1" >/dev/null 2>&1; }
  check_dependencies 2>&1 | grep -E 'ripgrep|rg|apt install|brew install|pacman'
)
# Expected: warning line with all three install hints (apt/brew/pacman); exit code 0
```

### Phase 1b: `deploy/setup.ps1` — Windows mirror

**Commit:** `feat(deploy): warn when rg missing in setup scripts` (same commit as Phase 1)

- [ ] **1b.1** Add `rg` optional-dependency check in `Test-Dependencies` (after the existing `git` check, ~line 1017), mirroring Phase 1's logic.
    - Use `Write-LogWarn` for the warning (matching the existing `git` warn pattern at line 1016).
    - Include Windows package-manager install hints: `winget install BurntSushi.ripgrep.MSVC`, `scoop install ripgrep`, `choco install ripgrep`.
    — **Why:** Repo AGENTS.md mandates `setup.ps1` = "Mirror of setup.sh (Windows parity)". Omitting creates platform asymmetry — macOS/Linux users see the warning, Windows users do not.
    — **Done when:** `setup.ps1` prints a `Write-LogWarn` with Windows install hints when `Test-CommandExists "rg"` returns false; function still returns `$true`.
    — **Consumers affected:** Windows users running `.\deploy\setup.ps1`

**Verification (PowerShell test):**
```powershell
# Source setup.ps1, override Test-CommandExists to simulate rg missing, then call Test-Dependencies.
. .\deploy\setup.ps1
function Test-CommandExists($cmd) { if ($cmd -eq 'rg') { return $false } else { Get-Command $cmd -ErrorAction SilentlyContinue } }
Test-Dependencies *>&1 | Select-String 'ripgrep|winget|scoop|choco'
# Expected: warning line with all three Windows install hints; function returns $true
```

### Phase 2: `README.md` — Add `rg` to Prerequisites

**Commit:** `docs(readme): add rg to prerequisites`

- [ ] **2.1** Add one bullet to the Prerequisites section (~line 292, after the GitHub CLI line), matching the existing bold-label format of the other bullets:
    `- **ripgrep (`rg`)** (recommended for faster content search; falls back to `grep` if absent)`
    — **Why:** README is the first place new contributors look for setup requirements; surfacing `rg` here sets expectations early. Bold-label format matches the surrounding style (e.g., `**Node.js v20+**`, `**GitHub CLI**`); a leading `>` would render as a blockquote.
    — **Done when:** The bullet appears in the rendered Prerequisites section between the GitHub CLI entry and the "Install GitHub CLI" subsection, using the bold-label format
    — **Consumers affected:** Repo visitors and new contributors reading the README

**Verification:**
```bash
grep -n 'ripgrep' README.md
# Expected: one match in the Prerequisites section (~line 293)
```

### Phase 3: `deploy/.AGENTS.md` — New "Built-in Tool Preferences" section

**Commit:** `docs(agents): add built-in tool preferences section for rg`

- [ ] **3.1** Insert a new `## Built-in Tool Preferences` section between `## MCP Tool Routing` (ends at line 43) and `## CodeGraph` (line 45). Place the new section header at line 45 (pushing CodeGraph down). Section content:
    ```
    ## Built-in Tool Preferences

    - **Content search:** prefer `rg` (ripgrep) over `grep` when available — faster, respects `.gitignore` by default, multithreaded. Agents already fall back to `grep` automatically if `rg` is absent (no hard dependency). Install: `apt install ripgrep` / `brew install ripgrep` / `pacman -S ripgrep`.
    ```
    — **Why:** `rg` is a shell binary invoked via the Bash tool, not an MCP server tool — placing it under "MCP Tool Routing" would violate section cohesion (SRP: the section's single responsibility is MCP server disambiguation). A dedicated section gives built-in tool preferences a semantically honest home and leaves room for future built-in-tool tips without polluting MCP routing.
    — **Done when:** The new `## Built-in Tool Preferences` section appears between MCP Tool Routing and CodeGraph; `rg` bullet is the first (and currently only) entry; MCP Tool Routing section is unchanged.
    — **Consumers affected:** All opencode sessions that read `~/.config/opencode/AGENTS.md` after deploy

**Verification:**
```bash
# New section header appears between MCP Tool Routing and CodeGraph
grep -n '## Built-in Tool Preferences' deploy/.AGENTS.md
# Expected: one match at ~line 45

# MCP Tool Routing section is unchanged (no rg mention leaked into it)
sed -n '/## MCP Tool Routing/,/## Built-in Tool Preferences/p' deploy/.AGENTS.md | grep -c 'ripgrep\|`rg`'
# Expected: 0
```

---

## Risks & Mitigation

| Risk | Likelihood | Mitigation |
|------|-----------|------------|
| `rg` check pattern differs from existing optional checks | Low | Follow the exact `git` check pattern in `check_dependencies()` / `Test-Dependencies` |
| README Prerequisites section layout shifts | Low | Insert immediately after the GitHub CLI line; verify with `grep` |
| Windows/macOS parity drift between setup.sh and setup.ps1 | Low | Both scripts updated in lockstep (Phase 1 + 1b, same commit) |
| Section placement dilutes MCP Tool Routing cohesion | Mitigated | Use a dedicated `## Built-in Tool Preferences` section instead of inserting under MCP Tool Routing |
| Docker-mode sessions lack `rg` (Dockerfile doesn't install it) | Accepted | Agents auto-fallback to `grep`. Follow-up (out of scope): optionally add `ripgrep` to Dockerfile `apt-get` list. |

## Success Metrics

- `setup.sh` runs successfully (exit 0) with and without `rg` installed
- `setup.ps1` runs successfully (returns `$true`) with and without `rg` installed
- README renders correctly with the new Prerequisite entry
- `deploy/.AGENTS.md` deploys cleanly via `setup.sh` (new `## Built-in Tool Preferences` section present)
