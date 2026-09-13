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
// OpenCode's local-plugin discovery globs `{plugin,plugins}/*.{ts,js}` (V1:
// packages/opencode/src/config/plugin.ts @ v1.18.11; V2 keeps glob discovery of
// `.opencode/plugins/`). `.mjs` is NOT matched. `.js` in the config dir resolves
// to CommonJS (no `"type": "module"` there), which would reject ESM `export`.
// See research/ponytail-load-fix.md.
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
//   - ctx.command.transform — registers the 6 /ponytail* commands; the former
//     command.execute.before mode-switch persistence now runs inside each
//     command's execute(), before the confirmation prompt. /ponytail [level]
//     reads the level from prompt.text (V1 delivered it via input.arguments).
//   - ctx.session.hook("context") — CORE: append the mode-filtered ruleset to
//     event.system. event.agent is native on this hook, so the V1 chat.message
//     sessionID→agent cache + session.get() fallback are V1-only machinery.
//
// ── V1 hooks (returned by server(), per the V1 plugin API @ 1.18.11) ────────
//   - config(input: Config)                              — register slash commands
//   - "chat.message"(input, output)                       — cache sessionID → agent
//   - "experimental.chat.system.transform"(input, output) — CORE: append ruleset to system[]
//   - "command.execute.before"(input, output)             — persist /ponytail <level> switches
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

// Default off-set: agents that should NOT receive runtime Ponytail injection —
// read-only/research agents (Ponytail N/A), non-coding agents (docs, business,
// integrations, vision), and the 8 high-value coding agents that carry a baked-in
// role-tuned lens (see each agent's "Ponytail <X> lens" section + provenance tag).
// All other coding/meta agents get runtime injection. Grep 'Ponytail lens derived'
// to find the 8 baked agents on re-vendor.
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

const sessionAgent = new Map(); // sessionID → agent (V1 path only: populated by chat.message)
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

// ── V1 plugin body (returned by server()) ───────────────────────────────────────
//
// Verbatim port of the original V1 named-export plugin. `client` is the only
// context field this path uses (PluginInput also exposes project/directory).

const v1Hooks = async ({ client }: any = {}) => {
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

// ── Dual entrypoint: V2 setup() + V1 server() ──────────────────────────────────

export default {
  id: 'ponytail-scoped',

  // ── OpenCode V2 ────────────────────────────────────────────────────────────
  async setup(ctx: any) {
    // V2 plugin context has no documented app.log; console is the sanctioned
    // channel in the V2 plugin examples.
    const log = (level: string, message: string) => {
      try {
        console.log(`[ponytail-scoped] ${level}: ${message}`);
      } catch (_) {}
    };

    log('info', 'ponytail-scoped loaded — default mode: ' + PONYTAIL_DEFAULT_MODE);

    // Register the 6 commands; the plugin now OWNS them, so the former
    // command.execute.before mode-switch persistence runs inside execute(),
    // before the same confirmation prompt the V1 template submitted. (The V1
    // `agent: "build"` pin has no documented V2 CommandDefinition equivalent —
    // commands run in the session's active agent.)
    await ctx.command.transform((editor: any) => {
      for (const [name, def] of Object.entries(COMMANDS)) {
        editor.add({
          name,
          description: def.description,
          execute: async ({ sessionID, prompt, delivery }: any = {}) => {
            // Formerly command.execute.before: persist the mode switch.
            // /ponytail [level]: the level arrives in prompt.text (V1 used
            // input.arguments); normalizeMode() rejects invalid values, so a
            // missing/garbled argument degrades to the status query.
            let mode: string | null = null;
            if (name === 'ponytail') {
              const arg = String((prompt && prompt.text) || '').trim().toLowerCase();
              if (arg) mode = normalizeMode(arg);
            } else if (name.startsWith('ponytail-')) {
              mode = normalizeMode(name.replace('ponytail-', ''));
            }

            if (mode && sessionID) {
              sessionMode.set(sessionID, mode);
              log('info', 'ponytail ' + mode + ' (session ' + sessionID + ')');
            }

            await ctx.session.prompt({ ...prompt, sessionID, text: def.template, delivery });
          },
        });
      }
    });

    // Core: append the mode-filtered ruleset to the system prompt for
    // agent-loop model requests, scoped by agent type. V2 event.system is a
    // SystemPart[] ({ type: "text", text }), not V1's string[].
    await ctx.session.hook('context', (event: any) => {
      const system = event && event.system;
      if (!system || !Array.isArray(system)) return;

      const sessionID = event.sessionID;
      // event.agent is native on the context hook — no chat.message cache or
      // session.get() fallback needed.
      const agent = event.agent;

      const mode = resolveMode(sessionID, agent);
      if (mode === 'off') return;

      if (isInOffSet(agent)) {
        log('debug', 'ponytail skipped: agent in off-set (' + (agent || '?') + ')');
        return;
      }

      const instructions = getPonytailInstructions(mode);
      if (!instructions) return;

      // Idempotency / double-injection guard: skip if already injected this
      // request (string or SystemPart form).
      for (const part of system) {
        const text = typeof part === 'string' ? part : part && typeof part.text === 'string' ? part.text : '';
        if (text.includes(PONYTAIL_MARKER)) return;
      }

      system.push({ type: 'text', text: instructions });
    });
  },

  // ── OpenCode V1 (>= 1.18.29) ───────────────────────────────────────────────
  async server(input: any = {}) {
    return v1Hooks(input);
  },
};
