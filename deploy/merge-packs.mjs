#!/usr/bin/env node
// deploy/merge-packs.mjs
//
// Provider-pack merger. Deep-merges one or more pack partials
// (deploy/packs/pack-<name>.json) into a target opencode.json, flipping
// `mcp.servers.<server>.disabled` (V2 shape) and merging the root `permissions`
// rule array (V2 shape — rules merged BY (action, resource) KEY so a pack
// allow flips a source-config deny in place, preserving rule order).
//
// Companion to deploy/resolve-models.mjs. Zero external dependencies — Node
// built-ins only (fs, path). Mirrors resolve-models.mjs conventions:
//   - ES modules, async main(), camelCase arg parsing
//   - readJsonMaybe / stripJsonComments helpers
//   - $comment keys tolerated in pack JSON
//
// Semantics (per PLAN.md Phase 3, as revised by the opencode-tooling review):
//   - Deep-merge: last-wins on scalars; objects merged recursively; arrays
//     left untouched. THREE exceptions, all handled specially:
//       1. a pack's `permissions` array is RULE-MERGED into the target's
//          `permissions` array by (action, resource) key — idempotent re-runs
//          replace in place, other rules are preserved (deepMerge would
//          otherwise replace the array wholesale);
//       2. a pack's optional `cli` key (plugin packs, e.g. pack-voice.json) is
//          stripped from the opencode.json merge and merged into a SEPARATE
//          cli config via --cli-config, where the `plugins` array is merged
//          BY PACKAGE (string name or {package, options}) — idempotent re-runs
//          replace in place, other plugins are preserved;
//       3. a legacy V1 `tui` pack key is accepted as an alias for `cli`
//          (its `plugin` tuples `[name, opts]` are normalized to
//          `{package, options}` objects), so old user-authored packs keep
//          working against the V2 cli.json target.
//   - --cli-config missing while a pack carries a `cli`/`tui` key => warning +
//     skip (Docker build path: containers have no microphone, cli.json is
//     host-side). Never fatal.
//   - Empty/whitespace --packs => true no-op (exit 0, no read, no write).
//     This is the Docker `ARG OPENCODE_PACKS=""` default path. Implemented
//     via split(",").map(trim).filter(Boolean) so "" never becomes [""].
//   - Unknown pack => exit non-zero, clear error listing available packs,
//     write nothing.
//   - Malformed pack JSON => exit non-zero with file path + parse error
//     (mirrors resolve-models.mjs line 73).
//   - --dry-run => print a summary of what WOULD change; do not write.
//   - Idempotent: running the same pack list twice yields identical output.
//
// Usage:
//   node merge-packs.mjs \
//     --config <opencode.json> \
//     --packs-dir <deploy/packs> \
//     --packs autodesk \
//     [--cli-config <cli.json>] [--tui-config <cli.json> (deprecated alias)] \
//     [--dry-run] [--verbose]
//
// Exit codes: 0 success/no-op, 1 bad args / unknown pack / parse error / IO.

import { readFile, writeFile, readdir } from "node:fs/promises";
import { existsSync } from "node:fs";
import { join } from "node:path";

// ─────────────────────────── arg parsing ────────────────────────────────
const camel = (s) => s.replace(/-([a-z])/g, (_, c) => c.toUpperCase());

function parseArgsCamel(argv) {
  const out = {
    config: null,
    cliConfig: null,
    tuiConfig: null, // deprecated alias for --cli-config (V1 voice-flow flag)
    packsDir: null,
    packs: "",
    dryRun: false,
    verbose: false,
  };
  const boolKeys = new Set(["dryRun", "verbose"]);
  for (let i = 0; i < argv.length; i++) {
    let a = argv[i];
    if (!a.startsWith("--")) continue;
    let key = camel(a.slice(2));
    if (boolKeys.has(key)) {
      out[key] = true;
    } else {
      out[key] = argv[++i];
    }
  }
  return out;
}
const O = parseArgsCamel(process.argv.slice(2));
if (!O.cliConfig && O.tuiConfig) O.cliConfig = O.tuiConfig;

// ─────────────────────────── helpers ────────────────────────────────────

// tolerate $comment keys + trailing commas minimally (our pack files use $comment)
function stripJsonComments(txt) {
  return txt.replace(/^[ \t]*"\$comment"[ \t]*:.*$(\r?\n)?/gm, "");
}

async function readJsonMaybe(p) {
  if (!p) return null;
  try {
    const txt = await readFile(p, "utf8");
    return JSON.parse(stripJsonComments(txt));
  } catch (e) {
    if (e.code === "ENOENT") return null;
    throw new Error(`Failed to parse JSON ${p}: ${e.message}`);
  }
}

