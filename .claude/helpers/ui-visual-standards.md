---
name: ui-visual-standards
type: helper
description: |
  The visual layer of the code standards: the artifact pipeline (design-system.md →
  design-system.json), the four token checks that block on write, the render-and-measure
  loop every UI task must close, and the craft rubric for the part no script can measure.
  Read by meta-react-architect, apple-ux-wireframer, apple-ios-lead, google-android-lead
  and google-code-reviewer. Companion to `code-quality.md` (which owns code structure).
---

# UI Visual Standards

> **The premise.** Lint proves code is well-formed. Token checks prove a UI is
> consistent. Neither has ever looked at the result. A skill that says "make it
> beautiful" changes nothing, because nothing measures whether it happened. This
> file defines what IS measured, what is merely looked at, and who does which.

---

## 1. The pipeline (three artifacts, in order)

```
 design-system.md          human writes it — prose, tables, the chosen direction
        │
        │  node .claude/scripts/build-styles-json.js --check --emit-css
        ▼
 design-system.json        machines read it — the exact token set
 design-system.tokens.css  the app imports it — one place a raw value may appear
        │
        │  ⭐ the DESIGN is rendered and measured too, before anyone builds it
        ▼
 wireframes/preview/*.html static proof from the real tokens → ui-capture
 screenshots/design-preview  the user approves PIXELS, not a character grid;
                             a contrast failure here is a broken PALETTE, and
                             the fix is the token set, not any screen's markup
        │
        │  every Write/Edit of a UI file
        ▼
 enforce-design-tokens.sh  blocks C1–C4 below
        │
        │  after the feature runs
        ▼
 visual-report.json        + screenshots — the rendered truth
 + ui-capture.js              graded by check-visual-report.js, injected into the reviewer
```

**A design system that only exists as markdown is not enforceable.** Regenerate the
JSON whenever the markdown changes — the hook does it automatically, but run
`--check` yourself before handing the system to anyone: it fails on unfilled
placeholders, which is the difference between a contract and a template.

---

## 1.5 Platform coverage — what runs where (do not assume the rest)

**The design system is written in ONE platform dialect, chosen from `tech-stack.md`.**
`apple-ux-wireframer` resolves the platform in its Phase 0.0 gate before writing a single
token; a token file in a dialect the stack cannot consume is a defect, not a draft, because
it is auto-injected into every UI specialist as a binding contract regardless.

The enforcement layers are **not equally available on every platform** — say so explicitly
in `design-system.md` rather than letting anyone assume a gate that is absent:

| Layer | Web / JS family | Native (Swift · Kotlin · Dart) |
|---|---|---|
| **C1 colour** (write-gate) | ✅ hex · `rgb()` · `hsl()` | ✅ hex · packed `0xAARRGGBB` literals |
| **C2/C3/C4** radius · type · spacing (write-gate) | ✅ | ❌ **not checked** — these patterns are CSS and utility-class *syntax*; that syntax does not exist in these languages |
| **Render loop** (`ui-capture.js`) | ✅ | ❌ browser-URL driven — use the platform's own simulator/emulator capture and write the same `visual-report.json` shape by hand |
| **Craft rubric** (§4) | ✅ | ✅ — it grades a screenshot, and every platform can produce one |
| **`google-code-reviewer`** | ✅ | ✅ — and on native it is the *only* automated reader of the token file |

**Where a platform has fewer gates, the token file must be MORE concrete, not less.** The
temptation runs the other way: fewer checks feels like more freedom, and it is exactly how a
native project ends up with the drift the web project is blocked from committing.

---

## 2. Token conformance — blocks on write (C1–C4)

`hooks/enforce-design-tokens.sh` → `scripts/check-design-tokens.js`, run against the
project's **own** token set. No value is hardcoded in the checker.

| Code | Blocks | Passes |
|---|---|---|
| **C1 color** | any hex / `rgb()` / `hsl()` literal not in the token set | a declared token value, a CSS var, a Tailwind theme class |
| **C2 radius** | `rounded-[7px]`, `border-radius: 11px` off the scale | on-scale values, `9999px`/`50%` (pill/circle = intent) |
| **C3 typography** | `text-[13px]`, `font-size: 15px` off the type scale; an undeclared `font-family` | scale values, `clamp()`/`calc()` fluid type |
| **C4 spacing** | `p-[13px]`, `margin: 13px` off the spacing scale | on-scale values, `auto`, `%`, `calc()` |

**Exempt** (this is where a raw value is *supposed* to live, exactly once): token/theme/
global CSS files, `tailwind.config.*`, any `*.config.*`, tests, stories, `.project/`.

