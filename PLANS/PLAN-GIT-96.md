# Plan: Replace GitHub PAT setup with GitHub CLI instructions

## Issue Reference
- **Number**: #96
- **URL**: https://github.com/darellchua2/opencode-config-template/issues/96
- **Labels**: enhancement

## Overview
Replace GitHub PAT prompting in setup scripts with GitHub CLI (`gh`) detection and setup instructions.

## Acceptance Criteria
- [x] `setup.sh` — `setup_github_pat` replaced with `setup_github_cli` function
- [x] `setup.ps1` — `Set-GitHubPAT` replaced with `Set-GitHubCLI` function
- [x] `README.md` — GITHUB_PAT references replaced with gh CLI instructions
- [x] All GITHUB_PAT env var persistence removed from both scripts

## Scope
- `setup.sh` (modify — replace PAT function, remove persistence)
- `setup.ps1` (modify — replace PAT function, remove persistence)
- `README.md` (modify — update prerequisites)

---

## Implementation Phases

### Phase 1: Update setup.sh
- [x] Replace `setup_github_pat` with `setup_github_cli`
- [x] Remove GITHUB_PAT env var initialization
- [x] Remove GITHUB_PAT from `setup_shell_vars` persistence
- [x] Replace GITHUB_PAT summary with gh CLI status check
- [x] Update help text

### Phase 2: Update setup.ps1
- [x] Replace `Set-GitHubPAT` with `Set-GitHubCLI`
- [x] Remove `$GitHubPAT` variable initialization
- [x] Remove GITHUB_PAT from `Set-ShellVariables` profile writes
- [x] Replace GITHUB_PAT summary with gh CLI status check
- [x] Update help text

### Phase 3: Update README.md
- [x] Add GitHub CLI to prerequisites
- [x] Add gh CLI install instructions section

---

## Success Metrics
- No GITHUB_PAT references remain in setup scripts
- gh CLI detection works across macOS, Linux, Windows
- Users are guided to install/authenticate gh CLI when missing
