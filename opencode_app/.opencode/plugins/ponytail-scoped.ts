// ponytail-scoped.ts — OpenCode wrapper plugin for ponytail with agent-type-aware scoping.
//
// Wraps the vendored ponytail ruleset (./ponytail/) and adds what the stock
// @dietrichgebert/ponytail OpenCode adapter cannot do:
//   1. Agent-type scoping — read-only/research agents skip injection entirely.
//      The stock adapter injects into ALL chats unconditionally; its
//      PONYTAIL_SUBAGENT_MATCHER is Claude-Code-only and a no-op on OpenCode.
//   2. Per-agent default modes via PONYTAIL_AGENT_MODE_MAP (JSON env var).
//
// ── Why .ts (NOT .mjs) ───────────────────────────────────────────────────────
// OpenCode's local-plugin discovery (packages/opencode/src/config/plugin.ts,
// verified identical at git tag v1.18.11) globs `{plugin,plugins}/*.{ts,js}`.
// `.mjs` is NOT matched, so a `.mjs` plugin is silently never discovered — no
// load, no error, no log line. The file MUST be `.ts` or `.js`. We use `.ts`
// because Bun always treats `.ts` as ESM, whereas `.js` here resolves to
// CommonJS (the config-dir package.json has no `"type": "module"`), which would
// reject the ESM `export` syntax. See research/ponytail-load-fix.md.
//
// ── Valid hooks in OpenCode 1.18.11 ──────────────────────────────────────────
// Confirmed against packages/plugin/src/index.ts @ v1.18.11 (Hooks interface).
// All four hooks below are first-class members of that interface:
//   - config(input: Config)                              — register slash commands
//   - "chat.message"(input, output)                       — cache sessionID → agent
//   - "experimental.chat.system.transform"(input, output) — CORE: append ruleset to system[]
//   - "command.execute.before"(input, output)             — persist /ponytail <level> switches
//
// Agent-type resolution:
//   - experimental.chat.system.transform input = { sessionID?, model }
//   - chat.message input = { sessionID, agent?, ... }  → cache sessionID→agent
//   - cache miss + sessionID present → client.session.get() fallback
//   - agent unresolvable → inject (safe default; off-set only EXCLUDES known read-only agents)
//
// Env vars:
//   PONYTAIL_DEFAULT_MODE   — lite|full|ultra|off  (default: full)
//   PONYTAIL_SUBAGENT_OFF   — regex of agent names to EXCLUDE (default: 7 read-only/research agents)
//   PONYTAIL_AGENT_MODE_MAP — JSON { "<agent>": "<mode>" } per-agent overrides
//
// Vendored from @dietrichgebert/ponytail v4.8.4 (MIT). See ./ponytail/../ATTRIBUTION.md.
// The stock npm plugin MUST NOT be in opencode.json plugin array (double-injection guard).

import { createRequire } from 'module';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const require = createRequire(import.meta.url);
const {
  getPonytailInstructions,
  normalizeMode,
  DEFAULT_MODE,
} = require('./ponytail/instructions.cjs');

// ── Configuration (read once at load) ──────────────────────────────────────────

const PONYTAIL_DEFAULT_MODE = normalizeMode(process.env.PONYTAIL_DEFAULT_MODE) || DEFAULT_MODE;

// Default off-set: agents that should NOT receive Ponytail injection —
// read-only/research agents (Ponytail N/A) + non-coding agents (docs,
// business, integrations, vision) where the lazy-code ruleset is irrelevant
// and only adds context weight. Coding agents stay in the injection set.
const DEFAULT_OFF_PATTERN =
  '^(explore|general|autoresearch-research-subagent|explorer-subagent|' +
  'requirements-specialist-subagent|discovery-specialist-subagent|' +
  'technical-design-specialist-subagent|' +
  'coverage-subagent|documentation-subagent|docx-creation-subagent|' +
  'pptx-specialist-subagent|xlsx-specialist-subagent|office-document-primary-agent|' +
  'startup-ceo-subagent|startup-founder-primary-agent|' +
  'google-mcp-specialist-subagent|microsoft-m365-specialist-subagent|' +
  'image-analyzer-subagent)$';

