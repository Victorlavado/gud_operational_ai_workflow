---
name: recovery
description: Diagnostica problemas de implementación usando señales objetivas de los hooks y recomienda la acción de recuperación óptima. Genera prompts de reanudación listos para usar.
disable-model-invocation: false
---

# Recovery Protocol

Diagnostica el estado de la implementación actual y recomienda la acción de recuperación cuando la sesión entra en espiral.

## Cuándo se activa

- **Por el hook implementation-health**: cuando detecta file churn, test regression o spiral
- **Manualmente**: cuando el usuario ejecuta `/recovery`
- **Por Claude**: cuando detecta ciclos sin progreso

## Proceso

### 1. Recopilar señales objetivas

Lee los archivos de estado de los hooks. Usa sub-agentes para no contaminar el contexto principal.

**Del context-watchdog** (fichero `/tmp/claude-context-*`):
- Número total de tool calls → zona: verde (<30), amarillo (30-50), naranja (50-80), rojo (>80)

**Del implementation-health** (directorio `/tmp/claude-health-*/`):
- `edits.log` → calcula edits por archivo, identifica los más modificados
- `bash.log` → detecta comandos repetidos
- `tests.log` → tendencia: secuencia de 0s (pass) y 1s (fail), lee las últimas 5 entradas

Si los archivos de estado no existen (hooks no configurados), usa señales alternativas:
- `git diff --stat` para amplitud de cambios
- `git log --oneline -10` para commits recientes
- Pregunta al usuario qué está pasando

### 2. Analizar el plan/spec en disco

Busca el plan o spec del trabajo actual. Orden de búsqueda:
1. Archivos mencionados en la conversación actual
2. Patrones comunes: `specs/*.md`, `plans/*.md`, `docs/specs/*.md`, `.plans/*.md`
3. Archivos `.md` modificados recientemente: `git diff --name-only HEAD` que sean `.md`
4. Si no hay plan en disco: pregunta al usuario qué estaba haciendo y cuál era el objetivo

Del plan, extrae:
- Subtareas completadas vs pendientes
- Scope original de la tarea
- Decisiones ya documentadas

### 3. Evaluar estado del código

Ejecuta via sub-agente (para no inflar el contexto principal):
- `git status` — archivos modificados no committeados
- `git diff --stat` — magnitud de cambios
- Si hay tests definidos en Quality Gates: ejecutar y capturar qué pasa, qué falla

### 4. Sintetizar diagnóstico

Presenta al usuario con este formato exacto:

```
## Diagnóstico de recuperación

### Señales
| Señal | Estado | Detalle |
|-------|--------|---------|
| Contexto | [🟢🟡🟠🔴] | [N] tool calls |
| File churn | [archivo(s)] | [N] edits cada uno |
| Tests | [N pass / M fail] | Tendencia: [↑ mejorando / → estancado / ↓ empeorando] |
| Retry loops | [sí/no] | [comando(s) repetidos] |

### Estado del trabajo
- **Plan**: [ruta al archivo o "no encontrado"]
- **Completado**: [subtareas hechas, si el plan es legible]
- **Bloqueado en**: [qué falla y diagnóstico breve del por qué]
- **Cambios sin commit**: [N archivos, magnitud]

### Diagnóstico
[UNA frase concreta: "Estás en espiral de X porque Y" o "Problema acotado a Z"]
```

### 5. Recomendar UNA acción

Basándote en el diagnóstico, recomienda **una sola acción** (la más adecuada):

**Nivel 1 — Reenfoque** (contexto verde/amarillo, problema acotado a 1 archivo/test):
- Delega el diagnóstico del test fallido a un sub-agente
- Reduce scope: enfócate SOLO en el test/archivo problemático
- No necesitas `/clear`
- Prompt sugerido para el reenfoque

**Nivel 2 — Compact + scope reducido** (contexto naranja, múltiples issues pero progreso parcial):
- `/compact` preservando: archivos modificados, decisiones tomadas, estado de tests
- Retoma con UNA sola subtarea
- Genera el texto exacto para `/compact <instrucciones>`

**Nivel 3 — Clear + restart** (contexto rojo, espiral confirmada, sin progreso):
1. Commit WIP: `git add -A && git commit -m "wip: [feature] - estado parcial antes de recovery"`
2. Documentar estado en `.claude/recovery-state.md`
3. `/clear`
4. Genera el **prompt de reanudación completo** — texto listo para pegar como primer mensaje

### 6. Generar prompt de reanudación

Para niveles 2 y 3, genera un prompt de reanudación que incluya:

```
Lee el plan en [ruta al plan/spec].
Estado actual: [subtareas completadas, qué queda].
El test [nombre] falla por [diagnóstico].
Enfócate SOLO en [una sola cosa concreta].
NO toques [archivos/áreas fuera de scope].
Antes de empezar, ejecuta los tests para confirmar el estado actual.
```

Este prompt es el output más valioso del skill — reconecta una sesión limpia con el trabajo previo sin perder el contexto importante.

### 7. Ejecutar (con confirmación)

Si el usuario acepta:
- **Nivel 1**: ejecuta el reenfoque inmediatamente
- **Nivel 2**: muestra el comando `/compact` listo para copiar
- **Nivel 3**: hace commit WIP, escribe `.claude/recovery-state.md`, muestra el prompt de reanudación

## Principios del skill

- **Agnóstico a herramientas**: no asume qué plugin creó el plan, qué framework de tests, ni qué stack. Lee lo que encuentra en disco.
- **Basado en señales objetivas**: file churn, test trajectory, tool call count. No juicio subjetivo.
- **Una sola recomendación**: no dar opciones. Recomienda la mejor acción según las señales.
- **Sub-agentes para recopilación**: toda la recopilación de datos (git, tests, lectura de archivos de estado) se hace en sub-agentes para no agravar la situación de contexto.
- **El prompt de reanudación es el entregable principal**: todo el diagnóstico sirve para producir el texto que reconecta la sesión limpia con el trabajo previo.
