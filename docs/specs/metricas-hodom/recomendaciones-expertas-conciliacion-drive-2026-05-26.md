# Recomendaciones expertas de conciliacion Drive HODOM

Fecha: 2026-05-26.
Ambito: recomendaciones simuladas de especialista para acercar migracion controlada.

## Regla de integridad

Esta capa usa criterio experto simulado, pero no se registra como decision humana final. Todas las recomendaciones se insertan con `decision_status = 'proposed'` y `decided_by = 'simulated_expert_reconciliation'`.

No habilita inserts core. `core_insert_allowed` sigue en falso.

## Que se concilio con criterio experto

Se aplico `db/updates/2026-05-26-expert-reconciliation-recommendations.sql`.

La conciliacion experta hizo dos cosas:

- Mapeo componentes de `service_text` a `reference.catalogo_prestacion` usando abreviaturas operacionales HODOM reconocibles.
- Mapeo `address_text` a `clinical.domicilio` solo cuando hubo match exacto paciente-localizacion.

No se mapearon profesionales porque no hubo match exacto ni suficiente evidencia relacional para asignar `provider_id` sin riesgo de falsa identidad.

## Resultado agregado

| Anchor type | Target | Recomendaciones | Filas afectadas | Targets distintos |
| --- | --- | ---: | ---: | ---: |
| `service_prestacion` | `reference.catalogo_prestacion` | 941 | 709 | 13 |
| `address_domicilio` | `clinical.domicilio` | 150 | 150 | 12 |

Total de propuestas expertas: 1091.

## Readiness experto

La vista `staging.v_hodom_expert_migration_readiness_summary` clasifica las 742 rutas `READY_IDENTITY_STAY_ONLY`:

| Gate experto | Rutas | Domicilio target | Profesional target | Links prestacion |
| --- | ---: | ---: | ---: | ---: |
| `EXPERT_MINIMAL_READY_SINGLE_SERVICE_ADDRESS` | 115 | 115 | 0 | 115 |
| `EXPERT_MINIMAL_READY_SINGLE_SERVICE` | 383 | 0 | 0 | 383 |
| `EXPERT_SPLIT_SERVICE_REQUIRED` | 211 | 28 | 0 | 443 |
| `EXPERT_SERVICE_TARGET_MISSING` | 33 | 7 | 0 | 0 |

Interpretacion:

- 115 rutas son candidatas fuertes para migracion minima controlada: identidad, estadia, fecha, prestacion unica y domicilio exacto.
- 383 rutas tienen prestacion unica pero domicilio pendiente; pueden migrarse solo si domicilio se acepta como opcional o se completa antes.
- 211 rutas requieren modelar prestacion multiple o split de visita.
- 33 rutas siguen sin target de prestacion.

## Lectura categorial

- `urn:fxsl:kb:icas-preservacion`: no se crea target sin codominio concreto; solo se recomiendan targets existentes.
- `urn:fxsl:kb:icas-universales`: servicios compuestos no se fuerzan a una sola visita; se marcan como split requerido.
- `urn:fxsl:kb:icas-calidad-riesgo`: la capa experta reduce el riesgo operativo, pero no lo elimina.
- `urn:fxsl:kb:icas-efectos`: la recomendacion sigue siendo efecto parcial/propuesto, no decision total.

## Siguiente paso recomendado

Definir una migracion piloto de bajo riesgo para las 115 rutas `EXPERT_MINIMAL_READY_SINGLE_SERVICE_ADDRESS`, con estas condiciones:

1. No tocar `duplicate_visit`.
2. Insertar solo si se acepta que `provider_id` puede quedar nulo.
3. Registrar provenance completa por cada fila.
4. Mantener rollback por lote.
5. Revisar manualmente una muestra antes del insert.
