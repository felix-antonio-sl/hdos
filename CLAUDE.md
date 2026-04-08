# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

HDOS (Hospitalización Domiciliaria) is a Python data pipeline and PostgreSQL migration system for consolidating, deduplicating, and enriching home hospitalization records for Hospital San Carlos (Ñuble, Chile). Two parallel data layers exist: a 4-stage CSV pipeline and a categorical PG migration. Output feeds Streamlit dashboards and REM reports for MINSAL.

## Commands

```bash
# Run tests
.venv/bin/python -m pytest tests/ -v

# Run a single test file
.venv/bin/python -m pytest tests/test_canonical_stays.py -v

# Run a single test
.venv/bin/python -m pytest tests/test_canonical_stays.py::test_function_name -v

# Run full pipeline (stages 3+4) then dashboard
scripts/refresh_data_and_run_dashboard.sh

# Run canonical builder only (stage 4)
scripts/run_canonical_builder.sh

# Run main dashboard (port 8502)
scripts/run_streamlit_dashboard.sh

# Run admin dashboard
scripts/run_streamlit_admin_dashboard.sh

# Run migration model dashboard
scripts/run_streamlit_migration_model_dashboard.sh

# Run individual pipeline stages
.venv/bin/python scripts/migrate_hodom_csv.py          # Stage 1
.venv/bin/python scripts/build_hodom_intermediate.py    # Stage 2
.venv/bin/python scripts/build_hodom_enriched.py        # Stage 3
.venv/bin/python scripts/build_hodom_canonical.py       # Stage 4

# PostgreSQL categorical migration
.venv/bin/python scripts/migrate_to_pg/run_migration.py --db-url postgresql://hodom:hodom@localhost:5555/hodom
.venv/bin/python scripts/migrate_to_pg/run_migration.py --db-url ... --phase F2_pacientes  # single phase
.venv/bin/python scripts/migrate_to_pg/run_migration.py --db-url ... --dry-run

# Rebuild & deploy dashboard container
docker compose up -d --build

# Verify PG is alive
docker exec hodom-pg psql -U hodom -d hodom -c "SELECT count(*) FROM clinical.estadia;"

# Post-migration corrections (idempotent, run after migration)
.venv/bin/python scripts/corr_12_parsear_epicrisis_docx.py                       # Parse DOCX → epicrisis
docker exec -i hodom-pg psql -U hodom -d hodom < scripts/corr_13_catalogo_prestaciones_rem.sql  # REM catalog
.venv/bin/python scripts/corr_14_satisfaccion_usuaria.py                         # Satisfaction surveys
.venv/bin/python scripts/corr_15_entrega_kine.py                                # Kine shift handover → notas
.venv/bin/python scripts/corr_16_epicrisis_medica_pdf.py                        # Medical epicrisis PDFs

# GPS sync from NavPro.cl (automated via cron)
.venv/bin/python scripts/sync_gps_navpro.py                                      # Incremental sync (last dt+1 → yesterday)
.venv/bin/python scripts/sync_gps_navpro.py --poll                               # Poll current positions (every 30 min)
.venv/bin/python scripts/sync_gps_navpro.py --from-date 2026-01-01               # Backfill from date
.venv/bin/python scripts/sync_gps_navpro.py --device PFFF57 --dry-run            # Single vehicle, dry-run

# Auxiliary scripts
.venv/bin/python scripts/build_active_patient_packets.py    # Patient summary packets
.venv/bin/python scripts/build_hodom_admissions_minimal.py  # Minimal admission dataset
.venv/bin/python scripts/build_hodom_discharges_minimal.py  # Minimal discharge dataset
.venv/bin/python scripts/generate_hodom_clinical_updates.py # Clinical updates
```

## Architecture

### Two Data Layers

**CSV Pipeline (4 stages)** — historical, deterministic, file-based:

```
Stage 1: migrate_hodom_csv.py
  input/raw_csv_exports/ → output/spreadsheet/ (normalized rows, patients, file summary)

Stage 2: build_hodom_intermediate.py
  Stage 1 output → output/spreadsheet/intermediate/ (20 CSVs)

Stage 3: build_hodom_enriched.py
  intermediate/ + XLSX forms + DEIS + INE geodata → output/spreadsheet/enriched/ (26 CSVs)

Stage 4: build_hodom_canonical.py
  enriched/ + input/manual/ corrections → output/spreadsheet/canonical/ (12 CSVs)
```

