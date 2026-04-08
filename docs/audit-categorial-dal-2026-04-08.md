# Auditoría Categorial DAL-Integrated — HDOS

```
Modo:      DAL_INTEGRATED
Scope:     hodom-pg (PG 14) × hdos (Python pipeline) × hdos-app (Next.js + Drizzle)
Fecha:     2026-04-08
Objetos:   115 tablas, 237 FKs, 155 CHECKs, 23 trigger functions, 10 views/MVs
```

---

## Modelo categorial del sistema

```
                    ┌─────────────┐
                    │  hodom-pg   │ ← fuente de verdad
                    │  (PG 14)    │
                    └──────┬──────┘
                           │
              ┌────────────┼────────────┐
              │            │            │
        ┌─────▼─────┐ ┌───▼────┐ ┌─────▼──────┐
        │   hdos    │ │ hdos   │ │  Streamlit  │
        │  (Python) │ │ -app   │ │  dashboard  │
        │  pipeline │ │(Next)  │ │  (readonly) │
        └───────────┘ └────────┘ └────────────┘
            Σ functor   Δ functor    Π functor
          (migra,corr)  (CRUD app)   (project)
```

Tres funtores consumen la misma base:

| Functor | Proyecto | Operación dominante | Schema filter |
|---------|----------|---------------------|---------------|
| **Σ** (generalización) | `hdos` Python | INSERT bulk, DDL, corrections | todos los 10 schemas |
| **Δ** (reestructuración) | `hdos-app` Next.js | CRUD operacional, portal | clinical, operational, reporting, portal, reference, territorial |
| **Π** (proyección) | Streamlit dashboards | SELECT readonly | todos via psycopg directo |

---

## 1. BROKEN-DIAGRAM: 9 tablas sin trigger PE-1

**Severidad: HIGH**

El path equation PE-1 (`T.patient_id = estadia.patient_id` para tablas con ambos `stay_id` y `patient_id`) está enforced por trigger `check_pe1` en **26 tablas**, pero **falta en 9** que tienen el mismo patrón:

| Tabla | stay_id | patient_id | PE-1 trigger | Poblada | Riesgo |
|-------|---------|------------|--------------|---------|--------|
| `condicion` | ✓ | ✓ | **NO** | 1,246 filas | **ALTO** — dato vivo sin guard |
| `documentacion` | ✓ | ✓ | **NO** | vacía | medio |
| `observacion` | ✓ | ✓ | **NO** | vacía | medio |
| `procedimiento` | ✓ | ✓ | **NO** | vacía | medio |
| `alerta` | ✓ | ✓ | **NO** | vacía | medio |
| `evento_adverso` | ✓ | ✓ | **NO** | vacía | medio |
| `notificacion_obligatoria` | ✓ | ✓ | **NO** | vacía | medio |
| `voluntad_anticipada` | ✓ | ✓ | **NO** | vacía | medio |
| `portal_mensaje` | ✓ | ✓ | **NO** | vacía | medio (hdos-app escribe) |

**Dato**: `condicion` tiene 1,246 filas sin PE-1 trigger. Verificación manual: **0 violaciones actuales** — pero no hay guard para INSERTs futuros. Cualquier INSERT con patient_id inconsistente pasaría silenciosamente.

**Diagrama roto**:
```
  condicion ──patient_id──→ paciente
      │                        ↑
      │ stay_id                │ estadia.patient_id
      ↓                        │
    estadia ───────────────────┘
    
  Conmutatividad NO ENFORCED por trigger.
  El triángulo puede romperse en cualquier INSERT.
```

**Reparación**: `BROKEN-DIAGRAM` — bind `check_pe1` a las 9 tablas faltantes.

---

## 2. REDUNDANT-BISIMILAR: encuesta_satisfaccion en 2 schemas

**Severidad: HIGH**

```
clinical.encuesta_satisfaccion     20 cols, 0 filas  ← hdos-app escribe aquí
reporting.encuesta_satisfaccion    48 cols, 33 filas ← hdos pipeline escribió aquí
```

Son dos objetos **no bisimilares** con el mismo nombre:
- Solo 6 columnas en común (encuesta_id, patient_id, stay_id, marca_temporal, fecha_encuesta, created_at)
- `clinical` tiene 14 columnas propias (Likert integers: satisfaccion_*, educacion_*, valoracion_mejoria, volveria)
- `reporting` tiene 42 columnas propias (booleans denormalizados del Google Form original, score_promedio, etc.)

**Consumidores**:

| Consumidor | Tabla que usa | Operación |
|------------|--------------|-----------|
| hdos-app API `/ficha/[stayId]/encuesta` | `clinical` | INSERT + SELECT |
| hdos pipeline `corr_14_satisfaccion_usuaria.py` | `reporting` | INSERT bulk |
| Streamlit dashboard | `reporting` | SELECT |

