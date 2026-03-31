# External Intelligence Protocol

How to feed the framework with ecosystem knowledge in a structured way.

## Principle

> Capturing without processing is noise. The value isn't in saving the link,
> but in extracting the actionable insight and deciding if it changes anything in your workflow.

---

## Curated sources

### Builder profiles (Twitter/X)

People who build, show tangible results, and share reproducible processes:

| Handle | Focus | Why it's signal |
|--------|-------|-----------------|
| @karpathy | AI research/engineering, agentic workflows | Defines paradigms. "Skill issue" framing. |
| @GeoffreyHuntley | Developer tooling, AI workflows | Ralph Loop, back-pressure. Pure builder. |
| @dabit3 | Full-stack/AI builder | Builds in public, shows real code |
| @levelsio | Indie hacking, shipping with AI | Execution speed, extreme pragmatism |
| @PierreDeWulf | Builder | Tangible projects |
| @thekitze | Developer tools, product | Practical tools |
| @steipete | Engineering leadership, tooling | Technical management perspective |
| @banteg | Builder/hacker | Real technical implementations |
| @shawmakesmagic | AI agents, elizaOS | Agent ecosystem, frameworks |
| @nateliason | Builder/entrepreneur | Practical AI application |
| @Austen | Builder/entrepreneur | Scale and product |

### Publications and blogs

| Source | URL | Focus |
|--------|-----|-------|
| Latent Space | latent.space | AI engineering deep dives |
| Geoffrey Huntley's blog | ghuntley.com | Developer tooling, AI workflows |
| Latent Patterns | latentpatterns.com | AI patterns, context engineering |
| Anthropic blog | anthropic.com/blog | Claude releases, Claude Code, channels, dispatch |
| Anthropic Engineering | anthropic.com/engineering | Agent patterns, multi-agent, harnesses, tool design |
| OpenClaw | github.com/anthropics/claw | Agent harness, releases |

### Official documentation

| Source | URL | Focus |
|--------|-----|-------|
| Claude Code Best Practices | code.claude.com/docs/en/best-practices | CLAUDE.md, hooks, skills, session management, context |

### Release tracking

| Product | Where to look | Why it matters |
|---------|---------------|----------------|
| Claude Code | Anthropic blog + changelog | New features directly affect the workflow |
| Claude models | Anthropic blog | New capabilities = new techniques |
| OpenClaw | GitHub releases | Agent harness for orchestration |
| Compound Engineering | GitHub/npm | Plugins, skills, new workflows |

---

## Discovery mode (open search)

Curated sources are the starting point, not the limit. Discovery mode searches beyond them, applying the same quality filters.

### When to activate
- During `/weekly-briefing`: dedicate part of the scan to open search
- When a new technology/pattern emerges that no curated source covers
- When the user asks to investigate a specific topic

### How it works
1. **Search** the open web with specific queries (not generic): `"claude code hooks" site:github.com`, `"agentic workflow" temporal.io`, etc.
2. **Apply the quality filter** (below) to each result — same standard as curated sources
3. **If a new source passes the filter repeatedly** (3+ actionable insights), propose it as a permanent curated source
4. **If a new profile appears consistently** in quality content, propose it for the builders list

### Suggested discovery queries
- `"[stack technology]" AND ("workflow" OR "agent" OR "automation")` — search for patterns with tools you use
- `"claude code" AND ("hook" OR "skill" OR "CLAUDE.md" OR "command")` — news on the main tooling
- `"agentic" AND ("production" OR "deployment" OR "architecture")` — agentic solutions in production, not prototypes
- Search repos with >100 stars created in the last month that use the relevant stack

---

## Quality filter

Before processing a resource, apply this filter:

### It's signal if...
- Has a **public repo** or **visible product** (not just opinion)
- Shows **tangible results**: demos, metrics, before/after
- The approach is **reproducible**: you can apply it to your project
- Comes from someone who **actively builds**, not just comments

### It's noise if...
- Just opinion without implementation
- Promises results without showing process
- Viral thread without technical substance
- "10 prompts that will change your life" -> skip
- You can't answer: "What would change in my workflow if I applied this?"

---

## Processing pipeline

### Step 1: Capture

**If you're in Claude Code:**
```
/process-resource <url>
```

**If you're on mobile or outside the terminal:**
Add the URL to `inbox.md` at the root of this repo (editable via GitHub mobile, cloud sync, or any editor):
```markdown
- <url> — [one-line note about why it caught your attention]
```

**When you sit down to work:**
```
/process-inbox
```
Processes all pending URLs in batch, applies filters, and presents the results.

### Step 2: Extraction
The `/process-resource` command (or you manually) must answer:

1. **What does it say?** — Summary in 3-5 bullets
2. **What's actionable?** — What can I do differently tomorrow?
3. **Does it affect the framework?** — Does it change any principle, protocol, or template?
4. **Is it a new pattern or a validation of an existing one?**

### Step 3: Decision

| Result | Action |
|--------|--------|
| New actionable insight | Create file in `knowledge-base/insights/` |
| Validates an existing pattern | Add reference to the existing insight |
| Requires a framework change | Create issue/task + update the affected artifact |
| Interesting but not actionable now | Discard. Don't accumulate. |
| Doesn't pass the quality filter | Discard immediately |

### Step 4: Storage

Format for files in `knowledge-base/insights/`:

```markdown
---
source: [URL]
author: [Who]
date_processed: [YYYY-MM-DD]
tags: [context-engineering, back-pressure, agent-orchestration, etc.]
impact: [high/medium/low]
status: [actionable/applied/superseded]
---

## Insight

[Concise summary of what was learned]

## Action

[What to change or try in the workflow]

## Applied in

[Reference to where it was applied, if done. Empty if pending.]
```

---

## Cadences

### Weekly: Intelligence Briefing

Command: `/weekly-briefing`

Run once a week (preferably Monday or Sunday evening). The briefing:

1. Scans curated sources (blogs, releases, most active X profiles)
2. Filters by relevance to the user's stack and workflow
3. Produces a summary with:
   - **Relevant releases**: New versions of stack tools
   - **Builder insights**: New patterns or techniques from curated profiles
   - **Update proposals**: Suggested framework changes with justification
4. Each proposal includes:
   - What to change
   - Why (with reference to the source)
   - How to integrate it into the workflow
   - Option to apply or discard

### On demand: Process Resource

Command: `/process-resource <url>`

For when you find something interesting between weeks:

1. Processes the resource through the pipeline described above
2. If actionable, stores it in `knowledge-base/insights/`
3. If it requires a framework change, proposes it
4. If it doesn't pass the filter, discards with a one-line justification

---

## Source evolution

Sources are not static. Every quarter:

- [ ] Did any source stop producing relevant content? -> Remove
- [ ] Did you discover new builders who pass the filter? -> Add
- [ ] Is there a new area in your stack that needs tracking? -> Add source
- [ ] Did any source become "hype"? -> Remove
