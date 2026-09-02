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

**Commit:** 6e7b27c

**Follow-up (→ 1.10.4): refreshed the trend catalog the design agent picks from.** User
flagged `helpers/design-trends.md` was missing current 2026 UI trends (named Bento Grid,
Minimalism). Verified against 2026 sources (web search) and added 3 directions with concrete
token starters — **9. Bento Grid** (modular tile layout — the big miss; flagged as a LAYOUT
system that combines with any palette), **10. Expressive Minimalism** (the 2026 evolution:
clean + warmth/organic/personality), **11. Kinetic Typography** (motion-first big type) — plus
renamed #5 to **Liquid Glass** (iOS 26 language). Catalog 8 → 11; picker guidance + product-type
mapping updated; "Last curated" → 2026-08. General principle (already in the file's frontmatter):
this catalog MUST be refreshed ~yearly against live trend sources, not left to drift.

> **Note (version consolidation):** the incremental bumps logged in this session
> (1.9.0 → 1.10.0 → … → 1.10.5) were **consolidated to a single released `1.8.0`** at the
> user's request — 1.8 had not yet been installed anywhere, so the whole batch ships under
> one version and the numbering will be advanced on the next real release. The per-entry
> version notes above reflect the in-progress numbering, not the shipped tag.

**Follow-up (→ 1.10.5): motion & animation as a first-class design dimension.** User: the
catalog was missing motion design/animation (as a trend/style, not a skill). Added a
**Motion & Animation** cross-cutting dimension to `helpers/design-trends.md` (parallel to how
Bento Grid is a layout dimension): 4 motion personalities (M-A Functional · M-B Premium ·
M-C Playful · M-D Cinematic) each with concrete duration/easing/stagger tokens + which visual
styles they pair with + the non-negotiable rules (`prefers-reduced-motion` fallback, animate
only `transform`/`opacity`, purposeful not decorative). Found + closed the downstream gap:
`templates/design-system.md` had **no motion section**, so the token contract had nowhere to
land — added a Motion & Animation token table (durations, easings, distance, stagger). And to
keep the template's "reviewer rejects motion violations" claim honest (the same enforce-without-
a-check anti-pattern), added a motion bullet to `google-code-reviewer` §4 (flag missing
reduced-motion fallback, animating layout props, off-token durations). General principle: every
token dimension the design agent can choose MUST have (a) a slot in the design-system template
and (b) a matching check in the reviewer — otherwise it's advice, not a contract.

---

## [2026-08-23] google-code-reviewer — Measurable rules must be measured, not judged

**Trigger (user report):**
> PM re-checked a review that google-code-reviewer had already returned and found 3 misses:
> (a) an options constant copied **verbatim into 3 files** — past the "3+ → must extract"
> threshold — where the reviewer's own suggestion moved one copy to a shared file and left
> the other three in place; (b) two label maps duplicating existing badge components and
> **already drifted** (same key → different user-visible strings on different screens),
> never mentioned; (c) no function-length check and no god-file finding on a **1035-line**
> file, 3.4× the 300-line limit. Reviewer had also filed the split as MAJOR #2 with the note
> "bigger job, do later". PM: only 2 of 4 frontend rules have a real gate; the rest are prose.

**Iteration count:** 3rd+ in this class. The previous entry (1.10.5) closed the same shape of
hole for motion tokens and stated the principle *"a dimension with no matching reviewer check
is advice, not a contract."* It was applied to one dimension; the hole is structural.

**Root cause:**
Four distinct defects, one pattern — **the reviewer was asked to judge properties it had no
procedure to observe.**
1. *Cross-file property judged from one file.* DRY / "extract shared logic" / duplication are
   repo-wide facts. All 7 checklist areas were phrased as inspection of the file at hand, and
   nothing told the reviewer to use its `Grep` tool to look outward. Both (a) and (b) are
   invisible from inside the reviewed file — so the check could never fire, however diligent
   the agent.
2. *Numeric threshold with no measurement step.* "functions <30 lines", "no god files" were
   stated as prose questions. Nothing said to run `wc -l` or enumerate function spans, so the
   answer defaulted to impression, and a 1035-line file passed as merely "large".
3. *Contradictory thresholds.* `code-quality.md` said "Max 300 lines" in one table and
   "God files (500+ lines)" in another — two numbers for one limit invites the looser reading.
4. *Severity assigned by rule identity, not by consequence.* Rule #3 was hardcoded 🟡, so
   duplication stayed MINOR even when the copies had **diverged** — which is a behaviour
   defect, not a style nit. Compounded by grading on fix-cost ("bigger job, do later"), which
   converts a blocking finding into a permanent one.
5. *Enforcement claimed but not verified.* `code-quality.md` advertised "three layers, NOT just
   prose"; in truth the hook covers standard #1 alone, the ESLint template covered #1 + #4 (and
   #4 only at `warn`, so `npm run lint` still exited 0), nothing at all covered #3 or file size,
   and **nothing in the framework installs the ESLint template** — it was prose in two agent
   files. Neither the FE agent nor the reviewer ever checked whether the gate existed.

**Upgrade type:** [ added + strengthened + deleted-conflict ]

**Files touched:**
- `.claude/agents/google-code-reviewer.md` (+55) — new mandatory **Measurement Pass (M1–M5)**
  before any grading; checklist §1/§1b/§2 re-pointed at those numbers; severity-by-consequence
  rule; report must open with the measurements
- `.claude/helpers/code-quality.md` (+30/−12) — coverage table stating which layer actually
  enforces each standard; 500-line contradiction removed; lint layer marked opt-in-and-unverified
- `.claude/templates/frontend/eslintrc.frontend.json` (+12) — `max-lines` (300, error) and
  `max-lines-per-function` (30, warn) added; static-inline-style rule `warn` → `error`;
  burn-down migration note for codebases already in violation
- `.claude/agents/meta-react-architect.md` (+12) — must grep-verify the merged rule ids landed;
  explicit ban on deleting a rule to make lint green
- mirrored to `plugins/vfm-agent-company/**`; version 1.9.0 → 1.9.1

**General principles added:**
1. A rule whose subject spans more than the file under review MUST carry an outward search
   procedure; searching by identifier alone is insufficient because copies get renamed, so the
   search MUST also run on a distinctive literal from the declaration's body.
2. A rule containing a number MUST carry the command that produces that number, and the review
   MUST publish the raw value. An area with no number cannot be marked pass.
3. Severity is a function of consequence, never of which rule was broken and never of how large
   the fix is. Duplicated definitions that have diverged are always blocking; fix-cost is the
   scheduler's input, not the grader's.
4. A proposal that relocates one of N duplicates is not a fix — the fix is one definition,
   N−1 deletions, N−1 imports.
