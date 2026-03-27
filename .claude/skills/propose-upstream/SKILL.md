---
name: propose-upstream
description: Envía propuestas de mejora descubiertas en el proyecto actual al framework gud_operational_ai_workflows via GitHub Issues.
disable-model-invocation: false
---

# Propose Upstream

Envía las propuestas acumuladas en `.claude/.upstream-proposals` al repositorio del framework como GitHub Issues, para que el maintainer las revise e incorpore.

## Prerrequisitos

- `gh` CLI autenticado (`gh auth status` debe funcionar)
- Archivo `.claude/.upstream-proposals` con al menos una propuesta

## Proceso

### 1. Verificar entorno

```bash
gh auth status
```

Si `gh` no está autenticado, informar al usuario y salir:
```
Para usar /propose-upstream necesitas autenticarte con GitHub CLI:
  gh auth login
```

### 2. Leer propuestas pendientes

Lee `.claude/.upstream-proposals`. Si no existe o está vacío:
```
No hay propuestas upstream pendientes. Las propuestas se generan automáticamente durante /session-review cuando se detectan hallazgos universales.
```

### 3. Presentar propuestas al usuario

Para CADA propuesta en el archivo, muestra:

```markdown
### Propuesta: [Título]

**Tipo**: [gotcha | pattern | anti-pattern | fix]
**Afecta**: [componente del framework]
**Descripción**: [resumen]

¿Enviar como Issue? [Sí / Modificar / Descartar]
```

Espera la decisión del usuario para CADA propuesta. Dos checkpoints humanos es intencional (aquí + maintainer review).

### 4. Crear GitHub Issues

Para cada propuesta aprobada (o modificada), ejecuta:

```bash
gh issue create \
  -R Victorlavado/gud_operational_ai_workflows \
  --title "[upstream] [título de la propuesta]" \
  --body "$(cat <<'EOF'
## Propuesta upstream desde proyecto

**Proyecto origen**: [nombre del directorio actual]
**Tipo**: [tipo]
**Afecta**: [componente]

## Descripción

[descripción completa]

## Cambio sugerido

[lo que debería cambiar en el framework]

## Evidencia

[qué pasó en la sesión que reveló esto]

---
_Generado automáticamente por `/propose-upstream`_
EOF
)"
```

### 5. Limpiar propuestas procesadas

- Las propuestas aprobadas y enviadas: **eliminar** del archivo
- Las propuestas descartadas: **eliminar** del archivo
- Las propuestas que el usuario pide mantener para más tarde: **conservar**
- Si todas las propuestas se procesaron, eliminar el archivo `.claude/.upstream-proposals`

### 6. Resumen

Muestra un resumen al finalizar:

```
Propuestas upstream procesadas:
  ✓ Enviadas: N (issues #XX, #YY)
  ✗ Descartadas: M
  ⏸ Pendientes: P
```

## Límites de seguridad

- **Máximo 5 issues por ejecución** — si hay más propuestas, procesar en batches
- **Solo Issues** — nunca crear PRs automáticamente
- **Prefijo "[upstream]"** en el título — para que el maintainer pueda filtrar
- **Sin secrets** — solo usa la autenticación existente de `gh`
- **Diseñado para open source** — cualquier usuario crea issues, el maintainer revisa
