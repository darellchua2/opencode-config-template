---
name: codegraph-setup-skill
description: Initialize and manage CodeGraph — a pre-indexed code knowledge graph MCP server. Use when setting up CodeGraph in a new project, re-indexing after major changes, checking index status, or troubleshooting. Triggers on "codegraph init", "codegraph setup", "initialize codegraph", "reindex codegraph", "codegraph status", or when a project lacks a `.codegraph/` directory and the agent needs code exploration.
---

# CodeGraph Setup Skill

CodeGraph builds a local SQLite knowledge graph of your codebase using tree-sitter. It provides MCP tools that let agents query symbol relationships, call graphs, and code structure instantly instead of scanning files with grep/glob/Read.

## Prerequisites

- Node.js v18+ (required for npx)
- No API keys needed — 100% local

## Setup Workflow

### Step 1: Initialize

Run in the project root directory:

```bash
npx @colbymchenry/codegraph init -i
```

This:
- Detects languages in the project
- Creates `.codegraph/` directory with `config.json` and SQLite database
- Indexes all source files into the knowledge graph
- Takes 5-60 seconds depending on project size

### Step 2: Add to .gitignore

Append `.codegraph/` to the project's `.gitignore`:

```bash
echo ".codegraph/" >> .gitignore
```

The index is local-only — it should not be committed.

### Step 3: Verify

```bash
npx @colbymchenry/codegraph status
```

Expected output:
- Backend: native (preferred) or wasm (slower fallback)
- File count, node count, edge count
- Watcher status

## Post-Setup

After initialization, CodeGraph works automatically:

- **File watcher** auto-syncs changes as you code (2-second debounce)
- **MCP tools** are available to all agents when `.codegraph/` exists
- **No manual re-indexing needed** for normal development

## MCP Tools Available After Setup

| Tool | Purpose | Session |
|------|---------|---------|
| `codegraph_search` | Find symbols by name | Main session |
| `codegraph_callers` | Find what calls a function | Main session |
| `codegraph_callees` | Find what a function calls | Main session |
| `codegraph_impact` | Analyze change impact radius | Main session |
| `codegraph_node` | Get symbol details | Main session |
| `codegraph_files` | Get indexed file structure | Main session |
| `codegraph_status` | Check index health | Main session |
| `codegraph_explore` | Full exploration with source code | Explore agents only |
| `codegraph_context` | Build context for a task | Explore agents only |

## CLI Reference

```bash
# Initialize and index
npx @colbymchenry/codegraph init -i

# Full re-index (after major structural changes)
npx @colbymchenry/codegraph index --force

# Incremental sync
npx @colbymchenry/codegraph sync

# Check status
npx @colbymchenry/codegraph status

# Search symbols
npx @colbymchenry/codegraph query "UserService"

# Find affected test files
npx @colbymchenry/codegraph affected src/utils.ts src/api.ts

# Remove CodeGraph from project
npx @colbymchenry/codegraph uninit --force
```

## Troubleshooting

### "Backend: wasm" (slow)

The WASM fallback is 5-10x slower. Fix by installing native build tools:

```bash
# Linux (Debian/Ubuntu)
sudo apt install build-essential python3 make

# macOS
xcode-select --install

# Then rebuild
npm rebuild better-sqlite3
```

### "database is locked"

Happens during indexing with WASM backend. Fix by switching to native backend (see above).

### Missing symbols after code changes

Wait 2-3 seconds for the file watcher to sync, or run `npx @colbymchenry/codegraph sync` manually.

### Large projects slow to index

Check `.codegraph/config.json` and add exclusions:

```json
{
  "exclude": [
    "node_modules/**",
    "dist/**",
    "build/**",
    "vendor/**",
    "*.min.js",
    "*.generated.*"
  ]
}
```

## Supported Languages

TypeScript, JavaScript, Python, Go, Rust, Java, C#, PHP, Ruby, C, C++, Swift, Kotlin, Dart, Svelte, Liquid, Pascal/Delphi, Scala, Vue (19+ languages).
