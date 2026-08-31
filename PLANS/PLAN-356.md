# PLAN-356 — Voice plugin pack (opencode-voice) + opt-in plugin installation

**Issue:** https://github.com/darellchua2/opencode-config-template/issues/356
**Branch:** feat/356-voice-plugin-pack (from main @ 6bf6a29)

## Overview

Add [`@renjfk/opencode-voice`](https://github.com/renjfk/opencode-voice) (local speech-to-text via whisper.cpp + sox, optional Piper TTS) to the configurator as the first **plugin pack**, establishing the opt-in plugin-installation pattern: end users decide which plugins to install, default OFF, same as MCP provider packs.

Unlike existing MCP packs (which flip `mcp.<server>.enabled` in `opencode.json`), voice is a **tui.json plugin**: the pack carries a `tui` key that is merged into a separate `~/.config/opencode/tui.json` with plugin-array merge-by-name semantics.

## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---------------------|---------------------------|---------------------------------|-------------|
| `deploy/packs/pack-voice.json` | — | merge-packs.mjs (`tui` key), setup.sh `install_voice` gate, validate_enable_pack (dir-driven) | low |
| `deploy/merge-packs.mjs` (`--tui-config`) | pack-voice.json | setup.sh `run_pack_merger`, setup.ps1 `Invoke-PackMerger`, opencode_app/Dockerfile (build arg) | med — new arg; Docker must not break (warn + skip) |
| `deploy/setup.sh` (`install_voice`, help text, `run_pack_merger`) | merge-packs.mjs tui support | end-user deploys | low — gated on `--enable-pack voice` |
| `deploy/setup.ps1` (help text, merger pass-through) | merge-packs.mjs tui support | Windows deploys | low — prereq installer skipped (plugin README documents macOS/Linux only) |
| `README.md` (pack docs §) | all of the above | humans | low |
| `tests/test_voice_pack.bats` | merge-packs.mjs + pack-voice.json | CI bats suite | low |

## Implementation Phases

### Phase 1: Pack + merger tui support

- [x] **1.1** `deploy/packs/pack-voice.json`: new pack with `tui` key — `keybinds.session_rename: "none"` (clobber factory default so `ctrl+r` works) + `plugin: [["@renjfk/opencode-voice", {endpoint, model}]]` defaulting normalization to local Ollama (`http://localhost:11434/v1`, `llama3.2`)
    — **Why:** the plugin only needs `endpoint` + `model` (any OpenAI-compatible endpoint); local-first default fits this repo's ethos; user edits the deployed tui.json to swap providers
    — **Done when:** `node deploy/merge-packs.mjs --config X --tui-config Y --packs voice` merges both keys
    — **Consumers affected:** merge-packs.mjs, setup.sh
- [x] **1.2** `deploy/merge-packs.mjs`: new `--tui-config <path>` arg; strip `tui` from the opencode.json deep-merge (never leak plugin config into the MCP config); merge `tui` partials into the tui target where the `plugin` array merges **by plugin name** (entry[0]) — idempotent re-runs replace in place, user's other plugins preserved; missing `--tui-config` with a tui-carrying pack ⇒ warning + skip (Docker build path: no tui.json, no microphone — never fatal); missing tui target file ⇒ initialize with `$schema`
    — **Why:** wholesale array replace would clobber existing plugins or duplicate on re-run; Docker calls merge-packs at build time and must not fail
    — **Done when:** smoke test shows idempotent double-merge, `other-plugin` preserved, opencode.json untouched; no `--tui-config` prints warning, exit 0
    — **Consumers affected:** setup.sh, setup.ps1, Dockerfile (unchanged invocation keeps working)

### Phase 2: setup.sh wiring

- [x] **2.1** `run_pack_merger`: pass `--tui-config` — real run: `${CONFIG_DIR}/tui.json`; dry-run: `${DRY_RUN_PREVIEW_DIR}/tui.json` (stages preview per the B1 contract, mirroring run_resolver)
    — **Done when:** `./setup.sh --dry-run -y --enable-pack voice` stages `tui.json` into the preview dir
    — **Consumers affected:** deploy_agents flow
- [x] **2.2** `install_voice()` after `install_docling` (gated on `--enable-pack voice`, mirrors PLAN-GIT-308 docling precedent): macOS `brew install whisper-cpp sox` when missing; Linux check sox (warn with exact apt command), check `whisper-cli` (offer source build via `prompt_yes_no`, default n — needs cmake + sudo symlink; `-y` mode prints instructions instead); **GPU auto-detect: `nvidia-smi` + `nvcc` ⇒ CUDA build with arch from `--query-gpu=compute_cap` (no lookup table); `rocminfo`/`hipcc` ⇒ ROCm/HIP build with `GPU_TARGETS` from the detected gfx target; `vulkaninfo` + `glslc` ⇒ Vulkan build (AMD/Intel); GPU without a toolkit ⇒ CPU + warning + optional ROCm install assist (`install_rocm_linux`: pulls latest amdgpu-install .deb from AMD's repo index — no pinned version, installs `rocm-hip-libraries rocminfo`, adds user to video/render groups, opt-in default n, never fatal); none ⇒ CPU**; whisper.cpp NPU/iGPU paths — **AMD Ryzen AI 300/400 (HX 370 etc.): VitisAI NPU offload** auto-selected when `xrt-smi` + NPU are present (`-DWHISPER_VITISAI=1`, XRT + FlexML runtimes required, `.rai` encoder cache fetched after model download, Ubuntu 24.04); **Intel Core Ultra (285H): OpenVINO encoder** auto-selected when `/dev/accel/accel0` or Intel iGPU + `/opt/intel/openvino*` are present (`-DWHISPER_OPENVINO=ON`, encoder runs on the Arc iGPU — the NPU device fails on Linux, ggml-org/whisper.cpp#2929; encoder IR conversion automated via `convert-whisper-to-openvino.py`); Vulkan remains the light cross-vendor fallback; **no-build server alternatives** printed as `sttEndpoint` hints: Lemonade Server (AMD NPU) and OpenVINO Model Server (both serve OpenAI-compatible `/audio/transcriptions`); whisper model recommendation derived from the same profile (large-v3-turbo on Metal/modern CUDA arch ≥ 80/ROCm/Vulkan, medium on older CUDA, small on CPU-only) with a `Suggested combination:` line and `/stt-model` switch hint; Piper TTS printed as instructions only (STT works without it)
    — **Why:** heavy host prereqs stay opt-in and interactive; auto-builds with sudo in `-y` CI runs are unsafe; the backend × model-size mix decides whether transcription is real-time or 15-30 s/clip
    — **Done when:** `./setup.sh -y --enable-pack voice` completes without prompts, printing exact commands for anything missing; profile mapping verified (arch 89 → large-v3-turbo, 75 → medium, CPU → small)
    — **Consumers affected:** setup_config flow
- [x] **2.3** Interactive enable prompt: when voice pack not requested and session is interactive, `prompt_yes_no "Enable voice plugin (local speech-to-text via whisper.cpp)?" "n"` in `install_voice`'s gate — yes appends `voice` to `ENABLE_PACK` (before `run_pack_merger` executes in deploy_agents); `-y` mode auto-answers n and prints the `--enable-pack voice` one-liner
    — **Why:** "end user decides which plugin to install" needs a first-class prompt, not just a flag
    — **Done when:** answering y prompts prereq install AND merges tui config (ENABLE_PACK mutated before run_pack_merger)
    — **Consumers affected:** main() flow order (validate_enable_pack runs early; "voice" is a known name so late append is safe)
- [x] **2.4** Help text + echo updates (3 spots): pack list line ~578-581 (note: voice is a *plugin* pack — tui.json + host prereqs), `--enable-pack` arg error ~884, post-config echo ~2491
    — **Done when:** `./setup.sh --help` lists voice; bad pack name error lists voice
    — **Consumers affected:** docs-consistency checks

### Phase 3: Windows mirror + docs

- [x] **3.1** `deploy/setup.ps1`: help text lists `voice` (macOS/Linux note — plugin README documents no Windows build), `Invoke-PackMerger` passes `-TuiConfig` (real: `$ConfigDir/tui.json`; dry-run: preview dir), prereq installer intentionally omitted with a warn-if-requested
    — **Done when:** `.\setup.ps1 -EnablePack voice` merges tui config; missing prereqs only warn
    — **Consumers affected:** Windows deploys
- [x] **3.2** `README.md` pack docs (§ ~360-384): add voice to the pack list + short "plugin packs" subsection (what it installs, prereqs, changing the normalization endpoint, `ctrl+r` / `leader+r` usage)
    — **Done when:** README pack section matches `ls deploy/packs/`
    — **Consumers affected:** humans

### Phase 4: Verification

- [x] **4.1** `tests/test_voice_pack.bats`: pack-voice.json is valid JSON with `tui.plugin[0][0] == "@renjfk/opencode-voice"`; merge-packs double-run idempotency; other plugins preserved; no `--tui-config` ⇒ exit 0 + warning; unknown-pack still exits 1
    — **Done when:** `bats tests/test_voice_pack.bats` passes
    — **Consumers affected:** CI
- [x] **4.2** Full gates: `bats tests/`, `node deploy/build-registry.mjs` (no frontmatter changed — expect no registry diff), `npm run check` if configured
    — **Done when:** all green; existing suite unbroken
    — **Consumers affected:** release

## Out of scope

- Individual-install path (`npx ... add <name>`): plugins are config entries, not copyable files — registry/installer model doesn't fit; revisit if a second plugin pack appears.
- Docker STT: no microphone in containers; pack warns and skips tui merge.
- Normalization endpoint auto-wiring to `--enable-local-llm`/vLLM: user edits tui.json (YAGNI until asked).
