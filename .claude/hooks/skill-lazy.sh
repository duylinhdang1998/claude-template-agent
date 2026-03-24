#!/usr/bin/env bash
# skill-lazy.sh — SubagentStart hook
# Reads lazySkills from agent frontmatter and injects a skill menu
# into the subagent's context. Agent decides when to load each skill.
#
# Input:  stdin JSON payload with agent_type
# Output: JSON with hookSpecificOutput.additionalContext

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
AGENTS_DIR="$PROJECT_DIR/.claude/agents"
SKILLS_DIR="$PROJECT_DIR/.claude/skills"

# Read stdin payload
PAYLOAD=$(cat)
AGENT_TYPE=$(echo "$PAYLOAD" | grep -o '"agent_type":"[^"]*"' | head -1 | cut -d'"' -f4)

# Exit if no agent type
if [[ -z "$AGENT_TYPE" ]]; then
  exit 0
fi

# Find agent file
AGENT_FILE="$AGENTS_DIR/${AGENT_TYPE}.md"
if [[ ! -f "$AGENT_FILE" ]]; then
  exit 0
fi

# Parse lazySkills from frontmatter
# Extract between --- markers, find lazySkills block, get skill names
SKILLS=()
IN_BLOCK=false
IN_FRONTMATTER=false
FRONTMATTER_COUNT=0

while IFS= read -r line; do
  if [[ "$line" == "---" ]]; then
    FRONTMATTER_COUNT=$((FRONTMATTER_COUNT + 1))
    if [[ $FRONTMATTER_COUNT -ge 2 ]]; then
      break
    fi
    IN_FRONTMATTER=true
    continue
  fi

  if [[ "$IN_FRONTMATTER" != true ]]; then
    continue
  fi

  # Detect lazySkills: block
  if [[ "$line" =~ ^lazySkills: ]]; then
    IN_BLOCK=true
    continue
  fi

  # If in block and line starts with "  - ", extract skill name
  if [[ "$IN_BLOCK" == true ]]; then
    if [[ "$line" =~ ^[[:space:]]*-[[:space:]]+(.*) ]]; then
      SKILL_NAME="${BASH_REMATCH[1]}"
      SKILL_NAME=$(echo "$SKILL_NAME" | xargs) # trim
      if [[ -n "$SKILL_NAME" ]]; then
        SKILLS+=("$SKILL_NAME")
      fi
    else
      # Non-list line = end of block
      IN_BLOCK=false
    fi
  fi
done < "$AGENT_FILE"

# Exit if no skills found
if [[ ${#SKILLS[@]} -eq 0 ]]; then
  exit 0
fi

# Build skill menu with descriptions
LINES="══════════════════════════════════════════════════════════════\n"
LINES+="  **LAZY SKILLS — SKILL LOADING RULES**\n"
LINES+="══════════════════════════════════════════════════════════════\n\n"
LINES+="## Available Skills\n\n"
LINES+="**MANDATORY**: If your PM prompt contains a SKILLS block, you MUST load\n"
LINES+="the listed skills via Skill tool BEFORE writing any application code.\n"
LINES+="Record loaded skills in your state file \`skills_used:\` field.\n\n"
LINES+="**NO SKILLS block in prompt?** Load skills only if you genuinely need\n"
LINES+="reference patterns for your task. Simple scaffold/config = no skills needed.\n\n"

for SKILL_NAME in "${SKILLS[@]}"; do
  SKILL_FILE="$SKILLS_DIR/$SKILL_NAME/SKILL.md"
  DESC="$SKILL_NAME"

  if [[ -f "$SKILL_FILE" ]]; then
    # Extract description from SKILL.md frontmatter (first 20 lines)
    RAW_DESC=$(head -20 "$SKILL_FILE" | grep -m1 "^description:" | sed 's/^description:[[:space:]]*//')
    if [[ -n "$RAW_DESC" ]]; then
      # Truncate to 100 chars
      DESC="${RAW_DESC:0:100}"
    fi
  fi

  LINES+="- **$SKILL_NAME**: $DESC\n"
done

# Output JSON for SubagentStart hook
# Escape for JSON: quotes and newlines
CONTEXT=$(printf '%b' "$LINES" | sed 's/"/\\"/g' | awk '{printf "%s\\n", $0}' | sed 's/\\n$//')

cat <<EOF
{"hookSpecificOutput":{"hookEventName":"SubagentStart","additionalContext":"$CONTEXT"}}
EOF

exit 0