Each stage imports the previous one as a Python module via `sys.path`. Stage 3 imports `build_hodom_intermediate` (as `core`) and `migrate_hodom_csv` (as `base`). Stage 4 imports `migrate_hodom_csv` (as `base`).

**PostgreSQL Migration (categorical)** — current source of truth:

```
scripts/migrate_to_pg/
├── run_migration.py          # CLI: --db-url, --phase, --dry-run
├── framework/
│   ├── category.py           # Functor base class + PathEquation (diagram commutativity checks)
│   ├── runner.py             # ComposedFunctor orchestrator, MigrationSources, MigrationReport
│   ├── hash_ids.py           # Deterministic ID generation
│   └── provenance.py         # Field-level provenance tracking
└── functors/                 # 13 functors: F₀ bootstrap → F₁₁ entregas turno
    ├── f0_bootstrap.py       # DDL, schema init
    ├── f1_territorial.py     # Geographic master data
    ├── f2_pacientes.py       # Patient records
    ├── f3_estadias.py        # Hospitalization stays
    ├── f4_episode_source.py  # Episode source tracking
    ├── f5_clinical_enrichment.py  # Diagnoses, conditions
    ├── f6_profesionales.py   # Healthcare professionals
    ├── f7_visitas.py         # Scheduled visits
    ├── f7b_visitas_realizadas.py  # Realized visits (RUTAS 2025-2026)
    ├── f8_epicrisis.py       # Clinical summaries (metadata only; CORR-12 adds parsed DOCX content)
    ├── f9_operacional.py     # Operational data (calls, routes)
    ├── f10_kpi_diario.py     # Daily KPIs
    ├── f11_entregas_turno.py # Shift handovers + evolution notes + devices
    └── f12_domicilios.py     # Patient domicile ↔ geolocation binding
```

Each functor implements `apply(conn, sources) → report` and optionally declares `PathEquation`s for categorical invariant checks (diagram commutativity). The `ComposedFunctor` orchestrator runs them in order and validates all equations.

**SQL/Python corrections** (`scripts/corr_*.{sql,py}`): 16 ad-hoc correction scripts applied directly to PG after migration:

| Script | Purpose |
|--------|---------|
| `corr_01` – `corr_07` | Solapamientos, establecimiento, completitud, etc. |
| `corr_08_establecimiento_por_direccion.py` | Inferir establecimiento desde dirección → comuna → CESFAM |
| `corr_09_normalizar_direcciones.py` | Normalización IDE Chile 2023 + INE Censo |
| `corr_10_enriquecer_direcciones_redundancia.py` | Cruce de variantes de dirección desde pipeline CSV |
| `corr_11_direcciones_dau.sql` | Direcciones recuperadas del DAU hospitalario |
| `corr_12_parsear_epicrisis_docx.py` | Parsear 295 DOCX epicrisis → campos clínicos (evolución, diagnóstico, examen) |
| `corr_13_catalogo_prestaciones_rem.sql` | Catálogo 16 prestaciones REM + descomposición visitas M:N |
| `corr_14_satisfaccion_usuaria.py` | 33 encuestas satisfacción → `reporting.encuesta_satisfaccion` |
| `corr_15_entrega_kine.py` | 933 notas kinesiología (112 hojas diarias XLSX) → `clinical.nota_evolucion` |
| `corr_16_epicrisis_medica_pdf.py` | 738 epicrisis médicas (1996 PDFs DAU/SGH vía PyMuPDF) → `clinical.epicrisis` |

### PG Schema (10 schemas, key tables)

| Schema | Key Tables | Purpose |
|--------|-----------|---------|
| `clinical` | `paciente`, `estadia`, `epicrisis`, `condicion`, `nota_evolucion`, `domicilio`, `dispositivo` | Clinical domain |
| `territorial` | `establecimiento`, `ubicacion`, `localizacion` | Geography + geocoding |
| `operational` | `visita`, `profesional`, `orden_servicio`, `ruta`, `registro_llamada`, `vehiculo`, `conductor` | Operations |
| `reference` | `catalogo_prestacion`, `service_type_ref`, `prioridad_ref` | Master data |
| `reporting` | `kpi_diario`, `visita_prestacion` (M:N), `encuesta_satisfaccion`, `actividad_profesional_diaria` | Analytics + REM |
| `telemetry` | `gps_posicion`, `posicion_actual`, `telemetria_dispositivo`, `telemetria_segmento`, `telemetria_resumen_diario` | GPS tracking from NavPro |
| `migration` | `provenance` | Field-level lineage tracking |
| `strict` | `hospitalizacion` | Validated stays (1:1 with `clinical.estadia`) |

