# Operational AI Workflows

Framework operativo para maximizar la efectividad del desarrollador trabajando con herramientas de IA (Claude Code).

## Capas

```
Capa 4: Agent Orchestration      — paralelizar, dispatch, channels, oversight
Capa 3: Context Continuity       — no perder el hilo entre sesiones
Capa 2: Spec-First Development   — revisar intención, no código
Capa 1: Project Intelligence     — CLAUDE.md como cerebro del proyecto  <-- implementada
```

## Uso rápido

### Proyecto nuevo
```
/init-project ~/dev/mi-proyecto
```
Genera un CLAUDE.md con Common Layer (universal) + Project Layer (vacío) + hooks de automatización.

### Proyecto existente
```
/init-project ~/dev/mi-proyecto
/bootstrap-intelligence ~/dev/mi-proyecto
```
Genera el CLAUDE.md y luego escanea sesiones pasadas, git history y código para pre-rellenar gotchas, patrones y convenciones.

### Día a día
- Trabaja normal. El **hook Stop** revisa automáticamente al final de cada sesión y propone actualizaciones al CLAUDE.md.
- Cuando encuentras algo interesante: añade la URL a `inbox.md` desde cualquier dispositivo.
- Cuando te sientes a trabajar: `/process-inbox` procesa las URLs en batch.
- Cada semana: `/weekly-briefing` para un scan del ecosistema.

## Arquitectura del CLAUDE.md

```
CLAUDE.md = Common Layer + Project Layer
```

**Common Layer** (`templates/common-layer.md`):
- Context management (degradación al 40%, /clear, sub-agentes)
- Work patterns (monotarea, specs como fuente de verdad)
- Quality gates por defecto (tests, lint, types)
- Commit conventions (conventional commits)
- Anti-patterns universales
- Session discipline

**Project Layer** (`templates/project-layer.md`):
- Architecture (diagrama, stack, boundaries)
- Domain (modelos, reglas de negocio, vocabulario)
- Patterns (convenciones de código, patrones arquitectónicos)
- Gotchas (trampas conocidas — se acumulan automáticamente)
- Quality gates específicos del proyecto
- Workflow (branching, deploy)
- Commands (comandos específicos)

## Automatización

| Mecanismo | Cuándo | Qué hace |
|-----------|--------|----------|
| Hook Stop | Al terminar cada sesión | Revisa si hay gotchas/patrones nuevos → propone CLAUDE.md updates |
| `/session-review` | Bajo demanda | Análisis completo de la sesión actual |
| `/bootstrap-intelligence` | Al integrar proyecto existente | Escanea historial y código → pre-rellena CLAUDE.md |
| `/process-inbox` | Cuando te sientes a trabajar | Procesa URLs capturadas desde móvil |
| `/weekly-briefing` | Semanal | Scan de ecosystem + búsqueda abierta |

## Principios

- **Contrapresión sobre confianza** — Tests, linters y tipos mantienen al agente en el camino correcto
- **Specs como fuente de verdad** — El código es un artefacto derivado de la spec
- **Contexto fresco por iteración** — Evitar degradación del contexto. Una tarea por ciclo
- **Sobre el loop, no en el loop** — Supervisar el proceso, no ejecutar línea por línea
- **Automatizar el mantenimiento** — Hooks y skills mantienen el sistema vivo sin depender del humano
- **Framework vivo** — Se alimenta del trabajo diario (interno) y del ecosistema (externo)

## Knowledge Base

Insights procesados en `knowledge-base/insights/`:
- Ralph Loop y contrapresión (ghuntley.com)
- Ingeniería de contexto (latentpatterns.com)
- Skill issue y developer como director (Karpathy)
- Matar la revisión de código (Latent Space)
- Best practices de Claude Code (Anthropic)
- Patrones de agentes (Anthropic Engineering)
