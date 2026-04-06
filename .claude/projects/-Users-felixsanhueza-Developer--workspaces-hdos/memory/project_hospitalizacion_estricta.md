---
name: Hospitalizacion Estricta Pipeline
description: Pipeline de hospitalizaciones estrictas desde ingresos formulario + egresos altas/SGH, con matching canon-guided y jerarquía de fuentes
type: project
---

## Hospitalizaciones Estrictas (desde 2025-01-01)

**Resultado actual:** 791 hospitalizaciones únicas, 659 pacientes, 0 egresos sin ingreso, 22 activos.

### Fuentes y jerarquía de confianza

**Ingresos:**
1. Formularios de postulación HODOM 2025/2026 (.xlsx) → `ingresos_minimos_estrictos.csv`
2. Canónico (`hospitalization_stay.csv`) como backfill cuando no hay formulario

**Egresos:**
1. Planilla de altas (`planilla-altas-2024-2026.xlsx`) — fuente más oficial
2. SGH (`ingresos-hodom-2024-marzo-2026.txt`) — solo si no existe en altas
3. Canon rescatado — para 9 pacientes sin egreso en altas ni SGH

**Fecha de ingreso en hospitalización estricta:** altas > canónico > formulario

### Archivos clave

- `output/spreadsheet/hospitalizaciones/hospitalizacion_estricta.csv` — resultado final (run, fecha_ingreso, fecha_egreso, dias_estadia)
- `output/spreadsheet/hospitalizaciones/ingresos_minimos_estrictos.csv` — 1922 ingresos (100% con RUN)
- `output/spreadsheet/hospitalizaciones/egresos_minimos_estrictos.csv` — 1188 egresos (100% con RUN)
- `input/manual/admissions_minimal_resolution.csv` — 24 resoluciones (11 set_run, 10 discard, 3 set_fecha)
- `input/manual/discharges_minimal_resolution.csv` — 70 resoluciones (7 set_run, 50 discard SGH dup, 9 add_canon, 2 fecha_fix, 2 force_canon)

### Matching algorithm

Canon-guided por paciente (implementado en `streamlit_migration_model_dashboard.py:build_hospitalization_pairs`):
1. Para cada paciente, usar estadías canónicas como plantilla
2. Buscar egreso estricto más cercano al canónico (±7d)
3. Buscar ingreso formulario más cercano al canónico (±7d)
4. Fallback cronológico para sobrantes
5. Rescatar ingresos huérfanos con egreso canónico

### Correcciones aplicadas

- 17 RUTs corregidos (float export, DV errado, apellido en campo RUT)
- 50 SGH duplicados descartados (±3d de planilla altas)
- 9 egresos rescatados del canónico (pacientes sin egreso en altas/SGH)
- 5 pacientes eliminados (sin egreso en ninguna fuente: ROJO, GAETE, SEPULVEDA BUSTOS, CONTRERAS SAN MARTIN, RIVERA LABRA)
- 2 fechas de egreso corregidas (ACUÑA 2025→2026, CONTRERAS 2025→2026)
- Rita Gonzalez Jeldres: solo ingreso 30/04/25 (descartado duplicado 28/04)

**Why:** El objetivo es tener un set estricto de hospitalizaciones determinadas únicamente por RUN + fecha_ingreso + fecha_egreso, priorizando fuentes oficiales sobre SGH.

**How to apply:** Regenerar con `build_hodom_admissions_minimal.py` + `build_hodom_discharges_minimal.py`, luego el CSV final se genera desde el matching del dashboard.
