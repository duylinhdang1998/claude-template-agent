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
#
# 4. LINT GATE (blocking): runs the project's `npm run lint` over the change.
#    helpers/code-quality.md says "npm run lint MUST pass before a task is marked
#    complete" — this is what makes that true. Before, the agent simply asserted it.
#    Exits 2 on failure so the specialist gets the lint output and must fix it.
#    Escape hatch: VFM_SKIP_LINT_GATE=1 (use only when lint genuinely cannot run).
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

##############################################################################
# LINT GATE — blocking. Makes "npm run lint MUST pass" a mechanism, not a claim.
##############################################################################
[ "${VFM_SKIP_LINT_GATE:-0}" = "1" ] && exit 0

# Only when JS/TS source actually changed
JS_CHANGED=$(git status --porcelain 2>/dev/null \
    | grep -E "\.(ts|tsx|js|jsx|mjs|cjs)$" \
    | grep -vE "node_modules|\.d\.ts$" | wc -l | tr -d " ")
[ "${JS_CHANGED:-0}" -eq 0 ] && exit 0

# Locate the nearest package.json that defines a "lint" script
LINT_DIR=""
for CAND in . app/web app/api app web apps/web apps/api packages/web packages/api; do
    if [ -f "$PROJECT_DIR/$CAND/package.json" ] \
       && grep -q '"lint"[[:space:]]*:' "$PROJECT_DIR/$CAND/package.json" 2>/dev/null; then
        LINT_DIR="$PROJECT_DIR/$CAND"
        break
    fi
done

if [ -z "$LINT_DIR" ]; then
    echo "⚠️ LINT GATE: no package.json with a \"lint\" script found — gate skipped."
    echo "   helpers/code-quality.md requires one. Frontend/backend agent: add it and merge"
    echo "   templates/shared/eslintrc.conventions.json + the area-specific ESLint template."
    exit 0
fi

LINT_OUT=$(cd "$LINT_DIR" && npm run lint --silent 2>&1) && LINT_RC=0 || LINT_RC=$?

if [ "$LINT_RC" -ne 0 ]; then
    {
        echo "🔴 LINT GATE FAILED — task is NOT complete."
        echo "Ran: npm run lint   (in ${LINT_DIR#$PROJECT_DIR/})"
        echo ""
        echo "$LINT_OUT" | tail -60
        echo ""
        echo "Fix these before finishing. Rules come from helpers/code-quality.md."
        echo "Do NOT weaken or delete a rule to make lint green: on a pre-existing"
        echo "violation set that ONE rule to \"warn\", keep a burn-down list, and restore"
        echo "\"error\" when the list is empty."
    } >&2
    exit 2
fi

echo "✅ Lint gate: npm run lint passed (${LINT_DIR#$PROJECT_DIR/})."
exit 0
