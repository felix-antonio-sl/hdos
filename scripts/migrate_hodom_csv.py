#!/usr/bin/env python3
from __future__ import annotations

import argparse
import csv
import hashlib
import json
import re
import unicodedata
from collections import Counter, defaultdict
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path
from typing import Iterable


OUTPUT_COLUMNS = [
    "record_uid",
    "dedupe_key",
    "patient_key",
    "patient_key_strategy",
    "source_file",
    "source_family",
    "source_pattern",
    "source_row_number",
    "source_row_id",
    "duplicate_count",
    "duplicate_rank",
    "duplicate_files",
    "estado",
    "fecha_ingreso_raw",
    "fecha_ingreso_date",
    "fecha_egreso_raw",
    "fecha_egreso_date",
    "dias_estadia_reportados",
    "motivo_egreso",
    "motivo_derivacion",
    "nombres",
    "apellido_paterno",
    "apellido_materno",
    "apellidos",
    "nombre_completo",
    "sexo",
    "edad_reportada",
    "fecha_nacimiento_raw",
    "fecha_nacimiento_date",
    "rut_raw",
    "rut",
    "rut_valido",
    "barthel",
    "prevision",
    "nro_ficha",
    "servicio_origen",
    "usuario_o2",
    "requerimiento_o2",
    "categorizacion",
    "diagnostico_egreso",
    "domicilio",
    "nro_casa",
    "domicilio_completo",
    "comuna",
    "cesfam",
    "urbano_rural",
    "nro_contacto",
    "nacionalidad",
    "enfermeria",
    "kinesiologia",
    "fonoaudiologia",
    "tto_ev",
    "tto_sc",
    "tto_im",
    "curaciones",
    "toma_muestras",
    "manejo_ostomias",
    "elementos_invasivos",
    "csv_flag",
    "educacion",
    "medico",
    "knt",
    "fono",
    "trabajo_social",
    "normalization_notes",
    "non_empty_fields",
]

PATIENT_COLUMNS = [
    "patient_key",
    "patient_key_strategy",
    "rut",
    "rut_valido",
    "rut_raw",
    "nombres",
    "apellido_paterno",
    "apellido_materno",
    "apellidos",
    "nombre_completo",
    "sexo",
    "fecha_nacimiento_date",
    "fecha_nacimiento_raw",
    "edad_reportada",
    "nacionalidad",
    "nro_contacto",
    "domicilio",
    "comuna",
    "cesfam",
    "episode_count",
    "source_files",
]

FILE_SUMMARY_COLUMNS = [
    "source_file",
    "source_family",
    "source_pattern",
    "raw_records",
    "deduped_records_kept",
    "duplicates_discarded",
    "min_fecha_ingreso",
    "max_fecha_ingreso",
    "min_fecha_egreso",
    "max_fecha_egreso",
]

PATTERN_WEIGHTS = {
    "p43": 40,
    "p43_headerless": 30,
    "p40": 25,
    "p27": 20,
    "p26": 15,
}

P43_COLUMNS = [
    "source_row_id",
    "estado",
    "fecha_ingreso_raw",
    "dias_estadia_reportados",
    "fecha_egreso_raw",
    "nombres",
    "apellido_paterno",
    "apellido_materno",
    "sexo",
    "edad_reportada",
    "rut_raw",
    "barthel",
    "prevision",
    "fecha_nacimiento_raw",
    "nro_ficha",
    "servicio_origen",
    "usuario_o2",
    "requerimiento_o2",
    "categorizacion",
    "diagnostico_egreso",
    "domicilio",
    "nro_casa",
    "comuna",
    "cesfam",
    "urbano_rural",
    "nro_contacto",
    "nacionalidad",
    "tto_ev",
    "tto_sc",
    "tto_im",
    "curaciones",
    "toma_muestras",
    "manejo_ostomias",
    "elementos_invasivos",
    "csv_flag",
    "educacion",
    "medico",
    "knt",
    "fono",
    "trabajo_social",
    "fecha_egreso_secundaria_raw",
    "motivo_egreso",
    "motivo_derivacion",
]

