"""Etapa 4 del pipeline HODOM: genera capa canónica estabilizada."""

from __future__ import annotations

import argparse
import csv
import difflib
import hashlib
import shutil
from datetime import date, datetime
from pathlib import Path

import migrate_hodom_csv as base


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
    "origen_derivacion_rem",
    "fallecido_clasificacion",
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
        if low <= edad <= high:
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


def infer_origin_derivation(service: str) -> str:
    """Normaliza servicio/origen a la categoría REM de derivación."""
    value = str(service or "").strip().upper()
    if not value:
        return ""
    if any(token in value for token in ["APS", "CESFAM", "CECOSF", "PSR", "CONSULTORIO"]):
        return "APS"
    if value in {"UE", "EU", "URG", "URG. HOSP", "URGENCIA", "USAT", "URA"}:
        return "Urgencia"
    if any(token in value for token in ["CAE", "CDT", "HOSPITAL DE DIA", "CMA", "CMI", "AMB"]):
        return "Ambulatorio"
    if "UGCC" in value:
        return "UGCC"
    if "LEY" in value and "URG" in value:
        return "Ley Urgencia"
    return "Hospitalización"


def finalize_stay(stay: dict[str, str]) -> dict[str, str]:
    """Normaliza campos derivados del stay después de cualquier corrección manual."""
    if stay.get("fecha_egreso"):
        stay["estado"] = "EGRESADO"
    elif not stay.get("estado"):
        stay["estado"] = "ACTIVO"
    stay["rango_etario"] = _compute_rango_etario(stay.get("edad_reportada", ""))
    if not stay.get("origen_derivacion_rem"):
        stay["origen_derivacion_rem"] = infer_origin_derivation(stay.get("servicio_origen", ""))
    return stay


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
        "origen_derivacion_rem": infer_origin_derivation(best.get("servicio_origen", "")),
        "fallecido_clasificacion": "",
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
    return finalize_stay(stay)


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

    # --- Phase 5: merge adjacent stays for same patient (gap <= 1 day) ---
    stays = _merge_adjacent_stays(stays)

    return stays


def _merge_adjacent_stays(stays: list[dict[str, str]]) -> list[dict[str, str]]:
    """Merge stays for the same patient/RUT where egreso-to-ingreso gap is <= 1 day.

    Groups by patient_id first, then also by RUT to catch cross-patient duplicates
    (same person with different patient_ids).
    """
    from datetime import date as _date

    # Build groups: by patient_id AND by RUT (cross-patient dedup)
    by_group: dict[str, list[dict[str, str]]] = {}
    assigned: set[str] = set()  # stay_ids already in a group

    # First pass: group by RUT (catches cross-patient duplicates)
    by_rut: dict[str, list[dict[str, str]]] = {}
    for s in stays:
        rut = s.get("rut", "").strip()
        if rut:
            by_rut.setdefault(rut, []).append(s)

    for rut, group in by_rut.items():
        if len(group) >= 1:
            key = f"rut:{rut}"
            by_group[key] = group
            for s in group:
                assigned.add(s.get("stay_id", ""))

    # Second pass: remaining stays grouped by patient_id
    for s in stays:
        sid = s.get("stay_id", "")
        if sid in assigned:
            continue
        pid = s.get("patient_id", "")
        key = f"pid:{pid}"
        by_group.setdefault(key, []).append(s)

    result: list[dict[str, str]] = []
    for group_key, group in by_group.items():
        if len(group) < 2:
            result.extend(group)
            continue

        # Sort by fecha_ingreso
        group.sort(key=lambda s: s.get("fecha_ingreso", ""))
        merged: list[dict[str, str]] = [group[0]]

        for current in group[1:]:
            prev = merged[-1]
            fe_prev = prev.get("fecha_egreso", "")
            fi_curr = current.get("fecha_ingreso", "")

            should_merge = False
            fi_prev = prev.get("fecha_ingreso", "")
            if fi_prev and fi_curr:
                try:
                    d_fi_prev = _date.fromisoformat(fi_prev)
                    d_fi_curr = _date.fromisoformat(fi_curr)
                    ingreso_diff = abs((d_fi_curr - d_fi_prev).days)
                    # Same ingreso (±2 days) → same hospitalization from different sources
                    if ingreso_diff <= 2:
                        should_merge = True
                except ValueError:
                    pass
            if not should_merge and fe_prev and fi_curr:
                try:
                    d_fe = _date.fromisoformat(fe_prev)
                    d_fi = _date.fromisoformat(fi_curr)
                    gap = (d_fi - d_fe).days
                    # Adjacent stays (egreso to ingreso gap ≤1 day)
                    if -3 <= gap <= 1:
                        should_merge = True
                except ValueError:
                    pass

            if should_merge:
                # Merge current into prev: extend date range, combine sources
                fe_curr = current.get("fecha_egreso", "")
                if fe_curr and (not fe_prev or fe_curr > fe_prev):
                    prev["fecha_egreso"] = fe_curr

                # Combine source episodes
                prev_sources = prev.get("source_episode_ids", "")
                curr_sources = current.get("source_episode_ids", "")
                all_sources = [s.strip() for s in f"{prev_sources},{curr_sources}".split(",") if s.strip()]
                prev["source_episode_ids"] = ",".join(sorted(set(all_sources)))
                prev["source_episode_count"] = str(len(set(all_sources)))

                # Combine diagnostics
                diag_prev = prev.get("diagnostico_principal", "")
                diag_curr = current.get("diagnostico_principal", "")
                all_diags = [d.strip() for d in f"{diag_prev} | {diag_curr}".split(" | ") if d.strip()]
                prev["diagnostico_principal"] = " | ".join(sorted(set(all_diags)))

                # Pick best origin/confidence
                prev["episode_origin"] = "consolidated"
                prev["confidence_level"] = "high"

                # Fill empty fields from current (including patient_id for cross-patient merges)
                for field in ("patient_id", "servicio_origen", "establecimiento", "codigo_deis",
                              "comuna", "localidad", "latitud", "longitud",
                              "gestora", "usuario_o2", "motivo_egreso",
                              "origen_derivacion_rem", "fallecido_clasificacion",
                              "nombre_completo", "rut", "sexo_resuelto", "edad_reportada"):
                    if not prev.get(field, "") and current.get(field, ""):
                        prev[field] = current[field]

                # Regenerate stay_id
                prev["stay_id"] = make_id("stay", prev["source_episode_ids"])
                finalize_stay(prev)
            else:
                merged.append(current)

        result.extend(merged)

    return result


