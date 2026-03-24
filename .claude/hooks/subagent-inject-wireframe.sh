#!/bin/bash
##############################################################################
# subagent-inject-wireframe.sh
#
# SubagentStart hook - Auto-inject wireframe into UI specialist's context
# via hookSpecificOutput.additionalContext (structured JSON output).
#
# Flow:
# 1. Subagent starts
# 2. Hook detects if this is UI specialist
# 3. Hook reads wireframe based on TASK_ID in prompt
# 4. Hook outputs JSON with additionalContext
# 5. Subagent sees wireframe in its context → implements correctly
#
# Trigger: SubagentStart
# Output: JSON { hookSpecificOutput: { additionalContext: "..." } }
##############################################################################

set -e

# Read subagent info from stdin (JSON)
INPUT=$(cat)

# Extract agent type and prompt (with jq fallback)
if command -v jq &>/dev/null; then
    SUBAGENT_TYPE=$(echo "$INPUT" | jq -r '.agent_type // .subagent_type // .type // empty' 2>/dev/null)
    PROMPT=$(echo "$INPUT" | jq -r '.prompt // empty' 2>/dev/null)
else
    SUBAGENT_TYPE=$(echo "$INPUT" | grep -o '"agent_type":"[^"]*"' | head -1 | cut -d'"' -f4)
    [ -z "$SUBAGENT_TYPE" ] && SUBAGENT_TYPE=$(echo "$INPUT" | grep -o '"subagent_type":"[^"]*"' | head -1 | cut -d'"' -f4)
    [ -z "$SUBAGENT_TYPE" ] && SUBAGENT_TYPE=$(echo "$INPUT" | grep -o '"type":"[^"]*"' | head -1 | cut -d'"' -f4)
    PROMPT=$(echo "$INPUT" | grep -o '"prompt":"[^"]*"' | head -1 | cut -d'"' -f4)
fi

# Define UI specialists that need wireframes
UI_SPECIALISTS="meta-react-architect apple-ios-lead google-android-lead"

# Check if this is a UI specialist
IS_UI_SPECIALIST=false
for specialist in $UI_SPECIALISTS; do
    if [[ "$SUBAGENT_TYPE" == "$specialist" ]]; then
        IS_UI_SPECIALIST=true
        break
    fi
done

# Skip if not UI specialist
if [[ "$IS_UI_SPECIALIST" == "false" ]]; then
    exit 0
fi

# Skip if wireframe already in prompt (PM manually included it)
if echo "$PROMPT" | grep -q "🎨 WIREFRAME"; then
    exit 0
fi

##############################################################################
# Find wireframe based on TASK_ID in prompt
##############################################################################

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Extract TASK_ID from prompt
TASK_ID=$(echo "$PROMPT" | grep -oE "TASK ID: [0-9]+\.[0-9]+" | head -1 | awk '{print $3}')

# Fallback: try TASK: X.Y pattern
if [[ -z "$TASK_ID" ]]; then
    TASK_ID=$(echo "$PROMPT" | grep -oE "Task [0-9]+\.[0-9SRQ]+" | head -1 | awk '{print $2}')
fi

# If no task ID, can't find wireframe
if [[ -z "$TASK_ID" ]]; then
    exit 0
fi

# Extract sprint number
SPRINT=$(echo "$TASK_ID" | cut -d'.' -f1)

# Find sprint file
SPRINT_FILE="$ROOT_DIR/.project/sprints/sprint-$SPRINT.md"

if [[ ! -f "$SPRINT_FILE" ]]; then
    exit 0
fi

# Find wireframe from sprint file
WIREFRAME_FILE=$(grep "| $TASK_ID |" "$SPRINT_FILE" 2>/dev/null | awk -F'|' '{print $(NF-1)}' | tr -d ' ')

# Skip if no wireframe or marked as "-"
if [[ -z "$WIREFRAME_FILE" ]] || [[ "$WIREFRAME_FILE" == "-" ]]; then
    exit 0
fi

# Find wireframe file
WIREFRAME_PATH="$ROOT_DIR/.project/wireframes/screens/$WIREFRAME_FILE"

if [[ ! -f "$WIREFRAME_PATH" ]]; then
    # Try without screens/ subdirectory
    WIREFRAME_PATH="$ROOT_DIR/.project/wireframes/$WIREFRAME_FILE"
fi

if [[ ! -f "$WIREFRAME_PATH" ]]; then
    # Wireframe not found - output warning via additionalContext
    WARN_MSG="⚠️ WIREFRAME NOT FOUND\n\nTask: $TASK_ID expects wireframe: $WIREFRAME_FILE\nBut file not found. Please check if wireframe exists or update sprint file."
    if command -v jq &>/dev/null; then
        jq -n --arg ctx "$WARN_MSG" '{
            "hookSpecificOutput": {
                "hookEventName": "SubagentStart",
                "additionalContext": $ctx
            }
        }'
    else
        ESCAPED=$(echo -e "$WARN_MSG" | sed 's/\\/\\\\/g; s/"/\\"/g' | sed ':a;N;$!ba;s/\n/\\n/g')
        echo "{\"hookSpecificOutput\":{\"hookEventName\":\"SubagentStart\",\"additionalContext\":\"$ESCAPED\"}}"
    fi
    exit 0
fi

##############################################################################
# Output wireframe via hookSpecificOutput.additionalContext
##############################################################################

WIREFRAME_CONTENT=$(cat "$WIREFRAME_PATH")

CONTEXT=$(cat << RULES_EOF
══════════════════════════════════════════════════════════════
🎨 AUTO-INJECTED WIREFRAME FOR TASK $TASK_ID
══════════════════════════════════════════════════════════════

$WIREFRAME_CONTENT

══════════════════════════════════════════════════════════════
📋 IMPLEMENTATION REQUIREMENTS:
- Follow the layout structure exactly as shown above
- Implement ALL states (loading, error, empty, success)
- Match mobile/desktop layouts if both shown
══════════════════════════════════════════════════════════════
RULES_EOF
)

# Output as proper JSON with additionalContext
if command -v jq &>/dev/null; then
    jq -n --arg ctx "$CONTEXT" '{
        "hookSpecificOutput": {
            "hookEventName": "SubagentStart",
            "additionalContext": $ctx
        }
    }'
else
    # Manual JSON escape: newlines → \n, quotes → \"
    ESCAPED=$(echo "$CONTEXT" | sed 's/\\/\\\\/g; s/"/\\"/g' | sed ':a;N;$!ba;s/\n/\\n/g')
    echo "{\"hookSpecificOutput\":{\"hookEventName\":\"SubagentStart\",\"additionalContext\":\"$ESCAPED\"}}"
fi

exit 0
