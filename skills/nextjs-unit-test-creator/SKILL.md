---
name: nextjs-unit-test-creator
description: Generate comprehensive unit and E2E tests for Next.js with scenario validation, framework detection, and Playwright support
license: Apache-2.0
compatibility: opencode
metadata:
  audience: developers
  workflow: nextjs-testing
---

## What I do

I implement a complete Next.js test generation workflow:

1. **Analyze Next.js Codebase**: Scan the Next.js application to identify new components, utility functions, and modules that need testing
2. **Detect Test Framework**: Read `package.json` to determine the testing framework (Jest, Vitest, Playwright) and related dependencies
3. **Generate Test Scenarios**: Create comprehensive test scenarios covering:
   - **Components**: Rendering, props, state, events, snapshots, accessibility
   - **Utility Functions**: Happy paths, edge cases, error handling, type validation
   - **Hooks**: Custom hook behavior, dependencies, state management
   - **E2E Tests**: User workflows, navigation, form submissions, API interactions (if Playwright detected)
4. **Prompt User Confirmation**: Display all generated scenarios and ask for user approval before proceeding
5. **Create Test Files**: Generate unit test files with proper structure and assertions
6. **Ensure Executability**: Verify tests run with `npm run test <test_files>` or appropriate command
7. **Create E2E Tests**: Generate Playwright E2E tests if explicitly requested and Playwright is installed

## When to use me

Use this workflow when:
- You need to create unit tests for new Next.js components
- You want to ensure all edge cases and user interactions are covered
- You need tests for utility functions in a Next.js application
- You need E2E tests for Next.js applications (Playwright)
- You prefer a systematic approach to test generation with user confirmation
- You want to ensure tests run correctly with your project's test framework

## Prerequisites

- Next.js project with `package.json`
- Test framework installed (Jest, Vitest, Playwright, or other)
- Next.js source code (components, utilities, hooks)
- Appropriate file permissions to create test files

Note: The skill automatically detects the test framework from `package.json` and uses appropriate commands. For E2E tests, Playwright must be installed and explicitly requested.

## Steps

### Step 1: Analyze Next.js Codebase
- Use glob patterns to find TypeScript/JavaScript files: `**/*.{ts,tsx,js,jsx}`
- Exclude test files: `**/*.test.{ts,tsx,js,jsx}`, `**/*.spec.{ts,tsx,js,jsx}`, `**/__tests__/**/*`
- Identify new files or functions by:
  - Checking git status for uncommitted/new files
  - Reading each file to identify:
    - Components: `function Component()`, `const Component = ()`, `class Component`
    - Utility functions: `export function`, `export const`
    - Custom hooks: `use*` functions returning state/effects
- Identify import statements to understand dependencies

### Step 2: Detect Test Framework
- Check `package.json` for test dependencies:
  ```bash
  # Check for Jest
  grep -E "(jest|@testing-library)" package.json

  # Check for Vitest
  grep -i "vitest" package.json

  # Check for Playwright
  grep -i "playwright" package.json

  # Check test scripts
  grep -A 5 '"scripts"' package.json | grep test
  ```
- Determine the test framework:
  - **Jest**: If `jest` or `@testing-library/*` is in devDependencies
  - **Vitest**: If `vitest` is in devDependencies
  - **Playwright**: If `@playwright/test` is in devDependencies
  - **Other**: Parse test scripts to identify the runner
- Store appropriate test command:
  ```bash
  # Determine test command from package.json
  if grep -q '"test":.*vitest' package.json; then
      TEST_CMD="npm run test"
      TEST_FRAMEWORK="vitest"
  elif grep -q '"test":.*jest' package.json; then
      TEST_CMD="npm run test"
      TEST_FRAMEWORK="jest"
  else
      TEST_CMD="npm run test"
      TEST_FRAMEWORK="detected"
  fi

  # Check for Playwright E2E tests
  if grep -q "@playwright/test" package.json; then
      PLAYWRIGHT_INSTALLED=true
      E2E_CMD="npm run test:e2e"
  else
      PLAYWRIGHT_INSTALLED=false
  fi
  ```
- Check for related testing libraries:
  - React Testing Library (`@testing-library/react`, `@testing-library/jest-dom`)
  - Testing Library user-event (`@testing-library/user-event`)
  - Next.js testing utilities (`@next/test-utils`)
  - Playwright (`@playwright/test`) for E2E testing
- Ask user if E2E tests are needed if Playwright is installed and user workflow suggests E2E testing

### Step 3: Generate Test Scenarios

#### Component Scenarios
- **Rendering**: Component renders without crashing
- **Props Display**: Correct display of passed props
- **User Interactions**: Click events, form submissions, keyboard interactions
- **State Changes**: State updates after user actions
- **Conditional Rendering**: Elements show/hide based on conditions
- **Accessibility**: ARIA labels, keyboard navigation, screen reader support
- **Snapshots**: UI structure remains consistent
- **Error Boundaries**: Graceful handling of errors
- **Loading States**: Display during data fetching
- **Empty States**: Display when no data is available

#### Utility Function Scenarios
- **Happy Path**: Valid inputs return expected outputs
- **Edge Cases**: Empty inputs, null/undefined values, boundary values
- **Error Handling**: Invalid inputs raise appropriate errors
- **Type Validation**: Type checking and coercion
- **Performance**: Large input handling
- **Async Functions**: Promises resolve/reject correctly

