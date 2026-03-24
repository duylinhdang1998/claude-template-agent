# HR Dynamic Hiring: Steps 3-5 + context7 Usage

## ⭐⭐ MANDATORY: Use context7 for Documentation (ALWAYS)

**When creating a new specialist or skill, ALWAYS fetch up-to-date documentation from context7 MCP server.**

```
WHY: LLM training data may be outdated. context7 provides LATEST docs, APIs, patterns.

WHEN: During Step 2 (Research) and Step 4 (Skill Creation)

HOW:
1. resolve-library-id → find the library ID for the required technology
2. query-docs → fetch latest patterns, APIs, best practices
3. Use fetched docs to populate:
   - Specialist agent file (background, skills, patterns)
   - Domain-specific skill file (SKILL.md with accurate, current patterns)

EXAMPLE (Vue.js):
1. resolve-library-id("vue") → /vuejs/docs
2. query-docs("/vuejs/docs", "Composition API patterns")
3. query-docs("/vuejs/docs", "Pinia state management")
4. Use results → create accurate vue-expert skill + evan-vue-architect agent
```

**⚠️ NEVER create a specialist or skill based on LLM memory alone!**
**ALWAYS verify with context7 docs first. This ensures:**
- Correct API usage (no deprecated patterns)
- Latest best practices (Vue 3 Composition API, not Options API defaults)
- Accurate ecosystem knowledge (Pinia not Vuex, Vite not Webpack)

---

## Step 3: Create Agent File

```bash
# Copy template
cp .claude/templates/specialists/specialist-template.md \
   .claude/agents/{company}-{role}.md

# Example: Need Vue.js developer
cp .claude/templates/specialists/specialist-template.md \
   .claude/agents/evan-vue-architect.md
```

---

## Step 4: ⭐ Scan Skills Directory & Assign to Frontmatter (MANDATORY)

**After creating the agent file, HR MUST scan `.claude/skills/` for relevant skills and declare them in the specialist's frontmatter.**

**Why?** Skills provide procedural knowledge, best practices, and expert guidance to the agent at runtime. Without skills, the agent is just a generic LLM with no domain expertise.

```bash
# Step 4a: List ALL available skills
ls .claude/skills/

# Step 4b: For each skill, read SKILL.md description to check relevance
cat .claude/skills/{skill-name}/SKILL.md | head -20
# Decide: ✅ relevant to this specialist's domain, or ❌ not relevant
```

**Step 4c: Add ALL matching skills to frontmatter:**

```yaml
# In .claude/agents/{new-specialist}.md frontmatter:
skills:
  # 1. Domain-specific skill (MUST exist — create with /skill-creator if missing)
  - {domain-specific-skill}     # e.g., vue-expert, flutter-expert, rust-expert

  # 2. General skills that apply (pick from .claude/skills/ based on relevance):
  - typescript-master            # If specialist uses TypeScript
  - performance-optimization     # If specialist needs perf expertise
  - systematic-debugging         # If specialist debugs code
  - software-architecture        # If specialist designs architecture
  - prisma                       # If specialist uses Prisma ORM
  - postgresql                   # If specialist works with PostgreSQL
  # ... add ALL that are relevant
```

**Step 4d: If a domain-specific skill doesn't exist → Create it:**

```
No {domain}-expert skill found in .claude/skills/
→ Use /skill-creator to create .claude/skills/{domain}-expert/SKILL.md
→ Include framework-specific patterns, best practices, ecosystem knowledge
→ Then add to specialist's frontmatter

Examples of domain skills that may need creation:
  - vue-expert, svelte-expert, angular-expert (frontend frameworks)
  - flutter-expert, react-native-expert (mobile cross-platform)
  - rust-expert, go-expert, elixir-expert (backend languages)
  - supabase-expert, firebase-expert (BaaS platforms)
  - tailwind-expert, sass-expert (styling)
  - Any technology not yet in .claude/skills/
```

### Skill Assignment Rules

| Rule | Description |
|------|-------------|
| **MUST scan** | Always `ls .claude/skills/` and check each potentially relevant skill |
| **MUST read descriptions** | Don't guess — read SKILL.md to confirm relevance |
| **MUST assign all matches** | Every relevant skill should be in frontmatter |
| **MUST create missing domain skills** | If no skill exists for the core technology → create one with `/skill-creator` |
| **MUST include general skills** | `typescript-master`, `test-driven-development`, `systematic-debugging` apply to most specialists |
| **NEVER assign irrelevant skills** | `react-expert` should NOT be assigned to a Vue.js specialist |

### Skill Categories to Check

| Category | Skills to Consider | When Relevant |
|----------|--------------------|---------------|
| **Language** | `typescript-master` | Almost always for web dev |
| **Framework** | `react-expert`, `next-best-practices`, `vue-expert`*, etc. | Match to project framework |
| **Architecture** | `software-architecture` | Backend/fullstack specialists |
| **Testing** | `test-driven-development`, `qa-testing` | Dev specialists who write tests |
| **Debugging** | `systematic-debugging` | All dev specialists |
| **Performance** | `performance-optimization` | Frontend, game, mobile specialists |
| **Database** | `prisma`, `postgresql`, `nosql-expert`, `redis-expert` | Backend specialists |
| **DevOps** | `devops-release`, `infrastructure-as-code`, `kubernetes-expert` | DevOps specialists |
| **Cloud** | `aws-expert`, `gcp-expert`, `azure-expert` | Cloud specialists |
| **Domain** | `deep-learning`, `nlp-expert`, `unity-game-development` | Specialized domains |

*\* May need to be created with `/skill-creator` if doesn't exist*

---

## Step 5: Activation Checklist

Before declaring specialist active, verify ALL:

- [ ] Agent file exists in `.claude/agents/{name}.md`
- [ ] Frontmatter has correct `name`, `description`, `model`, `tools`
- [ ] **⭐ `skills:` in frontmatter lists ALL relevant skills from `.claude/skills/`**
- [ ] **⭐ Domain-specific skill exists (created if needed)**
- [ ] `permissionMode: dontAsk` set (for autonomous execution)
- [ ] `tools: Read, Write, Edit, Glob, Grep, Bash` set (standard specialist tools)
