Ejecuta un briefing semanal de inteligencia externa para el framework Operational AI Workflows.

## Instrucciones

1. **Lee las fuentes curadas** en `protocols/external-intelligence.md` para saber dónde buscar.

2. **Escanea las siguientes fuentes** (usa WebSearch y WebFetch):

   ### Releases y changelogs
   - Anthropic blog: busca "Claude Code" OR "Claude channels" OR "Claude dispatch" en la última semana
   - OpenClaw GitHub: busca releases recientes
   - Compound Engineering: busca actualizaciones recientes

   ### Builders (Twitter/X)
   Busca actividad reciente de estos perfiles enfocándote en contenido técnico sobre AI workflows, agentes, y herramientas de desarrollo:
   - @karpathy, @GeoffreyHuntley, @dabit3, @levelsio, @steipete, @shawmakesmagic, @banteg, @thekitze, @PierreDeWulf, @nateliason, @Austen

   ### Blogs
   - ghuntley.com: artículos recientes
   - latentpatterns.com: contenido nuevo
   - latent.space: posts recientes

3. **Filtra** cada recurso encontrado con los criterios de `protocols/external-intelligence.md` (builders vs hype, accionable vs teórico).

4. **Genera el briefing** con este formato:

```markdown
# Weekly Intelligence Briefing — [YYYY-MM-DD]

## Releases relevantes
- [Release]: [Qué es, por qué importa para el workflow de Victor]

## Insights de builders
- [Quién]: [Insight resumido + link]

## Propuestas de actualización al framework
Para cada propuesta:
- **Qué cambiar**: [Artefacto afectado + cambio concreto]
- **Por qué**: [Referencia a la fuente]
- **Cómo integrarlo**: [Pasos concretos]
- **Aplicar / Descartar**: [Espera decisión de Victor]

## Descartados (con justificación)
- [Recurso]: [Por qué no pasa el filtro — una línea]
```

5. **Para cada propuesta de actualización**, pregunta a Victor si quiere aplicarla. Si dice sí:
   - Si es un insight nuevo: créalo en `knowledge-base/insights/` con el formato estándar
   - Si es un cambio al framework: aplica el cambio al artefacto correspondiente
   - Si es una validación de algo existente: actualiza el insight existente con la nueva referencia

6. **Muestra el briefing** al usuario y espera su feedback antes de aplicar cambios.
