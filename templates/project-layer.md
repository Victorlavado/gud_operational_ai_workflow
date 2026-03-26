# Project Layer — [Project Name]

<!-- This layer is specific to THIS project. Fill in each section based on your project's
     actual architecture, domain, and conventions. Delete sections that don't apply.

     The Common Layer (above) handles universal principles.
     This layer handles what makes YOUR project unique. -->

---

## Architecture

<!-- WITHOUT THIS: Claude assumes architecture from file names, producing code that
     violates boundaries, misuses layers, or creates circular dependencies. -->

### System overview

<!-- Draw the system as components and relationships. ASCII diagrams work well. -->

```
[Component A] --> [Component B] --> [Component C]
```

### Stack

| Layer | Technology | Notes |
|-------|-----------|-------|
| Language | | |
| Framework | | |
| Database | | |
| Queue/Worker | | |
| Infrastructure | | |

### Key boundaries

<!-- Where are the important interfaces? What crosses process/network boundaries? -->

- **[Boundary 1]**: [What crosses it, serialization format, constraints]

---

## Domain

<!-- WITHOUT THIS: Claude generates technically correct but semantically wrong code. -->

### Core models

- **[Model A]**: [Key fields, purpose, relationships]

### Business rules

- [Rule 1: e.g., "An order cannot be modified after status = SHIPPED"]

### Vocabulary

- **[Term]**: [Precise definition in this project's context]

---

## Patterns

<!-- WITHOUT THIS: Claude defaults to its training distribution, not your project's conventions. -->

### Code conventions

- **File structure**: [How files/dirs are organized, naming conventions]
- **Naming**: [snake_case, camelCase, etc.]

### Architecture patterns

- **[Pattern]**: [Description + pointer to canonical example in codebase]

### Anti-patterns (project-specific)

- DO NOT [anti-pattern specific to this project]

---

## Gotchas

<!-- HIGHEST ROI SECTION. Every gotcha here was discovered the hard way.
     Add new gotchas IMMEDIATELY when discovered — don't wait. -->

### Critical

- **[Gotcha]**: [What happens, why, and what to do instead]

### Important

- **[Gotcha]**: [Description and mitigation]

---

## Quality Gates — Project Overrides

<!-- Override or extend the Common Layer defaults for this project's specific tooling. -->

```bash
# Tests
[project-specific test command]

# Linting
[project-specific lint command]

# Type checking
[project-specific type check command]
```

### Infrastructure checks (project-specific)

- **When to rebuild**: [e.g., "After ANY change to Python code, run docker compose build"]
- **How to verify**: [e.g., "Check docker compose logs <service>"]

---

## Workflow

### Branching

- **Main branch**: [e.g., main, develop]
- **Feature branches**: [e.g., feat/description, VLC/feature-name]

### Commits

- **Scope values**: [e.g., auth, api, workflow, ui — project-specific scopes]

### Deploy

- **How**: [e.g., "Push to main triggers CI/CD"]

---

## Commands

### Development

```bash
# Start dev environment
[command]

# Run tests
[command]

# Lint and fix
[command]
```

### Infrastructure

```bash
# Build/rebuild
[command]

# Check logs
[command]
```
