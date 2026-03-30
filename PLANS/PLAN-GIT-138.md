# Plan: Create Open3D Specialist Subagent

## Issue Reference
- **Number**: #138
- **URL**: https://github.com/darellchua2/opencode-config-template/issues/138
- **Labels**: enhancement, subagent
- **Branch**: `feature/open3d-specialist-subagent`

## Overview
Create a specialized subagent for Open3D (3D data processing library) that advises users and proposes optimal code structures for 3D data processing tasks. The subagent must reference Open3D official documentation as its primary knowledge source and must determine the user's Open3D version before providing guidance.

## Repository Context

This is `opencode-config-template` — a configurator repository that deploys user-level OpenCode configuration to `~/.config/opencode/`. Global subagents in `agents/*.md` are deployed via glob during `setup.sh` / `setup.ps1` execution. No manual per-agent listing is needed in the setup scripts; counts are auto-calculated. The README.md subagents table and agent count **must** be updated manually.

## Acceptance Criteria Mapping

| # | Acceptance Criteria | Phase | Verified |
|---|--------------------|-------|----------|
| 1 | Subagent definition file created in `agents/` directory | Phase 2 | [ ] |
| 2 | Open3D documentation URL referenced as primary knowledge source | Phase 2 | [ ] |
| 3 | Version detection/prompting logic included in subagent instructions | Phase 2 | [ ] |
| 4 | Guidance covers point cloud, mesh, visualization, reconstruction, and ML topics | Phase 2 | [ ] |
| 5 | `setup.sh` and `setup.ps1` updated to deploy the new subagent | Phase 3 | [ ] |
| 6 | `README.md` subagents table updated with new entry | Phase 3 | [ ] |
| 7 | Documentation synchronization completed across all config files | Phase 4 | [ ] |

## Scope

| File | Change Type | Details |
|------|-------------|---------|
| `agents/open3d-specialist.md` | **New file** | Global subagent definition |
| `README.md` | Modified | Add row to Subagents table (line ~182), increment agent count (line 148: 24 → 25) |
| `AGENTS.md` | Modified | Add routing entry for Open3D specialist if appropriate |

> **Note on setup.sh / setup.ps1**: These scripts deploy agents via glob from `agents/*.md` and auto-calculate counts. No per-agent listing changes are required unless the help text or category groupings are affected. Verify by checking if a help-text listing of agents exists in either script.

---

## Implementation Phases

### Phase 1: Analysis & Design
- [ ] Review existing specialist subagent patterns (`agents/civil-3d-specialist.md`, `agents/autodesk-specialist-subagent.md`)
- [ ] Study the MANDATORY version detection pattern from `civil-3d-specialist.md`
- [ ] Review Open3D documentation structure at https://www.open3d.org/docs/release/
- [ ] Identify Open3D API modules and version history (current: 0.19.0)
- [ ] Define trigger phrases for Open3D-related tasks
- [ ] Design subagent expertise areas aligned with Open3D documentation sections

### Phase 2: Create Subagent Definition
- [ ] Create `agents/open3d-specialist.md` with proper YAML frontmatter:
  - `mode: subagent`
  - ``
  - Permissions: read, write, edit, glob, grep, bash, webfetch
- [ ] Define subagent purpose and capabilities
- [ ] Implement MANDATORY version detection/prompting logic (following civil-3d-specialist pattern)
- [ ] Add documentation search strategy using WebFetch:
  - Base URL: `https://www.open3d.org/docs/release/`
  - Python API reference: `https://www.open3d.org/docs/release/python_api/`
- [ ] Include expertise sections:
  1. **Point Cloud Processing** — I/O, outlier removal, voxelization, downsampling, normal estimation, FPFH features
  2. **Mesh Operations** — Triangle mesh creation, processing, simplification, subdivision, deformation
  3. **3D Visualization** — `draw_geometries`, `O3DVisualizer`, GUI widgets, headless rendering, WebRTC
  4. **Reconstruction** — RGBD integration, TSDF volume, ICP registration, pose graph optimization
  5. **Open3D-ML (Deep Learning)** — Semantic segmentation, object detection, TF/PyTorch pipelines, datasets (KITTI, NuScenes, ScanNet, etc.)
  6. **Camera & Sensors** — Pinhole camera, Azure Kinect, RealSense integration, RGBD images

