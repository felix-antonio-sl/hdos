#!/usr/bin/env python3
"""Build an idempotent SQL refresh from HODOM original sources.

The repository keeps a schema dump, while the local PostgreSQL instance holds the
working database. This generator creates a narrow migration that adds traceable
source metadata plus non-PII reference/reporting data derived from primary
operational and official sources.
"""

from __future__ import annotations

import csv
import hashlib
import json
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "db" / "updates" / "2026-05-25-original-source-refresh.sql"
PHASE = "original_source_refresh_2026_05_25"

CARTERA_SOURCE = Path("/home/felix/projects/hd-dt/02-cartera-y-prestaciones/cartera-servicios-hsc-2024.txt")
CARTERA_XLSX = Path("/home/felix/projects/hd-dt/01-normativo/hsc/res-exenta-1206-2024-cartera-hsc.xlsx")
REM_SOURCE = Path("/home/felix/projects/hd-dt/05-gobernanza-datos/rem-a21-c1-abril-2026.json")
REM_MARKDOWN = Path("/home/felix/projects/hd-dt/05-gobernanza-datos/rem-a21-c1-abril-2026.md")
RPE_34 = Path("/home/felix/projects/hd-dt/01-normativo/fuentes-minsal/RPE-N°34-Criterios-Tecnicos-para-Hospitalizacion-domiciliaria.pdf")
LOCAL_MANUAL_REM = ROOT / "docs" / "specs" / "manual-rem-2026.md"
LOCAL_RESUMEN_NORMATIVO = ROOT / "docs" / "specs" / "legal" / "resumen-normativo-hodom.md"
LOCAL_DS1_XML = ROOT / "docs" / "specs" / "legal" / "decreto-1-reglamento-hospitalizacion-domiciliaria.xml"

FIELD_MAP = {
    "USUARIO": "usuario",
    "MACROPROCESO": "macroproceso",
    "PROCESO (UNIDAD O SERVICIO)": "unidad_servicio",
    "SUBPROCESO (TIPO DE PRESTACIÓN)": "subproceso",
    "ESTAMENTO O ESPECIALIDAD": "estamento_especialidad",
    "PRESTACIÓN": "prestacion",
    "CÓDIGO MAI": "codigo_mai",
    "PRESTACIÓN EPH": "prestacion_eph",
    "PRESTACIÓN ACTUAL": "prestacion_actual_text",
    "PRESTACIÓN NUEVA": "prestacion_nueva_text",
    "ÁREA DE INFLUENCIA": "area_influencia",
    "COMPRA DE SERVICIO": "compra_servicio_text",
    "OBSERVACIONES": "observaciones",
}


def normalize(value: Any) -> str | None:
    if value is None:
        return None
    text = str(value).replace("\xa0", " ").strip()
    text = " ".join(text.split())
    return text or None


def normalize_header(value: str) -> str:
    return normalize(value) or ""


def parse_bool(value: str | None, true_values: set[str]) -> bool:
    if value is None:
        return False
    return value.strip().lower() in true_values


def sha256_file(path: Path) -> str | None:
    if not path.exists():
        return None
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def row_hash(payload: dict[str, Any]) -> str:
    encoded = json.dumps(payload, ensure_ascii=False, sort_keys=True, separators=(",", ":")).encode()
    return hashlib.sha256(encoded).hexdigest()


