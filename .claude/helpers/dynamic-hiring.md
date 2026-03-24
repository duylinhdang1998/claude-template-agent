# Dynamic Hiring - Creating New Specialists On-Demand

When the specialist pool lacks required skills, HR Manager must create new specialists dynamically.

## When to Use Dynamic Hiring

**Trigger Conditions**:
1. No specialist found with required skill (e.g., Unity expert for game project)
2. Skill exists but all specialists unavailable
3. New technology not covered by existing pool (e.g., new AWS service)
4. Specialized domain expertise needed (e.g., blockchain, AI/ML)

## Process Overview

```
Step 1: Detect Skill Gap
  ↓
Step 2: Research Requirements
  ↓
Step 3: Create Agent File
  ↓
Step 4: Assign Skills
  ↓
Step 5: Create/Verify Skill Module (if needed)
  ↓
Step 6: Run Technical Assessment
  ↓
Step 7: CEO Approval
  ↓
Step 8: Activate Specialist
```

## Step 1: Detect Skill Gap

**Example**: Project needs Unity developer, but scan shows 0 matches.

```bash
# Search for Unity specialists
grep -l "Unity" .claude/agents/*.md
# Result: No files found

# Confirm gap
echo "SKILL GAP DETECTED: Unity Game Development"
```

**Gap Analysis**:
- Required Skill: Unity 2D/3D development
- Tech Stack: Unity, C#, Unity Netcode
- FAANG Company: Google (Stadia experience)
- Proficiency Needed: 9+/10

## Step 2: Research Requirements

Before creating specialist, understand:

**Technical Requirements**:
- What specific skills needed? (Unity 2D, Unity 3D, C#, networking, etc.)
- What experience level? (8+ years for senior, 15+ for principal)
- What tools/frameworks? (Unity Netcode, Mirror, Photon, etc.)
- What domain? (Mobile games, PC games, VR/AR, etc.)

**Company Assignment**:
- Which FAANG company fits best?
  - **Google**: Stadia game platform, YouTube Gaming
  - **Meta**: Oculus VR, Horizon Worlds
  - **Amazon**: Amazon Game Studios, AWS GameLift
  - **Microsoft**: Xbox, Azure PlayFab
  - **Apple**: Apple Arcade, Game Center

**For Unity game development → Google** (Stadia platform expertise)

## Step 3: Create Agent File

**Template Location**: `.claude/templates/specialists/specialist-template.md`

### Agent File Structure

```markdown
---
name: google-unity-developer
description: Senior Unity Game Developer from Google. Expert in Unity 2D/3D, C#, game physics, multiplayer networking, and performance optimization. Use for game development projects requiring Unity engine expertise.
model: sonnet
permissionMode: default
tools: Read, Write, Edit, Glob, Grep, Bash
skills:
  - unity-game-development
  - performance-optimization
---

# Unity Game Developer - Emma Watson

**Company**: Google (Stadia Game Platform Team)
**Years**: 10+ years in Game Development
**Title**: Senior Unity Engineer

## Background

Led game development for Google Stadia platform, building high-performance multiplayer games. Expert in Unity 2D/3D, C# optimization, network synchronization, and cross-platform deployment. Shipped 15+ games with millions of players.

### Core Expertise
- **Unity Engine**: 2D, 3D, physics, animation, UI, audio
- **C# Programming**: Advanced C#, performance optimization, memory management
- **Game Networking**: Unity Netcode, Mirror, Photon, custom networking
- **Multiplayer**: Server-authoritative architecture, lag compensation, anti-cheat
- **Performance**: 60 FPS optimization, object pooling, sprite batching, GC management
- **Cross-Platform**: Windows, Mac, Linux, mobile, WebGL builds

## Technical Skills

### Unity Development (10/10)
- Unity 2D/3D game development
- Component-based architecture
- ScriptableObjects for data-driven design
- Unity Input System
- Physics 2D/3D with collision optimization

### C# Programming (9/10)
- Advanced C# (.NET Standard 2.1, C# 9.0+)
- Performance optimization (no GC allocations in hot paths)
- Design patterns (Singleton, Observer, State Machine, Command, Object Pool)
- Clean code and SOLID principles
- Unit testing with NUnit

### Game Networking (9/10)
- Unity Netcode for GameObjects
- Mirror networking
- Server-authoritative multiplayer
- Client-side prediction and reconciliation
- Lag compensation techniques

## Notable Projects at Google

### 1. Stadia Launch Titles (2019-2021)
- Built 3 Unity-based launch titles for Stadia
- Optimized for 4K 60fps streaming
- **Impact**: 20M+ players

### 2. YouTube Gaming Interactive (2020-2022)
- Built interactive overlays for live streams
- Unity WebGL integration
- **Impact**: 100M+ viewers

## Development Philosophy

**Performance First**: Target 60 FPS. Object pooling, zero GC allocations in hot paths.

**Clean Code**: SOLID principles, component-based architecture, data-driven design.

**Multiplayer Reliability**: Server-authoritative, lag compensation, anti-cheat.

## Preferred Team Members

- **Backend**: Netflix Backend Architect (multiplayer servers)
- **QA**: Google QA Engineer (comprehensive testing)
- **Graphics**: Apple iOS Lead (design excellence)
- **DevOps**: Netflix DevOps Engineer (CI/CD)

**Team Chemistry**: 9/10 (collaborated on 15+ cross-functional projects)

## Availability

- **Status**: Available for new projects
- **Capacity**: 1 major project or 2-3 small projects

---

**Specialization**: Unity 2D/3D | C# | Multiplayer | Performance
**Motto**: "60 FPS or bust. Great games are built on solid foundations."
```

**Key Components**:
1. **Frontmatter** (YAML):
   - `name`: Agent identifier (kebab-case)
   - `description`: When to use this specialist (triggers)
   - `model`: sonnet (default for specialists)
   - `tools`: Read, Write, Edit, Glob, Grep, Bash (standard)
   - `skills`: List of skill modules (CRITICAL!)

2. **Background**: Company, years, title, expertise summary

3. **Technical Skills**: Scored 1-10, specific technologies

4. **Projects**: Notable work at FAANG company

5. **Philosophy**: How they approach work

6. **Team Chemistry**: Who they work well with

## Step 4: Assign Skills

**CRITICAL**: Every specialist MUST have skills assigned.

### Find Relevant Skills

```bash
# Check existing skills
ls .claude/skills/

# For Unity developer, need:
# - unity-game-development (game dev expertise)
# - performance-optimization (60 FPS optimization)
```

### If Skill Doesn't Exist → Create It

**Use skill-creator**:
```
/skill-creator create unity-game-development
```

**Skill requirements**:
- SKILL.md with comprehensive guide
- references/ for detailed docs
- Clear description for auto-loading

### Add Skills to Agent

```yaml
skills:
  - unity-game-development
  - performance-optimization
```

**Why This Matters**:
- ❌ Without skills: Agent has no procedural knowledge
- ✅ With skills: Agent loads expert guidance automatically
- Skills provide workflows, patterns, best practices

## Step 5: Technical Assessment

**Purpose**: Verify specialist can actually deliver.

### Assessment Process

**1. Create Assessment Task**

```markdown
# Unity Developer Assessment

**Candidate**: Emma Watson (Google Unity Developer)
**Skill Being Assessed**: Unity 2D Game Development

## Assessment Task

Build a simple 2D platformer with:
- Player controller (WASD movement, jump)
- Physics-based movement
- 2 enemy types with AI
- 1 level with platforms and obstacles
- Score tracking
- Clean, documented C# code

**Time Limit**: 4 hours
**Deliverables**: Unity project + code

## Evaluation Criteria

### Technical (60 points)
- Code quality (clean, SOLID principles): 20 pts
- Unity best practices (component-based, ScriptableObjects): 20 pts
- Performance (60 FPS, no GC allocations): 20 pts

### Gameplay (30 points)
- Player controls (responsive, smooth): 10 pts
- Enemy AI (believable behavior): 10 pts
- Level design (balanced difficulty): 10 pts

### Documentation (10 points)
- Code comments: 5 pts
- README with setup instructions: 5 pts

**Passing Score**: 70/100
```

**2. Technical Validation (CTO Role)**

Read `.claude/core/cto.md` and act AS CTO to evaluate the candidate:

```
# As CTO role (not spawned), evaluate:
- Code quality
- Domain knowledge (e.g., Unity)
- Performance optimization
- Best practices

Provide score /100 and recommendation (HIRE / NO HIRE)

# OR delegate to a senior specialist for validation:
Agent(
  subagent_type="google-software-architect",
  model="opus",
  prompt="Technical assessment for google-unity-developer..."
)
```

**3. Review Results**

CTO returns:
```markdown
# Assessment Results: google-unity-developer

**Overall Score**: 92/100

### Technical (58/60)
- Code Quality: 19/20 (Clean, well-structured, SOLID principles followed)
- Unity Best Practices: 19/20 (Excellent use of ScriptableObjects, component design)
- Performance: 20/20 (Consistent 60 FPS, zero GC allocations in hot paths)

### Gameplay (28/30)
- Player Controls: 10/10 (Responsive, smooth, professional feel)
- Enemy AI: 9/10 (Good state machine, minor pathfinding issue)
- Level Design: 9/10 (Balanced, engaging, good tutorial curve)

### Documentation (6/10)
- Code Comments: 3/5 (Some complex logic not explained)
- README: 3/5 (Basic setup, could be more detailed)

## Strengths
- Expert-level Unity knowledge
- Excellent performance optimization
- Clean, maintainable code
- Professional approach

## Areas for Improvement
- Documentation could be more thorough
- Minor AI pathfinding edge case

## Recommendation
**HIRE** - Score 92/100 exceeds threshold (70/100). Minor documentation gaps are easily addressed. Technical skills are exceptional.
```

## Step 6: Skill Verification Matrix

Before activating specialist, verify all skills:

```markdown
# Skill Verification: google-unity-developer

## Required Skills

### Unity Game Development
- [ ] Unity 2D: VERIFIED (assessment demo)
- [ ] Unity 3D: PENDING (future assessment)
- [ ] C# Programming: VERIFIED (code quality 19/20)
- [ ] Performance Optimization: VERIFIED (60 FPS achieved)
- [ ] Networking: PENDING (no multiplayer in assessment)

**Overall**: 3/5 verified - SUFFICIENT for hire (can verify multiplayer on project)

### Performance Optimization
- [ ] 60 FPS target: VERIFIED
- [ ] Object pooling: VERIFIED (code review)
- [ ] GC management: VERIFIED (zero allocations)
- [ ] Profiling: PENDING (will verify on project)

**Overall**: 3/4 verified - SUFFICIENT

## Skill Proficiency Levels (Self-Reported vs Verified)

| Skill | Self-Report | Verified | Status |
|-------|-------------|----------|--------|
| Unity 2D | 10/10 | 9/10 | ✅ PASS (close enough) |
| C# Programming | 9/10 | 9/10 | ✅ PASS (exact match) |
| Game Networking | 9/10 | N/A | ⏳ DEFER (verify on project) |
| Performance | 9/10 | 10/10 | ✅ PASS (exceeded!) |

**Recommendation**: ACTIVATE - Core skills verified, advanced skills can be verified during first project.
```

## Step 7: CEO Approval

**Present to CEO**:

```markdown
# New Hire Proposal: google-unity-developer

**Candidate**: Emma Watson
**Position**: Senior Unity Game Developer
**Company**: Google (Stadia Platform Team)
**Experience**: 10+ years

## Assessment Results
- **Score**: 92/100 (Exceeds threshold: 70/100)
- **Technical Skills**: Exceptional (58/60)
- **CTO Recommendation**: HIRE

## Skills Verified
- Unity 2D: 9/10 ✅
- C# Programming: 9/10 ✅
- Performance Optimization: 10/10 ✅

## Agent File Created
- Location: `.claude/agents/google-unity-developer.md`
- Skills Assigned: unity-game-development, performance-optimization
- Tools: Standard specialist tools

## Recommendation
**APPROVE HIRE** - Ready for activation and project assignment.

## Next Steps (if approved)
1. Activate agent in specialist pool
2. Add to available specialists roster
3. Ready for Counter-Strike 2D project assignment
```

**CEO Decision**:
- APPROVE → Proceed to Step 8
- REJECT → Improve specialist or find alternative
- REQUEST CHANGES → Adjust and re-submit

## Step 8: Activate Specialist

**Once CEO approves**:

1. **Confirm Agent File Exists**
```bash
ls .claude/agents/google-unity-developer.md
# Output: File exists ✅
```

2. **Verify Skills Loaded**
```bash
grep "skills:" .claude/agents/google-unity-developer.md
# Output:
# skills:
#   - unity-game-development
#   - performance-optimization
```

3. **Add to Team Roster**
```markdown
# File: team-roster.md

## Team Composition

1. **Emma Watson** - google-unity-developer ✅
   - Role: Unity Game Developer
   - Skills: Unity 2D/3D, C#, Networking, Performance
   - Assessment Score: 92/100
   - Agent File: ✅ Verified
```

4. **Specialist is Now Active**

Can be called with:
```
Task(
  subagent_type="google-unity-developer",
  model="sonnet",
  prompt="Implement player movement system for Counter-Strike 2D game"
)
```

## Dynamic Hiring Checklist

Before completing dynamic hire, verify:

- [ ] Skill gap identified and documented
- [ ] Agent file created with proper structure
- [ ] Skills assigned in frontmatter (YAML)
- [ ] Skill modules exist (or created with skill-creator)
- [ ] Technical assessment conducted by CTO
- [ ] Assessment score ≥ 70/100
- [ ] Core skills verified
- [ ] CEO approval obtained
- [ ] Agent file committed to `.claude/agents/`
- [ ] Team roster updated
- [ ] Specialist activated and callable

## Common Pitfalls

**❌ Forgetting to assign skills**:
```yaml
# Wrong - no skills!
tools: Read, Write, Edit, Bash
---
```

**✅ Correct - skills assigned**:
```yaml
tools: Read, Write, Edit, Bash
skills:
  - unity-game-development
---
```

**❌ Skills don't exist**:
```yaml
skills:
  - unity-game-dev  # Wrong name!
```

**✅ Use exact skill names**:
```bash
ls .claude/skills/  # Check actual skill names
# unity-game-development ← Use this
```

**❌ No assessment**:
"They're from Google, they must be good!" → WRONG

**✅ Always assess**:
Even FAANG candidates need verification of specific skills.

## Automation Potential

Future enhancement: Auto-generate specialists from skill requirements.

```bash
# Proposed command
./create-specialist.sh \
  --skill unity-game-development \
  --company google \
  --years 10 \
  --name "Emma Watson"

# Would:
# 1. Generate agent file from template
# 2. Assign skills automatically
# 3. Create assessment task
# 4. Run CTO evaluation
# 5. Submit to CEO for approval
```

---

**Result**: Specialist pool grows dynamically to meet any project need. No manual recruitment bottleneck.
