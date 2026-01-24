# Plan: Implement Next.js 16 Unit Test Creator Skill

## Overview
Create a new OpenCode skill for generating comprehensive unit tests for Next.js 16 applications, following industry best practices and leveraging modern testing frameworks.

## Issue Reference
- Issue: #24
- URL: https://github.com/darellchua2/opencode-config-template/issues/24
- Labels: enhancement

## Files to Create
1. `skills/nextjs-unit-test-creator/SKILL.md` - Main skill definition
2. `skills/nextjs-unit-test-creator/examples/` - Example test files
3. `skills/nextjs-unit-test-creator/templates/` - Test templates

## Approach
1. **Analyze Existing Skills**: Review `test-generator-framework` and `python-pytest-creator` for patterns
2. **Define Skill Structure**: Create SKILL.md with proper frontmatter and documentation
3. **Implement Test Generators**: Create logic for:
   - App Router components (page.tsx, layout.tsx, loading.tsx, error.tsx)
   - Server Components testing patterns
   - Client Components testing patterns
   - API routes testing
   - Server Actions testing
4. **Add Examples**: Include comprehensive examples for each component type
5. **Document Patterns**: Document common testing patterns and edge cases

## Success Criteria
- [ ] SKILL.md follows the required frontmatter format
- [ ] Skill can generate valid tests for App Router components
- [ ] Generated tests use React Testing Library correctly
- [ ] Skill handles Server Components with appropriate mocking
- [ ] Skill generates tests for API routes
- [ ] Examples demonstrate all major patterns
- [ ] Documentation covers edge cases and best practices
- [ ] All generated tests are syntactically valid
- [ ] Skill integrates with test-generator-framework base

## Testing Frameworks to Support
- **React Testing Library** - Component testing
- **Vitest** - Test runner (Next.js 16 default)
- **@testing-library/react** - React component utilities
- **@testing-library/user-event** - User interaction testing
- **msw** (Mock Service Worker) - API mocking

## Key Patterns to Implement

### Server Component Testing
```typescript
import { render } from '@testing-library/react'
import Page from './page'

describe('Server Component', () => {
  it('renders correctly', async () => {
    // Test pattern
  })
})
```

### Client Component Testing
```typescript
import { render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'

describe('Client Component', () => {
  it('handles user interactions', async () => {
    // Test pattern
  })
})
```

### API Route Testing
```typescript
import { POST } from './route'
import { createMocks } from 'node-mocks-http'

describe('API Route', () => {
  it('handles POST requests', async () => {
    // Test pattern
  })
})
```

## Next.js 16 Specific Considerations
- App Router architecture
- Server Components vs Client Components
- Suspense boundaries and loading states
- Error boundaries and error handling
- Server Actions testing
- Route parameters and dynamic routes
- Metadata API testing

## Notes
- Focus on Next.js 16 specific patterns
- Maintain compatibility with existing test-generator-framework
- Provide clear migration examples for older Next.js versions
- Include TypeScript type safety considerations
- Document performance testing considerations
