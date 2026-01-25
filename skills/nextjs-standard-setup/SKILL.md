---
name: nextjs-standard-setup
description: Create standardized Next.js 16 demo applications with shadcn, Tailwind v4, and specific folder structure using Tekk-prefixed components and proper documentation standards
license: Apache-2.0
compatibility: opencode
metadata:
  audience: developers
  workflow: project-setup
---

## What I do

I create a standardized Next.js 16 application with:

1. **Next.js 16 Setup**: Install and configure the latest Next.js 16
2. **shadcn Integration**: Install and configure shadcn@latest with TypeScript
3. **Tailwind v4 Configuration**: Set up Tailwind CSS v4 with proper configuration
4. **Folder Structure**: Create standardized src/ directory structure
5. **Component Architecture**: Set up Tekk-prefixed abstraction layer with **named exports**
6. **Export Patterns**: Enforce named exports for all custom components with index.ts re-exports
7. **Documentation Standards**: Generate components with proper JSDoc docstrings
8. **Best Practices**: Ensure Next.js best practices (next/image, proper imports, etc.)

**Data Flow Architecture**:
```
page.tsx (server) → page-containers (client state) → sections/custom-components (stateless)
```

**Export Pattern Philosophy**:
- All custom components use **named exports** for better tree-shaking
- Library components (shadcn/ui) maintain their default exports
- Index.ts files provide clean import paths and enable named imports

## When to use me

Use this skill when:
- Starting a new Next.js demo application
- Need standardized project structure for consistency
- Want to ensure best practices from the start
- Creating maintainable component architecture
- Setting up projects with Tekk-prefixed naming conventions
- Need proper TypeScript and documentation standards

## Prerequisites

- Node.js 18+ installed
- npm/yarn/pnpm package manager
- Git repository initialized (optional but recommended)
- Terminal/shell access
- Internet connection for package installation

## Steps

### Step 1: Initialize Next.js 16 Project

Create a new Next.js 16 application with TypeScript:
```bash
# Create Next.js 16 app
npx create-next-app@latest . --typescript --tailwind --eslint --app --src-dir --import-alias "@/*"

# Install latest Next.js 16
npm install next@latest react@latest react-dom@latest
```

### Step 2: Configure Tailwind v4

Update to Tailwind CSS v4 and configure properly:
```bash
# Install Tailwind v4
npm install tailwindcss@next @tailwindcss/vite@next
```

Update configuration files for Tailwind v4 compatibility.

### Step 3: Install and Configure shadcn

Install shadcn with proper TypeScript configuration:
```bash
# Install shadcn CLI
npx shadcn@latest init

# Initialize with defaults
npx shadcn@latest add button card input label textarea select checkbox radio-group switch toast
```

### Step 4: Create Standardized Folder Structure

Create the required directory structure:
```bash
mkdir -p src/custom-components
mkdir -p src/app/custom-components/sections
mkdir -p src/page-containers/the/page/route
```

### Step 5: Generate Tekk-Prefixed Components

Create abstraction layer over shadcn components with Tekk prefix:

**custom-components Examples**:
- TekkButton (extends shadcn Button)
- TekkCard (extends shadcn Card)
- TekkInput (extends shadcn Input)
- TekkModal (extends shadcn Dialog)

**page-containers Examples**:
- TekkHomePageContainer (for home page client state)
- TekkDashboardPageContainer (for dashboard pages)

**sections Examples**:
- TekkHeroSection (hero section component)
- TekkFeaturesSection (features section)
- TekkContactSection (contact form section)

### Step 6: Setup Documentation Standards

Ensure all components have proper JSDoc docstrings with:
```typescript
/**
 * Component description with intended use cases
 * 
 * @param paramName - Parameter description with type
 * @param anotherParam - Another parameter description
 * @returns Expected output type if applicable
 * 
 * @example
 * ```tsx
 * <TekkButton variant="default" size="lg">
 *   Click me
 * </TekkButton>
 * ```
 */
```

### Step 7: Configure Next.js Best Practices

