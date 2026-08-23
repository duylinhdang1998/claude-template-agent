#!/bin/bash
# validate-schema.sh — PostToolUse(Write|Edit) wrapper
# The plugin registry calls validate-schema.py through run-python-hook.js using
# ${tool_input.file_path} templating. settings.json hooks receive the payload on
# stdin instead, so this wrapper extracts the path the same way the other
# .claude/hooks/* scripts do and forwards it. Keeps both registries equivalent.

INPUT=$(cat)
if command -v jq >/dev/null 2>&1; then
  FILE=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null)
fi
[ -z "$FILE" ] && FILE=$(echo "$INPUT" | grep -o '"file_path":"[^"]*"' | head -1 | cut -d'"' -f4)
[ -z "$FILE" ] && exit 0
[ -f "$FILE" ] || exit 0

DIR="$(cd "$(dirname "$0")" && pwd)"
command -v node >/dev/null 2>&1 || exit 0
exec node "$DIR/run-python-hook.js" "$DIR/validate-schema.py" "$FILE"
