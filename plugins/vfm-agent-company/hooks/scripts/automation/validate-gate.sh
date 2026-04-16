#!/bin/bash
##############################################################################
# validate-gate.sh
#
# Unified Gate Validation Script
# Validates phase gate requirements before proceeding to next phase.
#
# Usage: ./validate-gate.sh GATE_NUMBER
#
# Gates:
#   1 = Planning Complete (Sprint 0 -> Sprint 1)
#   2 = Testing Complete (Development -> Deployment)
#   3 = Deployment Ready (Staging -> Production)
#
# Returns:
#   0 = PASSED
#   1 = FAILED
##############################################################################

# Note: Do NOT use "set -e" here because check_file returns non-zero for missing files
# and we want to continue checking all artifacts, not exit on first failure.

GATE_NUM="$1"

if [ -z "$GATE_NUM" ]; then
    echo "Usage: $0 GATE_NUMBER"
    echo ""
    echo "Gates:"
    echo "  1 = Planning Complete (before development)"
    echo "  2 = Testing Complete (before deployment)"
    echo "  3 = Deployment Ready (before release)"
    echo ""
    echo "Example: $0 1"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
PROJECT_DIR="$ROOT_DIR"

if [ ! -d "$PROJECT_DIR" ]; then
    echo "Error: Project root not found: $PROJECT_DIR"
    exit 1
fi

PASS=0
FAIL=0
SKIP=0

# Helper: Check if file exists and has content
check_file() {
    local path="$1"
    local name="$2"
    local required="$3"  # "required" or "optional"

    if [ -f "$PROJECT_DIR/$path" ]; then
        LINES=$(wc -l < "$PROJECT_DIR/$path" | xargs)
        if [ "$LINES" -gt 5 ]; then
            echo "├── $name ... ✅ exists ($LINES lines)"
            PASS=$((PASS + 1))
            return 0
        else
            echo "├── $name ... ⚠️  exists but may be empty"
            if [ "$required" = "required" ]; then
                FAIL=$((FAIL + 1))
                return 1
            fi
            return 0
        fi
    else
        if [ "$required" = "required" ]; then
            echo "├── $name ... ❌ MISSING"
            FAIL=$((FAIL + 1))
            return 1
        else
            echo "├── $name ... ⏭️  skipped"
            SKIP=$((SKIP + 1))
            return 0
        fi
    fi
}

# Helper: Check directory has files matching pattern
check_dir_has_files() {
    local path="$1"
    local name="$2"
    local pattern="$3"

    if [ -d "$PROJECT_DIR/$path" ]; then
        COUNT=$(find "$PROJECT_DIR/$path" -name "$pattern" -type f 2>/dev/null | wc -l | xargs)
        if [ "$COUNT" -gt 0 ]; then
            echo "├── $name ... ✅ $COUNT files"
            PASS=$((PASS + 1))
            return 0
        else
            echo "├── $name ... ❌ empty"
            FAIL=$((FAIL + 1))
            return 1
        fi
    else
        echo "├── $name ... ❌ directory missing"
        FAIL=$((FAIL + 1))
        return 1
    fi
}

# Helper: Check wireframes decision in project-context.md
check_wireframes_decision() {
    if [ -f "$PROJECT_DIR/.project/project-context.md" ]; then
        if grep -qiE "Wireframes.*=.*No|Wireframes.*Skip" "$PROJECT_DIR/.project/project-context.md"; then
            echo "├── Wireframes decision ... ⏭️  SKIPPED (user chose)"
            SKIP=$((SKIP + 1))
            return 0
        elif grep -qiE "Wireframes.*=.*Yes" "$PROJECT_DIR/.project/project-context.md"; then
            check_dir_has_files ".project/wireframes/screens" "wireframes/*.md" "*.md"
            return $?
        else
            echo "├── Wireframes decision ... ⚠️  not found in project-context.md"
            SKIP=$((SKIP + 1))
            return 0
        fi
    else
        echo "├── project-context.md ... ❌ MISSING"
        FAIL=$((FAIL + 1))
        return 1
    fi
}

