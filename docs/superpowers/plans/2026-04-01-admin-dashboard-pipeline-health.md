# Admin Dashboard: Pipeline Health, Resolución y Modelo Estabilizado — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Estabilizar el modelo de datos del pipeline HODOM, agregar panel de salud con semáforos, flujos de resolución con edición directa, y control reforzado de duplicados.

**Architecture:** Se agrega un 4to paso al pipeline (`build_hodom_canonical.py`) que lee los CSVs enriquecidos y produce la capa canónica estabilizada. El dashboard admin se refactoriza para consumir esta capa canónica en lugar de recalcular stays en runtime. Se agrega `manual_resolution.csv` como mecanismo bidireccional (dashboard escribe, pipeline lee en próxima corrida).

**Tech Stack:** Python 3.14, pandas, Streamlit 1.43+, pytest, difflib (similitud de texto)

---

## File Structure

```
scripts/
├── build_hodom_canonical.py           ← NEW: 4to paso del pipeline — genera capa canónica
├── build_hodom_enriched.py            ← MODIFY: leer manual_resolution.csv al inicio
├── refresh_data_and_run_dashboard.sh  ← MODIFY: agregar paso canónico

tests/
├── conftest.py                        ← NEW: fixtures con datos de prueba
├── test_canonical_stays.py            ← NEW: tests de consolidación de stays
├── test_canonical_patients.py         ← NEW: tests de patient_master enriquecido
├── test_canonical_health.py           ← NEW: tests de pipeline_health y coverage_gap
├── test_canonical_queues.py           ← NEW: tests de review_queue y duplicates
├── test_manual_resolution.py          ← NEW: tests de lectura/aplicación de resoluciones

input/manual/
├── manual_resolution.csv              ← NEW: decisiones de gestoras (read/write)

streamlit_admin_app.py                 ← MODIFY: refactorizar a capa canónica + nuevos tabs
```

---

### Task 1: Infraestructura de tests + fixtures

**Files:**
- Create: `tests/conftest.py`
- Create: `pytest.ini`

- [ ] **Step 1: Instalar pytest**

```bash
.venv/bin/pip install pytest
```

- [ ] **Step 2: Crear pytest.ini**

```ini
[pytest]
testpaths = tests
python_files = test_*.py
python_functions = test_*
```

- [ ] **Step 3: Crear conftest.py con fixtures de datos de prueba**

```python
from __future__ import annotations

import csv
import io
from pathlib import Path

import pytest


@pytest.fixture
def sample_episodes() -> list[dict[str, str]]:
    """Episodios de prueba con distintos orígenes y estados."""
    return [
        {
            "episode_id": "ep_001",
            "patient_id": "pt_001",
            "fecha_ingreso": "2025-09-01",
            "fecha_egreso": "2025-09-15",
            "estado": "EGRESADO",
            "servicio_origen": "CESFAM SAN NICOLAS",
            "prevision": "FONASA A",
            "diagnostico_principal_texto": "EPOC",
            "motivo_egreso": "ALTA MEDICA",
            "establecimiento_resuelto": "HOSPITAL SAN CARLOS",
            "codigo_deis_resuelto": "112100",
            "comuna_resuelta": "SAN CARLOS",
            "localidad_resuelta": "SAN CARLOS",
            "latitud_localidad": "-36.4241",
            "longitud_localidad": "-71.9579",
            "episode_origin": "merged",
            "resolution_status": "AUTO",
            "gestora": "MARIA GONZALEZ",
            "usuario_o2": "mgonzalez",
            "nombre_completo": "JUAN PEREZ SOTO",
            "rut": "12345678-5",
            "sexo_resuelto": "masculino",
            "edad_reportada": "72",
        },
        {
            "episode_id": "ep_002",
            "patient_id": "pt_001",
            "fecha_ingreso": "2025-09-01",
            "fecha_egreso": "2025-09-15",
            "estado": "EGRESADO",
            "servicio_origen": "CESFAM SAN NICOLAS",
            "prevision": "FONASA A",
            "diagnostico_principal_texto": "BRONQUITIS CRONICA",
            "motivo_egreso": "ALTA MEDICA",
            "establecimiento_resuelto": "HOSPITAL SAN CARLOS",
            "codigo_deis_resuelto": "112100",
            "comuna_resuelta": "SAN CARLOS",
            "localidad_resuelta": "SAN CARLOS",
            "latitud_localidad": "-36.4241",
            "longitud_localidad": "-71.9579",
            "episode_origin": "raw",
            "resolution_status": "AUTO",
            "gestora": "MARIA GONZALEZ",
            "usuario_o2": "mgonzalez",
            "nombre_completo": "JUAN PEREZ SOTO",
            "rut": "12345678-5",
            "sexo_resuelto": "masculino",
            "edad_reportada": "72",
        },
        {
            "episode_id": "ep_003",
            "patient_id": "pt_002",
            "fecha_ingreso": "2025-10-10",
            "fecha_egreso": "",
            "estado": "ACTIVO",
            "servicio_origen": "UE",
            "prevision": "FONASA B",
            "diagnostico_principal_texto": "ITU",
            "motivo_egreso": "",
            "establecimiento_resuelto": "HOSPITAL CHILLAN",
            "codigo_deis_resuelto": "112200",
            "comuna_resuelta": "CHILLAN",
            "localidad_resuelta": "CHILLAN",
            "latitud_localidad": "-36.6066",
            "longitud_localidad": "-72.1034",
            "episode_origin": "form_rescued",
            "resolution_status": "PROVISIONAL",
            "gestora": "ANA LOPEZ",
            "usuario_o2": "",
            "nombre_completo": "MARIA RODRIGUEZ DIAZ",
            "rut": "9876543-2",
            "sexo_resuelto": "femenino",
            "edad_reportada": "65",
        },
        {
            "episode_id": "ep_004",
            "patient_id": "pt_003",
            "fecha_ingreso": "2025-10-12",
            "fecha_egreso": "2025-10-25",
            "estado": "EGRESADO",
            "servicio_origen": "CDT",
            "prevision": "FONASA A",
            "diagnostico_principal_texto": "DIABETES",
            "motivo_egreso": "FALLECIDO",
            "establecimiento_resuelto": "",
            "codigo_deis_resuelto": "",
            "comuna_resuelta": "SAN CARLOS",
            "localidad_resuelta": "",
            "latitud_localidad": "",
            "longitud_localidad": "",
            "episode_origin": "alta_rescued",
            "resolution_status": "AUTO",
            "gestora": "",
            "usuario_o2": "",
            "nombre_completo": "PEDRO MARTINEZ ROJAS",
            "rut": "11223344-5",
            "sexo_resuelto": "masculino",
            "edad_reportada": "80",
        },
    ]


@pytest.fixture
def sample_patients() -> list[dict[str, str]]:
    """Pacientes de prueba."""
    return [
        {
            "patient_id": "pt_001",
            "nombre_completo": "JUAN PEREZ SOTO",
            "rut": "12345678-5",
            "sexo": "masculino",
            "fecha_nacimiento_date": "1953-03-15",
            "edad_reportada": "72",
            "comuna": "SAN CARLOS",
            "cesfam": "CESFAM SAN NICOLAS",
            "episode_count": "2",
        },
        {
            "patient_id": "pt_002",
            "nombre_completo": "MARIA RODRIGUEZ DIAZ",
            "rut": "9876543-2",
            "sexo": "femenino",
            "fecha_nacimiento_date": "1960-07-22",
            "edad_reportada": "65",
            "comuna": "CHILLAN",
            "cesfam": "CESFAM CHILLAN",
            "episode_count": "1",
        },
        {
            "patient_id": "pt_003",
            "nombre_completo": "PEDRO MARTINEZ ROJAS",
            "rut": "11223344-5",
            "sexo": "masculino",
            "fecha_nacimiento_date": "1945-01-10",
            "edad_reportada": "80",
            "comuna": "SAN CARLOS",
            "cesfam": "",
            "episode_count": "1",
        },
    ]


@pytest.fixture
def sample_quality_issues() -> list[dict[str, str]]:
    """Issues de calidad de prueba."""
    return [
        {
            "quality_issue_id": "qi_001",
            "issue_type": "UNMATCHED_FORM_SUBMISSION",
            "severity": "MEDIUM",
            "normalized_row_id": "nr_100",
            "episode_id": "",
            "raw_value": "formulario sin match",
            "suggested_value": "",
            "status": "REVIEW_REQUIRED",
        },
        {
            "quality_issue_id": "qi_002",
            "issue_type": "BIRTHDATE_AGE_MISMATCH",
            "severity": "LOW",
            "normalized_row_id": "nr_200",
            "episode_id": "ep_003",
            "raw_value": "65",
            "suggested_value": "64",
            "status": "OPEN",
        },
        {
            "quality_issue_id": "qi_003",
            "issue_type": "ESTABLISHMENT_UNRESOLVED",
            "severity": "LOW",
            "normalized_row_id": "",
            "episode_id": "ep_004",
            "raw_value": "HOSPITAL X",
            "suggested_value": "",
            "status": "OPEN",
        },
        {
            "quality_issue_id": "qi_004",
            "issue_type": "ENUM_NORMALIZED",
            "severity": "INFO",
            "normalized_row_id": "nr_300",
            "episode_id": "ep_001",
            "raw_value": "fonasa a",
            "suggested_value": "FONASA A",
            "status": "RESOLVED_AUTO",
        },
    ]


@pytest.fixture
def sample_match_review_queue() -> list[dict[str, str]]:
    """Cola de revisión de match de prueba."""
    return [
        {
            "review_queue_id": "rq_001",
            "form_submission_id": "fs_100",
            "patient_id": "pt_010",
            "patient_name": "ROSA FUENTES VERA",
            "patient_rut": "15678901-3",
            "submission_timestamp": "2025-10-05",
            "servicio_origen_solicitud": "CESFAM BULNES",
            "diagnostico_form": "NEUMONIA",
            "request_prestacion": "HODOM",
            "gestora": "ANA LOPEZ",
            "candidate_rank": "1",
            "candidate_episode_id": "ep_050",
            "candidate_episode_origin": "raw",
            "candidate_fecha_ingreso": "2025-10-03",
            "candidate_fecha_egreso": "2025-10-20",
            "candidate_servicio_origen": "CESFAM BULNES",
            "candidate_diagnostico": "NEUMONIA ADQUIRIDA",
            "candidate_score": "78",
            "auto_close_recommended": "0",
        },
    ]


@pytest.fixture
def sample_identity_review() -> list[dict[str, str]]:
    """Cola de identidad de prueba."""
    return [
        {
            "identity_review_id": "idr_001",
            "issue_type": "BIRTHDATE_AGE_MISMATCH",
            "patient_id": "pt_002",
            "episode_id": "ep_003",
            "nombre_completo": "MARIA RODRIGUEZ DIAZ",
            "rut": "9876543-2",
            "raw_value": "65",
            "suggested_value": "64",
            "severity": "LOW",
            "status": "OPEN",
        },
    ]


@pytest.fixture
def sample_discharge_events() -> list[dict[str, str]]:
    """Eventos de alta normalizados de prueba."""
    return [
        {
            "discharge_event_id": "de_001",
            "nombre_completo": "ROSA FUENTES VERA",
            "rut_norm": "15678901-3",
            "fecha_ingreso": "2025-10-03",
            "fecha_egreso": "2025-10-20",
            "diagnostico": "NEUMONIA",
            "motivo_egreso": "ALTA MEDICA",
            "match_status": "unresolved",
            "episode_origin": "",
            "matched_episode_id": "",
        },
    ]


@pytest.fixture
def tmp_enriched_dir(tmp_path, sample_episodes, sample_patients, sample_quality_issues,
                     sample_match_review_queue, sample_identity_review,
                     sample_discharge_events):
    """Directorio temporal con CSVs enriquecidos para tests de integración."""
    enriched = tmp_path / "enriched"
    enriched.mkdir()

    def write_csv(name: str, rows: list[dict]) -> None:
        if not rows:
            return
        path = enriched / name
        with path.open("w", newline="", encoding="utf-8") as fh:
            writer = csv.DictWriter(fh, fieldnames=list(rows[0].keys()))
            writer.writeheader()
            writer.writerows(rows)

    write_csv("episode_master.csv", sample_episodes)
    write_csv("patient_master.csv", sample_patients)
    write_csv("data_quality_issue.csv", sample_quality_issues)
    write_csv("match_review_queue.csv", sample_match_review_queue)
    write_csv("identity_review_queue.csv", sample_identity_review)
    write_csv("normalized_discharge_event.csv", sample_discharge_events)
    write_csv("establishment_reference.csv", [
        {"establishment_id": "est_001", "codigo_deis": "112100", "nombre_oficial": "HOSPITAL SAN CARLOS", "comuna": "SAN CARLOS", "tipo_establecimiento": "Hospital"},
        {"establishment_id": "est_002", "codigo_deis": "112200", "nombre_oficial": "HOSPITAL CHILLAN", "comuna": "CHILLAN", "tipo_establecimiento": "Hospital"},
    ])
    write_csv("locality_reference.csv", [
        {"locality_id": "loc_001", "nombre_oficial": "SAN CARLOS", "provincia": "PUNILLA", "latitud": "-36.4241", "longitud": "-71.9579"},
        {"locality_id": "loc_002", "nombre_oficial": "CHILLAN", "provincia": "DIGUILLIN", "latitud": "-36.6066", "longitud": "-72.1034"},
    ])

    return enriched


def write_csv_to_path(path: Path, rows: list[dict]) -> None:
    """Utilidad para escribir CSVs en tests."""
    if not rows:
        with path.open("w", newline="", encoding="utf-8") as fh:
            fh.write("")
        return
    with path.open("w", newline="", encoding="utf-8") as fh:
        writer = csv.DictWriter(fh, fieldnames=list(rows[0].keys()))
        writer.writeheader()
        writer.writerows(rows)
```

