# Handoff cierre migracion Drive HODOM 2026

Fecha: 2026-05-26. Rama: `main`.

## Estado actual

Se completo el frente solicitado sobre el corte de `memoria-consolidada-migracion-drive-2026-05-26.md`:

| Indicador | Valor |
| --- | ---: |
| Rutas Drive 2026 en staging | 3,150 |
| Visitas Drive-sourced en core | 1,275 |
| Pacientes core | 733 |
| Pacientes creados desde INGRESOS | 43 |
| Pacientes normalizados desde INGRESOS | 7 |
| Estadias core | 855 |
| Estadias creadas desde INGRESOS | 36 |
| Estadias resueltas desde INGRESOS | 18 |
| Estadias sincronizadas activo/egreso desde INGRESOS | 117 |
| Estadias activas core respaldadas por INGRESOS `ACTIVO` | 19/19 |
| Word-overlap V2 materializado | 3,197 filas |
| Campos enriquecidos por duplicados V2 | 25 |
| Provenance migracion 2026 core | 10,222 filas |

## Decisiones ejecutadas

- Los 288 `BLOCKED_NO_ACTIVE_STAY_MATCH` del contrato exacto se trataron con INGRESOS como fuente temporal:
  - 17 estadias abiertas creadas desde filas `ACTIVO` sin egreso.
  - 1 estadia existente extendida usando `daterange &&`.
  - 2 rutas quedaron sin ancla INGRESOS y no se forzaron.
- El contrato flexible V2 quedo materializado en `staging.hodom_patient_word_overlap_match_2026` y expuesto como `staging.v_hodom_route_promotion_contract_v2`.
- Se normalizaron 7 nombres de `clinical.paciente` desde INGRESOS solo con candidato unico y regla de subconjunto estricto.
- Se reejecuto `drive-new-visits-2026.sql` tras corregir su orden de `DROP VIEW`; no inserto visitas nuevas, pero reparo provenance faltante para visitas ya existentes.
- Se aplico enriquecimiento seguro de duplicados V2 sobre visitas core existentes: 25 campos trazados en `v2_duplicate_enrichment_2026_05_26`. No se insertaron visitas nuevas.
- Se resincronizo la planilla viva `INGRESOS 2026 DRIVE` (731 filas; 220 RUT distintos) y se aplico `ingreso_status_sync_2026_05_26`:
  - 117 estadias tocadas con 319 campos de provenance.
  - 19 estadias quedaron `activo` con `fecha_egreso = NULL`, todas respaldadas por episodio `ACTIVO` en INGRESOS.
  - 3 estadias quedaron `fallecido` con `tipo_egreso = fallecido_esperado`.
  - 2 splits contiguos con estadia abierta fueron cerrados desde egreso fuente.
  - 2 estadias activas faltantes fueron creadas desde reingreso/episodio activo posterior al egreso.

## Pendientes

| Frente | Pendiente |
| --- | --- |
| V2 estadias | Resolver 129 `BLOCKED_NO_ACTIVE_STAY_MATCH` tras cierre oficial de estadias por INGRESOS; no reabrir pacientes solo para calzar rutas posteriores al egreso. |
| V2 identidad | Resolver 177 `BLOCKED_NO_PATIENT_MATCH` y 156 ambiguos con RUT/SGH o revision humana. |
| Servicios | Mapear `service_prestacion` para 287 `READY_IDENTITY_STAY_ONLY` V2 antes de insertar. |
| Duplicados | Continuar enriquecimiento solo cuando exista target core unico y valor fuente unico; no hacer merge destructivo. |
| INGRESOS status | Revisar 3 activos sin paciente core, 1 conflicto activo/egresado, 3 egresos sin estadia y 7 filas con fechas invalidas/review. |

## Supuestos

- `INGRESOS 2026 DRIVE` es fuente autoritativa para episodios 2026.
- `fecha_egreso = NULL` en filas `ACTIVO` representa episodio abierto.
- Cuando un egreso fuente y una fila activa apuntan a la misma estadia, el egreso documentado prevalece; si existe reingreso activo posterior, se crea una estadia nueva.
- El contrato exacto queda como referencia historica; el contrato operativo recomendado es V2.
- `simulated_expert_reconciliation` y `simulated_agent_reconciliation` orientan revision; no equivalen a aprobacion humana.

## Riesgos

- V2 aumenta sensibilidad nominal y por eso tambien aumenta ambiguos; no promover sin unicidad.
- Las estadias abiertas pueden bloquear episodios futuros por exclusion `daterange &&`; deben cerrarse cuando exista egreso real.
- Cerrar estadias desde INGRESOS aumenta rutas `BLOCKED_NO_ACTIVE_STAY_MATCH` cuando Drive contiene visitas posteriores al egreso oficial; esas rutas deben tratarse como conflicto de fuente o nuevo episodio, no como razon para mantener estadias abiertas.
- Hay PII en staging/core y vistas audit nominales; no exportar fuera de la BD local.
- El flujo antiguo de `drive-new-visits-2026.sql` reevalua preview varias veces para provenance; conviene compactarlo con tabla temporal en una siguiente iteracion.

## Verificacion

```bash
python3 -m unittest discover -s scripts -p 'test_*.py'
PGPASSWORD=hodom psql 'postgresql://hodom:hodom@localhost:5555/hodom' \
  -c "SELECT * FROM staging.v_hodom_migration_dashboard;"
```

Resultado verificado: 99/99 tests OK; dashboard con 855 estadias, 117 estadias sincronizadas activo/egreso desde INGRESOS, 19 estadias activas core respaldadas por INGRESOS `ACTIVO`, 18 estadias resueltas desde INGRESOS, 7 pacientes normalizados, 3,197 filas V2 materializadas y 25 campos enriquecidos por duplicados V2.

## Prompt de continuacion

Continuar desde `docs/specs/metricas-hodom/handoff-cierre-drive-2026-05-26.md`. Prioridad: revisar residuos de `staging.v_hodom_ingreso_status_sync_summary_2026` (3 activos sin paciente, 1 conflicto activo/egresado, 3 egresos sin estadia, 7 fechas invalidas/review); luego resolver 129 `BLOCKED_NO_ACTIVE_STAY_MATCH` V2 distinguiendo visitas posteriores a egreso oficial vs nuevos episodios. Mantener regla: conciliacion simulada orienta revision, no es aprobacion humana.