P40_COLUMNS = [
    "source_row_id",
    "estado",
    "fecha_ingreso_raw",
    "dias_estadia_reportados",
    "fecha_egreso_raw",
    "nombres",
    "apellido_paterno",
    "apellido_materno",
    "sexo",
    "edad_reportada",
    "rut_raw",
    "barthel",
    "prevision",
    "fecha_nacimiento_raw",
    "nro_ficha",
    "servicio_origen",
    "diagnostico_egreso",
    "domicilio",
    "nro_casa",
    "comuna",
    "cesfam",
    "urbano_rural",
    "nro_contacto",
    "nacionalidad",
    "tto_ev",
    "tto_sc",
    "tto_im",
    "curaciones",
    "toma_muestras",
    "manejo_ostomias",
    "elementos_invasivos",
    "csv_flag",
    "educacion",
    "medico",
    "knt",
    "fono",
    "trabajo_social",
    "fecha_egreso_secundaria_raw",
    "motivo_egreso",
    "motivo_derivacion",
]

P27_COLUMNS = [
    "source_row_id",
    "estado",
    "fecha_ingreso_raw",
    "fecha_egreso_raw",
    "dias_estadia_reportados",
    "motivo_egreso",
    "nombres",
    "apellidos",
    "sexo",
    "edad_reportada",
    "fecha_nacimiento_raw",
    "rut_raw",
    "barthel",
    "prevision",
    "servicio_origen",
    "usuario_o2",
    "requerimiento_o2",
    "categorizacion",
    "diagnostico_egreso",
    "domicilio",
    "comuna",
    "cesfam",
    "nro_contacto",
    "nacionalidad",
    "enfermeria",
    "kinesiologia",
    "fonoaudiologia",
]

P26_COLUMNS = [
    "estado",
    "fecha_ingreso_raw",
    "fecha_egreso_raw",
    "dias_estadia_reportados",
    "motivo_egreso",
    "nombre_completo",
    "sexo",
    "edad_reportada",
    "fecha_nacimiento_raw",
    "rut_raw",
    "barthel",
    "prevision",
    "servicio_origen",
    "usuario_o2",
    "requerimiento_o2",
    "categorizacion",
    "diagnostico_egreso",
    "domicilio",
    "comuna",
    "cesfam",
    "urbano_rural",
    "nro_contacto",
    "nacionalidad",
    "enfermeria",
    "kinesiologia",
    "fonoaudiologia",
]


@dataclass(frozen=True)
class PatternSpec:
    name: str
    columns: list[str]
    header_rows: int


PATTERN_SPECS = {
    "p26": PatternSpec("p26", P26_COLUMNS, 1),
    "p27": PatternSpec("p27", P27_COLUMNS, 1),
    "p40": PatternSpec("p40", P40_COLUMNS, 1),
    "p43": PatternSpec("p43", P43_COLUMNS, 1),
    "p43_headerless": PatternSpec("p43_headerless", P43_COLUMNS, 0),
}


def normalize_whitespace(value: str | None) -> str:
    if value is None:
        return ""
    return re.sub(r"\s+", " ", value.replace("\ufeff", " ").strip())


def canonical_text(value: str | None) -> str:
    text = normalize_whitespace(value)
    if not text:
        return ""
    folded = unicodedata.normalize("NFKD", text)
    folded = "".join(ch for ch in folded if not unicodedata.combining(ch))
    return re.sub(r"[^A-Z0-9]+", " ", folded.upper()).strip()


def slug_text(value: str | None) -> str:
    slug = canonical_text(value).lower().replace(" ", "-")
    slug = re.sub(r"-{2,}", "-", slug).strip("-")
    return slug[:80]


def digits_only(value: str | None) -> str:
    return re.sub(r"\D", "", normalize_whitespace(value))


def looks_like_date_literal(value: str | None) -> bool:
    text = normalize_whitespace(value)
    if not text:
        return False
    if "GMT" in text.upper():
        return True
    if re.search(r"\b(?:MON|TUE|WED|THU|FRI|SAT|SUN)\b", text.upper()):
        return True
    return bool(re.fullmatch(r"\d{1,2}[-/]\d{1,2}[-/]\d{2,5}", text))


def repair_year_token(year_token: str) -> str:
    token = year_token.strip()
    if len(token) == 4 and token.isdigit():
        return token
    if len(token) == 5 and token.isdigit() and token.startswith("0"):
        return token[1:]
    if len(token) == 3 and token.isdigit():
        candidates: list[int] = []
        for position in range(4):
            for digit in "0123456789":
                candidate = token[:position] + digit + token[position:]
                year = int(candidate)
                if 1900 <= year <= datetime.now().year + 2:
                    candidates.append(year)
        if candidates:
            return str(min(candidates, key=lambda year: abs(year - datetime.now().year)))
    if len(token) == 2 and token.isdigit():
        year = int(token)
        century = 2000 if year <= (datetime.now().year % 100) + 2 else 1900
        return str(century + year)
    return token


