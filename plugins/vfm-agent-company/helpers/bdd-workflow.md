# BDD Workflow for Multi-Agent System

BDD biến "yêu cầu mơ hồ" thành "contract kiểm chứng được" — agents tự verify mình, không cần người check.

## Why BDD for AI Agents

| Lý do | Giải thích |
|-------|-----------|
| Gherkin = ngôn ngữ tự nhiên | LLM sinh và hiểu Given/When/Then cực tốt |
| Spec = Executable | Agent tự verify output, không cần người check |
| Unambiguous | Mỗi scenario = 1 test case rõ ràng, giảm hallucination |
| Self-correcting loop | Code → run test → fail → fix → pass |

## Agent Role Mapping

| Agent | Methodology | Responsibility |
|-------|-------------|----------------|
| PM | ATDD mindset | Write Acceptance Criteria in user stories |
| QA (Batch 0) | BDD | Generate .feature files + skeleton tests |
| Dev (Batch 1) | TDD | Implement code, loop until tests GREEN |
| QA (Batch 3) | Verify | Run full suite, regression, coverage |

## .feature File Format

Location: `.project/scenarios/sprint-{N}/`

```gherkin
Feature: {Feature Name}
  {Brief description from user story}

  Scenario: {Happy path}
    Given {precondition}
    When {action}
    Then {expected result}
    And {additional assertion}

  Scenario: {Error case}
    Given {precondition}
    When {invalid action}
    Then {error handling}

  Scenario: {Edge case}
    Given {boundary condition}
    When {action}
    Then {expected behavior}
```

### Naming Convention
- File: `{task-id}-{feature-name}.feature` (e.g., `1.3-shopping-cart.feature`)
- Feature name matches user story title
- Scenarios cover: happy path, error cases, edge cases

## Skeleton Test File Format

QA generates skeleton tests at the CORRECT level based on what each scenario tests:

| Scenario tests... | Test level | Location | Framework |
|-------------------|-----------|----------|-----------|
| Business logic, utils, hooks | Unit | `app/__tests__/{name}.test.ts` | Vitest/Jest |
| API endpoints, DB, middleware | Integration | `app/__tests__/integration/{name}.test.ts` | Vitest + Supertest |
| User flows, clicks, navigation | E2E | `app/e2e/{name}.spec.ts` | Playwright |

Tag each scenario in .feature: `@unit`, `@integration`, or `@e2e`

```gherkin
Feature: Shopping Cart

  @unit
  Scenario: Calculate cart total
    Given cart has "T-Shirt" at $29.99 qty 2
    Then cart total should be $59.98

  @integration
  Scenario: POST /api/cart creates item
    Given user is authenticated
    When POST /api/cart with product_id
    Then response 201 with cart data

  @e2e
  Scenario: Add item from product page
    Given I am on product page
    When I click "Add to Cart"
    Then cart badge shows "1"
```

### Unit test skeleton (`app/__tests__/cart.test.ts`)
```typescript
import { describe, it, expect } from 'vitest'

describe('Feature: Shopping Cart', () => {
  describe('Scenario: Calculate cart total', () => {
    it('should calculate correct total', () => {
      // Given: cart has "T-Shirt" at $29.99 qty 2
      // Then: total = $59.98
      throw new Error('Not implemented')
    })
  })
})
```

### E2E test skeleton (`app/e2e/cart.spec.ts`)
```typescript
import { test, expect } from '@playwright/test'

test.describe('Feature: Shopping Cart', () => {
  test('Scenario: Add item from product page', async ({ page }) => {
    // Given: on product page
    // When: click "Add to Cart"
    // Then: cart badge shows "1"
    throw new Error('Not implemented')
  })
})
```

## ⭐ E2E Test Interaction Rules (MANDATORY)

**Two rules**: (1) use the correct interaction method, (2) test mid-interaction state, not just end-state.

### Rule 1: Same interaction method as users

| User Interaction | E2E Must Use | ❌ NOT This |
|-----------------|-------------|-------------|
| Mouse click | `page.click()` | keyboard Enter |
| Mouse drag & drop | `page.mouse.move/down/up` with incremental steps | keyboard Space+Arrow (different code path) |
| Mouse hover | `page.hover()` | `page.focus()` |
| Touch swipe | Touch events | Mouse events |
| Form typing | `page.fill()` or `page.type()` | `page.evaluate(el.value = ...)` |

