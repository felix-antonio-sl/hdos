# Plan migracion staging Drive HODOM 2026-05-25

Plan operativo ejecutado para migrar las fuentes Drive HODOM a PostgreSQL local mediante staging auditable.

**Objetivo:** cargar las tres carpetas Drive HODOM en PostgreSQL usando tablas `staging` y snapshots `reporting`, sin sobrescribir tablas clinicas core.

**Arquitectura:** mantener descargas crudas y SQL nominal generado en `.tmp/`, versionar solo codigo, DDL y documentacion, y cargar registros parseados en `staging`. Las rutas y entregas de turno contienen datos identificables y quedan solo en base local.

**Stack:** Python standard library, `openpyxl`, `python-docx`, `psql` local, PostgreSQL JSONB, `reporting.rem_a21_c1_snapshot` y `migration.provenance`.

---

## Tarea 1: DDL staging

**Files:**
- Create: `db/updates/2026-05-25-drive-staging-migration.sql`
- Test: `scripts/test_drive_staging_migration.py`

- [x] **Paso 1: escribir prueba DDL roja**

```python
def test_drive_staging_sql_defines_idempotent_tables(self):
    sql = Path("db/updates/2026-05-25-drive-staging-migration.sql").read_text()
    self.assertIn("CREATE SCHEMA IF NOT EXISTS staging", sql)
    self.assertIn("CREATE TABLE IF NOT EXISTS staging.drive_source_file", sql)
    self.assertIn("CREATE TABLE IF NOT EXISTS staging.hodom_route_visit", sql)
    self.assertIn("CREATE TABLE IF NOT EXISTS staging.hodom_shift_handover", sql)
    self.assertIn("ON CONFLICT", sql)
```

- [x] **Paso 2: ejecutar prueba roja**

Comando: `python3 -m unittest scripts/test_drive_staging_migration.py`.
Resultado esperado: FAIL porque la migracion aun no existia.

- [x] **Paso 3: agregar DDL**

Create tables:
- `staging.drive_source_file`: one row per Drive file with folder URL, path, title, MIME type, period, checksum, dataset and JSON metadata.
- `staging.hodom_route_visit`: one row per parsed route spreadsheet visit with patient name, address, phone, professionals, service text, source row and raw JSON.
- `staging.hodom_shift_handover`: one row per turn document with date range, title, extracted text, and metadata.
- `staging.hodom_annual_metric`: aggregate annual metric rows for 2023-2025.

- [x] **Paso 4: ejecutar prueba DDL**

Comando: `python3 -m unittest scripts/test_drive_staging_migration.py`.
Resultado: PASS para aserciones DDL.

## Tarea 2: Parser de rutas

**Files:**
- Create: `scripts/drive_staging_migration.py`
- Test: `scripts/test_drive_staging_migration.py`

- [x] **Paso 1: escribir prueba roja de parser**

```python
def test_parse_route_workbook_rows_extracts_date_and_visit_fields(self):
    path = make_route_workbook()
    rows = parse_route_workbook(path, {"drive_id": "file1", "path": "rutas/ENERO.xlsx", "year": 2026, "month": 1})
    self.assertEqual(len(rows), 1)
    self.assertEqual(rows[0]["visit_date"], "2026-01-31")
    self.assertEqual(rows[0]["patient_name"], "PACIENTE TEST")
    self.assertEqual(rows[0]["professionals"]["kine"], "KINE TEST")
```

- [x] **Paso 2: ejecutar prueba roja de parser**

Comando: `python3 -m unittest scripts/test_drive_staging_migration.py`.
Resultado esperado: FAIL porque las funciones aun no existian.

- [x] **Paso 3: implementar parser**

Implement:
- `normalize_text()`
- `month_number_from_title()`
- `make_id(prefix, value)`
- `parse_sheet_date(sheet_name, first_row, fallback_year, fallback_month)`
- `parse_route_workbook(path, source)`

The parser detects header rows containing `PACIENTE` or the standard route columns and skips collation/blank rows.

- [x] **Paso 4: ejecutar prueba parser**

Comando: `python3 -m unittest scripts/test_drive_staging_migration.py`.
Resultado: PASS.

## Tarea 3: Loader de migracion

**Files:**
- Modify: `scripts/drive_staging_migration.py`
- Test: `scripts/test_drive_staging_migration.py`

- [x] **Paso 1: escribir prueba roja de render SQL**

```python
def test_build_sql_batch_quotes_values_and_includes_route_rows(self):
    sql = build_sql_batch(
        files=[sample_file()],
        route_rows=[sample_route_row()],
        handovers=[],
        annual_metrics=[],
    )
    self.assertIn("INSERT INTO staging.drive_source_file", sql)
    self.assertIn("INSERT INTO staging.hodom_route_visit", sql)
    self.assertIn("route_visit_id", sql)
```

- [x] **Paso 2: ejecutar prueba roja de render SQL**

Comando: `python3 -m unittest scripts/test_drive_staging_migration.py`.
Resultado esperado: FAIL porque el render SQL aun no existia.

- [x] **Paso 3: implementar render SQL y CLI**

Implement:
- hardcoded source manifest for the three folder roots and known child folders;
- download/export helpers using public Drive IDs;
- workbook metadata extraction;
- DOCX text extraction for handovers;
- `build_sql_batch()`;
- `--apply` flag that executes `.tmp/drive-migration/drive-staging-load.sql` with `psql`.

- [x] **Paso 4: ejecutar pruebas**

Comando: `python3 -m unittest discover -s scripts -p 'test_*.py'`.
Resultado: 17 pruebas OK.

## Tarea 4: Aplicar y verificar

**Files:**
- Modify: `docs/specs/metricas-hodom/handoff-2026-05-25.md`
- Modify: `docs/specs/metricas-hodom/README.md`

- [x] **Paso 1: aplicar schema**

Comando: `PGPASSWORD=hodom psql 'postgresql://hodom:hodom@localhost:5555/hodom' -v ON_ERROR_STOP=1 -f db/updates/2026-05-25-drive-staging-migration.sql`.
Resultado: `COMMIT`.

- [x] **Paso 2: aplicar carga**

Comandos ejecutados: `python3 scripts/drive_staging_migration.py` y carga SQL generada con `psql`.
Resultado generado: 215 fuentes, 17117 filas de rutas, 133 entregas, 15 metricas anuales, 29 snapshots REM.

- [x] **Paso 3: verificar conteos DB**

Conteos verificados en DB:

| Tabla | Filas |
| --- | ---: |
| `staging.drive_source_file` | 215 |
| `staging.hodom_route_visit` | 17117 |
| `staging.hodom_shift_handover` | 133 |
| `staging.hodom_annual_metric` | 15 |
| `reporting.rem_a21_c1_snapshot` | 30 |
| `migration.provenance` fase `drive_staging_migration_2026_05_25` | 17509 |

- [x] **Paso 4: actualizar handoff**

Document migration status, counts, pending promotion decisions, and risks.
