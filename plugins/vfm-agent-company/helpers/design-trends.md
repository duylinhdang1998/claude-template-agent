---
name: design-trends
type: helper
description: |
  Curated catalog of the year's trendiest UI design directions, each with a
  ready-to-use token starter. apple-ux-wireframer reads this to present a
  shortlist to the user (when they choose "agent auto-designs"), then generates
  .project/design-system.md from the chosen direction.
  ⚠️ Refresh this list ~yearly. Last curated: 2026-08.
---

# Design Trend Catalog — 2026

Present these to the user as a numbered shortlist (tailor which ones you show to
the project type). Each entry has a **token starter** — copy it into
`.project/design-system.md` and adapt the exact hex/scale to the brand.

> Pick **3–5** to show, not all 11. Match to the product (e.g. fintech → 1/8;
> creative/portfolio → 3/4/11; consumer social → 2/10; dev tool → 1/6;
> product landing / feature showcase → 9/10; marketing/launch → 8/11).
> **9–11 are the newest 2026 directions** (Bento Grid, Expressive Minimalism,
> Kinetic Type) — lead with them for greenfield marketing/product sites.
> **Layout ≠ palette:** Bento Grid (9) is a *layout system* that combines with any
> palette here — pair it (e.g. "Bento + Minimal Mono").

---

## 1. Minimal Mono (Vercel / Linear style)
**Vibe**: high-contrast, near-monochrome, generous whitespace, crisp hairline
borders, tiny accent. Feels fast, engineered, premium. **Best for**: dev tools,
SaaS dashboards, B2B.
- Colors: bg `#0A0A0A` / surface `#111111` / border `#262626` / text `#EDEDED` / muted `#A1A1AA` / accent `#3B82F6`. (Light: bg `#FFFFFF`, surface `#FAFAFA`, border `#E5E5E5`, text `#0A0A0A`.)
- Type: Geist / Inter; tight tracking on headings; scale 12·14·16·20·24·32·48.
- Radius: 6·8·10. Shadows: almost none — rely on 1px borders. Motion: 150ms ease-out.

## 2. Soft Pastel / Friendly Consumer
**Vibe**: rounded, airy, low-saturation pastels, big radii, playful. **Best for**:
consumer apps, wellness, social, onboarding-heavy products.
- Colors: bg `#FFFDF9` / surface `#FFFFFF` / primary `#7C6BF5` / accent `#FF8FB1` / success `#57C7A0` / text `#2B2A33` / muted `#8A8794`.
- Type: rounded sans (Nunito / SF Rounded); scale 13·15·17·22·28·36.
- Radius: 12·16·24 (pill buttons). Shadows: soft `0 4px 16px rgba(0,0,0,.06)`. Motion: 220ms spring.

## 3. Neo-Brutalism
**Vibe**: hard edges, thick black borders, flat blocky shadows, loud primaries,
mono/grotesk type. Bold, memorable, anti-corporate. **Best for**: creative,
crypto/web3, marketing sites, Gen-Z brands.
- Colors: bg `#FFFEF2` / ink `#111111` / primary `#FFDE00` / secondary `#3D5AFE` / danger `#FF3B30`.
- Type: Space Grotesk / mono; heavy weights; scale 14·16·20·28·40·64.
- Radius: 0–4. Borders: 2–3px solid `#111`. Shadows: `4px 4px 0 #111` (hard offset). Motion: snap, translate on hover.

## 4. Editorial / Big Type + Serif
**Vibe**: magazine layout, large display serif, strong grid, restrained color,
imagery-forward. **Best for**: portfolios, agencies, publishing, luxury.
- Colors: bg `#F7F4EF` / surface `#FFFFFF` / ink `#1A1712` / accent `#B4532A` (terracotta) / muted `#7A736A`.
- Type: display serif (Fraunces / GT Sectra) for headings + clean sans body; scale 15·18·24·40·64·96.
- Radius: 2·4. Shadows: minimal. Motion: slow fades, parallax.

