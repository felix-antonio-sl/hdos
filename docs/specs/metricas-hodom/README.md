# Especificaciones metricas HODOM

Este directorio es la ubicacion normativa para artefactos agregados derivados de fuentes Drive HODOM antes de migracion.

## Artefactos canonicos

| Artefacto | Proposito |
| --- | --- |
| `metricas-anuales-atenciones-usuarios-2026-05-25.md` | Especificacion legible de atenciones, usuarios, ingresos y banderas de calidad 2023-2025. |
| `metricas-anuales-atenciones-usuarios-2026-05-25.json` | Version estructurada de la especificacion anual para consumo por scripts o staging. |
| `metricas-anuales-atenciones-usuarios-2026-05-25.csv` | Tabla anual compacta para revision operativa. |
| `consolidacion-fuentes-drive-2026-05-25.md` | Especificacion de inventario, cobertura, metricas REM extraidas y banderas de calidad por fuente Drive. |
| `consolidacion-fuentes-drive-2026-05-25.json` | Version estructurada de la consolidacion de fuentes. |
| `inventario-fuentes-drive-2026-05-25.csv` | Inventario tabular de archivos fuente, datasets, periodos y hashes. |
| `manifiesto-fuentes-drive-2026-05-25.json` | Manifiesto de IDs Drive, rutas fuente y clasificacion. |
| `plan-drive-staging-migration-2026-05-25.md` | Plan ejecutado para migracion staging de las tres carpetas Drive a PostgreSQL local. |
| `handoff-2026-05-25.md` | Estado actual, decisiones, pendientes, supuestos, riesgos y prompt de continuidad para migracion. |
| `../../../db/updates/2026-05-25-drive-staging-migration.sql` | DDL normativo e idempotente para `staging` y trazabilidad de carga Drive. |
| `plan-drive-promotion-readiness-2026-05-26.md` | Plan ejecutado para evaluar readiness de promocion desde staging hacia core. |
| `../../../db/updates/2026-05-26-drive-promotion-readiness.sql` | Vistas no destructivas de matching, calidad y readiness antes de promocion core. |
| `lectura-categorial-promocion-drive-2026-05-26.md` | Diagnostico categorial de preservacion, pullbacks, parcialidad y gates de promocion. |
| `../../../db/updates/2026-05-26-drive-promotion-contract.sql` | Contrato no destructivo que degrada readiness a gates seguros antes de inserts core. |
| `protocolo-conciliacion-humana-drive-2026-05-26.md` | Protocolo normativo de candidatos no deterministas, anclajes relacionales y decision humana. |
| `../../../db/updates/2026-05-26-human-reconciliation.sql` | Tabla de decisiones humanas y vistas de candidatos/gates de conciliacion. |
| `simulacion-conciliacion-drive-2026-05-26.md` | Resultado normativo de propuestas simuladas no vinculantes para ordenar revision humana. |
| `../../../db/updates/2026-05-26-simulated-reconciliation-proposals.sql` | Inserta propuestas `proposed` con target unico; no promueve a core ni crea decisiones humanas efectivas. |
| `revision-conciliacion-drive-2026-05-26.md` | Revision agregada de duplicados, composicion identidad-estadia y semillas de diccionario. |
| `../../../db/updates/2026-05-26-duplicate-visit-review.sql` | Vistas de cola/resumen para revisar pushout de duplicados de visita. |
| `../../../db/updates/2026-05-26-identity-stay-review.sql` | Vistas de cola/resumen para revisar composicion paciente-estadia. |
| `../../../db/updates/2026-05-26-dictionary-seeds.sql` | Vistas semilla para diccionarios de prestacion, profesional y domicilio. |
| `recomendaciones-expertas-conciliacion-drive-2026-05-26.md` | Recomendaciones simuladas de especialista para acercar migracion controlada. |
| `../../../db/updates/2026-05-26-expert-reconciliation-recommendations.sql` | Inserta propuestas expertas `proposed` para prestacion y domicilio, y resume readiness experto. |
| `memoria-consolidada-migracion-drive-2026-05-26.md` | Memoria consolidada de estado, decisiones, artefactos, pendientes y prompt de continuidad. |
| `../../../db/updates/2026-05-26-drive-pilot-migration.sql` | Piloto inicial: 115 visitas con servicio + domicilio en `operational.visita`. |
| `../../../db/updates/2026-05-26-professional-reconciliation.sql` | Conciliacion de profesionales Drive vs `operational.profesional`: 62 propuestas, vistas de scoring. |
| `../../../db/updates/2026-05-26-drive-enrichment-2026.sql` | Enriquecimiento UPDATE de 1,065 visitas core 2026 con provider_id y hora del Drive. |
| `../../../db/updates/2026-05-26-drive-new-visits-2026.sql` | Insercion de 333 visitas nuevas 2026 (READY_IDENTITY_STAY_ONLY sin visita core). |
| `../../../db/updates/2026-05-26-fuzzy-patient-match-2026.sql` | Fuzzy matching de identidad paciente: 30 propuestas, 335 rutas desbloqueadas. |
| `../../../scripts/test_drive_pilot_migration.py` | 16 tests unitarios de migracion piloto y conciliacion profesional. |

