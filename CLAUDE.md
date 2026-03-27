# Operational AI Workflows Framework

This repo contains a generic, living framework for maximizing developer effectiveness when working with AI coding tools (Claude Code primarily).

## Structure

```
bin/
  sync.sh                  # Sync engine (local + remote GitHub fetch)
templates/
  common-layer.md          # Universal principles (portable across all projects)
  project-layer.md         # Project-specific template (domain, architecture, gotchas)
  hooks/                   # Hook scripts and settings templates for automation
protocols/
  internal-maintenance.md  # How to update CLAUDE.md from daily work (automated via hooks)
  external-intelligence.md # Sources, filters, processing pipeline, cadences
knowledge-base/
  insights/                # Processed insights from external sources
inbox.md                   # Low-friction URL capture (mobile-friendly)
install.sh                 # First-time installer (wraps bin/sync.sh)
VERSION                    # Framework version (bump to trigger auto-update in projects)
.claude/
  commands/                # Slash commands
  skills/                  # Skills (loaded on demand)
  settings.json            # Hook configuration
```

## Principles

1. **Back-pressure over trust** — Automated feedback (tests, linters, types) keeps agents on track. Never rely on the agent "getting it right."
2. **Specs as source of truth** — Specs on disk are persistent memory between iterations. Code is a derived artifact.
3. **Fresh context per iteration** — Avoid context degradation. Each task gets a clean window. Use sub-agents for context-heavy work.
4. **On the loop, not in the loop** — Supervise the process, don't execute line by line.
5. **One task per cycle** — Monotask. Don't overload agent iterations.
6. **Automate maintenance** — Hooks and skills keep the system alive. Never depend on the human remembering triggers.

## Commands

- `/init-project [path]` — Initialize CLAUDE.md in a project (Common + Project layers + hooks)
- `/bootstrap-intelligence [path]` — Scan existing project for patterns, gotchas, conventions
- `/weekly-briefing` — Weekly intelligence scan across curated sources + open discovery
- `/process-resource <url>` — Process a single URL into an actionable insight
- `/process-inbox` — Batch-process all pending URLs from inbox.md
- `/session-review` — Review current session for CLAUDE.md updates (also runs automatically via Stop hook)
- `/recovery` — Diagnose implementation health and recommend recovery actions (also triggered by implementation-health hook)
- `/context-check` — Evaluate current session context state and recommend actions
- `/propose-upstream` — Send accumulated upstream proposals (from session-review) to framework repo as GitHub Issues

## Language

Victor works primarily in Spanish. Framework content is in Spanish where it's prose, English where it's technical/code.
