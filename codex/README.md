# VFM Agent Company — Codex CLI edition

Run the whole VFM Agent Company (CEO · CTO · PM · HR · BA + 34 FAANG/SEO specialists,
BDD-driven sprints) inside **[OpenAI Codex CLI](https://developers.openai.com/codex)** —
not just Claude Code.

`.claude/` stays the **single source of truth**. A generator (`codex/build.py`) converts it
into Codex-native artifacts. You never hand-maintain a parallel copy.

---

## Quick start

```bash
# from the repo root
bash codex/install.sh                 # global  → ~/.codex   (every project sees the company)
bash codex/install.sh --project .     # project → ./.agents/skills + ./AGENTS.md
```

Windows:

```powershell
powershell -ExecutionPolicy Bypass -File codex\install.ps1            # global
powershell -ExecutionPolicy Bypass -File codex\install.ps1 -Project . # project
```

Then, in Codex:

```
/work "Build a task manager with auth and a dashboard"
```

or just say *“start a project”*, *“build me an app”*, *“I found a bug”*.

Uninstall: `bash codex/install.sh --uninstall` (add `--project .` if you installed to a project).

**Requirements:** Python 3 (to build the distribution) and Node.js/npx (only for the optional
SEO MCP servers).

---

## How the port maps Claude Code → Codex

Codex recently gained a **skills** system (`SKILL.md` with `name`/`description` frontmatter,
scanned from `~/.codex/skills` and repo `.agents/skills`) that lines up almost 1:1 with Claude
Code skills. That makes near-full parity possible.

| Plugin component | Claude Code | Codex CLI (this port) |
|---|---|---|
| Instructions | `CLAUDE.md` + `.claude/AGENT.md` | **`AGENTS.md`** operating manual (installed globally/project) |
| Skills (76) | `.claude/skills/*/SKILL.md` | copied ~verbatim → Codex skills |
| Core roles (5) | read, "wear the hat" | bundled in the `work` skill's `references/core/` |
| Specialists (34) | spawned as **parallel subagents** | each → a Codex **skill**; the one agent **adopts the persona, sequentially** |
| `/work` command | a skill | a Codex skill (`work`) — the orchestration entrypoint |
| SEO tools | `.claude/extensions/*` (MCP) | `config.toml [mcp_servers.*]` snippet |
| Hooks (mechanical enforcement) | `settings.json` + bash hooks | restated as **mandatory rules** in `AGENTS.md` |

### The one real trade-off: no parallelism

Codex is a **single agent**. The company's PM normally spawns several specialists at once.
In Codex that becomes **sequential persona-switching**: the PM adopts one specialist skill,
finishes the task, drops the persona, and moves to the next. Same process and quality gates —
just serialized. The PM dispatch/completion tables are kept as a record (model column = `codex`).

Two things also become *discipline* instead of *machinery*:

- **Enforcement** — hooks that mechanically blocked bad states in Claude Code are re-expressed
  as non-negotiable rules in `AGENTS.md` (role indicators, PM-never-codes, code under `app/`,
  BDD-before-dev, 4-batch flow, quality gates).
- **Automation scripts** (`init-project.sh`, `create-sprint.sh`, `validate-gate.sh`,
  `sync-pm-tracker.sh`, …) are bundled inside the `work` skill's `scripts/`. Codex can run them;
  if a script's path assumptions don't fit, do the step manually and keep the same artifacts.

---

## What the installer does

1. **Builds** `codex/dist/` if missing (`python3 codex/build.py`).
2. **Skills** → copies all 110 skill folders to the target skills dir. Tracked in a manifest
   (`.vfm-company-manifest`) so a reinstall cleans stale VFM skills only — your other skills
   are untouched.
3. **AGENTS.md** → inserts the operating manual between clearly-marked
   `>>> VFM-AGENT-COMPANY >>> … <<<` markers. If the file exists, your content is preserved and
   the managed block is updated in place (idempotent).
4. **MCP** → writes `config.toml.vfm-mcp-snippet` next to `config.toml`. **It never edits your
   `config.toml`.** Add your API keys and paste the blocks you want.

Install targets:

| Mode | Skills | Manual | MCP snippet |
|------|--------|--------|-------------|
| `--global` (default) | `~/.codex/skills/` | `~/.codex/AGENTS.md` | `~/.codex/config.toml.vfm-mcp-snippet` |
| `--project [DIR]` | `DIR/.agents/skills/` | `DIR/AGENTS.md` | `DIR/.codex/config.toml.vfm-mcp-snippet` |

Override the Codex home with `CODEX_HOME=/path bash codex/install.sh`.

---

## SEO division (optional MCP servers)

The SEO specialists use MCP servers. After install, open the snippet, fill in keys, and paste
the blocks into your `config.toml`:

| Server | Package | Keys |
|--------|---------|------|
| `dataforseo` | `dataforseo-mcp-server` | `DATAFORSEO_USERNAME`, `DATAFORSEO_PASSWORD` |
| `ahrefs` | `@ahrefs/mcp` | `AHREFS_API_TOKEN` |
| `firecrawl-mcp` | `firecrawl-mcp` | `FIRECRAWL_API_KEY` |
| `nanobanana-mcp` | `@ycse/nanobanana-mcp` | `GOOGLE_AI_API_KEY` |

Docs: <https://developers.openai.com/codex/mcp>

---

## Rebuilding after you change the sources

Edit anything under `.claude/` (roles, skills, specialists), then:

```bash
python3 codex/build.py      # regenerates codex/dist/
bash codex/install.sh       # reinstall (idempotent)
```

`codex/dist/` is generated output and is **git-ignored** — the installer rebuilds it.

## Layout

```
codex/
├── build.py                 # generator: .claude/ → codex/dist/
├── install.sh / install.ps1 # installers (global | project | uninstall)
├── templates/               # hand-authored Codex pieces the generator assembles
│   ├── AGENTS.md            #   operating manual (single-agent model + rules)
│   ├── work-SKILL.md        #   /work entrypoint skill
│   └── mcp-servers.toml     #   SEO MCP snippet
└── dist/                    # GENERATED (git-ignored): AGENTS.md, config/, skills/**, MANIFEST.txt
```

## Known considerations

- Codex recommends `SKILL.md` bodies under ~4 KB for most reliable auto-loading. A few
  specialist skills are larger; they still load, and detailed material already lives in
  `references/` (progressive disclosure). Explicit invocation always works.
- The `company` dashboard skill and some Claude-specific automation assume Claude Code;
  they are included for parity but may be no-ops under Codex.
- No parallel execution (see the trade-off above).
