# Migration Explorer Dashboard

**Fecha**: 2026-04-06
**Estado**: Aprobado
**URL**: migra.sanixai.com

---

## 1. Objetivo

Dashboard Streamlit para explorar las entidades migradas a PostgreSQL v4, verificar relaciones FK, y monitorear la cobertura de proveniencia. Uso: ingeniero de datos durante el proceso de migración.

---

## 2. Arquitectura

Un solo archivo Streamlit conectado a PG via psycopg. Desplegado con Docker + Traefik en `migra.sanixai.com`, mismo patrón que `hdos.sanixai.com`.

### Archivos

| Archivo | Propósito |
|---|---|
| `apps/streamlit_migration_explorer.py` | Dashboard principal |
| `Dockerfile.migra` | python:3.12-slim + streamlit + pandas + psycopg[binary] |
| `docker-compose.migra.yml` | Service en red `web`, Traefik → migra.sanixai.com |

### Conexión PG

- Env var `DATABASE_URL`, default `postgresql://hodom:hodom@hodom-pg:5432/hodom`
- Container-to-container via red Docker `web`
- Queries via `psycopg.connect()` + `pandas.read_sql()`

---

## 3. Páginas

### 3.1 Overview (landing)

Contadores:
- Pacientes en `clinical.paciente`
- Estadías en `clinical.estadia`
- Establecimientos en `territorial.establecimiento`
- Ubicaciones en `territorial.ubicacion`
- Registros en `migration.provenance`

Estado por functor (F₀–F₃): query `migration.provenance` agrupado por `phase`, conteo de objetos.

Alertas hardcoded (Sprint 1):
- Estadías rechazadas por EXCLUDE constraint (count de strict.hospitalizacion - clinical.estadia)
- Estadías sin match canonical (provenance con source_type='strict' y sin field-level canonical)

### 3.2 Pacientes

Tabla principal:
```sql
SELECT p.patient_id, p.nombre_completo, p.rut, p.sexo, p.fecha_nacimiento,
       p.comuna, p.cesfam, p.prevision, p.estado_actual,
       COUNT(e.stay_id) AS estadias
FROM clinical.paciente p
LEFT JOIN clinical.estadia e ON e.patient_id = p.patient_id
GROUP BY p.patient_id
ORDER BY p.nombre_completo
```

Filtros sidebar: búsqueda texto (RUT/nombre), sexo, estado_actual, comuna.

Drill-down (click en fila → expander):
- Estadías del paciente (fecha_ingreso, fecha_egreso, diagnostico, estado, establecimiento)
- Proveniencia field-level:
```sql
SELECT field_name, source_type, source_file
FROM migration.provenance
WHERE target_table = 'clinical.paciente' AND target_pk = %s
ORDER BY field_name
```
- Badge visual: campo con `source_type='strict'` → verde, `source_type='canonical'` → azul

### 3.3 Estadías

Tabla principal:
```sql
SELECT e.stay_id, e.patient_id, p.nombre_completo, p.rut,
       e.fecha_ingreso, e.fecha_egreso, e.estado, e.diagnostico_principal,
       e.tipo_egreso, e.origen_derivacion, e.establecimiento_id,
       est.nombre AS establecimiento_nombre, e.confidence_level
FROM clinical.estadia e
JOIN clinical.paciente p ON p.patient_id = e.patient_id
LEFT JOIN territorial.establecimiento est ON est.establecimiento_id = e.establecimiento_id
ORDER BY e.fecha_ingreso DESC
```

Filtros: estado, rango fecha_ingreso, establecimiento, tiene_diagnostico (sí/no), confidence_level.

Drill-down (expander):
- Datos del paciente
- Establecimiento asociado
- Proveniencia (row-level + field-level)
- Flag: "stay_id fallback" si no hay provenance field-level con source_type='canonical'

### 3.4 Territorial

Dos subtabs:

**Establecimientos**:
```sql
SELECT est.establecimiento_id, est.nombre, est.tipo, est.comuna,
       est.servicio_salud, COUNT(e.stay_id) AS estadias
FROM territorial.establecimiento est
LEFT JOIN clinical.estadia e ON e.establecimiento_id = est.establecimiento_id
GROUP BY est.establecimiento_id
ORDER BY estadias DESC
```

**Ubicaciones**:
```sql
SELECT location_id, nombre_oficial, comuna, tipo, latitud, longitud
FROM territorial.ubicacion
ORDER BY comuna, nombre_oficial
```
Filtro por comuna.

### 3.5 Proveniencia

Tabla principal:
```sql
SELECT target_table, target_pk, source_type, source_file, source_key,
       phase, field_name, created_at
FROM migration.provenance
ORDER BY created_at DESC
LIMIT 1000
```

Filtros: phase (F0–F3), source_type (strict/canonical), target_table.

Estadísticas:
```sql
SELECT
    target_table,
    source_type,
    COUNT(*) FILTER (WHERE field_name IS NULL) AS row_level,
    COUNT(*) FILTER (WHERE field_name IS NOT NULL) AS field_level
FROM migration.provenance
GROUP BY target_table, source_type
ORDER BY target_table
```

---

## 4. Infraestructura Docker

### Dockerfile.migra

```dockerfile
FROM python:3.12-slim
WORKDIR /app
RUN pip install --no-cache-dir streamlit pandas "psycopg[binary]>=3.1"
COPY apps/streamlit_migration_explorer.py ./apps/
EXPOSE 8501
CMD ["streamlit", "run", "apps/streamlit_migration_explorer.py", \
     "--server.port=8501", "--server.headless=true"]
```

### docker-compose.migra.yml

```yaml
name: hdos-migra
services:
  app:
    build:
      context: .
      dockerfile: Dockerfile.migra
    container_name: hdos-migra
    restart: unless-stopped
    environment:
      - DATABASE_URL=postgresql://hodom:hodom@hodom-pg:5432/hodom
    networks:
      - web
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.hdos-migra.rule=Host(`migra.sanixai.com`)"
      - "traefik.http.routers.hdos-migra.entrypoints=websecure"
      - "traefik.http.routers.hdos-migra.tls.certresolver=myresolver"
      - "traefik.http.services.hdos-migra.loadbalancer.server.port=8501"

networks:
  web:
    external: true
```

### Prerequisito

El container `hodom-pg` debe estar en la red `web`:
```bash
docker network connect web hodom-pg
```

---

## 5. No incluido (YAGNI)

- Edición de datos (es exploración read-only)
- Mapa geoespacial (ya existe en el dashboard principal)
- Autenticación (herramienta interna)
- Tests (dashboard de exploración, no lógica de negocio)
