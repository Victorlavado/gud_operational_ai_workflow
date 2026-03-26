---
source: https://www.latent.space/p/reviews-dead
author: Ankit Jain (Latent Space)
date_processed: 2026-03-26
tags: [code-review, spec-first, upstream-review, quality-layers]
impact: high
status: actionable
---

## Insight

### La revisión de código tradicional está muerta

- Equipos con alta adopción de IA fusionan 98% más PRs, pero tiempos de revisión 91% más largos.
- Incluso antes de IA, las revisiones eran superficiales: aprobaciones automáticas y diffs apenas leídos.
- Al volumen actual, la revisión línea por línea es matemáticamente imposible.

### Modelo del Queso Suizo: 5 capas de defensa

Ninguna capa es perfecta sola, pero apiladas cubren los fallos:

1. **Generación competitiva** — Múltiples agentes generan soluciones, se rankean por: tests pasados, tamaño del diff, dependencias introducidas.
2. **Barreras deterministas** — Linters personalizados, invariantes organizacionales, contratos de dominio. Verificación objetiva, no juicio subjetivo.
3. **BDD (Behavior-Driven Development)** — Specs en lenguaje natural → tests automáticos ANTES de generar código. Humanos definen "qué es correcto", agentes implementan.
4. **Arquitectura de permisos** — Acotar el alcance del agente. Triggers de escalación para auth, schemas de DB, dependencias.
5. **Verificación adversarial** — Agente separado para escribir, verificar y romper. Red team / blue team en cada cambio.

### El cambio conceptual: revisión de intención, no de código

- Humanos revisan specs, planes, restricciones y criterios de aceptación.
- El código es un artefacto derivado de la spec.
- "Buen código" en la era de IA = estandarización y consistencia > preferencias individuales.
- Nunca pidas a un LLM que verifique su propio trabajo. Pide que escriba scripts de verificación objetivos.

## Acción

- Definir criterios de aceptación ANTES de generar código, no después
- Implementar quality gates como barreras deterministas (ya en template CLAUDE.md)
- Mover revisión a posición upstream: revisar spec + tests, no diffs
- Explorar generación competitiva (múltiples agentes para el mismo problema) en Capa 4
- Explorar verificación adversarial como skill/hook en proyectos críticos

## Aplicado en

- Framework Capa 1: Quality Gates como "barreras deterministas"
- Framework Capa 2 (futuro): Spec-First Development como workflow principal
- Template CLAUDE.md: sección Quality Gates con tests obligatorios antes de commit