def load_cartera_rows(path: Path = CARTERA_SOURCE) -> list[dict[str, Any]]:
    with path.open("r", encoding="utf-8-sig", newline="") as handle:
        reader = csv.reader(handle, delimiter="\t")
        header: list[str] | None = None
        rows: list[dict[str, Any]] = []

        for row_number, raw_row in enumerate(reader, start=1):
            values = [normalize(cell) for cell in raw_row]
            if not any(values):
                continue

            normalized_header = [normalize_header(cell or "") for cell in raw_row]
            if normalized_header and normalized_header[0] == "USUARIO":
                header = normalized_header
                continue
            if header is None:
                raise ValueError(f"Missing header before row {row_number}")

            keyed = {
                FIELD_MAP[column]: normalize(raw_row[index]) if index < len(raw_row) else None
                for index, column in enumerate(header)
                if column in FIELD_MAP
            }
            if keyed.get("prestacion") == "PRESTACIÓN":
                continue
            if not keyed.get("prestacion"):
                continue

            raw_record = {
                key: keyed.get(key)
                for key in (
                    "usuario",
                    "macroproceso",
                    "unidad_servicio",
                    "subproceso",
                    "estamento_especialidad",
                    "prestacion",
                    "codigo_mai",
                    "prestacion_eph",
                    "prestacion_actual_text",
                    "prestacion_nueva_text",
                    "area_influencia",
                    "compra_servicio_text",
                    "observaciones",
                )
            }
            item = {
                **raw_record,
                "source_id": "cartera_hsc_2024",
                "row_number": row_number,
                "prestacion_actual": parse_bool(keyed.get("prestacion_actual_text"), {"actual"}),
                "prestacion_nueva": parse_bool(keyed.get("prestacion_nueva_text"), {"nueva"}),
                "compra_servicio": parse_bool(keyed.get("compra_servicio_text"), {"si", "sí", "s"}),
                "raw_record": raw_record,
            }
            item["row_hash"] = row_hash(item["raw_record"])
            rows.append(item)

    return rows


def load_rem_snapshot(path: Path = REM_SOURCE) -> dict[str, Any]:
    payload = json.loads(path.read_text(encoding="utf-8"))
    periodo = payload["periodo"]["mes"]
    payload_json = json.dumps(payload, ensure_ascii=False, sort_keys=True)
    return {
        "snapshot_id": f"rem_a21_c1_hodom_hsc_{periodo.replace('-', '_')}",
        "source_id": f"rem_a21_c1_hodom_hsc_{periodo.replace('-', '_')}",
        "periodo": periodo,
        "establecimiento_nombre": "Hospital de San Carlos Dr. Benicio Arzola Medina - HODOM",
        "payload": payload,
        "payload_json": payload_json,
        "criterios_json": json.dumps(payload.get("criterios", {}), ensure_ascii=False, sort_keys=True),
        "calidad_datos_json": json.dumps(payload.get("calidad_datos", {}), ensure_ascii=False, sort_keys=True),
    }


def sql_literal(value: Any) -> str:
    if value is None:
        return "NULL"
    if isinstance(value, bool):
        return "TRUE" if value else "FALSE"
    if isinstance(value, (int, float)):
        return str(value)
    text = str(value)
    return "'" + text.replace("'", "''") + "'"


def sql_jsonb(value: str) -> str:
    return f"{sql_literal(value)}::jsonb"


def chunked(items: list[Any], size: int) -> list[list[Any]]:
    return [items[index : index + size] for index in range(0, len(items), size)]


def file_size(path: Path) -> int:
    return path.stat().st_size if path.exists() else 0


def nonempty_path(path: Path) -> str | None:
    return str(path) if file_size(path) > 0 else None