- [ ] **Step 4: Verificar que pytest funciona**

```bash
.venv/bin/pytest --co -q
```

Expected: `no tests ran` (sin errores de configuración)

- [ ] **Step 5: Commit**

```bash
git add pytest.ini tests/conftest.py
git commit -m "feat: agregar infraestructura de tests con fixtures para pipeline canónico"
```

---

### Task 2: Skeleton del canonical builder + consolidación de stays

**Files:**
- Create: `scripts/build_hodom_canonical.py`
- Create: `tests/test_canonical_stays.py`

- [ ] **Step 1: Escribir test de consolidación de stays**

```python
from __future__ import annotations

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "scripts"))


def test_consolidate_stays_merges_same_patient_same_dates(sample_episodes):
    from build_hodom_canonical import consolidate_stays

    stays = consolidate_stays(sample_episodes)
    # ep_001 y ep_002 tienen mismo patient_id + fecha_ingreso + fecha_egreso → 1 stay
    # ep_003 y ep_004 son distintos → 2 stays más
    assert len(stays) == 3

    # El stay consolidado debe tener los datos del mejor episodio (merged > raw)
    consolidated = next(s for s in stays if "ep_001" in s["source_episode_ids"])
    assert consolidated["source_episode_count"] == 2
    assert consolidated["episode_origin"] == "consolidated"
    assert "EPOC" in consolidated["diagnostico_principal"]
    assert "BRONQUITIS" in consolidated["diagnostico_principal"]
    assert consolidated["confidence_level"] == "high"


def test_consolidate_stays_single_episode_not_consolidated(sample_episodes):
    from build_hodom_canonical import consolidate_stays

    stays = consolidate_stays(sample_episodes)
    single = next(s for s in stays if s["source_episode_ids"] == "ep_003")
    assert single["source_episode_count"] == 1
    assert single["episode_origin"] == "form_rescued"
    assert single["confidence_level"] == "low"


def test_consolidate_stays_confidence_levels(sample_episodes):
    from build_hodom_canonical import consolidate_stays

    stays = consolidate_stays(sample_episodes)
    for stay in stays:
        if stay["episode_origin"] == "consolidated":
            assert stay["confidence_level"] == "high"
        elif stay["episode_origin"] in ("merged", "raw") and stay["fecha_egreso"]:
            assert stay["confidence_level"] in ("high", "medium")
        elif stay["episode_origin"] == "form_rescued":
            assert stay["confidence_level"] == "low"
```

- [ ] **Step 2: Ejecutar test para verificar que falla**

```bash
.venv/bin/pytest tests/test_canonical_stays.py -v
```

Expected: FAIL — `ModuleNotFoundError: No module named 'build_hodom_canonical'`

- [ ] **Step 3: Crear build_hodom_canonical.py con consolidación de stays**

```python
"""Etapa 4 del pipeline HODOM: genera capa canónica estabilizada.

Lee CSVs enriquecidos de output/spreadsheet/enriched/ y produce
CSVs canónicos con modelo de datos estable para el dashboard admin.
"""
from __future__ import annotations

import argparse
import csv
import hashlib
import json
from datetime import date, datetime
from pathlib import Path

ORIGIN_WEIGHT = {"merged": 4, "raw": 3, "alta_rescued": 2, "form_rescued": 1}


def read_csv(path: Path) -> list[dict[str, str]]:
    if not path.exists():
        return []
    with path.open("r", encoding="utf-8", newline="") as fh:
        return list(csv.DictReader(fh))


def write_csv(path: Path, rows: list[dict[str, str]], fieldnames: list[str] | None = None) -> None:
    if not rows:
        path.write_text("", encoding="utf-8")
        return
    if fieldnames is None:
        fieldnames = list(rows[0].keys())
    with path.open("w", newline="", encoding="utf-8") as fh:
        writer = csv.DictWriter(fh, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(rows)


def make_id(prefix: str, value: str) -> str:
    return f"{prefix}_{hashlib.sha256(value.encode()).hexdigest()[:16]}"


def stay_row_score(row: dict[str, str]) -> tuple[int, int]:
    origin = ORIGIN_WEIGHT.get(row.get("episode_origin", ""), 0)
    non_empty = sum(1 for v in row.values() if v and str(v).strip())
    return (origin, non_empty)


def compute_confidence(episode_origin: str, has_egreso: bool, source_count: int) -> str:
    if source_count > 1:
        return "high"
    if episode_origin in ("merged",) and has_egreso:
        return "high"
    if episode_origin in ("raw", "alta_rescued") and has_egreso:
        return "medium"
    if episode_origin in ("merged", "raw") and not has_egreso:
        return "medium"
    return "low"


def consolidate_stays(episodes: list[dict[str, str]]) -> list[dict[str, str]]:
    """Consolida episodios en hospitalization stays.

    Agrupa por:
    1. patient_id + fecha_ingreso + fecha_egreso (exacto)
    2. rut + fecha_ingreso ±2 días (identidad fragmentada)
    3. nombre_normalizado + fecha_ingreso ±2 días (fallback sin RUT)
    """
    # Paso 1: agrupar por patient_id + fechas exactas
    groups: dict[str, list[dict[str, str]]] = {}
    episode_assigned: set[str] = set()

    for ep in episodes:
        fi = ep.get("fecha_ingreso", "")
        fe = ep.get("fecha_egreso", "")
        pid = ep.get("patient_id", "")
        if fi and fe and pid:
            key = f"{pid}|{fi}|{fe}"
        else:
            key = f"episode:{ep['episode_id']}"
        groups.setdefault(key, []).append(ep)
        episode_assigned.add(ep["episode_id"])

    # Paso 2: buscar duplicados por RUT + fecha_ingreso ±2 días entre groups sin consolidar
    solo_groups = {k: v for k, v in groups.items() if len(v) == 1 and k.startswith("episode:")}
    rut_index: dict[str, list[str]] = {}
    for key, eps in solo_groups.items():
        rut = eps[0].get("rut", "")
        if rut:
            rut_index.setdefault(rut, []).append(key)

    merge_pairs: list[tuple[str, str]] = []
    for rut, keys in rut_index.items():
        if len(keys) < 2:
            continue
        for i in range(len(keys)):
            for j in range(i + 1, len(keys)):
                ep_a = solo_groups[keys[i]][0]
                ep_b = solo_groups[keys[j]][0]
                fi_a = ep_a.get("fecha_ingreso", "")
                fi_b = ep_b.get("fecha_ingreso", "")
                if fi_a and fi_b:
                    try:
                        diff = abs((date.fromisoformat(fi_a) - date.fromisoformat(fi_b)).days)
                        if diff <= 2:
                            merge_pairs.append((keys[i], keys[j]))
                    except ValueError:
                        pass

    # Paso 3: buscar duplicados por nombre + fecha_ingreso ±2 días
    name_index: dict[str, list[str]] = {}
    for key, eps in solo_groups.items():
        name = eps[0].get("nombre_completo", "").strip().upper()
        if name and len(name) > 5:
            name_index.setdefault(name, []).append(key)

    for name, keys in name_index.items():
        if len(keys) < 2:
            continue
        for i in range(len(keys)):
            for j in range(i + 1, len(keys)):
                ep_a = solo_groups[keys[i]][0]
                ep_b = solo_groups[keys[j]][0]
                fi_a = ep_a.get("fecha_ingreso", "")
                fi_b = ep_b.get("fecha_ingreso", "")
                if fi_a and fi_b:
                    try:
                        diff = abs((date.fromisoformat(fi_a) - date.fromisoformat(fi_b)).days)
                        if diff <= 2 and (keys[i], keys[j]) not in merge_pairs:
                            merge_pairs.append((keys[i], keys[j]))
                    except ValueError:
                        pass

    # Aplicar merges
    for key_a, key_b in merge_pairs:
        if key_a in groups and key_b in groups:
            groups[key_a].extend(groups.pop(key_b))

    # Construir stays
    stays: list[dict[str, str]] = []
    for group_key, group_eps in groups.items():
        best = max(group_eps, key=stay_row_score)
        source_ids = " | ".join(ep["episode_id"] for ep in group_eps)
        source_count = len(group_eps)

        diagnostics = sorted({
            ep.get("diagnostico_principal_texto", "")
            for ep in group_eps
            if ep.get("diagnostico_principal_texto", "")
        })

        origin = best.get("episode_origin", "raw")
        if source_count > 1:
            origin = "consolidated"

        has_egreso = bool(best.get("fecha_egreso", ""))

        stays.append({
            "stay_id": make_id("stay", group_key),
            "patient_id": best.get("patient_id", ""),
            "fecha_ingreso": best.get("fecha_ingreso", ""),
            "fecha_egreso": best.get("fecha_egreso", ""),
            "estado": best.get("estado", "SIN_ESTADO"),
            "servicio_origen": best.get("servicio_origen", ""),
            "prevision": best.get("prevision", ""),
            "diagnostico_principal": " | ".join(diagnostics) if source_count > 1 else best.get("diagnostico_principal_texto", ""),
            "motivo_egreso": best.get("motivo_egreso", ""),
            "establecimiento": best.get("establecimiento_resuelto", ""),
            "codigo_deis": best.get("codigo_deis_resuelto", ""),
            "comuna": best.get("comuna_resuelta", ""),
            "localidad": best.get("localidad_resuelta", ""),
            "latitud": best.get("latitud_localidad", ""),
            "longitud": best.get("longitud_localidad", ""),
            "source_episode_ids": source_ids,
            "source_episode_count": str(source_count),
            "episode_origin": origin,
            "confidence_level": compute_confidence(origin, has_egreso, source_count),
            "gestora": best.get("gestora", ""),
            "usuario_o2": best.get("usuario_o2", ""),
            "nombre_completo": best.get("nombre_completo", ""),
            "rut": best.get("rut", ""),
            "sexo_resuelto": best.get("sexo_resuelto", ""),
            "edad_reportada": best.get("edad_reportada", ""),
            "rango_etario": best.get("rango_etario", ""),
        })

    return stays


HOSPITALIZATION_STAY_FIELDS = [
    "stay_id", "patient_id", "fecha_ingreso", "fecha_egreso", "estado",
    "servicio_origen", "prevision", "diagnostico_principal", "motivo_egreso",
    "establecimiento", "codigo_deis", "comuna", "localidad", "latitud", "longitud",
    "source_episode_ids", "source_episode_count", "episode_origin", "confidence_level",
    "gestora", "usuario_o2", "nombre_completo", "rut", "sexo_resuelto",
    "edad_reportada", "rango_etario",
]
```

