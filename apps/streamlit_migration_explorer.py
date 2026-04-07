"""Dashboard HDOS — Migration Explorer (PostgreSQL)."""

from __future__ import annotations

import os
from contextlib import contextmanager

import pandas as pd
import psycopg
import streamlit as st

DATABASE_URL = os.environ.get(
    "DATABASE_URL",
    "postgresql://hodom:hodom@hodom-pg:5432/hodom",
)

st.set_page_config(page_title="HDOS — Migración Explorer", layout="wide")


@contextmanager
def get_conn():
    conn = psycopg.connect(DATABASE_URL)
    try:
        yield conn
    finally:
        conn.close()


def query_df(sql: str, params: tuple = ()) -> pd.DataFrame:
    with get_conn() as conn:
        return pd.read_sql(sql, conn, params=params)


# ── Header ────────────────────────────────────────────────────
st.title("HDOS — Migración Explorer")
st.caption("Explorador read-only de entidades migradas a PostgreSQL v4")

# ── Tabs ──────────────────────────────────────────────────────
tab_overview, tab_pac, tab_est, tab_cli, tab_kpi, tab_ter, tab_prov = st.tabs(
    ["Overview", "Pacientes", "Estadías", "Clínico", "KPI Diario", "Territorial", "Proveniencia"]
)


# ═══════════════════════════════════════════════════════════════
# TAB 1 — Overview
# ═══════════════════════════════════════════════════════════════
with tab_overview:
    st.header("Overview")

    # Entity counts
    try:
        cnt_pacientes = query_df("SELECT COUNT(*) AS n FROM clinical.paciente")["n"].iloc[0]
        cnt_estadias = query_df("SELECT COUNT(*) AS n FROM clinical.estadia")["n"].iloc[0]
        cnt_establecimientos = query_df("SELECT COUNT(*) AS n FROM territorial.establecimiento")["n"].iloc[0]
        cnt_ubicaciones = query_df("SELECT COUNT(*) AS n FROM territorial.ubicacion")["n"].iloc[0]
        cnt_provenance = query_df("SELECT COUNT(*) AS n FROM migration.provenance")["n"].iloc[0]
        cnt_strict_hosp = query_df("SELECT COUNT(*) AS n FROM strict.hospitalizacion")["n"].iloc[0]

        cnt_condiciones = query_df("SELECT COUNT(*) AS n FROM clinical.condicion")["n"].iloc[0]
        cnt_reqs = query_df("SELECT COUNT(*) AS n FROM clinical.requerimiento_cuidado")["n"].iloc[0]
        cnt_needs = query_df("SELECT COUNT(*) AS n FROM clinical.necesidad_profesional")["n"].iloc[0]
        cnt_kpi = query_df("SELECT COUNT(*) AS n FROM reporting.kpi_diario")["n"].iloc[0]
        cnt_ep_src = query_df("SELECT COUNT(*) AS n FROM operational.estadia_episodio_fuente")["n"].iloc[0]

        col1, col2, col3, col4, col5 = st.columns(5)
        col1.metric("Pacientes", cnt_pacientes)
        col2.metric("Estadías", cnt_estadias)
        col3.metric("Condiciones", cnt_condiciones)
        col4.metric("Requerimientos", cnt_reqs)
        col5.metric("Provenance", cnt_provenance)

        col6, col7, col8, col9, col10 = st.columns(5)
        col6.metric("Necesidades prof.", cnt_needs)
        col7.metric("Episode sources", cnt_ep_src)
        col8.metric("KPI días", cnt_kpi)
        col9.metric("Establecimientos", cnt_establecimientos)
        col10.metric("Ubicaciones", cnt_ubicaciones)

        # Alertas
        rechazadas = int(cnt_strict_hosp) - int(cnt_estadias)
        if rechazadas > 0:
            st.warning(
                f"**{rechazadas} estadías rechazadas** — "
                f"{cnt_strict_hosp} strict.hospitalizacion vs {cnt_estadias} clinical.estadia"
            )
        else:
            st.success("Sin estadías rechazadas — cobertura 1:1 strict → clinical")

        # Estado por functor
        st.subheader("Estado por functor (phase)")
        df_phase = query_df(
            """
            SELECT phase,
                   COUNT(DISTINCT target_pk) AS objetos,
                   COUNT(*) AS registros
            FROM migration.provenance
            GROUP BY phase
            ORDER BY phase
            """
        )
        if not df_phase.empty:
            st.dataframe(df_phase, use_container_width=True, hide_index=True)
        else:
            st.info("Sin datos de provenance")

        # Estadías sin match canonical
        st.subheader("Estadías sin match canonical")
        df_no_canon = query_df(
            """
            SELECT e.stay_id, p.nombre_completo, p.rut,
                   e.fecha_ingreso, e.fecha_egreso, e.estado
            FROM clinical.estadia e
            JOIN clinical.paciente p ON p.patient_id = e.patient_id
            WHERE e.stay_id NOT IN (
                SELECT DISTINCT target_pk::text
                FROM migration.provenance
                WHERE target_table = 'clinical.estadia'
                  AND source_type = 'canonical'
                  AND field_name IS NOT NULL
            )
            ORDER BY e.fecha_ingreso DESC
            """
        )
        if df_no_canon.empty:
            st.success("Todas las estadías tienen match canonical")
        else:
            st.warning(f"{len(df_no_canon)} estadías sin match canonical")
            st.dataframe(df_no_canon, use_container_width=True, hide_index=True)

    except Exception as exc:
        st.error(f"Error de conexión: {exc}")


