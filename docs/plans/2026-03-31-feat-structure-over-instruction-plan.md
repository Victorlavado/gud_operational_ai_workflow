---
title: "Structure Over Instruction: Path-Scoped Rules, Evaluation Surface Warning, Knowledge Graduation"
type: feat
status: completed
date: 2026-03-31
origin: docs/brainstorms/2026-03-31-structure-over-instruction-brainstorm.md
---

# Structure Over Instruction

Three independent improvements that shift the framework from behavioral instruction (CLAUDE.md text) to structural constraint (mechanisms that enforce without relying on the agent reading correctly).

(see brainstorm: docs/brainstorms/2026-03-31-structure-over-instruction-brainstorm.md)

## Overview

| Phase | Improvement | Core change |
|-------|-------------|-------------|
| 1 | Path-Scoped Rules | Decompose Project Layer into `.claude/rules/` files loaded contextually |
| 2 | Test Evaluation Warning | Hook that warns on test+implementation co-modification |
| 3 | Knowledge Graduation | Session-review persists corrections, auto-promotes after N=3 |
| Bonus | Sync bug fix | Add `statusline.sh` to sync list (pre-existing bug) |

Phases are independent. Each can be implemented and shipped separately.

## Problem Statement / Motivation

Layer 1 is mature, but the framework relies heavily on CLAUDE.md instructions — behavioral guidance the agent may ignore under context pressure or ambiguous prompts. Comparison with Meta Alchemist's 4-layer system and Karpathy's autoresearch revealed a shared principle: **structural constraints outperform behavioral instructions** because they work regardless of prompt quality.

Three specific failure modes this addresses:
1. **Context noise**: Agent loads all project rules even when only editing one area
2. **Silent test weakening**: Agent modifies tests to match wrong logic, creating false positive progress
3. **Knowledge loss**: Same corrections proposed across sessions but never graduating to permanent rules

## Proposed Solution

### Phase 1: Path-Scoped Rules

**Principle**: If an instruction only applies when editing files in a specific area, it goes in `.claude/rules/`. If it applies globally, it stays in CLAUDE.md. (see brainstorm: Key Decision 1)

**Uses Claude Code's native `.claude/rules/` format** with `globs` frontmatter:

```markdown
---
globs: ["src/api/**", "app/controllers/**"]
---

# API Conventions

- Always use DTOs for request/response serialization
- Validate input at the controller boundary, not in services
```

**Changes:**

#### 1.1 Update `templates/project-layer.md`

Add guidance in comment headers for sections that can be path-scoped (Patterns, Gotchas, Quality Gates). Explain the decision rule. Add an example of a rules file with globs frontmatter.

Sections that stay in CLAUDE.md (global):
- Architecture overview, Stack
- Domain (models, business rules, vocabulary)
- Workflow (branching, deploy)
- Commands

Sections candidates for `.claude/rules/` (path-specific):
- Patterns > Code conventions (when area-specific)
- Patterns > Architecture patterns (when area-specific)
- Anti-patterns (project-specific, when area-specific)
- Gotchas (when tied to a specific subsystem)
- Quality Gates overrides (when different per area)

#### 1.2 Update `.claude/commands/bootstrap-intelligence.md`

Add a new phase after code structure scanning:

1. Detect project areas with significant code (>5 files in a directory tree with a common concern)
2. For each detected area, generate a `.claude/rules/<area>.md` file with:
   - `globs` frontmatter matching the area's file paths
   - Discovered patterns, gotchas, and conventions for that area
3. Content that goes into rules files is NOT duplicated in CLAUDE.md
4. Present generated rules files for user approval (same pattern as existing CLAUDE.md proposals)

#### 1.3 Update `.claude/commands/init-project.md`

Informational only: add a line in the output that mentions the decomposition pattern and suggests running `/bootstrap-intelligence` for an existing codebase. No rules files generated.

#### 1.4 Update `.claude/skills/session-review/SKILL.md`

Make session-review rules-aware:

1. Check if `.claude/rules/` exists and contains rules files
2. When proposing a gotcha/pattern update:
   - If a matching rules file exists for the affected path → propose update there
   - If no matching rules file exists → propose in CLAUDE.md (existing behavior)
3. When CLAUDE.md exceeds ~400 lines → suggest decomposing path-specific content to rules files

#### 1.5 Rules files are project-owned

`sync.sh` does NOT sync rules files. They belong to the project, not the framework. This is consistent with the existing design where Common Layer is synced but Project Layer is never touched.

---

### Phase 2: Test Evaluation Warning Hook

**Principle**: Warning, not blocking. The value is visibility, not enforcement. (see brainstorm: Key Decision 2)

