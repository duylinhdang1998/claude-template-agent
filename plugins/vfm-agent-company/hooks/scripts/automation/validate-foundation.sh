#!/bin/bash
##############################################################################
# validate-foundation.sh
#
# FOUNDATION GATE — runs between Gate 1 (planning complete) and Sprint 1
# (first feature sprint). Verifies that the Sprint 0 Foundation Batch produced
# a skeleton that actually exists and actually runs.
#
# DESIGN NOTE — why this script knows nothing about any stack:
#   A gate that hardcodes "app/components/ui" or "npm run lint" is a gate for
#   exactly one stack, and silently passes every other one. Instead the CTO
#   DECLARES the project's own artifacts and its own verification commands in a
#   machine-readable Foundation Manifest inside architecture.md; this script only
#   reads that declaration and checks it. Swift, Kotlin, Dart, Go, Python and
#   TypeScript projects are all verified by the same code path.
#
# Usage: ./validate-foundation.sh [--manifest-only]
#
# Exit codes:
#   0 = PASSED    — every declared path exists, every declared command exits 0
#   1 = FAILED    — a declared artifact is missing or a verification command failed
#   2 = NO MANIFEST — architecture.md has no usable Foundation Manifest (CTO must author it)
##############################################################################

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="${CLAUDE_PROJECT_DIR:-$(cd "$SCRIPT_DIR/../.." && pwd)}"
ARCH_FILE="$ROOT_DIR/.project/documentation/architecture.md"

MANIFEST_ONLY=0
[ "$1" = "--manifest-only" ] && MANIFEST_ONLY=1

PASS=0
FAIL=0

echo ""
echo "🏗️  Foundation Gate: Sprint 0 skeleton"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Project root: $ROOT_DIR"
echo ""

##############################################################################
# 1) Locate the Foundation Manifest
##############################################################################
if [ ! -f "$ARCH_FILE" ]; then
    echo "❌ architecture.md not found: .project/documentation/architecture.md"
    echo ""
    echo "ACTION: PM → switch to CTO role → create architecture.md (see core/cto.md)."
    echo ""
    exit 2
fi

MANIFEST=$(awk '/<!-- foundation-manifest:start -->/{f=1;next} /<!-- foundation-manifest:end -->/{f=0} f' "$ARCH_FILE")

if [ -z "$(echo "$MANIFEST" | tr -d '[:space:]')" ]; then
    echo "❌ No Foundation Manifest in architecture.md"
    echo ""
    echo "The manifest is the ONLY thing that makes the foundation verifiable — without"
    echo "it this gate has nothing to check, and 'foundation complete' is an unbacked claim."
    echo ""
    echo "ACTION: PM → switch to CTO role → add this block to architecture.md:"
    echo ""
    echo "  ## Foundation Manifest"
    echo "  <!-- foundation-manifest:start -->"
    echo "  paths:"
    echo "    - <dir or file the foundation must produce>   # one per line, repo-relative"
    echo "  commands:"
    echo "    - <command that must exit 0>                  # build / lint / type-check, per layer"
    echo "  <!-- foundation-manifest:end -->"
    echo ""
    exit 2
fi

# Reject a manifest left as the template's own example lines.
if echo "$MANIFEST" | grep -qE '<dir or file|<command that must|\.\.\.|TODO|TBD|\[To be'; then
    echo "❌ Foundation Manifest still contains template placeholders."
    echo "   CTO must replace them with this project's real paths and commands."
    echo ""
    exit 2
fi

# --- parse: everything under `paths:` until `commands:`, and under `commands:` ---
PATHS=$(echo "$MANIFEST" | awk '/^[[:space:]]*paths:/{f=1;next} /^[[:space:]]*commands:/{f=0} f' \
        | sed -n 's/^[[:space:]]*-[[:space:]]*//p' | sed 's/[[:space:]]*#.*$//' | sed 's/[[:space:]]*$//' | grep -v '^$')
COMMANDS=$(echo "$MANIFEST" | awk '/^[[:space:]]*commands:/{f=1;next} /^[[:space:]]*[a-z_]+:/{if(f)f=0} f' \
        | sed -n 's/^[[:space:]]*-[[:space:]]*//p' | sed 's/[[:space:]]*$//' | grep -v '^$')

PATH_COUNT=$(echo "$PATHS" | grep -c . )
CMD_COUNT=$(echo "$COMMANDS" | grep -c . )

