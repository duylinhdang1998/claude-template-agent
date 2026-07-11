#!/usr/bin/env bash
# ============================================================================
# VFM Agent Company — Codex CLI installer
# ============================================================================
# Installs the company (skills + AGENTS.md operating manual + MCP snippet) so it
# works inside OpenAI Codex CLI.
#
# Usage:
#   bash codex/install.sh                 # global install → ~/.codex (all projects)
#   bash codex/install.sh --project [DIR] # project install → DIR/.agents/skills + DIR/AGENTS.md
#   bash codex/install.sh --uninstall     # remove skills installed by a previous run
#
# Env:
#   CODEX_HOME   override Codex home (default: ~/.codex)
#
# Safe by design:
#   • Skills tracked in a manifest; reinstall cleans stale VFM skills only.
#   • AGENTS.md is merged between markers (your own content is preserved).
#   • config.toml is NEVER modified — the MCP snippet is written next to it.
# ============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DIST="$SCRIPT_DIR/dist"
CODEX_HOME="${CODEX_HOME:-$HOME/.codex}"
MODE="global"
PROJECT_DIR=""
UNINSTALL=0

MARK_START="<!-- >>> VFM-AGENT-COMPANY (Codex) — managed block, do not edit inside >>> -->"
MARK_END="<!-- <<< VFM-AGENT-COMPANY (Codex) <<< -->"
MANIFEST_NAME=".vfm-company-manifest"

while [ $# -gt 0 ]; do
  case "$1" in
    --project) MODE="project"; shift; if [ $# -gt 0 ] && [ "${1#--}" = "$1" ]; then PROJECT_DIR="$1"; shift; fi ;;
    --global)  MODE="global"; shift ;;
    --uninstall) UNINSTALL=1; shift ;;
    -h|--help) sed -n '2,24p' "$0"; exit 0 ;;
    *) echo "Unknown arg: $1"; exit 1 ;;
  esac
done

# --- resolve destinations ----------------------------------------------------
if [ "$MODE" = "project" ]; then
  PROJECT_DIR="${PROJECT_DIR:-$PWD}"
  SKILLS_DEST="$PROJECT_DIR/.agents/skills"
  AGENTS_DEST="$PROJECT_DIR/AGENTS.md"
  CONFIG_DIR="$PROJECT_DIR/.codex"
  LABEL="project ($PROJECT_DIR)"
else
  SKILLS_DEST="$CODEX_HOME/skills"
  AGENTS_DEST="$CODEX_HOME/AGENTS.md"
  CONFIG_DIR="$CODEX_HOME"
  LABEL="global ($CODEX_HOME)"
fi
MANIFEST="$SKILLS_DEST/$MANIFEST_NAME"

# --- helper: remove skills from a previous install --------------------------
clean_previous() {
  if [ -f "$MANIFEST" ]; then
    while IFS= read -r sk; do
      [ -n "$sk" ] || continue
      rm -rf "$SKILLS_DEST/$sk"
    done < "$MANIFEST"
    rm -f "$MANIFEST"
  fi
}

# --- uninstall ---------------------------------------------------------------
if [ "$UNINSTALL" -eq 1 ]; then
  echo "→ Uninstalling VFM Agent Company (Codex) from $LABEL"
  clean_previous
  if [ -f "$AGENTS_DEST" ]; then
    tmp="$(mktemp)"
    awk -v s="$MARK_START" -v e="$MARK_END" '
      $0==s{skip=1; next} $0==e{skip=0; next} skip!=1{print}
    ' "$AGENTS_DEST" > "$tmp"
    # drop trailing blank lines
    awk 'NF{blank=0; buf[NR]=$0; last=NR; next}{blank++; buf[NR]=$0}
         END{for(i=1;i<=last;i++)print buf[i]}' "$tmp" > "$AGENTS_DEST" || cp "$tmp" "$AGENTS_DEST"
    rm -f "$tmp"
    echo "  ✓ removed managed block from $AGENTS_DEST"
  fi
  echo "✓ Uninstalled. (config.toml MCP entries, if any, were left untouched.)"
  exit 0
fi

# --- ensure dist exists (build if needed) -----------------------------------
if [ ! -d "$DIST/skills" ]; then
  echo "→ dist/ missing — building from .claude/ …"
  command -v python3 >/dev/null 2>&1 || { echo "✗ python3 required to build. Install Python 3, then re-run."; exit 1; }
  python3 "$SCRIPT_DIR/build.py"
fi

echo "════════════════════════════════════════════════════════════"
echo "  VFM Agent Company → Codex CLI"
echo "  Install target: $LABEL"
echo "════════════════════════════════════════════════════════════"

# --- 1. skills ---------------------------------------------------------------
echo "→ Installing skills …"
clean_previous
mkdir -p "$SKILLS_DEST"
count=0
: > "$MANIFEST"
for d in "$DIST/skills"/*/; do
  name="$(basename "$d")"
  rm -rf "$SKILLS_DEST/$name"
  cp -R "$d" "$SKILLS_DEST/$name"
  echo "$name" >> "$MANIFEST"
  count=$((count+1))
done
echo "  ✓ $count skills → $SKILLS_DEST"

# --- 2. AGENTS.md (merge between markers) ------------------------------------
echo "→ Installing operating manual (AGENTS.md) …"
mkdir -p "$(dirname "$AGENTS_DEST")"
CONTENT="$(cat "$DIST/AGENTS.md")"
BLOCK="$MARK_START
$CONTENT
$MARK_END"

if [ ! -f "$AGENTS_DEST" ]; then
  printf '%s\n' "$BLOCK" > "$AGENTS_DEST"
  echo "  ✓ created $AGENTS_DEST"
elif grep -qF "$MARK_START" "$AGENTS_DEST"; then
  tmp="$(mktemp)"
  awk -v s="$MARK_START" -v e="$MARK_END" -v block="$BLOCK" '
    $0==s{print block; skip=1; next} $0==e{skip=0; next} skip!=1{print}
  ' "$AGENTS_DEST" > "$tmp" && mv "$tmp" "$AGENTS_DEST"
  echo "  ✓ updated managed block in $AGENTS_DEST"
else
  { printf '\n'; printf '%s\n' "$BLOCK"; } >> "$AGENTS_DEST"
  echo "  ✓ appended managed block to $AGENTS_DEST (your existing content kept)"
fi

# --- 3. MCP snippet (never edits config.toml) --------------------------------
echo "→ Writing SEO MCP snippet …"
mkdir -p "$CONFIG_DIR"
SNIPPET_DEST="$CONFIG_DIR/config.toml.vfm-mcp-snippet"
cp "$DIST/config/mcp-servers.toml" "$SNIPPET_DEST"
echo "  ✓ $SNIPPET_DEST"

echo ""
echo "════════════════════════════════════════════════════════════"
echo "  ✅ Installed."
echo "════════════════════════════════════════════════════════════"
echo ""
echo "  Start Codex and run:   /work \"Build a task manager app\""
echo "  or just say:           \"start a project\" / \"I found a bug\""
echo ""
echo "  SEO MCP servers (optional): open"
echo "    $SNIPPET_DEST"
echo "  add your API keys, and paste the [mcp_servers.*] blocks into"
echo "    $CONFIG_DIR/config.toml"
echo ""
echo "  Uninstall later:  bash codex/install.sh${MODE:+ --$MODE} --uninstall"
echo ""
