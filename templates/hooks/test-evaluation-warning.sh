#!/bin/bash
# Test Evaluation Warning — detects when existing tests are modified alongside implementation.
#
# Prevents a silent failure mode: Claude changes implementation away from requirements,
# then modifies tests to match the wrong logic, creating false positive "all tests pass."
#
# Fires on PostToolUse for Bash tool when command contains "git commit".
# Checks git diff --cached for co-modification of test + implementation files.
# Only warns on MODIFIED (M) test files, not ADDED (A) — new tests are expected.
#
# OPT-IN: Requires .claude/.test-eval-enabled file to activate.
# The file can optionally contain custom test patterns (one glob per line).
#
# Install: Add to .claude/settings.json under hooks.PostToolUse
# Requires: git

# ─── OPT-IN CHECK ─────────────────────────────────────────────────────────
CLAUDE_DIR=""
if [ -n "$CLAUDE_PROJECT_DIR" ]; then
    CLAUDE_DIR="$CLAUDE_PROJECT_DIR/.claude"
else
    CLAUDE_DIR="$(git rev-parse --show-toplevel 2>/dev/null)/.claude"
fi

if [ ! -f "$CLAUDE_DIR/.test-eval-enabled" ]; then
    exit 0
fi

# ─── PARSE INPUT ───────────────────────────────────────────────────────────
INPUT=$(cat 2>/dev/null) || exit 0
if [ -z "$INPUT" ]; then exit 0; fi

PYTHON=$(command -v python3 2>/dev/null || command -v python 2>/dev/null || echo "")
[ -z "$PYTHON" ] && exit 0

PARSED=$(echo "$INPUT" | "$PYTHON" -c "
import sys, json
try:
    d = json.load(sys.stdin)
    ti = d.get('tool_input', {}) if isinstance(d.get('tool_input'), dict) else {}
    fields = [d.get('tool_name','unknown'), d.get('session_id',''), ti.get('command','')]
    sys.stdout.write('\x1e'.join(fields))
except:
    sys.stdout.write('\x1e'.join(['unknown','','']))
" 2>/dev/null) || exit 0

RS=$'\x1e'
TOOL_NAME="${PARSED%%${RS}*}"; PARSED="${PARSED#*${RS}}"
SESSION_ID="${PARSED%%${RS}*}"; PARSED="${PARSED#*${RS}}"
COMMAND="$PARSED"

# ─── FAST PATH: only process Bash tool with git commit ─────────────────────
if [ "$TOOL_NAME" != "Bash" ]; then exit 0; fi

case "$COMMAND" in
    *git\ commit*|*git\ -c*commit*) ;; # Continue
    *) exit 0 ;;
esac

# ─── SESSION ID FALLBACK ──────────────────────────────────────────────────
if [ -z "$SESSION_ID" ]; then
    SESSION_ID=$(echo "$PWD" | md5sum | cut -c1-12)
fi

# ─── ONE-SHOT SENTINEL ────────────────────────────────────────────────────
SENTINEL="/tmp/claude-test-eval-${SESSION_ID}"
# Reset sentinel per commit (use command hash to detect new commits)
CMD_HASH=$(echo "$COMMAND" | md5sum | cut -c1-12)
if [ -f "${SENTINEL}_${CMD_HASH}" ]; then exit 0; fi

# ─── DETECT CO-MODIFICATION ───────────────────────────────────────────────
# Get only MODIFIED files (not Added) from staging area
MODIFIED_FILES=$(git diff --cached --diff-filter=M --name-only 2>/dev/null)
if [ -z "$MODIFIED_FILES" ]; then exit 0; fi

# ─── LOAD TEST PATTERNS ───────────────────────────────────────────────────
# Default test file patterns
DEFAULT_PATTERNS='_test\.|\.test\.|_spec\.|\.spec\.|^test_|/tests/|/__tests__/|/spec/|/test/'

# Load custom patterns from .test-eval-enabled if it has content
CUSTOM_PATTERNS=""
if [ -s "$CLAUDE_DIR/.test-eval-enabled" ]; then
    # Convert glob patterns to regex (one per line)
    while IFS= read -r pattern; do
        pattern=$(echo "$pattern" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        [ -z "$pattern" ] && continue
        [[ "$pattern" == \#* ]] && continue
        CUSTOM_PATTERNS="${CUSTOM_PATTERNS:+$CUSTOM_PATTERNS|}$pattern"
    done < "$CLAUDE_DIR/.test-eval-enabled"
fi

TEST_PATTERN="${CUSTOM_PATTERNS:-$DEFAULT_PATTERNS}"

# ─── CLASSIFY FILES ───────────────────────────────────────────────────────
HAS_TEST_MODS=false
HAS_IMPL_MODS=false
TEST_FILES=""

while IFS= read -r file; do
    [ -z "$file" ] && continue
    if echo "$file" | grep -qE "$TEST_PATTERN"; then
        HAS_TEST_MODS=true
        TEST_FILES="${TEST_FILES:+$TEST_FILES, }$(basename "$file")"
    else
        HAS_IMPL_MODS=true
    fi
done <<< "$MODIFIED_FILES"

# ─── EMIT WARNING ─────────────────────────────────────────────────────────
if [ "$HAS_TEST_MODS" = true ] && [ "$HAS_IMPL_MODS" = true ]; then
    MSG="TEST_EVAL_WARNING: Tests existentes modificados junto con implementación (${TEST_FILES}). ¿Es un cambio de comportamiento intencional? Si no, los tests existentes podrían haberse debilitado para pasar."

    # Write to status line alert file
    if [ -n "$SESSION_ID" ]; then
        echo "$MSG" > "/tmp/claude-hooks-alert-${SESSION_ID}" 2>/dev/null
    fi
    echo "$MSG" >&2

    # Mark sentinel to avoid re-firing for this commit
    touch "${SENTINEL}_${CMD_HASH}" 2>/dev/null

    # Structured JSON output for Claude
    ESCAPED=$(echo "$MSG" | sed 's/\\/\\\\/g; s/"/\\"/g')
    echo "{\"hookSpecificOutput\":{\"hookEventName\":\"PostToolUse\",\"additionalContext\":\"${ESCAPED}\"}}"
fi

exit 0
