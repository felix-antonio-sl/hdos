from __future__ import annotations

from pathlib import Path

import pandas as pd
import pydeck as pdk
import streamlit as st


REPO_DIR = Path(__file__).resolve().parents[1]
ENRICHED_DIR = REPO_DIR / "output" / "spreadsheet" / "enriched"
INTERMEDIATE_DIR = REPO_DIR / "output" / "spreadsheet" / "intermediate"
MANUAL_DIR = REPO_DIR / "input" / "manual"

ORIGIN_CATEGORY_ORDER = ["APS", "urgencia", "hospitalizacion", "ambulatorio", "ley_urgencia", "UGCC", "sin_inferencia"]
AGE_CATEGORY_ORDER = ["<15", "15-19", "20-59", ">=60", "SIN_RANGO"]
SEX_CATEGORY_ORDER = ["femenino", "masculino", "sin_sexo"]


def read_csv(name: str) -> pd.DataFrame:
    data_dir = ENRICHED_DIR if (ENRICHED_DIR / "episode_master.csv").exists() else INTERMEDIATE_DIR
    path = data_dir / name
    if not path.exists():
        raise FileNotFoundError(f"No existe el archivo requerido: {path}")
    return pd.read_csv(path)


def read_csv_optional(name: str, *, prefer_enriched: bool = True) -> pd.DataFrame:
    candidates = []
    if prefer_enriched:
        candidates.extend([ENRICHED_DIR / name, INTERMEDIATE_DIR / name])
    else:
        candidates.extend([INTERMEDIATE_DIR / name, ENRICHED_DIR / name])
    for path in candidates:
        if path.exists():
            return pd.read_csv(path)
    return pd.DataFrame()


def read_manual_csv(name: str) -> pd.DataFrame:
    path = MANUAL_DIR / name
    if path.exists():
        return pd.read_csv(path)
    return pd.DataFrame()


def write_manual_csv(name: str, df: pd.DataFrame) -> Path:
    MANUAL_DIR.mkdir(parents=True, exist_ok=True)
    path = MANUAL_DIR / name
    df.to_csv(path, index=False)
    return path


def merge_existing_reviews(source: pd.DataFrame, existing: pd.DataFrame, key: str, editable_columns: list[str]) -> pd.DataFrame:
    if source.empty:
        return source
    merged = source.copy()
    if existing.empty or key not in existing.columns:
        for column in editable_columns:
            if column not in merged.columns:
                merged[column] = ""
        return merged
    existing = existing[[col for col in [key, *editable_columns] if col in existing.columns]].drop_duplicates(subset=[key], keep="last")
    merged = merged.merge(existing, on=key, how="left", suffixes=("", "_review"))
    for column in editable_columns:
        review_col = f"{column}_review"
        if review_col in merged.columns:
            merged[column] = merged[review_col].combine_first(merged.get(column))
            merged = merged.drop(columns=[review_col])
        elif column not in merged.columns:
            merged[column] = ""
    return merged


@st.cache_data(show_spinner=False)
def load_data() -> dict[str, pd.DataFrame]:
    enriched_mode = (ENRICHED_DIR / "episode_master.csv").exists()

    episodes = read_csv("episode_master.csv" if enriched_mode else "episode.csv")
    patients = read_csv("patient_master.csv")
    quality = read_csv("data_quality_issue.csv")
    catalogs = read_csv_optional("catalog_value.csv", prefer_enriched=False)

    requirements = read_csv_optional("episode_care_requirement.csv", prefer_enriched=False) if not enriched_mode else pd.DataFrame()
    professional_needs = read_csv_optional("episode_professional_need.csv", prefer_enriched=False) if not enriched_mode else pd.DataFrame()
    diagnoses = read_csv_optional("episode_diagnosis.csv", prefer_enriched=False) if not enriched_mode else pd.DataFrame()
    source_links = read_csv_optional("episode_source_link.csv", prefer_enriched=False) if not enriched_mode else pd.DataFrame()

    episode_requests = read_csv_optional("episode_request.csv") if enriched_mode else pd.DataFrame()
    episode_discharges = read_csv_optional("episode_discharge.csv") if enriched_mode else pd.DataFrame()
    rescue_candidates = read_csv_optional("episode_rescue_candidate.csv") if enriched_mode else pd.DataFrame()
    field_provenance = read_csv_optional("field_provenance.csv") if enriched_mode else pd.DataFrame()
    match_review_queue = read_csv_optional("match_review_queue.csv") if enriched_mode else pd.DataFrame()
    identity_review_queue = read_csv_optional("identity_review_queue.csv") if enriched_mode else pd.DataFrame()
    establishments = read_csv_optional("establishment_reference.csv") if enriched_mode else pd.DataFrame()
    localities = read_csv_optional("locality_reference.csv") if enriched_mode else pd.DataFrame()
    address_resolution = read_csv_optional("address_resolution.csv") if enriched_mode else pd.DataFrame()
    reconciliation = read_csv_optional("reconciliation_report.csv") if enriched_mode else pd.DataFrame()

    episodes["fecha_ingreso"] = pd.to_datetime(episodes["fecha_ingreso"], errors="coerce")
    episodes["fecha_egreso"] = pd.to_datetime(episodes["fecha_egreso"], errors="coerce")
    episodes["activity_date"] = episodes["fecha_ingreso"].combine_first(episodes["fecha_egreso"])
    episodes["activity_month"] = episodes["activity_date"].dt.to_period("M").astype("string")
    episodes["dias_estadia_reportados"] = pd.to_numeric(episodes["dias_estadia_reportados"], errors="coerce")
    episodes["dias_estadia_calculados"] = pd.to_numeric(episodes["dias_estadia_calculados"], errors="coerce")
    episodes["duplicate_count"] = pd.to_numeric(episodes["duplicate_count"], errors="coerce").fillna(1)
    episodes["estadia_util"] = episodes["dias_estadia_calculados"].combine_first(episodes["dias_estadia_reportados"])
    episodes["estado"] = episodes["estado"].fillna("SIN_ESTADO")
    episodes["tipo_flujo"] = episodes["tipo_flujo"].fillna("SIN_FLUJO")
    episodes["episode_status_quality"] = episodes["episode_status_quality"].fillna("SIN_CLASIFICAR")
    if "resolution_status" not in episodes.columns:
        episodes["resolution_status"] = "AUTO"
    if "episode_origin" not in episodes.columns:
        episodes["episode_origin"] = "raw"
    if "match_status" not in episodes.columns:
        episodes["match_status"] = "baseline"
    if "match_score" not in episodes.columns:
        episodes["match_score"] = pd.NA
    else:
        episodes["match_score"] = pd.to_numeric(episodes["match_score"], errors="coerce")
    if "requested_at" not in episodes.columns:
        episodes["requested_at"] = ""
    episodes["requested_at"] = pd.to_datetime(episodes["requested_at"], errors="coerce")

    patients["fecha_nacimiento_date"] = pd.to_datetime(patients["fecha_nacimiento_date"], errors="coerce")
    patients["edad_reportada"] = pd.to_numeric(patients["edad_reportada"], errors="coerce")
    patients["rut_valido"] = patients["rut_valido"].astype(str)
    if "episode_count" in patients.columns:
        patients["episode_count"] = pd.to_numeric(patients["episode_count"], errors="coerce").fillna(0).astype(int)

    if not address_resolution.empty:
        address_resolution["establishment_match_confidence"] = pd.to_numeric(
            address_resolution["establishment_match_confidence"], errors="coerce"
        )
        address_resolution["locality_match_confidence"] = pd.to_numeric(
            address_resolution["locality_match_confidence"], errors="coerce"
        )

    if not localities.empty:
        localities["latitud"] = pd.to_numeric(localities["latitud"], errors="coerce")
        localities["longitud"] = pd.to_numeric(localities["longitud"], errors="coerce")

    if not rescue_candidates.empty:
        for col in ["requested_at", "fecha_ingreso", "fecha_egreso"]:
            rescue_candidates[col] = pd.to_datetime(rescue_candidates[col], errors="coerce")

    if not episode_requests.empty:
        episode_requests["submission_timestamp"] = pd.to_datetime(
            episode_requests["submission_timestamp"], errors="coerce"
        )
        episode_requests["gestora_norm"] = episode_requests["gestora"].fillna("").map(
            lambda value: " ".join(str(value).strip().upper().split())
        )

    episodes["gestora_norm"] = episodes["gestora"].fillna("").map(
        lambda value: " ".join(str(value).strip().upper().split())
    )

    patient_lookup = patients[
        [
            "patient_id",
            "nombre_completo",
            "sexo",
            "edad_reportada",
            "fecha_nacimiento_date",
            "comuna",
            "cesfam",
            "rut",
            "rut_valido",
            "identity_resolution_status",
            "patient_key_strategy",
        ]
    ].rename(
        columns={
            "nombre_completo": "nombre_completo_patient",
            "sexo": "sexo_patient",
            "edad_reportada": "edad_reportada_patient",
            "fecha_nacimiento_date": "fecha_nacimiento_patient",
            "comuna": "comuna_patient",
            "cesfam": "cesfam_patient",
            "rut": "rut_patient",
            "rut_valido": "rut_valido_patient",
            "identity_resolution_status": "identity_resolution_status_patient",
            "patient_key_strategy": "patient_key_strategy_patient",
        }
    )

    merged = episodes.merge(patient_lookup, on="patient_id", how="left")

    merged["nombre_completo"] = merged["nombre_completo_patient"]
    merged["rut"] = merged["rut_patient"]
    merged["rut_valido"] = merged["rut_valido_patient"]
    merged["sexo_resuelto"] = merged["sexo_patient"].fillna("")
    merged["edad_reportada"] = merged["edad_reportada_patient"]
    merged["fecha_nacimiento_date"] = merged["fecha_nacimiento_patient"]
    merged["identity_resolution_status"] = merged["identity_resolution_status_patient"]
    merged["patient_key_strategy"] = merged["patient_key_strategy_patient"]
    merged["comuna_resuelta"] = merged["comuna_patient"].fillna("")
    merged["cesfam_resuelto"] = merged["cesfam_patient"].fillna("")

    if not address_resolution.empty:
        merged = merged.merge(
            address_resolution.rename(
                columns={
                    "resolved_establishment_id": "resolved_establishment_id",
                    "resolved_locality_id": "resolved_locality_id",
                    "resolution_status": "address_resolution_status",
                }
            )[
                [
                    "patient_id",
                    "raw_address",
                    "raw_comuna",
                    "raw_cesfam",
                    "resolved_establishment_id",
                    "resolved_locality_id",
                    "establishment_match_confidence",
                    "locality_match_confidence",
                    "address_resolution_status",
                ]
            ],
            on="patient_id",
            how="left",
        )
    else:
        merged["resolved_establishment_id"] = ""
        merged["resolved_locality_id"] = ""
        merged["address_resolution_status"] = ""
        merged["establishment_match_confidence"] = pd.NA
        merged["locality_match_confidence"] = pd.NA

    if not establishments.empty:
        merged = merged.merge(
            establishments.rename(
                columns={
                    "establishment_id": "resolved_establishment_id",
                    "codigo_deis": "codigo_deis_resuelto",
                    "nombre_oficial": "establecimiento_resuelto",
                    "comuna": "establecimiento_comuna",
                }
            )[
                [
                    "resolved_establishment_id",
                    "codigo_deis_resuelto",
                    "establecimiento_resuelto",
                    "establecimiento_comuna",
                ]
            ],
            on="resolved_establishment_id",
            how="left",
        )
    else:
        merged["codigo_deis_resuelto"] = ""
        merged["establecimiento_resuelto"] = ""
        merged["establecimiento_comuna"] = ""

    if not localities.empty:
        merged = merged.merge(
            localities.rename(
                columns={
                    "locality_id": "resolved_locality_id",
                    "nombre_oficial": "localidad_resuelta",
                    "provincia": "provincia_resuelta",
                    "latitud": "localidad_latitud",
                    "longitud": "localidad_longitud",
                    "source_priority": "locality_source_priority",
                }
            )[
                [
                    "resolved_locality_id",
                    "localidad_resuelta",
                    "provincia_resuelta",
                    "region",
                    "territory_type",
                    "localidad_latitud",
                    "localidad_longitud",
                    "locality_source_priority",
                ]
            ],
            on="resolved_locality_id",
            how="left",
        )
    else:
        merged["localidad_resuelta"] = ""
        merged["provincia_resuelta"] = ""
        merged["localidad_latitud"] = pd.NA
        merged["localidad_longitud"] = pd.NA
        merged["locality_source_priority"] = ""

    merged["rango_etario"] = pd.cut(
        merged["edad_reportada"],
        bins=[-1, 14, 19, 59, 150],
        labels=["<15", "15-19", "20-59", ">=60"],
    ).astype("string")

    if not requirements.empty:
        requirement_summary = (
            requirements.assign(
                is_active=requirements["is_active"].astype(str).eq("1"),
                requirement_type=requirements["requirement_type"].fillna("SIN_REQUERIMIENTO"),
            )
            .groupby(["episode_id", "requirement_type"])["is_active"]
            .max()
            .reset_index()
        )
        requirement_flags = (
            requirement_summary.pivot(index="episode_id", columns="requirement_type", values="is_active")
            .fillna(False)
            .reset_index()
        )
        merged = merged.merge(requirement_flags, on="episode_id", how="left")

    if not professional_needs.empty:
        professional_summary = (
            professional_needs.assign(
                professional_type=professional_needs["professional_type"].fillna("SIN_PROFESIONAL")
            )
            .groupby(["episode_id", "professional_type"])
            .size()
            .reset_index(name="need_count")
        )
        professional_flags = (
            professional_summary.assign(has_need=True)
            .pivot(index="episode_id", columns="professional_type", values="has_need")
            .fillna(False)
            .reset_index()
        )
        merged = merged.merge(professional_flags, on="episode_id", how="left")

    bool_like_columns = []
    if not requirements.empty:
        bool_like_columns.extend(requirements["requirement_type"].dropna().unique().tolist())
    if not professional_needs.empty:
        bool_like_columns.extend(professional_needs["professional_type"].dropna().unique().tolist())
    for column in bool_like_columns:
        if column in merged.columns:
            merged[column] = merged[column].fillna(False)

    quality["severity"] = quality["severity"].fillna("UNKNOWN")
    quality["issue_type"] = quality["issue_type"].fillna("UNKNOWN")
    quality_per_episode = quality.groupby("episode_id").size().rename("quality_issue_count")
    merged = merged.merge(quality_per_episode, on="episode_id", how="left")
    merged["quality_issue_count"] = merged["quality_issue_count"].fillna(0).astype(int)

    if not diagnoses.empty:
        diagnoses["diagnosis_text_raw"] = diagnoses["diagnosis_text_raw"].fillna("")
        diagnosis_per_episode = (
            diagnoses.groupby("episode_id")["diagnosis_text_raw"]
            .apply(lambda values: " | ".join(sorted(set(v for v in values if v))))
            .rename("diagnosticos")
        )
        merged = merged.merge(diagnosis_per_episode, on="episode_id", how="left")
    else:
        merged["diagnosticos"] = merged["diagnostico_principal_texto"]

    if not source_links.empty:
        source_counts = source_links.groupby("episode_id").size().rename("source_rows")
        merged = merged.merge(source_counts, on="episode_id", how="left")
        merged["source_rows"] = merged["source_rows"].fillna(0).astype(int)
    else:
        merged["source_rows"] = 1

    return {
        "enriched_mode": pd.DataFrame([{"enabled": enriched_mode}]),
        "episodes": episodes,
        "patients": patients,
        "quality": quality,
        "requirements": requirements,
        "professional_needs": professional_needs,
        "diagnoses": diagnoses,
        "source_links": source_links,
        "catalogs": catalogs,
        "episode_requests": episode_requests,
        "episode_discharges": episode_discharges,
        "rescue_candidates": rescue_candidates,
        "field_provenance": field_provenance,
        "match_review_queue": match_review_queue,
        "identity_review_queue": identity_review_queue,
        "establishments": establishments,
        "localities": localities,
        "address_resolution": address_resolution,
        "reconciliation": reconciliation,
        "merged": merged,
    }