def parse_numeric_date(text: str) -> str:
    match = re.fullmatch(r"(\d{1,2})[-/](\d{1,2})[-/](\d{2,5})", text)
    if not match:
        return ""
    day_token, month_token, year_token = match.groups()
    repaired_year = repair_year_token(year_token)
    try:
        parsed = datetime(
            int(repaired_year),
            int(month_token),
            int(day_token),
        )
    except ValueError:
        return ""
    return parsed.date().isoformat()


def calculate_rut_verifier(number: str) -> str:
    total = 0
    multiplier = 2
    for digit in reversed(number):
        total += int(digit) * multiplier
        multiplier += 1
        if multiplier > 7:
            multiplier = 2
    remainder = 11 - (total % 11)
    if remainder == 11:
        return "0"
    if remainder == 10:
        return "K"
    return str(remainder)


def split_rut_candidate(value: str | None) -> tuple[str, str]:
    text = normalize_whitespace(value).upper().replace(".", "").replace(" ", "")
    if not text or looks_like_date_literal(text):
        return "", ""
    cleaned = re.sub(r"[^0-9K-]", "", text)
    if not cleaned:
        return "", ""
    if "-" in cleaned:
        number, verifier = cleaned.split("-", 1)
    else:
        if len(cleaned) < 2:
            return "", ""
        number, verifier = cleaned[:-1], cleaned[-1]
    number = re.sub(r"\D", "", number)
    verifier = re.sub(r"[^0-9K]", "", verifier.upper())
    return number, verifier


def normalize_rut(value: str | None) -> str:
    number, verifier = split_rut_candidate(value)
    if not number or not verifier:
        return ""
    if len(number) < 6 or len(number) > 8:
        return ""
    if calculate_rut_verifier(number) != verifier:
        return ""
    return f"{int(number)}-{verifier}"


def normalize_estado(value: str | None) -> str:
    text = canonical_text(value)
    if not text:
        return ""
    if "ACTIV" in text:
        return "ACTIVO"
    if "EGRESA" in text:
        return "EGRESADO"
    return normalize_whitespace(value).upper()


def normalize_sexo(value: str | None) -> str:
    text = canonical_text(value)
    if text in {"F", "FEMENINO"}:
        return "F"
    if text in {"M", "MASCULINO"}:
        return "M"
    return ""


def normalize_barthel(value: str | None) -> str:
    text = canonical_text(value)
    if not text or text == "N A":
        return ""
    if "AUTO" in text or "INDEPEND" in text:
        return "INDEPENDIENTE"
    if "TOTAL" in text:
        return "DEP. TOTAL"
    if "SEVERA" in text:
        return "DEP. SEVERA"
    if "MODERADA" in text:
        return "DEP. MODERADA"
    if "LEVE" in text:
        return "DEP. LEVE"
    return normalize_whitespace(value).upper()


def normalize_prevision(value: str | None) -> str:
    text = canonical_text(value)
    if not text:
        return ""
    if text.startswith("FONASA"):
        for tramo in ("A", "B", "C", "D"):
            if re.search(rf"\b{tramo}\b", text):
                return f"FONASA {tramo}"
        return "FONASA"
    if "PRAIS" in text:
        return "PRAIS"
    return normalize_whitespace(value).upper()


def parse_date(value: str | None) -> str:
    text = normalize_whitespace(value)
    if not text:
        return ""

    parsed_numeric = parse_numeric_date(text)
    if parsed_numeric:
        return parsed_numeric

    sanitized = re.sub(r"\s+\([^)]*\)$", "", text)
    for fmt in ("%a %b %d %Y %H:%M:%S GMT%z",):
        try:
            return datetime.strptime(sanitized, fmt).date().isoformat()
        except ValueError:
            pass

    if re.fullmatch(r"\d{4}-\d{2}-\d{2}", text):
        try:
            return datetime.strptime(text, "%Y-%m-%d").date().isoformat()
        except ValueError:
            return ""

    return ""


