# Brainstorm: Structure Over Instruction

**Date:** 2026-03-31
**Status:** Draft
**Trigger:** Comparative analysis of the framework against external resources

## Context

Layer 1 (Project Intelligence) of gud_operational_ai_workflows is considered mature/complete. This brainstorm explores improvement areas across all 4 layers by comparing against two external resources:

1. **Meta Alchemist's 4-layer Claude Code system** — A self-evolving system with Cognitive Core, Specialized Agents, Path-Scoped Rules, and Evolution Engine
2. **Karpathy's autoresearch** — Radical minimalism: 3 files, 1 metric, immutable evaluation surface, git as state manager

## What We're Building

Three improvements that share a single meta-principle: **structural constraint > behavioral instruction**. The framework currently relies heavily on CLAUDE.md instructions (behavioral). These improvements shift enforcement toward structural mechanisms that work regardless of prompt quality.

### Improvement 1: Path-Scoped Rules

**What:** Decompose path-specific parts of the Project Layer into `.claude/rules/` files that Claude Code loads contextually.

**Decision rule:** If an instruction only applies when editing files in a specific area, it goes in `.claude/rules/`. If it applies globally, it stays in CLAUDE.md.

**What changes:**
- The `templates/project-layer.md` template recommends decomposing Patterns, path-specific Gotchas, and area-specific Quality Gates into `.claude/rules/`
- CLAUDE.md retains: Architecture overview, Domain (global), Workflow, Commands, universal Gotchas
- Works for both small and large projects (small projects = 1-2 rules files, not 20)

**Why:** Reduces CLAUDE.md size, improves context precision (agent doesn't load frontend rules when editing backend), uses native Claude Code infrastructure.

### Improvement 2: Evaluation Surface Warning

**What:** A lightweight hook that warns (not blocks) when a commit modifies existing test files alongside implementation files.

**Why:** Prevents a real failure mode: Claude changes implementation away from requirements, then modifies tests to match the wrong logic, creating false positive "all tests pass." The human gets a false sense of correct progress.

**Important precondition:** This only has value when tests correctly encode current behavior. For legacy projects with outdated tests, this ancla could point in the wrong direction.

**What changes:**
- Optional hook in `templates/hooks/` (not enabled by default)
- Documented in common-layer as recommended pattern for projects with mature test suites
- Warning, not blocking — surfaces the decision point without creating friction

**Key insight:** This doesn't guarantee the agent goes in the RIGHT direction (a bad prompt is still a bad prompt). But it prevents the agent from going in a WRONG direction silently, which is worse than not advancing.

### Improvement 3: Knowledge Graduation

**What:** Session-review persists corrections across sessions and auto-promotes repeated patterns to permanent rules.

**Current gap:** Each session-review starts from zero — no memory of "this correction was proposed 3 times before." Corrections that should be permanent rules get lost.

**What changes:**
- Session-review writes corrections to `knowledge-base/corrections.log` (append-only)
- Next session-review reads the log, detects repeated patterns
- After N occurrences, auto-promotes to CLAUDE.md with justification
- The log is a simple text file, not a database

**Why:** The framework already captures gotchas and proposes updates. But without cross-session persistence, the same mistakes recur. This closes the loop from "observed pattern" to "permanent rule" without human intervention.

## Why This Approach

The meta-principle **"structure > instruction"** emerged from comparing autoresearch's radical constraint model (immutable evaluation, single modifiable file) with the framework's current instruction-heavy approach. Both external resources converge on the same insight: telling an agent what to do is less reliable than making the wrong thing structurally difficult.

The three improvements are independent and additive:
- Path-scoped rules reduces noise in the agent's context
- Evaluation warning prevents silent regression
- Knowledge graduation makes the system self-improving

None requires the others. All can be adopted incrementally.

## Key Decisions

1. **Path-scoped rules without threshold** — Apply the rule "path-specific → rules/, global → CLAUDE.md" universally, not only when CLAUDE.md exceeds a size threshold. The cost in small projects is minimal (1-2 extra files), the benefit is real.

2. **Warning, not blocking** — The test evaluation hook warns but doesn't block. Blocking would create friction in legitimate cases (intentional behavior changes). The value is visibility, not enforcement.

3. **Precondition for evaluation surface** — The hook only has value in projects with mature test suites. Document this explicitly; don't enable by default.

4. **Append-only correction log** — Knowledge graduation uses a simple log file, not a database or structured format. Keeps complexity minimal.

## Resolved Questions

1. **Path-scoped rules and init-project** — `/bootstrap-intelligence` (not `/init-project`) generates `.claude/rules/` files by detecting real project areas from the codebase structure. This produces rules that match the actual project, not generic scaffolding.

2. **Graduation threshold** — N=3 occurrences across sessions before auto-promotion. Conservative enough to avoid promoting noise, but responsive enough to catch real patterns.

3. **Correction log format** — TSV structured: `date | category | description | session`. Easy to parse programmatically, minimal overhead.

## External Resources

- [Meta Alchemist tweet](https://x.com/meta_alchemist/status/2038222105654022325) — 4-layer self-evolving Claude Code system
- [Karpathy autoresearch](https://github.com/karpathy/autoresearch) — Autonomous ML research with radical minimalism