## Reglas normativas

- Los archivos crudos descargados quedan en `.tmp/` y no se versionan.
- Este directorio conserva solo metricas agregadas, inventario, hashes y trazabilidad de fuentes.
- No se exportan nombres, RUT, filas nominales ni otros datos identificables.
- Las filas nominales de rutas y entregas de turno solo pueden residir en la base local o en artefactos temporales ignorados por Git.
- Las banderas `review` bloquean migracion directa a tablas clinicas hasta validacion humana.
- Cualquier nuevo insumo Drive debe incorporarse al manifiesto y regenerar estos artefactos.

## Regeneracion

```bash
python3 scripts/drive_consolidation.py
python3 scripts/hodom_annual_metrics.py
python3 scripts/drive_staging_migration.py
PGPASSWORD=hodom psql 'postgresql://hodom:hodom@localhost:5555/hodom' -v ON_ERROR_STOP=1 -f db/updates/2026-05-26-drive-promotion-readiness.sql
PGPASSWORD=hodom psql 'postgresql://hodom:hodom@localhost:5555/hodom' -v ON_ERROR_STOP=1 -f db/updates/2026-05-26-drive-promotion-contract.sql
PGPASSWORD=hodom psql 'postgresql://hodom:hodom@localhost:5555/hodom' -v ON_ERROR_STOP=1 -f db/updates/2026-05-26-human-reconciliation.sql
PGPASSWORD=hodom psql 'postgresql://hodom:hodom@localhost:5555/hodom' -v ON_ERROR_STOP=1 -f db/updates/2026-05-26-simulated-reconciliation-proposals.sql
PGPASSWORD=hodom psql 'postgresql://hodom:hodom@localhost:5555/hodom' -v ON_ERROR_STOP=1 -f db/updates/2026-05-26-duplicate-visit-review.sql
PGPASSWORD=hodom psql 'postgresql://hodom:hodom@localhost:5555/hodom' -v ON_ERROR_STOP=1 -f db/updates/2026-05-26-identity-stay-review.sql
PGPASSWORD=hodom psql 'postgresql://hodom:hodom@localhost:5555/hodom' -v ON_ERROR_STOP=1 -f db/updates/2026-05-26-dictionary-seeds.sql
PGPASSWORD=hodom psql 'postgresql://hodom:hodom@localhost:5555/hodom' -v ON_ERROR_STOP=1 -f db/updates/2026-05-26-expert-reconciliation-recommendations.sql
PGPASSWORD=hodom psql 'postgresql://hodom:hodom@localhost:5555/hodom' -v ON_ERROR_STOP=1 -f db/updates/2026-05-26-professional-reconciliation.sql
PGPASSWORD=hodom psql 'postgresql://hodom:hodom@localhost:5555/hodom' -v ON_ERROR_STOP=1 -f db/updates/2026-05-26-fuzzy-patient-match-2026.sql
PGPASSWORD=hodom psql 'postgresql://hodom:hodom@localhost:5555/hodom' -v ON_ERROR_STOP=1 -f db/updates/2026-05-26-drive-enrichment-2026.sql
PGPASSWORD=hodom psql 'postgresql://hodom:hodom@localhost:5555/hodom' -v ON_ERROR_STOP=1 -f db/updates/2026-05-26-drive-new-visits-2026.sql
PGPASSWORD=hodom psql 'postgresql://hodom:hodom@localhost:5555/hodom' -v ON_ERROR_STOP=1 -f db/updates/2026-05-26-drive-pilot-migration.sql
python3 -m unittest discover -s scripts -p 'test_*.py'
```
