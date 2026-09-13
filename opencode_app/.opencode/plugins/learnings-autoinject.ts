// learnings-autoinject.ts — OpenCode plugin that auto-injects a compact manifest
// of a project's LEARNINGS/*.md files into the system prompt at session start.
//
// Closes the gap documented in continuous-learning-skill/SKILL.md:
//   "OpenCode does NOT auto-scan LEARNINGS/ directories."
// The superlocalmemory plugin auto-injects its vector store (tui.prompt.append),
// but the git-committed LEARNINGS/*.md markdown files are never surfaced
// automatically — agents must manually glob+read. This plugin automates the
// *discovery* step by injecting a titles+paths manifest into the system prompt
// so the model knows what's available without spending a tool call.
//
// Architecture mirrors ponytail-scoped.ts (same registration set, same toggle
// pattern, same env-var + slash-command controls). The model still `read()`s
// full file bodies on demand — we inject only the index.
//
// ── Why .ts (NOT .mjs) ───────────────────────────────────────────────────────
// OpenCode's local-plugin discovery globs `{plugin,plugins}/*.{ts,js}` (V1:
// packages/opencode/src/config/plugin.ts @ v1.18.11; V2 keeps glob discovery of
// `.opencode/plugins/`). `.mjs` is NOT matched. `.ts` is robust: Bun always
// treats it as ESM. See research/ponytail-load-fix.md.
//
// ── OpenCode V2 + V1 dual entrypoint ────────────────────────────────────────
// https://opencode.ai/v2/docs/build/plugins/ § "Support V1": V2 reads the
// default export's `id` + `setup(ctx)`; V1 (>= 1.18.29) calls `server()` and
// uses the returned V1 hook map. One file serves both runtimes. Intentionally
// NO import of "@opencode/plugin": this file deploys as a bare .ts into
// ~/.config/opencode/plugins/ (no node_modules / package.json there), and
// Plugin.define is documented as a typing helper — the V2 runtime contract is
// just `id` + `setup` on the default export. V1 older than 1.18.29 expects
// function exports and will not load this object form.
//
// ── V2 registrations (in setup) ──────────────────────────────────────────────
//   - ctx.command.transform — registers the 4 /learnings-* commands; the former
//     command.execute.before side effects (toggle/refresh persistence) now run
//     inside each command's execute(), before the confirmation prompt.
//   - ctx.session.hook("context") — CORE: append the manifest to event.system
//     for agent-loop model requests. event.agent is native on this hook, so
//     the V1 chat.message sessionID→agent cache + session.get() fallback are
//     V1-only machinery (kept in server() below, unused by setup()).
//
// ── V1 hooks (returned by server(), per the V1 plugin API) ──────────────────
//   - config(input)                              — register slash commands
//   - "chat.message"(input)                      — cache sessionID → agent
//   - "experimental.chat.system.transform"(input, output) — CORE: append manifest
//   - "command.execute.before"(input)            — persist /learnings-* toggles
//
// ── Env vars ─────────────────────────────────────────────────────────────────
//   LEARNINGS_AUTOINJECT_DEFAULT  — on|off  (default: on)   global default state
//   LEARNINGS_AUTOINJECT_USER     — on|off  (default: off)  also scan user-level dir
//   LEARNINGS_AUTOINJECT_OFF      — regex of agent names to EXCLUDE (default: read-only/research agents)
//   LEARNINGS_AUTOINJECT_MAX      — number  (default: 30)   cap files in manifest
//
// No opencode.json change required — local plugins are glob-discovered.

import fs from 'fs';
import path from 'path';
import os from 'os';

// ── Configuration (read once at load) ──────────────────────────────────────────

function parseBoolEnv(name: string, fallback: boolean): boolean {
  const v = (process.env[name] || '').trim().toLowerCase();
  if (v === 'on' || v === '1' || v === 'true' || v === 'yes') return true;
  if (v === 'off' || v === '0' || v === 'false' || v === 'no') return false;
  return fallback;
}

const DEFAULT_ENABLED = parseBoolEnv('LEARNINGS_AUTOINJECT_DEFAULT', true);
const USER_LEVEL_ENABLED = parseBoolEnv('LEARNINGS_AUTOINJECT_USER', false);
const MAX_FILES = (() => {
  const n = parseInt(process.env.LEARNINGS_AUTOINJECT_MAX || '', 10);
  return Number.isFinite(n) && n > 0 ? Math.min(n, 100) : 30;
})();

