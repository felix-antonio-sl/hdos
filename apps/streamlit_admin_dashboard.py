from __future__ import annotations

import csv
from datetime import datetime
from pathlib import Path
import sys

import pandas as pd
import pydeck as pdk
import streamlit as st

REPO_DIR = Path(__file__).resolve().parents[1]
SCRIPTS_DIR = REPO_DIR / "scripts"
if str(SCRIPTS_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPTS_DIR))

CANONICAL_DIR = REPO_DIR / "output" / "spreadsheet" / "canonical"
RESOLUTION_PATH = REPO_DIR / "input" / "manual" / "manual_resolution.csv"

ORIGIN_CATEGORY_ORDER = ["APS", "Urgencia", "Hospitalización", "Ambulatorio", "Ley Urgencia", "UGCC", "Sin inferencia"]
AGE_CATEGORY_ORDER = ["<15", "15-19", "20-59", ">=60", "SIN_RANGO"]
SEX_CATEGORY_ORDER = ["femenino", "masculino", "sin_sexo"]

RESOLUTION_COLUMNS = [
    "resolved_at",
    "queue_item_id",
    "queue_type",
    "entity_id",
    "action",
    "resolved_value",
    "resolved_by",
    "notes",
]

ISSUE_DESCRIPTIONS = {
    "LOCALITY_COORDINATES_MISSING": "Localidad sin coordenadas geograficas",
    "UNMATCHED_FORM_SUBMISSION": "Formulario HODOM sin episodio asociado",
    "PATIENT_WITHOUT_EPISODE": "Paciente registrado sin hospitalizacion",
    "ESTABLISHMENT_UNRESOLVED": "Establecimiento no encontrado en catalogo DEIS",
    "BIRTHDATE_AGE_MISMATCH": "Edad no coincide con fecha de nacimiento",
    "DATE_PARSE_FAILED": "Fecha no se pudo interpretar",
}

QUEUE_DESCRIPTIONS = {
    "unmatched_form": (
        "Formularios de solicitud HODOM que no pudieron asociarse automaticamente "
        "a una hospitalizacion. Revisa cada caso y decide si asociar a un episodio "
        "existente, crear uno nuevo, o descartar."
    ),
    "unresolved_discharge": (
        "Altas registradas en la planilla que no coinciden con ningun episodio. "
        "Pueden ser altas de pacientes no ingresados al sistema o errores de digitacion."
    ),
    "identity": (
        "Problemas de identidad: RUT invalido, edad que no coincide con fecha de "
        "nacimiento, u otros conflictos en los datos del paciente."
    ),
    "patient_orphan": (
        "Pacientes que aparecen en los registros pero no tienen ninguna hospitalizacion "
        "asociada. Pueden ser registros de prueba, errores, o pacientes cuyo ingreso "
        "no se registro."
    ),
    "establishment": (
        "Establecimientos de salud mencionados en los datos que no se pudieron resolver "
        "contra el catalogo oficial DEIS."
    ),
}

PAGINATION_SIZE = 20


def read_canonical(name: str) -> pd.DataFrame:
    path = CANONICAL_DIR / name
    if not path.exists():
        raise FileNotFoundError(f"No existe el archivo requerido: {path}")
    return pd.read_csv(path)


def read_canonical_optional(name: str) -> pd.DataFrame:
    path = CANONICAL_DIR / name
    if path.exists():
        return pd.read_csv(path)
    return pd.DataFrame()


@st.cache_data(ttl=300, show_spinner=False)
def load_core_data() -> dict[str, pd.DataFrame]:
    """Load core datasets needed for all main tabs (stays, patients, establishments, localities)."""
    stays = read_canonical("hospitalization_stay.csv")
    patients = read_canonical("patient_master.csv")
    establishments = read_canonical_optional("establishment_reference.csv")
    localities = read_canonical_optional("locality_reference.csv")

    # Parse dates on stays
    stays["fecha_ingreso"] = pd.to_datetime(stays["fecha_ingreso"], errors="coerce")
    stays["fecha_egreso"] = pd.to_datetime(stays["fecha_egreso"], errors="coerce")
    stays["activity_date"] = stays["fecha_ingreso"].combine_first(stays["fecha_egreso"])
    stays["activity_month"] = stays["activity_date"].dt.to_period("M").astype("string")
    stays["estadia_util"] = (stays["fecha_egreso"] - stays["fecha_ingreso"]).dt.days
    stays["estado"] = stays["estado"].fillna("SIN_ESTADO")
    stays["prevision"] = stays["prevision"].fillna("SIN_PREVISION")
    stays["servicio_origen"] = stays["servicio_origen"].fillna("SIN_SERVICIO")
    stays["motivo_egreso"] = stays["motivo_egreso"].fillna("")
    stays["usuario_o2"] = stays["usuario_o2"].fillna("")
    stays["diagnostico_principal"] = stays["diagnostico_principal"].fillna("SIN_DIAGNOSTICO")
    stays["episode_origin"] = stays["episode_origin"].fillna("raw")
    if "origen_derivacion_rem" not in stays.columns:
        stays["origen_derivacion_rem"] = ""
    stays["origen_derivacion_rem"] = stays["origen_derivacion_rem"].fillna("")
    if "fallecido_clasificacion" not in stays.columns:
        stays["fallecido_clasificacion"] = ""
    stays["fallecido_clasificacion"] = stays["fallecido_clasificacion"].fillna("")
    stays["establecimiento"] = stays["establecimiento"].fillna("")
    stays["codigo_deis"] = stays["codigo_deis"].fillna("")
    stays["comuna"] = stays["comuna"].fillna("")
    stays["localidad"] = stays["localidad"].fillna("")
    stays["latitud"] = pd.to_numeric(stays["latitud"], errors="coerce")
    stays["longitud"] = pd.to_numeric(stays["longitud"], errors="coerce")
    stays["sexo_resuelto"] = stays["sexo_resuelto"].fillna("")
    stays["edad_reportada"] = pd.to_numeric(stays["edad_reportada"], errors="coerce")
    stays["rango_etario"] = stays["rango_etario"].fillna("SIN_RANGO")
    stays["nombre_completo"] = stays["nombre_completo"].fillna("")
    stays["rut"] = stays["rut"].fillna("")

    # Display-formatted dates (dd-mm-aaaa)
    stays["fecha_ingreso_fmt"] = stays["fecha_ingreso"].dt.strftime("%d-%m-%Y").fillna("")
    stays["fecha_egreso_fmt"] = stays["fecha_egreso"].dt.strftime("%d-%m-%Y").fillna("")

    # Parse dates on patients
    patients["fecha_nacimiento_date"] = pd.to_datetime(patients["fecha_nacimiento_date"], errors="coerce")
    patients["edad_reportada"] = pd.to_numeric(patients["edad_reportada"], errors="coerce")
    patients["total_hospitalizaciones"] = pd.to_numeric(patients.get("total_hospitalizaciones", 0), errors="coerce").fillna(0).astype(int)
    for col in ("primera_fecha_ingreso", "ultima_fecha_egreso"):
        if col in patients.columns:
            patients[col] = pd.to_datetime(patients[col], errors="coerce").dt.strftime("%d-%m-%Y").fillna("")

    return {
        "stays": stays,
        "patients": patients,
        "establishments": establishments,
        "localities": localities,
    }


@st.cache_data(ttl=300, show_spinner=False)
def load_audit_data() -> dict[str, pd.DataFrame]:
    """Load audit/quality datasets only when needed (pipeline health, review queue, etc.)."""
    pipeline_health = read_canonical_optional("pipeline_health.csv")
    review_queue = read_canonical_optional("review_queue.csv")
    coverage_gaps = read_canonical_optional("coverage_gap.csv")
    quality_issues = read_canonical_optional("quality_issue.csv")
    duplicate_candidates = read_canonical_optional("duplicate_candidate.csv")

    # Parse pipeline_health timestamps
    if not pipeline_health.empty and "run_timestamp" in pipeline_health.columns:
        pipeline_health["run_timestamp"] = pd.to_datetime(pipeline_health["run_timestamp"], errors="coerce")

    return {
        "pipeline_health": pipeline_health,
        "review_queue": review_queue,
        "coverage_gaps": coverage_gaps,
        "quality_issues": quality_issues,
        "duplicate_candidates": duplicate_candidates,
    }


