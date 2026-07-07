#!/usr/bin/env node
// deploy/tui.mjs
//
// Zero-dependency interactive terminal UI for the v2.0 model system. Node
// built-ins only (readline raw-mode, fs, child_process). Runs identically on
// macOS / Linux / Windows-GitBash / PowerShell / `docker run -it`.
//
// Flows (first positional arg):
//   provider-picker   Arrow-key select a provider preset; write models.json
//   migration-review  Show before/after table (via resolver --json), confirm
//   override-editor   Pick agents to pin with a custom model
//   tier-editor       Edit the model of each tier for a chosen provider
//
// Non-TTY / piped stdin: flows exit non-zero (except migration-review with
// --yes), so setup.sh / setup.ps1 can fall back to flags (--provider, --yes).
//
// Contract: flows PRINT their outcome to stdout (JSON or a chosen value) and
// return exit 0 on success, non-zero on cancel/non-TTY.

import readline from "node:readline";
import { readFile, writeFile, mkdir, readdir } from "node:fs/promises";
import { existsSync } from "node:fs";
import { dirname, basename, join } from "node:path";
import { spawnSync } from "node:child_process";

// ─────────────────────────── arg parsing ────────────────────────────────
function parseArgs(argv) {
  const opts = {};
  const flags = new Set(["yes", "verbose"]);
  const rest = [];
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (a.startsWith("--")) {
      const key = a.slice(2).replace(/-([a-z])/g, (_, c) => c.toUpperCase());
      if (flags.has(key)) opts[key] = true;
      else opts[key] = argv[++i];
    } else {
      rest.push(a);
    }
  }
  return { opts, rest };
}

async function readJsonMaybe(p) {
  if (!p) return null;
  try {
    const txt = await readFile(p, "utf8");
    return JSON.parse(txt.replace(/^[ \t]*"\$comment"[ \t]*:.*$(\r?\n)?/gm, ""));
  } catch (e) {
    return null;
  }
}

// ─────────────────────────── TTY primitives ─────────────────────────────
const isTTY = () => process.stdin.isTTY && process.stdout.isTTY;
const hide = () => process.stdout.write("\x1b[?25l");
const show = () => process.stdout.write("\x1b[?25h");
function clearN(n) {
  for (let i = 0; i < n; i++) process.stdout.write("\x1b[1A\x1b[2K");
}
const B = (s) => `\x1b[1m${s}\x1b[0m`;
const DIM = (s) => `\x1b[2m${s}\x1b[0m`;
const CY = (s) => `\x1b[36m${s}\x1b[0m`;

async function singleSelect(title, options) {
  // options: [{label, value, hint?}]
  if (!isTTY()) return { aborted: true, nonTty: true };
  let idx = 0;
  let lineCount = 0;
  process.stdin.setRawMode(true);
  process.stdin.resume();
  readline.emitKeypressEvents(process.stdin);
  hide();
  const render = () => {
    if (lineCount) clearN(lineCount + 1);
    const lines = [B(title), ""];
    options.forEach((o, i) => {
      const sel = i === idx;
      const mark = sel ? `${CY("❯")}` : " ";
      const label = sel ? CY(o.label) : DIM(o.label);
      lines.push(`  ${mark} ${label}${o.hint ? "  " + DIM(o.hint) : ""}`);
    });
    lines.push("", DIM("  ↑/↓ navigate · Enter select · Esc cancel"));
    const text = lines.join("\n") + "\n";
    lineCount = text.split("\n").length - 1;
    process.stdout.write("\n" + text);
  };
  return new Promise((resolve) => {
    const cleanup = () => {
      process.stdin.removeListener("keypress", onKey);
      try { process.stdin.setRawMode(false); } catch {}
      show();
      if (lineCount) clearN(lineCount + 1);
      process.stdout.write("\n");
    };
    const onKey = (str, key) => {
      if (key.ctrl && key.name === "c") { cleanup(); process.exit(130); }
      else if (key.name === "up") { idx = (idx - 1 + options.length) % options.length; render(); }
      else if (key.name === "down") { idx = (idx + 1) % options.length; render(); }
      else if (key.name === "return") { cleanup(); resolve({ value: options[idx].value, index: idx }); }
      else if (key.name === "escape") { cleanup(); resolve({ aborted: true }); }
    };
    process.stdin.on("keypress", onKey);
    render();
  });
}

