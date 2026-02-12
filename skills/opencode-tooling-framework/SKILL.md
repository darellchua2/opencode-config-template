---
name: opencode-tooling-framework
description: Framework for creating and managing OpenCode skills and agents
license: Apache-2.0
compatibility: opencode
metadata:
  audience: developers
  workflow: tooling
  type: framework
---

## What I do

Framework for OpenCode configuration management. Extended by tooling-specific skills.

## Extensions

| Skill | Purpose |
|-------|---------|
| `opencode-skill-creation` | Generate new skills |
| `opencode-skill-auditor` | Audit skills for improvements |
| `opencode-skills-maintainer` | Sync agent prompts with skills |
| `opencode-agent-creation` | Generate new agents |

## Workflow Steps

### 1. Skill Creation
- Use `opencode-skill-creation` for new skills
- Structure: frontmatter + What I do + Steps + Related Skills
- Follow naming convention: `{domain}-{type}`
- Test skill loading

### 2. Skill Auditing
- Use `opencode-skill-auditor` for review
- Check for modularization opportunities
- Identify redundant skills
- Suggest improvements

### 3. Agent Creation
- Use `opencode-agent-creation` for new agents
- Define: description, mode, model, prompt
- Set tool restrictions for subagents
- Configure MCP access

### 4. Maintenance
- Use `opencode-skills-maintainer` to sync
- Update agent prompts with new skills
- Keep config.json in sync
- Validate JSON syntax

### 5. Subagent Configuration
- Set `mode: "subagent"` for subagents
- Restrict tools appropriately
- Limit MCP server access
- Filter skills via permissions

## Skill Structure

```markdown
---
name: skill-name
description: Brief description
license: Apache-2.0
compatibility: opencode
metadata:
  audience: developers
  workflow: category
---

## What I do
Brief description of functionality

## Steps
1. Step one
2. Step two

## Related Skills
- related-skill-1
- related-skill-2
```

## Agent Structure

```json
{
  "agent-name": {
    "description": "Description",
    "mode": "subagent",
    "model": "model-id",
    "prompt": "Instructions...",
    "tools": { "read": true, "write": true },
    "mcp": {},
    "permission": { "skill": { "skill-name": "allow" } }
  }
}
```

## Best Practices

1. Keep skills concise (~100-150 lines)
2. Use framework → extension pattern
3. Restrict subagent tools
4. Validate JSON after changes
5. Document tool restrictions

## Related Skills

- `opencode-skill-creation` - Create skills
- `opencode-skill-auditor` - Audit skills
- `opencode-skills-maintainer` - Maintain sync
- `opencode-agent-creation` - Create agents