# ---------------------------------------------------------------------------
# Helper functions
# ---------------------------------------------------------------------------

def infer_origin_derivation(service: str) -> str:
    value = str(service or "").strip().upper()
    if not value:
        return "Sin inferencia"
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
    # Servicios hospitalarios específicos
    if value in {"MEDICINA", "CIRUGIA", "CIRGUIA", "TMT", "GINE", "PEDIATRIA", "PED",
                 "UTI", "UCI", "MEL", "OTRO", "HCHM", "ING.ESPECIAL"}:
        return "Hospitalización"
    return "Hospitalización"


def resolve_origin_derivation(row: pd.Series) -> str:
    explicit = str(row.get("origen_derivacion_rem", "") or "").strip()
    if explicit:
        return explicit
    return infer_origin_derivation(row.get("servicio_origen", ""))


def classify_outcome(motivo: str) -> str:
    value = str(motivo or "").strip().upper()
    if not value:
        return "sin_clasificar"
    # Fallecido — detectar antes de "alta" porque "ALTA POR FALLECIMIENTO" es fallecido
    if any(t in value for t in ("FALLE", "FALLEC", "DEFUNC")):
        return "fallecido"
    # Reingreso/rehospitalización — antes de "alta" porque "ALTA POR REHOSPITALIZACION"
    if any(t in value for t in ("REHOSP", "REHOSPIT", "REINGRESO", "REINGRESO HOSP")):
        return "reingreso_hospitalizacion"
    if "HOSPITALIZACION" in value or "HOSPITALIZACIÓN" in value:
        return "reingreso_hospitalizacion"
    # Alta (incluye rechazo, curaciones APS, etc.)
    if "ALTA" in value:
        return "alta"
    return "otro"


def normalize_sex_label(value: str) -> str:
    token = str(value or "").strip().upper()
    if token == "F":
        return "femenino"
    if token == "M":
        return "masculino"
    return "sin_sexo"


def overlap_days(row: pd.Series, start: pd.Timestamp, end: pd.Timestamp) -> int:
    ingreso = row["fecha_ingreso"]
    egreso = row["fecha_egreso"]
    if pd.isna(ingreso) and pd.isna(egreso):
        return 0
    # Stay sin egreso: solo contar si ingreso es reciente (≤90 días antes del fin del período)
    # Evita que stays de 2023/2024 sin cerrar inflen los días persona
    if pd.isna(egreso) and pd.notna(ingreso):
        if (end - ingreso).days > 90:
            return 0
    effective_start = max(ingreso, start) if pd.notna(ingreso) else start
    effective_end = min(egreso, end) if pd.notna(egreso) else end
    if effective_end < effective_start:
        return 0
    return int((effective_end - effective_start).days) + 1


# ---------------------------------------------------------------------------
# REM functions
# ---------------------------------------------------------------------------

def _dedup_key(row: pd.Series) -> str:
    """Clave de deduplicación: RUT si existe, sino patient_id."""
    rut = str(row.get("rut", "")).strip()
    return rut if rut else row.get("patient_id", "")


def build_rem_c11(df: pd.DataFrame, start: pd.Timestamp | None, end: pd.Timestamp | None) -> tuple[pd.DataFrame, pd.DataFrame, pd.DataFrame, dict[str, object]]:
    work = df.copy()
    if start is None:
        start = pd.to_datetime(work["activity_date"].min())
    if end is None:
        end = pd.to_datetime(work["activity_date"].max())

    work["sexo_rem"] = work["sexo_resuelto"].map(normalize_sex_label)
    work["origen_derivacion_rem"] = work.apply(resolve_origin_derivation, axis=1)
    work["rango_etario"] = work["rango_etario"].fillna("SIN_RANGO")
    work["outcome"] = work["motivo_egreso"].map(classify_outcome)
    work["fallecido_clasificacion"] = work["fallecido_clasificacion"].replace("", pd.NA).fillna("SIN_CLASIFICACION")
    work["overlap_days"] = work.apply(lambda row: overlap_days(row, start, end), axis=1)
    work["is_active_in_period"] = work["overlap_days"] > 0
    work["ingreso_in_period"] = work["fecha_ingreso"].between(start, end, inclusive="both")
    work["egreso_in_period"] = work["fecha_egreso"].between(start, end, inclusive="both")

    # Clave de deduplicación por RUT (cubre cross-patient duplicates)
    work["_dedup_key"] = work.apply(_dedup_key, axis=1)

    # Personas atendidas: pacientes únicos por RUT con solapamiento en el período
    personas_atendidas = int(work.loc[work["is_active_in_period"], "_dedup_key"].nunique())

    # Días persona: solo stays con solapamiento positivo y fecha_ingreso válida
    dias_persona = int(work.loc[work["is_active_in_period"], "overlap_days"].sum())

    totals = {
        "ingresos": int(work["ingreso_in_period"].sum()),
        "personas_atendidas": personas_atendidas,
        "dias_persona": dias_persona,
        "altas": int(((work["egreso_in_period"]) & (work["outcome"] == "alta")).sum()),
        "reingresos_hospitalizacion": int(((work["egreso_in_period"]) & (work["outcome"] == "reingreso_hospitalizacion")).sum()),
        "fallecidos_total_inferidos": int(((work["egreso_in_period"]) & (work["outcome"] == "fallecido")).sum()),
        "fallecidos_esperados": int(((work["egreso_in_period"]) & (work["outcome"] == "fallecido") & work["fallecido_clasificacion"].eq("ESPERADO")).sum()),
        "fallecidos_no_esperados": int(((work["egreso_in_period"]) & (work["outcome"] == "fallecido") & work["fallecido_clasificacion"].eq("NO ESPERADO")).sum()),
    }

    def make_table(dimension_col: str, categories: list[str]) -> pd.DataFrame:
        rows = []
        for label in categories:
            mask_dim = work[dimension_col] == label
            rows.append({"componente": "ingresos", dimension_col: label,
                         "valor": int(work.loc[work["ingreso_in_period"] & mask_dim].shape[0])})
            rows.append({"componente": "personas_atendidas", dimension_col: label,
                         "valor": int(work.loc[work["is_active_in_period"] & mask_dim, "_dedup_key"].nunique())})
            rows.append({"componente": "dias_persona", dimension_col: label,
                         "valor": int(work.loc[work["is_active_in_period"] & mask_dim, "overlap_days"].sum())})
            rows.append({"componente": "altas", dimension_col: label,
                         "valor": int(work.loc[work["egreso_in_period"] & (work["outcome"] == "alta") & mask_dim].shape[0])})
            rows.append({"componente": "reingresos_hospitalizacion", dimension_col: label,
                         "valor": int(work.loc[work["egreso_in_period"] & (work["outcome"] == "reingreso_hospitalizacion") & mask_dim].shape[0])})
            rows.append({"componente": "fallecidos", dimension_col: label,
                         "valor": int(work.loc[work["egreso_in_period"] & (work["outcome"] == "fallecido") & mask_dim].shape[0])})
            rows.append({"componente": "fallecidos_esperados", dimension_col: label,
                         "valor": int(work.loc[work["egreso_in_period"] & (work["outcome"] == "fallecido") & work["fallecido_clasificacion"].eq("ESPERADO") & mask_dim].shape[0])})
            rows.append({"componente": "fallecidos_no_esperados", dimension_col: label,
                         "valor": int(work.loc[work["egreso_in_period"] & (work["outcome"] == "fallecido") & work["fallecido_clasificacion"].eq("NO ESPERADO") & mask_dim].shape[0])})
        data = pd.DataFrame(rows)
        pivot = data.pivot_table(index="componente", columns=dimension_col, values="valor", aggfunc="sum", fill_value=0).reindex(columns=categories, fill_value=0).reset_index()
        totals_local = data.groupby("componente")["valor"].sum().rename("total").reset_index()
        return totals_local.merge(pivot, on="componente", how="left")

    sexo = make_table("sexo_rem", SEX_CATEGORY_ORDER)
    edad = make_table("rango_etario", AGE_CATEGORY_ORDER)
    origen = make_table("origen_derivacion_rem", ORIGIN_CATEGORY_ORDER)
    metadata = {"start": start, "end": end, "totals": totals}
    return sexo, edad, origen, metadata


