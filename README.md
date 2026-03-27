# Operational AI Workflows

Framework operativo para maximizar la efectividad del desarrollador trabajando con herramientas de IA (Claude Code).

## Capas

```
Capa 4: Agent Orchestration      — paralelizar, dispatch, channels, oversight
Capa 3: Context Continuity       — no perder el hilo entre sesiones
Capa 2: Spec-First Development   — revisar intención, no código
Capa 1: Project Intelligence     — CLAUDE.md como cerebro del proyecto  <-- implementada
```

## Instalación

### Primera vez

```bash
# Desde cualquier máquina con el repo clonado:
git clone https://github.com/Victorlavado/gud_operational_ai_workflow.git
cd gud_operational_ai_workflow

# Instalar en un proyecto:
./install.sh ~/dev/mi-proyecto
```

Esto instala hooks, skills, commands y configuración. Después, abre Claude Code en el proyecto y ejecuta `/init-project` para generar el CLAUDE.md.

### Actualización automática

Los proyectos instalados se **actualizan solos**. Un hook `SessionStart` comprueba GitHub al iniciar cada sesión de Claude Code:

```
[Framework repo en GitHub]
        │
        │  push (VERSION bumped)
        ▼
[SessionStart hook en tu proyecto]
        │
        ├── compara VERSION local vs remota (1 request, <3s, max 1x/hora)
        ├── si hay cambio → descarga y sincroniza hooks, skills, commands, Common Layer
        └── si no hay cambio → nada
```

Sin intervención manual. Funciona en cualquier máquina con acceso a internet.

### Actualización manual

Si prefieres control explícito o no tienes internet:

```bash
# Desde el repo del framework (local):
./bin/sync.sh ~/dev/mi-proyecto

# O directamente con el install script:
./install.sh ~/dev/mi-proyecto
```

### Qué se sincroniza

| Artefacto | Fuente | Destino |
|-----------|--------|---------|
| Hooks | `templates/hooks/*.sh` | `.claude/hooks/` |
| Skills | `.claude/skills/*/SKILL.md` | `.claude/skills/` |
| Commands | `.claude/commands/context-check.md` | `.claude/commands/` |
| Settings | `templates/hooks/settings.json.template` | `.claude/settings.json` (merge) |
| Common Layer | `templates/common-layer.md` | Sección marcada en `CLAUDE.md` |
| Versión | `VERSION` | `.claude/.framework-version` |

El **Project Layer** del CLAUDE.md nunca se toca — es propiedad del proyecto.

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
| Hook auto-update | Al iniciar sesión | Comprueba nueva versión del framework → sincroniza automáticamente |
| Hook Stop | Al terminar cada sesión | Revisa si hay gotchas/patrones nuevos → propone CLAUDE.md updates |
| Hook context-watchdog | Cada tool call | Cuenta tool calls y alerta en umbrales de degradación (30/50/80) |
| Hook implementation-health | Cada Edit/Bash | Detecta file churn, retry loops, test regression → recomienda `/recovery` |
| `/recovery` | Auto (por hook) o bajo demanda | Diagnóstico objetivo de la sesión + recomendación de recuperación + prompt de reanudación |
| `/context-check` | Bajo demanda | Diagnóstico del estado del contexto |
| `/session-review` | Bajo demanda / auto (Stop) | Análisis completo de la sesión actual |
| `/bootstrap-intelligence` | Al integrar proyecto existente | Escanea historial y código → pre-rellena CLAUDE.md |
| `/process-inbox` | Cuando te sientes a trabajar | Procesa URLs capturadas desde móvil |
| `/weekly-briefing` | Semanal | Scan de ecosystem + búsqueda abierta |

## Estructura del repo

```
bin/
  sync.sh                  # Motor de sincronización (local y remoto)
templates/
  common-layer.md          # Universal principles (portable across all projects)
  project-layer.md         # Project-specific template (domain, architecture, gotchas)
  hooks/                   # Hook scripts and settings templates
protocols/
  internal-maintenance.md  # How to update CLAUDE.md from daily work
  external-intelligence.md # Sources, filters, processing pipeline, cadences
knowledge-base/
  insights/                # Processed insights from external sources
inbox.md                   # Low-friction URL capture (mobile-friendly)
install.sh                 # First-time installer (wrapper around bin/sync.sh)
VERSION                    # Framework version (triggers auto-update on bump)
.claude/
  commands/                # Slash commands
  skills/                  # Skills (loaded on demand)
  settings.json            # Hook configuration
```

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
