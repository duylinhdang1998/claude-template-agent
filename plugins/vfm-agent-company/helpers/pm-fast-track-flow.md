---
name: pm-fast-track-flow
type: helper
description: |
  Fast-Track execution order — spawn the dev agent before PM finishes its own docs,
  instead of finishing docs before spawning. Referenced from pm.md, pm-bug-fix-flow.md,
  and the Feature Change Sprint Flow section.
---

# PM Fast-Track Flow

**Why this exists**: the docs-first gates (BA interview, BDD approval-wait, full sprint file
before spawn) exist to catch misunderstandings BEFORE code is written. That protection has a
cost — the dev agent sits idle while PM writes. When the task is already unambiguous, the
protection buys nothing and the wait is pure overhead, especially on small tasks. Fast-Track
does not remove any quality gate — it only reorders PM's own paperwork to happen **after**
dispatch instead of before, so the dev agent starts immediately.

## Eligibility (ALL must hold)

| Check | Requirement |
|---|---|
| Foundation | `validate-foundation.sh` already PASSED for this project. Never applies to Sprint 0 / the Foundation Batch — parallel feature agents need the shared skeleton on disk first; that gate is about environment readiness, not requirement clarity, and Fast-Track doesn't touch it. |
| Requirements | The user's request already states what "done" looks like — expected behavior, repro steps, or explicit acceptance criteria — with no open question PM would otherwise ask in a BA/triage interview. |
| Scope | Bounded to an identifiable set of files/directories. Same "no shared file, no directory overlap" test as the Parallelization Rules in `core/pm.md`. |
| Change shape | No new data model, no new cross-cutting concern (auth, schema, shared utility), no scope that spans multiple unrelated modules. |

**If any check fails, or PM is unsure → do NOT fast-track.** Same principle as the Bug Fix
Classification Guard: defaulting to the full flow costs time; fast-tracking an ambiguous task
costs a wrong implementation and a redo, which costs more than the time saved.

## Execution Order

```
1. PM states the classification decision in ONE line — no checklist, no interview:

   📋 [PM] Fast-Track: {task summary} → scope app/{dir}/, spawning {specialist} now.

2. Spawn the dev specialist(s) IMMEDIATELY — the very next tool call, before any
   Write/Edit under .project/. The spawn prompt still carries the full task, scope, and
   acceptance criteria (all the normal spawn requirements from core/pm.md Execution Flow
   apply unchanged) — "fast" means skipping the PM-side ceremony that produces those same
   facts more slowly, never skipping them in the prompt itself.

   Minimum Parallel Agents Rule still applies: 2+ tasks → 2+ agents.

3. While the dev agent(s) run, PM does its own paperwork — nothing else blocks PM once the
   agent is dispatched:
   a. bash .claude/automation/create-sprint.sh {N} "{name}" → Read → Edit with the task(s),
      Status [IN PROGRESS]
   b. Scenario notes: acceptance criteria written as Given/When/Then, inline in the sprint
      file's task Notes (or a .feature file if the project's scenarios/ convention already
      exists and QA will run against it in Batch 3)
   c. bash .claude/automation/sync-pm-tracker.sh --event "Fast-Track {task}: dev dispatched"

4. When dev completes → Batch 2 (Code Review) → Batch 3 (QA) — UNCHANGED, still mandatory.
   Fast-Track never skips Code Review or QA. It only removes the pre-code documentation
   ceremony, not the post-code verification ceremony.
```

## What Fast-Track does NOT skip

- Code Review (Batch 2) / `{N}.R`
- QA Verification (Batch 3) / `{N}.Q`
- `sync-pm-tracker.sh` after each batch
- Git checkpoint, sprint closure checklist
- The spawn prompt's required fields (SCOPE, DELIVERABLES, BDD test-until-GREEN rule, etc.)

## What it skips or reorders

| Normal flow | Fast-Track |
|---|---|
| BA triage interview / bug triage interview before spawn | Skipped — the user's request already has the answers |
| Sprint file written and Edit'd before spawn | Written **after** dispatch, while dev runs |
| BDD scenarios generated + user approval wait before dev starts | Acceptance criteria captured inline by PM while dev runs; no approval wait |
| PM presents a plan and waits for user confirmation before spawning | Skipped — PM's one-line classification output IS the notice; user can interrupt if they disagree |

## Failure mode to avoid

If dev comes back with questions, or the diff doesn't match what PM assumed when it wrote the
docs in step 3 — that is the signal the task wasn't actually eligible. Don't force it: switch
that task back to the full flow (BA interview or BDD scenarios) for the correction, and treat
the mis-classification as a data point for judging the next task, not as a reason to retry
Fast-Track on the same task.
