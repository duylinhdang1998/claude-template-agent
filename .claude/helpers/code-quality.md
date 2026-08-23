# Code Quality Standards

**These rules apply to EVERY specialist, EVERY language, EVERY task.**

## Clean Code

| Principle | Rule |
|-----------|------|
| **Naming** | Variables, functions, classes MUST have clear, descriptive names. No `x`, `temp`, `data`, `handleClick2`. Name reveals intent. |
| **Functions** | Each function does ONE thing. Max 30 lines. If it needs a comment to explain what it does, rename it or split it. |
| **Files** | Each file has ONE clear responsibility. Max 300 lines. Split when it grows beyond. |
| **No magic** | No magic numbers, magic strings, hardcoded values. Use named constants. |

## DRY (Don't Repeat Yourself)

- If the same logic appears 3+ times → extract to a shared function/utility
- If the same UI pattern appears 3+ times → extract to a reusable component
- If the same config appears in multiple places → single source of truth
- **Exception**: Don't over-abstract for 2 occurrences — wait for the third

## SOLID (adapted for all languages)

| Principle | Practical Rule |
|-----------|---------------|
| **S** — Single Responsibility | One module = one reason to change |
| **O** — Open/Closed | Extend via composition/plugins, don't modify working code |
| **L** — Liskov Substitution | Subtypes must be drop-in replacements |
| **I** — Interface Segregation | Small, focused interfaces — no god objects |
| **D** — Dependency Inversion | Depend on abstractions, inject dependencies |

## Error Handling

- Never swallow errors silently (`catch {}` with no handling)
- Use typed/specific errors, not generic messages
- Validate at system boundaries (user input, API responses, env vars)
- Fail fast with clear error messages

## Code Smells to Avoid

```
❌ Functions with 5+ parameters → use options object / config
❌ Nested callbacks/promises 3+ deep → refactor to async/await or extract
❌ Boolean parameters → use named options or separate functions
❌ God files → any file over the 300-line limit above → split by responsibility.
   There is ONE threshold (300). Do not treat a second, looser number as the real one.
❌ Commented-out code → delete it, git has history
❌ console.log left in production code → use proper logger
❌ any type in TypeScript → use proper types
```

## When Fixing Bugs

- Fix the root cause, not the symptom
- Add a test that would have caught the bug
- Check for the same pattern elsewhere in the codebase

## Universal Code Conventions (EVERY language, EVERY specialist)

The Clean Code / DRY / SOLID / Code-Smell rules above are **conventions, and a convention
nobody lints is a convention that drifts.** They are encoded as lint rules in
`templates/shared/eslintrc.conventions.json`, which **every** TypeScript/JavaScript project
MUST merge — frontend and backend alike — before the area-specific file goes on top.

**Merge order (all three layers, in this order):**

```
templates/shared/eslintrc.conventions.json     ← ALWAYS (naming · imports · size · smells)
        ↓ then ONE of
templates/frontend/eslintrc.frontend.json      ← React/Next projects
templates/backend/eslintrc.backend.json        ← Node/TS service projects
```

| Convention (prose above) | Lint rule that enforces it |
|---|---|
| Naming reveals intent, no `x`/`temp`/`data` | `@typescript-eslint/naming-convention` |
| Functions do ONE thing, max 30 lines | `max-lines-per-function` |
| Files have ONE responsibility, max 300 lines | `max-lines` |
| No magic numbers / hardcoded values | `no-magic-numbers` (+ `enforceConst`) |
| Functions with 5+ parameters | `max-params: 4` |
| Nested callbacks/promises 3+ deep | `max-nested-callbacks: 3` · `max-depth: 4` · `complexity: 10` |
| `any` type in TypeScript | `@typescript-eslint/no-explicit-any: error` |
| `console.log` left in production code | `no-console` (allows `warn`/`error`) |
| Never swallow errors silently | `no-empty` with `allowEmptyCatch: false` (backend file) |

**One threshold, not two.** 300 lines/file and 30 lines/function are the same numbers here,
in the lint config, and in `google-code-reviewer` M1/M2. If you find a second, looser number
anywhere, it is a bug in the docs — fix it, do not follow it.

