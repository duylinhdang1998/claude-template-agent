#!/bin/bash
##############################################################################
# subagent-verify-go.sh
#
# SubagentStop hook — audit whether a code-producing specialist actually ran
# the /go verification skill before declaring done.
#
# Detection strategy (no access to agent transcript):
#   1. Check agent_type — only audit code-producing specialists
#   2. Check git diff — did the agent actually touch code files?
#   3. Scan the agent's state file for a `/go result:` line written by the
#      agent as part of its Completion Report (per the MANDATORY rule
#      injected into each specialist agent definition).
#   4. If code changed AND no /go evidence in state file → emit a WARNING
#      so PM / user sees a visible nudge.
#
# Non-blocking: this hook NEVER fails the agent. It only writes a warning to
# stderr/stdout so the transcript shows it.
#
# Trigger: SubagentStop
##############################################################################

set -e

INPUT=$(cat)

if command -v jq &>/dev/null; then
    AGENT_TYPE=$(echo "$INPUT" | jq -r '.agent_type // empty' 2>/dev/null)
else
    AGENT_TYPE=$(echo "$INPUT" | grep -o '"agent_type":"[^"]*"' | head -1 | cut -d'"' -f4)
fi

# Only audit code-producing specialists
case "$AGENT_TYPE" in
  amazon-cloud-architect|apple-ios-lead|google-ai-researcher|google-android-lead| \
  google-software-architect|google-sre-devops|meta-blockchain-architect| \
  meta-react-architect|microsoft-azure-architect|netflix-backend-architect| \
  netflix-devops-engineer)
    ;;
  *)
    # Non-code or non-specialist agents — skip silently
    exit 0
    ;;
esac

# Resolve project directory:
#   - $CLAUDE_PROJECT_DIR (set by Claude Code when firing hooks) is authoritative
#   - fall back to $PWD (works when invoked manually from project root)
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$PWD}"

[ -d "$PROJECT_DIR/.git" ] || exit 0
cd "$PROJECT_DIR" || exit 0

# Did the agent touch any code? (heuristic: changes outside .project/ and docs)
CODE_CHANGES=$(git status --porcelain 2>/dev/null \
    | awk '{print $2}' \
    | grep -vE '^\.project/|^docs/|\.md$|^\.claude/' \
    | wc -l | tr -d ' ')

if [ "$CODE_CHANGES" -eq 0 ]; then
    # No code changed → /go not applicable, skip audit
    exit 0
fi

# Look for /go evidence in the agent's state file(s) for this agent type.
# Pattern the specialist must write per the MANDATORY rule:
#   /go result: PASS
#   /go result: SKIPPED (sandbox blocks runtime)
STATE_GLOB=".project/state/specialists/${AGENT_TYPE}-*.md"
GO_EVIDENCE=0
if ls $STATE_GLOB >/dev/null 2>&1; then
    # Only check state files modified in the last 10 minutes (this task)
    RECENT_STATES=$(find .project/state/specialists -name "${AGENT_TYPE}-*.md" -mmin -10 2>/dev/null)
    for f in $RECENT_STATES; do
        if grep -qiE '^/go result:|^\*\*/go result' "$f" 2>/dev/null; then
            GO_EVIDENCE=1
            break
        fi
    done
fi

if [ "$GO_EVIDENCE" -eq 0 ]; then
    cat <<WARN >&2
⚠️ /go AUDIT WARNING — agent: ${AGENT_TYPE}
   Code files changed (${CODE_CHANGES} files) but NO "/go result:" line found
   in the agent's recent state file.

   Per MANDATORY rule in this agent's definition, the specialist MUST:
     1. Invoke Skill { skill: "go" } after implementation
     2. Write "/go result: PASS" (or SKIPPED with reason) into state file
        Completion Notes before handoff

   ACTION for PM:
     - Ask ${AGENT_TYPE} to run /go and append evidence, OR
     - If runtime verification is impossible, require explicit
       "/go result: SKIPPED (<reason>)" in the Completion Report.

   A sprint task without /go evidence should NOT be marked [COMPLETE].
WARN
else
    echo "✅ /go audit: ${AGENT_TYPE} recorded /go evidence in state file."
fi

exit 0
