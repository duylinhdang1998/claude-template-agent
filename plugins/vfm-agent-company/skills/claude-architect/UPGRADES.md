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