**Precondition**: Only valuable for projects with mature test suites that correctly encode current behavior. (see brainstorm: Key Decision 3)

**Changes:**

#### 2.1 Create `templates/hooks/test-evaluation-warning.sh`

Hook structure (follows `implementation-health.sh` pattern):

- **Event**: `PostToolUse` on `Bash` tool
- **Trigger**: Command contains `git commit`
- **Detection logic**:
  1. Run `git diff --cached --diff-filter=M --name-only` (only Modified files, not Added)
  2. Classify files as test or implementation using configurable patterns
  3. Default test patterns: `*_test.*`, `*.test.*`, `*_spec.*`, `*.spec.*`, `test_*.*`, plus files under `tests/`, `__tests__/`, `spec/` directories
  4. If BOTH modified test files AND modified implementation files are staged → emit warning
- **Warning output**: Status line alert + stderr + JSON additionalContext (triple-channel, existing pattern)
- **Warning message**: "Test files modified alongside implementation. Intentional behavior change? If not, existing tests may have been weakened to pass."
- **Key distinction**: New test files (git status `A`) do NOT trigger the warning. Only modifications to EXISTING tests (`M`) trigger it. This avoids false positives on normal feature development with new tests.

#### 2.2 Opt-in mechanism

The hook script checks for `.claude/.test-eval-enabled` file at startup. If absent, exits immediately (fast path). This avoids the `sync.sh` merge problem — the hook is always synced and always wired in `settings.json.template`, but does nothing unless the project opts in.

The `.test-eval-enabled` file can optionally contain custom test file patterns (one glob per line), overriding the defaults.

#### 2.3 Add to `templates/hooks/settings.json.template`

Wire the hook to `PostToolUse` event alongside existing hooks. Since it self-disables without the opt-in file, no special disabled state is needed.

#### 2.4 Add to `bin/sync.sh` hook list

Add `test-evaluation-warning.sh` to the hook sync loop (line ~93).

#### 2.5 Document in `templates/common-layer.md`

Add a brief mention in the Quality Gates section: "For projects with mature test suites, enable the test-evaluation-warning hook to detect when existing tests are modified alongside implementation. See `.claude/.test-eval-enabled`."

#### 2.6 Status line integration

Warning appears in status line via the existing `/tmp/claude-hooks-alert-<session_id>` mechanism. Uses a one-shot sentinel to avoid re-firing within the same commit sequence.

---

### Phase 3: Knowledge Graduation

**Principle**: Append-only log, N=3 threshold, LLM-based matching. (see brainstorm: Key Decisions 4, Resolved Questions 2-3)

**Changes:**

#### 3.1 Correction log format

Location: `.claude/corrections.log` per project (consistent with `.claude/.upstream-proposals`).

Format: TSV with header

```tsv
date	category	description	session	status
2026-03-15	gotcha	Docker compose must rebuild after Python code changes	abc123	active
2026-03-18	anti-pattern	Using print() instead of logger in service layer	def456	active
2026-03-22	gotcha	Docker compose must rebuild after Python code changes	ghi789	active
2026-03-25	gotcha	Docker compose must rebuild after Python code changes	jkl012	promoted
```

- **Categories** (controlled vocabulary, maps to CLAUDE.md sections): `gotcha`, `pattern`, `anti-pattern`, `convention`, `quality-gate`, `domain-rule`
- **Status**: `active` (can count toward threshold) or `promoted` (graduated, skip in future counts)
- **Session**: short identifier to track which session produced the correction

#### 3.2 Update `.claude/skills/session-review/SKILL.md`

Add two new steps to session-review:

**Step: Log corrections** (after existing analysis, before proposing updates)
1. For each correction/gotcha/pattern discovered in the session:
   - Assign a category from the controlled vocabulary
   - Append a TSV line to `.claude/corrections.log` with status `active`

**Step: Check for graduations** (after logging)
1. Read `.claude/corrections.log`
2. Group `active` entries by semantic similarity (LLM judgment, using category as clustering hint)
3. For groups with 3+ entries:
   - Determine the target CLAUDE.md section based on category (`gotcha` → Gotchas, `pattern` → Patterns, etc.)
   - If `.claude/rules/` exists and a matching rules file covers the path → propose update in rules file instead
   - Auto-promote: add the correction to CLAUDE.md (or rules file) with a comment noting it graduated from 3 occurrences
   - Mark all entries in the group as `promoted` in the log
4. For groups with <3 entries: report as "trending corrections" in session-review output (informational)

**Interaction with upstream proposals**: If a graduated correction is classified as universal (not project-specific), it ALSO goes to `.claude/.upstream-proposals`. Existing upstream pipeline handles the rest.

