# Protocolo de Inteligencia Externa

Cómo alimentar el framework con conocimiento del ecosistema de forma estructurada.

## Principio

> Capturar sin procesar es ruido. El valor no está en guardar el link,
> sino en extraer el insight accionable y decidir si cambia algo en tu workflow.

---

## Fuentes curadas

### Perfiles de builders (Twitter/X)

Personas que construyen, muestran resultados tangibles y comparten procesos reproducibles:

| Handle | Foco | Por qué es señal |
|--------|------|-------------------|
| @karpathy | AI research/engineering, agentic workflows | Define paradigmas. "Skill issue" framing. |
| @GeoffreyHuntley | Developer tooling, AI workflows | Ralph Loop, back-pressure. Builder puro. |
| @dabit3 | Full-stack/AI builder | Construye en público, muestra código real |
| @levelsio | Indie hacking, shipping con AI | Velocidad de ejecución, pragmatismo extremo |
| @PierreDeWulf | Builder | Proyectos tangibles |
| @thekitze | Developer tools, producto | Herramientas prácticas |
| @steipete | Engineering leadership, tooling | Perspectiva de gestión técnica |
| @banteg | Builder/hacker | Implementaciones técnicas reales |
| @shawmakesmagic | AI agents, elizaOS | Ecosistema de agentes, frameworks |
| @nateliason | Builder/entrepreneur | Aplicación práctica de AI |
| @Austen | Builder/entrepreneur | Escala y producto |

### Publicaciones y blogs

| Fuente | URL | Foco |
|--------|-----|------|
| Latent Space | latent.space | AI engineering deep dives |
| Geoffrey Huntley's blog | ghuntley.com | Developer tooling, AI workflows |
| Latent Patterns | latentpatterns.com | Patrones de AI, context engineering |
| Anthropic blog | anthropic.com/blog | Releases de Claude, Claude Code, channels, dispatch |
| Anthropic Engineering | anthropic.com/engineering | Patrones de agentes, multi-agent, harnesses, tool design |
| OpenClaw | github.com/anthropics/claw | Agent harness, releases |

### Documentación oficial

| Fuente | URL | Foco |
|--------|-----|------|
| Claude Code Best Practices | code.claude.com/docs/en/best-practices | CLAUDE.md, hooks, skills, session management, context |

### Release tracking

| Producto | Dónde mirar | Por qué importa |
|----------|-------------|-----------------|
| Claude Code | Anthropic blog + changelog | Nuevas features afectan directamente el workflow |
| Claude models | Anthropic blog | Capacidades nuevas = técnicas nuevas |
| OpenClaw | GitHub releases | Agent harness para orquestación |
| Compound Engineering | GitHub/npm | Plugins, skills, workflows nuevos |

---

## Modo descubrimiento (búsqueda abierta)

Las fuentes curadas son el punto de partida, no el límite. El modo descubrimiento busca más allá, aplicando los mismos filtros de calidad.

### Cuándo activarlo
- Durante el `/weekly-briefing`: dedicar una parte del scan a búsqueda abierta
- Cuando surge una tecnología/patrón nuevo que ninguna fuente curada cubre
- Cuando Victor pide investigar un tema específico

### Cómo funciona
1. **Buscar** en web abierta con queries específicas (no genéricas): `"claude code hooks" site:github.com`, `"agentic workflow" temporal.io`, etc.
2. **Aplicar el filtro de calidad** (abajo) a cada resultado — mismo estándar que las fuentes curadas
3. **Si una fuente nueva pasa el filtro repetidamente** (3+ insights accionables), proponerla como fuente curada permanente
4. **Si un perfil nuevo aparece consistentemente** en contenido de calidad, proponerlo para la lista de builders

### Queries de descubrimiento sugeridas
- `"[tecnología del stack]" AND ("workflow" OR "agent" OR "automation")` — buscar patrones para herramientas que Victor usa
- `"claude code" AND ("hook" OR "skill" OR "CLAUDE.md" OR "command")` — novedades del tooling principal
- `"agentic" AND ("production" OR "deployment" OR "architecture")` — soluciones agénticas en producción, no prototipos
- Buscar repos con >100 stars creados en el último mes que usen el stack relevante

---

## Filtro de calidad

