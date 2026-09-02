#!/usr/bin/env node
/**
 * build-styles-json.js — turn a prose design system into a machine-readable artifact.
 *
 * WHY THIS EXISTS
 *   `.project/design-system.md` is markdown. Markdown cannot be compared against code.
 *   Every downstream gate (token conformance, reviewer, visual report) needs an EXACT
 *   token set, otherwise it can only guess heuristically ("looks like a raw hex") instead
 *   of deciding ("#3B82F6 is not any declared color").
 *
 * WHAT IT DOES
 *   Parses ANY design-system markdown (no fixed section names required) by harvesting
 *   token→value pairs from markdown tables and CSS custom-property declarations, then
 *   classifies each pair by its NAME and VALUE SHAPE. Nothing here is specific to a
 *   project, palette, or style — a design system that uses different token names still
 *   parses, because classification is driven by value shape first, name second.
 *
 * USAGE
 *   node build-styles-json.js [--in <design-system.md>] [--out <design-system.json>]
 *                             [--emit-css] [--check] [--quiet]
 *
 *   --check     exit 1 if the design system is still a template (unfilled placeholders)
 *               or if a required token group is empty. Run this BEFORE handing the
 *               design system to any frontend agent.
 *   --emit-css  also write `<out-dir>/design-system.tokens.css` with :root custom props.
 *
 * EXIT CODES
 *   0 ok · 1 --check failed (placeholders / empty groups) · 2 no input file found
 */

'use strict';
const fs = require('fs');
const path = require('path');

// ── input resolution (same candidate order as subagent-inject-wireframe.sh) ──
const IN_CANDIDATES = [
  '.project/design-system.md',
  '.project/design/design-system.md',
  '.project/documentation/design-system.md',
  '.project/wireframes/design-system.md',
  'design-system.md',
  'DESIGN.md',
  'references/DESIGN.md',
  'app/design-system.md',
  'app/DESIGN.md',
];

function arg(flag, fallback) {
  const i = process.argv.indexOf(flag);
  return i > -1 && process.argv[i + 1] && !process.argv[i + 1].startsWith('--')
    ? process.argv[i + 1]
    : fallback;
}
const has = (flag) => process.argv.includes(flag);

const ROOT = process.env.CLAUDE_PROJECT_DIR || process.cwd();
const QUIET = has('--quiet');
const log = (...a) => { if (!QUIET) console.log(...a); };

let inFile = arg('--in', null);
if (!inFile) {
  for (const c of IN_CANDIDATES) {
    const p = path.join(ROOT, c);
    if (fs.existsSync(p)) { inFile = p; break; }
  }
}
if (!inFile || !fs.existsSync(inFile)) {
  console.error('✗ no design-system markdown found (looked for: ' + IN_CANDIDATES.join(', ') + ')');
  process.exit(2);
}
const outFile = arg('--out', path.join(path.dirname(inFile), 'design-system.json'));
const src = fs.readFileSync(inFile, 'utf8');

// ── value shape detectors ───────────────────────────────────────────────────
const RE_HEX = /#[0-9a-fA-F]{3,8}\b/g;
const RE_FUNC_COLOR = /\b(?:rgba?|hsla?|oklch|color-mix)\([^)]*\)/gi;
const RE_PLACEHOLDER = /(?:^|[^\w])(?:_{2,}|#_+|\?{2,}|TBD|TODO|xxx)(?:[^\w]|$)/i;
const RE_DURATION = /^\d+(?:\.\d+)?m?s$/i;
const RE_EASING = /^(?:cubic-bezier\([^)]*\)|spring\([^)]*\)|linear|ease(?:-in|-out|-in-out)?|steps\([^)]*\))$/i;
const RE_PX = /^-?\d+(?:\.\d+)?(?:px|rem|em|%)$/i;

const isPlaceholder = (v) => !v || RE_PLACEHOLDER.test(v) || v.trim() === '';
const normHex = (h) => {
  let v = h.toLowerCase();
  if (v.length === 4) v = '#' + v[1] + v[1] + v[2] + v[2] + v[3] + v[3]; // #abc → #aabbcc
  return v;
};

