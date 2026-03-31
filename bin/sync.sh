#!/bin/bash
# bin/sync.sh — Sync Operational AI Workflows framework to a target project.
#
# Usage:
#   bin/sync.sh TARGET_DIR              # sync from local framework repo
#   bin/sync.sh TARGET_DIR --remote     # sync from GitHub (used by auto-update hook)
#
# What it syncs:
#   - Hook scripts (.claude/hooks/)
#   - Skills (.claude/skills/)
#   - Commands (.claude/commands/)
#   - settings.json hooks config (preserving non-hook settings)
#   - Common Layer section of CLAUDE.md (if markers present)
#   - Framework version tracker (.claude/.framework-version)
#
# Idempotent — safe to run multiple times.

set -e

# ─── Configuration ──────────────────────────────────────────────────────────
GITHUB_REPO="Victorlavado/gud_operational_ai_workflow"
GITHUB_BRANCH="main"
GITHUB_RAW="https://raw.githubusercontent.com/${GITHUB_REPO}/${GITHUB_BRANCH}"

# ─── Arguments ──────────────────────────────────────────────────────────────
TARGET_DIR="${1:-.}"
MODE="local"

if [ "$2" = "--remote" ]; then
    MODE="remote"
fi

# Resolve absolute path
TARGET_DIR="$(cd "$TARGET_DIR" 2>/dev/null && pwd)" || {
    echo "ERROR: directorio '$1' no existe."
    exit 1
}

if [ "$MODE" = "local" ]; then
    FRAMEWORK_DIR="$(cd "$(dirname "$0")/.." && pwd)"
    if [ ! -f "$FRAMEWORK_DIR/templates/common-layer.md" ]; then
        echo "ERROR: framework no encontrado en $FRAMEWORK_DIR"
        exit 1
    fi
fi

# ─── Helpers ────────────────────────────────────────────────────────────────
fetch_content() {
    local src="$1"
    if [ "$MODE" = "local" ]; then
        cat "$FRAMEWORK_DIR/$src"
    else
        curl -sfL --max-time 10 "$GITHUB_RAW/$src" 2>/dev/null || echo ""
    fi
}

CHANGES=""

log_change() {
    CHANGES="${CHANGES}  · $1\n"
}

sync_file() {
    local src="$1"
    local dst="$2"
    local label="$3"

    local new_content
    new_content=$(fetch_content "$src")
    if [ -z "$new_content" ]; then return 0; fi

    mkdir -p "$(dirname "$dst")"

    local old_content=""
    if [ -f "$dst" ]; then old_content=$(cat "$dst"); fi

    if [ "$new_content" != "$old_content" ]; then
        printf '%s\n' "$new_content" > "$dst"
        log_change "$label"
    fi
}

# ─── Sync ───────────────────────────────────────────────────────────────────

# 1. Create directories
mkdir -p "$TARGET_DIR/.claude/hooks"
mkdir -p "$TARGET_DIR/.claude/skills/session-review"
mkdir -p "$TARGET_DIR/.claude/skills/recovery"
mkdir -p "$TARGET_DIR/.claude/skills/propose-upstream"
mkdir -p "$TARGET_DIR/.claude/commands"

# 2. Sync hooks
for hook in context-watchdog.sh implementation-health.sh session-review-hook.sh auto-update.sh statusline.sh test-evaluation-warning.sh; do
    sync_file "templates/hooks/$hook" "$TARGET_DIR/.claude/hooks/$hook" "hook: $hook"
    chmod +x "$TARGET_DIR/.claude/hooks/$hook" 2>/dev/null || true
done

# 3. Sync skills
for skill_dir in session-review recovery propose-upstream; do
    sync_file ".claude/skills/$skill_dir/SKILL.md" \
              "$TARGET_DIR/.claude/skills/$skill_dir/SKILL.md" \
              "skill: $skill_dir"
done

# 4. Sync commands
for cmd in context-check.md; do
    sync_file ".claude/commands/$cmd" \
              "$TARGET_DIR/.claude/commands/$cmd" \
              "command: ${cmd%.md}"
done

