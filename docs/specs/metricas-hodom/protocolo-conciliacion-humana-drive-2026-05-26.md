# Protocolo de conciliacion humana Drive HODOM

Fecha: 2026-05-26.
Ambito: candidatos de rutas Drive antes de promocion a `operational.visita`.

## Regla principal

Ningun match automatico se considera verdad operacional. Todo match es un candidato relacional que debe quedar aprobado, rechazado o marcado como no aplicable por decision humana antes de cualquier promocion core.

Esto materializa cinco criterios:

- No determinismo: una fila puede tener cero, uno o muchos candidatos.
- Conciliacion humana: la decision vive en `staging.hodom_reconciliation_decision`.
- Anclaje relacional: se aprueban relaciones especificas, no filas completas.
- Duplicados como pushout: una fila que coincide con una visita existente requiere decision de merge/deduplicacion.
- Provenance obligatoria: toda decision y futura promocion debe poder rastrearse a fuente, fila, regla y decisor.

## Lectura categorial

- `urn:fxsl:kb:icas-enriquecimiento`: los matches se modelan como relaciones enriquecidas, no como booleanos simples. El score o evidencia mide fuerza del morfismo, pero no reemplaza la decision.
- `urn:fxsl:kb:icas-efectos`: el matching opera como no-determinismo y parcialidad; una fila produce una lista de candidatos o errores, no un unico destino.
- `urn:fxsl:kb:icas-identidad-relacion`: identidad se decide por patron de relaciones observable; nombre, fecha o direccion son sondas, no identidad plena.
- `urn:fxsl:kb:icas-universales`: duplicados y coincidencias mismo-dia deben resolverse como pushout/merge, no como inserciones paralelas.
- `urn:fxsl:kb:icas-calidad-riesgo`: cada match ambiguo es riesgo de composicion; la conciliacion humana estrecha la cota antes de promover.

## Artefactos

- `db/updates/2026-05-26-human-reconciliation.sql`: DDL de decisiones humanas y vistas agregadas.
- `staging.hodom_reconciliation_decision`: tabla de decisiones humanas.
- `staging.v_hodom_route_reconciliation_candidate`: candidatos relacionales sin datos nominales exportables.
- `staging.v_hodom_route_reconciliation_candidate_summary`: conteos agregados seguros.
- `staging.v_hodom_route_reconciliation_human_gate`: gate por fila de ruta; mantiene `core_insert_allowed = false`.
- `staging.v_hodom_reconciliation_simulated_proposal_summary`: conteos agregados de propuestas simuladas no vinculantes.

## Tipos de anclaje

| Anchor type | Pregunta humana |
| --- | --- |
| `patient_identity` | Esta fila de ruta corresponde a este paciente core, o requiere crear/corregir identidad? |
| `active_stay` | Esta fila pertenece a esta estadia activa, o hay brecha temporal/episodica? |
| `service_prestacion` | Este texto de servicio mapea a esta prestacion o regla REM? |
| `professional_provider` | Este nombre/rol corresponde a este profesional core o queda como evidencia no-promovida? |
| `address_domicilio` | Esta direccion corresponde a este domicilio vigente o requiere nuevo anclaje? |
| `duplicate_visit` | Esta fila es duplicado, complemento o visita distinta respecto de una visita core existente? |
| `visit_date` | La fecha inferida desde hoja/fila es aceptable o debe corregirse? |

## Resultado agregado inicial

| Anchor type | Estado | Target | Candidatos | Filas afectadas |
| --- | --- | --- | ---: | ---: |
| `active_stay` | `NEEDS_HUMAN_ANCHOR` | `clinical.estadia` | 974 | 974 |
| `active_stay` | `NEEDS_HUMAN_CONFIRMATION` | `clinical.estadia` | 7064 | 7064 |
| `address_domicilio` | `NEEDS_MAPPING_RULE` | `clinical.domicilio` | 742 | 742 |
| `duplicate_visit` | `NEEDS_HUMAN_ANCHOR` | `operational.visita` | 6293 | 6293 |
| `duplicate_visit` | `NEEDS_HUMAN_REVIEW` | `operational.visita` | 10680 | 6293 |
| `patient_identity` | `NEEDS_HUMAN_ANCHOR` | `clinical.paciente` | 9104 | 9104 |
| `patient_identity` | `NEEDS_HUMAN_CONFIRMATION` | `clinical.paciente` | 8009 | 8009 |
| `professional_provider` | `NEEDS_MAPPING_RULE` | `operational.profesional` | 742 | 742 |
| `service_prestacion` | `NEEDS_MAPPING_RULE` | `reference.catalogo_prestacion` | 742 | 742 |
| `visit_date` | `NEEDS_HUMAN_ANCHOR` | sin target | 4 | 4 |

Totales:

- Candidatos relacionales: 44354.
- Filas de ruta cubiertas por gate humano: 17117.
- Decisiones humanas aprobadas iniciales: 0.
- Filas autorizadas para insert core: 0.

## Simulacion no vinculante

La simulacion aplicada el 2026-05-26 genero propuestas `proposed`, no decisiones finales:

| Anchor type | Propuestas | Criterio |
| --- | ---: | --- |
| `active_stay` | 7064 | Target de estadia unico con `target_pk` concreto. |
| `duplicate_visit` | 3151 | Visita core unica mismo paciente-mismo dia. |
| `patient_identity` | 8009 | Target de paciente unico con `target_pk` concreto. |

Estas propuestas pueden ordenar la revision humana, pero no deben tratarse como aprobacion. La promocion core sigue bloqueada hasta que una persona responsable convierta cada caso necesario en decision final.

## Reglas operativas

1. No elegir automaticamente el candidato con mayor cercania.
2. No colapsar duplicados sin decision `duplicate_visit`.
3. No crear paciente, domicilio, profesional o prestacion desde una sola sonda textual.
4. Mantener decisiones negativas (`not_same_as`, `does_not_map_to`, `distinct_from`) porque tambien reducen ambiguedad.
5. Toda aprobacion debe tener `decided_by`, `decided_at`, `rationale` y evidencia minima.
6. La promocion futura debe consumir solo decisiones `approved`; las candidatas no aprobadas no son insumo core.

## Siguiente paso

Construir una interfaz o lote de revision para grupos pequenos:

1. `service_prestacion` para las 742 filas `READY_IDENTITY_STAY_ONLY`.
2. `duplicate_visit` para las 6293 filas con visita core el mismo dia.
3. `patient_identity` para los 9104 casos sin anclaje automatico.

El orden recomendado es prestaciones primero, porque es el mapeo mas acotado y no requiere exponer nombres o direcciones en artefactos versionados.