def metric_delta_text(current: int | float | None, previous: int | float | None, suffix: str = "") -> str | None:
    if current is None or previous is None:
        return None
    delta = current - previous
    sign = "+" if delta > 0 else ""
    if isinstance(delta, float):
        return f"{sign}{delta:.1f}{suffix}"
    return f"{sign}{delta}{suffix}"


def infer_origin_derivation(service: str) -> str:
    value = str(service or "").strip().upper()
    if not value:
        return "sin_inferencia"
    if any(token in value for token in ["APS", "CESFAM", "CECOSF", "PSR"]):
        return "APS"
    if value in {"UE", "EU", "URG", "URG. HOSP", "URGENCIA"}:
        return "urgencia"
    if any(token in value for token in ["CAE", "CDT", "HOSPITAL DE DIA", "CMA", "CMI", "AMB"]):
        return "ambulatorio"
    if "UGCC" in value:
        return "UGCC"
    if "LEY" in value and "URG" in value:
        return "ley_urgencia"
    return "hospitalizacion"


def classify_outcome(motivo: str) -> str:
    value = str(motivo or "").strip().upper()
    if not value:
        return "sin_clasificar"
    if "FALLE" in value:
        return "fallecido"
    if "REHOSP" in value or "REINGRESO" in value or "HOSPITALIZ" in value:
        return "reingreso_hospitalizacion"
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
    effective_start = max(ingreso, start) if pd.notna(ingreso) else start
    effective_end = min(egreso, end) if pd.notna(egreso) else end
    if effective_end < effective_start:
        return 0
    return int((effective_end - effective_start).days) + 1


