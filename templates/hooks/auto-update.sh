#!/bin/bash
# Auto-update hook — checks for framework updates on session start.
# Also checks for pending session review from previous session.
#
# Runs at most once per hour per project. If a new version is available,
# downloads the latest sync script from GitHub and runs it.
#
# State files (in target project, gitignored):
#   .claude/.framework-version      — installed version
#   .claude/.last-framework-check   — timestamp of last check
#   .claude/.pending-session-review — marker from Stop hook
#
# Install: Added automatically by bin/sync.sh under hooks.SessionStart

# Helper: output to both stdout (Claude context) and stderr (user terminal)
notify() { echo "$1"; echo "$1" >&2; }

# ─── Pending session review from previous session ────────────────────────────
REVIEW_MARKER="$CLAUDE_PROJECT_DIR/.claude/.pending-session-review"
if [ -f "$REVIEW_MARKER" ]; then
    notify "SESSION_REVIEW_PENDING: La sesión anterior tuvo cambios significativos que no fueron revisados. Ejecuta /session-review para analizar si hay gotchas o patrones que añadir al CLAUDE.md."
    rm -f "$REVIEW_MARKER"
fi

# ─── Cooldown (1 hour) ─────────────────────────────────────────────────────
COOLDOWN=3600
LAST_CHECK_FILE="$CLAUDE_PROJECT_DIR/.claude/.last-framework-check"

if [ -f "$LAST_CHECK_FILE" ]; then
    last_check=$(cat "$LAST_CHECK_FILE" 2>/dev/null || echo "0")
    now=$(date +%s)
    elapsed=$((now - last_check))
    if [ "$elapsed" -lt "$COOLDOWN" ]; then
        exit 0
    fi
fi

# ─── Version check ─────────────────────────────────────────────────────────
GITHUB_RAW="https://raw.githubusercontent.com/Victorlavado/gud_operational_ai_workflow/main"
LOCAL_VERSION=$(cat "$CLAUDE_PROJECT_DIR/.claude/.framework-version" 2>/dev/null || echo "unknown")
REMOTE_VERSION=$(curl -sfL --max-time 3 "$GITHUB_RAW/VERSION" 2>/dev/null || echo "")

# Record check time regardless of result
date +%s > "$LAST_CHECK_FILE" 2>/dev/null || true

# No network or same version — exit silently
if [ -z "$REMOTE_VERSION" ] || [ "$LOCAL_VERSION" = "$REMOTE_VERSION" ]; then
    exit 0
fi

# ─── Update available — fetch and run sync ──────────────────────────────────
SYNC_SCRIPT=$(curl -sfL --max-time 10 "$GITHUB_RAW/bin/sync.sh" 2>/dev/null || echo "")

if [ -z "$SYNC_SCRIPT" ]; then
    notify "FRAMEWORK_UPDATE: nueva versión disponible ($LOCAL_VERSION → $REMOTE_VERSION) pero no se pudo descargar el sync. Se reintentará en la próxima sesión."
    exit 0
fi

# Run sync in remote mode against this project
bash <(echo "$SYNC_SCRIPT") "$CLAUDE_PROJECT_DIR" --remote