def source_rows(rem: dict[str, Any]) -> list[dict[str, Any]]:
    return [
        {
            "source_id": "ds1_2022_leychile",
            "title": "Decreto 1/2022 MINSAL: Reglamento de establecimientos que otorgan prestaciones de hospitalización domiciliaria",
            "authority": "Biblioteca del Congreso Nacional / Ministerio de Salud",
            "source_type": "official_regulation",
            "version_label": "Versión única publicada el 26-SEP-2022",
            "published_at": "2022-09-26",
            "effective_at": "2022-09-26",
            "source_url": "https://www.leychile.cl/navegar?idNorma=1181901",
            "local_path": nonempty_path(LOCAL_DS1_XML),
            "checksum_sha256": sha256_file(LOCAL_DS1_XML) if file_size(LOCAL_DS1_XML) > 0 else None,
            "mime_type": "text/html",
            "notes": "Fuente normativa primaria por URL oficial LeyChile; el XML local del repo está vacío y no se usa como fuente material.",
        },
        {
            "source_id": "nt_hodom_2024_minsal",
            "title": "Norma Técnica para establecimientos que otorgan prestaciones de hospitalización domiciliaria",
            "authority": "Ministerio de Salud - Subsecretaría de Redes Asistenciales",
            "source_type": "official_technical_standard",
            "version_label": "Decreto Exento N°31, 05-jun-2024",
            "published_at": "2024-06-05",
            "effective_at": "2024-06-05",
            "source_url": "https://www.minsal.cl/wp-content/uploads/2024/01/NORMA-TECNICA-DECRETO-EXENTO-N%C2%B0-31-SRA-2024.pdf",
            "local_path": None,
            "checksum_sha256": None,
            "mime_type": "application/pdf",
            "notes": "Fuente técnica primaria verificada en la página oficial de documentos SRA MINSAL.",
        },
        {
            "source_id": "manual_rem_2026_deis",
            "title": "Manual REM 2026 Series A, BS, BM y D",
            "authority": "DEIS / Ministerio de Salud",
            "source_type": "official_reporting_manual",
            "version_label": "Versión 1.1",
            "published_at": None,
            "effective_at": "2026-01-01",
            "source_url": "https://repositoriodeis.minsal.cl/ContenidoSitioWeb2020/REM/2026/SERIE/ManualSeriesREM2026%20SERIEA_BS_BM_DV1.1.pdf",
            "local_path": str(LOCAL_MANUAL_REM),
            "checksum_sha256": sha256_file(LOCAL_MANUAL_REM),
            "mime_type": "application/pdf",
            "notes": "Fuente oficial REM 2026. El markdown local es una referencia extractada del manual.",
        },
        {
            "source_id": "rpe_34_hodom_minsal",
            "title": "RPE N°34: Criterios Técnicos para Hospitalización domiciliaria",
            "authority": "Ministerio de Salud",
            "source_type": "official_programming_guidance",
            "version_label": "RPE N°34",
            "published_at": None,
            "effective_at": None,
            "source_url": None,
            "local_path": str(RPE_34),
            "checksum_sha256": sha256_file(RPE_34),
            "mime_type": "application/pdf",
            "notes": "Fuente primaria local para criterios técnicos de programación/capacidad HODOM.",
        },
        {
            "source_id": "cartera_hsc_2024",
            "title": "Cartera de servicios HSC 2024",
            "authority": "Hospital de San Carlos Dr. Benicio Arzola Medina",
            "source_type": "local_primary_source",
            "version_label": "Resolución Exenta 1206/2024 y extracción tabular TXT",
            "published_at": "2024-01-01",
            "effective_at": "2024-01-01",
            "source_url": None,
            "local_path": str(CARTERA_SOURCE),
            "checksum_sha256": sha256_file(CARTERA_SOURCE),
            "mime_type": "text/tab-separated-values",
            "notes": f"Archivo tabular original; XLSX preservado en {CARTERA_XLSX}.",
        },
        {
            "source_id": rem["source_id"],
            "title": "REM A21 C.1 HODOM HSC - abril 2026",
            "authority": "Hospital de San Carlos Dr. Benicio Arzola Medina - HODOM",
            "source_type": "local_operational_snapshot",
            "version_label": "Abril 2026",
            "published_at": "2026-04-30",
            "effective_at": "2026-04-01",
            "source_url": "https://docs.google.com/spreadsheets/d/1CST3FAfdKatStzC7LW5P6HCqRB6s6aSpZu-Y5QGwlvQ",
            "local_path": str(REM_SOURCE),
            "checksum_sha256": sha256_file(REM_SOURCE),
            "mime_type": "application/json",
            "notes": "Snapshot derivado de la planilla operacional INGRESOS 2026 (version 1).xlsb con criterios y calidad de datos conservados.",
        },
        {
            "source_id": "resumen_normativo_hodom_local",
            "title": "Resumen normativo HODOM local",
            "authority": "Repositorio HODOM",
            "source_type": "derived_reference",
            "version_label": "2026-04-19",
            "published_at": "2026-04-19",
            "effective_at": None,
            "source_url": None,
            "local_path": str(LOCAL_RESUMEN_NORMATIVO),
            "checksum_sha256": sha256_file(LOCAL_RESUMEN_NORMATIVO),
            "mime_type": "text/markdown",
            "notes": "Referencia derivada, no sustituye las fuentes normativas primarias.",
        },
    ]