**Width and height are deliberately NOT checked.** A fixed width is a layout decision;
padding and gap are rhythm decisions. Only rhythm belongs to the scale — over-blocking
gets a gate switched off, and a gate that is off still reads as covered.

**When a value you need does not exist**, that is a design-system change, not a local
exception: ask the PM/user to add the token and regenerate. Never relocate a literal to
a file the checker does not read.

---

## 3. The render loop — required before any UI task is complete

```bash
node .claude/scripts/ui-capture.js \
     --url http://localhost:3000 \
     --routes / /login /dashboard \
     --label <task-id>
node .claude/scripts/check-visual-report.js --latest
```

Captures every route × `390x844 · 768x1024 · 1440x900` × `light · dark`, writes the
screenshots and `visual-report.json` under `.project/screenshots/<label>/`.

**Measured, and therefore blocking (🔴):**

| | Threshold | Why it is objective |
|---|---|---|
| **contrast** | ≥ 4.5:1 body · ≥ 3:1 large (≥24px, or ≥18.66px bold) | WCAG AA, computed from the composited rendered colors |
| **overflow** | nothing past the viewport width | measured against the *configured* viewport, never `window.innerWidth` (mobile emulation expands the layout viewport to fit overflow, which hides the very defect) |
| **touch target** | ≥ 44×44 CSS px on the mobile viewport | Apple HIG / Material minimum |

**Advisory (🟡):** rendered `font-size` < 12px, body copy > 95 characters per line.

**No Playwright or no dev server?** Drive the browser with the Playwright MCP tools and
write the same `visual-report.json` shape by hand — `ui-capture.js` prints the schema on
exit 3. If the UI genuinely cannot be rendered, record it explicitly:
`visual result: SKIPPED (<reason>)` in the Completion Report. Silence is not a skip.

---

## 4. The craft rubric — what the numbers cannot reach

A page can pass every check above and still be lifeless. Score these **from the
screenshot**, not from the source. Anything scoring ≤2 is a finding.

| # | Dimension | 1 — amateur | 5 — considered |
|---|---|---|---|
| 1 | **Hierarchy** | everything one size/weight; the eye has nowhere to land | one clear focal point per view; size, weight and colour agree on what matters |
| 2 | **Spacing rhythm** | arbitrary gaps; unrelated things equally spaced | space encodes relationship — related items tighter than unrelated groups |
| 3 | **Alignment** | edges nearly line up | a real grid; optical alignment where mathematical alignment looks wrong |
| 4 | **Density** | uniform padding everywhere regardless of content | density suits the job — dense for scanning data, generous for reading |
| 5 | **Colour intent** | colour used decoratively; multiple competing accents | one accent with a job; neutrals carry the structure |
| 6 | **Typography** | one family, default weights, default line-height | deliberate pairing; measure, leading and tracking tuned per role |
| 7 | **State coverage** | only the happy path exists | hover · focus · active · disabled · loading · empty · error all designed |
| 8 | **Motion** | none, or decorative movement everywhere | one purposeful transition; `transform`/`opacity` only; honours `prefers-reduced-motion` |
| 9 | **Point of view** | could be any product; looks like a template | the chosen direction is legible in the first second |

**Rule 9 is the one that decides whether the work is any good.** The design system
picks the direction; this rubric asks whether the direction actually survived
implementation. A build that is consistent, accessible and characterless has passed
every gate and still failed.

---

## 5. Who does what

| Role | Obligation |
|---|---|
| `apple-ux-wireframer` | **reads `tech-stack.md` FIRST** (Phase 0.0) and emits tokens in that platform's dialect; authors `design-system.md` including the **Base primitives (Sprint 0 F3)** checklist; runs `build-styles-json.js --check` — handing over a system with blanks, or in the wrong dialect, is a defect. **Writes a `Layout Intent` block per screen** (hierarchy · group gaps · density · single accent · measure · columns) — the half ASCII cannot draw — and **renders + measures the design itself** before the approval gate, self-scoring §4 from the screenshots |
| Sprint 0 Foundation Batch | builds the primitives from those tokens **before any feature sprint** — see `helpers/pm-foundation-sprint.md`. Consistency is created here; every later gate can only verify it |
| UI specialists | never write a literal a token can express; run the render loop; attach report + screenshot paths to the Completion Report. **Read the wireframe's authority scope** — the ASCII is binding on presence/order/grouping/states, notation-only on borders/proportions/spacing/type sizes; those come from the tokens + Layout Intent. Transcribing a monospace grid literally is what produces boxes-in-boxes with flat hierarchy |
| `google-code-reviewer` | receives the report and screenshots by injection; **must `Read` at least one screenshot per viewport** before grading UI; blocking violations are 🔴; scores §4 from the image |
| PM | a UI task with no visual evidence is not `[COMPLETE]` |
