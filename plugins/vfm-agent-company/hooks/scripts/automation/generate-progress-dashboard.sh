#!/bin/bash

##############################################################################
# generate-progress-dashboard.sh
#
# Generates a clean, accurate progress dashboard from sprint files
#
# Usage: ./generate-progress-dashboard.sh
##############################################################################

set -e

# Paths — ROOT_DIR is 2 levels up from automation/
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)/.project"
OUTPUT_FILE="$PROJECT_DIR/progress-dashboard.md"

# Derive project name from project-context.md header, fall back to directory name
# Project name derived from directory

mkdir -p "$PROJECT_DIR"

##############################################################################
# HELPER FUNCTIONS
##############################################################################

make_bar() {
    local p=${1:-0}
    local width=${2:-10}
    [ "$p" -lt 0 ] && p=0
    [ "$p" -gt 100 ] && p=100
    local f=$((p * width / 100))
    local e=$((width - f))
    local bar=""
    for ((i=0; i<f; i++)); do bar="${bar}█"; done
    for ((i=0; i<e; i++)); do bar="${bar}░"; done
    echo "$bar"
}

status_emoji() {
    local p=${1:-0}
    if [ "$p" -ge 100 ]; then echo "✅"
    elif [ "$p" -ge 75 ]; then echo "🟢"
    elif [ "$p" -ge 50 ]; then echo "🟡"
    elif [ "$p" -gt 0 ]; then echo "🟠"
    else echo "🔵"
    fi
}

##############################################################################
# PARSE PROJECT INFO
##############################################################################

# Parse project name from "# Project Context — Name" header in project-context.md
PROJECT_NAME=$(head -5 "$PROJECT_DIR/project-context.md" 2>/dev/null | grep -E "^# " | head -1 | sed 's/^# Project Context[[:space:]]*[—–-][[:space:]]*//' | xargs || echo "Unknown Project")

##############################################################################
# PARSE ALL SPRINT FILES
##############################################################################

TOTAL_TASKS=0
COMPLETED_TASKS=0
TOTAL_SP=0
COMPLETED_SP=0
SPRINT_COUNT=0
CURRENT_SPRINT=0
ALL_COMPLETE=true

SPRINT_TABLE=""
TASK_TABLE=""
COMPLETED_LIST=""
IN_PROGRESS_LIST=""
NEXT_UP_LIST=""

for SPRINT_FILE in "$PROJECT_DIR"/sprints/sprint-*.md; do
    [ -f "$SPRINT_FILE" ] || continue

    SPRINT_NUM=$(basename "$SPRINT_FILE" .md | sed 's/sprint-//')
    SPRINT_COUNT=$((SPRINT_COUNT + 1))

    # Count tasks from Sprint Backlog table
    TASKS=$(grep -cE "^\| [0-9]+\.[0-9A-Za-z]+ \|" "$SPRINT_FILE" 2>/dev/null | tr -d '[:space:]')
    TASKS=${TASKS:-0}

    # Count completed: [COMPLETE] only (standardized format)
    COMPLETE_LINES=$(grep -E "^\| [0-9]+\.[0-9A-Za-z]+ \|" "$SPRINT_FILE" 2>/dev/null | grep -c "\[COMPLETE\]" 2>/dev/null | tr -d '[:space:]')
    DONE=${COMPLETE_LINES:-0}

    # Story points
    SP=$(grep -E "^\| [0-9]+\.[0-9A-Za-z]+ \|" "$SPRINT_FILE" 2>/dev/null | awk -F'|' '{gsub(/[^0-9]/,"",$4); if($4!="") sum+=$4} END{print sum+0}')
    DONE_SP=$(grep -E "^\| [0-9]+\.[0-9A-Za-z]+ \|" "$SPRINT_FILE" 2>/dev/null | grep -E "\[COMPLETE\]" | awk -F'|' '{gsub(/[^0-9]/,"",$4); if($4!="") sum+=$4} END{print sum+0}')

    TOTAL_TASKS=$((TOTAL_TASKS + TASKS))
    COMPLETED_TASKS=$((COMPLETED_TASKS + DONE))
    TOTAL_SP=$((TOTAL_SP + SP))
    COMPLETED_SP=$((COMPLETED_SP + DONE_SP))

    # Sprint goal
    GOAL=$(grep -E "^\*\*Goal\*\*:" "$SPRINT_FILE" 2>/dev/null | head -1 | sed 's/\*\*Goal\*\*://' | xargs || echo "Sprint $SPRINT_NUM")

    # Determine sprint status and current sprint
    if [ "$DONE" -eq "$TASKS" ] && [ "$TASKS" -gt 0 ]; then
        STATUS="✅ Complete"
        COMPLETED_LIST="${COMPLETED_LIST}- ✅ Sprint $SPRINT_NUM: $GOAL\n"
    elif [ "$DONE" -gt 0 ]; then
        STATUS="🟡 In Progress ($DONE/$TASKS)"
        CURRENT_SPRINT=$SPRINT_NUM
        ALL_COMPLETE=false
        IN_PROGRESS_LIST="${IN_PROGRESS_LIST}- 🟡 Sprint $SPRINT_NUM: $GOAL ($DONE/$TASKS done)\n"
    else
        STATUS="🔵 Not Started"
        ALL_COMPLETE=false
        # First incomplete sprint is the current sprint
        [ "$CURRENT_SPRINT" -eq 0 ] && CURRENT_SPRINT=$SPRINT_NUM
        if [ -z "$NEXT_UP_LIST" ]; then
            NEXT_UP_LIST="- 🔵 Sprint $SPRINT_NUM: $GOAL\n"
        fi
    fi

    SPRINT_TABLE="${SPRINT_TABLE}| Sprint $SPRINT_NUM | $GOAL | $DONE/$TASKS | $STATUS |\n"
    TASK_TABLE="${TASK_TABLE}| Sprint $SPRINT_NUM | $DONE | $TASKS | $((DONE * 100 / (TASKS > 0 ? TASKS : 1)))% |\n"