Libraries like @dnd-kit have separate code paths per sensor. A failing mouse test = a broken mouse feature — NEVER switch to keyboard as workaround.

### Rule 2: Test mid-interaction visual state

If a feature has visual feedback during interaction (drag overlay, resize preview, swipe animation), assert the visual state MID-interaction — not just the end result.

```typescript
// ✅ CORRECT: mouse drag + mid-drag position assertion
await page.mouse.move(startX, startY);
await page.mouse.down();
for (let i = 1; i <= 10; i++) {
  await page.mouse.move(startX + dx*(i/10), startY + dy*(i/10));
  await page.waitForTimeout(20);
}
// Assert overlay follows cursor BEFORE dropping
const overlay = page.locator('[style*="translate3d"]');
const box = await overlay.boundingBox();
expect(Math.abs(box.y - targetY)).toBeLessThan(50);

await page.mouse.up();
// Assert end-state (order changed)
await expect(items.nth(0)).toContainText('C');
```

---

## Self-Correcting Loop (Dev Agent)

```
Dev nhận: task + .feature file + skeleton test
    ↓
1. Read .feature → understand contract
2. Read skeleton test → see what needs to pass
3. Write implementation code
4. Run tests: npm test (unit + integration) AND npx playwright test (E2E, if exists)
    ↓
Red (fail)? → Read error → Fix code → Run tests again
    ↓
Green (pass)? → Task COMPLETE
    ↓
Still Red after 3 attempts? → Report to PM with error details
```

## When to Use BDD

| Task type | BDD? | Lý do |
|-----------|------|-------|
| API endpoints | Yes | Given request → When call → Then response |
| Business logic | Yes | Given state → When action → Then result |
| User flows (E2E) | Yes | Given page → When click → Then navigate |
| UI components | Partial | Interactions = BDD, styling = wireframe |
| CI/CD, deployment | No | Infrastructure, no business behavior |
| Database schema | No | Structure, no behavior |

## Example: User Story → Feature → Test

### User Story (BA writes)
```
As a user, I want to add items to cart so that I can purchase them later.

Acceptance Criteria:
- Given empty cart, When add product, Then cart has 1 item with correct total
- Given product in cart, When add same product, Then quantity increases
- Given product in cart, When remove product, Then cart is empty
```

### .feature File (QA Batch 0 generates)
```gherkin
Feature: Shopping Cart

  Scenario: Add item to empty cart
    Given the cart is empty
    When I add product "T-Shirt" with price $29.99 and quantity 2
    Then cart total should be $59.98
    And cart item count should be 1

  Scenario: Add duplicate item
    Given "T-Shirt" is already in cart with quantity 1
    When I add "T-Shirt" with quantity 2
    Then "T-Shirt" quantity should be 3

  Scenario: Remove item from cart
    Given "T-Shirt" is in cart
    When I remove "T-Shirt"
    Then the cart should be empty
```

### Skeleton Test (QA Batch 0 generates)
```typescript
describe('Feature: Shopping Cart', () => {
  describe('Scenario: Add item to empty cart', () => {
    it('should calculate correct total when adding to empty cart', () => {
      // Given: cart is empty
      // When: add "T-Shirt" price $29.99 qty 2
      // Then: total = $59.98, count = 1
      throw new Error('Not implemented')
    })
  })
  // ... more scenarios
})
```

### Implementation (Dev fills in Batch 1)
```typescript
describe('Scenario: Add item to empty cart', () => {
  it('should calculate correct total when adding to empty cart', () => {
    const cart = new Cart()
    cart.addItem({ name: 'T-Shirt', price: 29.99 }, 2)
    expect(cart.total).toBe(59.98)
    expect(cart.itemCount).toBe(1)
  })
})
```

Dev runs test → GREEN → Task COMPLETE.

---

## Cleanup Rule

**⚠️ MANDATORY**: Any agent that starts a dev server (`npm run dev`, `npx vite`, etc.) for testing MUST kill it when done.

```bash
# Kill dev server on common ports
lsof -ti:3000 | xargs kill 2>/dev/null
lsof -ti:5173 | xargs kill 2>/dev/null
```

This applies to QA agents (Batch 3) and any agent using Playwright MCP tools for visual checks.
