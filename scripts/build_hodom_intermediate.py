#!/usr/bin/env python3
from __future__ import annotations

import argparse
import csv
import hashlib
import json
from collections import Counter, defaultdict
from datetime import datetime
from pathlib import Path

import migrate_hodom_csv as base


RAW_SOURCE_FILE_COLUMNS = [
    "source_file_id",
    "file_name",
    "file_family",
    "source_pattern",
    "header_rows",
    "included_in_normalized",
    "header_fingerprint",
    "file_sha256",
    "row_count",
    "data_row_count",
    "imported_at",
]

RAW_SOURCE_ROW_COLUMNS = [
    "source_row_id",
    "source_file_id",
    "file_name",
    "row_number",
    "has_payload",
    "row_hash",
    "raw_json",
]

NORMALIZED_ROW_COLUMNS = [
    "normalized_row_id",
    "source_file_id",
    "source_row_id",
    "parse_status",
    "quality_score",
    *base.OUTPUT_COLUMNS,
]

EPISODE_SOURCE_LINK_COLUMNS = [
    "episode_source_link_id",
    "episode_id",
    "normalized_row_id",
    "record_uid",
    "source_file",
    "source_row_number",
    "duplicate_rank",
    "is_retained_row",
]

PATIENT_IDENTITY_CANDIDATE_COLUMNS = [
    "identity_candidate_id",
    "normalized_row_id",
    "episode_id",
    "patient_id",
    "patient_key",
    "patient_key_strategy",
    "identity_confidence",
    "review_required",
    "rut_norm",
    "rut_valido",
    "nombre_completo_norm",
    "fecha_nacimiento",
    "contacto_norm",
]

PATIENT_MASTER_COLUMNS = [
    "patient_id",
    "canonical_patient_key",
    "identity_resolution_status",
    *base.PATIENT_COLUMNS,
]

PATIENT_IDENTITY_LINK_COLUMNS = [
    "patient_identity_link_id",
    "patient_id",
    "identity_candidate_id",
    "link_type",
    "is_primary",
]

EPISODE_COLUMNS = [
    "episode_id",
    "patient_id",
    "source_episode_key",
    "record_uid",
    "estado",
    "tipo_flujo",
    "fecha_ingreso",
    "fecha_egreso",
    "dias_estadia_reportados",
    "dias_estadia_calculados",
    "motivo_egreso",
    "motivo_derivacion",
    "servicio_origen",
    "prevision",
    "barthel",
    "categorizacion",
    "usuario_o2",
    "requerimiento_o2",
    "diagnostico_principal_texto",
    "episode_status_quality",
    "duplicate_count",
]

EPISODE_DIAGNOSIS_COLUMNS = [
    "episode_diagnosis_id",
    "episode_id",
    "diagnosis_role",
    "diagnosis_text_raw",
    "diagnosis_text_norm",
    "coding_status",
    "cie10_code",
]

EPISODE_CARE_REQUIREMENT_COLUMNS = [
    "episode_requirement_id",
    "episode_id",
    "requirement_type",
    "requirement_value_raw",
    "requirement_value_norm",
    "is_active",
]

EPISODE_PROFESSIONAL_NEED_COLUMNS = [
    "episode_professional_need_id",
    "episode_id",
    "professional_type",
    "need_level",
    "source_column",
]

PATIENT_CONTACT_POINT_COLUMNS = [
    "contact_point_id",
    "patient_id",
    "source_episode_id",
    "contact_type",
    "contact_value_raw",
    "contact_value_norm",
    "is_primary",
]

PATIENT_ADDRESS_COLUMNS = [
    "address_id",
    "patient_id",
    "full_address_raw",
    "street_text",
    "house_number",
    "comuna",
    "cesfam",
    "territory_type",
    "address_quality_status",
    "first_seen_episode_id",
]

EPISODE_LOCATION_SNAPSHOT_COLUMNS = [
    "episode_location_snapshot_id",
    "episode_id",
    "address_id",
    "snapshot_full_address",
    "snapshot_comuna",
    "snapshot_cesfam",
    "snapshot_territory_type",
]

DATA_QUALITY_ISSUE_COLUMNS = [
    "quality_issue_id",
    "normalized_row_id",
    "episode_id",
    "issue_type",
    "severity",
    "raw_value",
    "suggested_value",
    "status",
]

CATALOG_VALUE_COLUMNS = [
    "catalog_value_id",
    "catalog_type",
    "code",
    "label",
    "label_normalized",
    "source_count",
]

RUT_CORRECTION_QUEUE_COLUMNS = [
    "source_file",
    "source_row_number",
    "record_uid",
    "nombre_completo",
    "fecha_nacimiento_raw",
    "rut_raw",
    "rut_sugerido",
    "rut_corregido_confirmado",
    "status",
    "notes",
]


def stable_id(prefix: str, *parts: str) -> str:
    digest = hashlib.sha1("|".join(str(part) for part in parts).encode("utf-8")).hexdigest()[:16]
    return f"{prefix}_{digest}"


def write_csv(path: Path, rows: list[dict[str, str]], columns: list[str]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=columns)
        writer.writeheader()
        for row in rows:
            writer.writerow({column: row.get(column, "") for column in columns})


def sha256_bytes(content: bytes) -> str:
    return hashlib.sha256(content).hexdigest()


def row_source_id(file_name: str, row_number: int | str) -> str:
    return stable_id("sr", file_name, str(row_number))


def normalized_row_id(record_uid: str) -> str:
    return stable_id("nr", record_uid)


def patient_id(patient_key: str) -> str:
    return stable_id("pt", patient_key)


def episode_id(dedupe_key: str) -> str:
    return stable_id("ep", dedupe_key)


def parse_status(record: dict[str, str]) -> str:
    notes = set(filter(None, record.get("normalization_notes", "").split(";")))
    if any(note.startswith("invalid_") or note == "birth_date_age_mismatch" for note in notes):
        return "PARTIAL"
    return "OK"