# ---------------------------------------------------------------------------
# Patient master enrichment
# ---------------------------------------------------------------------------

PATIENT_MASTER_FIELDS = [
    "patient_id", "nombre_completo", "rut", "sexo", "fecha_nacimiento_date",
    "edad_reportada", "edad_calculada", "comuna", "cesfam", "prevision",
    "total_hospitalizaciones", "primera_fecha_ingreso", "ultima_fecha_egreso",
    "dias_totales_estadia", "estado_actual", "tiene_issues_abiertos",
]

PATIENT_IDENTITY_MASTER_FIELDS = [
    "identity_patient_id",
    "run",
    "fecha_nacimiento",
    "nombre",
    "nombre_normalizado",
    "nombre_variantes",
    "source_patient_ids",
    "source_patient_count",
    "source_files",
    "matching_strategy",
    "matching_confidence",
]

PATIENT_IDENTITY_MISSING_RUN_REVIEW_FIELDS = [
    "identity_patient_id",
    "nombre",
    "fecha_nacimiento",
    "source_patient_ids",
    "source_files",
    "candidate_count",
    "candidate_run_1",
    "candidate_name_1",
    "candidate_birth_1",
    "candidate_score_1",
    "candidate_run_2",
    "candidate_name_2",
    "candidate_birth_2",
    "candidate_score_2",
    "candidate_run_3",
    "candidate_name_3",
    "candidate_birth_3",
    "candidate_score_3",
    "recommendation",
]


def enrich_patient_master(
    patients: list[dict],
    stays: list[dict],
    quality_issues: list[dict],
) -> list[dict]:
    """Enriquece el maestro de pacientes con campos agregados de estadias.

    Args:
        patients: Lista de dicts del patient master.
        stays: Lista de dicts producida por consolidate_stays().
        quality_issues: Lista de dicts con issues de calidad.

    Returns:
        Lista de dicts enriquecidos con campos adicionales.
    """
    # --- Index stays by patient_id ---
    stays_by_patient: dict[str, list[dict]] = {}
    for stay in stays:
        pid = stay.get("patient_id", "")
        if pid:
            stays_by_patient.setdefault(pid, []).append(stay)

    # --- Build episode_id -> patient_id mapping from stays ---
    episode_to_patient: dict[str, str] = {}
    for stay in stays:
        pid = stay.get("patient_id", "")
        source_eps = stay.get("source_episode_ids", "")
        if pid and source_eps:
            for ep_id in source_eps.split(","):
                ep_id = ep_id.strip()
                if ep_id:
                    episode_to_patient[ep_id] = pid

    # --- Build set of patient_ids with open issues ---
    patients_with_open_issues: set[str] = set()
    for issue in quality_issues:
        # Check "status" first, then fall back to "resolution_status"
        status = issue.get("status") or issue.get("resolution_status", "")
        if status in ("OPEN", "REVIEW_REQUIRED"):
            ep_id = issue.get("episode_id", "")
            pid = episode_to_patient.get(ep_id, "")
            if pid:
                patients_with_open_issues.add(pid)

    # --- Enrich each patient ---
    today = date.today()
    enriched: list[dict] = []
    for patient in patients:
        pid = patient.get("patient_id", "")
        patient_stays = stays_by_patient.get(pid, [])

        # edad_calculada
        fnac_str = patient.get("fecha_nacimiento_date", "")
        edad_calculada = ""
        if fnac_str:
            fnac = _parse_date(fnac_str)
            if fnac:
                fnac_date = fnac.date()
                age = today.year - fnac_date.year
                if (today.month, today.day) < (fnac_date.month, fnac_date.day):
                    age -= 1
                edad_calculada = str(age)

        # prevision
        prevision = patient.get("prevision", "")

        # Aggregate from stays
        total_hospitalizaciones = len(patient_stays)

        primera_fecha_ingreso = ""
        ultima_fecha_egreso = ""
        dias_totales_estadia = 0
        has_open_stay = False

        ingreso_dates: list[datetime] = []
        egreso_dates: list[datetime] = []

        for stay in patient_stays:
            fi = _parse_date(stay.get("fecha_ingreso", ""))
            fe = _parse_date(stay.get("fecha_egreso", ""))

            if fi:
                ingreso_dates.append(fi)
            if fe:
                egreso_dates.append(fe)
            else:
                has_open_stay = True

            if fi and fe:
                dias_totales_estadia += (fe - fi).days

        if ingreso_dates:
            primera_fecha_ingreso = min(ingreso_dates).strftime("%Y-%m-%d")
        if egreso_dates:
            ultima_fecha_egreso = max(egreso_dates).strftime("%Y-%m-%d")

        # estado_actual
        if not patient_stays:
            estado_actual = "sin_info"
        elif has_open_stay:
            estado_actual = "activo"
        else:
            estado_actual = "egresado"

        # tiene_issues_abiertos
        tiene_issues = "True" if pid in patients_with_open_issues else "False"

        enriched_patient = {
            **patient,
            "edad_calculada": edad_calculada,
            "prevision": prevision,
            "total_hospitalizaciones": total_hospitalizaciones,
            "primera_fecha_ingreso": primera_fecha_ingreso,
            "ultima_fecha_egreso": ultima_fecha_egreso,
            "dias_totales_estadia": dias_totales_estadia,
            "estado_actual": estado_actual,
            "tiene_issues_abiertos": tiene_issues,
        }
        enriched.append(enriched_patient)

    return enriched


def _normalized_name_tokens(value: str) -> list[str]:
    return [token for token in base.canonical_text(value).split() if token]


def _sorted_name_signature(value: str) -> str:
    return " ".join(sorted(_normalized_name_tokens(value)))


def _name_match_score(name_a: str, name_b: str) -> float:
    canonical_a = name_a.strip()
    canonical_b = name_b.strip()
    if not canonical_a or not canonical_b:
        return 0.0

    seq_ratio = difflib.SequenceMatcher(None, canonical_a, canonical_b).ratio()
    sorted_ratio = difflib.SequenceMatcher(
        None,
        _sorted_name_signature(canonical_a),
        _sorted_name_signature(canonical_b),
    ).ratio()

    tokens_a = set(_normalized_name_tokens(canonical_a))
    tokens_b = set(_normalized_name_tokens(canonical_b))
    if tokens_a and tokens_b:
        intersection = len(tokens_a & tokens_b)
        jaccard = intersection / len(tokens_a | tokens_b)
        containment = intersection / min(len(tokens_a), len(tokens_b))
    else:
        jaccard = 0.0
        containment = 0.0

    return max(seq_ratio, sorted_ratio, (jaccard + containment) / 2)


