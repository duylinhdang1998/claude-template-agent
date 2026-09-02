#!/usr/bin/env node
/**
 * ui-capture.js — render the UI, photograph it, and MEASURE the things that
 * separate a professional interface from an amateur one.
 *
 * WHY THIS EXISTS
 *   Token checks prove a UI is CONSISTENT. They cannot prove it is any good, because
 *   they never look at the rendered result. Meanwhile `google-code-reviewer` judges UI
 *   from source code and has never seen a pixel. This script closes both gaps: it
 *   produces (a) screenshots the reviewer can actually READ, and (b) a report of the
 *   craft failures that are objectively measurable from a live DOM.
 *
 * MEASURED (not judged) — every one of these is a number, not an opinion:
 *   V1 contrast     text/background pairs below the WCAG AA ratio for their size
 *   V2 overflow     content wider than the viewport (the #1 mobile defect)
 *   V3 touchTarget  interactive elements under 44×44 CSS px (mobile viewport only)
 *   V4 tinyText     rendered font-size below 12px
 *   V5 lineLength   body copy over 95 characters per line
 *
 * USAGE
 *   node ui-capture.js --url http://localhost:3000 [--routes / /login /dashboard]
 *                      [--out .project/screenshots/<label>] [--label task-1.2]
 *                      [--viewports 390x844,768x1024,1440x900] [--themes light,dark]
 *                      [--full-page] [--timeout 15000]
 *
 * EXIT CODES
 *   0 captured (read the report for violations) · 2 could not reach the URL
 *   3 Playwright unavailable — the agent must fall back to the Playwright MCP tools
 *     and write the SAME report shape by hand (schema printed on exit 3)
 */

'use strict';
const fs = require('fs');
const path = require('path');

const ROOT = process.env.CLAUDE_PROJECT_DIR || process.cwd();
const argv = process.argv.slice(2);
const flag = (f, d) => { const i = argv.indexOf(f); return i > -1 && argv[i + 1] && !argv[i + 1].startsWith('--') ? argv[i + 1] : d; };
const list = (f, d) => { // --routes / /a /b   (consumes until the next --flag)
  const i = argv.indexOf(f); if (i === -1) return d;
  const out = []; for (let j = i + 1; j < argv.length && !argv[j].startsWith('--'); j++) out.push(argv[j]);
  return out.length ? out : d;
};

const BASE = flag('--url', 'http://localhost:3000').replace(/\/$/, '');
const ROUTES = list('--routes', ['/']);
const LABEL = flag('--label', new Date().toISOString().slice(0, 16).replace(/[:T]/g, '-'));
const OUT = path.resolve(ROOT, flag('--out', path.join('.project', 'screenshots', LABEL)));
const VIEWPORTS = flag('--viewports', '390x844,768x1024,1440x900').split(',').map((v) => {
  const [w, h] = v.trim().split('x').map(Number); return { name: v.trim(), width: w, height: h };
});
const THEMES = flag('--themes', 'light,dark').split(',').map((s) => s.trim());
const TIMEOUT = Number(flag('--timeout', '15000'));
const FULL = argv.includes('--full-page');

const REPORT_SCHEMA = `{
  "$schema": "vfm-visual-report/1",
  "generatedAt": "<ISO>", "baseUrl": "<url>", "label": "<task label>",
  "captures": [{
    "route": "/", "viewport": "390x844", "theme": "light", "screenshot": "<relative path>",
    "violations": {
      "contrast":    [{ "selector": "", "ratio": 0, "required": 4.5, "color": "", "background": "", "sample": "" }],
      "overflow":    [{ "selector": "", "overflowPx": 0 }],
      "touchTarget": [{ "selector": "", "width": 0, "height": 0 }],
      "tinyText":    [{ "selector": "", "fontSize": 0 }],
      "lineLength":  [{ "selector": "", "chars": 0 }]
    }
  }],
  "summary": { "contrast": 0, "overflow": 0, "touchTarget": 0, "tinyText": 0, "lineLength": 0, "blocking": 0 }
}`;

