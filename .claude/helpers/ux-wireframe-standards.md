---
name: ux-wireframe-standards
type: helper
description: |
  The house standards apple-ux-wireframer must follow when drawing wireframes:
  canonical screen frames + widths, annotation/interaction indicators, flow-arrow
  vocabulary, localization-safe character rules, and the file + presentation
  templates for the Sprint 0 approval gate.
  Complements the `ux-wireframing` skill — that skill owns the ELEMENT LIBRARY
  (buttons, inputs, cards, tables) and famous-app examples; this file owns the
  CONVENTIONS and TEMPLATES that make every project's wireframes look the same.
---

# UX Wireframe Standards

> Read this before drawing the first screen. Load the `ux-wireframing` skill for
> the element library; come back here for widths, annotations, and file format.

---

## 0. ⛔ What a wireframe CAN and CANNOT specify (read before drawing)

**ASCII is a monospace grid. It is dimensionally false and you must not pretend
otherwise.** Every cell is the same size, every region is drawn with a border because a
border is the only way to show a boundary, every string of text is the same weight because
there is only one weight. A developer who transcribes that literally builds boxes inside
boxes with uniform padding and flat typography — an interface that looks like a terminal
rendered in HTML. **That is not a developer failing to follow the wireframe. That is the
developer following it exactly.**

So the wireframe's authority is scoped, and the scope is stated on every screen file:

| The wireframe is **BINDING** on | The wireframe is **NOTATION ONLY** on |
|---|---|
| which elements exist, and which do not | box borders — a `│` is a boundary, **not** `border: 1px solid` |
| their order and reading sequence | proportions — a 29-char row is not "full width" |
| which elements group together | spacing sizes — line counts are not the spacing scale |
| every state drawn (empty · loading · error) | type sizes — monospace flattens the whole type scale |
| behaviour and interaction per callout | alignment padding — column padding is a drawing artifact |
| responsive behaviour between breakpoints | colour and contrast — those live in the design system |

**Everything in the right-hand column is decided by the design system + the Layout Intent
block (§2.5), never by counting characters.** If a screen's appearance depends on something
only the right column can express, it MUST be written into Layout Intent — because that is
the half a developer cannot recover from the drawing.

---

## 1. Canonical frames & widths

Pick ONE width per viewport and hold it for the whole project — mixed widths are
the #1 reason a wireframe set looks sloppy.

| Viewport | Inner width | Frame style | Use for |
|---|---|---|---|
| Mobile   | **29 chars** | `╭─╮ … ╰─╯` (rounded) | iOS/Android screens, mobile-first default |
| Tablet   | **45 chars** | `╭─╮ … ╰─╯` | only when the SRS calls out tablet |
| Desktop  | **69 chars** | `┌─┐ … └─┘` (square) | web app, dashboard, marketing page |
| Component| free         | `┌─┐` or `╭─╮` to match its host | `components.md` only |

**Mobile frame** — status bar + content + tab bar:

```
╭─────────────────────────────╮
│ ●●●●●        9:41     ⌁ ▮   │   ← status bar (fixed, never annotate)
├─────────────────────────────┤
│ ◂  Screen Title         ⋯   │   ← nav bar
├─────────────────────────────┤
│                             │
│         content             │
│                             │
├─────────────────────────────┤
│   Home    Search   Profile  │   ← tab bar
╰─────────────────────────────╯
```

**Desktop frame** — browser chrome + app shell:

```
┌─────────────────────────────────────────────────────────────────────┐
│ ● ● ●  │  ◀ ▶ ↻  │  https://app.example.com                     │ ≡ │
├─────────────────────────────────────────────────────────────────────┤
│ Logo        Nav  Nav  Nav                          Search   Avatar  │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│                          page content                               │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

Rules:
- The **frame is chrome, not design** — never put product decisions in it.
- Nest at most **2 levels** of boxes inside the frame. Deeper than that, split
  the region into its own component wireframe in `components.md`.
- One screen per file. A modal over a screen stays in that screen's file, under
  its own `### Modal:` heading.

---

## 2. Annotation & interaction indicators

Wireframes are read by developers, not admired. Every non-obvious element gets a
numbered callout `①②③…` placed **inside** the frame, explained in a table
**below** it.

