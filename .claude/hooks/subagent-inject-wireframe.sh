#!/bin/bash
##############################################################################
# subagent-inject-wireframe.sh
#
# SubagentStart hook — Auto-inject UI CONTEXT into UI specialists via
# hookSpecificOutput.additionalContext (structured JSON output).
#
# Injects TWO things so the agent never has to "remember to go read a file":
#   1. DESIGN SYSTEM  — the project's design tokens (user-provided file).
#                       This is the fix for "frontend codes wrong design system".
#   2. WIREFRAME       — the screen layout for the current TASK ID (if any).
#
# UI specialists: meta-react-architect, apple-ios-lead, google-android-lead
#   + google-code-reviewer — it grades UI Rule #2 and motion rules, yet used to
#     receive neither the token file nor any rendered evidence, so it reviewed
#     interfaces by reading source code alone.
#
# Trigger: SubagentStart
# Output : JSON { hookSpecificOutput: { additionalContext: "..." } }
##############################################################################

INPUT=$(cat)

# --- Extract agent type + prompt (jq with grep fallback) --------------------
if command -v jq &>/dev/null; then
  SUBAGENT_TYPE=$(echo "$INPUT" | jq -r '.agent_type // .subagent_type // .type // empty' 2>/dev/null)
  PROMPT=$(echo "$INPUT" | jq -r '.prompt // empty' 2>/dev/null)
else
  SUBAGENT_TYPE=$(echo "$INPUT" | grep -o '"agent_type":"[^"]*"' | head -1 | cut -d'"' -f4)
  [ -z "$SUBAGENT_TYPE" ] && SUBAGENT_TYPE=$(echo "$INPUT" | grep -o '"subagent_type":"[^"]*"' | head -1 | cut -d'"' -f4)
  [ -z "$SUBAGENT_TYPE" ] && SUBAGENT_TYPE=$(echo "$INPUT" | grep -o '"type":"[^"]*"' | head -1 | cut -d'"' -f4)
  PROMPT=$(echo "$INPUT" | grep -o '"prompt":"[^"]*"' | head -1 | cut -d'"' -f4)
fi

# Only UI specialists need this context.
case "$SUBAGENT_TYPE" in
  meta-react-architect|apple-ios-lead|google-android-lead|google-code-reviewer) ;;
  *) exit 0 ;;
esac

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# Prefer the user's project dir (set for all hooks; correct in both local and
# plugin-installed contexts); fall back to the repo-relative path for local dev.
ROOT_DIR="${CLAUDE_PROJECT_DIR:-$(cd "$SCRIPT_DIR/../.." && pwd)}"

MAX_DS_LINES=500     # cap design-system injection to stay lean
CONTEXT=""

##############################################################################
# 1) DESIGN SYSTEM — locate the project's design-system file (first match wins)
##############################################################################
DS_CANDIDATES=(
  "$ROOT_DIR/.project/design-system.md"
  "$ROOT_DIR/.project/design/design-system.md"
  "$ROOT_DIR/.project/documentation/design-system.md"
  "$ROOT_DIR/.project/wireframes/design-system.md"
  "$ROOT_DIR/design-system.md"
  "$ROOT_DIR/DESIGN.md"
  "$ROOT_DIR/references/DESIGN.md"
  "$ROOT_DIR/app/design-system.md"
  "$ROOT_DIR/app/DESIGN.md"
)
DS_FILE=""
for cand in "${DS_CANDIDATES[@]}"; do
  if [ -f "$cand" ]; then DS_FILE="$cand"; break; fi
done

if [ -n "$DS_FILE" ]; then
  DS_REL="${DS_FILE#$ROOT_DIR/}"
  DS_CONTENT=$(head -n "$MAX_DS_LINES" "$DS_FILE")
  DS_TRUNC=""
  [ "$(wc -l < "$DS_FILE")" -gt "$MAX_DS_LINES" ] && DS_TRUNC="