def _patient_seed_score(patient: dict[str, str]) -> tuple[int, int, int, int]:
    return (
        1 if patient.get("rut", "").strip() else 0,
        1 if patient.get("fecha_nacimiento_date", "").strip() else 0,
        len(patient.get("nombre_completo", "").strip()),
        len(patient.get("source_files", "").split(";")),
    )


def _choose_cluster_name(members: list[dict[str, str]]) -> tuple[str, str, list[str]]:
    normalized_groups: dict[str, list[str]] = {}
    first_seen: dict[str, int] = {}
    for member in members:
        raw_name = (member.get("nombre_completo") or "").strip()
        normalized_name = raw_name and _sorted_name_signature(raw_name) or ""
        if not raw_name or not normalized_name:
            continue
        normalized_groups.setdefault(normalized_name, []).append(raw_name)
        first_seen.setdefault(raw_name, len(first_seen))

    if not normalized_groups:
        return "", "", []

    best_normalized, variants = max(
        normalized_groups.items(),
        key=lambda item: (len(item[1]), len(item[0]), max(len(v) for v in item[1])),
    )
    ordered_variants = sorted(
        set(variants),
        key=lambda value: (-variants.count(value), -len(value), first_seen.get(value, 0), value),
    )
    chosen = ordered_variants[0]
    return chosen, best_normalized, ordered_variants


def _choose_cluster_birth_date(members: list[dict[str, str]]) -> str:
    births: dict[str, int] = {}
    for member in members:
        birth = (member.get("fecha_nacimiento_date") or "").strip()
        if birth:
            births[birth] = births.get(birth, 0) + 1
    if not births:
        return ""
    return max(births.items(), key=lambda item: (item[1], item[0]))[0]


def build_patient_identity_master(patients: list[dict[str, str]]) -> list[dict[str, str]]:
    clusters: list[dict[str, object]] = []
    cluster_by_run: dict[str, dict[str, object]] = {}
    clusters_by_birth: dict[str, list[dict[str, object]]] = {}

    ordered_patients = sorted(
        patients,
        key=lambda patient: (
            0 if patient.get("rut", "").strip() else 1,
            patient.get("fecha_nacimiento_date", ""),
            patient.get("nombre_completo", ""),
        ),
    )

    for patient in ordered_patients:
        run = (patient.get("rut") or "").strip()
        birth = (patient.get("fecha_nacimiento_date") or "").strip()
        name = base.canonical_text(patient.get("nombre_completo", ""))

        cluster: dict[str, object] | None = None
        strategy = "singleton"
        confidence = "low"

        if run:
            cluster = cluster_by_run.get(run)
            if cluster is None:
                cluster = {
                    "cluster_key": f"run:{run}",
                    "run": run,
                    "members": [],
                    "strategies": [],
                    "scores": [],
                }
                clusters.append(cluster)
                cluster_by_run[run] = cluster
                if birth:
                    clusters_by_birth.setdefault(birth, []).append(cluster)
            strategy = "run_exact"
            confidence = "high"
        else:
            best_cluster: dict[str, object] | None = None
            best_score = 0.0
            if birth and name:
                for candidate in clusters_by_birth.get(birth, []):
                    candidate_members = candidate["members"]  # type: ignore[index]
                    candidate_name, candidate_normalized, _ = _choose_cluster_name(candidate_members)  # type: ignore[arg-type]
                    candidate_basis = candidate_normalized or base.canonical_text(candidate_name)
                    score = _name_match_score(name, candidate_basis)
                    if score > best_score:
                        best_score = score
                        best_cluster = candidate
                if best_cluster and best_score >= 0.80:
                    cluster = best_cluster
                    strategy = "birth_name_fuzzy_to_existing_run" if best_cluster.get("run") else "birth_name_fuzzy"
                    confidence = "high" if best_score >= 0.95 else "medium"

            if cluster is None:
                cluster = {
                    "cluster_key": f"fallback:{patient.get('patient_id', '')}",
                    "run": "",
                    "members": [],
                    "strategies": [],
                    "scores": [],
                }
                clusters.append(cluster)
                if birth:
                    clusters_by_birth.setdefault(birth, []).append(cluster)

        cluster["members"].append(patient)  # type: ignore[index]
        cluster["strategies"].append(strategy)  # type: ignore[index]
        cluster["scores"].append(confidence)  # type: ignore[index]

        if run and not cluster.get("run"):
            cluster["run"] = run

    identity_rows: list[dict[str, str]] = []
    for cluster in clusters:
        members = cluster["members"]  # type: ignore[index]
        chosen_name, normalized_name, variants = _choose_cluster_name(members)  # type: ignore[arg-type]
        birth = _choose_cluster_birth_date(members)  # type: ignore[arg-type]
        run = str(cluster.get("run", "") or "")
        canonical_value = run or f"{birth}|{normalized_name or chosen_name}"
        identity_patient_id = make_id("pidm", canonical_value)
        source_patient_ids = sorted({member.get("patient_id", "") for member in members if member.get("patient_id")})
        source_files = sorted(
            {
                token.strip()
                for member in members
                for token in (member.get("source_files", "") or "").split(";")
                if token.strip()
            }
        )
        strategies = cluster["strategies"]  # type: ignore[index]
        confidences = cluster["scores"]  # type: ignore[index]
        identity_rows.append(
            {
                "identity_patient_id": identity_patient_id,
                "run": run,
                "fecha_nacimiento": birth,
                "nombre": chosen_name,
                "nombre_normalizado": normalized_name,
                "nombre_variantes": " | ".join(sorted(set(variants))),
                "source_patient_ids": ",".join(source_patient_ids),
                "source_patient_count": str(len(source_patient_ids)),
                "source_files": "; ".join(source_files),
                "matching_strategy": ",".join(sorted(set(strategies))),
                "matching_confidence": "high" if "high" in confidences else "medium" if "medium" in confidences else "low",
            }
        )

    identity_rows.sort(key=lambda row: (row["run"], row["fecha_nacimiento"], row["nombre"]))
    return identity_rows


