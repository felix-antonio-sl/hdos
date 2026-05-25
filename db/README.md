# Base de Datos HODOM

## Archivos

- `hodom-integrado-pg-v4.sql`: dump PostgreSQL versionado del modelo integrado.
- `updates/2026-05-25-original-source-refresh.sql`: migracion idempotente aplicada a la base local para registrar fuentes originales, cartera HSC 2024 y snapshot REM A21 C.1 abril 2026.

## Criterio

- La base vigente de referencia es PostgreSQL.
- Este repositorio ya no conserva la salida SQLite inicial ni esquemas derivados obsoletos.
- El dump versionado sirve como artefacto de estructura y respaldo documental del estado PostgreSQL preservado en el repo.
- Las actualizaciones con datos de referencia no-PII se versionan como SQL idempotente en `db/updates/` y se pueden regenerar desde `scripts/build_original_source_update.py`.
- La actualizacion del 2026-05-25 crea/puebla:
  - `reference.original_source`
  - `reference.cartera_prestacion_hsc`
  - `reporting.rem_a21_c1_snapshot`
  - documentos/tags de fuentes en `operational.kb_documento`
  - trazabilidad en `migration.provenance`

## Reproducir actualizacion de fuentes originales

```bash
python3 -m unittest scripts/test_build_original_source_update.py
python3 scripts/build_original_source_update.py
PGPASSWORD=hodom psql 'postgresql://hodom:hodom@localhost:5555/hodom' \
  -v ON_ERROR_STOP=1 \
  -f db/updates/2026-05-25-original-source-refresh.sql
```

La carga no incluye datos identificables de pacientes. La cartera HSC se conserva en tabla separada porque su estamento/especialidad completo no cabe en el enum restringido de `reference.catalogo_prestacion`.

## Relacion documental

- La documentacion relacionada vive en [docs/README.md](/home/felix/projects/hdos/docs/README.md).
- El modelo conceptual principal vive en [modelo-integrado-hodom.md](/home/felix/projects/hdos/docs/models/modelo-integrado-hodom.md).
