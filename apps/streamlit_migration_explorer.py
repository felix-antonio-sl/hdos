"""Dashboard HDOS — Migration Explorer (PostgreSQL)."""

from __future__ import annotations

import os
from contextlib import contextmanager

import pandas as pd
import psycopg
import pydeck as pdk
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
tab_overview, tab_pac, tab_est, tab_cli, tab_vis, tab_kpi, tab_ter, tab_mapa, tab_satis, tab_prov = st.tabs(
    ["Overview", "Pacientes", "Estadías", "Clínico", "Operacional", "KPI Diario", "Territorial", "Mapa", "Satisfacción", "Proveniencia"]
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

        cnt_visitas = query_df("SELECT COUNT(*) AS n FROM operational.visita")["n"].iloc[0]
        cnt_profesionales = query_df("SELECT COUNT(*) AS n FROM operational.profesional")["n"].iloc[0]
        cnt_epicrisis = query_df("SELECT COUNT(*) AS n FROM clinical.epicrisis")["n"].iloc[0]
        cnt_llamadas = query_df("SELECT COUNT(*) AS n FROM operational.registro_llamada")["n"].iloc[0]

        col6, col7, col8, col9, col10 = st.columns(5)
        col6.metric("Visitas prog.", cnt_visitas)
        col7.metric("Profesionales", cnt_profesionales)
        col8.metric("Epicrisis", cnt_epicrisis)
        col9.metric("Llamadas", cnt_llamadas)
        col10.metric("KPI días", cnt_kpi)

        cnt_prestaciones = query_df("SELECT COUNT(*) AS n FROM reference.catalogo_prestacion")["n"].iloc[0]
        cnt_encuestas = query_df("SELECT COUNT(*) AS n FROM reporting.encuesta_satisfaccion")["n"].iloc[0]
        cnt_domicilios = query_df("SELECT COUNT(*) AS n FROM clinical.domicilio")["n"].iloc[0]
        cnt_localizaciones = query_df("SELECT COUNT(*) AS n FROM territorial.localizacion")["n"].iloc[0]

        col11, col12, col13, col14 = st.columns(4)
        col11.metric("Prestaciones catálogo", cnt_prestaciones)
        col12.metric("Encuestas satisfacción", cnt_encuestas)
        col13.metric("Domicilios", cnt_domicilios)
        col14.metric("Localizaciones", cnt_localizaciones)

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
# TAB 5 — Operacional (F₆-F₉)
# ═══════════════════════════════════════════════════════════════
with tab_vis:
    st.header("Operacional")

    sub_visitas, sub_notas, sub_disp, sub_epi, sub_prest, sub_llam, sub_prof = st.tabs(
        ["Visitas", "Notas Evolución", "Dispositivos", "Epicrisis", "Prestaciones REM", "Llamadas", "Profesionales"]
    )

    with sub_visitas:
        try:
            buscar_vis = st.text_input("Buscar paciente (RUT / nombre)", key="vis_buscar")
            df_vis = query_df(
                """
                SELECT v.fecha, p.nombre_completo, p.rut, v.rem_prestacion AS tipo,
                       v.estado, est.nombre AS establecimiento
                FROM operational.visita v
                JOIN clinical.paciente p ON p.patient_id = v.patient_id
                JOIN clinical.estadia e ON e.stay_id = v.stay_id
                LEFT JOIN territorial.establecimiento est ON est.establecimiento_id = e.establecimiento_id
                ORDER BY v.fecha DESC
                """
            )
            if buscar_vis:
                mask = (
                    df_vis["nombre_completo"].str.upper().str.contains(buscar_vis.upper(), na=False)
                    | df_vis["rut"].str.contains(buscar_vis, na=False)
                )
                df_vis = df_vis[mask]
            st.caption(f"{len(df_vis)} visitas")
            st.dataframe(df_vis, use_container_width=True, hide_index=True)

            st.subheader("Top prestaciones programadas")
            df_top_prest = query_df(
                """
                SELECT rem_prestacion AS prestacion, COUNT(*) AS n
                FROM operational.visita
                WHERE rem_prestacion IS NOT NULL
                GROUP BY rem_prestacion ORDER BY n DESC LIMIT 15
                """
            )
            st.bar_chart(df_top_prest.set_index("prestacion"))

            st.subheader("Visitas por mes")
            df_vis_mes = query_df(
                """
                SELECT TO_CHAR(fecha, 'YYYY-MM') AS mes, COUNT(*) AS n
                FROM operational.visita
                GROUP BY mes ORDER BY mes
                """
            )
            st.bar_chart(df_vis_mes.set_index("mes"))

            # COMPLETA vs PROGRAMADA breakdown
            st.subheader("Estado: COMPLETA vs PROGRAMADA")
            df_vis_estado = query_df(
                """
                SELECT estado, COUNT(*) AS n
                FROM operational.visita
                GROUP BY estado ORDER BY n DESC
                """
            )
            if not df_vis_estado.empty:
                cols_estado = st.columns(len(df_vis_estado))
                for i, row in df_vis_estado.iterrows():
                    cols_estado[i].metric(row["estado"] or "(sin estado)", int(row["n"]))
                st.bar_chart(df_vis_estado.set_index("estado"))

            st.subheader("Estado de visitas por mes")
            df_vis_estado_mes = query_df(
                """
                SELECT TO_CHAR(fecha, 'YYYY-MM') AS mes, estado, COUNT(*) AS n
                FROM operational.visita
                GROUP BY mes, estado ORDER BY mes
                """
            )
            if not df_vis_estado_mes.empty:
                df_pivot = df_vis_estado_mes.pivot_table(
                    index="mes", columns="estado", values="n", fill_value=0
                ).reset_index().set_index("mes")
                st.bar_chart(df_pivot)

        except Exception as exc:
            st.error(f"Error: {exc}")

    # ── Notas Evolución ──────────────────────────────────────
    with sub_notas:
        try:
            col_n1, col_n2, col_n3 = st.columns([2, 1, 1])
            with col_n1:
                buscar_nota = st.text_input("Buscar paciente (RUT / nombre)", key="nota_buscar")
            with col_n2:
                tipos_nota = ["Todos"] + [
                    "enfermeria", "kinesiologia", "fonoaudiologia",
                    "terapia_ocupacional", "medica", "trabajo_social", "tens",
                ]
                filtro_tipo_nota = st.selectbox("Tipo nota", tipos_nota, key="nota_tipo")
            with col_n3:
                col_d1, col_d2 = st.columns(2)
                with col_d1:
                    nota_desde = st.date_input("Desde", value=None, key="nota_desde")
                with col_d2:
                    nota_hasta = st.date_input("Hasta", value=None, key="nota_hasta")

            df_notas = query_df(
                """
                SELECT n.fecha, p.nombre_completo, p.rut, n.tipo,
                       LEFT(n.notas_clinicas, 120) AS notas_clinicas,
                       LEFT(n.plan_enfermeria, 120) AS plan_enfermeria,
                       n.hora
                FROM clinical.nota_evolucion n
                JOIN clinical.paciente p ON p.patient_id = n.patient_id
                ORDER BY n.fecha DESC, n.hora DESC
                """
            )

            # Apply filters
            if buscar_nota:
                mask = (
                    df_notas["nombre_completo"].str.upper().str.contains(buscar_nota.upper(), na=False)
                    | df_notas["rut"].str.contains(buscar_nota, na=False)
                )
                df_notas = df_notas[mask]
            if filtro_tipo_nota != "Todos":
                df_notas = df_notas[df_notas["tipo"] == filtro_tipo_nota]
            if nota_desde:
                df_notas = df_notas[pd.to_datetime(df_notas["fecha"]).dt.date >= nota_desde]
            if nota_hasta:
                df_notas = df_notas[pd.to_datetime(df_notas["fecha"]).dt.date <= nota_hasta]

            st.caption(f"{len(df_notas)} notas de evolución")
            st.dataframe(
                df_notas,
                use_container_width=True,
                hide_index=True,
                column_config={
                    "fecha": st.column_config.DateColumn("Fecha"),
                    "nombre_completo": st.column_config.TextColumn("Paciente", width="medium"),
                    "rut": st.column_config.TextColumn("RUT", width="small"),
                    "tipo": st.column_config.TextColumn("Tipo", width="small"),
                    "notas_clinicas": st.column_config.TextColumn("Notas clínicas", width="large"),
                    "plan_enfermeria": st.column_config.TextColumn("Plan enfermería", width="large"),
                    "hora": st.column_config.TextColumn("Hora", width="small"),
                },
            )

            st.subheader("Distribución por tipo")
            df_notas_tipo = query_df(
                """
                SELECT tipo, COUNT(*) AS n
                FROM clinical.nota_evolucion
                GROUP BY tipo ORDER BY n DESC
                """
            )
            st.bar_chart(df_notas_tipo.set_index("tipo"))

            st.subheader("Notas por mes")
            df_notas_mes = query_df(
                """
                SELECT TO_CHAR(fecha, 'YYYY-MM') AS mes, COUNT(*) AS n
                FROM clinical.nota_evolucion
                GROUP BY mes ORDER BY mes
                """
            )
            st.bar_chart(df_notas_mes.set_index("mes"))

        except Exception as exc:
            st.error(f"Error: {exc}")

    # ── Dispositivos ─────────────────────────────────────────
    with sub_disp:
        try:
            tipos_disp = ["Todos"] + [
                "VVP", "SNG", "CUP", "DRENAJE", "CONCENTRADOR_O2",
                "BOMBA_IV", "MONITOR", "GLUCOMETRO", "OTRO",
            ]
            filtro_tipo_disp = st.selectbox("Tipo dispositivo", tipos_disp, key="disp_tipo")

            df_disp = query_df(
                """
                SELECT p.nombre_completo, p.rut, d.tipo, d.estado, d.serial,
                       d.asignado_desde, d.asignado_hasta
                FROM clinical.dispositivo d
                JOIN clinical.paciente p ON p.patient_id = d.patient_id
                ORDER BY d.asignado_desde DESC NULLS LAST
                """
            )

            if filtro_tipo_disp != "Todos":
                df_disp = df_disp[df_disp["tipo"] == filtro_tipo_disp]

            # Active devices metric
            df_activos = query_df(
                """
                SELECT COUNT(*) AS n
                FROM clinical.dispositivo
                WHERE asignado_hasta IS NULL OR asignado_hasta >= CURRENT_DATE
                """
            )
            cnt_activos = int(df_activos["n"].iloc[0]) if not df_activos.empty else 0

            col_d1, col_d2 = st.columns(2)
            col_d1.metric("Total dispositivos", len(df_disp))
            col_d2.metric("Dispositivos activos", cnt_activos)

            st.dataframe(
                df_disp,
                use_container_width=True,
                hide_index=True,
                column_config={
                    "nombre_completo": st.column_config.TextColumn("Paciente", width="medium"),
                    "rut": st.column_config.TextColumn("RUT", width="small"),
                    "tipo": st.column_config.TextColumn("Tipo", width="small"),
                    "estado": st.column_config.TextColumn("Estado", width="small"),
                    "serial": st.column_config.TextColumn("Serial", width="small"),
                    "asignado_desde": st.column_config.DateColumn("Desde"),
                    "asignado_hasta": st.column_config.DateColumn("Hasta"),
                },
            )

            st.subheader("Distribución por tipo")
            df_disp_tipo = query_df(
                """
                SELECT tipo, COUNT(*) AS n
                FROM clinical.dispositivo
                GROUP BY tipo ORDER BY n DESC
                """
            )
            st.bar_chart(df_disp_tipo.set_index("tipo"))

        except Exception as exc:
            st.error(f"Error: {exc}")

    with sub_epi:
        try:
            buscar_epi = st.text_input("Buscar paciente", key="epi_buscar")
            df_epi = query_df(
                """
                SELECT ep.fecha_emision, p.nombre_completo, p.rut,
                       ep.diagnostico_ingreso, ep.servicio_origen,
                       LEFT(ep.resumen_evolucion, 200) AS evolucion,
                       ep.examen_fisico_ingreso AS examen_fisico,
                       ep.derivacion_aps
                FROM clinical.epicrisis ep
                JOIN clinical.paciente p ON p.patient_id = ep.patient_id
                ORDER BY ep.fecha_emision DESC
                """
            )
            if buscar_epi:
                mask = (
                    df_epi["nombre_completo"].str.upper().str.contains(buscar_epi.upper(), na=False)
                    | df_epi["rut"].astype(str).str.contains(buscar_epi, na=False)
                )
                df_epi = df_epi[mask]

            col_e1, col_e2, col_e3 = st.columns(3)
            col_e1.metric("Total epicrisis", len(df_epi))
            col_e2.metric("Con diagnóstico", int(df_epi["diagnostico_ingreso"].notna().sum()))
            col_e3.metric("Con examen físico", int(df_epi["examen_fisico"].notna().sum()))

            st.dataframe(
                df_epi, use_container_width=True, hide_index=True,
                column_config={
                    "fecha_emision": st.column_config.DateColumn("Emisión"),
                    "nombre_completo": st.column_config.TextColumn("Paciente", width="medium"),
                    "rut": st.column_config.TextColumn("RUT", width="small"),
                    "diagnostico_ingreso": st.column_config.TextColumn("Diagnóstico", width="large"),
                    "servicio_origen": st.column_config.TextColumn("Servicio", width="small"),
                    "evolucion": st.column_config.TextColumn("Evolución", width="large"),
                    "examen_fisico": st.column_config.TextColumn("Examen físico", width="medium"),
                    "derivacion_aps": st.column_config.TextColumn("Derivación APS", width="medium"),
                },
            )

            st.subheader("Top diagnósticos epicrisis")
            df_top_diag = query_df(
                """
                SELECT diagnostico_ingreso AS diagnostico, COUNT(*) AS n
                FROM clinical.epicrisis
                WHERE diagnostico_ingreso IS NOT NULL
                GROUP BY diagnostico_ingreso ORDER BY n DESC LIMIT 15
                """
            )
            if not df_top_diag.empty:
                st.bar_chart(df_top_diag.set_index("diagnostico"))

            st.subheader("Servicios de origen")
            df_serv = query_df(
                """
                SELECT COALESCE(servicio_origen, '(no registrado)') AS servicio, COUNT(*) AS n
                FROM clinical.epicrisis
                GROUP BY servicio_origen ORDER BY n DESC
                """
            )
            if not df_serv.empty:
                st.bar_chart(df_serv.set_index("servicio"))

        except Exception as exc:
            st.error(f"Error: {exc}")

    with sub_prest:
        try:
            st.subheader("Catálogo de Prestaciones")
            df_cat = query_df(
                """
                SELECT cp.prestacion_id AS codigo, cp.nombre_prestacion AS prestacion,
                       cp.estamento, cp.macroproceso,
                       COUNT(vp.visit_id) AS visitas
                FROM reference.catalogo_prestacion cp
                LEFT JOIN reporting.visita_prestacion vp USING (prestacion_id)
                GROUP BY cp.prestacion_id, cp.nombre_prestacion, cp.estamento, cp.macroproceso
                ORDER BY visitas DESC
                """
            )
            st.dataframe(df_cat, use_container_width=True, hide_index=True)

            st.subheader("Prestaciones por estamento")
            df_est_prest = query_df(
                """
                SELECT cp.estamento, COUNT(vp.visit_id) AS visitas
                FROM reporting.visita_prestacion vp
                JOIN reference.catalogo_prestacion cp USING (prestacion_id)
                GROUP BY cp.estamento ORDER BY visitas DESC
                """
            )
            if not df_est_prest.empty:
                st.bar_chart(df_est_prest.set_index("estamento"))

            st.subheader("Prestaciones por mes")
            df_prest_mes = query_df(
                """
                SELECT TO_CHAR(v.fecha, 'YYYY-MM') AS mes, cp.estamento, COUNT(*) AS n
                FROM reporting.visita_prestacion vp
                JOIN operational.visita v USING (visit_id)
                JOIN reference.catalogo_prestacion cp USING (prestacion_id)
                GROUP BY mes, cp.estamento ORDER BY mes
                """
            )
            if not df_prest_mes.empty:
                df_pivot = df_prest_mes.pivot_table(
                    index="mes", columns="estamento", values="n", fill_value=0
                ).reset_index().set_index("mes")
                st.area_chart(df_pivot)

        except Exception as exc:
            st.error(f"Error: {exc}")

    with sub_llam:
        try:
            df_llam = query_df(
                """
                SELECT l.fecha, l.hora, l.tipo, l.motivo, l.duracion,
                       COALESCE(p.nombre_completo, '(no match)') AS paciente,
                       l.nombre_familiar, l.estado_paciente, l.observaciones
                FROM operational.registro_llamada l
                LEFT JOIN clinical.paciente p ON p.patient_id = l.patient_id
                ORDER BY l.fecha DESC, l.hora DESC
                """
            )
            st.caption(f"{len(df_llam)} llamadas")
            st.dataframe(df_llam, use_container_width=True, hide_index=True)

            st.subheader("Llamadas por motivo")
            df_llam_motivo = query_df(
                """
                SELECT COALESCE(motivo, '(sin motivo)') AS motivo, COUNT(*) AS n
                FROM operational.registro_llamada
                GROUP BY motivo ORDER BY n DESC
                """
            )
            st.bar_chart(df_llam_motivo.set_index("motivo"))

        except Exception as exc:
            st.error(f"Error: {exc}")

    with sub_prof:
        try:
            df_prof = query_df(
                """
                SELECT pr.nombre, pr.profesion, pr.profesion_rem, pr.estado,
                       COUNT(v.visit_id) AS visitas_asignadas
                FROM operational.profesional pr
                LEFT JOIN operational.visita v ON v.provider_id = pr.provider_id
                GROUP BY pr.provider_id
                ORDER BY pr.profesion, pr.nombre
                """
            )
            st.caption(f"{len(df_prof)} profesionales")
            st.dataframe(df_prof, use_container_width=True, hide_index=True)

            st.subheader("Por estamento")
            df_est_prof = query_df(
                """
                SELECT profesion, COUNT(*) AS n
                FROM operational.profesional
                GROUP BY profesion ORDER BY n DESC
                """
            )
            st.bar_chart(df_est_prof.set_index("profesion"))

        except Exception as exc:
            st.error(f"Error: {exc}")


# ═══════════════════════════════════════════════════════════════
# TAB 6 — KPI Diario (F₁₀)
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

    sub_estab, sub_ubic, sub_dom = st.tabs(["Establecimientos", "Ubicaciones", "Domicilios"])

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

    with sub_dom:
        try:
            df_dom = query_df(
                """
                SELECT p.nombre_completo, p.rut, l.direccion_texto, l.comuna,
                       l.precision_geo, l.latitud, l.longitud,
                       d.tipo AS tipo_domicilio, d.vigente_desde, d.vigente_hasta
                FROM clinical.domicilio d
                JOIN clinical.paciente p ON p.patient_id = d.patient_id
                JOIN territorial.localizacion l ON l.localizacion_id = d.localizacion_id
                ORDER BY p.nombre_completo
                """
            )

            col_d1, col_d2, col_d3, col_d4 = st.columns(4)
            col_d1.metric("Total domicilios", len(df_dom))
            col_d2.metric("Geocodificados", int(df_dom["latitud"].notna().sum()))
            col_d3.metric("Comunas", int(df_dom["comuna"].nunique()))
            col_d4.metric("Precisión exacta", int((df_dom["precision_geo"] == "exacta").sum()))

            buscar_dom = st.text_input("Buscar paciente", key="dom_buscar")
            comunas_dom = ["Todas"] + sorted(df_dom["comuna"].dropna().unique().tolist())
            filtro_comuna_dom = st.selectbox("Filtrar por comuna", comunas_dom, key="dom_comuna")

            df_show = df_dom
            if buscar_dom:
                mask = (
                    df_show["nombre_completo"].str.upper().str.contains(buscar_dom.upper(), na=False)
                    | df_show["rut"].astype(str).str.contains(buscar_dom, na=False)
                )
                df_show = df_show[mask]
            if filtro_comuna_dom != "Todas":
                df_show = df_show[df_show["comuna"] == filtro_comuna_dom]

            st.caption(f"{len(df_show)} domicilios")
            st.dataframe(
                df_show, use_container_width=True, hide_index=True,
                column_config={
                    "nombre_completo": st.column_config.TextColumn("Paciente", width="medium"),
                    "rut": st.column_config.TextColumn("RUT", width="small"),
                    "direccion_norm": st.column_config.TextColumn("Dirección", width="large"),
                    "comuna": st.column_config.TextColumn("Comuna"),
                    "precision_geo": st.column_config.TextColumn("Precisión", width="small"),
                    "latitud": st.column_config.NumberColumn("Lat", format="%.5f"),
                    "longitud": st.column_config.NumberColumn("Lng", format="%.5f"),
                    "tipo_domicilio": st.column_config.TextColumn("Tipo", width="small"),
                    "vigente_desde": st.column_config.DateColumn("Desde"),
                    "vigente_hasta": st.column_config.DateColumn("Hasta"),
                },
            )

            st.subheader("Distribución por comuna")
            df_dom_comuna = query_df(
                """
                SELECT l.comuna, COUNT(*) AS n
                FROM clinical.domicilio d
                JOIN territorial.localizacion l ON l.localizacion_id = d.localizacion_id
                WHERE l.comuna IS NOT NULL
                GROUP BY l.comuna ORDER BY n DESC
                """
            )
            if not df_dom_comuna.empty:
                st.bar_chart(df_dom_comuna.set_index("comuna"))

            st.subheader("Precisión geocodificación")
            df_prec = query_df(
                """
                SELECT COALESCE(l.precision_geo, 'sin coordenada') AS precision, COUNT(*) AS n
                FROM territorial.localizacion l
                GROUP BY l.precision_geo ORDER BY n DESC
                """
            )
            if not df_prec.empty:
                st.bar_chart(df_prec.set_index("precision"))

        except Exception as exc:
            st.error(f"Error: {exc}")


# ═══════════════════════════════════════════════════════════════
# TAB — Mapa de Domicilios
# ═══════════════════════════════════════════════════════════════
with tab_mapa:
    st.header("Mapa de Domicilios")

    try:
        df_map = query_df(
            """
            SELECT l.latitud AS lat, l.longitud AS lon,
                   l.direccion_texto AS direccion, l.comuna,
                   l.precision_geo AS precision,
                   p.nombre_completo AS paciente
            FROM territorial.localizacion l
            JOIN clinical.domicilio d ON d.localizacion_id = l.localizacion_id
            JOIN clinical.paciente p ON p.patient_id = d.patient_id
            WHERE l.latitud IS NOT NULL AND l.longitud IS NOT NULL
            """
        )

        if df_map.empty:
            st.info("Sin localizaciones geocodificadas")
        else:
            col_f1, col_f2 = st.columns(2)
            with col_f1:
                comunas_map = ["Todas"] + sorted(df_map["comuna"].dropna().unique().tolist())
                filtro_com = st.selectbox("Comuna", comunas_map, key="map_comuna")
            with col_f2:
                prec_map = ["Todas"] + sorted(df_map["precision"].dropna().unique().tolist())
                filtro_prec = st.selectbox("Precisión", prec_map, key="map_prec")

            df_filtered = df_map
            if filtro_com != "Todas":
                df_filtered = df_filtered[df_filtered["comuna"] == filtro_com]
            if filtro_prec != "Todas":
                df_filtered = df_filtered[df_filtered["precision"] == filtro_prec]

            st.caption(f"{len(df_filtered)} domicilios en mapa")

            color_map = {
                "exacta": [34, 139, 34, 200],
                "aproximada": [255, 193, 7, 200],
                "centroide_localidad": [255, 87, 34, 200],
            }
            df_filtered = df_filtered.copy()
            df_filtered["color"] = df_filtered["precision"].map(
                lambda x: color_map.get(x, [128, 128, 128, 200])
            )

            center_lat = df_filtered["lat"].mean()
            center_lon = df_filtered["lon"].mean()

            layer = pdk.Layer(
                "ScatterplotLayer",
                data=df_filtered,
                get_position=["lon", "lat"],
                get_color="color",
                get_radius=200,
                pickable=True,
                auto_highlight=True,
            )

            view = pdk.ViewState(
                latitude=center_lat,
                longitude=center_lon,
                zoom=10,
                pitch=0,
            )

            tooltip = {
                "html": "<b>{paciente}</b><br/>{direccion}<br/>{comuna}<br/><i>{precision}</i>",
                "style": {"backgroundColor": "steelblue", "color": "white"},
            }

            st.pydeck_chart(pdk.Deck(
                layers=[layer],
                initial_view_state=view,
                tooltip=tooltip,
                map_provider="carto",
                map_style="light",
            ))

            st.markdown(
                "**Leyenda:** :green_circle: Exacta &ensp; :yellow_circle: Aproximada &ensp; :orange_circle: Centroide localidad"
            )

            st.subheader("Distribución geográfica")
            col_s1, col_s2 = st.columns(2)
            with col_s1:
                df_por_com = df_filtered.groupby("comuna").size().reset_index(name="n").sort_values("n", ascending=False)
                st.bar_chart(df_por_com.set_index("comuna"))
            with col_s2:
                df_por_prec = df_filtered.groupby("precision").size().reset_index(name="n").sort_values("n", ascending=False)
                st.bar_chart(df_por_prec.set_index("precision"))

    except Exception as exc:
        st.error(f"Error: {exc}")


# ═══════════════════════════════════════════════════════════════
# TAB — Satisfacción Usuaria
# ═══════════════════════════════════════════════════════════════
with tab_satis:
    st.header("Satisfacción Usuaria")

    try:
        df_enc = query_df(
            """
            SELECT e.nombre_paciente, e.parentesco, e.fecha_encuesta,
                   e.fecha_ingreso, e.fecha_alta,
                   e.sat_conocimiento, e.sat_informacion, e.sat_confidencialidad,
                   e.sat_escucha, e.sat_amabilidad,
                   e.score_satisfaccion, e.mejoria_percibida,
                   e.volveria_hodom, e.atencion_telefonica
            FROM reporting.encuesta_satisfaccion e
            ORDER BY e.fecha_encuesta DESC
            """
        )

        if df_enc.empty:
            st.info("Sin encuestas de satisfacción")
        else:
            col1, col2, col3, col4 = st.columns(4)
            col1.metric("Total encuestas", len(df_enc))
            col2.metric("Score promedio", f"{df_enc['score_satisfaccion'].mean():.2f}/5")
            si_volveria = (df_enc["volveria_hodom"] == "Sí, volvería").sum()
            col3.metric("Sí volverían", f"{si_volveria}/{len(df_enc)}")
            mejora_total = df_enc["mejoria_percibida"].isin(["TOTALMENTE", "MUCHO"]).sum()
            col4.metric("Mejoría total/mucho", f"{mejora_total}/{len(df_enc)}")

            st.dataframe(
                df_enc, use_container_width=True, hide_index=True,
                column_config={
                    "nombre_paciente": st.column_config.TextColumn("Paciente", width="medium"),
                    "parentesco": st.column_config.TextColumn("Parentesco", width="small"),
                    "fecha_encuesta": st.column_config.DateColumn("Fecha"),
                    "fecha_ingreso": st.column_config.DateColumn("Ingreso"),
                    "fecha_alta": st.column_config.DateColumn("Alta"),
                    "sat_conocimiento": st.column_config.NumberColumn("Conocim.", width="small"),
                    "sat_informacion": st.column_config.NumberColumn("Inform.", width="small"),
                    "sat_confidencialidad": st.column_config.NumberColumn("Confid.", width="small"),
                    "sat_escucha": st.column_config.NumberColumn("Escucha", width="small"),
                    "sat_amabilidad": st.column_config.NumberColumn("Amabil.", width="small"),
                    "score_satisfaccion": st.column_config.NumberColumn("Score", format="%.2f", width="small"),
                    "mejoria_percibida": st.column_config.TextColumn("Mejoría", width="small"),
                    "volveria_hodom": st.column_config.TextColumn("Volvería", width="small"),
                },
            )

            st.subheader("Satisfacción por dimensión")
            dims = {
                "Conocimiento": df_enc["sat_conocimiento"].mean(),
                "Información": df_enc["sat_informacion"].mean(),
                "Confidencialidad": df_enc["sat_confidencialidad"].mean(),
                "Escucha": df_enc["sat_escucha"].mean(),
                "Amabilidad": df_enc["sat_amabilidad"].mean(),
            }
            df_dims = pd.DataFrame({"Dimensión": list(dims.keys()), "Score": list(dims.values())})
            st.bar_chart(df_dims.set_index("Dimensión"))

            st.subheader("Distribución de respuestas")
            col_v1, col_v2 = st.columns(2)
            with col_v1:
                st.markdown("**Volvería a HODOM**")
                df_volveria = df_enc.groupby("volveria_hodom").size().reset_index(name="n")
                st.bar_chart(df_volveria.set_index("volveria_hodom"))
            with col_v2:
                st.markdown("**Mejoría percibida**")
                df_mejoria = df_enc["mejoria_percibida"].dropna()
                if not df_mejoria.empty:
                    df_mej = df_mejoria.value_counts().reset_index()
                    df_mej.columns = ["mejoria", "n"]
                    st.bar_chart(df_mej.set_index("mejoria"))

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