def build_rem_detail_dataset(df: pd.DataFrame, start: pd.Timestamp | None, end: pd.Timestamp | None) -> pd.DataFrame:
    work = df.copy()
    if start is None:
        start = pd.to_datetime(work["activity_date"].min())
    if end is None:
        end = pd.to_datetime(work["activity_date"].max())

    work["sexo_rem"] = work["sexo_resuelto"].map(normalize_sex_label)
    work["origen_derivacion_rem"] = work.apply(resolve_origin_derivation, axis=1)
    work["rango_etario"] = work["rango_etario"].fillna("SIN_RANGO")
    work["outcome"] = work["motivo_egreso"].map(classify_outcome)
    work["fallecido_clasificacion"] = work["fallecido_clasificacion"].replace("", pd.NA).fillna("SIN_CLASIFICACION")
    work["overlap_days"] = work.apply(lambda row: overlap_days(row, start, end), axis=1)
    work["is_active_in_period"] = work["overlap_days"] > 0
    work["ingreso_in_period"] = work["fecha_ingreso"].between(start, end, inclusive="both")
    work["egreso_in_period"] = work["fecha_egreso"].between(start, end, inclusive="both")
    work["_dedup_key"] = work.apply(_dedup_key, axis=1)
    return work


def rem_nominal_subset(detail_df: pd.DataFrame, component: str) -> pd.DataFrame:
    if component == "ingresos":
        return detail_df[detail_df["ingreso_in_period"]]
    if component == "personas_atendidas":
        # Deduplicar por RUT (cubre cross-patient) y luego por patient_id
        active = detail_df[detail_df["is_active_in_period"]].copy()
        return active.drop_duplicates(subset=["_dedup_key"])
    if component == "dias_persona":
        return detail_df[detail_df["is_active_in_period"]]
    if component == "altas":
        return detail_df[detail_df["egreso_in_period"] & detail_df["outcome"].eq("alta")]
    if component == "reingresos_hospitalizacion":
        return detail_df[detail_df["egreso_in_period"] & detail_df["outcome"].eq("reingreso_hospitalizacion")]
    if component == "fallecidos_total_inferidos":
        return detail_df[detail_df["egreso_in_period"] & detail_df["outcome"].eq("fallecido")]
    if component == "fallecidos_esperados":
        return detail_df[detail_df["egreso_in_period"] & detail_df["outcome"].eq("fallecido") & detail_df["fallecido_clasificacion"].eq("ESPERADO")]
    if component == "fallecidos_no_esperados":
        return detail_df[detail_df["egreso_in_period"] & detail_df["outcome"].eq("fallecido") & detail_df["fallecido_clasificacion"].eq("NO ESPERADO")]
    return detail_df[detail_df["egreso_in_period"] & detail_df["outcome"].eq("fallecido")]


# ---------------------------------------------------------------------------
# Map rendering
# ---------------------------------------------------------------------------

def render_pydeck_map(df: pd.DataFrame, *, lat_col: str, lon_col: str, tooltip_fields: list[str], radius: int = 450, key: str = "map") -> None:
    geo = df.copy()
    geo[lat_col] = pd.to_numeric(geo[lat_col], errors="coerce")
    geo[lon_col] = pd.to_numeric(geo[lon_col], errors="coerce")
    geo = geo.dropna(subset=[lat_col, lon_col])
    if geo.empty:
        st.info("No hay coordenadas para mostrar en el mapa.")
        return
    center = {"lat": float(geo[lat_col].median()), "lon": float(geo[lon_col].median())}
    layer = pdk.Layer(
        "ScatterplotLayer",
        data=geo,
        get_position=f"[{lon_col}, {lat_col}]",
        get_fill_color=[18, 115, 92, 180],
        get_radius=radius,
        pickable=True,
        opacity=0.8,
    )
    tooltip = {"html": "<br/>".join(f"<b>{f}</b>: {{{f}}}" for f in tooltip_fields), "style": {"backgroundColor": "#163028", "color": "white"}}
    st.pydeck_chart(
        pdk.Deck(
            map_style="mapbox://styles/mapbox/light-v11",
            initial_view_state=pdk.ViewState(latitude=center["lat"], longitude=center["lon"], zoom=8.3, pitch=0),
            layers=[layer],
            tooltip=tooltip,
        ),
        use_container_width=True,
        key=key,
    )


# ---------------------------------------------------------------------------
# Filters
# ---------------------------------------------------------------------------

def apply_period_filter(df: pd.DataFrame, start: pd.Timestamp | None, end: pd.Timestamp | None, mode: str) -> pd.DataFrame:
    if start is None or end is None:
        return df.copy()
    filtered = df.copy()
    ingreso = filtered["fecha_ingreso"]
    egreso = filtered["fecha_egreso"]
    activity = filtered["activity_date"]

    if mode == "overlap":
        mask = (
            (
                (ingreso.isna() | (ingreso <= end))
                & (egreso.isna() | (egreso >= start))
                & (ingreso.notna() | egreso.notna())
            )
            | activity.between(start, end)
        )
        return filtered[mask]

    mask = (
        ingreso.between(start, end, inclusive="both")
        | egreso.between(start, end, inclusive="both")
        | activity.between(start, end)
    )
    return filtered[mask]


def apply_non_temporal_admin_filters(
    df: pd.DataFrame,
    preset: str,
    comuna: list[str],
    establecimiento: list[str],
    servicio: list[str],
    prevision: list[str],
    search: str,
) -> pd.DataFrame:
    filtered = df.copy()
    if preset == "Activos":
        filtered = filtered[filtered["estado"].eq("ACTIVO")]
    if comuna:
        filtered = filtered[filtered["comuna"].isin(comuna)]
    if establecimiento:
        filtered = filtered[filtered["establecimiento"].isin(establecimiento)]
    if servicio:
        filtered = filtered[filtered["servicio_origen"].isin(servicio)]
    if prevision:
        filtered = filtered[filtered["prevision"].isin(prevision)]
    if search:
        token = search.strip().lower()
        filtered = filtered[
            filtered["nombre_completo"].fillna("").str.lower().str.contains(token)
            | filtered["diagnostico_principal"].fillna("").str.lower().str.contains(token)
            | filtered["rut"].fillna("").str.lower().str.contains(token)
        ]
    return filtered