function compileOffRegex() {
  const pattern = process.env.PONYTAIL_SUBAGENT_OFF || DEFAULT_OFF_PATTERN;
  try {
    return new RegExp(pattern, 'i');
  } catch (_) {
    return new RegExp(DEFAULT_OFF_PATTERN, 'i');
  }
}
const OFF_REGEX = compileOffRegex();

// Per-agent mode overrides: { "build": "full", "code-review-subagent": "lite" }
let AGENT_MODE_MAP = {};
if (process.env.PONYTAIL_AGENT_MODE_MAP) {
  try {
    const parsed = JSON.parse(process.env.PONYTAIL_AGENT_MODE_MAP);
    if (parsed && typeof parsed === 'object' && !Array.isArray(parsed)) {
      AGENT_MODE_MAP = parsed;
    }
  } catch (_) {
    // invalid JSON → silently fall back to empty map (default mode governs)
  }
}

// ── Per-session state ───────────────────────────────────────────────────────────

const sessionAgent = new Map(); // sessionID → agent (populated by chat.message)
const sessionMode = new Map();  // sessionID → mode (overridden via /ponytail commands)

function resolveMode(sessionID, agent) {
  // 1. Per-session override (from /ponytail <level> command) — highest priority
  if (sessionID && sessionMode.has(sessionID)) {
    return sessionMode.get(sessionID);
  }
  // 2. Per-agent map
  if (agent && AGENT_MODE_MAP[agent]) {
    const m = normalizeMode(AGENT_MODE_MAP[agent]);
    if (m) return m;
  }
  // 3. Global default
  return PONYTAIL_DEFAULT_MODE;
}

function isInOffSet(agent) {
  if (!agent) return false;
  return OFF_REGEX.test(agent);
}

// ── Command definitions (embedded so only plugins/ needs deploying) ───────────

const COMMANDS = {
  ponytail: {
    description: 'Ponytail: report or set lazy-code intensity. Usage: /ponytail [lite|full|ultra|off]',
    template:
      'You are running under ponytail. If the user gave a level, confirm the switch in one line. ' +
      'If no level was given, report the current mode in one line and what it means. Do not output code.',
    agent: 'build',
  },
  'ponytail-help': {
    description: 'Ponytail: quick command reference.',
    template:
      'List the ponytail slash commands and one line each on what they do: ' +
      '/ponytail [lite|full|ultra|off], /ponytail-help, /ponytail-lite, /ponytail-full, ' +
      '/ponytail-ultra, /ponytail-off. Format as a short list. Do not output code.',
    agent: 'build',
  },
  'ponytail-lite': {
    description: 'Ponytail: switch to lite intensity (name the lazier alternative, user picks).',
    template: 'Ponytail mode is now lite. Confirm in one line. Do not output code.',
    agent: 'build',
  },
  'ponytail-full': {
    description: 'Ponytail: switch to full intensity (the ladder enforced, default).',
    template: 'Ponytail mode is now full. Confirm in one line. Do not output code.',
    agent: 'build',
  },
  'ponytail-ultra': {
    description: 'Ponytail: switch to ultra intensity (YAGNI extremist, deletion before addition).',
    template: 'Ponytail mode is now ultra. Confirm in one line. Do not output code.',
    agent: 'build',
  },
  'ponytail-off': {
    description: 'Ponytail: turn off lazy-code injection for this session.',
    template: 'Ponytail is now off for this session. Confirm in one line. Do not output code.',
    agent: 'build',
  },
};

const PONYTAIL_MARKER = 'PONYTAIL MODE ACTIVE';