def filter_episodes(df: pd.DataFrame) -> tuple[pd.DataFrame, pd.Timestamp | None, pd.Timestamp | None]:
    with st.sidebar:
        st.subheader("Filtros")
        preset = st.selectbox(
            "Preset",
            ["Todo", "Punilla", "Rescates 2025", "Provisionales", "Con issues"],
            index=0,
        )
        st.caption(
            "Presets rápidos:\n"
            "- `Punilla`: filtra por provincia\n"
            "- `Rescates 2025`: focos oct-dic 2025\n"
            "- `Provisionales`: episodios aún no cerrados por reconciliación"
        )
        min_date = df["activity_date"].min()
        max_date = df["activity_date"].max()
        date_range = st.date_input(
            "Rango de actividad",
            value=(min_date.date() if pd.notna(min_date) else None, max_date.date() if pd.notna(max_date) else None),
        )
        flujo = st.multiselect("Flujo", sorted(df["tipo_flujo"].dropna().unique()), default=sorted(df["tipo_flujo"].dropna().unique()))
        calidad = st.multiselect(
            "Calidad del episodio",
            sorted(df["episode_status_quality"].dropna().unique()),
            default=sorted(df["episode_status_quality"].dropna().unique()),
        )
        resolution = st.multiselect(
            "Resolución",
            sorted(df["resolution_status"].dropna().unique()),
            default=sorted(df["resolution_status"].dropna().unique()),
        )
        episode_origin = st.multiselect(
            "Origen episodio",
            sorted(df["episode_origin"].dropna().unique()),
            default=sorted(df["episode_origin"].dropna().unique()),
        )
        comuna = st.multiselect("Comuna", sorted(df["comuna_resuelta"].dropna().unique()))
        provincia = st.multiselect(
            "Provincia",
            sorted(df["provincia_resuelta"].dropna().astype(str).unique()) if "provincia_resuelta" in df.columns else [],
        )
        address_resolution = st.multiselect(
            "Resolución territorial",
            sorted(df["address_resolution_status"].dropna().astype(str).unique()) if "address_resolution_status" in df.columns else [],
        )
        establishment = st.multiselect(
            "Establecimiento resuelto",
            sorted(df["establecimiento_resuelto"].dropna().astype(str).unique()) if "establecimiento_resuelto" in df.columns else [],
        )
        servicio = st.multiselect("Servicio de origen", sorted(df["servicio_origen"].dropna().unique()))
        prevision = st.multiselect("Previsión", sorted(df["prevision"].dropna().unique()))
        search = st.text_input("Buscar paciente / diagnóstico / RUT")

    filtered = df.copy()
    selected_start: pd.Timestamp | None = None
    selected_end: pd.Timestamp | None = None

    if preset == "Punilla" and "provincia_resuelta" in filtered.columns:
        filtered = filtered[filtered["provincia_resuelta"].fillna("").str.upper() == "PUNILLA"]
    elif preset == "Rescates 2025":
        filtered = filtered[filtered["episode_origin"].isin(["form_rescued", "alta_rescued"])]
        selected_start, selected_end = pd.Timestamp("2025-10-01"), pd.Timestamp("2025-12-31")
    elif preset == "Provisionales":
        filtered = filtered[filtered["resolution_status"] == "PROVISIONAL"]
    elif preset == "Con issues":
        filtered = filtered[filtered["quality_issue_count"] > 0]

    if isinstance(date_range, tuple) and len(date_range) == 2 and all(date_range):
        selected_start, selected_end = pd.to_datetime(date_range[0]), pd.to_datetime(date_range[1])
        ingreso = filtered["fecha_ingreso"]
        egreso = filtered["fecha_egreso"]
        activity = filtered["activity_date"]
        overlap_mask = (
            (
                (ingreso.isna() | (ingreso <= selected_end))
                & (egreso.isna() | (egreso >= selected_start))
                & (ingreso.notna() | egreso.notna())
            )
            | activity.between(selected_start, selected_end)
        )
        filtered = filtered[overlap_mask]

    if flujo:
        filtered = filtered[filtered["tipo_flujo"].isin(flujo)]
    if calidad:
        filtered = filtered[filtered["episode_status_quality"].isin(calidad)]
    if resolution:
        filtered = filtered[filtered["resolution_status"].isin(resolution)]
    if episode_origin:
        filtered = filtered[filtered["episode_origin"].isin(episode_origin)]
    if comuna:
        filtered = filtered[filtered["comuna_resuelta"].isin(comuna)]
    if provincia:
        filtered = filtered[filtered["provincia_resuelta"].isin(provincia)]
    if address_resolution:
        filtered = filtered[filtered["address_resolution_status"].isin(address_resolution)]
    if establishment:
        filtered = filtered[filtered["establecimiento_resuelto"].isin(establishment)]
    if servicio:
        filtered = filtered[filtered["servicio_origen"].isin(servicio)]
    if prevision:
        filtered = filtered[filtered["prevision"].isin(prevision)]
    if search:
        token = search.strip().lower()
        mask = (
            filtered["nombre_completo"].fillna("").str.lower().str.contains(token)
            | filtered["diagnostico_principal_texto"].fillna("").str.lower().str.contains(token)
            | filtered["rut"].fillna("").str.lower().str.contains(token)
        )
        filtered = filtered[mask]

    return filtered, selected_start, selected_end


def color_for_origin(origin: str) -> list[int]:
    mapping = {
        "raw": [90, 120, 200, 180],
        "merged": [18, 115, 92, 190],
        "form_rescued": [214, 99, 36, 210],
        "alta_rescued": [165, 92, 214, 210],
    }
    return mapping.get(str(origin or "").strip(), [120, 120, 120, 180])


def color_for_resolution(status: str) -> list[int]:
    mapping = {
        "RESOLVED": [18, 115, 92, 200],
        "PARTIAL": [214, 99, 36, 190],
        "UNRESOLVED": [184, 46, 46, 210],
    }
    return mapping.get(str(status or "").strip(), [120, 120, 120, 180])


def render_pydeck_map(
    df: pd.DataFrame,
    *,
    lat_col: str,
    lon_col: str,
    color_col: str,
    tooltip_fields: list[str],
    key: str,
    radius: int = 500,
) -> None:
    if df.empty:
        st.info("No hay puntos para mostrar en el mapa con los filtros actuales.")
        return

    geo = df.copy()
    geo[lat_col] = pd.to_numeric(geo[lat_col], errors="coerce")
    geo[lon_col] = pd.to_numeric(geo[lon_col], errors="coerce")
    geo = geo.dropna(subset=[lat_col, lon_col])
    if geo.empty:
        st.info("No hay coordenadas válidas para renderizar el mapa.")
        return

    center = {"lat": float(geo[lat_col].median()), "lon": float(geo[lon_col].median())}
    tooltip_lines = [f"<b>{field}</b>: {{{field}}}" for field in tooltip_fields]
    layer = pdk.Layer(
        "ScatterplotLayer",
        data=geo,
        get_position=f"[{lon_col}, {lat_col}]",
        get_fill_color=color_col,
        get_radius=radius,
        pickable=True,
        opacity=0.85,
        stroked=True,
        get_line_color=[30, 30, 30, 120],
        line_width_min_pixels=1,
    )
    deck = pdk.Deck(
        map_style="mapbox://styles/mapbox/light-v11",
        initial_view_state=pdk.ViewState(latitude=center["lat"], longitude=center["lon"], zoom=8.3, pitch=0),
        layers=[layer],
        tooltip={"html": "<br/>".join(tooltip_lines), "style": {"backgroundColor": "#163028", "color": "white"}},
    )
    st.pydeck_chart(deck, use_container_width=True, key=key)


def render_color_legend(title: str, items: list[tuple[str, list[int]]]) -> None:
    chips = []
    for label, color in items:
        color_css = f"rgba({color[0]}, {color[1]}, {color[2]}, {color[3] / 255:.2f})"
        chips.append(
            f"<span style='display:inline-flex;align-items:center;margin-right:12px;margin-bottom:6px;'>"
            f"<span style='display:inline-block;width:10px;height:10px;border-radius:999px;background:{color_css};margin-right:6px;border:1px solid rgba(0,0,0,0.15);'></span>"
            f"{label}</span>"
        )
    st.caption(title)
    st.markdown("".join(chips), unsafe_allow_html=True)


def render_record_details(title: str, record: pd.Series | None, fields: list[tuple[str, str]]) -> None:
    st.caption(title)
    if record is None:
        st.info("No hay un registro seleccionado.")
        return
    details = []
    for label, field in fields:
        value = record.get(field, "") if isinstance(record, pd.Series) else ""
        if pd.isna(value):
            value = ""
        details.append({"campo": label, "valor": value})
    st.dataframe(pd.DataFrame(details), use_container_width=True, hide_index=True)


def make_component_table(rows: list[dict[str, object]], dimension_order: list[str], dimension_column: str) -> pd.DataFrame:
    df = pd.DataFrame(rows)
    if df.empty:
        return pd.DataFrame(columns=["componente", "total", *dimension_order])
    pivot = (
        df.pivot_table(
            index="componente",
            columns=dimension_column,
            values="valor",
            aggfunc="sum",
            fill_value=0,
        )
        .reindex(columns=dimension_order, fill_value=0)
        .reset_index()
    )
    totals = df.groupby("componente")["valor"].sum().rename("total").reset_index()
    return totals.merge(pivot, on="componente", how="left")


def build_rem_c11(df: pd.DataFrame, start: pd.Timestamp | None, end: pd.Timestamp | None) -> tuple[pd.DataFrame, pd.DataFrame, pd.DataFrame, dict[str, object]]:
    if df.empty:
        empty = pd.DataFrame()
        return empty, empty, empty, {"fallecidos_esperados_disponible": False, "visitas_disponibles": False, "cupos_disponibles": False}

    work = df.copy()
    if start is None:
        start = pd.to_datetime(work["activity_date"].min())
    if end is None:
        end = pd.to_datetime(work["activity_date"].max())
    work["sexo_rem"] = work["sexo_resuelto"].map(normalize_sex_label)
    work["origen_derivacion_rem"] = work["servicio_origen"].map(infer_origin_derivation)
    work["rango_etario"] = work["rango_etario"].fillna("SIN_RANGO")
    work["outcome"] = work["motivo_egreso"].map(classify_outcome)
    work["overlap_days"] = work.apply(lambda row: overlap_days(row, start, end), axis=1)
    work["is_active_in_period"] = work["overlap_days"] > 0
    work["ingreso_in_period"] = work["fecha_ingreso"].between(start, end, inclusive="both")
    work["egreso_in_period"] = work["fecha_egreso"].between(start, end, inclusive="both")

    totals = {
        "ingresos": int(work["ingreso_in_period"].sum()),
        "personas_atendidas": int(work.loc[work["is_active_in_period"], "patient_id"].nunique()),
        "dias_persona": int(work["overlap_days"].sum()),
        "altas": int(((work["egreso_in_period"]) & (work["outcome"] == "alta")).sum()),
        "reingresos_hospitalizacion": int(((work["egreso_in_period"]) & (work["outcome"] == "reingreso_hospitalizacion")).sum()),
        "fallecidos_total_inferidos": int(((work["egreso_in_period"]) & (work["outcome"] == "fallecido")).sum()),
    }

    sexo_rows: list[dict[str, object]] = []
    age_rows: list[dict[str, object]] = []
    origin_rows: list[dict[str, object]] = []

    for label in SEX_CATEGORY_ORDER:
        sexo_rows.append({"componente": "ingresos", "sexo": label, "valor": int(work.loc[work["ingreso_in_period"] & (work["sexo_rem"] == label)].shape[0])})
        sexo_rows.append({"componente": "personas_atendidas", "sexo": label, "valor": int(work.loc[work["is_active_in_period"] & (work["sexo_rem"] == label), "patient_id"].nunique())})
        sexo_rows.append({"componente": "dias_persona", "sexo": label, "valor": int(work.loc[work["sexo_rem"] == label, "overlap_days"].sum())})
        sexo_rows.append({"componente": "altas", "sexo": label, "valor": int(work.loc[work["egreso_in_period"] & (work["outcome"] == "alta") & (work["sexo_rem"] == label)].shape[0])})
        sexo_rows.append({"componente": "reingresos_hospitalizacion", "sexo": label, "valor": int(work.loc[work["egreso_in_period"] & (work["outcome"] == "reingreso_hospitalizacion") & (work["sexo_rem"] == label)].shape[0])})

    for label in AGE_CATEGORY_ORDER:
        age_rows.append({"componente": "ingresos", "rango_etario": label, "valor": int(work.loc[work["ingreso_in_period"] & (work["rango_etario"] == label)].shape[0])})
        age_rows.append({"componente": "personas_atendidas", "rango_etario": label, "valor": int(work.loc[work["is_active_in_period"] & (work["rango_etario"] == label), "patient_id"].nunique())})
        age_rows.append({"componente": "dias_persona", "rango_etario": label, "valor": int(work.loc[work["rango_etario"] == label, "overlap_days"].sum())})
        age_rows.append({"componente": "altas", "rango_etario": label, "valor": int(work.loc[work["egreso_in_period"] & (work["outcome"] == "alta") & (work["rango_etario"] == label)].shape[0])})
        age_rows.append({"componente": "reingresos_hospitalizacion", "rango_etario": label, "valor": int(work.loc[work["egreso_in_period"] & (work["outcome"] == "reingreso_hospitalizacion") & (work["rango_etario"] == label)].shape[0])})

    for label in ORIGIN_CATEGORY_ORDER:
        origin_rows.append({"componente": "ingresos", "origen": label, "valor": int(work.loc[work["ingreso_in_period"] & (work["origen_derivacion_rem"] == label)].shape[0])})
        origin_rows.append({"componente": "personas_atendidas", "origen": label, "valor": int(work.loc[work["is_active_in_period"] & (work["origen_derivacion_rem"] == label), "patient_id"].nunique())})
        origin_rows.append({"componente": "dias_persona", "origen": label, "valor": int(work.loc[work["origen_derivacion_rem"] == label, "overlap_days"].sum())})
        origin_rows.append({"componente": "altas", "origen": label, "valor": int(work.loc[work["egreso_in_period"] & (work["outcome"] == "alta") & (work["origen_derivacion_rem"] == label)].shape[0])})
        origin_rows.append({"componente": "reingresos_hospitalizacion", "origen": label, "valor": int(work.loc[work["egreso_in_period"] & (work["outcome"] == "reingreso_hospitalizacion") & (work["origen_derivacion_rem"] == label)].shape[0])})

    sexo_table = make_component_table(sexo_rows, SEX_CATEGORY_ORDER, "sexo")
    age_table = make_component_table(age_rows, AGE_CATEGORY_ORDER, "rango_etario")
    origin_table = make_component_table(origin_rows, ORIGIN_CATEGORY_ORDER, "origen")

    metadata = {
        "fallecidos_esperados_disponible": False,
        "visitas_disponibles": False,
        "cupos_disponibles": False,
        "start": start,
        "end": end,
        "totals": totals,
    }
    return sexo_table, age_table, origin_table, metadata