Set up proper Next.js configurations:
- Use `next/image` for all images
- Configure proper imports and exports
- Set up TypeScript strict mode
- Configure ESLint and Prettier
- Add environment variable templates

## Best Practices

### Component Naming
- Always use "Tekk" prefix for custom components
- Use "PageContainer" suffix for page containers
- Use "Section" suffix for section components
- Follow PascalCase convention

### File Organization
- Keep shadcn components in `src/components/ui/`
- Place Tekk components in `src/custom-components/`
- Organize sections by feature/page
- Use index files for clean imports

### Export Patterns

**CRITICAL: ALL custom functional components MUST use named exports**

```typescript
// ✅ CORRECT - Named export for custom component
export const TekkButton: React.FC<TekkButtonProps> = ({ ... }) => {
  // component implementation
}

// ❌ INCORRECT - Default export for custom component
export default function TekkButton() { ... }
```

**Index.ts Pattern**:
Every custom components directory MUST have an `index.ts` file for clean imports:

```typescript
// /src/custom-components/index.ts
export { TekkButton } from './TekkButton'
export { TekkCard } from './TekkCard'
export { TekkModal } from './TekkModal'
```

**Library vs Custom Components**:

- **Library Components**: Use default exports as provided by the library (e.g., shadcn/ui)
  ```typescript
  // ✅ CORRECT - Default export from library
  import { Button } from '@/components/ui/button'  // shadcn component
  ```

- **Custom Wrappers**: Use named exports when extending library components
  ```typescript
  // ✅ CORRECT - Named export for custom wrapper
  import { Button as ShadcnButton } from '@/components/ui/button'

  export const TekkButton: React.FC<TekkButtonProps> = ({ ... }) => {
    return <ShadcnButton {...props} />
  }
  ```

**Import Patterns for Consumers**:
```typescript
// ✅ CORRECT - Clean named imports from index
import { TekkButton, TekkCard } from '@/custom-components'

// ✅ CORRECT - Direct import for tree-shaking
import { TekkButton } from '@/custom-components/TekkButton'

// ❌ AVOID - Default import from custom component
import TekkButton from '@/custom-components/TekkButton'
```

**Benefits of Named Exports**:
1. **Better Tree Shaking**: Bundlers can eliminate unused exports more effectively
2. **Clearer Imports**: Named imports make it explicit which components are being used
3. **Improved IDE Support**: Better auto-completion and refactoring capabilities
4. **Code Consistency**: Standardizes the codebase pattern across all components
5. **Easier Testing**: Named exports are easier to mock and test in isolation
6. **Better Documentation**: Explicit exports make component APIs clearer

### Documentation
- Every component must have JSDoc docstring
- Include parameter types and descriptions
- Add usage examples in docstrings
- Document component behavior and limitations

### Code Quality
- Use TypeScript strict mode
- Follow ESLint configuration
- Implement proper error boundaries
- Use semantic HTML elements

### Performance
- Implement proper code splitting
- Use dynamic imports for heavy components
- Optimize images with next/image
- Implement proper caching strategies

## Common Issues

### Installation Issues
- **Node.js Version**: Ensure Node.js 18+ is installed
- **Package Conflicts**: Clear npm cache with `npm cache clean --force`
- **Permissions**: Use `sudo` only if necessary for global installs

### Configuration Issues
- **Tailwind v4**: Configuration differs from v3, check official docs
- **TypeScript Errors**: Ensure proper `tsconfig.json` configuration
- **Import Paths**: Verify `import-alias` is correctly configured

### Component Issues
- **shadcn Integration**: Ensure proper initialization with `npx shadcn@latest init`
- **Type Errors**: Check TypeScript types for shadcn components
- **Styling**: Verify Tailwind classes are properly applied

### Build Issues
- **Missing Dependencies**: Run `npm install` after adding new packages
- **TypeScript Compilation**: Check for type errors before building
- **Environment Variables**: Ensure `.env.local` exists if required

## Example Generated Components