#### Custom Hook Scenarios
- **Initial State**: Returns correct initial values
- **State Updates**: State updates correctly after actions
- **Side Effects**: useEffect runs with correct dependencies
- **Cleanup**: useEffect cleanup functions work correctly
- **Multiple Calls**: Hook can be called multiple times
- **Dependency Changes**: Responds to dependency changes

#### E2E Test Scenarios (Playwright)
- **Page Navigation**: User can navigate between pages
- **Form Submissions**: Forms submit correctly and display results
- **Authentication**: Login/logout workflows work as expected
- **Data Display**: Data is fetched and displayed correctly
- **User Interactions**: Click events, keyboard navigation, scroll behavior
- **Responsive Design**: UI works on different screen sizes
- **Error Handling**: Error states display correctly
- **Loading States**: Loading indicators appear during async operations
- **Accessibility**: Page is accessible via keyboard and screen readers
- **Performance**: Pages load within acceptable time limits

### Step 4: Display Scenarios for Confirmation

Display formatted output:
```
📋 Generated Test Scenarios for <file_name>

**Type:** <Component | Utility Function | Custom Hook>

**Item to Test:** <ComponentName | functionName>

**Scenarios:**
1. Rendering Test
   - Component renders without errors
   - Correct elements are present in DOM

2. Props Test
   - Props are displayed correctly
   - Missing props use default values

3. User Interaction Test
   - Click event triggers callback
   - Form submission works as expected

4. State Test
   - State updates after interaction
   - Multiple state transitions work

5. Edge Case Test
   - Empty data handled gracefully
   - Null/undefined values don't break component

6. Accessibility Test
   - ARIA labels are present
   - Keyboard navigation works

**Total Scenarios:** <number>
**Estimated Test Lines:** <number>

**Test Framework Detected:** <Jest | Vitest | Other>
**Test Command:** <npm run test | vitest | jest>

**E2E Tests:** <Yes - Playwright | No>
**E2E Test Command:** <npm run test:e2e | n/a>

Are these scenarios acceptable? (y/n/suggest)
```

Wait for user response:
- **y**: Proceed to create test files (and E2E tests if requested)
- **n**: Ask for modifications or cancel
- **suggest**: Ask user to add/remove scenarios

Wait for user response:
- **y**: Proceed to create test files
- **n**: Ask for modifications or cancel
- **suggest**: Ask user to add/remove scenarios

### Step 5: Create Test Files

#### For Components (Jest + React Testing Library)
```typescript
/**
 * Test suite for <ComponentName>
 * Generated by nextjs-unit-test-creator skill
 */

import { render, screen, fireEvent, waitFor } from '@testing-library/react'
import { axe, toHaveNoViolations } from 'jest-axe'
import userEvent from '@testing-library/user-event'
import { <ComponentName> } from './<ComponentName>'

// Extend Jest to include jest-axe matchers
expect.extend(toHaveNoViolations)

describe('<ComponentName>', () => {
  const defaultProps = {
    // Default props for testing
  }

  it('renders without crashing', () => {
    render(<<ComponentName> {...defaultProps} />)
    expect(screen.getByText(/content/i)).toBeInTheDocument()
  })

  it('displays correct props', () => {
    const customProps = { ...defaultProps, title: 'Custom Title' }
    render(<<ComponentName> {...customProps} />)
    expect(screen.getByText('Custom Title')).toBeInTheDocument()
  })

  it('handles user interactions', async () => {
    const user = userEvent.setup()
    const handleClick = jest.fn()
    render(<<ComponentName> {...defaultProps} onClick={handleClick} />)

    const button = screen.getByRole('button')
    await user.click(button)

    expect(handleClick).toHaveBeenCalledTimes(1)
  })

  it('updates state after interaction', async () => {
    const user = userEvent.setup()
    render(<<ComponentName> {...defaultProps} />)

    const input = screen.getByLabelText(/search/i)
    await user.type(input, 'test query')

    expect(input).toHaveValue('test query')
  })

  it('handles empty state', () => {
    const emptyProps = { ...defaultProps, data: [] }
    render(<<ComponentName> {...emptyProps} />)

    expect(screen.getByText(/no data/i)).toBeInTheDocument()
  })

  it('has no accessibility violations', async () => {
    const { container } = render(<<ComponentName> {...defaultProps} />)
    const results = await axe(container)

    expect(results).toHaveNoViolations()
  })

  it('shows loading state', () => {
    const loadingProps = { ...defaultProps, isLoading: true }
    render(<<ComponentName> {...loadingProps} />)

    expect(screen.getByRole('progressbar')).toBeInTheDocument()
  })

  it('matches snapshot', () => {
    const { container } = render(<<ComponentName> {...defaultProps} />)
    expect(container).toMatchSnapshot()
  })
})
```