# ═══════════════════════════════════════════════════════════════
# TAB 2 — Pacientes
# ═══════════════════════════════════════════════════════════════
with tab_pac:
    st.header("Pacientes")

    # Sidebar-style filters in columns
    col_s, col_f1, col_f2, col_f3 = st.columns([2, 1, 1, 1])
    with col_s:
        buscar = st.text_input("Buscar RUT / nombre", key="pac_buscar")
    with col_f1:
        filtro_sexo = st.selectbox("Sexo", ["Todos", "M", "F"], key="pac_sexo")
    with col_f2:
        filtro_estado = st.selectbox(
            "Estado", ["Todos", "activo", "egresado", "fallecido"], key="pac_estado"
        )
    with col_f3:
        filtro_comuna = st.text_input("Comuna", key="pac_comuna")

    try:
        df_pac = query_df(
            """
            SELECT p.patient_id, p.nombre_completo, p.rut, p.sexo, p.fecha_nacimiento,
                   p.comuna, p.cesfam, p.prevision, p.estado_actual,
                   COUNT(e.stay_id) AS estadias
            FROM clinical.paciente p
            LEFT JOIN clinical.estadia e ON e.patient_id = p.patient_id
            GROUP BY p.patient_id
            ORDER BY p.nombre_completo
            """
        )

        # Apply filters
        if buscar:
            mask = (
                df_pac["nombre_completo"].str.upper().str.contains(buscar.upper(), na=False)
                | df_pac["rut"].str.contains(buscar, na=False)
            )
            df_pac = df_pac[mask]
        if filtro_sexo != "Todos":
            df_pac = df_pac[df_pac["sexo"] == filtro_sexo]
        if filtro_estado != "Todos":
            df_pac = df_pac[df_pac["estado_actual"] == filtro_estado]
        if filtro_comuna:
            df_pac = df_pac[
                df_pac["comuna"].str.upper().str.contains(filtro_comuna.upper(), na=False)
            ]

        st.caption(f"{len(df_pac)} pacientes")

        # Selection for drill-down
        event = st.dataframe(
            df_pac.drop(columns=["patient_id"]),
            use_container_width=True,
            hide_index=True,
            on_select="rerun",
            selection_mode="single-row",
            column_config={
                "nombre_completo": st.column_config.TextColumn("Nombre", width="large"),
                "rut": st.column_config.TextColumn("RUT", width="small"),
                "sexo": st.column_config.TextColumn("Sexo", width="small"),
                "fecha_nacimiento": st.column_config.DateColumn("Nac."),
                "comuna": st.column_config.TextColumn("Comuna"),
                "cesfam": st.column_config.TextColumn("CESFAM"),
                "prevision": st.column_config.TextColumn("Previsión"),
                "estado_actual": st.column_config.TextColumn("Estado"),
                "estadias": st.column_config.NumberColumn("Estadías", width="small"),
            },
        )

        # Drill-down
        sel = event.selection.rows if event and hasattr(event, "selection") else []
        if sel:
            idx = sel[0]
            row = df_pac.iloc[idx]
            patient_id = row["patient_id"]

            with st.expander(f"Detalle: {row['nombre_completo']} — {row['rut']}", expanded=True):
                # Stays
                df_stays = query_df(
                    """
                    SELECT e.stay_id, e.fecha_ingreso, e.fecha_egreso, e.estado,
                           e.diagnostico_principal, e.tipo_egreso, e.origen_derivacion,
                           est.nombre AS establecimiento, e.confidence_level
                    FROM clinical.estadia e
                    LEFT JOIN territorial.establecimiento est
                        ON est.establecimiento_id = e.establecimiento_id
                    WHERE e.patient_id = %s
                    ORDER BY e.fecha_ingreso
                    """,
                    (str(patient_id),),
                )
                st.subheader("Estadías")
                if df_stays.empty:
                    st.info("Sin estadías")
                else:
                    st.dataframe(df_stays, use_container_width=True, hide_index=True)

                # Field-level provenance
                st.subheader("Proveniencia (field-level)")
                df_prov = query_df(
                    """
                    SELECT field_name, source_type, source_file
                    FROM migration.provenance
                    WHERE target_table = 'clinical.paciente'
                      AND target_pk = %s
                    ORDER BY field_name
                    """,
                    (str(patient_id),),
                )
                if df_prov.empty:
                    st.info("Sin registros de proveniencia")
                else:
                    # Render with badges
                    for _, prow in df_prov.iterrows():
                        source = prow["source_type"] or ""
                        if source == "strict":
                            badge = ":green[strict]"
                        elif source == "canonical":
                            badge = ":blue[canonical]"
                        else:
                            badge = f"`{source}`"
                        field = prow["field_name"] or "—"
                        file_ = prow["source_file"] or "—"
                        st.markdown(f"- **{field}** {badge} — `{file_}`")

    except Exception as exc:
        st.error(f"Error: {exc}")