### TekkButton Example
```typescript
import React from 'react'
import { Button as ShadcnButton, ButtonProps } from "@/components/ui/button"

/**
 * Extended button component with Tekk styling and behavior
 *
 * @param variant - Button style variant (default, destructive, outline, etc.)
 * @param size - Button size (default, sm, lg, icon)
 * @param children - Button content
 * @param className - Additional CSS classes
 * @returns Enhanced button component
 *
 * @example
 * ```tsx
 * <TekkButton variant="default" size="lg">
 *   Submit Form
 * </TekkButton>
 * ```
 */
export const TekkButton: React.FC<ButtonProps> = ({
  variant = "default",
  size = "default",
  children,
  className,
  ...props
}) => {
  return (
    <ShadcnButton
      variant={variant}
      size={size}
      className={`font-semibold ${className}`}
      {...props}
    >
      {children}
    </ShadcnButton>
  )
}
```

### TekkHomePageContainer Example
```typescript
"use client"
import React, { useState } from 'react'

/**
 * Client-side container for home page with state management
 *
 * @param children - Page content components
 * @returns Client-side home page wrapper with state
 *
 * @example
 * ```tsx
 * <TekkHomePageContainer>
 *   <TekkHeroSection />
 *   <TekkFeaturesSection />
 * </TekkHomePageContainer>
 * ```
 */
export const TekkHomePageContainer: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [isLoading, setIsLoading] = useState(false)

  return (
    <div className="min-h-screen">
      {isLoading ? (
        <div>Loading...</div>
      ) : (
        children
      )}
    </div>
  )
}
```

### Index.ts Example (Custom Components)
```typescript
// /src/custom-components/index.ts

/**
 * Central export file for all Tekk-prefixed custom components
 * Provides clean import paths and enables tree-shaking
 *
 * @example
 * ```typescript
 * import { TekkButton, TekkCard } from '@/custom-components'
 * ```
 */

// Core UI Components
export { TekkButton } from './TekkButton'
export { TekkCard } from './TekkCard'
export { TekkInput } from './TekkInput'
export { TekkModal } from './TekkModal'

// Section Components
export { TekkHeroSection } from './sections/TekkHeroSection'
export { TekkFeaturesSection } from './sections/TekkFeaturesSection'
export { TekkContactSection } from './sections/TekkContactSection'

// Page Containers
export { TekkHomePageContainer } from '../page-containers/TekkHomePageContainer'
export { TekkDashboardPageContainer } from '../page-containers/TekkDashboardPageContainer'
```

### Consumer Usage Example
```typescript
// ✅ CORRECT - Named import from index
import { TekkButton, TekkCard } from '@/custom-components'

// ✅ CORRECT - Named import for tree-shaking specific components
import { TekkButton } from '@/custom-components/TekkButton'

// ✅ CORRECT - Library component import (default export from library)
import { Button } from '@/components/ui/button'

// ❌ AVOID - Default import from custom component
import TekkButton from '@/custom-components/TekkButton'

// Usage in component
export const MyPage: React.FC = () => {
  return (
    <div>
      <TekkButton variant="default" onClick={() => console.log('Clicked')}>
        Click me
      </TekkButton>
      <TekkCard title="Card Title">
        <p>Card content</p>
      </TekkCard>
    </div>
  )
}
```

## Verification Commands

After setup, verify with these commands:
```bash
# Check Next.js setup
npm run build

# Verify TypeScript
npm run type-check

# Check linting
npm run lint

# Run development server
npm run dev

# Verify named exports are used (manual check)
grep -r "export const" src/custom-components/ | wc -l
# Should equal the number of component files

# Check for index.ts files in component directories
ls -la src/custom-components/index.ts
ls -la src/custom-components/sections/index.ts
```

**Verification Checklist**:
- [ ] All custom components use `export const ComponentName`
- [ ] No custom components use `export default`
- [ ] All component directories have index.ts files
- [ ] Index.ts files re-export components using named exports
- [ ] Library imports (shadcn) use their original export pattern
- [ ] TypeScript compilation passes without errors
- [ ] Build completes successfully

## Related Skills

- `nextjs-pr-workflow`: For creating PRs after development
- `nextjs-unit-test-creator`: For adding unit tests to components
- `typescript-dry-principle`: For eliminating code duplication
- `linting-workflow`: For ensuring code quality