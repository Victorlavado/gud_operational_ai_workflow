#!/bin/bash
# Context Watchdog — tracks interaction count per session and warns at degradation thresholds.
#
# How it works:
# - Uses a temp file (/tmp/claude-context-<session-id>) to count PostToolUse events per session
# - Each tool call increments the counter
# - At defined thresholds, outputs warnings that Claude sees as feedback
#
# Thresholds (based on Latent Patterns research: smart zone ~40% utilization):
# - 30 tool calls: YELLOW — approaching smart zone boundary
# - 50 tool calls: ORANGE — likely beyond smart zone, consider /compact
# - 80 tool calls: RED — high degradation risk, /clear recommended
#
# Install: Add to .claude/settings.json under hooks.PostToolUse
# The hook receives tool name as argument

# Helper: emit alert to stderr (user terminal) + structured JSON to stdout (Claude context)
# PostToolUse hooks require additionalContext JSON for Claude to see the output.
ALERT_MSG=""
alert() {
    local msg="$1"
    echo "$msg" >&2
    ALERT_MSG="$msg"
}

TOOL_NAME="${1:-unknown}"

# Session tracking via temp file (unique per terminal session)
SESSION_FILE="/tmp/claude-context-$$"

# If parent PID-based tracking doesn't work, fallback to PWD-based
if [ ! -f "$SESSION_FILE" ]; then
    SESSION_FILE="/tmp/claude-context-$(echo "$PWD" | md5sum | cut -c1-8)"
fi

# Initialize counter if first call
if [ ! -f "$SESSION_FILE" ]; then
    echo "0" > "$SESSION_FILE"
fi

# Increment counter
COUNT=$(cat "$SESSION_FILE")
COUNT=$((COUNT + 1))
echo "$COUNT" > "$SESSION_FILE"

# Check thresholds and output warnings
if [ "$COUNT" -eq 30 ]; then
    alert "CONTEXT_WATCHDOG [YELLOW]: 30 tool calls en esta sesión. Te acercas al límite de la zona inteligente (~40% del contexto). Si la tarea actual es compleja, considera usar /compact para preservar el contexto esencial, o finaliza la tarea actual antes de empezar otra."
elif [ "$COUNT" -eq 50 ]; then
    alert "CONTEXT_WATCHDOG [ORANGE]: 50 tool calls. Probablemente estás más allá de la zona inteligente. Señales a vigilar: Claude olvida decisiones previas, repite errores corregidos, o ignora instrucciones del CLAUDE.md. Recomendación: /compact con instrucciones de qué preservar, o /clear + reformular con lo aprendido en esta sesión."
elif [ "$COUNT" -eq 80 ]; then
    alert "CONTEXT_WATCHDOG [RED]: 80 tool calls. Alto riesgo de degradación. La compactación automática puede haber eliminado contexto crítico. RECOMENDACIÓN: /clear y empezar sesión fresca. Antes de /clear: documenta el estado actual (qué se hizo, qué queda, decisiones tomadas) para poder retomar sin fricción."
elif [ "$((COUNT % 20))" -eq 0 ] && [ "$COUNT" -gt 80 ]; then
    alert "CONTEXT_WATCHDOG [RED]: $COUNT tool calls. Sesión muy larga. Calidad de output probablemente degradada. Usa /clear."
fi

# Emit structured JSON so Claude sees the alert via additionalContext
if [ -n "$ALERT_MSG" ]; then
    # Escape double quotes and backslashes for JSON safety
    ESCAPED=$(echo "$ALERT_MSG" | sed 's/\\/\\\\/g; s/"/\\"/g')
    echo "{\"hookSpecificOutput\":{\"hookEventName\":\"PostToolUse\",\"additionalContext\":\"${ESCAPED}\"}}"
fi