# ═══════════════════════════════════════════════════════════════
# TAB 3 — Estadías
# ═══════════════════════════════════════════════════════════════
with tab_est:
    st.header("Estadías")

    col_f1, col_f2, col_f3, col_f4, col_f5 = st.columns(5)
    with col_f1:
        filtro_est_estado = st.selectbox(
            "Estado", ["Todos", "activo", "egresado", "fallecido"], key="est_estado"
        )
    with col_f2:
        fecha_desde = st.date_input("Fecha ingreso desde", value=None, key="est_desde")
    with col_f3:
        fecha_hasta = st.date_input("Fecha ingreso hasta", value=None, key="est_hasta")
    with col_f4:
        filtro_establecimiento = st.text_input("Establecimiento", key="est_estab")
    with col_f5:
        filtro_diag = st.selectbox(
            "Diagnóstico", ["Todos", "Con diagnóstico", "Sin diagnóstico"], key="est_diag"
        )

    try:
        df_est = query_df(
            """
            SELECT e.stay_id, e.patient_id, p.nombre_completo, p.rut,
                   e.fecha_ingreso, e.fecha_egreso, e.estado, e.diagnostico_principal,
                   e.tipo_egreso, e.origen_derivacion, e.establecimiento_id,
                   est.nombre AS establecimiento_nombre, e.confidence_level
            FROM clinical.estadia e
            JOIN clinical.paciente p ON p.patient_id = e.patient_id
            LEFT JOIN territorial.establecimiento est
                ON est.establecimiento_id = e.establecimiento_id
            ORDER BY e.fecha_ingreso DESC
            """
        )

        # Apply filters
        if filtro_est_estado != "Todos":
            df_est = df_est[df_est["estado"] == filtro_est_estado]
        if fecha_desde:
            df_est = df_est[pd.to_datetime(df_est["fecha_ingreso"]).dt.date >= fecha_desde]
        if fecha_hasta:
            df_est = df_est[pd.to_datetime(df_est["fecha_ingreso"]).dt.date <= fecha_hasta]
        if filtro_establecimiento:
            df_est = df_est[
                df_est["establecimiento_nombre"]
                .str.upper()
                .str.contains(filtro_establecimiento.upper(), na=False)
            ]
        if filtro_diag == "Con diagnóstico":
            df_est = df_est[df_est["diagnostico_principal"].notna() & (df_est["diagnostico_principal"] != "")]
        elif filtro_diag == "Sin diagnóstico":
            df_est = df_est[df_est["diagnostico_principal"].isna() | (df_est["diagnostico_principal"] == "")]

        st.caption(f"{len(df_est)} estadías")

        event_est = st.dataframe(
            df_est.drop(columns=["patient_id", "establecimiento_id"]),
            use_container_width=True,
            hide_index=True,
            on_select="rerun",
            selection_mode="single-row",
            column_config={
                "stay_id": st.column_config.TextColumn("Stay ID", width="small"),
                "nombre_completo": st.column_config.TextColumn("Paciente", width="large"),
                "rut": st.column_config.TextColumn("RUT", width="small"),
                "fecha_ingreso": st.column_config.DateColumn("Ingreso"),
                "fecha_egreso": st.column_config.DateColumn("Egreso"),
                "estado": st.column_config.TextColumn("Estado", width="small"),
                "diagnostico_principal": st.column_config.TextColumn("Diagnóstico"),
                "tipo_egreso": st.column_config.TextColumn("Tipo Egreso"),
                "origen_derivacion": st.column_config.TextColumn("Origen"),
                "establecimiento_nombre": st.column_config.TextColumn("Establecimiento"),
                "confidence_level": st.column_config.TextColumn("Confidence", width="small"),
            },
        )

        # Drill-down
        sel_est = event_est.selection.rows if event_est and hasattr(event_est, "selection") else []
        if sel_est:
            idx = sel_est[0]
            row = df_est.iloc[idx]
            stay_id = row["stay_id"]
            patient_id = row["patient_id"]

            with st.expander(
                f"Detalle estadía {stay_id} — {row['nombre_completo']}", expanded=True
            ):
                col_a, col_b = st.columns(2)
                with col_a:
                    st.subheader("Paciente")
                    df_p = query_df(
                        """
                        SELECT nombre_completo, rut, sexo, fecha_nacimiento,
                               comuna, cesfam, prevision, estado_actual
                        FROM clinical.paciente
                        WHERE patient_id = %s
                        """,
                        (str(patient_id),),
                    )
                    if not df_p.empty:
                        for col, val in df_p.iloc[0].items():
                            st.markdown(f"**{col}**: {val}")

                with col_b:
                    st.subheader("Establecimiento")
                    est_id = row.get("establecimiento_id")
                    if est_id and pd.notna(est_id):
                        df_estab = query_df(
                            """
                            SELECT nombre, tipo, comuna, servicio_salud
                            FROM territorial.establecimiento
                            WHERE establecimiento_id = %s
                            """,
                            (str(est_id),),
                        )
                        if not df_estab.empty:
                            for col, val in df_estab.iloc[0].items():
                                st.markdown(f"**{col}**: {val}")
                    else:
                        st.info("Sin establecimiento asociado")

                st.subheader("Proveniencia")
                df_prov_est = query_df(
                    """
                    SELECT field_name, source_type, source_file, phase, source_key
                    FROM migration.provenance
                    WHERE target_table = 'clinical.estadia'
                      AND target_pk = %s
                    ORDER BY COALESCE(field_name, '')
                    """,
                    (str(stay_id),),
                )
                if df_prov_est.empty:
                    st.warning("Sin provenance — posible stay_id fallback")
                else:
                    has_canonical = any(
                        r["source_type"] == "canonical" and r.get("field_name")
                        for _, r in df_prov_est.iterrows()
                    )
                    if not has_canonical:
                        st.warning("Flag: stay_id fallback — sin field-level canonical")
                    st.dataframe(df_prov_est, use_container_width=True, hide_index=True)

    except Exception as exc:
        st.error(f"Error: {exc}")