def parse_int(value: str | None) -> str:
    text = normalize_whitespace(value)
    if not text:
        return ""
    digits = re.sub(r"[^0-9-]", "", text)
    if not digits:
        return ""
    try:
        return str(int(digits))
    except ValueError:
        return ""


def join_non_empty(parts: Iterable[str]) -> str:
    return normalize_whitespace(" ".join(part for part in parts if normalize_whitespace(part)))


def age_matches_birth_date(
    birth_date_iso: str,
    age_reported: str,
    reference_date_iso: str,
) -> bool:
    if not birth_date_iso or not age_reported:
        return True
    try:
        birth_date = datetime.strptime(birth_date_iso, "%Y-%m-%d").date()
        reference_date = datetime.strptime(reference_date_iso, "%Y-%m-%d").date()
        reported_age = int(age_reported)
    except ValueError:
        return True

    computed_age = reference_date.year - birth_date.year
    if (reference_date.month, reference_date.day) < (birth_date.month, birth_date.day):
        computed_age -= 1
    return 0 <= computed_age <= 120 and abs(computed_age - reported_age) <= 2


def normalize_servicio_origen(value: str | None) -> str:
    text = canonical_text(value)
    if not text:
        return ""
    if text in {"MED", "MEDICINA", "MEDCINA"}:
        return "MEDICINA"
    if text in {"CX", "CIRUGIA"}:
        return "CIRUGIA"
    return normalize_whitespace(value).upper()


def repair_mapped_row(mapped: dict[str, str], pattern_name: str) -> tuple[dict[str, str], list[str]]:
    repaired = dict(mapped)
    notes: list[str] = []

    fecha_nacimiento_raw = repaired.get("fecha_nacimiento_raw", "")
    rut_raw = repaired.get("rut_raw", "")
    if (
        pattern_name == "p26"
        and split_rut_candidate(fecha_nacimiento_raw)[0]
        and looks_like_date_literal(rut_raw)
    ):
        repaired["fecha_nacimiento_raw"], repaired["rut_raw"] = rut_raw, fecha_nacimiento_raw
        notes.append("swap_rut_fecha_nacimiento")

    return repaired, notes


def file_family(filename: str) -> str:
    upper_name = filename.upper()
    if upper_name.startswith("INGRESOS"):
        return "INGRESOS"
    if upper_name.startswith("EGRESOS"):
        return "EGRESOS"
    return "OTRO"


def detect_pattern(filename: str, rows: list[list[str]]) -> PatternSpec | None:
    if filename == "NO MOD.csv":
        return None
    if filename == "EGRESOS NOVIEMBRE.csv":
        return PATTERN_SPECS["p43_headerless"]
    if not rows:
        return None

    width = len(rows[0])
    if width == 26:
        return PATTERN_SPECS["p26"]
    if width == 27:
        return PATTERN_SPECS["p27"]
    if width == 40:
        return PATTERN_SPECS["p40"]
    if width == 43:
        return PATTERN_SPECS["p43"]
    return None


def pad_row(row: list[str], width: int) -> list[str]:
    if len(row) < width:
        return row + [""] * (width - len(row))
    if len(row) > width:
        return row[:width]
    return row


def record_non_empty_fields(record: dict[str, str]) -> int:
    excluded = {
        "record_uid",
        "dedupe_key",
        "patient_key",
        "patient_key_strategy",
        "source_file",
        "source_family",
        "source_pattern",
        "source_row_number",
        "duplicate_count",
        "duplicate_rank",
        "duplicate_files",
        "rut_valido",
        "normalization_notes",
        "non_empty_fields",
    }
    return sum(1 for key, value in record.items() if key not in excluded and normalize_whitespace(value))


def make_record_uid(filename: str, row_number: int) -> str:
    return hashlib.sha1(f"{filename}:{row_number}".encode("utf-8")).hexdigest()[:16]


def build_patient_identity(record: dict[str, str]) -> tuple[str, str]:
    rut = record["rut"]
    if rut:
        return f"rut:{rut}", "rut"

    name_slug = slug_text(record["nombre_completo"])
    birth_date = record["fecha_nacimiento_date"]
    contact_digits = digits_only(record["nro_contacto"])[:12]

    if name_slug and birth_date:
        return f"nombre-fecha:{name_slug}:{birth_date.replace('-', '')}", "nombre_fecha"
    if name_slug and contact_digits:
        return f"nombre-contacto:{name_slug}:{contact_digits}", "nombre_contacto"
    if name_slug:
        return f"nombre:{name_slug}", "nombre"
    return f"legacy:{record['record_uid']}", "legacy"


