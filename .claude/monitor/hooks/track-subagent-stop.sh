#!/bin/bash
# Hook: SubagentStop - Remove completed subagent from running list
# Matches by agent_type (FIFO per type, not global FIFO)

STATE_FILE="${CLAUDE_PROJECT_DIR}/.claude/monitor/state/activity.json"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

[ ! -f "$STATE_FILE" ] && exit 0

# Read agent_type from stdin JSON
INPUT=$(cat)
AGENT_TYPE=""
if command -v jq &>/dev/null; then
    AGENT_TYPE=$(echo "$INPUT" | jq -r '.agent_type // .subagent_type // .type // ""' 2>/dev/null)
fi

# Skip non-specialist agent types
case "$AGENT_TYPE" in
  general-purpose|Explore|Plan|statusline-setup|claude-code-guide)
    exit 0
    ;;
esac

node -e "
const fs = require('fs');
const state = JSON.parse(fs.readFileSync('$STATE_FILE', 'utf8'));
const agentType = '$AGENT_TYPE';

// Find oldest running agent of SAME type (FIFO per type)
let idx = -1;
if (agentType) {
  idx = state.subagents.findIndex(a => a.status === 'running' && a.type === agentType);
}
if (idx === -1) {
  idx = state.subagents.findIndex(a => a.status === 'running');
}

if (idx !== -1) {
  const agent = state.subagents[idx];
  state.history.push({
    event: 'subagent_stop',
    agent: agent.type || 'unknown',
    agentName: agent.name || 'unknown',
    timestamp: '$TIMESTAMP'
  });
  state.subagents.splice(idx, 1);
  if (state.history.length > 20) state.history = state.history.slice(-20);
  fs.writeFileSync('$STATE_FILE', JSON.stringify(state, null, 2));
}
"

exit 0
