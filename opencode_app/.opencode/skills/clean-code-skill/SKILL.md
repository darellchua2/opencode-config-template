---
name: clean-code-skill
description: Write clean, human-readable code with proper naming, small functions, self-documenting patterns, and object calisthenics - language-agnostic
license: Apache-2.0
compatibility: opencode
metadata:
  audience: developers
  workflow: code-quality
  languages: [language-agnostic]
---

## What I do

I help you write clean, maintainable code that is easy to understand and change:

1. **Improve Naming**: Apply consistent, understandable, specific, and searchable naming conventions
2. **Reduce Function Size**: Keep functions small (under 10 lines) with single responsibility
3. **Apply Object Calisthenics**: Follow the 9 rules for better object-oriented design
4. **Eliminate Comments**: Replace comments with self-documenting code
5. **Improve Formatting**: Apply consistent code structure and organization
6. **Reduce Cognitive Load**: Write code that tells a story

## When to use me

Use this skill when:
- Code is hard to understand even though it works
- Functions are long and do multiple things
- Names are vague, inconsistent, or misleading
- Code requires extensive comments to explain what it does
- Reviewing code for readability and maintainability
- Onboarding new developers who struggle with the codebase
- Setting up coding standards for a team
- Refactoring legacy code for better maintainability

## Prerequisites

- Code to analyze or write
- Understanding of basic programming concepts
- Willingness to refactor for readability
- Knowledge of the domain/business context for naming

## What is Clean Code?

Code that is:
- **Easy to understand** - reveals intent clearly
- **Easy to change** - modifications are localized
- **Easy to test** - dependencies are injectable
- **Simple** - no unnecessary complexity

## The Human-Centered Approach

Code has THREE consumers:
1. **Users** - get their needs met
2. **Customers** - make or save money
3. **Developers** - must maintain it

Design for all three, but remember: **developers read code 10x more than they write it.**

---

## Naming Principles

### Priority Order for Naming

1. **Consistency & Uniqueness** (HIGHEST PRIORITY)
2. **Understandability**
3. **Specificity**
4. **Brevity**
5. **Searchability**
6. **Pronounceability**
7. **Austerity**

### 1. Consistency & Uniqueness

Same concept = same name everywhere. One name per concept.

```python
# BAD: Inconsistent names for same concept
get_user_by_id(id)
fetch_customer_by_id(id)
retrieve_client_by_id(id)

# GOOD: Consistent
get_user(id)
get_order(id)
get_product(id)
```

### 2. Understandability

Use domain language, not technical jargon.

```typescript
// BAD: Technical
const arr = users.filter(u => u.isActive);

// GOOD: Domain language
const activeCustomers = users.filter(user => user.isActive);
```

### 3. Specificity

Avoid vague names: `data`, `info`, `manager`, `handler`, `processor`, `utils`

```python
# BAD: Vague
class DataManager:
    pass

def process_info(data):
    pass

# GOOD: Specific
class OrderRepository:
    pass

def validate_payment(payment):
    pass
```

### 4. Brevity (but not at cost of clarity)

Short names are good only if meaning is preserved.

```typescript
// BAD: Too cryptic
const usrLst = getUsrs();

// BAD: Unnecessarily long
const listOfAllActiveUsersInTheSystem = getActiveUsers();

// GOOD: Brief but clear
const activeUsers = getActiveUsers();
```

### 5. Searchability

Names should be unique enough to grep/search.

```python
# BAD: Common word, hard to search
data = fetch()

# GOOD: Unique, searchable
order_summary = fetch_order_summary()
```

### 6. Pronounceability

You should be able to say it in conversation.

```typescript
// BAD
const genymdhms = generateYearMonthDayHourMinuteSecond();

// GOOD
const timestamp = generateTimestamp();
```

### 7. Austerity

Avoid unnecessary filler words.

```python
# BAD: Redundant
user_data = user  # 'Data' adds nothing
class UserClass:  # 'Class' adds nothing
    pass

# GOOD
user = user
class User:
    pass
```

---

## Object Calisthenics (9 Rules)

Exercises to improve OO design. Follow strictly during practice, relax slightly in production.

### Rule 1: One Level of Indentation per Method

