---
name: pm-foundation-sprint
type: helper
description: |
  Sprint 0 Foundation Batch — the ONE code-producing step of Sprint 0, run after
  Gate 1 and before Sprint 1. Establishes the repo structure, the base component
  layer, and the machine-enforced FE/BE conventions that every later sprint
  inherits. PM reads this to build sprint-0.md and spawn the foundation agents.
---

# Sprint 0 — Foundation Batch

> **Why this exists.** Planning produces a *contract* (`design-system.md`,
> the File Blueprint, the convention docs). None of those are executable. Without a
> step that turns them into a running skeleton, the first feature sprint's dev agents
> each derive their own directory layout, their own button, their own spacing habits —
> and because sprints spawn **2–5 agents in parallel**, N agents produce N divergent
> answers to the same question, simultaneously. The result is an interface that is
> inconsistent by construction, and no downstream gate can fix it: a token check proves
> a colour came from the system, never that two screens share a button.
>
> **The rule this encodes: nothing may be invented in a feature sprint that could have
> been decided once in Sprint 0.**

---

## ⛔ Non-negotiables

```
⛔ Sprint 0 Foundation is MANDATORY for every NEW project. It is never
   "skipped for MVP speed" — it is what makes speed survivable.
⛔ NO feature task may be spawned until `validate-foundation.sh` exits 0.
⛔ Foundation tasks build the SHELL, never a feature. No business logic,
   no domain screens, no API endpoints beyond one health route.
⛔ Every artifact in the Foundation Manifest is DECLARED BY CTO in
   architecture.md and VERIFIED BY SCRIPT. An undeclared artifact is
   unverifiable and therefore does not count as delivered.
```

**Skipping is a decision, not a default.** The only project types that may skip are
those with no shared surface to standardise — a single-file script or a one-endpoint
function. PM records the skip and its reason in `pm-tracker.md`; "the user is in a
hurry" is not a reason.

---

## Position in the flow

```
Sprint 0 planning (BA → checkpoints → CTO → HR → UX) 
        │
        ▼   validate-gate.sh 1        ← planning artifacts exist
  GATE 1 PASSED
        │
        ▼   ⭐ FOUNDATION BATCH  (sprint-0.md — the only code in Sprint 0)
        │
        ▼   validate-foundation.sh    ← the skeleton actually runs
  FOUNDATION GATE PASSED
        │
        ▼
  Sprint 1 — first feature sprint (4-Batch Flow)
```

The Foundation Gate sits **between** Gate 1 and Sprint 1 because its inputs are Gate 1's
outputs and its output is what every Sprint 1 agent reads.

---

## The four deliverables

Every foundation task produces one of these. What each contains is **derived from
`tech-stack.md` + `architecture.md`** — never from this file's examples.

| # | Deliverable | What "done" means |
|---|---|---|
| **F1 — Structure** | A running, empty app | Every directory in the CTO's File Blueprint exists; the app builds and starts; one health/home route renders; dependency + build tooling installed and committed |
| **F2 — Convention config** | Standards that a machine enforces | The linter/formatter/type-checker config for **each** layer present in the stack (frontend AND backend), merged from `templates/`, wired into the build, and **failing loudly on a deliberate violation** |
| **F3 — Base component layer** | The primitives features compose from | The design system's tokens compiled into the app's native token format and imported once; the primitive set below implemented against those tokens, with every interaction state |
| **F4 — CONVENTIONS.md** | The written rules, next to the code | One file at the app root: layer boundaries, naming, file/function limits, error handling, state/data-fetch pattern, commit/branch convention, and **where each is enforced** |

### F3 — the primitive set (floor, not ceiling)

A project's primitives are whatever its screens repeat. Derive the list by reading the
wireframes and counting: **any element that appears on 3+ screens is a primitive and MUST
exist before feature work**. The following almost always qualify and are the minimum unless
the wireframes genuinely contain none of them:

```
Button (variants + sizes)   Input / field + label + error   Select     Checkbox / Radio
Card / surface              Modal / sheet                   Toast      Badge / tag
Table or List row           Avatar                          Spinner / skeleton
Empty state                 Error state                     Page layout + navigation shell
```

**Each primitive MUST ship every state it can be in** — default · hover · focus-visible ·
active · disabled · loading · error — and MUST be built **only** from
`.project/design-system.md` tokens. A primitive with one state is why a UI looks dead:
features inherit its gaps everywhere it is used.

---

## Building `sprint-0.md`

```bash
bash .claude/automation/create-sprint.sh 0 "Foundation — structure, standards, base components"
```

Then `Read` → `Edit` (never `Write`). Task IDs follow the standard format; **`0.R` code
review is required, `0.S`/`0.Q` are not** — there is no user-facing behaviour to write BDD
scenarios against, and the Foundation Gate is the mechanical verification.

