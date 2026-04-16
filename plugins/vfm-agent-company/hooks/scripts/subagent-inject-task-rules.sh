#!/bin/bash
##############################################################################
# subagent-inject-task-rules.sh
#
# SubagentStart hook - Inject state persistence & task completion rules
# into every specialist agent's context via additionalContext.
#
# This is the SINGLE mechanism for state file creation.
# Agent creates its own state file from template on first action.
#
# Trigger: SubagentStart
# Output: JSON { hookSpecificOutput: { additionalContext: "..." } }
##############################################################################

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

# Build context with ACTUAL agent type injected
CONTEXT=$(cat << RULES_EOF
══════════════════════════════════════════════════════════════
  **AUTO-INJECTED TASK RULES**
  **CRITICAL** **CRITICAL** **CRITICAL** **CRITICAL**
══════════════════════════════════════════════════════════════

## ⚠️ CRITICAL: State File (auto-injected for ${AGENT_TYPE})

Your agent type is: **${AGENT_TYPE}**

Extract your TASK ID from the prompt (look for "TASK ID: X.Y").
Your state file path: \`.project/state/specialists/${AGENT_TYPE}-{TASK_ID}.md\`

### First Action (BEFORE writing ANY code):

1. Find TASK ID from your prompt (e.g., "TASK ID: 1.1" → task_id = "1.1")
2. Check if state file exists: \`.project/state/specialists/${AGENT_TYPE}-{TASK_ID}.md\`
3. **If file does NOT exist** → create from template:
   \`\`\`bash
   cp .claude/templates/state/specialist-task.md ".project/state/specialists/${AGENT_TYPE}-{TASK_ID}.md"
   \`\`\`
   Then \`Read\` the file → \`Edit\` to fill ALL frontmatter fields:
   - agent: ${AGENT_TYPE}
   - task_id: {your task ID}
   - sprint: {sprint number}
   - project: {from your prompt}
   - title: {task title}
   - description: {15-25 words — verb + what + context}
   - started: {today's date}
4. **If file EXISTS** → \`Read\` it → \`Edit\` the \`description:\` field if still placeholder

### ⚠️ Do NOT use Write tool on state files! Always Read → Edit.
The YAML frontmatter structure MUST stay intact.

### On completion:
1. Edit \`status:\` → \`COMPLETE\`
2. Edit \`completed:\` → today's date
3. Edit \`skills_used:\` → list skills you loaded via Skill tool
4. Update \`## Progress\` checklist — mark items \`[x]\`
5. Update \`## Files Modified\` table
6. Fill \`## Completion Notes\` with key decisions and test results

**NEVER start from scratch when user says "continue" — resume from state file!**

## ⚠️ CRITICAL: Task Completion Checklist

When you finish a task:
- [ ] State file updated (status, completed, skills_used, progress, files, notes)
- [ ] Sprint file updated: Task → [COMPLETE] in both Task Details and Sprint Backlog
- [ ] Output **Completion Report** to PM
- [ ] DO NOT create new .md files outside your scope
RULES_EOF
)

# Output as JSON
if command -v jq &>/dev/null; then
    jq -n --arg ctx "$CONTEXT" '{
        "hookSpecificOutput": {
            "hookEventName": "SubagentStart",
            "additionalContext": $ctx
        }
    }'
else
    ESCAPED=$(echo "$CONTEXT" | sed 's/\\/\\\\/g; s/"/\\"/g' | sed ':a;N;$!ba;s/\n/\\n/g')
    echo "{\"hookSpecificOutput\":{\"hookEventName\":\"SubagentStart\",\"additionalContext\":\"$ESCAPED\"}}"
fi

exit 0
