#!/bin/bash
##############################################################################
# enforce-design-tokens.sh — PostToolUse(Write|Edit)
#
# HARD GATE for Frontend Rule #2 (follow the project design system).
#
# Until this hook existed, `helpers/code-quality.md` listed Rule #2's enforcement
# as "Review — (only layer)": an LLM judging source code it never rendered. The
# same file warns what happens to a prose-only standard — it gets re-argued at
# every review until it silently stops existing. This is the mechanical half.
#
# Checks (against the PROJECT'S OWN tokens — nothing hardcoded):
#   C1 color literal not in the token set
#   C2 corner radius off the radius scale
#   C3 font-size off the type scale / font-family not declared
#   C4 padding|margin|gap off the spacing scale
#
# FAILS OPEN by design: a project with no design system has no contract to
# enforce, so the hook exits 0 silently. A gate that blocks opted-out projects
# gets switched off, and a gate that is off is worse than none — it still reads
# as covered.
#
# Exit 2 = blocked; the violation goes to stderr and the agent must fix it.
##############################################################################

INPUT=$(cat)

# --- file path (jq with grep fallback, same convention as sibling hooks) -----
if command -v jq &>/dev/null; then
  FILE=$(echo "$INPUT" | jq -r '.tool_input.file_path // .file_path // empty' 2>/dev/null)
else
  FILE=$(echo "$INPUT" | grep -o '"file_path":"[^"]*"' | head -1 | cut -d'"' -f4)
fi
[ -z "$FILE" ] && exit 0
[ -f "$FILE" ] || exit 0

# --- only UI-bearing files --------------------------------------------------
# Native/cross-platform sources are included so a native project is not silently
# ungated. The checker itself decides what it can actually verify per language
# (C1 colour everywhere; C2-C4 are CSS/utility-class syntax, web only).
case "$FILE" in
  *.tsx|*.jsx|*.ts|*.js|*.css|*.scss|*.sass|*.less|*.vue|*.svelte|*.astro) ;;
  *.swift|*.kt|*.kts|*.dart) ;;
  *) exit 0 ;;
esac

command -v node &>/dev/null || exit 0   # no Node → cannot check; never break the session

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# ROOT_DIR is the USER'S project (where .project/ lives). SCRIPTS is where THIS
# framework's copy of the checkers lives — the two are the same tree in the
# `.claude/` runtime and different trees when installed as a plugin, so resolve
# them independently. Layouts: .claude/{hooks,scripts}/ · plugin hooks/scripts/ + scripts/
ROOT_DIR="${CLAUDE_PROJECT_DIR:-$(cd "$SCRIPT_DIR/../.." && pwd)}"
SCRIPTS=""
for cand in "$SCRIPT_DIR/../scripts" "$SCRIPT_DIR/../../scripts" "$ROOT_DIR/.claude/scripts"; do
  [ -f "$cand/check-design-tokens.js" ] && { SCRIPTS="$(cd "$cand" && pwd)"; break; }
done
[ -n "$SCRIPTS" ] || exit 0

# --- locate the design system (same candidate order as the inject hook) -----
DS_MD=""
for c in \
  "$ROOT_DIR/.project/design-system.md" \
  "$ROOT_DIR/.project/design/design-system.md" \
  "$ROOT_DIR/.project/documentation/design-system.md" \
  "$ROOT_DIR/.project/wireframes/design-system.md" \
  "$ROOT_DIR/design-system.md" \
  "$ROOT_DIR/DESIGN.md" \
  "$ROOT_DIR/references/DESIGN.md"
do
  [ -f "$c" ] && { DS_MD="$c"; break; }
done
[ -z "$DS_MD" ] && exit 0            # no design system → nothing to enforce

DS_JSON="$(dirname "$DS_MD")/design-system.json"

# --- keep the artifact in step with its source ------------------------------
# The markdown is what humans edit; the JSON is what machines read. If the JSON
# is missing or older than the markdown, it is regenerated here so the gate can
# never be evaded (or accidentally weakened) by editing tokens and not rebuilding.
if [ ! -f "$DS_JSON" ] || [ "$DS_MD" -nt "$DS_JSON" ]; then
  node "$SCRIPTS/build-styles-json.js" --in "$DS_MD" --out "$DS_JSON" --quiet 2>/dev/null || exit 0
fi

OUTPUT=$(node "$SCRIPTS/check-design-tokens.js" "$FILE" --tokens "$DS_JSON" --quiet 2>&1)
STATUS=$?

if [ "$STATUS" -eq 2 ]; then
  echo "$OUTPUT" >&2
  exit 2
fi
exit 0
