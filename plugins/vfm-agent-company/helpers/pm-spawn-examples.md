# PM Spawn Examples

> Reference examples for PM when spawning specialists. See `core/pm.md` for the mandatory spawn template format.
> **Skill Tiers**: See `helpers/model-tiers.md` for when to include SKILLS block.

## Example 1: Backend + Frontend in Parallel (Basic)

```python
# Single message, 2 Agent calls - different layers

Agent(
  subagent_type="netflix-backend-architect",
  description="Task 1.3: Product CRUD API",
  run_in_background=true,
  prompt="""
    📋 [PM] Task Assignment

    PROJECT: ecommerce-platform-2026-03
    SPRINT: Sprint 1
    TASK ID: 1.3
    TASK: Build Product CRUD API endpoints

    ─────────────────────────────────────
    READ FIRST:
    - .project/documentation/tech-stack.md
    - .project/sprints/sprint-1.md
    - .project/scenarios/sprint-1/1.3-product-crud.feature (BDD contract)
    - app/__tests__/product-crud.test.ts (skeleton — fill in)
    ─────────────────────────────────────

    SCOPE: app/api/products/ (ONLY this directory)

    SKILLS (MANDATORY — load BEFORE coding):
    Load these skills via Skill tool before writing any code:
    1. node-backend — API endpoint patterns, Express/Fastify best practices
    2. prisma — Schema design, query patterns
    Fill skills_used: in state file with skills you actually loaded.

    DELIVERABLES:
    - app/api/products/route.ts
    - app/api/products/[id]/route.ts
    - app/prisma/schema.prisma (Product model)

    ⚠️ BDD: Run ALL tests and loop until GREEN:
       npm test (unit + integration)
       npx playwright test (E2E, if exists)
    Task is NOT complete if any test is RED.

    STATE FILE: .project/state/specialists/netflix-backend-architect-1.3.md
    If NOT exists: cp .claude/templates/state/specialist-task.md to above path, then Read → Edit.
    On completion: fill skills_used: field with skills you actually loaded.

    AFTER COMPLETION:
    - All BDD tests GREEN
    - Update .project/sprints/sprint-1.md: Task 1.3 → [COMPLETE]
    - Update state file: status → COMPLETE, skills_used, completed date
  """
)

Agent(
  subagent_type="meta-react-architect",
  description="Task 1.7: Product catalog component",
  run_in_background=true,
  prompt="""
    📋 [PM] Task Assignment

    PROJECT: ecommerce-platform-2026-03
    SPRINT: Sprint 1
    TASK ID: 1.7
    TASK: Build product catalog component

    ─────────────────────────────────────
    READ FIRST:
    - .project/documentation/tech-stack.md
    - .project/sprints/sprint-1.md
    - .project/scenarios/sprint-1/1.7-product-catalog.feature (BDD contract)
    - app/__tests__/product-catalog.test.ts (skeleton — fill in)
    ─────────────────────────────────────

    SCOPE: app/components/catalog/ (ONLY this directory)

    SKILLS (MANDATORY — load BEFORE coding):
    Load these skills via Skill tool before writing any code:
    1. react-expert — React component patterns, hooks best practices
    2. performance-optimization — List rendering, virtualization
    Fill skills_used: in state file with skills you actually loaded.

    DELIVERABLES:
    - app/components/catalog/ProductGrid.tsx
    - app/components/catalog/ProductCard.tsx

    ⚠️ BDD: Run ALL tests and loop until GREEN:
       npm test (unit + integration)
       npx playwright test (E2E, if exists)
    Task is NOT complete if any test is RED.

    AFTER COMPLETION:
    - All BDD tests GREEN
    - Update .project/sprints/sprint-1.md: Task 1.7 → [COMPLETE]
    - Update .project/state/specialists/meta-react-architect-1.7.md
  """
)
```

## Example 2: Multiple Frontend Agents in Parallel (Advanced)

