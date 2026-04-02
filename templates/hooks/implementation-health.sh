#!/bin/bash
# Implementation Health Monitor — detects degradation patterns in real-time.
#
# Tracks objective signals via PostToolUse JSON stdin:
# - File churn: same file edited 4+ times → approach likely not working
# - Retry loops: same Bash command 3+ times → definition of insanity
# - Test regression: consecutive test failures → fixes aren't helping
# - Fix-test spiral: high edits + high test failures → confirmed spiral
#
# State: /tmp/claude-health-<session_id>/
# Works alongside context-watchdog.sh (separate concerns).
#
# Install: Add to .claude/settings.json under hooks.PostToolUse
# Requires: python3 (for JSON parsing; available on virtually all dev environments)

# Collect alerts — emitted via all available channels
# - Status line file: user sees in terminal status bar (via statusline.sh)
# - stderr: fallback (currently captured by Claude Code, kept for forward-compat)
# - stdout JSON (at end of script): Claude sees via additionalContext
ALERTS=""
alert() {
    local msg="$1"
    # Write to status line alert file (session-scoped, last alert wins)
    if [ -n "$SESSION_ID" ]; then
        echo "$msg" > "/tmp/claude-hooks-alert-${SESSION_ID}" 2>/dev/null
    fi
    echo "$msg" >&2
    ALERTS="${ALERTS:+$ALERTS | }$msg"
}

# Read JSON from stdin — exit silently on any failure
INPUT=$(cat 2>/dev/null) || exit 0
if [ -z "$INPUT" ]; then exit 0; fi

# Require python3/python for JSON parsing (replaces jq dependency)
PYTHON=$(command -v python3 2>/dev/null || command -v python 2>/dev/null || echo "")
[ -z "$PYTHON" ] && exit 0

# Parse all needed fields in a single python call (RS-delimited to handle multiline values)
# Uses ASCII Record Separator (0x1E) as delimiter — safe with any text content
PARSED=$(echo "$INPUT" | "$PYTHON" -c "
import sys, json
try:
    d = json.load(sys.stdin)
    ti = d.get('tool_input', {}) if isinstance(d.get('tool_input'), dict) else {}
    tr = d.get('tool_response', '')
    if not isinstance(tr, str):
        tr = str(tr)
    fields = [d.get('tool_name','unknown'), d.get('session_id',''), ti.get('file_path',''), ti.get('command',''), tr[:5000]]
    sys.stdout.write('\x1e'.join(fields))
except:
    sys.stdout.write('\x1e'.join(['unknown','','','','']))
" 2>/dev/null) || exit 0

# Split RS-delimited fields using parameter expansion (handles newlines in values)
RS=$'\x1e'
TOOL_NAME="${PARSED%%${RS}*}"; PARSED="${PARSED#*${RS}}"
SESSION_ID="${PARSED%%${RS}*}"; PARSED="${PARSED#*${RS}}"
FILE_PATH="${PARSED%%${RS}*}"; PARSED="${PARSED#*${RS}}"
COMMAND="${PARSED%%${RS}*}"; PARSED="${PARSED#*${RS}}"
RESPONSE="$PARSED"

# Fast path: only process relevant tools
case "$TOOL_NAME" in
    Edit|Write|MultiEdit|Bash) ;; # Continue processing
    *) exit 0 ;; # Not relevant — exit fast
esac

# Session ID fallback
if [ -z "$SESSION_ID" ]; then
    SESSION_ID=$(echo "$PWD" | md5sum | cut -c1-12)
fi

STATE_DIR="/tmp/claude-health-${SESSION_ID}"
mkdir -p "$STATE_DIR" 2>/dev/null || exit 0

# ─── FILE CHURN DETECTION ───────────────────────────────────────────────────
if [ "$TOOL_NAME" = "Edit" ] || [ "$TOOL_NAME" = "Write" ] || [ "$TOOL_NAME" = "MultiEdit" ]; then
    if [ -n "$FILE_PATH" ]; then
        # Skip tracking/documentation files — high edit counts are normal workflow
        IS_TRACKABLE=true
        case "$FILE_PATH" in
            */docs/*|*/README.md) IS_TRACKABLE=false ;;
        esac

        if [ "$IS_TRACKABLE" = true ]; then
            echo "$FILE_PATH" >> "$STATE_DIR/edits.log"

            EDIT_COUNT=$(grep -cF "$FILE_PATH" "$STATE_DIR/edits.log" 2>/dev/null || echo "0")
            BASENAME=$(basename "$FILE_PATH")
            FILE_HASH=$(echo "$FILE_PATH" | md5sum | cut -c1-8)

            # Churn without validation: many edits but no tests run (fires once per file)
            if [ "$EDIT_COUNT" -ge 4 ] && [ ! -f "$STATE_DIR/.churn_notest_${FILE_HASH}" ]; then
                TESTS_RUN=0
                if [ -f "$STATE_DIR/tests.log" ]; then
                    TESTS_RUN=$(wc -l < "$STATE_DIR/tests.log" | tr -d '[:space:]')
                fi
                if [ "$TESTS_RUN" -eq 0 ]; then
                    alert "IMPLEMENTATION_HEALTH [NO_VALIDATION]: ${BASENAME} edited ${EDIT_COUNT} times without running tests. Many changes without validation."
                    touch "$STATE_DIR/.churn_notest_${FILE_HASH}"
                fi
            fi
        fi
    fi