Antes de procesar un recurso, pasa este filtro:

### Es señal si...
- Tiene **repo público** o **producto visible** (no solo opinión)
- Muestra **resultados tangibles**: demos, métricas, antes/después
- El enfoque es **reproducible**: puedes aplicarlo a tu proyecto
- Viene de alguien que **construye activamente**, no solo comenta

### Es ruido si...
- Solo es opinión sin implementación
- Promete resultados sin mostrar proceso
- Es un thread viral sin sustancia técnica
- "10 prompts que cambiarán tu vida" → skip
- No puedes responder: "¿Qué cambiaría en mi workflow si aplico esto?"

---

## Pipeline de procesamiento

### Paso 1: Captura

**Si estás en Claude Code:**
```
/process-resource <url>
```

**Si estás en el móvil o fuera del terminal:**
Añade la URL a `inbox.md` en la raíz de este repo (editable via GitHub mobile, cloud sync, o cualquier editor):
```markdown
- <url> — [nota de una línea sobre por qué te llamó la atención]
```

**Cuando te sientes a trabajar:**
```
/process-inbox
```
Procesa todas las URLs pendientes en batch, aplica filtros, y te presenta los resultados.

### Paso 2: Extracción
El comando `/process-resource` (o tú manualmente) debe responder:

1. **¿Qué dice?** — Resumen en 3-5 bullets
2. **¿Qué es accionable?** — ¿Qué puedo hacer diferente mañana?
3. **¿Afecta al framework?** — ¿Cambia algún principio, protocolo o template?
4. **¿Es un nuevo patrón o una validación de uno existente?**

### Paso 3: Decisión

| Resultado | Acción |
|-----------|--------|
| Insight accionable nuevo | Crear archivo en `knowledge-base/insights/` |
| Valida un patrón existente | Añadir referencia al insight existente |
| Requiere cambio en el framework | Crear issue/tarea + actualizar el artefacto afectado |
| Interesante pero no accionable ahora | Descartar. No acumular. |
| No pasa el filtro de calidad | Descartar inmediatamente |

### Paso 4: Almacenamiento

Formato para archivos en `knowledge-base/insights/`:

```markdown
---
source: [URL]
author: [Quién]
date_processed: [YYYY-MM-DD]
tags: [context-engineering, back-pressure, agent-orchestration, etc.]
impact: [high/medium/low]
status: [actionable/applied/superseded]
---

## Insight

[Resumen conciso de lo que se aprendió]

## Acción

[Qué cambiar o probar en el workflow]

## Aplicado en

[Referencia a dónde se aplicó, si ya se hizo. Vacío si pendiente.]
```

---

## Cadencias

### Semanal: Intelligence Briefing

Comando: `/weekly-briefing`

Ejecutar una vez por semana (preferiblemente lunes o domingo noche). El briefing:

1. Escanea las fuentes curadas (blogs, releases, perfiles X más activos)
2. Filtra por relevancia al stack y workflow de Victor
3. Produce un resumen con:
   - **Releases relevantes**: Nuevas versiones de herramientas del stack
   - **Insights de builders**: Patrones o técnicas nuevas de los perfiles curados
   - **Propuestas de actualización**: Cambios sugeridos al framework con justificación
4. Cada propuesta incluye:
   - Qué cambiar
   - Por qué (con referencia a la fuente)
   - Cómo integrarlo en el workflow
   - Opción de aplicar o descartar

### Bajo demanda: Process Resource

Comando: `/process-resource <url>`

Para cuando encuentras algo interesante entre semanas:

1. Procesa el recurso con el pipeline descrito arriba
2. Si es accionable, lo almacena en `knowledge-base/insights/`
3. Si requiere cambio en el framework, lo propone
4. Si no pasa el filtro, lo descarta con una justificación de una línea

---

## Evolución de fuentes

Las fuentes no son estáticas. Cada trimestre:

- [ ] ¿Alguna fuente dejó de producir contenido relevante? → Eliminar
- [ ] ¿Descubriste builders nuevos que pasan el filtro? → Añadir
- [ ] ¿Hay un área nueva en tu stack que necesita tracking? → Añadir fuente
- [ ] ¿Alguna fuente se convirtió en "hype"? → Eliminar
