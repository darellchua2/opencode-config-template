---
name: typescript-dry-principle
description: Apply DRY principle to eliminate code duplication in TypeScript projects with comprehensive refactoring patterns
license: Apache-2.0
compatibility: opencode
metadata:
  audience: developers
  workflow: code-refactoring
---

## What I do
- Scan TypeScript files to identify repeated code patterns, logic, types, and configurations
- Detect common anti-patterns: duplicate logic, repeated type definitions, copy-pasted code blocks
- Extract common logic into reusable utility functions and modules
- Merge duplicate types into shared interfaces and type utilities
- Build type-safe reusable components using TypeScript generics
- Restructure code into logical directories (types/, utils/, constants/, hooks/, services/)
- Update files to import from shared modules instead of duplicating code
- Ensure code compiles and tests pass after refactoring

## When to use me

Use when:
- Similar code blocks across multiple TypeScript files
- Copy-pasting code between modules or components
- Type definitions are duplicated or repeated across files
- Business logic appears in multiple places with slight variations
- Configuration values are scattered across multiple files
- Tests contain repeated setup/teardown logic
- Improving code maintainability and reducing technical debt
- Preparing for code review to address technical debt
- Setting up new TypeScript project with proper code organization

## Prerequisites

- TypeScript project with source code (.ts, .tsx files)
- File permissions to read and modify TypeScript files
- TypeScript compiler installed and configured
- (Optional) Test suite to verify refactoring

## Steps

### Step 1: Analyze Codebase for Duplication Patterns

```bash
find . -name "*.ts" -o -name "*.tsx" | grep -v node_modules | grep -v dist
```

**Common duplication indicators**:
- Similar function names with variations (getUser, getUserData, getUserInfo)
- Nearly identical code blocks with slight variations
- Same type interfaces defined in multiple files
- Repeated validation or transformation logic
- Similar component structures with different props

### Step 2: Categorize Duplication Types

| Duplication Type | Description | Refactoring Approach |
|------------------|-------------|----------------------|
| **Logic Duplication** | Same business logic in multiple functions | Extract to shared utility functions |
| **Type Duplication** | Duplicate interfaces/types across files | Consolidate into shared types/ directory |
| **Component Duplication** | Similar components with minor variations | Create generic components using TypeScript generics |
| **Configuration Duplication** | Same config values in multiple files | Create constants/ directory |
| **API Call Duplication** | Repeated API calls with similar logic | Create API service layer |
| **Validation Duplication** | Same validation logic in multiple places | Create shared validators |
| **Template Duplication** | Similar code patterns that could be templated | Create higher-order functions or components |

### Step 3: Extract Common Logic to Utility Functions

**Example: Data Transformation Logic**

Before (duplicated):
```typescript
function formatUserName(firstName: string, lastName: string): string {
  return `${firstName.charAt(0).toUpperCase()}${firstName.slice(1).toLowerCase()} ${lastName.charAt(0).toUpperCase()}${lastName.slice(1).toLowerCase()}`
}
```

After (refactored to utils/stringUtils.ts):
```typescript
export function capitalizeFirstLetter(word: string): string {
  if (!word) return ''
  return word.charAt(0).toUpperCase() + word.slice(1).toLowerCase()
}

export function formatFullName(firstName: string, lastName: string): string {
  return `${capitalizeFirstLetter(firstName)} ${capitalizeFirstLetter(lastName)}`
}
```

### Step 4: Create API Service Layer

**Before (duplicated API calls)**:
```typescript
async function fetchUser(id: string): Promise<User> {
  const response = await fetch(`/api/users/${id}`)
  if (!response.ok) throw new Error('Failed to fetch user')
  return response.json()
}
```

After (refactored to services/apiService.ts):
```typescript
class ApiService {
  private baseUrl: string = '/api'

  async fetch<T>(endpoint: string): Promise<T> {
    const response = await fetch(`${this.baseUrl}${endpoint}`)
    if (!response.ok) throw new Error(`Failed to fetch ${endpoint}`)
    return response.json()
  }

  async getUser(id: string): Promise<User> {
    return this.fetch<User>(`/users/${id}`)
  }

  async getUserProfile(id: string): Promise<UserProfile> {
    return this.fetch<UserProfile>(`/users/${id}/profile`)
  }
}
```

### Step 5: Consolidate Type Definitions

Merge duplicate type definitions into shared types/ directory:
```typescript
// types/common.ts
export interface User {
  id: string
  name: string
  email: string
}

export interface ApiResponse<T> {
  data: T
  success: boolean
}
```

### Step 6: Create Generic Components

**Before (duplicated components)**:
```typescript
function UserCard({ user }: { user: User }) { ... }
function UserProfileCard({ user }: { user: UserProfile }) { ... }
```

After (generic component using generics):
```typescript
function Card<T extends { id: string }>({ item }: { item: T }) { ... }
function UserCard({ user }: { user: User }) {
  return <Card item={user} />
}
```

## Best Practices

- Extract constants to a constants/ directory
- Create reusable utility functions for common logic
- Use TypeScript generics for type-safe generic components
- Organize code into logical directories (types/, utils/, constants/, services/)
- Keep functions small and focused (single responsibility)
- Use composition over inheritance
- Leverage TypeScript type system effectively
- Use descriptive variable and function names
- Write tests for extracted utilities
- Ensure all imports use shared modules

## Common Issues

### Refactoring Breaks Tests
**Solution**: Run test suite after each refactoring, update tests to import from new utilities.

### Type Errors After Refactoring
**Solution**: Update type definitions, ensure proper imports, use TypeScript generics correctly.

### Circular Dependencies
**Solution**: Use proper module structure, avoid circular imports with barrel exports.

## References

- TypeScript Handbook: https://www.typescriptlang.org/docs/handbook/intro.html
- Refactoring Patterns: https://refactoring.guru/
