# VFM Agent Company

> An autonomous AI software company powered by Claude Code — BDD-driven development with FAANG specialists

[![Claude Code](https://img.shields.io/badge/Powered%20by-Claude%20Code-blue)](https://github.com/anthropics/claude-code)

## Install (Claude Code Plugin)

This repo is a Claude Code **plugin marketplace**. Install with:

```bash
/plugin marketplace add duylinhdang1998/claude-template-agent
/plugin install vfm-agent-company@vfm-agent-marketplace
```

Then start using:

```bash
/work "Build an e-commerce platform with Stripe payments"
```

## What Is This?

VFM Agent Company is an **autonomous AI software company** that operates like a real tech company. It has a CEO, CTO, HR, PM, BA, and 17 elite specialists from Meta, Google, Apple, Amazon, Netflix, and Microsoft.

### Option 1: Run directly in Claude Code

```bash
/work "Build an e-commerce platform with Stripe payments"
```

### Option 2: Open the Company Panel

```bash
/company start
```

Opens a real-time management dashboard in your browser with core roles, specialist agents, project progress, and an **integrated terminal** — run `/work` and other commands directly from there.

```bash
/company stop           # Close the panel when done
```

**The company handles everything:**
- CEO approves scope and complexity
- BA gathers requirements with **Given/When/Then** acceptance criteria
- CTO designs **File Blueprint** (exact file structure, naming, responsibilities)
- HR composes the right team (with dynamic hiring for any technology)
- PM plans sprints with Gate validation
- QA generates **BDD scenarios** → User approves → CONTRACT
- Dev agents build with **TDD loop** (Red → Green → Done)
- Code reviewer checks architecture compliance + code quality
- QA verifies regression + coverage + **visual UI check**
- DevOps deploys the result

---

## BDD-Driven Development

The system guarantees code does what user wants through a **verifiable contract chain**:

```
1. BA writes Given/When/Then         → requirements are unambiguous
2. QA generates .feature scenarios   → contract is executable
3. User approves scenarios           → "this is exactly what I want"
4. Dev codes with TDD loop           → code MUST pass scenarios (self-correcting)
5. Build passes                      → code compiles
6. Code Review checks architecture   → code follows File Blueprint + Clean Code
7. QA regression + visual check      → nothing breaks, UI looks correct
```

**Bug only happens when**: scenario wasn't written. Mitigated by QA adding edge cases + user reviewing scenarios.

---

## Architecture

### Two-Tier Agent System

```
┌───────────────────────────────────────────────────────────────────┐
│                            X Company                              │
│                                                                   │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │           TIER 1 — CORE ROLES (READ, not spawned)           │  │
│  │                                                             │  │
│  │  🎯 CEO       🏗️ CTO       📋 PM       👥 HR       📊 BA      │  │
│  │  Approve     Tech Stack  Orchestrate Team       Require-    │  │
│  │  & Delegate  File Blue-  & Spawn     Composition ments      │  │
│  │              print                              (G/W/T)     │  │
│  └──────────────────────────┬──────────────────────────────────┘  │
│                             │                                     │
│                    PM spawns via Agent tool                       │
│                             │                                     │
│  ┌──────────────────────────┴──────────────────────────────────┐  │
│  │              TIER 2 — SPECIALISTS (spawned)                 │  │
│  │                                                             │  │
│  │  Frontend  Backend  UX  QA  Code Review  DevOps  AI/ML     │  │
│  │                                                             │  │
│  │  17 built-in  +  Dynamic Hiring = unlimited specialists     │  │
│  └─────────────────────────────────────────────────────────────┘  │
└───────────────────────────────────────────────────────────────────┘
```

### BDD-Driven Development Flow

BDD is the **spine** connecting all agents — human-readable AND machine-executable.

```
┌─────────────────────────────────────────────────────────────────┐
│                  BDD-DRIVEN DEVELOPMENT FLOW                    │
│                                                                 │
│  User: "I want to add items to cart"                            │
│                    ↓                                            │
│  ┌──────────────────────────────────────────────────┐           │
│  │ BATCH 0: QA Agent generates BDD scenarios        │           │
│  │                                                  │           │
│  │   Feature: Shopping Cart                         │           │
│  │                                                  │           │
│  │   @unit                                          │           │
│  │   Scenario: Add item to empty cart               │           │
│  │     Given the cart is empty                      │           │
│  │     When I add "T-Shirt" qty 2 at $29.99         │           │
│  │     Then cart total should be $59.98             │           │
│  │                                                  │           │
│  │   @e2e                                           │           │
│  │   Scenario: Add item from product page           │           │
│  │     Given I am on product "T-Shirt" page         │           │
│  │     When I click "Add to Cart"                   │           │
│  │     Then cart badge shows "1"                    │           │
│  │                                                  │           │
│  │   Output:                                        │           │
│  │   ├── .project/scenarios/sprint-N/*.feature      │           │
│  │   ├── src/__tests__/cart.test.ts (skeleton)      │           │
│  │   └── src/e2e/cart.spec.ts (skeleton)            │           │
│  └──────────────────────────────────────────────────┘           │
│                    ↓                                            │
│  ┌──────────────────────────────────┐                           │
│  │ User reviews & approves          │ ← only human checkpoint  │
│  │ "Yes, this is what I want"       │                           │
│  │ Scenarios become CONTRACT        │                           │
│  └──────────────────────────────────┘                           │
│                    ↓                                            │
│  ┌──────────────────────────────────────────────────┐           │
│  │ BATCH 1: Dev Agent — TDD self-correcting loop    │           │
│  │                                                  │           │
│  │   Dev receives: task + .feature + skeleton test  │           │
│  │                    ↓                             │           │
│  │   ┌─────────────────────────────────────┐        │           │
│  │   │ 1. Read .feature → understand what  │        │           │
│  │   │ 2. Write implementation code        │        │           │
│  │   │ 3. Run tests: npm test              │        │           │
│  │   │         ↓                           │        │           │
│  │   │    Red? → Fix code → Run again      │        │           │
│  │   │         ↓                           │        │           │
│  │   │    Green? → DONE ✅                 │        │           │
│  │   └─────────────────────────────────────┘        │           │
│  │                                                  │           │
│  │   Task NOT complete until ALL tests GREEN        │           │
│  └──────────────────────────────────────────────────┘           │
│                    ↓                                            │
│  ┌──────────────────────────────────────────────────┐           │
│  │ BATCH 2: Code Review (6-area checklist)          │           │
│  │                                                  │           │
│  │  1. Architecture — files match File Blueprint?   │           │
│  │  2. Code Quality — Clean Code, DRY, SOLID?       │           │
│  │  3. TypeScript — no any, proper types?           │           │
│  │  4. Performance — unnecessary re-renders?        │           │
│  │  5. BDD — tests match .feature scenarios?        │           │
│  │  6. Integration — no circular deps?              │           │
│  │                                                  │           │
│  │  Reviewer loads tech skills first:               │           │
│  │  (react-expert, typescript-master, etc.)         │           │
│  │                                                  │           │
│  │  Output: LGTM / NEEDS MINOR / NEEDS MAJOR        │           │
│  └──────────────────────────────────────────────────┘           │
│                    ↓                                            │
│  ┌──────────────────────────────────────────────────┐           │
│  │ BATCH 3: QA Verification                         │           │
│  │                                                  │           │
│  │  1. Regression — ALL old tests still GREEN?      │           │
│  │  2. Coverage — ≥80% for new code?                │           │
│  │  3. Edge cases — add missing scenarios           │           │
│  │  4. E2E — Playwright user flows                  │           │
│  │  5. Visual UI — screenshot + analyze layout      │           │
│  │     ├── Overflow? Misalignment?                  │           │
│  │     ├── Responsive (mobile/tablet/desktop)?      │           │
│  │     └── Loading/error/empty states?              │           │
│  │                                                  │           │
│  │  Output: APPROVED / NEEDS FIXES                  │           │
│  └──────────────────────────────────────────────────┘           │
│                    ↓                                            │
│  ✅ Sprint Complete — Sprint Complete — all scenarios verified  │
└─────────────────────────────────────────────────────────────────┘
```

**Why BDD for AI agents?**

| Reason | Explanation |
|--------|------------|
| **Gherkin = natural language** | LLM generates and understands Given/When/Then perfectly |
| **Spec = Executable** | Agent self-verifies output, no human needed to check |
| **Unambiguous** | Each scenario = 1 test case, reduces hallucination |
| **Self-correcting loop** | Code → run test → fail → fix → pass (automatic) |

**Test levels from BDD scenarios:**

| Scenario tag | Test level | Location | Framework |
|-------------|-----------|----------|-----------|
| `@unit` | Unit | `src/__tests__/*.test.ts` | Vitest |
| `@integration` | Integration | `src/__tests__/integration/*.test.ts` | Vitest + Supertest |
| `@e2e` | E2E | `src/e2e/*.spec.ts` | Playwright |

### Project Lifecycle

```
Phase 1: CEO Approval
├── Analyze requirements, determine complexity tier
└── Delegate to PM

Phase 2: Sprint 0 (Planning - No Code)
├── BA: Gather requirements → SRS + User Stories (Given/When/Then)
├── Sprint 0 Checkpoints (user confirms):
│   ├── Wireframes: Yes / No / External?
│   ├── Tech Stack: Accept / Modify?
│   └── Team: Accept / Modify?
├── CTO: Finalize tech-stack.md + architecture.md (with File Blueprint)
├── HR: Finalize team.md + verification checklist
├── PM: Plan ALL sprints → Full roadmap → User approves
└── Gate 1 validation (all artifacts exist)

Phase 3: Development (Sprint 1+ — 4-Batch Flow per sprint)
├── Batch 0: QA generates BDD scenarios → User approves CONTRACT
├── Batch 1: Dev agents code with TDD loop → All tests GREEN
├── Batch 2: Code Review → Architecture + quality compliance
├── Batch 3: QA Verification → Regression + coverage + visual UI check
└── Sprint Closure → Report to CEO
```

---

## 4-Batch Flow (per sprint)

```
Batch 0: BDD SCENARIOS
  QA reads user stories → generates .feature files + skeleton tests
  PM presents scenarios → User approves → CONTRACT
       ↓
Batch 1: DEV + TDD
  Dev receives: task + .feature + skeleton test
  Dev codes → runs tests → Red? Fix → Green → DONE
  (self-correcting loop — task NOT complete if tests RED)
       ↓
Batch 2: CODE REVIEW
  Reviewer checks 6 areas:
  Architecture compliance, Code quality, TypeScript/Security,
  Performance, BDD compliance, Integration
       ↓
Batch 3: QA VERIFICATION
  Run full test suite (regression), coverage ≥80%,
  Visual UI check (Playwright screenshots → analyze layout/overflow/responsive)
       ↓
Sprint Complete
```

### Quality Gates

| Gate | Requirement | Batch |
|------|-------------|-------|
| BDD Scenarios | User approved .feature files | Batch 0 |
| BDD Tests GREEN | All scenarios pass | Batch 1 |
| Build | `npm run build` SUCCESS | Batch 1 |
| Code Review | LGTM from google-code-reviewer | Batch 2 |
| Regression | All tests GREEN, ≥80% coverage | Batch 3 |
| Visual UI | No layout/overflow/responsive issues | Batch 3 |

---

## CTO File Blueprint

CTO designs architecture down to **file level** — Dev agents follow this as their map:

```
src/
├── types/
│   └── member.ts              # Member, MemberFormData interfaces
├── stores/
│   └── familyStore.ts         # useFamilyStore — CRUD + tree state
├── components/
│   ├── tree/
│   │   ├── FamilyTree.tsx     # Main tree (ReactFlow)
│   │   └── MemberNode.tsx     # Single node — name, photo, dates
│   ├── member/
│   │   ├── MemberDetail.tsx   # Slide-in panel — read-only info
│   │   └── MemberForm.tsx     # Add/edit form — Zod validation
│   └── shared/
│       └── Modal.tsx          # Reusable — controlled via isOpen prop
├── hooks/
│   └── useTreeLayout.ts       # Calculate node positions
├── utils/
│   └── validation.ts          # Zod schemas
└── __tests__/
    └── family-store.test.ts
```

**Every file = 1-line responsibility. Dev doesn't decide where to put files — CTO already decided.**

---

## Directory Structure

```
.claude/
├── AGENT.md                    # Core guidelines (all agents MUST read)
├── settings.json               # System configuration
├── core/                       # Tier 1: Core Roles (READ, not spawned)
├── agents/                     # Tier 2: Specialists (17 agents, SPAWNED)
├── helpers/                    # Process helpers (BDD workflow, batch templates, ...)
├── automation/                 # Scripts: init-project, create-sprint, validate-gate
├── hooks/                      # Runtime hooks (sprint validation, git, wireframe, BDD)
├── monitor/                    # Company panel: dashboard + terminal (/company start)
├── skills/                     # Skill modules (React, AWS, Prisma, QA, ...)
└── templates/                  # Templates for docs, sprints, state trackers

.project/
├── requirements/               # srs.md, user-stories.md (Given/When/Then)
├── documentation/              # tech-stack.md, architecture.md (File Blueprint), team.md
├── wireframes/                 # UX wireframes (if chosen)
├── scenarios/                  # BDD .feature files per sprint
├── sprints/                    # sprint-1.md, sprint-2.md, ...
├── state/                      # pm-tracker.md, ba-tracker.md, specialists/
├── project-context.md          # Q&A history, decisions, preferences
└── progress-dashboard.md       # Auto-generated from sprint data

src/                            # Application source code (follows File Blueprint)
```

---

## Specialists

### 17 Built-in Specialists

Pre-configured agents from **Meta, Google, Apple, Amazon, Netflix, Microsoft** covering: React/Next.js, Node.js/APIs, iOS/Android, AWS/GCP/Azure, Unity, AI/ML, Blockchain, UX Design, Code Review, QA, DevOps, SRE, and Architecture.

Every project automatically includes: `google-code-reviewer` (Batch 2), `google-qa-engineer` (Batch 0 + 3), and `netflix-devops-engineer` (Phase 5-6).

### Dynamic Hiring

**The system is not limited to 17 specialists.** When a project requires a technology not covered by existing agents, HR detects the gap and creates a new specialist — complete with its own agent file, domain skill, and up-to-date knowledge.

```
┌─────────────────────────────────────────────────────────────────┐
│                     DYNAMIC HIRING FLOW                         │
│                                                                 │
│  CTO: "Project needs Vue.js + Node.js"                          │
│                    ↓                                            │
│  HR: Skill Gap Check                                            │
│  ┌────────────┬─────────────────────────┬────────┐              │
│  │ Technology │ Existing Specialist     │ Status │              │
│  ├────────────┼─────────────────────────┼────────┤              │
│  │ Node.js    │ netflix-backend-arch... │ ✅ HIT │              │
│  │ Vue.js 3   │ —                       │ ❌ GAP │              │
│  └────────────┴─────────────────────────┴────────┘              │
│                    ↓                                            │
│  Gap detected → Dynamic Hiring triggered                        │
│                    ↓                                            │
│  ┌──────────────────────────────────────────────────┐           │
│  │ Step 1  Fetch latest Vue.js docs via context7    │           │
│  │         (Composition API, Pinia, Vite patterns)  │           │
│  │                                                  │           │
│  │ Step 2  Create agent file                        │           │
│  │         → .claude/agents/evan-vue-architect.md   │           │
│  │         (persona, code patterns, rules)          │           │
│  │                                                  │           │
│  │ Step 3  Create domain skill                      │           │
│  │         → .claude/skills/vue-expert/SKILL.md     │           │
│  │         (best practices, project structure)      │           │
│  │                                                  │           │
│  │ Step 4  Compose skill stack                      │           │
│  │         vue-expert + typescript-master +         │           │
│  │         performance-optimization + ...           │           │
│  │                                                  │           │
│  │ Step 5  Activate → ready for team assignment     │           │
│  └──────────────────────────────────────────────────┘           │
│                    ↓                                            │
│  ✅ evan-vue-architect joins the project team                   │
└─────────────────────────────────────────────────────────────────┘
```

**What gets created:**

| Artifact | Location | Purpose |
|----------|----------|---------|
| Agent file | `.claude/agents/{name}.md` | Persona, expertise, code patterns, strict rules |
| Domain skill | `.claude/skills/{name}/SKILL.md` | Framework-specific best practices and patterns |
| Skill stack | Agent frontmatter `lazySkills:` | Composable skills (domain + general like `typescript-master`) |

**Design principles:**

| Principle | Description |
|-----------|-------------|
| **No substitution** | React ≠ Vue ≠ Angular. Each framework has unique patterns — never cross-assign. |
| **Docs-first** | Always fetch latest documentation via [context7](https://context7.com) before creating. No stale knowledge. |
| **Composable skills** | Domain skill (`vue-expert`) + general skills (`typescript-master`, `systematic-debugging`) = complete expertise. |
| **Instant activation** | New specialist is ready to be spawned immediately — no manual setup needed. |

> **Bottom line:** You can request a project in *any* technology. If the specialist doesn't exist yet, the system creates one.

### Skill Lazyload

Specialists don't load all their knowledge upfront. Instead, skills are **lazily injected** — the agent sees a menu of available skills and loads each one only when the task actually requires it.

```
┌─────────────────────────────────────────────────────────────────┐
│                     SKILL LAZYLOAD FLOW                         │
│                                                                 │
│  Agent frontmatter declares available skills:                   │
│  ┌──────────────────────────────────┐                           │
│  │ lazySkills:                      │                           │
│  │   - react-expert                 │                           │
│  │   - next-best-practices          │                           │
│  │   - performance-optimization     │                           │
│  └──────────────────────────────────┘                           │
│                    ↓                                            │
│  SubagentStart hook (skill-lazy.sh) fires                       │
│                    ↓                                            │
│  ┌──────────────────────────────────────────────────┐           │
│  │ 1. Parse lazySkills from agent frontmatter       │           │
│  │ 2. Read each SKILL.md description                │           │
│  │ 3. Build a skill menu with short descriptions    │           │
│  │ 4. Inject menu into agent context via            │           │
│  │    hookSpecificOutput.additionalContext          │           │
│  └──────────────────────────────────────────────────┘           │
│                    ↓                                            │
│  Agent sees:                                                    │
│  ┌──────────────────────────────────────────────────┐           │
│  │ ## Available Skills                              │           │
│  │ Load via Skill tool ONLY when needed.            │           │
│  │                                                  │           │
│  │ - react-expert: React 18+ patterns, hooks...     │           │
│  │ - next-best-practices: App Router, RSC, ...      │           │
│  │ - performance-optimization: Core Web Vitals...   │           │
│  └──────────────────────────────────────────────────┘           │
│                    ↓                                            │
│  Agent loads skills ON DEMAND via Skill tool                    │
│  (only when the current task requires it)                       │
└─────────────────────────────────────────────────────────────────┘
```

**Why lazyload?**

| Without Lazyload | With Lazyload |
|------------------|---------------|
| All skills loaded into every agent | Skills loaded only when needed |
| Context window bloated with unused knowledge | Context stays lean and focused |
| Agent slower to start, more noise | Agent starts fast, loads what it needs |

---

## Quick Start

```bash
# 1. Open in Claude Code
cd x-company
claude

# 2. Submit your project
/work "Build a task management app with real-time collaboration"

# 3. The company takes over:
#    CEO → PM → BA (asks questions) → Sprint 0 Checkpoints
#    → You confirm decisions → CTO designs File Blueprint
#    → QA generates BDD scenarios → You approve
#    → Dev codes with TDD loop → Code Review → QA + Visual Check
#    → Deployment

# Other commands:
/work continue          # Resume active project
/work status            # Check project status
/company start          # Open management panel (dashboard + terminal)
/company stop           # Close management panel
```

---

## Project Complexity Tiers

| Tier | Team Size | Duration | Examples |
|------|-----------|----------|----------|
| Simple | 3-4 | 1-2 weeks | Portfolio, landing page, simple CRUD |
| Standard | 5-6 | 4-6 weeks | Web apps, mobile apps, SaaS tools |
| Complex | 6-8 | 2-4 months | Real-time platforms, streaming, games |
| Enterprise | 8-12 | 4-12 months | Banking, cloud platforms, large systems |

---

## Technology

- **Platform**: [Claude Code](https://github.com/anthropics/claude-code) (Anthropic)
- **Agent System**: Claude Code native Agent tool with specialized subagent types
- **Quality**: BDD (Given/When/Then) + TDD (Red→Green loop) + Visual UI check
- **Testing**: Vitest (unit/integration) + Playwright (E2E + visual)
- **Automation**: Bash scripts for project management, gate validation, sprint tracking
- **Company Panel**: Dashboard + integrated terminal (`/company start`, auto-port per project)
- **Hooks**: Runtime enforcement (sprint format, wireframe injection, git commits, skill lazyload)

---

**Built with Claude Code** — BDD-driven autonomous AI collaboration for reliable software development.
