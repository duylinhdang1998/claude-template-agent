#!/bin/bash
# set-active-core.sh - Set or update session's active core role
#
# Usage: set-active-core.sh SESSION_ID ROLE_FILE
# Example: set-active-core.sh abc123 pm.md
#
# Behavior:
# - If session doesn't exist in file → append new line
# - If session exists → update the role (upsert)

SESSION_ID="$1"
ROLE_FILE="$2"

# Validate inputs
if [ -z "$SESSION_ID" ] || [ -z "$ROLE_FILE" ]; then
    echo "Usage: set-active-core.sh SESSION_ID ROLE_FILE"
    exit 1
fi

# Resolve path relative to project directory
if [ -n "$CLAUDE_PROJECT_DIR" ]; then
    ACTIVE_CORE_FILE="$CLAUDE_PROJECT_DIR/.claude/.active-core"
else
    ACTIVE_CORE_FILE=".claude/.active-core"
fi

# Create file if it doesn't exist
touch "$ACTIVE_CORE_FILE"

# Check if session already exists in file
if grep -q "^${SESSION_ID}:" "$ACTIVE_CORE_FILE" 2>/dev/null; then
    # Update existing session's role (macOS compatible sed)
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "s/^${SESSION_ID}:.*/${SESSION_ID}: ${ROLE_FILE}/" "$ACTIVE_CORE_FILE"
    else
        sed -i "s/^${SESSION_ID}:.*/${SESSION_ID}: ${ROLE_FILE}/" "$ACTIVE_CORE_FILE"
    fi
    echo "Updated: ${SESSION_ID}: ${ROLE_FILE}"
else
    # Append new session
    echo "${SESSION_ID}: ${ROLE_FILE}" >> "$ACTIVE_CORE_FILE"
    echo "Added: ${SESSION_ID}: ${ROLE_FILE}"
fi

exit 0
