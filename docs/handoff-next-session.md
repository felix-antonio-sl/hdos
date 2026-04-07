# Handoff — Próxima Sesión

## Contexto rápido

Sesión 2026-04-07 (segunda). Modelo de domicilio georeferenciado implementado. 671 localizaciones, 646 geocodificadas con Google Maps. Dashboard actualizado con Sprint 3+. 4 correcciones aplicadas (CORR-08 a CORR-11).

**DB**: `postgresql://hodom:hodom@localhost:5555/hodom` (container `hodom-pg`)
**Dashboard**: container `hdos-app` via Traefik → hdos.sanixai.com

## Para retomar

```bash
cd /home/felix/projects/hdos

# Verificar PG
docker exec hodom-pg psql -U hodom -d hodom -c "SELECT count(*) FROM clinical.estadia;"
# Esperado: 779

# Verificar domicilios
docker exec hodom-pg psql -U hodom -d hodom -c "
  SELECT precision_geo, count(*) FROM territorial.localizacion GROUP BY precision_geo ORDER BY count(*) DESC;"
# Esperado: exacta 262, aproximada 234, centroide_localidad 150, NULL 25

# Verificar dashboard
curl -s https://hdos.sanixai.com/_stcore/health
# Esperado: ok

# Si PG no responde:
docker start hodom-pg

# Si dashboard no responde:
docker rm -f hdos-app && docker compose up -d
```

## Lo que se hizo esta sesión

### 1. Dashboard Sprint 3+ (P0.1)
- 3 sub-tabs nuevos en Operacional: Visitas (COMPLETA vs PROGRAMADA), Notas Evolución (1417), Dispositivos (155)
- Archivo: `apps/streamlit_migration_explorer.py`

### 2. CORR-08: Estadías sin establecimiento (P0.2)
- 84/123 estadías resueltas por inferencia dirección → comuna → CESFAM
- Cobertura establecimiento: 84.2% → 95.0%
- Script: `scripts/corr_08_establecimiento_por_direccion.py`
- 39 restantes sin dirección ni comuna

### 3. Modelo domicilio georeferenciado (nuevo)
- `territorial.localizacion` — 671 puntos geográficos con coords obligatorias
- `clinical.domicilio` — binding temporal paciente ↔ localización (tipo: principal/alternativo/temporal/eleam)
- `operational.visita` — columnas `localizacion_id` + `domicilio_id` para uso futuro
- Trigger PE1/PE2: coherencia visita-domicilio
- Exclusión PE4: máximo 1 principal vigente por paciente
- Vista: `clinical.v_domicilio_vigente`
- DDL: `scripts/migrate_to_pg/ddl_domicilio.sql`
- Functor: `scripts/migrate_to_pg/functors/f12_domicilios.py`
- `latitud`/`longitud` ahora nullable (PE3 relajado: mejor NULL honesto que centroide falso)

### 4. CORR-09: Normalización de direcciones
- 480 direcciones normalizadas: Title Case, tipo de vía, localidades INE, typos
- Norma IDE Chile 2023 + INE Censo + features.csv (634 entidades rurales)
- Script: `scripts/corr_09_normalizar_direcciones.py`

### 5. CORR-10: Enriquecimiento desde redundancia pipeline
- 260 direcciones mejoradas cruzando variantes de `patient_address.csv` (intermediate)
- 158 pacientes sin dirección que sí la tenían en episodios previos
- 95 números de calle rescatados
- Script: `scripts/corr_10_enriquecer_direcciones_redundancia.py`

### 6. CORR-11: Direcciones recuperadas del DAU hospitalario
- 28/33 pacientes restantes resueltos via CLI `h` → DAU → texto_resumen
- Parsing: `Dirección : X Comuna : Y` del texto DAU
- SQL: `scripts/corr_11_direcciones_dau.sql`

