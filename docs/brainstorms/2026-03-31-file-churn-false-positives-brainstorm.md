# Brainstorm: Fix File Churn False Positives in Implementation Health

**Date:** 2026-03-31
**Status:** Draft
**Trigger:** Recurring false positive alerts from file churn detection in implementation-health hook

## Context

The implementation-health hook's file churn detection counts raw edits per file and alerts at 4 (warning) and 7 (critical). In practice, this produces false positives in common workflows:

- **Plan/tracking files**: Marking checkboxes as tasks complete (7 edits = 7 checkboxes)
- **Multi-section edits**: Updating different sections of the same file for different reasons (e.g., adding comments to 4 sections of a template)

The hook has never produced a useful file churn alert in real usage. The purpose (detecting edit spirals) is valid, but the signal is too coarse.

## What We're Building

Two changes to `templates/hooks/implementation-health.sh`:

### 1. Exclude tracking/documentation files from churn counting

Files under `docs/` and `README.md` are excluded from file churn detection entirely. These are tracking files (plans, brainstorms, docs) where high edit counts are normal workflow.

CLAUDE.md and SKILL.md still count — edits to those can represent real spirals.

### 2. Replace churn-solo alerts with churn-without-validation signal

**Remove**: Standalone file churn alerts at thresholds 4 and 7 (lines 86-95). Churn alone is noise.

**Add**: New composite signal — "churn + zero test runs." If a file has been edited 4+ times AND no test command has been run during the session, alert: "N edits sin ejecutar tests. Muchos cambios sin validación."

This captures the real risk (flying blind — lots of changes without verification) without false positives from legitimate multi-section edits.

**Keep unchanged**: The existing composite signals (FIX_TEST_SPIRAL at lines 157-167, TEST_REGRESSION, RETRY_LOOP) remain as-is. They work correctly.

### Signal matrix after changes

| Signal | Fires when | Action |
|--------|-----------|--------|
| Churn + test failures (FIX_TEST_SPIRAL) | 6+ edits AND 3+ test failures | Recommend /recovery |
| Churn + zero test runs (NEW) | 4+ edits on code files AND 0 test runs in session | Warn: "muchos cambios sin validar" |
| Test regression | 2+ consecutive test failures | Warn |
| Test spiral | 3+ consecutive test failures | Recommend /recovery |
| Retry loop | Same command 3+ times | Warn |
| ~~Churn standalone~~ | ~~4/7 edits~~ | **REMOVED** |

## Why This Approach

- **Exclusion list eliminates the most common false positives** (docs, plans, README)
- **Churn-without-validation captures a real risk** that no current signal detects: making many changes without running tests
- **Churn-solo was always a weak signal** — it cannot distinguish "editing same bug 7 times" from "building up a file section by section." Removing it eliminates noise without losing real detection (covered by composites)
- **Minimal change**: only the file churn section (~20 lines) needs modification. All other signals unchanged.

## Key Decisions

1. **Exclude docs/ + README.md, keep CLAUDE.md** — tracking files don't indicate spirals, but framework configuration files (CLAUDE.md, SKILL.md) can
2. **Churn alone never alerts** — only composite signals (churn + test failure, churn + no tests, retry loops) produce alerts
3. **New composite: churn + zero tests** — captures "flying blind" pattern (many edits, no validation)
4. **Thresholds unchanged for composites** — existing FIX_TEST_SPIRAL thresholds (6 edits + 3 test fails) remain

## Resolved Questions

1. **Exclusion boundary** — `docs/` directory + `README.md`. Not all `.md` files (CLAUDE.md, SKILL.md should still count).
2. **Churn-solo behavior** — Eliminated entirely. Composite signals are sufficient.
3. **New signal threshold** — 4+ edits on non-excluded files AND 0 test runs in session.
