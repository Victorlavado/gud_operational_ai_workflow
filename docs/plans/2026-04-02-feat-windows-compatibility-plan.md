---
title: "feat: Add Windows compatibility for install and sync scripts"
type: feat
status: completed
date: 2026-04-02
---

# feat: Add Windows compatibility for install and sync scripts

## Overview

The framework's install and sync scripts (`.sh`) cannot be executed natively on Windows — the OS prompts users to choose a program to open them. While the hook execution layer already works on Windows (settings.json uses `bash "..."` prefix), the initial installation entry point and several internal assumptions break on Windows.

## Problem Statement / Motivation

A user on Windows with Git Bash installed cannot run `./install.sh ~/dev/my-project` from PowerShell or CMD. Windows doesn't associate `.sh` files with bash. This blocks the first-time installation experience — the only way to install is to already know you need to type `bash install.sh`, which defeats the purpose of having a simple install command.

Additionally, several scripts assume `python3` is the command name, but Windows installs Python 3 as `python`. This causes silent failures in hooks (implementation-health exits, context-watchdog loses JSON parsing, statusline breaks).

## Proposed Solution

1. **Add `.gitattributes`** to enforce LF line endings on `.sh` files (CRLF breaks bash scripts)
2. **Add `install.bat`** wrapper that detects Git Bash and invokes `bash install.sh %*`
3. **Standardize Python detection** across all scripts (`python3` fallback to `python`)
4. **Fix process substitution** in `auto-update.sh` (replace `bash <(echo ...)` with temp-file approach)
5. **Update README.md** with Windows installation instructions

## Technical Considerations

### Critical: `.gitattributes` (line endings)

Without this, `git clone` on Windows with default config (`core.autocrlf=true`) produces CRLF line endings in `.sh` files, causing `\r: command not found` errors. This must be the first change.

```
*.sh text eol=lf
*.bat text eol=crlf
*.md text auto
*.json text auto
```

### Critical: `install.bat` wrapper

Must distinguish Git Bash from WSL bash — WSL uses a different filesystem namespace (`/mnt/c/` vs `/c/`) and would cause path mismatches with `$CLAUDE_PROJECT_DIR`.

Detection strategy:
- Check if `git` is in PATH (implies Git for Windows with bash)
- Use `git --exec-path` to derive bash location, or check `bash --version` for "msys"/"mingw"
- If only WSL bash found, warn the user to install Git for Windows
- If no bash at all, provide clear error with download link

### Important: Python detection (10 invocation sites across 6 files)

Current pattern: `command -v python3` or direct `python3` calls.

New pattern (apply to each script):
```bash
PYTHON=$(command -v python3 2>/dev/null || command -v python 2>/dev/null || echo "")
```

Then use `$PYTHON` throughout. Also add a Python 3 version guard where critical.

**Files affected:**
| File | Lines | Current behavior |
|------|-------|-----------------|
| `install.sh` | 26 | Warning only (cosmetic) |
| `bin/sync.sh` | 118 | JSON merge (has fallback) |
| `templates/hooks/context-watchdog.sh` | 41 | JSON parsing |
| `templates/hooks/implementation-health.sh` | 36 | Hard requirement, exits |
| `templates/hooks/statusline.sh` | 23 | **No guard at all** (bug) |
| `templates/hooks/test-evaluation-warning.sh` | 33 | JSON parsing |

### Important: Process substitution in `auto-update.sh`

Line 60: `bash <(echo "$SYNC_SCRIPT") "$CLAUDE_PROJECT_DIR" --remote`

Process substitution (`<()`) may not work reliably across all bash-on-Windows configurations. Replace with:

```bash
TMPFILE=$(mktemp)
echo "$SYNC_SCRIPT" > "$TMPFILE"
bash "$TMPFILE" "$CLAUDE_PROJECT_DIR" --remote
rm -f "$TMPFILE"
```

### Low risk: Verified compatible in Git Bash

These items were investigated and work correctly in Git Bash — no changes needed:
- `/tmp/` state files (MSYS2 maps to Windows temp)
- `md5sum`, `curl`, `sed`, `diff`, `date +%s` (bundled in Git Bash)
- `stat -c %Y` (GNU coreutils in Git Bash)
- `chmod +x` (no-op on NTFS, harmless with `2>/dev/null || true`)
- ANSI color codes in statusline (Windows Terminal supports 256-color)

### Verification needed: `$CLAUDE_PROJECT_DIR` format

Claude Code on Windows sets this env var for hooks. Need to verify empirically whether it uses Windows paths (`C:\Users\...`) or MSYS2 paths (`/c/Users/...`). The hooks in settings.json already use `bash "..."`, so Claude Code likely provides the path in a format bash can handle. Add a debug echo to one hook during testing to confirm.

## Acceptance Criteria

- [x] `.gitattributes` added with `*.sh text eol=lf` and `*.bat text eol=crlf`
- [x] `install.bat` created at repo root, detects Git Bash, rejects WSL-only bash, provides clear error if no bash found
- [x] All 6 files with `python3` references updated to use `python3 || python` detection pattern
- [x] `statusline.sh` gets missing python availability guard (pre-existing bug)
- [x] `auto-update.sh` process substitution replaced with temp-file approach
- [x] `install.sh` python warning updated with Windows install instructions (`winget install Python.Python.3` or python.org)
- [x] README.md updated with Windows installation section
- [ ] Manual test: clone repo on Windows, run `install.bat C:\path\to\project` successfully

## Success Metrics

- A user on Windows with Git Bash can install the framework by double-clicking `install.bat` or running it from CMD/PowerShell
- All hooks execute correctly in Claude Code sessions on Windows
- No CRLF-related script failures after fresh `git clone` on Windows

## Dependencies & Risks

**Dependencies:**
- Git for Windows (provides bash, curl, coreutils) — this is the baseline requirement
- Python 3 — already a dependency, just needs correct detection on Windows

**Risks:**
- `$CLAUDE_PROJECT_DIR` format unknown — mitigated by empirical verification during implementation
- WSL bash interference — mitigated by explicit Git Bash detection in `install.bat`
- Existing Windows users may have CRLF copies — `.gitattributes` only affects future clones; existing clones need `git checkout -- .` or re-clone

## Sources & References

### Internal References
- `install.sh` — current install entry point (bash-only)
- `bin/sync.sh` — sync engine with python3 dependency
- `templates/hooks/settings.json.template` — hook invocation pattern (already uses `bash "..."`)
- All 6 hook scripts in `templates/hooks/` — python3 references

### External References
- Git for Windows: provides MSYS2 bash environment
- `.gitattributes` documentation: standard practice for cross-platform repos