### 7. Geocoding Google Maps
- 646/671 localizaciones geocodificadas
- 262 exacta (39%), 234 aproximada (35%), 150 centroide_localidad (22%)
- 25 sin coordenadas (5 sin dirección + 20 irresolubles)
- API key: `AIzaSyDNhu45OKX0jwYrbD9wcdz4LsG5utS-rss` (Geocoding API habilitado)
- Script: `scripts/geocode_localizaciones.py`

### 8. CLAUDE.md mejorado
- Documentación PG migration, infra Docker, functores, testing

### 9. Runner fix
- `--phase` ahora funciona con `skip_deps` para ejecutar fases individuales
- Archivo: `scripts/migrate_to_pg/framework/runner.py`

## Estado actual de la base de datos

| Entidad | N |
|---|---|
| Pacientes | 673 |
| Estadías | 779 (740 con establecimiento, 95.0%) |
| Localizaciones | 671 (646 geocodificadas, 96.3%) |
| Domicilios | 671 (todos vigentes) |
| Visitas | 7,594 |
| Notas evolución | 1,417 |
| Dispositivos | 155 |
| Provenance total | ~22,000 |

### Distribución de precisión geográfica
| Precisión | N | % |
|---|---|---|
| exacta | 262 | 39.0% |
| aproximada | 234 | 34.9% |
| centroide_localidad | 150 | 22.4% |
| NULL (sin coordenada) | 25 | 3.7% |

## Tareas pendientes por prioridad

### P1 — Enriquecimiento

1. **Texto de epicrisis** — 295 DOCX sin parsear
   - F₈ solo cargó metadata; parsear contenido con python-docx
   - Poblar `clinical.epicrisis.resumen_evolucion`
   - Dir: `documentacion-legacy/drive-hodom/EPICRISIS ENFERMERIA /`

2. **Mapeo prestaciones REM**
   - 120 tipos de visita → `reference.catalogo_prestacion`
   - Necesario para reporting MINSAL

3. **Satisfacción usuaria** — 33 encuestas
   - `documentacion-legacy/drive-hodom/RESPUESTA SATISFACCIÓN USUARIA.xlsx`

### P2 — Calidad

4. **25 localizaciones sin coordenadas** — requieren geocoding manual o GPS terreno

5. **39 estadías sin establecimiento** — sin dirección ni comuna, irresolubles sin dato externo

6. **Bug Stage 3 CSV** (`build_hodom_enriched.py` ~L1039)
   - CEFSAMs registrados como localidades con comuna vacía
   - No afecta PG pero contamina CSVs

### P3 — Dashboard

7. **Agregar mapa de domicilios** al dashboard
   - Ahora que hay coordenadas reales, mostrar mapa con pydeck/folium
   - Colores por precisión (exacta=verde, aproximada=amarillo, etc.)

8. **Sub-tab Domicilios** en dashboard
   - Vista de domicilios vigentes, búsqueda por paciente, filtro por comuna

### P3 — Futuro

9. **Vincular visitas futuras** a domicilios
   - Las columnas `localizacion_id` / `domicilio_id` en visita están listas
   - Trigger PE1 auto-completa localización desde domicilio

10. **Geocoding incremental** — cuando se registren nuevos pacientes/domicilios
    - Script reutilizable: `scripts/geocode_localizaciones.py`

## Archivos clave de esta sesión

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
| `docs/reporte-cambios-domicilio-2026-04-07.md` | Reporte para stakeholders |

## CLI hospitalario (h)

```bash
/home/felix/.local/bin/h status          # verificar conectividad
/home/felix/.local/bin/h who <rut>       # identidad (nombre, CP)
/home/felix/.local/bin/h hx <rut>        # urgencias + hospitalizaciones
/home/felix/.local/bin/h dau <atencion_id>  # DAU completo (tiene dirección en texto_resumen)
```

Requiere Tailscale activo + proxy `c17102493` online.
Patrón para extraer dirección del DAU: `re.search(r'Dirección\s*:\s*(.+?)\s*Comuna\s*:', texto_resumen)`
