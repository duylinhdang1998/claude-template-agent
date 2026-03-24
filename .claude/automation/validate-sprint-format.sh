#!/bin/bash

##############################################################################
# validate-sprint-format.sh
#
# Validates sprint files against the standard format.
#
# MODES:
#   Quick mode (no args): Check format issues, output warnings for agents
#   Full mode (--full):   Comprehensive validation for PM
#
# Usage:
#   ./validate-sprint-format.sh          # Quick mode (hook)
#   ./validate-sprint-format.sh --full   # Full mode (CLI)
##############################################################################

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Detect mode from args
if [ "$1" = "--full" ]; then
    MODE="full"
else
    MODE="quick"
fi

PROJECT_DIR="$ROOT_DIR"
SPRINTS_DIR="$ROOT_DIR/.project/sprints"

if [ ! -d "$PROJECT_DIR" ]; then
    [ "$MODE" = "full" ] && echo "Error: Project root not found: $PROJECT_DIR" && exit 1
    exit 0
fi

if [ ! -d "$SPRINTS_DIR" ]; then
    [ "$MODE" = "full" ] && echo "Error: No sprints directory: $SPRINTS_DIR" && exit 1
    exit 0
fi

# Valid patterns
VALID_ID_PATTERN='^[0-9]+\.[0-9SRQ]+$'
VALID_STATUS_PATTERN='\[IN PROGRESS\]|\[COMPLETE\]|\[BLOCKED\]|→ Sprint'

ERRORS=0
WARNINGS=0
QUICK_ERRORS=""
QUICK_WARNINGS=""

[ "$MODE" = "full" ] && echo "Validating sprint format..." && echo ""

for SPRINT_FILE in "$SPRINTS_DIR"/sprint-*.md; do
    [ -f "$SPRINT_FILE" ] || continue
    FILENAME=$(basename "$SPRINT_FILE")

    [ "$MODE" = "full" ] && echo "Checking: $FILENAME"

    # ============================================================
    # QUICK MODE CHECKS (format issues agents commonly make)
    # ============================================================

    # Issue 1: Task heading with status tags
    # BAD: ### Task 3.6: Name [Frontend] [COMPLETE]
    # GOOD: ### Task 3.6: Name [Frontend]
    BAD_HEADINGS=$(grep -nE "^### Task [0-9]+\.[0-9]+:.*\[(COMPLETE|IN PROGRESS|NOT STARTED|BLOCKED)\]" "$SPRINT_FILE" 2>/dev/null || true)
    if [ -n "$BAD_HEADINGS" ]; then
        ERRORS=$((ERRORS + 1))
        QUICK_ERRORS="$QUICK_ERRORS
⚠️  $FILENAME: Task headings should NOT have status tags
    Remove [COMPLETE], [IN PROGRESS], [NOT STARTED] from ### Task lines
    Status belongs in **Status**: line below
    Found:
$(echo "$BAD_HEADINGS" | head -3 | sed 's/^/    /')"
    fi

    # Issue 2: Task Status line format
    # GOOD: **Status**: [NOT STARTED] | [IN PROGRESS] | [COMPLETE]
    # BAD: **Status**: [ ] NOT STARTED, **Status**: [x] COMPLETE
    BAD_STATUS=$(awk '/^## Task Details/,0' "$SPRINT_FILE" 2>/dev/null | grep -nE "^\*\*Status\*\*:" | grep -vE "\[NOT STARTED\]|\[IN PROGRESS\]|\[COMPLETE\]|\[BLOCKED\]" | head -3 || true)
    if [ -n "$BAD_STATUS" ]; then
        WARNINGS=$((WARNINGS + 1))
        QUICK_WARNINGS="$QUICK_WARNINGS
📋 $FILENAME: Task Status format should be one of:
    [NOT STARTED] | [IN PROGRESS] | [COMPLETE] | [BLOCKED]
    Found non-standard:
$(echo "$BAD_STATUS" | sed 's/^/    /')"
    fi

    # Issue 3: Sprint Backlog table status format
    # GOOD: (empty) | [IN PROGRESS] | [COMPLETE] | [BLOCKED]
    # BAD: COMPLETE, DONE, ✅
    BAD_TABLE_STATUS=$(grep -E "^\| [0-9]+\.[0-9]+ \|" "$SPRINT_FILE" 2>/dev/null | grep -vE "\[IN PROGRESS\]|\[COMPLETE\]|\[BLOCKED\]|\| \|" | grep -E "COMPLETE|DONE|✅|Complete|In Progress" | head -3 || true)
    if [ -n "$BAD_TABLE_STATUS" ]; then
        WARNINGS=$((WARNINGS + 1))
        QUICK_WARNINGS="$QUICK_WARNINGS
📊 $FILENAME: Sprint Backlog table Status should be:
    (empty) | [IN PROGRESS] | [COMPLETE] | [BLOCKED]
    Found non-standard:
$(echo "$BAD_TABLE_STATUS" | sed 's/^/    /')"
    fi

    # ============================================================
    # FULL MODE CHECKS (comprehensive validation)
    # ============================================================
    if [ "$MODE" = "full" ]; then

        # Check Required Sections
        REQUIRED_SECTIONS=(
            "## Task Details"
            "## Sprint Backlog"
            "## Sprint Summary"
            "## Definition of Done"
        )

        MISSING_SECTIONS=()
        for section in "${REQUIRED_SECTIONS[@]}"; do
            if ! grep -qiE "^${section}" "$SPRINT_FILE"; then
                MISSING_SECTIONS+=("$section")
            fi
        done

        if [ ${#MISSING_SECTIONS[@]} -gt 0 ]; then
            echo "  ❌ Missing required sections:"
            for missing in "${MISSING_SECTIONS[@]}"; do
                echo "     - $missing"
                ERRORS=$((ERRORS + 1))
            done
        fi

        # Validate Sprint Backlog Table
        LINE_NUM=0
        FILE_ERRORS=0
        IN_BACKLOG_SECTION=0
        FOUND_TABLE_HEADER=0
        TASK_COUNT=0
        TASK_IDS=()

        while IFS= read -r line; do
            LINE_NUM=$((LINE_NUM + 1))

            if echo "$line" | grep -qiE "^## Sprint Backlog"; then
                IN_BACKLOG_SECTION=1
                FOUND_TABLE_HEADER=0
                continue
            fi

            if [ "$IN_BACKLOG_SECTION" = "1" ]; then
                if echo "$line" | grep -qE "^---$" || echo "$line" | grep -qE "^## "; then
                    IN_BACKLOG_SECTION=0
                    continue
                fi
            fi

            [ "$IN_BACKLOG_SECTION" != "1" ] && continue
            [ -z "$line" ] && continue
            echo "$line" | grep -qE "^<!--" && continue

            if echo "$line" | grep -qE "^\|"; then
                FIRST_COL=$(echo "$line" | awk -F'|' '{print $2}' | xargs)

                [ "$FIRST_COL" = "ID" ] && FOUND_TABLE_HEADER=1 && continue
                echo "$FIRST_COL" | grep -qE "^-+$" && continue

                TASK_ID="$FIRST_COL"
                TASK_COUNT=$((TASK_COUNT + 1))
                TASK_IDS+=("$TASK_ID")

                if ! echo "$TASK_ID" | grep -qE "$VALID_ID_PATTERN"; then
                    echo "  ❌ Line $LINE_NUM: Invalid ID format '$TASK_ID' (expected X.Y)"
                    ERRORS=$((ERRORS + 1))
                    FILE_ERRORS=$((FILE_ERRORS + 1))
                    continue
                fi

                POINTS=$(echo "$line" | awk -F'|' '{print $4}' | xargs)
                STATUS=$(echo "$line" | awk -F'|' '{print $5}' | xargs)
                ASSIGNEE=$(echo "$line" | awk -F'|' '{print $6}' | xargs)

                if ! echo "$POINTS" | grep -qE "^[1-8]$"; then
                    echo "  ⚠️  Line $LINE_NUM: Task $TASK_ID invalid story points: '$POINTS'"
                    WARNINGS=$((WARNINGS + 1))
                fi

                if [ -n "$STATUS" ] && ! echo "$STATUS" | grep -qE "$VALID_STATUS_PATTERN"; then
                    echo "  ❌ Line $LINE_NUM: Task $TASK_ID invalid status: '$STATUS'"
                    ERRORS=$((ERRORS + 1))
                    FILE_ERRORS=$((FILE_ERRORS + 1))
                fi

                if [ -z "$ASSIGNEE" ] || [ "$ASSIGNEE" = "-" ]; then
                    echo "  ⚠️  Line $LINE_NUM: Task $TASK_ID has no assignee"
                    WARNINGS=$((WARNINGS + 1))
                fi
            fi
        done < "$SPRINT_FILE"

        # Check Task Details for each task
        MISSING_TASK_DETAILS=()
        for task_id in "${TASK_IDS[@]}"; do
            if ! grep -qE "^### Task ${task_id}:" "$SPRINT_FILE"; then
                MISSING_TASK_DETAILS+=("$task_id")
            fi
        done

        if [ ${#MISSING_TASK_DETAILS[@]} -gt 0 ]; then
            echo "  ❌ Missing Task Details for:"
            for missing in "${MISSING_TASK_DETAILS[@]}"; do
                echo "     - Task $missing"
                ERRORS=$((ERRORS + 1))
            done
        fi

        # Report for this file
        if [ "$FOUND_TABLE_HEADER" = "0" ]; then
            echo "  ⚠️  No Sprint Backlog table found"
            WARNINGS=$((WARNINGS + 1))
        elif [ "$TASK_COUNT" = "0" ]; then
            echo "  ⚠️  Sprint Backlog table is empty"
            WARNINGS=$((WARNINGS + 1))
        elif [ "$FILE_ERRORS" -eq 0 ] && [ ${#MISSING_SECTIONS[@]} -eq 0 ] && [ ${#MISSING_TASK_DETAILS[@]} -eq 0 ]; then
            echo "  ✅ $TASK_COUNT tasks validated - all OK"
        fi
        echo ""
    fi
done

# ============================================================
# OUTPUT
# ============================================================

if [ "$MODE" = "quick" ]; then
    # Quick mode: output warnings for agent
    if [ -n "$QUICK_ERRORS" ] || [ -n "$QUICK_WARNINGS" ]; then
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "🔍 SPRINT FORMAT VALIDATION"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        [ -n "$QUICK_ERRORS" ] && echo "$QUICK_ERRORS"
        [ -n "$QUICK_WARNINGS" ] && echo "$QUICK_WARNINGS"
        echo ""
        echo "📖 Reference: .claude/templates/sprints/sprint-template.md"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
    fi
else
    # Full mode: summary
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📊 Validation Summary"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    if [ "$ERRORS" -eq 0 ] && [ "$WARNINGS" -eq 0 ]; then
        echo "✅ All sprint files are valid!"
    else
        [ "$ERRORS" -gt 0 ] && echo "❌ Errors: $ERRORS (must fix)"
        [ "$WARNINGS" -gt 0 ] && echo "⚠️  Warnings: $WARNINGS (should fix)"
    fi
    echo ""
fi

[ "$MODE" = "full" ] && [ "$ERRORS" -gt 0 ] && exit 1
exit 0