```python
# BAD: Multiple levels
def process(orders):
    for order in orders:
        if order.is_valid():
            for item in order.items:
                if item.in_stock:
                    # process...

# GOOD: Extract methods
def process(orders):
    for order in orders:
        if order.is_valid():
            process_order(order)

def process_order(order):
    for item in order.items:
        if item.in_stock:
            process_item(item)
```

### Rule 2: Don't Use the ELSE Keyword

Use early returns, guard clauses, or polymorphism.

```typescript
// BAD: else
function getDiscount(user: User): number {
    if (user.isPremium) {
        return 20;
    } else {
        return 0;
    }
}

// GOOD: Early return
function getDiscount(user: User): number {
    if (user.isPremium) return 20;
    return 0;
}
```

### Rule 3: Wrap All Primitives and Strings

Primitives should be wrapped in domain objects when they have meaning.

```python
# BAD: Primitive obsession
def create_user(email: str, age: int):
    pass

# GOOD: Value objects
class Email:
    def __init__(self, value: str):
        if not self._is_valid(value):
            raise InvalidEmail()
        self._value = value
    
    def _is_valid(self, email: str) -> bool:
        return '@' in email

class Age:
    def __init__(self, value: int):
        if value < 0 or value > 150:
            raise InvalidAge()
        self._value = value

def create_user(email: Email, age: Age):
    pass
```

### Rule 4: First-Class Collections

Any class with a collection should have no other instance variables.

```typescript
// BAD: Collection mixed with other state
class Order {
    items: Item[] = [];
    customerId: string;
    total: number;
}

// GOOD: Collection is its own class
class OrderItems {
    constructor(private items: Item[] = []) {}
    
    add(item: Item): void { /* ... */ }
    total(): Money { /* ... */ }
    isEmpty(): boolean { /* ... */ }
}

class Order {
    constructor(
        private items: OrderItems,
        private customerId: CustomerId
    ) {}
}
```

### Rule 5: One Dot per Line (Law of Demeter)

Don't chain through object graphs.

```python
# BAD: Train wreck
city = order.customer.address.city

# GOOD: Tell, don't ask
city = order.get_shipping_city()
```

### Rule 6: Don't Abbreviate

If a name is too long to type, the class is doing too much.

```typescript
// BAD
const custRepo = new CustRepo();
const ord = new Ord();

// GOOD
const customerRepository = new CustomerRepository();
const order = new Order();
```

### Rule 7: Keep All Entities Small

- Classes: < 50 lines
- Methods: < 10 lines
- Files: < 100 lines

If larger, it's probably doing too much. Split it.

### Rule 8: No Classes with More Than Two Instance Variables

Forces small, focused classes.

```python
# BAD: Too many variables
class Order:
    def __init__(self):
        self.id = None
        self.customer_id = None
        self.items = []
        self.total = 0
        self.status = None

# GOOD: Composed of smaller objects
class Order:
    def __init__(self, order_id, details):
        self._id = order_id
        self._details = details

class OrderDetails:
    def __init__(self, customer, line_items):
        self._customer = customer
        self._line_items = line_items
```

### Rule 9: No Getters/Setters/Properties

Objects should have behavior, not just data. Tell objects what to do.

```typescript
// BAD: Data bag with getters
class Account {
    getBalance(): number { return this.balance; }
    setBalance(value: number) { this.balance = value; }
}

// Caller does the work
if (account.getBalance() >= amount) {
    account.setBalance(account.getBalance() - amount);
}

// GOOD: Behavior-rich object
class Account {
    withdraw(amount: Money): WithdrawResult {
        if (!this.canWithdraw(amount)) {
            return WithdrawResult.insufficientFunds();
        }
        this.balance = this.balance.subtract(amount);
        return WithdrawResult.success();
    }
}

// Caller tells, object decides
const result = account.withdraw(amount);
```

---

## Comments

### When to Write Comments

**Only write comments to explain WHY, not WHAT or HOW.**

Code explains what and how. Comments explain business reasons, non-obvious decisions, or warnings.

```python
# BAD: Explains what (redundant)
# Add 1 to counter
counter += 1

# GOOD: Explains why
# Compensate for 0-based indexing in legacy API
counter += 1
```