// Deep-merge `src` into `dst` in place. Scalars: last-wins (src overwrites).
// Objects: recurse. Arrays: replaced wholesale (documented limitation — the
// `permissions` and cli `plugins` arrays are intercepted and rule/item-merged
// separately below).
function deepMerge(dst, src) {
  for (const [k, v] of Object.entries(src)) {
    if (
      v !== null &&
      typeof v === "object" &&
      !Array.isArray(v) &&
      dst[k] !== null &&
      typeof dst[k] === "object" &&
      !Array.isArray(dst[k])
    ) {
      deepMerge(dst[k], v);
    } else {
      dst[k] = v;
    }
  }
  return dst;
}

// Merge V2 permission rule arrays BY (action, resource) KEY. An existing rule
// with the same key is replaced IN PLACE (order preserved — critical for the
// last-matching-rule-wins semantics: a pack allow replaces the source deny at
// the deny's position); rules with new keys are appended. Idempotent.
function mergeRuleArray(dstArr, srcArr) {
  for (const rule of srcArr) {
    if (!rule || typeof rule !== "object") continue;
    const idx = dstArr.findIndex(
      (r) => r && typeof r === "object" && r.action === rule.action && r.resource === rule.resource
    );
    if (idx >= 0) dstArr[idx] = rule;
    else dstArr.push(rule);
  }
  return dstArr;
}

// Plugin entry identity: a bare string (its own name), a V2
// {package, options} object (its .package), or a legacy V1 tuple [name, opts].
function entryName(e) {
  if (typeof e === "string") return e;
  if (Array.isArray(e)) return typeof e[0] === "string" ? e[0] : null;
  if (e && typeof e === "object" && typeof e.package === "string") return e.package;
  return null;
}

// Merge plugin arrays BY NAME (entry identity above). Existing same-name entry
// is replaced in place; new entries are appended. Idempotent.
function mergePluginArray(dstArr, srcArr) {
  for (const entry of srcArr) {
    const name = entryName(entry);
    const idx = name !== null ? dstArr.findIndex((e) => entryName(e) === name) : -1;
    if (idx >= 0) dstArr[idx] = entry;
    else dstArr.push(entry);
  }
  return dstArr;
}

// Normalize a legacy V1 `tui` partial to the V2 cli.json shape: `plugin`
// tuples [name, opts] become `plugins` objects {package, options}.
function normalizeCliPartial(raw) {
  if (!raw || typeof raw !== "object") return raw;
  const out = { ...raw };
  if (Array.isArray(out.plugin)) {
    const converted = out.plugin.map((e) =>
      Array.isArray(e) ? { package: e[0], options: e[1] || {} } : e
    );
    delete out.plugin;
    out.plugins = Array.isArray(out.plugins) ? [...converted, ...out.plugins] : converted;
  }
  return out;
}

function log(...a)   { console.log(...a); }
function verbose(...a){ if (O.verbose) console.error("[verbose]", ...a); }
function die(msg, code = 1) {
  console.error(`error: ${msg}`);
  process.exit(code);
}