#### For Components (Vitest + React Testing Library)
```typescript
/**
 * Test suite for <ComponentName>
 * Generated by nextjs-unit-test-creator skill
 */

import { describe, it, expect, vi, beforeEach } from 'vitest'
import { render, screen, fireEvent, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { <ComponentName> } from './<ComponentName>'

describe('<ComponentName>', () => {
  const defaultProps = {
    // Default props for testing
  }

  beforeEach(() => {
    // Reset mocks before each test
    vi.clearAllMocks()
  })

  it('renders without crashing', () => {
    render(<<ComponentName> {...defaultProps} />)
    expect(screen.getByText(/content/i)).toBeInTheDocument()
  })

  it('displays correct props', () => {
    const customProps = { ...defaultProps, title: 'Custom Title' }
    render(<<ComponentName> {...customProps} />)
    expect(screen.getByText('Custom Title')).toBeInTheDocument()
  })

  it('handles user interactions', async () => {
    const user = userEvent.setup()
    const handleClick = vi.fn()
    render(<<ComponentName> {...defaultProps} onClick={handleClick} />)

    const button = screen.getByRole('button')
    await user.click(button)

    expect(handleClick).toHaveBeenCalledTimes(1)
  })

  it('updates state after interaction', async () => {
    const user = userEvent.setup()
    render(<<ComponentName> {...defaultProps} />)

    const input = screen.getByLabelText(/search/i)
    await user.type(input, 'test query')

    expect(input).toHaveValue('test query')
  })

  it('handles empty state', () => {
    const emptyProps = { ...defaultProps, data: [] }
    render(<<ComponentName> {...emptyProps} />)

    expect(screen.getByText(/no data/i)).toBeInTheDocument()
  })

  it('shows loading state', () => {
    const loadingProps = { ...defaultProps, isLoading: true }
    render(<<ComponentName> {...loadingProps} />)

    expect(screen.getByRole('progressbar')).toBeInTheDocument()
  })
})
```

#### For Utility Functions (Jest)
```typescript
/**
 * Test suite for <functionName>
 * Generated by nextjs-unit-test-creator skill
 */

import { <functionName> } from './<fileName>'

describe('<functionName>', () => {
  it('returns correct result for valid inputs', () => {
    const result = <functionName>(validInput)
    expect(result).toBe(expectedOutput)
  })

  it('handles empty input', () => {
    const result = <functionName>('')
    expect(result).toBe(expectedValue)
  })

  it('handles null input', () => {
    const result = <functionName>(null)
    expect(result).toBe(expectedValue)
  })

  it('handles undefined input', () => {
    const result = <functionName>(undefined)
    expect(result).toBe(expectedValue)
  })

  it('throws error for invalid input', () => {
    expect(() => <functionName>(invalidInput)).toThrow(Error)
  })

  it('handles edge cases', () => {
    expect(<functionName>(0)).toBe(expectedValue)
    expect(<functionName>(-1)).toBe(expectedValue)
    expect(<functionName>(Number.MAX_SAFE_INTEGER)).toBe(expectedValue)
  })

  it('handles array input', () => {
    const result = <functionName>([1, 2, 3])
    expect(result).toEqual(expectedArray)
  })

  it('handles object input', () => {
    const result = <functionName>({ key: 'value' })
    expect(result).toMatchObject(expectedObject)
  })
})
```

#### For Utility Functions (Vitest)
```typescript
/**
 * Test suite for <functionName>
 * Generated by nextjs-unit-test-creator skill
 */

import { describe, it, expect, beforeEach } from 'vitest'
import { <functionName> } from './<fileName>'

describe('<functionName>', () => {
  beforeEach(() => {
    // Reset any mocks or state
  })

  it('returns correct result for valid inputs', () => {
    const result = <functionName>(validInput)
    expect(result).toBe(expectedOutput)
  })

  it('handles empty input', () => {
    const result = <functionName>('')
    expect(result).toBe(expectedValue)
  })

  it('handles null input', () => {
    const result = <functionName>(null)
    expect(result).toBe(expectedValue)
  })

  it('handles undefined input', () => {
    const result = <functionName>(undefined)
    expect(result).toBe(expectedValue)
  })

  it('throws error for invalid input', () => {
    expect(() => <functionName>(invalidInput)).toThrow(Error)
  })

  it('handles edge cases', () => {
    expect(<functionName>(0)).toBe(expectedValue)
    expect(<functionName>(-1)).toBe(expectedValue)
    expect(<functionName>(Number.MAX_SAFE_INTEGER)).toBe(expectedValue)
  })
})
```

#### For Custom Hooks (Jest)
```typescript
/**
 * Test suite for use<HookName>
 * Generated by nextjs-unit-test-creator skill
 */

import { renderHook, act, waitFor } from '@testing-library/react'
import { use<HookName> } from './use<HookName>'

describe('use<HookName>', () => {
  it('returns correct initial state', () => {
    const { result } = renderHook(() => use<HookName>())
    expect(result.current.someValue).toBe(initialValue)
  })

  it('updates state correctly', async () => {
    const { result } = renderHook(() => use<HookName>())

    await act(async () => {
      result.current.someAction()
    })

    expect(result.current.someValue).toBe(newValue)
  })

  it('handles dependencies correctly', async () => {
    const { result, rerender } = renderHook(
      ({ prop }) => use<HookName>(prop),
      { initialProps: { prop: 'initial' } }
    )

    expect(result.current.value).toBe('initial')

    await act(async () => {
      rerender({ prop: 'updated' })
    })

    expect(result.current.value).toBe('updated')
  })

  it('cleans up on unmount', () => {
    const cleanup = jest.fn()
    const { unmount } = renderHook(() => use<HookName>(cleanup))

    unmount()

    expect(cleanup).toHaveBeenCalledTimes(1)
  })
})
```