def quality_score(record: dict[str, str]) -> str:
    penalties = {
        "swap_rut_fecha_nacimiento": 2,
        "normalize_estado": 1,
        "normalize_barthel": 1,
        "normalize_prevision": 1,
        "normalize_servicio": 1,
        "invalid_rut_rejected": 10,
        "invalid_fecha_ingreso": 10,
        "invalid_fecha_egreso": 10,
        "invalid_fecha_nacimiento": 8,
        "birth_date_age_mismatch": 8,
        "normalize_sexo": 4,
    }
    score = 100
    for note in filter(None, record.get("normalization_notes", "").split(";")):
        score -= penalties.get(note, 2)
    if not record.get("rut"):
        score -= 5
    return str(max(score, 0))


def confidence_for_strategy(strategy: str) -> str:
    confidence = {
        "rut": "1.00",
        "nombre_fecha": "0.75",
        "nombre_contacto": "0.60",
        "nombre": "0.45",
        "legacy": "0.20",
    }
    return confidence.get(strategy, "0.40")


def review_required(record: dict[str, str]) -> str:
    notes = set(filter(None, record.get("normalization_notes", "").split(";")))
    return "1" if record.get("patient_key_strategy") != "rut" or any(note.startswith("invalid_") for note in notes) else "0"


def split_contact_values(raw_value: str) -> list[str]:
    matches = []
    for token in base.re.findall(r"\d{7,12}", raw_value or ""):
        if token not in matches:
            matches.append(token)
    if matches:
        return matches
    value = base.normalize_whitespace(raw_value)
    return [value] if value else []


def days_between(start_iso: str, end_iso: str) -> str:
    if not start_iso or not end_iso:
        return ""
    try:
        start = datetime.strptime(start_iso, "%Y-%m-%d").date()
        end = datetime.strptime(end_iso, "%Y-%m-%d").date()
    except ValueError:
        return ""
    delta = (end - start).days
    return str(delta) if delta >= 0 else ""


def issue_severity(note: str) -> str:
    if note in {"invalid_rut_rejected", "invalid_fecha_ingreso", "invalid_fecha_egreso"}:
        return "HIGH"
    if note in {"invalid_fecha_nacimiento", "birth_date_age_mismatch", "swap_rut_fecha_nacimiento"}:
        return "MEDIUM"
    return "LOW"


def issue_type(note: str) -> str:
    mapping = {
        "invalid_rut_rejected": "INVALID_RUT",
        "invalid_fecha_ingreso": "DATE_PARSE_FAILED",
        "invalid_fecha_egreso": "DATE_PARSE_FAILED",
        "invalid_fecha_nacimiento": "DATE_PARSE_FAILED",
        "birth_date_age_mismatch": "BIRTHDATE_AGE_MISMATCH",
        "swap_rut_fecha_nacimiento": "COLUMN_SHIFT_DETECTED",
        "normalize_estado": "ENUM_NORMALIZED",
        "normalize_barthel": "ENUM_NORMALIZED",
        "normalize_prevision": "ENUM_NORMALIZED",
        "normalize_servicio": "ENUM_NORMALIZED",
        "normalize_sexo": "ENUM_NORMALIZED",
        "manual_rut_override": "MANUAL_RUT_OVERRIDE",
    }
    return mapping.get(note, "NORMALIZATION_NOTE")


def issue_status(note: str) -> str:
    if note in {
        "normalize_estado",
        "normalize_barthel",
        "normalize_prevision",
        "normalize_servicio",
        "normalize_sexo",
        "swap_rut_fecha_nacimiento",
        "manual_rut_override",
    }:
        return "RESOLVED_AUTO"
    return "OPEN"


def suggested_value(note: str, record: dict[str, str]) -> str:
    if note == "invalid_rut_rejected":
        number, verifier = base.split_rut_candidate(record.get("rut_raw"))
        if number and verifier:
            expected = base.calculate_rut_verifier(number)
            return f"{int(number)}-{expected}"
    if note == "swap_rut_fecha_nacimiento":
        return "swap rut_raw <-> fecha_nacimiento_raw"
    return ""


def load_raw_source_layers(source_dir: Path) -> tuple[list[dict[str, str]], list[dict[str, str]], dict[str, str]]:
    raw_files: list[dict[str, str]] = []
    raw_rows: list[dict[str, str]] = []
    file_id_by_name: dict[str, str] = {}
    imported_at = datetime.now().isoformat(timespec="seconds")

    for path in sorted(source_dir.glob("*.csv")):
        file_bytes = path.read_bytes()
        with path.open("r", encoding="utf-8-sig", newline="") as handle:
            rows = list(csv.reader(handle))
        spec = base.detect_pattern(path.name, rows)
        source_file_id = stable_id("sf", path.name)
        file_id_by_name[path.name] = source_file_id
        header_row = rows[0] if rows else []
        raw_files.append(
            {
                "source_file_id": source_file_id,
                "file_name": path.name,
                "file_family": base.file_family(path.name),
                "source_pattern": spec.name if spec else "excluded",
                "header_rows": str(spec.header_rows if spec else 0),
                "included_in_normalized": "1" if spec else "0",
                "header_fingerprint": sha256_bytes(json.dumps(header_row, ensure_ascii=False).encode("utf-8")),
                "file_sha256": sha256_bytes(file_bytes),
                "row_count": str(len(rows)),
                "data_row_count": str(max(len(rows) - (spec.header_rows if spec else 0), 0)),
                "imported_at": imported_at,
            }
        )

        for row_number, row in enumerate(rows, start=1):
            raw_json = json.dumps(row, ensure_ascii=False)
            raw_rows.append(
                {
                    "source_row_id": row_source_id(path.name, row_number),
                    "source_file_id": source_file_id,
                    "file_name": path.name,
                    "row_number": str(row_number),
                    "has_payload": "1" if any(base.normalize_whitespace(cell) for cell in row) else "0",
                    "row_hash": sha256_bytes(raw_json.encode("utf-8")),
                    "raw_json": raw_json,
                }
            )

    return raw_files, raw_rows, file_id_by_name


