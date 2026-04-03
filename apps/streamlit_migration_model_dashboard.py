from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path

import pandas as pd
import streamlit as st


REPO_DIR = Path(__file__).resolve().parents[1]
CANONICAL_DIR = REPO_DIR / "output" / "spreadsheet" / "canonical"
INTERMEDIATE_DIR = REPO_DIR / "output" / "spreadsheet" / "intermediate"
HOSP_DIR = REPO_DIR / "output" / "spreadsheet" / "hospitalizaciones"
MANUAL_DIR = REPO_DIR / "input" / "manual"

DATE_FMT = "%d/%m/%y"


@dataclass(frozen=True)
class EntitySpec:
    key: str
    label: str
    path: Path
    primary_key: str
    description: str
    focus_columns: list[str]


@dataclass(frozen=True)
class RelationSpec:
    key: str
    label: str
    left_entity: str
    right_entity: str
    left_key: str
    right_key: str
    description: str
    multi_value: bool = False
    separator: str = ","


HOSP_ENTITY_SPECS = [
    EntitySpec(
        key="ingresos",
        label="Hospitalizaciones / ingresos_minimos_estrictos",
        path=HOSP_DIR / "ingresos_minimos_estrictos.csv",
        primary_key="ingreso_id",
        description="Ingresos estrictos validados: id, run, fecha_ingreso, source.",
        focus_columns=["run", "fecha_ingreso", "source_file"],
    ),
    EntitySpec(
        key="egresos",
        label="Hospitalizaciones / egresos_minimos_estrictos",
        path=HOSP_DIR / "egresos_minimos_estrictos.csv",
        primary_key="egreso_id",
        description="Egresos estrictos validados: id, run, fecha_egreso, source.",
        focus_columns=["run", "fecha_egreso", "source_file", "source_sheet"],
    ),
    EntitySpec(
        key="ingresos_descartados",
        label="Hospitalizaciones / ingresos_descartados",
        path=HOSP_DIR / "ingresos_minimos_descartados.csv",
        primary_key="ingreso_id",
        description="Ingresos descartados por falta de fecha o resolución manual.",
        focus_columns=["run", "nombre", "fecha_ingreso", "discard_reason"],
    ),
    EntitySpec(
        key="egresos_descartados",
        label="Hospitalizaciones / egresos_descartados",
        path=HOSP_DIR / "egresos_minimos_descartados.csv",
        primary_key="egreso_id",
        description="Egresos descartados por falta de fecha o resolución manual.",
        focus_columns=["run", "nombre", "fecha_egreso", "discard_reason"],
    ),
]


