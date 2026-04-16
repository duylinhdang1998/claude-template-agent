# PM Bug Fix Sprint Flow

**When CEO delegates a bug report to PM, follow Steps 1-6 below.**
**Do NOT read full ba.md or hr.md — all bug-specific instructions are here.**

## ⚠️ CLASSIFICATION GUARD (check FIRST)

**Before starting bug fix flow, verify this is actually a BUG, not a feature change.**

| Signal | Type | Action |
|--------|------|--------|
| Data model changes (new types, schema refactor) | Feature Change | ❌ STOP — use normal 4-Batch Flow with BDD |
| Business logic changes (who can do what) | Feature Change | ❌ STOP — use normal 4-Batch Flow with BDD |
| New UI components or screens | Feature Change | ❌ STOP — use normal 4-Batch Flow with BDD |
| Button doesn't work, crash, UI glitch | Bug | ✅ Continue with bug fix flow |
| Data displays incorrectly | Bug | ✅ Continue with bug fix flow |
| Performance regression | Bug | ✅ Continue with bug fix flow |

**If unsure, default to Feature Change flow (with BDD).** It's safer to have BDD scenarios reviewed by user than to skip them and discover misunderstandings mid-sprint.

## Mandatory First Output

```
📋 [PM] Bug Fix Sprint - Initiating...

I will follow Steps 1-6:
□ Step 1: Read project state
□ Step 2: Bug triage — interview user about each bug
□ Step 3: Team check — verify team composition
□ Step 4: Create bug fix sprint file (create-sprint.sh)
□ Step 5: Present plan — wait for user approval
□ Step 6: SPAWN specialists — agents fix code, NOT me
```

**⛔ DO NOT analyze root causes or touch source code. That is the specialist's job.**

---

## Step 1: Read Project State

```
1. Read .project/state/pm-tracker.md → Current state
2. Read .project/sprints/ → Find last sprint number (N)
3. Read .project/documentation/tech-stack.md → Tech context
4. Read .project/documentation/team.md → Current team
```

---

## Step 2: Bug Triage Interview

**PM stays as PM. No role switch needed — all bug triage instructions are here.**

Display this interview template:

```
📋 [PM] Bug Triage — Interviewing client about each bug:

┌─────┬──────────────────────────┬──────────┐
│ Bug │ Description              │ Severity │
├─────┼──────────────────────────┼──────────┤
│ B1  │ {from user report}       │ ?        │
│ B2  │ {from user report}       │ ?        │
└─────┴──────────────────────────┴──────────┘

For each bug, I need:
1. Steps to reproduce (what did you do?)
2. Expected behavior (what should happen?)
3. Actual behavior (what happened instead?)
4. Severity: 🔴 Critical / 🟡 Major / 🟢 Minor
5. Screenshots/screen recordings (if any)
```

### Severity Guide

| Level | Meaning | Examples |
|-------|---------|---------|
| 🔴 Critical | App crashes, data loss, security hole | Login broken, payment fails |
| 🟡 Major | Feature broken but workaround exists | Button not working, wrong data displayed |
| 🟢 Minor | Cosmetic, UX annoyance | Alignment off, typo, color wrong |

### After Interview

Document bugs directly in the sprint task details (Step 4). No separate bug report file needed — use `sprint-template.md` with bug details in each task's Notes/Acceptance Criteria.

---

## Step 3: Team Check

**PM stays as PM. No role switch needed — bug team assessment instructions are here.**

### Bug Type → Specialist Mapping

| Bug Type | Likely Specialist | Check |
|----------|-------------------|-------|
| UI/CSS/Layout | meta-react-architect, apple-ux-wireframer | Frontend team member? |
| API/Backend logic | netflix-backend-architect | Backend team member? |
| Database/Query | netflix-backend-architect, amazon-cloud-architect | DB-experienced member? |
| Performance | google-sre-devops | Performance specialist? |
| Security | google-code-reviewer | Security reviewer? |
| Mobile (iOS) | apple-ios-lead | iOS team member? |
| Mobile (Android) | google-android-lead | Android team member? |

### Assessment Output

```
📋 [PM] Bug Fix Team Assessment

Current team: {from team.md}
Bug types: {UI / Backend / Database / Performance / etc.}

Assessment:
├── Can current team fix all bugs? [YES/NO]
├── Need different specialists? [list if YES]
└── Recommendation: {keep team / adjust team}
```