if [ "$PATH_COUNT" -eq 0 ] || [ "$CMD_COUNT" -eq 0 ]; then
    echo "❌ Foundation Manifest incomplete — paths: $PATH_COUNT entries, commands: $CMD_COUNT entries."
    echo "   Both sections need at least one entry (a structure nobody can build is not a foundation)."
    echo ""
    exit 2
fi

echo "Manifest: $PATH_COUNT declared artifact(s), $CMD_COUNT verification command(s)"
echo ""

if [ "$MANIFEST_ONLY" -eq 1 ]; then
    echo "✅ Manifest present and well-formed (--manifest-only: artifacts not checked)"
    echo ""
    exit 0
fi

##############################################################################
# 2) Declared artifacts must exist and be non-empty
##############################################################################
echo "Declared artifacts:"
echo ""
while IFS= read -r p; do
    [ -z "$p" ] && continue
    TARGET="$ROOT_DIR/$p"
    if [ -d "$TARGET" ]; then
        N=$(find "$TARGET" -type f ! -name '.*' 2>/dev/null | wc -l | xargs)
        if [ "$N" -gt 0 ]; then
            echo "├── $p ... ✅ directory ($N files)"
            PASS=$((PASS + 1))
        else
            echo "├── $p ... ❌ directory is EMPTY"
            FAIL=$((FAIL + 1))
        fi
    elif [ -f "$TARGET" ]; then
        if [ -s "$TARGET" ]; then
            echo "├── $p ... ✅ file"
            PASS=$((PASS + 1))
        else
            echo "├── $p ... ❌ file is EMPTY"
            FAIL=$((FAIL + 1))
        fi
    else
        echo "├── $p ... ❌ MISSING"
        FAIL=$((FAIL + 1))
    fi
done <<< "$PATHS"

##############################################################################
# 3) Declared commands must exit 0
#
#    This is the half that cannot be faked. A directory can exist and contain
#    files that do not compile; only running the project's own build/lint/type
#    commands shows the skeleton is real.
##############################################################################
echo ""
echo "Verification commands:"
echo ""
while IFS= read -r c; do
    [ -z "$c" ] && continue
    OUT=$(cd "$ROOT_DIR" && eval "$c" 2>&1)
    RC=$?
    if [ "$RC" -eq 0 ]; then
        echo "├── \`$c\` ... ✅ exit 0"
        PASS=$((PASS + 1))
    else
        echo "├── \`$c\` ... ❌ exit $RC"
        echo "$OUT" | tail -15 | sed 's/^/│     /'
        FAIL=$((FAIL + 1))
    fi
done <<< "$COMMANDS"

##############################################################################
# 4) Design-system coherence — only when the project HAS a design system.
#    A foundation whose primitives were built off a token file with blanks in it
#    has hardcoded values in it by definition.
##############################################################################
if [ -f "$ROOT_DIR/.project/design-system.md" ]; then
    echo ""
    echo "Design system:"
    echo ""
    BUILD_TOKENS="$ROOT_DIR/.claude/scripts/build-styles-json.js"
    if [ -f "$BUILD_TOKENS" ] && command -v node &>/dev/null; then
        if (cd "$ROOT_DIR" && node "$BUILD_TOKENS" --check >/dev/null 2>&1); then
            echo "├── design-system.md tokens ... ✅ complete (no unfilled placeholders)"
            PASS=$((PASS + 1))
        else
            echo "├── design-system.md tokens ... ❌ incomplete — run:"
            echo "│     node .claude/scripts/build-styles-json.js --check --emit-css"
            FAIL=$((FAIL + 1))
        fi
    else
        echo "├── design-system.md tokens ... ⏭️  checker unavailable (node missing)"
    fi
fi

##############################################################################
# Summary
##############################################################################
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Summary: ✅ $PASS passed | ❌ $FAIL failed"
echo ""

if [ "$FAIL" -gt 0 ]; then
    echo "❌ FOUNDATION GATE FAILED"
    echo ""
    echo "ACTION: re-spawn the owning foundation agent with the output above."
    echo "        Do NOT start Sprint 1 — every feature agent inherits this skeleton,"
    echo "        so a defect here is multiplied by every sprint that follows."
    echo ""
    exit 1
fi

echo "✅ FOUNDATION GATE PASSED — structure, standards and base components verified."
echo "   Sprint 1 feature work may now be spawned."
echo ""
exit 0
