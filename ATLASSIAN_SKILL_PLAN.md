# Implementation Plan: Atlassian Skill for OpenCode Config Repo

## Goal
Add Atlassian (Jira + Confluence) support to your OpenCode config repo using a
Skill-only approach with OAuth 2.0 auto-refresh via `.bashrc` — no MCP server required.

---

## Repo Structure Changes

```
your-opencode-repo/
├── dotfiles/
│   └── .bashrc                          ← MODIFY: add atlassian_* functions
├── skills/
│   └── atlassian/
│       └── SKILL.md                     ← CREATE: Jira + Confluence API reference
└── opencode.json                        ← NO CHANGE needed (skill-only approach)
```

---

## Phase 1 — Shell Auth Setup

**File:** `dotfiles/.bashrc`

### 1.1 Add OAuth credentials block
At the top of the Atlassian section, define your app credentials as variables.
Keep secrets out of the repo — reference them from a local `.env` or use a
secrets manager (e.g. 1Password CLI, `pass`).

```bash
# Load secrets from a local file NOT committed to the repo
[ -f "$HOME/.atlassian.env" ] && source "$HOME/.atlassian.env"
```

Your local `~/.atlassian.env` (gitignored, lives only on your machine):
```bash
export ATLASSIAN_CLIENT_ID="your_client_id"
export ATLASSIAN_CLIENT_SECRET="your_client_secret"
export ATLASSIAN_DOMAIN="your-domain.atlassian.net"
```

### 1.2 Paste the atlassian_* functions
Add the full `atlassian_login`, `atlassian_token`, `atlassian_refresh`,
`atlassian_status`, and `atlassian_logout` functions from the generated
`atlassian_oauth.bashrc` file.

### 1.3 Add .gitignore entry
Make sure token and env files are never committed:
```
.atlassian.env
.atlassian_tokens.json
```

### Checklist
- [ ] `dotfiles/.bashrc` updated with atlassian_* functions
- [ ] `~/.atlassian.env` created locally with real credentials
- [ ] `.gitignore` excludes `.atlassian.env` and `.atlassian_tokens.json`
- [ ] `source ~/.bashrc` and run `atlassian_login` to verify the flow works
- [ ] `atlassian_status` shows "Logged in" with a valid expiry

---

## Phase 2 — Atlassian Skill

**File:** `skills/atlassian/SKILL.md`

This is the on-demand reference the agent loads when it needs to call Atlassian APIs.
Structure it in two sections: Jira and Confluence.

### 2.1 Frontmatter
```yaml
---
name: atlassian
description: >
  Use this skill when working with Jira issues or Confluence pages.
  Covers searching, creating, and updating content via the REST API.
---
```

### 2.2 Auth section
Tell the agent exactly how to get a token:
```markdown
## Auth
Run the following bash command to get a fresh access token:

  TOKEN=$(atlassian_token)

Use it in every request:
  Authorization: Bearer $TOKEN

Base domain is set in $ATLASSIAN_DOMAIN.
```

### 2.3 Jira section
Cover the endpoints you actually use day-to-day:

```markdown
## Jira

Base URL: https://$ATLASSIAN_DOMAIN/rest/api/3

### Search issues (JQL)
GET /search?jql=<query>&maxResults=20

Common JQL examples:
  assignee = currentUser() AND status != Done
  project = ENG AND sprint in openSprints()
  issueKey in (ENG-123, ENG-456)

### Get a single issue
GET /issue/{issueKey}

### Create an issue
POST /issue
Body: { project, summary, issuetype, description (ADF format) }

### Update an issue
PUT /issue/{issueKey}
Body: { fields: { summary, status, assignee, ... } }

### Add a comment
POST /issue/{issueKey}/comment
Body: { body: { type: "doc", version: 1, content: [...] } }

### Transition an issue (change status)
POST /issue/{issueKey}/transitions
- First GET /issue/{issueKey}/transitions to find the transition ID
- Then POST with { transition: { id: "<id>" } }
```

### 2.4 Confluence section
```markdown
## Confluence

Base URL: https://$ATLASSIAN_DOMAIN/wiki/rest/api

### Get a page by ID
GET /content/{pageId}?expand=body.storage,version

### Search pages (CQL)
GET /content/search?cql=<query>

Common CQL examples:
  space = ENG AND title ~ "Architecture"
  ancestor = <pageId>

### Create a page
POST /content
Body: {
  type: "page",
  title: "Page Title",
  space: { key: "SPACE" },
  body: { storage: { value: "<p>HTML content</p>", representation: "storage" } }
}

### Update a page
PUT /content/{pageId}
Body: { version: { number: <current+1> }, title, body }
- Always increment version.number or the update will fail

### Get page children
GET /content/{pageId}/child/page
```

### 2.5 Example bash calls
Give the agent copy-paste-ready curl patterns:
```markdown
## Example Calls

# Search my open Jira tickets
TOKEN=$(atlassian_token)
curl -s -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  "https://$ATLASSIAN_DOMAIN/rest/api/3/search?jql=assignee%3DcurrentUser()%20AND%20status!%3DDone"

# Get a Confluence page
TOKEN=$(atlassian_token)
curl -s -H "Authorization: Bearer $TOKEN" \
  "https://$ATLASSIAN_DOMAIN/wiki/rest/api/content/{pageId}?expand=body.storage"
```

### Checklist
- [ ] `skills/atlassian/SKILL.md` created with frontmatter
- [ ] Auth section references `atlassian_token` bash function
- [ ] Jira endpoints documented (search, get, create, update, comment, transition)
- [ ] Confluence endpoints documented (get, search, create, update)
- [ ] Example curl calls included
- [ ] Test by prompting: `use atlassian skill to find my open Jira tickets`

---

## Phase 3 — Wire It Into Your Workflow

### 3.1 Add a rule to AGENTS.md (optional but recommended)
If you want the agent to know about the skill without being prompted:

```markdown
## Atlassian
When asked about Jira issues or Confluence pages, load and use the `atlassian` skill.
Always run `atlassian_token` to get a fresh token before making API calls.
```

### 3.2 Scope the skill to specific agents (optional)
If you only want Atlassian available in certain agents, note this in your
`opencode.json` agent config using tool/skill restrictions per agent.

### 3.3 Document the first-time setup in your repo README
Add a section so you (or teammates) know what to do on a fresh machine:

```markdown
## Atlassian Setup
1. Create ~/.atlassian.env with your OAuth app credentials
2. source ~/.bashrc
3. Run: atlassian_login
4. Verify: atlassian_status
```

### Checklist
- [ ] AGENTS.md updated with Atlassian rule (if desired)
- [ ] README documents first-time setup steps
- [ ] Tested end-to-end: open OpenCode, prompt it to use the atlassian skill

---

## Phase 4 — Ongoing Maintenance

| Task | When |
|---|---|
| Re-run `atlassian_login` | If refresh token expires (~90 days) |
| Rotate `ATLASSIAN_CLIENT_SECRET` | Per your org's security policy |
| Update skill endpoints | When Atlassian API changes |
| Add new JQL/CQL examples | As you discover useful queries |

---

## Summary

| Phase | Files Changed | Effort |
|---|---|---|
| 1 — Shell Auth | `dotfiles/.bashrc`, `~/.atlassian.env` (local) | ~15 min |
| 2 — Skill | `skills/atlassian/SKILL.md` | ~20 min |
| 3 — Wire Up | `AGENTS.md`, `README.md` | ~10 min |
| 4 — Maintenance | Ongoing | Minimal |

**Total estimated setup time: ~45 minutes**
