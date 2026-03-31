# Common Layer — Operational AI Workflows

<!-- This layer is universal. It applies to ANY project regardless of stack, domain, or team.
     It gets copied as-is by /init-project and updated when the framework evolves.
     DO NOT put project-specific information here. -->

---

## Context Management

<!-- These rules prevent context degradation — the #1 cause of declining agent quality
     during a session. Source: Latent Patterns context engineering research.
     The context-watchdog hook automates threshold alerts via PostToolUse. -->

- IMPORTANT: The "smart zone" of the context window is at ~40% utilization. Beyond that, quality degrades.
- The **context-watchdog hook** monitors tool calls and emits automatic alerts at 3 thresholds:
  - **YELLOW (40%)**: approaching the limit. Don't start new tasks.
  - **ORANGE (65%)**: beyond the effective zone. Use `/compact` or finish the current task.
  - **RED (80%)**: high risk. Document state, `/clear`, resume with a fresh prompt.
- Use `/context-check` at any time for a full diagnosis of context state.
- Use `/clear` between unrelated tasks in the same session. Accumulated context degrades performance.
- **Two-attempt rule**: if you correct Claude 2+ times on the same problem, use `/clear` and reformulate the prompt incorporating what you learned.
- Use `/compact <instructions>` to compress context while keeping essentials. Example: `/compact Focus on the API changes`. IMPORTANT: When using /compact, specify what to preserve (modified files, decisions, test state).
- Use sub-agents (Agent tool) for tasks that produce heavy output: tests, extensive searches, log analysis. They run in separate context windows and return summaries.
- DO NOT bloat this CLAUDE.md with information discoverable by reading the code. Reserve this file for what Claude CANNOT infer.

### Degradation signals (actively watch for these)

If you observe ANY of these signals, context is degraded:
- Claude "forgets" decisions made earlier in the same session
- Claude repeats errors that were already corrected
- Claude ignores instructions in this CLAUDE.md
- Responses become generic or lose project specificity
- Claude proposes solutions that contradict established patterns

**Degradation protocol:**
1. DO NOT keep working — each additional interaction worsens the situation
2. Invoke `/recovery` for automatic diagnosis based on objective signals and action recommendation
3. If `/recovery` is unavailable: document state, WIP commit, `/clear` + resumption prompt

The **implementation-health hook** automatically detects spiral patterns (file churn, test regression, retry loops) and recommends invoking `/recovery` when signals warrant it.

## Work Patterns

<!-- How the agent should approach work. Source: Huntley's Ralph Loop,
     Karpathy's skill issue, Anthropic's agent patterns. -->

- **One task per cycle.** Don't mix multiple objectives in a single agent iteration.
- **Specs as source of truth.** Read specs/plans from disk before implementing. Code is a derived artifact of the spec.
- **Verify before starting.** Run existing tests before starting new work to detect inherited bugs.
- **Don't use autonomous agents when a predefined workflow suffices.** Progression: simple prompt -> LLM + retrieval -> workflow -> agent.
- **Express intent, not code.** Break down objectives into tasks, review at the macro level.

## Quality Gates — Defaults

<!-- IMPORTANT: These gates run ALWAYS. They are the back-pressure system
     that keeps the agent on track. Source: Huntley's back-pressure principle.

     Override or extend these in the Project Layer section below. -->

YOU MUST run these checks before every commit. No exceptions:

1. **Tests**: Run the project's test suite. If a test fails, DO NOT commit.
2. **Linting**: Run the configured linter. Fix before committing.
3. **Type checking**: If the project uses static types, run the type checker.
4. **Build**: If the project has a build step, verify it compiles.

### Test requirements by change type

- **New feature**: unit tests + integration test at minimum
- **Bug fix**: regression test that reproduces the bug first, then the fix
- **Refactor**: existing tests must pass without modification

### Test evaluation surface (opt-in)

For projects with mature test suites: enable the **test-evaluation-warning hook** by creating `.claude/.test-eval-enabled`. The hook warns when existing tests are modified alongside implementation in the same commit — a signal that tests may have been weakened to pass instead of fixing the actual code. New test files (additions) do not trigger the warning.

### Infrastructure checks

- If the project uses containers: rebuild after ANY change to service code
- Check service logs after rebuilding

## Commit Conventions

<!-- Vague commits ("various fixes", "added missing files") make it impossible
     to reconstruct context. Conventional commits enforce clarity. -->

- Use conventional commits: `type(scope): description`
- Types: `feat`, `fix`, `refactor`, `test`, `docs`, `chore`
- One logical change per commit. NEVER "various fixes" or "added files".
- The message describes the WHY, not the WHAT (the diff already shows the what).

## Anti-patterns — Universal

<!-- Things Claude tends to do across all projects. Catching these early
     prevents wasted time. -->

- DO NOT create generic utility files. Logic belongs in the module that uses it.
- DO NOT add `type: ignore`, `# noqa`, `eslint-disable` without documented justification.
- DO NOT use print/console.log for debugging. Use the project's logger.
- DO NOT generate code without verification. Always provide tests or verification scripts.
- DO NOT do "infinite exploration" — scope the search before investigating.
- DO NOT mix unrelated tasks in the same session or commit.

## Session Discipline

<!-- Source: Claude Code best practices + context watchdog system. -->

### At session start
- Read CLAUDE.md, check git status, run basic tests.
- If resuming previous work: use `claude --continue` or `claude --resume` to pick a session.

### During the session
- When switching tasks: `/clear` if the new task is unrelated to the previous one.
- When discovering a gotcha: add it IMMEDIATELY to the Gotchas section of this file.
- When receiving a context-watchdog alert: follow the degradation protocol (above).
- If implementation gets complicated (tests fail repeatedly, multiple approach changes): stop, run `/context-check`, decide whether to continue or `/clear` + reformulate.

### At session end
- The session-review hook leaves a marker on close. The next session detects the marker and reminds to run `/session-review`.
- If you did `/clear` during the session: verify that gotchas discovered before the /clear weren't lost.
- **Stop hooks are silent**: stdout from `Stop` hooks is not shown to the user (anthropics/claude-code#16227). To communicate something at session close, use the marker file strategy: Stop writes file -> SessionStart reads and deletes it.

### Recovering from long sessions
When `/clear` is needed but you don't want to lose context, document first:
```
## State at /clear — [timestamp]
- **Completed**: [what was finished]
- **In progress**: [what's halfway done + exact state]
- **Decisions**: [decisions made that must be preserved]
- **Gotchas**: [traps discovered]
- **Next step**: [exactly what to do when resuming]
```
Paste this as the first message of the clean session.
