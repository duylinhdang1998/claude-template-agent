# Model & Skill Tier Guide

PM selects **Model Tier** (model complexity) and **Skill Tier** (skill loading) together per task.

## Tier Table

| Tier | Model | Skill Tier | Skill Requirement | When to Use | Examples |
|------|-------|------------|-------------------|-------------|---------|
| **Low** | `haiku` | NONE | No skills needed | Simple, routine, minimal logic | File search, scaffold, copy/rename |
| **Medium** | `sonnet` | CORE (1-2) | MUST load 1-2 core skills | Standard dev work, most tasks | Feature implementation, form/page, API, stores |
| **High** | `opus` | DEEP (2-3) | MUST load 2-3 skills | Complex, critical, deep reasoning | Complex algorithm, security, real-time, novel UI |

## Model Selection Rules

```
DEFAULT: sonnet (omit model → uses agent frontmatter default)

UPGRADE to opus when:
  ├── Task involves complex algorithms (recursive tree, graph traversal)
  ├── Task is security-related (auth, encryption, input validation)
  ├── Task requires architecture design (database schema, system design)
  ├── Task is a novel feature with no existing pattern
  └── Task integrates multiple layers (API + DB + real-time)

DOWNGRADE to haiku when:
  ├── Task only reads/searches files (Explore agent)
  ├── Task is boilerplate/scaffold (init project, copy template)
  ├── Task is a minor fix (rename, fix typo, update config)
  └── Task is simple validation (lint, format check)
```

## Skill Tier Decision Tree

```
Is this task WRITING application code (components, stores, APIs, logic)?
├── NO → Skill Tier: NONE (scaffold, config, search, BDD scenarios, code review)
└── YES → Does it involve complex patterns, novel UI, or security?
    ├── YES → Skill Tier: DEEP (2-3 skills)
    └── NO  → Skill Tier: CORE (1-2 skills)
```

### Quick Reference

| Task Pattern | Skill Tier | Why |
|-------------|------------|-----|
| Project setup / scaffold | NONE | No application logic |
| BDD scenario generation | NONE | QA template work |
| Code review | NONE | Review, not implement |
| QA verification | NONE | Testing, not implementing features |
| Build React component/page | CORE | Standard frontend implementation |
| Build API endpoint | CORE | Standard backend implementation |
| Build Zustand/Redux store | CORE | State management patterns matter |
| Database schema design | CORE | Schema patterns matter |
| Real-time WebSocket feature | DEEP | Complex integration patterns |
| Auth/security implementation | DEEP | Security patterns critical |
| Performance optimization | DEEP | Needs deep framework knowledge |
| Novel UI (D3, canvas, tree viz) | DEEP | Non-standard patterns |
| Complex algorithm/data structure | DEEP | Needs deep reasoning + patterns |

## PM Spawn Syntax

```python
# Standard task (sonnet - default, no model needed)
Agent(subagent_type="netflix-backend-architect", prompt="...")

# Complex task (upgrade to opus)
Agent(subagent_type="netflix-backend-architect", model="opus", prompt="...")

# Simple task (downgrade to haiku)
Agent(subagent_type="Explore", model="haiku", prompt="...")
```

## PM Spawn: SKILLS Block Format

PM adds a `SKILLS` block to the spawn prompt for CORE and DEEP tiers.

### CORE Tier (1-2 skills)

```
SKILLS (MANDATORY — load BEFORE coding):
Load these skills via Skill tool before writing any code:
1. {primary-skill} — {why needed}
Fill skills_used: in state file with skills you actually loaded.
```

### DEEP Tier (2-3 skills)

```
SKILLS (MANDATORY — load BEFORE coding):
Load these skills via Skill tool before writing any code:
1. {primary-skill} — {why needed}
2. {secondary-skill} — {why needed}
3. {tertiary-skill} — {why needed, if applicable}
Fill skills_used: in state file with skills you actually loaded.
```

### NONE Tier

No SKILLS block in prompt. State file `skills_used: []` is expected.

## Skill Selection Guide

PM picks skills from the agent's `lazySkills` list in its agent file (`.claude/agents/{agent}.md`).

### Common Mappings

| Agent | Task involves... | Recommended Skills |
|-------|-----------------|-------------------|
| meta-react-architect | React components | `react-expert` |
| meta-react-architect | Next.js pages/routing | `next-best-practices` |
| meta-react-architect | TypeScript types/generics | `typescript-master` |
| meta-react-architect | Beautiful UI/design | `ui-ux-pro-max` |
| meta-react-architect | Performance | `performance-optimization` |
| netflix-backend-architect | Node.js API | `node-backend` |
| netflix-backend-architect | Prisma/DB | `prisma` |
| netflix-backend-architect | Real-time | `real-time-systems` |
| netflix-backend-architect | Auth/security | `security-expert` |
| google-qa-engineer | Testing | `qa-testing` |

### Selection Rules

1. **Read the agent's `lazySkills`** in its `.md` file
2. **Match skills to task domain** — don't load GraphQL skill for a REST API task
3. **Prefer specific over general** — `next-best-practices` over `react-expert` for routing tasks
4. **Max 3 skills** — more than 3 wastes context without benefit
