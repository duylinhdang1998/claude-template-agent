#!/bin/bash

##############################################################################
# auto-git-checkpoint.sh
#
# Auto-commit changes after subagent completes a task
# Triggered by SubagentStop hook
#
# Usage: Called automatically by hook, no arguments needed
##############################################################################

# Get paths
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
ROOT_DIR="$(cd "$CLAUDE_DIR/.." && pwd)"

PROJECT_DIR="$ROOT_DIR"
if [ ! -d "$PROJECT_DIR" ]; then
    exit 0
fi

cd "$PROJECT_DIR" || exit 0

# Initialize git if needed
if [ ! -d ".git" ]; then
    exit 0
fi

# Check for changes
if git diff --quiet && git diff --staged --quiet && [ -z "$(git ls-files --others --exclude-standard)" ]; then
    # No changes
    exit 0
fi

# Count changed files
CHANGED_COUNT=$(git status --porcelain | wc -l | tr -d ' ')
if [ "$CHANGED_COUNT" -eq 0 ]; then
    exit 0
fi

# Generate meaningful commit message from changed files and sprint info
COMMIT_TYPE="chore"
COMMIT_SCOPE=""
COMMIT_DESC=""

# Get list of changed files
CHANGED_FILES=$(git status --porcelain | awk '{print $2}')

