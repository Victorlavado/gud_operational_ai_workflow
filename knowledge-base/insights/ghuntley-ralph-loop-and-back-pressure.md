---
source: https://ghuntley.com/loop/ , https://ghuntley.com/pressure/
author: Geoffrey Huntley (@GeoffreyHuntley)
date_processed: 2026-03-26
tags: [agent-orchestration, back-pressure, ralph-loop, context-management]
impact: high
status: applied
---

## Insight

### El Ralph Loop: unidad fundamental del desarrollo con IA

Un bucle donde el agente realiza **una sola tarea por iteración** con contexto fresco:

1. **Una tarea por ciclo.** No sobrecargar al agente con múltiples objetivos simultáneos.
2. **El software es arcilla.** Cuando algo sale mal, se vuelve a la rueda del alfarero. No aferrarse a la arquitectura.
3. **Tres modos**: forward (construir), reverse (verificar/limpiar), brute force (validación exhaustiva).
4. **Primero manual, luego automatizado.** Practica el loop con CTRL+C para pausar y evaluar. Solo después sistematízalo.

### Contrapresión (back-pressure): infraestructura esencial

Sin contrapresión automatizada, los agentes se desvían en tareas de horizonte largo.

- **La ingeniería de software con IA consiste en prevenir escenarios de fallo** mediante retroalimentación estructurada.
- **Formas concretas de contrapresión**: compilación estricta, linters, tests automáticos, validación de tipos, hooks pre-commit.
- **Sin contrapresión → drift garantizado.**

### Ingeniería de contexto via specs

- Comprimir funcionalidad en specs Markdown (`/specs/*.md`) con citaciones al código fuente.
- Las specs sirven como memoria persistente entre iteraciones (el agente las lee del disco, no las recuerda).
- Las citaciones permiten al agente usar `file_read` para estudiar la implementación bajo demanda.

### "Sobre el loop" vs "en el loop"

- No aprobar cada cambio individualmente. Supervisar el flujo.
- Observar la inferencia es el mecanismo de aprendizaje.
- Los LLMs son espejos de la competencia del operador.

## Acción

- Monotarea en cada iteración de plan (un feature, un fix, una refactor — no mezclar)
- Quality gates obligatorias en CLAUDE.md (tests, lint, types) como back-pressure automática
- Specs con citaciones a archivos/líneas como contexto para el agente
- Posición de supervisión: revisar el proceso de generación, no solo el output

## Aplicado en

- Framework Capa 1: CLAUDE.md template incluye sección Quality Gates como back-pressure
- Framework Capa 1: Principio "one task per cycle" en CLAUDE.md del repo
- Protocolo interno: triggers de actualización como back-pressure sobre el CLAUDE.md
