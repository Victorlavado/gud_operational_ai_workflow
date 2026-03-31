# Operational AI Workflows

An operational framework for maximizing developer effectiveness when working with AI tools (Claude Code primarily).

## Layers

```
Layer 4: Agent Orchestration      — parallelize, dispatch, channels, oversight
Layer 3: Context Continuity       — maintain thread across sessions
Layer 2: Spec-First Development   — review intent, not code
Layer 1: Project Intelligence     — CLAUDE.md as the project's brain  <-- implemented
```

## Installation

### First time

```bash
# From any machine with the repo cloned:
git clone https://github.com/Victorlavado/gud_operational_ai_workflow.git
cd gud_operational_ai_workflow

# Install into a project:
./install.sh ~/dev/my-project
```

This installs hooks, skills, commands, and configuration. Then open Claude Code in the project and run `/init-project` to generate the CLAUDE.md.

### Automatic updates

Installed projects **update themselves**. A `SessionStart` hook checks GitHub at the start of each Claude Code session:

```
[Framework repo on GitHub]
        |
        |  push (VERSION bumped)
        v
[SessionStart hook in your project]
        |
        |-- compares local vs remote VERSION (1 request, <3s, max 1x/hour)
        |-- if changed -> downloads and syncs hooks, skills, commands, Common Layer
        +-- if unchanged -> nothing
```

No manual intervention. Works on any machine with internet access.

### Manual update

If you prefer explicit control or don't have internet:

```bash
# From the framework repo (local):
./bin/sync.sh ~/dev/my-project

# Or directly with the install script:
./install.sh ~/dev/my-project
```

### What gets synced

| Artifact | Source | Destination |
|----------|--------|-------------|
| Hooks | `templates/hooks/*.sh` | `.claude/hooks/` |
| Skills | `.claude/skills/*/SKILL.md` | `.claude/skills/` |
| Commands | `.claude/commands/*.md` | `.claude/commands/` |
| Settings | `templates/hooks/settings.json.template` | `.claude/settings.json` (merge) |
| Common Layer | `templates/common-layer.md` | Marked section in `CLAUDE.md` |
| Version | `VERSION` | `.claude/.framework-version` |

The **Project Layer** of CLAUDE.md is never touched — it belongs to the project.

## Quick start

### New project
```
/init-project ~/dev/my-project
```
Generates a CLAUDE.md with Common Layer (universal) + Project Layer (empty) + automation hooks.

### Existing project
```
/init-project ~/dev/my-project
/bootstrap-intelligence ~/dev/my-project
```
Generates the CLAUDE.md and then scans past sessions, git history, and code to pre-fill gotchas, patterns, and conventions.

### Day-to-day
- Work normally. The **Stop hook** automatically reviews at the end of each session and proposes CLAUDE.md updates.
- When you find something interesting: add the URL to `inbox.md` from any device.
- When you sit down to work: `/process-inbox` processes URLs in batch.
- Every week: `/weekly-briefing` for an ecosystem scan.

## CLAUDE.md Architecture

```
CLAUDE.md = Common Layer + Project Layer
```

**Common Layer** (`templates/common-layer.md`):
- Context management (degradation at ~40%, /clear, sub-agents)
- Work patterns (monotask, specs as source of truth)
- Default quality gates (tests, lint, types)
- Test evaluation surface (opt-in hook for mature test suites)
- Commit conventions (conventional commits)
- Universal anti-patterns
- Session discipline

**Project Layer** (`templates/project-layer.md`):
- Architecture (diagram, stack, boundaries)
- Domain (models, business rules, vocabulary)
- Patterns (code conventions, architectural patterns)
- Gotchas (known traps — accumulated automatically)
- Project-specific quality gates
- Workflow (branching, deploy)
- Commands (project-specific commands)

**Path-Scoped Rules** (`.claude/rules/<area>.md`):
- Instructions that only apply to a specific area of the project
- Use Claude Code's native format with `globs` frontmatter
- Decision rule: path-specific → `.claude/rules/`, global → CLAUDE.md
- Generated automatically by `/bootstrap-intelligence`

## Automation

| Mechanism | When | What it does |
|-----------|------|--------------|
| Auto-update hook | On session start | Checks for new framework version -> syncs automatically |
| Stop hook | At end of each session | Checks for new gotchas/patterns -> proposes CLAUDE.md updates |
| Context-watchdog hook | Every tool call | Reads real context % consumed and alerts at degradation thresholds (40%/65%/80%) |
| Implementation-health hook | Every Edit/Bash | Detects file churn, retry loops, test regression -> recommends `/recovery` |
| Status line | Every Claude response | Shows context bar + hook alerts in the user's terminal |
| Test evaluation warning | Every Bash (git commit) | Warns when existing tests modified alongside implementation (opt-in via `.claude/.test-eval-enabled`) |
| Knowledge graduation | Every session-review | Logs corrections to `.claude/corrections.log`, auto-promotes to CLAUDE.md after 3 occurrences |
| `/recovery` | Auto (via hook) or on demand | Objective session diagnosis + recovery recommendation + resumption prompt |
| `/context-check` | On demand | Context state diagnosis |
| `/session-review` | On demand / auto (Stop) | Full analysis + correction logging + knowledge graduation |
| `/bootstrap-intelligence` | When integrating existing project | Scans history and code -> pre-fills CLAUDE.md |
| `/process-inbox` | When you sit down to work | Processes URLs captured from mobile |
| `/weekly-briefing` | Weekly | Ecosystem scan + open discovery |

## Repo structure

```
bin/
  sync.sh                  # Sync engine (local and remote)
templates/
  common-layer.md          # Universal principles (portable across all projects)
  project-layer.md         # Project-specific template (domain, architecture, gotchas)
  hooks/                   # Hook scripts, status line, and settings templates
protocols/
  internal-maintenance.md  # How to update CLAUDE.md from daily work
  external-intelligence.md # Sources, filters, processing pipeline, cadences
knowledge-base/
  insights/                # Processed insights from external sources
docs/
  brainstorms/             # Brainstorm documents
  plans/                   # Implementation plans
inbox.md                   # Low-friction URL capture (mobile-friendly)
install.sh                 # First-time installer (wrapper around bin/sync.sh)
VERSION                    # Framework version (triggers auto-update on bump)
.claude/
  commands/                # Slash commands
  skills/                  # Skills (loaded on demand)
  settings.json            # Hook configuration
```

## Principles

- **Back-pressure over trust** — Tests, linters, and types keep the agent on track
- **Structure over instruction** — Structural constraints (hooks, rules files, immutable evaluation) outperform behavioral instructions in CLAUDE.md
- **Specs as source of truth** — Code is a derived artifact of the spec
- **Fresh context per iteration** — Avoid context degradation. One task per cycle
- **On the loop, not in the loop** — Supervise the process, don't execute line by line
- **Automate maintenance** — Hooks and skills keep the system alive without depending on the human
- **Living framework** — Fed by daily work (internal) and the ecosystem (external)

## Knowledge Base

Processed insights in `knowledge-base/insights/`:
- Ralph Loop and back-pressure (ghuntley.com)
- Context engineering (latentpatterns.com)
- Skill issue and developer as director (Karpathy)
- Kill code review (Latent Space)
- Claude Code best practices (Anthropic)
- Agent patterns (Anthropic Engineering)
