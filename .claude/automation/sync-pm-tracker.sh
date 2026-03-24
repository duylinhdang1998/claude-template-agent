#!/bin/bash

##############################################################################
# sync-pm-tracker.sh
#
# Auto-syncs ALL tracker state files from project artifacts.
# Ensures trackers always reflect the actual project state.
#
# Syncs:
#   1. pm-tracker.md  — from sprint files + specialist state files
#   2. ba-tracker.md  — deliverables checked from artifact existence
#
# Usage: bash .claude/automation/sync-pm-tracker.sh [--event "description"]
#
# Called by PM at every transition point:
#   - After each Batch completes (0/1/2/3)
#   - After BAT
#   - After sprint closure
#   - On "continue" command
#
# Source of truth:
#   - Sprint files (.project/sprints/sprint-*.md) → task statuses
#   - Specialist state files (.project/state/specialists/) → team status
#   - Project artifacts (srs.md, architecture.md, etc.) → deliverable status
#   - pm-tracker.md Activity Log → append only
##############################################################################

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
PROJECT_DIR="$ROOT_DIR/.project"
TRACKER="$PROJECT_DIR/state/pm-tracker.md"
SPRINTS_DIR="$PROJECT_DIR/sprints"
SPECIALISTS_DIR="$PROJECT_DIR/state/specialists"

EVENT_DESC="${1:---event}"
shift 2>/dev/null || true
# If --event flag, grab the description
if [[ "$EVENT_DESC" == "--event" ]]; then
  EVENT_DESC="${1:-sync}"
fi

# Verify tracker exists
if [[ ! -f "$TRACKER" ]]; then
  echo "Error: pm-tracker.md not found at $TRACKER"
  exit 1
fi

##############################################################################
# 1. SCAN SPRINT FILES — determine statuses
##############################################################################

TOTAL_SPRINTS=0
COMPLETED_SPRINTS=0
CURRENT_SPRINT=""
CURRENT_SPRINT_STATUS=""

# Collect sprint info
declare -a SPRINT_NUMS=()
declare -a SPRINT_NAMES=()
declare -a SPRINT_DATES=()
declare -a SPRINT_STATUSES=()

for SPRINT_FILE in "$SPRINTS_DIR"/sprint-*.md; do
  [[ -f "$SPRINT_FILE" ]] || continue
  TOTAL_SPRINTS=$((TOTAL_SPRINTS + 1))

  FILENAME=$(basename "$SPRINT_FILE")
  SPRINT_NUM=$(echo "$FILENAME" | grep -o '[0-9]\+')

  # Extract sprint name from first heading
  SPRINT_NAME=$(head -1 "$SPRINT_FILE" | sed 's/^# Sprint [0-9]*: //')

  # Extract duration line
  SPRINT_DATE=$(grep -m1 "^\*\*Duration\*\*:" "$SPRINT_FILE" | sed 's/.*: //' || echo "TBD")

  # Count tasks and completed tasks from backlog table
  TOTAL_TASKS=$(grep -E '^\| [0-9]+\.' "$SPRINT_FILE" | wc -l | tr -d ' ')
  COMPLETE_TASKS=$(grep -E '^\| [0-9]+\.' "$SPRINT_FILE" | grep -c '\[COMPLETE\]' || true)

  # Determine sprint status
  if [[ "$TOTAL_TASKS" -gt 0 && "$COMPLETE_TASKS" -eq "$TOTAL_TASKS" ]]; then
    STATUS="COMPLETE"
    COMPLETED_SPRINTS=$((COMPLETED_SPRINTS + 1))
  elif [[ "$COMPLETE_TASKS" -gt 0 ]]; then
    STATUS="IN_PROGRESS"
  else
    STATUS="PLANNED"
  fi

  SPRINT_NUMS+=("$SPRINT_NUM")
  SPRINT_NAMES+=("$SPRINT_NAME")
  SPRINT_DATES+=("$SPRINT_DATE")
  SPRINT_STATUSES+=("$STATUS")

  # Track current sprint (first non-complete, or last if all complete)
  if [[ -z "$CURRENT_SPRINT" && "$STATUS" != "COMPLETE" ]]; then
    CURRENT_SPRINT="Sprint $SPRINT_NUM"
    CURRENT_SPRINT_STATUS="$STATUS"
  fi
done

# If all sprints complete
if [[ -z "$CURRENT_SPRINT" && "$TOTAL_SPRINTS" -gt 0 ]]; then
  LAST_IDX=$((TOTAL_SPRINTS - 1))
  CURRENT_SPRINT="Sprint ${SPRINT_NUMS[$LAST_IDX]} (DELIVERED)"
  CURRENT_SPRINT_STATUS="COMPLETE"
