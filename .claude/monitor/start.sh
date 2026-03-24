#!/bin/bash
# Start Agent Monitor dashboard

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
PROJECT_NAME="$(basename "$PROJECT_DIR")"

# Generate a stable port per project (range 3800-3999)
# Hash project name → consistent port number
if [ -z "$PORT" ]; then
  HASH=$(echo -n "$PROJECT_NAME" | md5 -q 2>/dev/null || echo -n "$PROJECT_NAME" | md5sum | cut -d' ' -f1)
  PORT=$(( 3800 + ( 16#${HASH:0:4} % 200 ) ))
fi
STATE_FILE="$SCRIPT_DIR/state/activity.json"

# Clear stale sessions on start (in case previous session was Ctrl+C'd)
if [ -f "$STATE_FILE" ]; then
  node -e "
  const fs = require('fs');
  const state = JSON.parse(fs.readFileSync('$STATE_FILE', 'utf8'));
  state.sessions = {};
  state.subagents = [];
  fs.writeFileSync('$STATE_FILE', JSON.stringify(state, null, 2));
  " 2>/dev/null
fi

# Check if already running
if lsof -Pi :$PORT -sTCP:LISTEN -t >/dev/null 2>&1; then
  echo "Monitor already running: http://localhost:$PORT"
  exit 0
fi

# Start server
echo "Starting Agent Monitor on http://localhost:$PORT"
node "$SCRIPT_DIR/server.cjs" &
SERVER_PID=$!

# Wait for server to start
sleep 1

# Open browser
open "http://localhost:$PORT"

echo "Server running (PID: $SERVER_PID)"
echo "Monitor: http://localhost:$PORT"

# Don't wait - let script exit so Claude can continue