async function multiSelect(title, options) {
  // options: [{label, value, checked?}]
  if (!isTTY()) return { aborted: true, nonTty: true };
  let idx = 0;
  const checked = options.map((o) => !!o.checked);
  let lineCount = 0;
  process.stdin.setRawMode(true);
  process.stdin.resume();
  readline.emitKeypressEvents(process.stdin);
  hide();
  const render = () => {
    if (lineCount) clearN(lineCount + 1);
    const lines = [B(title), ""];
    options.forEach((o, i) => {
      const sel = i === idx;
      const mark = sel ? CY("❯") : " ";
      const box = checked[i] ? `${CY("◉")}` : "◯";
      const label = sel ? CY(o.label) : DIM(o.label);
      lines.push(`  ${mark} ${box} ${label}`);
    });
    lines.push("", DIM("  ↑/↓ navigate · Space toggle · a all · Enter done · Esc cancel"));
    const text = lines.join("\n") + "\n";
    lineCount = text.split("\n").length - 1;
    process.stdout.write("\n" + text);
  };
  return new Promise((resolve) => {
    const cleanup = () => {
      process.stdin.removeListener("keypress", onKey);
      try { process.stdin.setRawMode(false); } catch {}
      show();
      if (lineCount) clearN(lineCount + 1);
      process.stdout.write("\n");
    };
    const onKey = (str, key) => {
      if (key.ctrl && key.name === "c") { cleanup(); process.exit(130); }
      else if (key.name === "up") { idx = (idx - 1 + options.length) % options.length; render(); }
      else if (key.name === "down") { idx = (idx + 1) % options.length; render(); }
      else if (key.name === "space") { checked[idx] = !checked[idx]; render(); }
      else if (key.sequence === "a") { const all = !checked.every(Boolean); for (let i = 0; i < checked.length; i++) checked[i] = all; render(); }
      else if (key.name === "return") { cleanup(); resolve({ selected: options.filter((_, i) => checked[i]).map((o) => o.value) }); }
      else if (key.name === "escape") { cleanup(); resolve({ aborted: true }); }
    };
    process.stdin.on("keypress", onKey);
    render();
  });
}

async function textInput(prompt, defaultValue = "") {
  if (!isTTY()) return { aborted: true, nonTty: true };
  const rl = readline.createInterface({ input: process.stdin, output: process.stdout });
  return new Promise((resolve) => {
    rl.question(`${B(prompt)} ${defaultValue ? `[${DIM(defaultValue)}]` : ""}: `, (ans) => {
      rl.close();
      resolve({ value: (ans || defaultValue).trim() });
    });
  });
}

async function confirm(prompt, defYes = false) {
  if (!isTTY()) return { aborted: true, nonTty: true };
  const rl = readline.createInterface({ input: process.stdin, output: process.stdout });
  return new Promise((resolve) => {
    rl.question(`${B(prompt)} (${defYes ? "Y/n" : "y/N"}): `, (ans) => {
      rl.close();
      const y = (ans || "").toLowerCase();
      resolve({ value: y === "y" || y === "yes" || (defYes && y === "") });
    });
  });
}

// ─────────────────────────── frontmatter reader ─────────────────────────
function readFrontmatterModel(content) {
  const lines = content.split(/\r?\n/);
  if (!lines.length || lines[0].trim() !== "---") return null;
  for (let i = 1; i < lines.length; i++) {
    if (lines[i].trim() === "---") break;
    const m = lines[i].match(/^model\s*:\s*(.+?)\s*$/);
    if (m) return m[1].trim();
  }
  return null;
}

// ─────────────────────────── flows ──────────────────────────────────────

