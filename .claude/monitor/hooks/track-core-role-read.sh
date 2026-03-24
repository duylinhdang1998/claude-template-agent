#!/bin/bash
# Hook: PostToolUse (Read) - Auto-detect when core role files are read

STATE_FILE="${CLAUDE_PROJECT_DIR}/.claude/monitor/state/activity.json"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Read JSON from stdin
INPUT=$(cat)

# Extract file_path and session_id
FILE_PATH=$(echo "$INPUT" | node -e "
const data = JSON.parse(require('fs').readFileSync(0, 'utf8'));
console.log(data?.tool_input?.file_path || data?.file_path || '');
" 2>/dev/null || echo "")

SESSION_ID=$(echo "$INPUT" | node -e "
const data = JSON.parse(require('fs').readFileSync(0, 'utf8'));
console.log(data?.session_id || '');
" 2>/dev/null || echo "")

[ -z "$SESSION_ID" ] && SESSION_ID="auto-$$"

# Only process core role files
[[ "$FILE_PATH" != *"/core/"* ]] && [[ "$FILE_PATH" != *".claude/core/"* ]] && exit 0
[[ "$FILE_PATH" != *".md" ]] && exit 0

# Extract role name
ROLE=""
case "$FILE_PATH" in
  *"/core/ceo.md"|*"core/ceo.md") ROLE="CEO" ;;
  *"/core/cto.md"|*"core/cto.md") ROLE="CTO" ;;
  *"/core/pm.md"|*"core/pm.md") ROLE="PM" ;;
  *"/core/ba.md"|*"core/ba.md") ROLE="BA" ;;
  *"/core/hr.md"|*"core/hr.md") ROLE="HR" ;;
  *) exit 0 ;;
esac

[ -z "$ROLE" ] && exit 0

# Create state file if not exists
if [ ! -f "$STATE_FILE" ]; then
  mkdir -p "$(dirname "$STATE_FILE")"
  echo '{"sessions":{},"subagents":[],"history":[]}' > "$STATE_FILE"
fi

# Update state - one role per session, with cooldown to prevent rapid switches
node -e "
const fs = require('fs');
try {
  const state = JSON.parse(fs.readFileSync('$STATE_FILE', 'utf8'));
  if (!state.sessions) state.sessions = {};
  if (!state.history) state.history = [];

  const existing = state.sessions['$SESSION_ID'];
  const now = new Date('$TIMESTAMP').getTime();
  const lastSeen = existing?.last_seen ? new Date(existing.last_seen).getTime() : 0;
  const timeSinceLastChange = now - lastSeen;

  // Cooldown: if role changed within 3 seconds, only update last_seen (don't switch role)
  const COOLDOWN_MS = 3000;
  const isRoleChange = !existing || existing.role !== '$ROLE';
  const withinCooldown = isRoleChange && existing && timeSinceLastChange < COOLDOWN_MS;

  if (withinCooldown) {
    // Just update last_seen, keep existing role
    existing.last_seen = '$TIMESTAMP';
  } else {
    // Update session with new role
    state.sessions['$SESSION_ID'] = {
      role: '$ROLE',
      started_at: existing?.started_at || '$TIMESTAMP',
      last_seen: '$TIMESTAMP'
    };

    // Add to history when role changes
    if (isRoleChange) {
      state.history.push({
        event: 'core_role_switch',
        agent: '$ROLE',
        session: '$SESSION_ID',
        timestamp: '$TIMESTAMP'
      });
      if (state.history.length > 15) {
        state.history = state.history.slice(-15);
      }
    }
  }

  fs.writeFileSync('$STATE_FILE', JSON.stringify(state, null, 2));
} catch(e) {
  console.error(e);
}
"

exit 0
