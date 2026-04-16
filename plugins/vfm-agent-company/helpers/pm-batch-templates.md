---
name: pm-batch-templates
type: helper
description: |
  Full Agent() call templates for Batch 0 (BDD Scenarios), Batch 2 (Code Review), and Batch 3 (QA Verification).
  Includes BDD scenario generation, dispatch table format, and QA verification prompt.
---

# Batch 0: BDD Scenario Generation Prompt Template

```python
Agent(
  subagent_type="google-qa-engineer",
  description="Task {N}.S: BDD Scenarios Sprint {N}",
  prompt="""
    📋 [PM] Task Assignment

    SPRINT: Sprint {N}
    TASK ID: {N}.S
    TASK: Generate BDD Scenarios for Sprint {N}

    ─────────────────────────────────────
    READ FIRST:
    - .project/requirements/user-stories.md
    - .project/sprints/sprint-{N}.md
    - .project/documentation/tech-stack.md
    - helpers/bdd-workflow.md (for .feature format)
    ─────────────────────────────────────

    USER STORIES FOR THIS SPRINT:
    {list each task: ID, user story, acceptance criteria (Given/When/Then)}

    ─────────────────────────────────────
    OUTPUT (MANDATORY):
    ─────────────────────────────────────

    1. .feature FILES:
       - Create .project/scenarios/sprint-{N}/{task-id}-{name}.feature
       - Each .feature maps to ONE user story / task
       - Include: happy path, error cases, edge cases
       - Use Gherkin: Feature / Scenario / Given / When / Then / And

    2. SKELETON TEST FILES (organized by test level):
       - Unit tests: app/__tests__/{feature-name}.test.ts
         (business logic, utils, hooks, pure functions)
       - Integration tests: app/__tests__/integration/{feature-name}.test.ts
         (API endpoints, DB operations, middleware)
       - E2E tests: app/e2e/{feature-name}.spec.ts (Playwright)
         (user flows, click/navigate/form, browser interactions)
       - Use describe('Feature: ...') / describe('Scenario: ...') / it('should ...')
       - Body: throw new Error('Not implemented') — Dev fills in Batch 1
       - Tag each scenario in .feature with @unit, @integration, or @e2e

    3. SCENARIO SUMMARY:
       - List all scenarios for PM to present to user for approval
       - Format: Feature → Scenario list with Given/When/Then

    AFTER COMPLETION:
    - Update .project/sprints/sprint-{N}.md: Task {N}.S → [COMPLETE]
    - Update .project/state/specialists/google-qa-engineer-{N}.S.md
  """
)
```

**After QA completes**: PM shows brief scenario summary as FYI, then proceeds directly to Batch 1 (no approval wait). User already approved roadmap — scenarios are implementation detail.

---

# Batch 2: Code Review Prompt Template

```python
Agent(
  subagent_type="google-code-reviewer",
  description="Task {N}.R: Code Review Sprint {N}",
  prompt="""
    📋 [PM] Task Assignment

    SPRINT: Sprint {N}
    TASK ID: {N}.R
    TASK: Code Review — Sprint {N}

    ─────────────────────────────────────
    READ FIRST:
    - .project/sprints/sprint-{N}.md
    - .project/documentation/tech-stack.md
    - .project/documentation/architecture.md
    ─────────────────────────────────────

    COMPLETED TASKS:
    {list each task: ID, description, developer, files changed}

    REVIEW CHECKLIST:

    1. ARCHITECTURE COMPLIANCE (read architecture.md File Blueprint):
       - Files created in correct locations per Blueprint?
       - File names follow naming conventions? (PascalCase components, kebab-case utils, use* hooks)
       - 1 file = 1 responsibility (SRP)? No god files (>300 lines)?
       - No files created outside of Blueprint without CTO approval?
       - Domain grouping correct? (tree/, member/, NOT components/buttons/)

    2. CODE QUALITY (read helpers/code-quality.md):
       - Clean Code: meaningful names, functions <30 lines, no magic numbers
       - DRY: no logic repeated 3+ times without extraction
       - SOLID: single responsibility, dependency inversion
       - Error handling: no swallowed errors, typed errors at boundaries

    3. TYPESCRIPT & SECURITY:
       - No `any` type — proper types/interfaces
       - No XSS, injection, or auth vulnerabilities
       - Input validation at system boundaries (Zod/schemas)

    4. PERFORMANCE:
       - No N+1 queries, unnecessary re-renders
       - Proper memoization where needed (memo, useMemo, useCallback)

    5. BDD COMPLIANCE:
       - All .feature scenarios have corresponding tests?
       - Tests actually assert what scenarios describe (not just smoke tests)?
       - Test file structure matches: describe('Feature:') / describe('Scenario:')

    6. INTEGRATION:
       - Imports/data flow between components correct?
       - No circular dependencies?

    OUTPUT: LGTM / NEEDS MINOR / NEEDS MAJOR
    For each finding: 🔴 Critical / 🟡 Major / 🟢 Minor

    AFTER COMPLETION:
    - Update .project/sprints/sprint-{N}.md: Task {N}.R → [COMPLETE]
    - Update .project/state/specialists/google-code-reviewer-{N}.R.md
  """
)
```

