---
name: explore-repo-as-architect
description: "Read and understand an unfamiliar repository the way an ARCHITECT does — build an accurate map FIRST (wiring points + release-note feature graph), then send cheap sub-agents to read exact scopes with file:line EVIDENCE, verify their findings with an independent audit pass, and only then synthesize with a strong model. Use when the user asks to 'understand this repo', 'explore/read a codebase', 'reverse-engineer how X works', 'onboard me to this project', 'clone the architecture of', study an open-source repo before borrowing from it, or map a large/unfamiliar codebase. Vietnamese triggers: 'đọc repo', 'hiểu codebase', 'phân tích repo', 'khám phá dự án', 'map kiến trúc', 'đọc source như architect'. Alias: ck:xia (explore-repo-as-architect). Prevents the shallow default loop (README → tree → summarize) that misses wiring, loses context, hallucinates, and burns tokens."
---

# explore-repo-as-architect (`ck:xia`)

> **One line:** *Read little → understand deep.* Map before you read, read with evidence, verify before you trust, synthesize with the strong model — and use cheap models for the reading.

You are exploring a repository (this one, a cloned open-source repo, or a reference project the user wants to borrow architecture/ideas from). Your job is to produce an **accurate, evidence-backed mental model** of the codebase, not a vague text summary. Follow the architect's method below.

---

## 🧠 Core mindset — read like an ARCHITECT

1. **Understand architecture first** — the shape of the system before any single file.
2. **Find the wiring points first** — where components are *injected, set up, registered, connected*. Wiring reveals the real architecture faster than any folder.
3. **Use two graphs, not prose** — (Graph 1) the source-code/wiring map, (Graph 2) the release-notes/commit timeline. Together they give the highest-confidence picture.
4. **Deep — with evidence — with verification.** Every claim points to `file:line`. Every sub-agent result gets independently audited. No fabrication.

## 🚫 The default loop this skill REPLACES (anti-pattern)

The ineffective way most agents read a repo:

1. Read `README.md`
2. `ls` / tree the folders
3. Spawn sub-agents to "read modules"
4. Sub-agents hand back **text summaries** → main agent stitches them together

Why it fails:
- **Reads mechanically, not deep** → misses wiring, misses the important 5%.
- **Text summaries lose context** → downstream reasoning hallucinates.
- **Uses a big model for every sub-agent** → burns tokens for low signal.

If you catch yourself doing the above, stop and switch to the 5 steps below.

---

## 📋 The method — EXPLORE-REPO-AS-ARCHITECT (5 steps)

### Step 1 — Build the overall MAP (do this yourself, cheaply)

Produce **two artifacts** before deep reading anything.

**1A. Detect architecture & find wiring points → Code Map (Graph 1)**
Find where the system is assembled, not just where files live. Hunt for:
- **Entry points**: `main`, `index`, `app`, `server`, `cli`, `bootstrap`, `__main__`, framework entry (`next`, `vite`, `manage.py`, etc.).
- **Wiring / DI / registration**: dependency-injection containers, plugin/agent registries, route tables, `providers`, `configure*()`, `register*()`, `use*()`, hook/middleware chains, `export` barrels, config that maps names → implementations.
- **Boundaries**: package/module edges, public interfaces, adapters.

Concretely: `Grep` for the wiring keywords, `Glob` for entry files, read *only* the assembly files. Output an explicit graph:
```
ENTRY (wiring) ──▶ Module A ──▶ Module B
                └─▶ Module C ──▶ (adapter) ──▶ external
```

**1B. Release notes / commits → Feature Graph (Graph 2 = high-quality TODO list)**
Read the *evolution*, not just the current tree:
```bash
git log --oneline -30
git tag --sort=-creatordate | head -20
# plus: CHANGELOG.md, RELEASES.md, docs/releases, GitHub Releases
```
Collect major versions (v1 → v2 → v3) and the notable features each added. This yields a **ranked feature list** — effectively a high-quality TODO/inventory of what the repo actually does and in what order it mattered.

> **Result of Step 1:** Code map (Graph 1) + Feature list (Graph 2) → **highest confidence, lowest token cost.** You now know *what* to read deeply and *where* it lives.

### Step 2 — Directed detailed analysis (SPAWN cheap sub-agents at exact scopes)