def build_dedupe_key(record: dict[str, str]) -> str:
    payload = "|".join(
        [
            record["rut"] or record["patient_key"],
            record["fecha_ingreso_date"] or canonical_text(record["fecha_ingreso_raw"]),
            record["fecha_egreso_date"] or canonical_text(record["fecha_egreso_raw"]),
            canonical_text(record["estado"]),
            canonical_text(record["diagnostico_egreso"]),
            canonical_text(record["motivo_egreso"]),
        ]
    )
    return hashlib.sha1(payload.encode("utf-8")).hexdigest()[:20]


def pattern_rank(pattern_name: str) -> int:
    return PATTERN_WEIGHTS.get(pattern_name, 0)


def record_rank(record: dict[str, str]) -> tuple[int, int, int]:
    return (
        pattern_rank(record["source_pattern"]),
        int(record["non_empty_fields"]),
        -int(record["source_row_number"]),
    )


def normalize_record(mapped: dict[str, str], filename: str, row_number: int, pattern_name: str) -> dict[str, str]:
    mapped, notes = repair_mapped_row(mapped, pattern_name)
    record = {column: "" for column in OUTPUT_COLUMNS}
    record["record_uid"] = make_record_uid(filename, row_number)
    record["source_file"] = filename
    record["source_family"] = file_family(filename)
    record["source_pattern"] = pattern_name
    record["source_row_number"] = str(row_number)
    record["source_row_id"] = normalize_whitespace(mapped.get("source_row_id"))

    for key in (
        "estado",
        "motivo_egreso",
        "motivo_derivacion",
        "nombres",
        "apellido_paterno",
        "apellido_materno",
        "apellidos",
        "nombre_completo",
        "sexo",
        "barthel",
        "prevision",
        "nro_ficha",
        "servicio_origen",
        "usuario_o2",
        "requerimiento_o2",
        "categorizacion",
        "diagnostico_egreso",
        "domicilio",
        "nro_casa",
        "comuna",
        "cesfam",
        "urbano_rural",
        "nro_contacto",
        "nacionalidad",
        "enfermeria",
        "kinesiologia",
        "fonoaudiologia",
        "tto_ev",
        "tto_sc",
        "tto_im",
        "curaciones",
        "toma_muestras",
        "manejo_ostomias",
        "elementos_invasivos",
        "csv_flag",
        "educacion",
        "medico",
        "knt",
        "fono",
        "trabajo_social",
    ):
        record[key] = normalize_whitespace(mapped.get(key))

    if not record["nombre_completo"]:
        record["nombre_completo"] = join_non_empty(
            [
                mapped.get("nombres", ""),
                mapped.get("apellido_paterno", ""),
                mapped.get("apellido_materno", ""),
                mapped.get("apellidos", ""),
            ]
        )

    if not record["apellidos"]:
        record["apellidos"] = join_non_empty(
            [mapped.get("apellido_paterno", ""), mapped.get("apellido_materno", "")]
        )

    record["fecha_ingreso_raw"] = normalize_whitespace(mapped.get("fecha_ingreso_raw"))
    egreso_primary = normalize_whitespace(mapped.get("fecha_egreso_raw"))
    egreso_secondary = normalize_whitespace(mapped.get("fecha_egreso_secundaria_raw"))
    record["fecha_egreso_raw"] = egreso_primary or egreso_secondary
    record["fecha_nacimiento_raw"] = normalize_whitespace(mapped.get("fecha_nacimiento_raw"))

    record["fecha_ingreso_date"] = parse_date(record["fecha_ingreso_raw"])
    record["fecha_egreso_date"] = parse_date(record["fecha_egreso_raw"])
    record["fecha_nacimiento_date"] = parse_date(record["fecha_nacimiento_raw"])
    record["dias_estadia_reportados"] = parse_int(mapped.get("dias_estadia_reportados"))
    record["edad_reportada"] = parse_int(mapped.get("edad_reportada"))
    record["rut_raw"] = normalize_whitespace(mapped.get("rut_raw"))
    record["rut"] = normalize_rut(mapped.get("rut_raw"))
    record["rut_valido"] = "1" if record["rut"] else "0"

    reference_date = record["fecha_ingreso_date"] or record["fecha_egreso_date"]
    if reference_date and not age_matches_birth_date(
        record["fecha_nacimiento_date"],
        record["edad_reportada"],
        reference_date,
    ):
        notes.append("birth_date_age_mismatch")
        record["fecha_nacimiento_date"] = ""

    record["domicilio_completo"] = join_non_empty(
        [record["domicilio"], record["nro_casa"]]
    )

    normalized_estado = normalize_estado(record["estado"])
    if normalized_estado != record["estado"] and record["estado"]:
        notes.append("normalize_estado")
    record["estado"] = normalized_estado

    normalized_sexo = normalize_sexo(record["sexo"])
    if record["sexo"] and normalized_sexo != record["sexo"]:
        notes.append("normalize_sexo")
    record["sexo"] = normalized_sexo

    normalized_barthel = normalize_barthel(record["barthel"])
    if normalized_barthel and normalized_barthel != record["barthel"]:
        notes.append("normalize_barthel")
    record["barthel"] = normalized_barthel

    normalized_prevision = normalize_prevision(record["prevision"])
    if normalized_prevision != record["prevision"] and record["prevision"]:
        notes.append("normalize_prevision")
    record["prevision"] = normalized_prevision

    normalized_servicio = normalize_servicio_origen(record["servicio_origen"])
    if normalized_servicio != record["servicio_origen"] and record["servicio_origen"]:
        notes.append("normalize_servicio")
    record["servicio_origen"] = normalized_servicio

    if record["rut_raw"] and not record["rut"]:
        notes.append("invalid_rut_rejected")
    if record["fecha_ingreso_raw"] and not record["fecha_ingreso_date"]:
        notes.append("invalid_fecha_ingreso")
    if record["fecha_egreso_raw"] and not record["fecha_egreso_date"]:
        notes.append("invalid_fecha_egreso")
    if record["fecha_nacimiento_raw"] and not record["fecha_nacimiento_date"]:
        notes.append("invalid_fecha_nacimiento")

    patient_key, patient_key_strategy = build_patient_identity(record)
    record["patient_key"] = patient_key
    record["patient_key_strategy"] = patient_key_strategy
    record["normalization_notes"] = ";".join(sorted(set(notes)))
    record["non_empty_fields"] = str(record_non_empty_fields(record))
    record["dedupe_key"] = build_dedupe_key(record)
    return record


