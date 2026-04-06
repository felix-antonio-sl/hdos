# HODOM

Workspace de migracion, analisis, depuracion de datos y dashboards para Hospitalizacion Domiciliaria.

## Topologia del repositorio

- `apps/`: puntos de entrada Streamlit.
- `docs/`: documentacion activa, especificaciones, modelos y bitacoras.
- `documentacion-legacy/`: respaldo historico y material no normalizado consumido por algunos utilitarios.
- `input/`: datos fuente, correcciones manuales y referencias externas versionadas.
- `output/`: materializaciones del pipeline, reportes y artefactos derivados.
- `scripts/`: pipelines y utilitarios operativos.
- `tests/`: pruebas automatizadas del pipeline y la capa canonica.

## Convenciones

- El contenido activo vive dentro de la jerarquia anterior; no se agregan archivos de trabajo en la raiz.
- Los datos manuales editables viven en `input/manual`.
- Las fuentes externas conservadas en el repo viven en `input/reference`.
- Los respaldos historicos o importaciones masivas no normalizadas quedan en `documentacion-legacy`.
- Los artefactos generados por pipeline se materializan bajo `output/spreadsheet`.

## Dashboards

- Principal: `apps/streamlit_dashboard.py`
- Administrativo: `apps/streamlit_admin_dashboard.py`
- Modelo de migracion: `apps/streamlit_migration_model_dashboard.py`

## Inicio rapido

```bash
cd "$(git rev-parse --show-toplevel)"
.venv/bin/python -m pip install -r requirements-dashboard.txt
scripts/run_streamlit_dashboard.sh
```