fi

##############################################################################
# 2. CALCULATE PHASE COMPLETION
##############################################################################

# Phase logic:
# Phase 0 (Init): always done if sprints exist
# Phase 1 (Requirements): done if srs.md exists
# Phase 2 (Design): done if architecture.md has real content
# Phase 3 (Development): done if all dev tasks (.1-.9) in all sprints are COMPLETE
# Phase 4 (Testing): done if all .Q tasks are COMPLETE
# Phase 5-6 (Packaging/Deploy): done if project delivered (all sprints COMPLETE)
# Phase 7 (Release): done if all sprints COMPLETE (CEO sign-off implied)

P0="[ ]"; P1="[ ]"; P2="[ ]"; P3="[ ]"; P4="[ ]"; P5="[ ]"; P6="[ ]"; P7="[ ]"

# Phase 0: Init
[[ -d "$SPRINTS_DIR" ]] && P0="[x]"

# Phase 1: Requirements
[[ -f "$PROJECT_DIR/requirements/srs.md" ]] && P1="[x]"

# Phase 2: Design
if [[ -f "$PROJECT_DIR/documentation/architecture.md" ]]; then
  ARCH_LINES=$(wc -l < "$PROJECT_DIR/documentation/architecture.md" | tr -d ' ')
  [[ "$ARCH_LINES" -gt 20 ]] && P2="[x]"
fi

# Phase 3: Development — all dev tasks (not .S, .R, .Q) COMPLETE across all sprints
ALL_DEV_DONE=true
for SPRINT_FILE in "$SPRINTS_DIR"/sprint-*.md; do
  [[ -f "$SPRINT_FILE" ]] || continue
  # Dev tasks = rows matching N.1, N.2, etc. (not N.S, N.R, N.Q)
  DEV_TOTAL=$(grep -E '^\| [0-9]+\.[0-9]+' "$SPRINT_FILE" | wc -l | tr -d ' ')
  DEV_COMPLETE=$(grep -E '^\| [0-9]+\.[0-9]+' "$SPRINT_FILE" | grep -c '\[COMPLETE\]' || true)
  if [[ "$DEV_TOTAL" -gt 0 && "$DEV_COMPLETE" -lt "$DEV_TOTAL" ]]; then
    ALL_DEV_DONE=false
  fi
done
[[ "$ALL_DEV_DONE" == true && "$TOTAL_SPRINTS" -gt 0 ]] && P3="[x]"

# Phase 4: Testing — all .Q tasks COMPLETE
ALL_QA_DONE=true
for SPRINT_FILE in "$SPRINTS_DIR"/sprint-*.md; do
  [[ -f "$SPRINT_FILE" ]] || continue
  QA_LINE=$(grep -E '^\| [0-9]+\.Q' "$SPRINT_FILE" || true)
  if [[ -n "$QA_LINE" && ! "$QA_LINE" =~ \[COMPLETE\] ]]; then
    ALL_QA_DONE=false
  fi
done
[[ "$ALL_QA_DONE" == true && "$TOTAL_SPRINTS" -gt 0 ]] && P4="[x]"

# Phase 5-6-7: All sprints COMPLETE = delivered
if [[ "$TOTAL_SPRINTS" -gt 0 && "$COMPLETED_SPRINTS" -eq "$TOTAL_SPRINTS" ]]; then
  P5="[x]"; P6="[x]"; P7="[x]"
fi

##############################################################################
# 3. CALCULATE OVERALL PROGRESS
##############################################################################

CHECKED=0
for P in "$P0" "$P1" "$P2" "$P3" "$P4" "$P5" "$P6" "$P7"; do
  [[ "$P" == "[x]" ]] && CHECKED=$((CHECKED + 1))
done
PROGRESS=$((CHECKED * 100 / 8))

##############################################################################
# 4. SCAN SPECIALIST STATE FILES — team status
##############################################################################

TEAM_LINES=""
for STATE_FILE in "$SPECIALISTS_DIR"/*.md; do
  [[ -f "$STATE_FILE" ]] || continue
  AGENT=$(grep -m1 '^agent:' "$STATE_FILE" | sed 's/^agent: *//' || true)
  TASK_ID=$(grep -m1 '^task_id:' "$STATE_FILE" | sed 's/^task_id: *//' || true)
  TITLE=$(grep -m1 '^title:' "$STATE_FILE" | sed 's/^title: *//' || true)
  STATUS=$(grep -m1 '^status:' "$STATE_FILE" | sed 's/^status: *//' || true)
  SPRINT=$(grep -m1 '^sprint:' "$STATE_FILE" | sed 's/^sprint: *//' || true)

  # Only show latest task per agent (highest task_id)
  TEAM_LINES+="| $AGENT | $TASK_ID: $TITLE | $STATUS | Sprint $SPRINT |\n"