def has_meaningful_payload(record: dict[str, str]) -> bool:
    payload_fields = [
        "estado",
        "fecha_ingreso_raw",
        "fecha_egreso_raw",
        "rut_raw",
        "nombre_completo",
        "nombres",
        "apellidos",
        "diagnostico_egreso",
    ]
    return any(normalize_whitespace(record.get(field)) for field in payload_fields)


def read_records(source_dir: Path) -> list[dict[str, str]]:
    records: list[dict[str, str]] = []
    for path in sorted(source_dir.glob("*.csv")):
        with path.open("r", encoding="utf-8-sig", newline="") as handle:
            rows = list(csv.reader(handle))
        spec = detect_pattern(path.name, rows)
        if spec is None:
            continue
        body = rows[spec.header_rows :]
        for offset, row in enumerate(body, start=spec.header_rows + 1):
            if not any(normalize_whitespace(cell) for cell in row):
                continue
            mapped = dict(zip(spec.columns, pad_row(row, len(spec.columns))))
            record = normalize_record(mapped, path.name, offset, spec.name)
            if not has_meaningful_payload(record):
                continue
            records.append(record)
    return records


def deduplicate_records(records: list[dict[str, str]]) -> tuple[list[dict[str, str]], list[dict[str, str]]]:
    grouped: defaultdict[str, list[dict[str, str]]] = defaultdict(list)
    for record in records:
        grouped[record["dedupe_key"]].append(record)

    kept_records: list[dict[str, str]] = []
    duplicate_rows: list[dict[str, str]] = []

    for dedupe_key, group in grouped.items():
        ordered = sorted(group, key=record_rank, reverse=True)
        duplicate_files = sorted({record["source_file"] for record in ordered})
        for rank, record in enumerate(ordered, start=1):
            record["duplicate_count"] = str(len(group))
            record["duplicate_rank"] = str(rank)
            record["duplicate_files"] = "; ".join(duplicate_files)
        kept_records.append(ordered[0])
        duplicate_rows.extend(ordered)

    kept_records.sort(key=lambda record: (record["fecha_ingreso_date"], record["rut"], record["record_uid"]))
    duplicate_rows.sort(
        key=lambda record: (
            -int(record["duplicate_count"]),
            record["dedupe_key"],
            int(record["duplicate_rank"]),
        )
    )
    return kept_records, duplicate_rows


