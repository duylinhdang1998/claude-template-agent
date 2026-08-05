# VFM Agent Company — Plugin Upgrade Log

This file is maintained by the `claude-architect` skill. Every time a user reports a skill/agent failure and the architect upgrades the plugin, an entry is appended below. Entries are never edited or deleted — only appended.

**Purpose**:
1. Traceability — every plugin change ties back to an observed failure
2. Pattern detection — if the same skill gets upgraded 3+ times for related reasons, it needs structural rework, not another rule
3. Anti-regression — scores and rationale let a future architect verify rules still make sense

---

## [2026-04-18] claude-architect — Initial skill bootstrap

**Trigger (user report):**
> "Skill clone-website đang ngẫu hứng sáng tạo thêm section. Viết 1 skill architect để kiểm tra và nâng cấp .claude lên mỗi khi có vấn đề. Tuyệt đối không được hardcode."

**Iteration count:** 1st — creation, not a fix

**Root cause:**
Plugin had no self-improvement loop. Every skill failure required manual user intervention to re-edit SKILL.md, and there was no structured way to (a) diagnose whether the fix generalized or hardcoded the specific failure, (b) score the upgrade quality, (c) log the evolution. Without this loop, the same class of failure kept re-surfacing across different sections/projects.

**Upgrade type:** added (new skill)

**Files touched:**
- `plugins/vfm-agent-company/skills/claude-architect/SKILL.md` (new, ~270 lines)
- `plugins/vfm-agent-company/skills/claude-architect/UPGRADES.md` (new, this file)
- `plugins/vfm-agent-company/.claude-plugin/plugin.json` (version bump 1.0.5 → 1.1.0)
- `.claude-plugin/marketplace.json` (version bump)

**General principle added:**
Every plugin upgrade must pass the **Generality Litmus Test**: strip every proper noun (URL, brand, section name, specific value) from the proposed rule; if it still reads coherently and actionably, it's general. Otherwise, it's hardcoded — rewrite. The architect scores each upgrade on 10 criteria and will not commit below 8.0 overall.

**Verification mechanism:**
- Litmus Test applied during Step 3 (Draft)
- 10-criterion rubric in Step 6 (Self-Score) with pass threshold overall ≥ 8.0 and no single score < 6
- Mandatory UPGRADES.md append in Step 7 for audit trail
- Conventional commit message format tying back to root cause in Step 8

**Self-score:**
Not applicable — initial skill creation, not an upgrade of an existing skill. The first real upgrade logged here will be the first scored entry.

**Commit:** _(filled after push)_

---

## [2026-08-05] SYSTEM AUDIT — "agents getting slower & lower-quality over time"

**Trigger (user report):**
> "agent code càng ngày càng chậm và kém" — run claude-architect to find what needs improving. Focus: per-spawn injected context, eager MCP, the just-upgraded FE/BE agents.

**Iteration count:** 1st — system audit, not a single-skill fix.

**Evidence gathered (measured, not assumed):**
- FE agent body = 256 lines / 12KB with **9** `MANDATORY`/`⚠️`/`MUST`/`STEP` blocks; BE = 190 lines / 7KB. The agent `.md` body is injected as the FULL system prompt on EVERY spawn.
- Per-spawn fixed preamble (UI agent, Wireframes=Yes) ≈ 12KB body + ~2KB skill menu + ~2–3KB task-rules block + up to ~15KB design-system (`MAX_DS_LINES=500`) ≈ **~30KB (~7–8K tokens) before the agent writes one line.**
- `settings.json` eagerly loads **3 MCP servers** (`figma`, `sequential-thinking`, `context7`) every session regardless of task; each taxes every request's tool surface.
- Ruled OUT as causes: lazySkills (menu-only injection, ~1 line each) and agent-memory `lessons.md` (7 lines, not unbounded).