def kb_documents() -> list[dict[str, Any]]:
    docs = [
        ("doc_src_cartera_hsc_2024_txt", "Cartera de servicios HSC 2024 TXT", CARTERA_SOURCE, "normativa", "cartera_hsc_2024"),
        ("doc_src_cartera_hsc_2024_xlsx", "Resolución Exenta 1206/2024 Cartera HSC XLSX", CARTERA_XLSX, "normativa", "cartera_hsc_2024"),
        ("doc_src_rem_a21_c1_2026_04_json", "REM A21 C.1 HODOM HSC abril 2026 JSON", REM_SOURCE, "administrativo", "rem_a21_c1_hodom_hsc_2026_04"),
        ("doc_src_rem_a21_c1_2026_04_md", "REM A21 C.1 HODOM HSC abril 2026 informe", REM_MARKDOWN, "administrativo", "rem_a21_c1_hodom_hsc_2026_04"),
        ("doc_src_rpe_34_hodom_pdf", "RPE N°34 Criterios Técnicos HODOM", RPE_34, "normativa", "rpe_34_hodom_minsal"),
        ("doc_src_manual_rem_2026_md", "Manual REM 2026 extracto local", LOCAL_MANUAL_REM, "normativa", "manual_rem_2026_deis"),
        ("doc_src_resumen_normativo_hodom_md", "Resumen normativo HODOM", LOCAL_RESUMEN_NORMATIVO, "normativa", "resumen_normativo_hodom_local"),
    ]
    result = []
    for doc_id, name, path, category, source_id in docs:
        result.append(
            {
                "documento_id": doc_id,
                "nombre": name,
                "nombre_archivo": path.name,
                "ruta_archivo": str(path),
                "mime_type": guess_mime(path),
                "tamano_bytes": file_size(path),
                "categoria": category,
                "descripcion": f"Fuente original registrada por {PHASE}; source_id={source_id}; sha256={sha256_file(path)}",
                "subido_por_id": "system_original_source_refresh",
                "subido_por_nombre": "Original Source Refresh 2026-05-25",
            }
        )
    return result


def guess_mime(path: Path) -> str:
    suffix = path.suffix.lower()
    return {
        ".pdf": "application/pdf",
        ".xlsx": "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
        ".json": "application/json",
        ".md": "text/markdown",
        ".txt": "text/plain",
    }.get(suffix, "application/octet-stream")


def values_statement(table: str, columns: list[str], rows: list[dict[str, Any]], conflict: str, update_columns: list[str] | None = None) -> str:
    if not rows:
        return ""
    values = []
    for row in rows:
        values.append("(" + ", ".join(row[column] for column in columns) + ")")
    update = ""
    if update_columns:
        assignments = ", ".join(f"{column} = EXCLUDED.{column}" for column in update_columns)
        update = f" DO UPDATE SET {assignments}"
    else:
        update = " DO NOTHING"
    return f"INSERT INTO {table} ({', '.join(columns)}) VALUES\n" + ",\n".join(values) + f"\nON CONFLICT {conflict}{update};"