**If NEEDS MAJOR** → PM spawns fix agents → re-run Code Review.
**If LGTM or NEEDS MINOR** → proceed to Batch 3.

---

# Batch 3: QA Verification Prompt Template

**Note**: Batch 3 is VERIFICATION, not scenario writing. Scenarios were created in Batch 0.

```python
Agent(
  subagent_type="google-qa-engineer",
  description="Task {N}.Q: QA Verification Sprint {N}",
  prompt="""
    📋 [PM] Task Assignment

    SPRINT: Sprint {N}
    TASK ID: {N}.Q
    TASK: QA Verification — Sprint {N}

    ─────────────────────────────────────
    READ FIRST:
    - .project/scenarios/sprint-{N}/*.feature (BDD scenarios)
    - .project/sprints/sprint-{N}.md
    - .project/documentation/tech-stack.md
    ─────────────────────────────────────

    COMPLETED TASKS:
    {list each task: ID, description, deliverable files}

    CODE REVIEW STATUS: {LGTM / NEEDS MINOR}

    ─────────────────────────────────────
    VERIFICATION SCOPE:
    ─────────────────────────────────────

    1. REGRESSION CHECK:
       - Run ALL test suites (all sprints, not just current)
       - Verify zero regressions: old tests still GREEN
       - Command: npm test (or npx vitest run)

    2. COVERAGE CHECK:
       - Run coverage report: npx vitest run --coverage
       - Verify ≥80% coverage for new code
       - Report gaps if below target

    3. EDGE CASES (if needed):
       - Add scenarios not covered by Batch 0
       - Add to .project/scenarios/sprint-{N}/
       - Write corresponding tests

    4. E2E VERIFICATION (if sprint has UI changes):
       - Run E2E tests: npx playwright test
       - Verify critical user flows

    5. VISUAL UI CHECK (if sprint has UI changes):
       - Start dev server: npm run dev (or npx vite)
       - Use Playwright MCP tools to navigate each page/screen
       - Take screenshot of each page state (empty, loaded, error)
       - Visually analyze each screenshot for:
         • Layout: components aligned correctly? spacing consistent?
         • Overflow: any text/content overflowing containers?
         • Responsive: does it work at different widths? (resize browser)
         • States: loading, empty, error states render correctly?
         • Interactions: buttons clickable? forms usable? modals open/close?
       - Report each visual issue with screenshot evidence

    ⚠️ CLEANUP (MANDATORY):
       - Kill any dev server you started (lsof -ti:3000 | xargs kill)
       - Verify port is free before finishing

    OUTPUT: APPROVED / NEEDS FIXES
    If NEEDS FIXES: list each issue with severity and screenshot

    AFTER COMPLETION:
    - Kill dev server if still running (lsof -ti:3000 | xargs kill 2>/dev/null)
    - Update .project/sprints/sprint-{N}.md: Task {N}.Q → [COMPLETE]
    - Update .project/state/specialists/google-qa-engineer-{N}.Q.md
  """
)
```

**If NEEDS FIXES** → PM spawns dev agents to fix → re-run QA.
**If APPROVED** → proceed to Sprint Closure.

---

# Dispatch Table Format for Batch 2 + 3

Same 5-column format (Agent/Tasks/Scope/Model/Status) as Batch 1:

```markdown
📋 [PM] Sprint {N} — Review & QA phase:

| Agent | Tasks | Scope | Model | Status |
|-------|-------|-------|-------|--------|
| Reviewer #1 | {N}.R | All sprint {N} code | sonnet | Running... |

Waiting for code review...
```

Then after review:

```markdown
📋 [PM] Sprint {N} — QA phase:

| Agent | Tasks | Scope | Model | Status |
|-------|-------|-------|-------|--------|
| QA #1 | {N}.Q | All sprint {N} code + tests | sonnet | Running... |

Waiting for QA...
```