**Root cause (general patterns, per architect lenses):**
1. **Preamble Bloat / "everything is MANDATORY"** (lens: Weak-Modality inverted) — when 9 blocks all shout MUST, priority becomes illegible and the model spends attention reconciling rules instead of doing the task. Detailed how-to prose is *duplicated* in the agent body when it already lives in a lazySkill (e.g. STEP 0.5 craft pillars ≈ ui-ux-pro-max).
2. **Unconditional heavy injection** — full rule block + up to 15KB design-system injected even for trivial tasks; the body itself is the biggest, always-on cost.
3. **Eager MCP loading** — task-specific servers (Figma import, docs fetch, deep reasoning) are globally enabled, so every session pays for them.

**Proposed upgrades (general, verifiable — pending user pick before apply):**
- **P1 (MCP leanness):** *"MCP servers in settings.json load eagerly and tax every request. Globally enable ONLY servers the majority of sessions use; task-specific servers are opt-in per project."* Verify: each global `mcpServers` entry must justify majority-use.
- **P2 (agent-body leanness):** *"An agent `.md` is the full system prompt on every spawn — keep it lean. Consolidate to ONE read-first gate; put detailed how-to in lazySkills, never duplicated in the body; keep top-level `MANDATORY`/`⚠️` blocks ≤ 3 so priority stays legible."* Verify: body line count + count of top-level MUST-blocks ≤ 3.
- **P3 (drift detection):** *"`check-drift.sh` must diff every canonical→plugin artifact class (skills, agents, core, helpers), not just hooks"* — this is why `claude-architect` itself sat mis-placed undetected.

**Upgrade type:** [ audit — recommendations logged; application pending user confirmation ]

**Self-score:** deferred until a specific upgrade (P1/P2/P3) is applied.

**Commit:** _(audit entry; per-fix commits follow once user picks)_

---

## [2026-08-05] SYSTEM AUDIT — P1/P2/P3 APPLIED + drift reconciliation

**Trigger:** User confirmed "Làm cả 3 nhé, commit chung 1 nhánh" (apply all three, one branch).

**What was applied:**

**P1 — MCP leanness.** `settings.json`: globally enable ONLY `sequential-thinking`
(majority-use); `figma` + `context7` set `disabled:true` with OPT-IN descriptions
(task-specific — enable per project). Verify: every global `mcpServers` entry justifies
majority-use.

**P2 — Agent-body leanness.** The agent `.md` is the FULL system prompt on every spawn.
- `meta-react-architect`: 256→189 lines (−26%). Collapsed 5 shouting `⚠️/MANDATORY/STEP`
  blocks into **3 read-first GATES** (tokens · visual-craft · ship). The ~45-line
  craft-pillars prose (duplicated the `ui-ux-pro-max`/`frontend-design` skills) compressed
  to a one-line ship-quality bar with detail delegated to those on-demand skills.
- `netflix-backend-architect`: 190→173 lines. Removed the ~33-line `/go` block duplicated
  verbatim from the FE agent (detail lives in the `/go` skill); **2 GATES** (ship · skill map).
- All mechanical enforcement preserved verbatim (ESLint merge + `npm run lint` gate,
  PostToolUse multi-component hook, `/go` PASS requirement + report format).
Verify: body line count + top-level MUST-blocks ≤ 3.

**P3 — Drift detection, and the drift it found.** `check-drift.sh` now (a) includes `skills`
in `DIRECT_DIRS`, (b) skips build/OS artifacts, (c) adds a REVERSE pass detecting plugin-only
ORPHANs. Running it surfaced large pre-existing drift, now reconciled:
- **49 skills** diverged canonical↔plugin. Direction resolved per-file by which side held
  unique content: 47 were canonical-newer (richer frontmatter metadata) → pushed to plugin;
  `clone-website` was plugin-newer by ~93 lines (the "🚨 PRIME DIRECTIVE — absolute fidelity"
  + "⛔ Workflow Gate") → **backported to canonical** (canonical had been missing the entire
  anti-improvisation ruleset — a direct quality-regression source); `work` description
  backported (plugin-newer, keeps `${CLAUDE_SESSION_ID}` placeholder).