def filter_admin_data(df: pd.DataFrame, datasets: dict[str, pd.DataFrame]) -> tuple[pd.DataFrame, pd.DataFrame, pd.Timestamp | None, pd.Timestamp | None]:
    with st.sidebar:
        st.subheader("Filtros Administrativos")

        # Sidebar counters - load audit data lazily for the small sidebar summary
        audit = load_audit_data()
        rq = audit.get("review_queue", pd.DataFrame())
        qi = audit.get("quality_issues", pd.DataFrame())
        dc = audit.get("duplicate_candidates", pd.DataFrame())
        pending_queue = len(rq) if not rq.empty else 0
        open_issues = int(qi[qi["status"] == "open"].shape[0]) if not qi.empty and "status" in qi.columns else 0
        unreviewed_dupes = int(dc[dc["reviewed"] == False].shape[0]) if not dc.empty and "reviewed" in dc.columns else 0  # noqa: E712

        ph = audit.get("pipeline_health", pd.DataFrame())
        if not ph.empty:
            latest = ph.iloc[-1]
            status = str(latest.get("health_status", "unknown"))
            color = {"green": "#22c55e", "yellow": "#eab308", "red": "#ef4444"}.get(status, "#94a3b8")
            st.markdown(
                f'<div style="display:flex;align-items:center;gap:0.4rem;margin-bottom:0.5rem;">'
                f'<span style="display:inline-block;width:12px;height:12px;border-radius:50%;background:{color};"></span>'
                f'<span style="font-size:0.85rem;">Pipeline: {status}</span></div>',
                unsafe_allow_html=True,
            )

        st.caption(f"Cola de revision: {pending_queue} | Issues: {open_issues} | Duplicados: {unreviewed_dupes}")
        st.markdown("---")

        preset = st.selectbox("Preset", ["Todo", "Ingresos del periodo", "Egresos del periodo", "Activos"], index=0)
        min_date = df["activity_date"].min()
        max_date = df["activity_date"].max()
        date_range = st.date_input(
            "Rango temporal",
            value=(min_date.date() if pd.notna(min_date) else None, max_date.date() if pd.notna(max_date) else None),
        )
        comuna = st.multiselect("Comuna", sorted(df["comuna"].dropna().replace("", pd.NA).dropna().unique()))
        establecimiento = st.multiselect("Establecimiento", sorted(df["establecimiento"].dropna().replace("", pd.NA).dropna().astype(str).unique()))
        servicio = st.multiselect("Servicio de origen", sorted(df["servicio_origen"].dropna().unique()))
        prevision = st.multiselect("Prevision", sorted(df["prevision"].dropna().unique()))
        search = st.text_input("Buscar paciente / diagnostico / RUT")

    selected_start = None
    selected_end = None
    base_filtered = apply_non_temporal_admin_filters(
        df,
        preset,
        comuna,
        establecimiento,
        servicio,
        prevision,
        search,
    )
    admin_filtered = base_filtered.copy()
    rem_filtered = base_filtered.copy()

    if isinstance(date_range, tuple) and len(date_range) == 2 and all(date_range):
        selected_start, selected_end = pd.to_datetime(date_range[0]), pd.to_datetime(date_range[1])
        admin_filtered = apply_period_filter(base_filtered, selected_start, selected_end, mode="event")
        rem_filtered = apply_period_filter(base_filtered, selected_start, selected_end, mode="overlap")

    if preset == "Ingresos del periodo" and selected_start is not None and selected_end is not None:
        admin_filtered = admin_filtered[admin_filtered["fecha_ingreso"].between(selected_start, selected_end, inclusive="both")]
    elif preset == "Egresos del periodo" and selected_start is not None and selected_end is not None:
        admin_filtered = admin_filtered[admin_filtered["fecha_egreso"].between(selected_start, selected_end, inclusive="both")]

    return admin_filtered, rem_filtered, selected_start, selected_end


# ---------------------------------------------------------------------------
# Resolution persistence
# ---------------------------------------------------------------------------

def append_resolution(
    queue_item_id: str,
    queue_type: str,
    entity_id: str,
    action: str,
    resolved_value: str = "",
    resolved_by: str = "admin_dashboard",
    notes: str = "",
) -> None:
    """Append a resolution row to manual_resolution.csv (creates file + header if needed)."""
    RESOLUTION_PATH.parent.mkdir(parents=True, exist_ok=True)
    write_header = not RESOLUTION_PATH.exists() or RESOLUTION_PATH.stat().st_size == 0
    row = {
        "resolved_at": datetime.utcnow().isoformat(),
        "queue_item_id": queue_item_id,
        "queue_type": queue_type,
        "entity_id": entity_id,
        "action": action,
        "resolved_value": resolved_value,
        "resolved_by": resolved_by,
        "notes": notes,
    }
    with open(RESOLUTION_PATH, "a", newline="", encoding="utf-8") as fh:
        writer = csv.DictWriter(fh, fieldnames=RESOLUTION_COLUMNS)
        if write_header:
            writer.writeheader()
        writer.writerow(row)


# ---------------------------------------------------------------------------
# Render functions
# ---------------------------------------------------------------------------

def render_admin_header(df: pd.DataFrame) -> None:
    ingresos = int(df["fecha_ingreso"].notna().sum())
    egresos = int(df["fecha_egreso"].notna().sum())
    activos = int(df["estado"].eq("ACTIVO").sum())
    pacientes = int(df["patient_id"].nunique())
    mediana = df["estadia_util"].dropna().median()
    c1, c2, c3, c4, c5 = st.columns(5)
    c1.metric("Hospitalizaciones", len(df))
    c2.metric("Pacientes", pacientes)
    c3.metric("Ingresos", ingresos)
    c4.metric("Egresos", egresos)
    c5.metric("Activos / mediana", f"{activos} / {mediana:.1f} d" if pd.notna(mediana) else f"{activos} / s-d")


def render_admin_summary(df: pd.DataFrame) -> None:
    st.subheader("Resumen Administrativo")
    render_admin_header(df)
    col1, col2 = st.columns([1.3, 1])
    with col1:
        monthly = df.dropna(subset=["activity_month"]).groupby("activity_month").size().sort_index()
        st.caption("Actividad mensual")
        st.line_chart(monthly)
    with col2:
        top_diag = df["diagnostico_principal"].fillna("SIN_DIAGNOSTICO").value_counts().head(12).sort_values(ascending=True)
        st.caption("Diagnosticos principales")
        st.bar_chart(top_diag)


def render_admin_hospitalizations(df: pd.DataFrame) -> None:
    st.subheader("Hospitalizaciones")
    tabs = st.tabs(["Todas", "Ingresadas", "Egresadas", "Activas"])
    views = {
        "Todas": df,
        "Ingresadas": df[df["fecha_ingreso"].notna()],
        "Egresadas": df[df["fecha_egreso"].notna()],
        "Activas": df[df["estado"].eq("ACTIVO")],
    }
    columns = [
        "stay_id",
        "nombre_completo",
        "rut",
        "sexo_resuelto",
        "edad_reportada",
        "estado",
        "fecha_ingreso_fmt",
        "fecha_egreso_fmt",
        "estadia_util",
        "servicio_origen",
        "prevision",
        "establecimiento",
        "comuna",
        "diagnostico_principal",
    ]
    present_columns = [c for c in columns if c in df.columns]
    for tab, (title, view) in zip(tabs, views.items()):
        with tab:
            table = view.sort_values(["fecha_ingreso", "fecha_egreso"], ascending=[False, False])[present_columns]
            st.dataframe(table, use_container_width=True, hide_index=True)
            st.download_button(
                f"Descargar {title.lower()}",
                data=table.to_csv(index=False).encode("utf-8"),
                file_name=f"hospitalizaciones_{title.lower()}.csv",
                mime="text/csv",
                key=f"download_{title}",
            )


def render_admin_patients(stays: pd.DataFrame, patients: pd.DataFrame) -> None:
    st.subheader("Pacientes")
    cols_to_show = [
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
    ]
    present = [c for c in cols_to_show if c in patients.columns]
    st.dataframe(
        patients[present].sort_values(
            ["total_hospitalizaciones", "nombre_completo"], ascending=[False, True]
        ),
        use_container_width=True,
        hide_index=True,
    )


