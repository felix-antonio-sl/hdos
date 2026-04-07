# Migración Legacy → PostgreSQL v4

Diseño de migración de datos históricos HODOM (2025-01-01 → presente) hacia el schema canónico PostgreSQL v4 (`hodom-integrado-pg-v4.sql`, 100 tablas, 6 schemas).

Fecha: 2026-04-06

---

## 0. Decisión Arquitectural: PG es la Fuente Canónica

**A partir del Sprint 1 (2026-04-06), la base PostgreSQL con sus modificaciones validadas es la fuente canónica del sistema HODOM.**

- La migración es un proceso **one-shot** (bootstrap). No se re-ejecuta periódicamente.
- Las correcciones (ej: inferencia de sexo, ajustes manuales) se aplican **directo en PG**.
- `db/hdos.db` y `output/spreadsheet/canonical/` son fuentes históricas de la migración, no la verdad actual.
- Los sprints futuros (2-3) son **aditivos**: insertan nuevas tablas/datos sin destruir lo ya validado.
- El dashboard de exploración (`localhost:8504`) refleja el estado canónico real.

---

## 1. Modelo Categorial

### 1.1 Categoría Índice de Fuentes

```
I = { strict, canonical, intermediate, legacy }
```

Cada índice agrupa fuentes con nivel de confianza homogéneo:

| Índice | Confianza | Descripción | Archivos |
|--------|-----------|-------------|----------|
| `strict` | **1.0** (verdad) | Datos validados manualmente, únicos aceptados | `db/hdos.db` (673 pac, 838 hosp) |
| `canonical` | **0.8** (derivado) | Pipeline stages 1-4, superset con ruido | `output/spreadsheet/canonical/` (12 CSVs) |
| `intermediate` | **0.6** (estructurado) | Stages 2-3 del pipeline, tablas de dominio | `output/spreadsheet/intermediate/` + `enriched/` |
| `legacy` | **0.4** (bruto) | Documentación operacional en bruto | `documentacion-legacy/` (2661 archivos) |

### 1.2 Functores por Fuente

```
F(strict):       { paciente(rut, nombre, fdn), hospitalizacion(rut, fi, fe) }
F(canonical):    { hospitalization_stay(28 cols), patient_master(16 cols), ... 12 CSVs }
F(intermediate): { episode(3028), episode_care_requirement(4140), ... 46 CSVs }
F(legacy):       { FORMULARIOS(147), PROGRAMACIÓN(997), RUTAS(24×mes), EPICRISIS(2338), ... }
```

### 1.3 Schema Global como Colímite Controlado

El schema target (PG v4, 100 tablas) es el colímite, pero la migración **no** es un pushout libre. Es un **colímite controlado por estrictos**:

```
              W_strict
  F(strict) ──────────→ PG_v4    ← base (inner join)
                          ↑
              W_canon     │
  F(canonical) ──────────→│       ← enriquecimiento (left join ON estrictos)
                          │
              W_inter     │
  F(intermediate) ────────→│     ← dimensiones adicionales (left join ON estrictos)
                          │
              W_legacy    │
  F(legacy) ──────────────→│     ← dominios operacionales nuevos (insert donde FK existe)
```

**Regla de oro**: Solo entran al PG registros cuyo `rut` aparezca en `strict.paciente` y cuyo par `(rut, fecha_ingreso)` aparezca en `strict.hospitalizacion`.

### 1.4 Operador de Migración

```
M = Σ_strict ∘ Π_canonical ∘ Π_intermediate ∘ Π_legacy

donde:
  Σ_strict    = fusión total (todo lo estricto entra)
  Π_canonical = restricción al universo estricto + enriquecimiento de campos
  Π_intermediate = restricción al universo estricto + desglose dimensional
  Π_legacy    = restricción al universo estricto + extracción de dominios nuevos
```

---

## 2. Inventario de Fuentes → Tablas PG v4

### 2.1 Fuentes Estrictas (db/hdos.db)

| Tabla SQLite | Registros | → Tabla PG v4 | Campos mapeados |
|---|---|---|---|
| `paciente` | 673 | `clinical.paciente` | rut→rut, nombre→nombre_completo, fecha_nacimiento→fecha_nacimiento |
| `hospitalizacion` | 838 | `clinical.estadia` | rut_paciente→patient_id(via FK), fecha_ingreso, fecha_egreso |

**Cobertura**: 2 de 100 tablas. Estas 2 son las **únicas con garantía de integridad total**.

### 2.2 Fuentes Canónicas (output/spreadsheet/canonical/)

