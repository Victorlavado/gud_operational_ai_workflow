Escanea un proyecto existente para extraer patrones, fallos recurrentes y convenciones. Genera o actualiza el Project Layer del CLAUDE.md con conocimiento extraído automáticamente.

## Argumentos

$ARGUMENTS — Ruta al directorio del proyecto. Si no se proporciona, usa el directorio actual.

## Instrucciones

### Fase 1: Recopilar datos (en paralelo)

Lanza agentes en paralelo para analizar diferentes fuentes de información:

**Agente 1 — Análisis de sesiones pasadas:**
- Busca en `.claude/` directorios de sesiones, logs, o historial
- Busca en `.claude-auto/` si existe (hooks, validators, reminders)
- Extrae: errores recurrentes, correcciones frecuentes, patrones de uso

**Agente 2 — Análisis de git:**
- `git log --oneline -100` — últimos 100 commits
- `git log --diff-filter=M --name-only -50` — archivos más modificados
- Busca patrones en mensajes de commit (errores mencionados, reverts, "fix" repetidos)
- Identifica convenciones de branching y commit existentes

**Agente 3 — Análisis de estructura y código:**
- Estructura del proyecto (directorios clave, organización)
- Stack detection (package.json, pyproject.toml, Dockerfile, etc.)
- Patrones de código (imports, naming, file organization)
- Tests existentes (framework, estructura, cobertura aproximada)
- CI/CD configs (.github/workflows, Jenkinsfile, etc.)

**Agente 4 — Análisis de documentación existente:**
- CLAUDE.md existente (qué tiene, qué le falta)
- README, docs/, specs/ si existen
- Archivos .md sueltos en la raíz (posibles residuos de sesiones)
- ADRs (Architecture Decision Records) si existen

### Fase 2: Sintetizar hallazgos

Con los resultados de los 4 agentes, sintetiza:

#### Gotchas detectados
Busca en el historial:
- Errores que aparecen 2+ veces en commits o sesiones
- Reverts (indican decisiones equivocadas)
- Archivos que se modifican frecuentemente (hotspots)
- Patrones de "fix" seguido de otro "fix" en el mismo área

#### Patrones establecidos
- Convenciones de naming consistentes en el código
- Estructura de archivos que se repite
- Patrones arquitectónicos visibles (MVC, servicios, etc.)
- Testing patterns (qué framework, cómo se organizan)

#### Anti-patterns detectados
- Commits vagos o monolíticos
- Archivos de documentación desactualizados
- Tests faltantes en áreas con muchos bugs
- Configuraciones inconsistentes entre servicios

#### Quality gates existentes
- Comandos de test/lint/build encontrados
- CI checks configurados
- Hooks pre-commit existentes

### Fase 2.5: Generar path-scoped rules

Después de la síntesis, detecta áreas del proyecto que se beneficiarían de reglas path-scoped:

1. **Detectar áreas con código significativo**: Busca directorios con >5 archivos que representan un área funcional distinta (ej: `src/api/`, `app/models/`, `frontend/`, `workers/`, `lib/services/`)
2. **Para cada área detectada**, genera un archivo `.claude/rules/<area>.md` con:

```markdown
---
globs: ["<path-pattern>/**"]
---

# [Area Name] — Conventions

## Patterns
[Patrones específicos descubiertos para esta área]

## Gotchas
[Gotchas específicos de esta área]
```

3. **Regla de decisión**: Si un hallazgo (gotcha, patrón, anti-pattern) solo aplica cuando se editan archivos de un área específica → va a `.claude/rules/<area>.md`. Si aplica globalmente → va a CLAUDE.md.
4. **No duplicar**: El contenido que va a rules files NO se incluye también en CLAUDE.md.
5. **Presentar al usuario**: Muestra los rules files propuestos para aprobación, igual que las propuestas de CLAUDE.md.

### Fase 3: Generar o actualizar CLAUDE.md

**Si no existe CLAUDE.md:**
Sugiere ejecutar `/init-project` primero para crear la estructura, luego aplicar los hallazgos.

**Si existe CLAUDE.md:**
Para cada hallazgo, propone una actualización específica con formato diff:

```
## Propuesta: Añadir gotcha — [nombre]
Sección: Gotchas > Critical
Motivo: Detectado en [X commits/sesiones] — [evidencia]

+ - **[Gotcha]**: [Descripción]. Mitigación: [qué hacer].
```

### Fase 4: Presentar resultados

Muestra al usuario un resumen estructurado:

```markdown
# Bootstrap Intelligence Report — [Project Name]

## Datos analizados
- Sesiones: [N]
- Commits: [N]
- Archivos escaneados: [N]

## Gotchas descubiertos: [N]
[Lista con evidencia]

## Patrones identificados: [N]
[Lista con ejemplos]

## Anti-patterns detectados: [N]
[Lista con sugerencias de corrección]

## Quality gates encontrados
[Comandos existentes]

## Propuestas de actualización al CLAUDE.md: [N]
[Lista de cambios propuestos]
```

### Fase 5: Aplicar con confirmación

Para cada propuesta, pregunta al usuario:
- **Aplicar** — añade al CLAUDE.md
- **Modificar** — ajustar antes de añadir
- **Descartar** — no relevante

Opción de "Aplicar todas" para aceptar en batch si el usuario confía en los resultados.
