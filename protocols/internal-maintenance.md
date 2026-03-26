# Protocolo de Mantenimiento Interno

Cómo mantener vivo el CLAUDE.md de un proyecto a partir del trabajo diario.

## Principio

> El CLAUDE.md es código, no documentación. Si no está actualizado, el agente produce basura.
> Trátalo con la misma urgencia que un test roto.

---

## Triggers de actualización

### Inmediato (en la misma sesión)

| Evento | Acción en CLAUDE.md |
|--------|---------------------|
| Descubres un gotcha nuevo | Añadir a `## Gotchas` con descripción y mitigación |
| Un error se repite 2+ veces | Añadir a `## Gotchas > Critical` |
| Claude genera código que viola un patrón | Añadir a `## Patterns > Anti-patterns` |
| Cambias una regla de negocio | Actualizar `## Domain > Business rules` |
| Añades una dependencia nueva al stack | Actualizar `## Architecture > Stack` |
| Cambias comandos de build/test/deploy | Actualizar `## Commands` |

### Al final de cada sesión

- Revisar si algún gotcha descubierto durante la sesión falta en el CLAUDE.md
- Si se estableció un patrón nuevo (usado en 2+ lugares), documentarlo
- Si un quality gate cambió, actualizarlo

### Post-mortem (cuando algo sale mal)

Cuando un error significativo ocurre (tiempo perdido > 30 min, bug en prod, merge conflict grave):

1. **Identificar la causa raíz**: ¿Por qué Claude hizo lo que hizo?
2. **¿Faltaba información en el CLAUDE.md?**: Si sí, añadirla
3. **¿Claude ignoró información existente?**: Si sí, reformular la sección para que sea más directa
4. **¿Es un patrón recurrente?**: Si sí, añadir a Anti-patterns con ejemplo

---

## Cómo escribir para Claude

### Reglas de redacción

1. **Imperativo directo**: "Siempre reconstruye los containers después de cambiar código Python" — no "Es recomendable reconstruir..."
2. **Consecuencia explícita**: "Si no haces X, pasará Y" — Claude responde mejor cuando entiende el impacto
3. **Ejemplo concreto**: Cuando sea posible, incluir el comando exacto o el snippet de código
4. **Sin ambigüedad**: "Usa `model_dump_json()`, no `model_dump()`" — no "Prefiere serialización JSON"

### Peso del contenido

Claude da peso al CLAUDE.md, pero también lee el código. Para evitar conflictos:

- Si el CLAUDE.md contradice el código actual, **el código gana** — actualiza el CLAUDE.md
- Si una spec .md contradice el código, **el código gana** — marca la spec como desactualizada
- Las secciones más arriba en el archivo tienen más peso implícito — pon lo crítico primero

### Tamaño óptimo

- **Target**: 200-400 líneas. Suficiente para cubrir lo importante, no tanto que se diluya.
- **Zona de peligro**: >600 líneas. Claude empieza a perder detalles. Mover contenido extenso a archivos referenciados.
- **Principio de Latent Patterns**: La "zona inteligente" del contexto está al ~40% de utilización. No satures el CLAUDE.md con información que Claude puede descubrir leyendo el código.

---

## Qué NO poner en el CLAUDE.md

- **Documentación de API** — Claude la lee del código
- **Historial de cambios** — eso es git log
- **Tutoriales** — el CLAUDE.md es para un agente, no para onboarding de humanos
- **Specs completas** — referencia al archivo, no copies el contenido
- **Código extenso** — pon la ruta al archivo canónico, no el snippet

---

## Checklist de salud mensual

Cada mes, revisa el CLAUDE.md con estas preguntas:

- [ ] ¿Todas las gotchas siguen siendo relevantes? (eliminar las obsoletas)
- [ ] ¿Los comandos funcionan? (ejecutarlos y verificar)
- [ ] ¿Los patrones reflejan el código actual? (comparar con el repo)
- [ ] ¿Hay gotchas nuevas que descubriste y no documentaste?
- [ ] ¿El stack cambió? (nuevas dependencias, versiones)
- [ ] ¿El tamaño está en la zona óptima? (200-400 líneas)