```
╭─────────────────────────────╮
│ ◂  Checkout              ①  │
├─────────────────────────────┤
│  Email                      │
│  ┌───────────────────────┐  │
│  │ you@example.com       │② │
│  └───────────────────────┘  │
│                             │
│  ☑ Save this card        ③  │
│                             │
│  [       Pay $49.00      ]④ │
╰─────────────────────────────╯
```

| # | Element | Behaviour | Token / state |
|---|---|---|---|
| ① | Help icon | tap → opens support sheet | `icon.muted`, 44×44 target |
| ② | Email input | validates on blur; inline error below | `input.default` → `input.error` |
| ③ | Checkbox | default OFF; persists to profile | `checkbox.md` |
| ④ | Pay CTA | disabled until form valid; spinner while posting | `button.primary` |

**Indicator legend** — use these exact glyphs, nothing else:

| Glyph | Means | Glyph | Means |
|---|---|---|---|
| `[ Label ]` | button | `[_______]` | text input |
| `[ Label ]` + `════` under | primary / active | `[••••••]` | password input |
| `( Label )` | disabled control | `☐ / ☑` | checkbox off / on |
| `‹ Label ›` | link | `◯ / ◉` | radio off / on |
| `▾` | dropdown | `⟳` | loading / async |
| `░░░` | dimmed backdrop (modal) | `▒▒▒` | skeleton placeholder |
| `⌁` | focus ring / keyboard focus | `⚠` | error state marker |

**Gestures** (mobile only) — annotate on the element, not in prose:
`tap` · `long-press` · `swipe ◀▶` · `pull ↓ to refresh` · `drag ⇅ to reorder`.

**Touch targets**: anything tappable is **≥ 44×44pt**. If the drawing cannot show
it, say so in the callout table. `google-code-reviewer` checks this against the
implementation.

---

## 2.5 ⭐ Layout Intent — the half ASCII cannot draw (MANDATORY per screen)

`ui-visual-standards.md` §4 grades the built interface on hierarchy, spacing rhythm,
alignment, density, colour intent and typography. **None of those six survive a monospace
drawing.** A wireframe that omits them specifies everything except what the result is judged
on, and the developer is left to guess — which is why the same wireframe can be followed
faithfully and still produce an ugly screen.

Every `screens/NN-*.md` file carries this block, written in design-system terms. It is short
on purpose: six decisions, not an essay.

```markdown
## Layout Intent

**Focal point**   : <the ONE element the eye must land on first> — `<type token>`, `<emphasis>`
**Secondary**     : <what is read next> — `<type token>`
**Everything else**: `<type token>` / `text.muted` — must NOT compete

**Groups** (proximity encodes relationship — related tight, unrelated loose):
  · [<elements>] = one group, inner gap `space.<n>`
  · [<elements>] = one group, inner gap `space.<n>`
  · between groups: `space.<n>`

**Density**   : <comfortable | compact | spacious> — <why: scanning data vs reading>
**Emphasis**  : accent `<token>` used ONCE, on <element>. Everything else neutral.
**Container** : max content width `<token/value>`; body measure ≤ 75ch
**Columns**   : mobile <n> · tablet <n> · desktop <n>; <what reflows, what stays>
```

**Rules that make this real, not decorative:**

- **Exactly ONE focal point per screen.** Two focal points is zero focal points. If the
  screen genuinely has two equal jobs, it is two screens or a tabbed view — say which.
- **Every text element in the frame maps to a type-scale token.** A text element with no
  token gets built at the default size, and default-everything is the flat-hierarchy look.
- **Group gaps must differ from between-group gaps.** If every gap is the same value, the
  layout communicates nothing about what belongs together — the most common reason a screen
  reads as "a list of stuff" rather than a designed page.
- **The accent is used once.** A second accent demotes the first; three accents is
  decoration, and decoration is what "generic AI UI" is made of.
- **Never write raw values here** — `space.4`, `text-h2`, `radius.md`, not `16px`. Same rule
  as §5; a Layout Intent full of pixels bypasses the design system just as a frame would.

---

## 3. Flow arrows

One vocabulary for every flow diagram — the arrow carries the trigger, the label
under it carries the condition.

```
┌─────────┐  tap Login   ┌─────────┐  200 OK    ┌─────────┐
│ Login   │ ───────────▶ │ Verify  │ ─────────▶ │  Home   │
└─────────┘              └─────────┘            └─────────┘
     ▲                        │
     │  401 / retry           │ timeout 30s
     └────────────────────────┘
```