Notable relationships:
- `visita.prestacion_id` → `catalogo_prestacion` (primary prestación per visit)
- `visita_prestacion` → decomposed compound codes (e.g., "KTM+FONO" → 2 rows)
- `domicilio` → temporal binding `paciente` ↔ `localizacion` (tipo: principal/alternativo/temporal)
- `localizacion` → geocoded addresses (648/673 with coordinates, precision: exacta/aproximada/centroide)
- `visita.domicilio_id` → 7,594/7,594 visits linked to domicilios (100%)
- `visita.localizacion_id` → redundant with domicilio.localizacion_id (kept for hdos-app compat)
- `visita.location_id` → legacy, 0/7594 populated (kept for hdos-app vistas)
- `epicrisis` → 864 total (738 medical from PDF + 126 nursing from DOCX)
- `nota_evolucion` → 2,350 total (1,417 nursing + 933 kinesiology)
- `gps_posicion` → 124,626 GPS points (3 vehicles, Jan-Apr 2026, from NavPro.cl)
- `telemetria_segmento` → 11,374 segments (9,650 drives + 1,724 stops), 176 matched to patient visits
- `telemetria_resumen_diario` → 250 daily summaries (km, drive/stop minutes, max speed)
- `posicion_actual` → real-time position of 3 vehicles (polled every 30 min via cron)
- `v_encuesta_unificada` → coproduct view unifying clinical (hdos-app) ⊔ reporting (pipeline) encuestas

Categorical invariants (trigger-enforced):
- **PE-1**: `T.patient_id = estadia.patient_id` — 40/40 tables covered (14 with WHEN guard for nullable stay_id)
- **stay_coherence**: `visit_id → visita.stay_id = T.stay_id` — 7/7 tables covered
- **PE-T1**: `segmento.start_at::date = visita.fecha` — telemetry trigger
- **State machines**: estadia (6 states) and visita (13 states) with guard + sync triggers

### Known Architectural Debt

**Redundant `patient_id` in 33 clinical tables**: Tables like `nota_evolucion`, `epicrisis`, `condicion`, etc. have both `stay_id → estadia` and `patient_id → paciente`. Since `estadia.patient_id` is NOT NULL, `patient_id` is categorically redundant — it's the diagonal of a commutative triangle:

```
  T.patient_id = estadia.patient_id  (path equation, 0 violations)
```

Trigger `check_stay_coherence` enforces the invariant. **Decision**: keep for now (33-table refactor not worth the blast radius), but **do not propagate** to new tables. Any new table with `stay_id NOT NULL` should derive patient via JOIN, not store a redundant FK.

### Key Design Principles

- **PostgreSQL is the canonical source**: PG database (container `hodom-pg`, port 5555) with validated corrections IS the source of truth. CSV pipeline and `db/hdos.db` (SQLite) are historical migration sources.
- **Deterministic & reproducible**: Hashed IDs (`hashlib`), sorted output. Same input → identical output.
- **Source trust hierarchy**: `manual > enriched > forms > altas > SGH`. Origin weights: merged(4) > raw(3) > alta_rescued(2) > form_rescued(1).
- **Conservative deduplication**: Exact match → RUT ±2 days → nombre ±2 days. Prefers false negatives over false positives.
- **Field-level provenance**: `migration.provenance` table tracks where every migrated value came from (source_type, source_file, phase, field_name).
- **Manual override cycle**: Quality issues → review queues → `input/manual/manual_resolution.csv` → re-run stage 4.

### Identity Resolution Strategies

1. Valid RUT (strongest)
2. Nombre + fecha_nacimiento
3. Nombre + contacto (fallback)
4. Legacy key (historical)

### Consolidation Algorithm (Stage 4)

Episodes grouped into stays by: exact (patient_id + fecha_ingreso + fecha_egreso) → RUT ±2 days → nombre ±2 days. Best episode per group selected by origin weight + non-empty field count. Adjacent stays for same patient (gap ≤1 day) are merged.

### Dashboards

| App | Purpose | Deploy |
|-----|---------|--------|
| `apps/streamlit_migration_explorer.py` | PG migration explorer (10 tabs incl. Mapa pydeck, Satisfacción) | Docker → hdos.sanixai.com |
| `apps/streamlit_dashboard.py` | Main: geospatial, episode filtering, patient search | Local only (CSV-based) |
| `apps/streamlit_admin_dashboard.py` | Admin: review queues, quality issues, corrections | Local only (CSV-based) |
| `apps/streamlit_migration_model_dashboard.py` | Migration model | Local only (CSV-based) |