def render_header(df: pd.DataFrame) -> None:
    current_month = df["activity_month"].dropna().max()
    previous_month = None
    if pd.notna(current_month):
        try:
            previous_month = str((pd.Period(current_month, freq="M") - 1))
        except Exception:
            previous_month = None

    current_df = df[df["activity_month"] == current_month] if current_month else df.iloc[0:0]
    previous_df = df[df["activity_month"] == previous_month] if previous_month else df.iloc[0:0]

    total_episodes = len(df)
    total_patients = df["patient_id"].nunique()
    active_cases = int(df["estado"].eq("ACTIVO").sum())
    median_stay = df["estadia_util"].dropna().median()

    col1, col2, col3, col4 = st.columns(4)
    col1.metric("Episodios", f"{total_episodes:,}".replace(",", "."), metric_delta_text(len(current_df), len(previous_df)))
    col2.metric("Pacientes", f"{total_patients:,}".replace(",", "."), metric_delta_text(current_df["patient_id"].nunique(), previous_df["patient_id"].nunique()))
    col3.metric("Casos activos", active_cases)
    col4.metric("Mediana estadía", f"{median_stay:.1f} días" if pd.notna(median_stay) else "s/d")


def render_executive_summary(df: pd.DataFrame, localities: pd.DataFrame, address_resolution: pd.DataFrame) -> None:
    st.subheader("Resumen Ejecutivo")
    render_header(df)

    c1, c2 = st.columns([1.3, 1])

    monthly = (
        df.dropna(subset=["activity_month"])
        .groupby(["activity_month", "tipo_flujo"])
        .size()
        .unstack(fill_value=0)
        .sort_index()
    )
    with c1:
        st.caption("Actividad mensual")
        st.line_chart(monthly)

    with c2:
        top_comunas = (
            df["comuna_resuelta"].fillna("SIN_COMUNA").value_counts().head(10).sort_values(ascending=True)
        )
        st.caption("Top comunas")
        st.bar_chart(top_comunas)

    c3, c4, c5 = st.columns(3)
    with c3:
        st.caption("Previsión")
        st.dataframe(
            df["prevision"].fillna("SIN_PREVISION").value_counts().rename_axis("prevision").reset_index(name="episodios"),
            use_container_width=True,
            hide_index=True,
        )
    with c4:
        st.caption("Dependencia funcional")
        st.dataframe(
            df["barthel"].fillna("SIN_BARTHEL").value_counts().rename_axis("barthel").reset_index(name="episodios"),
            use_container_width=True,
            hide_index=True,
        )
    with c5:
        st.caption("Calidad del episodio")
        st.dataframe(
            df["episode_status_quality"]
            .fillna("SIN_CALIDAD")
            .value_counts()
            .rename_axis("calidad")
            .reset_index(name="episodios"),
            use_container_width=True,
            hide_index=True,
        )

    geo1, geo2, geo3 = st.columns(3)
    coords_count = 0
    if not localities.empty and {"latitud", "longitud"}.issubset(localities.columns):
        coords_count = int(
            (
                pd.to_numeric(localities["latitud"], errors="coerce").notna()
                & pd.to_numeric(localities["longitud"], errors="coerce").notna()
            ).sum()
        )
    geo1.metric("Localidades con coordenadas", coords_count)
    geo2.metric(
        "Direcciones resueltas",
        int(address_resolution["resolution_status"].eq("RESOLVED").sum()) if not address_resolution.empty else 0,
    )
    geo3.metric(
        "Episodios rescatados",
        int(df["episode_origin"].isin(["form_rescued", "alta_rescued"]).sum()),
    )


def render_activity_panel(df: pd.DataFrame) -> None:
    st.subheader("Actividad Asistencial")
    col1, col2 = st.columns(2)

    with col1:
        monthly_stay = (
            df.dropna(subset=["activity_month"])
            .groupby("activity_month")["estadia_util"]
            .median()
            .dropna()
        )
        st.caption("Mediana de estadía por mes")
        st.line_chart(monthly_stay)

    with col2:
        service_mix = (
            df["servicio_origen"].fillna("SIN_SERVICIO").value_counts().head(12).sort_values(ascending=True)
        )
        st.caption("Servicios de origen")
        st.bar_chart(service_mix)

    c1, c2, c3 = st.columns(3)
    with c1:
        o2_rate = float(df.get("USUARIO_O2", pd.Series(dtype=bool)).fillna(False).mean() * 100) if len(df) else 0.0
        st.metric("Uso O2", f"{o2_rate:.1f}%")
    with c2:
        csv_rate = float(df.get("CSV", pd.Series(dtype=bool)).fillna(False).mean() * 100) if len(df) else 0.0
        st.metric("CSV activo", f"{csv_rate:.1f}%")
    with c3:
        rehosp = int(df["motivo_egreso"].fillna("").str.contains("REHOSP", case=False).sum())
        st.metric("Rehospitalización registrada", rehosp)

    st.caption("Profesionales requeridos")
    professional_columns = [column for column in ["ENFERMERIA", "KINESIOLOGIA", "FONOAUDIOLOGIA", "MEDICO", "TRABAJO_SOCIAL", "KNT", "FONO"] if column in df.columns]
    if professional_columns:
        professional_rates = pd.Series(
            {column: int(df[column].fillna(False).sum()) for column in professional_columns}
        ).sort_values(ascending=False)
        st.bar_chart(professional_rates)


def render_quality_panel(df: pd.DataFrame, quality: pd.DataFrame, patients: pd.DataFrame) -> None:
    st.subheader("Calidad De Dato")
    c1, c2, c3, c4 = st.columns(4)
    issues_open = len(quality)
    episodes_review = int(df["episode_status_quality"].eq("REVIEW").sum())
    ambiguous_patients = int(patients["identity_resolution_status"].eq("AMBIGUOUS").sum())
    invalid_dates = int(
        quality["issue_type"].eq("DATE_PARSE_FAILED").sum() if "issue_type" in quality.columns else 0
    )
    c1.metric("Issues abiertos", issues_open)
    c2.metric("Episodios en revisión", episodes_review)
    c3.metric("Pacientes ambiguos", ambiguous_patients)
    c4.metric("Fallas de fecha", invalid_dates)

    qc1, qc2 = st.columns(2)
    with qc1:
        by_issue = quality["issue_type"].fillna("UNKNOWN").value_counts().head(12).sort_values(ascending=True)
        st.caption("Issues por tipo")
        st.bar_chart(by_issue)
    with qc2:
        by_severity = quality["severity"].fillna("UNKNOWN").value_counts().sort_values(ascending=True)
        st.caption("Issues por severidad")
        st.bar_chart(by_severity)

    st.caption("Pacientes sin identidad resuelta por RUT")
    ambiguous_view = patients[patients["identity_resolution_status"] != "AUTO"][
        [
            "nombre_completo",
            "patient_key_strategy",
            "fecha_nacimiento_date",
            "nro_contacto",
            "comuna",
            "source_files",
        ]
    ]
    st.dataframe(ambiguous_view, use_container_width=True, hide_index=True)