# ═══════════════════════════════════════════════════════════════
# TAB 4 — Clínico (F₅)
# ═══════════════════════════════════════════════════════════════
with tab_cli:
    st.header("Enriquecimiento Clínico")

    sub_cond, sub_req, sub_need = st.tabs(["Condiciones / Dx", "Requerimientos", "Necesidades Prof."])

    with sub_cond:
        try:
            buscar_dx = st.text_input("Buscar diagnóstico (CIE-10 o texto)", key="cli_dx_buscar")
            df_cond = query_df(
                """
                SELECT c.condition_id, p.nombre_completo, p.rut,
                       e.fecha_ingreso, c.codigo_cie10, c.descripcion, c.estado_clinico
                FROM clinical.condicion c
                JOIN clinical.estadia e ON e.stay_id = c.stay_id
                JOIN clinical.paciente p ON p.patient_id = c.patient_id
                ORDER BY e.fecha_ingreso DESC, c.descripcion
                """
            )
            if buscar_dx:
                mask = (
                    df_cond["descripcion"].str.upper().str.contains(buscar_dx.upper(), na=False)
                    | df_cond["codigo_cie10"].str.upper().str.contains(buscar_dx.upper(), na=False)
                )
                df_cond = df_cond[mask]
            st.caption(f"{len(df_cond)} condiciones")
            st.dataframe(
                df_cond.drop(columns=["condition_id"]),
                use_container_width=True, hide_index=True,
                column_config={
                    "nombre_completo": st.column_config.TextColumn("Paciente", width="medium"),
                    "rut": st.column_config.TextColumn("RUT", width="small"),
                    "fecha_ingreso": st.column_config.DateColumn("Ingreso"),
                    "codigo_cie10": st.column_config.TextColumn("CIE-10", width="small"),
                    "descripcion": st.column_config.TextColumn("Descripción", width="large"),
                    "estado_clinico": st.column_config.TextColumn("Estado", width="small"),
                },
            )

            # Top diagnósticos
            st.subheader("Top diagnósticos")
            df_top_dx = query_df(
                """
                SELECT COALESCE(codigo_cie10, '(sin código)') AS cie10,
                       descripcion, COUNT(*) AS n
                FROM clinical.condicion
                GROUP BY codigo_cie10, descripcion
                ORDER BY n DESC
                LIMIT 20
                """
            )
            st.dataframe(df_top_dx, use_container_width=True, hide_index=True)

        except Exception as exc:
            st.error(f"Error: {exc}")

    with sub_req:
        try:
            df_req = query_df(
                """
                SELECT r.tipo, r.valor_normalizado, r.activo, COUNT(*) AS n
                FROM clinical.requerimiento_cuidado r
                GROUP BY r.tipo, r.valor_normalizado, r.activo
                ORDER BY r.tipo, n DESC
                """
            )
            st.caption(f"{len(df_req)} combinaciones tipo/valor")
            st.dataframe(df_req, use_container_width=True, hide_index=True)

            st.subheader("Distribución por tipo")
            df_req_tipo = query_df(
                """
                SELECT tipo, COUNT(*) AS n
                FROM clinical.requerimiento_cuidado
                GROUP BY tipo ORDER BY n DESC
                """
            )
            st.bar_chart(df_req_tipo.set_index("tipo"))

        except Exception as exc:
            st.error(f"Error: {exc}")

    with sub_need:
        try:
            df_need = query_df(
                """
                SELECT profesion_requerida, nivel_necesidad, COUNT(*) AS n
                FROM clinical.necesidad_profesional
                GROUP BY profesion_requerida, nivel_necesidad
                ORDER BY n DESC
                """
            )
            st.caption(f"{len(df_need)} combinaciones profesión/nivel")
            st.dataframe(df_need, use_container_width=True, hide_index=True)

            st.subheader("Distribución por profesión")
            df_need_prof = query_df(
                """
                SELECT profesion_requerida AS profesion, COUNT(*) AS n
                FROM clinical.necesidad_profesional
                GROUP BY profesion_requerida ORDER BY n DESC
                """
            )
            st.bar_chart(df_need_prof.set_index("profesion"))

        except Exception as exc:
            st.error(f"Error: {exc}")


