#!/bin/bash
# Stop Agent Monitor dashboard

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PORT=${PORT:-3847}
STATE_FILE="$SCRIPT_DIR/state/activity.json"

# Find and kill process on port
PID=$(lsof -Pi :$PORT -sTCP:LISTEN -t 2>/dev/null)

if [ -n "$PID" ]; then
  kill $PID 2>/dev/null
  echo "Monitor stopped (PID: $PID)"
else
  echo "Monitor is not running"
fi

# Clear active sessions and subagents
if [ -f "$STATE_FILE" ]; then
  node -e "
  const fs = require('fs');
  const state = JSON.parse(fs.readFileSync('$STATE_FILE', 'utf8'));
  state.sessions = {};
  state.subagents = [];
  fs.writeFileSync('$STATE_FILE', JSON.stringify(state, null, 2));
  "
  echo "State cleared"
fi
