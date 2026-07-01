#!/bin/bash
# enforce-frontend-standards.sh — PostToolUse(Write|Edit)
# HARD GATE for Frontend Code Standard #1: "one component per file".
# Scans a just-written React file (.tsx/.jsx); if it defines 2+ components,
# exits 2 so the agent receives the violation on stderr and must split the file.
# Heuristic-based (no parser dependency) and conservative to avoid false blocks.

INPUT=$(cat)
FILE=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null)
[ -z "$FILE" ] && FILE=$(echo "$INPUT" | grep -o '"file_path":"[^"]*"' | head -1 | cut -d'"' -f4)
[ -z "$FILE" ] && exit 0

case "$FILE" in
  *.tsx|*.jsx) ;;
  *) exit 0 ;;
esac
case "$FILE" in
  *node_modules*|*.test.*|*.spec.*|*.stories.*|*/__tests__/*|*/__mocks__/*) exit 0 ;;
esac
[ -f "$FILE" ] || exit 0
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