// ── Plugin ──────────────────────────────────────────────────────────────────────
//
// NAMED export (matches the documented plugin pattern). OpenCode's plugin loader
// (packages/opencode/src/plugin/index.ts → getLegacyPlugins) iterates the module's
// exports (Object.values(mod)), so a named export is discovered and invoked as
// `(input, options) => Promise<Hooks>`. A default-export function also works via
// the same path, but named is the documented form. `client` is the only context
// field this plugin uses (PluginInput also exposes project/directory/worktree/$).

export const PonytailScoped = async ({ client }: any = {}) => {
  const log = (level: string, message: string) => {
    try {
      client && client.app && client.app.log({ body: { service: 'ponytail-scoped', level, message } });
    } catch (_) {}
  };

  log('info', 'ponytail-scoped loaded — default mode: ' + PONYTAIL_DEFAULT_MODE);

  return {
    // Register the 6 commands (non-destructive merge — preserves existing commands).
    config: async (config: any) => {
      if (!config.command) config.command = {};
      for (const [name, def] of Object.entries(COMMANDS)) {
        // Never overwrite a user-defined command of the same name.
        if (!config.command[name]) config.command[name] = def;
      }
    },

    // Cache sessionID → agent so the transform hook can scope by agent type.
    // chat.message fires before experimental.chat.system.transform on a normal turn.
    'chat.message': async (input: any) => {
      if (input && input.sessionID && input.agent) {
        sessionAgent.set(input.sessionID, input.agent);
      }
    },

    // Core: append the mode-filtered ruleset to the system prompt, scoped by agent type.
    'experimental.chat.system.transform': async (input: any, output: any) => {
      if (!output || !Array.isArray(output.system)) return;

      const sessionID = input && input.sessionID;
      let agent = sessionID ? sessionAgent.get(sessionID) : undefined;

      // Fallback: cache miss → look up the session via the SDK.
      if (!agent && sessionID && client && client.session && client.session.get) {
        try {
          const res = await client.session.get({ path: { id: sessionID } });
          const data = res && res.data;
          agent = (data && (data.agent || data.agentID || data.agentId)) || undefined;
          if (agent) sessionAgent.set(sessionID, agent);
        } catch (_) {
          // session lookup failed — proceed with agent unknown (will inject, safe default)
        }
      }

      const mode = resolveMode(sessionID, agent);
      if (mode === 'off') return;

      if (isInOffSet(agent)) {
        log('debug', 'ponytail skipped: agent in off-set (' + (agent || '?') + ')');
        return;
      }

      const instructions = getPonytailInstructions(mode);
      if (!instructions) return;

      // Idempotency / double-injection guard: skip if already injected this turn.
      const last = output.system.length > 0 ? output.system[output.system.length - 1] : '';
      if (typeof last === 'string' && last.includes(PONYTAIL_MARKER)) return;
      for (const entry of output.system) {
        if (typeof entry === 'string' && entry.includes(PONYTAIL_MARKER)) return;
      }

      if (output.system.length > 0) {
        output.system[output.system.length - 1] =
          String(output.system[output.system.length - 1]) + '\n\n' + instructions;
      } else {
        output.system.push(instructions);
      }
    },

    // Persist /ponytail <level> and /ponytail-<level> mode switches per session.
    'command.execute.before': async (input: any) => {
      if (!input) return;
      const cmd = input.command || '';
      const sessionID = input.sessionID;
      let mode: string | null = null;

      if (cmd === 'ponytail') {
        // /ponytail [level] — argument drives the switch; no arg = status query (no-op here)
        const arg = String(input.arguments || '').trim().toLowerCase();
        if (arg) mode = normalizeMode(arg);
      } else if (cmd.startsWith('ponytail-')) {
        mode = normalizeMode(cmd.replace('ponytail-', ''));
      }

      if (mode && sessionID) {
        sessionMode.set(sessionID, mode);
        const agent = sessionAgent.get(sessionID) || '?';
        log('info', 'ponytail ' + mode + ' (session ' + sessionID + ', agent ' + agent + ')');
      }
    },
  };
};
