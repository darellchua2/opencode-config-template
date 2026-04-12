# Plan: Add Docker Compose setup for hosting OpenCode Web as a local container

## Issue Reference
- **Number**: #156
- **URL**: https://github.com/darellchua2/opencode-config-template/issues/156
- **Labels**: enhancement, architecture

## Overview
Create a `docker-compose.yml` in this repository that enables running OpenCode Web as a Docker container hosted locally on a remote computer. The goal is to allow cloning this repo on any remote machine, running `docker compose up`, and having a fully configured OpenCode Web instance accessible from a browser with all agents, skills, and configuration pre-loaded.

## Acceptance Criteria
- [ ] `docker-compose.yml` created at repository root with a service for OpenCode Web
- [ ] `agents/` directory contents are mounted/copied into the container at `~/.config/opencode/agents/`
- [ ] `skills/` directory contents are mounted/copied into the container at `~/.config/opencode/skills/`
- [ ] `config.json` is mounted/copied to `~/.config/opencode/config.json`
- [ ] `.AGENTS.md` is mounted/copied to `~/.config/opencode/AGENTS.md`
- [ ] OpenCode Web interface is accessible from a browser on the host machine
- [ ] API keys (e.g. `ANTHROPIC_API_KEY`, `OPENAI_API_KEY`) can be passed via environment variables or a `.env` file
- [ ] Docker volumes are configured for persistent data that survives container restarts
- [ ] A `.env.example` file is provided documenting required and optional environment variables

## Scope
- Repository root: `docker-compose.yml`, `.env.example`, `Dockerfile` (if needed)
- Existing files referenced for mounting: `config.json`, `.AGENTS.md`, `agents/`, `skills/`
- Reference: `setup.sh` (for understanding what gets deployed and where)

---

## Implementation Phases

### Phase 1: Research & Setup
- [ ] Review `setup.sh` to understand current deployment targets and paths
- [ ] Identify the official OpenCode Docker image or determine base image strategy
- [ ] Document container runtime requirements (ports, volumes, environment)
- [ ] Check if `.env` is already in `.gitignore`

### Phase 2: Core Docker Configuration
- [ ] Create `docker-compose.yml` with OpenCode Web service definition
- [ ] Configure bind mounts for `agents/` → `~/.config/opencode/agents/`
- [ ] Configure bind mounts for `skills/` → `~/.config/opencode/skills/`
- [ ] Configure bind mounts for `config.json` → `~/.config/opencode/config.json`
- [ ] Configure bind mounts for `.AGENTS.md` → `~/.config/opencode/AGENTS.md`
- [ ] Configure Docker volume for persistent data (e.g., opencode-data)
- [ ] Expose the OpenCode Web port (configurable via `OPENCODE_PORT`)

### Phase 3: Environment Configuration
- [ ] Create `.env.example` with documented required and optional variables
- [ ] Ensure `.env` is in `.gitignore`
- [ ] Support API key passthrough (`ANTHROPIC_API_KEY`, `OPENAI_API_KEY`, etc.)
- [ ] Make exposed port configurable via environment variable

### Phase 4: Convenience & Polish
- [ ] Create optional `Makefile` or `justfile` with common commands (`up`, `down`, `logs`, `build`)
- [ ] Add comments to `docker-compose.yml` explaining each mount and configuration
- [ ] Update README.md with Docker setup instructions
- [ ] Test the full flow: clone → `docker compose up` → browser access

### Phase 5: Final Validation
- [ ] Verify all agents are available inside the container
- [ ] Verify all skills are available inside the container
- [ ] Verify config and AGENTS.md are correctly loaded
- [ ] Verify API keys are properly passed through
- [ ] Verify persistent data survives container restart
- [ ] Verify browser can access OpenCode Web on the host

---

## Technical Notes
- Bind mounts are preferred over COPY for development flexibility
- The `.env` file should be gitignored (never committed)
- Consider multi-stage Dockerfile if a custom image is needed
- The OpenCode Web port should be configurable (default: 3000)

## Dependencies
- Official OpenCode Docker image availability (or need for custom Dockerfile)

## Risks & Mitigation
- **Risk**: No official OpenCode Docker image exists → **Mitigation**: Create a custom Dockerfile based on a minimal Node.js image
- **Risk**: Bind mount paths differ between Linux/macOS/Windows → **Mitigation**: Use relative paths in docker-compose.yml
- **Risk**: API key exposure → **Mitigation**: `.env` in `.gitignore`, clear documentation in `.env.example`

## Success Metrics
- User can clone repo, run `docker compose up`, and access OpenCode Web in a browser
- All agents, skills, and configuration are pre-loaded inside the container
- Container restart preserves persistent data