def build_normalized_rows(records: list[dict[str, str]], file_id_by_name: dict[str, str]) -> list[dict[str, str]]:
    rows: list[dict[str, str]] = []
    for record in records:
        row = {
            "normalized_row_id": normalized_row_id(record["record_uid"]),
            "source_file_id": file_id_by_name[record["source_file"]],
            "source_row_id": row_source_id(record["source_file"], record["source_row_number"]),
            "parse_status": parse_status(record),
            "quality_score": quality_score(record),
        }
        row.update(record)
        rows.append(row)
    rows.sort(key=lambda row: (row["source_file"], int(row["source_row_number"])))
    return rows


def build_patient_master_rows(kept_records: list[dict[str, str]]) -> list[dict[str, str]]:
    patient_rows = base.build_patients(kept_records)
    rows: list[dict[str, str]] = []
    for patient in patient_rows:
        strategy = patient["patient_key_strategy"]
        rows.append(
            {
                "patient_id": patient_id(patient["patient_key"]),
                "canonical_patient_key": patient["patient_key"],
                "identity_resolution_status": "AUTO" if strategy == "rut" else "AMBIGUOUS",
                **patient,
            }
        )
    return rows


def build_patient_identity_candidates(kept_records: list[dict[str, str]]) -> list[dict[str, str]]:
    rows: list[dict[str, str]] = []
    for record in kept_records:
        candidate_id = stable_id("pi", record["record_uid"], record["patient_key"])
        rows.append(
            {
                "identity_candidate_id": candidate_id,
                "normalized_row_id": normalized_row_id(record["record_uid"]),
                "episode_id": episode_id(record["dedupe_key"]),
                "patient_id": patient_id(record["patient_key"]),
                "patient_key": record["patient_key"],
                "patient_key_strategy": record["patient_key_strategy"],
                "identity_confidence": confidence_for_strategy(record["patient_key_strategy"]),
                "review_required": review_required(record),
                "rut_norm": record["rut"],
                "rut_valido": record["rut_valido"],
                "nombre_completo_norm": base.canonical_text(record["nombre_completo"]),
                "fecha_nacimiento": record["fecha_nacimiento_date"],
                "contacto_norm": ";".join(split_contact_values(record["nro_contacto"])),
            }
        )
    return rows


def build_patient_identity_links(identity_rows: list[dict[str, str]]) -> list[dict[str, str]]:
    rows: list[dict[str, str]] = []
    for identity_row in identity_rows:
        strategy = identity_row["patient_key_strategy"]
        link_type = "AUTO_RUT" if strategy == "rut" else "AUTO_HEURISTIC"
        rows.append(
            {
                "patient_identity_link_id": stable_id("pl", identity_row["patient_id"], identity_row["identity_candidate_id"]),
                "patient_id": identity_row["patient_id"],
                "identity_candidate_id": identity_row["identity_candidate_id"],
                "link_type": link_type,
                "is_primary": "1",
            }
        )
    return rows


def build_episode_rows(kept_records: list[dict[str, str]]) -> list[dict[str, str]]:
    rows: list[dict[str, str]] = []
    for record in kept_records:
        notes = set(filter(None, record.get("normalization_notes", "").split(";")))
        quality = "CONSISTENT"
        if any(note.startswith("invalid_") or note == "birth_date_age_mismatch" for note in notes):
            quality = "REVIEW"
        elif notes:
            quality = "PARTIAL"

        rows.append(
            {
                "episode_id": episode_id(record["dedupe_key"]),
                "patient_id": patient_id(record["patient_key"]),
                "source_episode_key": record["dedupe_key"],
                "record_uid": record["record_uid"],
                "estado": record["estado"],
                "tipo_flujo": record["source_family"],
                "fecha_ingreso": record["fecha_ingreso_date"],
                "fecha_egreso": record["fecha_egreso_date"],
                "dias_estadia_reportados": record["dias_estadia_reportados"],
                "dias_estadia_calculados": days_between(record["fecha_ingreso_date"], record["fecha_egreso_date"]),
                "motivo_egreso": record["motivo_egreso"],
                "motivo_derivacion": record["motivo_derivacion"],
                "servicio_origen": record["servicio_origen"],
                "prevision": record["prevision"],
                "barthel": record["barthel"],
                "categorizacion": record["categorizacion"],
                "usuario_o2": record["usuario_o2"],
                "requerimiento_o2": record["requerimiento_o2"],
                "diagnostico_principal_texto": record["diagnostico_egreso"],
                "episode_status_quality": quality,
                "duplicate_count": record["duplicate_count"],
            }
        )
    return rows


def build_episode_source_links(raw_records: list[dict[str, str]], kept_records: list[dict[str, str]]) -> list[dict[str, str]]:
    kept_by_key = {record["dedupe_key"]: record for record in kept_records}
    rows: list[dict[str, str]] = []
    for record in raw_records:
        retained = kept_by_key[record["dedupe_key"]]
        ep_id = episode_id(record["dedupe_key"])
        rows.append(
            {
                "episode_source_link_id": stable_id("es", ep_id, record["record_uid"]),
                "episode_id": ep_id,
                "normalized_row_id": normalized_row_id(record["record_uid"]),
                "record_uid": record["record_uid"],
                "source_file": record["source_file"],
                "source_row_number": record["source_row_number"],
                "duplicate_rank": record["duplicate_rank"],
                "is_retained_row": "1" if record["record_uid"] == retained["record_uid"] else "0",
            }
        )
    return rows


def build_episode_diagnoses(kept_records: list[dict[str, str]]) -> list[dict[str, str]]:
    rows: list[dict[str, str]] = []
    for record in kept_records:
        diagnosis = base.normalize_whitespace(record["diagnostico_egreso"])
        if not diagnosis:
            continue
        ep_id = episode_id(record["dedupe_key"])
        rows.append(
            {
                "episode_diagnosis_id": stable_id("dx", ep_id, diagnosis),
                "episode_id": ep_id,
                "diagnosis_role": "EGRESO",
                "diagnosis_text_raw": diagnosis,
                "diagnosis_text_norm": base.canonical_text(diagnosis),
                "coding_status": "UNCODED",
                "cie10_code": "",
            }
        )
    return rows


