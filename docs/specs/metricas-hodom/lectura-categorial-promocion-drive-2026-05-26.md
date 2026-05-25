# Lectura categorial promocion Drive HODOM

Fecha: 2026-05-26.
Ambito: promocion desde `staging.hodom_route_visit` hacia tablas core HODOM.

## Reformulacion

La promocion no debe tratarse como un `INSERT` directo. Debe tratarse como una traduccion parcial entre dos schemas:

- Categoria origen: filas Drive normalizadas en `staging`.
- Categoria destino: instancia core con `clinical.paciente`, `clinical.estadia`, `clinical.domicilio`, `operational.visita`, `operational.profesional`, `reference.catalogo_prestacion` y `migration.provenance`.
- Morfismo esperado: una flecha parcial desde fila de ruta a visita core candidata, con fallas explicitas.

Segun `urn:fxsl:kb:icas-preservacion`, un schema relacional puede leerse como categoria finitamente presentada y una instancia como funtor a `Set`; una migracion confiable debe preservar identidad y composicion. En este caso, la promocion solo puede avanzar si respeta las path-equivalences del core:

```text
visita -> estadia -> paciente == visita -> paciente
visita -> domicilio -> paciente == visita -> paciente
visita -> fuente/provenance existe para cada fila promovida
```

## Patron canonico aplicado

1. **Preservacion functorial** (`urn:fxsl:kb:icas-preservacion`): la fila Drive no puede crear una visita core si la traduccion no preserva las relaciones obligatorias del destino.
2. **Pullback como JOIN** (`urn:fxsl:kb:icas-universales`): el matching paciente+estadia+fecha es un pullback. Si el pullback es vacio o ambiguo, la promocion queda bloqueada.
3. **Identidad por relacion** (`urn:fxsl:kb:icas-identidad-relacion`): "mismo paciente" no se decide por texto interno de la fila, sino por su patron relacional observable en el core. Nombre normalizado exacto es una sonda insuficiente, no identidad completa.
4. **Efecto de parcialidad** (`urn:fxsl:kb:icas-efectos`): la promocion opera como flecha de Kleisli hacia `Result(CoreVisitCandidate + Error)`, no como funcion total.
5. **Riesgo como morfismo incierto** (`urn:fxsl:kb:icas-calidad-riesgo`): cada match debil o ambiguo es un morfismo con probabilidad de falla; el control correcto es estrechar cotas antes de insertar.

## Diagnostico estructural

El estado anterior `READY_CORE_VISIT` era semanticamente demasiado fuerte. Lo que esta probado por la vista de readiness es solo:

```text
route_row x_{patient_name_norm, date} clinical.estadia
```

Eso demuestra compatibilidad paciente+estadia+fecha, pero no demuestra una visita core completa. Faltan al menos tres morfismos:

- `service_text_to_prestacion_id`
- `professionals_to_provider_id`
- `address_to_domicilio_id`

Por eso se agrego `db/updates/2026-05-26-drive-promotion-contract.sql`, que re-clasifica:

| Estado anterior | Contrato nuevo |
| --- | --- |
| `READY_CORE_VISIT` | `READY_IDENTITY_STAY_ONLY` |
| `REVIEW_EXISTING_CORE_VISIT_SAME_DAY` | `REVIEW_DUPLICATE_PUSHOUT_REQUIRED` |
| `BLOCKED_*` | Se mantiene bloqueado |

## Resultado aplicado

| Gate | Filas |
| --- | ---: |
| `READY_IDENTITY_STAY_ONLY` | 742 |
| `REVIEW_DUPLICATE_PUSHOUT_REQUIRED` | 6293 |
| `BLOCKED_NO_PATIENT_MATCH` | 9046 |
| `BLOCKED_NO_ACTIVE_STAY_MATCH` | 974 |
| `BLOCKED_AMBIGUOUS_PATIENT_MATCH` | 58 |
| `BLOCKED_MISSING_DATE` | 4 |

`core_insert_allowed = true`: 0 filas.

## Checklist de coherencia

Antes de insertar en `operational.visita`, cada fila candidata debe satisfacer:

- Identidad: una fila Drive produce a lo mas una visita candidata deterministica.
- Composicion: `visit.patient_id = stay.patient_id`.
- Domicilio: si se asigna `domicilio_id`, entonces `domicilio.patient_id = visit.patient_id`.
- Prestacion: `service_text` debe mapear a una prestacion o regla explicita de no reportabilidad.
- Profesional: cada profesional usado como `provider_id` debe existir o quedar como evidencia no-promovida.
- Provenance: cada fila promovida debe dejar `migration.provenance` con `source_file`, `source_key`, `phase` y `target_pk`.
- Duplicados: filas con visita core el mismo dia deben resolverse por pushout/deduplicacion, no por insercion paralela.

## Decision

No hay promocion core automatica en este paso. La siguiente unidad de trabajo debe construir reglas de mapping para prestacion, profesional y domicilio, y un contrato de deduplicacion para `REVIEW_DUPLICATE_PUSHOUT_REQUIRED`.

Esta conclusion es formal como diagnostico de preservacion/pullback/parcialidad; el uso exacto de nombre normalizado como sonda de identidad es una heuristica operacional, no un teorema.
