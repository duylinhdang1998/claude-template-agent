---
name: pm-sprint0-checkpoints
type: helper
description: |
  Sprint 0 Checkpoint display template (Step 2) and Project Type Detection table.
  PM reads this file to render the checkpoint block for user confirmation.
---

# Sprint 0: Checkpoint Display Template

PM displays this block after BA completes requirements gathering. Fill in `{}` placeholders from CTO/HR analysis.

```
📋 [PM] Sprint 0 Checkpoints

Requirements gathered. Please confirm the following decisions:

────────────────────────────────────────────────────────
1️⃣ PROJECT TYPE (auto-detected)
────────────────────────────────────────────────────────
   Detected: {Web App / Mobile App / API / CLI / Game}

────────────────────────────────────────────────────────
2️⃣ UI/UX DESIGN
────────────────────────────────────────────────────────
   Does the project need wireframes / a design system?

   1. ✅ Yes, agent designs - apple-ux-wireframer will show you the year's
        trendiest design directions to pick from, then generate the project
        design system (.project/design-system.md) + wireframes (recommended)
   2. ⏭️ No - Dev decides UI (MVP mode, no formal design system)
   3. 📎 Already have - I have Figma/mockups/reference (paste link); the agent
        extracts .project/design-system.md from it

────────────────────────────────────────────────────────
3️⃣ TECH STACK (CTO proposal)
────────────────────────────────────────────────────────
   | Layer | Technology |
   |-------|------------|
   | Frontend | {from CTO analysis - NEVER hardcode} |
   | Backend | {from CTO analysis} |
   | Database | {from CTO analysis} |

   ⚠️ PM MUST read core/cto.md and analyze project requirements
   before proposing tech stack. NEVER use defaults blindly.

   OK with the tech stack above? Or specify your requirements.

────────────────────────────────────────────────────────
4️⃣ TEAM COMPOSITION (HR proposal)
────────────────────────────────────────────────────────
   | Specialist | Role |
   |------------|------|
   | {from HR Skill Gap Check - NEVER hardcode} | Frontend |
   | {from HR Skill Gap Check} | Backend |
   | google-qa-engineer | QA |

   ⚠️ PM MUST read core/hr.md and run Skill Gap Check
   before proposing team. NEVER assign specialists without
   verifying they match the project's tech stack!

   OK with the team above?

────────────────────────────────────────────────────────
5️⃣ SPRINT 0 FOUNDATION (automatic — not a choice)
────────────────────────────────────────────────────────
   Before any feature work, Sprint 0 builds the skeleton every later
   sprint inherits:
     · project structure per the architecture File Blueprint
     · lint / format / type-check standards for BOTH frontend and backend
     · the base component layer (buttons, fields, cards, modals… all states)
     · app/CONVENTIONS.md

   Why: from Sprint 1 on, 2-5 agents build in parallel. Anything not
   decided once here gets invented N times, N different ways — which is
   what makes a UI look inconsistent no matter how good each part is.

────────────────────────────────────────────────────────
Reply briefly (e.g., "1, ok, ok" or specify details)
```

**PM MUST wait for user response before proceeding.**

---

## Project Type Detection Table

| Detected Type | Indicators | Wireframes Default |
|---------------|------------|-------------------|
| Web App | UI, pages, components, frontend | Yes (recommend) |
| Mobile App | iOS, Android, screens | Yes (recommend) |
| API/Backend | REST, GraphQL, microservice, no UI | No |
| CLI Tool | command line, terminal | No |
| Game | Unity, game mechanics | Yes (recommend) |
| Desktop App | Electron, native | Yes (recommend) |