// ─────────────────────────── main ───────────────────────────────────────
async function main() {
  // required args
  if (!O.config)    die("--config <path> is required");
  if (!O.packsDir)  die("--packs-dir <path> is required");
  // --packs is optional (empty = no-op); default "" is handled below.

  // M2: empty/whitespace packs => true no-op. split+trim+filter so "" => [].
  const requested = (O.packs || "")
    .split(",")
    .map((s) => s.trim())
    .filter(Boolean);

  if (requested.length === 0) {
    log("No packs requested (--packs empty) — no-op, config untouched.");
    return;
  }

  // discover available packs in packs-dir
  if (!existsSync(O.packsDir)) {
    die(`--packs-dir not found: ${O.packsDir}`);
  }
  const entries = await readdir(O.packsDir);
  const available = entries
    .filter((f) => /^pack-(.+)\.json$/.test(f))
    .map((f) => f.replace(/^pack-/, "").replace(/\.json$/, ""))
    .sort();

  // validate requested against available
  const unknown = requested.filter((n) => !available.includes(n));
  if (unknown.length > 0) {
    die(
      `Unknown pack(s): ${unknown.join(", ")}\n` +
      `Available packs in ${O.packsDir}: ${available.join(", ")}`
    );
  }

  // load target config
  if (!existsSync(O.config)) {
    die(`--config file not found: ${O.config}`);
  }
  const config = await readJsonMaybe(O.config);
  if (!config || typeof config !== "object") {
    die(`Could not parse config as JSON object: ${O.config}`);
  }

  // snapshot for dry-run diff (only the keys packs may touch: mcp, permissions)
  const before = JSON.stringify({
    mcp: config.mcp || {},
    permissions: config.permissions || [],
  });

  // load + deep-merge each requested pack in order. `cli` (and legacy `tui`)
  // keys are plugin-pack partials — strip them so they never leak into
  // opencode.json (handled below). `permissions` arrays are rule-merged
  // separately (deepMerge would replace the array wholesale).
  verbose(`Merging ${requested.length} pack(s) into ${O.config}:`);
  const merged = [];
  for (const name of requested) {
    const file = join(O.packsDir, `pack-${name}.json`);
    verbose(`  - ${name} (${file})`);
    const pack = await readJsonMaybe(file); // throws on malformed JSON (parse error)
    if (!pack || typeof pack !== "object") {
      die(`Pack ${name} is not a JSON object: ${file}`);
    }
    const { tui, cli, permissions: packPerms, ...mcpPack } = pack;
    deepMerge(config, mcpPack);
    if (Array.isArray(packPerms)) {
      if (!Array.isArray(config.permissions)) config.permissions = [];
      mergeRuleArray(config.permissions, packPerms);
    }
    merged.push({ name, cli: normalizeCliPartial(cli || tui) });
  }

  // Plugin packs: merge `cli` partials into the separate cli config (V2's
  // single global terminal-client config; replaces V1's layered tui.json).
  // The plugins array merges by package name (idempotent, preserves the
  // user's plugins). Missing --cli-config is a warning, not an error: the
  // Docker build path has no cli.json (host-side file, no microphone in
  // containers).
  let cliChanged = false;
  const cliPacks = merged.filter(({ cli }) => cli && typeof cli === "object");
  if (cliPacks.length > 0) {
    if (!O.cliConfig) {
      log(
        "warning: pack(s) carry a 'cli' key but --cli-config was not set — " +
          "skipping plugin merge (cli.json is host-side config; not applicable in Docker)."
      );
    } else {
      const cliConfig =
        (await readJsonMaybe(O.cliConfig)) || {
          $schema: "https://opencode.ai/v2/cli.json",
        };
      const cliBefore = JSON.stringify(cliConfig);
      for (const { name, cli } of cliPacks) {
        verbose(`  - ${name} cli -> ${O.cliConfig}`);
        const { plugins, ...cliRest } = cli;
        deepMerge(cliConfig, cliRest);
        if (Array.isArray(plugins)) {
          if (!Array.isArray(cliConfig.plugins)) cliConfig.plugins = [];
          mergePluginArray(cliConfig.plugins, plugins);
        }
      }
      cliChanged = JSON.stringify(cliConfig) !== cliBefore;
      if (!O.dryRun) {
        await writeFile(
          O.cliConfig,
          JSON.stringify(cliConfig, null, 2) + "\n",
          "utf8"
        );
      }
    }
  }

  const after = JSON.stringify({
    mcp: config.mcp || {},
    permissions: config.permissions || [],
  });

  if (O.dryRun) {
    log(`[DRY-RUN] Would merge ${requested.length} pack(s) into ${O.config}:`);
    log(`  packs: ${requested.join(", ")}`);
    log(`  changed: ${before === after ? "nothing (already merged)" : "yes"}`);
    // list the servers that would be enabled
    const enabling = [];
    for (const name of requested) {
      const p = await readJsonMaybe(join(O.packsDir, `pack-${name}.json`));
      enabling.push(...Object.keys(p.mcp?.servers || {}));
    }
    log(`  servers that would be enabled: ${enabling.join(", ")}`);
    if (cliPacks.length > 0) {
      const plugins = cliPacks.flatMap(({ cli }) =>
        (cli.plugins || []).map((p) => entryName(p))
      );
      log(
        `  plugins that would be ${O.cliConfig ? "merged into " + O.cliConfig : "SKIPPED (no --cli-config)"}: ${plugins.join(", ")}`
      );
    }
    return;
  }

  // write merged config (2-space indent matches opencode.json style)
  await writeFile(O.config, JSON.stringify(config, null, 2) + "\n", "utf8");
  log(`Merged ${requested.length} pack(s) into ${O.config}:`);
  log(`  packs: ${requested.join(", ")}`);
  log(`  changed: ${before === after ? "nothing (already merged)" : "yes"}`);
  if (cliPacks.length > 0) {
    const plugins = cliPacks.flatMap(({ cli }) =>
      (cli.plugins || []).map((p) => entryName(p))
    );
    if (O.cliConfig) {
      log(`  cli plugins merged into ${O.cliConfig}: ${plugins.join(", ")}`);
      log(`  cli changed: ${cliChanged ? "yes" : "no (already merged)"}`);
    }
  }
}

main().catch((e) => die(e.message || String(e)));