def build_episode_care_requirements(kept_records: list[dict[str, str]]) -> list[dict[str, str]]:
    field_map = {
        "usuario_o2": "USUARIO_O2",
        "requerimiento_o2": "REQUERIMIENTO_O2",
        "tto_ev": "TTO_EV",
        "tto_sc": "TTO_SC",
        "tto_im": "TTO_IM",
        "curaciones": "CURACIONES",
        "toma_muestras": "TOMA_MUESTRAS",
        "manejo_ostomias": "MANEJO_OSTOMIAS",
        "elementos_invasivos": "ELEMENTOS_INVASIVOS",
        "csv_flag": "CSV",
        "educacion": "EDUCACION",
    }
    rows: list[dict[str, str]] = []
    for record in kept_records:
        ep_id = episode_id(record["dedupe_key"])
        for field_name, requirement_type in field_map.items():
            value = base.normalize_whitespace(record.get(field_name))
            if not value:
                continue
            value_norm = base.canonical_text(value)
            rows.append(
                {
                    "episode_requirement_id": stable_id("rq", ep_id, requirement_type, value),
                    "episode_id": ep_id,
                    "requirement_type": requirement_type,
                    "requirement_value_raw": value,
                    "requirement_value_norm": value_norm,
                    "is_active": "0" if value_norm in {"NO", "N A"} else "1",
                }
            )
    return rows


def build_episode_professional_needs(kept_records: list[dict[str, str]]) -> list[dict[str, str]]:
    field_map = {
        "enfermeria": "ENFERMERIA",
        "kinesiologia": "KINESIOLOGIA",
        "fonoaudiologia": "FONOAUDIOLOGIA",
        "medico": "MEDICO",
        "trabajo_social": "TRABAJO_SOCIAL",
        "knt": "KNT",
        "fono": "FONO",
    }
    rows: list[dict[str, str]] = []
    for record in kept_records:
        ep_id = episode_id(record["dedupe_key"])
        for field_name, professional_type in field_map.items():
            value = base.normalize_whitespace(record.get(field_name))
            if not value:
                continue
            rows.append(
                {
                    "episode_professional_need_id": stable_id("pn", ep_id, professional_type, value),
                    "episode_id": ep_id,
                    "professional_type": professional_type,
                    "need_level": value,
                    "source_column": field_name,
                }
            )
    return rows


def build_patient_contact_points(kept_records: list[dict[str, str]]) -> list[dict[str, str]]:
    rows: list[dict[str, str]] = []
    seen = set()
    for record in kept_records:
        pt_id = patient_id(record["patient_key"])
        ep_id = episode_id(record["dedupe_key"])
        contact_values = split_contact_values(record["nro_contacto"])
        for idx, value in enumerate(contact_values, start=1):
            key = (pt_id, value)
            if key in seen:
                continue
            seen.add(key)
            rows.append(
                {
                    "contact_point_id": stable_id("cp", pt_id, value),
                    "patient_id": pt_id,
                    "source_episode_id": ep_id,
                    "contact_type": "PHONE",
                    "contact_value_raw": record["nro_contacto"],
                    "contact_value_norm": value,
                    "is_primary": "1" if idx == 1 else "0",
                }
            )
    return rows


def build_patient_addresses(
    kept_records: list[dict[str, str]]
) -> tuple[list[dict[str, str]], dict[tuple[str, str, str, str, str], str]]:
    rows: list[dict[str, str]] = []
    address_map: dict[tuple[str, str, str, str, str], str] = {}
    for record in kept_records:
        pt_id = patient_id(record["patient_key"])
        full_address = record["domicilio_completo"] or record["domicilio"]
        key = (
            pt_id,
            base.normalize_whitespace(full_address),
            base.normalize_whitespace(record["comuna"]),
            base.normalize_whitespace(record["cesfam"]),
            base.normalize_whitespace(record["urbano_rural"]),
        )
        if not any(key[1:]):
            continue
        if key in address_map:
            continue
        ep_id = episode_id(record["dedupe_key"])
        address_id_value = stable_id("ad", *key)
        address_map[key] = address_id_value
        rows.append(
            {
                "address_id": address_id_value,
                "patient_id": pt_id,
                "full_address_raw": full_address,
                "street_text": record["domicilio"],
                "house_number": record["nro_casa"],
                "comuna": record["comuna"],
                "cesfam": record["cesfam"],
                "territory_type": record["urbano_rural"],
                "address_quality_status": "OK"
                if record["comuna"] and record["cesfam"] and full_address
                else "PARTIAL",
                "first_seen_episode_id": ep_id,
            }
        )
    return rows, address_map


def build_episode_location_snapshots(
    kept_records: list[dict[str, str]],
    address_map: dict[tuple[str, str, str, str, str], str],
) -> list[dict[str, str]]:
    rows: list[dict[str, str]] = []
    for record in kept_records:
        pt_id = patient_id(record["patient_key"])
        full_address = record["domicilio_completo"] or record["domicilio"]
        key = (
            pt_id,
            base.normalize_whitespace(full_address),
            base.normalize_whitespace(record["comuna"]),
            base.normalize_whitespace(record["cesfam"]),
            base.normalize_whitespace(record["urbano_rural"]),
        )
        address_id_value = address_map.get(key)
        if not address_id_value:
            continue
        ep_id = episode_id(record["dedupe_key"])
        rows.append(
            {
                "episode_location_snapshot_id": stable_id("ls", ep_id, address_id_value),
                "episode_id": ep_id,
                "address_id": address_id_value,
                "snapshot_full_address": full_address,
                "snapshot_comuna": record["comuna"],
                "snapshot_cesfam": record["cesfam"],
                "snapshot_territory_type": record["urbano_rural"],
            }
        )
    return rows


