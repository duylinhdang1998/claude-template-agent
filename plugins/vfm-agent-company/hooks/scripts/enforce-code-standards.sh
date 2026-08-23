#!/bin/bash
# enforce-code-standards.sh — PostToolUse(Write|Edit)
# HARD GATE for two code standards, frontend AND backend:
#   A. File size — helpers/code-quality.md: max 300 lines per file (.ts/.tsx/.js/.jsx).
#      "No new violations" policy: a file that was ALREADY over the limit before this
#      change is only warned about (and only while it is not growing), so legacy files
#      stay editable and can be split incrementally. A new file over the limit, or an
#      over-limit file that grew, is BLOCKED.
#   B. One component per file (.tsx/.jsx only) — 2+ components blocks.
# Exit 2 puts the violation on stderr and the agent must fix it before continuing.
# Heuristic-based (no parser dependency) and conservative to avoid false blocks.

INPUT=$(cat)
FILE=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null)
[ -z "$FILE" ] && FILE=$(echo "$INPUT" | grep -o '"file_path":"[^"]*"' | head -1 | cut -d'"' -f4)
[ -z "$FILE" ] && exit 0

case "$FILE" in
  *.tsx|*.jsx|*.ts|*.js|*.mjs|*.cjs) ;;
  *) exit 0 ;;
esac
case "$FILE" in
  *node_modules*|*.d.ts|*.test.*|*.spec.*|*.stories.*|*/__tests__/*|*/__mocks__/*) exit 0 ;;
  */migrations/*|*/seed*|*.config.*|*/generated/*) exit 0 ;;
esac
[ -f "$FILE" ] || exit 0

##############################################################################
# A. FILE SIZE — max 300 lines (helpers/code-quality.md, one threshold)
#    Policy: no NEW violations. Legacy files may be edited while shrinking.
##############################################################################
MAX_LINES=300
CUR=$(wc -l < "$FILE" | tr -d " ")

if [ "$CUR" -gt "$MAX_LINES" ]; then
  # previous size at HEAD; 0 if the file is new / not tracked / not a git repo
  PREV=0
  if REL=$(git ls-files --full-name --error-unmatch "$FILE" 2>/dev/null); then
    PREV=$(git show "HEAD:$REL" 2>/dev/null | wc -l | tr -d " ")
    [ -z "$PREV" ] && PREV=0
  fi

  if [ "$PREV" -gt "$MAX_LINES" ] && [ "$CUR" -le "$PREV" ]; then
    echo "🟡 code-quality: $FILE is $CUR lines (limit $MAX_LINES) — pre-existing violation, not growing." >&2
    echo "   Allowed to proceed. It stays on the burn-down list until it is split." >&2
  else
    {
      echo "🔴 CODE STANDARD VIOLATION — file size."
      echo "File: $FILE"
      echo "Lines: $CUR (limit: $MAX_LINES$([ "$PREV" -gt 0 ] && echo ", was $PREV before this change"))"
      echo ""
      echo "helpers/code-quality.md: 1 file = 1 responsibility, max $MAX_LINES lines."
      echo "Split it NOW, before continuing:"
      echo "  - constants / option arrays / label maps  → <name>Constants.ts"
      echo "  - pure helpers                            → <name>Utils.ts (or lib/)"
      echo "  - stateful logic                          → hooks/use<Name>.ts"
      echo "  - each sub-view / sub-component           → its own file"
      echo "Before creating any of those, grep for an existing one (by identifier AND by a"
      echo "literal from its body) — do not add a second copy of something that exists."
    } >&2
    exit 2
  fi
fi

##############################################################################
# B. ONE COMPONENT PER FILE — React files only
##############################################################################
case "$FILE" in
  *.tsx|*.jsx) ;;
  *) exit 0 ;;
esac
command -v python3 >/dev/null 2>&1 || exit 0

RESULT=$(python3 - "$FILE" <<'PY'
import re, sys
try:
    src = open(sys.argv[1], encoding="utf-8").read()
except Exception:
    sys.exit(0)

names = []
# function Name(  /  export default function Name(
for m in re.finditer(r'\b(?:export\s+default\s+)?function\s+([A-Z]\w*)\s*\(', src):
    names.append(m.group(1))
# const Name = (...) => | const Name: FC = () => | React.memo(/forwardRef(/function
for m in re.finditer(
    r'\bconst\s+([A-Z]\w*)\s*(?::[^=\n]+)?=\s*'
    r'(?:React\.)?(?:memo\(|forwardRef\(|\([^)]*\)\s*(?::[^=>\n]+)?=>|\w+\s*=>|function\b)',
    src):
    names.append(m.group(1))

seen = []
for n in names:
    if n not in seen:
        seen.append(n)

# keep only names whose definition body actually contains JSX (component-like)
comps = []
for n in seen:
    idx = None
    for pat in (rf'function\s+{re.escape(n)}\b', rf'const\s+{re.escape(n)}\b'):
        m = re.search(pat, src)
        if m:
            idx = m.start(); break
    if idx is None:
        continue
    window = src[idx:idx + 1500]
    if re.search(r'return\s*\(?\s*<|=>\s*\(?\s*<|<[A-Za-z][\w.]*[\s/>]', window):
        comps.append(n)

if len(comps) >= 2:
    print("MULTI:" + ",".join(comps))
PY
)

if [[ "$RESULT" == MULTI:* ]]; then
  COMPS="${RESULT#MULTI:}"
  {
    echo "🔴 Frontend Code Standard #1 VIOLATION — one component per file."
    echo "File: $FILE"
    echo "This file defines multiple components: $COMPS"
    echo "Fix now: move each component into its OWN file (filename = component name, PascalCase),"
    echo "then import it. Re-read helpers/code-quality.md → 'Frontend Code Standards' rule #1."
  } >&2
  exit 2
fi
exit 0
