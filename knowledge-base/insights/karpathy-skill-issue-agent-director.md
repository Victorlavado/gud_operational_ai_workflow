---
source: https://x.com/saranormous/status/2035080458304987603 (No Priors interview)
author: Andrej Karpathy (@karpathy)
date_processed: 2026-03-26
tags: [agent-orchestration, skill-issue, developer-role, parallelization]
impact: high
status: actionable
---

## Insight

### "Skill issue": la responsabilidad es del operador

Cuando los agentes fallan, generalmente no es un problema de capacidad de la IA, sino del desarrollador:
- Instrucciones insuficientes
- Herramientas de memoria no configuradas
- No paralelizar adecuadamente

Karpathy no ha escrito una línea de código manualmente desde diciembre 2025.

### El developer como director, no ejecutor

- **"El cuello de botella eres tú."** — Si tienes tokens de suscripción sin usar, estás subutilizando.
- **Tokens ociosos = capacidad desperdiciada** — métrica clave de eficiencia.
- El rol pasa de escribir código a orquestar, supervisar y dirigir equipos de agentes.

### Workflow recomendado

- **Paralelización sobre serialización**: Ejecutar múltiples agentes simultáneamente.
- **Acciones macro sobre micro**: Delegar features completas (tareas de 20 min), no funciones individuales.
- **Equipos de agentes**: "La vieja IDE de un solo archivo está muerta; la nueva unidad son equipos de agentes."
- **Expresar intención, no código**: Descomponer objetivos en tareas, asignar a agentes, revisar a nivel macro.

### La profundidad técnica como multiplicador

- Los ingenieros mejor posicionados son los que tienen suficiente comprensión para delegar con precisión y detectar errores antes de que se propaguen.
- La personalidad del agente importa: retroalimentación calibrada genera confianza.
- El juicio humano se enfoca en lo que los agentes no pueden hacer; todo lo demás se delega.

## Acción

- Medir "tokens ociosos" como proxy de eficiencia operativa
- Delegar features completas, no funciones individuales
- Paralelizar agentes: mientras uno implementa, otro investiga, otro testea
- Invertir en comprensión arquitectónica como multiplicador de la capacidad de delegación
- Aspiración: llegar a no escribir código directamente, solo specs + revisión + dirección

## Aplicado en

- Framework: principio "on the loop, not in the loop"
- Framework Capa 4 (futuro): Agent Orchestration diseñada para paralelización
- Career direction: architectural thinking como el skill multiplicador