// Reuse ponytail's off-set verbatim — read-only/research/non-coding agents that
// do not act on LEARNINGS. Keeping the two regexes in sync is intentional; if
// ponytail's set changes, mirror it here.
const DEFAULT_OFF_PATTERN =
  '^(explore|general|autoresearch-research-subagent|explorer-subagent|' +
  'requirements-specialist-subagent|discovery-specialist-subagent|' +
  'technical-design-specialist-subagent|' +
  'coverage-subagent|documentation-subagent|docx-creation-subagent|' +
  'pptx-specialist-subagent|xlsx-specialist-subagent|office-document-primary-agent|' +
  'startup-ceo-subagent|startup-founder-primary-agent|' +
  'image-analyzer-subagent|' +
  'code-review-subagent|architecture-review-subagent|error-resolver-subagent|' +
  'nextjs-specialist-subagent|autoresearch-code-subagent|loop-operator-subagent|' +
  'tdd-subagent|testing-subagent)$';

function compileOffRegex() {
  const pattern = process.env.LEARNINGS_AUTOINJECT_OFF || DEFAULT_OFF_PATTERN;
  try {
    return new RegExp(pattern, 'i');
  } catch (_) {
    return new RegExp(DEFAULT_OFF_PATTERN, 'i');
  }
}
const OFF_REGEX = compileOffRegex();

const LEARNINGS_DIR = 'LEARNINGS';
const USER_LEARNINGS_DIR = path.join(os.homedir(), '.config', 'opencode', 'learnings');
const MARKER = 'LEARNINGS AUTOINJECT';

// ── Per-session state ───────────────────────────────────────────────────────────

const sessionAgent = new Map();       // sessionID → agent (V1 path only: populated by chat.message)
const sessionEnabled = new Map();     // sessionID → boolean (overridden via /learnings-on|off)
const sessionManifest = new Map();    // sessionID → string (cached manifest; rebuilt on /learnings-refresh)

function isOn(sessionID: string): boolean {
  if (sessionID && sessionEnabled.has(sessionID)) return sessionEnabled.get(sessionID);
  return DEFAULT_ENABLED;
}

function isInOffSet(agent?: string): boolean {
  if (!agent) return false;
  return OFF_REGEX.test(agent);
}

// ── LEARNINGS discovery (filesystem, dependency-free) ───────────────────────────

function walkMd(rootDir: string): string[] {
  const out: string[] = [];
  const stack = [rootDir];
  while (stack.length) {
    const dir = stack.pop()!;
    let entries: fs.Dirent[];
    try {
      entries = fs.readdirSync(dir, { withFileTypes: true });
    } catch (_) {
      continue;
    }
    for (const e of entries) {
      if (e.isDirectory()) {
        if (!e.name.startsWith('.') && e.name !== 'node_modules') stack.push(path.join(dir, e.name));
      } else if (e.isFile() && e.name.endsWith('.md')) {
        out.push(path.join(dir, e.name));
      }
    }
  }
  return out.sort();
}

// Extract a one-line title: first H1/H2, else first non-empty non-frontmatter line.
function extractTitle(absPath: string): string | null {
  let fd: number | undefined;
  try {
    fd = fs.openSync(absPath, 'r');
    const buf = Buffer.alloc(512);
    const bytes = fs.readSync(fd, buf, 0, 512, 0);
    const lines = buf.toString('utf8', 0, bytes).split('\n');
    let inFrontmatter = false;
    let sawFrontmatterOpen = false;
    for (const raw of lines) {
      const line = raw.trim();
      if (!line || line.startsWith('<!--')) continue;
      if (line === '---') {
        if (!sawFrontmatterOpen) { inFrontmatter = true; sawFrontmatterOpen = true; continue; }
        inFrontmatter = false; continue;
      }
      if (inFrontmatter) continue;
      if (line.startsWith('# ')) return line.slice(2).trim().slice(0, 120);
      if (line.startsWith('## ')) return line.slice(3).trim().slice(0, 120);
      return line.replace(/^[-*]\s*/, '').slice(0, 120);
    }
  } catch (_) {
    // unreadable file — fall through
  } finally {
    if (fd !== undefined) { try { fs.closeSync(fd); } catch (_) {} }
  }
  return null;
}

function getProjectName(directory: string): string {
  try {
    const pj = path.join(directory, 'package.json');
    if (fs.existsSync(pj)) {
      const name = JSON.parse(fs.readFileSync(pj, 'utf8')).name;
      if (typeof name === 'string' && name.trim()) return name.trim();
    }
  } catch (_) {}
  return path.basename(directory) || 'project';
}

function buildSection(rootDir: string, rootLabel: string): { lines: string[]; total: number } | null {
  if (!fs.existsSync(rootDir)) return null;
  const files = walkMd(rootDir);
  if (files.length === 0) return null;
  const lines: string[] = [];
  for (const abs of files) {
    if (lines.length >= MAX_FILES) {
      lines.push(`... and ${files.length - MAX_FILES} more in ${rootLabel} (raise LEARNINGS_AUTOINJECT_MAX)`);
      break;
    }
    const rel = path.relative(rootDir, abs).replace(/\\/g, '/');
    const title = extractTitle(abs);
    lines.push(title ? `- ${rel} — ${title}` : `- ${rel}`);
  }
  return { lines, total: files.length };
}

