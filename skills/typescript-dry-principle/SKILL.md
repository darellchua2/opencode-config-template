---
name: typescript-dry-principle
description: Apply DRY principle to eliminate code duplication in TypeScript projects
license: Apache-2.0
compatibility: opencode
metadata:
  audience: developers
  workflow: code-refactoring
---

## What I do

- Identify repeated code patterns, logic, types, and configurations across TypeScript files
- Extract common logic into reusable utility functions and modules
- Consolidate duplicate type definitions into shared interfaces and type utilities
- Create generic solutions for type-safe reusable code using TypeScript generics
- Organize extracted code into logical folder structures (types/, utils/, constants/, hooks/, services/)
- Replace duplicated code with imports from shared modules

## When to use me

Use this when:
- You notice similar code blocks across multiple files
- You're copy-pasting code between modules
- Type definitions are duplicated or repeated
- Business logic appears in multiple places
- Configuration values are scattered across files
- Tests contain repeated setup/teardown logic

Ask clarifying questions if the scope of refactoring is unclear.