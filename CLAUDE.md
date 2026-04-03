# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

HDOS (Hospitalización Domiciliaria) is a Python data pipeline for consolidating, deduplicating, and enriching home hospitalization records for Hospital San Carlos (Ñuble, Chile). Data flows through CSV files — no database. Output feeds two Streamlit dashboards and REM reports for MINSAL.

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

# Run individual pipeline stages
.venv/bin/python scripts/migrate_hodom_csv.py          # Stage 1
.venv/bin/python scripts/build_hodom_intermediate.py    # Stage 2
.venv/bin/python scripts/build_hodom_enriched.py        # Stage 3
.venv/bin/python scripts/build_hodom_canonical.py       # Stage 4
```

## Architecture

### 4-Stage Pipeline

```
Stage 1: migrate_hodom_csv.py
  input/raw_csv_exports/ (33 CSVs) → output/spreadsheet/ (normalized rows, patients, file summary)

Stage 2: build_hodom_intermediate.py
  Stage 1 output → output/spreadsheet/intermediate/ (17 CSVs: episodes, patients, diagnoses, care requirements, identity candidates, provenance)

Stage 3: build_hodom_enriched.py
  intermediate/ + XLSX forms + DEIS reference + INE geodata → output/spreadsheet/enriched/ (28 CSVs: episode_master, patient_master, address_resolution, locality_reference, etc.)

Stage 4: build_hodom_canonical.py
  enriched/ + input/manual/ corrections → output/spreadsheet/canonical/ (7 CSVs: hospitalization_stay, patient_master, review_queue, coverage_gap, etc.)
```

Each stage imports the previous one as a Python module. Stage 3 (`build_hodom_enriched.py`) imports `build_hodom_intermediate` and `migrate_hodom_csv` directly via `sys.path`.

### Key Design Principles

- **Deterministic & reproducible**: Hashed IDs (`hashlib`), sorted output. Re-running a stage with the same input produces identical output.
- **Source trust hierarchy**: `manual > enriched > forms > altas > SGH`. Origin weights: merged(4) > raw(3) > alta_rescued(2) > form_rescued(1).
- **Conservative deduplication**: Exact match → RUT ±2 days → nombre ±2 days. The pipeline prefers false negatives over false positives.
- **Field-level provenance**: `field_provenance.csv` tracks where every value came from.
- **Manual override cycle**: Quality issues → review queues → `input/manual/manual_resolution.csv` → re-run stage 4.

### Identity Resolution Strategies

1. Valid RUT (strongest)
2. Nombre + fecha_nacimiento
3. Nombre + contacto (fallback)
4. Legacy key (historical)

### Consolidation Algorithm (Stage 4)

Episodes are grouped into stays by: exact (patient_id + fecha_ingreso + fecha_egreso) → RUT ±2 days → nombre ±2 days. Best episode per group selected by origin weight + non-empty field count. Adjacent stays for same patient (gap ≤1 day) are merged.

### Dashboards

- **`apps/streamlit_dashboard.py`** — Main dashboard: geospatial visualization, episode filtering, patient search, aggregations by origin/age/sex.
- **`apps/streamlit_admin_dashboard.py`** — Admin dashboard: review queues, quality issues, manual corrections, pipeline health. Uses lazy loading and pagination.

### Data Directories

- `input/raw_csv_exports/` — Raw source CSVs (SGH exports, etc.)
- `input/manual/` — Manual corrections (`manual_resolution.csv`, `rut_corrections.csv`)
- `input/reference/` — Reference data, legacy imports
- `output/spreadsheet/intermediate/` — Stage 2 output
- `output/spreadsheet/enriched/` — Stage 3 output
- `output/spreadsheet/canonical/` — Stage 4 output (final)

## Dependencies

Runtime: `streamlit>=1.43`, `pandas>=2.2`, `openpyxl`, `requests`. Optional: `pyogrio` (for GIS/geodatabase operations).

Virtual environment at `.venv/`. No `pyproject.toml` — dependencies managed via `requirements-dashboard.txt` and direct pip installs.

## Domain Context

- **REM**: Resumen Estadístico Mensual — monthly statistical reports required by MINSAL (Chile's Ministry of Health)
- **HODOM**: Hospitalización Domiciliaria — home hospitalization program
- **RUT**: Chilean national ID number with check digit validation
- **DEIS**: Departamento de Estadísticas e Información en Salud — health statistics department
- **SGH**: Sistema de Gestión Hospitalaria — hospital management system
- **Age ranges follow REM standard**: <15, 15-19, 20-59, >=60