def build_missing_run_review(identity_rows: list[dict[str, str]]) -> list[dict[str, str]]:
    with_run = [row for row in identity_rows if row.get("run", "").strip()]
    missing = [row for row in identity_rows if not row.get("run", "").strip()]

    review_rows: list[dict[str, str]] = []
    for row in missing:
        birth = row.get("fecha_nacimiento", "").strip()
        name = row.get("nombre", "").strip()
        candidate_pool = with_run
        if birth:
            same_birth = [candidate for candidate in with_run if candidate.get("fecha_nacimiento", "").strip() == birth]
            if same_birth:
                candidate_pool = same_birth

        candidates: list[tuple[float, dict[str, str]]] = []
        for candidate in candidate_pool:
            score = _name_match_score(name, candidate.get("nombre", ""))
            if score >= 0.72:
                candidates.append((score, candidate))
        candidates.sort(
            key=lambda item: (
                item[0],
                item[1].get("fecha_nacimiento", ""),
                item[1].get("nombre", ""),
            ),
            reverse=True,
        )

        top_score = candidates[0][0] if candidates else 0.0
        second_score = candidates[1][0] if len(candidates) > 1 else 0.0
        if birth and top_score >= 0.90 and top_score - second_score >= 0.05:
            recommendation = "review_high_confidence_birth_name"
        elif not birth and top_score >= 0.99 and top_score - second_score >= 0.05:
            recommendation = "review_exact_name_only"
        elif candidates:
            recommendation = "review_candidates"
        else:
            recommendation = "manual_search"

        review = {
            "identity_patient_id": row.get("identity_patient_id", ""),
            "nombre": name,
            "fecha_nacimiento": birth,
            "source_patient_ids": row.get("source_patient_ids", ""),
            "source_files": row.get("source_files", ""),
            "candidate_count": str(len(candidates)),
            "recommendation": recommendation,
        }
        for idx in range(3):
            slot = idx + 1
            if idx < len(candidates):
                score, candidate = candidates[idx]
                review[f"candidate_run_{slot}"] = candidate.get("run", "")
                review[f"candidate_name_{slot}"] = candidate.get("nombre", "")
                review[f"candidate_birth_{slot}"] = candidate.get("fecha_nacimiento", "")
                review[f"candidate_score_{slot}"] = f"{score:.3f}"
            else:
                review[f"candidate_run_{slot}"] = ""
                review[f"candidate_name_{slot}"] = ""
                review[f"candidate_birth_{slot}"] = ""
                review[f"candidate_score_{slot}"] = ""
        review_rows.append(review)

    review_rows.sort(key=lambda row: (row["fecha_nacimiento"], row["nombre"]))
    return review_rows


# ---------------------------------------------------------------------------
# Episode source traceability
# ---------------------------------------------------------------------------

EPISODE_SOURCE_FIELDS = [
    "source_id",
    "stay_id",
    "episode_id",
    "raw_file",
    "raw_row",
    "origin_type",
    "fields_contributed",
]


def build_episode_source(
    stays: list[dict[str, str]],
    episodes: list[dict[str, str]],
) -> list[dict[str, str]]:
    """Map each original episode to its consolidated stay for traceability.

    For each stay, iterates its ``source_episode_ids`` (comma-separated) and
    looks up the episode in *episodes* to produce a source row linking that
    episode back to the stay.

    Args:
        stays: Output of :func:`consolidate_stays`.
        episodes: The original episode master list.

    Returns:
        One dict per (stay, episode) pair with fields from
        :data:`EPISODE_SOURCE_FIELDS`.
    """
    # Index episodes by episode_id for O(1) lookups
    ep_index: dict[str, dict[str, str]] = {}
    for ep in episodes:
        eid = ep.get("episode_id", "")
        if eid:
            ep_index[eid] = ep

    rows: list[dict[str, str]] = []
    for stay in stays:
        stay_id = stay.get("stay_id", "")
        source_ids_raw = stay.get("source_episode_ids", "")
        if not source_ids_raw:
            continue

        for ep_id in source_ids_raw.split(","):
            ep_id = ep_id.strip()
            if not ep_id:
                continue
            ep = ep_index.get(ep_id, {})
            rows.append({
                "source_id": make_id("src", f"{stay_id}|{ep_id}"),
                "stay_id": stay_id,
                "episode_id": ep_id,
                "raw_file": ep.get("raw_file", ""),
                "raw_row": ep.get("raw_row", ""),
                "origin_type": ep.get("episode_origin", ""),
                "fields_contributed": ep.get("fields_contributed", ""),
            })

    return rows


# ---------------------------------------------------------------------------
# Pipeline health metrics
# ---------------------------------------------------------------------------

PIPELINE_HEALTH_FIELDS = [
    "run_id",
    "run_timestamp",
    "source_files_processed",
    "raw_rows_processed",
    "patients_total",
    "stays_total",
    "stays_with_egreso",
    "stays_with_ingreso",
    "stays_with_establishment",
    "issues_open",
    "issues_review_required",
    "review_queue_pending",
    "duplicate_candidates",
    "coverage_gaps_detected",
    "health_status",
]