ENTITY_SPECS = [
    EntitySpec(
        key="identity_master",
        label="Canonical / patient_identity_master",
        path=CANONICAL_DIR / "patient_identity_master.csv",
        primary_key="identity_patient_id",
        description="Maestro nuevo de identidad. Una fila por persona consolidada para migracion nominal.",
        focus_columns=["run", "fecha_nacimiento", "nombre", "source_patient_count", "matching_strategy", "matching_confidence"],
    ),
    EntitySpec(
        key="canonical_patient",
        label="Canonical / patient_master",
        path=CANONICAL_DIR / "patient_master.csv",
        primary_key="patient_id",
        description="Vista operacional agregada por paciente en la capa canonica.",
        focus_columns=["rut", "nombre_completo", "fecha_nacimiento_date", "total_hospitalizaciones", "estado_actual"],
    ),
    EntitySpec(
        key="stay",
        label="Canonical / hospitalization_stay",
        path=CANONICAL_DIR / "hospitalization_stay.csv",
        primary_key="stay_id",
        description="Estadias consolidadas listas para migracion y explotacion analitica.",
        focus_columns=["patient_id", "fecha_ingreso", "fecha_egreso", "estado", "source_episode_count", "episode_origin"],
    ),
    EntitySpec(
        key="episode_source",
        label="Canonical / episode_source",
        path=CANONICAL_DIR / "episode_source.csv",
        primary_key="source_id",
        description="Trazabilidad de episodios originales absorbidos por cada stay canonico.",
        focus_columns=["stay_id", "episode_id", "origin_type", "raw_file"],
    ),
    EntitySpec(
        key="missing_run_review",
        label="Canonical / patient_identity_missing_run_review",
        path=CANONICAL_DIR / "patient_identity_missing_run_review.csv",
        primary_key="identity_patient_id",
        description="Cola residual de identidades sin run para revision manual.",
        focus_columns=["nombre", "fecha_nacimiento", "candidate_count", "recommendation", "candidate_run_1"],
    ),
    EntitySpec(
        key="intermediate_patient",
        label="Intermediate / patient_master",
        path=INTERMEDIATE_DIR / "patient_master.csv",
        primary_key="patient_id",
        description="Paciente tecnico antes de reconciliacion enriquecida.",
        focus_columns=["canonical_patient_key", "identity_resolution_status", "rut", "nombre_completo", "source_files"],
    ),
    EntitySpec(
        key="identity_candidate",
        label="Intermediate / patient_identity_candidate",
        path=INTERMEDIATE_DIR / "patient_identity_candidate.csv",
        primary_key="identity_candidate_id",
        description="Candidatos de identidad generados fila a fila desde los origenes.",
        focus_columns=["patient_id", "patient_key", "patient_key_strategy", "rut_norm", "rut_valido", "review_required"],
    ),
    EntitySpec(
        key="identity_link",
        label="Intermediate / patient_identity_link",
        path=INTERMEDIATE_DIR / "patient_identity_link.csv",
        primary_key="patient_identity_link_id",
        description="Vinculo entre paciente tecnico y candidato de identidad.",
        focus_columns=["patient_id", "identity_candidate_id", "link_type", "is_primary"],
    ),
    EntitySpec(
        key="intermediate_episode",
        label="Intermediate / episode",
        path=INTERMEDIATE_DIR / "episode.csv",
        primary_key="episode_id",
        description="Episodio tecnico deduplicado antes de la reconciliacion enriquecida.",
        focus_columns=["patient_id", "fecha_ingreso", "fecha_egreso", "estado", "tipo_flujo"],
    ),
    EntitySpec(
        key="episode_source_link",
        label="Intermediate / episode_source_link",
        path=INTERMEDIATE_DIR / "episode_source_link.csv",
        primary_key="episode_source_link_id",
        description="Enlace entre episodio tecnico y filas normalizadas de origen.",
        focus_columns=["episode_id", "normalized_row_id", "source_file", "source_row_number", "is_retained_row"],
    ),
]


RELATION_SPECS = [
    RelationSpec(
        key="identity_to_patient",
        label="patient_identity_master -> canonical patient_master",
        left_entity="identity_master",
        right_entity="canonical_patient",
        left_key="source_patient_ids",
        right_key="patient_id",
        description="Relacion 1:N desde identidad canonica a pacientes operacionales fuente que quedaron dentro del cluster.",
        multi_value=True,
    ),
    RelationSpec(
        key="patient_to_stay",
        label="canonical patient_master -> hospitalization_stay",
        left_entity="canonical_patient",
        right_entity="stay",
        left_key="patient_id",
        right_key="patient_id",
        description="Relacion 1:N entre paciente canonico operativo y sus estadias consolidadas.",
    ),
    RelationSpec(
        key="stay_to_episode_source",
        label="hospitalization_stay -> episode_source",
        left_entity="stay",
        right_entity="episode_source",
        left_key="stay_id",
        right_key="stay_id",
        description="Relacion 1:N entre cada stay y los episodios originales que contribuyeron a consolidarlo.",
    ),
    RelationSpec(
        key="intermediate_patient_to_link",
        label="intermediate patient_master -> patient_identity_link",
        left_entity="intermediate_patient",
        right_entity="identity_link",
        left_key="patient_id",
        right_key="patient_id",
        description="Relacion 1:N entre paciente tecnico y sus enlaces de identidad.",
    ),
    RelationSpec(
        key="identity_link_to_candidate",
        label="patient_identity_link -> patient_identity_candidate",
        left_entity="identity_link",
        right_entity="identity_candidate",
        left_key="identity_candidate_id",
        right_key="identity_candidate_id",
        description="Relacion N:1 entre cada link y el candidato de identidad usado para resolverlo.",
    ),
    RelationSpec(
        key="episode_to_source_link",
        label="intermediate episode -> episode_source_link",
        left_entity="intermediate_episode",
        right_entity="episode_source_link",
        left_key="episode_id",
        right_key="episode_id",
        description="Relacion 1:N entre episodio tecnico y filas normalizadas retenidas/relacionadas de origen.",
    ),
]


