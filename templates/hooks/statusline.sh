#!/bin/bash
# Status line — displays context usage and hook alerts in the Claude Code terminal.
#
# Dual role:
# 1. Visual: shows context bar + hook alerts to the user
# 2. Data bridge: writes used_percentage to /tmp/claude-context-pct-<session_id>
#    so PostToolUse hooks (context-watchdog) can use real % instead of tool call proxies
#
# Hooks write alerts to /tmp/claude-hooks-alert-<session_id>.
# This script reads that file and displays the latest alert with color coding.
#
# Context degradation thresholds (based on convergent research):
#   GREEN  <40%  — within Anthropic's recommended optimal zone
#   YELLOW  40%  — approaching effective boundary (RULER/MECW research: 60-70%)
#   ORANGE  65%  — beyond effective zone, compaction recommended
#   RED     80%  — near auto-compaction (83.5%), fresh session recommended
#
# Install: Add statusLine to .claude/settings.json (see settings.json.template)

input=$(cat)

# Parse session state in a single python3 call (RS-delimited for safety)
PARSED=$(echo "$input" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    m = d.get('model', {})
    ctx = d.get('context_window', {})
    import os
    cwd = d.get('cwd', '')
    dirname = os.path.basename(cwd) if cwd else '?'
    fields = [
        m.get('display_name', m.get('id', '?')),
        str(int(ctx.get('used_percentage', 0) or 0)),
        d.get('session_id', ''),
        str(ctx.get('context_window_size', 200000)),
        dirname
    ]
    sys.stdout.write('\x1e'.join(fields))
except:
    sys.stdout.write('\x1e'.join(['?','0','','200000','?']))
" 2>/dev/null) || exit 0

RS=$'\x1e'
MODEL="${PARSED%%${RS}*}"; PARSED="${PARSED#*${RS}}"
PCT="${PARSED%%${RS}*}"; PARSED="${PARSED#*${RS}}"
SESSION_ID="${PARSED%%${RS}*}"; PARSED="${PARSED#*${RS}}"
MAX_CTX="${PARSED%%${RS}*}"; PARSED="${PARSED#*${RS}}"
DIR_NAME="$PARSED"

# Write real context percentage to shared state file (read by context-watchdog hook)
if [ -n "$SESSION_ID" ] && [ -n "$PCT" ]; then
    echo "$PCT" > "/tmp/claude-context-pct-${SESSION_ID}" 2>/dev/null
fi

# Colors
C_RESET='\033[0m'
C_DIM='\033[38;5;245m'
C_GREEN='\033[38;5;71m'
C_YELLOW='\033[38;5;178m'
C_ORANGE='\033[38;5;208m'
C_RED='\033[38;5;196m'
C_BAR_EMPTY='\033[38;5;238m'

# Context bar (10 blocks)
bar=""
for ((i=0; i<10; i++)); do
    threshold=$((i * 10))
    progress=$((PCT - threshold))
    if [ "$progress" -ge 8 ]; then
        # Color block based on degradation thresholds
        if [ "$PCT" -lt 40 ]; then
            bar+="${C_GREEN}█${C_RESET}"
        elif [ "$PCT" -lt 65 ]; then
            bar+="${C_YELLOW}█${C_RESET}"
        elif [ "$PCT" -lt 80 ]; then
            bar+="${C_ORANGE}█${C_RESET}"
        else
            bar+="${C_RED}█${C_RESET}"
        fi
    elif [ "$progress" -ge 3 ]; then
        bar+="${C_DIM}▄${C_RESET}"
    else
        bar+="${C_BAR_EMPTY}░${C_RESET}"
    fi
done

# Format max context display
MAX_K=$((MAX_CTX / 1000))
if [ "$MAX_K" -ge 1000 ]; then
    MAX_DISPLAY="$((MAX_K / 1000))M"
else
    MAX_DISPLAY="${MAX_K}k"
fi

# Line 1: Dir | Model | Context bar
printf '%b\n' "${C_DIM}${DIR_NAME} | ${MODEL}${C_RESET} ${bar} ${C_DIM}${PCT}% of ${MAX_DISPLAY}${C_RESET}"

# Line 2: Hook alert (if recent)
ALERT_FILE="/tmp/claude-hooks-alert-${SESSION_ID}"
if [ -n "$SESSION_ID" ] && [ -f "$ALERT_FILE" ]; then
    # Only show if file was modified within last 10 minutes
    FILE_MTIME=$(stat -c %Y "$ALERT_FILE" 2>/dev/null || echo 0)
    NOW=$(date +%s)
    AGE=$(( NOW - FILE_MTIME ))

    if [ "$AGE" -lt 600 ]; then
        ALERT=$(cat "$ALERT_FILE" 2>/dev/null)
        if [ -n "$ALERT" ]; then
            # Color based on severity level in the message
            if echo "$ALERT" | grep -qE '\[RED\]|SPIRAL|CRITICAL'; then
                printf '%b\n' "${C_RED}${ALERT}${C_RESET}"
            elif echo "$ALERT" | grep -q '\[ORANGE\]'; then
                printf '%b\n' "${C_ORANGE}${ALERT}${C_RESET}"
            elif echo "$ALERT" | grep -q '\[YELLOW\]'; then
                printf '%b\n' "${C_YELLOW}${ALERT}${C_RESET}"
            else
                printf '%b\n' "${C_YELLOW}${ALERT}${C_RESET}"
            fi
        fi
    fi
fi