def build_pipeline_health(
    stays: list[dict[str, str]],
    quality_issues: list[dict[str, str]],
    coverage_gaps: list[dict[str, str]],
    source_files_count: int,
) -> dict[str, str]:
    """Generate a single dict representing pipeline health metrics.

    Args:
        stays: Consolidated stays from :func:`consolidate_stays`.
        quality_issues: Quality-issue rows (may use ``status`` or
            ``resolution_status`` as the column name).
        coverage_gaps: Output of :func:`build_coverage_gaps`.
        source_files_count: Number of raw source files processed.

    Returns:
        Dict with keys from :data:`PIPELINE_HEALTH_FIELDS`.
    """
    now = datetime.now()

    patients_total = len({s.get("patient_id", "") for s in stays} - {""})
    stays_total = len(stays)
    stays_with_egreso = sum(1 for s in stays if s.get("fecha_egreso", ""))
    stays_with_ingreso = sum(1 for s in stays if s.get("fecha_ingreso", ""))
    stays_with_establishment = sum(
        1 for s in stays if s.get("establecimiento", "")
    )

    # Count open / review-required issues — handle both column names
    issues_open = 0
    issues_review_required = 0
    for issue in quality_issues:
        status = issue.get("status") or issue.get("resolution_status", "")
        if status in ("OPEN", "REVIEW_REQUIRED"):
            issues_open += 1
        if status == "REVIEW_REQUIRED":
            issues_review_required += 1

    # Coverage gaps with flag set
    gaps_detected = sum(
        1 for g in coverage_gaps if g.get("gap_flag") == "True"
    )

    # Raw rows processed — sum of source_episode_count across stays
    raw_rows = sum(int(s.get("source_episode_count", "0") or "0") for s in stays)

    # Health status
    issue_ratio = issues_open / stays_total if stays_total else 0.0
    if issue_ratio > 0.15 or gaps_detected > 2:
        health_status = "red"
    elif issue_ratio > 0.05 or gaps_detected > 0:
        health_status = "yellow"
    else:
        health_status = "green"

    return {
        "run_id": make_id("run", now.isoformat()),
        "run_timestamp": now.isoformat(),
        "source_files_processed": str(source_files_count),
        "raw_rows_processed": str(raw_rows),
        "patients_total": str(patients_total),
        "stays_total": str(stays_total),
        "stays_with_egreso": str(stays_with_egreso),
        "stays_with_ingreso": str(stays_with_ingreso),
        "stays_with_establishment": str(stays_with_establishment),
        "issues_open": str(issues_open),
        "issues_review_required": str(issues_review_required),
        "review_queue_pending": "0",
        "duplicate_candidates": "0",
        "coverage_gaps_detected": str(gaps_detected),
        "health_status": health_status,
    }


# ---------------------------------------------------------------------------
# Coverage gaps detection
# ---------------------------------------------------------------------------

COVERAGE_GAP_FIELDS = [
    "month",
    "metric",
    "observed",
    "expected",
    "ratio",
    "gap_flag",
]


def build_coverage_gaps(
    stays: list[dict[str, str]],
) -> list[dict[str, str]]:
    """Detect months where ingresos fall below 70 % of the 6-month moving avg.

    For each month present in *stays* (derived from ``fecha_ingreso[:7]``),
    the function computes how many stays started that month (observed) and
    compares it to the average of the preceding 6 months (expected).  If
    ``observed / expected < 0.70`` the month is flagged.

    Months with fewer than 6 preceding months of data are still evaluated
    using whatever history is available.  If there is no preceding data the
    month is not flagged.

    Args:
        stays: Consolidated stays.

    Returns:
        One dict per month with fields from :data:`COVERAGE_GAP_FIELDS`.
    """
    # Count stays per month
    month_counts: dict[str, int] = {}
    for stay in stays:
        fi = stay.get("fecha_ingreso", "")
        if len(fi) >= 7:
            month = fi[:7]
            month_counts[month] = month_counts.get(month, 0) + 1

    if not month_counts:
        return []

    sorted_months = sorted(month_counts.keys())

    rows: list[dict[str, str]] = []
    for i, month in enumerate(sorted_months):
        observed = month_counts[month]

        # Preceding months (up to 6)
        preceding = sorted_months[max(0, i - 6):i]
        if not preceding:
            # No history — cannot compute moving average; report without flag
            rows.append({
                "month": month,
                "metric": "ingresos",
                "observed": str(observed),
                "expected": "",
                "ratio": "",
                "gap_flag": "False",
            })
            continue

        expected = sum(month_counts[m] for m in preceding) / len(preceding)
        ratio = observed / expected if expected else 0.0
        gap_flag = "True" if ratio < 0.70 else "False"

        rows.append({
            "month": month,
            "metric": "ingresos",
            "observed": str(observed),
            "expected": f"{expected:.2f}",
            "ratio": f"{ratio:.2f}",
            "gap_flag": gap_flag,
        })

    return rows


# ---------------------------------------------------------------------------
# Review queue, quality issues filter, duplicate candidates
# ---------------------------------------------------------------------------

REVIEW_QUEUE_FIELDS = [
    "queue_item_id",
    "queue_type",
    "entity_id",
    "patient_name",
    "patient_rut",
    "summary",
    "candidate_ids",
    "candidate_scores",
    "priority",
    "created_at",
]

QUALITY_ISSUE_FIELDS = [
    "issue_id",
    "issue_type",
    "severity",
    "entity_type",
    "entity_id",
    "description",
    "raw_value",
    "suggested_value",
    "status",
    "created_at",
]

DUPLICATE_CANDIDATE_FIELDS = [
    "candidate_id",
    "entity_type",
    "entity_a_id",
    "entity_b_id",
    "match_reason",
    "confidence",
    "reviewed",
    "resolution",
]