Now, and only now, read deeply — and delegate the reading to **cheap sub-agents** aimed at *precise* scopes from your map. Do **not** say "go read the auth module"; say "read `src/auth/session.ts` and the token-refresh path, return the layers, the main logic, the algorithm, and file:line for each."

Each sub-agent's handoff MUST contain:
- ✅ **Layers** of the feature (the responsibility stack).
- ✅ **Main logic** (the actual control/data flow).
- ✅ **Key algorithm** (if any).
- ✅ **Exact implementation location** — *which file, which lines* (e.g. `file.go:123-175`).
- ✅ **EVIDENCE** — quoted code / line refs that prove the claim isn't fabricated.

**Model choice (important — this is where the savings are):** run sub-agents on a **small/cheap model** (Haiku or similar). Reading a bounded scope and reporting file:line is exactly what small models do well: good enough, cheaper, token-frugal. Reserve the strong model for Step 4.

In this harness:
- Prefer the **`Explore`** agent for read-only fan-out searches (it reads excerpts, returns conclusions), and the **`general-purpose`** agent for a bounded deep-read of a specific scope.
- Pass `model: "haiku"` on the `Agent` call to keep sub-agent reads cheap.
- Give each sub-agent **one scope** and demand the evidence fields above in its report. Launch independent scopes **in parallel** (multiple `Agent` calls in one message).

### Step 3 — Independent verification (AUDIT pass)

Never trust a sub-agent's report blind. Spawn a separate **audit agent** (also cheap) whose only job is to *check*, not to summarize:
- **Cross-check against source** — do the cited `file:line` refs actually contain what was claimed?
- **Check logic, location, consistency** — does the described flow match the code?
- **Detect omissions / drift** — what did the reader miss or overstate?

The audit agent returns CONFIRMED / DISCREPANCY per claim. Discrepancies go back to Step 2 for a re-read. This is what makes the final map *trustworthy* rather than merely plausible.

### Step 4 — Aggregate & choose (STRONG model reasons here)

Now the **main agent (strong model — Opus-class)** does the judgement work the cheap readers can't:
- **Which parts fit the current project's context** — what's relevant vs. noise.
- **What's worth learning / borrowing** and **what to skip**.
- **Proposed architecture & implementation direction** grounded in the verified map.

This is the only step that needs the expensive model, because it's reasoning over an already-verified, evidence-dense map — not re-reading raw files.

### Step 5 — Apply & deploy

Turn the verified map + judgement into action: write the **plan**, then implement. Because the map is accurate and evidence-backed, the plan is grounded in how the code *actually* works — so implementation is fast and correct.

> Real-world shape of the payoff: pull the *core* from one repo, graft the *architecture* from another, take the *agent-core/"soul"* from a third — confidently, because each was mapped and verified rather than guessed.

---

## ✅ Principles (the checklist to hold yourself to)

- [ ] **Read little → understand deep** (map first, don't read everything).
- [ ] **Clear goal** for every read (bounded scope, stated question).
- [ ] **Evidence** on every claim (`file:line`, quoted code).
- [ ] **Verification** by an independent audit pass.
- [ ] **Smart filtering** — keep what's relevant, drop the rest.
- [ ] **Cheap model for reading, strong model for judging.**

## 🎛️ Quick reference — who does what

| Step | Actor | Model | Output |
|------|-------|-------|--------|
| 1. Map | You (main) | — | Graph 1 (wiring) + Graph 2 (release/feature list) |
| 2. Deep read | Sub-agents, one per scope, in parallel | **cheap (Haiku)** | handoff w/ layers, logic, algorithm, `file:line`, evidence |
| 3. Audit | Independent audit agent | **cheap** | CONFIRMED / DISCREPANCY per claim |
| 4. Synthesize | You (main) | **strong (Opus)** | relevance judgement + architecture proposal |
| 5. Apply | You (main) | strong | plan → implementation |

## When NOT to use this

- A single small file or a one-line lookup — just read it directly.
- You already have an accurate map from earlier in the session — skip to Step 2/4.

---

*Alias `ck:xia`. Mantra: "Hiểu đúng bản chất, đọc đúng cách, AI sẽ là cánh tay đắc lực nhất của Vibe Coder." — Understand the essence, read the right way, and the AI becomes the Vibe Coder's most capable hand.*
