# Design System — <PROJECT NAME>

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

## Tailwind / framework mapping (if applicable)

- How the tokens above map to Tailwind theme keys / CSS variables / component libs.
- Which arbitrary-value patterns are banned (e.g. `text-[13px]`, `bg-[#123456]`).

## Component patterns (optional)

- Button variants, input states, card anatomy, etc. — reference the tokens above.