done

# Deduplicate: keep last entry per agent (highest task)
if [[ -n "$TEAM_LINES" ]]; then
  TEAM_TABLE=$(printf '%b' "$TEAM_LINES" | sort -t'|' -k2,2 | awk -F'|' '
    { agent=$2; gsub(/^[ \t]+|[ \t]+$/, "", agent); data[agent]=$0 }
    END { for (a in data) print data[a] }
  ')
else
  TEAM_TABLE="| (no specialists) | - | - | - |"
fi

##############################################################################
# 5. BUILD SPRINT TIMELINE TABLE
##############################################################################

TIMELINE_LINES=""
for i in "${!SPRINT_NUMS[@]}"; do
  TIMELINE_LINES+="| Sprint ${SPRINT_NUMS[$i]} | ${SPRINT_DATES[$i]} | ${SPRINT_NAMES[$i]} | ${SPRINT_STATUSES[$i]} |\n"
done

##############################################################################
# 6. READ EXISTING ACTIVITY LOG (preserve it)
##############################################################################

ACTIVITY_LOG=""
IN_LOG=false
while IFS= read -r line; do
  if [[ "$line" == "## Activity Log" ]]; then
    IN_LOG=true
    continue
  fi
  if [[ "$IN_LOG" == true ]]; then
    if [[ "$line" == "---" ]]; then
      break
    fi
    if [[ "$line" =~ ^- ]]; then
      ACTIVITY_LOG+="$line\n"
    fi
  fi
done < "$TRACKER"

# Append new event if provided
TODAY=$(date +%Y-%m-%d)
if [[ "$EVENT_DESC" != "sync" ]]; then
  NEW_ENTRY="- $TODAY: $EVENT_DESC"
  # Only add if not duplicate of last entry
  LAST_ENTRY=$(printf '%b' "$ACTIVITY_LOG" | tail -1)
  if [[ "$NEW_ENTRY" != "$LAST_ENTRY" ]]; then
    ACTIVITY_LOG+="$NEW_ENTRY\n"
  fi
fi

##############################################################################
# 7. READ EXISTING SPRINT 0 DECISIONS (preserve them)
##############################################################################

DECISIONS=""
IN_DECISIONS=false
HEADER_FOUND=false
while IFS= read -r line; do
  if [[ "$line" == "## Sprint 0 Decisions" ]]; then
    IN_DECISIONS=true
    continue
  fi
  if [[ "$IN_DECISIONS" == true ]]; then
    if [[ "$line" == "---" ]]; then
      break
    fi
    DECISIONS+="$line\n"
  fi
done < "$TRACKER"

##############################################################################
# 8. READ EXISTING GATE CHECKS (preserve them)
##############################################################################

GATES=""
IN_GATES=false
while IFS= read -r line; do
  if [[ "$line" == "## Gate Checks" ]]; then
    IN_GATES=true
    continue
  fi
  if [[ "$IN_GATES" == true ]]; then
    if [[ "$line" == "---" ]]; then
      break
    fi
    GATES+="$line\n"
  fi
done < "$TRACKER"

##############################################################################
# 9. EXTRACT PROJECT NAME AND STARTED DATE FROM TRACKER
##############################################################################

PROJECT_NAME=$(head -1 "$TRACKER" | sed 's/^# PM Progress Tracker - //')
STARTED_DATE=$(grep -m1 'Started' "$TRACKER" 2>/dev/null | sed 's/.*Started\*\*: *//' | tr -d ' ')
[[ -z "$STARTED_DATE" ]] && STARTED_DATE="$TODAY"

##############################################################################
# 10. WRITE UPDATED TRACKER
##############################################################################

cat > "$TRACKER" << ENDOFFILE
# PM Progress Tracker - $PROJECT_NAME

**PM**: Project Manager
**Started**: $STARTED_DATE
**Current Sprint**: $CURRENT_SPRINT
**Overall Progress**: ${PROGRESS}%

---

## Project Timeline

| Sprint | Dates | Focus | Status |
|--------|-------|-------|--------|
$(printf '%b' "$TIMELINE_LINES")

---

## Phase Completion

- $P0 Phase 0: Project Initialization
- $P1 Phase 1: Requirements (BA)
- $P2 Phase 2: System Design (CTO)
- $P3 Phase 3: Development
- $P4 Phase 4: Testing
- $P5 Phase 5: Packaging
- $P6 Phase 6: Deployment
- $P7 Phase 7: Release

---

## Sprint 0 Decisions

$(printf '%b' "$DECISIONS")

---

## Gate Checks

$(printf '%b' "$GATES")

---

## Team Status

| Specialist | Current Task | Status | Sprint |
|-----------|-------------|--------|--------|
$TEAM_TABLE

---

## Activity Log

$(printf '%b' "$ACTIVITY_LOG")

---

## Blockers

None currently.

---

**Last Updated**: $TODAY
**Updated By**: sync-pm-tracker.sh
ENDOFFILE

echo "✅ pm-tracker.md synced (Progress: ${PROGRESS}%, Sprint: $CURRENT_SPRINT)"

##############################################################################
# 11. SYNC ba-tracker.md DELIVERABLES
##############################################################################

BA_TRACKER="$PROJECT_DIR/state/ba-tracker.md"

if [[ -f "$BA_TRACKER" ]]; then
  BA_CHANGED=false

  # Check each deliverable against actual artifact existence
  # Requirements gathered → srs.md exists
  if [[ -f "$PROJECT_DIR/requirements/srs.md" ]]; then
    if grep -q '^\- \[ \] Requirements gathered' "$BA_TRACKER" 2>/dev/null; then
      sed -i '' 's/^- \[ \] Requirements gathered/- [x] Requirements gathered/' "$BA_TRACKER"
      BA_CHANGED=true
    fi
  fi

  # SRS document → srs.md exists
  if [[ -f "$PROJECT_DIR/requirements/srs.md" ]]; then
    if grep -q '^\- \[ \] SRS document' "$BA_TRACKER" 2>/dev/null; then
      sed -i '' 's/^- \[ \] SRS document/- [x] SRS document/' "$BA_TRACKER"
      BA_CHANGED=true
    fi
  fi

  # User stories → user-stories.md exists
  if [[ -f "$PROJECT_DIR/requirements/user-stories.md" ]]; then
    if grep -q '^\- \[ \] User stories' "$BA_TRACKER" 2>/dev/null; then
      sed -i '' 's/^- \[ \] User stories/- [x] User stories/' "$BA_TRACKER"
      BA_CHANGED=true
    fi
  fi

  # MoSCoW prioritization → srs.md contains "MoSCoW" or "MUST HAVE"
  if [[ -f "$PROJECT_DIR/requirements/srs.md" ]] && grep -qi 'MoSCoW\|MUST HAVE' "$PROJECT_DIR/requirements/srs.md" 2>/dev/null; then
    if grep -q '^\- \[ \] MoSCoW' "$BA_TRACKER" 2>/dev/null; then
      sed -i '' 's/^- \[ \] MoSCoW/- [x] MoSCoW/' "$BA_TRACKER"
      BA_CHANGED=true
    fi
  fi

  # Hand off to CTO → architecture.md OR tech-stack.md has real content (>20 lines)
  CTO_DONE=false
  if [[ -f "$PROJECT_DIR/documentation/architecture.md" ]]; then
    ARCH_L=$(wc -l < "$PROJECT_DIR/documentation/architecture.md" | tr -d ' ')
    [[ "$ARCH_L" -gt 20 ]] && CTO_DONE=true
  fi
  if [[ -f "$PROJECT_DIR/documentation/tech-stack.md" ]]; then
    TECH_L=$(wc -l < "$PROJECT_DIR/documentation/tech-stack.md" | tr -d ' ')
    [[ "$TECH_L" -gt 20 ]] && CTO_DONE=true
  fi
  if [[ "$CTO_DONE" == true ]]; then
    if grep -q '^\- \[ \] Hand off to CTO' "$BA_TRACKER" 2>/dev/null; then
      sed -i '' 's/^- \[ \] Hand off to CTO/- [x] Hand off to CTO/' "$BA_TRACKER"
      BA_CHANGED=true
    fi
  fi

  # Update Last Updated timestamp
  if [[ "$BA_CHANGED" == true ]]; then
    sed -i '' "s/^\*\*Last Updated\*\*:.*/\*\*Last Updated\*\*: $TODAY/" "$BA_TRACKER"
    sed -i '' "s/^\*\*Updated By\*\*:.*/\*\*Updated By\*\*: sync-pm-tracker.sh/" "$BA_TRACKER"
    echo "✅ ba-tracker.md synced (deliverables updated)"
  else
    echo "✅ ba-tracker.md already up-to-date"
  fi
else
  echo "ℹ️  ba-tracker.md not found (skipped)"
fi
