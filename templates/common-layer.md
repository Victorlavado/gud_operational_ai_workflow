# Common Layer — Operational AI Workflows

<!-- This layer is universal. It applies to ANY project regardless of stack, domain, or team.
     It gets copied as-is by /init-project and updated when the framework evolves.
     DO NOT put project-specific information here. -->

---

## Context Management

<!-- These rules prevent context degradation — the #1 cause of declining agent quality
     during a session. Source: Latent Patterns context engineering research.
     The context-watchdog hook automates threshold alerts via PostToolUse. -->

- IMPORTANT: La "zona inteligente" del contexto está al ~40% de utilización. Más allá, la calidad degrada.
- El **context-watchdog hook** monitoriza tool calls y emite alertas automáticas en 3 umbrales:
  - **AMARILLO (30 tool calls)**: acercándote al límite. No empieces tareas nuevas.
  - **NARANJA (50 tool calls)**: fuera de zona inteligente. Usa `/compact` o finaliza la tarea actual.
  - **ROJO (80 tool calls)**: alto riesgo. Documenta estado, haz `/clear`, retoma con prompt fresco.
- Usa `/context-check` en cualquier momento para un diagnóstico completo del estado del contexto.
- Usa `/clear` entre tareas no relacionadas en la misma sesión. El contexto acumulado degrada rendimiento.
- **Regla de los dos intentos**: si corriges a Claude 2+ veces en el mismo problema, usa `/clear` y reformula el prompt incorporando lo aprendido.
- Usa `/compact <instrucciones>` para comprimir contexto manteniendo lo esencial. Ejemplo: `/compact Focus on the API changes`. IMPORTANT: Al usar /compact, especifica qué preservar (archivos modificados, decisiones, estado de tests).
- Usa sub-agentes (Agent tool) para tareas que producen mucho output: tests, búsquedas extensas, análisis de logs. Ejecutan en ventanas de contexto separadas y devuelven resúmenes.
- NO satures este CLAUDE.md con información que puedes descubrir leyendo el código. Reserva este archivo para lo que Claude NO puede inferir.

### Señales de degradación (vigílalas activamente)

Si observas CUALQUIERA de estas señales, el contexto está degradado:
- Claude "olvida" decisiones tomadas antes en la misma sesión
- Claude repite errores que ya fueron corregidos
- Claude ignora instrucciones que están en este CLAUDE.md
- Las respuestas se vuelven genéricas o pierden especificidad del proyecto
- Claude propone soluciones que contradicen patrones ya establecidos

**Protocolo ante degradación:**
1. NO sigas trabajando — cada interacción adicional empeora la situación
2. Invoca `/recovery` para diagnóstico automático basado en señales objetivas y recomendación de acción
3. Si `/recovery` no está disponible: documenta estado, commit WIP, `/clear` + prompt de reanudación

El **hook implementation-health** detecta automáticamente patrones de espiral (file churn, test regression, retry loops) y recomienda invocar `/recovery` cuando las señales lo justifican.

## Work Patterns

<!-- How the agent should approach work. Source: Huntley's Ralph Loop,
     Karpathy's skill issue, Anthropic's agent patterns. -->

- **Una tarea por ciclo.** No mezclar múltiples objetivos en una misma iteración del agente.
- **Specs como fuente de verdad.** Leer specs/planes del disco antes de implementar. El código es un artefacto derivado de la spec.
- **Verificar antes de empezar.** Ejecutar tests existentes antes de iniciar trabajo nuevo para detectar bugs heredados.
- **No usar agentes autónomos cuando un workflow predefinido basta.** Progresión: prompt simple → LLM + retrieval → workflow → agente.
- **Expresar intención, no código.** Descomponer objetivos en tareas, revisar a nivel macro.

## Quality Gates — Defaults

<!-- IMPORTANT: These gates run ALWAYS. They are the back-pressure system
     that keeps the agent on track. Source: Huntley's back-pressure principle.

     Override or extend these in the Project Layer section below. -->

YOU MUST run these checks before every commit. No exceptions:

1. **Tests**: Ejecutar la suite de tests del proyecto. Si falla un test, NO hacer commit.
2. **Linting**: Ejecutar el linter configurado. Corregir antes de commit.
3. **Type checking**: Si el proyecto usa tipos estáticos, ejecutar el type checker.
4. **Build**: Si el proyecto tiene build step, verificar que compila.

### Test requirements por tipo de cambio

- **Nueva feature**: unit tests + integration test como mínimo
- **Bug fix**: test de regresión que reproduce el bug primero, luego el fix
- **Refactor**: los tests existentes deben pasar sin modificación

### Infrastructure checks

- Si el proyecto usa containers: reconstruir después de CUALQUIER cambio en el código del servicio
- Verificar logs del servicio después de reconstruir

## Commit Conventions

<!-- Commits vagos ("various fixes", "added missing files") hacen imposible
     reconstruir el contexto. Conventional commits fuerzan claridad. -->

- Usar conventional commits: `type(scope): description`
- Tipos: `feat`, `fix`, `refactor`, `test`, `docs`, `chore`
- Un cambio lógico por commit. NUNCA "various fixes" o "added files".
- El mensaje describe el POR QUÉ, no el QUÉ (el diff ya muestra el qué).

## Anti-patterns — Universal

<!-- Things Claude tends to do across all projects. Catching these early
     prevents wasted time. -->

- DO NOT crear archivos de utilidad genéricos. La lógica pertenece al módulo que la usa.
- DO NOT añadir `type: ignore`, `# noqa`, `eslint-disable` salvo causa justificada documentada.
- DO NOT usar print/console.log para debugging. Usar el logger del proyecto.
- DO NOT generar código sin verificación. Siempre proveer tests o scripts de verificación.
- DO NOT hacer "exploraciones infinitas" — acotar el scope de búsqueda antes de investigar.
- DO NOT mezclar tareas no relacionadas en una misma sesión o commit.

## Session Discipline

<!-- Source: Claude Code best practices + context watchdog system. -->

### Al inicio de sesión
- Leer CLAUDE.md, revisar git status, ejecutar tests básicos.
- Si retomas trabajo previo: usa `claude --continue` o `claude --resume` para elegir sesión.

### Durante la sesión
- Al cambiar de tarea: `/clear` si la nueva tarea no tiene relación con la anterior.
- Al encontrar un gotcha: añadirlo INMEDIATAMENTE a la sección Gotchas de este archivo.
- Al recibir alerta del context-watchdog: seguir el protocolo de degradación (arriba).
- Si la implementación se complica (tests fallan repetidamente, múltiples cambios de enfoque): parar, hacer `/context-check`, decidir si continuar o `/clear` + reformular.

### Al final de sesión
- El hook session-review se ejecuta automáticamente y propone actualizaciones al CLAUDE.md.
- Si hiciste `/clear` durante la sesión: verifica que los gotchas descubiertos antes del /clear no se perdieron.

### Recuperación de sesiones largas
Cuando `/clear` es necesario pero no quieres perder contexto, documenta antes:
```
## Estado al hacer /clear — [timestamp]
- **Completado**: [qué se terminó]
- **En progreso**: [qué quedó a medias + estado exacto]
- **Decisiones**: [decisiones tomadas que deben preservarse]
- **Gotchas**: [trampas descubiertas]
- **Siguiente paso**: [exactamente qué hacer al retomar]
```
Pega esto como primer mensaje de la sesión limpia.
