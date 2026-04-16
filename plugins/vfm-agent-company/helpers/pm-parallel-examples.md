# PM Parallelization Analysis Example

> Reference for how PM should analyze task parallelization before spawning. See `core/pm.md` for the parallelization rules.

## Full Analysis Example

```
📋 [PM] Parallelization Analysis

Sprint 1 Tasks:
┌─────┬──────────────────────────┬────────────────────────┬─────────────┐
│ ID  │ Task                     │ Directory Scope        │ Shared Files│
├─────┼──────────────────────────┼────────────────────────┼─────────────┤
│ 1.1 │ User API                 │ app/api/users/     │ schema.prisma│
│ 1.2 │ Product API              │ app/api/products/  │ schema.prisma│
│ 1.3 │ Order API                │ app/api/orders/    │ schema.prisma│
│ 1.4 │ Dashboard Page           │ app/dashboard/     │ -           │
│ 1.5 │ Settings Page            │ app/settings/      │ -           │
│ 1.6 │ Profile Page             │ app/profile/       │ -           │
└─────┴──────────────────────────┴────────────────────────┴─────────────┘

Parallelization Decision:
├── Backend (1.1, 1.2, 1.3): ❌ Share schema.prisma → RUN SEQUENTIALLY
├── Frontend (1.4, 1.5, 1.6): ✅ No overlap → SPAWN 3 AGENTS IN PARALLEL
└── Backend + Frontend: ✅ Different layers → PARALLEL OK
```

## Pre-Spawn Checklist Example

```
📋 [PM] Pre-Spawn Checklist

Tasks to spawn: 2.1, 2.2, 2.3

□ Step 1: List deliverables for each task
  - 2.1: app/dashboard/*
  - 2.2: app/settings/*
  - 2.3: app/profile/*

□ Step 2: Check directory overlap
  - 2.1 vs 2.2: No overlap ✅
  - 2.1 vs 2.3: No overlap ✅
  - 2.2 vs 2.3: No overlap ✅

□ Step 3: Check shared files (schema, utils, types)
  - schema.prisma: None modify ✅
  - app/lib/utils.ts: None modify ✅

□ Step 4: Check dependencies
  - 2.1 depends on: None ✅
  - 2.2 depends on: None ✅
  - 2.3 depends on: None ✅

DECISION: ✅ Safe to spawn 3 agents in parallel!
```
