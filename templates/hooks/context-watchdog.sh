#!/bin/bash
# Context Watchdog — monitors real context usage and warns at degradation thresholds.
#
# How it works:
# - Reads actual used_percentage from /tmp/claude-context-pct-<session_id>
#   (written by statusline.sh, which gets real token data from Claude Code)
# - Alerts Claude via additionalContext JSON when thresholds are crossed
# - Maintains a tool call counter as diagnostic data (no alerts based on it)
#
# Thresholds (based on convergent research — RULER, MECW, Anthropic, Latent Patterns):
# - 40%: YELLOW — approaching effective boundary of context window
# - 65%: ORANGE — beyond effective zone, compaction recommended
# - 80%: RED — near auto-compaction (83.5%), fresh session recommended
#
# These thresholds are percentage-based, so they work correctly across all models
# regardless of context window size (200k Haiku, 1M Sonnet/Opus).
#
# Install: Add to .claude/settings.json under hooks.PostToolUse
# The hook receives tool name as argument

# Helper: emit alert via all available channels
# - Status line file: user sees in terminal status bar (via statusline.sh)
# - stderr: fallback (currently captured by Claude Code, kept for forward-compat)
# - stdout JSON (at end of script): Claude sees via additionalContext
ALERT_MSG=""
alert() {
    local msg="$1"
    # Write to status line alert file (session-scoped)
    if [ -n "$SESSION_ID" ]; then
        echo "$msg" > "/tmp/claude-hooks-alert-${SESSION_ID}" 2>/dev/null
    fi
    echo "$msg" >&2
    ALERT_MSG="$msg"
}

TOOL_NAME="${1:-unknown}"

# Extract session_id from PostToolUse JSON stdin (unique per Claude Code session)
SESSION_ID=""
INPUT=$(cat 2>/dev/null)
PYTHON=$(command -v python3 2>/dev/null || command -v python 2>/dev/null || echo "")
if [ -n "$INPUT" ] && [ -n "$PYTHON" ]; then
    SESSION_ID=$(echo "$INPUT" | "$PYTHON" -c "import sys,json;print(json.load(sys.stdin).get('session_id',''),end='')" 2>/dev/null)
fi

# Session ID fallback
if [ -z "$SESSION_ID" ]; then
    SESSION_ID=$(echo "$PWD" | md5sum | cut -c1-8)
fi

# ─── TOOL CALL COUNTER (diagnostic, no alerts) ────────────────────────────
COUNTER_FILE="/tmp/claude-context-calls-${SESSION_ID}"
if [ ! -f "$COUNTER_FILE" ]; then
    echo "0" > "$COUNTER_FILE"
fi
COUNT=$(cat "$COUNTER_FILE" 2>/dev/null || echo "0")
COUNT=$((COUNT + 1))
echo "$COUNT" > "$COUNTER_FILE"

# ─── CONTEXT PERCENTAGE MONITORING (real data from statusline.sh) ──────────
PCT_FILE="/tmp/claude-context-pct-${SESSION_ID}"
ALERT_STATE="/tmp/claude-context-alert-state-${SESSION_ID}"

# Read real context percentage (written by statusline.sh after each Claude response)
PCT=0
if [ -f "$PCT_FILE" ]; then
    PCT=$(cat "$PCT_FILE" 2>/dev/null || echo "0")
    # Sanitize: ensure it's a number
    case "$PCT" in
        ''|*[!0-9]*) PCT=0 ;;
    esac
fi

# Read last alert level to avoid repeating (fires once per threshold crossing)
LAST_ALERT=$(cat "$ALERT_STATE" 2>/dev/null || echo "none")

# Check thresholds — each fires once, escalating
if [ "$PCT" -ge 80 ] && [ "$LAST_ALERT" != "red" ]; then
    alert "CONTEXT_WATCHDOG [RED]: ${PCT}% context consumed. Near auto-compaction (83.5%). Automatic compaction may remove critical context. RECOMMENDATION: /clear and start a fresh session. Before /clear: document current state (what was done, what remains, decisions made)."
    echo "red" > "$ALERT_STATE" 2>/dev/null
elif [ "$PCT" -ge 65 ] && [ "$LAST_ALERT" != "orange" ] && [ "$LAST_ALERT" != "red" ]; then
    alert "CONTEXT_WATCHDOG [ORANGE]: ${PCT}% context consumed. Beyond the model's effective zone. Watch for: forgetting prior decisions, repeated errors, ignoring CLAUDE.md. Recommendation: /compact with instructions on what to preserve."
    echo "orange" > "$ALERT_STATE" 2>/dev/null
elif [ "$PCT" -ge 40 ] && [ "$LAST_ALERT" != "yellow" ] && [ "$LAST_ALERT" != "orange" ] && [ "$LAST_ALERT" != "red" ]; then
    alert "CONTEXT_WATCHDOG [YELLOW]: ${PCT}% context consumed. Approaching the effective zone boundary. If the current task is complex, consider /compact. Do not start new tasks — stay focused on the current one."
    echo "yellow" > "$ALERT_STATE" 2>/dev/null
fi

# Emit structured JSON so Claude sees the alert via additionalContext
if [ -n "$ALERT_MSG" ]; then
    # Escape double quotes and backslashes for JSON safety
    ESCAPED=$(echo "$ALERT_MSG" | sed 's/\\/\\\\/g; s/"/\\"/g')
    echo "{\"hookSpecificOutput\":{\"hookEventName\":\"PostToolUse\",\"additionalContext\":\"${ESCAPED}\"}}"
fi