done

# If all sprints complete, current sprint = last sprint
if [ "$ALL_COMPLETE" = true ] && [ "$SPRINT_COUNT" -gt 0 ]; then
    CURRENT_SPRINT=$SPRINT_COUNT
fi

# Calculate progress
[ "$TOTAL_TASKS" -gt 0 ] && PROGRESS=$((COMPLETED_TASKS * 100 / TOTAL_TASKS)) || PROGRESS=0
[ "$SPRINT_COUNT" -gt 0 ] && AVG_VELOCITY=$((COMPLETED_TASKS * 100 / TOTAL_TASKS)) || AVG_VELOCITY=0

##############################################################################
# PHASE CALCULATIONS
##############################################################################

# Phase 1: Planning (requirements, docs, sprints exist)
PHASE1=0
[ -d "$PROJECT_DIR/requirements" ] && [ "$(find "$PROJECT_DIR/requirements" -name "*.md" -type f 2>/dev/null | wc -l)" -gt 0 ] && PHASE1=$((PHASE1 + 40))
[ -d "$PROJECT_DIR/documentation" ] && [ "$(find "$PROJECT_DIR/documentation" -name "*.md" -type f 2>/dev/null | wc -l)" -gt 0 ] && PHASE1=$((PHASE1 + 30))
[ "$SPRINT_COUNT" -gt 0 ] && PHASE1=$((PHASE1 + 30))
[ "$PHASE1" -gt 100 ] && PHASE1=100

# Phase 2: Development (sprint 1 to N-1 or all if single sprint)
if [ "$SPRINT_COUNT" -le 1 ]; then
    PHASE2=$PROGRESS
else
    DEV_DONE=0
    DEV_TOTAL=0
    LAST_SPRINT=$SPRINT_COUNT
    for SPRINT_FILE in "$PROJECT_DIR"/sprints/sprint-*.md; do
        [ -f "$SPRINT_FILE" ] || continue
        SNUM=$(basename "$SPRINT_FILE" .md | sed 's/sprint-//')
        [ "$SNUM" -eq "$LAST_SPRINT" ] && continue
        DT=$(grep -cE "^\| [0-9]+\.[0-9A-Za-z]+ \|" "$SPRINT_FILE" 2>/dev/null | tr -d '[:space:]')
        DEV_TOTAL=$((DEV_TOTAL + ${DT:-0}))
        DD=$(grep -E "^\| [0-9]+\.[0-9A-Za-z]+ \|" "$SPRINT_FILE" 2>/dev/null | grep -c "\[COMPLETE\]" 2>/dev/null | tr -d '[:space:]')
        DEV_DONE=$((DEV_DONE + ${DD:-0}))
    done
    [ "$DEV_TOTAL" -gt 0 ] && PHASE2=$((DEV_DONE * 100 / DEV_TOTAL)) || PHASE2=0
