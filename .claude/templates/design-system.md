# Design System — <PROJECT NAME>

> **Platform:** <UI platform from tech-stack.md>  ·  **Styling:** <styling system>  ·  **Component library:** <kit or "none">
> **Source:** `.project/documentation/tech-stack.md` (read <date>)
> **Enforcement on this platform:** <which gates apply here; which do not, and why>

> Copy this to **`.project/design-system.md`** and fill in your tokens.
> The UI agents (meta-react-architect / apple-ios-lead / google-android-lead)
> get this file **auto-injected into their context at spawn** — they must use
> ONLY these tokens. `google-code-reviewer` rejects any value that bypasses it.
>
> Keep it under ~500 lines (only the first 500 are injected). Tokens > prose.

## Colors (tokens)

| Token | Value | Usage |
|-------|-------|-------|
| `--color-primary` | `#______` | primary actions, links |
| `--color-primary-hover` | `#______` | hover state |
| `--color-bg` | `#______` | page background |
| `--color-surface` | `#______` | cards, panels |
| `--color-border` | `#______` | dividers, input borders |
| `--color-text` | `#______` | body text |
| `--color-text-muted` | `#______` | secondary text |
| `--color-success` / `--color-warning` / `--color-danger` | `#___` | status |

## Typography

| Token | Size / Line-height | Weight | Usage |
|-------|-------------------|--------|-------|
| `text-display` | 40/48 | 700 | hero |
| `text-h1` | 32/40 | 700 | page title |
| `text-h2` | 24/32 | 600 | section |
| `text-body` | 16/24 | 400 | default |
| `text-sm` | 14/20 | 400 | captions |
| Font family | `______` | | base / mono |

## Spacing scale

`4 · 8 · 12 · 16 · 24 · 32 · 48 · 64` (px). Use scale steps only — no arbitrary values.

## Radius & Shadows

| Token | Value |
|-------|-------|
| `radius-sm` / `radius-md` / `radius-lg` | `___ / ___ / ___` |
| `shadow-sm` / `shadow-md` | `___ / ___` |

## Motion & Animation (tokens)

Motion personality: `____` (M-A Functional / M-B Premium / M-C Playful / M-D Cinematic — see design-trends).

| Token | Value | Usage |
|-------|-------|-------|
| `--duration-fast` | `___ms` | hover, press, micro-feedback |
| `--duration-base` | `___ms` | enter/exit, state changes |
| `--duration-slow` | `___ms` | large/cinematic transitions |
| `--ease-standard` | `cubic-bezier(___)` | default enter easing |
| `--ease-exit` | `cubic-bezier(___)` | exit easing (usually quicker) |
| `--ease-emphasized` | `spring(___) / cubic-bezier(___)` | delight moments, key CTAs |
| `--motion-distance` | `___px` | enter offset (fade+slide) |
| `--stagger-step` | `___ms` | delay between staggered list items |

**Rules (binding):** every animation MUST honor `prefers-reduced-motion` (static fallback);
animate **only `transform` + `opacity`** (never `width/height/top/left/margin`); one focal
motion per view. `google-code-reviewer` rejects motion that violates these.

## Platform token mapping (MANDATORY — not "if applicable")

Express the tokens above in the **target platform's own dialect**, and in that one only.
The same token names and values, written the way this stack consumes them:

- **How each token is referenced in product code** — theme key, custom property, native
  token namespace, or theme object, per the platform.
- **Where the tokens are DEFINED** — the single file that holds the raw values. It is the
  one place a literal is allowed to appear; everything else references it.
- **Which literal patterns are banned** on this platform (the shapes a bypass takes here).

> A token set written in a dialect the stack cannot consume is still auto-injected into
> every UI specialist as a binding contract. Getting this section wrong does not produce a
> rough draft — it produces a contract nobody can follow.

## Base primitives (Sprint 0 F3) — MANDATORY

The components the Foundation Batch builds **before any feature sprint**, so that parallel
UI agents compose one button instead of writing five. Derive by counting: **any element on
3+ screens is a primitive.** Every entry lists its variants and **every state** —
default · hover · focus · active · disabled · loading · error.

| Primitive | Variants | States | Notes |
|---|---|---|---|
| <name> | <variants> | <all states it can be in> | <anatomy / token usage> |

## Component patterns (optional)

- Composition rules beyond the primitives — reference the tokens above.
