---
name: session-review
description: Revisa la sesión actual para detectar gotchas, patrones y anti-patterns. Propone actualizaciones al CLAUDE.md del proyecto.
disable-model-invocation: false
---

# Session Review

Revisa la sesión de trabajo actual (o la más reciente) para detectar conocimiento que debería estar en el CLAUDE.md del proyecto pero no lo está.

## Cuándo se ejecuta

- **Automáticamente**: invocado por el hook Stop al final de cada sesión
- **Manualmente**: cuando el usuario ejecuta `/session-review`
- **Por el agente**: cuando Claude detecta un patrón que se repite 2+ veces en la sesión

## Proceso

### 1. Recopilar contexto de la sesión

Analiza la conversación actual buscando:

- **Gotchas descubiertos**: errores que costaron tiempo, sorpresas, trampas
  - Señales: mensajes de error seguidos de cambios de enfoque, "ah, el problema era que...", comandos ejecutados 2+ veces con variaciones
- **Patrones establecidos**: soluciones que funcionaron y se usaron en 2+ lugares
  - Señales: misma estructura de código repetida, mismos comandos usados múltiples veces
- **Errores repetidos de Claude**: cosas que Claude hizo mal y fueron corregidas
  - Señales: el usuario corrige el enfoque, "no, hazlo así", rollbacks, rewrites
- **Anti-patterns**: prácticas que generaron problemas
  - Señales: tests fallidos por la misma razón, imports incorrectos, paths equivocados
- **Reglas de negocio mencionadas**: lógica de dominio que se discutió y no está documentada
  - Señales: "en este proyecto, X siempre debe ser Y", "el campo Z significa..."

### 2. Comparar con CLAUDE.md actual

Lee el CLAUDE.md del proyecto actual y verifica:
- ¿Los gotchas descubiertos ya están documentados? Si no, proponer.
- ¿Los patrones usados están documentados? Si no, proponer.
- ¿Hay anti-patterns documentados que se violaron? Si sí, reforzar la redacción.
- ¿Hay secciones del CLAUDE.md que contradicen lo que pasó en la sesión? Si sí, proponer actualización.

### 3. Generar propuestas

Para cada hallazgo, genera una propuesta con este formato:

```markdown
### [Tipo]: [Título corto]

**Evidencia**: [Qué pasó en la sesión que reveló esto]
**Sección CLAUDE.md**: [Dónde iría — Gotchas, Patterns, Anti-patterns, Domain, etc.]
**Cambio propuesto**:
+ [Línea a añadir o modificar]

**Prioridad**: [Alta — costó >15min / Media — podría volver a pasar / Baja — nice to have]
```

### 4. Presentar al usuario

Muestra las propuestas ordenadas por prioridad. Para cada una:
- **Aplicar**: añade al CLAUDE.md inmediatamente
- **Modificar**: el usuario ajusta antes de aplicar
- **Descartar**: no relevante o ya conocido

### 5. Aplicar cambios (con routing a rules files)

Para las propuestas aceptadas:
1. Lee el CLAUDE.md actual
2. **Comprueba si existen archivos `.claude/rules/`** en el proyecto
3. **Routing de contenido** — Para cada propuesta, aplica la regla de decisión:
   - Si el hallazgo solo aplica cuando se editan archivos de un área específica Y existe un rules file con globs que cubren esa área → propone insertar en el rules file
   - Si no existe un rules file que cubra el área → propone insertar en CLAUDE.md (comportamiento existente)
   - Si el hallazgo aplica globalmente → propone insertar en CLAUDE.md
4. Inserta el nuevo contenido en el destino correspondiente (CLAUDE.md o rules file)
5. Verifica que el CLAUDE.md no supere las 400 líneas (zona inteligente)
6. Si supera: sugiere descomponer contenido path-specific a archivos `.claude/rules/<area>.md` con globs frontmatter. Ejemplo:
   ```
   El CLAUDE.md tiene [N] líneas (zona de peligro >400).
   Sugiero mover las convenciones de [área] a .claude/rules/[area].md
   para reducir el tamaño y mejorar la precisión del contexto.
   ```

### 6. Clasificar y proponer upstream (reverse sync)

Para cada hallazgo aplicado, evalúa si es **universal** o **project-specific**:

- **Project-specific**: Gotchas de dominio, reglas de negocio, paths, APIs, configuraciones propias del proyecto. → Solo CLAUDE.md del proyecto.
- **Universal**: Gotchas que aplican a CUALQUIER proyecto usando el framework (ej: "Stop hooks son silenciosos", "notify() necesario para visibilidad"). → CLAUDE.md del proyecto + `.claude/.upstream-proposals`.

#### Criterios para clasificar como universal

Un hallazgo es universal si cumple AL MENOS UNO:
- Afecta un hook o skill del framework (no código del proyecto)
- Es un bug o limitación de Claude Code que cualquier usuario encontraría
- Es un patrón de trabajo que mejora la efectividad independientemente del stack
- Es una corrección a la documentación del Common Layer

#### Formato de `.upstream-proposals`

Si el hallazgo es universal, append al archivo `.claude/.upstream-proposals` (crear si no existe):

```markdown
---
## [Fecha ISO] — [Título corto]

**Tipo**: [gotcha | pattern | anti-pattern | fix]
**Afecta**: [hook/skill/template name, o "common-layer"]
**Descripción**: [Qué se descubrió y por qué importa]
**Cambio sugerido**: [Qué debería cambiar en el framework]
**Evidencia**: [Qué pasó en la sesión que reveló esto]
```

Después de añadir una propuesta upstream, notifica al usuario:

```
UPSTREAM_PROPOSAL: Se detectó un hallazgo universal: "[título]".
Añadido a .claude/.upstream-proposals. Cuando quieras enviarlas al framework, ejecuta /propose-upstream.
```

## Modo automático (invocado por hook)

Cuando se invoca desde el hook Stop:
- Ejecuta el análisis silenciosamente
- Solo muestra propuestas si hay hallazgos de prioridad Alta o Media
- Si no hay hallazgos relevantes, no muestra nada (no interrumpir innecesariamente)