**Riesgo**: Un paciente puede tener encuesta en `reporting` (migración) pero `clinical` devuelve vacío a hdos-app. Son **dos mundos desconectados** — la aplicación y el pipeline no ven los mismos datos.

**Patrón**: `REDUNDANT-BISIMILAR` — mismo concepto, dos representaciones incompatibles.

**Reparación propuesta**: Coproducto (colímite) — crear una vista que unifique ambas tablas:

```sql
CREATE VIEW clinical.v_encuesta_unificada AS
SELECT encuesta_id, patient_id, stay_id, fecha_encuesta,
       satisfaccion_ingreso, ... , volveria, 'clinical' AS source
FROM clinical.encuesta_satisfaccion
UNION ALL
SELECT encuesta_id, patient_id, stay_id, fecha_encuesta,
       satisfaccion_ingreso, ... , volveria, 'reporting' AS source  
FROM reporting.encuesta_satisfaccion;
```

O migrar los 33 registros de `reporting` a `clinical` (el schema canónico para hdos-app).

---

## 3. DANGLING-REF: visita triple referencia geográfica

**Severidad: MEDIUM**

`operational.visita` tiene 3 FKs geográficas + GPS:

```
visita ──location_id──→ ubicacion (1659 filas)     0/7594 poblado
visita ──localizacion_id──→ localizacion (673)      7594/7594 poblado  
visita ──domicilio_id──→ domicilio → localizacion   7594/7594 poblado
visita.gps_lat/lng                                  176/7594 poblado (NavPro)
```

**Path equation verificada**: `visita.localizacion_id = domicilio.localizacion_id` en **100%** de los registros — la columna es redundante por construcción.

**Pero NO se puede eliminar**: hdos-app hace `LEFT JOIN territorial.localizacion l ON v.localizacion_id = l.localizacion_id` en 2 rutas API (`rutas/optimizar`, `rutas/[rutaId]/ejecutar`).

**Patrón**: `DANGLING-REF` (location_id, 0% poblada) + `REDUNDANT-BISIMILAR` (localizacion_id, derivable de domicilio).

**Reparación**: No destructiva. Documentar que:
- `location_id → ubicacion` es legacy dead (pero hdos-app lo referencia en vistas)
- `localizacion_id` es derivable pero consumido activamente
- La cadena canónica es: `visita → domicilio → localizacion → (lat,lng)`
- GPS real viene de `telemetria_segmento` via matching

---

## 4. NON-FUNCTORIAL: Drizzle schema drift

**Severidad: MEDIUM**

El schema Drizzle de hdos-app (`src/db/drizzle/schema.ts`, 3319 líneas) fue generado por introspección (`drizzle-kit pull`) pero **no se ha actualizado** después de:

| Cambio en PG | Reflejado en Drizzle? |
|---|---|
| 11 CHECK constraints nuevos (R5, R8) | **NO** |
| `telemetria_segmento.location_id` eliminado | **NO** (pero telemetry no está en schemaFilter) |
| Tablas telemetry nuevas (`gps_posicion`, `posicion_actual`) | **NO** (telemetry no en filter) |
| 3 vehículos en `operational.vehiculo` | **NO** (vehiculo está en filter pero sin datos al momento del pull) |

El functor Δ (hdos-app Drizzle) no es fiel al estado actual de PG. La divergencia es benigna (los CHECKs nuevos son más restrictivos, no menos), pero se acumula.

**Patrón**: `VERSION-MISMATCH` — schema ORM desactualizado respecto a DDL vivo.

**Reparación**: `cd /home/felix/projects/hdos-app && npx drizzle-kit pull`

---

## 5. ORPHAN-OBJECT: 70 tablas vacías (61%)

**Severidad: LOW**

| Categoría | Tablas | Ejemplo |
|-----------|--------|---------|
| Clínicas aspiracionales | 42 | medicacion, procedimiento, observacion, herida, sesion_rehabilitacion |
| Operacionales aspiracionales | 16 | orden_servicio, ruta, conductor, sla, agenda_profesional |
| Reporting sin datos | 5 | rem_cupos, rem_visitas, rem_personas_atendidas |
| Portal (hdos-app futuro) | 5 | portal_usuario, portal_mensaje, portal_invitacion, portal_acceso_log, audit_log |
| Territorial sin uso | 2 | matriz_distancia, zona (1 fila placeholder) |

**Patrón**: `ORPHAN-OBJECT` — objetos declarados pero sin morfismos activos.

**No es defecto**: es un schema aspiracional que modela el sistema target. Las tablas vacías son **reservaciones categóricas** para datos que vendrán del sistema operacional (hdos-app) cuando se despliegue.

