"""Etapa 4 del pipeline HODOM: genera capa canónica estabilizada."""

from __future__ import annotations

import csv
import hashlib
from datetime import datetime
from pathlib import Path


# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

ORIGIN_WEIGHTS: dict[str, int] = {
    "merged": 4,
    "raw": 3,
    "alta_rescued": 2,
    "form_rescued": 1,
}

HOSPITALIZATION_STAY_FIELDS: list[str] = [
    "stay_id",
    "patient_id",
    "fecha_ingreso",
    "fecha_egreso",
    "estado",
    "servicio_origen",
    "prevision",
    "diagnostico_principal",
    "motivo_egreso",
    "establecimiento",
    "codigo_deis",
    "comuna",
    "localidad",
    "latitud",
    "longitud",
    "source_episode_ids",
    "source_episode_count",
    "episode_origin",
    "confidence_level",
    "gestora",
    "usuario_o2",
    "nombre_completo",
    "rut",
    "sexo_resuelto",
    "edad_reportada",
    "rango_etario",
]

AGE_BINS = [(-1, 14, "<15"), (15, 19, "15-19"), (20, 59, "20-59"), (60, 150, ">=60")]


# ---------------------------------------------------------------------------
# Helper functions
# ---------------------------------------------------------------------------


def read_csv(path: Path) -> list[dict[str, str]]:
    """Lee un archivo CSV y devuelve una lista de dicts."""
    with open(path, encoding="utf-8", newline="") as f:
        reader = csv.DictReader(f)
        return list(reader)


