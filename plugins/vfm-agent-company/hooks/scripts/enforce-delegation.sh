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

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$PWD}"

# Detect intents that MUST go through /work (project-scope tasks)
# Match clone/rebuild/replicate website, build app, etc.
PROMPT_LOWER=$(echo "$PROMPT" | tr '[:upper:]' '[:lower:]')

case "$PROMPT_LOWER" in
    *"clone "*|*"clon "*|*"replicate "*|*"rebuild "*|*"reverse-engineer"*|*"copy "*"site"*|*"copy "*"website"*|*"pixel-perfect"*|*"sao chép"*"web"*|*"clone web"*|*"build "*"app"*|*"build "*"website"*|*"xây dựng "*"app"*|*"làm "*"website"*)
        # Skip if user already typed /work
        if [[ "$PROMPT_LOWER" != *"/work"* ]]; then
            echo "🎯 [VFM Agent Company] This looks like a project-scope task."
            echo "   Route through the company workflow:"
            echo "      /work \"<your request>\""
            echo "   The CEO will scope it, PM will plan a sprint, and specialists will execute."
            echo "   Do NOT invoke clone-website, develop-web-game, or other build skills directly."
        fi
        exit 0
        ;;
esac

# Skip if no project indicators exist (user is just chatting)
if [ ! -d "$PROJECT_DIR/.project/state" ] && [ ! -d "$PROJECT_DIR/.project/sprints" ]; then
    exit 0
fi

# Skip short prompts (< 15 chars = likely "ok", "continue", "status")
if [ ${#PROMPT} -lt 15 ]; then
    exit 0
fi

echo "💡 Delegate specialized work to agents."

exit 0
