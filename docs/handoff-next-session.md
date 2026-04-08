# Handoff — Próxima Sesión

## Contexto rápido

Sesión 2026-04-07 (tercera). Enriquecimiento P1 completado. Dashboard Sprint 4 (10 tabs, mapa pydeck). Visitas 100% vinculadas a domicilios. 80/80 tests passing. 7 correcciones nuevas (CORR-08 a CORR-14).

**DB**: `postgresql://hodom:hodom@localhost:5555/hodom` (container `hodom-pg`)
**Dashboard**: container `hdos-app` via Traefik → hdos.sanixai.com

## Para retomar

```bash
cd /home/felix/projects/hdos

# Verificar PG
docker exec hodom-pg psql -U hodom -d hodom -c "SELECT count(*) FROM clinical.estadia;"
# Esperado: 779

# Verificar domicilios + visitas vinculadas
docker exec hodom-pg psql -U hodom -d hodom -c "
  SELECT count(*) AS localizaciones FROM territorial.localizacion;"
# Esperado: 673
docker exec hodom-pg psql -U hodom -d hodom -c "
  SELECT count(*) AS total, count(domicilio_id) AS con_domicilio FROM operational.visita;"
# Esperado: 7594 / 7594 (100%)

# Verificar dashboard
curl -s https://hdos.sanixai.com/_stcore/health
# Esperado: ok

# Si PG no responde:
docker start hodom-pg

# Si dashboard no responde:
docker rm -f hdos-app && docker compose up -d
```

## Lo que se hizo esta sesión

### CORR-12: Epicrisis DOCX parseadas (P1.1)
- 295 DOCX parseados, 126 vinculados a pacientes en PG (169 sin paciente en DB — períodos no migrados)
- Campos extraídos: diagnóstico (126), evolución clínica (126), examen físico/invasivos/heridas (102), servicio origen (7), derivación APS (6)
- Parsing robusto: regex para EVOLUCIÓN, INVASIVOS, HERIDAS, OSTOMÍAS, PLAN DE ENFERMERÍA
- Script idempotente: `scripts/corr_12_parsear_epicrisis_docx.py`
- Dependencia: `python-docx` (instalado en .venv)

### CORR-13: Catálogo prestaciones REM (P1.2)
- 16 prestaciones atómicas en `reference.catalogo_prestacion` (KTM, KTR, FONO, TTO_EV, CA, CS, etc.)
- 7,590/7,594 visitas mapeadas a `prestacion_id` (código primario)
- `reporting.visita_prestacion` — tabla junction M:N con 11,926 filas (descomposición de 145 combinaciones → atómicas)
- Normalización: VM_INGRESO→VM_ING, VM_EGRESO→VM_EGR
- SQL idempotente: `scripts/corr_13_catalogo_prestaciones_rem.sql`

### CORR-14: Satisfacción usuaria (P1.3)
- 33 encuestas cargadas en `reporting.encuesta_satisfaccion` (30 vinculadas a paciente, 3 sin match)
- 45 columnas del formulario Google → campos estructurados (Likert 1-5, booleanos, texto)
- Score promedio: 4.76/5.0 | Volverían: 20 sí + 8 prob. sí + 3 prob. no + 2 no
- Script idempotente: `scripts/corr_14_satisfaccion_usuaria.py`

### Dashboard Sprint 4 (P3)
- **Tab Mapa**: pydeck + CartoDB, 646 domicilios geocodificados, colores por precisión, tooltips, filtros
- **Sub-tab Domicilios** en Territorial: tabla con búsqueda, filtros, métricas de cobertura
- **Sub-tab Prestaciones REM** en Operacional: catálogo, distribución por estamento, área chart por mes
- **Sub-tab Epicrisis** actualizado: diagnósticos, evolución clínica, examen físico (antes solo metadata)
- **Tab Satisfacción**: scores Likert, dimensiones, distribución volvería/mejoría
- **Overview** actualizado: métricas de prestaciones, encuestas, domicilios, localizaciones
- Dependencia: `pydeck` agregado a Dockerfile.migra

### Vinculación visitas ↔ domicilios
- 7,594/7,594 visitas vinculadas a domicilio + localización (100%)
- 2 pacientes resueltos via DAU: Antonio Cerda (Durazno 927) y John Sepúlveda (Santa Rosa Ñiquihue)
- Trigger PE1 auto-llenó `localizacion_id` desde `domicilio_id`

### Enriquecimiento quick wins
- **Códigos MAI**: 11/16 prestaciones en catálogo ahora tienen código MAI oficial (CANASTA HODOM.xlsx)
- **Actividad profesional diaria**: 88 días en `reporting.actividad_profesional_diaria` (enfermería 9.1/día, kine 8.9/día, fono 4.1/día, médico 2.7/día)
- **Fechas nacimiento**: 672/673 ya tenían fecha — sin acción
- **resp antiguo**: solo 5/47 match — sin acción

### Tests
- 80/80 tests passing (pytest)

### docs/specs commiteados
- 31 archivos de diseño MVP HODOM-HSC (paquete consolidado + paquete inicial)

## Estado actual de la base de datos