```python
# 3 Frontend agents working on 3 different pages simultaneously!

Agent(
  subagent_type="meta-react-architect",
  run_in_background=true,
  prompt="""
    📋 [PM] Task Assignment

    PROJECT: ecommerce-app-2026-03
    SPRINT: Sprint 2
    TASK ID: 2.1
    TASK: Build Dashboard Page

    SCOPE: app/dashboard/ (ONLY this directory)

    SKILLS (MANDATORY — load BEFORE coding):
    1. react-expert — Component patterns, state management
    2. next-best-practices — App Router, data fetching

    DELIVERABLES:
    - app/dashboard/page.tsx
    - app/dashboard/components/StatsCard.tsx
    - app/dashboard/components/RecentOrders.tsx

    AFTER COMPLETION:
    - Update .project/sprints/sprint-2.md: Task 2.1 → [COMPLETE]
    - Update .project/state/specialists/meta-react-architect-2.1.md
  """
)

Agent(
  subagent_type="meta-react-architect",
  run_in_background=true,
  prompt="""
    📋 [PM] Task Assignment

    PROJECT: ecommerce-app-2026-03
    SPRINT: Sprint 2
    TASK ID: 2.2
    TASK: Build Settings Page

    SCOPE: app/settings/ (ONLY this directory)

    SKILLS (MANDATORY — load BEFORE coding):
    1. react-expert — Form patterns, controlled components

    DELIVERABLES:
    - app/settings/page.tsx
    - app/settings/components/ProfileForm.tsx

    AFTER COMPLETION:
    - Update .project/sprints/sprint-2.md: Task 2.2 → [COMPLETE]
    - Update .project/state/specialists/meta-react-architect-2.2.md
  """
)

Agent(
  subagent_type="meta-react-architect",
  run_in_background=true,
  prompt="""
    📋 [PM] Task Assignment

    PROJECT: ecommerce-app-2026-03
    SPRINT: Sprint 2
    TASK ID: 2.3
    TASK: Build Profile Page

    SCOPE: app/profile/ (ONLY this directory)

    SKILLS (MANDATORY — load BEFORE coding):
    1. react-expert — Component patterns

    DELIVERABLES:
    - app/profile/page.tsx
    - app/profile/components/Avatar.tsx

    AFTER COMPLETION:
    - Update .project/sprints/sprint-2.md: Task 2.3 → [COMPLETE]
    - Update .project/state/specialists/meta-react-architect-2.3.md
  """
)
```

## Example 3: Multiple Backend Agents (Different Modules)

```python
# 2 Backend agents on completely separate modules

Agent(
  subagent_type="netflix-backend-architect",
  run_in_background=true,
  prompt="""
    📋 [PM] Task Assignment

    PROJECT: saas-platform-2026-03
    SPRINT: Sprint 3
    TASK ID: 3.1
    TASK: Build Authentication Module

    SCOPE: app/modules/auth/ (ONLY this directory)
    SHARED FILES: NONE - this module is self-contained

    SKILLS (MANDATORY — load BEFORE coding):
    1. node-backend — API patterns, middleware
    2. security-expert — JWT, auth best practices, OWASP

    DELIVERABLES:
    - app/modules/auth/auth.service.ts
    - app/modules/auth/auth.controller.ts
    - app/modules/auth/strategies/jwt.strategy.ts
    - app/modules/auth/guards/auth.guard.ts

    AFTER COMPLETION:
    - Update .project/sprints/sprint-3.md: Task 3.1 → [COMPLETE]
    - Update .project/state/specialists/netflix-backend-architect-3.1.md
  """
)

Agent(
  subagent_type="netflix-backend-architect",
  run_in_background=true,
  prompt="""
    📋 [PM] Task Assignment

    PROJECT: saas-platform-2026-03
    SPRINT: Sprint 3
    TASK ID: 3.2
    TASK: Build Payment Module

    SCOPE: app/modules/payments/ (ONLY this directory)
    SHARED FILES: NONE - this module is self-contained

    SKILLS (MANDATORY — load BEFORE coding):
    1. node-backend — API patterns, error handling
    2. security-expert — Payment security, PCI compliance

    DELIVERABLES:
    - app/modules/payments/payment.service.ts
    - app/modules/payments/payment.controller.ts
    - app/modules/payments/stripe.client.ts

    AFTER COMPLETION:
    - Update .project/sprints/sprint-3.md: Task 3.2 → [COMPLETE]
    - Update .project/state/specialists/netflix-backend-architect-3.2.md
  """
)
```

## Example 4: Sequential When Shared Files (Schema)

```python
# ❌ WRONG - Both modify schema.prisma = CONFLICT
Agent(subagent_type="netflix-backend-architect", prompt="Task 1.1: User model")
Agent(subagent_type="netflix-backend-architect", prompt="Task 1.2: Product model")

# ✅ CORRECT - Sequential for shared files
Agent(
  subagent_type="netflix-backend-architect",
  run_in_background=false,  # Wait for completion!
  prompt="""
    TASK ID: 1.1
    TASK: Build User + Product models (combined to avoid schema conflict)

    DELIVERABLES:
    - app/prisma/schema.prisma (User + Product models)
    - app/api/users/route.ts
    - app/api/products/route.ts
  """
)
# Only after 1.1 completes, spawn next task that needs schema
```