def render_normalization_panel(
    episodes: pd.DataFrame,
    quality: pd.DataFrame,
    field_provenance: pd.DataFrame,
    episode_requests: pd.DataFrame,
    episode_discharges: pd.DataFrame,
    match_review_queue: pd.DataFrame,
) -> None:
    st.subheader("Normalización Y Reconciliación")
    st.caption(
        "Este panel mezcla métricas de reconciliación, matching y issues. "
        "No todo lo que aparece aquí corresponde a 'error'; varias cifras reflejan trazabilidad de overrides o cobertura de integración."
    )
    c1, c2, c3, c4 = st.columns(4)
    c1.metric("Overrides trazados", len(field_provenance))
    c2.metric("Formularios vinculados", int(episode_requests["match_status"].isin(["matched_exact", "matched_probable", "matched_manual"]).sum()) if not episode_requests.empty else 0)
    c3.metric("Altas vinculadas", int(episode_discharges["match_status"].isin(["matched_exact", "matched_probable", "matched_manual"]).sum()) if not episode_discharges.empty else 0)
    c4.metric("Issues abiertos reales", int(quality["status"].isin(["OPEN", "REVIEW_REQUIRED"]).sum()) if not quality.empty else 0)

    with st.expander("Cómo leer estas métricas", expanded=False):
        semantics = pd.DataFrame(
            [
                {
                    "métrica": "Overrides trazados",
                    "significado": "Número de campos donde una fuente ganó sobre otra o se preservó conflicto con trazabilidad.",
                    "tipo": "Trazabilidad, no error",
                },
                {
                    "métrica": "Formularios vinculados",
                    "significado": "Solicitudes de formulario que terminaron asociadas a un episodio existente.",
                    "tipo": "Cobertura de matching",
                },
                {
                    "métrica": "Altas vinculadas",
                    "significado": "Filas de la planilla de altas que lograron asociarse a un episodio.",
                    "tipo": "Cobertura de matching",
                },
                {
                    "métrica": "Issues abiertos reales",
                    "significado": "Issues que aún requieren acción o revisión; excluye los resueltos automáticamente.",
                    "tipo": "Calidad pendiente",
                },
            ]
        )
        st.dataframe(semantics, use_container_width=True, hide_index=True)

    left, right = st.columns(2)
    with left:
        if not field_provenance.empty:
            by_source = field_provenance["selected_source"].fillna("UNKNOWN").value_counts().sort_values(ascending=True)
            st.caption("Overrides por fuente")
            st.bar_chart(by_source)
        if not episode_requests.empty:
            request_match = episode_requests["match_status"].fillna("UNKNOWN").value_counts().sort_values(ascending=True)
            st.caption("Estado de match de formularios")
            st.bar_chart(request_match)
    with right:
        if not field_provenance.empty:
            by_field = field_provenance["field_name"].fillna("UNKNOWN").value_counts().head(12).sort_values(ascending=True)
            st.caption("Campos más sobrescritos")
            st.bar_chart(by_field)
        if not episode_discharges.empty:
            discharge_match = episode_discharges["match_status"].fillna("UNKNOWN").value_counts().sort_values(ascending=True)
            st.caption("Estado de match de altas")
            st.bar_chart(discharge_match)

    st.caption("Muestra de conflictos / procedencia")
    if field_provenance.empty:
        st.info("No hay `field_provenance` disponible en la capa activa.")
    else:
        st.dataframe(field_provenance.head(200), use_container_width=True, hide_index=True)

    st.caption("Cola de revisión de match")
    if match_review_queue.empty:
        st.info("No hay `match_review_queue` disponible en la capa activa.")
    else:
        auto_close = match_review_queue[match_review_queue["auto_close_recommended"] == 1]
        st.metric("Auto-close sugeridos", len(auto_close))
        st.dataframe(
            match_review_queue[
                [
                    "patient_name",
                    "patient_rut",
                    "submission_timestamp",
                    "servicio_origen_solicitud",
                    "diagnostico_form",
                    "request_prestacion",
                    "gestora",
                    "candidate_rank",
                    "candidate_episode_id",
                    "candidate_fecha_ingreso",
                    "candidate_servicio_origen",
                    "candidate_diagnostico",
                    "candidate_score",
                    "auto_close_recommended",
                ]
            ],
            use_container_width=True,
            hide_index=True,
        )


def render_review_panel(
    match_review_queue: pd.DataFrame,
    identity_review_queue: pd.DataFrame,
) -> None:
    st.subheader("Revisión Asistida")
    c1, c2, c3 = st.columns(3)
    c1.metric("Match review queue", len(match_review_queue))
    c2.metric(
        "Auto-close sugeridos",
        int((match_review_queue["auto_close_recommended"] == 1).sum()) if not match_review_queue.empty else 0,
    )
    c3.metric("Issues nominales abiertos", len(identity_review_queue))

    tab1, tab2 = st.tabs(["Match Queue", "Identity Queue"])
    with tab1:
        if match_review_queue.empty:
            st.info("No hay cola de revisión de match.")
        else:
            st.dataframe(
                match_review_queue.sort_values(["auto_close_recommended", "candidate_rank"], ascending=[False, True]),
                use_container_width=True,
                hide_index=True,
            )
    with tab2:
        if identity_review_queue.empty:
            st.info("No hay issues nominales abiertos.")
        else:
            st.dataframe(
                identity_review_queue.sort_values(["issue_type", "severity"]),
                use_container_width=True,
                hide_index=True,
            )


def render_rescue_panel(
    episodes: pd.DataFrame,
    rescue_candidates: pd.DataFrame,
    reconciliation: pd.DataFrame,
    episode_requests: pd.DataFrame,
    match_review_queue: pd.DataFrame,
) -> None:
    st.subheader("Rescates 2025")
    default_months = {"2025-10", "2025-11", "2025-12"}
    rescue_2025 = rescue_candidates[
        rescue_candidates.apply(
            lambda row: any(
                str(row[column] or "").startswith(prefix)
                for prefix in default_months
                for column in ["requested_at", "fecha_egreso", "fecha_ingreso"]
            ),
            axis=1,
        )
    ] if not rescue_candidates.empty else rescue_candidates

    c1, c2, c3 = st.columns(3)
    c1.metric("Rescates foco 2025", len(rescue_2025))
    c2.metric("Episodios provisionales", int(episodes["resolution_status"].eq("PROVISIONAL").sum()))
    c3.metric("Origen form_rescued", int(episodes["episode_origin"].eq("form_rescued").sum()))

    if not reconciliation.empty:
        st.caption("Reconciliación mensual")
        st.dataframe(reconciliation, use_container_width=True, hide_index=True)
        recon_chart = reconciliation.set_index("month")[
            ["baseline_episode_count", "enriched_episode_count", "rescued_form_count", "rescued_discharge_count"]
        ].apply(pd.to_numeric, errors="coerce")
        st.line_chart(recon_chart)

    if not rescue_2025.empty:
        st.caption("Candidatos rescatados / pendientes")
        st.dataframe(
            rescue_2025[
                [
                    "candidate_type",
                    "episode_origin",
                    "rescue_priority",
                    "requested_at",
                    "fecha_ingreso",
                    "fecha_egreso",
                    "nombre_completo",
                    "rut_norm",
                    "diagnostico",
                    "servicio_origen",
                    "motivo_egreso",
                ]
            ],
            use_container_width=True,
            hide_index=True,
        )
    else:
        st.info("No hay rescates focalizados en octubre-diciembre 2025.")

    rescued_map = episodes[
        episodes["episode_origin"].isin(["form_rescued", "alta_rescued"])
        & episodes["localidad_latitud"].notna()
        & episodes["localidad_longitud"].notna()
    ].copy() if {"localidad_latitud", "localidad_longitud"}.issubset(episodes.columns) else pd.DataFrame()
    if not rescued_map.empty:
        rescued_map["map_color"] = rescued_map["episode_origin"].map(color_for_origin)
        st.caption("Mapa de episodios rescatados")
        render_pydeck_map(
            rescued_map,
            lat_col="localidad_latitud",
            lon_col="localidad_longitud",
            color_col="map_color",
            tooltip_fields=["nombre_completo", "episode_origin", "resolution_status", "diagnostico_principal_texto"],
            key="rescued_map",
            radius=850,
        )

    if not episode_requests.empty:
        requests_focus = episode_requests[
            episode_requests["submission_timestamp"].dt.strftime("%Y-%m").isin(sorted(default_months))
        ]
        if not requests_focus.empty:
            st.caption("Solicitudes HODOM del período foco")
            st.dataframe(
                requests_focus[
                    [
                        "submission_timestamp",
                        "patient_id",
                        "diagnostico",
                        "request_prestacion",
                        "gestora",
                        "match_status",
                        "resolution_status",
                        "episode_origin",
                    ]
                ].sort_values("submission_timestamp", ascending=False),
                use_container_width=True,
                hide_index=True,
            )

    if not match_review_queue.empty:
        st.caption("Cola de revisión manual de match")
        st.dataframe(match_review_queue.head(150), use_container_width=True, hide_index=True)