fi

# ─── BASH COMMAND TRACKING ──────────────────────────────────────────────────
if [ "$TOOL_NAME" = "Bash" ]; then
    if [ -n "$COMMAND" ]; then
        # Normalize and hash for deduplication
        CMD_HASH=$(echo "$COMMAND" | tr -s '[:space:]' ' ' | md5sum | cut -c1-16)
        echo "$CMD_HASH" >> "$STATE_DIR/bash.log"

        # ── Retry loop detection ──
        CMD_COUNT=$(grep -c "^${CMD_HASH}$" "$STATE_DIR/bash.log" 2>/dev/null || echo "0")
        if [ "$CMD_COUNT" -ge 3 ] && [ ! -f "$STATE_DIR/.retry_${CMD_HASH}" ]; then
            SHORT_CMD=$(echo "$COMMAND" | tr '\n' ' ' | head -c 80)
            alert "IMPLEMENTATION_HEALTH [RETRY_LOOP]: Same command executed ${CMD_COUNT} times: '${SHORT_CMD}'. If the result doesn't change, the problem is elsewhere."
            touch "$STATE_DIR/.retry_${CMD_HASH}"
        fi

        # ── Test result tracking ──
        IS_TEST=false
        CMD_LOWER=$(echo "$COMMAND" | tr '[:upper:]' '[:lower:]')
        case "$CMD_LOWER" in
            *npm\ test*|*yarn\ test*|*pnpm\ test*|*pytest*|*rspec*|*cargo\ test*|*go\ test*) IS_TEST=true ;;
            *jest*|*mocha*|*vitest*|*mix\ test*|*dotnet\ test*|*phpunit*|*make\ test*) IS_TEST=true ;;
            *bundle\ exec*rspec*|*bundle\ exec*test*|*rails\ test*) IS_TEST=true ;;
        esac

        if [ "$IS_TEST" = true ]; then
            HAS_FAILURE=0
            if echo "$RESPONSE" | grep -qiE '(FAIL|FAILED|FAILURE|ERROR|AssertionError|expected.*received|expected.*but got|test(s)? failed)'; then
                HAS_FAILURE=1
            fi

            echo "$HAS_FAILURE" >> "$STATE_DIR/tests.log"

            # Check trajectory over last runs
            if [ -f "$STATE_DIR/tests.log" ]; then
                TOTAL_RUNS=$(wc -l < "$STATE_DIR/tests.log" | tr -d '[:space:]')

                # 2+ consecutive failures: regression warning (fires once)
                if [ "$TOTAL_RUNS" -ge 2 ]; then
                    LAST_TWO_FAILS=$(tail -2 "$STATE_DIR/tests.log" | grep -c "1" | tr -d '[:space:]')
                    if [ "$LAST_TWO_FAILS" -ge 2 ] && [ ! -f "$STATE_DIR/.test_regression" ]; then
                        alert "IMPLEMENTATION_HEALTH [TEST_REGRESSION]: Tests failing for the last ${LAST_TWO_FAILS} consecutive runs. Fixes are not resolving the problem."
                        touch "$STATE_DIR/.test_regression"
                    fi
                fi

                # 3+ consecutive failures: spiral confirmed (fires once)
                if [ "$TOTAL_RUNS" -ge 3 ]; then
                    LAST_THREE_FAILS=$(tail -3 "$STATE_DIR/tests.log" | grep -c "1" | tr -d '[:space:]')
                    if [ "$LAST_THREE_FAILS" -ge 3 ] && [ ! -f "$STATE_DIR/.test_spiral" ]; then
                        alert "IMPLEMENTATION_HEALTH [SPIRAL]: 3 consecutive test runs failing. Spiral confirmed. Run /recovery for full diagnosis."
                        touch "$STATE_DIR/.test_spiral"
                    fi
                fi
            fi
        fi
    fi
fi

# ─── COMPOSITE SIGNAL: FIX-TEST SPIRAL ─────────────────────────────────────
# Cross-reference: high edit count + high test failures = confirmed spiral
if [ -f "$STATE_DIR/edits.log" ] && [ -f "$STATE_DIR/tests.log" ]; then
    TOTAL_EDITS=$(wc -l < "$STATE_DIR/edits.log" 2>/dev/null || echo "0")
    TOTAL_TEST_FAILS=$(grep -c "1" "$STATE_DIR/tests.log" 2>/dev/null || echo "0")

    if [ "$TOTAL_EDITS" -ge 6 ] && [ "$TOTAL_TEST_FAILS" -ge 3 ] && [ ! -f "$STATE_DIR/.composite_spiral" ]; then
        alert "IMPLEMENTATION_HEALTH [FIX_TEST_SPIRAL]: ${TOTAL_EDITS} edits + ${TOTAL_TEST_FAILS} test failures. Edit→test→fail pattern confirmed. Run /recovery or /clear and rethink with reduced scope."
        touch "$STATE_DIR/.composite_spiral"
    fi
fi

# ─── EMIT STRUCTURED JSON FOR CLAUDE ────────────────────────────────────────
if [ -n "$ALERTS" ]; then
    ESCAPED=$(echo "$ALERTS" | sed 's/\\/\\\\/g; s/"/\\"/g')
    echo "{\"hookSpecificOutput\":{\"hookEventName\":\"PostToolUse\",\"additionalContext\":\"${ESCAPED}\"}}"
fi

exit 0
