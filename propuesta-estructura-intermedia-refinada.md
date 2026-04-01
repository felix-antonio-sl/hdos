# Propuesta De Estructura Intermedia Refinada

## Problema del staging actual

La estructura actual mezcla en una sola tabla de episodios:

- identidad del paciente
- datos demográficos
- estado administrativo del episodio
- datos clínicos
- prestaciones y requerimientos
- domicilio y contacto
- calidad del dato
- trazabilidad de origen

Eso sirve para una primera carga, pero queda poco claro para:

- corregir identidad sin tocar el episodio
- comparar múltiples episodios del mismo paciente
- normalizar catálogos
- representar varias prestaciones por episodio
- guardar conflictos o dudas de calidad de dato

## Principio de diseño

Propongo una estructura intermedia en 3 capas:

1. `raw`
   Conserva el CSV casi sin tocar.
2. `normalized`
   Normaliza columnas, tipos, enums y trazabilidad.
3. `curated`
   Desagrega entidades de negocio: paciente, episodio, prestaciones, ubicación, calidad.

La capa `curated` sigue siendo intermedia. No es todavía la base final de la app, pero ya permite migrar de forma segura.

## Modelo propuesto

### 1. Ingesta cruda

#### `raw_source_file`

Un registro por archivo importado.

Campos:

- `source_file_id`
- `file_name`
- `file_family`
  `INGRESOS` o `EGRESOS`
- `source_pattern`
  `p26`, `p27`, `p40`, `p43`
- `imported_at`
- `row_count`
- `header_fingerprint`
- `sha256`

#### `raw_source_row`

Una fila por línea del CSV, sin pérdida.

Campos:

- `source_row_id`
- `source_file_id`
- `row_number`
- `raw_json`
  fila completa como objeto o array
- `raw_csv_line`
- `has_payload`

Uso:

- auditoría
- reprocesamiento
- comparación con el origen

### 2. Normalización técnica

#### `normalized_row`

Una fila por registro parseado, todavía cercana al origen pero ya tipada.

Campos de trazabilidad:

- `normalized_row_id`
- `source_row_id`
- `record_uid`
- `dedupe_key`
- `duplicate_count`
- `duplicate_rank`

Campos técnicos:

- `estado_raw`
- `estado_norm`
- `fecha_ingreso_raw`
- `fecha_ingreso`
- `fecha_egreso_raw`
- `fecha_egreso`
- `fecha_nacimiento_raw`
- `fecha_nacimiento`
- `rut_raw`
- `rut_norm`
- `rut_valido`
- `non_empty_fields`

Campos de parsing:

- `parse_status`
  `OK`, `PARTIAL`, `FAILED`
- `normalization_notes`
- `quality_score`

La idea es que aquí todavía exista una fila “similar” al CSV, pero ya sin depender de strings crudos para consultas.

### 3. Identidad del paciente

#### `patient_identity_candidate`

No todos los registros permiten afirmar identidad final. Esta tabla guarda la identidad inferida desde cada fila.

Campos:

- `identity_candidate_id`
- `normalized_row_id`
- `patient_key`
- `patient_key_strategy`
  `rut`, `nombre_fecha`, `nombre_contacto`, `legacy`
- `rut_norm`
- `rut_valido`
- `nombre_completo_norm`
- `fecha_nacimiento`
- `contacto_norm`
- `identity_confidence`

Uso:

- resolver merges
- revisar pacientes sin RUT válido
- separar identidad inferida de identidad maestra

#### `patient_master`

Un registro por paciente consolidado.

Campos:

- `patient_id`
- `canonical_rut`
- `canonical_nombre_completo`
- `canonical_nombres`
- `canonical_apellido_paterno`
- `canonical_apellido_materno`
- `canonical_sexo`
- `canonical_fecha_nacimiento`
- `canonical_nacionalidad`
- `identity_resolution_status`
  `AUTO`, `REVIEWED`, `AMBIGUOUS`

Relación:

- un `patient_master` puede agrupar varios `patient_identity_candidate`

#### `patient_identity_link`

Tabla puente para trazabilidad del merge.

Campos:

- `patient_id`
- `identity_candidate_id`
- `link_type`
  `AUTO_RUT`, `AUTO_HEURISTIC`, `MANUAL_REVIEW`
- `is_primary`

## 4. Episodio clínico-administrativo

#### `episode`

Entidad central. Un episodio corresponde a una hospitalización domiciliaria concreta.

Campos:

- `episode_id`
- `patient_id`
- `source_episode_key`
  hash técnico de deduplicación
- `estado`
- `tipo_flujo`
  `INGRESO`, `EGRESO`, `MIXTO`
- `fecha_ingreso`
- `fecha_egreso`
- `dias_estadia_reportados`
- `dias_estadia_calculados`
- `motivo_egreso_id`
- `motivo_derivacion_id`
- `servicio_origen_id`
- `prevision_id`
- `barthel_id`
- `categorizacion_id`
- `diagnostico_principal_texto`
- `episode_status_quality`
  `CONSISTENT`, `PARTIAL`, `REVIEW`

Esta tabla no debería repetir nombre, RUT, domicilio ni teléfono.

## 5. Diagnóstico y observaciones clínicas

#### `episode_diagnosis`

Porque el diagnóstico es una observación clínica del episodio, no del paciente permanente.

Campos:

- `episode_diagnosis_id`
- `episode_id`
- `diagnosis_text_raw`
- `diagnosis_text_norm`
- `diagnosis_role`
  `PRINCIPAL`, `EGRESO`, `DERIVACION`
- `coding_status`
  `UNCODED`, `MAPPED_CIE10`, `REVIEW`
- `cie10_code`

