# Handoff — Próxima Sesión de Continuidad

## Contexto rápido

Migración categorial de HODOM legacy a PostgreSQL completada en sesión 2026-04-07. 13 functores, ~18,800 objetos, 18 tablas, 7 correcciones manuales. Dashboard live en hdos.sanixai.com.

**DB**: `postgresql://hodom:hodom@localhost:5555/hodom` (container `hodom-pg`)
**Dashboard**: container `hdos-app` via Traefik → hdos.sanixai.com
**Handoff completo**: `docs/handoff-2026-04-07.md`

## Para retomar

```bash
cd /home/felix/projects/hdos

# Verificar que PG está vivo
docker exec hodom-pg psql -U hodom -d hodom -c "SELECT count(*) FROM clinical.estadia;"
# Esperado: 779

# Verificar dashboard
curl -s https://hdos.sanixai.com/_stcore/health
# Esperado: ok

# Si PG no existe (server reiniciado):
docker start hodom-pg  # o recrear con:
# docker run --name hodom-pg -e POSTGRES_DB=hodom -e POSTGRES_USER=hodom -e POSTGRES_PASSWORD=hodom -p 5555:5432 -d postgres:14-alpine
# docker network connect web hodom-pg
# Luego re-ejecutar migración completa:
# .venv/bin/python scripts/migrate_to_pg/run_migration.py --db-url postgresql://hodom:hodom@localhost:5555/hodom

# Si dashboard no responde:
docker compose up -d --build
```

## Tareas pendientes por prioridad

### P0 — Valor inmediato

1. **Actualizar dashboard** con datos de Sprint 3+
   - El dashboard tiene 8 tabs pero NO muestra F₇b (visitas realizadas), F₁₁ (notas evolución), ni dispositivos
   - Agregar: sub-tab "Visitas Realizadas" con gráfico COMPLETA vs PROGRAMADA
   - Agregar: sub-tab "Notas Evolución" con búsqueda por paciente y filtro por fecha
   - Agregar: listado de dispositivos activos por paciente
   - Archivo: `apps/streamlit_migration_explorer.py`

2. **Resolver 123 estadías sin establecimiento** via CLI hospitalario
   - Requiere proxy `c17102493` (100.77.30.26) ONLINE en el hospital
   - Verificar: `tailscale status` → buscar `c17102493 active`
   - Luego: `/home/felix/.local/bin/h hx <rut> --hosp` para cada paciente solo-SGH
   - El SGH puede tener sala/servicio que permita inferir CESFAM
   - RUTs pendientes se pueden extraer con:
     ```sql
     SELECT p.rut FROM clinical.estadia e
     JOIN clinical.paciente p ON p.patient_id = e.patient_id
     WHERE e.establecimiento_id IS NULL;
     ```

### P1 — Enriquecimiento

3. **Texto de epicrisis** — 295 DOCX sin parsear
   - F₈ solo cargó metadata (nombre archivo → paciente)
   - Parsear contenido DOCX con python-docx/zipfile para extraer texto clínico
   - Poblar `clinical.epicrisis.resumen_evolucion` con texto real
   - Directorio: `documentacion-legacy/drive-hodom/EPICRISIS ENFERMERIA /`

4. **Mapeo prestaciones REM**
   - 120 tipos de visita normalizados (KTM, TTO_EV, CA, etc.)
   - Necesitan mapeo a `reference.catalogo_prestacion` para reporting MINSAL
   - Tabla de referencia ya existe en DDL con seed data

5. **Satisfacción usuaria** — 33 encuestas
   - `documentacion-legacy/drive-hodom/RESPUESTA SATISFACCIÓN USUARIA.xlsx`
   - Pequeño pero útil para indicadores de calidad
   - No hay tabla específica en DDL; podría ir en un schema `reporting`

### P2 — Calidad

6. **104 pacientes con comuna "OTRO"**
   - Muchos tienen dirección (`clinical.paciente.direccion`) que podría inferir comuna
   - Ej: si dirección contiene "ÑIQUÉN" → comuna NIQUEN

7. **Bug Stage 3 CSV pipeline** (`build_hodom_enriched.py` ~L1039)
   - Registra CEFSAMs como localidades con comuna vacía
   - No afecta PG pero contamina los CSV canonical
   - Fix: pasar la comuna correcta a `register_locality()` o no registrar CEFSAMs como localidades

### P3 — Futuro

8. **55 tablas DDL vacías** — dominios clínicos granulares (medicación, GES, interconsultas, recetas, etc.)
   - Requieren sistema operacional en producción, no existen en legacy
   - Cuando se implemente el sistema HODOM operacional, estas tablas se poblarán nativamente

## Arquitectura

```
input/raw_csv_exports/     → Stage 1-4 CSV pipeline → output/spreadsheet/canonical/
input/reference/legacy/    ─┐
documentacion-legacy/      ─┤→ scripts/migrate_to_pg/functors/F₀-F₁₁ → PostgreSQL (hodom-pg:5555)
db/hdos.db (SQLite)        ─┘
                                                                          ↓
                                                          apps/streamlit_migration_explorer.py
                                                          → Docker hdos-app → hdos.sanixai.com
```

## Archivos clave

| Archivo | Propósito |
|---|---|
| `scripts/migrate_to_pg/run_migration.py` | CLI migración: `--db-url --phase --dry-run` |
| `scripts/migrate_to_pg/functors/f*.py` | 13 functores (F₀-F₁₁) |
| `scripts/corr_*.sql` | 7 correcciones manuales documentadas |
| `apps/streamlit_migration_explorer.py` | Dashboard Streamlit (8 tabs) |
| `docker-compose.yml` | Deploy hdos-app → hdos.sanixai.com |
| `Dockerfile.migra` | Image Streamlit + psycopg |
| `docs/handoff-2026-04-07.md` | Handoff detallado de esta sesión |
| `docs/models/hodom-integrado-pg-v4.sql` | DDL canónico (100 tablas) |
| `docs/models/migracion-legacy-pg-v4.md` | Diseño de migración (11 fases) |

## CLI hospitalario (h)

```bash
/home/felix/.local/bin/h status          # verificar conectividad
/home/felix/.local/bin/h who <rut>       # identificar paciente
/home/felix/.local/bin/h hx <rut> --hosp # hospitalizaciones previas
/home/felix/.local/bin/h ctx <id>        # contexto clínico completo
```

Requiere Tailscale activo + proxy `c17102493` online. Manual completo en `~/.openclaw/kv_commons/outbox/AGENT-MANUAL.md`.