# ═══════════════════════════════════════════════════════════════
# TAB 5 — KPI Diario (F₁₀)
# ═══════════════════════════════════════════════════════════════
with tab_kpi:
    st.header("KPI Diario")

    try:
        df_kpi = query_df(
            """
            SELECT fecha, pacientes_activos, visitas_realizadas
            FROM reporting.kpi_diario
            ORDER BY fecha
            """
        )

        if df_kpi.empty:
            st.info("Sin datos de KPI diario")
        else:
            col_k1, col_k2, col_k3 = st.columns(3)
            col_k1.metric("Días con datos", len(df_kpi))
            col_k2.metric("Promedio visitas/día", f"{df_kpi['visitas_realizadas'].mean():.1f}")
            col_k3.metric("Promedio pacientes activos", f"{df_kpi['pacientes_activos'].mean():.1f}")

            st.subheader("Visitas realizadas por día")
            chart_data = df_kpi.set_index("fecha")[["visitas_realizadas", "pacientes_activos"]]
            st.line_chart(chart_data)

            st.subheader("Resumen mensual")
            df_kpi["mes"] = pd.to_datetime(df_kpi["fecha"]).dt.to_period("M").astype(str)
            df_monthly = df_kpi.groupby("mes").agg(
                dias=("fecha", "count"),
                visitas_total=("visitas_realizadas", "sum"),
                visitas_promedio=("visitas_realizadas", "mean"),
                pacientes_promedio=("pacientes_activos", "mean"),
            ).reset_index()
            df_monthly["visitas_promedio"] = df_monthly["visitas_promedio"].round(1)
            df_monthly["pacientes_promedio"] = df_monthly["pacientes_promedio"].round(1)
            st.dataframe(df_monthly, use_container_width=True, hide_index=True)

            # Desglose por profesión (desde provenance)
            st.subheader("Desglose por profesión (último mes con datos)")
            df_prof = query_df(
                """
                SELECT field_name, SUM(
                    CAST(
                        SPLIT_PART(SPLIT_PART(source_key, '|', 2), '=', 2) AS INTEGER
                    )
                ) AS total_visitas
                FROM migration.provenance
                WHERE phase = 'F10' AND field_name LIKE 'visitas_%'
                GROUP BY field_name
                ORDER BY total_visitas DESC
                """
            )
            if not df_prof.empty:
                df_prof["profesion"] = df_prof["field_name"].str.replace("visitas_", "")
                st.bar_chart(df_prof.set_index("profesion")["total_visitas"])

    except Exception as exc:
        st.error(f"Error: {exc}")


