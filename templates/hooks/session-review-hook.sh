#!/bin/bash
# Session Review Hook — runs at end of Claude Code session (Stop event)
# Outputs a reminder for Claude to review the session for CLAUDE.md updates.
#
# Install: Add to .claude/settings.json under hooks.Stop
# Only fires if the session has been substantive (checks git for recent changes)

# Check if there are uncommitted changes or recent commits in the last hour
# If yes, the session was substantive enough to warrant a review
RECENT_CHANGES=$(git diff --stat 2>/dev/null | tail -1)
RECENT_COMMITS=$(git log --oneline --since="1 hour ago" 2>/dev/null | head -5)

if [ -n "$RECENT_CHANGES" ] || [ -n "$RECENT_COMMITS" ]; then
    echo "SESSION_REVIEW_REMINDER: Esta sesión tuvo cambios significativos. Antes de terminar, revisa si hay gotchas, patrones o anti-patterns que deban añadirse al CLAUDE.md. Ejecuta el skill session-review para analizar la sesión y proponer actualizaciones."
fi