function buildManifest(sessionID: string, directory: string): string | null {
  const projectSection = buildSection(path.join(directory, LEARNINGS_DIR), 'project');
  let userSection: { lines: string[]; total: number } | null = null;
  if (USER_LEVEL_ENABLED) {
    userSection = buildSection(USER_LEARNINGS_DIR, 'user-level');
  }
  if (!projectSection && !userSection) return null;

  const out: string[] = [];
  out.push(`<${MARKER} — project: ${getProjectName(directory)}>`);
  out.push('Available learnings (use `read()` on a path for full detail):');
  if (projectSection) out.push(...projectSection.lines);
  if (userSection) {
    out.push(`(user-level @ ~/.config/opencode/learnings/ — ${userSection.total} files)`);
    out.push(...userSection.lines);
  }
  const counts: string[] = [];
  if (projectSection) counts.push(`${projectSection.total} project`);
  if (userSection) counts.push(`${userSection.total} user-level`);
  out.push(`Source: LEARNINGS/ (${counts.join(', ')}). Refresh: /learnings-refresh`);
  out.push(`</${MARKER}>`);
  return out.join('\n');
}

// ── Command definitions ─────────────────────────────────────────────────────────

const COMMANDS = {
  learnings: {
    description: 'Learnings-autoinject: report on/off state and file count for this session.',
    template:
      'Report the learnings-autoinject state for this session in one line (on or off, and how many ' +
      'LEARNINGS files are indexed). Do not output code.',
    agent: 'build',
  },
  'learnings-on': {
    description: 'Learnings-autoinject: enable manifest injection for this session.',
    template: 'LEARNINGS auto-inject is now ON for this session. Confirm in one line. Do not output code.',
    agent: 'build',
  },
  'learnings-off': {
    description: 'Learnings-autoinject: disable manifest injection for this session.',
    template: 'LEARNINGS auto-inject is now OFF for this session. Confirm in one line. Do not output code.',
    agent: 'build',
  },
  'learnings-refresh': {
    description: 'Learnings-autoinject: re-scan LEARNINGS/ and rebuild the manifest on the next turn.',
    template: 'LEARNINGS manifest cache invalidated — it will be rebuilt on the next turn. Confirm in one line. Do not output code.',
    agent: 'build',
  },
};

// ── V1 plugin body (returned by server()) ───────────────────────────────────────
//
// Verbatim port of the original V1 named-export plugin. Destructures
// { client, directory } — directory is the project root used to locate
// <cwd>/LEARNINGS/.

const v1Hooks = async ({ client, directory }: any = {}) => {
  const cwd: string = directory || process.cwd();

  const log = (level: string, message: string) => {
    try {
      client && client.app && client.app.log({ body: { service: 'learnings-autoinject', level, message } });
    } catch (_) {}
  };

  log('info', 'learnings-autoinject loaded — default: ' + (DEFAULT_ENABLED ? 'on' : 'off'));

  return {
    // Register the 4 commands (non-destructive merge).
    config: async (config: any) => {
      if (!config.command) config.command = {};
      for (const [name, def] of Object.entries(COMMANDS)) {
        if (!config.command[name]) config.command[name] = def;
      }
    },

    // Cache sessionID → agent so the transform hook can scope by agent type.
    'chat.message': async (input: any) => {
      if (input && input.sessionID && input.agent) {
        sessionAgent.set(input.sessionID, input.agent);
      }
    },

    // Core: append the cached manifest to the system prompt, gated by toggle + off-set + idempotency.
    'experimental.chat.system.transform': async (input: any, output: any) => {
      if (!output || !Array.isArray(output.system)) return;

      const sessionID = input && input.sessionID;
      if (sessionID && !isOn(sessionID)) return;

      let agent = sessionID ? sessionAgent.get(sessionID) : undefined;
      if (!agent && sessionID && client && client.session && client.session.get) {
        try {
          const res = await client.session.get({ path: { id: sessionID } });
          const data = res && res.data;
          agent = (data && (data.agent || data.agentID || data.agentId)) || undefined;
          if (agent) sessionAgent.set(sessionID, agent);
        } catch (_) {}
      }

      if (isInOffSet(agent)) {
        log('debug', 'learnings skipped: agent in off-set (' + (agent || '?') + ')');
        return;
      }

      // Idempotency: skip if already injected this turn.
      for (const entry of output.system) {
        if (typeof entry === 'string' && entry.includes(MARKER)) return;
      }

      // Cache the manifest per session (rebuilt on /learnings-refresh).
      let manifest = sessionID ? sessionManifest.get(sessionID) : undefined;
      if (manifest === undefined) {
        manifest = buildManifest(sessionID || '', cwd);
        if (sessionID) sessionManifest.set(sessionID, manifest); // may be null (no LEARNINGS dir)
      }
      if (!manifest) return; // no LEARNINGS/ → skip silently

      if (output.system.length > 0) {
        output.system[output.system.length - 1] =
          String(output.system[output.system.length - 1]) + '\n\n' + manifest;
      } else {
        output.system.push(manifest);
      }
    },

    // Persist /learnings-on|off|refresh per session.
    'command.execute.before': async (input: any) => {
      if (!input) return;
      const cmd = input.command || '';
      const sessionID = input.sessionID;
      if (!sessionID) return;

      if (cmd === 'learnings-on') {
        sessionEnabled.set(sessionID, true);
        log('info', 'learnings ON (session ' + sessionID + ')');
      } else if (cmd === 'learnings-off') {
        sessionEnabled.set(sessionID, false);
        log('info', 'learnings OFF (session ' + sessionID + ')');
      } else if (cmd === 'learnings-refresh') {
        sessionManifest.delete(sessionID);
        log('info', 'learnings manifest invalidated (session ' + sessionID + ')');
      }
    },
  };
};

