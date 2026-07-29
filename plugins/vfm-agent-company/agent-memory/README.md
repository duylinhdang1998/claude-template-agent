# Agent Memory — persistent per-agent learning

This is the "upgrade the sub-agents" architecture. Each specialist accumulates
**lessons** across tasks so it stops repeating the same mistakes.

## How it works (wired via hooks — no manual step)

- **On spawn** (`SubagentStart`): `hooks/subagent-inject-task-rules.sh` reads
  `agent-memory/<agent-type>/lessons.md` and injects it into the agent's context.
- **On correction**: when code review / QA / the user rejects the agent's work,
  the agent appends a one-line lesson to its own `lessons.md` before re-submitting.
- Next time that agent spawns, the lesson is already in context → it self-corrects.

## Format (`<agent-type>/lessons.md`)

```
- [2026-07-29] Used raw hex #3B82F6 instead of token → always use design-system tokens; never hard-code colors.
- [2026-07-29] Put 2 components in one file → one component per file, filename = component name.
```

Keep each line a **reusable rule**, not a story. Terse > verbose (only the first
~200 lines are injected, to stay lean).

## Which agents have memory

Every agent with `memory: project` in its frontmatter (all specialists). A folder
is created lazily on first spawn. It's safe to hand-edit these files to teach an
agent a project-specific rule up front.