**Riesgo**: bajo. Los triggers y CHECKs están correctamente definidos para cuando se pueblen.

---

## 6. BROKEN-DIAGRAM: check_stay_coherence parcial

**Severidad: MEDIUM**

El trigger `check_stay_coherence` (verifica que `visit_id` en una tabla clínica corresponda a una visita del mismo `stay_id`) está en **6 tablas**, pero faltan tablas con el mismo patrón:

| Tabla | visit_id | stay_id | Trigger | PE verificada |
|-------|----------|---------|---------|---------------|
| medicacion | ✓ | ✓ | ✓ | ✓ |
| procedimiento | ✓ | ✓ | ✓ | ✓ |
| observacion | ✓ | ✓ | ✓ | ✓ |
| nota_evolucion | ✓ | ✓ | ✓ | ✓ |
| sesion_rehabilitacion | ✓ | ✓ | ✓ | ✓ |
| educacion_paciente | ✓ | ✓ | ✓ | ✓ |
| **documentacion** | ✓ | ✓ | **NO** | — |
| **seguimiento_herida** | ✓ | ✗ | n/a | n/a |
| **seguimiento_dispositivo** | ✓ | ✗ | n/a | n/a |
| **toma_muestra** | ✓ | ✗ | n/a | n/a |

`documentacion` tiene visit_id + stay_id pero no tiene el trigger. Es un diagrama roto menor (tabla vacía).

---

## 7. NON-FUNCTORIAL: profesional.vehiculo TEXT vs FK

**Severidad: LOW**

```
profesional.vehiculo  TEXT        -- "texto legacy"
operational.vehiculo  vehiculo_id TEXT PK  -- tabla real con 3 vehículos
```

El morfismo `profesional → vehiculo` está roto — es un campo TEXT libre en lugar de una FK. Ningún profesional tiene este campo poblado actualmente.

**Patrón**: `NON-FUNCTORIAL` — relación semántica sin morfismo formal.

---

## 8. REDUNDANT-BISIMILAR: strict ↔ clinical

**Severidad: LOW**

```
strict.paciente           673 filas  (rut PK)
clinical.paciente         673 filas  (patient_id PK)

strict.hospitalizacion    838 filas  (id serial PK, rut FK)
clinical.estadia          779 filas  (stay_id PK, patient_id FK)
```

`strict` es un staging layer validado. 838 - 779 = **59 registros rechazados** que no pasaron a `clinical`. La relación entre schemas es un Σ-functor con pérdida:

```
strict.hospitalizacion ──Σ──→ clinical.estadia  (pérdida: 59/838 = 7%)
```

No hay FK cross-schema. La coherencia depende de la pipeline de migración (F3_estadias).

---

## Signature

```
Modo:      DAL_INTEGRATED
Issues:    8
Patrones:  BROKEN-DIAGRAM(2), REDUNDANT-BISIMILAR(2), DANGLING-REF(1),
           NON-FUNCTORIAL(2), ORPHAN-OBJECT(1)
Migración: Δ (reestructuración preservando forma)
Riesgos:   PE-1 sin guard en condicion (1246 filas vivas)
           Encuesta bifurcada (app vs pipeline ven datos distintos)
           Drizzle schema drift (11 CHECKs no reflejados)
```

## Reparaciones por prioridad

| # | Sev | Patrón | Acción | Blast radius |
|---|-----|--------|--------|---|
| 1 | HIGH | BROKEN-DIAGRAM | Bind `check_pe1` a 9 tablas faltantes (condicion es urgente) | Bajo — trigger solo valida, no modifica |
| 2 | HIGH | REDUNDANT-BISIMILAR | Unificar encuesta: migrar 33 filas reporting→clinical, o crear vista coproducto | Medio — afecta hdos pipeline + dashboard |
| 3 | MED | VERSION-MISMATCH | `drizzle-kit pull` en hdos-app | Bajo — solo regenera schema.ts |
| 4 | MED | BROKEN-DIAGRAM | Bind `check_stay_coherence` a `documentacion` | Bajo |
| 5 | LOW | NON-FUNCTORIAL | `profesional.vehiculo` → FK cuando se use | Ninguno (vacío) |
| 6 | LOW | DANGLING-REF | Documentar cadena geográfica canónica | Ninguno |

## Functor Information Loss

La auditoría en formato Markdown no puede expresar:
- La semántica temporal de los path equations (cuándo se verifican vs cuándo se podrían violar)
- La composición de los 3 funtores consumidores (Σ, Δ, Π) como adjunción triple
- El behavioral equivalence entre las dos tablas encuesta (requeriría coalgebra)