def render_admin_rem(df: pd.DataFrame, start: pd.Timestamp | None, end: pd.Timestamp | None) -> None:
    st.subheader("REM A21 / C.1")
    sexo, edad, origen, metadata = build_rem_c11(df, start, end)
    detail_df = build_rem_detail_dataset(df, start, end)
    totals = metadata["totals"]
    st.info(
        f"Periodo analizado: {metadata['start'].date() if metadata['start'] is not None else 's/d'} a "
        f"{metadata['end'].date() if metadata['end'] is not None else 's/d'}"
    )
    st.caption("En este tab el rango temporal se aplica por solapamiento del episodio con el periodo, porque el REM no usa la misma semantica de los listados administrativos.")
    c1, c2, c3, c4, c5, c6 = st.columns(6)
    c1.metric("Ingresos", totals["ingresos"])
    c2.metric("Personas atendidas", totals["personas_atendidas"])
    c3.metric("Dias persona", totals["dias_persona"])
    c4.metric("Altas", totals["altas"])
    c5.metric("Reingresos a hospitalizacion", totals["reingresos_hospitalizacion"])
    c6.metric("Fallecidos inferidos", totals["fallecidos_total_inferidos"])
    with st.expander("Como se calcula cada indicador REM C.1.1", expanded=False):
        methodology = pd.DataFrame(
            [
                {"indicador": "Ingresos", "calculo": "Conteo de estadias con `fecha_ingreso` dentro del rango.", "semantica": "Observado"},
                {"indicador": "Personas atendidas", "calculo": "Pacientes unicos con al menos un dia de solapamiento entre estadia y rango.", "semantica": "Inferido desde vigencia de la estadia"},
                {"indicador": "Dias persona", "calculo": "Suma de `overlap_days` por estadia dentro del rango.", "semantica": "Inferido desde fechas"},
                {"indicador": "Altas", "calculo": "Estadias con `fecha_egreso` en rango y `motivo_egreso` clasificado como alta.", "semantica": "Observado + normalizado"},
                {"indicador": "Reingresos a hospitalizacion", "calculo": "Estadias con `fecha_egreso` en rango y `motivo_egreso` con patron textual de rehospitalizacion/reingreso.", "semantica": "Inferido desde texto"},
                {"indicador": "Fallecidos inferidos", "calculo": "Estadias con `fecha_egreso` en rango y `motivo_egreso` con patron de fallecimiento.", "semantica": "Inferido desde texto"},
                {"indicador": "Fallecidos esperados / no esperados", "calculo": "Subconjuntos de fallecidos con `fallecido_clasificacion` cargada manualmente en la capa canónica.", "semantica": "Manual estructurado"},
            ]
        )
        st.dataframe(methodology, use_container_width=True, hide_index=True)
    tab1, tab2, tab3, tab4 = st.tabs(["Totales", "Sexo", "Rango Etario", "Origen"])
    with tab1:
        total_table = pd.DataFrame(
            [
                {"componente": "ingresos", "total": totals["ingresos"]},
                {"componente": "personas_atendidas", "total": totals["personas_atendidas"]},
                {"componente": "dias_persona", "total": totals["dias_persona"]},
                {"componente": "altas", "total": totals["altas"]},
                {"componente": "fallecidos_esperados", "total": totals["fallecidos_esperados"]},
                {"componente": "fallecidos_no_esperados", "total": totals["fallecidos_no_esperados"]},
                {"componente": "reingresos_hospitalizacion", "total": totals["reingresos_hospitalizacion"]},
            ]
        )
        st.dataframe(total_table, use_container_width=True, hide_index=True)
    with tab2:
        st.dataframe(sexo, use_container_width=True, hide_index=True)
    with tab3:
        st.dataframe(edad, use_container_width=True, hide_index=True)
    with tab4:
        st.dataframe(origen, use_container_width=True, hide_index=True)

    st.markdown("---")
    st.caption("Verificacion nominal del REM")
    component = st.selectbox(
        "Componente REM a revisar",
        [
            "ingresos",
            "personas_atendidas",
            "dias_persona",
            "altas",
            "reingresos_hospitalizacion",
            "fallecidos_total_inferidos",
            "fallecidos_esperados",
            "fallecidos_no_esperados",
        ],
        index=0,
    )
    detail_view = rem_nominal_subset(detail_df, component)

    detail_columns = [
        "stay_id",
        "patient_id",
        "nombre_completo",
        "rut",
        "sexo_resuelto",
        "edad_reportada",
        "fecha_ingreso_fmt",
        "fecha_egreso_fmt",
        "overlap_days",
        "servicio_origen",
        "prevision",
        "comuna",
        "establecimiento",
        "diagnostico_principal",
        "motivo_egreso",
        "fallecido_clasificacion",
        "origen_derivacion_rem",
    ]
    present_columns = [column for column in detail_columns if column in detail_view.columns]
    st.caption(f"Listado nominal usado para calcular: {component}")
    st.dataframe(
        detail_view.sort_values(["fecha_ingreso", "fecha_egreso"], ascending=[False, False])[present_columns],
        use_container_width=True,
        hide_index=True,
    )
    st.download_button(
        f"Descargar detalle REM: {component}",
        data=detail_view[present_columns].to_csv(index=False).encode("utf-8"),
        file_name=f"rem_{component}.csv",
        mime="text/csv",
        key=f"download_rem_{component}",
    )


def render_admin_territory(df: pd.DataFrame, establishments: pd.DataFrame, localities: pd.DataFrame) -> None:
    st.subheader("Territorio y Establecimientos")
    c1, c2, c3 = st.columns(3)
    c1.metric("Estadias con DEIS", int(df["codigo_deis"].fillna("").ne("").sum()))
    c2.metric("Localidades con coordenadas", int(localities["latitud"].notna().sum()) if not localities.empty and "latitud" in localities.columns else 0)
    c3.metric("Comunas activas", int(df["comuna"].fillna("").replace("", pd.NA).dropna().nunique()))
    map_df = df.copy()
    if {"latitud", "longitud"}.issubset(map_df.columns):
        map_df["latitud"] = pd.to_numeric(map_df["latitud"], errors="coerce")
        map_df["longitud"] = pd.to_numeric(map_df["longitud"], errors="coerce")
        map_df = map_df.dropna(subset=["latitud", "longitud"])
    if not map_df.empty and "latitud" in map_df.columns and "longitud" in map_df.columns:
        render_pydeck_map(
            map_df,
            lat_col="latitud",
            lon_col="longitud",
            tooltip_fields=["nombre_completo", "establecimiento", "localidad", "comuna"],
            key="admin_territory_map",
            radius=650,
        )
    if not establishments.empty:
        est_cols = [c for c in ["codigo_deis", "nombre_oficial", "comuna", "tipo_establecimiento"] if c in establishments.columns]
        st.dataframe(
            establishments[est_cols].sort_values([c for c in ["comuna", "nombre_oficial"] if c in establishments.columns]),
            use_container_width=True,
            hide_index=True,
        )


# ---------------------------------------------------------------------------
# Pipeline Health tab (Task 9)
# ---------------------------------------------------------------------------