def build_data_quality_issues(raw_records: list[dict[str, str]], kept_records: list[dict[str, str]]) -> list[dict[str, str]]:
    episode_by_key = {record["dedupe_key"]: episode_id(record["dedupe_key"]) for record in kept_records}
    rows: list[dict[str, str]] = []
    seen = set()
    for record in raw_records:
        for note in filter(None, record.get("normalization_notes", "").split(";")):
            row_id = normalized_row_id(record["record_uid"])
            ep_id = episode_by_key.get(record["dedupe_key"], "")
            raw_value = ""
            if "rut" in note:
                raw_value = record.get("rut_raw", "")
            elif "fecha_ingreso" in note:
                raw_value = record.get("fecha_ingreso_raw", "")
            elif "fecha_egreso" in note:
                raw_value = record.get("fecha_egreso_raw", "")
            elif "fecha_nacimiento" in note or note == "birth_date_age_mismatch":
                raw_value = record.get("fecha_nacimiento_raw", "")
            key = (row_id, note)
            if key in seen:
                continue
            seen.add(key)
            rows.append(
                {
                    "quality_issue_id": stable_id("dq", row_id, note),
                    "normalized_row_id": row_id,
                    "episode_id": ep_id,
                    "issue_type": issue_type(note),
                    "severity": issue_severity(note),
                    "raw_value": raw_value,
                    "suggested_value": suggested_value(note, record),
                    "status": issue_status(note),
                }
            )
    return rows


def build_catalog_values(episode_rows: list[dict[str, str]]) -> list[dict[str, str]]:
    field_map = {
        "estado": "ESTADO",
        "motivo_egreso": "MOTIVO_EGRESO",
        "servicio_origen": "SERVICIO_ORIGEN",
        "prevision": "PREVISION",
        "barthel": "BARTHEL",
        "categorizacion": "CATEGORIZACION",
        "comuna": "COMUNA",
        "cesfam": "CESFAM",
    }
    counts: Counter[tuple[str, str]] = Counter()
    labels: dict[tuple[str, str], str] = {}

    for episode in episode_rows:
        for field_name, catalog_type in field_map.items():
            value = base.normalize_whitespace(episode.get(field_name))
            if not value:
                continue
            normalized = base.canonical_text(value)
            key = (catalog_type, normalized)
            counts[key] += 1
            labels[key] = value

    rows: list[dict[str, str]] = []
    for (catalog_type, normalized), count in sorted(counts.items()):
        label = labels[(catalog_type, normalized)]
        rows.append(
            {
                "catalog_value_id": stable_id("cv", catalog_type, normalized),
                "catalog_type": catalog_type,
                "code": base.slug_text(label).replace("-", "_").upper(),
                "label": label,
                "label_normalized": normalized,
                "source_count": str(count),
            }
        )
    return rows


def load_rut_corrections(path: Path) -> tuple[dict[tuple[str, str], dict[str, str]], dict[tuple[str, str], dict[str, str]]]:
    if not path.exists():
        return {}, {}
    with path.open("r", encoding="utf-8", newline="") as handle:
        rows = list(csv.DictReader(handle))
    corrections_by_origin: dict[tuple[str, str], dict[str, str]] = {}
    corrections_by_identity: dict[tuple[str, str], dict[str, str]] = {}
    for row in rows:
        corrected = base.normalize_whitespace(row.get("rut_corregido_confirmado"))
        if not corrected:
            continue
        origin_key = (
            base.normalize_whitespace(row.get("source_file")),
            base.normalize_whitespace(row.get("source_row_number")),
        )
        identity_key = (
            base.canonical_text(row.get("nombre_completo")),
            base.normalize_whitespace(row.get("rut_raw")),
        )
        corrections_by_origin[origin_key] = row
        corrections_by_identity[identity_key] = row
    return corrections_by_origin, corrections_by_identity


def apply_rut_corrections(
    records: list[dict[str, str]],
    corrections_by_origin: dict[tuple[str, str], dict[str, str]],
    corrections_by_identity: dict[tuple[str, str], dict[str, str]],
) -> int:
    applied = 0
    for record in records:
        origin_key = (record["source_file"], record["source_row_number"])
        identity_key = (
            base.canonical_text(record["nombre_completo"]),
            base.normalize_whitespace(record["rut_raw"]),
        )
        correction = corrections_by_origin.get(origin_key) or corrections_by_identity.get(identity_key)
        if not correction:
            continue
        corrected_raw = base.normalize_whitespace(correction.get("rut_corregido_confirmado"))
        corrected_norm = base.normalize_rut(corrected_raw)
        if not corrected_norm:
            continue
        record["rut_raw"] = corrected_raw
        record["rut"] = corrected_norm
        record["rut_valido"] = "1"
        notes = set(filter(None, record.get("normalization_notes", "").split(";")))
        notes.discard("invalid_rut_rejected")
        notes.add("manual_rut_override")
        record["normalization_notes"] = ";".join(sorted(notes))
        patient_key, patient_key_strategy = base.build_patient_identity(record)
        record["patient_key"] = patient_key
        record["patient_key_strategy"] = patient_key_strategy
        record["dedupe_key"] = base.build_dedupe_key(record)
        applied += 1
    return applied


def build_rut_correction_queue(kept_records: list[dict[str, str]]) -> list[dict[str, str]]:
    rows: list[dict[str, str]] = []
    for record in kept_records:
        if not record["rut_raw"] or record["rut_valido"] == "1":
            continue
        number, verifier = base.split_rut_candidate(record["rut_raw"])
        suggested = ""
        if number and verifier:
            suggested = f"{int(number)}-{base.calculate_rut_verifier(number)}"
        rows.append(
            {
                "source_file": record["source_file"],
                "source_row_number": record["source_row_number"],
                "record_uid": record["record_uid"],
                "nombre_completo": record["nombre_completo"],
                "fecha_nacimiento_raw": record["fecha_nacimiento_raw"],
                "rut_raw": record["rut_raw"],
                "rut_sugerido": suggested,
                "rut_corregido_confirmado": "",
                "status": "PENDING",
                "notes": "",
            }
        )
    rows.sort(key=lambda row: (row["source_file"], int(row["source_row_number"])))
    return rows


