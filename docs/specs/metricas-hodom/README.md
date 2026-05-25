# Especificaciones metricas HODOM

Este directorio es la ubicacion normativa para artefactos agregados derivados de fuentes Drive HODOM antes de migracion.

## Artefactos canonicos

| Artefacto | Proposito |
| --- | --- |
| `metricas-anuales-atenciones-usuarios-2026-05-25.md` | Especificacion legible de atenciones, usuarios, ingresos y banderas de calidad 2023-2025. |
| `metricas-anuales-atenciones-usuarios-2026-05-25.json` | Version estructurada de la especificacion anual para consumo por scripts o staging. |
| `metricas-anuales-atenciones-usuarios-2026-05-25.csv` | Tabla anual compacta para revision operativa. |
| `consolidacion-fuentes-drive-2026-05-25.md` | Especificacion de inventario, cobertura, metricas REM extraidas y banderas de calidad por fuente Drive. |
| `consolidacion-fuentes-drive-2026-05-25.json` | Version estructurada de la consolidacion de fuentes. |
| `inventario-fuentes-drive-2026-05-25.csv` | Inventario tabular de archivos fuente, datasets, periodos y hashes. |
| `manifiesto-fuentes-drive-2026-05-25.json` | Manifiesto de IDs Drive, rutas fuente y clasificacion. |
| `handoff-2026-05-25.md` | Estado actual, decisiones, pendientes, supuestos, riesgos y prompt de continuidad para migracion. |

## Reglas normativas

- Los archivos crudos descargados quedan en `.tmp/` y no se versionan.
- Este directorio conserva solo metricas agregadas, inventario, hashes y trazabilidad de fuentes.
- No se exportan nombres, RUT, filas nominales ni otros datos identificables.
- Las banderas `review` bloquean migracion directa a tablas clinicas hasta validacion humana.
- Cualquier nuevo insumo Drive debe incorporarse al manifiesto y regenerar estos artefactos.

## Regeneracion

```bash
python3 scripts/drive_consolidation.py
python3 scripts/hodom_annual_metrics.py
python3 -m unittest discover -s scripts -p 'test_*.py'
```
