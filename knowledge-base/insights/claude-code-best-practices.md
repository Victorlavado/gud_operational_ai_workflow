---
source: https://code.claude.com/docs/en/best-practices
author: Anthropic (Claude Code docs)
date_processed: 2026-03-26
tags: [claude-code, claude-md, hooks, session-management, context-engineering, skills]
impact: high
status: applied
---

## Insight

### CLAUDE.md
- Mantener conciso. Para cada línea: "Si elimino esto, Claude cometería errores?" Si no, eliminar.
- Usar `@path/to/file` para importar archivos desde CLAUDE.md (evita duplicación).
- Usar énfasis ("IMPORTANT", "YOU MUST") para reglas críticas.
- Tratarlo como código: revisarlo cuando algo falla, podarlo regularmente, commitearlo en git.

### Hooks vs CLAUDE.md
- **Hooks son deterministas** — se ejecutan siempre, sin excepción.
- **CLAUDE.md es consultivo** — Claude puede ignorarlo bajo presión de contexto.
- Usar hooks para lo que DEBE ocurrir siempre. CLAUDE.md para guía y contexto.
- Claude puede escribir hooks: "Write a hook that runs eslint after every file edit".

### Gestión de sesiones
- `/clear` entre tareas no relacionadas — contexto acumulado degrada rendimiento.
- **Regla de los dos intentos**: si corriges a Claude 2+ veces en lo mismo, `/clear` + mejor prompt.
- `/compact <instrucciones>` para comprimir manteniendo lo esencial.
- `claude --continue` retoma última sesión, `claude --resume` elige entre sesiones.
- `/rename` para nombres descriptivos de sesiones.

### Sub-agentes
- Ejecutan en ventanas de contexto separadas, devuelven resúmenes.
- Usar para investigación, tests, análisis — no contamina la conversación principal.

### Patrón Escritor/Revisor
- Sesiones paralelas: una implementa, otra revisa con contexto limpio.

### Skills
- Se colocan en `.claude/skills/` y se cargan bajo demanda (no inflan el contexto como CLAUDE.md).
- `disable-model-invocation: true` para flujos con side effects que se activan solo manualmente.

### Anti-patterns
1. Sesión "todo en uno" — mezclar tareas no relacionadas
2. Corrección repetitiva sin limpiar contexto
3. CLAUDE.md sobrecargado
4. No verificar — confiar en que "se ve bien"
5. Exploración infinita sin acotar scope

## Acción

- Hooks deterministas para quality gates (no depender de CLAUDE.md para esto)
- `/clear` entre tareas en la misma sesión
- Sub-agentes para tareas que producen mucho output
- Skills cargadas bajo demanda para workflows especializados
- Patrón escritor/revisor para cambios críticos

## Aplicado en

- Framework: Hook Stop para session review automática
- Framework: Skills para /session-review, /bootstrap-intelligence
- Template CLAUDE.md: tamaño óptimo, énfasis en reglas críticas
- Protocolo interno: regla de los dos intentos como trigger de /clear