### Phase 3: Update Deployment Configuration
- [ ] Verify `setup.sh` agent deployment glob covers new file (agents/*.md — should be automatic)
- [ ] Verify `setup.ps1` agent deployment glob covers new file (agents/*.md — should be automatic)
- [ ] Update `README.md`:
  - Increment agent count: `24 agents` → `25 agents` (line 148)
  - Add row to Subagents table (after line 182):
    ```
    | **open3d-specialist** | Open3D 3D data processing guidance | (documentation search + version-specific guidance) |
    ```
- [ ] Review if `AGENTS.md` needs a routing entry for Open3D tasks

### Phase 4: Verification & Sync
- [ ] Verify subagent file follows existing patterns (frontmatter, structure, permissions)
- [ ] Verify version prompting logic matches civil-3d-specialist MANDATORY pattern
- [ ] Verify README.md count is correct (25 agents: 2 primary + 23 subagents)
- [ ] Verify all documentation URLs are valid
- [ ] Verify setup.sh and setup.ps1 syntax (no breaking changes)
- [ ] Run `shellcheck setup.sh` if available
- [ ] Cross-reference AGENTS.md checklist for completeness

### Phase 5: Commit & Push
- [ ] Stage all changes
- [ ] Create semantic commit: `feat: add open3d-specialist subagent for 3D data processing guidance`
- [ ] Push to branch `feature/open3d-specialist-subagent`
- [ ] Update GitHub issue #138 with progress

---

## Technical Notes

### Version Prompting Pattern (Critical)

Following the `civil-3d-specialist.md` MANDATORY pattern:

```
CRITICAL: Version Detection (MANDATORY)

If the user has NOT specified their Open3D version:

STOP and ask:
"What version of Open3D are you using? (e.g., 0.19.0, 0.18.0, 0.17.0)

This is required because API availability, function signatures, and module 
organization differ between versions. Providing incorrect version guidance 
could lead to runtime errors or broken pipelines."

DO NOT proceed with any guidance until the user provides their version.
```

### Open3D Version History

| Version | Release | Key Changes |
|---------|---------|-------------|
| 0.19.0 | 2024-12 | Latest — SYCL GPU support, TensorBoard plugin, VoxelBlockGrid |
| 0.18.0 | 2023-11 | Dense SLAM, SLAC optimizer, RGBD video reader |
| 0.17.0 | 2022-08 | Major tensor API overhaul, new rendering pipeline |
| 0.16.0 | 2022-02 | GUI improvements, WebRTC visualizer |
| 0.15.0 | 2021-04 | Open3D-ML TF2 support, new datasets |
| 0.14.0 | 2021-01 | Headless rendering, offscreen renderer |
| 0.13.0 | 2020-06 | New ICP variants, colored ICP |

### Version-Sensitive Areas
- **Tensor API** (`open3d.t` and `open3d.core`) — Major changes in 0.17.0+
- **Open3D-ML** (`open3d.ml.torch`, `open3d.ml.tf`) — Dataset/model availability varies
- **Rendering** (`open3d.visualization.rendering`) — New pipeline in 0.16.0+
- **Reconstruction System (Tensor)** — New in 0.18.0+
- **SLAM** — New in 0.18.0+

### Open3D Documentation Structure

```
https://www.open3d.org/docs/release/
├── Getting Started
├── Tutorial
│   ├── Core (Tensor, Hash map)
│   ├── Geometry (Point cloud, Mesh, RGBD, KDTree, File IO)
│   ├── Geometry (Tensor) (PointCloud)
│   ├── Visualization
│   ├── Pipelines (ICP, Registration, RGBD)
│   ├── Pipelines (Tensor) (ICP, Robust Kernel)
│   ├── Reconstruction system
│   ├── Reconstruction system (Tensor)
│   └── Sensor (Azure Kinect, RealSense)
├── Reference
│   ├── Python API (open3d.*, open3d.t.*, open3d.ml.*)
│   └── C++ API
└── Python Examples / C++ Examples
```

### Subagent Frontmatter Template

```yaml
---
description: Specialized subagent for Open3D - provides version-specific guidance for 3D data processing including point clouds, meshes, visualization, reconstruction, deep learning (Open3D-ML), camera integration, and sensor workflows. MANDATORY version detection before providing any guidance.
mode: subagent

permission:
  read: allow
  write: allow
  edit: allow
  glob: allow
  grep: allow
  bash: allow
  webfetch: allow
---
```

### Trigger Phrases

```
- "open3d" or "open 3d"
- "point cloud" + ("processing" or "filtering" or "segmentation")
- "3d visualization" or "3d vis" + open3d
- "mesh" + ("processing" or "simplification" or "reconstruction")
- "icp" + ("registration" or "alignment")
- "tsdf" or "reconstruction system"
- "rgbd" + ("integration" or "odometry")
- "open3d-ml" or "open3d ml" or "3d deep learning"
- "kinect" + "open3d"
- "realsense" + "open3d"
- "voxel" + "open3d"
```

### File Update Locations (per AGENTS.md Checklist)

| File | Lines | Update Type | Required? |
|------|-------|-------------|-----------|
| `setup.sh` | ~1828 (agent glob) | Auto (glob from agents/*.md) | Verify only |
| `setup.ps1` | (agent glob) | Auto (glob from agents/*.md) | Verify only |
| `README.md` | ~148 | Increment agent count (24 → 25) | Yes |
| `README.md` | ~182-183 | Add subagent row | Yes |
| `AGENTS.md` | Varies | Add routing if needed | Review |

## Dependencies
- Existing specialist subagent patterns (`civil-3d-specialist.md`, `autodesk-specialist-subagent.md`)
- AGENTS.md documentation sync checklist
- WebFetch tool for Open3D documentation search
- Open3D official documentation: https://www.open3d.org/docs/release/

## Risks & Mitigation

| Risk | Mitigation |
|------|------------|
| Incorrect version guidance | MANDATORY version prompting before any guidance (follows civil-3d-specialist pattern) |
| Open3D API changes between versions | Include version-sensitive area table; fetch docs via WebFetch when unsure |
| setup.sh/ps1 auto-count mismatch | Verify glob pattern catches new file; manual count not needed in scripts |
| Missing sync updates | Follow AGENTS.md checklist strictly |
| Open3D-ML API instability | Clearly separate core Open3D vs Open3D-ML guidance; version gate ML content |

## Success Metrics
- Subagent correctly prompts for Open3D version when not specified
- Subagent covers all 6 expertise areas (point cloud, mesh, visualization, reconstruction, ML, sensors)
- All sync files updated correctly with accurate counts (25 total agents)
- Open3D documentation URLs are valid and referenced
- Subagent follows established specialist subagent conventions