| CSV | Registros | → Tabla PG v4 | Campos de enriquecimiento |
|---|---|---|---|
| `patient_master.csv` | 1488 | `clinical.paciente` | sexo, comuna, cesfam, prevision, contacto_telefono, estado_actual |
| `hospitalization_stay.csv` | 1753 | `clinical.estadia` | estado, diagnostico_principal, origen_derivacion, establecimiento_id, tipo_egreso, confidence_level |
| `episode_source.csv` | 3115 | `operational.estadia_episodio_fuente` | source_id, stay_id, episode_id, origin_type |
| `establishment_reference.csv` | 86 | `territorial.establecimiento` | código_deis, nombre, comuna, servicio_salud |
| `locality_reference.csv` | 1660 | `territorial.ubicacion` | nombre_oficial, comuna, latitud, longitud |
| `patient_identity_master.csv` | 1454 | (proveniencia) | matching_strategy, matching_confidence |
| `quality_issue.csv` | 521 | (staging) | issues de calidad para auditoría post-migración |
| `review_queue.csv` | 1533 | (staging) | items pendientes de revisión manual |
| `duplicate_candidate.csv` | 123 | (staging) | candidatos a deduplicación |
| `coverage_gap.csv` | 31 | (staging) | brechas de cobertura |
| `pipeline_health.csv` | 1 | (staging) | metadata del último run |

**Cobertura adicional**: +3 tablas (establecimiento, ubicacion, estadia_episodio_fuente).

### 2.3 Fuentes Intermedias (output/spreadsheet/intermediate/ + enriched/)

| CSV | Registros | → Tabla PG v4 | Campos extraíbles |
|---|---|---|---|
| `episode_care_requirement.csv` | 4140 | `clinical.requerimiento_cuidado` | tipo, valor_normalizado |
| `episode_professional_need.csv` | 1959 | `clinical.necesidad_profesional` | profesion_requerida |
| `episode_diagnosis.csv` | 2426 | `clinical.condicion` | codigo, descripcion |
| `episode_location_snapshot.csv` | 1696 | `territorial.ubicacion` (enriquecimiento) | latitud, longitud |
| `patient_address.csv` | 1570 | `clinical.paciente` (enriquecimiento) | direccion |
| `patient_contact_point.csv` | 1456 | `clinical.paciente` (enriquecimiento) | contacto_telefono |
| `field_provenance.csv` | 13772 | (auditoría) | trazabilidad campo-a-campo |

**Cobertura adicional**: +2 tablas (requerimiento_cuidado, necesidad_profesional), +1 parcial (condicion).

### 2.4 Fuentes Legacy (documentacion-legacy/)