def render_territory_panel(
    establishments: pd.DataFrame,
    localities: pd.DataFrame,
    address_resolution: pd.DataFrame,
    filtered_episodes: pd.DataFrame,
) -> None:
    st.subheader("Territorio")
    st.caption("Explora cobertura geográfica, resolución de establecimientos y localidades a nivel de episodio y catálogo oficial.")
    c1, c2, c3, c4 = st.columns(4)
    c1.metric("Establecimientos DEIS", len(establishments))
    c2.metric("Localidades referencia", len(localities))
    c3.metric("Direcciones parciales", int(address_resolution["resolution_status"].eq("PARTIAL").sum()) if not address_resolution.empty else 0)
    c4.metric("Direcciones no resueltas", int(address_resolution["resolution_status"].eq("UNRESOLVED").sum()) if not address_resolution.empty else 0)
    coords_available = 0
    if not localities.empty and {"latitud", "longitud"}.issubset(localities.columns):
        coords_mask = pd.to_numeric(localities["latitud"], errors="coerce").notna() & pd.to_numeric(
            localities["longitud"], errors="coerce"
        ).notna()
        coords_available = int(coords_mask.sum())
    st.caption(f"Coordenadas oficiales cargadas: {coords_available}/{len(localities) if not localities.empty else 0}")
    render_color_legend(
        "Leyenda de resolución territorial",
        [
            ("RESOLVED", color_for_resolution("RESOLVED")),
            ("PARTIAL", color_for_resolution("PARTIAL")),
            ("UNRESOLVED", color_for_resolution("UNRESOLVED")),
        ],
    )
    render_color_legend(
        "Leyenda de origen de episodio",
        [
            ("raw", color_for_origin("raw")),
            ("merged", color_for_origin("merged")),
            ("form_rescued", color_for_origin("form_rescued")),
            ("alta_rescued", color_for_origin("alta_rescued")),
        ],
    )

    drilldown_col1, drilldown_col2, drilldown_col3 = st.columns(3)
    selected_province = ""
    selected_commune = ""
    selected_locality = ""
    if not localities.empty:
        provinces = [""] + sorted([value for value in localities["provincia"].dropna().astype(str).unique() if value])
        selected_province = drilldown_col1.selectbox("Provincia detalle", provinces, index=0)
        locality_subset = localities.copy()
        if selected_province:
            locality_subset = locality_subset[locality_subset["provincia"] == selected_province]
        communes = [""] + sorted([value for value in locality_subset["comuna"].dropna().astype(str).unique() if value])
        selected_commune = drilldown_col2.selectbox("Comuna detalle", communes, index=0)
        if selected_commune:
            locality_subset = locality_subset[locality_subset["comuna"] == selected_commune]
        names = [""] + sorted([value for value in locality_subset["nombre_oficial"].dropna().astype(str).unique() if value])
        selected_locality = drilldown_col3.selectbox("Localidad detalle", names, index=0)
    else:
        drilldown_col1.info("Sin catálogo territorial")

    left, right = st.columns(2)
    with left:
        if not establishments.empty:
            top_est = establishments["comuna"].fillna("SIN_COMUNA").value_counts().head(12).sort_values(ascending=True)
            st.caption("Establecimientos por comuna")
            st.bar_chart(top_est)
            st.caption("Muestra de establecimientos DEIS")
            st.dataframe(
                establishments[["codigo_deis", "nombre_oficial", "comuna", "tipo_establecimiento"]].head(100),
                use_container_width=True,
                hide_index=True,
            )
    with right:
        if not address_resolution.empty:
            by_status = address_resolution["resolution_status"].fillna("UNKNOWN").value_counts().sort_values(ascending=True)
            st.caption("Resolución de direcciones")
            st.bar_chart(by_status)
            st.dataframe(
                address_resolution[address_resolution["resolution_status"] != "RESOLVED"].head(100),
                use_container_width=True,
                hide_index=True,
            )

    detail_localities = localities.copy()
    if selected_province:
        detail_localities = detail_localities[detail_localities["provincia"] == selected_province]
    if selected_commune:
        detail_localities = detail_localities[detail_localities["comuna"] == selected_commune]
    if selected_locality:
        detail_localities = detail_localities[detail_localities["nombre_oficial"] == selected_locality]

    map_col, table_col = st.columns([1.15, 1])
    with map_col:
        geo = filtered_episodes.copy()
        if selected_province:
            geo = geo[geo["provincia_resuelta"] == selected_province]
        if selected_commune:
            geo = geo[geo["comuna_resuelta"] == selected_commune]
        if selected_locality:
            geo = geo[geo["localidad_resuelta"] == selected_locality]
        if {"localidad_latitud", "localidad_longitud"}.issubset(geo.columns):
            geo["localidad_latitud"] = pd.to_numeric(geo["localidad_latitud"], errors="coerce")
            geo["localidad_longitud"] = pd.to_numeric(geo["localidad_longitud"], errors="coerce")
            geo = geo.dropna(subset=["localidad_latitud", "localidad_longitud"])
        else:
            geo = pd.DataFrame()
        if not geo.empty:
            geo["map_color"] = geo["episode_origin"].map(color_for_origin)
            st.caption("Mapa de episodios filtrados con localidad resuelta")
            render_pydeck_map(
                geo,
                lat_col="localidad_latitud",
                lon_col="localidad_longitud",
                color_col="map_color",
                tooltip_fields=[
                    "nombre_completo",
                    "comuna_resuelta",
                    "establecimiento_resuelto",
                    "episode_origin",
                    "resolution_status",
                ],
                key="episode_geo_map",
                radius=650,
            )
        else:
            st.warning("No hay episodios filtrados con coordenadas resueltas para mapear.")

    with table_col:
        if not detail_localities.empty:
            localities_view = detail_localities.copy()
            localities_view["has_coords"] = localities_view["latitud"].fillna("").astype(str).ne("") & localities_view["longitud"].fillna("").astype(str).ne("")
            st.caption("Cobertura de localidades")
            st.dataframe(
                localities_view[
                    ["nombre_oficial", "comuna", "provincia", "territory_type", "source_priority", "has_coords"]
                ].head(150),
                use_container_width=True,
                hide_index=True,
            )
        else:
            st.info("No hay localidades en el detalle seleccionado.")

    if not localities.empty and {"latitud", "longitud"}.issubset(localities.columns):
        geo = detail_localities.copy()
        geo["latitud"] = pd.to_numeric(geo["latitud"], errors="coerce")
        geo["longitud"] = pd.to_numeric(geo["longitud"], errors="coerce")
        geo = geo.dropna(subset=["latitud", "longitud"])
        if not geo.empty:
            geo["map_color"] = geo["source_priority"].map(
                lambda value: [18, 115, 92, 180]
                if value == "official_gdb"
                else [214, 99, 36, 180]
                if value == "manual_official_snapshot"
                else [90, 120, 200, 180]
            )
            st.caption("Mapa base de localidades con coordenadas disponibles")
            render_pydeck_map(
                geo,
                lat_col="latitud",
                lon_col="longitud",
                color_col="map_color",
                tooltip_fields=["nombre_oficial", "comuna", "provincia", "source_priority"],
                key="locality_geo_map",
                radius=450,
            )
        else:
            st.warning("No hay coordenadas cargadas todavía en `locality_reference`. La capa territorial sigue en modo tabular y de resolución nominal.")

    st.markdown("---")
    detail_col1, detail_col2 = st.columns(2)
    with detail_col1:
        episode_options = {}
        geo_episode_view = filtered_episodes.copy()
        if selected_province:
            geo_episode_view = geo_episode_view[geo_episode_view["provincia_resuelta"] == selected_province]
        if selected_commune:
            geo_episode_view = geo_episode_view[geo_episode_view["comuna_resuelta"] == selected_commune]
        if selected_locality:
            geo_episode_view = geo_episode_view[geo_episode_view["localidad_resuelta"] == selected_locality]
        geo_episode_view = geo_episode_view.sort_values(["activity_date", "nombre_completo"], ascending=[False, True])
        for _, row in geo_episode_view.head(200).iterrows():
            label = f"{row.get('nombre_completo','')} | {row.get('activity_date','')} | {row.get('episode_origin','')}"
            episode_options[label] = row
        selected_episode_label = st.selectbox("Detalle de episodio", [""] + list(episode_options.keys()), index=0)
        selected_episode = episode_options.get(selected_episode_label)
        render_record_details(
            "Ficha de episodio",
            selected_episode,
            [
                ("Paciente", "nombre_completo"),
                ("RUT", "rut"),
                ("Fecha ingreso", "fecha_ingreso"),
                ("Fecha egreso", "fecha_egreso"),
                ("Origen episodio", "episode_origin"),
                ("Resolución", "resolution_status"),
                ("Diagnóstico", "diagnostico_principal_texto"),
                ("Servicio", "servicio_origen"),
                ("Establecimiento", "establecimiento_resuelto"),
                ("Localidad", "localidad_resuelta"),
            ],
        )

    with detail_col2:
        locality_options = {}
        for _, row in detail_localities.sort_values(["provincia", "comuna", "nombre_oficial"]).head(300).iterrows():
            label = f"{row.get('nombre_oficial','')} | {row.get('comuna','')} | {row.get('provincia','')}"
            locality_options[label] = row
        selected_locality_label = st.selectbox("Detalle de localidad", [""] + list(locality_options.keys()), index=0)
        selected_locality_row = locality_options.get(selected_locality_label)
        render_record_details(
            "Ficha de localidad",
            selected_locality_row,
            [
                ("Localidad", "nombre_oficial"),
                ("Comuna", "comuna"),
                ("Provincia", "provincia"),
                ("Tipo", "territory_type"),
                ("Latitud", "latitud"),
                ("Longitud", "longitud"),
                ("Fuente", "source_priority"),
            ],
        )


def render_gestoras_panel(episodes: pd.DataFrame, episode_requests: pd.DataFrame) -> None:
    st.subheader("Gestoras")
    if episode_requests.empty:
        st.info("No hay `episode_request` disponible en la capa activa.")
        return

    request_rows = episode_requests.copy()
    request_rows["submission_month"] = request_rows["submission_timestamp"].dt.to_period("M").astype("string")
    summary = (
        request_rows.groupby("gestora_norm")
        .agg(
            solicitudes=("episode_request_id", "count"),
            rescates=("episode_origin", lambda values: int(values.isin(["form_rescued", "alta_rescued"]).sum())),
            matches_exactos=("match_status", lambda values: int((values == "matched_exact").sum())),
            matches_probables=("match_status", lambda values: int((values == "matched_probable").sum())),
            pendientes=("match_status", lambda values: int((values == "unresolved").sum())),
        )
        .reset_index()
        .rename(columns={"gestora_norm": "gestora"})
        .sort_values(["solicitudes", "pendientes"], ascending=[False, False])
    )
    summary = summary[summary["gestora"].astype(str).str.strip() != ""]

    top_col, trend_col = st.columns([1, 1.2])
    with top_col:
        st.caption("Carga por gestora")
        st.dataframe(summary.head(30), use_container_width=True, hide_index=True)
    with trend_col:
        top_gestoras = summary["gestora"].head(8).tolist()
        trend = (
            request_rows[request_rows["gestora_norm"].isin(top_gestoras)]
            .groupby(["submission_month", "gestora_norm"])
            .size()
            .unstack(fill_value=0)
            .sort_index()
        )
        st.caption("Tendencia mensual de solicitudes")
        st.line_chart(trend)

    rescued_by_gestora = (
        request_rows.groupby("gestora_norm")["episode_origin"]
        .apply(lambda values: int(values.isin(["form_rescued", "alta_rescued"]).sum()))
        .sort_values(ascending=False)
    )
    rescued_by_gestora = rescued_by_gestora[rescued_by_gestora.index.str.strip() != ""]
    st.caption("Rescates por gestora")
    st.bar_chart(rescued_by_gestora.head(20))


