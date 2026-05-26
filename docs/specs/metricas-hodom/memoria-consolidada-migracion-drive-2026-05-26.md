# Memoria consolidada migracion Drive HODOM

Fecha: 2026-05-26.
Rama: `main`.
Estado base previo a esta consolidacion: `12571a6 feat(db): add expert reconciliation recommendations`.

## Estado actual

La migracion Drive HODOM esta en fase de conciliacion previa a promocion core. Los datos nominales ya estan cargados en staging local, pero la regla vigente sigue siendo no insertar en `clinical` ni `operational` hasta que exista un contrato de promocion controlado.

Controles verificados:

| Indicador | Valor |
| --- | ---: |
| Propuestas expertas `simulated_expert_reconciliation` | 1091 |
| Rutas con target de prestacion | 709 |
| Rutas con target de domicilio | 150 |
| Rutas candidatas a piloto minimo | 115 |
| Duplicados en cola `duplicate_visit` | 3151 |
| Pares identidad-estadia con anclaje faltante | 1003 |
| Decisiones humanas efectivas | 0 |
| Filas con `core_insert_allowed = true` | 0 |

## Decisiones consolidadas

- Las propuestas simuladas no equivalen a decisiones humanas.
- `simulated_agent_reconciliation` orienta revision por candidatos unicos.
- `simulated_expert_reconciliation` agrega criterio experto simulado para prestacion y domicilio, pero sigue en `decision_status = 'proposed'`.
- No se concilio `professional_provider` porque no hubo evidencia suficiente para asignar `provider_id` sin riesgo de falsa identidad.
- La migracion piloto mas cercana son 115 rutas `EXPERT_MINIMAL_READY_SINGLE_SERVICE_ADDRESS`.
- La deuda operacional aceptable para piloto, si se decide avanzar, seria `provider_id = NULL` con provenance completa.
- `duplicate_visit` no debe tocarse en el piloto; requiere flujo separado de merge/pushout.

## Artefactos relevantes

| Artefacto | Uso |
| --- | --- |
| `docs/specs/metricas-hodom/handoff-2026-05-25.md` | Handoff historico acumulado. |
| `docs/specs/metricas-hodom/revision-conciliacion-drive-2026-05-26.md` | Revision de duplicados, identidad-estadia y semillas. |
| `docs/specs/metricas-hodom/recomendaciones-expertas-conciliacion-drive-2026-05-26.md` | Readiness experto y piloto recomendado. |
| `db/updates/2026-05-26-human-reconciliation.sql` | Tabla de decisiones y candidatos no deterministas. |
| `db/updates/2026-05-26-simulated-reconciliation-proposals.sql` | Propuestas simuladas iniciales. |
| `db/updates/2026-05-26-duplicate-visit-review.sql` | Cola de duplicados y multiplicidad many-to-one. |
| `db/updates/2026-05-26-identity-stay-review.sql` | Cola de composicion paciente-estadia. |
| `db/updates/2026-05-26-dictionary-seeds.sql` | Semillas de diccionario. |
| `db/updates/2026-05-26-expert-reconciliation-recommendations.sql` | Propuestas expertas y readiness piloto. |

## Pendientes inmediatos

1. Definir migracion piloto para las 115 rutas `EXPERT_MINIMAL_READY_SINGLE_SERVICE_ADDRESS`.
2. Crear SQL de promocion piloto no destructivo primero como `SELECT`/vista de preview.
3. Exigir provenance por fila antes de cualquier `INSERT`.
4. Decidir explicitamente si `provider_id = NULL` es aceptable para piloto.
5. Mantener fuera del piloto las 3151 propuestas `duplicate_visit`.
6. Resolver despues duplicados por prioridad: 31 prioridad 1, 2318 prioridad 2 y 802 prioridad 3.
7. Completar los 1003 casos `PAIR_MISSING_ANCHOR`.
8. Modelar servicios compuestos para las 211 rutas `EXPERT_SPLIT_SERVICE_REQUIRED`.

## Riesgos

- Tratar una propuesta simulada como aprobacion humana real generaria falsa certeza.
- Migrar duplicados sin pushout puede crear visitas paralelas incorrectas.
- Asignar profesional por texto debil puede crear falsa identidad de prestador.
- Servicios compuestos no deben colapsarse arbitrariamente a una sola prestacion.
- Exportar vistas semilla de profesionales o domicilios podria exponer informacion sensible.

## Prompt de continuacion

Continuar desde `docs/specs/metricas-hodom/memoria-consolidada-migracion-drive-2026-05-26.md` y `docs/specs/metricas-hodom/recomendaciones-expertas-conciliacion-drive-2026-05-26.md`: preparar una migracion piloto controlada para las 115 rutas `EXPERT_MINIMAL_READY_SINGLE_SERVICE_ADDRESS` usando primero una vista preview, sin tocar `duplicate_visit`, con `provider_id = NULL` solo si se acepta como deuda operacional explicita y con provenance completa por fila.
