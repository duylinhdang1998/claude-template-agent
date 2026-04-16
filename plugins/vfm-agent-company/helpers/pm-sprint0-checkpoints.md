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
   Does the project need wireframes?

   1. ✅ Yes - Create full wireframes (recommended for UI apps)
   2. ⏭️ No - Dev decides UI (MVP mode)
   3. 📎 Already have - I have Figma/mockups/reference (paste link)

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
