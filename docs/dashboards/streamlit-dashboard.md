# Dashboard Streamlit HODOM

## Requisitos

```bash
cd "$(git rev-parse --show-toplevel)"
.venv/bin/python -m pip install -r requirements-dashboard.txt
```

## Ejecutar

```bash
.venv/bin/streamlit run apps/streamlit_dashboard.py --server.port 8502
```

Atajos:

```bash
scripts/run_streamlit_dashboard.sh
```

o regenerando datos antes:

```bash
scripts/refresh_data_and_run_dashboard.sh
```

## Fuente de datos

La app lee directamente desde:

`output/spreadsheet/enriched`

Si ese directorio no existe, cae en forma automática a:

`output/spreadsheet/intermediate`

Si regeneras el pipeline intermedio, la app refleja los cambios al recargar.

## Vistas incluidas

- `Resumen`: KPIs ejecutivos, actividad mensual y mezcla asistencial.
- `Normalización`: conflictos de procedencia, overrides y estado de match de formularios/altas.
- `Rescates 2025`: reconciliación mensual y episodios rescatados/provisionales.
- `Territorio`: establecimientos DEIS, localidades, estado de resolución territorial y mapa con coordenadas cuando existen en la capa enriquecida.
- `REM / Gestión`: vista estructurada según REM A21/C1, con componentes de personas atendidas por rango de fechas y desagregaciones por sexo, edad y origen inferido de derivación.
- `Explorador`: tablas filtrables de episodios, pacientes e issues.

## Verificación mínima

En esta sesión se verificó que Streamlit responde localmente con `HTTP 200` en `http://localhost:8502`.

Nota:

- En esta máquina `8501` está ocupado por otro proceso del sistema.
- El dashboard HODOM queda fijado en `8502`.