def render_review_workbench(
    quality: pd.DataFrame,
    address_resolution: pd.DataFrame,
    match_review_queue: pd.DataFrame,
    establishments: pd.DataFrame,
    localities: pd.DataFrame,
) -> None:
    st.subheader("Mesa De Revisión")
    st.caption("Edita decisiones locales y guárdalas en `input/manual` para reutilizarlas en la próxima iteración del pipeline.")

    issue_tab, address_tab, match_tab = st.tabs(["Issues", "Direcciones", "Matches"])

    with issue_tab:
        issue_base = quality.copy()
        issue_base = issue_base[~issue_base["status"].fillna("").eq("RESOLVED_AUTO")]
        issue_base = issue_base[
            ["quality_issue_id", "issue_type", "severity", "status", "raw_value", "suggested_value"]
        ].copy()
        issue_base["review_decision"] = ""
        issue_base["approved_value"] = ""
        issue_base["review_notes"] = ""
        issue_existing = read_manual_csv("issue_review_overrides.csv")
        issue_view = merge_existing_reviews(
            issue_base,
            issue_existing,
            "quality_issue_id",
            ["review_decision", "approved_value", "review_notes"],
        )
        issue_filter = st.multiselect(
            "Tipos de issue a revisar",
            sorted(issue_view["issue_type"].dropna().unique()),
            default=sorted(issue_view["issue_type"].dropna().unique())[:6],
            key="issue_filter",
        )
        if issue_filter:
            issue_view = issue_view[issue_view["issue_type"].isin(issue_filter)]
        edited_issues = st.data_editor(
            issue_view.sort_values(["severity", "issue_type"]).head(400),
            use_container_width=True,
            hide_index=True,
            num_rows="fixed",
            column_config={
                "review_decision": st.column_config.SelectboxColumn(
                    "review_decision",
                    options=["", "accept_suggestion", "manual_fix", "ignore", "needs_clinical_review"],
                ),
            },
            key="issue_editor",
        )
        if st.button("Guardar revisión de issues"):
            path = write_manual_csv("issue_review_overrides.csv", edited_issues)
            st.success(f"Guardado en {path}")

    with address_tab:
        address_base = address_resolution[address_resolution["resolution_status"] != "RESOLVED"].copy()
        address_base["override_establishment_id"] = ""
        address_base["override_locality_id"] = ""
        address_base["override_status"] = ""
        address_base["review_notes"] = ""
        address_existing = read_manual_csv("address_review_overrides.csv")
        address_view = merge_existing_reviews(
            address_base,
            address_existing,
            "address_resolution_id",
            ["override_establishment_id", "override_locality_id", "override_status", "review_notes"],
        )
        establishment_options = [""] + sorted(establishments["establishment_id"].dropna().astype(str).unique()) if not establishments.empty else [""]
        locality_options = [""] + sorted(localities["locality_id"].dropna().astype(str).unique()) if not localities.empty else [""]
        edited_addresses = st.data_editor(
            address_view.head(300),
            use_container_width=True,
            hide_index=True,
            num_rows="fixed",
            column_config={
                "override_establishment_id": st.column_config.SelectboxColumn("override_establishment_id", options=establishment_options),
                "override_locality_id": st.column_config.SelectboxColumn("override_locality_id", options=locality_options),
                "override_status": st.column_config.SelectboxColumn(
                    "override_status",
                    options=["", "resolved_manual", "partial_manual", "discard_establishment", "discard_locality"],
                ),
            },
            key="address_editor",
        )
        if st.button("Guardar revisión de direcciones"):
            path = write_manual_csv("address_review_overrides.csv", edited_addresses)
            st.success(f"Guardado en {path}")

    with match_tab:
        match_base = match_review_queue.copy()
        match_base["review_decision"] = ""
        match_base["selected_episode_id"] = ""
        match_base["review_notes"] = ""
        match_existing = read_manual_csv("match_review_decisions.csv")
        match_view = merge_existing_reviews(
            match_base,
            match_existing,
            "review_queue_id",
            ["review_decision", "selected_episode_id", "review_notes"],
        )
        edited_matches = st.data_editor(
            match_view.head(400),
            use_container_width=True,
            hide_index=True,
            num_rows="fixed",
            column_config={
                "review_decision": st.column_config.SelectboxColumn(
                    "review_decision",
                    options=["", "link_candidate", "create_rescue", "ignore", "needs_manual_lookup"],
                ),
            },
            key="match_editor",
        )
        if st.button("Guardar revisión de matches"):
            path = write_manual_csv("match_review_decisions.csv", edited_matches)
            st.success(f"Guardado en {path}")


def render_rem_panel(df: pd.DataFrame, start: pd.Timestamp | None, end: pd.Timestamp | None) -> None:
    st.subheader("REM A21 / C.1 Hospitalización Domiciliaria")
    st.caption("Vista estructurada según el marco del Manual REM 2026 y la especificación de datos A21/C1.")

    sexo_table, age_table, origin_table, metadata = build_rem_c11(df, start, end)
    totals = metadata["totals"]

    st.info(
        f"Período analizado: {metadata['start'].date() if metadata['start'] is not None else 's/d'} a "
        f"{metadata['end'].date() if metadata['end'] is not None else 's/d'}"
    )

    render_color_legend(
        "Semántica de cálculo",
        [
            ("Observado", [18, 115, 92, 200]),
            ("Inferido", [214, 99, 36, 190]),
            ("No disponible", [120, 120, 120, 180]),
        ],
    )

    m1, m2, m3, m4, m5, m6 = st.columns(6)
    m1.metric("Ingresos", totals["ingresos"])
    m2.metric("Personas atendidas", totals["personas_atendidas"])
    m3.metric("Días persona", totals["dias_persona"])
    m4.metric("Altas", totals["altas"])
    m5.metric("Reingresos hospitalización", totals["reingresos_hospitalizacion"])
    m6.metric("Fallecidos inferidos", totals["fallecidos_total_inferidos"])

    coverage_col, note_col = st.columns([1.2, 1])
    with coverage_col:
        coverage = pd.DataFrame(
            [
                {"seccion": "C.1.1 Personas atendidas", "estado": "Parcial", "detalle": "Ingresos, personas atendidas, días persona, altas y reingresos sí; fallecidos esperado/no esperado no se distinguen en la fuente."},
                {"seccion": "C.1.2 Visitas realizadas", "estado": "No disponible", "detalle": "La capa actual no trae visitas nominales ni agregadas por profesional."},
                {"seccion": "C.1.3 Cupos disponibles", "estado": "No disponible", "detalle": "La fuente actual no trae capacidad instalada, cupos programados, utilizados ni disponibles."},
            ]
        )
        st.caption("Cobertura de la fuente frente al REM")
        st.dataframe(coverage, use_container_width=True, hide_index=True)
    with note_col:
        st.warning(
            "La derivación REM por origen se infiere heurísticamente desde `servicio_origen`. "
            "Sirve para exploración y pre-cálculo, no para tributación oficial sin validación clínica/estadística."
        )
        st.caption("Reglas aplicadas")
        st.markdown(
            "- `UE` y equivalentes -> `urgencia`\n"
            "- `CAE/CDT/CMA/CMI` -> `ambulatorio`\n"
            "- resto hospitalario -> `hospitalizacion`\n"
            "- `APS/CECOSF/CESFAM` explícitos -> `APS`\n"
            "- `ley_urgencia` y `UGCC` sólo si aparecen textualmente"
        )

    with st.expander("Cómo se calcula cada indicador REM C.1.1", expanded=False):
        methodology = pd.DataFrame(
            [
                {
                    "indicador": "Ingresos",
                    "cálculo": "Conteo de episodios cuya `fecha_ingreso` cae dentro del rango filtrado.",
                    "semántica": "Observado",
                },
                {
                    "indicador": "Personas atendidas",
                    "cálculo": "Pacientes únicos con al menos un día de solapamiento entre el episodio y el rango filtrado.",
                    "semántica": "Inferido desde vigencia del episodio",
                },
                {
                    "indicador": "Días persona",
                    "cálculo": "Suma de días de intersección entre cada episodio y el rango filtrado; incluye ambos extremos.",
                    "semántica": "Inferido desde fechas de episodio",
                },
                {
                    "indicador": "Altas",
                    "cálculo": "Conteo de episodios con `fecha_egreso` dentro del rango y `motivo_egreso` clasificado como alta.",
                    "semántica": "Observado con clasificación normalizada",
                },
                {
                    "indicador": "Reingresos hospitalización",
                    "cálculo": "Conteo de episodios con `fecha_egreso` dentro del rango y `motivo_egreso` con patrón rehospitalización/reingreso/hospitalización.",
                    "semántica": "Inferido desde texto normalizado de motivo de egreso",
                },
                {
                    "indicador": "Fallecidos inferidos",
                    "cálculo": "Conteo de episodios con `fecha_egreso` dentro del rango y `motivo_egreso` con patrón de fallecimiento.",
                    "semántica": "Inferido; no distingue esperado vs no esperado",
                },
                {
                    "indicador": "Desagregación por sexo",
                    "cálculo": "Usa `sexo_resuelto` del paciente asociado al episodio.",
                    "semántica": "Observado/normalizado",
                },
                {
                    "indicador": "Desagregación por rango etario",
                    "cálculo": "Usa `edad_reportada` del paciente y los buckets `<15`, `15-19`, `20-59`, `>=60`.",
                    "semántica": "Observado/derivado",
                },
                {
                    "indicador": "Desagregación por origen",
                    "cálculo": "Se infiere heurísticamente desde `servicio_origen`.",
                    "semántica": "Inferido",
                },
            ]
        )
        st.dataframe(methodology, use_container_width=True, hide_index=True)

    tab_total, tab_sexo, tab_edad, tab_origen = st.tabs(
        ["Totales", "Por Sexo", "Por Rango Etario", "Por Origen Derivación"]
    )

    with tab_total:
        total_table = pd.DataFrame(
            [
                {"componente": "ingresos", "total": totals["ingresos"]},
                {"componente": "personas_atendidas", "total": totals["personas_atendidas"]},
                {"componente": "dias_persona", "total": totals["dias_persona"]},
                {"componente": "altas", "total": totals["altas"]},
                {"componente": "reingresos_hospitalizacion", "total": totals["reingresos_hospitalizacion"]},
                {"componente": "fallecidos_esperados", "total": "N/D"},
                {"componente": "fallecidos_no_esperados", "total": "N/D"},
                {"componente": "fallecidos_total_inferidos", "total": totals["fallecidos_total_inferidos"]},
            ]
        )
        st.dataframe(total_table, use_container_width=True, hide_index=True)

    with tab_sexo:
        st.dataframe(sexo_table, use_container_width=True, hide_index=True)

    with tab_edad:
        st.dataframe(age_table, use_container_width=True, hide_index=True)

    with tab_origen:
        st.dataframe(origin_table, use_container_width=True, hide_index=True)