#### For Custom Hooks (Vitest)
```typescript
/**
 * Test suite for use<HookName>
 * Generated by nextjs-unit-test-creator skill
 */

import { describe, it, expect, vi } from 'vitest'
import { renderHook, act } from '@testing-library/react'
import { use<HookName> } from './use<HookName>'

describe('use<HookName>', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('returns correct initial state', () => {
    const { result } = renderHook(() => use<HookName>())
    expect(result.current.someValue).toBe(initialValue)
  })

  it('updates state correctly', async () => {
    const { result } = renderHook(() => use<HookName>())

    await act(async () => {
      result.current.someAction()
    })

    expect(result.current.someValue).toBe(newValue)
  })

  it('handles dependencies correctly', async () => {
    const { result, rerender } = renderHook(
      ({ prop }) => use<HookName>(prop),
      { initialProps: { prop: 'initial' } }
    )

    expect(result.current.value).toBe('initial')

    await act(async () => {
      rerender({ prop: 'updated' })
    })

    expect(result.current.value).toBe('updated')
  })

  it('cleans up on unmount', () => {
    const cleanup = vi.fn()
    const { unmount } = renderHook(() => use<HookName>(cleanup))

    unmount()

    expect(cleanup).toHaveBeenCalledTimes(1)
  })
})
```

#### For E2E Tests (Playwright)
```typescript
/**
 * E2E test suite for <PageName>
 * Generated by nextjs-unit-test-creator skill
 */

import { test, expect } from '@playwright/test'

test.describe('<PageName>', () => {
  test.beforeEach(async ({ page }) => {
    // Navigate to page before each test
    await page.goto('/<page-path>')
  })

  test('page loads successfully', async ({ page }) => {
    // Check if page title is correct
    await expect(page).toHaveTitle(/<page-title>/i)

    // Check if main content is visible
    await expect(page.locator('main')).toBeVisible()
  })

  test('navigation works correctly', async ({ page }) => {
    // Click on navigation link
    await page.click('text=Home')

    // Verify navigation
    await expect(page).toHaveURL('/')
  })

  test('form submission works', async ({ page }) => {
    // Fill out form
    await page.fill('input[name="email"]', 'test@example.com')
    await page.fill('input[name="password"]', 'password123')

    // Submit form
    await page.click('button[type="submit"]')

    // Wait for navigation or success message
    await expect(page).toHaveURL(/dashboard|success/i)
  })

  test('displays data correctly', async ({ page }) => {
    // Wait for data to load
    await page.waitForSelector('[data-testid="data-container"]')

    // Check if data is displayed
    await expect(page.locator('[data-testid="data-item"]')).toHaveCount(5)
  })

  test('handles loading state', async ({ page }) => {
    // Navigate to page that triggers loading
    await page.goto('/<page-path>?slow=true')

    // Check for loading indicator
    await expect(page.locator('[data-testid="loading"]')).toBeVisible()

    // Wait for loading to complete
    await page.waitForSelector('[data-testid="data-container"]')

    // Loading should be hidden
    await expect(page.locator('[data-testid="loading"]')).not.toBeVisible()
  })

  test('handles error state', async ({ page }) => {
    // Navigate to page that triggers error
    await page.goto('/<page-path>?error=true')

    // Check for error message
    await expect(page.locator('[data-testid="error"]')).toBeVisible()
    await expect(page.locator('text=Something went wrong')).toBeVisible()
  })

  test('authentication workflow', async ({ page }) => {
    // Navigate to login page
    await page.goto('/login')

    // Fill login form
    await page.fill('input[name="email"]', 'test@example.com')
    await page.fill('input[name="password"]', 'password123')

    // Submit form
    await page.click('button[type="submit"]')

    // Wait for redirect to dashboard
    await page.waitForURL('/dashboard')

    // Verify user is logged in
    await expect(page.locator('text=Welcome, Test')).toBeVisible()
  })

  test('responsive design works', async ({ page }) => {
    // Test mobile view
    await page.setViewportSize({ width: 375, height: 667 })
    await expect(page.locator('nav')).toBeVisible()

    // Test tablet view
    await page.setViewportSize({ width: 768, height: 1024 })
    await expect(page.locator('main')).toBeVisible()

    // Test desktop view
    await page.setViewportSize({ width: 1920, height: 1080 })
    await expect(page.locator('aside')).toBeVisible()
  })

  test('keyboard navigation works', async ({ page }) => {
    // Navigate to page
    await page.goto('/<page-path>')

    // Use keyboard to navigate
    await page.keyboard.press('Tab')
    await page.keyboard.press('Enter')

    // Verify interaction
    await expect(page.locator('[data-testid="modal"]')).toBeVisible()
  })

  test('page loads within acceptable time', async ({ page }) => {
    const startTime = Date.now()

    await page.goto('/<page-path>')
    await page.waitForLoadState('networkidle')

    const loadTime = Date.now() - startTime

    // Page should load within 3 seconds
    expect(loadTime).toBeLessThan(3000)
  })
})
```