| Arrow | Meaning |
|---|---|
| `──▶` | forward navigation (push) |
| `◀──` | back / pop |
| `⇢`   | conditional branch (label the condition) |
| `⤴`   | modal / sheet presented over current screen |
| `⟲`   | stays on screen, state change only |
| `⇥`   | hand-off to an external app or system (OAuth, payment, deep link) |

Every flow MUST show its **failure edge**. A flow with only the happy path is
rejected at the approval gate.

---

## 4. Localization & character safety

ASCII frames break the moment a glyph is not one column wide.

- **Never put emoji inside a bordered column whose alignment matters.** Emoji and
  CJK render **double-width** in most terminals and shift every `│` after them.
  Use word labels (`Home`, `Search`) inside frames; keep emoji for flow diagrams
  and headings where nothing needs to line up.
- **Vietnamese diacritics are safe** (single width) — write real VN copy in the
  wireframe when the product ships VN.
- **Size for the longest locale.** German and Vietnamese run ~30% longer than
  English. Draw the label at its longest, then note truncation:
  `Xác nhận đơn hàng…` with a callout `truncates at 1 line, tooltip on hover`.
- **RTL**: if the SRS lists Arabic/Hebrew, add one mirrored copy of the primary
  screen and note `layout mirrors; icons flip except media controls`.
- **Numbers, dates, currency**: annotate the format, never hardcode one locale's
  shape into the design (`₫1.234.567` vs `$1,234.56`).

---

## 5. Binding to the design system

A wireframe that names raw values is a bug. Every visual decision references
`.project/design-system.md`:

- ✅ `button.primary`, `text.muted`, `space.4`, `radius.md`, `motion.fast`
- ❌ `#3B82F6`, `16px`, `border-radius: 8px`

That file is auto-injected into every UI specialist at spawn
(`.claude/hooks/subagent-inject-wireframe.sh`), and `google-code-reviewer`
rejects UI values that bypass it — so a wireframe token that does not exist in
`design-system.md` will strand the frontend agent. **Create the design system
first (Phase 0), draw second.**

---

## 5.5 ⭐ Render it before you present it

**A design specified only in monospace has never been seen.** The implementation side of
this pipeline is required to render and measure its work (`ui-visual-standards.md` §3); the
design side shipping only ASCII means the first time anyone sees the actual product is after
it is built — and by then the wireframes, the tokens and the code all encode the same
unexamined guess. The approval gate must show pixels, not characters.

**Before the approval gate, build a static preview from the REAL tokens:**

```bash
# 1) the tokens must be compiled first — the preview imports them, it does not restate them
node .claude/scripts/build-styles-json.js --check --emit-css

# 2) write .project/wireframes/preview/NN-<screen>.html for the KEY screens:
#    the ones that establish the layout patterns every other screen reuses
#    (typically 3-5 — plus one page showing every base primitive in all its states).
#    Each file: <link> the generated design-system.tokens.css, then real markup.
#    Use ONLY token values. This is a visual proof, not a codebase — no framework,
#    no build step, no logic.

# 3) render and MEASURE it with the same pipeline the implementation is judged by
node .claude/scripts/ui-capture.js \
     --url "file://$(pwd)/.project/wireframes/preview" \
     --routes /01-<screen>.html /02-<screen>.html /primitives.html \
     --label design-preview
node .claude/scripts/check-visual-report.js --latest
```

**Then `Read` the screenshots and grade your own design against the §4 craft rubric in
`helpers/ui-visual-standards.md`** — hierarchy, spacing rhythm, alignment, density, colour
intent, typography, state coverage, motion, point of view. **Anything scoring ≤2 gets fixed
in the tokens and the Layout Intent before the user ever sees it**, because every one of
those failures is about to be copied into every screen the frontend agent builds.

Blocking violations (contrast · overflow · touch target) found here are **design defects, not
implementation defects** — fix the token set, not the markup. A contrast failure in the
preview means the palette itself is broken, and shipping it hands every UI specialist a
palette that cannot pass its own gate.

**Present the screenshots at the approval gate** (§7), with the ASCII frames as the
structural companion. The user approves a picture of the product; the frontend agent gets a
visual reference instead of a character grid.

> **If the preview genuinely cannot be rendered** (no Playwright, no Node), say so
> explicitly — `visual proof: SKIPPED (<reason>)` in the presentation — and raise the
> concreteness of Layout Intent to compensate. Silence is not a skip.