def render_explorer(df: pd.DataFrame, patients: pd.DataFrame, quality: pd.DataFrame) -> None:
    st.subheader("Explorador")
    tab1, tab2, tab3 = st.tabs(["Episodios", "Pacientes", "Issues"])

    with tab1:
        episode_view = df[
            [
                "episode_id",
                "nombre_completo",
                "rut",
                "episode_origin",
                "resolution_status",
                "match_status",
                "match_score",
                "estado",
                "tipo_flujo",
                "fecha_ingreso",
                "fecha_egreso",
                "estadia_util",
                "servicio_origen",
                "prevision",
                "barthel",
                "comuna_resuelta",
                "cesfam_resuelto",
                "establecimiento_resuelto" if "establecimiento_resuelto" in df.columns else "source_rows",
                "provincia_resuelta" if "provincia_resuelta" in df.columns else "source_rows",
                "codigo_deis" if "codigo_deis" in df.columns else "source_rows",
                "locality_id" if "locality_id" in df.columns else "source_rows",
                "diagnostico_principal_texto",
                "episode_status_quality",
                "quality_issue_count",
                "source_rows",
            ]
        ].sort_values(["fecha_ingreso", "fecha_egreso"], ascending=[False, False])
        st.dataframe(episode_view, use_container_width=True, hide_index=True)
        st.download_button(
            "Descargar episodios filtrados",
            data=episode_view.to_csv(index=False).encode("utf-8"),
            file_name="episodios_filtrados.csv",
            mime="text/csv",
        )
        episode_lookup = {
            f"{row.get('nombre_completo','')} | {row.get('fecha_ingreso','')} | {row.get('episode_id','')}": row
            for _, row in episode_view.head(250).iterrows()
        }
        selected_episode_label = st.selectbox("Inspeccionar episodio", [""] + list(episode_lookup.keys()), index=0)
        render_record_details(
            "Detalle de episodio seleccionado",
            episode_lookup.get(selected_episode_label),
            [
                ("Paciente", "nombre_completo"),
                ("RUT", "rut"),
                ("Episodio", "episode_id"),
                ("Origen", "episode_origin"),
                ("Resolución", "resolution_status"),
                ("Score", "match_score"),
                ("Servicio", "servicio_origen"),
                ("Comuna", "comuna_resuelta"),
                ("CESFAM", "cesfam_resuelto"),
                ("Diagnóstico", "diagnostico_principal_texto"),
            ],
        )

    with tab2:
        patient_view = patients[
            [
                "patient_id",
                "nombre_completo",
                "rut",
                "patient_key_strategy",
                "identity_resolution_status",
                "patient_resolution_status" if "patient_resolution_status" in patients.columns else "identity_resolution_status",
                "sexo",
                "edad_reportada",
                "comuna",
                "cesfam",
                "episode_count",
            ]
        ].sort_values(["episode_count", "nombre_completo"], ascending=[False, True])
        st.dataframe(patient_view, use_container_width=True, hide_index=True)
        patient_lookup = {
            f"{row.get('nombre_completo','')} | {row.get('rut','')} | {row.get('patient_id','')}": row
            for _, row in patient_view.head(250).iterrows()
        }
        selected_patient_label = st.selectbox("Inspeccionar paciente", [""] + list(patient_lookup.keys()), index=0)
        render_record_details(
            "Detalle de paciente seleccionado",
            patient_lookup.get(selected_patient_label),
            [
                ("Paciente", "nombre_completo"),
                ("RUT", "rut"),
                ("Strategy", "patient_key_strategy"),
                ("Resolución identidad", "identity_resolution_status"),
                ("Sexo", "sexo"),
                ("Edad", "edad_reportada"),
                ("Comuna", "comuna"),
                ("CESFAM", "cesfam"),
                ("N° episodios", "episode_count"),
            ],
        )

    with tab3:
        st.dataframe(
            quality.sort_values(["severity", "issue_type"]),
            use_container_width=True,
            hide_index=True,
        )


def main() -> None:
    st.set_page_config(
        page_title="HODOM Explorer",
        page_icon=":hospital:",
        layout="wide",
        initial_sidebar_state="expanded",
    )

    st.markdown(
        """
        <style>
        .block-container {padding-top: 1.1rem; padding-bottom: 2.2rem; max-width: 1500px;}
        .stApp {
            background:
                radial-gradient(circle at top left, rgba(11,110,79,0.08), transparent 28%),
                radial-gradient(circle at top right, rgba(214,99,36,0.08), transparent 24%),
                linear-gradient(180deg, #f7fbfa 0%, #eef4f2 100%);
        }
        section[data-testid="stSidebar"] {
            background: linear-gradient(180deg, #12362d 0%, #163f34 100%);
            border-right: 1px solid rgba(255,255,255,0.08);
        }
        section[data-testid="stSidebar"] * {
            color: #f1f7f5 !important;
        }
        section[data-testid="stSidebar"] [data-baseweb="select"] > div,
        section[data-testid="stSidebar"] input,
        section[data-testid="stSidebar"] textarea {
            background: rgba(255,255,255,0.08) !important;
            border: 1px solid rgba(255,255,255,0.14) !important;
        }
        .stMetric {
            background: linear-gradient(180deg, rgba(248,250,249,0.98) 0%, rgba(255,255,255,0.98) 100%);
            border: 1px solid rgba(16, 74, 61, 0.10);
            padding: 0.7rem 0.85rem;
            border-radius: 1rem;
            box-shadow: 0 12px 30px rgba(17, 48, 40, 0.05);
        }
        [data-testid="stTabs"] button[role="tab"] {
            border-radius: 999px;
            padding: 0.45rem 0.9rem;
            border: 1px solid rgba(20,52,43,0.08);
            background: rgba(255,255,255,0.55);
            margin-right: 0.25rem;
        }
        [data-testid="stTabs"] button[role="tab"][aria-selected="true"] {
            background: #103e33;
            color: white;
            border-color: #103e33;
        }
        .stDataFrame, div[data-testid="stTable"] {
            border: 1px solid rgba(20,52,43,0.08);
            border-radius: 0.9rem;
            overflow: hidden;
            background: rgba(255,255,255,0.92);
        }
        h1, h2, h3 {letter-spacing: -0.03em;}
        h1 {font-weight: 800;}
        </style>
        """,
        unsafe_allow_html=True,
    )

    st.title("HODOM Data Explorer")
    st.caption("Explorador de normalizacion, reconciliacion y metricas sanitarias construido sobre la capa intermedia/enriquecida del pipeline.")
    active_mode = "enriched" if (ENRICHED_DIR / "episode_master.csv").exists() else "intermediate"
    st.info(
        f"Capa activa: `{active_mode}`. "
        f"Directorio de lectura: `{ENRICHED_DIR if active_mode == 'enriched' else INTERMEDIATE_DIR}`"
    )

    try:
        datasets = load_data()
    except FileNotFoundError as exc:
        st.error(str(exc))
        st.stop()

    merged = datasets["merged"]
    filtered, selected_start, selected_end = filter_episodes(merged)

    if filtered.empty:
        st.warning("Los filtros dejaron el conjunto vacío.")
        st.stop()

    overview_tab, normalization_tab, review_tab, rescue_tab, territory_tab, gestoras_tab, rem_tab, explorer_tab = st.tabs(
        ["Resumen", "Normalización", "Revisión", "Rescates 2025", "Territorio", "Gestoras", "REM A21/C1", "Explorador"]
    )

    with overview_tab:
        render_executive_summary(filtered, datasets["localities"], datasets["address_resolution"])
        render_activity_panel(filtered)
    with normalization_tab:
        render_normalization_panel(
            filtered,
            datasets["quality"],
            datasets["field_provenance"],
            datasets["episode_requests"],
            datasets["episode_discharges"],
            datasets["match_review_queue"],
        )
    with review_tab:
        render_review_workbench(
            datasets["quality"],
            datasets["address_resolution"],
            datasets["match_review_queue"],
            datasets["establishments"],
            datasets["localities"],
        )
    with rescue_tab:
        render_rescue_panel(
            datasets["episodes"],
            datasets["rescue_candidates"],
            datasets["reconciliation"],
            datasets["episode_requests"],
            datasets["match_review_queue"],
        )
    with territory_tab:
        render_territory_panel(
            datasets["establishments"],
            datasets["localities"],
            datasets["address_resolution"],
            filtered,
        )
    with gestoras_tab:
        render_gestoras_panel(datasets["episodes"], datasets["episode_requests"])
    with rem_tab:
        render_rem_panel(filtered, selected_start, selected_end)
    with explorer_tab:
        render_explorer(filtered, datasets["patients"], datasets["quality"])


if __name__ == "__main__":
    main()
