# Pipeline Intermedio HODOM

Este directorio contiene la tubería materializada por capas para ir desde CSV raw hasta entidades listas para migración.

## Runner

```bash
python3 /Users/felixsanhueza/Developer/_workspaces/hdos/scripts/build_hodom_intermediate.py
```

Si existe `/Users/felixsanhueza/Developer/_workspaces/hdos/input/manual/rut_corrections.csv`, el runner aplica esas correcciones antes de deduplicar.
Si no existe, el runner genera ese archivo con la cola actual de RUT inválidos para que puedas completarlo.

## Capas

- `raw_source_file.csv` y `raw_source_row.csv`: ingesta cruda sin pérdida.
- `normalized_row.csv`: parseo y normalización técnica, todavía fila-a-fila.
- `patient_master.csv`, `patient_identity_candidate.csv`, `patient_identity_link.csv`: resolución de identidad.
- `episode.csv`, `episode_source_link.csv`, `episode_diagnosis.csv`: episodios y trazabilidad.
- `episode_care_requirement.csv` y `episode_professional_need.csv`: requerimientos y necesidades profesionales.
- `patient_contact_point.csv`, `patient_address.csv`, `episode_location_snapshot.csv`: contacto y domicilio.
- `data_quality_issue.csv`: cola estructurada de calidad de dato.
- `catalog_value.csv`: catálogos observados en la capa curada.
- `rut_correction_queue.csv`: cola editable para completar correcciones manuales de RUT.

## Conteos de esta corrida

- `raw_source_file.csv`: `31` filas
- `raw_source_row.csv`: `3774` filas
- `normalized_row.csv`: `2998` filas
- `patient_identity_candidate.csv`: `1696` filas
- `patient_master.csv`: `1218` filas
- `patient_identity_link.csv`: `1696` filas
- `episode.csv`: `1696` filas
- `episode_source_link.csv`: `2998` filas
- `episode_diagnosis.csv`: `1696` filas
- `episode_care_requirement.csv`: `4140` filas
- `episode_professional_need.csv`: `1959` filas
- `patient_contact_point.csv`: `1456` filas
- `patient_address.csv`: `1570` filas
- `episode_location_snapshot.csv`: `1696` filas
- `data_quality_issue.csv`: `1844` filas
- `catalog_value.csv`: `146` filas
- `rut_correction_queue.csv`: `0` filas

## DDL

La definición PostgreSQL de esta estructura quedó en `hodom_intermediate_postgres.sql`.