# Helper: Check tracker file has real content (not just template placeholders)
check_tracker_content() {
    local path="$1"
    local name="$2"

    if [ ! -f "$PROJECT_DIR/$path" ]; then
        echo "├── $name content ... ❌ FILE MISSING"
        FAIL=$((FAIL + 1))
        return 1
    fi

    # Count lines that still have template placeholders
    PLACEHOLDER_COUNT=$(grep -cE '\[To be filled\]|\[To be gathered\]|\[To be asked\]|\[Pending\]|\[None yet\]|\(none yet\)|\{PROJECT_NAME\}|\{DATE\}' "$PROJECT_DIR/$path" 2>/dev/null || echo "0")

    if [ "$PLACEHOLDER_COUNT" -gt 3 ]; then
        echo "├── $name content ... ❌ TEMPLATE ($PLACEHOLDER_COUNT placeholder lines — must fill with real data)"
        FAIL=$((FAIL + 1))
        return 1
    elif [ "$PLACEHOLDER_COUNT" -gt 0 ]; then
        echo "├── $name content ... ⚠️  $PLACEHOLDER_COUNT placeholders remaining (acceptable)"
        PASS=$((PASS + 1))
        return 0
    else
        echo "├── $name content ... ✅ real data"
        PASS=$((PASS + 1))
        return 0
    fi
}

##############################################################################
# GATE 1: Planning Complete
##############################################################################
validate_gate1() {
    echo ""
    echo "📋 Gate 1 Check: Planning Complete"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Project root: $PROJECT_DIR"
    echo ""
    echo "Required Artifacts:"
    echo ""

    # Core requirements (use || true to continue on failure)
    check_file ".project/requirements/srs.md" "requirements/srs.md" "required" || true
    check_file ".project/requirements/user-stories.md" "requirements/user-stories.md" "required" || true

    # Documentation
    check_file ".project/documentation/tech-stack.md" "documentation/tech-stack.md" "required" || true
    check_file ".project/documentation/architecture.md" "documentation/architecture.md" "required" || true
    check_file ".project/documentation/team.md" "documentation/team.md" "required" || true

    # State files
    check_file ".project/state/pm-tracker.md" "state/pm-tracker.md" "required" || true
    check_file ".project/state/ba-tracker.md" "state/ba-tracker.md" "required" || true

    # Tracker content quality (must have real data, not just template)
    check_tracker_content ".project/state/pm-tracker.md" "pm-tracker.md" || true
    check_tracker_content ".project/state/ba-tracker.md" "ba-tracker.md" || true

    # Context
    check_file ".project/project-context.md" "project-context.md" "required" || true

    # Wireframes (conditional)
    check_wireframes_decision || true

    # Sprint files
    check_dir_has_files ".project/sprints" "sprints/sprint-*.md" "sprint-*.md" || true

    # Sprint format validation
    VALIDATE_SPRINT="$SCRIPT_DIR/validate-sprint-format.sh"
    if [ -f "$VALIDATE_SPRINT" ]; then
        if bash "$VALIDATE_SPRINT" 2>/dev/null | grep -q "❌"; then
            echo "├── Sprint format validation ... ❌ ERRORS found"
            echo "    Run: bash .claude/automation/validate-sprint-format.sh --full"
            FAIL=$((FAIL + 1))
        else
            echo "├── Sprint format validation ... ✅ all valid"
            PASS=$((PASS + 1))
        fi
    fi

    # Dashboard
    check_file ".project/progress-dashboard.md" "progress-dashboard.md" "optional"
}

