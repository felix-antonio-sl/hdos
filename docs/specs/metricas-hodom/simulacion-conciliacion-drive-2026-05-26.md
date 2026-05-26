# Simulacion de conciliacion Drive HODOM

Fecha: 2026-05-26.
Ambito: propuestas no vinculantes sobre `staging.hodom_reconciliation_decision`.

## Regla de seguridad

La simulacion no reemplaza decision humana. El agente puede proponer anclajes probables, pero no puede convertirlos en autoridad operacional. Por eso todas las filas generadas por `db/updates/2026-05-26-simulated-reconciliation-proposals.sql` quedan con `decision_status = 'proposed'`.

Ninguna propuesta simulada habilita insercion o actualizacion en tablas core.

## Lectura categorial

- `urn:fxsl:kb:icas-efectos`: la conciliacion es una flecha parcial/no determinista; la simulacion solo elige ramas candidatas.
- `urn:fxsl:kb:icas-identidad-relacion`: se propone identidad cuando el patron relacional observado tiene target unico, no por igualdad textual tomada como verdad plena.
- `urn:fxsl:kb:icas-preservacion`: solo se proponen relaciones con `target_pk` concreto para no colapsar morfismos distintos.
- `urn:fxsl:kb:icas-calidad-riesgo`: las propuestas estrechan el espacio de revision, pero no cierran el riesgo.

## Criterio de simulacion

Se generan propuestas solo cuando se cumplen todas estas condiciones:

1. Existe `target_pk` concreto.
2. Hay exactamente un target distinto para la combinacion `anchor_type`, `source_table`, `source_pk` y `relation_type`.
3. El tipo de anclaje pertenece a uno de estos grupos:
   - `patient_identity`
   - `active_stay`
   - `duplicate_visit`
4. El estado candidato es `NEEDS_HUMAN_CONFIRMATION` o `NEEDS_HUMAN_REVIEW`.

No se simulan propuestas para:

- `service_prestacion`, porque falta `prestacion_id` concreto.
- `professional_provider`, porque falta `provider_id` concreto.
- `address_domicilio`, porque falta `domicilio_id` concreto.
- `visit_date`, porque requiere correccion de fuente.
- `patient_identity` o `active_stay` sin target.

## Resultado aplicado

La migracion inserto 18224 propuestas simuladas:

| Anchor type | Relacion | Target | Estado | Riesgo | Propuestas | Filas afectadas |
| --- | --- | --- | --- | --- | ---: | ---: |
| `active_stay` | `same_as` | `clinical.estadia` | `proposed` | `medium_requires_confirmation` | 7064 | 7064 |
| `duplicate_visit` | `duplicate_of` | `operational.visita` | `proposed` | `high_requires_merge_decision` | 3151 | 3151 |
| `patient_identity` | `same_as` | `clinical.paciente` | `proposed` | `medium_requires_confirmation` | 8009 | 8009 |

Control posterior:

| Indicador | Valor |
| --- | ---: |
| Propuestas simuladas | 18224 |
| Decisiones efectivas humanas | 0 |
| Rutas bajo gate humano | 17117 |
| Filas con `core_insert_allowed = true` | 0 |

## Interpretacion operativa

Estas filas sirven para ordenar el trabajo humano:

1. Revisar primero `duplicate_visit` por riesgo alto de merge/pushout.
2. Confirmar `patient_identity` y `active_stay` por lotes, usando trazabilidad local en base y sin exportar nominales.
3. Construir diccionarios o reglas explicitas para `service_prestacion`, `professional_provider` y `address_domicilio`.

La regla sigue siendo: una propuesta simulada puede orientar revision, pero solo una persona responsable debe cambiarla a una decision final.