def build_unified_review_queue(
    match_queue: list[dict],
    identity_queue: list[dict],
    discharge_events: list[dict],
    quality_issues: list[dict],
) -> list[dict]:
    """Unify all review queues into a single list.

    Sources:
    - match_queue items (where auto_close_recommended != "1") -> queue_type="unmatched_form"
    - discharge_events where match_status or resolution_status == "unresolved" -> queue_type="unresolved_discharge"
    - identity_queue items -> queue_type="identity"
    - quality_issues PATIENT_WITHOUT_EPISODE + REVIEW_REQUIRED -> queue_type="patient_orphan"
    - quality_issues ESTABLISHMENT_UNRESOLVED + OPEN -> queue_type="establishment"

    Handles both conftest schema (review_id, episode_id, match_score) and
    real pipeline schema (review_queue_id, form_submission_id, candidate_score, etc.).

    Returns:
        List of dicts with REVIEW_QUEUE_FIELDS keys.
    """
    now = datetime.now().isoformat()
    rows: list[dict] = []

    # --- match_queue -> unmatched_form ---
    for item in match_queue:
        auto_close = str(item.get("auto_close_recommended", ""))
        if auto_close == "1":
            continue

        # Handle both schemas for identifiers
        entity_id = (
            item.get("review_queue_id")
            or item.get("review_id")
            or item.get("episode_id", "")
        )
        patient_name = item.get("patient_name", "")
        patient_rut = item.get("patient_rut", "")

        # Candidate info — handle both schemas
        candidate_id = item.get("candidate_episode_id", "")
        candidate_score = str(
            item.get("candidate_score")
            or item.get("match_score", "")
        )
        match_reason = item.get("match_reason", "")
        summary = f"Form match pending: {match_reason}" if match_reason else "Form match pending review"

        # Determine score for priority
        try:
            score_val = float(candidate_score) if candidate_score else 0.0
        except (ValueError, TypeError):
            score_val = 0.0

        # Normalise score: if between 0 and 1, scale to 0-100
        if 0 < score_val <= 1.0:
            score_val = score_val * 100

        priority = "high" if score_val >= 60 else "high"  # form matches are always high

        queue_item_id = make_id("rq", f"match|{entity_id}")
        rows.append({
            "queue_item_id": queue_item_id,
            "queue_type": "unmatched_form",
            "entity_id": entity_id,
            "patient_name": patient_name,
            "patient_rut": patient_rut,
            "summary": summary,
            "candidate_ids": candidate_id,
            "candidate_scores": candidate_score,
            "priority": priority,
            "created_at": item.get("submission_timestamp", now),
        })

    # --- discharge_events -> unresolved_discharge ---
    for item in discharge_events:
        match_status = item.get("match_status", "")
        resolution_status = item.get("resolution_status", "")
        if match_status != "unresolved" and resolution_status != "unresolved":
            continue

        entity_id = item.get("discharge_id", "")
        episode_id = item.get("episode_id", "")
        summary = f"Unresolved discharge for episode {episode_id}"

        queue_item_id = make_id("rq", f"discharge|{entity_id}")
        rows.append({
            "queue_item_id": queue_item_id,
            "queue_type": "unresolved_discharge",
            "entity_id": entity_id,
            "patient_name": item.get("patient_name", ""),
            "patient_rut": item.get("patient_rut", ""),
            "summary": summary,
            "candidate_ids": episode_id,
            "candidate_scores": "",
            "priority": "medium",
            "created_at": item.get("created_at", now),
        })

    # --- identity_queue -> identity ---
    for item in identity_queue:
        entity_id = item.get("identity_review_id", "")
        patient_id = item.get("patient_id", "")
        issue_type = item.get("issue_type", "")
        original_val = item.get("original_rut", "")
        suggested_val = item.get("suggested_rut", "")
        summary = f"Identity issue ({issue_type}): {original_val} -> {suggested_val}"

        queue_item_id = make_id("rq", f"identity|{entity_id}")
        rows.append({
            "queue_item_id": queue_item_id,
            "queue_type": "identity",
            "entity_id": entity_id,
            "patient_name": item.get("patient_name", ""),
            "patient_rut": original_val,
            "summary": summary,
            "candidate_ids": patient_id,
            "candidate_scores": "",
            "priority": "low",
            "created_at": item.get("created_at", now),
        })

    # --- quality_issues -> patient_orphan / establishment ---
    for item in quality_issues:
        issue_type = item.get("issue_type", "")
        status = item.get("status") or item.get("resolution_status", "")

        if issue_type == "PATIENT_WITHOUT_EPISODE" and status == "REVIEW_REQUIRED":
            entity_id = item.get("quality_issue_id") or item.get("issue_id", "")
            queue_item_id = make_id("rq", f"orphan|{entity_id}")
            rows.append({
                "queue_item_id": queue_item_id,
                "queue_type": "patient_orphan",
                "entity_id": entity_id,
                "patient_name": item.get("patient_name", ""),
                "patient_rut": item.get("patient_rut", ""),
                "summary": item.get("description", "Patient without episode"),
                "candidate_ids": "",
                "candidate_scores": "",
                "priority": "low",
                "created_at": item.get("created_at", now),
            })
        elif issue_type == "ESTABLISHMENT_UNRESOLVED" and status == "OPEN":
            entity_id = item.get("quality_issue_id") or item.get("issue_id", "")
            queue_item_id = make_id("rq", f"establishment|{entity_id}")
            rows.append({
                "queue_item_id": queue_item_id,
                "queue_type": "establishment",
                "entity_id": entity_id,
                "patient_name": item.get("patient_name", ""),
                "patient_rut": item.get("patient_rut", ""),
                "summary": item.get("description", "Establishment unresolved"),
                "candidate_ids": "",
                "candidate_scores": "",
                "priority": "low",
                "created_at": item.get("created_at", now),
            })

    return rows


def filter_actionable_quality_issues(
    quality_issues: list[dict],
) -> list[dict]:
    """Filter quality issues to only OPEN and REVIEW_REQUIRED statuses.

    Handles both ``status`` and ``resolution_status`` column names and
    normalises ``issue_id`` from ``quality_issue_id`` or ``issue_id``.

    Returns:
        List of dicts with QUALITY_ISSUE_FIELDS keys.
    """
    rows: list[dict] = []
    for issue in quality_issues:
        status = issue.get("status") or issue.get("resolution_status", "")
        if status not in ("OPEN", "REVIEW_REQUIRED"):
            continue

        issue_id = issue.get("quality_issue_id") or issue.get("issue_id", "")
        rows.append({
            "issue_id": issue_id,
            "issue_type": issue.get("issue_type", ""),
            "severity": issue.get("severity", ""),
            "entity_type": issue.get("entity_type", "episode"),
            "entity_id": issue.get("episode_id") or issue.get("entity_id", ""),
            "description": issue.get("description", ""),
            "raw_value": issue.get("raw_value", ""),
            "suggested_value": issue.get("suggested_value", ""),
            "status": status,
            "created_at": issue.get("created_at", ""),
        })

    return rows