**Naming conventions** (the table in `core/cto.md` → File Blueprint) are now machine-checked
by `@typescript-eslint/naming-convention`. File *names* are not (no zero-dependency rule
exists) — `google-code-reviewer` §1 remains their only gate.

## Frontend Code Standards (React/Next.js + Tailwind)

**These four rules are MANDATORY for every frontend file. They are authored by
`meta-react-architect` and enforced by `google-code-reviewer`.**

### 🔒 Enforcement (three layers — NOT just prose)

1. **Automatic hook (hard gate)** — a `PostToolUse` hook
   (`hooks/enforce-code-standards.sh`) scans every `.ts`/`.tsx`/`.js`/`.jsx` file on write
   and **blocks** on two things: 2+ components in one `.tsx` file (Rule #1), and any file
   over the 300-line limit. File size uses a **no-new-violations** policy — a file that was
   already over the limit before the change is warned about while it is not growing, so
   legacy files stay editable and can be split incrementally; a new over-limit file, or an
   over-limit file that grew, is blocked. Tests, `.d.ts`, migrations, seeds and configs are
   exempt. It does NOT cover Rules #2/#3.
2. **ESLint build gate** — every React/Next project MUST merge
   `templates/shared/eslintrc.conventions.json` **then**
   `templates/frontend/eslintrc.frontend.json` into its own ESLint config, and
   **`npm run lint` MUST pass** before a frontend task is marked complete.
   The lint run is enforced by the `SubagentStop` hook (`post-task-validate.sh`), which
   blocks task completion on a lint failure — it is no longer the agent's word for it.
3. **Code review (all 4 rules + the numeric limits)** — `google-code-reviewer`
   runs a Measurement Pass (file length, function length, cross-file duplicate
   scan, drift diff) and grades from those numbers.

**Which layer actually covers what — do not overstate this table.**

| Standard | Hook | ESLint | Review |
|---|---|---|---|
| #1 one component per file | ✅ blocks | ✅ `react/no-multi-comp` | ✅ |
| #2 design tokens | — | — | ✅ (only layer) |
| #3 extract shared logic / no duplication | — | — | ✅ (only layer) |
| #4 no static inline style | — | ✅ `no-restricted-syntax` | ✅ |
| ≤ 300 lines per file | — | ✅ `max-lines` | ✅ M1 |
| ≤ 30 lines per function | — | ✅ `max-lines-per-function` | ✅ M2 |

**Where a standard's only layer is "Review", the review IS the gate** — it must be graded
mechanically (measure, then judge), never as an impression. A standard enforced by prose
alone gets re-argued as a trade-off at every review until it silently stops existing.

⚠️ **The lint layer is opt-in per project and therefore not guaranteed.** Nothing copies
`eslintrc.frontend.json` automatically — the frontend agent merges it during scaffolding and
MUST verify it landed (`grep` the config for the rule ids). The reviewer re-checks the same
thing (M5) and reports any missing rule id as a 🔴 finding in its own right. Assume a gate
exists only after you have grepped for it.

| # | Rule | Do | Don't |
|---|------|----|----|
| **1** | **One component per file** | Each file exports exactly ONE component. Sub-components, even small ones, get their own file. File name = component name (PascalCase). | ❌ Two+ `export function`/`export const` components in the same file. ❌ Defining helper components below the main one. |
| **2** | **Follow the project design system** | Use the project's design tokens, primitives, and patterns (colors, typography, spacing, radius, shadows). Read the design system reference (e.g. `clone-ui-design` skill / `references/DESIGN.md` / `design-system.md`) BEFORE writing UI. | ❌ Ad-hoc hex colors, arbitrary `px` spacing, one-off font sizes that bypass the system. |
| **3** | **Extract shared logic to its own file** | Shared functions → `lib/` or `utils/` (one concern per file). Shared stateful logic → `hooks/use-*.ts` (one hook per file). Shared UI → reusable component file. Clean separation, named for intent, reusable. | ❌ Copy-pasting the same helper into multiple components. ❌ Burying reusable logic inside a component. |
| **4** | **No inline styles unless value is dynamic** | Use existing Tailwind utility classes for all static styling. Inline `style={}` is allowed ONLY when the value is computed at runtime from a variable (e.g. `style={{ width: \`${percent}%\` }}`, `style={{ transform: \`translateX(${x}px)\` }}`). | ❌ `style={{ color: 'red', padding: '8px' }}` for static values. ❌ Arbitrary Tailwind values when a token class exists. |

### Quick reference — Rule 4 (inline style)

```tsx
// ❌ WRONG — static values as inline style
<div style={{ marginTop: '16px', backgroundColor: '#1e293b' }} />

// ✅ RIGHT — Tailwind utility classes for static styling
<div className="mt-4 bg-slate-800" />

// ✅ ALLOWED — value is dynamic (driven by a variable), Tailwind can't express it
<div className="h-2 rounded bg-blue-500" style={{ width: `${progress}%` }} />
```

---

## Backend Code Standards (Node / TypeScript services)

**These five rules are MANDATORY for every backend file. They are authored by
`netflix-backend-architect` and enforced by `google-code-reviewer` §1c.**
They are the backend counterpart of the four frontend rules above — same shape, same
severities, same "measure before you judge" discipline.

### 🔒 Enforcement — what actually gates what

| Standard | Hook | ESLint | Review |
|---|---|---|---|
| **B1** thin route/controller | — | ✅ `no-restricted-imports` (layer globs) | ✅ |
| **B2** one source per enum/constant | — | — | ✅ **(only layer — M3/M4)** |
| **B3** validation schema declared once | — | — | ✅ **(only layer)** |
| **B4** typed errors, no floating promises | — | ✅ `no-floating-promises`, `only-throw-error`, `no-empty` | ✅ |
| **B5** no `any` at the boundary | — | ✅ `@typescript-eslint/no-explicit-any` | ✅ |
| ≤ 300 lines/file · ≤ 30 lines/function | ✅ blocks | ✅ `max-lines`, `max-lines-per-function` | ✅ M1/M2 |

Where the only layer is **Review**, the review IS the gate — grade it from the Measurement
Pass numbers, never from impression.

| # | Rule | Do | Don't |
|---|------|----|----|
| **B1** | **Route/controller stays thin** | The route layer parses input, calls ONE service, shapes the response. Business logic lives in a service; data access lives in a repository. Dependencies point inward: route → service → repository. | ❌ Query the ORM/DB client directly from a route handler. ❌ Branching business rules inside the handler. ❌ A service importing a controller. |
| **B2** | **One source per enum, constant and label map** | Every status/role/priority set, and every map from a code to a human string, is declared **once** in a shared module and imported. Server and client consume the SAME definition — export it from one place rather than re-typing it on each side. | ❌ The same options array or label map re-declared in a second file. ❌ Two copies that have drifted apart — that is a behaviour defect, not a style nit (see M4). |
| **B3** | **Validation schema declared once, reused** | Define the request schema once (Zod/Valibot/etc.), infer the TypeScript type from it (`z.infer`), and reuse both at the boundary and in the service signature. One schema = one truth for shape, parsing and types. | ❌ An inline schema re-written per handler. ❌ A hand-written `interface` that duplicates a schema already defined — they drift the moment either changes. |
| **B4** | **Errors typed, never swallowed** | Throw typed error classes carrying a stable code; translate to HTTP status at ONE boundary (error middleware). `await` or explicitly handle every promise. Validate env vars once in a config module and import the typed config. | ❌ `catch {}` with no handling. ❌ `throw new Error('failed')` as the only signal. ❌ A floating promise. ❌ `process.env.X` scattered through the codebase. |
| **B5** | **No `any` at the boundary** | Parse untrusted input (request body, query, third-party response) into a typed shape at the edge and pass the typed value inward. | ❌ `any`/`as any` to silence the compiler. ❌ Trusting an external response's shape without parsing it. |

### Quick reference — B1 (thin route)

```ts
// ❌ WRONG — business logic + DB access inside the route handler
export async function POST(req: Request) {
  const body = await req.json();
  if (body.total > 1000 && body.tier === 'basic') body.total *= 0.9;   // business rule
  const order = await prisma.order.create({ data: body });             // direct DB access
  return Response.json(order);
}

// ✅ RIGHT — parse, delegate, respond
export async function POST(req: Request) {
  const input = createOrderSchema.parse(await req.json()); // B3: the one schema
  const order = await orderService.create(input);          // B1: logic lives here
  return Response.json(order);
}
```
