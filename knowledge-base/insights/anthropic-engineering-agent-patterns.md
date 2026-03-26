---
source: https://www.anthropic.com/engineering
author: Anthropic Engineering
date_processed: 2026-03-26
tags: [agent-architecture, multi-agent, harnesses, tool-design, orchestration]
impact: high
status: actionable
---

## Insight

### 5 patrones de workflow (de menos a más complejo)
1. **Prompt Chaining** — tareas secuenciales con gates programáticos
2. **Routing** — clasificar inputs, dirigir a handlers especializados
3. **Parallelization** — múltiples LLM calls simultáneas (sectioning o voting)
4. **Orchestrator-Workers** — LLM central descompone y delega dinámicamente
5. **Evaluator-Optimizer** — un LLM genera, otro evalúa, en bucle

**Principio clave**: No usar agentes autónomos cuando un workflow predefinido basta.

### Diseño de herramientas para agentes
- **Consolidar sobre proliferar**: herramientas inteligentes que manejan múltiples operaciones, no wrappers de API.
- **Respuestas de alta señal**: campos semánticos, no IDs técnicos. Resolver UUIDs a nombres.
- **Errores accionables**: instrucciones de remediación, no códigos genéricos.
- **Documentación como contrato**: las descripciones de tools guían el comportamiento del agente.
- **Poka-yoke**: hacer que los errores sean difíciles de cometer (rutas absolutas > relativas).

### Harnesses para agentes de larga duración
- **Archivos de progreso en JSON** (no markdown) — resiste mejor modificación inapropiada.
- **Git como registro de estado** entre sesiones.
- **Una feature por sesión** — evitar fallos en cascada por agotamiento de contexto.
- **Protocolo de reanudación**: (1) verificar directorio, (2) leer docs + git log, (3) ejecutar tests, (4) seleccionar siguiente feature.
- **Tests pre-feature**: ejecutar tests e2e antes de empezar trabajo nuevo.

### Multi-agente
- Opus líder + Sonnet subagentes superó al agente único en 90.2%.
- La paralelización redujo tiempos hasta 90%.
- Multi-agente consume ~15x más tokens — solo justificado en tareas de alto valor.
- Cada subagente necesita: objetivos explícitos, formato de salida, guía de herramientas, límites claros.

## Acción

- Usar el principio de "mínima complejidad necesaria" al elegir patrones de agente
- Diseñar tools con documentación como contrato + errores accionables
- Protocolo de reanudación estandarizado para sesiones largas (→ Capa 3: Context Continuity)
- Tests pre-feature como parte del quality gate
- Multi-agente solo para tareas de alto valor (investigación profunda, refactors grandes)

## Aplicado en

- Framework: principio "no usar agentes cuando un workflow basta"
- Framework Capa 3 (futuro): protocolo de reanudación
- Template CLAUDE.md: tests pre-feature en Quality Gates