# 5. Sync settings.json (replace hooks section, preserve other keys)
TEMPLATE_SETTINGS=$(fetch_content "templates/hooks/settings.json.template")
if [ -n "$TEMPLATE_SETTINGS" ]; then
    if [ ! -f "$TARGET_DIR/.claude/settings.json" ]; then
        printf '%s\n' "$TEMPLATE_SETTINGS" > "$TARGET_DIR/.claude/settings.json"
        log_change "settings.json (creado)"
    elif command -v python3 &>/dev/null; then
        EXISTING=$(cat "$TARGET_DIR/.claude/settings.json")
        # Overwrite hooks section from template, preserve everything else
        MERGED=$(python3 -c "
import json, sys
existing = json.loads(sys.argv[1])
template = json.loads(sys.argv[2])
existing['hooks'] = template['hooks']
print(json.dumps(existing, indent=2))
" "$EXISTING" "$TEMPLATE_SETTINGS" 2>/dev/null) || MERGED=""

        if [ -n "$MERGED" ] && [ "$MERGED" != "$EXISTING" ]; then
            printf '%s\n' "$MERGED" > "$TARGET_DIR/.claude/settings.json"
            log_change "settings.json (hooks actualizados)"
        fi
    else
        # Sin python3: backup + overwrite (hooks section is framework-managed)
        EXISTING=$(cat "$TARGET_DIR/.claude/settings.json")
        if [ "$EXISTING" != "$TEMPLATE_SETTINGS" ]; then
            cp "$TARGET_DIR/.claude/settings.json" "$TARGET_DIR/.claude/settings.json.bak"
            printf '%s\n' "$TEMPLATE_SETTINGS" > "$TARGET_DIR/.claude/settings.json"
            log_change "settings.json (actualizado, backup en settings.json.bak)"
        fi
    fi
fi

# 6. Sync Common Layer in CLAUDE.md (if markers present)
if [ -f "$TARGET_DIR/CLAUDE.md" ] && grep -q "<!-- COMMON LAYER START -->" "$TARGET_DIR/CLAUDE.md" 2>/dev/null; then
    COMMON_LAYER=$(fetch_content "templates/common-layer.md")
    if [ -n "$COMMON_LAYER" ]; then
        # Extract everything before and after the markers
        BEFORE=$(sed '/<!-- COMMON LAYER START -->/,$d' "$TARGET_DIR/CLAUDE.md")
        AFTER=$(sed '1,/<!-- COMMON LAYER END -->/d' "$TARGET_DIR/CLAUDE.md")

        {
            printf '%s\n' "$BEFORE"
            echo "<!-- COMMON LAYER START -->"
            printf '%s\n' "$COMMON_LAYER"
            echo "<!-- COMMON LAYER END -->"
            printf '%s\n' "$AFTER"
        } > "$TARGET_DIR/CLAUDE.md.tmp"

        if ! diff -q "$TARGET_DIR/CLAUDE.md" "$TARGET_DIR/CLAUDE.md.tmp" >/dev/null 2>&1; then
            mv "$TARGET_DIR/CLAUDE.md.tmp" "$TARGET_DIR/CLAUDE.md"
            log_change "CLAUDE.md (Common Layer actualizado)"
        else
            rm -f "$TARGET_DIR/CLAUDE.md.tmp"
        fi
    fi
fi

# 7. Add tracking files to .gitignore
if [ -f "$TARGET_DIR/.gitignore" ]; then
    for entry in ".claude/.framework-version" ".claude/.last-framework-check" ".claude/.pending-session-review" ".claude/.upstream-proposals"; do
        if ! grep -qF "$entry" "$TARGET_DIR/.gitignore" 2>/dev/null; then
            echo "$entry" >> "$TARGET_DIR/.gitignore"
            log_change ".gitignore (añadido $entry)"
        fi
    done
fi

# 8. Update version tracker
NEW_VERSION=$(fetch_content "VERSION")
if [ -n "$NEW_VERSION" ]; then
    printf '%s\n' "$NEW_VERSION" > "$TARGET_DIR/.claude/.framework-version"
fi

# 9. Report
if [ -n "$CHANGES" ]; then
    printf "FRAMEWORK_SYNC: actualizado.\n${CHANGES}"
else
    echo "FRAMEWORK_SYNC: todo al día, sin cambios."
fi
