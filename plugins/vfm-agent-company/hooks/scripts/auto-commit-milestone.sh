#!/bin/bash

##############################################################################
# auto-commit-milestone.sh
#
# Auto-commit when core roles create milestone files
# Triggered by PostToolUse hook on Write/Edit
#
# Usage: Called by hook with file path argument
#        ./auto-commit-milestone.sh "/path/to/file.md"
#
# Milestone files that trigger immediate commit:
#   - requirements/srs.md           (BA completed)
#   - requirements/user-stories.md  (BA completed)
#   - documentation/tech-stack.md   (CTO completed)
#   - documentation/architecture.md (CTO completed)
#   - documentation/team.md         (HR completed)
#   - sprints/sprint-*.md           (PM created sprint)
#   - project-context.md            (Project decisions)
##############################################################################

# Read file path from stdin JSON (PostToolUse provides tool_input)
INPUT=$(cat)

if command -v jq &>/dev/null; then
    FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null)
else
    FILE_PATH=$(echo "$INPUT" | grep -o '"file_path":"[^"]*"' | head -1 | cut -d'"' -f4)
fi

# Fallback to command line arg
[ -z "$FILE_PATH" ] && FILE_PATH="${1:-}"

# Exit if no file path
if [ -z "$FILE_PATH" ]; then
    exit 0
fi

# Get paths
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
ROOT_DIR="$(cd "$CLAUDE_DIR/.." && pwd)"

# Check if file is within the project root
if [[ ! "$FILE_PATH" =~ ^"$ROOT_DIR"/ ]]; then
    exit 0
fi

PROJECT_DIR="$ROOT_DIR"
if [ ! -d "$PROJECT_DIR/.git" ]; then
    exit 0
fi

# Use a stable identifier for lock files
PROJECT_ID="project"

# Define milestone patterns and their commit messages
# Format: pattern|role|message
declare -a MILESTONES=(
    ".project/requirements/srs.md|BA|docs(requirements): Complete SRS document"
    ".project/requirements/user-stories.md|BA|docs(requirements): Complete user stories"
    ".project/documentation/tech-stack.md|CTO|docs(tech): Define tech stack"
    ".project/documentation/architecture.md|CTO|docs(arch): Define system architecture"
    ".project/documentation/team.md|HR|docs(team): Define team composition"
    ".project/sprints/sprint-[0-9]*.md|PM|docs(sprint): __SPRINT_DYNAMIC__"
    ".project/project-context.md|BA|docs(context): Update project context"
    ".project/state/pm-tracker.md|PM|docs(tracking): Update PM tracker"
    ".project/state/ba-tracker.md|BA|docs(tracking): Update BA tracker"
)

# Get relative path within project
REL_PATH="${FILE_PATH#$PROJECT_DIR/}"

# Check if file matches any milestone pattern
COMMIT_MSG=""
ROLE=""

for milestone in "${MILESTONES[@]}"; do
    PATTERN=$(echo "$milestone" | cut -d'|' -f1)
    MILESTONE_ROLE=$(echo "$milestone" | cut -d'|' -f2)
    MSG=$(echo "$milestone" | cut -d'|' -f3)

    # Use bash pattern matching
    if [[ "$REL_PATH" =~ ^${PATTERN}$ ]] || [[ "$REL_PATH" == $PATTERN ]]; then
        COMMIT_MSG="$MSG"
        ROLE="$MILESTONE_ROLE"
        break
    fi
done

# Handle dynamic sprint message (create vs update)
if [[ "$COMMIT_MSG" == *"__SPRINT_DYNAMIC__"* ]] && [[ "$REL_PATH" =~ \.project/sprints/sprint-([0-9]+)\.md$ ]]; then
    SPRINT_NUM="${BASH_REMATCH[1]}"
    if git ls-files --error-unmatch "$REL_PATH" &>/dev/null 2>&1; then
        COMMIT_MSG="docs(sprint): Update Sprint $SPRINT_NUM progress"
    else
        COMMIT_MSG="docs(sprint): Create Sprint $SPRINT_NUM plan"
    fi
fi

# Special handling for sprint files (pattern with wildcard)
if [ -z "$COMMIT_MSG" ] && [[ "$REL_PATH" =~ ^\.project/sprints/sprint-[0-9]+\.md$ ]]; then
    SPRINT_NUM=$(echo "$REL_PATH" | sed 's|\.project/sprints/sprint-\([0-9]*\)\.md|\1|')
    # Detect create vs update: check if file is tracked by git
    if git ls-files --error-unmatch "$REL_PATH" &>/dev/null 2>&1; then
        COMMIT_MSG="docs(sprint): Update Sprint $SPRINT_NUM progress"
    else
        COMMIT_MSG="docs(sprint): Create Sprint $SPRINT_NUM plan"
    fi
    ROLE="PM"
fi

# Exit if not a milestone file
if [ -z "$COMMIT_MSG" ]; then
    exit 0
fi

# Debounce: Use a lock file to prevent multiple rapid commits
LOCK_FILE="/tmp/milestone-commit-$PROJECT_ID.lock"
LOCK_TIMEOUT=5  # seconds

# Check if lock exists and is recent
if [ -f "$LOCK_FILE" ]; then
    LOCK_AGE=$(($(date +%s) - $(stat -f %m "$LOCK_FILE" 2>/dev/null || stat -c %Y "$LOCK_FILE" 2>/dev/null || echo 0)))
    if [ "$LOCK_AGE" -lt "$LOCK_TIMEOUT" ]; then
        # Recent lock, skip to avoid duplicate commits
        exit 0
    fi
fi

# Create lock
touch "$LOCK_FILE"

# Change to project directory
cd "$PROJECT_DIR" || exit 0

# Check for actual changes
if git diff --quiet "$REL_PATH" 2>/dev/null && ! git ls-files --others --exclude-standard | grep -q "^$REL_PATH$"; then
    # File unchanged and not new
    rm -f "$LOCK_FILE"
    exit 0
fi

# Stage the specific file
git add "$REL_PATH"

# Check if there's something to commit
if git diff --cached --quiet; then
    rm -f "$LOCK_FILE"
    exit 0
fi

# Also stage related files that might have been modified together
case "$ROLE" in
    "BA")
        git add .project/requirements/*.md .project/project-context.md .project/state/ba-tracker.md 2>/dev/null || true
        ;;
    "CTO")
        git add .project/documentation/tech-stack.md .project/documentation/architecture.md 2>/dev/null || true
        ;;
    "HR")
        git add .project/documentation/team.md 2>/dev/null || true
        ;;
    "PM")
        git add .project/sprints/*.md .project/state/pm-tracker.md .project/tracking/*.md 2>/dev/null || true
        ;;
esac

# Commit
git commit -q -m "$COMMIT_MSG

Triggered by: $REL_PATH
Role: $ROLE"

# Output
COMMIT_HASH=$(git rev-parse --short HEAD)
echo "📝 [$ROLE] Milestone committed: $COMMIT_HASH - $REL_PATH"

# Clean up lock
rm -f "$LOCK_FILE"

exit 0
