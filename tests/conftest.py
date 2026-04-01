"""
Fixtures de datos de prueba para el pipeline canonico HODOM.

Provee episodios, pacientes, issues de calidad, cola de revision de matches,
revisiones de identidad, eventos de alta, y un directorio temporal con CSVs
para tests de integracion.
"""

import csv
from pathlib import Path

import pytest


def write_csv_to_path(path: Path, rows: list[dict]) -> Path:
    """Escribe una lista de dicts como CSV en la ruta indicada.

    Args:
        path: Ruta absoluta del archivo CSV a crear.
        rows: Lista de diccionarios con los datos. Las keys del primer
              elemento se usan como encabezados.

    Returns:
        La misma ruta recibida, para facilitar encadenamiento.
    """
    if not rows:
        path.write_text("")
        return path

    fieldnames = list(rows[0].keys())
    with open(path, "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(rows)
    return path


# ---------------------------------------------------------------------------
# Fixtures
# ---------------------------------------------------------------------------


@pytest.fixture()
def sample_episodes() -> list[dict]:
    """4 episodios de prueba que cubren distintos origenes y estados."""
    return [
        {
            "episode_id": "ep_001",
            "patient_id": "pt_001",
            "fecha_ingreso": "2026-01-15",
            "fecha_egreso": "2026-02-10",
            "estado": "activo",
            "servicio_origen": "medicina_interna",
            "prevision": "FONASA_A",
            "diagnostico_principal_texto": "Neumonia adquirida en comunidad",
            "motivo_egreso": "alta_medica",
            "establecimiento_resuelto": "CESFAM Dr. Jorge Sabat",
            "codigo_deis_resuelto": "113100",
            "comuna_resuelta": "Valdivia",
            "localidad_resuelta": "Valdivia Urbano",
            "latitud_localidad": "-39.8142",
            "longitud_localidad": "-73.2459",
            "episode_origin": "merged",
            "resolution_status": "resolved",
            "gestora": "Maria Gonzalez",
            "usuario_o2": "mgonzalez",
            "nombre_completo": "JUAN PEREZ SOTO",
            "rut": "12345678-5",
            "sexo_resuelto": "M",
            "edad_reportada": "72",
        },
        {
            "episode_id": "ep_002",
            "patient_id": "pt_001",
            "fecha_ingreso": "2026-01-15",
            "fecha_egreso": "2026-02-10",
            "estado": "activo",
            "servicio_origen": "medicina_interna",
            "prevision": "FONASA_A",
            "diagnostico_principal_texto": "Neumonia adquirida en comunidad",
            "motivo_egreso": "alta_medica",
            "establecimiento_resuelto": "CESFAM Dr. Jorge Sabat",
            "codigo_deis_resuelto": "113100",
            "comuna_resuelta": "Valdivia",
            "localidad_resuelta": "Valdivia Urbano",
            "latitud_localidad": "-39.8142",
            "longitud_localidad": "-73.2459",
            "episode_origin": "raw",
            "resolution_status": "pending",
            "gestora": "Maria Gonzalez",
            "usuario_o2": "mgonzalez",
            "nombre_completo": "JUAN PEREZ SOTO",
            "rut": "12345678-5",
            "sexo_resuelto": "M",
            "edad_reportada": "72",
        },
        {
            "episode_id": "ep_003",
            "patient_id": "pt_002",
            "fecha_ingreso": "2026-02-01",
            "fecha_egreso": "",
            "estado": "activo",
            "servicio_origen": "geriatria",
            "prevision": "FONASA_B",
            "diagnostico_principal_texto": "Fractura de cadera",
            "motivo_egreso": "",
            "establecimiento_resuelto": "CESFAM Externo Las Animas",
            "codigo_deis_resuelto": "113101",
            "comuna_resuelta": "Valdivia",
            "localidad_resuelta": "Las Animas",
            "latitud_localidad": "-39.8350",
            "longitud_localidad": "-73.2200",
            "episode_origin": "form_rescued",
            "resolution_status": "pending",
            "gestora": "Ana Lopez",
            "usuario_o2": "alopez",
            "nombre_completo": "MARIA RODRIGUEZ DIAZ",
            "rut": "9876543-2",
            "sexo_resuelto": "F",
            "edad_reportada": "85",
        },
        {
            "episode_id": "ep_004",
            "patient_id": "pt_003",
            "fecha_ingreso": "2026-03-01",
            "fecha_egreso": "2026-03-20",
            "estado": "cerrado",
            "servicio_origen": "traumatologia",
            "prevision": "ISAPRE",
            "diagnostico_principal_texto": "Herida operatoria compleja",
            "motivo_egreso": "alta_medica",
            "establecimiento_resuelto": "Hospital Base Valdivia",
            "codigo_deis_resuelto": "113300",
            "comuna_resuelta": "Valdivia",
            "localidad_resuelta": "Valdivia Urbano",
            "latitud_localidad": "-39.8142",
            "longitud_localidad": "-73.2459",
            "episode_origin": "alta_rescued",
            "resolution_status": "resolved",
            "gestora": "Maria Gonzalez",
            "usuario_o2": "mgonzalez",
            "nombre_completo": "PEDRO MARTINEZ ROJAS",
            "rut": "15432678-K",
            "sexo_resuelto": "M",
            "edad_reportada": "58",
        },
    ]


@pytest.fixture()
def sample_patients() -> list[dict]:
    """3 pacientes de prueba vinculados a los episodios."""
    return [
        {
            "patient_id": "pt_001",
            "nombre_completo": "JUAN PEREZ SOTO",
            "rut": "12345678-5",
            "sexo": "M",
            "fecha_nacimiento_date": "1954-03-12",
            "edad_reportada": "72",
            "comuna": "Valdivia",
            "cesfam": "CESFAM Dr. Jorge Sabat",
            "episode_count": 2,
        },
        {
            "patient_id": "pt_002",
            "nombre_completo": "MARIA RODRIGUEZ DIAZ",
            "rut": "9876543-2",
            "sexo": "F",
            "fecha_nacimiento_date": "1941-07-22",
            "edad_reportada": "85",
            "comuna": "Valdivia",
            "cesfam": "CESFAM Externo Las Animas",
            "episode_count": 1,
        },
        {
            "patient_id": "pt_003",
            "nombre_completo": "PEDRO MARTINEZ ROJAS",
            "rut": "15432678-K",
            "sexo": "M",
            "fecha_nacimiento_date": "1968-11-05",
            "edad_reportada": "58",
            "comuna": "Valdivia",
            "cesfam": "Hospital Base Valdivia",
            "episode_count": 1,
        },
    ]


@pytest.fixture()
def sample_quality_issues() -> list[dict]:
    """4 issues de calidad con distintos tipos y estados de resolucion."""
    return [
        {
            "issue_id": "qi_001",
            "episode_id": "ep_001",
            "issue_type": "UNMATCHED_FORM",
            "severity": "high",
            "description": "Formulario sin match con episodio de alta",
            "resolution_status": "REVIEW_REQUIRED",
            "resolved_at": "",
            "resolved_by": "",
        },
        {
            "issue_id": "qi_002",
            "episode_id": "ep_002",
            "issue_type": "BIRTHDATE_AGE",
            "severity": "medium",
            "description": "Edad reportada no coincide con fecha de nacimiento",
            "resolution_status": "OPEN",
            "resolved_at": "",
            "resolved_by": "",
        },
        {
            "issue_id": "qi_003",
            "episode_id": "ep_003",
            "issue_type": "ESTABLISHMENT_UNRESOLVED",
            "severity": "medium",
            "description": "Establecimiento no resuelto contra catalogo DEIS",
            "resolution_status": "OPEN",
            "resolved_at": "",
            "resolved_by": "",
        },
        {
            "issue_id": "qi_004",
            "episode_id": "ep_004",
            "issue_type": "ENUM_NORMALIZED",
            "severity": "low",
            "description": "Valor normalizado automaticamente",
            "resolution_status": "RESOLVED_AUTO",
            "resolved_at": "2026-03-21T10:00:00",
            "resolved_by": "system",
        },
    ]


@pytest.fixture()
def sample_match_review_queue() -> list[dict]:
    """1 item en cola de revision de match con candidato."""
    return [
        {
            "review_id": "mr_001",
            "episode_id": "ep_001",
            "candidate_episode_id": "ep_002",
            "match_score": 0.92,
            "match_reason": "same_patient_same_dates",
            "status": "pending",
            "reviewed_by": "",
            "reviewed_at": "",
        },
    ]


@pytest.fixture()
def sample_identity_review() -> list[dict]:
    """1 item de revision de identidad."""
    return [
        {
            "identity_review_id": "ir_001",
            "patient_id": "pt_002",
            "issue_type": "RUT_INVALID",
            "original_rut": "9876543-2",
            "suggested_rut": "9876543-K",
            "status": "pending",
            "reviewed_by": "",
            "reviewed_at": "",
        },
    ]


@pytest.fixture()
def sample_discharge_events() -> list[dict]:
    """1 evento de alta no resuelto."""
    return [
        {
            "discharge_id": "de_001",
            "episode_id": "ep_003",
            "fecha_egreso_reportada": "2026-03-15",
            "motivo_egreso": "alta_medica",
            "resolution_status": "unresolved",
            "resolved_at": "",
            "resolved_by": "",
        },
    ]


@pytest.fixture()
def tmp_enriched_dir(
    tmp_path: Path,
    sample_episodes: list[dict],
    sample_patients: list[dict],
    sample_quality_issues: list[dict],
    sample_match_review_queue: list[dict],
    sample_identity_review: list[dict],
    sample_discharge_events: list[dict],
) -> Path:
    """Escribe todos los fixtures como CSVs en un directorio temporal.

    Ademas crea establishment_reference.csv y locality_reference.csv
    como tablas de referencia minimas para tests de integracion.

    Returns:
        Path al directorio temporal con los CSVs.
    """
    write_csv_to_path(tmp_path / "episodes.csv", sample_episodes)
    write_csv_to_path(tmp_path / "patients.csv", sample_patients)
    write_csv_to_path(tmp_path / "quality_issues.csv", sample_quality_issues)
    write_csv_to_path(
        tmp_path / "match_review_queue.csv", sample_match_review_queue
    )
    write_csv_to_path(
        tmp_path / "identity_review.csv", sample_identity_review
    )
    write_csv_to_path(
        tmp_path / "discharge_events.csv", sample_discharge_events
    )

    # Tablas de referencia
    write_csv_to_path(
        tmp_path / "establishment_reference.csv",
        [
            {
                "codigo_deis": "113100",
                "nombre_establecimiento": "CESFAM Dr. Jorge Sabat",
                "comuna": "Valdivia",
                "tipo": "CESFAM",
            },
            {
                "codigo_deis": "113101",
                "nombre_establecimiento": "CESFAM Externo Las Animas",
                "comuna": "Valdivia",
                "tipo": "CESFAM",
            },
            {
                "codigo_deis": "113300",
                "nombre_establecimiento": "Hospital Base Valdivia",
                "comuna": "Valdivia",
                "tipo": "Hospital",
            },
        ],
    )

    write_csv_to_path(
        tmp_path / "locality_reference.csv",
        [
            {
                "localidad": "Valdivia Urbano",
                "comuna": "Valdivia",
                "latitud": "-39.8142",
                "longitud": "-73.2459",
            },
            {
                "localidad": "Las Animas",
                "comuna": "Valdivia",
                "latitud": "-39.8350",
                "longitud": "-73.2200",
            },
        ],
    )

    return tmp_path
