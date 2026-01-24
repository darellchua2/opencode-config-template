---
name: opencode-skill-creation
description: Generate OpenCode skills following official documentation best practices
license: Apache-2.0
compatibility: opencode
metadata:
  audience: developers
  workflow: skill-development
---

## What I do

- Guide you through creating a new OpenCode skill by prompting for required information
- Generate SKILL.md files with proper YAML frontmatter following official documentation
- Validate skill names against naming rules (1-64 chars, lowercase alphanumeric with single hyphens)
- Create directory structure at `.opencode/skill/<name>/` or appropriate location
- Ensure description is 1-1024 characters and specific enough for agents to choose correctly
- Follow the skill structure: "What I do" and "When to use me" sections

## When to use me

Use this when:
- You want to create a new OpenCode skill without manually formatting SKILL.md
- You need to ensure your skill follows official documentation standards
- You want to avoid repetitive setup when creating multiple skills

Ask clarifying questions about the skill's purpose, target audience, and usage scenarios.