### Prefer Self-Documenting Code

Instead of commenting, rename to make intent clear.

```typescript
// BAD: Comment needed
// Check if user can access premium features
if (user.subscriptionLevel >= 2 && !user.isBanned) { }

// GOOD: Self-documenting
if (user.canAccessPremiumFeatures()) { }
```

---

## Formatting

### Vertical Spacing
- Related code together
- Blank lines between concepts
- Most important/public at top

### Horizontal Spacing
- Consistent indentation
- Space around operators
- Max line length ~80-120 characters

### Storytelling
Code should read top-to-bottom like a story. High-level at top, details below.

```python
class OrderProcessor:
    # Public API first
    def process(self, order):
        self._validate(order)
        self._calculate_totals(order)
        return self._save(order)
    
    # Supporting methods below, in order of appearance
    def _validate(self, order):
        pass
    
    def _calculate_totals(self, order):
        pass
    
    def _save(self, order):
        pass
```

---

## Steps

### Step 1: Analyze Current Code

1. Read the code as if you're seeing it for the first time
2. Note areas that require mental effort to understand
3. Identify long functions (>10 lines)
4. Find vague or inconsistent names
5. Locate comments that explain WHAT

### Step 2: Improve Naming

1. Apply the 7 naming principles in priority order
2. Use domain language, not technical jargon
3. Ensure consistency across the codebase
4. Make names searchable and pronounceable

### Step 3: Reduce Function Size

1. Apply Rule 1 (one level of indentation)
2. Extract methods to achieve <10 lines per function
3. Ensure each function does one thing
4. Use early returns to avoid else

### Step 4: Apply Object Calisthenics

1. Review against all 9 rules
2. Focus on the most impactful violations first
3. Refactor incrementally
4. Keep tests passing after each change

### Step 5: Eliminate Unnecessary Comments

1. Replace WHAT comments with better naming
2. Keep WHY comments that explain business reasons
3. Add warnings for non-obvious edge cases
4. Document public APIs with proper documentation

---

## Best Practices

### General Clean Code Practices

- **Meaningful Names**: Spend time on naming, it pays off
- **Small Functions**: If you can't see the whole function, it's too long
- **Do One Thing**: Each function/class should have one purpose
- **DRY (Don't Repeat Yourself)**: But wait for Rule of Three
- **KISS (Keep It Simple)**: Simplest solution that works

### Code Review Checklist

- [ ] Can I understand this code in 6 months?
- [ ] Are names consistent with the rest of the codebase?
- [ ] Does each function do one thing?
- [ ] Are functions shorter than 10 lines?
- [ ] Is there unnecessary complexity?
- [ ] Would a junior developer understand this?

---

## Common Issues

### Over-Abstraction

**Issue**: Creating too many small classes/methods for simple logic

**Solution**:
- Apply clean code when you feel pain
- Rule of Three for abstractions
- Keep related code together

### Inconsistent Naming

**Issue**: Same concept has different names across codebase

**Solution**:
- Create a project glossary
- Use consistent naming conventions
- Review naming in code reviews

### Too Many Small Functions

**Issue**: Code becomes hard to navigate with too many tiny functions

**Solution**:
- Group related functions in classes
- Use clear naming to show relationships
- Keep related code physically close

---

## Verification Commands

After applying clean code principles:

```bash
# Check function/method lengths
find src -name "*.py" -exec grep -c "def " {} \;

# Check for common vague names
grep -r "data\|info\|manager\|handler\|utils" src/ --include="*.py"

# Count lines per file (should be < 100)
find src -name "*.py" -exec wc -l {} \; | sort -rn | head -20

# Check for TODO/FIXME that should be addressed
grep -r "TODO\|FIXME" src/ --include="*.py"
```

**Clean Code Verification Checklist:**
- [ ] All names are consistent, specific, and searchable
- [ ] Functions are under 10 lines
- [ ] Classes are under 50 lines
- [ ] No unnecessary comments (WHAT comments)
- [ ] Code reads top-to-bottom like a story
- [ ] No else keyword when early return works
- [ ] Primitives wrapped in domain objects
- [ ] Collections are first-class
- [ ] No getters/setters without behavior