// provider-picker: --presets <p> [--provider <name>] [--out <models.json>]
// With --provider, skips the menu and writes that preset directly (non-interactive).
async function flowProviderPicker({ opts }) {
  const presets = await readJsonMaybe(opts.presets);
  if (!presets) { console.error("error: --presets file missing/invalid"); process.exit(2); }
  let chosen;
  if (opts.provider && presets[opts.provider]) {
    chosen = opts.provider;
  } else {
    const keys = Object.keys(presets).filter((k) => !k.startsWith("$"));
    const options = keys.map((k) => ({ label: presets[k].label || k, value: k, hint: presets[k].primary }));
    const sel = await singleSelect("Select a model provider", options);
    if (sel.aborted) { console.error("cancelled"); process.exit(1); }
    chosen = sel.value;
  }
  const preset = presets[chosen];
  const out = { primary: preset.primary, tiers: preset.tiers };

  if (opts.out) {
    await mkdir(dirname(opts.out), { recursive: true });
    await writeFile(opts.out, JSON.stringify(out, null, 2) + "\n", "utf8");
    console.log(`Wrote ${opts.out} (${chosen})`);
  } else {
    console.log(JSON.stringify({ provider: chosen, map: out }));
  }
}

// migration-review: runs resolver --json --dry-run, shows before/after, confirms.
// Passes through resolver args; --resolver <path> --agents-dest <dir> required.
async function flowMigrationReview({ opts, rest }) {
  const resolverPath = opts.resolver;
  const agentsDest = opts.agentsDest;
  if (!resolverPath || !agentsDest) {
    console.error("error: migration-review requires --resolver <resolve-models.mjs> --agents-dest <dir>");
    process.exit(2);
  }

  // Forward resolver-relevant flags (parseArgs already consumed them into opts).
  const resolverFlags = [
    "agentsSrc", "agentsDest", "tiers", "defaultMap", "userMap", "projectMap",
    "overrides", "projectOverrides", "configSrc", "configDest", "state",
    "provider", "presets", "force",
  ];
  const kebab = (k) => k.replace(/[A-Z]/g, (m) => "-" + m.toLowerCase());
  const resolverArgs = [];
  for (const k of resolverFlags) {
    if (opts[k] === true) resolverArgs.push("--" + kebab(k));
    else if (opts[k]) resolverArgs.push("--" + kebab(k), opts[k]);
  }
  resolverArgs.push("--json", "--dry-run");

  const res = spawnSync(process.execPath, [resolverPath, ...resolverArgs], {
    encoding: "utf8",
  });
  if (res.status !== 0 || !res.stdout) {
    console.error("resolver failed:");
    console.error(res.stderr || res.stdout);
    process.exit(2);
  }
  let data;
  try { data = JSON.parse(res.stdout); }
  catch { console.error("could not parse resolver output"); process.exit(2); }

  // before = current dest frontmatter model (if file exists)
  const before = {};
  if (existsSync(agentsDest)) {
    for (const f of (await readdir(agentsDest)).filter((f) => f.endsWith(".md"))) {
      const stem = basename(f, ".md");
      const content = await readFile(join(agentsDest, f), "utf8");
      const m = readFrontmatterModel(content);
      if (m) before[stem] = m;
    }
  }

  // render before/after table
  const cStem = Math.max(5, ...data.agents.map((a) => a.stem.length));
  const cModel = 30;
  const pad = (s, w) => (s + " ".repeat(w)).slice(0, w);
  const lines = [];
  const _providerName = data.provider || "default";
  lines.push(B("v2.0 migration preview") + DIM("  (provider: " + _providerName + ")"));
  lines.push(`${pad("AGENT", cStem)}  ${pad("CURRENT", cModel)} -> ${pad("RESOLVED", cModel)}  TIER`);
  lines.push("-".repeat(cStem + cModel * 2 + 14));
  for (const a of data.agents) {
    const cur = before[a.stem] ? pad(before[a.stem], cModel) : DIM(pad("(new)", cModel));
    const after = a.model === "(preserved)" ? DIM(pad(a.model, cModel)) : pad(a.model || "-", cModel);
    lines.push(`${pad(a.stem, cStem)}  ${cur} -> ${after}  ${a.tier || "-"}`);
  }
  lines.push("-".repeat(cStem + cModel * 2 + 14));
  lines.push(`Primary: ${data.primary}    ${data.written} write · ${data.preserved} preserve · ${data.skipped} skip`);
  console.log(lines.join("\n"));

  if (opts.yes) { console.log(DIM("--yes set, proceeding")); return; }
  const c = await confirm("Proceed with migration?", false);
  if (c.aborted || !c.value) { console.error("aborted"); process.exit(1); }
}