- **2 orphans** (`go`, `simplify`) existed only in the plugin → backported to canonical
  (same class that had hidden `claude-architect`).
- **`enforce-delegation.sh`** — plugin had intent-routing logic (route clone/build prompts to
  `/work`) that canonical lacked → backported to canonical (kept canonical's `$0`-relative
  path style; only the by-design `CLAUDE_PROJECT_DIR` vs `ROOT_DIR` path lines now differ).
- `codex/dist` regenerated; drift check now clean but for the by-design hook path lines.

**General principle reinforced:** the distributed plugin silently drifting from canonical is
itself a cause of "agents getting worse over time" — consumers installed skills without
metadata and a `clone-website` without its fidelity rules. Drift detection MUST cover every
artifact class in BOTH directions, or stale distributed copies rot unnoticed.

**Self-score (per applied change):**

| Criterion | P1 MCP | P2 agents | P3 drift |
|---|---|---|---|
| 1 Specificity Avoidance | 9 | 9 | 10 |
| 2 Verifiability | 9 | 9 | 10 |
| 3 Placement | 9 | 10 | 9 |
| 4 Clarity | 9 | 9 | 9 |
| 5 Completeness | 8 | 9 | 9 |
| 6 Anti-Regression | 8 | 9 | 10 |
| 7 Brevity | 9 | 9 | 8 |
| 8 Evidence Grounding | 10 | 10 | 10 |
| 9 Consistency | 9 | 9 | 9 |
| 10 Actionability | 9 | 9 | 9 |
| **Overall** | **8.9** | **9.2** | **9.3** |

All ≥ 8.0, no single < 6 → pass. Weakest: P1 Completeness/Anti-Regression (8) — a future
project could still re-enable an MCP without justification; mitigated by the OPT-IN
descriptions embedded at each server. P3 Brevity (8) — the reverse-pass added lines, but they
are load-bearing.

**Version:** 1.9.0 → 1.10.0 (minor — restructure of 2 agents + plugin skill-metadata sync).

**Commit:** e2c5cca

---

## [2026-08-05] google-qa-engineer + google-code-reviewer — audit & fix

**Trigger:** "Review tiếp 2 agent google-qa-engineer và agent code-reviewer nhé."

**Iteration:** 1st review of these two agents (continues the FE/BE agent-audit series).

**Findings & fixes (all general, verifiable):**

**google-qa-engineer (Elena Rodriguez):**
1. *Skill-backing gap* (same class as the BE agent): declared Playwright/OWASP/k6/perf
   expertise but wired only 3 generic lazySkills. All the backing skills existed unused.
   → wired `playwright`, `api-security-testing`, `security-audit`,
   `performance-optimization`, `visual-preview` + added a load-on-demand skill map so it
   pulls per-task. Verify: every lazySkill resolves to a `skills/<name>/SKILL.md` (0 dead).
2. *Wrong tool identifier* (Missing-Extraction pattern): Tier-1 browser section named the
   Chrome MCP `mcp__Claude_in_Chrome__*` and searched `ToolSearch "Claude_in_Chrome"` — the
   real namespace is lowercase-hyphenated `mcp__claude-in-chrome__*`, so the availability
   check could return zero and wrongly declare Tier 1 unavailable, skipping the user's real
   browser. → corrected the prefix + made the ToolSearch a `select:` of the real core tools.
   Verify: prefix string equals the environment's actual MCP namespace.

**google-code-reviewer (Daniel Park):**
3. *Enforcement without a reference* (correctness — the important one): §1b orders the
   reviewer to 🔴 REJECT values that bypass `.project/design-system.md`, and the injection
   hook even advertises "google-code-reviewer will reject…", yet the reviewer is NOT in the
   design-system injection `case` (only meta-react/apple-ios/android are) AND its body never
   told it to load the tokens — so it was enforcing a contract against a reference it never
   had. General principle: **an agent that enforces a token/spec contract MUST first load
   that contract; never assume another agent's injected context reaches this one.** Fix kept
   LEAN (on-demand, not a 15KB unconditional injection per the P1/P2 perf doctrine): added a
   "read `.project/design-system.md` FIRST when the diff touches UI" gate. Verify: the review
   report must cite the token source (or state it was missing).