… (truncated at ${MAX_DS_LINES} lines — read \`${DS_REL}\` in full for the rest)"
  CONTEXT+="══════════════════════════════════════════════════════════════
🎨 AUTO-INJECTED DESIGN SYSTEM — source of truth: \`${DS_REL}\`
══════════════════════════════════════════════════════════════

**MANDATORY — use ONLY the tokens below (colors, type scale, spacing, radius,
shadows). Do NOT invent hex values, arbitrary px, or one-off font sizes.**
If a value you need is missing here, ask the PM/user — do NOT guess.
\`google-code-reviewer\` will 🔴 REJECT ad-hoc values that bypass this system.

${DS_CONTENT}${DS_TRUNC}

"
else
  CONTEXT+="══════════════════════════════════════════════════════════════
🎨 DESIGN SYSTEM — NOT FOUND
══════════════════════════════════════════════════════════════

No design-system file was found at any known location:
  .project/design-system.md · design-system.md · DESIGN.md · references/DESIGN.md
**STOP before inventing UI tokens.** Ask the PM/user to provide the design
system file (place it at \`.project/design-system.md\`), OR load the design/UI
craft skill (\`ui-design-system\`) if the project has no formal system. Do NOT
hard-code arbitrary colors/spacing/fonts.

"
fi

##############################################################################
# 2) WIREFRAME — inject only if not already in prompt and a mapping exists
##############################################################################
if ! echo "$PROMPT" | grep -q "🎨 WIREFRAME"; then
  TASK_ID=$(echo "$PROMPT" | grep -oE "TASK ID: [0-9]+\.[0-9]+" | head -1 | awk '{print $3}')
  [ -z "$TASK_ID" ] && TASK_ID=$(echo "$PROMPT" | grep -oE "Task [0-9]+\.[0-9SRQ]+" | head -1 | awk '{print $2}')

  if [ -n "$TASK_ID" ]; then
    SPRINT=$(echo "$TASK_ID" | cut -d'.' -f1)
    SPRINT_FILE="$ROOT_DIR/.project/sprints/sprint-$SPRINT.md"
    if [ -f "$SPRINT_FILE" ]; then
      WIREFRAME_FILE=$(grep "| $TASK_ID |" "$SPRINT_FILE" 2>/dev/null | awk -F'|' '{print $(NF-1)}' | tr -d ' ')
      if [ -n "$WIREFRAME_FILE" ] && [ "$WIREFRAME_FILE" != "-" ]; then
        WIREFRAME_PATH="$ROOT_DIR/.project/wireframes/screens/$WIREFRAME_FILE"
        [ -f "$WIREFRAME_PATH" ] || WIREFRAME_PATH="$ROOT_DIR/.project/wireframes/$WIREFRAME_FILE"
        if [ -f "$WIREFRAME_PATH" ]; then
          CONTEXT+="══════════════════════════════════════════════════════════════
🎨 AUTO-INJECTED WIREFRAME FOR TASK $TASK_ID
══════════════════════════════════════════════════════════════

$(cat "$WIREFRAME_PATH")

⛔ HOW TO READ THIS — the drawing is a monospace grid, and it is dimensionally FALSE.
Transcribing it literally is how a screen ends up as boxes-inside-boxes with uniform
padding and flat typography. Its authority is scoped:

  BINDING          which elements exist · their order · which ones GROUP together ·
                   every state drawn · the behaviour in the callout table ·
                   responsive behaviour between breakpoints
  NOTATION ONLY    box borders (a │ is a boundary, NOT a 1px solid CSS border) ·
                   proportions (a 29-char row is not \"full width\") · spacing sizes
                   (line counts are not the spacing scale) · type sizes (monospace
                   flattens the whole scale) · column padding (a drawing artifact)

The NOTATION-ONLY column is decided by the design system + the screen's **Layout Intent**
block — focal point, group gaps, density, single accent, container/measure, columns.
**Layout Intent is the binding half.** If it is missing from this screen file, STOP and ask
the PM for it rather than inventing proportions from character counts.

📋 Implement ALL states (loading/error/empty/success) · match mobile/desktop where both
are shown · then RENDER and look at it (ui-capture.js) before calling the task done.
"
        else
          CONTEXT+="⚠️ WIREFRAME NOT FOUND — Task $TASK_ID expects \`$WIREFRAME_FILE\` but it is missing. Check the sprint file / wireframes dir.
"
        fi
      fi
    fi
  fi
fi

##############################################################################
# 3) VISUAL EVIDENCE — the rendered result, not the source code
#
#    Every other gate in this pipeline reads code. This block hands the agent the
#    one artifact that is not an inference: screenshots of the running UI plus the
#    measured report next to them. Only fresh evidence is injected — a report from
#    an earlier build describes code that no longer exists.
##############################################################################
# newest first — `find | head -1` returns an arbitrary report, which would show the
# reviewer evidence from a different task than the one it is grading.
VIS_REPORT=$(find "$ROOT_DIR/.project/screenshots" -name visual-report.json -mmin -120 -print0 2>/dev/null \
  | xargs -0 ls -t 2>/dev/null | head -1)
if [ -n "$VIS_REPORT" ] && [ -f "$VIS_REPORT" ]; then
  VIS_DIR="$(dirname "$VIS_REPORT")"
  VIS_REL="${VIS_REPORT#$ROOT_DIR/}"
  SHOTS=$(find "$VIS_DIR" -name '*.png' 2>/dev/null | head -8 | sed "s|$ROOT_DIR/||; s|^|  · |")
  if command -v python3 &>/dev/null; then
    SUMMARY=$(python3 -c '
import json,sys
try:
    d=json.load(open(sys.argv[1])); s=d.get("summary",{})
    print("blocking: %d  (contrast %d · overflow %d · touch-target %d)  advisory: tiny-text %d · long-line %d" % (
        s.get("contrast",0)+s.get("overflow",0)+s.get("touchTarget",0),
        s.get("contrast",0), s.get("overflow",0), s.get("touchTarget",0),
        s.get("tinyText",0), s.get("lineLength",0)))
    for c in d.get("captures",[])[:6]:
        v=c.get("violations",{})
        for kind in ("contrast","overflow","touchTarget"):
            for x in v.get(kind,[])[:2]:
                print("  %s %s [%s/%s] %s %s" % (kind.upper(), c.get("route",""), c.get("viewport",""),
                      c.get("theme",""), x.get("selector",""),
                      ("%s:1 (needs %s:1)" % (x.get("ratio"),x.get("required"))) if kind=="contrast"
                      else ("%spx past viewport" % x.get("overflowPx")) if kind=="overflow"
                      else ("%sx%s (min 44x44)" % (x.get("width"),x.get("height")))))
except Exception as e:
    print("(could not parse report: %s)" % e)
' "$VIS_REPORT" 2>/dev/null)
  else
    SUMMARY="(python3 unavailable — read the report file directly)"
  fi

  # A capture labelled `design-preview` is the UX agent's rendered DESIGN, not a render
  # of this agent's code. Injecting it unlabelled would let a reviewer grade the design as
  # if it were the implementation, and let a developer think its work had been rendered.
  if [ "$(basename "$VIS_DIR")" = "design-preview" ]; then
    CONTEXT+="══════════════════════════════════════════════════════════════
🎯 AUTO-INJECTED DESIGN REFERENCE — \`${VIS_REL}\`
══════════════════════════════════════════════════════════════

${SUMMARY}

Reference renders (use \`Read\` on these paths — they render as images):
${SHOTS}

**This is the APPROVED DESIGN rendered from the token set — the target, NOT a render
of your code.** Read it before writing UI: it shows the intended hierarchy, spacing
rhythm, density and typographic weight that the ASCII wireframe cannot express.

⚠️ It is NOT visual evidence for this task. You still owe a render of your OWN work:
    node .claude/scripts/ui-capture.js --url <dev-url> --routes <routes> --label <task-id>

"
  else
    CONTEXT+="══════════════════════════════════════════════════════════════
📸 AUTO-INJECTED VISUAL EVIDENCE — \`${VIS_REL}\`
══════════════════════════════════════════════════════════════

${SUMMARY}

Screenshots (use \`Read\` on these paths — they render as images):
${SHOTS}

**You are expected to LOOK at the interface, not infer it from source.**
Read at least one screenshot per viewport before judging any UI. The numbers
above are the measurable failures only — spacing rhythm, hierarchy, alignment
and whether the thing has any point of view are visible ONLY in the image.
Blocking violations (contrast · overflow · touch-target) are 🔴 findings.

"
  fi
elif [ "$SUBAGENT_TYPE" = "google-code-reviewer" ]; then
  CONTEXT+="══════════════════════════════════════════════════════════════
📸 VISUAL EVIDENCE — NONE FOUND
══════════════════════════════════════════════════════════════

No fresh \`visual-report.json\` exists under \`.project/screenshots/\`. If this
diff changes UI, the specialist shipped an interface nobody rendered. Report a
🔴 finding for missing visual evidence and require:
  node .claude/scripts/ui-capture.js --url <dev-url> --routes <routes> --label <task-id>

"
fi

##############################################################################
# Emit combined additionalContext
##############################################################################
[ -z "$CONTEXT" ] && exit 0

if command -v jq &>/dev/null; then
  jq -n --arg ctx "$CONTEXT" '{
    "hookSpecificOutput": {
      "hookEventName": "SubagentStart",
      "additionalContext": $ctx
    }
  }'
elif command -v python3 &>/dev/null; then
  CTX="$CONTEXT" python3 -c 'import json,os;print(json.dumps({"hookSpecificOutput":{"hookEventName":"SubagentStart","additionalContext":os.environ["CTX"]}}))'
else
  ESCAPED=$(printf '%s' "$CONTEXT" | sed 's/\\/\\\\/g; s/"/\\"/g' | sed ':a;N;$!ba;s/\n/\\n/g')
  echo "{\"hookSpecificOutput\":{\"hookEventName\":\"SubagentStart\",\"additionalContext\":\"$ESCAPED\"}}"
fi

exit 0
