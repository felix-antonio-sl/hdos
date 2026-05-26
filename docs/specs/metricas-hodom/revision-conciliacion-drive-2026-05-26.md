# Revision de conciliacion Drive HODOM

Fecha: 2026-05-26.
Ambito: revision no vinculante posterior a propuestas simuladas.

## Regla vigente

Las vistas de esta etapa ordenan revision humana. No aprueban, no rechazan y no escriben en tablas core. `simulated_agent_reconciliation` sigue siendo una fuente de orientacion, no una persona responsable.

## Lectura categorial

- `urn:fxsl:kb:icas-universales`: `duplicate_visit` se trata como pushout/merge; el caso many-to-one exige mas cuidado que el 1-a-1.
- `urn:fxsl:kb:icas-identidad-relacion`: `patient_identity` y `active_stay` se revisan como par composicional, no como textos independientes.
- `urn:fxsl:kb:icas-efectos`: las colas siguen siendo flechas parciales con estados de falla explicitos.
- `urn:fxsl:kb:icas-preservacion`: las semillas de diccionario no crean codominios; solo preparan targets revisables.
- `urn:fxsl:kb:icas-calidad-riesgo`: las prioridades estrechan riesgo, pero no lo cierran.

## Duplicados visita

Artefactos:

- `db/updates/2026-05-26-duplicate-visit-review.sql`
- `staging.v_hodom_duplicate_visit_review_queue`
- `staging.v_hodom_duplicate_visit_review_summary`

Resultado agregado:

| Indicador | Valor |
| --- | ---: |
| Propuestas `duplicate_visit` en cola | 3151 |
| Filas Drive distintas | 3151 |
| Visitas core distintas | 2887 |
| Coincidencias misma fecha | 3151 |
| Decisiones humanas efectivas | 0 |
| Filas autorizadas para core | 0 |

Prioridad de revision:

| Prioridad | Accion | Riesgo | Propuestas | Visitas core |
| ---: | --- | --- | ---: | ---: |
| 1 | Revisar brecha de prestacion/domicilio o brecha estructural antes de merge | `high_anchor_gap` | 31 | 29 |
| 2 | Revisar complemento de profesional antes de merge | `high_provider_gap` | 2318 | 2120 |
| 3 | Confirmar duplicado con visita core completa | `medium_duplicate_confirmation` | 802 | 738 |

Multiplicidad:

| Filas Drive por visita core | Visitas core | Propuestas |
| ---: | ---: | ---: |
| 1 | 2636 | 2636 |
| 2 | 238 | 476 |
| 3 | 13 | 39 |

## Identidad y estadia

Artefactos:

- `db/updates/2026-05-26-identity-stay-review.sql`
- `staging.v_hodom_identity_stay_review_queue`
- `staging.v_hodom_identity_stay_review_summary`

Resultado agregado:

| Estado composicional | Filas |
| --- | ---: |
| `IDENTITY_STAY_COMPOSES` | 7035 |
| `PAIR_MISSING_ANCHOR` con `PATIENT_ONLY` | 974 |
| `PAIR_MISSING_ANCHOR` con `STAY_ONLY` | 29 |
| `COMPOSITION_MISMATCH` | 0 |
| `TEMPORAL_WINDOW_MISMATCH` | 0 |

Interpretacion: el par paciente-estadia compone para 7035 rutas simuladas. Las 1003 restantes no deben avanzar hasta completar el anclaje faltante.

## Semillas de diccionario

Artefactos:

- `db/updates/2026-05-26-dictionary-seeds.sql`
- `staging.v_hodom_service_prestacion_dictionary_seed`
- `staging.v_hodom_professional_provider_dictionary_seed`
- `staging.v_hodom_address_domicilio_dictionary_seed`
- `staging.v_hodom_dictionary_seed_summary`

Alcance: solo rutas `READY_IDENTITY_STAY_ONLY`.

| Diccionario | Target | Terminos semilla | Menciones |
| --- | --- | ---: | ---: |
| `service_prestacion` | `reference.catalogo_prestacion` | 147 | 742 |
| `professional_provider` | `operational.profesional` | 24 | 1072 |
| `address_domicilio` | `clinical.domicilio` | 192 | 742 |

Distribucion de roles profesionales:

| Rol | Terminos semilla | Menciones |
| --- | ---: | ---: |
| `enfermera` | 4 | 400 |
| `kine` | 5 | 369 |
| `fono` | 5 | 168 |
| `medico` | 5 | 96 |
| `tens` | 5 | 39 |

Los valores normalizados de profesionales y domicilios viven solo en la base local. No deben exportarse a archivos versionados.

## Siguiente orden operativo

1. Resolver los 31 duplicados prioridad 1.
2. Resolver los 2318 duplicados con brecha de profesional, empezando por los 384 many-to-one.
3. Revisar los 802 duplicados completos.
4. Completar las 1003 rutas con anclaje identidad-estadia faltante.
5. Convertir semillas de diccionario en reglas revisadas, empezando por `service_prestacion` porque no contiene valores nominales personales.
