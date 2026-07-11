#!/usr/bin/env python3
"""
VFM Agent Company — Codex build generator
==========================================

Reads the Claude Code plugin sources under `.claude/` (the single source of truth)
and emits a Codex-CLI-compatible distribution under `codex/dist/`:

  codex/dist/
  ├── AGENTS.md                     # company operating manual (single-agent model)
  ├── config/mcp-servers.toml       # SEO MCP servers snippet for config.toml
  ├── MANIFEST.txt                  # what was generated
  └── skills/
      ├── work/                     # /work entrypoint + core roles + automation
      │   ├── SKILL.md
      │   ├── references/core/*.md, references/AGENT.md, references/helpers/*
      │   ├── templates/**          # project/doc templates used by scripts
      │   └── scripts/*.sh          # bundled automation
      ├── <specialist>/SKILL.md     # each .claude/agents/*.md → a Codex skill (persona)
      └── <topic-skill>/**          # each .claude/skills/*/ copied ~verbatim

Codex reads only `name` + `description` from SKILL.md frontmatter, so specialist
frontmatter is rewritten cleanly and the rich Claude frontmatter (model/tools/…) is
dropped (its useful bits are surfaced in the body instead).

Run:  python3 codex/build.py
No third-party dependencies (stdlib only).
"""
from __future__ import annotations
import os
import re
import shutil
import sys

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(SCRIPT_DIR)
SRC = os.path.join(REPO, ".claude")
TPL = os.path.join(SCRIPT_DIR, "templates")
OUT = os.path.join(SCRIPT_DIR, "dist")

AGENTS_SRC = os.path.join(SRC, "agents")
SKILLS_SRC = os.path.join(SRC, "skills")
CORE_SRC = os.path.join(SRC, "core")
HELPERS_SRC = os.path.join(SRC, "helpers")
TEMPLATES_SRC = os.path.join(SRC, "templates")
AUTOMATION_SRC = os.path.join(SRC, "automation")


def die(msg: str) -> None:
    print(f"✗ {msg}", file=sys.stderr)
    sys.exit(1)


def parse_frontmatter(text: str):
    """Return (frontmatter_dict_minimal, body). Only extracts `name` and `description`,
    handling YAML block scalars (| or >) and plain/quoted inline values.
    """
    if not text.startswith("---"):
        return {}, text
    m = re.match(r"^---\s*\n(.*?)\n---\s*\n?(.*)$", text, re.DOTALL)
    if not m:
        return {}, text
    fm_raw, body = m.group(1), m.group(2)
    lines = fm_raw.split("\n")
    fm = {}
    i = 0
    while i < len(lines):
        line = lines[i]
        km = re.match(r"^([A-Za-z0-9_-]+):\s*(.*)$", line)
        if km and (km.group(1) in ("name", "description")):
            key, val = km.group(1), km.group(2).strip()
            if val in ("|", ">", "|-", ">-", "|+", ">+", ""):
                # block scalar / empty → gather deeper-indented following lines
                block = []
                i += 1
                while i < len(lines):
                    nxt = lines[i]
                    if nxt.strip() == "":
                        block.append("")
                        i += 1
                        continue
                    if re.match(r"^\s+", nxt):  # indented → part of block
                        block.append(nxt.strip())
                        i += 1
                    else:
                        break
                collapsed = " ".join(x for x in block if x != "").strip()
                fm[key] = re.sub(r"\s+", " ", collapsed)
                continue
            else:
                val = val.strip()
                if (val.startswith('"') and val.endswith('"')) or (
                    val.startswith("'") and val.endswith("'")
                ):
                    val = val[1:-1]
                fm[key] = re.sub(r"\s+", " ", val).strip()
        i += 1
    return fm, body


def toml_escape(s: str) -> str:
    return s.replace("\\", "\\\\").replace('"', '\\"').replace("\n", " ")


def clean_out() -> None:
    if os.path.exists(OUT):
        shutil.rmtree(OUT)
    os.makedirs(os.path.join(OUT, "skills"), exist_ok=True)
    os.makedirs(os.path.join(OUT, "config"), exist_ok=True)


def copy_topic_skills() -> list[str]:
    """Copy .claude/skills/*/ verbatim (they are already Codex-compatible). The `work`
    skill is skipped here — it is authored fresh for Codex."""
    copied = []
    for name in sorted(os.listdir(SKILLS_SRC)):
        d = os.path.join(SKILLS_SRC, name)
        if not os.path.isdir(d):
            continue
        if name == "work":
            continue  # overridden by build_work_skill()
        if not os.path.exists(os.path.join(d, "SKILL.md")):
            print(f"  ⚠  skill '{name}' has no SKILL.md — skipped")
            continue
        shutil.copytree(d, os.path.join(OUT, "skills", name))
        copied.append(name)
    return copied


ADAPT_HEADER = """> **Codex specialist persona.** In Codex you *are* this specialist for the current task —
> there is no separate subagent. Adopt this persona, do the work end-to-end (write code,
> run tests, verify real behavior), then return to the 📋 [PM] hat and report. Work one
> persona at a time (no parallelism). References to spawning, the `Agent`/`Task` tool, or
> `set-active-core.sh` do not apply in Codex — everything runs in *this* session.
"""