---

## 6. File templates

### `screens/NN-<name>.md`

```markdown
# NN — <Screen Name>

**Purpose**: <one line — the job this screen does>
**User stories**: US-03, US-07
**Entry points**: <from where> · **Exits**: <to where>

## Layout Intent
<the §2.5 block — MANDATORY. This is the binding half; the frame below is notation.>

## Default state
<frame — structural only: presence, order, grouping, states. NOT proportions/borders/sizes.>

## Callouts
| # | Element | Behaviour | Token / state |

## Empty state
<frame or "N/A — screen always has content, see US-03">

## Loading state
<frame using ▒▒▒ skeletons>

## Error state
<frame using ⚠ + the recovery action>

## Responsive
<desktop frame, or "mobile-only">

## Accessibility
- Focus order: <…>
- Screen reader: <labels for icon-only controls>
- Contrast: <token pairs used, all ≥ 4.5:1>
```

### `wireframes/README.md` (screen index — the PM reads this)

```markdown
# Wireframes — <Project>

**Design direction**: <chosen style>  ·  **Design system**: `.project/design-system.md`
**Status**: DRAFT | IN REVIEW | ✅ APPROVED (<date>)

| # | Screen | File | States done | Stories | Status |
|---|---|---|---|---|---|
| 01 | Login | `screens/01-login.md` | default·loading·error | US-01 | ✅ |
| 02 | Feed  | `screens/02-feed.md`  | default·empty·loading | US-03,US-04 | 🚧 |

## Flows
| Flow | File |
|---|---|
| Auth | `flows/auth-flow.md` |

## Open questions
- [ ] <anything the user still has to decide>
```

### `flows/<name>-flow.md`

```markdown
# <Name> Flow
**Trigger**: <what starts it>  ·  **Success**: <end state>  ·  **Stories**: US-…

<arrow diagram>

## Edges
| From → To | Trigger | Condition |
## Failure paths
| Failure | Where it surfaces | Recovery |
```

### `components.md`
One `##` per reusable pattern: frame, the states it supports, the tokens it
consumes, and which screens use it. If a pattern appears on **3+ screens**, it
belongs here and the screens reference it instead of redrawing it.

---

## 7. Presentation template (the approval gate)

Do not dump every file into chat. Present in this shape, then ask:

```
🎨 [UX] Design ready for review — <Project>

Direction : <style> (your pick from Sprint 0)
System    : .project/design-system.md — <N> tokens, <font pair>, <radius/motion>
Screens   : <N> screens, <N> flows, <N> shared components

📸 Rendered preview (look at these — the ASCII is only the structure):
  .project/screenshots/design-preview/<file>.png   ← per key screen
  Measured: contrast <n> · overflow <n> · touch-target <n>   (0/0/0 required)
  Craft self-score (§4 rubric): <9 dimensions, lowest named>

Key screens:
  01 Login   — <one line>
  02 Feed    — <one line>
  03 Detail  — <one line>

Open questions:
  1. <question that actually changes the design>
```

Then `AskUserQuestion` (header `Wireframes`) with options along the lines of:
**Approve** · **Approve with changes** (capture them) · **Rework <screen>** ·
**Change direction** (goes back to Phase 0.1).

On approval: set `Status: ✅ APPROVED (<date>)` in `wireframes/README.md` and
report to the PM. **Frontend tasks must not be assigned before that line reads
APPROVED.**

---

## 8. Pre-submit checklist

- [ ] **Layout Intent block on EVERY screen** — one focal point, groups with differing
      gaps, density, single accent, container/measure, columns per breakpoint
- [ ] **Every text element in every frame maps to a type-scale token** (none left default)
- [ ] **Rendered preview built from the real tokens and CAPTURED**; contrast · overflow ·
      touch-target all 0; craft rubric self-scored from the screenshots, nothing ≤2
- [ ] One width per viewport, held across every file
- [ ] Every screen in the SRS has a file; every file maps to ≥1 user story
- [ ] Default · empty · loading · error drawn for every screen that can have them
- [ ] Callout table under every frame with a non-obvious element
- [ ] Every flow shows at least one failure edge
- [ ] Tokens referenced by name — zero raw hex/px anywhere
- [ ] No emoji inside alignment-critical columns; longest-locale copy used
- [ ] Touch targets ≥ 44×44pt noted; focus order and SR labels present
- [ ] `README.md` index complete with status
