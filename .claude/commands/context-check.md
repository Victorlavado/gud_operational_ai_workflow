Evalúa el estado del contexto de la sesión actual y recomienda acciones.

## Instrucciones

### 1. Evaluar señales de degradación

Analiza la conversación actual buscando estas señales:

**Señales directas (alta fiabilidad):**
- ¿Ha habido compactación automática en esta sesión? (el sistema inserta un mensaje cuando compacta)
- ¿Se ha producido algún error que ya fue corregido antes en esta misma sesión?
- ¿Hay instrucciones del CLAUDE.md que se estén ignorando?

**Señales heurísticas (fiabilidad moderada):**
- ¿Cuántas interacciones sustantivas (tool calls) se han acumulado?
- ¿La sesión abarca múltiples tareas no relacionadas?
- ¿Se han leído muchos archivos grandes?

### 2. Leer el contador del watchdog

```bash
# Intenta leer el counter del context watchdog
COUNTER_FILE="/tmp/claude-context-$(echo "$PWD" | md5sum | cut -c1-8)"
cat "$COUNTER_FILE" 2>/dev/null || echo "Counter no disponible"
```

### 3. Generar diagnóstico

```markdown
## Context Health Check — [timestamp]

### Estado: [VERDE / AMARILLO / NARANJA / ROJO]

**Tool calls en sesión**: [N] (umbral amarillo: 30, naranja: 50, rojo: 80)
**Compactación detectada**: [Sí/No]
**Errores repetidos**: [Sí/No — cuáles]
**Tareas mezcladas**: [Sí/No]

### Recomendación

[Basada en el estado:]

**VERDE** (< 30 tool calls, sin señales):
> Todo bien. Continúa trabajando.

**AMARILLO** (30-50 tool calls o 1 señal):
> Acercándote al límite. Si vas a empezar una tarea nueva, considera `/clear` primero.
> Si continúas con la tarea actual, usa sub-agentes para operaciones pesadas.

**NARANJA** (50-80 tool calls o 2+ señales):
> Recomendación: `/compact` preservando [lista de contexto crítico a preservar].
> Alternativa: termina la tarea actual, haz commit, y `/clear`.

**ROJO** (80+ tool calls o compactación + errores repetidos):
> ACCIÓN: Antes de `/clear`, documenta:
> 1. Estado actual del trabajo (qué se completó, qué falta)
> 2. Decisiones tomadas en esta sesión
> 3. Gotchas descubiertos
> Luego: `/clear` y retoma con un prompt fresco que incluya este contexto.
```

### 4. Si el estado es NARANJA o ROJO

Propón un "prompt de reanudación" — un bloque de texto que el usuario puede copiar para empezar la sesión limpia con todo el contexto necesario:

```markdown
### Prompt de reanudación sugerido

> [Resumen de lo trabajado en esta sesión]
> [Decisiones tomadas]
> [Estado actual: qué archivos se modificaron, qué tests pasan/fallan]
> [Siguiente paso a ejecutar]
```

Esto resuelve el problema de "pierdo el hilo al hacer /clear" — el prompt de reanudación es la memoria comprimida inteligentemente.