#### For E2E Tests with API Mocking (Playwright)
```typescript
/**
 * E2E test suite for <PageName> with API mocking
 * Generated by nextjs-unit-test-creator skill
 */

import { test, expect } from '@playwright/test'

test.describe('<PageName> with API Mocking', () => {
  test('displays mocked data', async ({ page }) => {
    // Mock API response
    await page.route('**/api/data', async (route) => {
      await route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify([
          { id: 1, name: 'Mocked Item 1' },
          { id: 2, name: 'Mocked Item 2' },
        ]),
      })
    })

    await page.goto('/<page-path>')

    // Verify mocked data is displayed
    await expect(page.locator('text=Mocked Item 1')).toBeVisible()
    await expect(page.locator('text=Mocked Item 2')).toBeVisible()
  })

  test('handles API error', async ({ page }) => {
    // Mock API error
    await page.route('**/api/data', async (route) => {
      await route.fulfill({
        status: 500,
        contentType: 'application/json',
        body: JSON.stringify({ error: 'Internal Server Error' }),
      })
    })

    await page.goto('/<page-path>')

    // Verify error message is displayed
    await expect(page.locator('[data-testid="error"]')).toBeVisible()
    await expect(page.locator('text=Failed to load data')).toBeVisible()
  })

  test('handles slow API response', async ({ page }) => {
    // Mock slow API response
    await page.route('**/api/data', async (route) => {
      // Simulate network delay
      await new Promise((resolve) => setTimeout(resolve, 2000))

      await route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify([]),
      })
    })

    await page.goto('/<page-path>')

    // Verify loading state is shown
    await expect(page.locator('[data-testid="loading"]')).toBeVisible()

    // Wait for data to load
    await page.waitForSelector('[data-testid="data-container"]')

    // Loading should be hidden
    await expect(page.locator('[data-testid="loading"]')).not.toBeVisible()
  })
})
```

#### For E2E Tests with Authentication (Playwright)
```typescript
/**
 * E2E test suite for authentication workflows
 * Generated by nextjs-unit-test-creator skill
 */

import { test, expect } from '@playwright/test'

test.describe('Authentication', () => {
  test.beforeEach(async ({ page, context }) => {
    // Clear cookies and storage before each test
    await context.clearCookies()
  })

  test('successful login', async ({ page }) => {
    await page.goto('/login')

    // Fill login form
    await page.fill('input[name="email"]', 'test@example.com')
    await page.fill('input[name="password"]', 'password123')

    // Submit form
    await page.click('button[type="submit"]')

    // Verify redirect to dashboard
    await page.waitForURL('/dashboard')

    // Verify user is authenticated
    await expect(page.locator('text=Welcome, Test')).toBeVisible()
    await expect(page.locator('[data-testid="logout-button"]')).toBeVisible()
  })

  test('failed login with invalid credentials', async ({ page }) => {
    await page.goto('/login')

    // Fill login form with invalid credentials
    await page.fill('input[name="email"]', 'invalid@example.com')
    await page.fill('input[name="password"]', 'wrongpassword')

    // Submit form
    await page.click('button[type="submit"]')

    // Verify error message
    await expect(page.locator('[data-testid="error"]')).toBeVisible()
    await expect(page.locator('text=Invalid credentials')).toBeVisible()

    // Verify user is not redirected
    await expect(page).toHaveURL('/login')
  })

  test('successful logout', async ({ page }) => {
    // First login
    await page.goto('/login')
    await page.fill('input[name="email"]', 'test@example.com')
    await page.fill('input[name="password"]', 'password123')
    await page.click('button[type="submit"]')

    await page.waitForURL('/dashboard')

    // Logout
    await page.click('[data-testid="logout-button"]')

    // Verify redirect to login page
    await page.waitForURL('/login')

    // Verify user is logged out
    await expect(page.locator('[data-testid="logout-button"]')).not.toBeVisible()
  })

  test('protected routes require authentication', async ({ page }) => {
    // Try to access protected route without authentication
    await page.goto('/dashboard')

    // Should be redirected to login
    await page.waitForURL('/login')

    // Verify login page is displayed
    await expect(page.locator('text=Sign in')).toBeVisible()
  })
})
```

#### For E2E Tests with File Upload (Playwright)
```typescript
/**
 * E2E test suite for file upload functionality
 * Generated by nextjs-unit-test-creator skill
 */

import { test, expect } from '@playwright/test'
import path from 'path'

test.describe('File Upload', () => {
  test('successful file upload', async ({ page }) => {
    await page.goto('/upload')

    // Select file to upload
    const fileInput = page.locator('input[type="file"]')
    await fileInput.setInputFiles(path.join(__dirname, 'test-file.txt'))

    // Upload button should be enabled
    await expect(page.locator('button[type="submit"]')).toBeEnabled()

    // Submit form
    await page.click('button[type="submit"]')

    // Verify success message
    await expect(page.locator('[data-testid="success"]')).toBeVisible()
    await expect(page.locator('text=File uploaded successfully')).toBeVisible()
  })

  test('multiple file upload', async ({ page }) => {
    await page.goto('/upload')

    // Select multiple files
    const fileInput = page.locator('input[type="file"]')
    await fileInput.setInputFiles([
      path.join(__dirname, 'file1.txt'),
      path.join(__dirname, 'file2.txt'),
    ])

    // Submit form
    await page.click('button[type="submit"]')

    // Verify success message
    await expect(page.locator('[data-testid="success"]')).toBeVisible()
    await expect(page.locator('text=2 files uploaded')).toBeVisible()
  })

  test('invalid file type', async ({ page }) => {
    await page.goto('/upload')

    // Try to upload invalid file type
    const fileInput = page.locator('input[type="file"]')
    await fileInput.setInputFiles(path.join(__dirname, 'invalid.exe'))

    // Submit form
    await page.click('button[type="submit"]')

    // Verify error message
    await expect(page.locator('[data-testid="error"]')).toBeVisible()
    await expect(page.locator('text=Invalid file type')).toBeVisible()
  })

  test('file upload progress', async ({ page }) => {
    await page.goto('/upload')

    // Mock slow upload
    await page.route('**/api/upload', async (route) => {
      await new Promise((resolve) => setTimeout(resolve, 2000))
      await route.fulfill({ status: 200 })
    })

    // Select file
    await page.locator('input[type="file"]').setInputFiles(
      path.join(__dirname, 'test-file.txt')
    )

    // Submit form
    await page.click('button[type="submit"]')

    // Verify progress bar
    await expect(page.locator('[data-testid="progress"]')).toBeVisible()

    // Wait for completion
    await page.waitForSelector('[data-testid="success"]')

    // Verify success
    await expect(page.locator('text=File uploaded successfully')).toBeVisible()
  })
})
```

