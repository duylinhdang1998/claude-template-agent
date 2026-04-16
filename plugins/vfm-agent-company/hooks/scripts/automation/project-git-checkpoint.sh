#!/bin/bash

##############################################################################
# project-git-checkpoint.sh
#
# Create a git checkpoint (commit) after completing a task
# Used by specialists to save progress after each task
#
# Usage: ./project-git-checkpoint.sh "commit message"
#        ./project-git-checkpoint.sh --task TASK_ID
##############################################################################

set -e

COMMIT_ARG="$1"

if [ -z "$COMMIT_ARG" ]; then
    echo "Usage: $0 \"commit message\""
    echo "       $0 --task TASK_ID"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
PROJECT_DIR="$ROOT_DIR"

cd "$PROJECT_DIR"

# Check git is initialized (managed at project root)
if [ ! -d ".git" ]; then
    echo "No git repository found at project root. Run 'git init' first."
    exit 1
fi

# Parse arguments
if [ "$1" = "--task" ]; then
    TASK_ID="$2"
    # Find task details from sprint files
    TASK_DESC=$(grep -h "| $TASK_ID |" .project/sprints/sprint-*.md 2>/dev/null | head -1 | awk -F'|' '{print $3}' | xargs)
    COMMIT_MSG="feat: Complete task $TASK_ID - $TASK_DESC"
else
    COMMIT_MSG="$*"
fi

if [ -z "$COMMIT_MSG" ]; then
    echo "Error: Commit message required"
    exit 1
fi

# Enforce conventional commits format
# Types: feat, fix, refactor, docs, test, chore, perf, ci
CONVENTIONAL_PATTERN='^(feat|fix|refactor|docs|test|chore|perf|ci)(\(.+\))?!?: .+'

if ! echo "$COMMIT_MSG" | grep -qE "$CONVENTIONAL_PATTERN"; then
    # Auto-fix by prepending 'chore:' if no valid type
    COMMIT_MSG="chore: $COMMIT_MSG"
    echo "⚠️ Auto-fixed to conventional format"
fi

# Check for changes
if git diff --quiet && git diff --staged --quiet; then
    echo "⚠️ No changes to commit"
    exit 0
fi

# Stage all changes
git add -A

# Commit with message
git commit -q -m "$COMMIT_MSG"

# Get commit info
COMMIT_HASH=$(git rev-parse --short HEAD)
COMMIT_COUNT=$(git rev-list --count HEAD)

echo "✅ Checkpoint created: $COMMIT_HASH"
echo "📝 Message: $COMMIT_MSG"
echo "📊 Total commits: $COMMIT_COUNT"
