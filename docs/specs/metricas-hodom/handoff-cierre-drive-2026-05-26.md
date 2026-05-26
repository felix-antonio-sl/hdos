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
| Estadias core | 853 |
| Estadias creadas desde INGRESOS | 36 |
| Estadias resueltas desde INGRESOS | 18 |
| Word-overlap V2 materializado | 3,197 filas |
| Campos enriquecidos por duplicados V2 | 25 |
| Provenance migracion 2026 core | 9,903 filas |

## Decisiones ejecutadas

- Los 288 `BLOCKED_NO_ACTIVE_STAY_MATCH` del contrato exacto se trataron con INGRESOS como fuente temporal:
  - 17 estadias abiertas creadas desde filas `ACTIVO` sin egreso.
  - 1 estadia existente extendida usando `daterange &&`.
  - 2 rutas quedaron sin ancla INGRESOS y no se forzaron.
- El contrato flexible V2 quedo materializado en `staging.hodom_patient_word_overlap_match_2026` y expuesto como `staging.v_hodom_route_promotion_contract_v2`.
- Se normalizaron 7 nombres de `clinical.paciente` desde INGRESOS solo con candidato unico y regla de subconjunto estricto.
- Se reejecuto `drive-new-visits-2026.sql` tras corregir su orden de `DROP VIEW`; no inserto visitas nuevas, pero reparo provenance faltante para visitas ya existentes.
- Se aplico enriquecimiento seguro de duplicados V2 sobre visitas core existentes: 25 campos trazados en `v2_duplicate_enrichment_2026_05_26`. No se insertaron visitas nuevas.

## Pendientes

| Frente | Pendiente |
| --- | --- |
| V2 estadias | Resolver 38 `BLOCKED_NO_ACTIVE_STAY_MATCH` con ancla temporal adicional. |
| V2 identidad | Resolver 177 `BLOCKED_NO_PATIENT_MATCH` y 156 ambiguos con RUT/SGH o revision humana. |
| Servicios | Mapear `service_prestacion` para 287 `READY_IDENTITY_STAY_ONLY` V2 antes de insertar. |
| Duplicados | Continuar enriquecimiento solo cuando exista target core unico y valor fuente unico; no hacer merge destructivo. |
| App | Transicionar estadias creadas desde `pendiente_evaluacion` por flujo de la app cuando corresponda. |

## Supuestos

- `INGRESOS 2026 DRIVE` es fuente autoritativa para episodios 2026.
- `fecha_egreso = NULL` en filas `ACTIVO` representa episodio abierto.
- El contrato exacto queda como referencia historica; el contrato operativo recomendado es V2.
- `simulated_expert_reconciliation` y `simulated_agent_reconciliation` orientan revision; no equivalen a aprobacion humana.

## Riesgos

- V2 aumenta sensibilidad nominal y por eso tambien aumenta ambiguos; no promover sin unicidad.
- Las estadias abiertas pueden bloquear episodios futuros por exclusion `daterange &&`; deben cerrarse cuando exista egreso real.
- Hay PII en staging/core y vistas audit nominales; no exportar fuera de la BD local.
- El flujo antiguo de `drive-new-visits-2026.sql` reevalua preview varias veces para provenance; conviene compactarlo con tabla temporal en una siguiente iteracion.

## Verificacion

```bash
python3 -m unittest discover -s scripts -p 'test_*.py'
PGPASSWORD=hodom psql 'postgresql://hodom:hodom@localhost:5555/hodom' \
  -c "SELECT * FROM staging.v_hodom_migration_dashboard;"
```

Resultado verificado: 98/98 tests OK; dashboard con 853 estadias, 18 estadias resueltas desde INGRESOS, 7 pacientes normalizados, 3,197 filas V2 materializadas y 25 campos enriquecidos por duplicados V2.

## Prompt de continuacion

Continuar desde `docs/specs/metricas-hodom/handoff-cierre-drive-2026-05-26.md`. Prioridad: resolver 38 `BLOCKED_NO_ACTIVE_STAY_MATCH` del contrato V2 con anclas temporales adicionales; luego mapear `service_prestacion` para 287 `READY_IDENTITY_STAY_ONLY` V2; despues continuar enriquecimiento UPDATE de duplicados solo cuando haya target core unico y valor fuente unico. Mantener regla: conciliacion simulada orienta revision, no es aprobacion humana.