Streamlit config in `.streamlit/config.toml`: port 8502, headless, light theme (primary `#0B6E4F`).

### Infrastructure

- **PG container**: `hodom-pg` (postgres:14-alpine), port 5555, creds `hodom:hodom`, DB `hodom`. Network `web`. **Shared by hdos (Python pipeline) AND hdos-app (Next.js + Drizzle ORM at `/home/felix/projects/hdos-app`)**. Always grep hdos-app before DDL changes.
- **Dashboard container**: `hdos-dashboard` (Dockerfile, python:3.12-slim + streamlit + pandas + psycopg + pydeck), port 8501 internal. Traefik routes `hdos.sanixai.com` to it.
- **hdos-app**: Next.js app consuming same PG via Drizzle ORM at `/home/felix/projects/hdos-app`. Schema: `src/db/drizzle/schema.ts`. Drizzle filter: clinical, operational, reporting, portal, reference, territorial (NOT telemetry/strict/migration). Portal tables (portal_usuario, portal_mensaje, portal_invitacion, portal_acceso_log) and audit_log are owned by hdos-app.
- **GPS sync cron**: poll every 30 min (07:00-21:00 Chile), full sync daily 21:30. Logs: `/var/log/hdos-gps-{poll,sync}.log`.
- **Rebuild**: `docker compose up -d --build`.

### Data Directories

- `input/raw_csv_exports/` — Raw source CSVs (SGH exports)
- `input/manual/` — Manual corrections (`manual_resolution.csv`, `rut_corrections.csv`)
- `input/reference/` — Reference data, legacy imports
- `output/spreadsheet/{intermediate,enriched,canonical}/` — Pipeline stage outputs (.gitignored, regenerable)
- `output/reports/` — Hand-curated reports (tracked)
- `db/hdos.db` — SQLite migration source for F0 bootstrap (read-only, not current truth)

### Testing

Tests use `sys.path.insert` to import pipeline modules from `scripts/`. Config in `pytest.ini`.

**Shared fixtures** (`tests/conftest.py`): `sample_episodes`, `sample_patients`, `sample_quality_issues`, `sample_match_review_queue`, `sample_identity_review`, `sample_discharge_events`. Helper `write_csv_to_path(path, rows)` for creating temp CSVs. `tmp_enriched_dir` fixture writes all fixture data as CSVs for integration tests.

**Test organization**: `tests/test_canonical_*.py` (stays, patients, health, queues), `tests/test_migration/` (category framework, functors F0-F3, provenance, sprint integration).

## Dependencies

Python 3.12 (Docker) / 3.14 (local .venv). Runtime: `streamlit>=1.43`, `pandas>=2.2`, `openpyxl`, `psycopg[binary]>=3.1`. GIS: `geopandas`, `pyogrio`, `pyproj`, `shapely`. PDF: `PyMuPDF`. Geospatial viz: `pydeck`. DOCX parsing: `python-docx`. GPS sync: `cloudscraper` (Cloudflare bypass for NavPro.cl).

Virtual environment at `.venv/`. Dependencies managed via `requirements-dashboard.txt` (minimal: streamlit + pandas) and direct pip installs — no pyproject.toml or comprehensive requirements file.

## Domain Context

- **REM**: Resumen Estadístico Mensual — monthly statistical reports required by MINSAL (Chile's Ministry of Health)
- **HODOM**: Hospitalización Domiciliaria — home hospitalization program
- **RUT**: Chilean national ID number with check digit validation
- **DEIS**: Departamento de Estadísticas e Información en Salud — health statistics department
- **SGH**: Sistema de Gestión Hospitalaria — hospital management system
- **Age ranges follow REM standard**: <15, 15-19, 20-59, >=60

## Conventions

- No working files in the repo root — content lives under `apps/`, `scripts/`, `tests/`, `input/`, `output/`, `docs/`.
- Editable manual data lives in `input/manual/`. External reference data in `input/reference/`.
- Pipeline artifacts materialize under `output/spreadsheet/` (.gitignored — regenerable from pipeline stages).
- Generated SQL from Python correction scripts (corr_08/09/10, geocode) are .gitignored.
- Active documentation in `docs/` (models, specs, audit reports). Current spec package: `docs/specs/paquete-consolidado-hodom/`. Current DDL: `docs/models/hodom-integrado-pg-v4.sql`.
