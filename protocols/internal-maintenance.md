# Internal Maintenance Protocol

How to keep a project's CLAUDE.md alive from daily work.

## Principle

> CLAUDE.md is code, not documentation. If it's not up to date, the agent produces garbage.
> Treat it with the same urgency as a broken test.

---

## Update triggers

### Immediate (same session)

| Event | Action in CLAUDE.md |
|-------|---------------------|
| Discover a new gotcha | Add to `## Gotchas` with description and mitigation |
| An error repeats 2+ times | Add to `## Gotchas > Critical` |
| Claude generates code that violates a pattern | Add to `## Patterns > Anti-patterns` |
| A business rule changes | Update `## Domain > Business rules` |
| A new dependency is added to the stack | Update `## Architecture > Stack` |
| Build/test/deploy commands change | Update `## Commands` |

### At end of each session

- Review if any gotcha discovered during the session is missing from CLAUDE.md
- If a new pattern was established (used in 2+ places), document it
- If a quality gate changed, update it
- Session-review automatically logs corrections to `.claude/corrections.log` — no manual action needed

### Post-mortem (when something goes wrong)

When a significant error occurs (time lost > 30 min, bug in prod, severe merge conflict):

1. **Identify the root cause**: Why did Claude do what it did?
2. **Was information missing from CLAUDE.md?**: If yes, add it
3. **Did Claude ignore existing information?**: If yes, rewrite the section to be more direct
4. **Is it a recurring pattern?**: If yes, add to Anti-patterns with an example

---

## Writing for Claude

### Writing rules

1. **Direct imperative**: "Always rebuild containers after changing Python code" — not "It's recommended to rebuild..."
2. **Explicit consequence**: "If you don't do X, Y will happen" — Claude responds better when it understands the impact
3. **Concrete example**: When possible, include the exact command or code snippet
4. **No ambiguity**: "Use `model_dump_json()`, not `model_dump()`" — not "Prefer JSON serialization"

### Content weight

Claude gives weight to CLAUDE.md, but also reads the code. To avoid conflicts:

- If CLAUDE.md contradicts the current code, **the code wins** — update the CLAUDE.md
- If a .md spec contradicts the code, **the code wins** — mark the spec as outdated
- Sections higher in the file carry more implicit weight — put critical stuff first

### Optimal size

- **Target**: 200-400 lines. Enough to cover what matters, not so much that it gets diluted.
- **Danger zone**: >600 lines. Claude starts losing details. Move extensive content to referenced files.
- **Latent Patterns principle**: The "smart zone" of context is at ~40% utilization. Don't saturate CLAUDE.md with information Claude can discover by reading the code.

---

## What NOT to put in CLAUDE.md

- **API documentation** — Claude reads it from the code
- **Change history** — that's git log
- **Tutorials** — CLAUDE.md is for an agent, not for human onboarding
- **Complete specs** — reference the file, don't copy the content
- **Extensive code** — put the path to the canonical file, not the snippet

---

## Monthly health checklist

Every month, review the CLAUDE.md with these questions:

- [ ] Are all gotchas still relevant? (remove obsolete ones)
- [ ] Do the commands work? (run them and verify)
- [ ] Do the patterns reflect the current code? (compare with the repo)
- [ ] Are there new gotchas you discovered but didn't document?
- [ ] Did the stack change? (new dependencies, versions)
- [ ] Is the size in the optimal zone? (200-400 lines)
- [ ] Review `.claude/corrections.log` — are promoted entries reflected in CLAUDE.md? Are there stale active entries that should be manually promoted or discarded?
