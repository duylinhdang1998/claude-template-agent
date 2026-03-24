#!/bin/bash
# Hook: Stop - Update last_seen when Claude finishes responding
# NOTE: Does NOT delete session - relies on server timeout for cleanup

STATE_FILE="${CLAUDE_PROJECT_DIR}/.claude/monitor/state/activity.json"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Read JSON from stdin (Stop hook passes data via stdin)
INPUT=$(cat)

# Extract session_id from input
SESSION_ID=$(echo "$INPUT" | node -e "
const data = JSON.parse(require('fs').readFileSync(0, 'utf8'));
console.log(data?.session_id || '');
" 2>/dev/null || echo "")

[ -z "$SESSION_ID" ] && exit 0
[ ! -f "$STATE_FILE" ] && exit 0

# Just update last_seen, don't delete
node -e "
const fs = require('fs');
try {
  const state = JSON.parse(fs.readFileSync('$STATE_FILE', 'utf8'));

  if (!state.sessions || !state.sessions['$SESSION_ID']) process.exit(0);

  // Update last_seen
  state.sessions['$SESSION_ID'].last_seen = '$TIMESTAMP';

  fs.writeFileSync('$STATE_FILE', JSON.stringify(state, null, 2));
} catch(e) {}
"

exit 0
