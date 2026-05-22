# PLAN-GIT-194: Restructure user-space files into deploy/ folder + CodeGraph injection

**Issue**: [#194](https://github.com/darellchua2/opencode-config-template/issues/194)
**Branch**: `issue-194`
**Status**: Ready to begin execution

---

## Problem

User-space deployment files (config.json, .AGENTS.md, setup.sh, setup.ps1) are scattered at the repo root alongside repo-level files (AGENTS.md, docker-compose.yml). This makes it unclear which files belong to which deployment mode (user-space vs Docker).

Additionally, built-in OpenCode subagents (explore, general) don't receive CodeGraph guidance when spawned by the primary agent — only custom subagents have CodeGraph instructions in their .md files (added in #192).

## Solution

1. Move user-space files into a `deploy/` folder for clear separation from Docker files
2. Add built-in subagent CodeGraph injection instructions to both AGENTS.md files
3. Update all path references across the repository

## Target Structure

```
opencode-config-template/
├── deploy/                  # User-space deployment (NEW)
│   ├── setup.sh             # Moved from root
│   ├── setup.ps1            # Moved from root
│   ├── config.json          # Moved from root
│   └── .AGENTS.md           # Moved from root (with CodeGraph injection added)
├── opencode_app/            # Docker standalone (unchanged structure)
│   ├── AGENTS.md            # CodeGraph injection added
│   ├── Dockerfile
│   ├── docker-entrypoint.sh
│   ├── opencode.json
│   ├── README.md
│   ├── .dockerignore
│   └── .opencode/
│       ├── agents/
│       └── skills/
├── AGENTS.md                # Repo-level instructions (updated paths)
├── README.md                # Updated paths and commands
├── CHANGELOG.md             # Updated
├── docker-compose.yml       # Unchanged
├── .env.example             # Unchanged
├── PLANS/
├── LEARNINGS/
└── .opencode/
    └── agents/
```

---

## Phase 1: Create deploy/ folder and move files

### 1.1 Create directory and move files

- [ ] Create `deploy/` directory
- [ ] Move `setup.sh` → `deploy/setup.sh`
- [ ] Move `setup.ps1` → `deploy/setup.ps1`
- [ ] Move `config.json` → `deploy/config.json`
- [ ] Move `.AGENTS.md` → `deploy/.AGENTS.md`
- [ ] Verify no old root-level config.json, .AGENTS.md, setup.sh, setup.ps1 remain

### 1.2 Update setup.sh path references

SCRIPT_DIR will resolve to `deploy/` after the move. All paths referencing the repo root need to go up one level (`${SCRIPT_DIR}/..`):

| Line | Current Path | New Path |
|------|-------------|----------|
| 66 | `${SCRIPT_DIR}/VERSION` | `${SCRIPT_DIR}/../VERSION` |
| 79 | `${SCRIPT_DIR}/opencode_app/.opencode/agents` | `${SCRIPT_DIR}/../opencode_app/.opencode/agents` |
| 1619 | `${SCRIPT_DIR}/.AGENTS.md` | `${SCRIPT_DIR}/.AGENTS.md` (same — moves with script) |
| 1659 | `${SCRIPT_DIR}/config.json` | `${SCRIPT_DIR}/config.json` (same — moves with script) |
| 1692 | `${SCRIPT_DIR}/opencode_app/.opencode/skills` | `${SCRIPT_DIR}/../opencode_app/.opencode/skills` |
| 2605 | `${SCRIPT_DIR}/config.json` | `${SCRIPT_DIR}/config.json` (same) |
| 2609 | `${SCRIPT_DIR}/scripts/generate-skills.py` | `${SCRIPT_DIR}/../scripts/generate-skills.py` (if exists) |

- [ ] Add `REPO_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"` near SCRIPT_DIR definition
- [ ] Update VERSION_FILE to use REPO_DIR
- [ ] Update all `opencode_app/.opencode/` paths to use REPO_DIR
- [ ] Keep `.AGENTS.md` and `config.json` paths on SCRIPT_DIR (they move with the script)
- [ ] Search for any other `${SCRIPT_DIR}/` references that point outside deploy/

### 1.3 Update setup.ps1 path references

Same logic — ScriptDir resolves to `deploy/`:

| Line | Current Path | New Path |
|------|-------------|----------|
| 51 | `$ScriptDir/VERSION` | `$RepoDir/VERSION` |
| 61 | `$ScriptDir/opencode_app/.opencode/agents` | `$RepoDir/opencode_app/.opencode/agents` |
| 1143 | `$ScriptDir/.AGENTS.md` | `$ScriptDir/.AGENTS.md` (same) |
| 1185 | `$ScriptDir/config.json` | `$ScriptDir/config.json` (same) |
| 1214 | `$ScriptDir/opencode_app/.opencode/skills` | `$RepoDir/opencode_app/.opencode/skills` |

- [ ] Add `$RepoDir = Join-Path $ScriptDir ".."` near ScriptDir definition (resolve to absolute)
- [ ] Update VERSION_FILE to use $RepoDir
- [ ] Update all `opencode_app/.opencode/` paths to use $RepoDir
- [ ] Keep `.AGENTS.md` and `config.json` paths on $ScriptDir
- [ ] Search for any other `$ScriptDir` references that point outside deploy/

---

## Phase 2: Add CodeGraph injection to AGENTS.md files

### 2.1 Add built-in subagent CodeGraph injection to deploy/.AGENTS.md

Add a new section after the existing `### Subagent Integration` table. This instructs the primary agent to inject CodeGraph guidance when spawning built-in explore or general subagents:

```markdown
### Built-In Subagent CodeGraph Injection

When spawning built-in `explore` or `general` subagents via the Task tool,
if a `.codegraph/` directory exists in the project, include this guidance
in the Task prompt:

"CodeGraph is available in this project. Prioritize these tools:
- `codegraph_explore` for multi-symbol exploration
- `codegraph_search` for symbol lookups
- `codegraph_files` for file structure
- `codegraph_context` for task-relevant code context
- `codegraph_callers`/`codegraph_callees` for dependency tracing
- `codegraph_impact` for change radius analysis
Fall back to grep/glob/read only if CodeGraph tools return no results."
```

- [ ] Add section to deploy/.AGENTS.md after Subagent Integration table
- [ ] Verify no duplicate CodeGraph instructions

### 2.2 Add matching section to opencode_app/AGENTS.md

Add the same CodeGraph injection section for Docker parity (container may have host-mounted repos with .codegraph/):

- [ ] Add section to opencode_app/AGENTS.md after Subagent Integration table
- [ ] Keep the Docker-specific MCP Tool Routing table unchanged

---

## Phase 3: Update documentation references

### 3.1 Update README.md (root)

- [ ] Update file structure diagram: move config.json, .AGENTS.md, setup.sh, setup.ps1 under `deploy/`
- [ ] Update all setup commands: `./setup.sh` → `./deploy/setup.sh`
- [ ] Update all PowerShell commands: `.\setup.ps1` → `.\deploy\setup.ps1`
- [ ] Update file location references in tables
- [ ] Update any path references to config.json, .AGENTS.md

### 3.2 Update AGENTS.md (root)

- [ ] Update file structure diagram: move entries under `deploy/`
- [ ] Update `setup.sh` references to `deploy/setup.sh`
- [ ] Update `setup.ps1` references to `deploy/setup.ps1`
- [ ] Update `.AGENTS.md` path references to `deploy/.AGENTS.md`
- [ ] Update `config.json` path references to `deploy/config.json`
- [ ] Update sync trigger references

### 3.3 Update opencode_app/README.md

- [ ] Update any references to setup.sh paths

### 3.4 Update opencode-tooling-subagent.md

The repo detection logic at line 31 currently checks for `setup.sh` at repo root. After move:

- [ ] Update detection: `setup.sh` + `skills/` + `agents/` → look for `deploy/setup.sh` + `opencode_app/.opencode/`
- [ ] Update all references to `setup.sh`/`setup.ps1` paths in the file
- [ ] Update file structure example in the subagent
- [ ] Update the reference to `.AGENTS.md` → `deploy/.AGENTS.md`

### 3.5 Update CHANGELOG.md

- [ ] Add entry for deploy/ restructure

---

## Phase 4: Validation

- [ ] Run `./deploy/setup.sh --dry-run` — verify paths resolve correctly
- [ ] Run `./deploy/setup.ps1 -DryRun` — verify paths resolve correctly (if on Windows)
- [ ] Grep entire repo for old root-level paths (`/setup.sh`, `setup.ps1`) that should now be `/deploy/setup.sh`
- [ ] Verify `deploy/.AGENTS.md` has CodeGraph injection section
- [ ] Verify `opencode_app/AGENTS.md` has CodeGraph injection section
- [ ] Verify no stale `config.json`, `.AGENTS.md`, `setup.sh`, `setup.ps1` at root
- [ ] Verify `opencode-tooling-subagent.md` detection logic uses new paths
- [ ] Verify README.md all commands use `deploy/` prefix
- [ ] Verify AGENTS.md file structure diagram matches actual structure

---

## Commit Strategy

One commit per phase using conventional commits:
1. `refactor: move user-space deployment files into deploy/ folder` (Phase 1)
2. `docs(codegraph): add built-in subagent CodeGraph injection to AGENTS.md files` (Phase 2)
3. `docs: update all path references for deploy/ restructure` (Phase 3)
4. `chore: validate deploy/ restructure and path updates` (Phase 4)