// override-editor: --tiers <agent-tiers.json> --out <agent-overrides.json>
async function flowOverrideEditor({ opts }) {
  const tiersDoc = await readJsonMaybe(opts.tiers);
  if (!tiersDoc) { console.error("error: --tiers file missing/invalid"); process.exit(2); }
  const existing = (await readJsonMaybe(opts.out)) || {};
  const stems = Object.keys(tiersDoc.tiers).sort();
  const options = stems.map((s) => ({
    label: `${s}  [${tiersDoc.tiers[s]}]${existing[s] ? `  -> ${existing[s].model}` : ""}`,
    value: s,
  }));
  const sel = await multiSelect("Select agents to pin a custom model (Esc to finish)", options);
  if (sel.aborted) { console.error("cancelled"); process.exit(1); }

  const result = {};
  for (const stem of sel.selected) {
    const t = await textInput(`Model for ${stem} (provider/model-id)`, existing[stem] && existing[stem].model || "");
    if (t.aborted || !t.value) continue;
    result[stem] = { model: t.value };
  }
  // merge with any existing pins not re-touched
  for (const k of Object.keys(existing)) if (!result[k] && existing[k].model) {
    // keep existing pins that user didn't deselect? Only keep selected set to keep it simple & explicit.
  }
  if (opts.out) {
    await mkdir(dirname(opts.out), { recursive: true });
    await writeFile(opts.out, JSON.stringify(result, null, 2) + "\n", "utf8");
    console.log(`Wrote ${opts.out} (${Object.keys(result).length} override(s))`);
  } else {
    console.log(JSON.stringify(result));
  }
}

// tier-editor: --presets <p> --provider <name> --out <models.json>
async function flowTierEditor({ opts }) {
  const presets = await readJsonMaybe(opts.presets);
  if (!presets || !opts.provider || !presets[opts.provider]) {
    console.error("error: --presets and --provider <name> required");
    process.exit(2);
  }
  const base = presets[opts.provider];
  const tierOrder = ["primary", "reasoning", "fast", "docs", "vision"];
  const out = { primary: base.primary, tiers: { ...base.tiers } };
  for (const tier of tierOrder) {
    const cur = tier === "primary" ? out.primary : out.tiers[tier];
    const t = await textInput(tier === "primary" ? "primary model" : `${tier} tier model`, cur);
    if (t.aborted) continue;
    if (t.value) { if (tier === "primary") out.primary = t.value; else out.tiers[tier] = t.value; }
  }
  if (opts.out) {
    await mkdir(dirname(opts.out), { recursive: true });
    await writeFile(opts.out, JSON.stringify(out, null, 2) + "\n", "utf8");
    console.log(`Wrote ${opts.out}`);
  } else {
    console.log(JSON.stringify(out));
  }
}

// ─────────────────────────── dispatch ───────────────────────────────────
const flow = process.argv[2];
const parsed = parseArgs(process.argv.slice(3));
(async () => {
  switch (flow) {
    case "provider-picker": await flowProviderPicker(parsed); break;
    case "migration-review": await flowMigrationReview(parsed); break;
    case "override-editor": await flowOverrideEditor(parsed); break;
    case "tier-editor": await flowTierEditor(parsed); break;
    default:
      console.error("usage: tui.mjs <provider-picker|migration-review|override-editor|tier-editor> [opts]");
      process.exit(2);
  }
})().catch((e) => { console.error(`tui error: ${e.message}`); process.exit(1); });
