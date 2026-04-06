# Dashboard Administrativo HODOM

## Ejecutar

```bash
cd "$(git rev-parse --show-toplevel)"
.venv/bin/streamlit run apps/streamlit_admin_dashboard.py
```

## Enfoque

Este dashboard está separado del dashboard de migración.

Su objetivo es:

- explorar hospitalizaciones
- revisar pacientes ingresados, egresados y activos
- consultar indicadores administrativos
- revisar estadística REM A21/C1
- visualizar territorio y establecimientos

No muestra:

- issues de migración
- colas de revisión
- conflictos de reconciliación
- semántica técnica del pipeline
