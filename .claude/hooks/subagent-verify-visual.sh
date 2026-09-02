#!/bin/bash
##############################################################################
# subagent-verify-visual.sh
#
# SubagentStop hook — audit whether a UI specialist actually LOOKED at what it
# built before declaring done.
#
# The problem it addresses: every existing gate reads source code. Lint reads
# code, the token hook reads code, the reviewer reads code. Nothing in the
# pipeline had ever rendered the page, so "the UI is fine" was an inference from
# syntax. This hook requires the one artifact that is not an inference: a fresh
# visual report produced from a running build.
#
# Detection (no access to the agent transcript — same strategy as verify-go):
#   1. agent_type is a UI-producing specialist
#   2. UI files actually changed in the working tree
#   3. a visual report exists under .project/screenshots/*/ and is FRESH
#   4. the report has no blocking (measured) violations
#
# NON-BLOCKING by design. A dev server is not always runnable inside a sandbox,
# and a gate that fails honest work gets disabled. It writes a loud warning that
# the PM and the reviewer both see — and the reviewer, which now receives the
# screenshots, is the layer that turns this into a 🔴.
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

case "$AGENT_TYPE" in
  meta-react-architect|apple-ios-lead|google-android-lead|apple-ux-wireframer) ;;
  *) exit 0 ;;
esac

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$PWD}"
[ -d "$PROJECT_DIR/.git" ] || exit 0
cd "$PROJECT_DIR" || exit 0

# Did this agent touch anything that renders?
UI_CHANGES=$(git status --porcelain 2>/dev/null \
  | awk '{print $NF}' \
  | grep -cE '\.(tsx|jsx|vue|svelte|astro|css|scss|less|swift|kt)$' || true)
[ "${UI_CHANGES:-0}" -eq 0 ] && exit 0

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CHECKER=""
for cand in "$SCRIPT_DIR/../scripts" "$SCRIPT_DIR/../../scripts" "$PROJECT_DIR/.claude/scripts"; do
  [ -f "$cand/check-visual-report.js" ] && { CHECKER="$cand/check-visual-report.js"; break; }
done

# Fresh = produced within this task's window. A report from an earlier build
# describes code that no longer exists, and stale evidence is not evidence.
REPORT=$(find .project/screenshots -name visual-report.json -mmin -30 -print0 2>/dev/null \
  | xargs -0 ls -t 2>/dev/null | head -1)

if [ -z "$REPORT" ]; then
  cat <<WARN >&2
⚠️ VISUAL AUDIT WARNING — agent: ${AGENT_TYPE}
   ${UI_CHANGES} UI file(s) changed but NO fresh visual report was found under
   .project/screenshots/*/visual-report.json (looked back 30 minutes).

   This agent shipped an interface without ever rendering it. Required before
   the task can be called complete:

     node .claude/scripts/ui-capture.js --url <dev-url> \\
          --routes <the routes this task touched> --label <task-id>

   No Playwright / no dev server? Drive the browser with the Playwright MCP
   tools and write the same \`visual-report.json\` shape by hand (the script
   prints the schema), or record in the Completion Report:
     visual result: SKIPPED (<why the UI could not be rendered>)

   PM: a UI task with no visual evidence should NOT be marked [COMPLETE].
WARN
  exit 0
fi

if [ -n "$CHECKER" ] && command -v node &>/dev/null; then
  if ! OUTPUT=$(node "$CHECKER" "$REPORT" 2>&1); then
    cat <<WARN >&2
⚠️ VISUAL QUALITY WARNING — agent: ${AGENT_TYPE}
${OUTPUT}

   These are measured defects in the RENDERED page, not style opinions.
   PM: do not close this task until they are fixed or explicitly waived.
WARN
    exit 0
  fi
  echo "✅ visual audit: ${AGENT_TYPE} — ${REPORT} is fresh and has no blocking violations."
else
  echo "✅ visual audit: fresh report found (${REPORT}); grader unavailable, not graded."
fi

exit 0