5. Every standard MUST declare which layer actually enforces it; where the only layer is human
   review, the review IS the gate and must be graded mechanically. A claimed gate MUST be
   verified by grepping for it — by the agent that installs it AND by the reviewer — and a
   missing gate is a finding in its own right.

**Verification mechanism:**
M1 `wc -l` per changed file (>300 = 🔴) · M2 function spans (>30 lines = 🟡, 3 longest reported)
· M3 `grep -rn` on both identifier and distinctive body literal, occurrence count reported
(≥3 = 🔴) · M4 key-by-key diff of duplicate copies (any differing value = 🔴 MAJOR) ·
M5 `grep -rE` the project ESLint config for all four required rule ids (missing = 🔴).

**Self-score:**
```
  1. Specificity Avoidance  : 10/10   (no project/file/brand nouns in any rule body)
  2. Verifiability          : 10/10   (each of M1–M5 is a runnable command with a numeric verdict)
  3. Placement              :  9/10   (Measurement Pass sits above the checklist, after skill-loading)
  4. Clarity                :  9/10   (MUST/never; thresholds single-valued after the 500 removal)
  5. Completeness           :  9/10   (covers siblings: renamed copies, drifted copies, partial
                                       relocation, fix-cost downgrading, absent gate)
  6. Anti-Regression Power  :  9/10   (all three reported misses become mechanically detectable;
                                       two also gain a lint gate)
  7. Brevity                :  7/10   (+55 lines on the reviewer — the table carries most of it)
  8. Evidence Grounding     : 10/10   (each rule maps to a numbered defect in this entry)
  9. Consistency            :  9/10   (resolves the 300/500 conflict rather than adding to it)
 10. Actionability          : 10/10   (commands are copy-pasteable; verdicts are thresholds)
────────────────────────────────
 Overall                    : 9.2/10
```
Weakest: **Brevity 7/10** — the Measurement Pass adds real length to the reviewer prompt.
Accepted: the misses were caused by absent procedure, and procedure cannot be compressed to a
slogan without becoming prose again — which is the exact failure being fixed.

**Open item (not fixed here):** nothing in `automation/init-project.sh` copies
`eslintrc.frontend.json` into a new project; installation is still an instruction to an agent,
now merely verified after the fact by M5 and the FE agent's grep. Making it a scripted step is
the structural close and should be its own upgrade.

**Commit:** 00b8391

---

## [2026-08-23] code standards — Conventions become lint; backend gets a gate; lint gets teeth

**Trigger (user report):**
> "Agent đang không tuân thủ code quality, code rất tệ… mặc dù có skill senior-frontend,
> react-best-practice mà tôi cảm giác code như của 1 junior vậy. Đây mới chỉ là frontend tôi
> còn chưa review backend." Follow-up scope: fix ① convention, ② backend standards,
> ④ make the lint gate blocking. (③ pre-write decomposition plan and ⑤⑥ deferred by the user.)

**Iteration count:** 4th+ in the enforcement class (see the 1.10.5 motion entry and the
2026-08-23 reviewer entry above). Previous rounds patched *detection*; this one patches the
*mechanism*.

**Root cause:**
Three separate holes, one shape — **standards existed as prose that nothing executed.**
1. *Conventions were a markdown table.* The naming/type/file conventions lived only in
   `core/cto.md` → File Blueprint. Grep across the whole framework for
   `naming-convention|filename-case|import/order|consistent-type-imports` returned **0**.
   Nothing machine-checked any of them, so "convention" meant "whatever the agent felt like".
2. *Backend had 0 of 4 enforcement layers.* The hook matched `.tsx|.jsx` only; the single
   ESLint template was `plugins: ["react"]`; `code-quality.md` had no backend section
   (grep "backend" = 0); the reviewer had §1b Frontend and no backend counterpart. Backend
   code was governed solely by the generic Clean Code prose that had already been shown to
   fail on the frontend.
3. *The build gate had no teeth.* `code-quality.md` claimed "`npm run lint` MUST pass before
   a task is marked complete", but `post-task-validate.sh` — the `SubagentStop` hook that
   could enforce it — only compared `git status` counts and **always `exit 0`**. Passing lint
   was an agent self-assertion that nothing verified.

**Upgrade type:** [ added + strengthened ]

**Files touched:**
- `templates/shared/eslintrc.conventions.json` (**new**) — the universal layer every TS/JS
  project merges first: `naming-convention`, `consistent-type-imports`, `no-explicit-any`,
  `no-magic-numbers`, `max-lines` 300, `max-lines-per-function` 30, `max-params` 4,
  `max-nested-callbacks` 3, `max-depth` 4, `complexity` 10, `prefer-const`, `eqeqeq`,
  `no-console`. Rules needing extra plugins are quarantined in a `//optional` key with their
  install command, so merging the file can never break a project on an unknown rule id.
- `templates/backend/eslintrc.backend.json` (**new**) — layer-boundary enforcement via
  `no-restricted-imports` overrides (route/controller may not import the ORM or a repository;
  a service may not import a controller), `no-floating-promises`, `only-throw-error`,
  `no-empty` without `allowEmptyCatch`, and `process.env` restricted to the config module.
- `templates/frontend/eslintrc.frontend.json` — refactored to layer ON TOP of the shared file
  (React-only rules remain); `.tsx` gets a relaxed 80-line function limit because JSX is
  markup, while the 300-line FILE limit is not relaxed; tests exempted.
- `helpers/code-quality.md` (+90) — new "Universal Code Conventions" section mapping every
  prose convention to the lint rule that enforces it, plus the three-file merge order; new
  "Backend Code Standards" section (B1–B5) with its own honest coverage table.
- `agents/google-code-reviewer.md` — new **§1c Backend Code Standards**; checklist 7 → 8 areas.
- `agents/netflix-backend-architect.md` — new **GATE 3** (was TWO gates, now THREE): the five
  backend standards, a mandatory pre-write "does this already exist?" grep by identifier AND
  literal, and the merge-then-`--print-config`-verify step.
- `agents/meta-react-architect.md` — merge order updated; verification switched from grepping
  the config file to `npx eslint --print-config` (which resolves `extends`; a raw grep does not).
- `hooks/enforce-frontend-standards.sh` → **renamed** `hooks/enforce-code-standards.sh`, now
  covering `.ts/.js` as well and adding a **file-size hard gate** with a *no-new-violations*
  policy: an already-over-limit file is only warned about while it is not growing, so legacy
  files stay editable and shrinkable; a new over-limit file, or one that grew, is blocked.
- `hooks/post-task-validate.sh` — **lint gate added**: runs the project's `npm run lint` over
  the change and `exit 2`s with the output on failure. Timeout raised 10s → 180s in both
  `settings.json` and `hooks/hooks.json`.
