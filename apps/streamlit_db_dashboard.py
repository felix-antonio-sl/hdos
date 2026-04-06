"""Dashboard HDOS — Pacientes y Hospitalizaciones (SQLite)."""

from __future__ import annotations

import sqlite3
from contextlib import contextmanager
from pathlib import Path

import pandas as pd
import streamlit as st

DB_PATH = Path(__file__).resolve().parents[1] / "db" / "hdos.db"

st.set_page_config(page_title="HDOS — Base de Datos", layout="wide")


@contextmanager
def get_db():
    conn = sqlite3.connect(DB_PATH)
    conn.execute("PRAGMA foreign_keys = ON")
    conn.row_factory = sqlite3.Row
    try:
        yield conn
    finally:
        conn.close()


def query_df(sql: str, params: tuple = ()) -> pd.DataFrame:
    with get_db() as conn:
        return pd.read_sql_query(sql, conn, params=params)


def execute(sql: str, params: tuple = ()):
    with get_db() as conn:
        conn.execute(sql, params)
        conn.commit()


# ── Sidebar ──────────────────────────────────────────────────
st.sidebar.title("HDOS")
vista = st.sidebar.radio("Vista", ["Pacientes", "Hospitalizaciones", "Agregar"])

# ── Pacientes ────────────────────────────────────────────────
if vista == "Pacientes":
    st.header("Pacientes")

    buscar = st.text_input("Buscar por nombre o RUT")
    where = ""
    params: tuple = ()
    if buscar:
        buscar_like = f"%{buscar.upper()}%"
        where = "WHERE UPPER(nombre) LIKE ? OR rut LIKE ?"
        params = (buscar_like, buscar_like)

    df = query_df(
        f"""
        SELECT p.rut, p.nombre, p.fecha_nacimiento,
               COUNT(h.id) AS hospitalizaciones
        FROM paciente p
        LEFT JOIN hospitalizacion h ON h.rut_paciente = p.rut
        {where}
        GROUP BY p.rut
        ORDER BY p.nombre
        """,
        params,
    )
    df["fecha_nacimiento"] = pd.to_datetime(df["fecha_nacimiento"], errors="coerce").dt.date
    st.caption(f"{len(df)} pacientes")

    edited = st.data_editor(
        df,
        key="pacientes_editor",
        num_rows="fixed",
        disabled=["rut", "hospitalizaciones"],
        column_config={
            "rut": st.column_config.TextColumn("RUT", width="small"),
            "nombre": st.column_config.TextColumn("Nombre", width="large"),
            "fecha_nacimiento": st.column_config.DateColumn("Fecha Nacimiento"),
            "hospitalizaciones": st.column_config.NumberColumn("Hosp.", width="small"),
        },
        use_container_width=True,
    )

    if st.button("Guardar cambios pacientes"):
        cambios = 0
        for i, row in edited.iterrows():
            orig = df.iloc[i]
            if row["nombre"] != orig["nombre"] or str(row["fecha_nacimiento"]) != str(orig["fecha_nacimiento"]):
                fdn = str(row["fecha_nacimiento"]) if pd.notna(row["fecha_nacimiento"]) else None
                execute(
                    "UPDATE paciente SET nombre = ?, fecha_nacimiento = ? WHERE rut = ?",
                    (row["nombre"], fdn, row["rut"]),
                )
                cambios += 1
        if cambios:
            st.success(f"{cambios} paciente(s) actualizado(s)")
            st.rerun()
        else:
            st.info("Sin cambios")

    # Detalle de hospitalizaciones al seleccionar paciente
    st.divider()
    st.subheader("Hospitalizaciones del paciente")
    rut_sel = st.selectbox(
        "Seleccionar paciente",
        options=df["rut"].tolist(),
        format_func=lambda r: f"{r} — {df[df['rut'] == r]['nombre'].iloc[0]}",
    )

    if rut_sel:
        df_h = query_df(
            """SELECT id, fecha_ingreso, fecha_egreso
               FROM hospitalizacion WHERE rut_paciente = ?
               ORDER BY fecha_ingreso""",
            (rut_sel,),
        )
        df_h["fecha_ingreso"] = pd.to_datetime(df_h["fecha_ingreso"], errors="coerce").dt.date
        df_h["fecha_egreso"] = pd.to_datetime(df_h["fecha_egreso"], errors="coerce").dt.date
        if df_h.empty:
            st.info("Sin hospitalizaciones")
        else:
            edited_h = st.data_editor(
                df_h,
                key="hosp_pac_editor",
                num_rows="fixed",
                disabled=["id"],
                column_config={
                    "id": st.column_config.NumberColumn("ID", width="small"),
                    "fecha_ingreso": st.column_config.DateColumn("Ingreso"),
                    "fecha_egreso": st.column_config.DateColumn("Egreso"),
                },
                use_container_width=True,
            )

            if st.button("Guardar cambios hospitalizaciones"):
                cambios = 0
                for i, row in edited_h.iterrows():
                    orig = df_h.iloc[i]
                    if str(row["fecha_ingreso"]) != str(orig["fecha_ingreso"]) or str(row["fecha_egreso"]) != str(orig["fecha_egreso"]):
                        egreso = str(row["fecha_egreso"]) if pd.notna(row["fecha_egreso"]) else None
                        execute(
                            "UPDATE hospitalizacion SET fecha_ingreso = ?, fecha_egreso = ? WHERE id = ?",
                            (str(row["fecha_ingreso"]), egreso, int(row["id"])),
                        )
                        cambios += 1
                if cambios:
                    st.success(f"{cambios} hospitalización(es) actualizada(s)")
                    st.rerun()
                else:
                    st.info("Sin cambios")

