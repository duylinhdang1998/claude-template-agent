#!/bin/bash

# Create Sprint File from Template
# Usage: ./create-sprint.sh SPRINT_NUMBER "Sprint Name"
#
# Example:
#   ./create-sprint.sh 1 "Foundation & Tree View"
#   ./create-sprint.sh 2 "Core Features"

set -e

SPRINT_NUM="$1"
SPRINT_NAME="$2"

if [ -z "$SPRINT_NUM" ]; then
    echo "Usage: $0 SPRINT_NUMBER [SPRINT_NAME]"
    echo ""
    echo "Examples:"
    echo "  $0 1 \"Foundation\""
    echo "  $0 2 \"Core Features\""
    exit 1
fi

# Default sprint name if not provided
if [ -z "$SPRINT_NAME" ]; then
    SPRINT_NAME="Sprint $SPRINT_NUM"
fi

# Base paths
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
TEMPLATE_FILE="$ROOT_DIR/.claude/templates/sprints/sprint-template.md"
PROJECT_DIR="$ROOT_DIR"
SPRINT_FILE="$ROOT_DIR/.project/sprints/sprint-$SPRINT_NUM.md"

# Validate template exists
if [ ! -f "$TEMPLATE_FILE" ]; then
    echo "Error: Sprint template not found at $TEMPLATE_FILE"
    exit 1
fi

# Check if sprint file already exists
if [ -f "$SPRINT_FILE" ]; then
    echo "Warning: Sprint file already exists: $SPRINT_FILE"
    read -p "Overwrite? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Aborted."
        exit 0
    fi
fi

# Create sprints directory if needed
mkdir -p "$PROJECT_DIR/.project/sprints"

# Copy template and replace placeholders
echo "Creating sprint file from template..."

# Read template and replace placeholders
sed -e "s/{N}/$SPRINT_NUM/g" \
    -e "s/{Sprint Name}/$SPRINT_NAME/g" \
    -e "s/{X}/TBD/g" \
    -e "s/{Y}/TBD/g" \
    "$TEMPLATE_FILE" > "$SPRINT_FILE"

echo ""
echo "Sprint file created: $SPRINT_FILE"
echo ""

# Auto-validate sprint format
VALIDATE_SCRIPT="$SCRIPT_DIR/validate-sprint-format.sh"
if [ -f "$VALIDATE_SCRIPT" ]; then
    echo "Validating sprint format..."
    if bash "$VALIDATE_SCRIPT" 2>/dev/null | grep -q "✅"; then
        echo "Sprint format validated"
    else
        echo "Sprint format validation found issues. Run:"
        echo "   bash .claude/automation/validate-sprint-format.sh --full"
    fi
    echo ""
fi

echo "Next steps:"
echo "   1. Open the file: code $SPRINT_FILE"
echo "   2. Update Duration (Week X)"
echo "   3. Add tasks to Sprint Backlog table"
echo "   4. Fill in Summary section"
echo "   5. Identify Dependencies and Risks"
echo "   6. Run: bash .claude/automation/validate-sprint-format.sh --full"
echo ""
echo "Sprint Backlog table format:"
echo "   | ID | Task | Points | Status | Assignee | Wireframe |"
echo "   |----|------|--------|--------|----------|-----------|"
echo "   | $SPRINT_NUM.1 | Task description | 3 | | Frontend | - |"
echo ""

# Auto-sync progress dashboard after sprint creation
SYNC_SCRIPT="$ROOT_DIR/.claude/automation/generate-progress-dashboard.sh"
if [ -x "$SYNC_SCRIPT" ]; then
    bash "$SYNC_SCRIPT" > /dev/null 2>&1 && echo "📊 Dashboard synced (Sprint $SPRINT_NUM added)" || true
fi