def render_pipeline_health() -> None:
    st.subheader("Salud del Pipeline")

    st.markdown(
        "Esta seccion muestra el estado general del proceso de datos (pipeline) que alimenta "
        "este dashboard. El pipeline toma los datos crudos de las planillas, los limpia, "
        "normaliza y cruza para producir los registros que ves en las demas pestanas. "
        "Aqui puedes verificar si el proceso se ejecuto correctamente y si hay problemas "
        "de calidad de datos que requieran atencion."
    )

    audit = load_audit_data()
    ph = audit.get("pipeline_health", pd.DataFrame())
    cg = audit.get("coverage_gaps", pd.DataFrame())
    qi = audit.get("quality_issues", pd.DataFrame())

    if ph.empty:
        st.warning("No hay datos de salud del pipeline disponibles.")
        return

    latest = ph.iloc[-1]
    status = str(latest.get("health_status", "unknown"))
    color_map = {"green": "#22c55e", "yellow": "#eab308", "red": "#ef4444"}
    label_map = {"green": "Saludable", "yellow": "Con advertencias", "red": "Critico"}
    reason_map = {
        "green": "Todos los indicadores estan dentro de los rangos esperados. No se detectaron problemas criticos.",
        "yellow": "Se detectaron advertencias menores: puede haber brechas de cobertura o issues de calidad que conviene revisar, pero los datos principales son confiables.",
        "red": "Se detectaron problemas criticos que afectan la confiabilidad de los datos. Revisa los issues abiertos y la cola de revision antes de usar los indicadores.",
    }
    sem_color = color_map.get(status, "#94a3b8")
    sem_label = label_map.get(status, "Desconocido")
    sem_reason = reason_map.get(status, "No se pudo determinar el estado del pipeline.")

    # Semaphore
    st.markdown(
        f"""
        <div style="display:flex;align-items:center;gap:1rem;padding:1rem;border-radius:1rem;
                     background:linear-gradient(135deg,rgba(248,250,249,0.98),rgba(255,255,255,0.98));
                     border:1px solid rgba(16,74,61,0.10);margin-bottom:1rem;">
            <div style="width:48px;height:48px;border-radius:50%;background:{sem_color};
                        box-shadow:0 0 12px {sem_color};flex-shrink:0;"></div>
            <div>
                <div style="font-size:1.3rem;font-weight:700;color:#14342b;">{sem_label}</div>
                <div style="font-size:0.85rem;color:#3d5a50;margin-top:0.2rem;">
                    {sem_reason}
                </div>
                <div style="font-size:0.8rem;color:#6b7b75;margin-top:0.3rem;">
                    Ultima ejecucion: {latest.get('run_timestamp', 'N/D')}
                </div>
            </div>
        </div>
        """,
        unsafe_allow_html=True,
    )

    # 8 metric cards with captions
    m1, m2, m3, m4 = st.columns(4)
    stays_total = int(latest.get("stays_total", 0))
    patients_total = int(latest.get("patients_total", 0))
    stays_egreso = int(latest.get("stays_with_egreso", 0))
    stays_estab = int(latest.get("stays_with_establishment", 0))
    pct_egreso = f"{stays_egreso / stays_total * 100:.1f}%" if stays_total > 0 else "N/D"
    pct_estab = f"{stays_estab / stays_total * 100:.1f}%" if stays_total > 0 else "N/D"

    m1.metric("Estadias", stays_total)
    m1.caption("Total de hospitalizaciones registradas en el sistema.")
    m2.metric("Pacientes", patients_total)
    m2.caption("Pacientes unicos identificados (por RUT o ID interno).")
    m3.metric("% con egreso", pct_egreso)
    m3.caption("Porcentaje de estadias que tienen fecha de alta registrada.")
    m4.metric("% con establecimiento", pct_estab)
    m4.caption("Porcentaje de estadias asociadas a un establecimiento DEIS.")

    m5, m6, m7, m8 = st.columns(4)
    m5.metric("Issues abiertos", int(latest.get("issues_open", 0)))
    m5.caption("Problemas de calidad de datos detectados y aun no resueltos.")
    m6.metric("Cola de revision", int(latest.get("review_queue_pending", 0)))
    m6.caption("Registros que necesitan revision manual en la pestana Revision.")
    m7.metric("Brechas de cobertura", int(latest.get("coverage_gaps_detected", 0)))
    m7.caption("Meses donde los ingresos cayeron significativamente respecto al promedio.")
    m8.metric("Candidatos duplicados", int(latest.get("duplicate_candidates", 0)))
    m8.caption("Pares de registros que podrian ser el mismo paciente u hospitalizacion.")

    # Coverage chart
    if not cg.empty:
        st.markdown("---")
        st.subheader("Brechas de cobertura mensual")
        st.markdown(
            "Esto compara cuantos ingresos hubo cada mes contra el promedio de los 6 meses "
            "anteriores. Si un mes tiene menos del 70% del promedio, se marca como brecha. "
            "Las brechas pueden indicar que faltan datos en la planilla de ese mes, o que "
            "hubo una caida real en la actividad."
        )
        metrics_available = sorted(cg["metric"].unique()) if "metric" in cg.columns else []
        selected_metric = st.selectbox("Metrica de cobertura", metrics_available, index=0, key="cg_metric") if metrics_available else None
        if selected_metric:
            subset = cg[cg["metric"] == selected_metric].sort_values("month")
            chart_data = subset.set_index("month")[["observed", "expected"]]
            st.line_chart(chart_data)
            gap_rows = subset[subset["gap_flag"] == True]  # noqa: E712
            if not gap_rows.empty:
                st.warning(f"{len(gap_rows)} mes(es) con brecha detectada para '{selected_metric}'.")

    # Issue breakdown
    if not qi.empty and "issue_type" in qi.columns:
        st.markdown("---")
        st.subheader("Problemas de calidad de datos")
        st.markdown(
            "Estos son problemas de datos que requieren atencion. Cada tipo de problema "
            "tiene un significado especifico que se explica a continuacion."
        )
        issue_counts = qi["issue_type"].value_counts()
        st.bar_chart(issue_counts)

        # Explanatory table of issue types
        issue_rows = []
        for issue_type, count in issue_counts.items():
            description = ISSUE_DESCRIPTIONS.get(str(issue_type), str(issue_type))
            issue_rows.append({"Tipo": str(issue_type), "Descripcion": description, "Cantidad": int(count)})
        if issue_rows:
            st.dataframe(pd.DataFrame(issue_rows), use_container_width=True, hide_index=True)


# ---------------------------------------------------------------------------
# Resolution tab (Tasks 10-11)
# ---------------------------------------------------------------------------

def render_queue_items(rq: pd.DataFrame, queue_type: str) -> None:
    """Render review queue items for a given queue_type with action buttons and pagination."""
    subset = rq[rq["queue_type"] == queue_type] if not rq.empty and "queue_type" in rq.columns else pd.DataFrame()
    if subset.empty:
        st.info(f"No hay items pendientes de tipo '{queue_type}'.")
        return

    total_items = len(subset)
    page_key = f"page_{queue_type}"
    if page_key not in st.session_state:
        st.session_state[page_key] = PAGINATION_SIZE

    visible_limit = st.session_state[page_key]
    visible_subset = subset.head(visible_limit)

    st.caption(f"Mostrando {min(visible_limit, total_items)} de {total_items} items")

    for idx, row in visible_subset.iterrows():
        item_id = str(row.get("queue_item_id", idx))
        entity_id = str(row.get("entity_id", ""))
        patient_name = str(row.get("patient_name", ""))
        patient_rut = str(row.get("patient_rut", ""))
        summary = str(row.get("summary", ""))
        candidates = str(row.get("candidate_ids", ""))
        scores = str(row.get("candidate_scores", ""))
        priority = str(row.get("priority", ""))

        with st.expander(f"{patient_name} ({patient_rut}) - {summary[:80]}", expanded=False):
            st.markdown(f"**Item:** {item_id} | **Entidad:** {entity_id} | **Prioridad:** {priority}")
            if candidates:
                st.markdown(f"**Candidatos:** {candidates}")
            if scores:
                st.markdown(f"**Scores:** {scores}")

            if queue_type in ("identity", "establishment"):
                with st.form(key=f"form_{item_id}"):
                    st.caption(f"Resolucion inline para {queue_type}")
                    resolved_value = st.text_input("Valor resuelto", value="", key=f"val_{item_id}")
                    notes = st.text_input("Notas", value="", key=f"notes_{item_id}")
                    col_a, col_b, col_c = st.columns(3)
                    with col_a:
                        associate = st.form_submit_button("Asociar")
                    with col_b:
                        create = st.form_submit_button("Crear nuevo")
                    with col_c:
                        discard = st.form_submit_button("Descartar")

                    if associate:
                        append_resolution(item_id, queue_type, entity_id, "associate", resolved_value, notes=notes)
                        st.success(f"Resolucion 'asociar' guardada para {item_id}.")
                        st.cache_data.clear()
                    elif create:
                        append_resolution(item_id, queue_type, entity_id, "create", resolved_value, notes=notes)
                        st.success(f"Resolucion 'crear' guardada para {item_id}.")
                        st.cache_data.clear()
                    elif discard:
                        append_resolution(item_id, queue_type, entity_id, "discard", resolved_value, notes=notes)
                        st.success(f"Resolucion 'descartar' guardada para {item_id}.")
                        st.cache_data.clear()
            else:
                col_a, col_b, col_c = st.columns(3)
                with col_a:
                    if st.button("Asociar", key=f"assoc_{item_id}"):
                        append_resolution(item_id, queue_type, entity_id, "associate")
                        st.success(f"Resolucion 'asociar' guardada para {item_id}.")
                        st.cache_data.clear()
                with col_b:
                    if st.button("Crear nuevo", key=f"create_{item_id}"):
                        append_resolution(item_id, queue_type, entity_id, "create")
                        st.success(f"Resolucion 'crear' guardada para {item_id}.")
                        st.cache_data.clear()
                with col_c:
                    if st.button("Descartar", key=f"discard_{item_id}"):
                        append_resolution(item_id, queue_type, entity_id, "discard")
                        st.success(f"Resolucion 'descartar' guardada para {item_id}.")
                        st.cache_data.clear()

    # "Mostrar mas" pagination button
    if visible_limit < total_items:
        if st.button(f"Mostrar mas ({total_items - visible_limit} restantes)", key=f"more_{queue_type}"):
            st.session_state[page_key] = visible_limit + PAGINATION_SIZE
            st.rerun()


