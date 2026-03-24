# BA Templates & Standards

## SRS Template

```markdown
# Software Requirements Specification

## 1. Introduction
- Purpose
- Scope
- Definitions & Acronyms

## 2. Overall Description
- Product Perspective
- Main Features
- Target Users

## 3. Functional Requirements
### FR1: [Feature 1]
**Priority**: MUST HAVE
**Requirements**:
- FR1.1: System shall...
- FR1.2: System shall...

**Acceptance Criteria**:
Given [context]
When [action]
Then [expected outcome]

## 4. Non-Functional Requirements
- Performance: API response < 500ms
- Security: OWASP Top 10 compliance
- Usability: First task < 60 seconds
- Compatibility: Chrome, Firefox, Safari, Edge

## 5. Prioritization (MoSCoW)
### MUST HAVE (60%)
### SHOULD HAVE (20%)
### COULD HAVE (15%)
### WON'T HAVE (5%)
```

---

## User Story Template

```markdown
# US-001: [Story Name]

**As a** [user role]
**I want to** [action]
**So that** [benefit]

## Acceptance Criteria

```gherkin
Scenario: [Scenario Name]
  Given [context]
  When [action]
  Then [expected outcome]
```

## Technical Notes
- [Technical notes]

## Dependencies
- [Dependent stories]

## Estimation
- Story Points: [1-8]
- Priority: MUST/SHOULD/COULD
```

---

## UAT Test Scenario Template

```markdown
## Test Scenario: [Scenario Name]

**Objective**: [Test objective]

**Preconditions**:
- User is logged in
- [Precondition]

**Steps**:
1. Navigate to [page]
2. Click [button]
3. Enter [data]
4. Submit

**Expected Results**:
- [Expected result 1]
- [Expected result 2]

**Pass/Fail**: _____
**Comments**: _____
**Tested By**: _____
**Date**: _____
```

---

## Project Context Template

```markdown
# Project Context - {PROJECT_NAME}

## Client Q&A History

### Session 1 (YYYY-MM-DD)
**Q1**: [Question asked]
**A1**: [Client answer]

**Q2**: [Question asked]
**A2**: [Client answer]

## Design Decisions
| Decision | Rationale | Date |
|----------|-----------|------|
| SQLite over PostgreSQL | Single user, simpler deployment | 2026-03-17 |

## Client Preferences
- Language: Vietnamese
- Style: Modern, clean UI
- Colors: [preferences]

## Constraints
- Timeline: 4-6 weeks
- Budget: [if specified]
- Technical: [any limitations]

## Scope Changes
| Change | Status | Date |
|--------|--------|------|
| Added export PDF | Approved | 2026-03-18 |

## Sprint 0 Decisions
- Wireframes = Yes | No | External (link)
- Tech Stack = APPROVED | Modified: [changes]
- Team = APPROVED | Modified: [changes]
```

**⚠️ IMPORTANT**: Sprint 0 Decisions format must match script pattern:
- `Wireframes = Yes` → wireframes required
- `Wireframes = No` or `Wireframes.*Skip` → wireframes skipped
- This is checked by `generate-progress-dashboard.sh` for Phase 1 planning %

---

## MoSCoW Prioritization

| Priority | % | Meaning | Example |
|----------|---|---------|---------|
| **MUST** | 60% | Critical for MVP, cannot launch without | User auth, core CRUD |
| **SHOULD** | 20% | Important, workarounds exist | Search, filters |
| **COULD** | 15% | Nice-to-have if time permits | Export, themes |
| **WON'T** | 5% | Explicitly out of scope for v1 | Mobile app, AI features |

---

## Scope Management (Change Requests)

When client requests changes:

```
1. DOCUMENT the request
   - What is being requested?
   - Why is it needed?
   - Who requested it?

2. ASSESS IMPACT
   - Time: +X days/weeks
   - Cost: +$X
   - Risk: Low/Medium/High

3. PRESENT OPTIONS
   Option A: Add to current scope (+2 weeks)
   Option B: Defer to Phase 2 (no delay)
   Option C: Replace existing feature (no delay)

4. GET APPROVAL
   - CEO sign-off required for major changes
   - Update SRS document

5. UPDATE DOCUMENTATION
   - Update requirements
   - Update user stories
   - Notify team
```

---

## Communication Matrix

| Role | Communication |
|------|---------------|
| **CEO** | Weekly status, scope changes, major decisions |
| **CTO** | Technical feasibility review, requirements validation |
| **PM** | Daily sync, sprint planning, backlog refinement |
| **QA** | UAT scenarios, acceptance criteria validation |
| **Developers** | Requirements clarification, story details |

---

## Amazon BA Standards

1. **Work Backwards from Customer**: Start with customer benefit, write "press release" first
2. **Be Precise**: No ambiguity, all requirements testable
3. **Document Everything**: If not written, doesn't exist
4. **Manage Expectations**: Under-promise, over-deliver
5. **Prioritize Ruthlessly**: Can't build everything, focus on value
6. **One Source of Truth**: All requirements in SRS