// ── harvest raw name→value pairs ────────────────────────────────────────────
// Source 1: markdown table rows  `| name | value | ... |`
// Source 2: CSS custom properties `--name: value;`
// Source 3: `Key: value` lines inside prose
const pairs = [];
const pushPair = (name, value) => {
  if (!name || !value) return;
  name = name.replace(/[`*]/g, '').trim();
  value = value.replace(/[`*]/g, '').trim();
  if (!name || !value) return;
  // a cell may declare several sibling tokens: `radius-sm / radius-md / radius-lg`
  const names = name.split(/\s*\/\s*/).filter(Boolean);
  const values = value.split(/\s*\/\s*/).filter(Boolean);
  if (names.length > 1 && names.length === values.length) {
    names.forEach((n, i) => pairs.push({ name: n, value: values[i] }));
  } else {
    pairs.push({ name: names[0] || name, value });
  }
};

for (const line of src.split('\n')) {
  const t = line.trim();
  if (t.startsWith('|') && t.endsWith('|')) {
    const cells = t.slice(1, -1).split('|').map((c) => c.trim());
    const isHeader = /^(token|name|property|variable|key)$/i.test(cells[0].replace(/[`*]/g, ''));
    if (cells.length >= 2 && !/^:?-{2,}/.test(cells[0]) && !isHeader) pushPair(cells[0], cells[1]);
    continue;
  }
  const cssVar = t.match(/^(--[a-z0-9-]+)\s*:\s*([^;]+);?/i);
  if (cssVar) { pushPair(cssVar[1], cssVar[2]); continue; }
  const kv = t.match(/^([A-Za-z][\w\s-]{1,30}):\s+(\S.*)$/);
  if (kv && !t.startsWith('http')) pushPair(kv[1], kv[2]);
}

// ── classify ────────────────────────────────────────────────────────────────
const out = {
  $schema: 'vfm-design-tokens/1',
  source: path.relative(ROOT, inFile),
  generatedAt: new Date().toISOString(),
  colors: {}, fontFamilies: {}, fontSizes: {}, spacing: [],
  radius: {}, shadows: {}, motion: {}, placeholders: [], unclassified: {},
};

const nameHas = (n, ...keys) => keys.some((k) => n.toLowerCase().includes(k));

for (const { name, value } of pairs) {
  if (isPlaceholder(value)) { out.placeholders.push({ token: name, value }); continue; }
  const key = name.replace(/^--/, '');
  const hexes = value.match(RE_HEX) || [];
  const funcColors = value.match(RE_FUNC_COLOR) || [];

  if (nameHas(key, 'shadow')) { out.shadows[key] = value; continue; }
  if (hexes.length === 1 && value.replace(hexes[0], '').trim().length <= 2) {
    out.colors[key] = normHex(hexes[0]); continue;
  }
  if (funcColors.length === 1 && !nameHas(key, 'shadow')) { out.colors[key] = value.trim(); continue; }
  if (nameHas(key, 'radius', 'rounded')) { out.radius[key] = value; continue; }
  if (nameHas(key, 'duration', 'ease', 'stagger', 'motion', 'transition') ||
      RE_DURATION.test(value) || RE_EASING.test(value)) { out.motion[key] = value; continue; }
  if (nameHas(key, 'font family', 'font-family', 'fontfamily') ||
      (nameHas(key, 'font') && !/\d/.test(value))) { out.fontFamilies[key] = value; continue; }
  if (nameHas(key, 'text', 'size', 'display', 'h1', 'h2', 'h3', 'body', 'caption', 'label')) {
    // "40/48" (size/line-height) · "16px" · "1rem"
    const m = value.match(/^(\d+(?:\.\d+)?)(px|rem|em)?\s*\/\s*(\d+(?:\.\d+)?)(px|rem|em)?$/);
    if (m) { out.fontSizes[key] = { size: m[1] + (m[2] || 'px'), lineHeight: m[3] + (m[4] || 'px') }; continue; }
    if (RE_PX.test(value)) { out.fontSizes[key] = { size: value }; continue; }
  }
  if (RE_PX.test(value) && nameHas(key, 'space', 'spacing', 'gap', 'gutter')) {
    out.spacing.push(parseFloat(value)); continue;
  }
  out.unclassified[key] = value;
}

// spacing scale is usually prose, not a table: "`4 · 8 · 12 · 16 · 24` (px)"
{
  const lines = src.split('\n');
  const start = lines.findIndex((l) => /^#{1,6}\s.*spacing/i.test(l));
  let body = '';
  if (start > -1) {
    for (let i = start + 1; i < lines.length && !/^#{1,6}\s/.test(lines[i]); i++) body += lines[i] + '\n';
  }
  const nums = (body.match(/\b\d{1,3}\b/g) || []).map(Number).filter((n) => n > 0 && n <= 256);
  out.spacing = [...new Set([...out.spacing, ...nums])].sort((a, b) => a - b);
}

// every hex mentioned ANYWHERE is a declared value — the token checker treats this as
// the permissive superset so a color used before it gets a formal name is not blocked.
out.allowedHex = [...new Set((src.match(RE_HEX) || []).map(normHex).filter((h) => !/^#_+$/.test(h)))];
out.allowedRadius = [...new Set(Object.values(out.radius).flatMap((v) => v.match(/\d+(?:\.\d+)?(?:px|rem|%)/g) || []))];
out.allowedFontSizes = [...new Set(Object.values(out.fontSizes).map((f) => f.size).filter(Boolean))];

// ── write ───────────────────────────────────────────────────────────────────
fs.mkdirSync(path.dirname(outFile), { recursive: true });
fs.writeFileSync(outFile, JSON.stringify(out, null, 2) + '\n');
log(`✓ ${path.relative(ROOT, outFile)} — ${Object.keys(out.colors).length} colors · ` +
    `${Object.keys(out.fontSizes).length} sizes · ${out.spacing.length} spacing steps · ` +
    `${Object.keys(out.radius).length} radius · ${Object.keys(out.motion).length} motion`);

if (has('--emit-css')) {
  const cssPath = path.join(path.dirname(outFile), 'design-system.tokens.css');
  const decl = [];
  for (const [k, v] of Object.entries(out.colors)) decl.push(`  --${k.replace(/^--/, '')}: ${v};`);
  for (const [k, v] of Object.entries(out.radius)) decl.push(`  --${k.replace(/^--/, '')}: ${v};`);
  for (const [k, v] of Object.entries(out.shadows)) decl.push(`  --${k.replace(/^--/, '')}: ${v};`);
  for (const [k, v] of Object.entries(out.motion)) decl.push(`  --${k.replace(/^--/, '')}: ${v};`);
  fs.writeFileSync(cssPath,
    `/* GENERATED by build-styles-json.js from ${out.source} — do not edit by hand */\n:root {\n${decl.join('\n')}\n}\n`);
  log(`✓ ${path.relative(ROOT, cssPath)} — ${decl.length} custom properties`);
}

// ── --check: is this design system actually usable? ─────────────────────────
if (has('--check')) {
  const problems = [];
  if (out.placeholders.length) {
    problems.push(`${out.placeholders.length} unfilled placeholder token(s): ` +
      out.placeholders.slice(0, 6).map((p) => `${p.token}=${p.value}`).join(', ') +
      (out.placeholders.length > 6 ? ' …' : ''));
  }
  const empty = ['colors', 'fontSizes', 'spacing', 'radius']
    .filter((g) => (Array.isArray(out[g]) ? out[g].length : Object.keys(out[g]).length) === 0);
  if (empty.length) problems.push(`empty token group(s): ${empty.join(', ')}`);

  if (problems.length) {
    console.error('\n⛔ DESIGN SYSTEM NOT READY — ' + path.relative(ROOT, inFile));
    problems.forEach((p) => console.error('   • ' + p));
    console.error('\n   A design system with blanks is a template, not a contract. Every UI\n' +
                  '   specialist is locked to this file — fill every token with a CONCRETE\n' +
                  '   value before any frontend task is assigned.\n');
    process.exit(1);
  }
  log('✓ --check passed: no placeholders, all required groups populated.');
}