def build_patients(records: list[dict[str, str]]) -> list[dict[str, str]]:
    grouped: defaultdict[str, list[dict[str, str]]] = defaultdict(list)
    for record in records:
        grouped[record["patient_key"]].append(record)

    patients: list[dict[str, str]] = []
    for patient_key, group in grouped.items():
        best = max(group, key=lambda record: (int(record["non_empty_fields"]), record["record_uid"]))
        patient = {column: "" for column in PATIENT_COLUMNS}
        patient["patient_key"] = patient_key
        patient["patient_key_strategy"] = best.get("patient_key_strategy", "")
        for key in (
            "rut",
            "rut_valido",
            "rut_raw",
            "nombres",
            "apellido_paterno",
            "apellido_materno",
            "apellidos",
            "nombre_completo",
            "sexo",
            "fecha_nacimiento_date",
            "fecha_nacimiento_raw",
            "edad_reportada",
            "nacionalidad",
            "nro_contacto",
            "domicilio",
            "comuna",
            "cesfam",
        ):
            patient[key] = best.get(key, "")
        patient["episode_count"] = str(len(group))
        patient["source_files"] = "; ".join(sorted({record["source_file"] for record in group}))
        patients.append(patient)

    patients.sort(key=lambda patient: (patient["rut"], patient["nombre_completo"], patient["patient_key"]))
    return patients


def file_summary(
    raw_records: list[dict[str, str]], kept_records: list[dict[str, str]]
) -> list[dict[str, str]]:
    raw_by_file: defaultdict[str, list[dict[str, str]]] = defaultdict(list)
    kept_by_file: defaultdict[str, list[dict[str, str]]] = defaultdict(list)
    for record in raw_records:
        raw_by_file[record["source_file"]].append(record)
    for record in kept_records:
        kept_by_file[record["source_file"]].append(record)

    summaries: list[dict[str, str]] = []
    for source_file in sorted(raw_by_file):
        group = raw_by_file[source_file]
        kept = kept_by_file.get(source_file, [])
        summary = {column: "" for column in FILE_SUMMARY_COLUMNS}
        summary["source_file"] = source_file
        summary["source_family"] = group[0]["source_family"]
        summary["source_pattern"] = group[0]["source_pattern"]
        summary["raw_records"] = str(len(group))
        summary["deduped_records_kept"] = str(len(kept))
        summary["duplicates_discarded"] = str(len(group) - len(kept))

        ingreso_dates = sorted({record["fecha_ingreso_date"] for record in group if record["fecha_ingreso_date"]})
        egreso_dates = sorted({record["fecha_egreso_date"] for record in group if record["fecha_egreso_date"]})
        summary["min_fecha_ingreso"] = ingreso_dates[0] if ingreso_dates else ""
        summary["max_fecha_ingreso"] = ingreso_dates[-1] if ingreso_dates else ""
        summary["min_fecha_egreso"] = egreso_dates[0] if egreso_dates else ""
        summary["max_fecha_egreso"] = egreso_dates[-1] if egreso_dates else ""
        summaries.append(summary)

    return summaries


def write_csv(path: Path, rows: list[dict[str, str]], columns: list[str]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=columns)
        writer.writeheader()
        for row in rows:
            writer.writerow({column: row.get(column, "") for column in columns})