def fmt_date_col(df: pd.DataFrame, col: str) -> pd.DataFrame:
    """Format an ISO date column to dd/mm/yy for display."""
    if col in df.columns:
        df[col] = pd.to_datetime(df[col], errors="coerce").dt.strftime(DATE_FMT).fillna("")
    return df


def build_hospitalization_pairs(
    ingresos: pd.DataFrame,
    egresos: pd.DataFrame,
    canon: pd.DataFrame,
    *,
    desde: str = "2025-01-01",
) -> tuple[pd.DataFrame, pd.DataFrame, pd.DataFrame]:
    """Match ingresos → egresos by RUN, return (pairs, orphan_ing, orphan_egr)."""
    from collections import defaultdict
    from datetime import datetime

    def pd_date(s: str):
        try:
            return datetime.fromisoformat(s).date()
        except Exception:
            return None

    ing = ingresos[ingresos["fecha_ingreso"] >= desde].to_dict("records") if not ingresos.empty else []
    egr = egresos[egresos["fecha_egreso"] >= desde].to_dict("records") if not egresos.empty else []
    all_ing = ingresos.to_dict("records") if not ingresos.empty else []

    canon_by_rut: dict[str, list[dict]] = defaultdict(list)
    if not canon.empty:
        for r in canon.to_dict("records"):
            rut = str(r.get("rut", "")).strip()
            if rut:
                canon_by_rut[rut].append(r)

    ing_by_run: dict[str, list[dict]] = defaultdict(list)
    for i in all_ing:
        run = str(i.get("run", "")).strip()
        if run:
            ing_by_run[run].append(i)

    used_ing: set[str] = set()
    used_egr: set[str] = set()
    pairs: list[dict] = []

    for e in sorted(egr, key=lambda x: x.get("fecha_egreso", "")):
        run = str(e.get("run", "")).strip()
        if not run:
            continue
        fe = e["fecha_egreso"]
        cands = []
        for i in ing_by_run.get(run, []):
            iid = i["ingreso_id"]
            if iid in used_ing:
                continue
            fi = i["fecha_ingreso"]
            if fi <= fe:
                gap = (pd_date(fe) - pd_date(fi)).days  # type: ignore[operator]
                cands.append((gap, i))
        if not cands:
            for s in canon_by_rut.get(run, []):
                fi = str(s.get("fecha_ingreso", ""))
                if fi and fi <= fe:
                    gap = (pd_date(fe) - pd_date(fi)).days  # type: ignore[operator]
                    cands.append((gap, {"ingreso_id": f"canon_{s['stay_id']}", "run": run, "fecha_ingreso": fi}))
        if cands:
            cands.sort(key=lambda x: x[0])
            gap, best = cands[0]
            if gap <= 120:
                pairs.append(
                    {
                        "run": run,
                        "fecha_ingreso": best["fecha_ingreso"],
                        "fecha_egreso": fe,
                        "dias_estadia": gap,
                        "ingreso_id": best["ingreso_id"],
                        "egreso_id": e["egreso_id"],
                    }
                )
                used_ing.add(best["ingreso_id"])
                used_egr.add(e["egreso_id"])

    orphan_ing_rows = [i for i in ing if i["ingreso_id"] not in used_ing]
    for i in list(orphan_ing_rows):
        run = str(i.get("run", "")).strip()
        if not run:
            continue
        fi_d = pd_date(i["fecha_ingreso"])
        for s in canon_by_rut.get(run, []):
            fe = str(s.get("fecha_egreso", ""))
            fe_d = pd_date(fe)
            if fe_d and fi_d and fe_d >= fi_d and (fe_d - fi_d).days <= 120:
                pairs.append(
                    {
                        "run": run,
                        "fecha_ingreso": i["fecha_ingreso"],
                        "fecha_egreso": fe,
                        "dias_estadia": (fe_d - fi_d).days,
                        "ingreso_id": i["ingreso_id"],
                        "egreso_id": f"canon_{s['stay_id']}",
                    }
                )
                orphan_ing_rows.remove(i)
                break

    orphan_egr_rows = [e for e in egr if e["egreso_id"] not in used_egr]

    return (
        pd.DataFrame(pairs) if pairs else pd.DataFrame(),
        pd.DataFrame(orphan_ing_rows) if orphan_ing_rows else pd.DataFrame(),
        pd.DataFrame(orphan_egr_rows) if orphan_egr_rows else pd.DataFrame(),
    )


