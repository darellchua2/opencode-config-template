---
name: nextjs-standard-setup
description: Create standardized Next.js 16 demo applications with shadcn, Tailwind v4, src directory with path aliases, React Compiler, and npx zero-install experience using Tekk-prefixed components
license: Apache-2.0
compatibility: opencode
metadata:
  audience: developers
  workflow: project-setup
---

## What I do

I create a standardized Next.js 16 application with:

- **Next.js 16 Setup**: Install and configure latest Next.js 16 with npx
- **shadcn Integration**: Install and configure shadcn@latest with TypeScript
- **Tailwind v4 Configuration**: Set up Tailwind CSS v4
- **src Directory**: Use src/ directory structure with path aliases (@/*)
- **Component Architecture**: Set up Tekk-prefixed abstraction layer with named exports
- **React Compiler**: Enable React Compiler for optimized reactivity
- **Documentation Standards**: Generate components with proper JSDoc docstrings

## When to use me

Use when:
- Starting a new Next.js demo application
- Need standardized project structure for consistency
- Want to ensure best practices from the start
- Setting up projects with Tekk-prefixed naming conventions
- Using npx for zero-install experience
- Enabling React Compiler for optimized performance

## Prerequisites

- Node.js 18+ installed
- npm/yarn/pnpm package manager
- Git repository initialized (recommended)
- Terminal/shell access
- Internet connection for package installation

## Steps

### Step 1: Initialize Next.js 16

Create Next.js 16 app with TypeScript:

```bash
# Create with npx for zero-install experience
npx -y create-next-app@latest --typescript --tailwind --eslint --app --src-dir --import-alias "@/*"
```

**Key flags**:
- `--typescript`: TypeScript support
- `--tailwind`: Tailwind CSS
- `--eslint`: ESLint configuration
- `--app`: App Router (recommended)
- `--src-dir`: src/ directory structure
- `--import-alias "@/*"`: Path aliases

### Step 2: Configure Tailwind v4

```bash
# Install Tailwind v4
npx -y tailwindcss@latest init -p
```

Update `tailwind.config.ts`:

```typescript
import type { Config } from "tailwindcss"

const config: Config = {
  content: [
    "./src/**/*.{js,ts,jsx,tsx,mdx}",
  ],
  theme: {
    extend: {},
  },
  plugins: [],
}

export default config
```

### Step 3: Install shadcn

```bash
# Initialize shadcn
npx -y shadcn@latest init
```

**Configuration options**:
- TypeScript: Yes
- Style: Default (Tailwind)
- Base color: Slate
- Tailwind config: tailwind.config.ts
- Aliases: @/components, @/lib, @/utils

shadcn creates:
- `src/components/ui/`: Library components
- `src/lib/utils.ts`: Utility functions
- `components.json`: Component configuration

### Step 4: Create Directory Structure

```bash
# Create src/ structure
mkdir -p src/app
mkdir -p src/components/ui
mkdir -p src/components/TekkComponents
mkdir -p src/custom-components
mkdir -p src/page-containers
mkdir -p src/lib
mkdir -p src/types
```

**Project structure**:
```
project-root/
├── src/
│   ├── app/                    # App Router pages
│   ├── components/             # Reusable UI components
│   │   ├── ui/               # shadcn components
│   │   └── TekkComponents/  # Tekk wrappers
│   ├── custom-components/    # Feature components
│   ├── lib/                    # Utilities
│   └── types/                  # TypeScript types
├── tsconfig.json             # Path aliases
├── next.config.ts            # React Compiler
├── tailwind.config.ts        # Tailwind v4
└── package.json
```

### Step 5: Configure Path Aliases

Update `tsconfig.json`:

```json
{
  "compilerOptions": {
    "baseUrl": ".",
    "paths": {
      "@/*": ["./src/*"],
      "@/components/*": ["./src/components/*"],
      "@/lib/*": ["./src/lib/*"],
      "@/app/*": ["./src/app/*"],
      "@/types/*": ["./src/types/*"]
    },
    "target": "ES2022",
    "lib": ["ES2022", "DOM"],
    "module": "ESNext",
    "moduleResolution": "bundler",
    "strict": true
  }
}
```

### Step 6: Enable React Compiler

Update `next.config.ts`:

```typescript
const nextConfig = {
  experimental: {
    reactCompiler: true,
  },
}

