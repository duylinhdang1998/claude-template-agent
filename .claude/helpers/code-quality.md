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
❌ God files (500+ lines) → split by responsibility
❌ Commented-out code → delete it, git has history
❌ console.log left in production code → use proper logger
❌ any type in TypeScript → use proper types
```

## When Fixing Bugs

- Fix the root cause, not the symptom
- Add a test that would have caught the bug
- Check for the same pattern elsewhere in the codebase

## Frontend Code Standards (React/Next.js + Tailwind)

**These four rules are MANDATORY for every frontend file. They are authored by
`meta-react-architect` and enforced by `google-code-reviewer`.**

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