| Fuente | Archivos | Formato | → Tablas PG v4 | Extracción |
|---|---|---|---|---|
| **FORMULARIOS/** | 3 XLSX | 17 cols, 147 registros (2026) | `clinical.valoracion_ingreso`, `clinical.documentacion` | Parsing XLSX directo |
| **PROGRAMACIÓN/** | 13 XLSX | 43 cols/hoja, 997 pacientes | `operational.visita` (programadas), `operational.agenda_profesional` | Parsing mensual, pivot columnas→filas |
| **Consolidado atenciones** | 1 XLSX | 6 cols, 368 días | `reporting.kpi_diario` | Mapping directo |
| **HODOM 2025 FECHAS NAC** | 1 XLSX | 12 cols, 999 registros | `clinical.paciente` (enriquecimiento DOB) | LEFT JOIN por RUT |
| **Estadísticas/ENFERMERAS** | 16 XLSX | fecha, nombre, diagnóstico, duración | `operational.visita` (realizadas), `clinical.procedimiento` | Parsing multi-hoja |
| **Estadísticas/KINE** | 1 XLSX | similar enfermeras | `clinical.sesion_rehabilitacion` | Parsing multi-hoja |
| **Estadísticas/FONO** | 1 XLSX | similar | `clinical.sesion_rehabilitacion` | Parsing multi-hoja |
| **Estadísticas/TENS** | 8 XLSX | similar | `operational.visita` | Parsing multi-hoja |
| **Estadísticas/TRABAJO SOCIAL** | 1 XLSX | 17 hojas mensuales | `clinical.informe_social` | Parsing multi-hoja |
| **RUTAS/** | 24 XLSX (2024-2025) | fecha, profesionales, paciente, hora | `operational.ruta`, `operational.visita` | Parsing mensual |
| **EPICRISIS/** | 2338 archivos | PDF/DOCX | `clinical.epicrisis` (metadata: paciente, fecha) | Filename parsing + OCR futuro |
| **ENTREGA TURNO/** | 109 DOCX | texto libre | `operational.entrega_turno` | NLP/regex extraction |
| **LLAMADAS/** | 1 XLSX, 7 hojas | 10 cols | `operational.registro_llamada` | Parsing mensual |
| **EDUCACIONES/** | 20 PDF | folletos | `clinical.educacion_paciente` (referencia) | Metadata solo |
| **CURACIONES/** | 17 JPEG | fotos clínicas | `clinical.herida` (referencia externa) | Metadata filename |
| **CANASTA/** | 2 XLSX | | `operational.canasta_valorizada` | Parsing directo |

**Cobertura adicional**: +15 tablas operacionales y clínicas.

### 2.5 Resumen de Cobertura

```
Tablas PG v4 total:                     100
  ├─ Poblables desde fuentes:            22  (22%)
  │    ├─ Desde estrictos:                2  (base)
  │    ├─ + Desde canónicos:             +3  (territorial + proveniencia)
  │    ├─ + Desde intermedios:           +2  (requerimientos, necesidades)
  │    └─ + Desde legacy:              +15  (operacional, clínico extendido)
  ├─ Seed data en DDL:                   13  (reference.*)
  ├─ Derivables post-migración:           6  (reporting.*, MVs)
  ├─ Requieren fuentes externas:          4  (telemetry.*, matriz_distancia)
  └─ Sin datos disponibles:             55  (dominios clínicos detallados)
```

Las 55 tablas sin datos corresponden a dominios clínicos granulares (medicación, dispositivos, recetas, dispensación, GES, interconsultas, etc.) que requieren un sistema de captura operacional en producción — no existen en el corpus legacy.

---

## 3. Fases de Migración

### Orden Topológico (por dependencias FK)

```
Phase 0  ──→  Phase 1  ──→  Phase 2  ──→  Phase 3
(bootstrap)   (territorial)  (pacientes)   (estadías)
                                │              │
                                ├──→  Phase 4  ├──→  Phase 5
                                │   (provenance)    (clinical enrichment)
                                │                         │
                                └──→  Phase 6  ──→  Phase 7
                                    (profesionales)  (visitas + rutas)
                                                          │
                                                     Phase 8  ──→  Phase 9
                                                   (docs clínicos)  (operacional)
                                                                         │
                                                                    Phase 10
                                                                   (reporting)
                                                                         │
                                                                    Phase 11
                                                                   (validación)
```

---

### Phase 0: Bootstrap del Schema

**Acción**: Ejecutar DDL completo contra instancia PostgreSQL ≥14.

```bash
psql -d hodom -f docs/models/hodom-integrado-pg-v4.sql
```

**Resultado**: 100 tablas en 6 schemas + 13 tablas de referencia con seed data + 54 triggers + 24 funciones PL/pgSQL.

**Prerequisitos**: PostgreSQL ≥14 con extensión `btree_gist`.

**Validación**:
- 100 tablas creadas
- 13 tablas reference con datos seed
- 0 errores en creación de triggers/funciones/vistas

---

### Phase 1: Territorial (establecimiento + ubicación)

**Fuentes**: `canonical/establishment_reference.csv`, `canonical/locality_reference.csv`

**Target**: `territorial.establecimiento` (86), `territorial.ubicacion` (1660)

**Wrapper W₁**:

| CSV col | → PG col | Transformación |
|---|---|---|
| `establishment_id` | `establecimiento_id` | directo |
| `codigo_deis` | (índice adicional) | directo |
| `nombre_oficial` | `nombre` | directo |
| `tipo_establecimiento` | `tipo` | normalizar a CHECK enum |
| `comuna` | `comuna` | directo |
| `direccion` | `direccion` | concat(via, numero) |
| `servicio_salud` | `servicio_salud` | directo |

```
Para ubicacion:
  locality_id   → location_id
  nombre_oficial → nombre_oficial
  comuna        → comuna
  latitud       → latitud
  longitud      → longitud
  territory_type → tipo (normalizar URBANO/RURAL/...)
```

**FK internas**: `ubicacion.zone_id → zona.zone_id` — las zonas se construyen como clustering de localidades por proximidad geográfica. Pueden quedar NULL en fase 1 y resolverse en fase posterior.

**Validación**:
- `SELECT COUNT(*) FROM territorial.establecimiento` = 86
- `SELECT COUNT(*) FROM territorial.ubicacion` = 1660
- 0 violaciones de CHECK constraints

---

### Phase 2: Pacientes (estrictos + enriquecimiento)

**Fuente base**: `db/hdos.db → paciente` (673 registros)
**Fuente enriquecimiento**: `canonical/patient_master.csv` (1488 registros, filtrar a 673)

**Wrapper W₂**:

```
Paso 2a — Base (desde estrictos):
  rut              → rut
  nombre           → nombre_completo
  fecha_nacimiento → fecha_nacimiento
  patient_id       = hash_determinista(rut)  -- mismo algoritmo que pipeline

Paso 2b — Enriquecimiento (desde canonical, SOLO para RUTs en estrictos):
  sexo                → sexo (normalizar a 'masculino'/'femenino')
  comuna              → comuna
  cesfam              → cesfam
  prevision           → prevision (normalizar a CHECK enum)
  contacto            → contacto_telefono
  estado_actual       → estado_actual (derivar de fecha_egreso NULL → 'activo')
  direccion           → direccion (desde patient_address.csv si existe)

Paso 2c — Enriquecimiento DOB (desde legacy HODOM 2025 FECHAS NAC):
  Solo para pacientes donde fecha_nacimiento IS NULL en estrictos
  LEFT JOIN por RUT → actualizar fecha_nacimiento
```

**Regla de conflicto**: Si `strict.nombre ≠ canonical.nombre_completo`, prevalece strict. El campo canonical solo se usa para columnas que strict no tiene.

**Generación de patient_id**: Debe usar el **mismo algoritmo hash** que el pipeline existente (`scripts/build_hodom_canonical.py`) para mantener consistencia con `episode_source.csv`.

**Validación**:
- `SELECT COUNT(*) FROM clinical.paciente` = 673
- `SELECT COUNT(*) FROM clinical.paciente WHERE rut IS NOT NULL` = 673
- 0 pacientes con rut duplicado
- 0 pacientes huérfanos (sin hospitalizaciones en fase 3)

---

### Phase 3: Estadías (estrictos + enriquecimiento)

**Fuente base**: `db/hdos.db → hospitalizacion` (838 registros)
**Fuente enriquecimiento**: `canonical/hospitalization_stay.csv` (1753 registros, filtrar a 838)

**Wrapper W₃**:

```
Paso 3a — Base (desde estrictos):
  rut_paciente   → patient_id = hash_determinista(rut_paciente)
  fecha_ingreso  → fecha_ingreso (DATE)
  fecha_egreso   → fecha_egreso (DATE, NULL = activo)
  stay_id        = hash_determinista(rut_paciente, fecha_ingreso, fecha_egreso)
  estado         = CASE
                     WHEN fecha_egreso IS NULL THEN 'activo'
                     ELSE 'egresado'
                   END

Paso 3b — Enriquecimiento (desde canonical, match por rut + fecha_ingreso ±1 día):
  diagnostico_principal → diagnostico_principal
  origen_derivacion_rem → origen_derivacion (normalizar a CHECK enum)
  motivo_egreso         → tipo_egreso (map: ALTA→alta_clinica, FALLECIMIENTO→fallecido_esperado, etc.)
  establecimiento       → establecimiento_id (lookup en territorial.establecimiento)
  confidence_level      → confidence_level
  gestora               → (metadata, no en estadia)
  usuario_o2            → (metadata para dispositivo futuro)
```

**Match key para enriquecimiento**: `(rut, fecha_ingreso)` con tolerancia ±1 día. Si hay múltiples matches, elegir el de mayor `confidence_level`.

**Constraint EXCLUDE**: La constraint `EXCLUDE USING gist` del DDL previene estadías solapadas para el mismo paciente. Si datos estrictos tienen solapamientos legítimos (reingresos), ajustar fechas o documentar excepciones.

**Validación**:
- `SELECT COUNT(*) FROM clinical.estadia` = 838
- `SELECT COUNT(*) FROM clinical.estadia WHERE fecha_egreso IS NULL` = 27 (activos)
- `SELECT COUNT(*) FROM clinical.estadia WHERE fecha_egreso IS NOT NULL` = 811
- 0 estadia con patient_id que no exista en clinical.paciente
- 0 violaciones de CHECK en estado, tipo_egreso, origen_derivacion
- 0 violaciones de EXCLUDE (no overlap)

---

### Phase 4: Proveniencia de Episodios

**Fuente**: `canonical/episode_source.csv` (3115 registros)
**Target**: `operational.estadia_episodio_fuente`

**Wrapper W₄**:

```
Filtro: SOLO episode_source rows cuyo stay_id matchee con una estadia en Phase 3
  source_id   → source_id (PK)
  stay_id     → stay_id (FK → clinical.estadia)
  episode_id  → episode_id
  origin_type → origin_type
  raw_file    → (metadata adicional si la tabla lo soporta)
```

**Validación**:
- Todos los stay_id referenciados existen en clinical.estadia
- Registros cargados ≤ 3115 (por filtro a estrictos)

---

### Phase 5: Enriquecimiento Clínico

**Fuentes**: `intermediate/episode_care_requirement.csv`, `episode_professional_need.csv`, `episode_diagnosis.csv`
**Target**: `clinical.requerimiento_cuidado`, `clinical.necesidad_profesional`, `clinical.condicion`

**Dependencias**: Requiere `clinical.estadia` (Phase 3) y `clinical.plan_cuidado`.

**Problema**: Las tablas target requieren `plan_id` (FK a `plan_cuidado`) y `stay_id`. Los CSVs intermedios tienen `episode_id`, no `stay_id` directamente.

**Wrapper W₅**:

```
Paso 5a — Crear plan_cuidado implícito por estadia:
  Para cada estadia cargada en Phase 3, crear un plan_cuidado con:
    plan_id = hash_determinista(stay_id, 'default')
    stay_id = estadia.stay_id
    estado  = 'activo'

Paso 5b — Mapear episode_care_requirement → requerimiento_cuidado:
  episode_id → (lookup episode_source → stay_id → plan_id)
  tipo       → tipo (normalizar a reference.tipo_requerimiento_ref)
  valor      → valor_normalizado

Paso 5c — Mapear episode_professional_need → necesidad_profesional:
  episode_id → (lookup → plan_id)
  profesion  → profesion_requerida

Paso 5d — Mapear episode_diagnosis → condicion:
  episode_id → (lookup → stay_id)
  codigo     → codigo_cie10
  descripcion → descripcion
```

**Functor Information Loss**: Los CSVs intermedios agrupan por `episode_id`, pero PG v4 modela por `stay_id` o `plan_id`. Múltiples episodios pueden consolidarse en una estadia; la información de qué episodio específico aportó cada requerimiento se pierde parcialmente.

---

### Phase 6: Profesionales

**Fuentes**: `documentacion-legacy/ESTADISTICAS POR PROFESIONAL/` (38 XLSX)
**Target**: `operational.profesional`

**Wrapper W₆**:

```
Para cada XLSX en ENFERMERAS/, TENS/, KINE/, FONO/, TRABAJO SOCIAL/:
  Extraer nombres únicos de profesionales de headers/celdas
  
  provider_id     = hash_determinista(nombre_normalizado)
  nombre_completo = nombre extraído
  estamento       = inferir de subdirectorio (ENFERMERIA, KINESIOLOGIA, etc.)
  activo          = TRUE
```

**Desafíos**:
- Nombres inconsistentes entre archivos (abreviaciones, apellidos parciales)
- Un profesional puede aparecer en múltiples archivos con variantes
- Deduplicación por nombre normalizado (lowercase, sin tildes, trim)

**Validación**:
- 0 duplicados por nombre normalizado
- Todos los estamentos son válidos según CHECK del DDL

---

### Phase 7: Visitas y Rutas

**Fuentes**:
- `documentacion-legacy/PROGRAMACIÓN/2025 PROGRAMACIÓN.xlsx` (997 pacientes, 13 hojas mensuales)
- `documentacion-legacy/RUTAS/` (24 XLSX mensuales)
- `documentacion-legacy/ESTADISTICAS POR PROFESIONAL/` (38 XLSX)

**Target**: `operational.visita`, `operational.ruta`

**Wrapper W₇ (Programación → visitas programadas)**:

```
Para cada hoja mensual en PROGRAMACIÓN:
  Para cada paciente × día con celda no vacía:
    
    Filtro: paciente.rut debe existir en clinical.paciente (estrictos)
    
    visit_id     = hash_determinista(rut, fecha, tipo_atencion)
    stay_id      = lookup estadia activa para (patient_id, fecha)
    patient_id   = lookup por RUT
    fecha_programada = fecha de la celda
    estado       = 'PROGRAMADA'
    rem_reportable = FALSE (solo programación, no ejecución)
    tipo_atencion  = valor celda (ERTA, NPT, CA, CONTROL POLI, etc.)
```

**Wrapper W₇ (Estadísticas → visitas realizadas)**:

```
Para cada hoja en ENFERMERAS/KINE/FONO/TENS:
  Para cada fila con fecha + paciente + motivo:
    
    Filtro: paciente debe existir en estrictos
    
    visit_id       = hash_determinista(profesional, paciente_rut, fecha)
    estado         = 'COMPLETA' (o 'DOCUMENTADA' si tiene observación)
    rem_reportable = TRUE
    duracion_minutos = parsear duración
    provider_id    = lookup profesional (Phase 6)
```

**Wrapper W₇ (Rutas → operational.ruta)**:

```
Para cada XLSX mensual en RUTAS/:
  Para cada fila con fecha + profesional + paciente + hora:
    
    route_id = hash_determinista(fecha, vehiculo_o_turno)
    fecha    = parsear
    visitas asociadas = lookup por (profesional, paciente, fecha)
```

**Desafíos críticos**:
- Programación usa RUT + nombre; matching al universo estricto por RUT
- Estadísticas usan solo nombre (sin RUT); matching requiere fuzzy por nombre → rut
- Rutas usan formato libre; parsing semi-estructurado
- Un mismo evento puede aparecer en programación Y estadísticas → deduplicar
- Prioridad: estadística (realizada) > programación (planeada)

---

### Phase 8: Documentos Clínicos

**Fuentes**:
- `documentacion-legacy/EPICRISIS/` (2338 archivos PDF/DOCX)
- `documentacion-legacy/FORMULARIOS/` (3 XLSX)

**Target**: `clinical.epicrisis`, `clinical.documentacion`, `clinical.valoracion_ingreso`

**Wrapper W₈ (Epicrisis)**:

```
Para cada archivo en EPICRISIS/:
  Extraer metadata del filename:
    nombre_paciente = parsear filename
    tipo_epicrisis  = inferir de subdirectorio (ENFERMERIA, CON IND MÉDICA, etc.)
    fecha_documento = inferir de fecha modificación o contenido
  
  Filtro: nombre_paciente debe matchear con paciente en estrictos (fuzzy)
  
  epicrisis_id = hash_determinista(filename)
  stay_id      = lookup estadia del paciente que contenga fecha_documento
  tipo         = 'enfermeria' | 'medica' | 'completa'
  ruta_archivo = path relativo al archivo
```

**Nota**: La extracción de contenido de PDFs (OCR) queda fuera del scope de esta migración. Solo se carga metadata y referencia al archivo. Contenido textual es un proyecto futuro.

**Wrapper W₈ (Formularios)**:

```
Para cada fila en FORMULARIO 2026 RESP.xlsx:
  
  Filtro: RUT debe existir en estrictos
  
  → clinical.valoracion_ingreso (datos clínicos del ingreso)
  → clinical.documentacion (referencia al formulario)
```

---

### Phase 9: Registros Operacionales

**Fuentes**:
- `documentacion-legacy/LLAMADAS/` (1 XLSX, 7 hojas)
- `documentacion-legacy/ENTREGA TURNO/` (109 DOCX)
- `documentacion-legacy/EDUCACIONES/` (20 PDF)
- `documentacion-legacy/CANASTA/` (2 XLSX)

**Target**: `operational.registro_llamada`, `operational.entrega_turno`, `clinical.educacion_paciente`, `operational.canasta_valorizada`

**Wrapper W₉ (Llamadas)**:

```
Para cada hoja mensual en LLAMADAS:
  Para cada fila con fecha + hora + paciente + motivo:
    
    Filtro: paciente matchea a estrictos
    
    call_id      = hash_determinista(fecha, hora, paciente_rut)
    stay_id      = lookup estadia activa
    fecha        = parsear
    motivo       = texto
    observaciones = texto
```

**Wrapper W₉ (Entrega turno)**:

```
Para cada DOCX en ENTREGA TURNO/:
  Extraer: fecha, turno_saliente, turno_entrante, pacientes mencionados
  
  Requiere NLP/regex: los DOCX son texto semi-estructurado
  Alcance mínimo: fecha + referencia al archivo
```

**Wrapper W₉ (Canasta)**:

```
Para cada fila en CANASTA XLSX:
  canasta_id   = hash
  descripcion, codigo, valor unitario, cantidad
```

---

### Phase 10: Reporting (KPI diario)

**Fuente**: `documentacion-legacy/DATOS ESTADÍSTICOS/Consolidado atenciones diarias.xlsx`
**Target**: `reporting.kpi_diario`

**Wrapper W₁₀**:

```
Para cada fila (368 días):
  fecha        → fecha
  enfermero    → visitas_enfermeria
  kinesiologo  → visitas_kinesiologia
  fonoaudiologo → visitas_fonoaudiologia
  medico       → visitas_medicas
  tecnico      → visitas_tecnico
  total        → total_visitas_dia
```

**Post-procesamiento**: Después de cargar phases 2-7, refrescar materialized views:

```sql
SELECT refresh_hodom_mvs();
```

---

### Phase 11: Validación Integral

**Checks de integridad referencial**:

```sql
-- Pacientes sin estadías
SELECT COUNT(*) FROM clinical.paciente p
LEFT JOIN clinical.estadia e ON e.patient_id = p.patient_id
WHERE e.stay_id IS NULL;  -- debe ser 0

-- Estadías con paciente inexistente
SELECT COUNT(*) FROM clinical.estadia e
LEFT JOIN clinical.paciente p ON p.patient_id = e.patient_id
WHERE p.patient_id IS NULL;  -- debe ser 0

-- Visitas sin estadia válida
SELECT COUNT(*) FROM operational.visita v
LEFT JOIN clinical.estadia e ON e.stay_id = v.stay_id
WHERE v.stay_id IS NOT NULL AND e.stay_id IS NULL;  -- debe ser 0

-- Requerimientos sin plan válido
SELECT COUNT(*) FROM clinical.requerimiento_cuidado rc
LEFT JOIN clinical.plan_cuidado pc ON pc.plan_id = rc.plan_id
WHERE pc.plan_id IS NULL;  -- debe ser 0
```

**Checks de conteo**:

| Tabla | Esperado | Fuente |
|---|---|---|
| `clinical.paciente` | 673 | estrictos |
| `clinical.estadia` | 838 | estrictos |
| `territorial.establecimiento` | 86 | canónico |
| `territorial.ubicacion` | 1660 | canónico |
| `operational.profesional` | ~30-50 | legacy (estimado) |
| `operational.visita` | variable | legacy (por cuantificar) |
| `reporting.kpi_diario` | 368 | legacy |

**Checks de calidad**:

```sql
-- Estadías con fechas invertidas
SELECT COUNT(*) FROM clinical.estadia
WHERE fecha_egreso < fecha_ingreso;  -- debe ser 0

-- Pacientes con RUT duplicado
SELECT rut, COUNT(*) FROM clinical.paciente
WHERE rut IS NOT NULL
GROUP BY rut HAVING COUNT(*) > 1;  -- debe ser 0

-- Estadías solapadas (EXCLUDE constraint ya previene, pero verificar)
-- Si hay excepciones, se documentan
```

---

## 4. Riesgos y Mitigaciones

### R1: Divergencia de IDs hash (CRITICAL)

**Riesgo**: Si el algoritmo de hash para `patient_id` y `stay_id` difiere del usado por el pipeline existente, las referencias cruzadas con `episode_source.csv` se rompen.

**Mitigación**: Extraer la función de hash de `scripts/build_hodom_canonical.py` y reutilizarla en el script de migración. Alternativamente, hacer lookup por `(rut, fecha_ingreso)` en vez de confiar en IDs pre-computados.

### R2: Matching fuzzy nombre→RUT en legacy (HIGH)

**Riesgo**: Las estadísticas por profesional y epicrisis usan nombres sin RUT. El matching fuzzy puede generar falsos positivos (pacientes con nombres similares).

**Mitigación**: Usar la misma estrategia de matching del pipeline (nombre normalizado + fecha ±2 días). Registros sin match confiable van a cola de revisión manual, no se insertan.

### R3: Solapamiento de estadías en estrictos (HIGH)

**Riesgo**: La constraint `EXCLUDE USING gist` rechaza estadías solapadas para el mismo paciente. Si los estrictos contienen reingresos con solapamiento legítimo (ej: egreso día X, reingreso día X), el INSERT falla.

**Mitigación**: Fase previa de detección de solapamientos en los 838 registros. Ajustar `fecha_egreso` del primer período al día anterior del reingreso, o usar rangos abiertos `[)` en vez de cerrados `[]`.

### R4: Volumen de epicrisis sin OCR (MEDIUM)

**Riesgo**: 2338 archivos PDF/DOCX quedan como metadata sin contenido. El valor clínico no es accesible por query.

**Mitigación**: Fase futura de OCR/extracción. En esta migración, se carga solo la referencia al archivo y metadata derivada del filename.

### R5: Tablas sin datos (55/100) (LOW)

**Riesgo**: El schema PG v4 tiene 55 tablas sin datos disponibles. Los triggers y constraints de esas tablas no se validan empíricamente.

**Mitigación**: Aceptable. Estas tablas son para captura operacional futura. La migración legacy no pretende cubrirlas. Se documentan como "pendientes de sistema de captura".

---

## 5. Functor Information Loss

| Transformación | Información perdida |
|---|---|
| `legacy XLSX → operational.visita` | Layout visual de programación (colores, agrupaciones manuales), notas marginales |
| `epicrisis PDF → clinical.epicrisis` | Contenido textual completo (sin OCR), firmas, sellos, narrativa clínica libre |
| `entrega turno DOCX → operational.entrega_turno` | Formato libre, contexto narrativo, observaciones no estructuradas |
| `estadísticas enfermeras → visita` | Hojas Excel con formatos heterogéneos, notas al pie, celdas combinadas |
| `multiple episodes → single estadia` | Qué episodio específico aportó cada campo (parcialmente preservado en estadia_episodio_fuente) |
| `canonical 1753 stays → 838 estrictas` | 915 estadías descartadas por no pasar filtro estricto (ruido del pipeline) |
| `curaciones JPEG → clinical.herida` | Contenido visual de la fotografía (solo se almacena referencia) |

---

## 6. Implementación Recomendada

### Estructura del Script de Migración

```
scripts/
  migrate_to_pg/
    __init__.py
    phase_00_bootstrap.py      # Ejecuta DDL
    phase_01_territorial.py    # Establecimientos + ubicaciones
    phase_02_pacientes.py      # Pacientes estrictos + enriquecimiento
    phase_03_estadias.py       # Estadías estrictas + enriquecimiento
    phase_04_provenance.py     # Episode source
    phase_05_clinical.py       # Requerimientos, necesidades, condiciones
    phase_06_profesionales.py  # Extracción desde legacy
    phase_07_visitas_rutas.py  # Programación + estadísticas + rutas
    phase_08_documentos.py     # Epicrisis + formularios
    phase_09_operacional.py    # Llamadas, turnos, educaciones
    phase_10_reporting.py      # KPI diario
    phase_11_validation.py     # Checks de integridad
    utils/
      hash_ids.py              # Algoritmo de hash reutilizado del pipeline
      xlsx_parser.py           # Parser genérico de XLSX legacy
      name_matcher.py          # Matching fuzzy de nombres
      provenance.py            # Registro de proveniencia por fila
    run_migration.py           # Orquestador secuencial
```

### Ejecución

```bash
# Full migration
.venv/bin/python scripts/migrate_to_pg/run_migration.py --db-url postgresql://...

# Single phase (idempotente)
.venv/bin/python scripts/migrate_to_pg/run_migration.py --phase 2 --db-url postgresql://...

# Dry run (sin escritura, solo validación)
.venv/bin/python scripts/migrate_to_pg/run_migration.py --dry-run --db-url postgresql://...
```

### Principios de Implementación

1. **Idempotencia**: Cada fase debe poder re-ejecutarse sin duplicar datos (UPSERT o DELETE+INSERT por fase).
2. **Transaccionalidad**: Cada fase es una transacción. Si falla, se revierte completa.
3. **Proveniencia**: Cada INSERT registra la fuente (archivo, fila, fase) en una tabla de auditoría auxiliar.
4. **Determinismo**: IDs generados por hash = misma entrada produce misma salida.
5. **Filtro estricto**: Todo dato que entre debe tener su ancla en `db/hdos.db`.

---

## 7. Priorización

### Sprint 1 (Core — mínimo viable)

| Fase | Esfuerzo | Valor |
|---|---|---|
| Phase 0: Bootstrap | bajo | prerequisito |
| Phase 1: Territorial | bajo | prerequisito FK |
| Phase 2: Pacientes | medio | **core** |
| Phase 3: Estadías | medio | **core** |
| Phase 11: Validación | bajo | calidad |

**Resultado**: PG con 673 pacientes + 838 estadías + 86 establecimientos + 1660 ubicaciones. Base funcional.

### Sprint 2 (Enriquecimiento)

| Fase | Esfuerzo | Valor |
|---|---|---|
| Phase 4: Proveniencia | bajo | trazabilidad |
| Phase 5: Clinical enrichment | medio | dimensiones clínicas |
| Phase 10: KPI diario | bajo | reporting inmediato |

### Sprint 3 (Operacional Legacy)

| Fase | Esfuerzo | Valor |
|---|---|---|
| Phase 6: Profesionales | medio | prerequisito visitas |
| Phase 7: Visitas + Rutas | **alto** | dato operacional rico |
| Phase 8: Documentos | medio | referencia clínica |
| Phase 9: Operacional | medio | completitud |

---

## 8. Signature

```
Fuentes:     strict (db/hdos.db), canonical (12 CSVs), intermediate (46 CSVs), legacy (2661 archivos)
Método:      Grothendieck ∫F con colímite controlado por estrictos
Global Schema: hodom-integrado-pg-v4.sql (100 tablas, 6 schemas)
Wrappers:    W₁ (territorial), W₂ (pacientes), W₃ (estadías), W₄ (provenance),
             W₅ (clinical), W₆ (profesionales), W₇ (visitas), W₈ (docs), W₉ (operacional), W₁₀ (reporting)
Cobertura:   22/100 tablas poblables + 13 seed + 6 derivables = 41/100 (41%)
Proveniencia: completa para phases 1-4, parcial para phases 5-10
```
