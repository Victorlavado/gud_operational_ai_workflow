---
title: "Fix file churn false positives in implementation-health hook"
type: fix
status: completed
date: 2026-03-31
origin: docs/brainstorms/2026-03-31-file-churn-false-positives-brainstorm.md
---

# Fix file churn false positives in implementation-health hook

## Overview

The file churn detection in `templates/hooks/implementation-health.sh` produces false positive alerts in common workflows (plan checkbox updates, multi-section edits). Replace the current churn-solo alerts with smarter signals: exclude tracking files from counting, and only alert when churn combines with zero test validation.

(see brainstorm: docs/brainstorms/2026-03-31-file-churn-false-positives-brainstorm.md)

## Problem Statement

Current file churn detection counts raw edits per file and alerts at thresholds 4 (warning) and 7 (critical). This produces false positives because the counter is context-blind — it cannot distinguish:
- Editing the same bug 7 times (real spiral)
- Marking 7 checkboxes in a plan file (normal progress)
- Adding comments to 4 sections of a template (normal work)

The hook has never produced a useful standalone file churn alert in real usage (see brainstorm: Context section).

## Proposed Solution

Two changes to `templates/hooks/implementation-health.sh` (lines 76-97):

### Change 1: Exclude tracking files from churn counting

Add a path filter before incrementing the edit counter. Files matching these patterns skip churn detection entirely:
- Files under `docs/` directory
- `README.md`

Files that still count: CLAUDE.md, SKILL.md, all source code files. (see brainstorm: Key Decision 1)

Implementation in the existing `if [ -n "$FILE_PATH" ]` block (line 78), add before `echo "$FILE_PATH" >> "$STATE_DIR/edits.log"`:

```bash
# Skip tracking/documentation files — high edit counts are normal workflow
case "$FILE_PATH" in
    */docs/*|*/README.md) ;; # Skip churn counting
    *)
        echo "$FILE_PATH" >> "$STATE_DIR/edits.log"
        # ... rest of churn logic
    ;;
esac
```

### Change 2: Replace churn-solo alerts with churn-without-validation

**Remove** lines 85-95 (standalone churn alerts at thresholds 4 and 7).

**Add** a new composite check: if a code file has 4+ edits AND no test command has been run during the session, emit a warning.

The hook already tracks test runs in `$STATE_DIR/tests.log` (line 129). The check:

```bash
# Churn without validation: many edits but no tests run
if [ "$EDIT_COUNT" -ge 4 ] && [ ! -f "$STATE_DIR/.churn_notest_${FILE_HASH}" ]; then
    TESTS_RUN=0
    if [ -f "$STATE_DIR/tests.log" ]; then
        TESTS_RUN=$(wc -l < "$STATE_DIR/tests.log" | tr -d '[:space:]')
    fi
    if [ "$TESTS_RUN" -eq 0 ]; then
        alert "IMPLEMENTATION_HEALTH [NO_VALIDATION]: ${BASENAME} editado ${EDIT_COUNT} veces sin ejecutar tests. Muchos cambios sin validación."
        touch "$STATE_DIR/.churn_notest_${FILE_HASH}"
    fi
fi
```

### What stays unchanged

- FIX_TEST_SPIRAL composite (lines 157-167) — works correctly
- TEST_REGRESSION detection (lines 136-152) — works correctly
- RETRY_LOOP detection (lines 107-112) — works correctly
- All state file management — unchanged

## Acceptance Criteria

- [x] Files under `docs/` and `README.md` do not increment the edit counter
- [x] CLAUDE.md and SKILL.md still increment the edit counter
- [x] Standalone churn alerts at thresholds 4 and 7 are removed
- [x] New composite alert fires when: 4+ edits on a code file AND 0 test runs in session
- [x] New alert uses one-shot sentinel (fires once per file, not repeatedly)
- [x] Existing composite signals (FIX_TEST_SPIRAL, TEST_REGRESSION, RETRY_LOOP) unchanged
- [x] Hook still exits cleanly on all edge cases (missing python3, empty input, etc.)

## Success Metrics

- Zero false positive churn alerts on plan/doc editing workflows
- "No validation" alert fires correctly when editing code without running tests

## Sources & References

- **Origin brainstorm:** [docs/brainstorms/2026-03-31-file-churn-false-positives-brainstorm.md](docs/brainstorms/2026-03-31-file-churn-false-positives-brainstorm.md) — Key decisions: exclude docs/+README (not all .md), churn-solo never alerts, new churn+zero-tests composite
- **Implementation target:** `templates/hooks/implementation-health.sh:76-97`
- **Existing composite reference:** `templates/hooks/implementation-health.sh:157-167`