def load_csv(path: Path) -> pd.DataFrame:
    if not path.exists() or path.stat().st_size == 0:
        return pd.DataFrame()
    return pd.read_csv(path)


@st.cache_data(show_spinner=False)
def load_tables() -> dict[str, pd.DataFrame]:
    tables = {spec.key: load_csv(spec.path) for spec in ENTITY_SPECS}
    for spec in HOSP_ENTITY_SPECS:
        tables[spec.key] = load_csv(spec.path)
    return tables


def relation_frame(df: pd.DataFrame, key: str, *, multi_value: bool, separator: str) -> pd.DataFrame:
    if df.empty or key not in df.columns:
        return pd.DataFrame(columns=["row_id", "join_value"])

    work = df.copy()
    row_id_col = work.columns[0]
    work["row_id"] = work[row_id_col].fillna("").astype(str)
    work[key] = work[key].fillna("").astype(str)

    if multi_value:
        work[key] = work[key].map(
            lambda value: [token.strip() for token in value.split(separator) if token.strip()]
        )
        work = work.explode(key)

    work["join_value"] = work[key].fillna("").astype(str).str.strip()
    work = work[work["join_value"] != ""]
    return work[["row_id", "join_value"]]


def build_entity_profile(df: pd.DataFrame, spec: EntitySpec) -> pd.DataFrame:
    rows = []
    for column in [spec.primary_key, *spec.focus_columns]:
        if column not in df.columns:
            rows.append(
                {
                    "columna": column,
                    "completitud_pct": 0.0,
                    "valores_unicos": 0,
                    "nulos": len(df),
                }
            )
            continue
        series = df[column]
        non_empty = series.fillna("").astype(str).str.strip() != ""
        rows.append(
            {
                "columna": column,
                "completitud_pct": round(non_empty.mean() * 100, 2) if len(df) else 0.0,
                "valores_unicos": int(series[non_empty].nunique()) if non_empty.any() else 0,
                "nulos": int((~non_empty).sum()),
            }
        )
    return pd.DataFrame(rows)


def evaluate_relation(tables: dict[str, pd.DataFrame], spec: RelationSpec) -> tuple[dict[str, int], pd.DataFrame]:
    left = tables[spec.left_entity]
    right = tables[spec.right_entity]
    left_rel = relation_frame(left, spec.left_key, multi_value=spec.multi_value, separator=spec.separator)
    right_rel = relation_frame(right, spec.right_key, multi_value=False, separator=spec.separator)

    if left_rel.empty:
        metrics = {
            "left_rows": len(left),
            "right_rows": len(right),
            "left_links": 0,
            "right_keys": int(right_rel["join_value"].nunique()) if not right_rel.empty else 0,
            "matched_links": 0,
            "orphan_links": 0,
        }
        return metrics, pd.DataFrame()

    merged = left_rel.merge(
        right_rel.rename(columns={"row_id": "target_row_id"}),
        on="join_value",
        how="left",
    )
    orphan = merged[merged["target_row_id"].isna()].copy()
    metrics = {
        "left_rows": len(left),
        "right_rows": len(right),
        "left_links": len(left_rel),
        "right_keys": int(right_rel["join_value"].nunique()) if not right_rel.empty else 0,
        "matched_links": int(merged["target_row_id"].notna().sum()),
        "orphan_links": int(merged["target_row_id"].isna().sum()),
    }
    return metrics, orphan


def render_overview(tables: dict[str, pd.DataFrame]) -> None:
    identity = tables["identity_master"]
    stays = tables["stay"]
    pending = tables["missing_run_review"]
    episode_source = tables["episode_source"]

    total_identity = len(identity)
    with_run = int(identity["run"].fillna("").astype(str).str.strip().ne("").sum()) if not identity.empty else 0
    with_birth = int(identity["fecha_nacimiento"].fillna("").astype(str).str.strip().ne("").sum()) if not identity.empty else 0

    cols = st.columns(4)
    cols[0].metric("Identidades canónicas", total_identity)
    cols[1].metric("Con run", with_run)
    cols[2].metric("Con fecha nacimiento", with_birth)
    cols[3].metric("Pendientes sin run", len(pending))

    cols = st.columns(3)
    cols[0].metric("Stays canónicos", len(stays))
    cols[1].metric("Trazas episode_source", len(episode_source))
    cols[2].metric(
        "Pacientes fuente absorbidos",
        int(identity["source_patient_count"].fillna(0).astype(int).sum()) if not identity.empty else 0,
    )

    if not identity.empty:
        summary = pd.DataFrame(
            {
                "metric": ["identidades", "con_run", "sin_run", "con_fecha_nacimiento", "clusters_multifuente"],
                "valor": [
                    len(identity),
                    with_run,
                    len(identity) - with_run,
                    with_birth,
                    int((identity["source_patient_count"].fillna(0).astype(int) > 1).sum()),
                ],
            }
        )
        st.dataframe(summary, use_container_width=True, hide_index=True)