def _lookup_entity_data(entity_id: str, entity_type: str, stays: pd.DataFrame, patients: pd.DataFrame) -> dict[str, str]:
    """Look up actual data for a duplicate candidate entity from stays or patients."""
    info: dict[str, str] = {"id": entity_id}
    if entity_type == "patient" and not patients.empty:
        match = patients[patients["patient_id"] == entity_id]
        if not match.empty:
            row = match.iloc[0]
            info["nombre"] = str(row.get("nombre_completo", ""))
            info["rut"] = str(row.get("rut", ""))
            info["sexo"] = str(row.get("sexo", ""))
            info["edad"] = str(row.get("edad_reportada", ""))
            info["comuna"] = str(row.get("comuna", ""))
            return info
    if entity_type == "stay" and not stays.empty:
        match = stays[stays["stay_id"] == entity_id]
        if not match.empty:
            row = match.iloc[0]
            info["nombre"] = str(row.get("nombre_completo", ""))
            info["rut"] = str(row.get("rut", ""))
            info["ingreso"] = str(row.get("fecha_ingreso_fmt", ""))
            info["egreso"] = str(row.get("fecha_egreso_fmt", ""))
            info["establecimiento"] = str(row.get("establecimiento", ""))
            info["diagnostico"] = str(row.get("diagnostico_principal", ""))
            return info
    # Fallback: try both
    if not patients.empty:
        match = patients[patients["patient_id"] == entity_id]
        if not match.empty:
            row = match.iloc[0]
            info["nombre"] = str(row.get("nombre_completo", ""))
            info["rut"] = str(row.get("rut", ""))
            return info
    if not stays.empty:
        match = stays[stays["stay_id"] == entity_id]
        if not match.empty:
            row = match.iloc[0]
            info["nombre"] = str(row.get("nombre_completo", ""))
            info["rut"] = str(row.get("rut", ""))
            return info
    return info


def render_duplicate_items(dc: pd.DataFrame, stays: pd.DataFrame, patients: pd.DataFrame) -> None:
    """Render duplicate candidate pairs with side-by-side comparison and action buttons."""
    if dc.empty:
        st.info("No hay candidatos duplicados pendientes.")
        return

    unreviewed = dc[dc["reviewed"] == False] if "reviewed" in dc.columns else dc  # noqa: E712
    if unreviewed.empty:
        st.success("Todos los candidatos duplicados han sido revisados.")
        return

    total_dupes = len(unreviewed)
    dupe_page_key = "page_duplicates"
    if dupe_page_key not in st.session_state:
        st.session_state[dupe_page_key] = PAGINATION_SIZE

    visible_limit = st.session_state[dupe_page_key]
    visible_dupes = unreviewed.head(visible_limit)

    st.caption(f"Mostrando {min(visible_limit, total_dupes)} de {total_dupes} pares")

    for idx, row in visible_dupes.iterrows():
        cand_id = str(row.get("candidate_id", idx))
        entity_a = str(row.get("entity_a_id", ""))
        entity_b = str(row.get("entity_b_id", ""))
        match_reason = str(row.get("match_reason", ""))
        confidence = row.get("confidence", "")
        entity_type = str(row.get("entity_type", ""))

        # Look up actual data for both entities
        data_a = _lookup_entity_data(entity_a, entity_type, stays, patients)
        data_b = _lookup_entity_data(entity_b, entity_type, stays, patients)

        label_a_name = data_a.get("nombre", entity_a)
        label_b_name = data_b.get("nombre", entity_b)
        expander_label = f"{label_a_name} vs {label_b_name} ({match_reason})"

        with st.expander(expander_label, expanded=False):
            col_left, col_right = st.columns(2)
            with col_left:
                st.markdown("**Entidad A**")
                for k, v in data_a.items():
                    if v and v != "nan":
                        st.markdown(f"- **{k}:** {v}")
            with col_right:
                st.markdown("**Entidad B**")
                for k, v in data_b.items():
                    if v and v != "nan":
                        st.markdown(f"- **{k}:** {v}")
            st.markdown(f"**Razon de coincidencia:** {match_reason} | **Confianza:** {confidence}")

            col_merge, col_not_dup = st.columns(2)
            with col_merge:
                if st.button("Fusionar", key=f"merge_{cand_id}"):
                    append_resolution(cand_id, "duplicate", f"{entity_a}|{entity_b}", "merge")
                    st.success(f"Resolucion 'fusionar' guardada para {cand_id}.")
                    st.cache_data.clear()
            with col_not_dup:
                if st.button("No es duplicado", key=f"notdup_{cand_id}"):
                    append_resolution(cand_id, "duplicate", f"{entity_a}|{entity_b}", "not_duplicate")
                    st.success(f"Resolucion 'no duplicado' guardada para {cand_id}.")
                    st.cache_data.clear()

    # "Mostrar mas" pagination button for duplicates
    if visible_limit < total_dupes:
        if st.button(f"Mostrar mas ({total_dupes - visible_limit} restantes)", key="more_duplicates"):
            st.session_state[dupe_page_key] = visible_limit + PAGINATION_SIZE
            st.rerun()


def render_resolution_tab(stays: pd.DataFrame, patients: pd.DataFrame) -> None:
    st.subheader("Revision y Resolucion")

    st.markdown(
        "Esta seccion muestra los datos pendientes de revision manual. Las acciones que "
        "tomes aqui se guardan y se aplican en la proxima ejecucion del pipeline."
    )

    audit = load_audit_data()
    rq = audit.get("review_queue", pd.DataFrame())
    dc = audit.get("duplicate_candidates", pd.DataFrame())

    # Determine available queue types
    queue_types = sorted(rq["queue_type"].unique().tolist()) if not rq.empty and "queue_type" in rq.columns else []
    sub_tab_labels = queue_types + (["Duplicados"] if not dc.empty else [])

    if not sub_tab_labels:
        st.info("No hay items de revision ni duplicados pendientes.")
        return

    sub_tabs = st.tabs(sub_tab_labels)
    for i, label in enumerate(sub_tab_labels):
        with sub_tabs[i]:
            if label == "Duplicados":
                st.markdown(
                    "Pares de registros que podrian ser el mismo paciente o la misma "
                    "hospitalizacion registrada dos veces. Revisa cada par y decide si "
                    "fusionar o marcar como no duplicado."
                )
                render_duplicate_items(dc, stays, patients)
            else:
                desc = QUEUE_DESCRIPTIONS.get(label, "")
                if desc:
                    st.markdown(desc)
                render_queue_items(rq, label)

    # Show existing resolutions if file exists
    if RESOLUTION_PATH.exists() and RESOLUTION_PATH.stat().st_size > 0:
        st.markdown("---")
        st.caption("Resoluciones registradas")
        resolutions = pd.read_csv(RESOLUTION_PATH)
        st.dataframe(resolutions, use_container_width=True, hide_index=True)


# ---------------------------------------------------------------------------
# Methodology tab
# ---------------------------------------------------------------------------

