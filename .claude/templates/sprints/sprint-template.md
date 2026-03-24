# Sprint {N}: {Sprint Name}

**Sprint**: {N} of {TOTAL}
**Duration**: Week {X}-{Y} ({START_DATE} to {END_DATE})
**Goal**: {One-line sprint goal - what user can do after this sprint}
**Status**: PLANNED | IN_PROGRESS | COMPLETE

---

## Task Details

<!--
DETAILED SECTIONS: Human-readable task breakdown
Each task has deliverables, acceptance criteria, and time tracking
-->

### Task {N}.1: {Task Name} [{Assignee}]
**Status**: [NOT STARTED] | [IN PROGRESS] | [COMPLETE]
**Estimated**: {X} hours | **Actual**: - hours
**Story Points**: {1-8}
**Wireframe**: {filename.md | - }

**Deliverables**:
- [ ] {file path 1}
- [ ] {file path 2}
- [ ] {file path 3}

**Acceptance Criteria**:
- [ ] [FR-XXX] {Requirement from SRS}
- [ ] [FR-YYY] {Another requirement}

**Notes**: {Technical decisions, dependencies, blockers}

---

### Task {N}.2: {Task Name} [{Assignee}]
**Status**: [NOT STARTED]
**Estimated**: {X} hours | **Actual**: - hours
**Story Points**: {1-8}
**Wireframe**: {filename.md | - }

**Deliverables**:
- [ ] {file path 1}

**Acceptance Criteria**:
- [ ] [FR-XXX] {Requirement}

---

<!-- Add more tasks as needed -->

---

## Sprint Backlog (Machine-Parseable)

<!--
IMPORTANT: This table is parsed by scripts (generate-progress-dashboard.sh)
- ID format: {sprint}.{task} (e.g., 1.1, 1.2)
- Status: empty | [IN PROGRESS] | [COMPLETE] | [BLOCKED]
- Points: 1-8 (story points)
- Assignee: Frontend | Backend | QA | DevOps | UX
- Wireframe: filename.md or -

DO NOT change column order! Scripts depend on exact format.
-->

| ID | Task | Points | Status | Assignee | Wireframe |
|----|------|--------|--------|----------|-----------|
| {N}.1 | {Task name} | {pts} | | {Role} | {-.md} |
| {N}.2 | {Task name} | {pts} | | {Role} | {-.md} |

---

## Sprint Summary

| Metric | Value |
|--------|-------|
| Total Tasks | {count} |
| Story Points | {total} |
| Estimated Hours | {total_hours}h |
| Actual Hours | {actual_hours}h |
| Velocity | {percent}% |

| Role | Tasks | Points | Hours |
|------|-------|--------|-------|
| Frontend | {count} | {pts} | {hours}h |
| Backend | {count} | {pts} | {hours}h |
| QA | {count} | {pts} | {hours}h |
| DevOps | {count} | {pts} | {hours}h |

---

## Definition of Done

<!--
SPRINT-SPECIFIC DoD: What THIS sprint must achieve
NOT generic checkboxes - actual testable outcomes
-->

### Functional Criteria
- [ ] {Specific feature works: e.g., "User can view family tree with 50+ nodes"}
- [ ] {Another feature: e.g., "Clicking node opens detail panel"}
- [ ] {Another feature: e.g., "Zoom in/out works with mouse wheel"}

### Technical Criteria
- [ ] All tasks marked [COMPLETE] in Sprint Backlog
- [ ] Code reviewed (LGTM from google-code-reviewer)
- [ ] No TypeScript errors (`npm run build` passes)
- [ ] No ESLint errors (`npm run lint` passes)
- [ ] Unit tests written for new code

### Quality Criteria
- [ ] {Sprint-specific quality: e.g., "Tree renders in <1 second"}
- [ ] {Another quality: e.g., "No console errors in browser"}

---

## Dependencies

<!--
NOTE: Use "Task X.Y" format (not bare "X.Y") to avoid false parsing by progress scripts
-->

| Dependency | Reason | Status |
|------------|--------|--------|
| Task {N}.X → {M}.Y | {Why dependency exists} | Resolved / Pending |

---

## Risks & Blockers

| # | Type | Description | Impact | Mitigation | Owner | Status |
|---|------|-------------|--------|------------|-------|--------|
| 1 | Risk | {Potential issue} | {H/M/L} | {Plan} | {Name} | Open |
| - | - | None identified | - | - | - | - |

---

## Notes

- {Important context for this sprint}
- {Technical decisions made}
- {Coordination needed between specialists}

---

## Sprint Retrospective

<!--
Fill this out AFTER sprint completes
-->

### What Went Well
- {Positive outcome 1}
- {Positive outcome 2}

### What Needs Improvement
- {Issue 1 and how to fix}
- {Issue 2 and how to fix}

### Carry Over to Next Sprint
- {Incomplete task or scope change}

### Time Analysis
| Metric | Estimated | Actual | Variance |
|--------|-----------|--------|----------|
| Total Hours | {X}h | {Y}h | {+/-Z}h |
| Velocity | 100% | {actual}% | - |

---

## Reference

### Task ID Format
**Format**: `{sprint}.{task}` (e.g., 1.1, 1.2, 2.1)

### Status Values
| Status | Task Details | Sprint Backlog Table |
|--------|--------------|----------------------|
| Not started | `[NOT STARTED]` | (empty) |
| In progress | `[IN PROGRESS]` | `[IN PROGRESS]` |
| Complete | `[COMPLETE]` | `[COMPLETE]` |
| Blocked | `[BLOCKED]` | `[BLOCKED]` |
| Deferred | - | `→ Sprint N` |

### Assignee Values
| Assignee | Specialist | Skills |
|----------|------------|--------|
| Frontend | meta-react-architect | React, Next.js, TailwindCSS |
| Backend | netflix-backend-architect | Node.js, Prisma, APIs |
| QA | google-qa-engineer | Jest, Playwright, E2E |
| DevOps | netflix-devops-engineer | Vercel, CI/CD, Docker |
| UX | apple-ux-wireframer | Wireframes, Figma |

### Story Points Guide
| Points | Complexity | Time Estimate |
|--------|------------|---------------|
| 1 | Trivial | < 1 hour |
| 2 | Simple | 1-2 hours |
| 3 | Medium | 2-4 hours |
| 5 | Complex | 4-8 hours |
| 8 | Very Complex | 8-16 hours |