4. Wired `graphql-expert` (reviewer must review the BE agent's GraphQL output) + normalized
   the load-skill notation from `/skill` to `Skill { skill: "…" }`.

**Upgrade type:** [ strengthened + added ]

**Self-score:** QA-wiring 9.0 · QA-mcp-fix 9.4 · reviewer-tokens 9.3 · reviewer-graphql 8.6.
All ≥ 8.0, no single < 6 → pass. Weakest: reviewer-graphql Completeness (8) — coverage add,
not a failure fix.

**Version:** 1.10.0 → 1.10.1 (patch — agent skill-wiring + two correctness fixes, no new skills).

**Commit:** 76c906a

**Follow-up (same review, → 1.10.2):** applied the P2 lean-body pass to `google-qa-engineer`
for consistency — it was the fattest agent at 239 lines with ~110 lines of decorative persona
(SDLC-phase list, a week-1–5 gantt, a Communication block, duplicate skill pointers) injected
every spawn and duplicated by the `qa-testing` skill. Cut to **156 lines** (−35%), keeping ALL
operational content (RUN-TESTS gate, browser tiers, skill map, the Quality-Gates sign-off
checklist, test-pyramid standards). `google-code-reviewer` left as-is: already lean at 132
lines; its only nuance (no `Bash`, so it cannot literally run lint/tsc) is a deliberate
read-only-reviewer tradeoff, not a defect — no change warranted (claude-architect boundary
condition: don't upgrade for the sake of it).

---

## [2026-08-05] apple-ux-wireframer — back the design agent with its design/token skills

**Trigger:** "review nốt agent design nhé. agent design đang có những skill gì?"

**Iteration:** 1st review of the design agent (closes the agent-audit series: FE · BE · QA ·
reviewer · design).

**Root cause (two patterns, both high-impact because this agent authors the design-system
contract every UI specialist is locked to — so it is the upstream root of "ugly UI"):**
1. *Expertise not backed by skills* (same class as BE/QA): its job is picking a DIRECTION +
   generating the token system, yet it wired only 3 lazySkills and NONE of the aesthetic/token
   skills that already exist in the repo.
2. *Declared-but-uninvoked tool*: `ui-ux-pro-max` was in its lazySkills and ships a
   `design_system.py` token generator, but the body only said "cp template + Edit by hand" —
   it never told the agent to RUN the generator. The powerful path sat dead (a known TODO).

**Fixes (general, verifiable):**
- Wired `ui-design-system`, `frontend-design`, `design-taste-frontend`, `tailwind-patterns`,
  `figma-implement-design` (all pre-existing) + a load-on-demand skill map routing each to a
  phase. Verify: every lazySkill resolves (0 dead).
- Phase 0 now instructs the agent to (a) load `frontend-design`/`design-taste-frontend` for
  the taste bar before presenting directions, and (b) actually RUN
  `design_system.py "<product+style>" --format markdown` to bootstrap concrete,
  palette-consistent tokens, then refine — with the explicit rule that **this is the ONE agent
  expected to run the generator; the FE agent is banned from it and only consumes the output**
  (keeps Gate-1 of meta-react-architect coherent). Verified the CLI flags against
  `--help` before documenting them.

**Upgrade type:** [ added + strengthened ]

**Self-score:** skill-wiring 9.1 · generator-usage 9.4 · skill-map 8.8. All ≥ 8.0 → pass.
Weakest: skill-map Brevity/Completeness (8.8) — a routing aid, acceptable.

**Version:** 1.10.2 → 1.10.3 (patch — agent skill-wiring + generator-usage fix, no new skills).

**Commit:** _(filled after push)_

---
