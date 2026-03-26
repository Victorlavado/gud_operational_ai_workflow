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

### 5. Aplicar cambios

Para las propuestas aceptadas:
1. Lee el CLAUDE.md actual
2. Inserta el nuevo contenido en la sección correspondiente
3. Verifica que el CLAUDE.md no supere las 400 líneas (zona inteligente)
4. Si supera: sugiere qué mover a archivos referenciados via `@path`

## Modo automático (invocado por hook)

Cuando se invoca desde el hook Stop:
- Ejecuta el análisis silenciosamente
- Solo muestra propuestas si hay hallazgos de prioridad Alta o Media
- Si no hay hallazgos relevantes, no muestra nada (no interrumpir innecesariamente)
