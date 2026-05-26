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
python3 -m unittest discover -s scripts -p 'test_*.py'
```