##############################################################################
# GATE 2: Testing Complete
##############################################################################
validate_gate2() {
    echo ""
    echo "🧪 Gate 2 Check: Testing Complete"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Project root: $PROJECT_DIR"
    echo ""
    echo "Required Artifacts:"
    echo ""

    # Test files (search inside app/ — internal structure varies by tech stack)
    if [ -d "$PROJECT_DIR/app" ]; then
        TS_TESTS=$(find "$PROJECT_DIR/app" -name "*.test.ts" -type f 2>/dev/null | wc -l | xargs)
        TSX_TESTS=$(find "$PROJECT_DIR/app" -name "*.test.tsx" -type f 2>/dev/null | wc -l | xargs)
        if [ "$TS_TESTS" -gt 0 ] || [ "$TSX_TESTS" -gt 0 ]; then
            echo "├── Unit/Integration tests ... ✅ $((TS_TESTS + TSX_TESTS)) files"
            PASS=$((PASS + 1))
        else
            echo "├── Unit/Integration tests ... ❌ no test files found in app/"
            FAIL=$((FAIL + 1))
        fi
    else
        echo "├── Unit/Integration tests ... ❌ app/ directory missing"
        FAIL=$((FAIL + 1))
    fi

    # E2E tests (search inside app/ — optional based on project)
    E2E_TESTS=$(find "$PROJECT_DIR/app" -name "*.spec.ts" -type f 2>/dev/null | wc -l | xargs)
    if [ "$E2E_TESTS" -gt 0 ]; then
        echo "├── E2E tests ... ✅ $E2E_TESTS files"
        PASS=$((PASS + 1))
    else
        echo "├── E2E tests ... ⏭️  not configured"
        SKIP=$((SKIP + 1))
    fi

    # Coverage report (check both root and app/ level)
    if [ -f "$PROJECT_DIR/coverage/coverage-summary.json" ] || [ -f "$PROJECT_DIR/app/coverage/coverage-summary.json" ]; then
        COVERAGE_FILE="$PROJECT_DIR/coverage/coverage-summary.json"
        [ ! -f "$COVERAGE_FILE" ] && COVERAGE_FILE="$PROJECT_DIR/app/coverage/coverage-summary.json"
        # Check coverage percentage
        COVERAGE=$(cat "$COVERAGE_FILE" 2>/dev/null | grep -o '"pct":[0-9]*' | head -1 | grep -o '[0-9]*')
        if [ -n "$COVERAGE" ] && [ "$COVERAGE" -ge 80 ]; then
            echo "├── Test coverage ... ✅ ${COVERAGE}%"
            PASS=$((PASS + 1))
        else
            echo "├── Test coverage ... ❌ ${COVERAGE:-0}% (need >=80%)"
            FAIL=$((FAIL + 1))
        fi
    else
        echo "├── Test coverage ... ❌ no coverage report"
        FAIL=$((FAIL + 1))
    fi

}

##############################################################################
# GATE 3: Deployment Ready
##############################################################################
validate_gate3() {
    echo ""
    echo "🚀 Gate 3 Check: Deployment Ready"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Project root: $PROJECT_DIR"
    echo ""
    echo "Required Artifacts:"
    echo ""

    # Docker (optional — check both root and app/)
    if [ -f "$PROJECT_DIR/Dockerfile" ] || [ -f "$PROJECT_DIR/app/Dockerfile" ]; then
        echo "├── Dockerfile ... ✅ exists"
        PASS=$((PASS + 1))
    else
        echo "├── Dockerfile ... ⏭️  not required (Vercel deployment)"
        SKIP=$((SKIP + 1))
    fi

    # CI/CD
    if [ -d "$PROJECT_DIR/.github/workflows" ] || [ -f "$PROJECT_DIR/vercel.json" ] || [ -f "$PROJECT_DIR/app/vercel.json" ]; then
        echo "├── CI/CD configuration ... ✅ exists"
        PASS=$((PASS + 1))
    else
        echo "├── CI/CD configuration ... ❌ missing"
        FAIL=$((FAIL + 1))
    fi

    # Environment config (check both root and app/)
    if [ -f "$PROJECT_DIR/.env.example" ] || [ -f "$PROJECT_DIR/.env.production" ] || [ -f "$PROJECT_DIR/app/.env.example" ]; then
        echo "├── Environment config ... ✅ exists"
        PASS=$((PASS + 1))
    else
        echo "├── Environment config ... ⚠️  no .env.example"
        SKIP=$((SKIP + 1))
    fi

    # Deployment docs
    check_file ".project/documentation/deployment.md" "Deployment docs" "optional"
}

##############################################################################
# Main
##############################################################################

case "$GATE_NUM" in
    1) validate_gate1 ;;
    2) validate_gate2 ;;
    3) validate_gate3 ;;
    *)
        echo "❌ Invalid gate number: $GATE_NUM"
        echo "Valid gates: 1, 2, 3"
        exit 1
        ;;
esac

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Summary: ✅ $PASS passed | ❌ $FAIL failed | ⏭️ $SKIP skipped"
echo ""

if [ "$FAIL" -gt 0 ]; then
    echo "❌ GATE $GATE_NUM FAILED"
    echo ""
    echo "ACTION: Complete missing items before proceeding."
    echo ""
    exit 1
else
    case "$GATE_NUM" in
        1) echo "✅ GATE 1 PASSED - Ready for development!" ;;
        2) echo "✅ GATE 2 PASSED - Ready for deployment!" ;;
        3) echo "✅ GATE 3 PASSED - Ready for release!" ;;
    esac
    echo ""
    exit 0
fi