---

## Step 4: Create Bug Fix Sprint

```bash
bash .claude/automation/create-sprint.sh {N+1} "Bug Fixes"
```

Then Edit the sprint file with bug fix tasks:

```markdown
| ID | Task | Points | Status | Assignee | Wireframe |
|----|------|--------|--------|----------|-----------|
| {N+1}.1 | Fix: {bug A description} | 2 | | {specialist} | - |
| {N+1}.2 | Fix: {bug B description} | 3 | | {specialist} | - |
| {N+1}.R | Code Review: Sprint {N+1} | 2 | | Reviewer | - |
| {N+1}.Q | QA: Regression tests + verification | 3 | | QA | - |
```

**Bug task naming:** Always prefix with `Fix:` to distinguish from feature tasks.
**⚠️ Every bug fix sprint MUST include `{N+1}.R` and `{N+1}.Q` tasks.**

---

## Step 5: Present Bug Fix Plan to User

```markdown
📋 [PM] Bug Fix Sprint Plan

| Sprint | Focus | Bugs | Assignee |
|--------|-------|------|----------|
| Sprint {N+1} | Bug Fixes | B1, B2, ... | {team} |

Estimated effort: {X} story points

Proceed with bug fixes?
```

**Wait for user confirmation before spawning agents.**

---

## Step 6: SPAWN Specialists

**⚠️ CRITICAL: PM is a coordinator, NOT a developer!**
**PM MUST spawn specialist agents to fix bugs. PM NEVER writes fix code itself.**

Follow the **4-Batch Flow** (skip Batch 0 for bug fixes — the bug report IS the scenario. Dev writes a test that reproduces the bug, then fixes it):

### Batch 1: Dev Agents (fix tasks)

```python
Agent(
  subagent_type="{specialist from HR assessment}",
  run_in_background=true,
  prompt="""
    📋 [PM] Task Assignment

    SPRINT: Sprint {N+1}
    TASK ID: {N+1}.1
    TASK: Fix: {bug A description}

    ─────────────────────────────────────
    READ FIRST:
    - .project/documentation/tech-stack.md
    - .project/sprints/sprint-{N+1}.md
    - .project/requirements/bugs-sprint-{N+1}.md
    ─────────────────────────────────────

    BUG DETAILS:
    - Steps to reproduce: {from BA triage}
    - Expected: {expected behavior}
    - Actual: {actual behavior}
    - Severity: {🔴/🟡/🟢}

    ⚠️ SCOPE: app/{affected directory}/ (ONLY this directory!)

    AFTER COMPLETION:
    - Update .project/sprints/sprint-{N+1}.md: Task {N+1}.1 → [COMPLETE]
    - Update .project/state/specialists/{agent-type}-{N+1}.1.md
  """
)
```

Display Dispatch Status Table:

```markdown
📋 [PM] Sprint {N+1} — Bug Fixes in progress:

| Agent | Tasks | Scope | Model | Status |
|-------|-------|-------|-------|--------|
| {type} #1 | {N+1}.1 | app/{dir}/ | sonnet | Running... |
| {type} #2 | {N+1}.2 | app/{dir}/ | sonnet | Running... |

Waiting for agents to finish...
```

### Batch 2: Code Review

Spawn `google-code-reviewer` for task `{N+1}.R`
(Follow templates from PM's "Sprint Execution: 4-Batch Flow" section.)

### Batch 3: QA Testing

Spawn `google-qa-engineer` for task `{N+1}.Q`
(Follow templates from PM's "Sprint Execution: 4-Batch Flow" section.)

**⚠️ Bug Fix Sprint QA**: Always set Integration = REQUIRED, E2E = REQUIRED.
- E2E MUST reproduce each bug scenario (steps from BA triage → verify fix)
- Integration tests for any API endpoints that were modified

---

## Rules Summary

| Skips (bug fix sprint) | Keeps (bug fix sprint) |
|------------------------|----------------------|
| Sprint 0 | BA triage (Step 2 above) |
| Gate 1 check | HR team check (Step 3 above) |
| Wireframes | Specialist spawning |
| Full SRS | Code review (Batch 2) |
| | QA sign-off (Batch 3) |
