#!/bin/bash
# enforce-conventional-commits.sh
# Enforces conventional commits format via PreToolUse hook
# - Validates commit messages follow: type(scope)?: description
# - Auto-fixes invalid messages by prepending 'chore:'
# - Skips merge commits

INPUT=$(cat)
TOOL=$(echo "$INPUT" | jq -r '.tool_name // empty')
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

# Only intercept Bash tool with git commit commands
if [[ "$TOOL" != "Bash" ]] || ! echo "$COMMAND" | grep -q "git commit"; then
  exit 0
fi

# Extract -m flag message
# Pattern: -m 'message' or -m "message"
# Use awk for reliable extraction (works on macOS)
MSG=$(echo "$COMMAND" | awk -F"-m " '{print $2}' | awk -F"'" '{if(NF>1) print $2; else {split($0,a,"\""); print a[2]}}')

# No message found, skip validation
if [[ -z "$MSG" ]]; then
  exit 0
fi

# Skip merge commits
if [[ "$MSG" == *"Merge branch"* ]] || [[ "$MSG" == *"Merge pull request"* ]]; then
  exit 0
fi

# Skip empty messages
if [[ -z "$MSG" ]]; then
  exit 0
fi

# Conventional commits pattern
# Types: feat, fix, refactor, docs, test, chore, perf, ci
CONVENTIONAL_PATTERN='^(feat|fix|refactor|docs|test|chore|perf|ci)(\(.+\))?!?: .+'

if echo "$MSG" | grep -qE "$CONVENTIONAL_PATTERN"; then
  # Valid format - allow as-is
  exit 0
fi

# Invalid format - auto-fix by prepending 'chore:'
FIXED_MSG="chore: $MSG"

# Reconstruct command with fixed message
if echo "$COMMAND" | grep -qE "\-m\s*'"; then
  NEW_COMMAND=$(echo "$COMMAND" | sed "s/-m '[^']*'/-m '$FIXED_MSG'/")
else
  NEW_COMMAND=$(echo "$COMMAND" | sed "s/-m \"[^\"]*\"/-m '$FIXED_MSG'/")
fi

# Return modified input
jq -n --arg cmd "$NEW_COMMAND" --arg reason "Auto-fixed to conventional format: $FIXED_MSG" '{
  hookSpecificOutput: {
    hookEventName: "PreToolUse",
    permissionDecision: "allow",
    updatedInput: { command: $cmd },
    permissionDecisionReason: $reason
  }
}'

exit 0