def build_duplicate_candidates(
    stays: list[dict],
    patients: list[dict],
) -> list[dict]:
    """Detect suspected duplicate stays and patients.

    Detection rules:
    - **Stays**: same RUT + fecha_ingreso within 7 days + different patient_id
      or different stay_id -> "same_rut_similar_dates"
    - **Patients**: same RUT + different patient_id -> "same_rut_different_patient"
    - **Patients**: >90% name similarity (SequenceMatcher) + same comuna +
      different patient_id -> "similar_name_same_comuna"

    Returns:
        List of dicts with DUPLICATE_CANDIDATE_FIELDS keys.
    """
    rows: list[dict] = []
    seen_pairs: set[tuple[str, str, str]] = set()

    def _add(entity_type: str, a_id: str, b_id: str, reason: str, confidence: str) -> None:
        # Normalise pair order to avoid duplicates
        pair_key = (entity_type, min(a_id, b_id), max(a_id, b_id))
        if pair_key in seen_pairs:
            return
        seen_pairs.add(pair_key)
        candidate_id = make_id("dup", f"{entity_type}|{a_id}|{b_id}")
        rows.append({
            "candidate_id": candidate_id,
            "entity_type": entity_type,
            "entity_a_id": a_id,
            "entity_b_id": b_id,
            "match_reason": reason,
            "confidence": confidence,
            "reviewed": "False",
            "resolution": "",
        })

    # --- Stay duplicates: same RUT + fecha_ingreso within 7 days + different stay_id ---
    stays_with_rut: list[tuple[str, str, str, str]] = []  # (rut, stay_id, patient_id, fecha_ingreso)
    for stay in stays:
        rut = stay.get("rut", "").strip()
        stay_id = stay.get("stay_id", "")
        patient_id = stay.get("patient_id", "")
        fi = stay.get("fecha_ingreso", "")
        if rut and stay_id and fi:
            stays_with_rut.append((rut, stay_id, patient_id, fi))

    for i in range(len(stays_with_rut)):
        rut_a, sid_a, pid_a, fi_a_str = stays_with_rut[i]
        fi_a = _parse_date(fi_a_str)
        if not fi_a:
            continue
        for j in range(i + 1, len(stays_with_rut)):
            rut_b, sid_b, pid_b, fi_b_str = stays_with_rut[j]
            if rut_a != rut_b:
                continue
            if sid_a == sid_b:
                continue
            fi_b = _parse_date(fi_b_str)
            if not fi_b:
                continue
            if abs((fi_a - fi_b).days) <= 7:
                _add("stay", sid_a, sid_b, "same_rut_similar_dates", "high")

    # --- Patient duplicates: same RUT + different patient_id ---
    patients_by_rut: dict[str, list[dict]] = {}
    for patient in patients:
        rut = patient.get("rut", "").strip()
        if rut:
            patients_by_rut.setdefault(rut, []).append(patient)

    for rut, group in patients_by_rut.items():
        if len(group) < 2:
            continue
        for i in range(len(group)):
            pid_a = group[i].get("patient_id", "")
            for j in range(i + 1, len(group)):
                pid_b = group[j].get("patient_id", "")
                if pid_a != pid_b:
                    _add("patient", pid_a, pid_b, "same_rut_different_patient", "high")

    # --- Patient duplicates: >90% name similarity + same comuna + different patient_id ---
    patients_by_comuna: dict[str, list[dict]] = {}
    for patient in patients:
        comuna = patient.get("comuna", "").strip()
        if comuna:
            patients_by_comuna.setdefault(comuna, []).append(patient)

    for comuna, group in patients_by_comuna.items():
        if len(group) < 2:
            continue
        for i in range(len(group)):
            pid_a = group[i].get("patient_id", "")
            name_a = group[i].get("nombre_completo", "").strip().upper()
            if not name_a:
                continue
            for j in range(i + 1, len(group)):
                pid_b = group[j].get("patient_id", "")
                if pid_a == pid_b:
                    continue
                name_b = group[j].get("nombre_completo", "").strip().upper()
                if not name_b:
                    continue
                ratio = difflib.SequenceMatcher(None, name_a, name_b).ratio()
                if ratio > 0.90:
                    _add("patient", pid_a, pid_b, "similar_name_same_comuna", "medium")

    return rows


# ---------------------------------------------------------------------------
# Manual resolution reader
# ---------------------------------------------------------------------------

MANUAL_RESOLUTION_FIELDS = [
    "resolution_id",
    "queue_type",
    "item_id",
    "action",
    "target_id",
    "field_corrected",
    "old_value",
    "new_value",
    "resolved_by",
    "resolved_at",
    "applied",
]


def read_manual_resolutions(path: Path) -> list[dict[str, str]]:
    """Read manual_resolution.csv.  Returns empty list if file doesn't exist."""
    try:
        return read_csv(path)
    except FileNotFoundError:
        return []


def apply_resolutions_to_queue(
    queue: list[dict[str, str]],
    resolutions: list[dict[str, str]],
) -> list[dict[str, str]]:
    """Remove resolved items from the review queue.

    Filters out queue items whose ``entity_id`` appears in *resolutions*
    with an ``action`` in (discard, associate, merge) and ``applied`` != "True".
    """
    resolved_ids: set[str] = set()
    for res in resolutions:
        action = res.get("action", "")
        applied = res.get("applied", "")
        if action in ("discard", "associate", "merge") and applied != "True":
            item_id = res.get("item_id", "")
            if item_id:
                resolved_ids.add(item_id)

    return [item for item in queue if item.get("entity_id", "") not in resolved_ids]


def apply_resolutions_to_stays(
    stays: list[dict[str, str]],
    resolutions: list[dict[str, str]],
) -> list[dict[str, str]]:
    """Aplica correcciones manuales dirigidas a stay_id en la capa canónica."""
    stay_lookup = {stay["stay_id"]: stay for stay in stays}
    for res in resolutions:
        if res.get("applied") == "True":
            continue
        if res.get("action") != "correct":
            continue
        item_id = res.get("item_id", "")
        field = res.get("field_corrected", "")
        new_val = res.get("new_value", "")
        if not item_id or not field or not new_val:
            continue
        stay = stay_lookup.get(item_id)
        if stay is None:
            continue
        stay[field] = new_val
        finalize_stay(stay)
    return list(stay_lookup.values())


# ---------------------------------------------------------------------------
# Main orchestration
# ---------------------------------------------------------------------------