#### 3.3 Deduplication

Before appending a new correction, session-review checks if the same correction was already `promoted`. If the correction already exists as a rule in CLAUDE.md or a rules file, it does NOT log it again. This prevents re-promotion loops.

#### 3.4 Update `protocols/internal-maintenance.md`

Reference `corrections.log` in:
- End-of-session checklist: "Session-review automatically logs corrections to `.claude/corrections.log`"
- Monthly health checklist: "Review `.claude/corrections.log` — are promoted entries reflected in CLAUDE.md? Are there stale active entries that should be manually promoted or discarded?"

#### 3.5 `.gitignore` decision

`.claude/corrections.log` should be **committed** (not gitignored). It represents the project's learning history — valuable for the team, auditable, and needed across machines. Add it to sync.sh's "do not overwrite" list alongside the Project Layer of CLAUDE.md.

---

### Bonus: Fix `statusline.sh` sync bug

`bin/sync.sh` line ~93 lists hooks to sync but omits `statusline.sh`. The `settings.json.template` references `.claude/hooks/statusline.sh` in target projects. Fix: add `statusline.sh` to the hook sync loop.

## Technical Considerations

- **No new dependencies**: All changes use bash, existing hook infrastructure, and Claude Code's native rules format
- **Backward compatible**: Projects without `.claude/rules/` or `.test-eval-enabled` behave exactly as before
- **Context impact**: Path-scoped rules reduce context consumption; the other two improvements add minimal context overhead
- **Sync safety**: Rules files and corrections.log are project-owned. `sync.sh` syncs the hook script but never overwrites project state

## Acceptance Criteria

### Phase 1: Path-Scoped Rules
- [x] `templates/project-layer.md` documents the decomposition rule with examples
- [x] `/bootstrap-intelligence` generates `.claude/rules/` files for detected project areas
- [x] `/init-project` mentions the pattern in output
- [x] `/session-review` routes path-specific findings to matching rules files
- [x] `sync.sh` does NOT sync rules files (verified — no changes needed, rules are project-owned)

### Phase 2: Test Evaluation Warning Hook
- [x] `templates/hooks/test-evaluation-warning.sh` exists and follows existing hook patterns
- [x] Hook only fires when `.claude/.test-eval-enabled` exists (opt-in)
- [x] Hook warns on `M`odified test files, ignores `A`dded test files
- [x] Warning appears in status line and stderr
- [x] Hook is wired in `settings.json.template`
- [x] Hook is synced by `sync.sh`
- [x] Documented in `common-layer.md`

### Phase 3: Knowledge Graduation
- [x] Session-review writes corrections to `.claude/corrections.log` (TSV format)
- [x] Session-review reads log and detects repeated patterns (N>=3)
- [x] Auto-promoted corrections appear in correct CLAUDE.md section (or rules file)
- [x] Promoted entries marked in log to prevent re-promotion
- [x] Universal corrections also go to upstream proposals
- [x] `corrections.log` is committed (not gitignored — no .gitignore entry needed)

### Post-implementation: README.md
- [x] `README.md` updated to reflect new capabilities (path-scoped rules, test evaluation hook, knowledge graduation)
- [x] Automation table updated with new hook entry
- [x] Repo structure updated if new files/directories were added
- [x] Principles section updated if the "structure > instruction" meta-principle warrants mention

### Bonus
- [x] `statusline.sh` added to `sync.sh` hook list

## Dependencies & Risks

| Risk | Mitigation |
|------|------------|
| LLM-based matching in graduation is non-deterministic | Categories provide clustering hints; N=3 is conservative |
| Test file detection heuristics may miss project-specific patterns | Custom patterns via `.test-eval-enabled` file |
| sync.sh overwrites settings.json hooks section | Opt-in via file check inside hook, not via settings |
| Rules files could diverge from CLAUDE.md | Session-review routes updates to the right place |

## Sources & References

- **Origin brainstorm**: [docs/brainstorms/2026-03-31-structure-over-instruction-brainstorm.md](docs/brainstorms/2026-03-31-structure-over-instruction-brainstorm.md) — Key decisions carried forward: path-scoped without threshold, warning not blocking, N=3 graduation threshold
- **External**: [Meta Alchemist 4-layer system](https://x.com/meta_alchemist/status/2038222105654022325), [Karpathy autoresearch](https://github.com/karpathy/autoresearch)
- **Hook reference pattern**: `templates/hooks/implementation-health.sh`
- **Session-review skill**: `.claude/skills/session-review/SKILL.md`
- **Sync engine**: `bin/sync.sh`
- **Settings template**: `templates/hooks/settings.json.template`