def write_csv(
    path: Path,
    rows: list[dict[str, str]],
    fieldnames: list[str] | None = None,
) -> None:
    """Escribe una lista de dicts como CSV."""
    if not rows:
        path.write_text("")
        return
    if fieldnames is None:
        fieldnames = list(rows[0].keys())
    with open(path, "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames, extrasaction="ignore")
        writer.writeheader()
        writer.writerows(rows)


def make_id(prefix: str, value: str) -> str:
    """Genera un ID determinista con hash SHA-256 truncado a 12 hex chars."""
    digest = hashlib.sha256(value.encode("utf-8")).hexdigest()[:12]
    return f"{prefix}_{digest}"


def stay_row_score(row: dict[str, str]) -> tuple[int, int]:
    """Puntaje de un episodio para seleccion del 'mejor' representante.

    Returns:
        (origin_weight, non_empty_field_count)
    """
    origin = row.get("episode_origin", "")
    weight = ORIGIN_WEIGHTS.get(origin, 0)
    non_empty = sum(1 for v in row.values() if v)
    return (weight, non_empty)


def compute_confidence(
    episode_origin: str, has_egreso: bool, source_count: int
) -> str:
    """Calcula el nivel de confianza de una estadia.

    - high: consolidated (multiple sources) or merged + egreso
    - medium: raw/alta_rescued + egreso
    - low: form_rescued or no egreso
    """
    if source_count > 1:
        return "high"
    if episode_origin == "merged" and has_egreso:
        return "high"
    if episode_origin in ("raw", "alta_rescued") and has_egreso:
        return "medium"
    # form_rescued or any origin without egreso
    return "low"


def _compute_rango_etario(edad_str: str) -> str:
    """Clasifica edad en rango etario REM."""
    if not edad_str:
        return ""
    try:
        edad = int(float(edad_str))
    except (ValueError, TypeError):
        return ""
    for low, high, label in AGE_BINS:
        if low < edad <= high:
            return label
    return ""


def _parse_date(s: str) -> datetime | None:
    """Intenta parsear una fecha ISO (YYYY-MM-DD)."""
    if not s:
        return None
    try:
        return datetime.strptime(s, "%Y-%m-%d")
    except ValueError:
        return None


# ---------------------------------------------------------------------------
# Field mapping from episode to stay
# ---------------------------------------------------------------------------

_FIELD_MAP: dict[str, str] = {
    "diagnostico_principal_texto": "diagnostico_principal",
    "establecimiento_resuelto": "establecimiento",
    "codigo_deis_resuelto": "codigo_deis",
    "comuna_resuelta": "comuna",
    "localidad_resuelta": "localidad",
    "latitud_localidad": "latitud",
    "longitud_localidad": "longitud",
}

# Fields that are copied as-is (same name in episode and stay)
_DIRECT_FIELDS: list[str] = [
    "patient_id",
    "fecha_ingreso",
    "fecha_egreso",
    "estado",
    "servicio_origen",
    "prevision",
    "motivo_egreso",
    "gestora",
    "usuario_o2",
    "nombre_completo",
    "rut",
    "sexo_resuelto",
    "edad_reportada",
]


# ---------------------------------------------------------------------------
# Consolidation logic
# ---------------------------------------------------------------------------


def _group_key(ep: dict[str, str]) -> str | None:
    """Returns a grouping key for episodes that can be grouped by exact match.

    An episode is groupable only when it has patient_id, fecha_ingreso,
    AND fecha_egreso.  Returns None if any of those is missing/empty.
    """
    pid = ep.get("patient_id", "")
    fi = ep.get("fecha_ingreso", "")
    fe = ep.get("fecha_egreso", "")
    if pid and fi and fe:
        return f"{pid}|{fi}|{fe}"
    return None


def _build_stay(episodes: list[dict[str, str]]) -> dict[str, str]:
    """Construye un dict de estadia a partir de uno o mas episodios."""
    # Sort by score descending to pick best first
    episodes_sorted = sorted(episodes, key=stay_row_score, reverse=True)
    best = episodes_sorted[0]

    source_ids = sorted(ep["episode_id"] for ep in episodes)
    source_count = len(episodes)

    # Consolidate diagnostics
    diagnostics: list[str] = []
    for ep in episodes_sorted:
        diag = ep.get("diagnostico_principal_texto", "").strip()
        if diag and diag not in diagnostics:
            diagnostics.append(diag)
    consolidated_diag = " | ".join(diagnostics) if diagnostics else ""

    # Determine episode_origin
    if source_count > 1:
        ep_origin = "consolidated"
    else:
        ep_origin = best.get("episode_origin", "")

    has_egreso = bool(best.get("fecha_egreso", ""))
    confidence = compute_confidence(ep_origin, has_egreso, source_count)

    # Build stay_id from sorted source episode ids
    stay_id = make_id("stay", "|".join(source_ids))

    stay: dict[str, str] = {
        "stay_id": stay_id,
        "diagnostico_principal": consolidated_diag,
        "source_episode_ids": ",".join(source_ids),
        "source_episode_count": str(source_count),
        "episode_origin": ep_origin,
        "confidence_level": confidence,
    }

    # Copy direct fields from best episode
    for field in _DIRECT_FIELDS:
        stay[field] = best.get(field, "")

    # Copy renamed fields from best episode
    for src_field, dst_field in _FIELD_MAP.items():
        if dst_field not in stay:  # diagnostico_principal already set above
            stay[dst_field] = best.get(src_field, "")

    # Compute rango_etario
    stay["rango_etario"] = _compute_rango_etario(stay.get("edad_reportada", ""))

    return stay


def consolidate_stays(episodes: list[dict[str, str]]) -> list[dict[str, str]]:
    """Consolida episodios en estadias de hospitalizacion.

    Algoritmo:
    1. Agrupar por patient_id + fecha_ingreso + fecha_egreso (match exacto)
    2. Dedup por RUT + fecha_ingreso ±2 dias entre episodios no agrupados
    3. Dedup por nombre_completo (uppercase) + fecha_ingreso ±2 dias (fallback)
    4. Construir stays a partir de cada grupo

    Args:
        episodes: Lista de dicts con los campos del episode_master.

    Returns:
        Lista de dicts con los campos de HOSPITALIZATION_STAY_FIELDS.
    """
    if not episodes:
        return []

    # --- Phase 1: exact match grouping ---
    groups: dict[str, list[dict[str, str]]] = {}
    ungrouped: list[dict[str, str]] = []

    for ep in episodes:
        key = _group_key(ep)
        if key is not None:
            groups.setdefault(key, []).append(ep)
        else:
            ungrouped.append(ep)

    # Separate exact-match groups that had only 1 member -> still grouped
    # but also candidates for phase-2 merging? No — only ungrouped go
    # through phase 2/3.  Episodes already in a group stay there.

    # --- Phase 2: dedup by RUT + fecha_ingreso ±2 days ---
    still_ungrouped: list[dict[str, str]] = []
    rut_merged: dict[int, list[dict[str, str]]] = {}  # keyed by index into list

    for ep in ungrouped:
        rut = ep.get("rut", "").strip()
        fi_str = ep.get("fecha_ingreso", "").strip()
        fi = _parse_date(fi_str)
        merged = False

        if rut and fi:
            for idx, members in rut_merged.items():
                ref = members[0]
                ref_rut = ref.get("rut", "").strip()
                ref_fi = _parse_date(ref.get("fecha_ingreso", ""))
                if ref_rut == rut and ref_fi and abs((fi - ref_fi).days) <= 2:
                    members.append(ep)
                    merged = True
                    break

        if not merged:
            if rut and fi:
                rut_merged[id(ep)] = [ep]
            else:
                still_ungrouped.append(ep)

    # Add rut_merged groups to main groups
    for members in rut_merged.values():
        if len(members) > 1:
            # Create a composite key
            key = f"rut_dedup:{members[0].get('rut', '')}|{members[0].get('fecha_ingreso', '')}"
            groups[key] = members
        else:
            still_ungrouped.append(members[0])

    # --- Phase 3: dedup by nombre_completo (uppercase) + fecha_ingreso ±2 days ---
    final_ungrouped: list[dict[str, str]] = []
    name_merged: dict[int, list[dict[str, str]]] = {}

    for ep in still_ungrouped:
        nombre = ep.get("nombre_completo", "").strip().upper()
        fi_str = ep.get("fecha_ingreso", "").strip()
        fi = _parse_date(fi_str)
        merged = False

        if nombre and fi:
            for idx, members in name_merged.items():
                ref = members[0]
                ref_nombre = ref.get("nombre_completo", "").strip().upper()
                ref_fi = _parse_date(ref.get("fecha_ingreso", ""))
                if ref_nombre == nombre and ref_fi and abs((fi - ref_fi).days) <= 2:
                    members.append(ep)
                    merged = True
                    break

        if not merged:
            if nombre and fi:
                name_merged[id(ep)] = [ep]
            else:
                final_ungrouped.append(ep)

    # Add name_merged groups to main groups
    for members in name_merged.values():
        if len(members) > 1:
            key = f"name_dedup:{members[0].get('nombre_completo', '').upper()}|{members[0].get('fecha_ingreso', '')}"
            groups[key] = members
        else:
            final_ungrouped.append(members[0])

    # --- Phase 4: standalone episodes ---
    for ep in final_ungrouped:
        key = f"episode:{ep.get('episode_id', '')}"
        groups[key] = [ep]

    # --- Build stays ---
    stays: list[dict[str, str]] = []
    for members in groups.values():
        stay = _build_stay(members)
        stays.append(stay)

    return stays
