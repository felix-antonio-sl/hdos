# Reporte de Cambios — Modelo de Domicilio Georeferenciado

**Fecha**: 2026-04-07
**Base de datos**: `hodom-pg` (PostgreSQL 14, puerto 5555)
**Alcance**: Nuevas tablas, corrección de establecimiento, actualización de dashboard

---

## 1. Resumen ejecutivo

Se implementaron tres cambios estructurales en la base de datos HODOM:

1. **Modelo de domicilio georeferenciado** — nuevo modelo que separa la dirección del paciente en una localización geográfica (con coordenadas obligatorias) y un vínculo temporal paciente-domicilio, soportando múltiples domicilios simultáneos por paciente.

2. **Corrección CORR-08** — resolución de 84 estadías que no tenían establecimiento asignado, elevando la cobertura de 84.2% a 95.0%.

3. **Dashboard Sprint 3+** — tres nuevas secciones en el dashboard de migración (hdos.sanixai.com) mostrando visitas realizadas, notas de evolución y dispositivos.

---

## 2. Modelo de domicilio — Por qué

El campo `clinical.paciente.direccion` (texto plano) no cubría las necesidades reales del programa HODOM:

| Necesidad | Antes | Ahora |
|-----------|-------|-------|
| Dirección rural sin calle/número | Texto libre sin estructura | Texto libre + referencia + localidad |
| Paciente cambia de domicilio | Se sobrescribía el campo | Registro temporal con vigencia |
| Múltiples domicilios simultáneos (ELEAM + familiar) | No soportado | Múltiples registros con tipo |
| Visita en dirección no registrada (familiar de otra ciudad) | Imposible | Localización ad-hoc en visita |
| Georreferenciación para rutas | No existía | Coordenadas obligatorias en toda localización |

---

## 3. Nuevas tablas y columnas

### 3.1 `territorial.localizacion`

Punto geográfico a nivel de paciente. Coordenadas **siempre** presentes.

| Columna | Tipo | Descripción |
|---------|------|-------------|
| `localizacion_id` | TEXT PK | Hash determinista |
| `direccion_texto` | TEXT | Texto libre ("Camino a Monte Blanco km 3, parcela 5") |
| `referencia` | TEXT | Indicación ad-hoc ("frente al colegio", "antes de la copa de agua") |
| `comuna` | TEXT | Comuna inferida o declarada |
| `localidad` | TEXT | Sector o localidad reconocida |
| `tipo_zona` | TEXT | URBANO, PERIURBANO, RURAL, RURAL_AISLADO |
| `latitud` | REAL NOT NULL | Coordenada obligatoria |
| `longitud` | REAL NOT NULL | Coordenada obligatoria |
| `precision_geo` | TEXT NOT NULL | Calidad de la coordenada (ver abajo) |
| `fuente_coords` | TEXT | Origen de las coordenadas |

**Valores de `precision_geo`:**

- `exacta` — GPS de terreno o geocoding verificado
- `aproximada` — Estimada por referencia
- `centroide_localidad` — Centro del sector conocido
- `centroide_comuna` — Centro de la comuna (peor caso, pero honesto)

> Actualmente los 671 registros tienen `precision_geo = 'centroide_comuna'`. Las coordenadas reales se irán incorporando desde GPS de terreno o geocoding.

### 3.2 `clinical.domicilio`

Vínculo temporal entre paciente y localización.

| Columna | Tipo | Descripción |
|---------|------|-------------|
| `domicilio_id` | TEXT PK | Hash determinista |
| `patient_id` | TEXT FK → paciente | Paciente propietario |
| `localizacion_id` | TEXT FK → localizacion | Punto geográfico |
| `tipo` | TEXT | `principal`, `alternativo`, `temporal`, `eleam` |
| `vigente_desde` | DATE NOT NULL | Inicio de vigencia |
| `vigente_hasta` | DATE | NULL = vigente actualmente |
| `contacto_local` | TEXT | Teléfono en esta dirección específica |
| `notas` | TEXT | "Casa del hijo Pedro", "ELEAM Los Olivos" |

**Tipos de domicilio:**

- `principal` — Residencia habitual. Máximo uno vigente por paciente (constraint de exclusión).
- `alternativo` — Casa de familiar donde el paciente alterna. Puede haber varios simultáneos.
- `temporal` — Situación transitoria (ej: hijo de Santiago que viene a cuidar).
- `eleam` — Establecimiento de larga estadía para adultos mayores.

### 3.3 Columnas nuevas en `operational.visita`

| Columna | Tipo | Descripción |
|---------|------|-------------|
| `localizacion_id` | TEXT FK → localizacion | Punto donde ocurre la visita (puede ser ad-hoc) |
| `domicilio_id` | TEXT FK → domicilio | Domicilio conocido (opcional) |

> Estas columnas están vacías (NULL) para las 7,594 visitas existentes. Se usarán a futuro cuando se programen visitas con el nuevo modelo.

### 3.4 Vista `clinical.v_domicilio_vigente`

Vista de conveniencia que une domicilios actualmente vigentes con su localización.

---