# ═══════════════════════════════════════════════════════════════
# TAB 6 — Territorial
# ═══════════════════════════════════════════════════════════════
with tab_ter:
    st.header("Territorial")

    sub_estab, sub_ubic = st.tabs(["Establecimientos", "Ubicaciones"])

    with sub_estab:
        try:
            df_establecimientos = query_df(
                """
                SELECT est.establecimiento_id, est.nombre, est.tipo, est.comuna,
                       est.servicio_salud, COUNT(e.stay_id) AS estadias
                FROM territorial.establecimiento est
                LEFT JOIN clinical.estadia e ON e.establecimiento_id = est.establecimiento_id
                GROUP BY est.establecimiento_id
                ORDER BY estadias DESC
                """
            )
            st.caption(f"{len(df_establecimientos)} establecimientos")
            st.dataframe(
                df_establecimientos,
                use_container_width=True,
                hide_index=True,
                column_config={
                    "establecimiento_id": st.column_config.TextColumn("ID", width="small"),
                    "nombre": st.column_config.TextColumn("Nombre", width="large"),
                    "tipo": st.column_config.TextColumn("Tipo"),
                    "comuna": st.column_config.TextColumn("Comuna"),
                    "servicio_salud": st.column_config.TextColumn("Servicio Salud"),
                    "estadias": st.column_config.NumberColumn("Estadías", width="small"),
                },
            )
        except Exception as exc:
            st.error(f"Error: {exc}")

    with sub_ubic:
        try:
            df_ubic_all = query_df(
                """
                SELECT location_id, nombre_oficial, comuna, tipo, latitud, longitud
                FROM territorial.ubicacion
                ORDER BY comuna, nombre_oficial
                """
            )
            comunas_ubic = ["Todas"] + sorted(df_ubic_all["comuna"].dropna().unique().tolist())
            filtro_comuna_ubic = st.selectbox("Filtrar por comuna", comunas_ubic, key="ubic_comuna")

            df_ubic = df_ubic_all
            if filtro_comuna_ubic != "Todas":
                df_ubic = df_ubic_all[df_ubic_all["comuna"] == filtro_comuna_ubic]

            st.caption(f"{len(df_ubic)} ubicaciones")
            st.dataframe(
                df_ubic,
                use_container_width=True,
                hide_index=True,
                column_config={
                    "location_id": st.column_config.TextColumn("ID", width="small"),
                    "nombre_oficial": st.column_config.TextColumn("Nombre", width="large"),
                    "comuna": st.column_config.TextColumn("Comuna"),
                    "tipo": st.column_config.TextColumn("Tipo"),
                    "latitud": st.column_config.NumberColumn("Lat", format="%.6f"),
                    "longitud": st.column_config.NumberColumn("Lng", format="%.6f"),
                },
            )
        except Exception as exc:
            st.error(f"Error: {exc}")