def render_entities(tables: dict[str, pd.DataFrame]) -> None:
    spec = st.selectbox("Entidad", ENTITY_SPECS, format_func=lambda item: item.label)
    df = tables[spec.key]

    st.caption(spec.description)
    cols = st.columns(4)
    cols[0].metric("Filas", len(df))
    cols[1].metric("Primary key", spec.primary_key)
    cols[2].metric(
        "PK únicos",
        int(df[spec.primary_key].nunique()) if not df.empty and spec.primary_key in df.columns else 0,
    )
    cols[3].metric("Columnas", len(df.columns))

    profile = build_entity_profile(df, spec)
    st.subheader("Perfil")
    st.dataframe(profile, use_container_width=True, hide_index=True)

    st.subheader("Muestra")
    if df.empty:
        st.info("La entidad no tiene filas en esta corrida.")
    else:
        cols_to_show = [column for column in [spec.primary_key, *spec.focus_columns] if column in df.columns]
        st.dataframe(df[cols_to_show].head(200), use_container_width=True, hide_index=True)


def render_relations(tables: dict[str, pd.DataFrame]) -> None:
    spec = st.selectbox("Relación", RELATION_SPECS, format_func=lambda item: item.label)
    metrics, orphan = evaluate_relation(tables, spec)

    st.caption(spec.description)
    cols = st.columns(6)
    cols[0].metric("Rows origen", metrics["left_rows"])
    cols[1].metric("Rows destino", metrics["right_rows"])
    cols[2].metric("Links origen", metrics["left_links"])
    cols[3].metric("Keys destino", metrics["right_keys"])
    cols[4].metric("Links válidos", metrics["matched_links"])
    cols[5].metric("Links huérfanos", metrics["orphan_links"])

    if orphan.empty:
        st.success("No se detectaron vínculos huérfanos para esta relación.")
    else:
        st.warning("Se detectaron vínculos huérfanos. Muestra de referencia:")
        st.dataframe(orphan.head(200), use_container_width=True, hide_index=True)