- [ ] **Step 4: Ejecutar tests para verificar que pasan**

```bash
.venv/bin/pytest tests/test_canonical_stays.py -v
```

Expected: 3 passed

- [ ] **Step 5: Commit**

```bash
git add scripts/build_hodom_canonical.py tests/test_canonical_stays.py
git commit -m "feat: agregar canonical builder con consolidación de hospitalization stays"
```

---

### Task 3: Patient master enriquecido

**Files:**
- Modify: `scripts/build_hodom_canonical.py`
- Create: `tests/test_canonical_patients.py`

- [ ] **Step 1: Escribir tests de patient_master enriquecido**

```python
from __future__ import annotations

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "scripts"))


def test_enrich_patients_adds_aggregated_fields(sample_patients, sample_episodes):
    from build_hodom_canonical import consolidate_stays, enrich_patient_master

    stays = consolidate_stays(sample_episodes)
    enriched = enrich_patient_master(sample_patients, stays, [])
    pt1 = next(p for p in enriched if p["patient_id"] == "pt_001")

    assert pt1["total_hospitalizaciones"] == "1"  # 2 episodes → 1 stay
    assert pt1["primera_fecha_ingreso"] == "2025-09-01"
    assert pt1["ultima_fecha_egreso"] == "2025-09-15"
    assert pt1["estado_actual"] == "egresado"
    assert pt1["tiene_issues_abiertos"] == "False"


def test_enrich_patients_active_state(sample_patients, sample_episodes):
    from build_hodom_canonical import consolidate_stays, enrich_patient_master

    stays = consolidate_stays(sample_episodes)
    enriched = enrich_patient_master(sample_patients, stays, [])
    pt2 = next(p for p in enriched if p["patient_id"] == "pt_002")

    assert pt2["estado_actual"] == "activo"


def test_enrich_patients_with_open_issues(sample_patients, sample_episodes, sample_quality_issues):
    from build_hodom_canonical import consolidate_stays, enrich_patient_master

    stays = consolidate_stays(sample_episodes)
    enriched = enrich_patient_master(sample_patients, stays, sample_quality_issues)
    pt2 = next(p for p in enriched if p["patient_id"] == "pt_002")

    # pt_002 tiene ep_003 con issue BIRTHDATE_AGE_MISMATCH OPEN
    assert pt2["tiene_issues_abiertos"] == "True"


def test_enrich_patients_calculates_days(sample_patients, sample_episodes):
    from build_hodom_canonical import consolidate_stays, enrich_patient_master

    stays = consolidate_stays(sample_episodes)
    enriched = enrich_patient_master(sample_patients, stays, [])
    pt1 = next(p for p in enriched if p["patient_id"] == "pt_001")

    # 2025-09-01 to 2025-09-15 = 14 days
    assert int(pt1["dias_totales_estadia"]) == 14
```

- [ ] **Step 2: Ejecutar tests para verificar que fallan**

```bash
.venv/bin/pytest tests/test_canonical_patients.py -v
```

Expected: FAIL — `ImportError: cannot import name 'enrich_patient_master'`

- [ ] **Step 3: Implementar enrich_patient_master en build_hodom_canonical.py**

Agregar al final de `scripts/build_hodom_canonical.py`:

```python
def enrich_patient_master(
    patients: list[dict[str, str]],
    stays: list[dict[str, str]],
    quality_issues: list[dict[str, str]],
) -> list[dict[str, str]]:
    """Enriquece patient_master con campos agregados desde stays e issues."""
    # Indexar stays por patient_id
    stays_by_patient: dict[str, list[dict[str, str]]] = {}
    for stay in stays:
        pid = stay.get("patient_id", "")
        if pid:
            stays_by_patient.setdefault(pid, []).append(stay)

    # Indexar issues abiertos por episode_id → patient_id
    open_issue_episodes: set[str] = set()
    for issue in quality_issues:
        if issue.get("status", "") in ("OPEN", "REVIEW_REQUIRED"):
            eid = issue.get("episode_id", "")
            if eid:
                open_issue_episodes.add(eid)

    # Mapear episode_id → patient_id via stays
    patient_has_open_issue: set[str] = set()
    for stay in stays:
        source_ids = stay.get("source_episode_ids", "").split(" | ")
        for eid in source_ids:
            if eid.strip() in open_issue_episodes:
                patient_has_open_issue.add(stay["patient_id"])

    enriched: list[dict[str, str]] = []
    for patient in patients:
        pid = patient["patient_id"]
        patient_stays = stays_by_patient.get(pid, [])

        ingreso_dates = []
        egreso_dates = []
        total_days = 0
        any_active = False

        for stay in patient_stays:
            fi = stay.get("fecha_ingreso", "")
            fe = stay.get("fecha_egreso", "")
            if fi:
                ingreso_dates.append(fi)
            if fe:
                egreso_dates.append(fe)
            else:
                any_active = True
            if fi and fe:
                try:
                    delta = (date.fromisoformat(fe) - date.fromisoformat(fi)).days
                    total_days += max(delta, 0)
                except ValueError:
                    pass

        if any_active:
            estado = "activo"
        elif patient_stays:
            estado = "egresado"
        else:
            estado = "sin_info"

        edad_calculada = ""
        fdn = patient.get("fecha_nacimiento_date", "")
        if fdn:
            try:
                born = date.fromisoformat(fdn)
                today = date.today()
                edad_calculada = str(today.year - born.year - ((today.month, today.day) < (born.month, born.day)))
            except ValueError:
                pass

        enriched.append({
            **patient,
            "edad_calculada": edad_calculada,
            "prevision": patient.get("prevision", ""),
            "total_hospitalizaciones": str(len(patient_stays)),
            "primera_fecha_ingreso": min(ingreso_dates) if ingreso_dates else "",
            "ultima_fecha_egreso": max(egreso_dates) if egreso_dates else "",
            "dias_totales_estadia": str(total_days),
            "estado_actual": estado,
            "tiene_issues_abiertos": str(pid in patient_has_open_issue),
        })

    return enriched


PATIENT_MASTER_FIELDS = [
    "patient_id", "nombre_completo", "rut", "sexo", "fecha_nacimiento_date",
    "edad_reportada", "edad_calculada", "comuna", "cesfam", "prevision",
    "total_hospitalizaciones", "primera_fecha_ingreso", "ultima_fecha_egreso",
    "dias_totales_estadia", "estado_actual", "tiene_issues_abiertos",
]
```

- [ ] **Step 4: Ejecutar tests**

```bash
.venv/bin/pytest tests/test_canonical_patients.py -v
```

Expected: 4 passed

- [ ] **Step 5: Commit**

```bash
git add scripts/build_hodom_canonical.py tests/test_canonical_patients.py
git commit -m "feat: agregar enrich_patient_master con campos agregados desde stays"
```

---

### Task 4: Episode source + pipeline health + coverage gaps

**Files:**
- Modify: `scripts/build_hodom_canonical.py`
- Create: `tests/test_canonical_health.py`

- [ ] **Step 1: Escribir tests**

```python
from __future__ import annotations

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "scripts"))


def test_build_episode_source(sample_episodes):
    from build_hodom_canonical import consolidate_stays, build_episode_source

    stays = consolidate_stays(sample_episodes)
    sources = build_episode_source(stays, sample_episodes)
    # 4 episodios originales = 4 filas de trazabilidad
    assert len(sources) == 4
    assert all("source_id" in s for s in sources)
    assert all("stay_id" in s for s in sources)
    assert all("origin_type" in s for s in sources)


def test_build_pipeline_health(sample_episodes, sample_quality_issues):
    from build_hodom_canonical import consolidate_stays, build_pipeline_health

    stays = consolidate_stays(sample_episodes)
    health = build_pipeline_health(stays, sample_quality_issues, [], 31)
    assert health["stays_total"] == "3"
    assert health["patients_total"] == "3"
    assert health["health_status"] in ("green", "yellow", "red")
    assert "run_timestamp" in health


def test_build_coverage_gaps():
    from build_hodom_canonical import build_coverage_gaps

    # Simular meses: ene-sep con ~80 stays, oct con 30 (gap)
    stays = []
    for month_num in range(1, 10):
        for i in range(80):
            stays.append({
                "stay_id": f"stay_{month_num}_{i}",
                "fecha_ingreso": f"2025-{month_num:02d}-{(i % 28) + 1:02d}",
                "fecha_egreso": f"2025-{month_num:02d}-{min((i % 28) + 10, 28):02d}",
            })
    # Octubre con solo 30
    for i in range(30):
        stays.append({
            "stay_id": f"stay_10_{i}",
            "fecha_ingreso": f"2025-10-{(i % 28) + 1:02d}",
            "fecha_egreso": f"2025-10-{min((i % 28) + 10, 28):02d}",
        })

    gaps = build_coverage_gaps(stays)
    oct_gaps = [g for g in gaps if g["month"] == "2025-10"]
    assert len(oct_gaps) > 0
    assert oct_gaps[0]["gap_flag"] == "True"


def test_pipeline_health_status_green(sample_episodes):
    from build_hodom_canonical import consolidate_stays, build_pipeline_health

    stays = consolidate_stays(sample_episodes)
    # Sin issues abiertos, sin gaps, sin duplicados
    health = build_pipeline_health(stays, [], [], 31)
    assert health["health_status"] == "green"
```

- [ ] **Step 2: Ejecutar tests para verificar que fallan**

```bash
.venv/bin/pytest tests/test_canonical_health.py -v
```

Expected: FAIL

- [ ] **Step 3: Implementar build_episode_source, build_pipeline_health, build_coverage_gaps**

