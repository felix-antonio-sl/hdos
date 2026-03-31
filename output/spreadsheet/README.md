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

Columnas nuevas relevantes:

- `patient_key_strategy`: indica si la identidad quedó basada en `rut`, `nombre_fecha` o `nombre_contacto`.
- `rut_valido`: `1` si el RUT pasó validación por dígito verificador.
- `normalization_notes`: correcciones aplicadas, por ejemplo `swap_rut_fecha_nacimiento` o `invalid_rut_rejected`.

## Resultado de esta corrida

- Archivos fuente procesados: `30`
- Filas válidas leídas: `2998`
- Episodios deduplicados: `1698`
- Filas descartadas por duplicado: `1300`
- Pacientes deduplicados: `1231`
- Archivo excluido como catálogo: `NO MOD.csv`

Control de calidad adicional:

- Episodios con RUT válido: `1653`
- Episodios con RUT rechazado: `40`
- Episodios sin RUT válido pero con clave legible `nombre+fecha`: `39`
- Episodios sin RUT válido pero con clave legible `nombre+contacto`: `6`
- Correcciones `rut/fecha_nacimiento` invertidos detectadas: `71`

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
