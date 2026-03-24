# Sprint Task Format Standard

**Version**: 2.1
**Last Updated**: 2026-03-17

---

## Purpose

This document defines the **mandatory format** for sprint task tables to ensure automation scripts can accurately track progress.

---

## Task Table Format

### Required Columns

```markdown
| ID | Task | Points | Status | Assignee | Wireframe |
|----|------|--------|--------|----------|-----------|
| 1.S | BDD Scenarios: Sprint 1 | 2 | [COMPLETE] | QA | - |
| 1.1 | Task name here | 3 | [COMPLETE] | Frontend | - |
| 1.R | Code Review: Sprint 1 | 2 | | Reviewer | - |
| 1.Q | QA Verification: Sprint 1 | 2 | | QA | - |
```

### Column Definitions

| Column | Format | Example |
|--------|--------|---------|
| **ID** | `{sprint}.{task}` | `1.1`, `1.10`, `2.3` |
| **Task** | Free text | `Initialize Next.js 14 project` |
| **Points** | Integer 1-8 | `3`, `5`, `8` |
| **Status** | See status formats below | `[COMPLETE]` |
| **Assignee** | Role name | `Frontend`, `Backend`, `QA` |
| **Wireframe** | Filename or `-` | `home.md`, `-` |

---

## ID Format (MANDATORY)

**Pattern**: `{sprint_number}.{task_number}`

| Example | Meaning |
|---------|---------|
| `1.1` | Sprint 1, Task 1 |
| `1.10` | Sprint 1, Task 10 |
| `2.3` | Sprint 2, Task 3 |

**Special IDs:**
- `{N}.S` = BDD Scenario generation (QA Batch 0) — MANDATORY
- `{N}.R` = Code Review (Batch 2) — MANDATORY
- `{N}.Q` = QA Verification (Batch 3) — MANDATORY

**Rules:**
- Sprint number matches the sprint file (sprint-1.md → `1.x`)
- Task numbers are sequential within each sprint
- Start at `.1` for each sprint

---

## Status Format (MANDATORY)

| Status | Format | When to Use |
|--------|--------|-------------|
| Not Started | (empty or no tag) | Task not yet begun |
| In Progress | `[IN PROGRESS]` | Currently working |
| Complete | `[COMPLETE]` | Task finished and verified |
| Blocked | `[BLOCKED]` | Cannot proceed (add reason) |
| Deferred | `→ Sprint N` | Moved to later sprint |

### Examples

```markdown
| ID | Task | Points | Status | Assignee | Wireframe |
|----|------|--------|--------|----------|-----------|
| 1.1 | Initialize Next.js 14 | 2 | [COMPLETE] | Backend | - |
| 1.2 | Set up Prisma schema | 3 | [IN PROGRESS] | Backend | - |
| 1.3 | Add authentication | 3 | | Backend | - |
| 1.4 | Tree visualization | 5 | [BLOCKED] | Frontend | tree.md |
| 1.5 | Performance optimization | 3 | → Sprint 2 | Frontend | - |
```

---

## Scripts That Parse Sprint Files

These automation scripts depend on this format:

1. **`auto-sync-progress.sh`** - Calculates overall progress
2. **`generate-progress-dashboard.sh`** - Generates visual dashboard
3. **`validate-sprint-on-edit.sh`** - Validates format on save

### Task ID Pattern (Regex)

```regex
^\| [0-9]+\.[0-9]+ \|
```

### Completed Status Patterns (Regex)

```regex
\[COMPLETE\]|COMPLETE
```

---

## Sprint File Structure

### Required Sections (MANDATORY)

Every sprint file MUST contain these sections **in order**:

| # | Section | Required | Purpose |
|---|---------|----------|---------|
| 1 | Header | ✅ | Project ID, Sprint N of M, Duration, Goal, Status |
| 2 | `## Task Details` | ✅ | Detailed task breakdown with deliverables, acceptance criteria |
| 3 | `## Sprint Backlog` | ✅ | Machine-parseable table for automation |
| 4 | `## Sprint Summary` | ✅ | Metrics: Total tasks, points, hours |
| 5 | `## Definition of Done` | ✅ | Exit criteria for this sprint |
| 6 | `## Dependencies` | ✅ | Cross-task/sprint dependencies |
| 7 | `## Risks & Blockers` | ✅ | Risk register |
| 8 | `## Notes` | ✅ | Sprint-specific context |
| 9 | `## Sprint Retrospective` | ⚠️ Optional (fill after sprint) | What went well, improvements |
| 10 | `## Reference` | ⚠️ Optional | Task ID format, status values guide |

### Task Details Format (MANDATORY)

Each task in `## Task Details` MUST follow this format:

```markdown
### Task {N}.{M}: {Task Name} [{Assignee}]
**Status**: [NOT STARTED] | [IN PROGRESS] | [COMPLETE]
**Estimated**: {X} hours | **Actual**: {Y} hours
**Story Points**: {1-8}
**Wireframe**: {filename.md | - }

**Deliverables**:
- [ ] {file path 1}
- [x] {file path 2}  ← check when completed

**Acceptance Criteria**:
- [ ] [FR-XXX] {Requirement from SRS}
- [x] {Another criterion}  ← check when verified

**BDD Scenario**: `.project/scenarios/sprint-{N}/{task-id}-{name}.feature`

**Notes**: {Optional technical notes}
```

### ⚠️ Checkbox Consistency Rule (MANDATORY)

**When marking Status [COMPLETE], ALL checkboxes MUST be checked:**

```markdown
# ❌ WRONG - Status complete but checkboxes unchecked
**Status**: [COMPLETE]
**Deliverables**:
- [ ] app/components/Form.tsx  ← still unchecked!

# ✅ CORRECT - All checkboxes match status
**Status**: [COMPLETE]
**Deliverables**:
- [x] app/components/Form.tsx  ← checked!
```

**Specialists MUST:**
1. Check `[x]` for each completed Deliverable
2. Check `[x]` for each met Acceptance Criterion
3. Fill **Actual**: hours spent
4. THEN set **Status**: [COMPLETE]

### Sprint Backlog Table

```markdown
## Sprint Backlog

| ID | Task | Points | Status | Assignee | Wireframe |
|----|------|--------|--------|----------|-----------|
| N.S | BDD Scenarios: Sprint N | 2 | | QA | - |
| N.1 | Task description | X | | Role | - |
| N.R | Code Review: Sprint N | 2 | | Reviewer | - |
| N.Q | QA Verification: Sprint N | 2 | | QA | - |
```

### Validation

**Scripts check for:**
1. ✅ Sprint Backlog table format (existing)
2. ✅ Required sections presence (NEW)
3. ✅ Task Details for each task in Backlog (NEW)

---

## Definition of Done Rules (MANDATORY)

**DoD must ONLY contain criteria for THIS sprint.**

### ❌ WRONG - Deferred items in DoD

```markdown
## Definition of Done

- [x] Code reviewed
- [ ] Unit tests written (80% coverage) - Sprint 2  ← WRONG!
- [x] No TypeScript errors
```

### ✅ CORRECT - Only this sprint's criteria

```markdown
## Definition of Done

- [x] Code reviewed
- [x] No TypeScript errors
- [x] All API endpoints functional
```

### Rules

1. **No deferred items** - If it's "→ Sprint N", remove from DoD
2. **No unchecked items with sprint references** - `- [ ] ... - Sprint N` is invalid
3. **All items must be achievable THIS sprint**
4. **DoD = exit criteria, not wishlist**

### Validation Pattern

Hook will BLOCK if DoD contains: `- \[ \].*Sprint [0-9]`

---

## Validation

```bash
bash .claude/automation/validate-sprint-format.sh
```

---

## Changelog

- **2.1** (2026-03-17): Standardized on `X.Y` format with `[COMPLETE]` status
- **2.0** (2026-03-17): Attempted PREFIX-NN format (reverted)
- **1.0** (2026-03-16): Initial version