### Step 6: Verify Executability
- Ensure tests can be run with the appropriate command:
  ```bash
  # Run all tests
  npm run test

  # Run specific test file
  npm run test <fileName>.test.tsx

  # Run tests in watch mode
  npm run test:watch

  # Run tests with coverage
  npm run test:coverage

  # Run tests for specific pattern
  npm run test -- <pattern>
  ```
- Verify no import errors or syntax issues
- Check that all tests are discoverable

### Step 7: Display Summary
```
✅ Test files created successfully!

**Test Files Created:**
- <ComponentName>.test.tsx (<number> tests)
- <functionName>.test.ts (<number> tests)

**Total Tests Generated:** <number>
**Test Framework:** <Jest | Vitest>

**Test Categories:**
- Rendering tests: <number>
- User interaction tests: <number>
- Edge case tests: <number>
- Accessibility tests: <number>
- State management tests: <number>

**To run tests:**
```bash
# Run all tests
npm run test

# Run specific test file
npm run test <fileName>.test.tsx

# Run tests in watch mode
npm run test:watch

# Run with coverage
npm run test:coverage
```

**Next Steps:**
1. Review generated test files
2. Update test data and expected values
3. Run tests to verify they pass
4. Add any missing scenarios
5. Update snapshot tests if needed
```

## Scenario Generation Rules

### Component Tests
- **Rendering**: Component renders without errors
- **Props Display**: Verify props are correctly rendered
- **User Interactions**: Click events, form submissions, keyboard events
- **State Management**: State updates correctly after actions
- **Conditional Rendering**: Elements show/hide based on props/state
- **Accessibility**: ARIA labels, roles, keyboard navigation
- **Loading States**: Display during async operations
- **Empty States**: Display when no data available
- **Error States**: Display error messages appropriately
- **Snapshots**: Ensure UI structure consistency

### Utility Function Tests
- **Happy Path**: Valid inputs return expected outputs
- **Edge Cases**: Empty strings, null, undefined, zero, negative values
- **Error Handling**: Invalid types, out of range values
- **Type Checking**: TypeScript type correctness
- **Performance**: Large inputs handled efficiently
- **Async Handling**: Promises resolve/reject correctly

### Custom Hook Tests
- **Initial State**: Returns correct default values
- **State Updates**: State changes after actions
- **Side Effects**: useEffect runs with proper dependencies
- **Cleanup**: Cleanup functions execute correctly
- **Multiple Instances**: Multiple hook calls work independently
- **Dependency Changes**: Responds to prop changes

## Examples

### Example 1: Simple Component
**Input Code:**
```typescript
interface ButtonProps {
  label: string
  onClick: () => void
  disabled?: boolean
}

export function Button({ label, onClick, disabled = false }: ButtonProps) {
  return (
    <button onClick={onClick} disabled={disabled}>
      {label}
    </button>
  )
}
```

**Generated Scenarios:**
```
1. Rendering: Button renders without errors
2. Props Display: Label is displayed correctly
3. User Interaction: onClick callback triggered
4. Disabled State: Button is disabled when disabled=true
5. Accessibility: Button has correct role and attributes
```

**Generated Test File:**
```typescript
import { render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { Button } from './Button'

describe('Button', () => {
  const defaultProps = {
    label: 'Click me',
    onClick: jest.fn(),
  }

  it('renders without crashing', () => {
    render(<Button {...defaultProps} />)
    expect(screen.getByRole('button')).toBeInTheDocument()
  })

  it('displays correct label', () => {
    render(<Button {...defaultProps} />)
    expect(screen.getByText('Click me')).toBeInTheDocument()
  })

  it('handles click events', async () => {
    const user = userEvent.setup()
    render(<Button {...defaultProps} />)

    const button = screen.getByRole('button')
    await user.click(button)

    expect(defaultProps.onClick).toHaveBeenCalledTimes(1)
  })

  it('is disabled when disabled prop is true', () => {
    render(<Button {...defaultProps} disabled />)
    const button = screen.getByRole('button')
    expect(button).toBeDisabled()
  })

  it('has correct accessibility attributes', () => {
    render(<Button {...defaultProps} />)
    const button = screen.getByRole('button')
    expect(button).toHaveAttribute('type', 'button')
  })
})
```

### Example 2: Utility Function
**Input Code:**
```typescript
export function formatDate(date: Date): string {
  if (!(date instanceof Date) || isNaN(date.getTime())) {
    throw new Error('Invalid date')
  }

  return date.toLocaleDateString('en-US', {
    year: 'numeric',
    month: 'long',
    day: 'numeric',
  })
}
```

**Generated Scenarios:**
```
1. Happy path: Valid date returns formatted string
2. Edge case: Today's date
3. Edge case: Future date
4. Error case: Non-Date object
5. Error case: Invalid Date object
6. Edge case: Epoch time
```

