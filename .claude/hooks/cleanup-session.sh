#!/bin/bash
# cleanup-session.sh - Remove session from .active-core on SessionEnd
#
# Called by hooks: SessionEnd, Stop

# Read JSON from stdin
INPUT=$(cat)

# Try multiple field names for session ID
SESSION_ID=""
if command -v jq &>/dev/null; then
    SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // .sessionId // .session // empty' 2>/dev/null)
fi

# Fallback: try env var
if [ -z "$SESSION_ID" ] || [ "$SESSION_ID" = "null" ]; then
    SESSION_ID="${CLAUDE_SESSION_ID:-}"
fi

# Resolve .active-core path
if [ -n "$CLAUDE_PROJECT_DIR" ]; then
    ACTIVE_CORE_FILE="$CLAUDE_PROJECT_DIR/.claude/.active-core"
else
    ACTIVE_CORE_FILE=".claude/.active-core"
fi

# Check if file exists
if [ ! -f "$ACTIVE_CORE_FILE" ]; then
    exit 0
fi

if [ -n "$SESSION_ID" ] && [ "$SESSION_ID" != "null" ]; then
    # Remove specific session line
    if grep -q "^${SESSION_ID}:" "$ACTIVE_CORE_FILE" 2>/dev/null; then
        if [[ "$OSTYPE" == "darwin"* ]]; then
            sed -i '' "/^${SESSION_ID}:/d" "$ACTIVE_CORE_FILE"
        else
            sed -i "/^${SESSION_ID}:/d" "$ACTIVE_CORE_FILE"
        fi
    fi
else
    # No session ID available — clear entire file (session is ending, safe to reset)
    > "$ACTIVE_CORE_FILE"
fi

# Clean up empty lines
if [ -f "$ACTIVE_CORE_FILE" ]; then
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' '/^$/d' "$ACTIVE_CORE_FILE"
    else
        sed -i '/^$/d' "$ACTIVE_CORE_FILE"
    fi
fi

exit 0