| ID | Task | Assignee | Depends on |
|----|------|----------|------------|
| `0.1` | F1 — scaffold structure per File Blueprint, app builds + starts | stack's lead specialist | — |
| `0.2` | F2 — convention config, every layer, wired to the build | same specialist as the layer it configures | 0.1 |
| `0.3` | F3 — token compilation + base component layer, all states | the stack's **UI** specialist | 0.1, design-system.md |
| `0.4` | F4 — CONVENTIONS.md | the specialist who authored 0.2 | 0.2 |
| `0.R` | Code Review — foundation | `google-code-reviewer` | 0.1–0.4 |

**Ordering is real, not decorative.** `0.1` MUST complete before `0.2`–`0.4` start — they
all write into the tree it creates, and running them in parallel with it is the
same-directory collision `pm.md` bans. `0.2`/`0.3`/`0.4` may then run in parallel **only if
their scopes do not overlap**; on a single-package repo they usually do, so serialise them.

**Multi-layer stacks split, they do not merge.** If the stack has a frontend and a backend,
`0.1`–`0.2` are **two tasks each**, one per layer, assigned to that layer's specialist —
never one agent doing both.

---

## Spawn prompt — required blocks

On top of the standard spawn template (`helpers/pm-spawn-examples.md`), every foundation
prompt MUST carry:

```
FOUNDATION TASK — you are building the SHELL, not a feature.

READ FIRST (all of them, before writing any file):
  · .project/documentation/tech-stack.md      ← the stack you are building for
  · .project/documentation/architecture.md    ← File Blueprint + Foundation Manifest
  · .project/design-system.md                 ← the token contract (UI tasks)
  · .claude/helpers/code-quality.md           ← the conventions you are encoding
  · .claude/helpers/ui-visual-standards.md    ← token pipeline + craft rubric (UI tasks)

SCOPE: app/  — create the structure; implement NO domain feature.

⛔ BANS
  · No business logic, no domain screens, no domain endpoints.
  · No hardcoded design value — every visual value comes from the token file.
  · No primitive with only a default state.
  · Do NOT invent structure the File Blueprint does not declare. If something is
    missing from it, STOP and ask the PM to have CTO update it. Never improvise
    a directory — an improvised structure is the drift this sprint exists to prevent.

DELIVERABLES (each must be listed in the Foundation Manifest by CTO)
  <the F-item's concrete paths, taken from architecture.md>

PROVE IT — paste the output of each into your Completion Report:
  <build command>        must exit 0
  <lint command>         must exit 0
  <type-check command>   must exit 0
  For F2 additionally: introduce ONE deliberate violation of a rule you configured,
  show the tool REPORTING it, then revert. A config that has never rejected
  anything has not been shown to be wired in.
```

That last instruction is the whole point of F2. Config files are the easiest thing in
software to install and never connect; "I added the config" and "the gate works" are
different claims, and only the second one is worth having.

---

## Foundation Gate

```bash
bash .claude/automation/validate-foundation.sh
```

Reads the **Foundation Manifest** from `.project/documentation/architecture.md` (authored by
CTO — see `core/cto.md`), then for each declared path checks it exists and is non-empty, and
runs each declared command requiring exit 0. Nothing about any stack is hardcoded in the
script: the project declares its own artifacts and its own verification commands.

| Result | PM action |
|--------|-----------|
| Exit 0 | Edit `pm-tracker.md` → Foundation Gate PASSED → proceed to Sprint 1 |
| Exit 1 | Re-spawn the owning agent with the script's output. **Do NOT start Sprint 1.** |
| Exit 2 | Manifest missing/empty → switch to CTO, author it, re-run |

Then: `bash .claude/automation/sync-pm-tracker.sh --event "Sprint 0 Foundation COMPLETE"`.

---

## What Sprint 1+ inherits (and must not redo)

State this explicitly in every later feature spawn prompt:

```
The foundation already exists. You MUST:
  · put files exactly where the File Blueprint says
  · COMPOSE the existing primitives in app/<primitives-dir> — read that
    directory BEFORE writing any UI
  · follow app/CONVENTIONS.md

If a primitive you need does not exist, that is a foundation change: build it in
the primitives directory with all its states, then compose it. Do NOT build a
one-off local variant — a local variant is invisible to every other agent working
in parallel, which is precisely how a UI becomes inconsistent.
```

---

## Anti-patterns

```
❌ Sprint 0 = planning only, features start in Sprint 1        → UI drift by construction
❌ "Scaffolding" folded into the first feature task            → nobody owns it, nobody verifies it
❌ Base components deferred until "we see what we need"        → they are needed on screen one
❌ Convention config installed but never run                   → a gate that has never rejected anything
❌ Foundation declared complete without validate-foundation.sh → an unverified claim
❌ Primitives built with hardcoded values "for now"            → the token contract dies at birth
❌ One agent doing FE + BE foundation together                 → two standards, half-owned

✅ DO gate Sprint 1 on the foundation actually running
✅ DO derive the primitive list by counting repeats in the wireframes
✅ DO make CTO declare the manifest so a script can check it
✅ DO prove each convention gate by watching it reject something
```