def render_admin_methodology() -> None:
    st.subheader("Metodologia")
    st.markdown(
        """
        Este dashboard esta orientado a uso administrativo e institucional. Muestra los
        datos procesados de hospitalizacion domiciliaria (HODOM) para el Servicio de Salud,
        y permite revisar indicadores, detectar problemas de calidad y resolver manualmente
        registros que el pipeline automatico no pudo procesar.
        """
    )

    st.markdown("#### Principios de diseno")
    st.markdown(
        """
        - **Fuente unica de verdad:** todos los datos provienen de la capa canonica, que es el resultado
          del pipeline de procesamiento. No se leen planillas crudas directamente.
        - **Transparencia:** cuando un indicador es inferido desde texto libre o fechas (en lugar de
          ser un dato observado directamente), se declara explicitamente.
        - **Auditabilidad:** cada tab incluye la posibilidad de descargar los datos nominales
          que sustentan cada indicador, para verificacion manual.
        - **Resolucion progresiva:** los problemas de datos se resuelven de forma incremental;
          las decisiones manuales se almacenan y se aplican en la siguiente ejecucion del pipeline.
        """
    )

    st.markdown("#### Flujo del pipeline de datos")
    st.markdown(
        """
        1. **Ingesta:** se toman las planillas Excel/CSV originales (registros de ingresos,
           formularios HODOM, datos de O2, etc.) y se normalizan a un formato intermedio.
        2. **Enriquecimiento:** se cruzan los datos con catalogos de referencia (establecimientos DEIS,
           localidades con coordenadas, comunas) y se resuelven identidades de pacientes por RUT.
        3. **Capa canonica:** se generan los archivos finales que alimentan este dashboard:
           `hospitalization_stay.csv`, `patient_master.csv`, `establishment_reference.csv`, etc.
        4. **Auditoria automatica:** el pipeline detecta problemas de calidad (quality_issue),
           brechas de cobertura (coverage_gap), posibles duplicados (duplicate_candidate) y
           registros que requieren revision manual (review_queue).
        5. **Resolucion manual:** en la pestana "Revision y Resolucion" los administradores
           pueden tomar decisiones sobre los casos ambiguos, que se aplicaran en la proxima ejecucion.
        """
    )

    st.markdown("#### Fuentes de datos por pestana")
    scope = pd.DataFrame(
        [
            {"Pestana": "Resumen", "Fuente principal": "hospitalization_stay (canonical)", "Uso": "Vision general de actividad y diagnosticos principales"},
            {"Pestana": "Hospitalizaciones", "Fuente principal": "hospitalization_stay (canonical)", "Uso": "Listado nominal de estadias con filtros y descarga"},
            {"Pestana": "Pacientes", "Fuente principal": "patient_master (canonical)", "Uso": "Seguimiento de pacientes unicos, hospitalizaciones acumuladas"},
            {"Pestana": "REM A21/C1", "Fuente principal": "hospitalization_stay + reglas de calculo", "Uso": "Estadistica institucional REM con verificacion nominal"},
            {"Pestana": "Territorio", "Fuente principal": "locality_reference + establishment_reference", "Uso": "Mapa de cobertura territorial y establecimientos DEIS"},
            {"Pestana": "Salud del Pipeline", "Fuente principal": "pipeline_health + coverage_gap + quality_issue", "Uso": "Monitoreo de calidad de datos y brechas"},
            {"Pestana": "Revision y Resolucion", "Fuente principal": "review_queue + duplicate_candidate", "Uso": "Resolucion manual de casos ambiguos"},
        ]
    )
    st.dataframe(scope, use_container_width=True, hide_index=True)

    st.markdown("#### Como interpretar cada pestana")
    st.markdown(
        """
        - **Resumen:** ofrece los indicadores clave (hospitalizaciones, pacientes, ingresos, egresos,
          activos) y graficos de tendencia mensual. Util para tener un panorama rapido.
        - **Hospitalizaciones:** permite filtrar y buscar estadias individuales. Usa los filtros del
          sidebar para acotar por periodo, comuna, establecimiento o diagnostico.
        - **Pacientes:** lista todos los pacientes unicos con su historial acumulado. La columna
          "total_hospitalizaciones" indica cuantas estadias tiene cada paciente.
        - **REM A21/C1:** reproduce los indicadores del Registro Estadistico Mensual, desglosados por
          sexo, rango etario y origen de derivacion. Incluye verificacion nominal para cada componente.
        - **Territorio:** mapa interactivo con la ubicacion de las hospitalizaciones y tabla de
          establecimientos DEIS vinculados.
        - **Salud del Pipeline:** semaforo de estado, metricas de completitud y graficos de brechas.
          Si el semaforo esta en rojo, los datos del dashboard pueden no ser confiables.
        - **Revision y Resolucion:** cola de trabajo para resolver manualmente formularios sin asociar,
          altas huerfanas, problemas de identidad, establecimientos no resueltos y posibles duplicados.
        """
    )

    st.markdown("#### Glosario")
    glossary = pd.DataFrame(
        [
            {"Termino": "Estadia", "Definicion": "Un episodio de hospitalizacion domiciliaria, desde el ingreso hasta el alta."},
            {"Termino": "Dias persona", "Definicion": "Suma de dias que cada paciente estuvo hospitalizado dentro del periodo seleccionado (solapamiento)."},
            {"Termino": "Brecha de cobertura", "Definicion": "Un mes donde los ingresos registrados son menores al 70% del promedio de los 6 meses anteriores."},
            {"Termino": "Issue de calidad", "Definicion": "Un problema de datos detectado automaticamente (ej: localidad sin coordenadas, fecha invalida)."},
            {"Termino": "Cola de revision", "Definicion": "Registros que el pipeline no pudo resolver automaticamente y requieren decision humana."},
            {"Termino": "Candidato duplicado", "Definicion": "Par de registros con alta probabilidad de ser el mismo paciente u hospitalizacion."},
            {"Termino": "Codigo DEIS", "Definicion": "Identificador unico de establecimiento de salud asignado por el Departamento de Estadisticas e Informacion de Salud (DEIS)."},
        ]
    )
    st.dataframe(glossary, use_container_width=True, hide_index=True)


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main() -> None:
    st.set_page_config(
        page_title="HODOM Administrativo",
        page_icon=":clipboard:",
        layout="wide",
        initial_sidebar_state="expanded",
    )
    st.markdown(
        """
        <style>
        .block-container {padding-top: 1.1rem; padding-bottom: 2rem; max-width: 1500px;}
        .stApp {
            background:
                radial-gradient(circle at top left, rgba(14,71,58,0.07), transparent 28%),
                radial-gradient(circle at top right, rgba(176,120,44,0.07), transparent 22%),
                linear-gradient(180deg, #f6faf8 0%, #edf3f1 100%);
        }
        section[data-testid="stSidebar"] {
            background: linear-gradient(180deg, #17352d 0%, #1b4338 100%);
            border-right: 1px solid rgba(255,255,255,0.08);
        }
        section[data-testid="stSidebar"] label,
        section[data-testid="stSidebar"] p,
        section[data-testid="stSidebar"] h1,
        section[data-testid="stSidebar"] h2,
        section[data-testid="stSidebar"] h3,
        section[data-testid="stSidebar"] [data-testid="stMarkdownContainer"],
        section[data-testid="stSidebar"] [data-testid="stCaptionContainer"] {
            color: #f2f7f5 !important;
        }
        section[data-testid="stSidebar"] input,
        section[data-testid="stSidebar"] textarea,
        section[data-testid="stSidebar"] [data-baseweb="select"] *,
        section[data-testid="stSidebar"] [data-testid="stDateInputField"] * {
            color: #14342b !important;
            -webkit-text-fill-color: #14342b !important;
        }
        section[data-testid="stSidebar"] [data-baseweb="select"] > div,
        section[data-testid="stSidebar"] input,
        section[data-testid="stSidebar"] textarea {
            background: rgba(255,255,255,0.92) !important;
            border: 1px solid rgba(255,255,255,0.14) !important;
        }
        [data-testid="stTabs"] button[role="tab"] {
            border-radius: 999px; padding: 0.45rem 0.9rem; border: 1px solid rgba(20,52,43,0.08);
            background: rgba(255,255,255,0.6); margin-right: 0.25rem;
        }
        [data-testid="stTabs"] button[role="tab"][aria-selected="true"] {
            background: #103e33; color: white; border-color: #103e33;
        }
        .stMetric {
            background: linear-gradient(180deg, rgba(248,250,249,0.98) 0%, rgba(255,255,255,0.98) 100%);
            border: 1px solid rgba(16,74,61,0.10); padding: 0.7rem 0.85rem; border-radius: 1rem;
            box-shadow: 0 12px 30px rgba(17,48,40,0.05);
        }
        </style>
        """,
        unsafe_allow_html=True,
    )
    st.title("HODOM Administrativo")
    st.caption("Dashboard institucional para hospitalizaciones domiciliarias, pacientes, indicadores y REM.")

    try:
        core = load_core_data()
    except FileNotFoundError as exc:
        st.error(str(exc))
        st.stop()

    filtered, rem_filtered, start, end = filter_admin_data(core["stays"], core)
    if filtered.empty:
        st.warning("Los filtros dejaron el conjunto vacio.")
        st.stop()

    overview_tab, hosp_tab, patient_tab, rem_tab, territory_tab, pipeline_tab, resolution_tab, methodology_tab = st.tabs(
        ["Resumen", "Hospitalizaciones", "Pacientes", "REM A21/C1", "Territorio", "Salud del Pipeline", "Revision y Resolucion", "Metodologia"]
    )
    with overview_tab:
        render_admin_summary(filtered)
    with hosp_tab:
        render_admin_hospitalizations(filtered)
    with patient_tab:
        render_admin_patients(filtered, core["patients"])
    with rem_tab:
        render_admin_rem(rem_filtered, start, end)
    with territory_tab:
        render_admin_territory(filtered, core["establishments"], core["localities"])
    with pipeline_tab:
        render_pipeline_health()
    with resolution_tab:
        render_resolution_tab(core["stays"], core["patients"])
    with methodology_tab:
        render_admin_methodology()


if __name__ == "__main__":
    main()