def render_hospitalizaciones(tables: dict[str, pd.DataFrame]) -> None:
    ingresos = tables.get("ingresos", pd.DataFrame())
    egresos = tables.get("egresos", pd.DataFrame())
    canon = tables.get("stay", pd.DataFrame())
    ingresos_desc = tables.get("ingresos_descartados", pd.DataFrame())
    egresos_desc = tables.get("egresos_descartados", pd.DataFrame())

    # Pacientes únicos
    ing_amplio = load_csv(HOSP_DIR / "ingresos_minimos.csv")
    egr_amplio = load_csv(HOSP_DIR / "egresos_minimos.csv")

    pairs, orphan_ing, orphan_egr = build_hospitalization_pairs(ingresos, egresos, canon)

    # --- Métricas principales ---
    st.subheader("Período: 01/01/25 → hoy")
    ing_2025 = ingresos[ingresos["fecha_ingreso"] >= "2025-01-01"] if not ingresos.empty else pd.DataFrame()
    egr_2025 = egresos[egresos["fecha_egreso"] >= "2025-01-01"] if not egresos.empty else pd.DataFrame()

    c1, c2, c3, c4 = st.columns(4)
    c1.metric("Ingresos", len(ing_2025))
    c2.metric("Egresos", len(egr_2025))
    c3.metric("Pareados", len(pairs))
    c4.metric(
        "Mediana estadía",
        f"{int(pairs['dias_estadia'].median())}d" if not pairs.empty else "—",
    )

    c5, c6, c7, c8 = st.columns(4)
    c5.metric("Activos (sin egreso)", len(orphan_ing))
    c6.metric("Egresos sin ingreso", len(orphan_egr))
    c7.metric("Ingresos descartados", len(ingresos_desc))
    c8.metric("Egresos descartados", len(egresos_desc))

    # --- Distribución de estadía ---
    if not pairs.empty:
        st.subheader("Distribución de estadía")
        bins = [0, 7, 14, 30, 60, 999]
        labels = ["0-7d", "8-14d", "15-30d", "31-60d", "60+d"]
        pairs["rango"] = pd.cut(pairs["dias_estadia"], bins=bins, labels=labels, right=True)
        dist = pairs["rango"].value_counts().reindex(labels).fillna(0).astype(int)
        st.bar_chart(dist)

    # --- Construir mapa de nombres: formulario → canónico → egreso ---
    nombre_map: dict[str, str] = {}
    # 1. Desde ingresos amplios (formularios)
    if not ing_amplio.empty:
        for _, r in ing_amplio.iterrows():
            iid = str(r.get("ingreso_id", ""))
            nombre = str(r.get("nombre", "")).strip()
            if iid and nombre:
                nombre_map[iid] = nombre
    # 2. Desde canónico (para pares con ingreso canon_*)
    if not canon.empty:
        for _, r in canon.iterrows():
            sid = f"canon_{r.get('stay_id', '')}"
            nombre = str(r.get("nombre_completo", "")).strip()
            if nombre:
                nombre_map[sid] = nombre
    # 3. Fallback por RUN desde egresos amplios
    run_to_nombre: dict[str, str] = {}
    if not egr_amplio.empty:
        for _, r in egr_amplio.iterrows():
            run = str(r.get("run", "")).strip()
            nombre = str(r.get("nombre", "")).strip()
            if run and nombre and run not in run_to_nombre:
                run_to_nombre[run] = nombre

    # --- Tabla de pareados ---
    st.subheader("Hospitalizaciones pareadas")
    if not pairs.empty:
        show = pairs.copy()
        show["nombre"] = show["ingreso_id"].map(nombre_map).fillna("")
        # Fallback por RUN para los que quedaron vacíos
        mask_empty = show["nombre"].str.strip() == ""
        show.loc[mask_empty, "nombre"] = show.loc[mask_empty, "run"].map(run_to_nombre).fillna("")
        show = show[["run", "nombre", "fecha_ingreso", "fecha_egreso", "dias_estadia"]]
        show = fmt_date_col(show, "fecha_ingreso")
        show = fmt_date_col(show, "fecha_egreso")
        show.columns = ["RUN", "Nombre", "Ingreso", "Egreso", "Días"]
        show = show.sort_values("Ingreso", ascending=False)
        st.dataframe(show, use_container_width=True, hide_index=True, height=500)
    else:
        st.info("No hay pareados en el período.")

    # --- Distribución mensual ---
    if not pairs.empty:
        st.subheader("Distribución mensual")
        pairs_monthly = pairs.copy()
        pairs_monthly["mes_ingreso"] = pd.to_datetime(pairs_monthly["fecha_ingreso"], errors="coerce").dt.to_period("M").astype(str)
        monthly = pairs_monthly.groupby("mes_ingreso").agg(
            ingresos=("ingreso_id", "count"),
            dias_mediana=("dias_estadia", "median"),
        ).reset_index()
        monthly.columns = ["Mes", "Hospitalizaciones", "Mediana días"]
        st.dataframe(monthly, use_container_width=True, hide_index=True)

    # --- Ingresos sin egreso / Egresos sin ingreso ---
    col_left, col_right = st.columns(2)

    with col_left:
        st.subheader(f"Ingresos sin egreso ({len(orphan_ing)})")
        if not orphan_ing.empty:
            oi = orphan_ing.copy()
            oi["nombre"] = oi["ingreso_id"].map(nombre_map).fillna("")
            mask_empty = oi["nombre"].str.strip() == ""
            oi.loc[mask_empty, "nombre"] = oi.loc[mask_empty, "run"].map(run_to_nombre).fillna("")
            from datetime import date

            oi["dias_activo"] = (
                pd.to_datetime(date.today().isoformat())
                - pd.to_datetime(oi["fecha_ingreso"], errors="coerce")
            ).dt.days
            oi = oi[["run", "nombre", "fecha_ingreso", "dias_activo"]]
            oi = fmt_date_col(oi, "fecha_ingreso")
            oi.columns = ["RUN", "Nombre", "Ingreso", "Días"]
            oi = oi.sort_values("Días", ascending=False)
            st.dataframe(oi, use_container_width=True, hide_index=True)
        else:
            st.success("Todos los ingresos tienen egreso.")

    with col_right:
        st.subheader(f"Egresos sin ingreso ({len(orphan_egr)})")
        if not orphan_egr.empty:
            oe = orphan_egr.copy()
            if not egr_amplio.empty:
                nombre_map_egr = dict(zip(egr_amplio["egreso_id"], egr_amplio["nombre"]))
                oe["nombre"] = oe["egreso_id"].map(nombre_map_egr).fillna("")
            else:
                oe["nombre"] = ""
            oe_cols = ["run", "nombre", "fecha_egreso"]
            if "source_sheet" in oe.columns:
                oe_cols.append("source_sheet")
            oe = oe[oe_cols]
            oe = fmt_date_col(oe, "fecha_egreso")
            col_names = ["RUN", "Nombre", "Egreso"]
            if "source_sheet" in oe.columns:
                col_names.append("Fuente")
            oe.columns = col_names
            st.dataframe(oe, use_container_width=True, hide_index=True)
        else:
            st.success("Todos los egresos tienen ingreso.")

    # --- Buscador por RUN ---
    st.subheader("Buscar paciente por RUN")
    search_run = st.text_input("RUN", placeholder="12345678-9")
    if search_run.strip():
        run_q = search_run.strip()
        st.markdown(f"**Ingresos** de `{run_q}`:")
        if not ingresos.empty:
            ri = ingresos[ingresos["run"] == run_q].copy()
            ri = fmt_date_col(ri, "fecha_ingreso")
            st.dataframe(ri, use_container_width=True, hide_index=True)
        st.markdown(f"**Egresos** de `{run_q}`:")
        if not egresos.empty:
            re_ = egresos[egresos["run"] == run_q].copy()
            re_ = fmt_date_col(re_, "fecha_egreso")
            st.dataframe(re_, use_container_width=True, hide_index=True)
        st.markdown(f"**Pareados** de `{run_q}`:")
        if not pairs.empty:
            rp = pairs[pairs["run"] == run_q].copy()
            rp = fmt_date_col(rp, "fecha_ingreso")
            rp = fmt_date_col(rp, "fecha_egreso")
            st.dataframe(rp, use_container_width=True, hide_index=True)


