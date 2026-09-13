#!/usr/bin/env node
// Apply a skill profile (lean|full) to a DEPLOYED opencode config.
//
// Rewrites ONLY the `skill` rules inside the target config's `permissions`
// array (V2 shape — ordered {action, resource, effect} rules, last matching
// rule wins):
//   lean -> deny "*" + allow the lean keys (from skill-profiles.json)
//   full -> no-op (deploy verbatim; the shipped opencode.json IS the full profile)
//
// Never edits the source `opencode_app/opencode.json` (single source of truth).
// Mirrors merge-packs.mjs CLI conventions so setup.sh can call it the same way.

import { readFileSync, writeFileSync, existsSync } from "node:fs";

function usage() {
  console.log(`Usage: node apply-skill-profile.mjs --config <path> --profiles <path> [--profile lean|full]

  --config    Path to the DEPLOYED config.json to patch in place.
  --profiles  Path to deploy/skill-profiles.json (lean key list).
  --profile   Profile to apply. Default: lean. "full" is a verified no-op:
              the config keeps the shipped allowlist rules verbatim.

Exits non-zero on: missing/unparseable config or profiles, unknown profile,
config without a V2 \`permissions\` array (redeploy the config first), or lean
keys not present in the config's shipped allowlist (guards typo'd keys).`);
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

if (!Array.isArray(config.permissions)) {
  console.error(
    "apply-skill-profile: config has no `permissions` rule array (V2 shape) — redeploy the config first"
  );
  process.exit(1);
}

// Shipped skill allowlist = non-"*" skill rules with effect allow.
const shippedAllows = config.permissions
  .filter(
    (r) =>
      r && r.action === "skill" && r.effect === "allow" && r.resource && r.resource !== "*"
  )
  .map((r) => r.resource);

if (profile === "full") {
  console.log(`apply-skill-profile: full — deployed verbatim (${shippedAllows.length} allows, no rewrite)`);
  process.exit(0);
}

const lean = profiles.lean;
if (!Array.isArray(lean) || lean.length === 0) {
  console.error("apply-skill-profile: profiles file has no non-empty .lean array");
  process.exit(1);
}

const shipped = new Set(shippedAllows);
const missing = lean.filter((k) => !shipped.has(k));
if (missing.length > 0) {
  console.error(
    `apply-skill-profile: lean keys not present in shipped allowlist (typo guard): ${missing.join(", ")}`
  );
  process.exit(1);
}

// Strip every existing skill rule, then append the lean block (deny "*" first,
// sorted allows after). Skill checks only ever match skill rules, so appending
// at the end preserves deny-then-exceptions ordering semantics without
// disturbing the position of unrelated (read/shell/…) rules.
config.permissions = config.permissions.filter((r) => !(r && r.action === "skill"));
config.permissions.push({ action: "skill", resource: "*", effect: "deny" });
for (const k of [...lean].sort()) {
  config.permissions.push({ action: "skill", resource: k, effect: "allow" });
}

writeFileSync(configPath, JSON.stringify(config, null, 2) + "\n");
console.log(
  `apply-skill-profile: lean — deployed skill rules rewritten to ${lean.length} allows + deny "*"`
);
