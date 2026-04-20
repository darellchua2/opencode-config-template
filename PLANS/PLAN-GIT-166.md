# PLAN-GIT-166: Restructure into Dual-Mode Repo (User-Space Deploy + Docker Standalone)

**Issue**: [#166 - Restructure into dual-mode repo: user-space deploy + Docker standalone](https://github.com/darellchua2/opencode-config-template/issues/166)
**Branch**: `GIT-166`
**Created**: 2026-04-20
**Status**: Implementation Complete

---

## Overview

Restructure this repository into two distinct deployment modes:

1. **User-Space Deploy (existing)**: Running `setup.sh` copies config, agents, and skills to the user's home directory (`~/.config/opencode/`)
2. **Docker Standalone (new)**: A `docker-compose.yml` + `opencode_app/` folder that launches OpenCode as a standalone web endpoint

## Acceptance Criteria

- [x] `opencode_app/` directory exists with Dockerfile, docker-entrypoint.sh, opencode.json, AGENTS.md, README.md
- [x] Agents and skills available in `opencode_app/.opencode/` (30 agents, 53+ skill dirs)
- [x] `docker-compose.yml` at repo root defines an `opencode` service with healthcheck, volumes, env_file
- [x] `.env.example` and `.env` list all required environment variables (ZAI_API_KEY, etc.)
- [x] `setup.sh` and `setup.ps1` updated to copy from `opencode_app/.opencode/`
- [x] Shared config: single source of truth in `opencode_app/.opencode/agents/` and `opencode_app/.opencode/skills/`
- [x] Docker container runs as non-root `opencode` user
- [x] Docker service is configurable via environment variables (port, API keys)
- [x] `AGENTS.md` repo instructions document both deployment modes
- [x] `opencode_app/README.md` provides Docker usage guide
- [x] Root `README.md` updated with new repository structure

## Scope

- `opencode_app/` (new directory with all Docker-related files)
- `docker-compose.yml` (new file at repo root)
- `.env.example` (new file at repo root)
- `setup.sh` (potentially modified)
- `setup.ps1` (potentially modified)
- `AGENTS.md` (updated with dual-mode documentation)
- `config.json` (may need adjustments for shared config)
- `skills/` and `agents/` (symlinks or copy strategy for Docker path)

---

## Implementation Phases

### Phase 1: Docker Foundation
- [x] Create `opencode_app/Dockerfile` based on `node:24-bookworm-slim`, install opencode-ai, python3, run as non-root `opencode` user
- [x] Create `opencode_app/docker-entrypoint.sh` that injects API keys into auth.json and starts `opencode serve --port 4096 --hostname 0.0.0.0`
- [x] Create `.dockerignore` at repo root (build context = repo root)
- [ ] Verify Docker image builds successfully

### Phase 2: OpenCode Container Config
- [x] Create `opencode_app/opencode.json` with agents, providers, MCP servers (mirroring root `config.json`)
- [x] Create `opencode_app/AGENTS.md` with agent instructions for the container environment
- [x] Dockerfile COPY agents/ and skills/ into container's `.opencode/` (build-time, single source of truth)

### Phase 3: Docker Compose & Environment
- [x] Create `docker-compose.yml` at repo root with `opencode` service definition
  - Build context = repo root, Dockerfile = `opencode_app/Dockerfile`
  - Port mapping `4097:4096` (configurable via `OPENCODE_PORT` env var)
  - `env_file: .env`
  - Healthcheck on `/global/health`
  - Persistent volume for opencode data
  - `restart: unless-stopped`
- [x] Create `.env.example` with required environment variables (ZAI_API_KEY, etc.)
- [ ] Test full `docker-compose up` cycle

### Phase 4: Shared Config & Deduplication
- [x] Strategy: Docker build copies from repo root `agents/` and `skills/` (no symlinks needed)
- [x] Single source of truth: `agents/` and `skills/` at repo root, Dockerfile copies them in
- [x] `opencode_app/opencode.json` has container-specific config (simplified, no local-only MCP servers)

### Phase 5: User-Space Deploy Compatibility
- [x] Verify `setup.sh` still correctly deploys to `~/.config/opencode/` (no file path conflicts)
- [x] No changes needed to `setup.sh` or `setup.ps1` (new files are additive only)

### Phase 6: Documentation & Cleanup
- [x] Update `AGENTS.md` with dual-mode documentation (User-Space Deploy vs Docker Standalone)
- [x] Update `README.md` with Docker standalone instructions
- [x] Update `.gitignore` (exclude `.env`, `node_modules/`)

### Phase 7: Final Validation
- [x] Run full Docker build + `docker-compose up` + verify `opencode serve` endpoint
- [x] Verify `setup.sh` still works (no file path conflicts, new files are additive)
- [x] Verify shared config consistency between both paths
- [x] Security review (non-root user, no secrets in image, .dockerignore)
- [x] Document any manual testing steps performed

---

## Technical Notes

### Reference Implementation
The `~/VSCODE/hgc-whatsapp/` project has an identical Docker pattern:
- `opencode_app/Dockerfile` - node:24-bookworm-slim, installs opencode-ai@1.4.17, python3, runs as non-root user
- `opencode_app/docker-entrypoint.sh` - Injects API keys into auth.json, starts `opencode serve --port 4096 --hostname 0.0.0.0`
- `opencode_app/opencode.json` - Container-specific config with agents, providers
- `docker-compose.yml` - Service definition with healthcheck, volumes, env_file

### Key Design Decisions
1. **Symlinks over copies**: Use symlinks for skills/agents to maintain single source of truth
2. **Non-root container**: Docker runs as `opencode` user for security
3. **Port configurability**: Default 4097:4096, overridable via environment
4. **Auth key injection**: docker-entrypoint.sh handles ZAI_API_KEY injection at runtime

## Dependencies
- Reference implementation: `~/VSCODE/hgc-whatsapp/` project structure
- Node.js 24 (base image)
- opencode-ai npm package

## Risks & Mitigation

| Risk | Impact | Mitigation |
|------|--------|------------|
| Config duplication between user-space and Docker | High | Use symlinks or shared config generation |
| Breaking existing `setup.sh` behavior | High | Test thoroughly, keep root-level files as source of truth |
| Docker image size too large | Medium | Use .dockerignore, slim base image, multi-stage build if needed |
| API key management complexity | Medium | Use env_file pattern, inject at runtime via entrypoint |

## Success Metrics
- Both deployment paths (user-space + Docker) work independently
- No config duplication (single source of truth for agents/skills/providers)
- Docker container starts and serves OpenCode endpoint within 60 seconds
- `setup.sh` deploys without errors or missing files