def render_pending(tables: dict[str, pd.DataFrame]) -> None:
    pending = tables["missing_run_review"]
    duplicate_candidates = load_csv(CANONICAL_DIR / "duplicate_candidate.csv")
    review_queue = load_csv(CANONICAL_DIR / "review_queue.csv")
    manual_resolution = load_csv(MANUAL_DIR / "manual_resolution.csv")

    st.subheader("Pendientes de identidad")
    if pending.empty:
        st.success("No quedan casos sin run en patient_identity_missing_run_review.")
    else:
        st.dataframe(pending, use_container_width=True, hide_index=True)

    col1, col2 = st.columns(2)
    with col1:
        st.subheader("Duplicate candidates")
        st.dataframe(duplicate_candidates.head(200), use_container_width=True, hide_index=True)
    with col2:
        st.subheader("Manual resolution")
        st.dataframe(manual_resolution.tail(200), use_container_width=True, hide_index=True)

    st.subheader("Review queue")
    st.dataframe(review_queue.head(200), use_container_width=True, hide_index=True)


def main() -> None:
    st.set_page_config(
        page_title="HODOM / Modelo de Migración",
        layout="wide",
    )
    st.title("HODOM / Dashboard de Entidades y Relaciones")
    st.caption(
        "Vista separada del pipeline de migración, enfocada sólo en la normalización actual, "
        "las entidades materializadas y las relaciones que preparan la migración."
    )

    tables = load_tables()
    overview_tab, hosp_tab, entity_tab, relation_tab, pending_tab = st.tabs(
        ["Resumen", "Hospitalizaciones", "Entidades", "Relaciones", "Pendientes"]
    )

    with overview_tab:
        render_overview(tables)
    with hosp_tab:
        render_hospitalizaciones(tables)
    with entity_tab:
        render_entities(tables)
    with relation_tab:
        render_relations(tables)
    with pending_tab:
        render_pending(tables)


if __name__ == "__main__":
    main()
