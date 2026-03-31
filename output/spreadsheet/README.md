# Migración HODOM

Este directorio contiene una salida intermedia lista para cargar a una base nueva.

## Artefactos

- `hodom_episodios_deduplicados.csv`: episodios normalizados y deduplicados. Es la tabla principal para cargar.
- `hodom_pacientes.csv`: dimensión de pacientes construida desde los episodios deduplicados.
- `hodom_episodios_raw.csv`: todas las filas válidas normalizadas, sin deduplicar.
- `hodom_duplicados.csv`: grupos de duplicados con `duplicate_count` y `duplicate_rank`.
- `hodom_resumen_fuentes.csv`: resumen por archivo fuente.
- `hodom_reporte_migracion.json`: métricas globales de la corrida.
- `hodom_schema_postgres.sql`: DDL base para PostgreSQL.

## Resultado de esta corrida

- Archivos fuente procesados: `30`
- Filas válidas leídas: `2998`
- Episodios deduplicados: `1757`
- Filas descartadas por duplicado: `1241`
- Pacientes deduplicados: `1298`
- Archivo excluido como catálogo: `NO MOD.csv`

## Carga sugerida en PostgreSQL

1. Crear tablas:

```sql
\i /Users/felixsanhueza/Developer/_workspaces/hdos/output/spreadsheet/hodom_schema_postgres.sql
```

2. Cargar pacientes:

```sql
\copy hodom_pacientes_staging
FROM '/Users/felixsanhueza/Developer/_workspaces/hdos/output/spreadsheet/hodom_pacientes.csv'
WITH (FORMAT csv, HEADER true, ENCODING 'UTF8');
```

3. Cargar episodios:

```sql
\copy hodom_episodios_staging
FROM '/Users/felixsanhueza/Developer/_workspaces/hdos/output/spreadsheet/hodom_episodios_deduplicados.csv'
WITH (FORMAT csv, HEADER true, ENCODING 'UTF8');
```

## Regeneración

Si cambias o agregas CSV fuente, vuelve a correr:

```bash
python3 /Users/felixsanhueza/Developer/_workspaces/hdos/scripts/migrate_hodom_csv.py
```
