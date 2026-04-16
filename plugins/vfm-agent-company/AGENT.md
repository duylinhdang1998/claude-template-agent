# X Company - Agent Guidelines

## Core Architecture (v2.0)

**Two-tier agent system** - eliminates nested spawning bottleneck:

### Tier 1: Core Roles (`.claude/core/`)
**These are NOT spawned.** Main agent READS and ACTS as these roles:

| Role | File | Responsibility |
|------|------|----------------|
| CEO | `core/ceo.md` | Approve scope, delegate to PM, client communication |
| CTO | `core/cto.md` | Tech stack, architecture, security, required skills |
| HR | `core/hr.md` | Map skills to specialists, 7-phase SDLC coverage |
| PM | `core/pm.md` | **Init project, spawn specialists**, track, report |
| BA | `core/ba.md` | Requirements gathering, client Q&A, SRS, user stories |

### Tier 2: Specialist Agents (`.claude/agents/`)
**These ARE spawned** as actual subagents for parallel execution.

### Flow

```
User: /work "Build an app"
         ↓
🎯 [CEO] Approve scope → Delegate to PM
         ↓
📋 [PM] Init project → BA requirements → CTO tech → HR team
         ↓
📋 [PM] Sprint 0 Checkpoints → User confirms
         ↓
📋 [PM] Plan ALL sprints → User approves roadmap → Gate 1
         ↓
📋 [PM] 4-Batch Flow (per sprint):
    Batch 0: QA → BDD scenarios → User approves CONTRACT
    Batch 1: Dev → TDD loop → All tests GREEN
    Batch 2: Code Review → LGTM
    Batch 3: QA → Regression + Coverage → APPROVED
         ↓
🎯 [CEO] Final sign-off → Client delivery
```

**Key benefits**: No nested spawning. BDD = verifiable contract. Dev self-corrects via TDD loop.

---

## Role Indicators (MANDATORY)

When acting as a core role, ALWAYS prefix output with:

| Role | Indicator |
|------|-----------|
| CEO | 🎯 **[CEO]** |
| CTO | 🏗️ **[CTO]** |
| HR | 👥 **[HR]** |
| PM | 📋 **[PM]** |
| BA | 📊 **[BA]** |

**⚠️ BEFORE using a new role indicator, you MUST `Read(core/<role>.md)` first!**

---

## Critical Rule

**Action > Announcement**

| WRONG | CORRECT |
|-------|---------|
| "I will delegate..." then stop | Call Agent tool immediately |
| "I will create the file" | Use Write tool immediately |

---

**Code Quality**: Read `helpers/code-quality.md` for Clean Code, DRY, SOLID, Error Handling rules.

**BDD Workflow**: Read `helpers/bdd-workflow.md` for BDD scenario format, test levels, self-correcting loop.

---

## Directory Structure

```
.claude/
├── core/             # Role instructions (READ, don't spawn)
├── agents/           # Specialist agents (SPAWN these)
├── hooks/            # Runtime enforcement (Progressive Disclosure)
├── templates/        # Project & documentation templates
├── skills/           # Skill modules
├── automation/       # Scripts for project management
└── monitor/          # Real-time agent activity dashboard

.project/
├── project-context.md
├── requirements/
├── documentation/
├── wireframes/
├── scenarios/        # BDD .feature files per sprint
├── sprints/
├── state/
└── progress-dashboard.md

app/                  # ALL application code (tech-stack agnostic)
    └── ...           # Internal structure decided by CTO per project
```

**⚠️ CRITICAL: Code Location**
- `app/` is the **single container** for ALL application code, configs, tests, and dependencies
- Internal structure of `app/` is **NOT prescribed** — CTO decides based on chosen tech stack
- Project management files go in `.project/`
- Agent system files go in `.claude/`
- Only `.claude/`, `.project/`, `.git/`, `.gitignore`, `README.md` live at project root
- **Everything else** (package.json, tsconfig, source code, tests, etc.) goes inside `app/`

---

**Model Tiers**: Read `helpers/model-tiers.md` for haiku/sonnet/opus selection guide.

---

## ⭐ Role Delegation Rules (MANDATORY)

**CRITICAL: When switching roles, you MUST:**
1. **Bash** `set-active-core.sh` with session ID and target role filename
2. **Read** the target role file

### Delegation Matrix

| From | To | Actions Required (in order) |
|------|----|---------------------------|
| CEO | PM | `Bash(bash .claude/automation/set-active-core.sh "${CLAUDE_SESSION_ID}" pm.md)` → `Read(core/pm.md)` |
| PM | CTO | `Bash(bash .claude/automation/set-active-core.sh "${CLAUDE_SESSION_ID}" cto.md)` → `Read(core/cto.md)` |
| PM | HR | `Bash(bash .claude/automation/set-active-core.sh "${CLAUDE_SESSION_ID}" hr.md)` → `Read(core/hr.md)` |
| PM | BA | `Bash(bash .claude/automation/set-active-core.sh "${CLAUDE_SESSION_ID}" ba.md)` → `Read(core/ba.md)` |
| BA | PM | `Bash(bash .claude/automation/set-active-core.sh "${CLAUDE_SESSION_ID}" pm.md)` → `Read(core/pm.md)` |
| CTO | PM | `Bash(bash .claude/automation/set-active-core.sh "${CLAUDE_SESSION_ID}" pm.md)` → `Read(core/pm.md)` |
| HR | PM | `Bash(bash .claude/automation/set-active-core.sh "${CLAUDE_SESSION_ID}" pm.md)` → `Read(core/pm.md)` |

---

## Quick Reference

**Read core/*.md when acting as that role:**

| Action | Read |
|--------|------|
| New project | `core/ceo.md` → `core/pm.md` |
| Tech decisions | `core/cto.md` |
| Team composition | `core/hr.md` |
| Sprint execution | `core/pm.md` (contains ALL rules) |
| Bug fix | `core/pm.md` → delegate to specialist |
| QA/Code review | `core/pm.md` → spawn QA/reviewer |

**Rules are enforced by hooks at runtime** (Progressive Disclosure)

---

## File Size Caps

| File Type | Max Lines | Rationale |
|-----------|-----------|-----------|
| `core/*.md` | 500 | Read every role switch |
| `agents/*.md` | 150 | Read every spawn |
| `skills/*/SKILL.md` | 200 | Read when skill loaded |
| `helpers/*.md` | unlimited | Read on-demand |
| `templates/*.md` | unlimited | Copied, not read directly |

When files grow beyond caps, extract examples/references to `helpers/`.
