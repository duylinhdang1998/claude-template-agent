#!/bin/bash
##############################################################################
# post-task-validate.sh
#
# SubagentStop hook - Verify subagent actually changed files and updated sprint
#
# Uses git diff to check:
# 1. Did any source files change?
# 2. Did sprint file get updated with [COMPLETE]?
# 3. Did specialist state file get updated?
#
# Outputs warning if no changes detected (possible silent failure)
##############################################################################

set -e

# Read stdin JSON (SubagentStop provides agent_type, agent_id, etc.)
INPUT=$(cat)
if command -v jq &>/dev/null; then
    AGENT_TYPE=$(echo "$INPUT" | jq -r '.agent_type // empty' 2>/dev/null)
else
    AGENT_TYPE=$(echo "$INPUT" | grep -o '"agent_type":"[^"]*"' | head -1 | cut -d'"' -f4)
fi

# Skip non-specialist agents
case "$AGENT_TYPE" in
    ""|"general-purpose"|"Explore"|"Plan"|"statusline-setup"|"claude-code-guide")
        exit 0
        ;;
esac

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
ROOT_DIR="$(cd "$CLAUDE_DIR/.." && pwd)"

PROJECT_DIR="$ROOT_DIR"
if [ ! -d "$PROJECT_DIR" ]; then
    exit 0
fi

# Skip if not a git repo
if [ ! -d "$PROJECT_DIR/.git" ]; then
    exit 0
fi

cd "$PROJECT_DIR" || exit 0

# Check for any file changes (staged + unstaged + untracked)
CHANGED_FILES=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
if [ "$CHANGED_FILES" -eq 0 ]; then
    echo "⚠️ POST-TASK CHECK: Subagent completed but NO files changed."
    echo "   PM should verify the task was actually completed."
    exit 0
fi

# Check if any source files changed
SRC_CHANGES=$(git status --porcelain 2>/dev/null | grep -cE "app/" || true)

# Check if sprint file was updated
SPRINT_CHANGES=$(git diff .project/sprints/ 2>/dev/null | grep -c "\[COMPLETE\]" || true)
SPRINT_UNSTAGED=$(git diff --cached .project/sprints/ 2>/dev/null | grep -c "\[COMPLETE\]" || true)
SPRINT_TOTAL=$((SPRINT_CHANGES + SPRINT_UNSTAGED))

# Build status output
WARNINGS=0

if [ "$SRC_CHANGES" -eq 0 ]; then
    echo "⚠️ POST-TASK CHECK: No source files (app/) changed."
    WARNINGS=$((WARNINGS + 1))
fi

if [ "$SPRINT_TOTAL" -eq 0 ]; then
    echo "⚠️ POST-TASK CHECK: Sprint file not updated with [COMPLETE]."
    WARNINGS=$((WARNINGS + 1))
fi

if [ "$WARNINGS" -eq 0 ]; then
    echo "✅ Post-task check: $CHANGED_FILES files changed, sprint updated."
fi

exit 0
