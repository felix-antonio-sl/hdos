# Dashboard de Modelo de Migración HODOM

## Ejecutar

```bash
cd "$(git rev-parse --show-toplevel)"
.venv/bin/streamlit run apps/streamlit_migration_model_dashboard.py
```

Atajo:

```bash
scripts/run_streamlit_migration_model_dashboard.sh
```

## Enfoque

Este dashboard está separado del dashboard principal y del dashboard administrativo.

Su objetivo es:

- revisar la normalización actual de migración
- navegar entidad por entidad
- revisar relación por relación
- validar cobertura de claves y enlaces
- cerrar pendientes de identidad antes de migrar

## Fuente de datos

Lee principalmente desde:

- `output/spreadsheet/canonical`
- `output/spreadsheet/intermediate`
- `input/manual/manual_resolution.csv`

## Vistas incluidas

- `Resumen`: KPIs de identidad, stays y trazabilidad
- `Entidades`: perfil y muestra por tabla materializada
- `Relaciones`: cobertura y huérfanos por relación
- `Pendientes`: cola residual de identidad, duplicados y resoluciones manuales
