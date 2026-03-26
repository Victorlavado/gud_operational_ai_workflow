Procesa un recurso externo (URL, artículo, entrevista, thread) y decide si es accionable para el framework Operational AI Workflows.

## Argumentos

$ARGUMENTS — URL del recurso a procesar. Si no se proporciona URL, pregunta al usuario.

## Instrucciones

1. **Obtén el contenido** del recurso usando WebFetch. Si es un perfil de X/Twitter, usa WebSearch para encontrar el contenido relevante.

2. **Aplica el filtro de calidad** (de `protocols/external-intelligence.md`):
   - ¿Tiene repo público o producto visible?
   - ¿Muestra resultados tangibles?
   - ¿Es reproducible?
   - ¿Puedes responder: "¿Qué cambiaría en mi workflow si aplico esto?"

3. **Si NO pasa el filtro**: Informa al usuario con una justificación de una línea y termina.

4. **Si SÍ pasa el filtro**, extrae:
   - **¿Qué dice?** — Resumen en 3-5 bullets
   - **¿Qué es accionable?** — Qué puede cambiar Victor mañana en su forma de trabajar
   - **¿Afecta al framework?** — ¿Cambia algún principio, protocolo o template?
   - **¿Es nuevo o valida algo existente?** — Revisa `knowledge-base/insights/` para ver si ya existe un insight relacionado

5. **Presenta el resultado** al usuario con este formato:

```markdown
## Recurso: [Título]
**Fuente**: [URL]
**Autor**: [Quién]
**Filtro**: PASA / NO PASA

### Resumen
- [Bullet 1]
- [Bullet 2]
- [Bullet 3]

### Acción propuesta
[Qué cambiar y dónde]

### Impacto en el framework
- [ ] Nuevo insight → crear en knowledge-base/insights/
- [ ] Actualización de insight existente → [cuál]
- [ ] Cambio en template/protocolo → [cuál y qué cambiar]
- [ ] Solo informativo, no requiere cambios
```

6. **Espera confirmación** del usuario antes de:
   - Crear el archivo de insight en `knowledge-base/insights/`
   - Modificar cualquier artefacto del framework

7. **Si el usuario confirma**, crea el insight con el formato estándar:

```markdown
---
source: [URL]
author: [Quién]
date_processed: [YYYY-MM-DD]
tags: [tags relevantes]
impact: [high/medium/low]
status: [actionable/applied/superseded]
---

## Insight
[Contenido]

## Acción
[Qué hacer]

## Aplicado en
[Vacío si pendiente, referencia si ya se aplicó]
```