- mirrored to `plugins/vfm-agent-company/**`; version 1.9.1 → 1.10.0.

**General principles added:**
1. A convention that no tool executes is not a convention. Every prose rule that a linter can
   express MUST be shipped as a lint rule, and the prose MUST name the rule id that enforces it.
2. Enforcement layers MUST be declared per standard, honestly, including the standards whose
   only layer is human review — where that is the case, the review is the gate and must be
   graded from measurements.
3. Every area of the codebase gets the same four layers, or the gap must be stated. Parity is
   the default; a missing layer is a finding, not an omission.
4. A limit introduced onto an existing codebase MUST ship with a no-new-violations policy so
   it can be adopted without freezing work — and with an explicit ban on deleting the rule to
   make the build green.
5. A claim of the form "X MUST pass before completion" MUST be executed by a hook. If no hook
   runs it, delete the claim rather than leave it as decoration.

**Verification mechanism:**
Hook A (file size): `wc -l` vs `git show HEAD:<path>` — blocks new/growing violations, warns on
static legacy ones. Hook B (multi-component): unchanged AST-free heuristic. Lint gate: real
`npm run lint` exit code, output piped back to the agent on stderr. Config presence:
`npx eslint --print-config <file> | grep <rule-id>` in both agent gates and reviewer M5.
All four hook paths were exercised against a scratch repo (new-over-limit → blocked;
legacy shrinking → warned; legacy growing → blocked; test file → exempt) and both lint-gate
paths (fail → exit 2 with output; pass → exit 0).

**Self-score:**
```
  1. Specificity Avoidance  : 10/10   (rules are rule-ids and thresholds; no project nouns)
  2. Verifiability          : 10/10   (every layer is an exit code or a --print-config grep;
                                       all six paths executed, not reasoned about)
  3. Placement              :  9/10   (GATE 3 before the persona; conventions above the
                                       framework-specific sections)
  4. Clarity                :  9/10   (merge order explicit; one threshold, stated once)
  5. Completeness           :  9/10   (FE + BE parity; legacy-adoption path; plugin-missing
                                       path; test/migration exemptions)
  6. Anti-Regression Power  : 10/10   (a junior-shaped file now cannot be written at all, and
                                       a task with failing lint cannot be marked complete)
  7. Brevity                :  7/10   (+90 lines of helper prose; two new config files)
  8. Evidence Grounding     : 10/10   (each hole tied to a grep that returned 0 or a hook that
                                       returned exit 0)
  9. Consistency            :  9/10   (300/30 now identical in prose, lint and reviewer M1/M2)
 10. Actionability          : 10/10   (merge order, install commands, verify command, and the
                                       burn-down procedure are all copy-pasteable)
────────────────────────────────
 Overall                    : 9.3/10
```
Weakest: **Brevity 7/10** — same trade as the previous entry; procedure does not compress.

**Deliberately NOT done (user-scoped out):** ③ pre-write decomposition-plan gate (the only
remaining change that acts on the *production* side rather than detection), ⑤ rewriting the
hollow `senior-frontend`/`senior-backend` skills, ⑥ verifying `skills_used:`. Also unaddressed
by user decision: the folder-structure/Blueprint depth gap diagnosed this session — the user
elected to review `architecture.md` manually instead.

**Known drift found in passing (not fixed):** `plugins/vfm-agent-company/hooks/hooks.json`
registers `subagent-verify-go.sh`, which has no counterpart in `.claude/settings.json`. The two
hook registries have diverged; worth reconciling in its own pass.

**Commit:** 00b8391

**Follow-up (same 1.10.0 release): hook-registry drift closed + guarded.**
The "known drift found in passing" above turned out to be a half-installed feature, not a
stray file. Commit `74ba59f` ("enforce /go self-check for 11 code-producing specialists")
mirrored the *instruction* half — the MANDATORY `/go` rule — into all 11 agent files on both
sides, but put the *enforcement* half (`subagent-verify-go.sh` + its registration) into
`plugins/hooks/hooks.json` only. `git log --all -- .claude/hooks/subagent-verify-go.sh`
returns nothing: it never existed on the `.claude/` side. So in that runtime, eleven agent
files carried "No /go PASS evidence = task NOT complete" and **nothing audited it**. The
`validate-schema.py` PostToolUse hook (from the claude-seo merge) had the same one-sided
registration.

Fixed:
- Ported `subagent-verify-go.sh`, `validate-schema.py`, `run-python-hook.js` into
  `.claude/hooks/` and registered both hooks in `.claude/settings.json`.
- Added `.claude/hooks/validate-schema.sh` — a stdin wrapper, because the plugin registry
  passes the path via `${tool_input.file_path}` templating while `settings.json` hooks receive
  the payload on stdin. Same behaviour, different plumbing; recorded as an alias in the checker.
- **New: `.claude/scripts/check-hook-registry-drift.sh`** — compares the two registries
  (normalising matcher order and group layout) and verifies every referenced script exists on
  its own side. Exits 1 naming the gap. It found a real second difference while being written
  (matcher `Write|Edit` vs `Edit|Write` in different groups), which is what a working detector
  should do. Now reports: *19 hook registrations across 7 events, all scripts present on both
  sides.*
- **`claude-architect/SKILL.md` Step 4 gains a "Mirror to BOTH runtimes" block** — the general
  principle: *a feature is not applied until its instruction half AND its enforcement half
  exist on both sides*, with the two commands to prove it and an explicit ban on bumping the
  version while either reports a difference.

General principle (6th for this entry): **when a system ships more than one copy of itself,
parity between the copies MUST be machine-checked. A rule that is enforced in one runtime and
decorative in another is worse than no rule — it reads as covered.**

**Commit:** 00b8391

---

## [2026-08-28] Pointer integrity — a reference to a file nobody wrote reads as coverage

**Trigger (user report):**
> "Tôi cần biết ui designer agent và các skill của agent này" → while answering, the agent
> file's own "Full reference" pointer was checked and did not resolve. User: "Có đấy fix đi".

**Iteration:** 2nd pass on `apple-ux-wireframer` (1st was 2026-08-05, skill wiring).

**Root cause (one pattern, three instances):**
A doc can point at something that does not exist, and nothing in the system notices. Three
live instances, all silent at runtime — the agent reads nothing / loads nothing and improvises,
which is indistinguishable from the rule being followed:
1. `apple-ux-wireframer.md:159` — `Read helpers/ux-wireframe-standards.md` for "screen frames,
   interaction indicators, flow arrows, localization, and presentation templates".
   `git log --all -- '*ux-wireframe-standards*'` returns nothing: **the file was never written.**
   The 2026-08-05 entry moved the ASCII standards out of the agent body into a helper to keep
   the agent lean — and the helper half of that move was never committed. Every wireframe since
   has been drawn to improvised conventions.