def build_canonical_outputs(
    enriched_dir: Path,
    output_dir: Path,
    manual_dir: Path,
) -> None:
    """Main orchestration: reads enriched CSVs, processes, writes canonical layer."""

    # 1. Read CSVs from enriched_dir
    episodes = read_csv(enriched_dir / "episode_master.csv")
    patients = read_csv(enriched_dir / "patient_master.csv")
    quality_issues = read_csv(enriched_dir / "data_quality_issue.csv")
    match_queue = read_csv(enriched_dir / "match_review_queue.csv")
    identity_queue = read_csv(enriched_dir / "identity_review_queue.csv")
    discharge_events = read_csv(enriched_dir / "normalized_discharge_event.csv")

    # 2. Read manual resolutions
    resolutions = read_manual_resolutions(manual_dir / "manual_resolution.csv")

    # 3. Count source files
    intermediate_dir = enriched_dir.parent / "intermediate"
    try:
        source_files = read_csv(intermediate_dir / "raw_source_file.csv")
        source_count = len(source_files)
    except FileNotFoundError:
        source_count = 0

    # 3b. Apply manual corrections to episodes and patients
    ep_lookup = {ep["episode_id"]: ep for ep in episodes}
    pat_lookup_by_id = {p["patient_id"]: p for p in patients}
    for res in resolutions:
        if res.get("applied") == "True":
            continue
        if res.get("action") != "correct":
            continue
        field = res.get("field_corrected", "")
        new_val = res.get("new_value", "")
        item_id = res.get("item_id", "")
        if not field or not new_val or not item_id:
            continue
        if item_id in ep_lookup:
            ep_lookup[item_id][field] = new_val
        if item_id in pat_lookup_by_id:
            pat_lookup_by_id[item_id][field] = new_val

    # 3c. Enrich episodes with patient + reference data before consolidation
    patient_lookup = {p["patient_id"]: p for p in patients}
    estab_lookup = {}
    for est in read_csv(enriched_dir / "establishment_reference.csv") if (enriched_dir / "establishment_reference.csv").exists() else []:
        eid = est.get("establishment_id", "")
        if eid:
            estab_lookup[eid] = est
    loc_lookup = {}
    for loc in read_csv(enriched_dir / "locality_reference.csv") if (enriched_dir / "locality_reference.csv").exists() else []:
        lid = loc.get("locality_id", "")
        if lid:
            loc_lookup[lid] = loc

    for ep in episodes:
        pid = ep.get("patient_id", "")
        pat = patient_lookup.get(pid, {})
        if pat.get("nombre_completo"):
            ep["nombre_completo"] = pat.get("nombre_completo", "")
        if pat.get("rut"):
            ep["rut"] = pat.get("rut", "")
        if pat.get("sexo"):
            ep["sexo_resuelto"] = pat.get("sexo", "")
        if pat.get("edad_reportada") not in ("", None):
            ep["edad_reportada"] = str(pat.get("edad_reportada", ""))
        if pat.get("comuna"):
            ep["comuna_resuelta"] = pat.get("comuna", "")
        if pat.get("cesfam"):
            ep["cesfam"] = pat.get("cesfam", "")

        est_id = ep.get("establishment_id", "")
        est = estab_lookup.get(est_id, {})
        ep.setdefault("establecimiento_resuelto", est.get("nombre_oficial", ""))
        if not ep.get("codigo_deis_resuelto"):
            ep["codigo_deis_resuelto"] = est.get("codigo_deis", ep.get("codigo_deis", ""))

        loc_id = ep.get("locality_id", "")
        loc = loc_lookup.get(loc_id, {})
        ep.setdefault("localidad_resuelta", loc.get("nombre_oficial", ""))
        ep.setdefault("latitud_localidad", str(loc.get("latitud", "")))
        ep.setdefault("longitud_localidad", str(loc.get("longitud", "")))

    # 4. Process
    stays = consolidate_stays(episodes)
    stays = apply_resolutions_to_stays(stays, resolutions)
    enriched_patients = enrich_patient_master(patients, stays, quality_issues)
    identity_patients = build_patient_identity_master(patients)
    missing_run_review = build_missing_run_review(identity_patients)
    episode_sources = build_episode_source(stays, episodes)
    filtered_issues = filter_actionable_quality_issues(quality_issues)
    review_queue = build_unified_review_queue(
        match_queue, identity_queue, discharge_events, quality_issues,
    )
    review_queue = apply_resolutions_to_queue(review_queue, resolutions)
    coverage_gaps = build_coverage_gaps(stays)
    duplicate_candidates = build_duplicate_candidates(stays, enriched_patients)
    health = build_pipeline_health(stays, quality_issues, coverage_gaps, source_count)
    health["review_queue_pending"] = str(len(review_queue))
    health["duplicate_candidates"] = str(len(duplicate_candidates))

    # 5. Write outputs
    output_dir.mkdir(parents=True, exist_ok=True)

    write_csv(output_dir / "hospitalization_stay.csv", stays, HOSPITALIZATION_STAY_FIELDS)
    write_csv(output_dir / "patient_master.csv", enriched_patients, PATIENT_MASTER_FIELDS)
    write_csv(output_dir / "patient_identity_master.csv", identity_patients, PATIENT_IDENTITY_MASTER_FIELDS)
    write_csv(
        output_dir / "patient_identity_missing_run_review.csv",
        missing_run_review,
        PATIENT_IDENTITY_MISSING_RUN_REVIEW_FIELDS,
    )
    write_csv(output_dir / "episode_source.csv", episode_sources, EPISODE_SOURCE_FIELDS)
    write_csv(output_dir / "pipeline_health.csv", [health], PIPELINE_HEALTH_FIELDS)
    write_csv(output_dir / "quality_issue.csv", filtered_issues, QUALITY_ISSUE_FIELDS)
    write_csv(output_dir / "review_queue.csv", review_queue, REVIEW_QUEUE_FIELDS)
    write_csv(output_dir / "coverage_gap.csv", coverage_gaps, COVERAGE_GAP_FIELDS)
    write_csv(output_dir / "duplicate_candidate.csv", duplicate_candidates, DUPLICATE_CANDIDATE_FIELDS)

    # 6. Copy reference files from enriched_dir
    for ref_file in ("establishment_reference.csv", "locality_reference.csv"):
        src = enriched_dir / ref_file
        if src.exists():
            shutil.copy2(src, output_dir / ref_file)

    # 7. Print summary
    print(f"Canonical outputs written to {output_dir}")
    print(f"  Stays: {len(stays)}")
    print(f"  Patients: {len(enriched_patients)}")
    print(f"  Identity patients: {len(identity_patients)}")
    print(f"  Missing-run review rows: {len(missing_run_review)}")
    print(f"  Episode sources: {len(episode_sources)}")
    print(f"  Quality issues (actionable): {len(filtered_issues)}")
    print(f"  Review queue (pending): {len(review_queue)}")
    print(f"  Coverage gaps: {len(coverage_gaps)}")
    print(f"  Duplicate candidates: {len(duplicate_candidates)}")
    print(f"  Health status: {health['health_status']}")


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Genera capa canonica estabilizada para dashboard admin HODOM.",
    )
    parser.add_argument(
        "--enriched-dir",
        type=Path,
        default=Path("output/spreadsheet/enriched"),
    )
    parser.add_argument(
        "--output-dir",
        type=Path,
        default=Path("output/spreadsheet/canonical"),
    )
    parser.add_argument(
        "--manual-dir",
        type=Path,
        default=Path("input/manual"),
    )
    args = parser.parse_args()
    build_canonical_outputs(args.enriched_dir, args.output_dir, args.manual_dir)


if __name__ == "__main__":
    main()