fi

# Phase 3: Testing (QA tasks across ALL sprints + test files in app/)
PHASE3=0
QA_TOTAL=0
QA_DONE=0
for SPRINT_FILE in "$PROJECT_DIR"/sprints/sprint-*.md; do
    [ -f "$SPRINT_FILE" ] || continue
    QT=$(grep -E "^\| [0-9]+\.[0-9A-Za-z]+ \|" "$SPRINT_FILE" 2>/dev/null | grep -ciE "QA|Test|Review|BDD|Scenario" 2>/dev/null | tr -d '[:space:]')
    QA_TOTAL=$((QA_TOTAL + ${QT:-0}))
    QD=$(grep -E "^\| [0-9]+\.[0-9A-Za-z]+ \|" "$SPRINT_FILE" 2>/dev/null | grep -iE "QA|Test|Review|BDD|Scenario" | grep -c "\[COMPLETE\]" 2>/dev/null | tr -d '[:space:]')
    QA_DONE=$((QA_DONE + ${QD:-0}))
done
[ "$QA_TOTAL" -gt 0 ] && PHASE3=$((QA_DONE * 100 / QA_TOTAL)) || PHASE3=0
# Also check for test files in source directory (project root, not .project/)
ROOT_DIR_PARENT="$(cd "$PROJECT_DIR/.." && pwd)"
TEST_FILES=$(find "$ROOT_DIR_PARENT/app" -type f \( -name "*.test.ts" -o -name "*.test.tsx" -o -name "*.spec.ts" \) -not -path "*/node_modules/*" 2>/dev/null | wc -l | tr -d ' ')
[ "$TEST_FILES" -gt 0 ] && [ "$PHASE3" -lt 50 ] && PHASE3=50
[ "$PHASE3" -gt 100 ] && PHASE3=100

# Phase 4: Deployment (DevOps tasks + config files)
PHASE4=0
DEPLOY_TOTAL=0
DEPLOY_DONE=0
for SPRINT_FILE in "$PROJECT_DIR"/sprints/sprint-*.md; do
    [ -f "$SPRINT_FILE" ] || continue
    DT=$(grep -E "^\| [0-9]+\.[0-9A-Za-z]+ \|" "$SPRINT_FILE" 2>/dev/null | grep -ciE "DevOps|Deploy|Vercel|Docker|CI" 2>/dev/null | tr -d '[:space:]')
    DEPLOY_TOTAL=$((DEPLOY_TOTAL + ${DT:-0}))
    DD=$(grep -E "^\| [0-9]+\.[0-9A-Za-z]+ \|" "$SPRINT_FILE" 2>/dev/null | grep -iE "DevOps|Deploy|Vercel|Docker|CI" | grep -c "\[COMPLETE\]" 2>/dev/null | tr -d '[:space:]')
    DEPLOY_DONE=$((DEPLOY_DONE + ${DD:-0}))
done
[ "$DEPLOY_TOTAL" -gt 0 ] && PHASE4=$((DEPLOY_DONE * 100 / DEPLOY_TOTAL)) || PHASE4=0
# Check for deployment configs in project root
[ -f "$ROOT_DIR_PARENT/vercel.json" ] || [ -f "$ROOT_DIR_PARENT/Dockerfile" ] && [ "$PHASE4" -lt 50 ] && PHASE4=50
# If no deployment tasks exist and all sprints done, mark as N/A (100%)
if [ "$DEPLOY_TOTAL" -eq 0 ] && [ "$ALL_COMPLETE" = true ]; then
    PHASE4=100
fi
[ "$PHASE4" -gt 100 ] && PHASE4=100

# Overall progress status
OVERALL=$((( PHASE1 + PHASE2 + PHASE3 + PHASE4 ) / 4))
if [ "$PROGRESS" -ge 100 ]; then
    PROJECT_STATUS="✅ Complete"