| Entidad | N |
|---|---|
| Pacientes | 673 |
| Estadías | 779 (740 con establecimiento, 95.0%) |
| Localizaciones | 673 (648 geocodificadas, 96.3%) |
| Domicilios | 673 (todos vigentes) |
| Visitas | 7,594 (100% con domicilio, 7,590 con prestación) |
| Prestaciones (catálogo) | 16 atómicas |
| Visita↔Prestación (M:N) | 11,926 |
| Epicrisis | 126 (con evolución clínica real) |
| Encuestas satisfacción | 33 (30 vinculadas, score 4.76/5) |
| Notas evolución | 1,417 |
| Dispositivos | 155 |
| GPS posiciones | 124,626 (3 vehículos, ene-abr 2026, NavPro.cl) |
| Segmentos telemetría | 11,374 (9,650 drives + 1,724 stops) |
| Stops con visita match | 176 (correlación GPS ↔ domicilio <150m) |
| Resúmenes diarios | 250 (km, min drive/stop, vmax por vehículo) |
| Vehículos | 3 (PFFF57, RGHB14, TZXS94) |
| Provenance total | ~32,300 |

## SYNC-GPS: NavPro.cl → PG telemetry (2026-04-08)

### Script: `scripts/sync_gps_navpro.py`
- `--poll`: posición actual 3 vehículos (cada 30 min, 07:00-21:00 Chile)
- sin flag: sync completo CSV + detección paradas + matching visitas (diario 21:30 Chile)
- Backfill: 124,626 posiciones, 11,374 segmentos, 176 matches
- Cron configurado en crontab (usuario felix)
- Logs: `/var/log/hdos-gps-poll.log`, `/var/log/hdos-gps-sync.log`
- Credenciales NavPro: `NAVPRO_USER`/`NAVPRO_PASS` env vars (fallback hardcoded)
- Requiere: `cloudscraper` (bypass Cloudflare)

### Tablas creadas
- `telemetry.gps_posicion` — puntos GPS raw (dt, lat, lng, speed, motion, ignition, ...)
- `telemetry.posicion_actual` — 1 fila por vehículo, UPSERT cada 30 min
- `operational.vehiculo` — 3 vehículos HODOM con patente y GPS device name
- `telemetry.telemetria_dispositivo` — 3 dispositivos GPS vinculados a vehículos

### Matching GPS ↔ visitas
- Haversine <150m entre parada GPS y `territorial.localizacion` del paciente
- Coincidencia temporal: misma fecha que `operational.visita`
- Score de correlación 0.61-0.97 (176 matches sobre 1,724 stops)

## Tareas pendientes por prioridad

### P1 — Enriquecimiento (COMPLETADO)

~~1. Texto epicrisis~~ → CORR-12 (126 registros con evolución real)
~~2. Mapeo prestaciones REM~~ → CORR-13 (16 atómicas, 11,926 descomposiciones)
~~3. Satisfacción usuaria~~ → CORR-14 (33 encuestas, score 4.76/5)

### P2 — Calidad

4. **25 localizaciones sin coordenadas** — requieren geocoding manual o GPS terreno

5. **39 estadías sin establecimiento** — sin dirección ni comuna, irresolubles sin dato externo

6. **Bug Stage 3 CSV** (`build_hodom_enriched.py` ~L1039)
   - CEFSAMs registrados como localidades con comuna vacía
   - No afecta PG pero contamina CSVs

### P3 — Dashboard (COMPLETADO)

~~7. Mapa de domicilios~~ → Tab Mapa con pydeck (646 puntos, colores por precisión)
~~8. Sub-tab Domicilios~~ → En Territorial (búsqueda, filtros, métricas)

### P3 — Futuro

~~9. Vincular visitas a domicilios~~ → 7,594/7,594 (100%), trigger PE1 activo

10. **Geocoding incremental** — 2 localizaciones nuevas (Cerda, Sepúlveda) + 25 anteriores sin coords
    - Script reutilizable: `scripts/geocode_localizaciones.py`

## Archivos clave de esta sesión

| Archivo | Propósito |
|---|---|
| `scripts/corr_12_parsear_epicrisis_docx.py` | CORR-12: parser DOCX epicrisis → PG |
| `scripts/corr_13_catalogo_prestaciones_rem.sql` | CORR-13: catálogo + descomposición REM |
| `scripts/corr_14_satisfaccion_usuaria.py` | CORR-14: encuestas satisfacción → PG |

### Sesión anterior
| Archivo | Propósito |
|---|---|
| `scripts/migrate_to_pg/ddl_domicilio.sql` | DDL modelo domicilio |
| `scripts/migrate_to_pg/functors/f12_domicilios.py` | Functor F₁₂ |
| `scripts/corr_08_establecimiento_por_direccion.py` | CORR-08 generador |
| `scripts/corr_09_normalizar_direcciones.py` | CORR-09 normalización |
| `scripts/corr_10_enriquecer_direcciones_redundancia.py` | CORR-10 redundancia |
| `scripts/corr_11_direcciones_dau.sql` | CORR-11 DAU hospitalario |
| `scripts/geocode_localizaciones.py` | Geocoding Google Maps |
| `apps/streamlit_migration_explorer.py` | Dashboard (6 sub-tabs Operacional) |

## CLI hospitalario (h)

```bash
/home/felix/.local/bin/h status          # verificar conectividad
/home/felix/.local/bin/h who <rut>       # identidad (nombre, CP)
/home/felix/.local/bin/h hx <rut>        # urgencias + hospitalizaciones
/home/felix/.local/bin/h dau <atencion_id>  # DAU completo (tiene dirección en texto_resumen)
```

Requiere Tailscale activo + proxy `c17102493` online.
Patrón para extraer dirección del DAU: `re.search(r'Dirección\s*:\s*(.+?)\s*Comuna\s*:', texto_resumen)`