2. + 3. `apple-ios-lead.md:13` and `google-android-lead.md:13` — `lazySkills: ui-ux-pro-max-skill`.
   That string is the **plugin** name from `settings.json` `enabledPlugins`
   (`"ui-ux-pro-max@ui-ux-pro-max-skill"`), not the skill name. `skills/ui-ux-pro-max-skill/`
   does not exist, so both mobile leads have shipped with **no** UI/UX intelligence loaded
   while their frontmatter claimed it.

Why the existing guards missed all three: `check-drift.sh` proves the two runtimes are
IDENTICAL, and `check-hook-registry-drift.sh` proves hook registries match. Both were green —
because each broken pointer was broken *identically on both sides*. Mirror parity says nothing
about whether a pointer resolves.

**Fix:**
- Wrote `helpers/ux-wireframe-standards.md` (303 lines) — canonical frames + fixed widths per
  viewport, the callout/indicator glyph legend, gesture + touch-target rules, the flow-arrow
  vocabulary (incl. a mandatory failure edge), localization/character-width rules (the
  double-width emoji + CJK trap that silently breaks every frame, longest-locale sizing, RTL),
  the design-system binding (token names only, never raw hex/px — ties to
  `subagent-inject-wireframe.sh` + reviewer rejection), file templates for screen/README/flows/
  components, the approval-gate presentation template, and a pre-submit checklist.
  Deliberately **complementary**, not duplicative: the `ux-wireframing` skill keeps the element
  library and app examples; the helper owns conventions + templates.
- Fixed the two `lazySkills` entries to `ui-ux-pro-max` on both sides.
- **New guard — reference integrity in `check-drift.sh`.** After the mirror pass, every
  `helpers/*.md` pointer in `core/` + `agents/`, and every `lazySkills:` entry, must resolve —
  checked independently on each side (plugin-qualified `a:b` skills skipped). Exits 1 naming
  the file and the dangling target. Verified it catches all three regressions when reverted.

**Generalization check:** the guard keys on *pointer resolves*, not on the three known names —
any future helper or skill reference is covered the moment it is written.

**Upgrade type:** [ added + fixed + guarded ]

**Self-score:** 9.4 · Root cause 10 (git-log proof the file never existed) · Generalization 10
(name-free structural check) · Anti-regression 10 (guard fails on revert) · Brevity 7 (+303
lines of helper, but it is the content the agent was already told to read).

**Version:** 1.10.0 → 1.10.1 (patch — one missing helper, two wiring fixes, one new guard).

**Pre-existing, NOT touched:** `check-drift.sh` still reports `enforce-delegation.sh` DIFFERS and
`validate-schema.sh` MISSING in plugin. Both are the documented by-design plumbing split
(stdin wrapper vs `${tool_input.file_path}` templating) recorded in the 1.10.0 follow-up above;
`check-hook-registry-drift.sh` — the authority on that question — reports match. Worth teaching
`check-drift.sh` the same alias list in its own pass so its output is not routinely ignored.

**General principle (7th):** **a pointer is a promise. Mirror checks prove the copies agree;
they cannot prove the promise is kept. Every path a doc tells an agent to read must be
machine-verified to exist — a dangling reference is worse than a missing rule, because the
frontmatter reads as covered.**

## [2026-08-28] UI quality — measurement replaces prose; the reviewer finally sees pixels

**Trigger (user report):**
> "Hiện tại với skill là không đủ để agent làm UI đẹp được. Tôi được gửi cho 1 list script
> và hook như này. Bạn check xem có sáng tạo được không?" (+ a screenshot of another
> project's `hooks/` and `scripts/` directories: token checks, clone-fidelity extractors,
> design-system generators, screenshot lifecycle hooks.)

**Iteration:** 3rd pass on the UI chain (2026-08-05 wired the design agent's skills;
2026-08-28 wrote its missing standards helper). Both previous passes added **prose**. The
complaint after both is that UI still is not good — which is the signal that the missing
thing was never more prose.

**Root cause — the system had no way to be wrong about UI.**
`helpers/code-quality.md` shipped a table naming its own hole: Rule #2 (follow the design
system) listed `Hook —  ESLint —  Review ✅ (only layer)`, directly above the sentence *"a
standard enforced by prose alone gets re-argued as a trade-off at every review until it
silently stops existing."* Three compounding gaps:

1. **No machine-readable contract.** `.project/design-system.md` is markdown. Nothing can
   be compared against markdown, so even the review layer could only pattern-match "looks
   like a raw hex" rather than decide "`#3B82F6` is not any declared color".
2. **No write-time gate.** Every other standard (file size, one-component-per-file, lint)
   blocks on write. The design system — the contract every UI specialist is locked to and
   the one the wireframer exists to author — blocked nothing.
3. **Nothing in the pipeline had ever rendered the UI.** Lint reads source, the hooks read
   source, and `google-code-reviewer` graded interfaces from source with no `Bash` tool and
   no image. A page could be consistent, accessible and characterless and pass every gate.

**Upgrade — three layers, each measuring something the previous one cannot see:**

*Tier 0 — the artifact.* `scripts/build-styles-json.js` compiles ANY design-system markdown
into `design-system.json` (+ optional `tokens.css`) by harvesting name→value pairs from
tables and CSS custom properties, classifying by **value shape first, name second** — so a
project using different token names still parses. `--check` fails on unfilled placeholders:
the difference between a contract and a template. The wireframer must now run it before
handover.

*Tier 1 — conformance.* `hooks/enforce-design-tokens.sh` → `scripts/check-design-tokens.js`
blocks four classes on every UI write, against the project's OWN tokens: C1 color literal,
C2 off-scale radius, C3 off-scale font-size / undeclared family, C4 off-scale
padding/margin/gap. Deliberately **fails open** (no design system → exit 0) and deliberately
**does not check width/height** — a fixed width is a layout decision, padding is a rhythm
decision, and an over-blocking gate gets switched off, which is worse than none because it
still reads as covered.

*Tier 2 — the rendered truth.* `scripts/ui-capture.js` drives Playwright over
routes × 3 viewports × light/dark, writes screenshots and measures five things that are
numbers rather than opinions: WCAG contrast on composited colors, viewport overflow,
sub-44px touch targets, sub-12px text, >95ch line length. `scripts/check-visual-report.js`
grades the artifact **without a browser**, so a report produced via the Playwright MCP
tools is judged by identical rules. `subagent-verify-visual.sh` audits that a fresh report
exists. And `subagent-inject-wireframe.sh` now injects the report **and the screenshot
paths** into `google-code-reviewer`, which is told to `Read` them — the first time any
reviewer in this framework has seen the interface it grades.

