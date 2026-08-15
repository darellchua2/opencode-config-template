#!/usr/bin/env node
// Apply a skill profile (lean|full) to a DEPLOYED opencode config.
//
// Rewrites ONLY the `permission.skill` block of the target config:
//   lean -> { "*": "deny", ...<29 lean keys>: "allow" }   (from skill-profiles.json)
//   full -> no-op (deploy verbatim; the shipped opencode.json IS the full profile)
//
// Never edits the source `opencode_app/opencode.json` (single source of truth).
// Mirrors merge-packs.mjs CLI conventions so setup.sh can call it the same way.

import { readFileSync, writeFileSync, existsSync } from "node:fs";
import { resolve } from "node:path";

function usage() {
  console.log(`Usage: node apply-skill-profile.mjs --config <path> --profiles <path> [--profile lean|full]

  --config    Path to the DEPLOYED config.json to patch in place.
  --profiles  Path to deploy/skill-profiles.json (lean key list).
  --profile   Profile to apply. Default: lean. "full" is a verified no-op:
              the config keeps the shipped 87-allow allowlist verbatim.

Exits non-zero on: missing/unparseable config or profiles, unknown profile,
lean keys not present in the config's shipped allowlist (guards typo'd keys).`);
}

const args = process.argv.slice(2);
function argValue(flag) {
  const i = args.indexOf(flag);
  if (i === -1) return undefined;
  return args[i + 1];
}

const configPath = argValue("--config");
const profilesPath = argValue("--profiles");
const profile = argValue("--profile") ?? "lean";

if (!configPath || !profilesPath) {
  usage();
  process.exit(1);
}
if (!["lean", "full"].includes(profile)) {
  console.error(`apply-skill-profile: unknown profile "${profile}" (expected lean|full)`);
  process.exit(1);
}
for (const p of [configPath, profilesPath]) {
  if (!existsSync(p)) {
    console.error(`apply-skill-profile: file not found: ${p}`);
    process.exit(1);
  }
}

const config = JSON.parse(readFileSync(configPath, "utf8"));
const profiles = JSON.parse(readFileSync(profilesPath, "utf8"));

if (profile === "full") {
  const allows = Object.keys(config.permission?.skill ?? {}).filter((k) => k !== "*");
  console.log(`apply-skill-profile: full — deployed verbatim (${allows.length} allows, no rewrite)`);
  process.exit(0);
}

const lean = profiles.lean;
if (!Array.isArray(lean) || lean.length === 0) {
  console.error("apply-skill-profile: profiles file has no non-empty .lean array");
  process.exit(1);
}

const shipped = config.permission?.skill ?? {};
const missing = lean.filter((k) => shipped[k] !== "allow");
if (missing.length > 0) {
  console.error(
    `apply-skill-profile: lean keys not present in shipped allowlist (typo guard): ${missing.join(", ")}`
  );
  process.exit(1);
}

const next = { "*": "deny" };
for (const k of [...lean].sort()) next[k] = "allow";
config.permission.skill = next;

writeFileSync(configPath, JSON.stringify(config, null, 2) + "\n");
console.log(
  `apply-skill-profile: lean — deployed permission.skill rewritten to ${lean.length} allows + "*": "deny"`
);