Agregar a `scripts/build_hodom_canonical.py`:

```python
def build_episode_source(
    stays: list[dict[str, str]],
    episodes: list[dict[str, str]],
) -> list[dict[str, str]]:
    """Genera trazabilidad: cada episodio fuente mapeado a su stay."""
    episode_lookup = {ep["episode_id"]: ep for ep in episodes}
    sources: list[dict[str, str]] = []

    for stay in stays:
        source_ids = stay.get("source_episode_ids", "").split(" | ")
        for eid in source_ids:
            eid = eid.strip()
            if not eid:
                continue
            ep = episode_lookup.get(eid, {})
            sources.append({
                "source_id": make_id("src", f"{stay['stay_id']}|{eid}"),
                "stay_id": stay["stay_id"],
                "episode_id": eid,
                "raw_file": ep.get("raw_file", ""),
                "raw_row": ep.get("raw_row", ""),
                "origin_type": ep.get("episode_origin", "raw"),
                "fields_contributed": ep.get("fields_contributed", ""),
            })

    return sources


EPISODE_SOURCE_FIELDS = [
    "source_id", "stay_id", "episode_id", "raw_file", "raw_row", "origin_type",
    "fields_contributed",
]


def build_pipeline_health(
    stays: list[dict[str, str]],
    quality_issues: list[dict[str, str]],
    coverage_gaps: list[dict[str, str]],
    source_files_count: int,
) -> dict[str, str]:
    """Genera 1 fila de métricas de salud del pipeline."""
    patients = set(s["patient_id"] for s in stays if s.get("patient_id"))
    with_egreso = sum(1 for s in stays if s.get("fecha_egreso"))
    with_ingreso = sum(1 for s in stays if s.get("fecha_ingreso"))
    with_establishment = sum(1 for s in stays if s.get("establecimiento"))

    open_issues = [q for q in quality_issues if q.get("status") in ("OPEN", "REVIEW_REQUIRED")]
    issues_open = sum(1 for q in open_issues if q.get("status") == "OPEN")
    issues_review = sum(1 for q in open_issues if q.get("status") == "REVIEW_REQUIRED")

    total = len(stays) or 1
    pct_open = (issues_open + issues_review) / total

    gaps_detected = sum(1 for g in coverage_gaps if g.get("gap_flag") == "True")

    if pct_open > 0.15 or gaps_detected > 2:
        status = "red"
    elif pct_open > 0.05 or gaps_detected > 0:
        status = "yellow"
    else:
        status = "green"

    return {
        "run_id": make_id("run", datetime.now().isoformat()),
        "run_timestamp": datetime.now().isoformat(timespec="seconds"),
        "source_files_processed": str(source_files_count),
        "raw_rows_processed": "",
        "patients_total": str(len(patients)),
        "stays_total": str(len(stays)),
        "stays_with_egreso": str(with_egreso),
        "stays_with_ingreso": str(with_ingreso),
        "stays_with_establishment": str(with_establishment),
        "issues_open": str(issues_open),
        "issues_review_required": str(issues_review),
        "review_queue_pending": "",
        "duplicate_candidates": "",
        "coverage_gaps_detected": str(gaps_detected),
        "health_status": status,
    }


PIPELINE_HEALTH_FIELDS = [
    "run_id", "run_timestamp", "source_files_processed", "raw_rows_processed",
    "patients_total", "stays_total", "stays_with_egreso", "stays_with_ingreso",
    "stays_with_establishment", "issues_open", "issues_review_required",
    "review_queue_pending", "duplicate_candidates", "coverage_gaps_detected",
    "health_status",
]


def build_coverage_gaps(stays: list[dict[str, str]]) -> list[dict[str, str]]:
    """Detecta meses con cobertura inferior al 70% del promedio móvil 6 meses."""
    from collections import Counter

    monthly: Counter[str] = Counter()
    for stay in stays:
        fi = stay.get("fecha_ingreso", "")[:7]
        if fi:
            monthly[fi] += 1

    if not monthly:
        return []

    sorted_months = sorted(monthly.keys())
    gaps: list[dict[str, str]] = []

    for i, month in enumerate(sorted_months):
        # Promedio móvil de los 6 meses anteriores
        window = [monthly[sorted_months[j]] for j in range(max(0, i - 6), i)]
        if not window:
            continue
        expected = sum(window) / len(window)
        observed = monthly[month]
        ratio = observed / expected if expected > 0 else 1.0
        is_gap = ratio < 0.70

        gaps.append({
            "month": month,
            "metric": "ingresos",
            "observed": str(observed),
            "expected": str(round(expected)),
            "ratio": f"{ratio:.2f}",
            "gap_flag": str(is_gap),
        })

    return gaps


COVERAGE_GAP_FIELDS = [
    "month", "metric", "observed", "expected", "ratio", "gap_flag",
]
```

- [ ] **Step 4: Ejecutar tests**

```bash
.venv/bin/pytest tests/test_canonical_health.py -v
```

Expected: 4 passed

- [ ] **Step 5: Commit**

```bash
git add scripts/build_hodom_canonical.py tests/test_canonical_health.py
git commit -m "feat: agregar episode_source, pipeline_health y coverage_gaps al canonical builder"
```

---

### Task 5: Review queue unificada + quality issues filtrados + duplicate candidates

**Files:**
- Modify: `scripts/build_hodom_canonical.py`
- Create: `tests/test_canonical_queues.py`

- [ ] **Step 1: Escribir tests**

```python
from __future__ import annotations

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "scripts"))


def test_build_unified_review_queue(sample_match_review_queue, sample_identity_review,
                                     sample_discharge_events, sample_quality_issues):
    from build_hodom_canonical import build_unified_review_queue

    queue = build_unified_review_queue(
        sample_match_review_queue,
        sample_identity_review,
        sample_discharge_events,
        sample_quality_issues,
    )
    assert len(queue) >= 3  # 1 match + 1 identity + 1 discharge + quality issues
    types = {q["queue_type"] for q in queue}
    assert "unmatched_form" in types
    assert "identity" in types
    assert "unresolved_discharge" in types


def test_filter_quality_issues_only_open(sample_quality_issues):
    from build_hodom_canonical import filter_actionable_quality_issues

    filtered = filter_actionable_quality_issues(sample_quality_issues)
    # Solo OPEN y REVIEW_REQUIRED, no RESOLVED_AUTO
    assert len(filtered) == 3
    assert all(q["status"] in ("OPEN", "REVIEW_REQUIRED") for q in filtered)


def test_build_duplicate_candidates(sample_episodes):
    from build_hodom_canonical import consolidate_stays, build_duplicate_candidates

    stays = consolidate_stays(sample_episodes)
    candidates = build_duplicate_candidates(stays, [])
    # No debería haber duplicados en los datos de prueba (ya consolidados)
    assert isinstance(candidates, list)


def test_build_duplicate_candidates_detects_same_rut_different_patient():
    from build_hodom_canonical import build_duplicate_candidates

    stays = [
        {"stay_id": "s1", "patient_id": "pt_A", "rut": "12345678-5",
         "nombre_completo": "JUAN PEREZ", "fecha_ingreso": "2025-10-01",
         "fecha_egreso": "2025-10-15", "comuna": "SAN CARLOS"},
        {"stay_id": "s2", "patient_id": "pt_B", "rut": "12345678-5",
         "nombre_completo": "JUAN PEREZ SOTO", "fecha_ingreso": "2025-10-02",
         "fecha_egreso": "2025-10-16", "comuna": "SAN CARLOS"},
    ]
    patients = [
        {"patient_id": "pt_A", "rut": "12345678-5", "nombre_completo": "JUAN PEREZ", "comuna": "SAN CARLOS"},
        {"patient_id": "pt_B", "rut": "12345678-5", "nombre_completo": "JUAN PEREZ SOTO", "comuna": "SAN CARLOS"},
    ]
    candidates = build_duplicate_candidates(stays, patients)
    assert len(candidates) >= 1
    assert candidates[0]["match_reason"] == "same_rut_similar_dates"
```

- [ ] **Step 2: Ejecutar tests para verificar que fallan**

```bash
.venv/bin/pytest tests/test_canonical_queues.py -v
```

Expected: FAIL

- [ ] **Step 3: Implementar las 3 funciones**

Agregar a `scripts/build_hodom_canonical.py`:

```python
def build_unified_review_queue(
    match_queue: list[dict[str, str]],
    identity_queue: list[dict[str, str]],
    discharge_events: list[dict[str, str]],
    quality_issues: list[dict[str, str]],
) -> list[dict[str, str]]:
    """Unifica todas las colas de revisión en una sola."""
    queue: list[dict[str, str]] = []

    # Formularios sin match
    for item in match_queue:
        if item.get("auto_close_recommended") == "1":
            continue
        queue.append({
            "queue_item_id": make_id("q", f"form|{item.get('form_submission_id', '')}"),
            "queue_type": "unmatched_form",
            "entity_id": item.get("form_submission_id", ""),
            "patient_name": item.get("patient_name", ""),
            "patient_rut": item.get("patient_rut", ""),
            "summary": f"Formulario {item.get('request_prestacion', '')} - {item.get('diagnostico_form', '')} ({item.get('servicio_origen_solicitud', '')})",
            "candidate_ids": item.get("candidate_episode_id", ""),
            "candidate_scores": item.get("candidate_score", ""),
            "priority": "high" if int(item.get("candidate_score", "0") or "0") >= 60 else "medium",
            "created_at": item.get("submission_timestamp", ""),
        })

    # Egresos sin resolver
    for item in discharge_events:
        if item.get("match_status", "") != "unresolved":
            continue
        queue.append({
            "queue_item_id": make_id("q", f"discharge|{item.get('discharge_event_id', '')}"),
            "queue_type": "unresolved_discharge",
            "entity_id": item.get("discharge_event_id", ""),
            "patient_name": item.get("nombre_completo", ""),
            "patient_rut": item.get("rut_norm", ""),
            "summary": f"Alta {item.get('fecha_egreso', '')} - {item.get('diagnostico', '')} ({item.get('motivo_egreso', '')})",
            "candidate_ids": item.get("matched_episode_id", ""),
            "candidate_scores": "",
            "priority": "medium",
            "created_at": item.get("fecha_egreso", ""),
        })

    # Identidad
    for item in identity_queue:
        queue.append({
            "queue_item_id": make_id("q", f"identity|{item.get('identity_review_id', '')}"),
            "queue_type": "identity",
            "entity_id": item.get("patient_id", ""),
            "patient_name": item.get("nombre_completo", ""),
            "patient_rut": item.get("rut", ""),
            "summary": f"{item.get('issue_type', '')}: valor={item.get('raw_value', '')} sugerido={item.get('suggested_value', '')}",
            "candidate_ids": item.get("episode_id", ""),
            "candidate_scores": "",
            "priority": "low",
            "created_at": "",
        })

    # Pacientes sin episodio
    for issue in quality_issues:
        if issue.get("issue_type") == "PATIENT_WITHOUT_EPISODE" and issue.get("status") == "REVIEW_REQUIRED":
            queue.append({
                "queue_item_id": make_id("q", f"orphan|{issue.get('quality_issue_id', '')}"),
                "queue_type": "patient_orphan",
                "entity_id": issue.get("episode_id", issue.get("normalized_row_id", "")),
                "patient_name": "",
                "patient_rut": "",
                "summary": f"Paciente sin episodio asociado",
                "candidate_ids": "",
                "candidate_scores": "",
                "priority": "low",
                "created_at": "",
            })

    # Establecimientos sin resolver
    for issue in quality_issues:
        if issue.get("issue_type") == "ESTABLISHMENT_UNRESOLVED" and issue.get("status") == "OPEN":
            queue.append({
                "queue_item_id": make_id("q", f"estab|{issue.get('quality_issue_id', '')}"),
                "queue_type": "establishment",
                "entity_id": issue.get("episode_id", ""),
                "patient_name": "",
                "patient_rut": "",
                "summary": f"Establecimiento no resuelto: {issue.get('raw_value', '')}",
                "candidate_ids": "",
                "candidate_scores": "",
                "priority": "low",
                "created_at": "",
            })

    return queue


REVIEW_QUEUE_FIELDS = [
    "queue_item_id", "queue_type", "entity_id", "patient_name", "patient_rut",
    "summary", "candidate_ids", "candidate_scores", "priority", "created_at",
]


def filter_actionable_quality_issues(
    quality_issues: list[dict[str, str]],
) -> list[dict[str, str]]:
    """Filtra solo issues abiertos con acción requerida."""
    return [
        {
            "issue_id": q.get("quality_issue_id", ""),
            "issue_type": q.get("issue_type", ""),
            "severity": q.get("severity", ""),
            "entity_type": "episode" if q.get("episode_id") else "patient",
            "entity_id": q.get("episode_id", "") or q.get("normalized_row_id", ""),
            "description": f"{q.get('issue_type', '')}: {q.get('raw_value', '')}",
            "raw_value": q.get("raw_value", ""),
            "suggested_value": q.get("suggested_value", ""),
            "status": q.get("status", ""),
            "created_at": "",
        }
        for q in quality_issues
        if q.get("status", "") in ("OPEN", "REVIEW_REQUIRED")
    ]


QUALITY_ISSUE_FIELDS = [
    "issue_id", "issue_type", "severity", "entity_type", "entity_id",
    "description", "raw_value", "suggested_value", "status", "created_at",
]


def build_duplicate_candidates(
    stays: list[dict[str, str]],
    patients: list[dict[str, str]],
) -> list[dict[str, str]]:
    """Detecta pares sospechosos de duplicación en stays y pacientes."""
    import difflib

    candidates: list[dict[str, str]] = []
    seen_pairs: set[tuple[str, str]] = set()

    # Duplicados de stays: mismo RUT, fechas solapadas, patient_id distinto
    rut_stays: dict[str, list[dict[str, str]]] = {}
    for stay in stays:
        rut = stay.get("rut", "")
        if rut:
            rut_stays.setdefault(rut, []).append(stay)

    for rut, group in rut_stays.items():
        if len(group) < 2:
            continue
        for i in range(len(group)):
            for j in range(i + 1, len(group)):
                a, b = group[i], group[j]
                if a["patient_id"] == b["patient_id"] and a["stay_id"] == b["stay_id"]:
                    continue
                pair = tuple(sorted([a["stay_id"], b["stay_id"]]))
                if pair in seen_pairs:
                    continue
                fi_a, fi_b = a.get("fecha_ingreso", ""), b.get("fecha_ingreso", "")
                if fi_a and fi_b:
                    try:
                        diff = abs((date.fromisoformat(fi_a) - date.fromisoformat(fi_b)).days)
                        if diff <= 7:
                            seen_pairs.add(pair)
                            candidates.append({
                                "candidate_id": make_id("dup", f"{pair[0]}|{pair[1]}"),
                                "entity_type": "stay",
                                "entity_a_id": a["stay_id"],
                                "entity_b_id": b["stay_id"],
                                "match_reason": "same_rut_similar_dates",
                                "confidence": f"{max(0.5, 1.0 - diff * 0.1):.2f}",
                                "reviewed": "False",
                                "resolution": "",
                            })
                    except ValueError:
                        pass

    # Duplicados de pacientes: mismo RUT, patient_id distinto
    rut_patients: dict[str, list[dict[str, str]]] = {}
    for p in patients:
        rut = p.get("rut", "")
        if rut:
            rut_patients.setdefault(rut, []).append(p)

    for rut, group in rut_patients.items():
        if len(group) < 2:
            continue
        for i in range(len(group)):
            for j in range(i + 1, len(group)):
                a, b = group[i], group[j]
                pair = tuple(sorted([a["patient_id"], b["patient_id"]]))
                if pair in seen_pairs:
                    continue
                seen_pairs.add(pair)
                candidates.append({
                    "candidate_id": make_id("dup", f"{pair[0]}|{pair[1]}"),
                    "entity_type": "patient",
                    "entity_a_id": a["patient_id"],
                    "entity_b_id": b["patient_id"],
                    "match_reason": "same_rut_different_patient",
                    "confidence": "0.90",
                    "reviewed": "False",
                    "resolution": "",
                })

    # Pacientes con nombre muy similar y misma comuna
    for i in range(len(patients)):
        for j in range(i + 1, len(patients)):
            a, b = patients[i], patients[j]
            if a["patient_id"] == b["patient_id"]:
                continue
            pair = tuple(sorted([a["patient_id"], b["patient_id"]]))
            if pair in seen_pairs:
                continue
            name_a = a.get("nombre_completo", "").strip().upper()
            name_b = b.get("nombre_completo", "").strip().upper()
            comuna_a = a.get("comuna", "").strip().upper()
            comuna_b = b.get("comuna", "").strip().upper()
            if name_a and name_b and comuna_a == comuna_b and comuna_a:
                similarity = difflib.SequenceMatcher(None, name_a, name_b).ratio()
                if similarity >= 0.90:
                    seen_pairs.add(pair)
                    candidates.append({
                        "candidate_id": make_id("dup", f"{pair[0]}|{pair[1]}"),
                        "entity_type": "patient",
                        "entity_a_id": a["patient_id"],
                        "entity_b_id": b["patient_id"],
                        "match_reason": "similar_name_same_comuna",
                        "confidence": f"{similarity:.2f}",
                        "reviewed": "False",
                        "resolution": "",
                    })

    return candidates


DUPLICATE_CANDIDATE_FIELDS = [
    "candidate_id", "entity_type", "entity_a_id", "entity_b_id",
    "match_reason", "confidence", "reviewed", "resolution",
]
```

- [ ] **Step 4: Ejecutar tests**

```bash
.venv/bin/pytest tests/test_canonical_queues.py -v
```

Expected: 4 passed

- [ ] **Step 5: Commit**

```bash
git add scripts/build_hodom_canonical.py tests/test_canonical_queues.py
git commit -m "feat: agregar review_queue unificada, quality_issues filtrados y duplicate_candidates"
```

---

### Task 6: Manual resolution reader + main() del canonical builder

**Files:**
- Modify: `scripts/build_hodom_canonical.py`
- Create: `tests/test_manual_resolution.py`

- [ ] **Step 1: Escribir tests**

```python
from __future__ import annotations

import csv
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "scripts"))
from conftest import write_csv_to_path


def test_read_manual_resolutions(tmp_path):
    from build_hodom_canonical import read_manual_resolutions

    path = tmp_path / "manual_resolution.csv"
    write_csv_to_path(path, [
        {
            "resolution_id": "res_001",
            "queue_type": "unmatched_form",
            "item_id": "fs_100",
            "action": "associate",
            "target_id": "ep_050",
            "field_corrected": "",
            "old_value": "",
            "new_value": "",
            "resolved_by": "gestora1",
            "resolved_at": "2026-04-01T10:00:00",
            "applied": "False",
        },
    ])
    resolutions = read_manual_resolutions(path)
    assert len(resolutions) == 1
    assert resolutions[0]["action"] == "associate"
    assert resolutions[0]["applied"] == "False"


def test_read_manual_resolutions_empty(tmp_path):
    from build_hodom_canonical import read_manual_resolutions

    path = tmp_path / "manual_resolution.csv"
    resolutions = read_manual_resolutions(path)
    assert resolutions == []


def test_apply_resolutions_discard_removes_from_queue():
    from build_hodom_canonical import apply_resolutions_to_queue

    queue = [
        {"queue_item_id": "q_001", "queue_type": "unmatched_form", "entity_id": "fs_100"},
        {"queue_item_id": "q_002", "queue_type": "unmatched_form", "entity_id": "fs_200"},
    ]
    resolutions = [
        {"item_id": "fs_100", "action": "discard", "applied": "False"},
    ]
    filtered = apply_resolutions_to_queue(queue, resolutions)
    assert len(filtered) == 1
    assert filtered[0]["entity_id"] == "fs_200"


def test_canonical_main_produces_all_outputs(tmp_enriched_dir):
    from build_hodom_canonical import build_canonical_outputs

    output_dir = tmp_enriched_dir.parent / "canonical_out"
    output_dir.mkdir()

    build_canonical_outputs(tmp_enriched_dir, output_dir, tmp_enriched_dir.parent / "manual")

    expected_files = [
        "hospitalization_stay.csv",
        "patient_master.csv",
        "episode_source.csv",
        "pipeline_health.csv",
        "quality_issue.csv",
        "review_queue.csv",
        "coverage_gap.csv",
        "duplicate_candidate.csv",
    ]
    for name in expected_files:
        assert (output_dir / name).exists(), f"Missing: {name}"
```

- [ ] **Step 2: Ejecutar tests para verificar que fallan**

```bash
.venv/bin/pytest tests/test_manual_resolution.py -v
```

Expected: FAIL

- [ ] **Step 3: Implementar read_manual_resolutions, apply_resolutions_to_queue y build_canonical_outputs**

Agregar a `scripts/build_hodom_canonical.py`:

