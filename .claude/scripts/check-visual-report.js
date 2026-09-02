#!/usr/bin/env node
/**
 * check-visual-report.js — grade a visual report. No browser required.
 *
 * Separated from `ui-capture.js` on purpose: the capture needs Playwright and a running
 * dev server, but the GATE and the REVIEWER only need to read the artifact. Splitting
 * them means a report produced by the Playwright MCP tools (no npm Playwright installed)
 * is graded by exactly the same rules as one produced by the script.
 *
 * USAGE
 *   node check-visual-report.js [<report.json> | --latest] [--max-age-min N] [--quiet]
 *
 *   --latest        find the newest .project/screenshots/<any>/visual-report.json
 *   --max-age-min   fail if the report is older than N minutes (stale evidence is not
 *                   evidence — it may describe a build from before the current change)
 *
 * EXIT CODES
 *   0 pass · 1 blocking violations · 3 no report found (or stale)
 */

'use strict';
const fs = require('fs');
const path = require('path');

const ROOT = process.env.CLAUDE_PROJECT_DIR || process.cwd();
const argv = process.argv.slice(2);
const QUIET = argv.includes('--quiet');
const flag = (f, d) => { const i = argv.indexOf(f); return i > -1 && argv[i + 1] ? argv[i + 1] : d; };
const MAX_AGE = Number(flag('--max-age-min', '0'));

function findLatest() {
  const base = path.join(ROOT, '.project', 'screenshots');
  if (!fs.existsSync(base)) return null;
  const found = [];
  for (const d of fs.readdirSync(base)) {
    const p = path.join(base, d, 'visual-report.json');
    if (fs.existsSync(p)) found.push({ p, m: fs.statSync(p).mtimeMs });
  }
  found.sort((a, b) => b.m - a.m);
  return found.length ? found[0].p : null;
}

let file = argv.find((a) => !a.startsWith('--') && a.endsWith('.json'));
if (!file || argv.includes('--latest')) file = findLatest();
if (!file || !fs.existsSync(file)) {
  if (!QUIET) console.error('✗ no visual report found under .project/screenshots/*/visual-report.json');
  process.exit(3);
}
if (MAX_AGE > 0) {
  const ageMin = (Date.now() - fs.statSync(file).mtimeMs) / 60000;
  if (ageMin > MAX_AGE) {
    if (!QUIET) console.error(`✗ visual report is ${Math.round(ageMin)} min old (max ${MAX_AGE}) — re-capture before claiming done`);
    process.exit(3);
  }
}

let R;
try { R = JSON.parse(fs.readFileSync(file, 'utf8')); }
catch (e) { console.error('✗ malformed report: ' + e.message); process.exit(3); }

const rel = path.relative(ROOT, file);
const s = R.summary || {};
const blocking = (s.contrast || 0) + (s.overflow || 0) + (s.touchTarget || 0);
const warn = (s.tinyText || 0) + (s.lineLength || 0);

if (!QUIET) {
  console.log(`\n📐 VISUAL REPORT — ${rel}`);
  console.log(`   ${(R.captures || []).length} capture(s) · ${R.baseUrl || '?'} · ${R.generatedAt || '?'}`);
  console.log(`   🔴 contrast ${s.contrast || 0} · overflow ${s.overflow || 0} · touch-target ${s.touchTarget || 0}`);
  console.log(`   🟡 tiny-text ${s.tinyText || 0} · long-line ${s.lineLength || 0}`);
}

if (blocking) {
  const lines = [];
  for (const c of R.captures || []) {
    const v = c.violations || {};
    for (const x of (v.contrast || []).slice(0, 4)) {
      lines.push(`  🔴 CONTRAST  ${c.route} [${c.viewport}/${c.theme}]  ${x.selector} — ${x.ratio}:1 (needs ${x.required}:1)  "${(x.sample || '').slice(0, 32)}"`);
    }
    for (const x of (v.overflow || []).slice(0, 3)) {
      lines.push(`  🔴 OVERFLOW  ${c.route} [${c.viewport}/${c.theme}]  ${x.selector} — ${x.overflowPx}px past the viewport`);
    }
    for (const x of (v.touchTarget || []).slice(0, 3)) {
      lines.push(`  🔴 TOUCH     ${c.route} [${c.viewport}/${c.theme}]  ${x.selector} — ${x.width}×${x.height} (min 44×44)`);
    }
  }
  console.error('\n⛔ VISUAL QUALITY GATE FAILED — ' + blocking + ' blocking violation(s)\n');
  console.error(lines.slice(0, 20).join('\n'));
  if (lines.length > 20) console.error(`  … and ${lines.length - 20} more`);
  console.error(`
  These are MEASURED, not opinions: a contrast ratio, a pixel overflow, a hit-box size.
  Fix them in the design system or the component — then re-capture:
      node .claude/scripts/ui-capture.js --url <dev-url> --routes <routes> --label <task>

  Screenshots for the same run are next to the report — LOOK at them before deciding
  the fix. A page can pass every number and still be ugly; the numbers only prove it
  is not broken.
`);
  process.exit(1);
}

if (!QUIET) {
  console.log(warn
    ? `   ✓ no blocking violations (${warn} advisory — review the screenshots)\n`
    : '   ✓ clean\n');
}
process.exit(0);
