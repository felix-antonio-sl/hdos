# Input

## Subdirectorios

- `manual/`: correcciones y resoluciones editables que el pipeline reutiliza entre corridas.
- `raw_csv_exports/`: exportaciones CSV crudas preservadas como insumo de migracion.
- `reference/`: referencias externas versionadas, snapshots y material de apoyo estructurado.

## Criterio

Los archivos en `input/` son fuentes o decisiones manuales. Los artefactos producidos por scripts no deben escribirse aqui salvo colas de resolucion manual explicitamente editables.