```python
def read_manual_resolutions(path: Path) -> list[dict[str, str]]:
    """Lee manual_resolution.csv. Retorna lista vacía si no existe."""
    if not path.exists():
        return []
    return read_csv(path)


MANUAL_RESOLUTION_FIELDS = [
    "resolution_id", "queue_type", "item_id", "action", "target_id",
    "field_corrected", "old_value", "new_value", "resolved_by",
    "resolved_at", "applied",
]


def apply_resolutions_to_queue(
    queue: list[dict[str, str]],
    resolutions: list[dict[str, str]],
) -> list[dict[str, str]]:
    """Filtra items de la cola que ya fueron resueltos (discard/associate)."""
    resolved_ids = {
        r["item_id"]
        for r in resolutions
        if r.get("action") in ("discard", "associate", "merge") and r.get("applied") != "True"
    }
    return [q for q in queue if q.get("entity_id") not in resolved_ids]


def build_canonical_outputs(
    enriched_dir: Path,
    output_dir: Path,
    manual_dir: Path,
) -> None:
    """Función principal: lee enriquecidos, aplica resoluciones, genera capa canónica."""
    output_dir.mkdir(parents=True, exist_ok=True)

    # Leer enriquecidos
    episodes = read_csv(enriched_dir / "episode_master.csv")
    patients = read_csv(enriched_dir / "patient_master.csv")
    quality_issues = read_csv(enriched_dir / "data_quality_issue.csv")
    match_queue = read_csv(enriched_dir / "match_review_queue.csv")
    identity_queue = read_csv(enriched_dir / "identity_review_queue.csv")
    discharge_events = read_csv(enriched_dir / "normalized_discharge_event.csv")
    establishments = read_csv(enriched_dir / "establishment_reference.csv")

    # Leer resoluciones manuales
    resolutions = read_manual_resolutions(manual_dir / "manual_resolution.csv")

    # Contar fuentes
    source_files = read_csv(enriched_dir / ".." / "intermediate" / "raw_source_file.csv")
    source_count = len(source_files) if source_files else 0

    # 1. Consolidar stays
    stays = consolidate_stays(episodes)

    # 2. Enriquecer pacientes
    enriched_patients = enrich_patient_master(patients, stays, quality_issues)

    # 3. Trazabilidad
    episode_sources = build_episode_source(stays, episodes)

    # 4. Quality issues filtrados
    filtered_issues = filter_actionable_quality_issues(quality_issues)

    # 5. Cola unificada
    review_queue = build_unified_review_queue(
        match_queue, identity_queue, discharge_events, quality_issues,
    )
    review_queue = apply_resolutions_to_queue(review_queue, resolutions)

    # 6. Coverage gaps
    coverage_gaps = build_coverage_gaps(stays)

    # 7. Duplicate candidates
    duplicate_candidates = build_duplicate_candidates(stays, enriched_patients)

    # 8. Pipeline health
    health = build_pipeline_health(stays, quality_issues, coverage_gaps, source_count)
    health["review_queue_pending"] = str(len(review_queue))
    health["duplicate_candidates"] = str(len(duplicate_candidates))

    # Escribir outputs
    write_csv(output_dir / "hospitalization_stay.csv", stays, HOSPITALIZATION_STAY_FIELDS)
    write_csv(output_dir / "patient_master.csv", enriched_patients, PATIENT_MASTER_FIELDS)
    write_csv(output_dir / "episode_source.csv", episode_sources, EPISODE_SOURCE_FIELDS)
    write_csv(output_dir / "pipeline_health.csv", [health], PIPELINE_HEALTH_FIELDS)
    write_csv(output_dir / "quality_issue.csv", filtered_issues, QUALITY_ISSUE_FIELDS)
    write_csv(output_dir / "review_queue.csv", review_queue, REVIEW_QUEUE_FIELDS)
    write_csv(output_dir / "coverage_gap.csv", coverage_gaps, COVERAGE_GAP_FIELDS)
    write_csv(output_dir / "duplicate_candidate.csv", duplicate_candidates, DUPLICATE_CANDIDATE_FIELDS)

    # Copiar referencia sin cambios
    for name in ("establishment_reference.csv", "locality_reference.csv"):
        src = enriched_dir / name
        if src.exists():
            import shutil
            shutil.copy2(src, output_dir / name)

    print(f"Canonical outputs written to {output_dir}")
    print(f"  stays: {len(stays)}")
    print(f"  patients: {len(enriched_patients)}")
    print(f"  review_queue: {len(review_queue)}")
    print(f"  coverage_gaps: {len(coverage_gaps)}")
    print(f"  duplicate_candidates: {len(duplicate_candidates)}")
    print(f"  health_status: {health['health_status']}")


def main() -> None:
    parser = argparse.ArgumentParser(description="Genera capa canónica estabilizada para dashboard admin HODOM.")
    parser.add_argument("--enriched-dir", type=Path, default=Path("output/spreadsheet/enriched"))
    parser.add_argument("--output-dir", type=Path, default=Path("output/spreadsheet/canonical"))
    parser.add_argument("--manual-dir", type=Path, default=Path("input/manual"))
    args = parser.parse_args()

    build_canonical_outputs(args.enriched_dir, args.output_dir, args.manual_dir)


if __name__ == "__main__":
    main()
```

- [ ] **Step 4: Ejecutar tests**

```bash
.venv/bin/pytest tests/test_manual_resolution.py -v
```

Expected: 4 passed

- [ ] **Step 5: Ejecutar todos los tests para verificar que nada se rompió**

```bash
.venv/bin/pytest tests/ -v
```

Expected: All passed

- [ ] **Step 6: Commit**

```bash
git add scripts/build_hodom_canonical.py tests/test_manual_resolution.py
git commit -m "feat: completar canonical builder con main(), manual_resolution y build_canonical_outputs"
```

---

### Task 7: Integrar canonical builder en scripts de ejecución

**Files:**
- Modify: `scripts/refresh_data_and_run_dashboard.sh`
- Create: `scripts/run_canonical_builder.sh`

- [ ] **Step 1: Leer script actual de refresh**

```bash
cat scripts/refresh_data_and_run_dashboard.sh
```

- [ ] **Step 2: Crear script standalone para canonical builder**

Crear `scripts/run_canonical_builder.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
.venv/bin/python scripts/build_hodom_canonical.py "$@"
```

- [ ] **Step 3: Agregar paso canónico al refresh script**

Modificar `scripts/refresh_data_and_run_dashboard.sh` para agregar después del paso enriched y antes del streamlit:

```bash
# Paso 4: Generar capa canónica
.venv/bin/python scripts/build_hodom_canonical.py
```

- [ ] **Step 4: Hacer ejecutable y probar**

```bash
chmod +x scripts/run_canonical_builder.sh
.venv/bin/python scripts/build_hodom_canonical.py --enriched-dir output/spreadsheet/enriched --output-dir output/spreadsheet/canonical
```

Expected: CSVs generados en `output/spreadsheet/canonical/` con salida tipo:
```
Canonical outputs written to output/spreadsheet/canonical
  stays: ~1700
  patients: ~1468
  ...
```

- [ ] **Step 5: Commit**

```bash
git add scripts/run_canonical_builder.sh scripts/refresh_data_and_run_dashboard.sh
git commit -m "feat: integrar canonical builder en scripts de ejecución"
```

---

### Task 8: Refactorizar dashboard admin para consumir capa canónica

**Files:**
- Modify: `streamlit_admin_app.py`

- [ ] **Step 1: Modificar load_admin_data() para leer desde canonical**

Cambiar la función `load_admin_data()` en `streamlit_admin_app.py` para que:
1. Busque primero en `output/spreadsheet/canonical/`
2. Lea `hospitalization_stay.csv` directamente (ya no necesita `build_hospitalization_stays()` en runtime)
3. Lea `patient_master.csv` enriquecido (ya trae campos agregados)
4. Lea `pipeline_health.csv`, `review_queue.csv`, `coverage_gap.csv`, `quality_issue.csv`, `duplicate_candidate.csv`

```python
CANONICAL_DIR = BASE_DIR / "output" / "spreadsheet" / "canonical"

def read_csv(name: str) -> pd.DataFrame:
    for directory in (CANONICAL_DIR, ENRICHED_DIR, INTERMEDIATE_DIR):
        path = directory / name
        if path.exists():
            return pd.read_csv(path)
    raise FileNotFoundError(f"No existe: {name}")
```

- [ ] **Step 2: Simplificar load_admin_data() — usar stays precalculados**

Reemplazar el bloque que llama `build_hospitalization_stays(merged)` por lectura directa:

```python
@st.cache_data(show_spinner=False)
def load_admin_data() -> dict[str, pd.DataFrame]:
    stays = read_csv("hospitalization_stay.csv")
    patients = read_csv("patient_master.csv")
    establishments = read_csv_optional("establishment_reference.csv")
    localities = read_csv_optional("locality_reference.csv")
    pipeline_health = read_csv_optional("pipeline_health.csv")
    review_queue = read_csv_optional("review_queue.csv")
    coverage_gaps = read_csv_optional("coverage_gap.csv")
    quality_issues = read_csv_optional("quality_issue.csv")
    duplicate_candidates = read_csv_optional("duplicate_candidate.csv")

    # Parsear fechas en stays
    stays["fecha_ingreso"] = pd.to_datetime(stays["fecha_ingreso"], errors="coerce")
    stays["fecha_egreso"] = pd.to_datetime(stays["fecha_egreso"], errors="coerce")
    stays["activity_date"] = stays["fecha_ingreso"].combine_first(stays["fecha_egreso"])
    stays["activity_month"] = stays["activity_date"].dt.to_period("M").astype("string")
    stays["estadia_util"] = (stays["fecha_egreso"] - stays["fecha_ingreso"]).dt.days
    stays["estado"] = stays["estado"].fillna("SIN_ESTADO")
    stays["prevision"] = stays["prevision"].fillna("SIN_PREVISION")
    stays["servicio_origen"] = stays["servicio_origen"].fillna("SIN_SERVICIO")
    stays["motivo_egreso"] = stays["motivo_egreso"].fillna("")
    stays["diagnostico_principal"] = stays["diagnostico_principal"].fillna("SIN_DIAGNOSTICO")
    stays["episode_origin"] = stays["episode_origin"].fillna("raw")
    stays["nombre_completo"] = stays["nombre_completo"].fillna("")
    stays["rut"] = stays["rut"].fillna("")
    stays["comuna"] = stays["comuna"].fillna("")

    stays["rango_etario"] = pd.cut(
        pd.to_numeric(stays["edad_reportada"], errors="coerce"),
        bins=[-1, 14, 19, 59, 150],
        labels=["<15", "15-19", "20-59", ">=60"],
    ).astype("string")

    # Parsear fechas en patients
    patients["fecha_nacimiento_date"] = pd.to_datetime(patients["fecha_nacimiento_date"], errors="coerce")
    patients["edad_reportada"] = pd.to_numeric(patients["edad_reportada"], errors="coerce")
    patients["total_hospitalizaciones"] = pd.to_numeric(patients["total_hospitalizaciones"], errors="coerce").fillna(0).astype(int)

    return {
        "stays": stays,
        "patients": patients,
        "establishments": establishments,
        "localities": localities,
        "pipeline_health": pipeline_health,
        "review_queue": review_queue,
        "coverage_gaps": coverage_gaps,
        "quality_issues": quality_issues,
        "duplicate_candidates": duplicate_candidates,
    }
```

- [ ] **Step 3: Actualizar render_admin_hospitalizations para usar campos canónicos**

Cambiar la referencia de `diagnostico_principal_texto` a `diagnostico_principal` y `establecimiento_resuelto` a `establecimiento` en las columnas de la tabla:

```python
columns = [
    "stay_id",
    "nombre_completo",
    "rut",
    "estado",
    "fecha_ingreso",
    "fecha_egreso",
    "estadia_util",
    "source_episode_count",
    "servicio_origen",
    "prevision",
    "establecimiento",
    "comuna",
    "diagnostico_principal",
]
```

- [ ] **Step 4: Actualizar render_admin_patients para usar patient_master enriquecido**

```python
def render_admin_patients(stays: pd.DataFrame, patients: pd.DataFrame) -> None:
    st.subheader("Pacientes")
    st.dataframe(
        patients[
            [
                "nombre_completo",
                "rut",
                "sexo",
                "edad_reportada",
                "comuna",
                "cesfam",
                "total_hospitalizaciones",
                "primera_fecha_ingreso",
                "ultima_fecha_egreso",
                "estado_actual",
                "tiene_issues_abiertos",
            ]
        ].sort_values(["total_hospitalizaciones", "nombre_completo"], ascending=[False, True]),
        use_container_width=True,
        hide_index=True,
    )
```

- [ ] **Step 5: Actualizar render_admin_rem para usar campos canónicos**

Cambiar `diagnostico_principal_texto` → `diagnostico_principal`, `establecimiento_resuelto` → `establecimiento`, `comuna_resuelta` → `comuna` en todas las funciones REM.