**Generated Test File:**
```typescript
import { formatDate } from './dateUtils'

describe('formatDate', () => {
  it('formats a valid date correctly', () => {
    const date = new Date('2024-01-15')
    const result = formatDate(date)
    expect(result).toBe('January 15, 2024')
  })

  it('handles today\'s date', () => {
    const today = new Date()
    const result = formatDate(today)
    expect(typeof result).toBe('string')
    expect(result.length).toBeGreaterThan(0)
  })

  it('handles future dates', () => {
    const futureDate = new Date('2050-12-31')
    const result = formatDate(futureDate)
    expect(result).toContain('2050')
  })

  it('throws error for non-Date object', () => {
    expect(() => formatDate('2024-01-15' as any)).toThrow('Invalid date')
    expect(() => formatDate({} as any)).toThrow('Invalid date')
  })

  it('throws error for invalid Date', () => {
    const invalidDate = new Date('invalid')
    expect(() => formatDate(invalidDate)).toThrow('Invalid date')
  })

  it('handles epoch time', () => {
    const epochDate = new Date(0)
    const result = formatDate(epochDate)
    expect(result).toContain('1970')
  })
})
```

### Example 3: Custom Hook
**Input Code:**
```typescript
import { useState, useEffect } from 'react'

export function useCounter(initialValue: number = 0) {
  const [count, setCount] = useState(initialValue)

  const increment = () => setCount((prev) => prev + 1)
  const decrement = () => setCount((prev) => prev - 1)
  const reset = () => setCount(initialValue)

  return { count, increment, decrement, reset }
}
```

**Generated Scenarios:**
```
1. Initial state: Returns correct initial value
2. Increment: Count increases by 1
3. Decrement: Count decreases by 1
4. Reset: Count resets to initial value
5. Multiple calls: Independent state between instances
6. Default initial value: Starts at 0 when not provided
```

**Generated Test File:**
```typescript
import { renderHook, act } from '@testing-library/react'
import { useCounter } from './useCounter'

describe('useCounter', () => {
  it('returns correct initial value', () => {
    const { result } = renderHook(() => useCounter(5))
    expect(result.current.count).toBe(5)
  })

  it('increments the count', () => {
    const { result } = renderHook(() => useCounter(0))

    act(() => {
      result.current.increment()
    })

    expect(result.current.count).toBe(1)
  })

  it('decrements the count', () => {
    const { result } = renderHook(() => useCounter(5))

    act(() => {
      result.current.decrement()
    })

    expect(result.current.count).toBe(4)
  })

  it('resets to initial value', () => {
    const { result } = renderHook(() => useCounter(10))

    act(() => {
      result.current.increment()
      result.current.increment()
    })

    expect(result.current.count).toBe(12)

    act(() => {
      result.current.reset()
    })

    expect(result.current.count).toBe(10)
  })

  it('maintains independent state between instances', () => {
    const { result: counter1 } = renderHook(() => useCounter(0))
    const { result: counter2 } = renderHook(() => useCounter(10))

    act(() => {
      counter1.current.increment()
    })

    expect(counter1.current.count).toBe(1)
    expect(counter2.current.count).toBe(10)
  })

  it('uses default initial value when not provided', () => {
    const { result } = renderHook(() => useCounter())
    expect(result.current.count).toBe(0)
  })
})
```

## Best Practices

- **Test Naming**: Use descriptive test names that describe what is being tested
- **User Actions**: Use `@testing-library/user-event` instead of `fireEvent` for realistic user interactions
- **Accessibility**: Test keyboard navigation and ARIA attributes
- **Avoid Implementation Details**: Test behavior, not implementation
- **One Assertion Per Test**: Prefer multiple focused tests over one complex test
- **Arrange-Act-Assert**: Structure tests in AAA pattern
- **Mock External Dependencies**: Mock API calls, databases, etc.
- **Snapshot Tests**: Use sparingly and review changes carefully
- **Coverage**: Aim for 80%+ code coverage
- **Fast Tests**: Keep unit tests fast (< 1s each)

## Common Issues

### Test Framework Not Detected
**Issue**: Unable to determine Jest or Vitest from `package.json`

**Solution**: Check test scripts in `package.json`:
```json
{
  "scripts": {
    "test": "jest",
    "test:watch": "jest --watch"
  }
}
```
or
```json
{
  "scripts": {
    "test": "vitest",
    "test:watch": "vitest watch"
  }
}
```

### React Testing Library Not Found
**Issue**: Cannot import from `@testing-library/react`

**Solution**: Install React Testing Library:
```bash
npm install --save-dev @testing-library/react @testing-library/jest-dom @testing-library/user-event
```

### Import Errors
**Issue**: Cannot import component or function to test

**Solution**: Ensure the component is exported correctly:
```typescript
// Default export
export default function Component() {}

// Named export
export function Component() {}
export const Component = () => {}
```

### Async Test Timeouts
**Issue**: Async tests timeout or fail

**Solution**: Use proper async/await and waitFor:
```typescript
it('handles async operations', async () => {
  render(<AsyncComponent />)
  await waitFor(() => {
    expect(screen.getByText('Loaded')).toBeInTheDocument()
  })
})
```

### Snapshot Tests Fail
**Issue**: Snapshot tests fail after legitimate changes

**Solution**: Update snapshots:
```bash
npm run test -- -u
```

### Missing Test Setup
**Issue**: Tests fail due to missing Jest configuration

**Solution**: Create or update `jest.config.js`:
```javascript
module.exports = {
  testEnvironment: 'jsdom',
  setupFilesAfterEnv: ['<rootDir>/jest.setup.js'],
}
```