let chromium;
try { ({ chromium } = require('playwright')); }
catch {
  console.error(`✗ Playwright is not installed in this project.

  Either install it:      npm i -D playwright && npx playwright install chromium
  Or drive the browser with the Playwright MCP tools and write the report yourself.

  Whatever route you take, the artifact contract is the same — the gate and the
  reviewer both read this file, so it MUST exist at
  <out>/visual-report.json with this shape:

${REPORT_SCHEMA}
`);
  process.exit(3);
}

// ── the in-page measurement pass (runs in the browser, not in Node) ─────────
function measure({ isMobile, vpWidth }) {
  // vpWidth is the viewport we ASKED for. Never trust window.innerWidth here: under
  // mobile emulation Chrome expands the layout viewport to fit overflowing content
  // (390 → 916 on a page with a 900px child), so comparing against it makes the
  // overflow check silently always-pass — the exact defect it exists to catch.
  const sel = (el) => {
    if (el.id) return '#' + el.id;
    const cls = (el.className && typeof el.className === 'string' ? el.className.trim().split(/\s+/).slice(0, 2).join('.') : '');
    return el.tagName.toLowerCase() + (cls ? '.' + cls : '');
  };
  const parse = (c) => {
    const m = String(c).match(/rgba?\(([\d.]+)[,\s]+([\d.]+)[,\s]+([\d.]+)(?:[,\s/]+([\d.]+))?/);
    return m ? { r: +m[1], g: +m[2], b: +m[3], a: m[4] === undefined ? 1 : +m[4] } : null;
  };
  const lum = ({ r, g, b }) => {
    const f = (v) => { v /= 255; return v <= 0.03928 ? v / 12.92 : Math.pow((v + 0.055) / 1.055, 2.4); };
    return 0.2126 * f(r) + 0.7152 * f(g) + 0.0722 * f(b);
  };
  const over = (fg, bg) => ({ // composite a translucent foreground onto its background
    r: fg.r * fg.a + bg.r * (1 - fg.a), g: fg.g * fg.a + bg.g * (1 - fg.a), b: fg.b * fg.a + bg.b * (1 - fg.a), a: 1,
  });
  const bgOf = (el) => {
    let n = el;
    while (n && n !== document.documentElement) {
      const c = parse(getComputedStyle(n).backgroundColor);
      if (c && c.a > 0.9) return c;
      n = n.parentElement;
    }
    const c = parse(getComputedStyle(document.body).backgroundColor);
    return c && c.a > 0.9 ? c : { r: 255, g: 255, b: 255, a: 1 };
  };
  const ratio = (a, b) => { const [x, y] = [lum(a), lum(b)].sort((p, q) => q - p); return (x + 0.05) / (y + 0.05); };
  const visible = (el) => {
    const s = getComputedStyle(el); const r = el.getBoundingClientRect();
    return s.display !== 'none' && s.visibility !== 'hidden' && +s.opacity > 0.1 && r.width > 0 && r.height > 0;
  };

  const V = { contrast: [], overflow: [], touchTarget: [], tinyText: [], lineLength: [] };
  const seen = new Set();

  for (const el of document.querySelectorAll('body *')) {
    if (!visible(el)) continue;
    const s = getComputedStyle(el);
    const text = [...el.childNodes].filter((n) => n.nodeType === 3).map((n) => n.textContent.trim()).join(' ').trim();

    if (text.length > 1) {
      const size = parseFloat(s.fontSize);
      const weight = parseInt(s.fontWeight, 10) || 400;
      const fg = parse(s.color); const bg = bgOf(el);
      if (fg) {
        const eff = fg.a < 1 ? over(fg, bg) : fg;
        const large = size >= 24 || (size >= 18.66 && weight >= 700);
        const need = large ? 3 : 4.5;
        const r = ratio(eff, bg);
        const key = 'c' + sel(el) + text.slice(0, 12);
        if (r < need && !seen.has(key)) {
          seen.add(key);
          V.contrast.push({ selector: sel(el), ratio: +r.toFixed(2), required: need, color: s.color, background: `rgb(${Math.round(bg.r)}, ${Math.round(bg.g)}, ${Math.round(bg.b)})`, sample: text.slice(0, 60) });
        }
      }
      if (size < 12) V.tinyText.push({ selector: sel(el), fontSize: +size.toFixed(1) });
      // characters per line ≈ rendered width ÷ average glyph width (0.5em is the usual ratio)
      if (text.length > 80 && /^(p|li|blockquote|div|span)$/i.test(el.tagName)) {
        const chars = Math.round(el.getBoundingClientRect().width / (size * 0.5));
        if (chars > 95) V.lineLength.push({ selector: sel(el), chars });
      }
    }

    const r = el.getBoundingClientRect();
    if (r.right > vpWidth + 1 && r.width > 8) {
      V.overflow.push({ selector: sel(el), overflowPx: Math.round(r.right - vpWidth) });
    }
    if (isMobile && el.matches('a,button,input,select,textarea,[role="button"],[role="link"],[onclick]')) {
      if ((r.width < 44 || r.height < 44) && r.width > 0) {
        V.touchTarget.push({ selector: sel(el), width: Math.round(r.width), height: Math.round(r.height) });
      }
    }
  }
  // cap each list so one broken page cannot produce a megabyte of report
  for (const k of Object.keys(V)) V[k] = V[k].slice(0, 25);
  return V;
}

// ── drive the browser ───────────────────────────────────────────────────────
(async () => {
  fs.mkdirSync(OUT, { recursive: true });
  const report = {
    $schema: 'vfm-visual-report/1', generatedAt: new Date().toISOString(),
    baseUrl: BASE, label: LABEL, captures: [],
    summary: { contrast: 0, overflow: 0, touchTarget: 0, tinyText: 0, lineLength: 0, blocking: 0 },
  };
  const browser = await chromium.launch();
  let reached = false;

  for (const vp of VIEWPORTS) {
    for (const theme of THEMES) {
      const ctx = await browser.newContext({
        viewport: { width: vp.width, height: vp.height },
        colorScheme: theme, deviceScaleFactor: 2,
        isMobile: vp.width < 500, hasTouch: vp.width < 500,
      });
      const page = await ctx.newPage();
      for (const route of ROUTES) {
        const url = BASE + (route.startsWith('/') ? route : '/' + route);
        try {
          await page.goto(url, { waitUntil: 'networkidle', timeout: TIMEOUT });
          reached = true;
        } catch (e) {
          console.error(`  ⚠ ${url} [${vp.name}/${theme}] — ${e.message.split('\n')[0]}`);
          continue;
        }
        await page.waitForTimeout(300); // let entrance animation settle before judging it
        const slug = (route === '/' ? 'index' : route.replace(/[^\w-]+/g, '-').replace(/^-|-$/g, ''));
        const file = `${slug}__${vp.name}__${theme}.png`;
        await page.screenshot({ path: path.join(OUT, file), fullPage: FULL });
        const violations = await page.evaluate(measure, { isMobile: vp.width < 500, vpWidth: vp.width });
        for (const k of Object.keys(report.summary)) {
          if (k !== 'blocking' && violations[k]) report.summary[k] += violations[k].length;
        }
        report.captures.push({ route, viewport: vp.name, theme, screenshot: path.join(path.relative(ROOT, OUT), file), violations });
        console.log(`  ✓ ${route} [${vp.name}/${theme}] → ${file}` +
          `  (contrast ${violations.contrast.length} · overflow ${violations.overflow.length} · touch ${violations.touchTarget.length})`);
      }
      await ctx.close();
    }
  }
  await browser.close();

  if (!reached) {
    console.error(`\n✗ could not load any route at ${BASE} — is the dev server running?`);
    process.exit(2);
  }

  report.summary.blocking = report.summary.contrast + report.summary.overflow + report.summary.touchTarget;
  const rp = path.join(OUT, 'visual-report.json');
  fs.writeFileSync(rp, JSON.stringify(report, null, 2) + '\n');
  console.log(`\n✓ ${report.captures.length} capture(s) → ${path.relative(ROOT, OUT)}`);
  console.log(`✓ report → ${path.relative(ROOT, rp)}  (blocking: ${report.summary.blocking})`);
})().catch((e) => { console.error('✗ ui-capture failed: ' + e.message); process.exit(2); });
