#!/bin/bash

# Initialize New Project (Single-project architecture)
# Sets up project structure at ROOT level — no projects/ subdirectory
# Usage: ./init-project.sh "Project Name" [DESCRIPTION]
#
# If directories already exist:
#   - Verifies/creates missing folders
#   - Skips existing files (idempotent)

set -e

PROJECT_NAME="$1"
DESCRIPTION="${2:-}"

if [ -z "$PROJECT_NAME" ]; then
    echo "Usage: $0 \"Project Name\" [Description]"
    echo ""
    echo "Examples:"
    echo "  $0 \"Instagram Clone\""
    echo "  $0 \"E-commerce Platform\" \"Online store with payments\""
    exit 1
fi

# Base paths
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
TEMPLATES_DIR="$SCRIPT_DIR/../templates"

echo "Initializing new project: $PROJECT_NAME"
echo ""

echo "Project root: $ROOT_DIR"

# Create/verify all directories at ROOT level
echo ""
echo "Creating/verifying project structure..."

mkdir -p "$ROOT_DIR/.project/state/specialists"
mkdir -p "$ROOT_DIR/.project/requirements"
mkdir -p "$ROOT_DIR/.project/documentation"
mkdir -p "$ROOT_DIR/.project/sprints"
mkdir -p "$ROOT_DIR/.project/wireframes/screens"
mkdir -p "$ROOT_DIR/.project/scenarios"
mkdir -p "$ROOT_DIR/app"
# Note: Internal structure of app/ is NOT created here.
# CTO decides internal structure based on chosen tech stack.

echo "  All directories created/verified"

# NOTE: project-context.md is NOT created here
# It is a BA deliverable - BA role creates it fresh with actual Q&A content
# This prevents "Error writing file" when BA uses Write tool

# Create README.md if missing
if [ ! -f "$ROOT_DIR/README.md" ]; then
    echo "Creating README.md..."
    cat > "$ROOT_DIR/README.md" << EOF
# $PROJECT_NAME

**Status**: Planning

---

## Quick Links

- [Project Context](./.project/project-context.md)
- [Progress Dashboard](./.project/progress-dashboard.md)

---

## Directories

- \`app/\` - All application source code
- \`.project/requirements/\` - BA outputs (SRS, user stories)
- \`.project/documentation/\` - CTO outputs (tech stack, architecture)
- \`.project/sprints/\` - Sprint plans
- \`.project/wireframes/\` - UX outputs
- \`.project/state/\` - Agent state files

---

**Created**: $(date +%Y-%m-%d)
EOF
    echo "  README.md"
fi

# Copy documentation templates if missing
DOC_TEMPLATES="$TEMPLATES_DIR/documentation"
if [ -d "$DOC_TEMPLATES" ]; then
    for template in "$DOC_TEMPLATES"/*.md; do
        if [ -f "$template" ]; then
            filename=$(basename "$template")
            if [ ! -f "$ROOT_DIR/.project/documentation/$filename" ]; then
                cp "$template" "$ROOT_DIR/.project/documentation/"
                echo "  documentation/$filename (template)"
            fi
        fi
    done
fi

# Copy state templates if they exist
STATE_TEMPLATES="$TEMPLATES_DIR/state"
if [ -d "$STATE_TEMPLATES" ]; then
    # Copy pm-tracker.md if missing
    if [ -f "$STATE_TEMPLATES/pm-tracker.md" ] && [ ! -f "$ROOT_DIR/.project/state/pm-tracker.md" ]; then
        sed -e "s/{PROJECT_NAME}/$PROJECT_NAME/g" \
            -e "s/{DATE}/$(date +%Y-%m-%d)/g" \
            "$STATE_TEMPLATES/pm-tracker.md" > "$ROOT_DIR/.project/state/pm-tracker.md"
        echo "  state/pm-tracker.md (template)"
    fi

    # Copy ba-tracker.md if missing
    if [ -f "$STATE_TEMPLATES/ba-tracker.md" ] && [ ! -f "$ROOT_DIR/.project/state/ba-tracker.md" ]; then
        sed -e "s/{PROJECT_NAME}/$PROJECT_NAME/g" \
            -e "s/{DATE}/$(date +%Y-%m-%d)/g" \
            "$STATE_TEMPLATES/ba-tracker.md" > "$ROOT_DIR/.project/state/ba-tracker.md"
        echo "  state/ba-tracker.md (template)"
    fi
fi

# Copy tracking templates if they exist
TRACKING_TEMPLATES="$TEMPLATES_DIR/tracking"
if [ -d "$TRACKING_TEMPLATES" ]; then
    # Create progress-dashboard.md from template
    if [ -f "$TRACKING_TEMPLATES/progress-dashboard.md" ] && [ ! -f "$ROOT_DIR/.project/progress-dashboard.md" ]; then
        sed -e "s/{PROJECT_NAME}/$PROJECT_NAME/g" \
            -e "s/{DATE}/$(date +%Y-%m-%d)/g" \
            "$TRACKING_TEMPLATES/progress-dashboard.md" > "$ROOT_DIR/.project/progress-dashboard.md"
        echo "  progress-dashboard.md (template)"
    fi
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Project ready: $PROJECT_NAME"
echo "Path: $ROOT_DIR"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