def build_sql(cartera_rows: list[dict[str, Any]], rem_snapshot: dict[str, Any]) -> str:
    generated_at = datetime.now(timezone.utc).isoformat(timespec="seconds")
    lines: list[str] = [
        "-- HODOM original-source refresh",
        f"-- Generated at: {generated_at}",
        "-- Sources: LeyChile DS1/2022, MINSAL NT HODOM 2024, DEIS REM 2026, HSC cartera 2024, HSC REM A21 C.1 abril 2026.",
        "",
        "BEGIN;",
        "",
        "CREATE TABLE IF NOT EXISTS reference.original_source (",
        "    source_id text PRIMARY KEY,",
        "    title text NOT NULL,",
        "    authority text,",
        "    source_type text NOT NULL,",
        "    version_label text,",
        "    published_at date,",
        "    effective_at date,",
        "    source_url text,",
        "    local_path text,",
        "    checksum_sha256 text,",
        "    mime_type text,",
        "    notes text,",
        "    retrieved_at timestamp with time zone DEFAULT now() NOT NULL,",
        "    created_at timestamp with time zone DEFAULT now() NOT NULL",
        ");",
        "",
        "CREATE TABLE IF NOT EXISTS reference.cartera_prestacion_hsc (",
        "    source_id text NOT NULL REFERENCES reference.original_source(source_id),",
        "    row_number integer NOT NULL,",
        "    row_hash text NOT NULL,",
        "    usuario text,",
        "    macroproceso text,",
        "    unidad_servicio text,",
        "    subproceso text,",
        "    estamento_especialidad text,",
        "    prestacion text NOT NULL,",
        "    codigo_mai text,",
        "    prestacion_eph text,",
        "    prestacion_actual boolean DEFAULT false NOT NULL,",
        "    prestacion_nueva boolean DEFAULT false NOT NULL,",
        "    area_influencia text,",
        "    compra_servicio boolean DEFAULT false NOT NULL,",
        "    observaciones text,",
        "    raw_record jsonb NOT NULL,",
        "    created_at timestamp with time zone DEFAULT now() NOT NULL,",
        "    updated_at timestamp with time zone DEFAULT now() NOT NULL,",
        "    PRIMARY KEY (source_id, row_number)",
        ");",
        "",
        "CREATE INDEX IF NOT EXISTS idx_cartera_prestacion_hsc_codigo_mai ON reference.cartera_prestacion_hsc (codigo_mai);",
        "CREATE INDEX IF NOT EXISTS idx_cartera_prestacion_hsc_prestacion_trgm ON reference.cartera_prestacion_hsc USING gin (to_tsvector('spanish'::regconfig, prestacion));",
        "",
        "CREATE TABLE IF NOT EXISTS reporting.rem_a21_c1_snapshot (",
        "    snapshot_id text PRIMARY KEY,",
        "    source_id text NOT NULL REFERENCES reference.original_source(source_id),",
        "    periodo text NOT NULL,",
        "    establecimiento_nombre text NOT NULL,",
        "    payload jsonb NOT NULL,",
        "    criterios jsonb NOT NULL DEFAULT '{}'::jsonb,",
        "    calidad_datos jsonb NOT NULL DEFAULT '{}'::jsonb,",
        "    created_at timestamp with time zone DEFAULT now() NOT NULL,",
        "    updated_at timestamp with time zone DEFAULT now() NOT NULL,",
        "    UNIQUE (periodo, source_id)",
        ");",
        "",
        "COMMENT ON TABLE reference.original_source IS 'Fuentes originales y derivadas usadas para cargar datos de referencia HODOM con trazabilidad.';",
        "COMMENT ON TABLE reference.cartera_prestacion_hsc IS 'Copia normalizada no-PII de la cartera completa de servicios HSC 2024 desde fuente tabular original.';",
        "COMMENT ON TABLE reporting.rem_a21_c1_snapshot IS 'Snapshot JSON de REM A21 C.1 HODOM con criterios, calidad de datos y fuente original preservados.';",
        "",
    ]

    source_sql_rows = []
    for row in source_rows(rem_snapshot):
        source_sql_rows.append(
            {
                "source_id": sql_literal(row["source_id"]),
                "title": sql_literal(row["title"]),
                "authority": sql_literal(row["authority"]),
                "source_type": sql_literal(row["source_type"]),
                "version_label": sql_literal(row["version_label"]),
                "published_at": sql_literal(row["published_at"]),
                "effective_at": sql_literal(row["effective_at"]),
                "source_url": sql_literal(row["source_url"]),
                "local_path": sql_literal(row["local_path"]),
                "checksum_sha256": sql_literal(row["checksum_sha256"]),
                "mime_type": sql_literal(row["mime_type"]),
                "notes": sql_literal(row["notes"]),
            }
        )
    lines.append(
        values_statement(
            "reference.original_source",
            ["source_id", "title", "authority", "source_type", "version_label", "published_at", "effective_at", "source_url", "local_path", "checksum_sha256", "mime_type", "notes"],
            source_sql_rows,
            "(source_id)",
            ["title", "authority", "source_type", "version_label", "published_at", "effective_at", "source_url", "local_path", "checksum_sha256", "mime_type", "notes", "retrieved_at"],
        ).replace("retrieved_at = EXCLUDED.retrieved_at", "retrieved_at = now()")
    )

    lines.extend(
        [
            "",
            "INSERT INTO operational.kb_tag (tag_id, nombre, color) VALUES",
            "('tag_hodom', 'hodom', '#2563eb'),",
            "('tag_rem_a21', 'REM A21', '#059669'),",
            "('tag_fuente_original', 'fuente original', '#7c3aed'),",
            "('tag_cartera_hsc', 'cartera HSC', '#ea580c')",
            "ON CONFLICT (tag_id) DO UPDATE SET nombre = EXCLUDED.nombre, color = EXCLUDED.color;",
            "",
        ]
    )

    doc_sql_rows = []
    for row in kb_documents():
        doc_sql_rows.append({column: sql_literal(row[column]) for column in row})
    lines.append(
        values_statement(
            "operational.kb_documento",
            ["documento_id", "nombre", "nombre_archivo", "ruta_archivo", "mime_type", "tamano_bytes", "categoria", "descripcion", "subido_por_id", "subido_por_nombre"],
            doc_sql_rows,
            "(documento_id)",
            ["nombre", "nombre_archivo", "ruta_archivo", "mime_type", "tamano_bytes", "categoria", "descripcion", "subido_por_id", "subido_por_nombre", "updated_at", "deleted_at"],
        )
        .replace("updated_at = EXCLUDED.updated_at", "updated_at = now()")
        .replace("deleted_at = EXCLUDED.deleted_at", "deleted_at = NULL")
    )

    doc_tags = []
    tag_map = {
        "doc_src_cartera_hsc_2024_txt": ["tag_hodom", "tag_fuente_original", "tag_cartera_hsc"],
        "doc_src_cartera_hsc_2024_xlsx": ["tag_hodom", "tag_fuente_original", "tag_cartera_hsc"],
        "doc_src_rem_a21_c1_2026_04_json": ["tag_hodom", "tag_fuente_original", "tag_rem_a21"],
        "doc_src_rem_a21_c1_2026_04_md": ["tag_hodom", "tag_rem_a21"],
        "doc_src_rpe_34_hodom_pdf": ["tag_hodom", "tag_fuente_original"],
        "doc_src_manual_rem_2026_md": ["tag_hodom", "tag_rem_a21"],
        "doc_src_resumen_normativo_hodom_md": ["tag_hodom"],
    }
    for document_id, tag_ids in tag_map.items():
        for tag_id in tag_ids:
            doc_tags.append({"documento_id": sql_literal(document_id), "tag_id": sql_literal(tag_id)})
    lines.append(
        values_statement(
            "operational.kb_documento_tag",
            ["documento_id", "tag_id"],
            doc_tags,
            "(documento_id, tag_id)",
        )
    )

    lines.extend(
        [
            "",
            "DELETE FROM reference.cartera_prestacion_hsc WHERE source_id = 'cartera_hsc_2024';",
        ]
    )

    cartera_columns = [
        "source_id",
        "row_number",
        "row_hash",
        "usuario",
        "macroproceso",
        "unidad_servicio",
        "subproceso",
        "estamento_especialidad",
        "prestacion",
        "codigo_mai",
        "prestacion_eph",
        "prestacion_actual",
        "prestacion_nueva",
        "area_influencia",
        "compra_servicio",
        "observaciones",
        "raw_record",
    ]
    for group in chunked(cartera_rows, 400):
        sql_rows = []
        for row in group:
            sql_rows.append(
                {
                    "source_id": sql_literal(row["source_id"]),
                    "row_number": sql_literal(row["row_number"]),
                    "row_hash": sql_literal(row["row_hash"]),
                    "usuario": sql_literal(row["usuario"]),
                    "macroproceso": sql_literal(row["macroproceso"]),
                    "unidad_servicio": sql_literal(row["unidad_servicio"]),
                    "subproceso": sql_literal(row["subproceso"]),
                    "estamento_especialidad": sql_literal(row["estamento_especialidad"]),
                    "prestacion": sql_literal(row["prestacion"]),
                    "codigo_mai": sql_literal(row["codigo_mai"]),
                    "prestacion_eph": sql_literal(row["prestacion_eph"]),
                    "prestacion_actual": sql_literal(row["prestacion_actual"]),
                    "prestacion_nueva": sql_literal(row["prestacion_nueva"]),
                    "area_influencia": sql_literal(row["area_influencia"]),
                    "compra_servicio": sql_literal(row["compra_servicio"]),
                    "observaciones": sql_literal(row["observaciones"]),
                    "raw_record": sql_jsonb(json.dumps(row["raw_record"], ensure_ascii=False, sort_keys=True)),
                }
            )
        lines.append(values_statement("reference.cartera_prestacion_hsc", cartera_columns, sql_rows, "(source_id, row_number)"))

    lines.extend(
        [
            "",
            f"DELETE FROM reporting.rem_a21_c1_snapshot WHERE snapshot_id = {sql_literal(rem_snapshot['snapshot_id'])};",
            "INSERT INTO reporting.rem_a21_c1_snapshot (snapshot_id, source_id, periodo, establecimiento_nombre, payload, criterios, calidad_datos)",
            "VALUES (",
            f"    {sql_literal(rem_snapshot['snapshot_id'])},",
            f"    {sql_literal(rem_snapshot['source_id'])},",
            f"    {sql_literal(rem_snapshot['periodo'])},",
            f"    {sql_literal(rem_snapshot['establecimiento_nombre'])},",
            f"    {sql_jsonb(rem_snapshot['payload_json'])},",
            f"    {sql_jsonb(rem_snapshot['criterios_json'])},",
            f"    {sql_jsonb(rem_snapshot['calidad_datos_json'])}",
            ")",
            "ON CONFLICT (snapshot_id) DO UPDATE SET",
            "    source_id = EXCLUDED.source_id,",
            "    periodo = EXCLUDED.periodo,",
            "    establecimiento_nombre = EXCLUDED.establecimiento_nombre,",
            "    payload = EXCLUDED.payload,",
            "    criterios = EXCLUDED.criterios,",
            "    calidad_datos = EXCLUDED.calidad_datos,",
            "    updated_at = now();",
            "",
            f"DELETE FROM migration.provenance WHERE phase = {sql_literal(PHASE)};",
        ]
    )

    provenance_rows = []
    for source in source_rows(rem_snapshot):
        provenance_rows.append(
            {
                "target_table": sql_literal("reference.original_source"),
                "target_pk": sql_literal(source["source_id"]),
                "source_type": sql_literal(source["source_type"]),
                "source_file": sql_literal(source.get("source_url") or source.get("local_path")),
                "source_key": sql_literal(source["source_id"]),
                "phase": sql_literal(PHASE),
                "field_name": "NULL",
            }
        )
    for doc in kb_documents():
        provenance_rows.append(
            {
                "target_table": sql_literal("operational.kb_documento"),
                "target_pk": sql_literal(doc["documento_id"]),
                "source_type": sql_literal("local_document"),
                "source_file": sql_literal(doc["ruta_archivo"]),
                "source_key": sql_literal(doc["documento_id"]),
                "phase": sql_literal(PHASE),
                "field_name": "NULL",
            }
        )
    provenance_rows.append(
        {
            "target_table": sql_literal("reporting.rem_a21_c1_snapshot"),
            "target_pk": sql_literal(rem_snapshot["snapshot_id"]),
            "source_type": sql_literal("local_operational_snapshot"),
            "source_file": sql_literal(str(REM_SOURCE)),
            "source_key": sql_literal(rem_snapshot["snapshot_id"]),
            "phase": sql_literal(PHASE),
            "field_name": "NULL",
        }
    )
    for row in cartera_rows:
        provenance_rows.append(
            {
                "target_table": sql_literal("reference.cartera_prestacion_hsc"),
                "target_pk": sql_literal(f"{row['source_id']}:{row['row_number']}"),
                "source_type": sql_literal("local_primary_source"),
                "source_file": sql_literal(str(CARTERA_SOURCE)),
                "source_key": sql_literal(str(row["row_number"])),
                "phase": sql_literal(PHASE),
                "field_name": "NULL",
            }
        )
    for group in chunked(provenance_rows, 600):
        lines.append(
            values_statement(
                "migration.provenance",
                ["target_table", "target_pk", "source_type", "source_file", "source_key", "phase", "field_name"],
                group,
                "(target_table, target_pk, phase, (COALESCE(field_name, ''::text)))",
            )
        )

    lines.extend(["", "COMMIT;", ""])
    return "\n".join(lines)


def main() -> None:
    cartera = load_cartera_rows(CARTERA_SOURCE)
    rem = load_rem_snapshot(REM_SOURCE)
    sql = build_sql(cartera, rem)
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT.write_text(sql, encoding="utf-8")
    print(f"Wrote {OUTPUT} with {len(cartera)} cartera rows and REM snapshot {rem['snapshot_id']}.")


if __name__ == "__main__":
    main()