def convert_specialists(existing: set[str]) -> list[str]:
    """Convert each .claude/agents/*.md into a Codex skill folder with clean frontmatter."""
    made = []
    for fn in sorted(os.listdir(AGENTS_SRC)):
        if not fn.endswith(".md"):
            continue
        path = os.path.join(AGENTS_SRC, fn)
        with open(path, encoding="utf-8") as f:
            text = f.read()
        fm, body = parse_frontmatter(text)
        name = fm.get("name") or fn[:-3]
        desc = fm.get("description") or f"{name} specialist persona."
        # extra persona flavor from raw frontmatter (agentName), if present
        am = re.search(r"^agentName:\s*(.+)$", text, re.MULTILINE)
        persona = am.group(1).strip() if am else None

        folder = name
        if folder in existing:  # collision with a topic skill → namespace it
            folder = f"agent-{name}"
        existing.add(folder)

        out_dir = os.path.join(OUT, "skills", folder)
        os.makedirs(out_dir, exist_ok=True)

        intro = f"# {name}\n\n"
        if persona:
            intro += f"**Persona:** {persona} · **Specialist skill (Codex):** `{folder}`\n\n"
        skill_md = (
            f"---\nname: {folder}\ndescription: >-\n  {desc}\n---\n\n"
            f"{intro}{ADAPT_HEADER}\n---\n\n{body.strip()}\n"
        )
        with open(os.path.join(out_dir, "SKILL.md"), "w", encoding="utf-8") as f:
            f.write(skill_md)
        made.append(folder)
    return made


def build_work_skill() -> None:
    """Author the /work entrypoint skill and bundle core roles, helpers, templates, scripts."""
    wdir = os.path.join(OUT, "skills", "work")
    os.makedirs(wdir, exist_ok=True)
    # SKILL.md from template
    shutil.copy(os.path.join(TPL, "work-SKILL.md"), os.path.join(wdir, "SKILL.md"))
    # references: core roles + AGENT.md + helpers
    ref_core = os.path.join(wdir, "references", "core")
    os.makedirs(ref_core, exist_ok=True)
    for fn in sorted(os.listdir(CORE_SRC)):
        if fn.endswith(".md"):
            shutil.copy(os.path.join(CORE_SRC, fn), os.path.join(ref_core, fn))
    agent_md = os.path.join(SRC, "AGENT.md")
    if os.path.exists(agent_md):
        shutil.copy(agent_md, os.path.join(wdir, "references", "AGENT.md"))
    if os.path.isdir(HELPERS_SRC):
        shutil.copytree(HELPERS_SRC, os.path.join(wdir, "references", "helpers"))
    # templates + automation scripts (optional helpers for faithful sprint machinery)
    if os.path.isdir(TEMPLATES_SRC):
        shutil.copytree(TEMPLATES_SRC, os.path.join(wdir, "templates"))
    if os.path.isdir(AUTOMATION_SRC):
        sdir = os.path.join(wdir, "scripts")
        os.makedirs(sdir, exist_ok=True)
        for fn in sorted(os.listdir(AUTOMATION_SRC)):
            if fn.endswith(".sh"):
                dst = os.path.join(sdir, fn)
                shutil.copy(os.path.join(AUTOMATION_SRC, fn), dst)
                os.chmod(dst, 0o755)


def write_static() -> None:
    shutil.copy(os.path.join(TPL, "AGENTS.md"), os.path.join(OUT, "AGENTS.md"))
    shutil.copy(
        os.path.join(TPL, "mcp-servers.toml"),
        os.path.join(OUT, "config", "mcp-servers.toml"),
    )


def main() -> None:
    for p in (SRC, AGENTS_SRC, SKILLS_SRC, CORE_SRC):
        if not os.path.isdir(p):
            die(f"source not found: {p}")
    print("VFM Agent Company → Codex build")
    print(f"  source : {SRC}")
    print(f"  output : {OUT}\n")
    clean_out()
    topic = copy_topic_skills()
    print(f"  ✓ topic skills copied      : {len(topic)}")
    existing = set(topic) | {"work"}
    specialists = convert_specialists(existing)
    print(f"  ✓ specialists → skills     : {len(specialists)}")
    build_work_skill()
    print("  ✓ work skill (roles+scripts): 1")
    write_static()
    print("  ✓ AGENTS.md + mcp-servers.toml")

    total_skills = len(
        [
            d
            for d in os.listdir(os.path.join(OUT, "skills"))
            if os.path.isdir(os.path.join(OUT, "skills", d))
        ]
    )
    with open(os.path.join(OUT, "MANIFEST.txt"), "w", encoding="utf-8") as f:
        f.write("VFM Agent Company — Codex distribution\n")
        f.write("Generated by codex/build.py from .claude/ (do not edit dist/ by hand)\n\n")
        f.write(f"topic skills : {len(topic)}\n")
        f.write(f"specialists  : {len(specialists)}\n")
        f.write(f"work skill   : 1\n")
        f.write(f"total skills : {total_skills}\n\n")
        f.write("specialists:\n")
        for s in sorted(specialists):
            f.write(f"  - {s}\n")
        f.write("\ntopic skills:\n")
        for s in sorted(topic):
            f.write(f"  - {s}\n")
    print(f"\n✓ done — {total_skills} skills total in {OUT}/skills")


if __name__ == "__main__":
    main()