### Vitest Not Recognized
**Issue**: Vitest tests not running

**Solution**: Update `vitest.config.ts`:
```typescript
import { defineConfig } from 'vitest/config'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react()],
  test: {
    environment: 'jsdom',
  },
})
```

## Troubleshooting Checklist

Before generating tests:
- [ ] Next.js project structure is valid
- [ ] `package.json` exists and is valid
- [ ] Test framework is installed (Jest or Vitest)
- [ ] React Testing Library is installed
- [ ] Source files (components, utilities) exist
- [ ] Files are properly exported

After generating tests:
- [ ] Test files are created in correct location
- [ ] Test files follow `.test.tsx` or `.test.ts` naming convention
- [ ] All imports resolve correctly
- [ ] Test commands are appropriate for framework
- [ ] Tests are discoverable: `npm run test -- --listTests`
- [ ] Tests can be executed: `npm run test`
- [ ] No syntax errors in test files
- [ ] Test coverage is adequate

## Related Commands

```bash
# Install testing dependencies
npm install --save-dev @testing-library/react @testing-library/jest-dom @testing-library/user-event jest-environment-jsdom

# Run all tests
npm run test

# Run specific test file
npm run test -- Button.test.tsx

# Run tests in watch mode
npm run test:watch

# Run tests with coverage
npm run test:coverage

# Run tests for specific pattern
npm run test -- --testNamePattern="Button"

# Update snapshots
npm run test -- -u

# Show test coverage report
npm run test:coverage -- --coverage

# Run only failed tests
npm run test -- --onlyFailures

# Run tests in verbose mode
npm run test -- --verbose

# Run tests in watch mode with coverage
npm run test:watch -- --coverage
```

## Test File Template

### Component Test Template
```typescript
/**
 * Test suite for <ComponentName>
 * Generated by nextjs-unit-test-creator skill
 */

import { render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { <ComponentName> } from './<ComponentName>'

describe('<ComponentName>', () => {
  const defaultProps = {
    // Define default props here
  }

  describe('Rendering', () => {
    it('renders without crashing', () => {
      render(<<ComponentName> {...defaultProps} />)
      expect(screen.getByTestId('<component-name>')).toBeInTheDocument()
    })

    it('displays correct props', () => {
      const customProps = { ...defaultProps, /* custom prop */ }
      render(<<ComponentName> {...customProps} />)

      expect(screen.getByText(/content/i)).toBeInTheDocument()
    })
  })

  describe('User Interactions', () => {
    it('handles click events', async () => {
      const user = userEvent.setup()
      const handleClick = jest.fn()
      render(<<ComponentName> {...defaultProps} onClick={handleClick} />)

      const button = screen.getByRole('button')
      await user.click(button)

      expect(handleClick).toHaveBeenCalledTimes(1)
    })

    it('handles form submissions', async () => {
      const user = userEvent.setup()
      const handleSubmit = jest.fn()
      render(<<ComponentName> {...defaultProps} onSubmit={handleSubmit} />)

      const form = screen.getByRole('form')
      await user.click(screen.getByRole('button', { name: /submit/i }))

      expect(handleSubmit).toHaveBeenCalled()
    })
  })

  describe('State Management', () => {
    it('updates state correctly', async () => {
      const user = userEvent.setup()
      render(<<ComponentName> {...defaultProps} />)

      const input = screen.getByLabelText(/search/i)
      await user.type(input, 'test')

      expect(input).toHaveValue('test')
    })
  })

  describe('Edge Cases', () => {
    it('handles empty state', () => {
      const emptyProps = { ...defaultProps, data: [] }
      render(<<ComponentName> {...emptyProps} />)

      expect(screen.getByText(/no data/i)).toBeInTheDocument()
    })

    it('handles loading state', () => {
      const loadingProps = { ...defaultProps, isLoading: true }
      render(<<ComponentName> {...loadingProps} />)

      expect(screen.getByRole('progressbar')).toBeInTheDocument()
    })
  })
})
```

### Utility Function Test Template
```typescript
/**
 * Test suite for <functionName>
 * Generated by nextjs-unit-test-creator skill
 */

import { <functionName> } from './<fileName>'

describe('<functionName>', () => {
  describe('Happy Path', () => {
    it('returns correct result for valid input', () => {
      const result = <functionName>(validInput)
      expect(result).toBe(expectedOutput)
    })
  })

  describe('Edge Cases', () => {
    it('handles empty input', () => {
      const result = <functionName>('')
      expect(result).toBe(expectedValue)
    })

    it('handles null input', () => {
      const result = <functionName>(null)
      expect(result).toBe(expectedValue)
    })

    it('handles undefined input', () => {
      const result = <functionName>(undefined)
      expect(result).toBe(expectedValue)
    })

    it('handles boundary values', () => {
      expect(<functionName>(0)).toBe(expectedValue)
      expect(<functionName>(-1)).toBe(expectedValue)
      expect(<functionName>(Number.MAX_SAFE_INTEGER)).toBe(expectedValue)
    })
  })

  describe('Error Handling', () => {
    it('throws error for invalid type', () => {
      expect(() => <functionName>(invalidInput as any)).toThrow()
    })

    it('throws error for out of range value', () => {
      expect(() => <functionName>(9999)).toThrow()
    })
  })
})
```

## Related Skills

- `nextjs-pr-workflow`: For creating PRs after completing tests
- `git-issue-creator`: For creating issues and branches for new features
- `python-ruff-linter`: For Python projects (for comparison)