# Check most recently modified specialist state file (has task context)
SPECIALIST_DIR="$PROJECT_DIR/.project/state/specialists"
if [ -d "$SPECIALIST_DIR" ]; then
    # Get most recently modified specialist file (sorted by time, newest first)
    SPECIALIST_FILE=$(ls -t "$SPECIALIST_DIR"/*.md 2>/dev/null | head -1)
    if [ -n "$SPECIALIST_FILE" ] && [ -f "$SPECIALIST_FILE" ]; then
        # Try frontmatter first: "description: Task Description"
        COMMIT_DESC=$(head -20 "$SPECIALIST_FILE" | grep -E "^description:" | head -1 | sed 's/^description: *//')

        # Guard: skip if description is still a placeholder or unfilled
        if echo "$COMMIT_DESC" | grep -qE '\{TASK_DESCRIPTION_FOR_COMMIT\}|^\[FILL:|^$'; then
            COMMIT_DESC=""
        fi

        # Fallback to old format: "**Task**: X.Y - Description" or "Task X.Y: Description"
        if [ -z "$COMMIT_DESC" ]; then
            TASK_LINE=$(head -15 "$SPECIALIST_FILE" | grep -E "\*\*Task\*\*:|Task [0-9]+\.[0-9SRQ]+:" | head -1)
            if [ -n "$TASK_LINE" ]; then
                COMMIT_DESC=$(echo "$TASK_LINE" | sed 's/.*\*\*Task\*\*: [0-9.]* [-—] //' | sed 's/.*Task [0-9.]*: //' | sed 's/ *$//')
            fi
        fi

        # Determine commit type from description
        if [ -n "$COMMIT_DESC" ]; then
            if echo "$COMMIT_DESC" | grep -qiE "test|QA|E2E"; then
                COMMIT_TYPE="test"
            elif echo "$COMMIT_DESC" | grep -qiE "fix|bug"; then
                COMMIT_TYPE="fix"
            elif echo "$COMMIT_DESC" | grep -qiE "setup|deploy|CI|vercel"; then
                COMMIT_TYPE="chore"
            else
                COMMIT_TYPE="feat"
            fi
        fi
    fi
fi

# Only do file-based analysis if we don't have task description yet
if [ -z "$COMMIT_DESC" ]; then
    CODE_FILES=$(echo "$CHANGED_FILES" | grep -E '\.(ts|tsx|js|jsx|css|json)$' | head -5)
    TEST_FILES=$(echo "$CHANGED_FILES" | grep -E '\.test\.|\.spec\.' | head -3)

    # Determine commit type and extract meaningful description
    if [ -n "$TEST_FILES" ]; then
    COMMIT_TYPE="test"
    # Extract test file names
    TEST_NAMES=$(echo "$TEST_FILES" | xargs -I{} basename {} | sed 's/\.test\.\|\.spec\./_/g' | sed 's/\.[^.]*$//' | tr '\n' ', ' | sed 's/,$//')
    COMMIT_DESC="add tests for ${TEST_NAMES}"
elif echo "$CHANGED_FILES" | grep -qE "app/"; then
    COMMIT_TYPE="feat"
    # Extract component/module names from changed files
    COMPONENTS=$(echo "$CODE_FILES" | grep -E 'components/' | xargs -I{} basename {} .tsx 2>/dev/null | head -3 | tr '\n' ', ' | sed 's/,$//')
    PAGES=$(echo "$CODE_FILES" | grep -E 'app/.*page\.' | xargs -I{} dirname {} | xargs -I{} basename {} 2>/dev/null | head -2 | tr '\n' ', ' | sed 's/,$//')
    API_ROUTES=$(echo "$CODE_FILES" | grep -E 'api/' | xargs -I{} dirname {} | xargs -I{} basename {} 2>/dev/null | head -2 | tr '\n' ', ' | sed 's/,$//')
    LIB_FILES=$(echo "$CODE_FILES" | grep -E 'lib/' | xargs -I{} basename {} .ts 2>/dev/null | head -2 | tr '\n' ', ' | sed 's/,$//')

    if [ -n "$COMPONENTS" ]; then
        COMMIT_DESC="update ${COMPONENTS}"
    elif [ -n "$PAGES" ]; then
        COMMIT_DESC="update ${PAGES} page"
    elif [ -n "$API_ROUTES" ]; then
        COMMIT_TYPE="feat"
        COMMIT_SCOPE="api"
        COMMIT_DESC="update ${API_ROUTES} endpoint"
    elif [ -n "$LIB_FILES" ]; then
        COMMIT_DESC="update ${LIB_FILES} utils"
    else
        # Fallback: get first changed file basename
        FIRST_FILE=$(echo "$CODE_FILES" | head -1 | xargs basename 2>/dev/null | sed 's/\.[^.]*$//')
        [ -n "$FIRST_FILE" ] && COMMIT_DESC="update ${FIRST_FILE}"
    fi
elif echo "$CHANGED_FILES" | grep -qE "\.project/sprints/"; then
    COMMIT_TYPE="docs"
    COMMIT_SCOPE="sprint"
    # Try to extract task info from git diff (newly added [COMPLETE])
    SPRINT_FILE=$(echo "$CHANGED_FILES" | grep "\.project/sprints/" | head -1)
    if [ -n "$SPRINT_FILE" ] && [ -f "$SPRINT_FILE" ]; then
        # Check git diff for newly added [COMPLETE] status
        TASK_NAME=$(git diff "$SPRINT_FILE" 2>/dev/null | grep -E '^\+.*\[COMPLETE\]' | head -1 | sed 's/.*Task [0-9.]*: //' | sed 's/ \[.*$//' | sed 's/^+//')
        if [ -z "$TASK_NAME" ]; then
            # Fallback: look in file for last completed task
            TASK_NAME=$(grep -B1 '\[COMPLETE\]' "$SPRINT_FILE" 2>/dev/null | grep -E '^### Task' | tail -1 | sed 's/### Task [0-9.]*: //' | sed 's/ \[.*$//')
        fi
        [ -n "$TASK_NAME" ] && COMMIT_DESC="complete ${TASK_NAME}"
    fi
elif echo "$CHANGED_FILES" | grep -qE "\.project/requirements/|\.project/documentation/"; then
    COMMIT_TYPE="docs"
    DOC_FILES=$(echo "$CHANGED_FILES" | grep -E "\.project/requirements/|\.project/documentation/" | xargs -I{} basename {} .md 2>/dev/null | head -2 | tr '\n' ', ' | sed 's/,$//')
    [ -n "$DOC_FILES" ] && COMMIT_DESC="update ${DOC_FILES}"
elif echo "$CHANGED_FILES" | grep -qE "\.project/tracking/|\.project/state/"; then
    COMMIT_TYPE="docs"
    COMMIT_SCOPE="tracking"
    TRACKING_FILES=$(echo "$CHANGED_FILES" | grep -E "\.project/tracking/|\.project/state/" | xargs -I{} basename {} .md 2>/dev/null | head -2 | tr '\n' ', ' | sed 's/,$//')
    [ -n "$TRACKING_FILES" ] && COMMIT_DESC="update ${TRACKING_FILES}"
fi
fi  # End file-based analysis

# Fallback description if still empty
[ -z "$COMMIT_DESC" ] && COMMIT_DESC="update ${CHANGED_COUNT} files"

# Build final message
if [ -n "$COMMIT_SCOPE" ]; then
    COMMIT_MSG="$COMMIT_TYPE($COMMIT_SCOPE): $COMMIT_DESC"
else
    COMMIT_MSG="$COMMIT_TYPE: $COMMIT_DESC"
fi

# Lock to prevent race condition with parallel agents
LOCK_FILE="$PROJECT_DIR/.git-checkpoint.lock"
if [ -f "$LOCK_FILE" ]; then
    # Another checkpoint is running, skip
    echo "⏭️ Git checkpoint skipped (another in progress)"
    exit 0
fi
touch "$LOCK_FILE"
trap "rm -f '$LOCK_FILE'" EXIT

# Extract file list from specialist state file (## Files Created/Modified table)
# Only stage files THIS agent touched, not all of app/
AGENT_FILES=""
AGENT_TYPE=""
AGENT_NAME=""

if [ -n "$SPECIALIST_FILE" ] && [ -f "$SPECIALIST_FILE" ]; then
    # Extract agent type from frontmatter: "agent:" (new) or "state:" (legacy)
    AGENT_TYPE=$(head -10 "$SPECIALIST_FILE" | grep -E "^(agent|state):" | head -1 | sed 's/^[a-z]*: *//')

    # Parse ## Files Modified (new) or ## Files Created/Modified (legacy) table
    # Extract file paths from "| app/path/file.ts | ACTION |" rows
    # Note: grep -v uses fixed string (-F) to avoid | being treated as regex OR
    AGENT_FILES=$(sed -n '/^## Files \(Created\/\)\{0,1\}Modified/,/^## /p' "$SPECIALIST_FILE" \
        | grep -E '^\|' \
        | grep -v -F '| File' \
        | grep -v -F '|---' \
        | sed 's/^ *| *//' \
        | cut -d'|' -f1 \
        | sed 's/ *$//' \
        | sed 's/`//g' \
        | grep -v '^$')

    # Resolve agentName from .claude/agents/{AGENT_TYPE}.md frontmatter
    if [ -n "$AGENT_TYPE" ]; then
        AGENT_DEF="$CLAUDE_DIR/agents/${AGENT_TYPE}.md"
        if [ -f "$AGENT_DEF" ]; then
            AGENT_NAME=$(head -25 "$AGENT_DEF" | grep -E "^agentName:" | head -1 | sed 's/^agentName: *//')
        fi
    fi
fi

# Stage specific files from this agent's state file
if [ -n "$AGENT_FILES" ]; then
    echo "$AGENT_FILES" | while IFS= read -r f; do
        [ -n "$f" ] && git add "$f" 2>/dev/null
    done
fi

# Always stage this agent's own state file + sprint file updates
[ -n "$SPECIALIST_FILE" ] && git add "$SPECIALIST_FILE" 2>/dev/null
git add .project/sprints/ 2>/dev/null || true

# If no specific files found, fall back to staging known dirs (non-parallel safe)
if git diff --cached --quiet 2>/dev/null; then
    git add app/ .project/state/ .project/documentation/ .project/requirements/ .project/wireframes/ .project/tracking/ 2>/dev/null || true
    git add .project/project-context.md 2>/dev/null || true
fi

# Build author line
COMMIT_AUTHOR="Auto-committed"
if [ -n "$AGENT_NAME" ] && [ -n "$AGENT_TYPE" ]; then
    COMMIT_AUTHOR="$AGENT_NAME ($AGENT_TYPE)"
elif [ -n "$AGENT_TYPE" ]; then
    COMMIT_AUTHOR="$AGENT_TYPE"
fi

# Only commit if there are staged changes
if ! git diff --cached --quiet 2>/dev/null; then
    git commit -q -m "$COMMIT_MSG

Spec: $COMMIT_AUTHOR"

    COMMIT_HASH=$(git rev-parse --short HEAD)
    echo "🔒 Git checkpoint: $COMMIT_HASH"
else
    echo "⏭️ Git checkpoint: no staged changes"
fi

exit 0
