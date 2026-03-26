Procesa todas las URLs pendientes en inbox.md en batch, aplicando los filtros de calidad del framework.

## Instrucciones

### 1. Leer el inbox

Lee `inbox.md` en la raíz de este repo. Extrae todas las URLs con sus notas.

Si el inbox está vacío (solo tiene el header y el ejemplo comentado), informa al usuario:
```
El inbox está vacío. Añade URLs desde cualquier dispositivo editando inbox.md.
```

### 2. Procesar cada URL

Para cada URL encontrada, ejecuta el pipeline de procesamiento de `protocols/external-intelligence.md`:

1. **Obtener contenido** via WebFetch o WebSearch
2. **Aplicar filtro de calidad**: ¿builder o hype? ¿accionable o teórico? ¿reproducible?
3. **Extraer insight** si pasa el filtro

Usa agentes en paralelo para procesar múltiples URLs simultáneamente (máximo 5 en paralelo para no saturar).

### 3. Presentar resultados en batch

Muestra todos los resultados juntos:

```markdown
# Inbox Processing — [YYYY-MM-DD]

## Procesados: [N] URLs

### Aprobados (pasan el filtro)

#### 1. [Título] — [URL]
**Autor**: [Quién]
**Nota original**: [Lo que Victor escribió al guardarlo]
**Resumen**: [3-5 bullets]
**Acción propuesta**: [Qué cambiar en el workflow/framework]
**Impacto**: [high/medium/low]

[Repetir para cada URL aprobada]

### Descartados

- [URL] — [Motivo de descarte en una línea]

### Acciones pendientes

- [ ] Crear insight: [título] → knowledge-base/insights/
- [ ] Actualizar framework: [qué cambiar y dónde]
- [ ] Añadir fuente curada: [perfil/blog] (si apareció 3+ veces con calidad)
```

### 4. Esperar decisiones del usuario

Para cada acción pendiente, espera confirmación:
- **Aplicar todas** — procesa todo en batch
- **Revisar una a una** — pregunta por cada acción
- **Descartar todas** — limpiar inbox sin guardar nada

### 5. Ejecutar acciones confirmadas

- Crear archivos de insight en `knowledge-base/insights/` con formato estándar
- Actualizar artefactos del framework si corresponde
- Añadir nuevas fuentes curadas si se identificaron

### 6. Limpiar el inbox

Después de procesar, limpia el inbox eliminando las URLs procesadas.
Mantén el header y el formato del archivo intacto.

Resultado final del inbox:

```markdown
# Inbox

Añade URLs aquí desde cualquier dispositivo. Formato: `- <url> — [nota breve]`
Procesa con `/process-inbox` cuando te sientes a trabajar.

---

<!-- Procesado el [YYYY-MM-DD]: [N] URLs procesadas, [M] insights creados -->
```
