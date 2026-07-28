#!/bin/bash
# Hook: UserPromptSubmit
# License gate — locks the plugin's entry point (/work) until this machine has
# a valid install token. Non-/work prompts pass untouched, so the rest of the
# user's Claude Code session is never affected.
#
# Activated = $VFM_INSTALL_TOKEN (or ~/.vfm-agent-company/license) matches the
# committed license.hash. See license.py.

INPUT=$(cat)
if command -v jq &>/dev/null; then
    PROMPT=$(echo "$INPUT" | jq -r '.prompt // empty' 2>/dev/null)
else
    PROMPT=$(echo "$INPUT" | grep -o '"prompt":"[^"]*"' | head -1 | cut -d'"' -f4)
fi
PROMPT_LOWER=$(echo "$PROMPT" | tr '[:upper:]' '[:lower:]')

# Only guard the plugin entry point.
case "$PROMPT_LOWER" in
    *"/work"*) ;;      # fall through → check the license
    *) exit 0 ;;       # anything else → don't interfere
esac

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PY="$(command -v python3 || command -v python || true)"

if [ -n "$PY" ] && "$PY" "$DIR/license.py" check >/dev/null 2>&1; then
    exit 0   # activated → allow /work
fi

# Not activated → block the prompt. Exit code 2 shows stderr to the user and
# stops the prompt from being processed.
{
    echo "🔒 VFM Agent Company chưa được kích hoạt trên máy này."
    echo "   Cần token cài đặt hợp lệ mới chạy được /work."
    echo "   Kích hoạt bằng một trong hai cách:"
    echo "     • export VFM_INSTALL_TOKEN=<token>   rồi mở lại phiên Claude Code"
    echo "     • python3 \"$DIR/license.py\" activate   (lưu token vào máy)"
} >&2
exit 2
