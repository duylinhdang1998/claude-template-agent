#!/usr/bin/env node
/**
 * check-design-tokens.js — mechanical enforcement of "use the project design system".
 *
 * WHY THIS EXISTS
 *   `helpers/code-quality.md` documents Frontend Rule #2 (follow the design system) with
 *   its only enforcement layer listed as "Review" — an LLM's judgement, applied to source
 *   code it reads but never renders. That same file states the consequence: *a standard
 *   enforced by prose alone gets re-argued as a trade-off at every review until it
 *   silently stops existing.* This script is the missing mechanical layer.
 *
 * WHAT IT CHECKS (each against the project's OWN token set — nothing is hardcoded)
 *   C1 color      — a color literal that is not a declared token value
 *   C2 radius     — an arbitrary corner radius that is not on the radius scale
 *   C3 typography — an arbitrary font-size, or a font-family outside the declared families
 *   C4 spacing    — padding/margin/gap in a px value that is not on the spacing scale
 *
 * USAGE
 *   node check-design-tokens.js <file> [<file>...] [--tokens <design-system.json>]
 *                               [--only c1,c2,c3,c4] [--quiet]
 *
 * EXIT CODES
 *   0 clean (or nothing to check / no design system) · 2 violations found
 *
 * DESIGN NOTE — why it fails OPEN
 *   No design system in the project means no contract to enforce, so the checker exits 0.
 *   A gate that blocks work on projects that never opted in would be turned off within a
 *   day, and a gate that is off is worse than no gate because it still reads as covered.
 */

'use strict';
const fs = require('fs');
const path = require('path');

const ROOT = process.env.CLAUDE_PROJECT_DIR || process.cwd();
const args = process.argv.slice(2);
const flag = (f, d) => { const i = args.indexOf(f); return i > -1 && args[i + 1] ? args[i + 1] : d; };
const QUIET = args.includes('--quiet');
const ONLY = flag('--only', 'c1,c2,c3,c4').split(',').map((s) => s.trim().toLowerCase());
const files = args.filter((a) => !a.startsWith('--') && !['--tokens', '--only'].includes(args[args.indexOf(a) - 1]));

// ── token source ────────────────────────────────────────────────────────────
const TOKEN_CANDIDATES = [
  '.project/design-system.json', '.project/design/design-system.json',
  '.project/documentation/design-system.json', 'design-system.json',
];
let tokensPath = flag('--tokens', null);
if (!tokensPath) {
  for (const c of TOKEN_CANDIDATES) {
    const p = path.join(ROOT, c);
    if (fs.existsSync(p)) { tokensPath = p; break; }
  }
}
if (!tokensPath || !fs.existsSync(tokensPath)) process.exit(0); // fail open — see design note
let T;
try { T = JSON.parse(fs.readFileSync(tokensPath, 'utf8')); } catch { process.exit(0); }

