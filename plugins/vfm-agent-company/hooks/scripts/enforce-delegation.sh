#!/bin/bash
# Hook: UserPromptSubmit
# Smart delegation reminder - only fires when relevant
# Skips short prompts and when no active project exists

# Read prompt from stdin JSON (UserPromptSubmit provides { "prompt": "..." })
INPUT=$(cat)
if command -v jq &>/dev/null; then
    PROMPT=$(echo "$INPUT" | jq -r '.prompt // empty' 2>/dev/null)
else
    PROMPT=$(echo "$INPUT" | grep -o '"prompt":"[^"]*"' | head -1 | cut -d'"' -f4)
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Skip if no project indicators exist (user is just chatting)
if [ ! -d "$ROOT_DIR/.project/state" ] && [ ! -d "$ROOT_DIR/.project/sprints" ]; then
    exit 0
fi

# Skip short prompts (< 15 chars = likely "ok", "continue", "status")
if [ ${#PROMPT} -lt 15 ]; then
    exit 0
fi

echo "💡 Delegate specialized work to agents."

exit 0
