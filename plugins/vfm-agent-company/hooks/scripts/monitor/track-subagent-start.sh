#!/bin/bash
# Hook: SubagentStart - Read agent type from stdin JSON, get name from agents/*.md

STATE_FILE="${CLAUDE_PROJECT_DIR}/.claude/monitor/state/activity.json"
AGENTS_DIR="${CLAUDE_PROJECT_DIR}/.claude/agents"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
DEBUG_LOG="/tmp/subagent-hook-debug.log"

AGENT_TYPE="unknown"
AGENT_NAME="unknown"
DESCRIPTION=""

# Read JSON from stdin (SubagentStart passes agent info via stdin)
INPUT=$(cat)

# Debug log
echo "=== $(date) ===" >> "$DEBUG_LOG"
echo "INPUT: $INPUT" >> "$DEBUG_LOG"
echo "ENV CLAUDE_SUBAGENT_TYPE: $CLAUDE_SUBAGENT_TYPE" >> "$DEBUG_LOG"

# Extract agent_type and description from JSON
if [ -n "$INPUT" ]; then
  AGENT_TYPE=$(echo "$INPUT" | jq -r '.agent_type // .subagent_type // .type // "unknown"' 2>/dev/null || echo "unknown")
  DESCRIPTION=$(echo "$INPUT" | jq -r '.description // ""' 2>/dev/null || echo "")
  echo "Parsed AGENT_TYPE: $AGENT_TYPE" >> "$DEBUG_LOG"
fi

# Fallback to env var
[ "$AGENT_TYPE" = "unknown" ] && [ -n "$CLAUDE_SUBAGENT_TYPE" ] && AGENT_TYPE="$CLAUDE_SUBAGENT_TYPE"
echo "Final AGENT_TYPE: $AGENT_TYPE" >> "$DEBUG_LOG"

# Skip non-specialist agent types (not tracked in monitor)
case "$AGENT_TYPE" in
  general-purpose|Explore|Plan|statusline-setup|claude-code-guide)
    echo "Skipping non-specialist type: $AGENT_TYPE" >> "$DEBUG_LOG"
    exit 0
    ;;
esac

# Look up agent name from .claude/agents/{type}.md frontmatter
AGENT_FILE="$AGENTS_DIR/${AGENT_TYPE}.md"
if [ -f "$AGENT_FILE" ]; then
  # Priority: agentName > name > type
  # Extract 'agentName:' first (display name like "Michael Zhang")
  AGENT_NAME=$(awk '/^---$/{p=1-p;next} p && /^agentName:/{sub(/^agentName:[[:space:]]*/, ""); print; exit}' "$AGENT_FILE" 2>/dev/null)

  # Fallback to 'name:' if no agentName
  if [ -z "$AGENT_NAME" ]; then
    AGENT_NAME=$(awk '/^---$/{p=1-p;next} p && /^name:/{sub(/^name:[[:space:]]*/, ""); print; exit}' "$AGENT_FILE" 2>/dev/null)
  fi

  [ -z "$AGENT_NAME" ] && AGENT_NAME="$AGENT_TYPE"
  echo "Found AGENT_NAME: $AGENT_NAME from $AGENT_FILE" >> "$DEBUG_LOG"
fi

# Fallback
[ -z "$AGENT_NAME" ] || [ "$AGENT_NAME" = "" ] && AGENT_NAME="$AGENT_TYPE"

AGENT_ID="$(date +%s%N)"

# Create state file if not exists
[ ! -f "$STATE_FILE" ] && mkdir -p "$(dirname "$STATE_FILE")" && echo '{"session_start":null,"core_roles":{},"subagents":[],"history":[]}' > "$STATE_FILE"

# Get session ID from input
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // ""' 2>/dev/null || echo "")

# Add subagent to state AND set parent role to PM (PM spawns agents)
node -e "
const fs = require('fs');
const state = JSON.parse(fs.readFileSync('$STATE_FILE', 'utf8'));

if (!state.session_start) state.session_start = '$TIMESTAMP';
if (!state.subagents) state.subagents = [];
if (!state.history) state.history = [];
if (!state.sessions) state.sessions = {};

// Add subagent
state.subagents.push({
  id: '$AGENT_ID',
  type: '$AGENT_TYPE',
  name: '$AGENT_NAME',
  description: '$DESCRIPTION',
  status: 'running',
  started_at: '$TIMESTAMP'
});

state.history.push({
  event: 'subagent_start',
  agent: '$AGENT_TYPE',
  agentName: '$AGENT_NAME',
  timestamp: '$TIMESTAMP'
});

// When spawning agents, the parent is PM (PM orchestrates specialists)
const sessionId = '$SESSION_ID';
if (sessionId && state.sessions[sessionId]) {
  const oldRole = state.sessions[sessionId].role;
  if (oldRole !== 'PM') {
    state.sessions[sessionId].role = 'PM';
    state.sessions[sessionId].last_seen = '$TIMESTAMP';
    state.history.push({
      event: 'core_role_switch',
      agent: 'PM',
      session: sessionId,
      timestamp: '$TIMESTAMP'
    });
  }
}

if (state.history.length > 15) state.history = state.history.slice(-15);
fs.writeFileSync('$STATE_FILE', JSON.stringify(state, null, 2));
"

exit 0
