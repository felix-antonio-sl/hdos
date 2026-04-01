# Pipeline Enriquecido HODOM

Integra formularios 2025/2026, planilla de altas y referencias oficiales para reconciliar, rescatar y preparar migracion nominal.

## Fuentes adicionales

- Formularios HODOM 2025/2026 desde `/Users/felixsanhueza/Downloads`.
- Planilla de altas 2024-2026 desde `/Users/felixsanhueza/Downloads/PLANILLA DE ALTAS 26.xlsx`.
- Referencia oficial de establecimientos desde el PDF DEIS.
- Referencia territorial estructurante desde las paginas oficiales INE/Censo 2024.

## Conteos

- `raw_form_submission.csv`: `3709` filas
- `raw_discharge_sheet.csv`: `1114` filas
- `raw_reference_snapshot.csv`: `9` filas
- `normalized_form_submission.csv`: `1921` filas
- `normalized_discharge_event.csv`: `1090` filas
- `normalized_establishment_reference.csv`: `86` filas
- `normalized_locality_reference.csv`: `1660` filas
- `normalized_form_episode_candidate.csv`: `1921` filas
- `normalized_discharge_episode_candidate.csv`: `1090` filas
- `patient_master.csv`: `1468` filas
- `episode_master.csv`: `1848` filas
- `episode_request.csv`: `1921` filas
- `episode_discharge.csv`: `1090` filas
- `episode_rescue_candidate.csv`: `293` filas
- `field_provenance.csv`: `13364` filas
- `match_review_queue.csv`: `1835` filas
- `identity_review_queue.csv`: `5` filas
- `establishment_reference.csv`: `86` filas
- `locality_reference.csv`: `1660` filas
- `locality_alias.csv`: `4768` filas
- `address_resolution.csv`: `1468` filas
- `data_quality_issue.csv`: `2297` filas
- `reconciliation_report.csv`: `4` filas

## Fuentes web usadas

- Establecimientos DEIS: https://www.minsal.cl/wp-content/uploads/2018/12/Listado-Establecimientos-DEIS.pdf
- INE Geodatos Abiertos: https://www.ine.gob.cl/herramientas/portal-de-mapas/geodatos-abiertos/
- INE Censo 2024 Nuble: https://regiones.ine.gob.cl/nuble/prensa/ine-publica-bases-de-datos-a-nivel-de-manzana-y-cartografia-del-censo-de-poblacion-y-vivienda-2024
