#!/bin/bash

##############################################################################
# validate-sprint-on-edit.sh
#
# Hook: PostToolUse (Write|Edit) on sprint files
# Purpose: Auto-validate sprint format after any edit to sprint-*.md
#
# Format: | X.Y | Task | Story Points | Status | Assignee |
# Where X.Y = Sprint.Task (e.g., 1.1, 1.10, 2.3)
#
# BLOCKS (exit 1) if format is invalid.
##############################################################################

# Read file path from stdin JSON (PostToolUse provides tool_input)
INPUT=$(cat)

# Try to extract file path from tool_input (Edit/Write tool)
if command -v jq &>/dev/null; then
    FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null)
else
    FILE_PATH=$(echo "$INPUT" | grep -o '"file_path":"[^"]*"' | head -1 | cut -d'"' -f4)
fi

# Fallback to command line arg
[ -z "$FILE_PATH" ] && FILE_PATH="${1:-}"

[ -z "$FILE_PATH" ] && exit 0

# Only process sprint files
if ! echo "$FILE_PATH" | grep -qE "\.project/sprints/sprint-[0-9]+\.md$"; then
    exit 0
fi

SPRINT_FILE="$FILE_PATH"
[ ! -f "$SPRINT_FILE" ] && exit 0

# Valid patterns
VALID_ID_PATTERN='^[0-9]+\.[0-9]+$'
VALID_STATUS_PATTERN='\[COMPLETE\]|\[IN PROGRESS\]|\[BLOCKED\]|→ Sprint|COMPLETE'

ERRORS=0
FILENAME=$(basename "$SPRINT_FILE")

while IFS= read -r line; do
    # Check if line is a task row (starts with | X.Y |)
    if echo "$line" | grep -qE "^\| [0-9]+\.[0-9]+ \|"; then
        TASK_ID=$(echo "$line" | awk -F'|' '{print $2}' | xargs)

        # Validate ID format
        if ! echo "$TASK_ID" | grep -qE "$VALID_ID_PATTERN"; then
            if [ "$ERRORS" -eq 0 ]; then
                echo "⚠️ Sprint format issues in $FILENAME:"
            fi
            echo "  ❌ Task '$TASK_ID': Invalid ID (must be X.Y like 1.1, 2.10)"
            ERRORS=$((ERRORS + 1))
        fi
    fi
done < "$SPRINT_FILE"

# Check for deferred items in Definition of Done (INVALID)
# Pattern: "- [ ]" followed by "Sprint N" anywhere in line
if grep -qE "^- \[ \].*Sprint [0-9]" "$SPRINT_FILE"; then
    if [ "$ERRORS" -eq 0 ]; then
        echo "⚠️ Sprint format issues in $FILENAME:"
    fi
    echo "  ❌ Definition of Done contains deferred items"
    echo "     Found: $(grep -E "^- \[ \].*Sprint [0-9]" "$SPRINT_FILE" | head -1)"
    echo "     Rule: DoD must ONLY contain criteria for THIS sprint"
    ERRORS=$((ERRORS + 1))
fi

if [ "$ERRORS" -gt 0 ]; then
    echo ""
    echo "Valid format: | 1.1 | Task description | 3 | [COMPLETE] | Name |"
    echo "DoD rule: No deferred items (- [ ] ... Sprint N)"
    echo "See: .claude/helpers/sprint-task-format.md"
    echo ""
    echo "🚫 BLOCKED: Fix format before proceeding."
    exit 1
fi

exit 0