module.exports = nextConfig
```

**React Compiler Benefits**:
- Automatic React optimization (no manual memo needed)
- Reduces re-renders
- Improved performance
- No code changes required

**Requirements**: Next.js 16+, React 18.2.0+, TypeScript strict mode

### Step 7: Configure Environment Variables

Create `.env.local.example`:

```bash
cat > .env.local.example <<EOF
# Database
DATABASE_URL=postgresql://user:password@localhost:5432/mydb

# API
NEXT_PUBLIC_API_URL=http://localhost:3000/api

# Authentication
NEXTAUTH_SECRET=your-secret-key

# Feature Flags
NEXT_PUBLIC_FEATURE_X=true
NEXT_PUBLIC_FEATURE_Y=false
EOF
```

### Step 8: Setup Documentation Standards

All components require JSDoc docstrings:

```typescript
/**
 * Component description with use cases
 *
 * @param paramName - Parameter description with type
 * @returns Expected output type
 *
 * @example
 * ```tsx
 * <TekkButton variant="default" size="lg">
 *   Click me
 * </TekkButton>
 * ```
 */
```

## Best Practices

### Component Naming

- Use "Tekk" prefix for custom components
- Use "PageContainer" suffix for page containers
- Use "Section" suffix for section components
- Follow PascalCase

### Export Patterns (CRITICAL)

**All custom components MUST use named exports**:

```typescript
// ✅ CORRECT - Named export
export const TekkButton: React.FC = ({ ... }) => { }

// ❌ INCORRECT - Default export
export default function TekkButton() { }
```

**Index.ts pattern** for clean imports:

```typescript
// /src/custom-components/index.ts
export { TekkButton } from './TekkButton'
export { TekkCard } from './TekkCard'
```

**Benefits of named exports**:
- Better tree-shaking
- Clearer imports
- Improved IDE support
- Code consistency
- Easier testing
- Better documentation

### Component Examples

**TekkButton wrapper**:

```typescript
import { Button as ShadcnButton } from '@/components/ui/button'

export const TekkButton: React.FC<ButtonProps> = ({
  variant = "default",
  size = "default",
  children,
  ...props
}) => {
  return <ShadcnButton variant={variant} size={size} {...props}>
    {children}
  </ShadcnButton>
}
```

**Page container**:

```typescript
export const TekkHomePageContainer: React.FC<{
  children: React.ReactNode
}> = ({ children }) => {
  return <div className="min-h-screen">{children}</div>
}
```

### Code Quality

- Use TypeScript strict mode
- Follow ESLint configuration
- Implement error boundaries
- Use semantic HTML elements
- Use `next/image` for images
- Implement proper code splitting

## Common Issues

### Installation Issues

- **Node.js Version**: Ensure Node.js 18+ is installed
- **Package Conflicts**: Clear npm cache with `npm cache clean --force`

### Configuration Issues

- **Tailwind v4**: Configuration differs from v3, check official docs
- **TypeScript Errors**: Ensure proper `tsconfig.json` configuration
- **Import Paths**: Verify `import-alias` is correctly configured

### Build Issues

- **Missing Dependencies**: Run `npm install` after adding new packages
- **TypeScript Compilation**: Check for type errors before building
- **Environment Variables**: Ensure `.env.local` exists if required

## Verification

```bash
# Check Next.js setup
npm run build

# Verify TypeScript
npm run type-check

# Check linting
npm run lint

# Run development server
npm run dev
```

## References

- **Next.js Documentation**: https://nextjs.org/docs
- **Tailwind v4 Docs**: https://tailwindcss.com/blog/tailwindcss-v4-alpha
- **shadcn Documentation**: https://ui.shadcn.com
- **React Compiler**: https://react.dev/learn/react-compiler