# ═══════════════════════════════════════════════════════════════
# TAB 5 — Proveniencia
# ═══════════════════════════════════════════════════════════════
with tab_prov:
    st.header("Proveniencia")

    try:
        # Get filter options
        df_phases = query_df("SELECT DISTINCT phase FROM migration.provenance ORDER BY phase")
        df_source_types = query_df(
            "SELECT DISTINCT source_type FROM migration.provenance ORDER BY source_type"
        )
        df_tables = query_df(
            "SELECT DISTINCT target_table FROM migration.provenance ORDER BY target_table"
        )

        col_f1, col_f2, col_f3 = st.columns(3)
        with col_f1:
            phases = ["Todos"] + df_phases["phase"].dropna().tolist()
            filtro_phase = st.selectbox("Phase", phases, key="prov_phase")
        with col_f2:
            source_types = ["Todos"] + df_source_types["source_type"].dropna().tolist()
            filtro_source = st.selectbox("Source type", source_types, key="prov_source")
        with col_f3:
            tables = ["Todas"] + df_tables["target_table"].dropna().tolist()
            filtro_table = st.selectbox("Target table", tables, key="prov_table")

        # Build query with filters
        where_parts = []
        params_list: list = []
        if filtro_phase != "Todos":
            where_parts.append("phase = %s")
            params_list.append(filtro_phase)
        if filtro_source != "Todos":
            where_parts.append("source_type = %s")
            params_list.append(filtro_source)
        if filtro_table != "Todas":
            where_parts.append("target_table = %s")
            params_list.append(filtro_table)

        where_clause = ("WHERE " + " AND ".join(where_parts)) if where_parts else ""

        df_prov_main = query_df(
            f"""
            SELECT target_table, target_pk, source_type, source_file, source_key,
                   phase, field_name, created_at
            FROM migration.provenance
            {where_clause}
            ORDER BY created_at DESC
            LIMIT 1000
            """,
            tuple(params_list),
        )

        st.caption(f"{len(df_prov_main)} registros (max 1000)")
        st.dataframe(
            df_prov_main,
            use_container_width=True,
            hide_index=True,
            column_config={
                "target_table": st.column_config.TextColumn("Tabla"),
                "target_pk": st.column_config.TextColumn("PK"),
                "source_type": st.column_config.TextColumn("Source type"),
                "source_file": st.column_config.TextColumn("Archivo fuente"),
                "source_key": st.column_config.TextColumn("Source key"),
                "phase": st.column_config.TextColumn("Phase"),
                "field_name": st.column_config.TextColumn("Campo"),
                "created_at": st.column_config.DatetimeColumn("Creado"),
            },
        )

        # Stats table
        st.subheader("Estadísticas por tabla y source_type")
        df_stats = query_df(
            """
            SELECT
                target_table,
                source_type,
                COUNT(*) FILTER (WHERE field_name IS NULL) AS row_level,
                COUNT(*) FILTER (WHERE field_name IS NOT NULL) AS field_level
            FROM migration.provenance
            GROUP BY target_table, source_type
            ORDER BY target_table
            """
        )
        st.dataframe(
            df_stats,
            use_container_width=True,
            hide_index=True,
            column_config={
                "target_table": st.column_config.TextColumn("Tabla"),
                "source_type": st.column_config.TextColumn("Source type"),
                "row_level": st.column_config.NumberColumn("Row-level"),
                "field_level": st.column_config.NumberColumn("Field-level"),
            },
        )

    except Exception as exc:
        st.error(f"Error: {exc}")