- [ ] **Step 6: Actualizar render_admin_territory para campos canónicos**

Cambiar `codigo_deis_resuelto` → `codigo_deis`, `establecimiento_resuelto` → `establecimiento`, `latitud_localidad` → `latitud`, `longitud_localidad` → `longitud`.

- [ ] **Step 7: Actualizar filter_admin_data y apply_non_temporal_admin_filters para campos canónicos**

Cambiar `comuna_resuelta` → `comuna`, `provincia_resuelta` → `provincia` (o eliminar si no existe en canonical), `establecimiento_resuelto` → `establecimiento`.

- [ ] **Step 8: Eliminar funciones obsoletas**

Eliminar de `streamlit_admin_app.py`:
- `build_hospitalization_stays()` — ya no se usa
- `stay_row_score()` — ya no se usa
- El bloque de merge complejo en `load_admin_data()` que hacía joins con establishments y localities — los stays canónicos ya traen esos campos

- [ ] **Step 9: Validar compilación**

```bash
python3 -m py_compile streamlit_admin_app.py
```

Expected: sin errores

- [ ] **Step 10: Commit**

```bash
git add streamlit_admin_app.py
git commit -m "refactor: dashboard admin consume capa canónica en lugar de recalcular stays en runtime"
```

---

### Task 9: Tab "Salud del Pipeline"

**Files:**
- Modify: `streamlit_admin_app.py`

- [ ] **Step 1: Agregar función render_pipeline_health**

```python
def render_pipeline_health(
    pipeline_health: pd.DataFrame,
    coverage_gaps: pd.DataFrame,
    quality_issues: pd.DataFrame,
    review_queue: pd.DataFrame,
    duplicate_candidates: pd.DataFrame,
) -> None:
    st.subheader("Salud del Pipeline")

    # Semáforo general
    if not pipeline_health.empty:
        latest = pipeline_health.iloc[-1]
        status = latest.get("health_status", "yellow")
        color_map = {"green": "#1B8A6B", "yellow": "#D4A017", "red": "#C0392B"}
        label_map = {"green": "CONFIABLE", "yellow": "ATENCIÓN", "red": "REVISAR"}
        st.markdown(
            f'<div style="background:{color_map.get(status, "#999")};color:white;padding:1rem;'
            f'border-radius:0.8rem;text-align:center;font-size:1.4rem;font-weight:700;">'
            f'{label_map.get(status, "?")} — Estado general del pipeline</div>',
            unsafe_allow_html=True,
        )
        st.caption(f"Última ejecución: {latest.get('run_timestamp', 's/d')}")

        # Tarjetas
        c1, c2, c3, c4 = st.columns(4)
        c1.metric("Stays totales", latest.get("stays_total", "0"))
        c2.metric("Pacientes", latest.get("patients_total", "0"))
        c3.metric("% con egreso", f"{int(latest.get('stays_with_egreso', 0)) / max(int(latest.get('stays_total', 1)), 1) * 100:.0f}%")
        c4.metric("% con establecimiento", f"{int(latest.get('stays_with_establishment', 0)) / max(int(latest.get('stays_total', 1)), 1) * 100:.0f}%")

        c5, c6, c7, c8 = st.columns(4)
        c5.metric("Issues abiertos", latest.get("issues_open", "0"))
        c6.metric("Revisión requerida", latest.get("issues_review_required", "0"))
        c7.metric("Cola pendiente", latest.get("review_queue_pending", "0"))
        c8.metric("Duplicados detectados", latest.get("duplicate_candidates", "0"))
    else:
        st.warning("No hay datos de salud del pipeline. Ejecuta el canonical builder primero.")

    # Cobertura mensual
    st.markdown("---")
    st.caption("Cobertura mensual: observado vs esperado")
    if not coverage_gaps.empty:
        cg = coverage_gaps.copy()
        cg["observed"] = pd.to_numeric(cg["observed"], errors="coerce")
        cg["expected"] = pd.to_numeric(cg["expected"], errors="coerce")
        cg["gap_flag"] = cg["gap_flag"].eq("True")
        chart_data = cg.set_index("month")[["observed", "expected"]]
        st.line_chart(chart_data)
        gaps_only = cg[cg["gap_flag"]]
        if not gaps_only.empty:
            st.warning(f"Gaps detectados en: {', '.join(gaps_only['month'].tolist())}")
    else:
        st.info("Sin datos de cobertura.")

    # Issues por tipo
    if not quality_issues.empty:
        st.markdown("---")
        st.caption("Issues abiertos por tipo")
        issue_counts = quality_issues["issue_type"].value_counts()
        st.bar_chart(issue_counts)
```

- [ ] **Step 2: Agregar el tab al main()**

Modificar la sección de tabs en `main()`:

```python
overview_tab, hosp_tab, patient_tab, rem_tab, territory_tab, health_tab, resolution_tab, methodology_tab = st.tabs(
    ["Resumen", "Hospitalizaciones", "Pacientes", "REM A21/C1", "Territorio",
     "Salud del Pipeline", "Revisión y Resolución", "Metodología"]
)
# ...
with health_tab:
    render_pipeline_health(
        datasets["pipeline_health"],
        datasets["coverage_gaps"],
        datasets["quality_issues"],
        datasets["review_queue"],
        datasets["duplicate_candidates"],
    )
```

- [ ] **Step 3: Validar compilación**

```bash
python3 -m py_compile streamlit_admin_app.py
```

- [ ] **Step 4: Commit**

```bash
git add streamlit_admin_app.py
git commit -m "feat: agregar tab Salud del Pipeline con semáforo, métricas y cobertura mensual"
```

---

### Task 10: Tab "Revisión y Resolución" — estructura + formularios sin match

**Files:**
- Modify: `streamlit_admin_app.py`

- [ ] **Step 1: Agregar función de escritura de resoluciones**

```python
MANUAL_RESOLUTION_PATH = BASE_DIR / "input" / "manual" / "manual_resolution.csv"

RESOLUTION_FIELDS = [
    "resolution_id", "queue_type", "item_id", "action", "target_id",
    "field_corrected", "old_value", "new_value", "resolved_by",
    "resolved_at", "applied",
]


def append_resolution(
    item_id: str,
    queue_type: str,
    action: str,
    target_id: str = "",
    field_corrected: str = "",
    old_value: str = "",
    new_value: str = "",
    resolved_by: str = "dashboard",
) -> None:
    """Agrega una resolución manual a manual_resolution.csv."""
    MANUAL_RESOLUTION_PATH.parent.mkdir(parents=True, exist_ok=True)
    file_exists = MANUAL_RESOLUTION_PATH.exists() and MANUAL_RESOLUTION_PATH.stat().st_size > 0
    row = {
        "resolution_id": f"res_{datetime.now().strftime('%Y%m%d%H%M%S')}_{item_id[:8]}",
        "queue_type": queue_type,
        "item_id": item_id,
        "action": action,
        "target_id": target_id,
        "field_corrected": field_corrected,
        "old_value": old_value,
        "new_value": new_value,
        "resolved_by": resolved_by,
        "resolved_at": datetime.now().isoformat(timespec="seconds"),
        "applied": "False",
    }
    with MANUAL_RESOLUTION_PATH.open("a", newline="", encoding="utf-8") as fh:
        writer = csv.DictWriter(fh, fieldnames=RESOLUTION_FIELDS)
        if not file_exists:
            writer.writeheader()
        writer.writerow(row)
```

Agregar `import csv` y `from datetime import datetime` al inicio del archivo.

- [ ] **Step 2: Agregar render_resolution_tab con sub-tabs**

```python
def render_resolution_tab(
    review_queue: pd.DataFrame,
    duplicate_candidates: pd.DataFrame,
    stays: pd.DataFrame,
    patients: pd.DataFrame,
    establishments: pd.DataFrame,
) -> None:
    st.subheader("Revisión y Resolución")

    if review_queue.empty and duplicate_candidates.empty:
        st.success("No hay pendientes de revisión.")
        return

    # Conteo por tipo
    type_counts = review_queue["queue_type"].value_counts().to_dict() if not review_queue.empty else {}
    dup_count = len(duplicate_candidates) if not duplicate_candidates.empty else 0

    tab_labels = []
    tab_data = []
    for qt, label in [
        ("unmatched_form", "Formularios sin match"),
        ("unresolved_discharge", "Egresos sin resolver"),
        ("identity", "Identidad"),
        ("patient_orphan", "Pacientes huérfanos"),
        ("establishment", "Establecimientos"),
    ]:
        count = type_counts.get(qt, 0)
        if count > 0:
            tab_labels.append(f"{label} ({count})")
            tab_data.append(("queue", qt))

    if dup_count > 0:
        tab_labels.append(f"Duplicados ({dup_count})")
        tab_data.append(("duplicates", ""))

    if not tab_labels:
        st.success("No hay pendientes de revisión.")
        return

    tabs = st.tabs(tab_labels)
    for tab, (source, qt) in zip(tabs, tab_data):
        with tab:
            if source == "queue":
                render_queue_items(review_queue[review_queue["queue_type"] == qt], qt, stays, patients, establishments)
            else:
                render_duplicate_items(duplicate_candidates, stays, patients)
```

- [ ] **Step 3: Agregar render_queue_items para formularios sin match**

```python
def render_queue_items(
    items: pd.DataFrame,
    queue_type: str,
    stays: pd.DataFrame,
    patients: pd.DataFrame,
    establishments: pd.DataFrame,
) -> None:
    if items.empty:
        st.info("Sin pendientes en esta cola.")
        return

    for idx, row in items.iterrows():
        with st.expander(f"{row.get('patient_name', 'Sin nombre')} — {row.get('summary', '')}", expanded=False):
            col1, col2 = st.columns([2, 1])
            with col1:
                st.markdown(f"**Paciente:** {row.get('patient_name', '')} | **RUT:** {row.get('patient_rut', '')}")
                st.markdown(f"**Resumen:** {row.get('summary', '')}")
                st.markdown(f"**Prioridad:** {row.get('priority', '')}")
            with col2:
                candidate_id = row.get("candidate_ids", "")
                if candidate_id and not stays.empty:
                    candidates = stays[stays["stay_id"].isin(candidate_id.split(" | "))]
                    if not candidates.empty:
                        st.caption("Candidato(s):")
                        st.dataframe(candidates[["stay_id", "nombre_completo", "fecha_ingreso", "fecha_egreso", "diagnostico_principal"]].head(3), hide_index=True)

            action_key = f"action_{row.get('queue_item_id', idx)}"
            col_a, col_b, col_c = st.columns(3)
            with col_a:
                if st.button("Asociar", key=f"assoc_{action_key}"):
                    append_resolution(
                        item_id=row.get("entity_id", ""),
                        queue_type=queue_type,
                        action="associate",
                        target_id=candidate_id.split(" | ")[0] if candidate_id else "",
                    )
                    st.success("Asociación guardada.")
                    st.rerun()
            with col_b:
                if st.button("Crear nuevo", key=f"create_{action_key}"):
                    append_resolution(
                        item_id=row.get("entity_id", ""),
                        queue_type=queue_type,
                        action="create",
                    )
                    st.success("Creación registrada.")
                    st.rerun()
            with col_c:
                if st.button("Descartar", key=f"discard_{action_key}"):
                    append_resolution(
                        item_id=row.get("entity_id", ""),
                        queue_type=queue_type,
                        action="discard",
                    )
                    st.success("Descartado.")
                    st.rerun()
```