const allowedHex = new Set((T.allowedHex || []).map((h) => h.toLowerCase()));
const allowedRadius = new Set(T.allowedRadius || []);
const allowedSizes = new Set(T.allowedFontSizes || []);
const spacing = new Set((T.spacing || []).map(Number));
const families = Object.values(T.fontFamilies || {})
  .flatMap((v) => String(v).split(',')).map((s) => s.trim().replace(/^['"]|['"]$/g, '').toLowerCase())
  .filter(Boolean);

// ── which files this applies to ─────────────────────────────────────────────
const UI_EXT = /\.(tsx|jsx|ts|js|css|scss|sass|less|vue|svelte|astro)$/i;
// Native / cross-platform UI sources. The C2–C4 patterns are CSS and utility-class SYNTAX;
// that syntax does not exist in these languages, so running them here would report green
// without looking at anything. Only C1 is checked — a colour literal is the one drift that
// IS expressible in every one of these languages, and it is the drift that actually makes
// an interface look inconsistent. An honestly-bounded gate beats an overstated one.
const NATIVE_EXT = /\.(swift|kt|kts|dart)$/i;
// Files that DEFINE the system, describe it, or are not product UI. Exempting these is not
// a loophole: they are the place a raw value is supposed to appear exactly once.
const EXEMPT = [
  /(^|\/)(node_modules|dist|build|out|coverage|\.next|\.git)\//,
  /(^|\/)\.(claude|project)\//,
  /tailwind\.config\.[a-z]+$/i, /\.config\.(js|ts|mjs|cjs)$/i,
  /(^|\/)(globals?|tokens?|colou?rs?|theme|typography|variables|reset|design-system)[\w.-]*\.(css|scss|sass|less|ts|js|swift|kt|kts|dart)$/i,
  /\.(test|spec|stories)\.[a-z]+$/i,
  /(^|\/)__(tests|mocks)__\//,
];
// Returns 'web' | 'native' | null — null means the checker does not apply to this file.
const uiKind = (f) => {
  const rel = f.replace(/\\/g, '/');
  if (EXEMPT.some((re) => re.test(rel))) return null;
  if (UI_EXT.test(rel)) return 'web';
  if (NATIVE_EXT.test(rel)) return 'native';
  return null;
};
const applies = (f) => uiKind(f) !== null;

// ── helpers ─────────────────────────────────────────────────────────────────
const normHex = (h) => {
  let v = h.toLowerCase();
  if (v.length === 4) v = '#' + v[1] + v[1] + v[2] + v[2] + v[3] + v[3];
  if (v.length === 5) v = '#' + v[1] + v[1] + v[2] + v[2] + v[3] + v[3] + v[4] + v[4];
  return v.length === 9 ? v.slice(0, 7) : v; // ignore alpha channel when matching
};
const nearest = (n, set) => {
  const a = [...set].map(Number).filter((x) => !isNaN(x));
  if (!a.length) return null;
  return a.reduce((best, x) => (Math.abs(x - n) < Math.abs(best - n) ? x : best), a[0]);
};
// strip comments + import/url lines so a documented example is not reported as product code
const strip = (src) => src
  .replace(/\/\*[\s\S]*?\*\//g, (m) => m.replace(/[^\n]/g, ' '))
  .replace(/(^|[^:])\/\/[^\n]*/g, (m) => m.replace(/[^\n]/g, ' '))
  .replace(/^\s*(import|@import|require)[^\n]*$/gm, (m) => ' '.repeat(m.length));

const lineOf = (src, idx) => src.slice(0, idx).split('\n').length;
const findings = [];
const add = (file, line, code, found, msg) => findings.push({ file, line, code, found, msg });

// ── the checks ──────────────────────────────────────────────────────────────
function checkFile(file) {
  const abs = path.isAbsolute(file) ? file : path.join(ROOT, file);
  const kind = fs.existsSync(abs) ? uiKind(path.relative(ROOT, abs)) : null;
  if (!kind) return;
  const rel = path.relative(ROOT, abs);
  const raw = fs.readFileSync(abs, 'utf8');
  const src = strip(raw);

  // C1 — color literals
  if (ONLY.includes('c1')) {
    for (const m of src.matchAll(/#[0-9a-fA-F]{3,8}\b/g)) {
      const hex = normHex(m[0]);
      if (!allowedHex.has(hex)) {
        add(rel, lineOf(src, m.index), 'C1', m[0],
          `color \`${m[0]}\` is not in the design system. Declared: ${[...allowedHex].slice(0, 6).join(', ')}${allowedHex.size > 6 ? ' …' : ''}`);
      }
    }
    for (const m of src.matchAll(/\b(?:rgb|hsl)a?\(\s*[\d.]+[^)]*\)/gi)) {
      // a functional color is fine when it is itself a declared token value
      const norm = m[0].replace(/\s+/g, '');
      const declared = Object.values(T.colors || {}).some((v) => String(v).replace(/\s+/g, '') === norm);
      if (!declared) {
        add(rel, lineOf(src, m.index), 'C1', m[0],
          `color \`${m[0]}\` is not a declared token. Use a token/CSS var instead of a literal.`);
      }
    }
    // Packed ARGB/RGB integer literals — how a colour is written on native platforms.
    if (kind === 'native') {
      for (const m of src.matchAll(/\b0x([0-9a-fA-F]{6,8})\b/g)) {
        const digits = m[1].length === 8 ? m[1].slice(2) : m[1]; // AARRGGBB → RRGGBB
        if (!allowedHex.has('#' + digits.toLowerCase())) {
          add(rel, lineOf(src, m.index), 'C1', m[0],
            `color \`${m[0]}\` is not in the design system. Reference the project's token \
namespace instead of a packed colour literal.`);
        }
      }
    }
  }

  // C2 — radius
  if (kind === 'web' && ONLY.includes('c2') && allowedRadius.size) {
    for (const m of src.matchAll(/rounded-\[([^\]]+)\]/g)) {
      if (!allowedRadius.has(m[1])) {
        add(rel, lineOf(src, m.index), 'C2', m[0],
          `radius \`${m[1]}\` is off-scale. Scale: ${[...allowedRadius].join(' · ')}`);
      }
    }
    for (const m of src.matchAll(/border-radius\s*:\s*([^;{}\n]+)/gi)) {
      const v = m[1].trim();
      if (/var\(|inherit|initial|unset|9999px|50%|100%/.test(v)) continue; // pills/circles are intent, not drift
      if (!v.split(/\s+/).every((p) => allowedRadius.has(p))) {
        add(rel, lineOf(src, m.index), 'C2', v,
          `radius \`${v}\` is off-scale. Scale: ${[...allowedRadius].join(' · ')}`);
      }
    }
  }

  // C3 — typography
  if (kind === 'web' && ONLY.includes('c3')) {
    if (allowedSizes.size) {
      for (const m of src.matchAll(/\btext-\[([^\]]+)\]/g)) {
        if (/^#|^rgb|^hsl|^var\(/i.test(m[1])) continue; // that is a color, handled by C1
        if (!allowedSizes.has(m[1])) {
          add(rel, lineOf(src, m.index), 'C3', m[0],
            `font-size \`${m[1]}\` is not in the type scale: ${[...allowedSizes].join(' · ')}`);
        }
      }
      for (const m of src.matchAll(/font-size\s*:\s*([^;{}\n]+)/gi)) {
        const v = m[1].trim();
        if (/var\(|inherit|clamp\(|calc\(|%$|em$/.test(v)) continue; // fluid type is a deliberate technique
        if (!allowedSizes.has(v)) {
          add(rel, lineOf(src, m.index), 'C3', v,
            `font-size \`${v}\` is not in the type scale: ${[...allowedSizes].join(' · ')}`);
        }
      }
    }
    if (families.length) {
      for (const m of src.matchAll(/font-family\s*:\s*([^;{}\n]+)/gi)) {
        const first = m[1].split(',')[0].trim().replace(/^['"]|['"]$/g, '').toLowerCase();
        if (/var\(|inherit/.test(first)) continue;
        if (!families.includes(first)) {
          add(rel, lineOf(src, m.index), 'C3', first,
            `font-family \`${first}\` is not a declared family: ${families.join(' · ')}`);
        }
      }
    }
  }

  // C4 — spacing (padding / margin / gap only: a fixed width or height is a layout
  //      decision, a padding is a rhythm decision — only rhythm belongs to the scale)
  if (kind === 'web' && ONLY.includes('c4') && spacing.size) {
    const util = /\b(p|px|py|pt|pb|pl|pr|m|mx|my|mt|mb|ml|mr|gap|gap-x|gap-y|space-x|space-y)-\[(-?\d+(?:\.\d+)?)(px|rem)\]/g;
    for (const m of src.matchAll(util)) {
      const px = m[3] === 'rem' ? parseFloat(m[2]) * 16 : parseFloat(m[2]);
      if (!spacing.has(px)) {
        add(rel, lineOf(src, m.index), 'C4', m[0],
          `spacing ${px}px is off-scale (nearest: ${nearest(px, spacing)}px). Scale: ${[...spacing].join(' · ')}`);
      }
    }
    const decl = /\b(padding|margin|gap|row-gap|column-gap)(?:-(?:top|right|bottom|left|inline|block))?\s*:\s*([^;{}\n]+)/gi;
    for (const m of src.matchAll(decl)) {
      const v = m[2].trim();
      if (/var\(|auto|inherit|calc\(|%|clamp\(/.test(v)) continue;
      for (const part of v.split(/\s+/)) {
        const pm = part.match(/^(-?\d+(?:\.\d+)?)(px|rem)$/);
        if (!pm) continue;
        const px = pm[2] === 'rem' ? parseFloat(pm[1]) * 16 : parseFloat(pm[1]);
        if (px !== 0 && !spacing.has(px)) {
          add(rel, lineOf(src, m.index), 'C4', part,
            `spacing ${px}px is off-scale (nearest: ${nearest(px, spacing)}px). Scale: ${[...spacing].join(' · ')}`);
        }
      }
    }
  }
}

files.forEach(checkFile);

if (!findings.length) {
  if (!QUIET) console.log(`✓ design tokens OK (${files.length} file(s) checked against ${path.relative(ROOT, tokensPath)})`);
  process.exit(0);
}

const LABEL = { C1: 'COLOR', C2: 'RADIUS', C3: 'TYPOGRAPHY', C4: 'SPACING' };
console.error(`\n⛔ DESIGN-SYSTEM VIOLATION — ${findings.length} value(s) bypass ${path.relative(ROOT, tokensPath)}\n`);
for (const f of findings.slice(0, 25)) {
  console.error(`  ${f.file}:${f.line}  [${f.code} ${LABEL[f.code]}]  ${f.msg}`);
}
if (findings.length > 25) console.error(`  … and ${findings.length - 25} more`);
console.error(`
  FIX: replace each literal with the token that expresses the intent — whatever form
  this platform's design system uses (a utility theme class, a CSS custom property, a
  native token namespace, or the primitive component that already encodes it). If the value you need genuinely does not exist in the system, that
  is a DESIGN-SYSTEM change — ask the PM/user to add the token, then re-run:
      node .claude/scripts/build-styles-json.js --check
  Do NOT silence this by inlining the value somewhere the checker does not look.
`);
process.exit(2);
