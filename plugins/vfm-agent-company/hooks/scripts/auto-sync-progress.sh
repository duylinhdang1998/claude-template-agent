#!/bin/bash

##############################################################################
# auto-sync-progress.sh
#
# Unified hook + manual script for syncing tracking files
#
# Usage:
#   As hook (SubagentStop):  Triggered automatically, uses ROOT_DIR
#   Manual:                  ./auto-sync-progress.sh [--verbose]
#
# Examples:
#   ./auto-sync-progress.sh                  # Hook mode (auto)
#   ./auto-sync-progress.sh --verbose        # Detailed output
##############################################################################

set -e

# Parse arguments
EXTRA_ARG=""
VERBOSE=false

for arg in "$@"; do
    case $arg in
        --verbose|-v)
            VERBOSE=true
            ;;
        *)
            if [ -z "$EXTRA_ARG" ]; then
                EXTRA_ARG="$arg"
            fi
            ;;
    esac
done

# Get paths
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
ROOT_DIR="$(cd "$CLAUDE_DIR/.." && pwd)"

# In hook mode (no EXTRA_ARG), use ROOT_DIR as project directory
PROJECT_DIR="$ROOT_DIR"

# Exit silently if project doesn't exist (hook mode)
if [ ! -d "$PROJECT_DIR" ]; then
    if [ "$VERBOSE" = true ]; then
        echo "❌ Project not found: $PROJECT_DIR"
    fi
    exit 0
fi

# Exit silently if no sprints (hook mode)
if [ ! -d "$PROJECT_DIR/.project/sprints" ]; then
    if [ "$VERBOSE" = true ]; then
        echo "⚠️ No sprints directory found"
    fi
    exit 0
fi

##############################################################################
# STEP 1: Calculate progress from sprint files
##############################################################################

if [ "$VERBOSE" = true ]; then
    echo "🔄 Syncing tracking files for: $PROJECT_DIR"
    echo ""
    echo "📊 Step 1: Calculating progress..."
fi

TOTAL_TASKS=0
COMPLETED_TASKS=0

for SPRINT_FILE in "$PROJECT_DIR"/.project/sprints/sprint-*.md; do
    if [ -f "$SPRINT_FILE" ]; then
        # Count tasks (table rows with task IDs like "| 1.1 |", "| 2.10 |")
        TASKS=$(grep -cE "^\| [0-9]+\.[0-9A-Za-z]+ \|" "$SPRINT_FILE" 2>/dev/null || true)
        TASKS=${TASKS:-0}

        # Count completed: [COMPLETE], COMPLETE
        COMPLETE=$(grep -E "^\| [0-9]+\.[0-9A-Za-z]+ \|" "$SPRINT_FILE" 2>/dev/null | grep -cE "\[COMPLETE\]|COMPLETE" 2>/dev/null || true)
        COMPLETE=${COMPLETE:-0}

        TOTAL_TASKS=$((TOTAL_TASKS + TASKS))
        COMPLETED_TASKS=$((COMPLETED_TASKS + COMPLETE))

        if [ "$VERBOSE" = true ]; then
            echo "  - $(basename "$SPRINT_FILE"): $COMPLETE/$TASKS"
        fi
    fi
done

# Avoid division by zero
[ "$TOTAL_TASKS" -eq 0 ] && TOTAL_TASKS=1

PROGRESS=$((COMPLETED_TASKS * 100 / TOTAL_TASKS))

if [ "$VERBOSE" = true ]; then
    echo "  ✅ Overall: $COMPLETED_TASKS/$TOTAL_TASKS tasks ($PROGRESS%)"
    echo ""
fi

##############################################################################
# STEP 2: Regenerate tracking files
##############################################################################

if [ "$VERBOSE" = true ]; then
    echo "📈 Step 2: Regenerating progress-dashboard.md..."
fi

AUTOMATION_DIR="$CLAUDE_DIR/automation"
if [ -x "$AUTOMATION_DIR/generate-progress-dashboard.sh" ]; then
    "$AUTOMATION_DIR/generate-progress-dashboard.sh" > /dev/null 2>&1
fi

if [ "$VERBOSE" = true ]; then
    echo "  ✅ Done"
    echo ""
fi

##############################################################################
# STEP 3: Cleanup .gitkeep files
##############################################################################

for dir in tracking state state/specialists requirements documentation sprints; do
    GITKEEP="$PROJECT_DIR/.project/$dir/.gitkeep"
    if [ -f "$GITKEEP" ]; then
        FILE_COUNT=$(ls -1 "$PROJECT_DIR/.project/$dir" 2>/dev/null | grep -cv "^\.gitkeep$" || echo "0")
        if [ "$FILE_COUNT" -gt 0 ]; then
            rm -f "$GITKEEP"
            if [ "$VERBOSE" = true ]; then
                echo "🧹 Removed $dir/.gitkeep"
            fi
        fi
    fi
done

##############################################################################
# OUTPUT
##############################################################################

if [ "$VERBOSE" = true ]; then
    echo ""
    echo "✅ Sync complete!"
    echo "   Progress: $PROGRESS% ($COMPLETED_TASKS/$TOTAL_TASKS tasks)"
    echo "   Files: progress-dashboard.md"
else
    # Brief output for hook mode
    echo "📊 Progress synced: $COMPLETED_TASKS/$TOTAL_TASKS tasks ($PROGRESS%)"
fi

exit 0