def write_sql(path: Path) -> None:
    sql = """CREATE TABLE IF NOT EXISTS raw_source_file (
    source_file_id TEXT PRIMARY KEY,
    file_name TEXT NOT NULL,
    file_family TEXT NOT NULL,
    source_pattern TEXT NOT NULL,
    header_rows INTEGER NOT NULL,
    included_in_normalized BOOLEAN NOT NULL,
    header_fingerprint TEXT NOT NULL,
    file_sha256 TEXT NOT NULL,
    row_count INTEGER NOT NULL,
    data_row_count INTEGER NOT NULL,
    imported_at TIMESTAMP NOT NULL
);

CREATE TABLE IF NOT EXISTS raw_source_row (
    source_row_id TEXT PRIMARY KEY,
    source_file_id TEXT NOT NULL REFERENCES raw_source_file(source_file_id),
    file_name TEXT NOT NULL,
    row_number INTEGER NOT NULL,
    has_payload BOOLEAN NOT NULL,
    row_hash TEXT NOT NULL,
    raw_json JSONB NOT NULL
);

CREATE TABLE IF NOT EXISTS normalized_row (
    normalized_row_id TEXT PRIMARY KEY,
    source_file_id TEXT NOT NULL REFERENCES raw_source_file(source_file_id),
    source_row_id TEXT NOT NULL REFERENCES raw_source_row(source_row_id),
    parse_status TEXT NOT NULL,
    quality_score INTEGER NOT NULL,
    record_uid TEXT NOT NULL,
    dedupe_key TEXT NOT NULL,
    patient_key TEXT NOT NULL,
    patient_key_strategy TEXT NOT NULL,
    source_file TEXT NOT NULL,
    source_family TEXT NOT NULL,
    source_pattern TEXT NOT NULL,
    source_row_number INTEGER NOT NULL,
    duplicate_count INTEGER,
    duplicate_rank INTEGER,
    duplicate_files TEXT,
    estado TEXT,
    fecha_ingreso_raw TEXT,
    fecha_ingreso DATE,
    fecha_egreso_raw TEXT,
    fecha_egreso DATE,
    dias_estadia_reportados INTEGER,
    motivo_egreso TEXT,
    motivo_derivacion TEXT,
    nombres TEXT,
    apellido_paterno TEXT,
    apellido_materno TEXT,
    apellidos TEXT,
    nombre_completo TEXT,
    sexo TEXT,
    edad_reportada INTEGER,
    fecha_nacimiento_raw TEXT,
    fecha_nacimiento DATE,
    rut_raw TEXT,
    rut_norm TEXT,
    rut_valido BOOLEAN,
    barthel TEXT,
    prevision TEXT,
    nro_ficha TEXT,
    servicio_origen TEXT,
    usuario_o2 TEXT,
    requerimiento_o2 TEXT,
    categorizacion TEXT,
    diagnostico_egreso TEXT,
    domicilio TEXT,
    nro_casa TEXT,
    domicilio_completo TEXT,
    comuna TEXT,
    cesfam TEXT,
    urbano_rural TEXT,
    nro_contacto TEXT,
    nacionalidad TEXT,
    enfermeria TEXT,
    kinesiologia TEXT,
    fonoaudiologia TEXT,
    tto_ev TEXT,
    tto_sc TEXT,
    tto_im TEXT,
    curaciones TEXT,
    toma_muestras TEXT,
    manejo_ostomias TEXT,
    elementos_invasivos TEXT,
    csv_flag TEXT,
    educacion TEXT,
    medico TEXT,
    knt TEXT,
    fono TEXT,
    trabajo_social TEXT,
    normalization_notes TEXT,
    non_empty_fields INTEGER
);

CREATE TABLE IF NOT EXISTS patient_master (
    patient_id TEXT PRIMARY KEY,
    canonical_patient_key TEXT NOT NULL,
    identity_resolution_status TEXT NOT NULL,
    patient_key TEXT NOT NULL,
    patient_key_strategy TEXT NOT NULL,
    rut TEXT,
    rut_valido BOOLEAN,
    rut_raw TEXT,
    nombres TEXT,
    apellido_paterno TEXT,
    apellido_materno TEXT,
    apellidos TEXT,
    nombre_completo TEXT,
    sexo TEXT,
    fecha_nacimiento DATE,
    fecha_nacimiento_raw TEXT,
    edad_reportada INTEGER,
    nacionalidad TEXT,
    nro_contacto TEXT,
    domicilio TEXT,
    comuna TEXT,
    cesfam TEXT,
    episode_count INTEGER,
    source_files TEXT
);

CREATE TABLE IF NOT EXISTS patient_identity_candidate (
    identity_candidate_id TEXT PRIMARY KEY,
    normalized_row_id TEXT NOT NULL REFERENCES normalized_row(normalized_row_id),
    episode_id TEXT NOT NULL,
    patient_id TEXT NOT NULL REFERENCES patient_master(patient_id),
    patient_key TEXT NOT NULL,
    patient_key_strategy TEXT NOT NULL,
    identity_confidence NUMERIC(4,2) NOT NULL,
    review_required BOOLEAN NOT NULL,
    rut_norm TEXT,
    rut_valido BOOLEAN,
    nombre_completo_norm TEXT,
    fecha_nacimiento DATE,
    contacto_norm TEXT
);

CREATE TABLE IF NOT EXISTS patient_identity_link (
    patient_identity_link_id TEXT PRIMARY KEY,
    patient_id TEXT NOT NULL REFERENCES patient_master(patient_id),
    identity_candidate_id TEXT NOT NULL REFERENCES patient_identity_candidate(identity_candidate_id),
    link_type TEXT NOT NULL,
    is_primary BOOLEAN NOT NULL
);

CREATE TABLE IF NOT EXISTS episode (
    episode_id TEXT PRIMARY KEY,
    patient_id TEXT NOT NULL REFERENCES patient_master(patient_id),
    source_episode_key TEXT NOT NULL,
    record_uid TEXT NOT NULL,
    estado TEXT,
    tipo_flujo TEXT,
    fecha_ingreso DATE,
    fecha_egreso DATE,
    dias_estadia_reportados INTEGER,
    dias_estadia_calculados INTEGER,
    motivo_egreso TEXT,
    motivo_derivacion TEXT,
    servicio_origen TEXT,
    prevision TEXT,
    barthel TEXT,
    categorizacion TEXT,
    usuario_o2 TEXT,
    requerimiento_o2 TEXT,
    diagnostico_principal_texto TEXT,
    episode_status_quality TEXT,
    duplicate_count INTEGER
);

CREATE TABLE IF NOT EXISTS episode_source_link (
    episode_source_link_id TEXT PRIMARY KEY,
    episode_id TEXT NOT NULL REFERENCES episode(episode_id),
    normalized_row_id TEXT NOT NULL REFERENCES normalized_row(normalized_row_id),
    record_uid TEXT NOT NULL,
    source_file TEXT NOT NULL,
    source_row_number INTEGER NOT NULL,
    duplicate_rank INTEGER,
    is_retained_row BOOLEAN NOT NULL
);

CREATE TABLE IF NOT EXISTS episode_diagnosis (
    episode_diagnosis_id TEXT PRIMARY KEY,
    episode_id TEXT NOT NULL REFERENCES episode(episode_id),
    diagnosis_role TEXT NOT NULL,
    diagnosis_text_raw TEXT NOT NULL,
    diagnosis_text_norm TEXT NOT NULL,
    coding_status TEXT NOT NULL,
    cie10_code TEXT
);

CREATE TABLE IF NOT EXISTS episode_care_requirement (
    episode_requirement_id TEXT PRIMARY KEY,
    episode_id TEXT NOT NULL REFERENCES episode(episode_id),
    requirement_type TEXT NOT NULL,
    requirement_value_raw TEXT NOT NULL,
    requirement_value_norm TEXT NOT NULL,
    is_active BOOLEAN NOT NULL
);

CREATE TABLE IF NOT EXISTS episode_professional_need (
    episode_professional_need_id TEXT PRIMARY KEY,
    episode_id TEXT NOT NULL REFERENCES episode(episode_id),
    professional_type TEXT NOT NULL,
    need_level TEXT NOT NULL,
    source_column TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS patient_contact_point (
    contact_point_id TEXT PRIMARY KEY,
    patient_id TEXT NOT NULL REFERENCES patient_master(patient_id),
    source_episode_id TEXT REFERENCES episode(episode_id),
    contact_type TEXT NOT NULL,
    contact_value_raw TEXT NOT NULL,
    contact_value_norm TEXT NOT NULL,
    is_primary BOOLEAN NOT NULL
);

CREATE TABLE IF NOT EXISTS patient_address (
    address_id TEXT PRIMARY KEY,
    patient_id TEXT NOT NULL REFERENCES patient_master(patient_id),
    full_address_raw TEXT NOT NULL,
    street_text TEXT,
    house_number TEXT,
    comuna TEXT,
    cesfam TEXT,
    territory_type TEXT,
    address_quality_status TEXT NOT NULL,
    first_seen_episode_id TEXT REFERENCES episode(episode_id)
);

CREATE TABLE IF NOT EXISTS episode_location_snapshot (
    episode_location_snapshot_id TEXT PRIMARY KEY,
    episode_id TEXT NOT NULL REFERENCES episode(episode_id),
    address_id TEXT NOT NULL REFERENCES patient_address(address_id),
    snapshot_full_address TEXT,
    snapshot_comuna TEXT,
    snapshot_cesfam TEXT,
    snapshot_territory_type TEXT
);

CREATE TABLE IF NOT EXISTS data_quality_issue (
    quality_issue_id TEXT PRIMARY KEY,
    normalized_row_id TEXT NOT NULL REFERENCES normalized_row(normalized_row_id),
    episode_id TEXT REFERENCES episode(episode_id),
    issue_type TEXT NOT NULL,
    severity TEXT NOT NULL,
    raw_value TEXT,
    suggested_value TEXT,
    status TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS catalog_value (
    catalog_value_id TEXT PRIMARY KEY,
    catalog_type TEXT NOT NULL,
    code TEXT NOT NULL,
    label TEXT NOT NULL,
    label_normalized TEXT NOT NULL,
    source_count INTEGER NOT NULL
);
"""
    path.write_text(sql, encoding="utf-8")


