---
source: https://latentpatterns.com/courses/context-engineering , https://latentpatterns.com/courses/building-your-own-coding-agent
author: Latent Patterns
date_processed: 2026-03-26
tags: [context-engineering, sub-agents, agent-architecture]
impact: high
status: applied
---

## Insight

### La ingeniería de contexto es la disciplina central

- **El tamaño real útil del contexto NO es el anunciado.** La "zona inteligente" está al ~40% de utilización. Más allá: degradación.
- **Slots que compiten**: system prompt → harness → AGENTS.md/CLAUDE.md → tool definitions → user prompt. Cada slot consume presupuesto finito.
- **Cada tool call expande el contexto dinámicamente.** Cada ciclo tool_call + resultado añade múltiples entradas, empujando hacia degradación.
- **La compactación automática es peligrosa.** Puede eliminar instrucciones críticas de forma no determinista.

### Sub-agentes como "bolsas desechables de memoria"

- No son "personas" ni roles. Son una herramienta arquitectónica para gestión de recursos.
- **Resuelven el problema del test runner**: ejecutar tests en el agente principal contamina su contexto. Delegar a un sub-agente mantiene al padre en zona inteligente.
- **Modelo mental: futures/promises** — computaciones diferidas, no resultados inmediatos.
- **Modelo de actores** (Erlang/OTP): cada contexto es un actor aislado, mensajes entre agentes transportan resultados, no datos crudos.
- **Interfaz de comunicación mínima** entre padre e hijo.

### Implicaciones para el CLAUDE.md

- El CLAUDE.md compite por espacio en el contexto con todo lo demás.
- **200-400 líneas es el sweet spot**: suficiente para lo importante, no tanto que desplace al código.
- Información que Claude puede descubrir leyendo código → no ponerla en el CLAUDE.md.
- Información que Claude NO puede inferir (gotchas, reglas de negocio, patrones anti-intuitivos) → sí ponerla.

## Acción

- Mantener CLAUDE.md en 200-400 líneas (zona inteligente)
- Usar sub-agentes (Agent tool) para tareas que producen mucho output (tests, búsquedas, análisis)
- No saturar el contexto con specs completas — referenciar archivos, no copiar contenido
- Diseñar la comunicación entre agentes como paso de mensajes mínimo

## Aplicado en

- Framework Capa 1: CLAUDE.md template con tamaño óptimo documentado
- Protocolo interno: sección "Qué NO poner en el CLAUDE.md"
- Protocolo interno: regla de "zona inteligente" al 40%
