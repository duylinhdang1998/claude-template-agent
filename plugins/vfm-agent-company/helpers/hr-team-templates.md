# HR Team Composition Templates

> ⚠️ **WARNING**: These templates show DEFAULT specialists as EXAMPLES only.
> The actual specialist for each role MUST come from Skill Gap Check results.
> If the project uses a different framework than the default → Skill Gap Check
> WILL detect the gap → Dynamic Hiring WILL create the correct specialist.

## Team Composition Templates

### Web App (Standard)
```
Team Size: 6 specialists (+ BA role)
├── [BA role - not spawned]    (Phase 1)
├── apple-ux-wireframer        (Phase 2)
├── {frontend-specialist}      (Phase 3 - Frontend) ← FROM SKILL GAP CHECK
├── {backend-specialist}       (Phase 3 - Backend)  ← FROM SKILL GAP CHECK
├── google-code-reviewer       (Phase 3 - Review) ⭐ MANDATORY
├── google-qa-engineer         (Phase 4)
└── netflix-devops-engineer    (Phase 5-6)

Default mappings (ONLY if Skill Gap Check confirms match):
  - React/Next.js → meta-react-architect
  - Vue.js        → evan-vue-architect (or Dynamic Hire)
  - Angular       → Dynamic Hire
  - Svelte        → Dynamic Hire
  - Node.js       → netflix-backend-architect
  - .NET          → microsoft-azure-architect
  - Python        → Dynamic Hire
```

### Mobile App (iOS)
```
Team Size: 6 specialists (+ BA role)
├── [BA role - not spawned]
├── apple-ux-wireframer
├── apple-ios-lead             (iOS native - verify via Skill Gap Check)
├── {backend-specialist}       ← FROM SKILL GAP CHECK
├── google-code-reviewer       ⭐ MANDATORY
├── google-qa-engineer
└── netflix-devops-engineer
```

### Mobile App (Android)
```
Team Size: 6 specialists (+ BA role)
├── [BA role - not spawned]
├── apple-ux-wireframer
├── google-android-lead        (Android native - verify via Skill Gap Check)
├── {backend-specialist}       ← FROM SKILL GAP CHECK
├── google-code-reviewer       ⭐ MANDATORY
├── google-qa-engineer
└── netflix-devops-engineer
```

### AI/ML Application
```
Team Size: 7 specialists (+ BA role)
├── [BA role - not spawned]
├── apple-ux-wireframer
├── google-ai-researcher       (ML models)
├── {frontend-specialist}      ← FROM SKILL GAP CHECK
├── {backend-specialist}       ← FROM SKILL GAP CHECK
├── google-code-reviewer       ⭐ MANDATORY
├── google-qa-engineer
└── netflix-devops-engineer
```

### E-commerce Platform
```
Team Size: 7 specialists (+ BA role)
├── [BA role - not spawned]
├── apple-ux-wireframer
├── {frontend-specialist}      ← FROM SKILL GAP CHECK
├── {backend-specialist-1}     ← FROM SKILL GAP CHECK
├── {backend-specialist-2}     ← FROM SKILL GAP CHECK (if needed)
├── google-code-reviewer       ⭐ MANDATORY
├── google-qa-engineer
└── netflix-devops-engineer
```

### Game (Unity)
```
Team Size: 5 specialists (+ BA role)
├── [BA role - not spawned]
├── apple-ux-wireframer        (Game UI/UX)
├── google-unity-developer     (Game dev - verify via Skill Gap Check)
├── google-code-reviewer       ⭐ MANDATORY
├── google-qa-engineer
└── netflix-devops-engineer
```

## Team Size by Complexity

| Complexity | Team Size | Duration |
|------------|-----------|----------|
| Simple | 3-4 | 1-2 weeks |
| Standard | 5-6 | 1-2 months |
| Complex | 6-8 | 2-4 months |
| Enterprise | 8-12 | 4-12 months |

---

## Verification Checklist Output

HR MUST output this checklist before presenting team to PM:

```markdown
👥 [HR] Team Verification Checklist

SDLC PHASE COVERAGE:
├── Phase 1 (Requirements).. BA role (not spawned) ✅
├── Phase 2a (Architecture). CTO role (not spawned) ✅
├── Phase 2b (UX Design).... apple-ux-wireframer ✅
├── Phase 3 (Development)... meta-react-architect, netflix-backend-architect ✅
├── Phase 3 (Code Review)... google-code-reviewer ✅ ⭐ MANDATORY
├── Phase 4 (Testing)....... google-qa-engineer ✅
├── Phase 5 (Packaging)..... netflix-devops-engineer ✅
├── Phase 6 (Deployment).... netflix-devops-engineer ✅
└── Phase 7 (Release)....... PM + CEO roles ✅

⭐ MANDATORY SPECIALIST CHECK:
├── apple-ux-wireframer ... ✅ INCLUDED (required for all teams)
├── google-code-reviewer .. ✅ INCLUDED (required for all teams)
├── google-qa-engineer .... ✅ INCLUDED (required for all teams)
└── netflix-devops-engineer ✅ INCLUDED (required for all teams)

SPECIALIST FILE VERIFICATION:
├── .claude/core/ba.md .......................... ✅ exists (role)
├── .claude/agents/apple-ux-wireframer.md ....... ✅ exists
├── .claude/agents/meta-react-architect.md ...... ✅ exists
├── .claude/agents/netflix-backend-architect.md . ✅ exists
├── .claude/agents/google-code-reviewer.md ...... ✅ exists ⭐
├── .claude/agents/google-qa-engineer.md ........ ✅ exists
└── .claude/agents/netflix-devops-engineer.md ... ✅ exists

TEAM SIZE: 6 specialists + BA role (Standard project ✅)

STATUS: ✅ ALL CHECKS PASSED - Team approved
```

**If any check fails:**
```markdown
SDLC PHASE COVERAGE:
├── Phase 2b (UX Design).... ❌ NO SPECIALIST ASSIGNED
├── Phase 4 (Testing)....... ❌ NO SPECIALIST ASSIGNED
...

STATUS: ❌ VERIFICATION FAILED

MISSING ROLES:
- Phase 2b: Need to add apple-ux-wireframer
- Phase 4: Need to add google-qa-engineer

ACTION: Adding missing specialists...
```

### Quick Checklist (Internal)

- [ ] All 7 SDLC phases have assigned specialists
- [ ] `apple-ux-wireframer` is in the team (MANDATORY)
- [ ] `google-code-reviewer` is in the team (MANDATORY)
- [ ] `google-qa-engineer` is in the team (MANDATORY)
- [ ] `netflix-devops-engineer` is in the team (MANDATORY)
- [ ] All specialist agent files exist in `.claude/agents/`
- [ ] No skill gaps between CTO requirements and team
- [ ] Team size appropriate for project complexity
- [ ] No duplicate roles (unless needed for scale)