# ── Hospitalizaciones ────────────────────────────────────────
elif vista == "Hospitalizaciones":
    st.header("Hospitalizaciones")

    col1, col2, col3 = st.columns(3)
    with col1:
        filtro_estado = st.selectbox("Estado", ["Todas", "Activas (sin egreso)", "Con egreso"])
    with col2:
        fecha_desde = st.date_input("Desde", value=None)
    with col3:
        fecha_hasta = st.date_input("Hasta", value=None)

    where_parts = []
    params_list: list = []

    if filtro_estado == "Activas (sin egreso)":
        where_parts.append("h.fecha_egreso IS NULL")
    elif filtro_estado == "Con egreso":
        where_parts.append("h.fecha_egreso IS NOT NULL")

    if fecha_desde:
        where_parts.append("h.fecha_ingreso >= ?")
        params_list.append(str(fecha_desde))
    if fecha_hasta:
        where_parts.append("h.fecha_ingreso <= ?")
        params_list.append(str(fecha_hasta))

    where_clause = ("WHERE " + " AND ".join(where_parts)) if where_parts else ""

    df_all = query_df(
        f"""
        SELECT h.id, h.rut_paciente, p.nombre, h.fecha_ingreso, h.fecha_egreso
        FROM hospitalizacion h
        JOIN paciente p ON h.rut_paciente = p.rut
        {where_clause}
        ORDER BY h.fecha_ingreso DESC
        """,
        tuple(params_list),
    )
    st.caption(f"{len(df_all)} hospitalizaciones")

    st.dataframe(
        df_all,
        column_config={
            "id": st.column_config.NumberColumn("ID", width="small"),
            "rut_paciente": st.column_config.TextColumn("RUT", width="small"),
            "nombre": st.column_config.TextColumn("Paciente", width="large"),
            "fecha_ingreso": st.column_config.DateColumn("Ingreso"),
            "fecha_egreso": st.column_config.DateColumn("Egreso"),
        },
        use_container_width=True,
    )

# ── Agregar ──────────────────────────────────────────────────
elif vista == "Agregar":
    st.header("Agregar registros")

    tab_pac, tab_hosp = st.tabs(["Nuevo paciente", "Nueva hospitalización"])

    with tab_pac:
        with st.form("nuevo_paciente"):
            rut = st.text_input("RUT (ej: 12345678-9)")
            nombre = st.text_input("Nombre completo")
            fdn = st.date_input("Fecha de nacimiento", value=None)
            submitted = st.form_submit_button("Agregar paciente")
            if submitted:
                if not rut or not nombre:
                    st.error("RUT y nombre son obligatorios")
                else:
                    try:
                        fdn_str = str(fdn) if fdn else None
                        execute(
                            "INSERT INTO paciente (rut, nombre, fecha_nacimiento) VALUES (?, ?, ?)",
                            (rut.strip(), nombre.strip().upper(), fdn_str),
                        )
                        st.success(f"Paciente {nombre.upper()} agregado")
                    except sqlite3.IntegrityError:
                        st.error(f"Ya existe un paciente con RUT {rut}")

    with tab_hosp:
        pacientes = query_df("SELECT rut, nombre FROM paciente ORDER BY nombre")
        with st.form("nueva_hosp"):
            rut_pac = st.selectbox(
                "Paciente",
                options=pacientes["rut"].tolist(),
                format_func=lambda r: f"{r} — {pacientes[pacientes['rut'] == r]['nombre'].iloc[0]}",
            )
            fi = st.date_input("Fecha ingreso")
            fe = st.date_input("Fecha egreso", value=None)
            submitted_h = st.form_submit_button("Agregar hospitalización")
            if submitted_h:
                fe_str = str(fe) if fe else None
                execute(
                    "INSERT INTO hospitalizacion (rut_paciente, fecha_ingreso, fecha_egreso) VALUES (?, ?, ?)",
                    (rut_pac, str(fi), fe_str),
                )
                st.success("Hospitalización agregada")