def write_manifest(path: Path, outputs: dict[str, list[dict[str, str]]], corrections_applied: int) -> None:
    manifest = {
        "generated_at": datetime.now().isoformat(timespec="seconds"),
        "rut_corrections_applied": corrections_applied,
        "tables": {name: len(rows) for name, rows in outputs.items()},
    }
    path.write_text(json.dumps(manifest, indent=2, ensure_ascii=False), encoding="utf-8")


def write_readme(path: Path, outputs: dict[str, list[dict[str, str]]]) -> None:
    lines = [
        "# Pipeline Intermedio HODOM",
        "",
        "Este directorio contiene la tubería materializada por capas para ir desde CSV raw hasta entidades listas para migración.",
        "",
        "## Runner",
        "",
        "```bash",
        "python3 /Users/felixsanhueza/Developer/_workspaces/hdos/scripts/build_hodom_intermediate.py",
        "```",
        "",
        "Si existe `/Users/felixsanhueza/Developer/_workspaces/hdos/input/manual/rut_corrections.csv`, el runner aplica esas correcciones antes de deduplicar.",
        "Si no existe, el runner genera ese archivo con la cola actual de RUT inválidos para que puedas completarlo.",
        "",
        "## Capas",
        "",
        "- `raw_source_file.csv` y `raw_source_row.csv`: ingesta cruda sin pérdida.",
        "- `normalized_row.csv`: parseo y normalización técnica, todavía fila-a-fila.",
        "- `patient_master.csv`, `patient_identity_candidate.csv`, `patient_identity_link.csv`: resolución de identidad.",
        "- `episode.csv`, `episode_source_link.csv`, `episode_diagnosis.csv`: episodios y trazabilidad.",
        "- `episode_care_requirement.csv` y `episode_professional_need.csv`: requerimientos y necesidades profesionales.",
        "- `patient_contact_point.csv`, `patient_address.csv`, `episode_location_snapshot.csv`: contacto y domicilio.",
        "- `data_quality_issue.csv`: cola estructurada de calidad de dato.",
        "- `catalog_value.csv`: catálogos observados en la capa curada.",
        "- `rut_correction_queue.csv`: cola editable para completar correcciones manuales de RUT.",
        "",
        "## Conteos de esta corrida",
        "",
    ]
    for name, rows in outputs.items():
        lines.append(f"- `{name}.csv`: `{len(rows)}` filas")
    lines.extend(
        [
            "",
            "## DDL",
            "",
            "La definición PostgreSQL de esta estructura quedó en `hodom_intermediate_postgres.sql`.",
        ]
    )
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Materializa la estructura intermedia refinada HODOM desde CSV raw."
    )
    parser.add_argument(
        "--source-dir",
        type=Path,
        default=Path("salida de csv desde planillas hodom ingresos"),
        help="Directorio con CSV fuente.",
    )
    parser.add_argument(
        "--output-dir",
        type=Path,
        default=Path("output/spreadsheet/intermediate"),
        help="Directorio de salida de la tubería intermedia.",
    )
    parser.add_argument(
        "--rut-corrections",
        type=Path,
        default=Path("input/manual/rut_corrections.csv"),
        help="Archivo opcional con correcciones manuales de RUT.",
    )
    args = parser.parse_args()

    raw_files, raw_rows, file_id_by_name = load_raw_source_layers(args.source_dir)
    raw_records = base.read_records(args.source_dir)
    corrections_by_origin, corrections_by_identity = load_rut_corrections(args.rut_corrections)
    corrections_applied = apply_rut_corrections(raw_records, corrections_by_origin, corrections_by_identity)
    kept_records, _ = base.deduplicate_records(raw_records)

    normalized_rows = build_normalized_rows(raw_records, file_id_by_name)
    patient_rows = build_patient_master_rows(kept_records)
    identity_rows = build_patient_identity_candidates(kept_records)
    identity_links = build_patient_identity_links(identity_rows)
    episode_rows = build_episode_rows(kept_records)
    episode_source_links = build_episode_source_links(raw_records, kept_records)
    diagnosis_rows = build_episode_diagnoses(kept_records)
    requirement_rows = build_episode_care_requirements(kept_records)
    professional_need_rows = build_episode_professional_needs(kept_records)
    contact_rows = build_patient_contact_points(kept_records)
    address_rows, address_map = build_patient_addresses(kept_records)
    location_snapshot_rows = build_episode_location_snapshots(kept_records, address_map)
    quality_rows = build_data_quality_issues(raw_records, kept_records)
    catalog_rows = build_catalog_values(
        [
            {
                **record,
                "comuna": record["comuna"],
                "cesfam": record["cesfam"],
            }
            for record in kept_records
        ]
    )
    rut_queue_rows = build_rut_correction_queue(kept_records)

    outputs = {
        "raw_source_file": raw_files,
        "raw_source_row": raw_rows,
        "normalized_row": normalized_rows,
        "patient_identity_candidate": identity_rows,
        "patient_master": patient_rows,
        "patient_identity_link": identity_links,
        "episode": episode_rows,
        "episode_source_link": episode_source_links,
        "episode_diagnosis": diagnosis_rows,
        "episode_care_requirement": requirement_rows,
        "episode_professional_need": professional_need_rows,
        "patient_contact_point": contact_rows,
        "patient_address": address_rows,
        "episode_location_snapshot": location_snapshot_rows,
        "data_quality_issue": quality_rows,
        "catalog_value": catalog_rows,
        "rut_correction_queue": rut_queue_rows,
    }

    column_map = {
        "raw_source_file": RAW_SOURCE_FILE_COLUMNS,
        "raw_source_row": RAW_SOURCE_ROW_COLUMNS,
        "normalized_row": NORMALIZED_ROW_COLUMNS,
        "patient_identity_candidate": PATIENT_IDENTITY_CANDIDATE_COLUMNS,
        "patient_master": PATIENT_MASTER_COLUMNS,
        "patient_identity_link": PATIENT_IDENTITY_LINK_COLUMNS,
        "episode": EPISODE_COLUMNS,
        "episode_source_link": EPISODE_SOURCE_LINK_COLUMNS,
        "episode_diagnosis": EPISODE_DIAGNOSIS_COLUMNS,
        "episode_care_requirement": EPISODE_CARE_REQUIREMENT_COLUMNS,
        "episode_professional_need": EPISODE_PROFESSIONAL_NEED_COLUMNS,
        "patient_contact_point": PATIENT_CONTACT_POINT_COLUMNS,
        "patient_address": PATIENT_ADDRESS_COLUMNS,
        "episode_location_snapshot": EPISODE_LOCATION_SNAPSHOT_COLUMNS,
        "data_quality_issue": DATA_QUALITY_ISSUE_COLUMNS,
        "catalog_value": CATALOG_VALUE_COLUMNS,
        "rut_correction_queue": RUT_CORRECTION_QUEUE_COLUMNS,
    }

    args.output_dir.mkdir(parents=True, exist_ok=True)
    for name, rows in outputs.items():
        write_csv(args.output_dir / f"{name}.csv", rows, column_map[name])
    if not args.rut_corrections.exists():
        write_csv(args.rut_corrections, rut_queue_rows, RUT_CORRECTION_QUEUE_COLUMNS)
    write_sql(args.output_dir / "hodom_intermediate_postgres.sql")
    write_manifest(args.output_dir / "manifest.json", outputs, corrections_applied)
    write_readme(args.output_dir / "README.md", outputs)

    print(f"Output dir: {args.output_dir.resolve()}")
    print(f"rut_corrections_applied: {corrections_applied}")
    for name, rows in outputs.items():
        print(f"{name}: {len(rows)}")


if __name__ == "__main__":
    main()