- [ ] **Step 4: Conectar el tab en main()**

```python
with resolution_tab:
    render_resolution_tab(
        datasets["review_queue"],
        datasets["duplicate_candidates"],
        datasets["stays"],
        datasets["patients"],
        datasets["establishments"],
    )
```

- [ ] **Step 5: Validar compilación**

```bash
python3 -m py_compile streamlit_admin_app.py
```

- [ ] **Step 6: Commit**

```bash
git add streamlit_admin_app.py
git commit -m "feat: agregar tab Revisión y Resolución con vista de formularios sin match"
```

---

### Task 11: Edición directa inline + resolución de identidad y duplicados

**Files:**
- Modify: `streamlit_admin_app.py`

- [ ] **Step 1: Agregar formulario de edición directa para identidad/pacientes**

Agregar al final de `render_queue_items`, una rama para `queue_type in ("identity", "patient_orphan", "establishment")`:

```python
            # Edición directa para identity/patient/establishment
            if queue_type in ("identity", "patient_orphan", "establishment"):
                st.markdown("---")
                st.caption("Corrección directa")
                with st.form(key=f"edit_form_{row.get('queue_item_id', idx)}"):
                    entity_id = row.get("entity_id", "")

                    if queue_type == "identity":
                        new_rut = st.text_input("RUT corregido", value=row.get("patient_rut", ""))
                        new_name = st.text_input("Nombre corregido", value=row.get("patient_name", ""))
                        new_dob = st.text_input("Fecha nacimiento (YYYY-MM-DD)", value="")
                        submitted = st.form_submit_button("Guardar corrección")
                        if submitted:
                            if new_rut != row.get("patient_rut", ""):
                                append_resolution(entity_id, queue_type, "correct",
                                                  field_corrected="rut",
                                                  old_value=row.get("patient_rut", ""),
                                                  new_value=new_rut)
                            if new_name != row.get("patient_name", ""):
                                append_resolution(entity_id, queue_type, "correct",
                                                  field_corrected="nombre_completo",
                                                  old_value=row.get("patient_name", ""),
                                                  new_value=new_name)
                            if new_dob:
                                append_resolution(entity_id, queue_type, "correct",
                                                  field_corrected="fecha_nacimiento",
                                                  old_value="",
                                                  new_value=new_dob)
                            st.success("Correcciones guardadas.")
                            st.rerun()

                    elif queue_type == "establishment":
                        if not establishments.empty:
                            options = establishments["nombre_oficial"].dropna().unique().tolist()
                            selected = st.selectbox("Establecimiento DEIS", [""] + sorted(options))
                            submitted = st.form_submit_button("Asignar establecimiento")
                            if submitted and selected:
                                append_resolution(entity_id, queue_type, "correct",
                                                  field_corrected="establecimiento",
                                                  old_value=row.get("summary", ""),
                                                  new_value=selected)
                                st.success("Establecimiento asignado.")
                                st.rerun()

                    elif queue_type == "patient_orphan":
                        action = st.radio("Acción", ["Confirmar como correcto", "Marcar para eliminar"], index=0)
                        submitted = st.form_submit_button("Guardar")
                        if submitted:
                            act = "correct" if action == "Confirmar como correcto" else "discard"
                            append_resolution(entity_id, queue_type, act)
                            st.success("Decisión guardada.")
                            st.rerun()
```

- [ ] **Step 2: Agregar render_duplicate_items para duplicados**

```python
def render_duplicate_items(
    candidates: pd.DataFrame,
    stays: pd.DataFrame,
    patients: pd.DataFrame,
) -> None:
    if candidates.empty:
        st.info("Sin duplicados detectados.")
        return

    for idx, row in candidates.iterrows():
        entity_type = row.get("entity_type", "")
        a_id = row.get("entity_a_id", "")
        b_id = row.get("entity_b_id", "")
        reason = row.get("match_reason", "")
        confidence = row.get("confidence", "")

        with st.expander(f"{entity_type.upper()}: {a_id} vs {b_id} — {reason} ({confidence})", expanded=False):
            col1, col2 = st.columns(2)

            if entity_type == "stay" and not stays.empty:
                show_cols = ["stay_id", "nombre_completo", "rut", "fecha_ingreso", "fecha_egreso",
                             "diagnostico_principal", "servicio_origen", "establecimiento"]
                a_data = stays[stays["stay_id"] == a_id]
                b_data = stays[stays["stay_id"] == b_id]
                with col1:
                    st.caption("Stay A")
                    if not a_data.empty:
                        st.dataframe(a_data[[c for c in show_cols if c in a_data.columns]].T, use_container_width=True)
                with col2:
                    st.caption("Stay B")
                    if not b_data.empty:
                        st.dataframe(b_data[[c for c in show_cols if c in b_data.columns]].T, use_container_width=True)
            elif entity_type == "patient" and not patients.empty:
                show_cols = ["patient_id", "nombre_completo", "rut", "sexo", "edad_reportada",
                             "comuna", "cesfam", "total_hospitalizaciones"]
                a_data = patients[patients["patient_id"] == a_id]
                b_data = patients[patients["patient_id"] == b_id]
                with col1:
                    st.caption("Paciente A")
                    if not a_data.empty:
                        st.dataframe(a_data[[c for c in show_cols if c in a_data.columns]].T, use_container_width=True)
                with col2:
                    st.caption("Paciente B")
                    if not b_data.empty:
                        st.dataframe(b_data[[c for c in show_cols if c in b_data.columns]].T, use_container_width=True)

            dup_key = f"dup_{row.get('candidate_id', idx)}"
            col_a, col_b = st.columns(2)
            with col_a:
                if st.button("Fusionar (A gana)", key=f"merge_{dup_key}"):
                    append_resolution(
                        item_id=row.get("candidate_id", ""),
                        queue_type="duplicate",
                        action="merge",
                        target_id=a_id,
                    )
                    st.success("Fusión registrada.")
                    st.rerun()
            with col_b:
                if st.button("No es duplicado", key=f"notdup_{dup_key}"):
                    append_resolution(
                        item_id=row.get("candidate_id", ""),
                        queue_type="duplicate",
                        action="not_duplicate",
                    )
                    st.success("Marcado como no duplicado.")
                    st.rerun()
```

- [ ] **Step 3: Agregar contadores de pendientes en sidebar**

En la función `filter_admin_data()` o al inicio del `main()`, agregar al sidebar:

```python
    with st.sidebar:
        # Después de los filtros existentes
        st.markdown("---")
        st.caption("Pendientes de revisión")
        if not datasets["review_queue"].empty:
            pending = len(datasets["review_queue"])
            st.markdown(f"**Cola de revisión:** {pending}")
        if not datasets["duplicate_candidates"].empty:
            dups = len(datasets["duplicate_candidates"])
            st.markdown(f"**Duplicados:** {dups}")
        if not datasets["pipeline_health"].empty:
            status = datasets["pipeline_health"].iloc[-1].get("health_status", "")
            color = {"green": "🟢", "yellow": "🟡", "red": "🔴"}.get(status, "⚪")
            st.markdown(f"**Pipeline:** {color} {status.upper()}")
```

- [ ] **Step 4: Validar compilación**

```bash
python3 -m py_compile streamlit_admin_app.py
```

- [ ] **Step 5: Commit**

```bash
git add streamlit_admin_app.py
git commit -m "feat: agregar edición directa inline, resolución de duplicados y contadores en sidebar"
```

---

### Task 12: Leer manual_resolution.csv en build_hodom_enriched.py

**Files:**
- Modify: `scripts/build_hodom_enriched.py`

- [ ] **Step 1: Identificar punto de inserción**

Buscar en `build_hodom_enriched.py` la función `build_enriched_outputs()` alrededor de la línea 1738, donde se inicializan los datos baseline. Las correcciones manuales deben aplicarse **antes** del loop de matching de formularios.

- [ ] **Step 2: Agregar lectura y aplicación de correcciones manuales**

Después de la inicialización de `enriched_patients` y `enriched_episodes` (aprox. línea 1820), agregar:

```python
    # Aplicar correcciones manuales de manual_resolution.csv
    manual_resolution_path = Path("input/manual/manual_resolution.csv")
    if manual_resolution_path.exists():
        manual_rows = read_manual_csv(manual_resolution_path)
        for res in manual_rows:
            if res.get("applied") == "True":
                continue
            if res.get("action") != "correct":
                continue
            field = res.get("field_corrected", "")
            new_val = res.get("new_value", "")
            entity_id = res.get("item_id", "")
            if not field or not new_val or not entity_id:
                continue
            # Aplicar corrección a paciente
            if entity_id in enriched_patients and field in enriched_patients[entity_id]:
                enriched_patients[entity_id][field] = new_val
            # Aplicar corrección a episodio
            if entity_id in enriched_episodes and field in enriched_episodes[entity_id]:
                enriched_episodes[entity_id][field] = new_val
```

- [ ] **Step 3: Verificar compilación**

```bash
python3 -m py_compile scripts/build_hodom_enriched.py
```

- [ ] **Step 4: Commit**

```bash
git add scripts/build_hodom_enriched.py
git commit -m "feat: aplicar correcciones de manual_resolution.csv al inicio del pipeline enriched"
```

---

### Task 13: Validación end-to-end

**Files:**
- Modify: `scripts/refresh_data_and_run_dashboard.sh`

- [ ] **Step 1: Ejecutar pipeline completo**

```bash
.venv/bin/python scripts/build_hodom_enriched.py
.venv/bin/python scripts/build_hodom_canonical.py
```

Expected: Ambos terminan sin errores. Verifica que `output/spreadsheet/canonical/` contiene:
- hospitalization_stay.csv
- patient_master.csv
- episode_source.csv
- pipeline_health.csv
- quality_issue.csv
- review_queue.csv
- coverage_gap.csv
- duplicate_candidate.csv
- establishment_reference.csv
- locality_reference.csv

- [ ] **Step 2: Verificar conteos**

```bash
.venv/bin/python -c "
import csv
from pathlib import Path
canonical = Path('output/spreadsheet/canonical')
for name in sorted(canonical.glob('*.csv')):
    with name.open() as f:
        rows = list(csv.DictReader(f))
    print(f'{name.name}: {len(rows)} rows')
"
```

Expected: Conteos razonables (stays ~1700, patients ~1468, etc.)

- [ ] **Step 3: Verificar que dashboard admin compila y arranca**

```bash
python3 -m py_compile streamlit_admin_app.py
```

- [ ] **Step 4: Ejecutar tests completos**

```bash
.venv/bin/pytest tests/ -v
```

Expected: All passed

- [ ] **Step 5: Verificar refresh script completo**

Asegurar que `scripts/refresh_data_and_run_dashboard.sh` tiene los 3 pasos:

```bash
#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

# Paso 1-3: Pipeline intermedio + enriquecido
.venv/bin/python scripts/build_hodom_enriched.py

# Paso 4: Capa canónica
.venv/bin/python scripts/build_hodom_canonical.py

# Dashboard
echo "Iniciando dashboard en http://localhost:8502"
exec .venv/bin/streamlit run streamlit_admin_app.py --server.port 8502
```

- [ ] **Step 6: Commit final**

```bash
git add -A
git commit -m "feat: validación end-to-end del pipeline canónico + dashboard admin refactorizado"
```
