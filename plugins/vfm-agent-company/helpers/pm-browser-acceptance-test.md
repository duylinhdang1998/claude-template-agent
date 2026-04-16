# PM Browser Acceptance Test (BAT)

**Visual verification via Playwright MCP — PM drives the browser, user watches.**

## When to Run

| Trigger | Required? |
|---------|-----------|
| **Final sprint complete** (all sprints done) | ✅ MANDATORY |
| Feature change sprint complete | ✅ MANDATORY |
| Regular sprint complete (not final) | Optional — run if user requests |

## Prerequisites

- All Quality Gates passed (tests GREEN, code review LGTM, QA APPROVED)
- Dev server can start (`npm run dev` or equivalent)

## Flow

```
📋 [PM] Browser Acceptance Test — Starting...

1. Start dev server
2. Open browser via Playwright
3. Clear localStorage (fresh state)
4. Walk through user stories from sprint(s)
5. Report results to user
```

## Step-by-Step

### Step 1: Start Dev Server

```
PM checks if dev server is running (lsof -ti:{port}).
If not running → start it (npm run dev).
Wait for server to be ready.
```

### Step 2: Open Browser

```
Use Playwright MCP tools:
- browser_navigate → app URL
- browser_snapshot → verify page loaded
```

### Step 3: Clear State

```
Use browser_evaluate:
- localStorage.clear()
- Navigate again to get fresh state
```

### Step 4: Walk Through User Stories (EVERY SINGLE ONE)

**⚠️ MANDATORY: PM MUST test EVERY user story. No exceptions. No skipping.**

**Before testing, PM MUST build a checklist from `.project/requirements/user-stories.md`:**

```markdown
📋 [PM] BAT Checklist (from user-stories.md):

| # | Story | Test Action | Result |
|---|-------|------------|--------|
| US-001 | {title} | {action} | ⬜ |
| US-002 | {title} | {action} | ⬜ |
| ... | ... | ... | ⬜ |

⚠️ ALL rows must be ✅ or ❌ before BAT can be declared complete.
   Any ⬜ (untested) = BAT INCOMPLETE = cannot report to CEO.
```

For each user story:
1. Announce: `📋 [PM] Testing US-XXX: {story title}`
2. Perform actions via Playwright MCP tools:
   - `browser_fill_form` — fill inputs
   - `browser_click` — click buttons
   - `browser_drag` — drag & drop interactions
   - `browser_snapshot` — verify state after action
   - `browser_select_option` — dropdowns
   - `browser_run_code` — complex interactions (multi-step drag, etc.)
3. Verify expected outcome from snapshot
4. Report: ✅ PASS or ❌ FAIL with details

**Test priority order:**
1. Happy path flows first (create, read, update)
2. Key interactions (drag & drop, search, export, navigation)
3. Edge cases (empty states, validation)

**⚠️ If a user story involves physical interaction (drag, swipe, resize):**
- MUST test the actual interaction, not just the data result
- Use `browser_run_code` for complex mouse sequences if `browser_drag` is insufficient

### Step 5: Report Results

```markdown
📋 [PM] Browser Acceptance Test Results

| # | User Story | Test | Result |
|---|-----------|------|--------|
| 1 | US-001: {title} | {action tested} | ✅ PASS |
| 2 | US-002: {title} | {action tested} | ✅ PASS |
| 3 | US-003: {title} | {action tested} | ❌ FAIL — {what went wrong} |

Overall: X/Y tests passed

{If all pass}
📋 [PM] All browser tests passed. Reporting to CEO for final sign-off.

{If any fail}
📋 [PM] X failures found. Creating fix tasks before delivery.
```

## Playwright MCP Tools Quick Reference

| Action | Tool | Example |
|--------|------|---------|
| Open page | `browser_navigate` | url: "http://localhost:5173" |
| See page state | `browser_snapshot` | (no params) |
| Fill form | `browser_fill_form` | fields: [{name, type, ref, value}] |
| Click button | `browser_click` | ref: "e27", element: "Submit" |
| Select dropdown | `browser_select_option` | ref, value |
| Run JS | `browser_evaluate` | function: "() => localStorage.clear()" |
| Take screenshot | `browser_take_screenshot` | type: "png", filename: ".project/bat/{name}.png" |
| Check console | `browser_console_messages` | (no params) |

## Important Notes

- **PM drives the browser directly** — do NOT spawn an agent for this
- **User is watching** — announce each test clearly before performing it
- **Use snapshots, not screenshots** — snapshots show interactive elements with refs
- **Fresh state** — always clear localStorage before testing
- **Report incrementally** — show each test result as you go, don't batch at end
- **Screenshots go to `.project/bat/`** — ALWAYS use `filename: ".project/bat/{name}.png"` in `browser_take_screenshot`. NEVER save to project root.