**The honest limit, stated in the helper itself:** Tier 0+1 make a UI *consistent*; Tier 2's
numbers only prove it is *not broken*. Neither makes it good. `helpers/ui-visual-standards.md`
§4 therefore adds a 9-dimension craft rubric scored **from the screenshot**, ending at
*point of view* — "a build that is consistent, accessible and characterless has passed every
gate and still failed."

**Runtime-verified, not asserted** (per the repo's own /go principle): Playwright was
installed and both scripts run against a deliberately broken page. This caught a real bug
that source review would not have: the overflow check compared against `window.innerWidth`,
but mobile emulation **expands the layout viewport to fit overflowing content** (390 → 916
on the fixture), so the check silently always passed — the exact defect it exists to catch.
Fixed to measure against the configured viewport. Final fixture run: contrast 1.74:1 caught,
526px overflow caught, 24×24 target caught, 10px text caught.

**Files:** +4 scripts, +2 hooks, +1 helper (`ui-visual-standards.md`), 3 agents rewired,
`code-quality.md` table corrected (Rule #2 now `Hook ✅ blocks`; a new row for rendered
defects; Rule #3 flagged as the remaining prose-only standard), both hook registries.

**Upgrade type:** [ added + strengthened ]

**Self-score:**
```
🎯 Upgrade Self-Score
Target:     UI enforcement chain (code-quality · 3 agents · 2 hooks · 4 scripts · 1 helper)
Trigger:    "skill là không đủ để agent làm UI đẹp được"
Rule class: added (mechanical layers) + strengthened (agent obligations)

  1. Specificity Avoidance  : 10/10  (every threshold comes from the project's own tokens
                                      or a published standard — WCAG AA, 44px HIG; zero
                                      project/palette/brand values in any checker)
  2. Verifiability          : 10/10  (each rule IS a command with an exit code)
  3. Placement              :  9/10  (obligations sit in the agents' pre-action gates; the
                                      helper is referenced from every one)
  4. Clarity                :  9/10  (MUST/BLOCKED throughout; exempt paths enumerated)
  5. Completeness           :  9/10  (author → write → render → review covered; Rule #3
                                      duplication left prose-only and labelled as such)
  6. Anti-Regression Power  :  9/10  (Tier 1 makes the failure unwritable; Tier 2 is an
                                      audit + injection, deliberately non-blocking)
  7. Brevity                :  6/10  (~900 lines of new tooling — the honest cost of
                                      converting an opinion into a measurement)
  8. Evidence Grounding     : 10/10  (the repo's own enforcement table named the hole; the
                                      fixture run produced the numbers quoted above)
  9. Consistency            : 10/10  (fails open like the lint gate; audits like verify-go;
                                      injects like the design-system block)
 10. Actionability          : 10/10  (every message names the command that fixes it)
────────────────────────────────
 Overall                    : 9.2/10
```
Weakest: **Brevity 6/10** — unavoidable in kind. A measurement cannot be expressed as a
sentence; that is the entire point of the entry.

**Version:** 1.10.1 → 1.11.0 (minor — new enforcement layer, 4 scripts, 2 hooks, 1 helper).

**Deliberately NOT done (user-scoped):** Tier 3, the clone-fidelity pipeline (~12 scripts:
DOM/asset extraction, hover + animation capture, layout-fidelity diff, section stackify).
`clone-website` remains 564 lines of prose with zero scripts — the same prose-only disease
this entry cures for the design system, still untreated for cloning. Own pass.

**General principle (8th):** **a quality bar that is never measured is a preference. Prose
can state intent; only an artifact plus a threshold can enforce it — and for anything
visual, the artifact must be the RENDERED result, because every gate that reads source code
is blind to the difference between a well-formed UI and a good one.**

---

## [2026-09-01] core/pm.md · core/cto.md · apple-ux-wireframer — Sprint 0 Foundation Batch + stack-aware design system

**Trigger (user report):**
> "sprint 0: Luôn phải là dựng structure, luôn xây dựng các component base, đưa ra code
> standard, convention code của cả FE và BE. Hiện tại đang thiếu bước này khiến cho agent
> FE dựng UI rất xấu và thiếu tính đồng bộ."
> "Khi mà sử dụng agent ux-wireframe chưa matching với các stack UI đã chọn? Lí do là gì"

**Iteration count:** 1st report of the foundation gap; the design-system half is the **3rd**
pass over UI quality (v1.7.0 design-system injection → v1.11.0 token/render enforcement →
this). The first two made the *contract* stricter; neither asked whether the contract was
written for the right platform, or who builds the components it describes.

**Root cause:**

*Gap 1 — nothing installs the standards or the primitives.* `pm.md` defined Sprint 0 as
"Planning Sprint (no code)" and Gate 1 as a check that **documents exist**. Sprint 1 then went
straight to features under the Minimum Parallel Agents Rule (2–5 agents). So the first UI
sprint had no tree, no lint config, and no primitives — and N agents each answered "what does
a button look like here?" simultaneously and differently. The repo had already written the
admission down without acting on it: `code-quality.md` said *"Nothing copies
`eslintrc.frontend.json` automatically — the frontend agent merges it during scaffolding"*,
where "scaffolding" was a step no role owned, no sprint contained, and no gate verified. **A
standard that is only installed if someone remembers is not installed.**

*Gap 2 — the design system never knew its platform.* `grep -rn "tech-stack"` over
`apple-ux-wireframer.md`, `design-trends.md`, `ux-wireframe-standards.md`,
`ui-visual-standards.md` and `templates/design-system.md` returned **zero hits**. The agent's
only inputs were the trend catalog and the requirements, so it emitted the pipeline's native
dialect — CSS variables and a Tailwind mapping — for *every* project. Three compounding
causes: (a) no stack input; (b) `pm.md` Step 3 listed the wireframer spawn *above* the
tech-stack row, so it could run before `tech-stack.md` was written; (c) every downstream
artifact was web-shaped — `check-design-tokens.js` matched only
`tsx|jsx|ts|js|css|scss|sass|less|vue|svelte|astro`, so `.swift`/`.kt`/`.dart` were **silently
unchecked**, while `subagent-inject-wireframe.sh` still injected the CSS-var file into
`apple-ios-lead` and `google-android-lead` as "tokens you may not bypass". A contract in a
dialect the target cannot consume, backed by a gate that never reads the target's files.

**Upgrade type:** added (new sprint phase + gate + platform dialect layer) · strengthened
(role obligations, spawn ordering) · relocated (stack read promoted to the agent's first action)

**Files touched** (mirrored to `plugins/vfm-agent-company/` — drift check clean):
- `helpers/pm-foundation-sprint.md` — **new**, the F1–F4 playbook
- `automation/validate-foundation.sh` — **new**, the Foundation Gate (fixture-tested both ways)
- `core/pm.md` — Sprint 0 step 6, Foundation Gate, Step 3 ordering, 4 anti-patterns
- `core/cto.md` — Foundation Manifest as mandatory architecture.md §6
- `agents/apple-ux-wireframer.md` — Phase 0.0 stack gate, Platform Token Dialect table,
  honest enforcement-coverage note, Phase 0.3 primitive declaration
- `templates/design-system.md` — platform header, "Platform token mapping (MANDATORY)",
  "Base primitives (Sprint 0 F3)"
- `helpers/ui-visual-standards.md` — §1.5 platform coverage matrix
- `helpers/code-quality.md`, `helpers/pm-sprint0-checkpoints.md`, `skills/work/SKILL.md`
- `scripts/check-design-tokens.js` + `hooks/enforce-design-tokens.sh` — native C1 coverage
- version 1.11.0 → 1.12.0 (minor)

**General principles added:**

1. **Nothing may be invented in a feature sprint that could have been decided once in
   Sprint 0.** Where work is parallelised, every undecided question is answered N times in
   N different ways — and no downstream review can merge those answers back together.
   Therefore the phase that plans a contract must be followed, before any feature work, by a
   phase that *builds* it: structure, per-layer convention config, and the shared component
   layer, each verified by running the project's own commands.
2. **A convention is installed only when it has been observed rejecting something.** F2
   requires introducing a deliberate violation, showing the tool report it, and reverting.
3. **A design system is platform-typed, not universal.** The artifact that generates it MUST
   read the stack before its first decision, emit tokens in exactly one dialect — the
   target's — and STOP rather than guess when the platform is unresolved. A token file in the
   wrong dialect is a defect, not a draft, because it is auto-injected as a binding contract
   regardless of whether the target can consume it.
4. **State enforcement coverage where it varies, rather than implying it is uniform.** Gates
   whose checks are one platform's *syntax* must declare which platforms they cannot verify —
   and where fewer gates apply, the written contract must be more concrete, not less.

**Verification mechanisms:**
- `bash .claude/automation/validate-foundation.sh` — reads the CTO-declared Foundation
  Manifest; every declared path must exist non-empty, every declared command must exit 0.
  Zero stack knowledge in the script: the project declares its own artifacts and its own
  commands, so TS, Swift, Kotlin, Dart, Go and Python go through one code path. Exit 2 on a
  missing or placeholder manifest; rejects commands left as template text.
- Fixture-tested: fail path (missing artifact + failing command → exit 1), pass path (exit 0),
  no-manifest path (exit 2).
- `check-design-tokens.js` now classifies files `web | native | null`; C1 runs on both
  (adding packed `0xAARRGGBB` literals for native), C2–C4 stay web-only **by declaration**.
  Fixture-verified: undeclared `0xFFDE0000` in a Kotlin product file → C1; declared value →
  clean; `Theme.kt` → exempt; `13.dp` → correctly not reported (C4 is CSS syntax).
- `design-system.md` must carry a `Platform:` header line naming its source and an
  `Enforcement:` line naming the gates that do and do not apply.

**Self-score:**

```
🎯 Upgrade Self-Score

Target:     core/pm.md · core/cto.md · apple-ux-wireframer (+7 supporting files, 2 scripts)
Trigger:    "thiếu bước dựng structure/component base/code standard → UI xấu, thiếu đồng bộ"
            + "ux-wireframe chưa matching với stack UI đã chọn"
Rule class: added (Foundation phase + gate) · strengthened (ordering) · relocated (stack read)

                              Foundation   Stack-aware DS
  1. Specificity Avoidance  :    9/10          10/10
  2. Verifiability          :   10/10           8/10
  3. Placement              :   10/10          10/10
  4. Clarity                :    9/10          10/10
  5. Completeness           :    9/10           9/10
  6. Anti-Regression Power  :    8/10           9/10
  7. Brevity                :    7/10           8/10
  8. Evidence Grounding     :   10/10          10/10
  9. Consistency            :   10/10          10/10
 10. Actionability          :   10/10          10/10
────────────────────────────────────────────────────────
 Overall                    :    9.2           9.4      →  combined 9.3/10
```

**Weakest dimensions:**
- **Anti-Regression 8/10 (Foundation)** — the gate is a script, but *calling* it is a PM
  instruction, exactly like Gate 1. A PM that skips the call still spawns features. A
  `SubagentStart` hook that refuses a feature-task spawn while `sprint-0.md` is incomplete
  would close this; deferred because it needs a reliable "is this a feature task" signal,
  and a wrong guess blocks legitimate work.
- **Verifiability 8/10 (dialect)** — that the emitted dialect *matches* the declared platform
  is still judged by the reviewer, not a script. A checker comparing the `Platform:` header
  against the token syntax present in the file is the obvious follow-up.
- **Brevity 7/10** — ~330 new lines. The foundation playbook is genuinely a playbook; the
  script is the part that makes it more than an opinion.

**Deliberately NOT done:** `ui-capture.js` remains browser-only, so the render loop does not
run on native targets — documented in §1.5 as an explicit gap rather than papered over. A
simulator/emulator capture path writing the same `visual-report.json` shape is its own pass.

**Pre-existing drift observed, not fixed here** (out of scope, reported to user):
`check-drift.sh` flags `hooks/scripts/validate-schema.sh` missing from the plugin runtime and
`enforce-delegation.sh` differing. Neither was touched by this upgrade.

**Commit:** <pending>

---

## [2026-09-01] ux-wireframe-standards · apple-ux-wireframer · subagent-inject-wireframe — Layout Intent + rendered design proof

**Trigger (user report):**
> "Tôi cảm giác agent ux vẽ wireframe không tốt, và khi agent frontend vào code theo
> wireframe sẽ rất là xấu"

**Iteration count:** 4th pass on UI quality (v1.7.0 design-system injection → v1.11.0 token
+ render enforcement → v1.12.0 foundation + platform dialect → this). Each earlier pass
tightened what happens *after* the design exists. None asked whether the design artifact
itself can carry the information the result is graded on.

**Root cause:**

The user's two complaints are one defect, and it is not the agent being bad at drawing.

`grep -rn -iE "hierarch|proximity|grouping|visual weight|proportion|density|emphasis|measure|
max-width|column|grid|rhythm"` across `ux-wireframe-standards.md` (303 lines) and
`skills/ux-wireframing/SKILL.md` (342 lines) returned **three hits, all about emoji character
width**. The wireframe pipeline had a complete vocabulary for notation — frames, glyphs,
callouts, states, flows, a11y, localization — and **zero** vocabulary for hierarchy,
proximity, proportion, density, emphasis or measure. Meanwhile `ui-visual-standards.md` §4
grades the built interface on precisely those dimensions. **The design specified everything
except what the result is judged on**, so the developer had to guess the entire visual half.

Compounding it, the delivery mechanism commanded literal transcription. The injection hook's
closing line was `📋 Follow the layout exactly`. Applied to a monospace grid — one cell size,
one font weight, a border around every region because a border is the only available boundary
— "exactly" produces boxes-inside-boxes with uniform padding and flat typography. **The
frontend agent was not disobeying the wireframe; it was obeying it.** A low-fidelity medium
was handed the authority of a high-fidelity specification.

Third: the design side had no visual feedback loop at all. The implementation side has been
required since v1.11.0 to render and measure (`ui-capture.js`); the UX agent shipped a
character grid and never saw a pixel, and the user approved that character grid. So the first
sight of the real product came *after* it was built — with tokens, wireframes and code all
encoding the same unexamined guess. (`visual-preview`, in the agent's `lazySkills`, is an
ASCII/Mermaid *code-explanation* skill — it never closed this loop.)

**Upgrade type:** added (Layout Intent artifact + design render loop) · strengthened
(wireframe authority scoped) · deleted-conflict (the "follow exactly" instruction)

**Files touched** (mirrored; registry + file drift clean):
- `helpers/ux-wireframe-standards.md` — **§0** authority scope (BINDING vs NOTATION-ONLY
  table, placed before the first drawing instruction); **§2.5 Layout Intent** (mandatory per
  screen); **§5.5 render before presenting**; screen template, approval-gate template and
  pre-submit checklist updated
- `agents/apple-ux-wireframer.md` — Responsibility 1 rewritten (intent first, drawing
  second), new Responsibility 4 (render + measure + self-score §4), workflow, output tree
  (`wireframes/preview/`), quality checklist
- `hooks/subagent-inject-wireframe.sh` — "Follow the layout exactly" replaced by the scoped
  authority block; visual-evidence injection **split**: a `design-preview` capture is now
  labelled 🎯 DESIGN REFERENCE (the target) rather than 📸 VISUAL EVIDENCE (a render of the
  agent's own code), so a reviewer cannot grade the design as if it were the implementation
- `helpers/ui-visual-standards.md` — design render added to the §1 pipeline; §5 role table
- version 1.12.0 → 1.13.0 (minor)

**General principles added:**

1. **A specification medium has an authority ceiling, and it must be stated where the
   specification is delivered.** An artifact may only bind the consumer on what it can
   actually express; for everything else it is notation, and the real decision must be
   written somewhere the medium does not distort. Telling a consumer to follow a
   low-fidelity artifact "exactly" converts the medium's limitations into product defects.
2. **Specify what you grade.** Where a rubric judges dimensions the design artifact cannot
   carry, the gap is filled by guesswork every single time. Each graded dimension gets a
   declared field in the artifact — one focal point, group gaps that differ from
   between-group gaps, density, one accent, measure, columns.
3. **The artifact that specifies a visual result must itself be rendered and subjected to
   the same gates the result will face.** Otherwise the failure modes are being specified in
   a medium that cannot express them, and the first honest look at the product happens after
   it is built. A contrast failure in the design render is a broken palette — fix the tokens,
   not any screen's markup.
4. **Injected evidence must name what it is evidence OF.** A render of the design and a
   render of the implementation are different claims; unlabelled, the second gets satisfied
   by the first.

**Verification mechanisms:**
- Screen files must carry a `## Layout Intent` block; the hook instructs the UI specialist to
  **STOP and ask the PM** when it is absent rather than inventing proportions from character
  counts — the failure surfaces at the point of use instead of silently.
- The design preview reuses the existing measured pipeline unchanged:
  `ui-capture.js --url "file://$(pwd)/.project/wireframes/preview"` → `check-visual-report.js`
  → contrast · overflow · touch-target must be 0, craft rubric self-scored from the images.
- Hook fixture-tested end to end: wireframe injection renders valid JSON with the scoped
  authority block; the `design-preview` branch and the ordinary-evidence branch each verified
  to emit their own labelling. (An escaping bug — backticks inside the double-quoted context
  string, which `bash -n` accepts but which execute as command substitution at runtime — was
  caught by that runtime test and removed.)

**Self-score:**

```
🎯 Upgrade Self-Score

Target:     ux-wireframe-standards · apple-ux-wireframer · subagent-inject-wireframe (+1 helper)
Trigger:    "agent ux vẽ wireframe không tốt → frontend code theo wireframe rất xấu"
Rule class: added (Layout Intent + design render loop) · strengthened (authority scope)
            · deleted-conflict ("Follow the layout exactly")

  1. Specificity Avoidance  : 10/10  (no project, screen, brand or value anywhere; the
                                      primitive/screen lists are derived by counting)
  2. Verifiability          :  9/10  (design render is a measured command with thresholds;
                                      "one focal point" is checkable by reading the block —
                                      but no script asserts the block exists)
  3. Placement              : 10/10  (§0 precedes the first drawing instruction; the
                                      authority scope travels WITH the wireframe at the
                                      moment of use, not in a file the dev may not open)
  4. Clarity                : 10/10  (BINDING vs NOTATION-ONLY table; MUST/STOP throughout)
  5. Completeness           :  9/10  (all six ungraded dimensions given fields; sibling
                                      modes — flat type, uniform gaps, multi-accent,
                                      false proportions — each named)
  6. Anti-Regression Power  :  9/10  (removes the instruction that CAUSED the failure and
                                      supplies the missing input; a dev following the new
                                      injection cannot transcribe borders literally)
  7. Brevity                :  7/10  (~150 lines; the Layout Intent block itself is 6 lines,
                                      which is the part that runs every time)
  8. Evidence Grounding     : 10/10  (the 3-hit grep and the verbatim "Follow the layout
                                      exactly" line are both quoted above)
  9. Consistency            : 10/10  (reuses ui-capture/check-visual-report unchanged;
                                      matches the §4 rubric's own vocabulary one-to-one)
 10. Actionability          : 10/10  (a fill-in template + a runnable command block)
────────────────────────────────
 Overall                    :  9.4/10
```

**Weakest dimensions:**
- **Brevity 7/10** — the standards file grew by three sections. Irreducible: the missing
  information was six whole dimensions, and naming them is the fix.
- **Verifiability 9/10** — no script asserts every screen file contains a `Layout Intent`
  block with a single focal point. A `validate-wireframes.sh` (grep each `screens/*.md` for
  the required headings, one `Focal point:` line, ≥2 distinct `space.` values in Groups)
  would make it mechanical. Worth doing next; the hook's STOP-and-ask covers the case where
  it matters most.

**Deliberately NOT done:** `skills/ux-wireframing/SKILL.md` still teaches the element library
and famous-app patterns with no layout-intent vocabulary. It is the *element* reference and
the standards file now owns conventions, so the split holds — but its "Best Practices" list
(6 items, none about hierarchy) is the weakest surviving surface in this pipeline.

**Commit:** <pending>

---

## [2026-09-01] ui-ux-pro-max → ui-design-system — one design-system skill, one generator, one author

**Trigger (user report):**
> "tôi nghĩ ui-ux-pro-max đang conflict với ui design. Tôi nghĩ nên loại bỏ skill này và
> nên luôn apply ui-design-system hơn"

**Iteration count:** 1st report of the conflict; 5th consecutive pass on UI quality.

**Root cause — the conflict was real, in three places:**

1. **Two generators claimed one output.** `ui-ux-pro-max/scripts/design_system.py` (invoked by
   `apple-ux-wireframer` Phase 0.2) and `ui-design-system/scripts/design_token_generator.py`
   both produced design tokens. The second was referenced by **zero** files — a dead asset
   whose existence still implied a second, competing way to author the contract.
2. **One agent was told to load both.** `apple-ux-wireframer.md:193` listed
   ``ui-design-system` + `ui-ux-pro-max`` for the same Phase 0.2 step.
3. **Two agent files contradicted each other on who may generate.**
   `meta-react-architect.md:44` permitted the frontend agent to run
   `ui-ux-pro-max --design-system`; `apple-ux-wireframer.md:142` stated the frontend agent
   "is BANNED from running it". Whichever agent ran last defined the palette.

**Why the reported remedy was inverted (raised with the user, who then chose the merge):**
the redundant asset was `ui-design-system`, not `ui-ux-pro-max` — 32 lines, 3 styles
(`modern/classic/playful`), zero craft vocabulary, and its only script never invoked. Its
stated role (token structure, dev handoff) was already owned, and owned better, by
`templates/design-system.md` + `helpers/ui-visual-standards.md`. `ui-ux-pro-max` held the
only non-redundant asset: 763 rows across 11 CSVs (50 styles · 97 palettes · 57 font
pairings · 99 UX guidelines · 11 per-stack pattern sets including `swiftui`, `react` and
`nuxt-ui` — the sources the v1.12.0 Platform Token Dialect work leans on). Deleting it as
first proposed would have broken Phase 0.2 and traded a library for a stub.

**Upgrade type:** deleted-conflict (merge) · strengthened (single-author rule)

**Resolution — merge, keeping the user's intent (one always-applied skill, that name):**
- `ui-ux-pro-max/{data/, scripts/core.py, search.py, design_system.py}` → `ui-design-system/`
- `ui-ux-pro-max/` **deleted**; `design_token_generator.py` (dead, 3 styles) **deleted**
- `.claude/settings.json` — removed `"ui-ux-pro-max@ui-ux-pro-max-skill"` from
  `enabledPlugins`. **Without this the external marketplace plugin re-provides the old skill
  and the conflict returns** — vendoring the data is only half a merge if the original is
  still installed.
- `SKILL.md` rewritten around the distinction the conflict came from: **the contract**
  (`.project/design-system.md`, one author) vs **the library** (`data/*.csv`, read-only,
  everyone). Scripts' internal branding strings renamed; `DATA_DIR` was already relative
  (`Path(__file__).parent.parent`), so no path edits were needed.
- 14 files rewritten across both runtimes; 4 agents' `lazySkills` de-duplicated (the rename
  collapsed two entries into one).
- version 1.13.0 → 1.14.0 (minor — skill restructure)

**General principles added:**

1. **One artifact, one author.** Where two components can both produce the same output, they
   do not "offer flexibility" — they race, and the last writer wins silently. Name the single
   owner in the consumer's own file, and give every other agent an escalation path instead of
   a fallback generator.
2. **A skill's value is its non-redundant asset, not its name.** Before deleting a skill for
   overlap, compare what each side uniquely holds; the more prominent name is often the
   emptier one. Here the 32-line skill was the redundant one and the 763-row skill was the
   asset — the reverse of the initial read, mine included.
3. **Removing a vendored copy does not remove the dependency.** A skill installed as an
   external plugin re-appears in the agent's list regardless of what the repo contains;
   consolidation must clear the registry entry too.

**Verification mechanisms:**
- `grep -rn "ui-ux-pro-max"` across both runtimes returns nothing outside this log and the
  new skill's own "replaces the former…" description line.
- Both scripts smoke-tested from the new location before and after the reference rewrite:
  `search.py --domain style` (3 results), `search.py --stack swiftui`, `design_system.py
  --format markdown` — all exit 0.
- `diff -rq` between the two runtimes' `skills/ui-design-system/` reports identical trees;
  hook registry check passes; `__pycache__` added to `.gitignore` (the smoke test generates
  it and it was about to be committed).

**Self-score:**

```
🎯 Upgrade Self-Score

Target:     skills/ui-design-system (merged) · 4 agents · model-tiers · settings.json
Trigger:    "ui-ux-pro-max đang conflict với ui design"
Rule class: deleted-conflict (merge two skills into one) · strengthened (single-author rule)

  1. Specificity Avoidance  :  9/10  (the single-author rule is stated generally; the entry
                                      necessarily names the two skills being merged)
  2. Verifiability          : 10/10  (grep returns zero stale refs; both scripts smoke-tested;
                                      diff -rq proves the runtimes identical)
  3. Placement              : 10/10  (the ban sits in the FE agent's design-system block —
                                      the exact paragraph read when the file is missing)
  4. Clarity                : 10/10  ("You may NOT generate a design system" + named owner
                                      + explicit escalation, replacing a permissive clause)
  5. Completeness           :  9/10  (contract-vs-library split, dead script, duplicate
                                      lazySkills, external plugin registry all covered)
  6. Anti-Regression Power  :  9/10  (the second generator no longer exists, so the race is
                                      not merely discouraged — it is unbuildable)
  7. Brevity                :  9/10  (net deletion: one skill and one dead script removed)
  8. Evidence Grounding     : 10/10  (the two contradicting line numbers and the zero-
                                      reference grep are quoted)
  9. Consistency            : 10/10  (matches the ownership model already used for the
                                      Foundation Manifest and the design-system injection)
 10. Actionability          : 10/10  (every agent now has one command path and one owner)
────────────────────────────────
 Overall                    :  9.6/10
```

**Weakest dimension:** Specificity 9/10 — unavoidable in a consolidation entry; the *rule*
that ships (one author per artifact) contains no proper nouns.

**Note for the user, not fixed here:** disabling the `ui-ux-pro-max-skill` marketplace plugin
is a settings change that also affects any other project using this settings file.

**Commit:** <pending>
