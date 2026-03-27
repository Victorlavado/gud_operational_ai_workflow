#!/bin/bash
# Session Review Hook — runs at end of Claude Code session (Stop event)
# Leaves a marker file so the NEXT session picks up the review reminder at SessionStart.
#
# Why not print directly? Stop hook stdout is silent by design (anthropics/claude-code#16227).
# Instead we write a marker that the SessionStart hook (auto-update.sh) can detect.
#
# Install: Add to .claude/settings.json under hooks.Stop
# Only fires if the session has been substantive (checks git for recent changes)

MARKER_FILE="${CLAUDE_PROJECT_DIR:-.}/.claude/.pending-session-review"

RECENT_CHANGES=$(git diff --stat 2>/dev/null | tail -1)
RECENT_COMMITS=$(git log --oneline --since="1 hour ago" 2>/dev/null | head -5)

if [ -n "$RECENT_CHANGES" ] || [ -n "$RECENT_COMMITS" ]; then
    cat > "$MARKER_FILE" <<EOF
timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)
changes=${RECENT_CHANGES}
commits=${RECENT_COMMITS}
EOF
fi