## 4. Invariantes (reglas de integridad)

### Implementados como constraints/triggers

| ID | Regla | Implementación |
|----|-------|----------------|
| **PE1** | Si una visita referencia un domicilio, su localización DEBE coincidir con la del domicilio | Trigger `trg_visita_domicilio_coherence` (auto-fill o error) |
| **PE2** | El paciente del domicilio debe ser el paciente de la estadía de la visita | Mismo trigger |
| **PE3** | Toda localización tiene coordenadas (sin excepción) | `NOT NULL` en latitud/longitud |
| **PE4** | Máximo un domicilio principal vigente por paciente en cualquier instante | `EXCLUDE USING gist` con daterange |

### No implementado como constraint (calidad)

| ID | Regla | Motivo |
|----|-------|--------|
| **PE5** | Paciente activo debería tener al menos un domicilio vigente | Datos legacy no lo cumplen; mejor como alerta en review queue |

---

## 5. Corrección CORR-08 — Estadías sin establecimiento

**Problema**: 123 estadías (15.8%) no tenían `establecimiento_id` asignado.

**Método**: Inferencia de comuna desde dirección del paciente + mapeo comuna → CESFAM.

| Estrategia | Estadías resueltas |
|------------|-------------------|
| Calle/villa conocida de San Carlos | 43 |
| Localidad rural reconocida | 32 |
| Comuna ya registrada (no "OTRO") | 5 |
| Nombre de comuna en dirección | 4 |
| **Total resueltas** | **84** |
| Sin dirección (irresolubles sin dato externo) | 39 |

**Resultado**: Cobertura de establecimiento **84.2% → 95.0%** (656 → 740 de 779 estadías).

Archivo SQL: `scripts/corr_08_establecimiento_por_direccion.sql`
Script generador: `scripts/corr_08_establecimiento_por_direccion.py`

---

## 6. Dashboard — Nuevas secciones

El dashboard en hdos.sanixai.com (tab "Operacional") ahora incluye:

| Sub-tab | Datos | Registros |
|---------|-------|-----------|
| **Visitas** (actualizado) | Gráfico COMPLETA vs PROGRAMADA + desglose mensual por estado | 7,594 (6,029 completas / 1,565 programadas) |
| **Notas Evolución** (nuevo) | Búsqueda por paciente, filtro por tipo y fecha, distribución por profesión | 1,417 notas |
| **Dispositivos** (nuevo) | Filtro por tipo, métricas activos/total, distribución por tipo | 155 dispositivos |

---

## 7. Métricas actuales de la base de datos

| Entidad | Cantidad |
|---------|----------|
| Pacientes | 673 |
| Estadías | 779 |
| Estadías con establecimiento | 740 (95.0%) |
| Localizaciones | 671 |
| Domicilios | 671 (vigentes) |
| Visitas | 7,594 |
| Notas de evolución | 1,417 |
| Dispositivos | 155 |
| Registros de proveniencia (nuevos) | 2,726 |

### Distribución de domicilios por comuna

| Comuna | Domicilios |
|--------|-----------|
| San Carlos | 525 |
| Ñiquén | 67 |
| San Nicolás | 41 |
| Sin comuna resuelta | 35 |
| Bulnes | 1 |
| San Fabián | 1 |
| Chillán | 1 |

---

## 8. Archivos modificados o creados

| Archivo | Acción |
|---------|--------|
| `scripts/migrate_to_pg/ddl_domicilio.sql` | **Nuevo** — DDL del modelo de domicilio |
| `scripts/migrate_to_pg/functors/f12_domicilios.py` | **Nuevo** — Functor F₁₂ de migración |
| `scripts/migrate_to_pg/run_migration.py` | Modificado — F₁₂ en lista de functores |
| `scripts/migrate_to_pg/framework/runner.py` | Modificado — soporte `skip_deps` para `--phase` |
| `scripts/corr_08_establecimiento_por_direccion.py` | **Nuevo** — generador de corrección CORR-08 |
| `scripts/corr_08_establecimiento_por_direccion.sql` | **Nuevo** — SQL de corrección aplicado |
| `apps/streamlit_migration_explorer.py` | Modificado — 3 sub-tabs nuevos |
| `CLAUDE.md` | Modificado — documentación actualizada |

---

## 9. Próximos pasos

1. **Geocoding real** — Reemplazar centroides de comuna por coordenadas reales (GPS de terreno, Google Maps, o INE). El campo `precision_geo` permite distinguir la calidad.

2. **39 estadías sin establecimiento** — Requieren dato externo (DAU del hospital o revisión manual). No tienen dirección ni comuna.

3. **Domicilios múltiples** — El modelo ya soporta alternativo/temporal/ELEAM. Cuando el sistema operacional esté activo, se podrán registrar domicilios adicionales por paciente.

4. **Vincular visitas** — Las columnas `localizacion_id` y `domicilio_id` en visita están listas. Cuando se programe una visita nueva, se asigna la localización (trigger PE1 auto-completa si se indica el domicilio).

---

*Reporte generado el 2026-04-07. Base de datos: hodom-pg (PostgreSQL 14).*