// ── Dual entrypoint: V2 setup() + V1 server() ──────────────────────────────────

export default {
  id: 'learnings-autoinject',

  // ── OpenCode V2 ────────────────────────────────────────────────────────────
  async setup(ctx: any) {
    const cwd: string = (ctx.location && ctx.location.directory) || process.cwd();

    // V2 plugin context has no documented app.log; console is the sanctioned
    // channel in the V2 plugin examples.
    const log = (level: string, message: string) => {
      try {
        console.log(`[learnings-autoinject] ${level}: ${message}`);
      } catch (_) {}
    };

    log('info', 'learnings-autoinject loaded — default: ' + (DEFAULT_ENABLED ? 'on' : 'off'));

    // Register the 4 commands; the plugin now OWNS them, so the former
    // command.execute.before side effects run inside execute(), before the
    // same confirmation prompt the V1 template submitted. (The V1
    // `agent: "build"` pin has no documented V2 CommandDefinition equivalent —
    // commands run in the session's active agent.)
    await ctx.command.transform((editor: any) => {
      for (const [name, def] of Object.entries(COMMANDS)) {
        editor.add({
          name,
          description: def.description,
          execute: async ({ sessionID, prompt, delivery }: any = {}) => {
            if (sessionID) {
              if (name === 'learnings-on') {
                sessionEnabled.set(sessionID, true);
                log('info', 'learnings ON (session ' + sessionID + ')');
              } else if (name === 'learnings-off') {
                sessionEnabled.set(sessionID, false);
                log('info', 'learnings OFF (session ' + sessionID + ')');
              } else if (name === 'learnings-refresh') {
                sessionManifest.delete(sessionID);
                log('info', 'learnings manifest invalidated (session ' + sessionID + ')');
              }
            }
            await ctx.session.prompt({ ...prompt, sessionID, text: def.template, delivery });
          },
        });
      }
    });

    // Core: append the cached manifest to the system prompt for agent-loop
    // model requests, gated by toggle + off-set + idempotency. V2 event.system
    // is a SystemPart[] ({ type: "text", text }), not V1's string[].
    await ctx.session.hook('context', (event: any) => {
      const system = event && event.system;
      if (!system || !Array.isArray(system)) return;

      const sessionID = event.sessionID;
      if (sessionID && !isOn(sessionID)) return;

      // event.agent is native on the context hook — no chat.message cache or
      // session.get() fallback needed.
      if (isInOffSet(event.agent)) {
        log('debug', 'learnings skipped: agent in off-set (' + (event.agent || '?') + ')');
        return;
      }

      // Idempotency: skip if already injected this request (string or part form).
      for (const part of system) {
        const text = typeof part === 'string' ? part : part && typeof part.text === 'string' ? part.text : '';
        if (text.includes(MARKER)) return;
      }

      // Cache the manifest per session (rebuilt on /learnings-refresh).
      let manifest = sessionID ? sessionManifest.get(sessionID) : undefined;
      if (manifest === undefined) {
        manifest = buildManifest(sessionID || '', cwd);
        if (sessionID) sessionManifest.set(sessionID, manifest); // may be null (no LEARNINGS dir)
      }
      if (!manifest) return; // no LEARNINGS/ → skip silently

      system.push({ type: 'text', text: manifest });
    });
  },

  // ── OpenCode V1 (>= 1.18.29) ───────────────────────────────────────────────
  async server(input: any = {}) {
    return v1Hooks(input);
  },
};