## 5. Liquid Glass / Glassmorphism 2.0 / Aurora
**Vibe**: frosted translucent panels, blurred aurora gradient backgrounds, subtle
depth and refraction (Apple's iOS 26 "Liquid Glass" language). Modern, atmospheric.
**Best for**: AI products, fintech dashboards, hero landing pages, Apple-adjacent
apps. (Use sparingly — watch contrast/a11y; keep text on a solid layer.)
- Colors: bg gradient `#0B1026 → #1B2A4A`, aurora blobs `#7C5CFF`/`#22D3EE`/`#F472B6`, glass `rgba(255,255,255,.08)` + `backdrop-blur`, text `#F5F7FF`, border `rgba(255,255,255,.14)`.
- Type: Inter / Sora; scale 13·15·17·22·30·44.
- Radius: 16·20·28. Shadows: `0 8px 32px rgba(0,0,0,.35)`. Motion: 300ms ease, floating blobs.

## 6. Dark Developer / Terminal
**Vibe**: deep charcoal, syntax-accent colors, monospace accents, data-dense but
calm. **Best for**: dev tools, analytics, infra, dashboards.
- Colors: bg `#0D1117` / surface `#161B22` / border `#30363D` / text `#C9D1D9` / accent `#2F81F7` / green `#3FB950` / amber `#D29922`.
- Type: Inter body + JetBrains Mono for code/numbers; scale 12·13·14·16·20·28.
- Radius: 6·8. Shadows: subtle. Motion: 120ms, minimal.

## 7. Warm Minimalism / Earthy
**Vibe**: beige/sand neutrals, muted earth accents, calm and human, lots of
breathing room. **Best for**: lifestyle, e-commerce, DTC brands, booking.
- Colors: bg `#FAF6F0` / surface `#FFFFFF` / primary `#3F4A3C` (olive) / accent `#C08457` (clay) / text `#2E2A25` / muted `#8C857B`.
- Type: humanist sans (General Sans / Satoshi); scale 14·16·18·24·32·48.
- Radius: 10·14·20. Shadows: `0 6px 20px rgba(60,50,40,.08)`. Motion: 200ms ease.

## 8. Bold Gradient / AI-native
**Vibe**: vivid mesh gradients, glowing accents, high energy, futuristic.
**Best for**: AI startups, product launches, growth landing pages.
- Colors: bg `#08070D` / surface `#141221` / gradient `#6D28D9 → #DB2777 → #F59E0B`, text `#FFFFFF`, muted `#B4B0C4`, accent `#A855F7`.
- Type: Sora / Clash Display; scale 13·15·18·24·34·56.
- Radius: 12·16·24. Shadows: colored glow `0 0 40px rgba(168,85,247,.35)`. Motion: 250ms, animated gradient.

## 9. Bento Grid (Modular compartments) — ⭐ 2026
**Vibe**: content arranged into a tidy grid of rounded **tiles** of varying sizes,
like a Japanese bento box — each tile is one scannable "bite". 2026 "Active Grid":
tiles expand / play a video / reveal a second data layer on hover. Organized,
scannable, keynote-premium (Apple-style). **Best for**: landing pages, product &
feature showcases, dashboards, portfolios, pricing/overview pages. **This is a
LAYOUT system — combine it with any palette above** (e.g. "Bento + Minimal Mono").
- Layout: CSS Grid, 12-col, gap `16–24px`; tiles span varying `col/row`; asymmetric sizes; 1 hero tile + supporting tiles.
- Colors (neutral default): bg `#F4F4F5` / tile `#FFFFFF` / border `rgba(0,0,0,.06)` / text `#18181B` / accent per brand. (Dark: bg `#0A0A0A`, tile `#161616`, border `rgba(255,255,255,.08)`.)
- Type: clean sans (Inter / Geist); scale 13·15·18·24·32·48.
- Radius: 16·20·24 (tiles). Shadows: `0 2px 8px rgba(0,0,0,.05)` + lift on hover. Motion: tile hover scale/expand 200–300ms ease-out; reveal secondary layer; honor `prefers-reduced-motion`.

## 10. Expressive Minimalism — ⭐ 2026
**Vibe**: the 2026 evolution of minimalism — clean layout + generous whitespace,
**warmed** with organic shapes, ONE characterful display font, a single confident
accent, and human touches (a blob, grain, a hand-drawn mark). Inhabited, not empty.
**Best for**: modern brands, agencies, SaaS marketing, DTC, consumer.
- Colors: bg `#FBFAF8` / surface `#FFFFFF` / ink `#1B1A17` / one bold accent `#FF5D3B` (or brand) / muted `#6F6B64`.
- Type: one expressive display (Fraunces / Clash Display / Boldonse) for headers + neutral sans body; big jump 16·18·22·36·64·96.
- Radius: 8·16 + occasional full-round organic shapes. Shadows: minimal, soft. Motion: 200ms ease, ONE signature move (organic blob drift, magnetic button).

## 11. Kinetic Typography / Motion-first — ⭐ 2026
**Vibe**: oversized **animated type** as the hero — words stagger, mask-reveal, and
morph on scroll; imagery is minimal, the type IS the design. High energy, memorable.
**Best for**: creative studios, product launches, campaign/event sites, portfolios.
- Colors: high contrast — bg `#0B0B0B` / text `#F5F5F5` / one electric accent `#C6FF00` (or `#FF2D55`). (Or invert to light bg.)
- Type: variable grotesk / display (Anton, Clash Display, PP Neue Montreal); massive scale 18·24·48·96·160+; tight leading.
- Radius: 0–8 (type-led, few boxes). Motion: scroll-linked stagger / mask reveal / marquee / variable-font weight-width animation; 400–800ms sequences; **MUST** honor `prefers-reduced-motion` (fall back to static).

---

## After the user picks

Generate `.project/design-system.md` from `.claude/templates/design-system.md`,
filling **concrete** tokens from the chosen direction above (no blanks left).
Add: exact color ramp, type scale + font families, spacing scale (4/8-based),
radius + shadow tokens, motion durations, and 2–3 component patterns (button,
input, card) referencing those tokens. This file is auto-injected into the
frontend agent's context — it MUST be concrete and complete.