## 6. Prestaciones, requerimientos y participación profesional

El CSV actual colapsa muchas cosas distintas en columnas planas. Conviene separarlas.

#### `episode_care_requirement`

Una fila por requerimiento o condición activa del episodio.

Campos:

- `episode_requirement_id`
- `episode_id`
- `requirement_type`
  ejemplos: `USUARIO_O2`, `REQUERIMIENTO_O2`, `TTO_EV`, `TTO_SC`, `TTO_IM`, `CURACIONES`, `TOMA_MUESTRAS`, `OSTOMIAS`, `INVASIVOS`, `CSV`
- `requirement_value_raw`
- `requirement_value_norm`
- `is_active`

#### `episode_professional_need`

Una fila por necesidad o intervención profesional declarada.

Campos:

- `episode_professional_need_id`
- `episode_id`
- `professional_type`
  `ENFERMERIA`, `KINESIOLOGIA`, `FONOAUDIOLOGIA`, `MEDICO`, `TRABAJO_SOCIAL`
- `need_level`
  `SI`, `NO`, `MOTORA`, `RESPIRATORIA`, `AMBAS`, etc.
- `source_column`

Esto evita tener 8 columnas semánticamente distintas en una sola tabla.

## 7. Contacto y domicilio

#### `patient_contact_point`

Un paciente puede tener varios teléfonos a lo largo del tiempo.

Campos:

- `contact_point_id`
- `patient_id`
- `contact_type`
  `PHONE`
- `contact_value_raw`
- `contact_value_norm`
- `is_primary`
- `source_episode_id`

#### `patient_address`

No conviene dejar domicilio como texto plano dentro del episodio.

Campos:

- `address_id`
- `patient_id`
- `full_address_raw`
- `street_text`
- `house_number`
- `comuna_id`
- `cesfam_id`
- `territory_type`
  `URBANO`, `RURAL`
- `address_quality_status`

#### `episode_location_snapshot`

Si el domicilio cambia entre episodios, el episodio debe mantener snapshot.

Campos:

- `episode_location_snapshot_id`
- `episode_id`
- `address_id`
- `snapshot_full_address`
- `snapshot_comuna_id`
- `snapshot_cesfam_id`
- `snapshot_territory_type`

## 8. Catálogos normalizados

En vez de guardar texto libre repetido:

- `catalog_estado`
- `catalog_barthel`
- `catalog_prevision`
- `catalog_servicio_origen`
- `catalog_motivo_egreso`
- `catalog_motivo_derivacion`
- `catalog_categorizacion`
- `catalog_comuna`
- `catalog_cesfam`

Cada catálogo debería tener:

- `catalog_id`
- `code`
- `label`
- `label_normalized`
- `source_reference`
  por ejemplo `NO_MOD`
- `active`

## 9. Calidad y observabilidad

#### `data_quality_issue`

Los errores no deberían vivir sólo en `normalization_notes` como texto.

Campos:

- `quality_issue_id`
- `normalized_row_id`
- `episode_id`
  nullable mientras no exista episodio consolidado
- `issue_type`
  `INVALID_RUT`, `DATE_PARSE_FAILED`, `COLUMN_SHIFT_DETECTED`, `BIRTHDATE_AGE_MISMATCH`, `ENUM_UNMAPPED`
- `severity`
  `HIGH`, `MEDIUM`, `LOW`
- `raw_value`
- `suggested_value`
- `status`
  `OPEN`, `RESOLVED`, `WAIVED`

Esto permite armar una cola de revisión humana.

## Relaciones recomendadas

### Mínimas

- `raw_source_file 1:N raw_source_row`
- `raw_source_row 1:1 normalized_row`
- `normalized_row 1:1 patient_identity_candidate`
- `patient_master 1:N patient_identity_link`
- `patient_identity_candidate 1:N patient_identity_link`
- `patient_master 1:N episode`
- `episode 1:N episode_diagnosis`
- `episode 1:N episode_care_requirement`
- `episode 1:N episode_professional_need`
- `patient_master 1:N patient_contact_point`
- `patient_master 1:N patient_address`
- `episode 1:1 episode_location_snapshot`
- `normalized_row 1:N data_quality_issue`

## Qué mejora respecto al staging actual

### Antes

- un episodio repetía nombre, RUT, teléfono, domicilio, catálogo y calidad
- no distinguía identidad inferida de identidad consolidada
- no permitía varias prestaciones o varios diagnósticos
- la calidad del dato quedaba embebida como texto libre

### Después

- identidad, episodio, ubicación y prestaciones quedan separados
- la resolución de pacientes dudosos es auditable
- las prestaciones pasan a estructura fila-a-fila
- los catálogos quedan gobernables
- los errores de calidad se pueden revisar en workflow

## Versión mínima viable

Si no quieres implementar todo de una vez, la versión intermedia mínima que sí vale la pena construir es:

1. `raw_source_file`
2. `raw_source_row`
3. `normalized_row`
4. `patient_identity_candidate`
5. `patient_master`
6. `episode`
7. `episode_care_requirement`
8. `data_quality_issue`

Con eso ya resuelves el 80% del problema sin caer en sobreingeniería.

## Mi recomendación concreta

Para esta migración no usaría `hodom_episodios_staging` como tabla intermedia final. La dejaría sólo como salida técnica del script. La estructura intermedia real debería partir, al menos, en:

- `normalized_row`
- `patient_master`
- `episode`
- `episode_care_requirement`
- `patient_address`
- `patient_contact_point`
- `data_quality_issue`

Eso te da una base clara para migrar hoy y te evita rehacer todo cuando quieras limpiar identidad, prestaciones o reportes REM.
