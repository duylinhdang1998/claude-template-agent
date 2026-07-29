#!/bin/bash
##############################################################################
# subagent-inject-wireframe.sh
#
# SubagentStart hook — Auto-inject UI CONTEXT into UI specialists via
# hookSpecificOutput.additionalContext (structured JSON output).
#
# Injects TWO things so the agent never has to "remember to go read a file":
#   1. DESIGN SYSTEM  — the project's design tokens (user-provided file).
#                       This is the fix for "frontend codes wrong design system".
#   2. WIREFRAME       — the screen layout for the current TASK ID (if any).
#
# UI specialists: meta-react-architect, apple-ios-lead, google-android-lead
#
# Trigger: SubagentStart
# Output : JSON { hookSpecificOutput: { additionalContext: "..." } }
##############################################################################

INPUT=$(cat)

# --- Extract agent type + prompt (jq with grep fallback) --------------------
if command -v jq &>/dev/null; then
  SUBAGENT_TYPE=$(echo "$INPUT" | jq -r '.agent_type // .subagent_type // .type // empty' 2>/dev/null)
  PROMPT=$(echo "$INPUT" | jq -r '.prompt // empty' 2>/dev/null)
else
  SUBAGENT_TYPE=$(echo "$INPUT" | grep -o '"agent_type":"[^"]*"' | head -1 | cut -d'"' -f4)
  [ -z "$SUBAGENT_TYPE" ] && SUBAGENT_TYPE=$(echo "$INPUT" | grep -o '"subagent_type":"[^"]*"' | head -1 | cut -d'"' -f4)
  [ -z "$SUBAGENT_TYPE" ] && SUBAGENT_TYPE=$(echo "$INPUT" | grep -o '"type":"[^"]*"' | head -1 | cut -d'"' -f4)
  PROMPT=$(echo "$INPUT" | grep -o '"prompt":"[^"]*"' | head -1 | cut -d'"' -f4)
fi

# Only UI specialists need this context.
case "$SUBAGENT_TYPE" in
  meta-react-architect|apple-ios-lead|google-android-lead) ;;
  *) exit 0 ;;
esac

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# Prefer the user's project dir (set for all hooks; correct in both local and
# plugin-installed contexts); fall back to the repo-relative path for local dev.
ROOT_DIR="${CLAUDE_PROJECT_DIR:-$(cd "$SCRIPT_DIR/../.." && pwd)}"

MAX_DS_LINES=500     # cap design-system injection to stay lean
CONTEXT=""

##############################################################################
# 1) DESIGN SYSTEM — locate the project's design-system file (first match wins)
##############################################################################
DS_CANDIDATES=(
  "$ROOT_DIR/.project/design-system.md"
  "$ROOT_DIR/.project/design/design-system.md"
  "$ROOT_DIR/.project/documentation/design-system.md"
  "$ROOT_DIR/.project/wireframes/design-system.md"
  "$ROOT_DIR/design-system.md"
  "$ROOT_DIR/DESIGN.md"
  "$ROOT_DIR/references/DESIGN.md"
  "$ROOT_DIR/app/design-system.md"
  "$ROOT_DIR/app/DESIGN.md"
)
DS_FILE=""
for cand in "${DS_CANDIDATES[@]}"; do
  if [ -f "$cand" ]; then DS_FILE="$cand"; break; fi
done

if [ -n "$DS_FILE" ]; then
  DS_REL="${DS_FILE#$ROOT_DIR/}"
  DS_CONTENT=$(head -n "$MAX_DS_LINES" "$DS_FILE")
  DS_TRUNC=""
  [ "$(wc -l < "$DS_FILE")" -gt "$MAX_DS_LINES" ] && DS_TRUNC="

