# Team Composition - [PROJECT_NAME]

**Complexity**: [Simple / Standard / Complex / Enterprise]
**Duration**: [X weeks/months]
**Team Size**: [N] specialists

---

## Core Roles (Not Spawned)

These roles are handled by the main agent reading role instructions:

| Role | Phase | File | Responsibility |
|------|-------|------|----------------|
| CEO | 1, 7 | `core/ceo.md` | Approval, sign-off |
| CTO | 2a | `core/cto.md` | Tech stack, architecture |
| HR | 2a | `core/hr.md` | Team composition |
| BA | 1 | `core/ba.md` | Requirements gathering |
| PM | All | `core/pm.md` | Sprint planning, coordination |

---

## Specialists (Spawned)

These are actual agents spawned for parallel execution:

| Specialist | Role | Phases | Primary Skills |
|------------|------|--------|----------------|
| `apple-ux-wireframer` | UX Design | 2b | Wireframes, user flows |
| `meta-react-architect` | Frontend | 3 | React, Next.js, TailwindCSS |
| `netflix-backend-architect` | Backend | 3 | Node.js, Prisma, APIs |
| `google-qa-engineer` | QA | 4 | Jest, Playwright, E2E |
| `netflix-devops-engineer` | DevOps | 5-6 | Vercel, CI/CD, Docker |

---

## SDLC Phase Coverage

```
PHASE COVERAGE VERIFICATION:
├── Phase 1 (Requirements).... [Role/Specialist] [✅/❌]
├── Phase 2a (Architecture)... [Role/Specialist] [✅/❌]
├── Phase 2b (UX Design)...... [Role/Specialist] [✅/⏭️ SKIPPED/❌]
├── Phase 3 (Development)..... [Specialists] [✅/❌]
├── Phase 4 (Testing)......... [Specialist] [✅/❌]
├── Phase 5 (Packaging)....... [Specialist] [✅/❌]
├── Phase 6 (Deployment)...... [Specialist] [✅/❌]
└── Phase 7 (Release)......... [Role] [✅/❌]

STATUS: [✅ ALL CHECKS PASSED / ❌ MISSING COVERAGE]
```

---

## Specialist Responsibilities

### [specialist-name] (Role)

**Responsibilities**:
- [Responsibility 1]
- [Responsibility 2]
- [Responsibility 3]

**Deliverables**:
- `path/to/file1`
- `path/to/file2`

---

## Team Size Guidelines

| Complexity | Team Size | Duration |
|------------|-----------|----------|
| Simple | 3-4 specialists | 1-2 weeks |
| Standard | 5-6 specialists | 1-2 months |
| Complex | 6-8 specialists | 2-4 months |
| Enterprise | 8-12 specialists | 4-12 months |

---

## Communication Matrix

| From → To | Channel | Frequency |
|-----------|---------|-----------|
| PM → Specialists | Task assignments | Per sprint |
| Specialists → PM | Progress updates | Daily |
| PM → CEO | Milestone reports | Per sprint |
| Frontend ↔ Backend | API contracts | As needed |
| QA → All | Bug reports | As found |

---

## Code Review

After each task completion:
- `google-code-reviewer` reviews code
- Must get LGTM before task marked complete
- Focus: TypeScript, security, performance

---

**Created**: [DATE]
**Last Updated**: [DATE]
