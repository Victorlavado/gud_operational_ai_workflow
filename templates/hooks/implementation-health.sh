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
# Requires: jq

# Read JSON from stdin — exit silently on any failure
INPUT=$(cat 2>/dev/null) || exit 0
if [ -z "$INPUT" ]; then exit 0; fi

# Require jq
command -v jq &>/dev/null || exit 0

# Quick parse: tool name (fast path for irrelevant tools)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // "unknown"' 2>/dev/null) || exit 0
case "$TOOL_NAME" in
    Edit|Write|MultiEdit|Bash) ;; # Continue processing
    *) exit 0 ;; # Not relevant — exit fast
esac

# Parse session ID for state tracking
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty' 2>/dev/null)
if [ -z "$SESSION_ID" ]; then
    SESSION_ID=$(echo "$PWD" | md5sum | cut -c1-12)
fi

STATE_DIR="/tmp/claude-health-${SESSION_ID}"
mkdir -p "$STATE_DIR" 2>/dev/null || exit 0

# ─── FILE CHURN DETECTION ───────────────────────────────────────────────────
if [ "$TOOL_NAME" = "Edit" ] || [ "$TOOL_NAME" = "Write" ] || [ "$TOOL_NAME" = "MultiEdit" ]; then
    FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null)
    if [ -n "$FILE_PATH" ]; then
        echo "$FILE_PATH" >> "$STATE_DIR/edits.log"

        EDIT_COUNT=$(grep -cF "$FILE_PATH" "$STATE_DIR/edits.log" 2>/dev/null || echo "0")
        BASENAME=$(basename "$FILE_PATH")
        FILE_HASH=$(echo "$FILE_PATH" | md5sum | cut -c1-8)

        # Threshold 4: warning (fires once per file)
        if [ "$EDIT_COUNT" -ge 4 ] && [ ! -f "$STATE_DIR/.churn_4_${FILE_HASH}" ]; then
            echo "IMPLEMENTATION_HEALTH [FILE_CHURN]: ${BASENAME} editado ${EDIT_COUNT} veces en esta sesión. Si son correcciones al mismo problema, el enfoque actual probablemente no funciona. Considera replantear."
            touch "$STATE_DIR/.churn_4_${FILE_HASH}"
        fi

        # Threshold 7: critical (fires once per file)
        if [ "$EDIT_COUNT" -ge 7 ] && [ ! -f "$STATE_DIR/.churn_7_${FILE_HASH}" ]; then
            echo "IMPLEMENTATION_HEALTH [FILE_CHURN_CRITICAL]: ${BASENAME} editado ${EDIT_COUNT} veces. Señal clara de espiral. Invoca /recovery para diagnóstico y recomendación de recuperación."
            touch "$STATE_DIR/.churn_7_${FILE_HASH}"
        fi
    fi
fi

# ─── BASH COMMAND TRACKING ──────────────────────────────────────────────────
if [ "$TOOL_NAME" = "Bash" ]; then
    COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)

    if [ -n "$COMMAND" ]; then
        # Normalize and hash for deduplication
        CMD_HASH=$(echo "$COMMAND" | tr -s '[:space:]' ' ' | md5sum | cut -c1-16)
        echo "$CMD_HASH" >> "$STATE_DIR/bash.log"

        # ── Retry loop detection ──
        CMD_COUNT=$(grep -c "^${CMD_HASH}$" "$STATE_DIR/bash.log" 2>/dev/null || echo "0")
        if [ "$CMD_COUNT" -ge 3 ] && [ ! -f "$STATE_DIR/.retry_${CMD_HASH}" ]; then
            SHORT_CMD=$(echo "$COMMAND" | tr '\n' ' ' | head -c 80)
            echo "IMPLEMENTATION_HEALTH [RETRY_LOOP]: Mismo comando ejecutado ${CMD_COUNT} veces: '${SHORT_CMD}'. Si el resultado no cambia, el problema está en otro sitio."
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
            # Extract response (truncated) to check for failure patterns
            RESPONSE=$(echo "$INPUT" | jq -r '
                if .tool_response | type == "string" then .tool_response
                else (.tool_response | tostring)
                end' 2>/dev/null | head -c 5000)

            HAS_FAILURE=0
            if echo "$RESPONSE" | grep -qiE '(FAIL|FAILED|FAILURE|ERROR|AssertionError|expected.*received|expected.*but got|test(s)? failed)'; then
                HAS_FAILURE=1
            fi

            echo "$HAS_FAILURE" >> "$STATE_DIR/tests.log"

            # Check trajectory over last 3 runs
            if [ -f "$STATE_DIR/tests.log" ]; then
                TOTAL_RUNS=$(wc -l < "$STATE_DIR/tests.log")

                # 2+ consecutive failures: regression warning (fires once)
                if [ "$TOTAL_RUNS" -ge 2 ]; then
                    LAST_TWO_FAILS=$(tail -2 "$STATE_DIR/tests.log" | grep -c "1" || echo "0")
                    if [ "$LAST_TWO_FAILS" -ge 2 ] && [ ! -f "$STATE_DIR/.test_regression" ]; then
                        echo "IMPLEMENTATION_HEALTH [TEST_REGRESSION]: Tests fallando en las últimas ${LAST_TWO_FAILS} ejecuciones consecutivas. Los fixes no están resolviendo el problema."
                        touch "$STATE_DIR/.test_regression"
                    fi
                fi

                # 3+ consecutive failures: spiral confirmed (fires once)
                if [ "$TOTAL_RUNS" -ge 3 ]; then
                    LAST_THREE_FAILS=$(tail -3 "$STATE_DIR/tests.log" | grep -c "1" || echo "0")
                    if [ "$LAST_THREE_FAILS" -ge 3 ] && [ ! -f "$STATE_DIR/.test_spiral" ]; then
                        echo "IMPLEMENTATION_HEALTH [SPIRAL]: 3 ejecuciones de tests consecutivas fallando. Espiral confirmada. Invoca /recovery para diagnóstico completo."
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
        echo "IMPLEMENTATION_HEALTH [FIX_TEST_SPIRAL]: ${TOTAL_EDITS} edits + ${TOTAL_TEST_FAILS} test failures. Patrón edit→test→fail confirmado. Invoca /recovery o haz /clear y replantea con scope reducido."
        touch "$STATE_DIR/.composite_spiral"
    fi
fi

exit 0