… (truncated at ${MAX_DS_LINES} lines — read \`${DS_REL}\` in full for the rest)"
  CONTEXT+="══════════════════════════════════════════════════════════════
🎨 AUTO-INJECTED DESIGN SYSTEM — source of truth: \`${DS_REL}\`
══════════════════════════════════════════════════════════════

**MANDATORY — use ONLY the tokens below (colors, type scale, spacing, radius,
shadows). Do NOT invent hex values, arbitrary px, or one-off font sizes.**
If a value you need is missing here, ask the PM/user — do NOT guess.
\`google-code-reviewer\` will 🔴 REJECT ad-hoc values that bypass this system.

${DS_CONTENT}${DS_TRUNC}

"
else
  CONTEXT+="══════════════════════════════════════════════════════════════
🎨 DESIGN SYSTEM — NOT FOUND
══════════════════════════════════════════════════════════════

No design-system file was found at any known location:
  .project/design-system.md · design-system.md · DESIGN.md · references/DESIGN.md
**STOP before inventing UI tokens.** Ask the PM/user to provide the design
system file (place it at \`.project/design-system.md\`), OR load the design/UI
craft skill (\`ui-ux-pro-max\`) if the project has no formal system. Do NOT
hard-code arbitrary colors/spacing/fonts.

"
fi

##############################################################################
# 2) WIREFRAME — inject only if not already in prompt and a mapping exists
##############################################################################
if ! echo "$PROMPT" | grep -q "🎨 WIREFRAME"; then
  TASK_ID=$(echo "$PROMPT" | grep -oE "TASK ID: [0-9]+\.[0-9]+" | head -1 | awk '{print $3}')
  [ -z "$TASK_ID" ] && TASK_ID=$(echo "$PROMPT" | grep -oE "Task [0-9]+\.[0-9SRQ]+" | head -1 | awk '{print $2}')

  if [ -n "$TASK_ID" ]; then
    SPRINT=$(echo "$TASK_ID" | cut -d'.' -f1)
    SPRINT_FILE="$ROOT_DIR/.project/sprints/sprint-$SPRINT.md"
    if [ -f "$SPRINT_FILE" ]; then
      WIREFRAME_FILE=$(grep "| $TASK_ID |" "$SPRINT_FILE" 2>/dev/null | awk -F'|' '{print $(NF-1)}' | tr -d ' ')
      if [ -n "$WIREFRAME_FILE" ] && [ "$WIREFRAME_FILE" != "-" ]; then
        WIREFRAME_PATH="$ROOT_DIR/.project/wireframes/screens/$WIREFRAME_FILE"
        [ -f "$WIREFRAME_PATH" ] || WIREFRAME_PATH="$ROOT_DIR/.project/wireframes/$WIREFRAME_FILE"
        if [ -f "$WIREFRAME_PATH" ]; then
          CONTEXT+="══════════════════════════════════════════════════════════════
🎨 AUTO-INJECTED WIREFRAME FOR TASK $TASK_ID
══════════════════════════════════════════════════════════════

$(cat "$WIREFRAME_PATH")

📋 Follow the layout exactly · implement ALL states (loading/error/empty/success)
· match mobile/desktop layouts if both shown.
"
        else
          CONTEXT+="⚠️ WIREFRAME NOT FOUND — Task $TASK_ID expects \`$WIREFRAME_FILE\` but it is missing. Check the sprint file / wireframes dir.
"
        fi
      fi
    fi
  fi
fi

##############################################################################
# Emit combined additionalContext
##############################################################################
[ -z "$CONTEXT" ] && exit 0

if command -v jq &>/dev/null; then
  jq -n --arg ctx "$CONTEXT" '{
    "hookSpecificOutput": {
      "hookEventName": "SubagentStart",
      "additionalContext": $ctx
    }
  }'
elif command -v python3 &>/dev/null; then
  CTX="$CONTEXT" python3 -c 'import json,os;print(json.dumps({"hookSpecificOutput":{"hookEventName":"SubagentStart","additionalContext":os.environ["CTX"]}}))'
else
  ESCAPED=$(printf '%s' "$CONTEXT" | sed 's/\\/\\\\/g; s/"/\\"/g' | sed ':a;N;$!ba;s/\n/\\n/g')
  echo "{\"hookSpecificOutput\":{\"hookEventName\":\"SubagentStart\",\"additionalContext\":\"$ESCAPED\"}}"
fi

exit 0