elif [ "$PROGRESS" -ge 75 ]; then
    PROJECT_STATUS="🟢 On Track"
elif [ "$PROGRESS" -ge 50 ]; then
    PROJECT_STATUS="🟡 At Risk"
else
    PROJECT_STATUS="🔵 In Progress"
fi

##############################################################################
# TEAM TABLE
##############################################################################

TEAM_TABLE=""
TEAM_SEEN=""
if [ -d "$PROJECT_DIR/state/specialists" ]; then
    for LOG in "$PROJECT_DIR/state/specialists"/*.md; do
        [ -f "$LOG" ] || continue

        # Extract from frontmatter (support both old "state:" and new "agent:" keys)
        AGENT_TYPE=$(grep -E "^(agent|state):" "$LOG" 2>/dev/null | head -1 | sed 's/^[a-z]*://' | xargs || echo "")
        TASK_ID=$(grep -E "^task(_id)?:" "$LOG" 2>/dev/null | head -1 | sed 's/^[a-z_]*://' | xargs || echo "")
        TASK_TITLE=$(grep -E "^title:" "$LOG" 2>/dev/null | sed 's/title://' | xargs || echo "")

        # Skip files with placeholders
        echo "$TASK_ID" | grep -q "{" && continue
        echo "$TASK_TITLE" | grep -q "{" && continue
        [ -z "$AGENT_TYPE" ] && continue
        [ -z "$TASK_TITLE" ] && TASK_TITLE="(unknown)"

        # Skip duplicates (keep first seen)
        echo "$TEAM_SEEN" | grep -q ":$AGENT_TYPE:" && continue
        TEAM_SEEN="${TEAM_SEEN}:$AGENT_TYPE:"

        # Determine status from sprint file
        STATUS="🟢 Available"
        if [ -n "$TASK_ID" ]; then
            for SF in "$PROJECT_DIR"/sprints/sprint-*.md; do
                [ -f "$SF" ] || continue
                if grep -qE "^\| $TASK_ID \|.*\[COMPLETE\]" "$SF" 2>/dev/null; then
                    STATUS="✅ Done"
                    break
                elif grep -qE "^\| $TASK_ID \|.*\[IN PROGRESS\]" "$SF" 2>/dev/null; then
                    STATUS="🟡 Working"
                    break
                fi
            done
        fi

        TEAM_TABLE="${TEAM_TABLE}| $AGENT_TYPE | $TASK_TITLE | $STATUS |\n"
    done
fi

[ -z "$TEAM_TABLE" ] && TEAM_TABLE="| (No active specialists) | - | - |\n"

##############################################################################
# MILESTONE TABLE
##############################################################################

MILESTONE_TABLE="| Requirements | ✅ Done |\n| Architecture | ✅ Done |\n"
for ((i=1; i<=SPRINT_COUNT; i++)); do
    SF="$PROJECT_DIR/sprints/sprint-$i.md"
    if [ -f "$SF" ]; then
        TASKS=$(grep -cE "^\| [0-9]+\.[0-9A-Za-z]+ \|" "$SF" 2>/dev/null | tr -d '[:space:]')
        TASKS=${TASKS:-0}
        DONE=$(grep -E "^\| [0-9]+\.[0-9A-Za-z]+ \|" "$SF" 2>/dev/null | grep -c "\[COMPLETE\]" 2>/dev/null | tr -d '[:space:]')
        DONE=${DONE:-0}
        if [ "$DONE" -eq "$TASKS" ] && [ "$TASKS" -gt 0 ]; then
            MILESTONE_TABLE="${MILESTONE_TABLE}| Sprint $i | ✅ Complete |\n"
        elif [ "$DONE" -gt 0 ]; then
            MILESTONE_TABLE="${MILESTONE_TABLE}| Sprint $i | 🟡 $DONE/$TASKS |\n"
        else
            MILESTONE_TABLE="${MILESTONE_TABLE}| Sprint $i | 🔵 Not Started |\n"
        fi
    fi
done
MILESTONE_TABLE="${MILESTONE_TABLE}| Testing | $(status_emoji $PHASE3) $PHASE3% |\n"
MILESTONE_TABLE="${MILESTONE_TABLE}| Deployment | $(status_emoji $PHASE4) $PHASE4% |\n"

##############################################################################
# BURNDOWN CHART
##############################################################################

BURNDOWN="Story Points Remaining\n\n"
REMAINING=$TOTAL_SP
for SF in "$PROJECT_DIR"/sprints/sprint-*.md; do
    [ -f "$SF" ] || continue
    SNUM=$(basename "$SF" .md | sed 's/sprint-//')
    DONE_SP=$(grep -E "^\| [0-9]+\.[0-9A-Za-z]+ \|" "$SF" 2>/dev/null | grep -E "\[COMPLETE\]" | awk -F'|' '{gsub(/[^0-9]/,"",$4); if($4!="") sum+=$4} END{print sum+0}')
    REMAINING=$((REMAINING - DONE_SP))
    BAR=""
    [ "$TOTAL_SP" -gt 0 ] && BAR_LEN=$((REMAINING * 15 / TOTAL_SP)) || BAR_LEN=0
    for ((j=0; j<BAR_LEN; j++)); do BAR="${BAR}●"; done
    BURNDOWN="${BURNDOWN}$(printf "%3d" $REMAINING) |$BAR (S$SNUM)\n"
done
BURNDOWN="${BURNDOWN}  0 |_______________\n"

##############################################################################
# GENERATE OUTPUT
##############################################################################

[ -z "$COMPLETED_LIST" ] && COMPLETED_LIST="- (none yet)\n"
[ -z "$IN_PROGRESS_LIST" ] && IN_PROGRESS_LIST="- (none)\n"
[ -z "$NEXT_UP_LIST" ] && NEXT_UP_LIST="- (all complete)\n"

cat > "$OUTPUT_FILE" << EOF
# Progress Dashboard: $PROJECT_NAME

**Sprint**: $CURRENT_SPRINT of $SPRINT_COUNT
**Status**: $PROJECT_STATUS
**Last Updated**: $(date '+%Y-%m-%d %H:%M:%S')

---

## Overall Progress

\`\`\`
[$(make_bar $OVERALL 20)] $OVERALL% Complete

Phase 1: Planning      [$(make_bar $PHASE1 10)] $(printf "%3d" $PHASE1)% $(status_emoji $PHASE1)
Phase 2: Development   [$(make_bar $PHASE2 10)] $(printf "%3d" $PHASE2)% $(status_emoji $PHASE2)
Phase 3: Testing       [$(make_bar $PHASE3 10)] $(printf "%3d" $PHASE3)% $(status_emoji $PHASE3)
Phase 4: Deployment    [$(make_bar $PHASE4 10)] $(printf "%3d" $PHASE4)% $(status_emoji $PHASE4)
\`\`\`

---

## Sprint Summary

| Sprint | Goal | Tasks | Status |
|--------|------|-------|--------|
$(echo -e "$SPRINT_TABLE")

**Velocity**: $AVG_VELOCITY% average

---

## Task Progress

| Sprint | Completed | Total | Progress |
|--------|-----------|-------|----------|
$(echo -e "$TASK_TABLE")

**Total**: $COMPLETED_TASKS/$TOTAL_TASKS tasks ($PROGRESS%)

---

## Story Points

\`\`\`
$(echo -e "$BURNDOWN")
\`\`\`

**Total**: $TOTAL_SP | **Completed**: $COMPLETED_SP | **Remaining**: $((TOTAL_SP - COMPLETED_SP))

---

## Active Team

| Specialist | Current Task | Status |
|------------|--------------|--------|
$(echo -e "$TEAM_TABLE")

---

## Milestones

| Milestone | Status |
|-----------|--------|
$(echo -e "$MILESTONE_TABLE")

---

## Highlights

### Completed
$(echo -e "$COMPLETED_LIST")

### In Progress
$(echo -e "$IN_PROGRESS_LIST")

### Next Up
$(echo -e "$NEXT_UP_LIST")

---

**Auto-generated by**: auto-sync-progress.sh
**Update Frequency**: On SubagentStop + Manual sync
EOF

echo "✅ Dashboard generated: $OUTPUT_FILE"