def write_sql(path: Path) -> None:
    sql = """CREATE TABLE IF NOT EXISTS hodom_pacientes_staging (
    patient_key TEXT PRIMARY KEY,
    patient_key_strategy TEXT,
    rut TEXT,
    rut_valido BOOLEAN,
    rut_raw TEXT,
    nombres TEXT,
    apellido_paterno TEXT,
    apellido_materno TEXT,
    apellidos TEXT,
    nombre_completo TEXT,
    sexo TEXT,
    fecha_nacimiento_date DATE,
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

CREATE TABLE IF NOT EXISTS hodom_episodios_staging (
    record_uid TEXT PRIMARY KEY,
    dedupe_key TEXT NOT NULL,
    patient_key TEXT NOT NULL REFERENCES hodom_pacientes_staging(patient_key),
    patient_key_strategy TEXT,
    source_file TEXT NOT NULL,
    source_family TEXT NOT NULL,
    source_pattern TEXT NOT NULL,
    source_row_number INTEGER NOT NULL,
    source_row_id TEXT,
    duplicate_count INTEGER NOT NULL,
    duplicate_rank INTEGER NOT NULL,
    duplicate_files TEXT,
    estado TEXT,
    fecha_ingreso_raw TEXT,
    fecha_ingreso_date DATE,
    fecha_egreso_raw TEXT,
    fecha_egreso_date DATE,
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
    fecha_nacimiento_date DATE,
    rut_raw TEXT,
    rut TEXT,
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
"""
    path.write_text(sql, encoding="utf-8")


def write_report(
    path: Path,
    raw_records: list[dict[str, str]],
    kept_records: list[dict[str, str]],
    patients: list[dict[str, str]],
    raw_duplicates: list[dict[str, str]],
) -> None:
    group_sizes = Counter()
    seen_keys = set()
    for record in raw_duplicates:
        if record["dedupe_key"] in seen_keys:
            continue
        seen_keys.add(record["dedupe_key"])
        group_sizes[record["duplicate_count"]] += 1
    report = {
        "generated_at": datetime.now().isoformat(timespec="seconds"),
        "raw_records": len(raw_records),
        "deduplicated_records": len(kept_records),
        "discarded_duplicate_rows": len(raw_records) - len(kept_records),
        "patients": len(patients),
        "source_files": len({record["source_file"] for record in raw_records}),
        "duplicate_group_sizes": dict(sorted(group_sizes.items(), key=lambda item: int(item[0]))),
        "valid_rut_records": sum(1 for record in kept_records if record["rut_valido"] == "1"),
        "invalid_rut_records": sum(1 for record in kept_records if record["rut_raw"] and record["rut_valido"] == "0"),
        "patient_key_strategies": dict(Counter(record["patient_key_strategy"] for record in kept_records)),
        "invalid_date_records": {
            "fecha_ingreso": sum(
                1 for record in kept_records if record["fecha_ingreso_raw"] and not record["fecha_ingreso_date"]
            ),
            "fecha_egreso": sum(
                1 for record in kept_records if record["fecha_egreso_raw"] and not record["fecha_egreso_date"]
            ),
            "fecha_nacimiento": sum(
                1 for record in kept_records if record["fecha_nacimiento_raw"] and not record["fecha_nacimiento_date"]
            ),
        },
    }
    path.write_text(json.dumps(report, indent=2, ensure_ascii=False), encoding="utf-8")


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Normaliza y deduplica los CSV históricos HODOM para carga a una base nueva."
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
        default=Path("output/spreadsheet"),
        help="Directorio donde se escribirán los artefactos.",
    )
    args = parser.parse_args()

    raw_records = read_records(args.source_dir)
    kept_records, duplicate_rows = deduplicate_records(raw_records)
    patients = build_patients(kept_records)
    summaries = file_summary(raw_records, kept_records)

    args.output_dir.mkdir(parents=True, exist_ok=True)
    write_csv(args.output_dir / "hodom_episodios_raw.csv", raw_records, OUTPUT_COLUMNS)
    write_csv(
        args.output_dir / "hodom_episodios_deduplicados.csv",
        kept_records,
        OUTPUT_COLUMNS,
    )
    write_csv(args.output_dir / "hodom_duplicados.csv", duplicate_rows, OUTPUT_COLUMNS)
    write_csv(args.output_dir / "hodom_pacientes.csv", patients, PATIENT_COLUMNS)
    write_csv(args.output_dir / "hodom_resumen_fuentes.csv", summaries, FILE_SUMMARY_COLUMNS)
    write_sql(args.output_dir / "hodom_schema_postgres.sql")
    write_report(
        args.output_dir / "hodom_reporte_migracion.json",
        raw_records,
        kept_records,
        patients,
        duplicate_rows,
    )

    print(f"Raw records: {len(raw_records)}")
    print(f"Deduplicated records: {len(kept_records)}")
    print(f"Discarded duplicate rows: {len(raw_records) - len(kept_records)}")
    print(f"Patients: {len(patients)}")
    print(f"Output dir: {args.output_dir.resolve()}")


if __name__ == "__main__":
    main()
