# HODOM como servicio de delivery clínico

## La tesis

Uber, DoorDash e Instacart resolvieron un problema que HODOM enfrenta todos los
días: hacer que un recurso móvil escaso (profesionales) llegue a una demanda dispersa
(pacientes en sus casas), dentro de ventanas de tiempo, con restricciones de capacidad,
y dejando trazabilidad verificable de que el servicio ocurrió.

La diferencia no es estructural — es de restricciones. Un Dasher puede llevar
cualquier pedido. Una enfermera no puede hacer kinesiología. Un viaje de Uber dura
8 minutos. Una curación domiciliaria dura 90. Pero la arquitectura de datos subyacente
— el grafo de matching, la máquina de estados del "viaje", el ruteo con ventanas de
tiempo, la verificación de entrega — es transferible casi directamente.

Hoy el pipeline HDOS sabe **qué** pasó (episodios, estadías, diagnósticos). No sabe
**cómo** se entregó el servicio: quién fue, a qué hora llegó, cuánto se demoró en
la ruta, si el paciente estaba, si se cumplió el plan de cuidados.

Este documento propone cerrar esa brecha con un modelo de datos inspirado en las
plataformas de delivery, adaptado a la realidad clínica de Ñuble.

---

## El gap: qué sabe HDOS hoy vs qué necesita saber

```
HOY (pipeline stages 1-4)              NECESITA SABER
─────────────────────────               ──────────────
Paciente X ingresó el 15/03            ¿Quién lo visitó el 18/03?
Requiere enfermería + kine             ¿Cuántas visitas recibió esta semana?
Tiene diagnóstico EPOC                 ¿El profesional llegó a la hora acordada?
Vive en Coihueco rural                 ¿Cuánto viajó el kine para llegar?
Gestora: María González               ¿Se cumplió la frecuencia del plan?
Usa oxígeno                            ¿Llevaron el O2 portátil?
Egresó el 20/04                        ¿Cuántas visitas se perdieron y por qué?
```

Las entidades actuales modelan la **demanda clínica**. Faltan las entidades que
modelan la **oferta operacional** y la **ejecución del servicio**.

---

## Mapeo conceptual: delivery → HODOM

El modelo se transfiere así. Las filas marcadas con `*` son donde HODOM agrega
complejidad que delivery no tiene.

```
UBER / DOORDASH                    HODOM
───────────────                    ─────
Customer                           Paciente
  └─ dirección de entrega            └─ domicilio (lat/lng, ya existe)
  └─ preferencias                    └─ ventana horaria, continuidad *

Driver / Dasher                    Profesional
  └─ vehículo                        └─ vehículo (auto, moto, transporte público)
  └─ ubicación GPS                   └─ base habitual + GPS en ruta
  └─ disponibilidad (online/off)     └─ turno + disponibilidad diaria
  └─ cualquier pedido                └─ solo lo que su profesión permite *

Order                              Orden de servicio
  └─ ítems del pedido                └─ tipo de prestación (curación, control, kine)
  └─ prioridad                       └─ acuidad clínica (urgente/normal) *
  └─ ventana de entrega              └─ frecuencia prescrita *

Trip / Delivery                    Visita domiciliaria
  └─ pickup → dropoff               └─ base → domicilio → siguiente visita
  └─ estados (en_ruta, llegó...)     └─ estados (en_ruta, llegó, en_atención...)
  └─ clock-in / clock-out            └─ EVV (verificación electrónica)
  └─ receipt                         └─ registro clínico *

Route                              Ruta diaria
  └─ secuencia de entregas           └─ secuencia de visitas
  └─ optimización TSP                └─ VRPTW con restricciones de skill *

Dispatch / Matching                Asignación
  └─ driver más cercano              └─ profesional: skill + cercanía + continuidad *
  └─ bipartite matching              └─ matching multi-factor ponderado

Rating                             Resultado de visita
  └─ 1-5 estrellas                   └─ completada / parcial / no realizada
  └─ feedback                        └─ satisfacción + adherencia clínica *

Surge zone / H3 hex                Zona operacional
  └─ demanda por hexágono            └─ carga por zona territorial
  └─ pricing dinámico                └─ priorización por acuidad *
```

---

## Modelo de datos

### Entidades nuevas sobre el pipeline existente

El pipeline actual produce `hospitalization_stay` y `patient_master` como salida
canónica. El modelo logístico se monta encima:

```
                    ┌─────────────────────┐
                    │  hospitalization_stay │ (existente, 29 campos)
                    │  patient_master      │ (existente, 16 campos)
                    └──────────┬──────────┘
                               │
                    ┌──────────▼──────────┐
                    │   service_order      │  ← plan de cuidados → órdenes
                    └──────────┬──────────┘
                               │ genera N visitas
                    ┌──────────▼──────────┐
                    │      visit          │  ← entidad central (el "Trip")
                    └───┬─────┬──────┬────┘
                        │     │      │
              ┌─────────▼┐ ┌─▼────┐ ┌▼──────────┐
              │ provider  │ │route │ │visit_event │
              └─────┬─────┘ └──────┘ └───────────┘
              ┌─────▼──────────┐
              │provider_schedule│
              └────────────────┘
```

Además: `zone` (zonificación territorial) y `supply_item` (insumos por visita).

---

### `provider` — el profesional como recurso móvil

En Uber, el Supply Entity modela "the state of an ongoing session for a driver."
En HODOM, `provider` modela al profesional como recurso despachable con competencias.

```sql
CREATE TABLE provider (
    provider_id       TEXT PRIMARY KEY,   -- hash(rut)
    rut               TEXT NOT NULL,
    nombre            TEXT NOT NULL,

    -- Tipo y competencias (el equivalente a vehicle_type + product_tier de Uber)
    profesion         TEXT NOT NULL,      -- ENFERMERIA | KINESIOLOGIA | FONOAUDIOLOGIA
                                         -- MEDICO | TRABAJO_SOCIAL | TENS | NUTRICION
    competencias      TEXT,              -- CSV: curaciones_avanzadas,oxigenoterapia,
                                         --      rehabilitacion_respiratoria,
                                         --      cuidados_paliativos,manejo_ostomias,
                                         --      elementos_invasivos,toma_muestras

    -- Movilidad (como vehicle.form_factor de Uber: CAR, BICYCLE, MOTORCYCLE, PEDESTRIAN)
    vehiculo          TEXT,              -- AUTO | MOTO | BICICLETA | TRANSPORTE_PUBLICO | PIE
    comunas_cobertura TEXT,              -- CSV: SAN_CARLOS,COIHUECO,NINHUE,...

    -- Capacidad (como max concurrent trips de Uber Supply)
    max_visitas_dia   INTEGER DEFAULT 6,

    -- Base geográfica (como driver home location)
    base_lat          REAL,
    base_lng          REAL,

    -- Estado (como driver online/offline/busy)
    estado            TEXT DEFAULT 'ACTIVO',  -- ACTIVO | LICENCIA | INACTIVO
    contrato          TEXT                    -- PLANTA | CONTRATA | HONORARIOS | COMPRA_SERVICIOS
);
```

**Por qué no es simplemente un "driver"**: Un driver de Uber es fungible — cualquiera
sirve cualquier trip. Un profesional HODOM tiene `profesion` (filtro duro) y
`competencias` (filtro blando). Esto convierte el matching de O(n) a O(n×m) pero con
poda agresiva por profesión.

---

### `provider_schedule` — disponibilidad como slots

En Uber, el driver pasa de offline a online con un tap. En HODOM, la disponibilidad
es estructurada: turnos, guardias, licencias. Inspirado en FHIR `Slot` y en los
`service_option` time slots de Instacart.

```sql
CREATE TABLE provider_schedule (
    schedule_id       TEXT PRIMARY KEY,
    provider_id       TEXT NOT NULL REFERENCES provider,
    fecha             DATE NOT NULL,
    hora_inicio       TIME NOT NULL,      -- 08:00
    hora_fin          TIME NOT NULL,      -- 14:00
    tipo              TEXT NOT NULL,      -- TURNO | GUARDIA | EXTRA | BLOQUEADO
    motivo_bloqueo    TEXT,              -- licencia_medica | capacitacion | feriado | administrativo
    UNIQUE(provider_id, fecha, hora_inicio)
);
```

---

### `service_order` — la orden de servicio (el "Order" de DoorDash)

En DoorDash, un Order tiene ítems, prioridad, ventana de entrega, y pickup/dropoff.
En HODOM, una `service_order` nace del plan de cuidados: el médico prescribe
"enfermería 3 veces por semana" y eso se convierte en una orden recurrente que
genera visitas concretas.

Puente entre la capa clínica existente (`episode_care_requirement`,
`episode_professional_need`) y la capa logística.

```sql
CREATE TABLE service_order (
    order_id          TEXT PRIMARY KEY,  -- hash(stay_id + service_type + fecha_inicio)
    stay_id           TEXT NOT NULL,     -- FK hospitalization_stay (existente)
    patient_id        TEXT NOT NULL,     -- FK patient_master (existente)

    -- Qué servicio (como order_items de DoorDash)
    service_type      TEXT NOT NULL,     -- ENFERMERIA | KINESIOLOGIA | FONOAUDIOLOGIA
                                        -- MEDICO | CURACION | TOMA_MUESTRA | CONTROL_SIGNOS
                                        -- OXIGENOTERAPIA | EDUCACION | TRABAJO_SOCIAL
    profesion_requerida TEXT NOT NULL,   -- ENFERMERIA | KINESIOLOGIA | etc.
    competencia_requerida TEXT,          -- curaciones_avanzadas | oxigenoterapia | NULL

    -- Frecuencia (no existe en delivery — los pedidos son one-shot)
    frecuencia        TEXT NOT NULL,     -- DIARIA | 3X_SEMANA | 2X_SEMANA | SEMANAL
                                        -- QUINCENAL | MENSUAL | UNICA
    duracion_est_min  INTEGER,          -- 30 | 60 | 90 | 120

    -- Prioridad (como surge/priority de Uber, pero clínica)
    prioridad         TEXT DEFAULT 'NORMAL',  -- URGENTE | ALTA | NORMAL

    -- Restricciones que delivery no tiene
    requiere_continuidad BOOLEAN DEFAULT FALSE,  -- mismo profesional siempre
    profesional_asignado TEXT,                    -- FK provider, para continuidad
    requiere_vehiculo    BOOLEAN DEFAULT FALSE,   -- transporte de O2/equipos
    insumos_requeridos   TEXT,                    -- CSV: set_curacion,oxigeno_portatil,...

    -- Ventana preferida (como delivery_window de Instacart)
    ventana_preferida TEXT,              -- MANANA | TARDE | INDIFERENTE
    notas_coordinacion TEXT,

    -- Vigencia
    fecha_inicio      DATE NOT NULL,
    fecha_fin         DATE,             -- NULL = mientras dure la estadía
    estado            TEXT DEFAULT 'ACTIVA',  -- ACTIVA | SUSPENDIDA | COMPLETADA | CANCELADA

    -- Métricas de cumplimiento
    visitas_planificadas INTEGER DEFAULT 0,
    visitas_completadas  INTEGER DEFAULT 0
);
```

**Transformación desde datos existentes**: Cada `episode_care_requirement` (hoy hay
4,140 registros de 10 tipos) + cada `episode_professional_need` (1,959 registros de
7 tipos) se traduce en una `service_order`. Ejemplo:

```
episode_care_requirement: {episode_id: "abc", type: "CURACIONES", is_active: true}
episode_professional_need: {episode_id: "abc", type: "ENFERMERIA", level: "SI"}
                    ↓
service_order: {
    stay_id: "xyz" (el stay que contiene episode "abc"),
    service_type: "CURACION",
    profesion_requerida: "ENFERMERIA",
    competencia_requerida: "curaciones_avanzadas",
    frecuencia: "3X_SEMANA",  ← derivada de protocolo clínico por tipo
    duracion_est_min: 60
}
```

---

### `visit` — la visita domiciliaria (el "Trip" de Uber)

**La entidad central del modelo logístico.** En Uber, un Trip es "a unit of work
composed of waypoints." En HODOM, una `visit` es una instancia concreta de servicio:
un profesional específico va a un paciente específico en una fecha específica.

```sql
CREATE TABLE visit (
    visit_id           TEXT PRIMARY KEY,  -- hash(order_id + fecha + provider_id)
    order_id           TEXT NOT NULL REFERENCES service_order,
    stay_id            TEXT NOT NULL,     -- denormalizado para queries rápidos
    patient_id         TEXT NOT NULL,
    provider_id        TEXT REFERENCES provider,  -- NULL = sin asignar
    route_id           TEXT REFERENCES route,     -- NULL = sin ruta
    seq_en_ruta        INTEGER,                   -- posición en la ruta

    -- Programación (como Uber SCHEDULED status)
    fecha              DATE NOT NULL,
    hora_plan_inicio   TIME,             -- 09:30 (puede ser NULL si solo se sabe la fecha)
    hora_plan_fin      TIME,             -- 10:30

    -- Ejecución real — los 6 campos EVV obligatorios
    -- (equivalentes al clock-in/clock-out + GPS de Uber trip)
    hora_real_inicio   TEXT,             -- ISO timestamp del clock-in
    hora_real_fin      TEXT,             -- ISO timestamp del clock-out
    gps_lat            REAL,             -- GPS al hacer clock-in
    gps_lng            REAL,
    gps_distancia_m    REAL,             -- distancia GPS vs domicilio registrado

    -- Estado (máquina de estados — ver sección siguiente)
    estado             TEXT NOT NULL DEFAULT 'PROGRAMADA',

    -- Métricas de viaje (como ETA/travel_time de Uber)
    travel_km          REAL,             -- km desde punto anterior
    travel_min         REAL,             -- minutos de viaje
    tiempo_atencion_min REAL,            -- minutos de atención efectiva

    -- Resultado (como delivered/failed de DoorDash)
    resultado          TEXT,             -- COMPLETA | PARCIAL | NO_REALIZADA
    motivo_no_realizada TEXT,            -- PACIENTE_AUSENTE | REHUSA | HOSPITALIZADO
                                        -- FALLECIDO | CLIMA | RUTA_INACCESIBLE
                                        -- PROFESIONAL_INDISPUESTO

    -- Documentación clínica (no existe en delivery)
    doc_estado         TEXT DEFAULT 'PENDIENTE',  -- PENDIENTE | REGISTRADA | APROBADA
    notas_clinicas     TEXT,

    -- Insumos (como order_items consumed)
    insumos_usados     TEXT,             -- CSV de insumos efectivamente utilizados

    -- REM (el equivalente al "payment processed" de delivery)
    rem_reportable     BOOLEAN DEFAULT TRUE,
    rem_prestacion     TEXT,             -- código de prestación para REM

    updated_at         TEXT              -- ISO timestamp
);
```

---

### Máquina de estados de `visit`

Directamente inspirada en los trip status de Uber (`processing → accepted →
arriving → in_progress → completed`) y DoorDash (`created → confirmed →
enroute_to_pickup → picked_up → enroute_to_dropoff → delivered`), pero con
estados clínicos post-entrega que delivery no necesita.

```
                    PROGRAMADA
                        │
                ┌───────┼───────┐
                │               │
            ASIGNADA        CANCELADA
                │
            DESPACHADA  (notificación al profesional)
                │
             EN_RUTA    (profesional sale, GPS activo)
                │
             LLEGADA    (GPS dentro del radio del domicilio = geofence de Uber)
                │
           EN_ATENCION  (clock-in EVV — equivale a trip "in_progress")
                │
        ┌───────┼───────┐
        │       │       │
   COMPLETA  PARCIAL  NO_REALIZADA
        │       │       │
        └───────┼───────┘
                │
           DOCUMENTADA  (registro clínico completado)
                │
            VERIFICADA  (supervisora aprueba — como QA de Axxess/WellSky)
                │
           REPORTADA_REM (incluida en reporte mensual MINSAL)
```

**Transiciones y sus triggers:**

| De → A | Trigger | Análogo delivery |
|---|---|---|
| PROGRAMADA → ASIGNADA | Motor de matching asigna profesional | Uber: `processing → accepted` |
| ASIGNADA → DESPACHADA | Push notification al profesional | DoorDash: `confirmed` |
| DESPACHADA → EN_RUTA | Profesional toca "Iniciar ruta" | Uber: driver starts navigation |
| EN_RUTA → LLEGADA | GPS entra en radio de 200m del domicilio | Uber: `arriving` (0.2 mi geofence) |
| LLEGADA → EN_ATENCION | Profesional hace clock-in EVV | Uber: `in_progress` (rider picked up) |
| EN_ATENCION → COMPLETA | Clock-out EVV, servicio completo | Uber: `completed` |
| EN_ATENCION → PARCIAL | Clock-out, servicio incompleto | — (delivery es binario) |
| EN_ATENCION → NO_REALIZADA | Paciente ausente/rehúsa | Uber: `rider_canceled` |
| PROGRAMADA → CANCELADA | Coordinación cancela | DoorDash: `cancelled` |
| COMPLETA → DOCUMENTADA | Profesional sube registro clínico | — (post-trip, no existe en delivery) |
| DOCUMENTADA → VERIFICADA | Supervisora revisa y aprueba | — (no existe en delivery) |
| VERIFICADA → REPORTADA_REM | Incluida en REM mensual | Uber: payment processed |

---

### `route` — la ruta diaria (como el Supply waypoint queue de Uber)

En Uber, el Supply Entity mantiene "an ordered queue of waypoints across one or more
trips." En HODOM, `route` es la secuencia optimizada de visitas que un profesional
ejecuta en un día.

```sql
CREATE TABLE route (
    route_id           TEXT PRIMARY KEY,  -- hash(provider_id + fecha)
    provider_id        TEXT NOT NULL REFERENCES provider,
    fecha              DATE NOT NULL,
    estado             TEXT DEFAULT 'PLANIFICADA',  -- PLANIFICADA | EN_CURSO | COMPLETADA

    -- Origen (como driver start location)
    origen_lat         REAL,
    origen_lng         REAL,
    hora_salida_plan   TIME,
    hora_salida_real   TEXT,

    -- Métricas agregadas de la ruta
    total_visitas      INTEGER,
    km_totales         REAL,
    minutos_viaje      REAL,
    minutos_atencion   REAL,

    -- Ratio de eficiencia (DoorDash: travel vs wait decomposition)
    -- ratio < 0.3 = bueno (menos de 30% del tiempo en viaje)
    ratio_viaje_atencion REAL,

    UNIQUE(provider_id, fecha)
);
```

El campo `ratio_viaje_atencion` viene directamente de DoorDash, que descompone cada
delivery en segmentos medibles y optimiza para minimizar "tiempo muerto" (viaje,
parking, espera). En HODOM, el equivalente es: ¿cuánto del día del profesional
es atención vs cuánto es ruta?

---

### `visit_event` — el event log (como Uber statechart transitions)

Uber usa statecharts con entry/exit actions. Cada transición de estado genera un
evento. DoorDash emite webhooks en cada cambio. Instacart tiene 31 tipos de webhook.
En HODOM, `visit_event` es el log inmutable de todo lo que pasó con una visita.

```sql
CREATE TABLE visit_event (
    event_id           INTEGER PRIMARY KEY AUTOINCREMENT,
    visit_id           TEXT NOT NULL REFERENCES visit,
    timestamp          TEXT NOT NULL,     -- ISO 8601
    estado_previo      TEXT,
    estado_nuevo       TEXT NOT NULL,
    lat                REAL,
    lng                REAL,
    origen             TEXT NOT NULL,     -- APP | SISTEMA | COORDINACION
    detalle            TEXT               -- JSON libre para metadata
);
```

**Ejemplo de secuencia para una visita real:**

```
08:15  PROGRAMADA → ASIGNADA      origen=SISTEMA    detalle={"provider":"María López","score":0.87}
08:15  ASIGNADA → DESPACHADA      origen=SISTEMA    detalle={"notificacion":"push"}
08:32  DESPACHADA → EN_RUTA       origen=APP        lat=-36.42 lng=-71.95
08:58  EN_RUTA → LLEGADA          origen=APP        lat=-36.41 lng=-71.97  detalle={"distancia_m":45}
09:01  LLEGADA → EN_ATENCION      origen=APP        lat=-36.41 lng=-71.97  detalle={"evv_clock_in":true}
09:52  EN_ATENCION → COMPLETA     origen=APP        lat=-36.41 lng=-71.97  detalle={"evv_clock_out":true,"duracion_min":51}
10:30  COMPLETA → DOCUMENTADA     origen=APP        detalle={"notas":"Curación herida operatoria limpia..."}
14:00  DOCUMENTADA → VERIFICADA   origen=COORDINACION  detalle={"revisora":"Ana Muñoz"}
```

Esto es exactamente lo que hacen los 6 elementos EVV obligatorios (21st Century
Cures Act en EEUU, trasladable al contexto REM chileno): tipo de servicio,
paciente, profesional, fecha, ubicación GPS, hora inicio/fin.

---

### `zone` — zonificación territorial

Uber creó H3 para particionar el mundo en hexágonos y medir oferta/demanda por celda.
En Ñuble, la geometría hexagonal no aporta valor (la demanda es demasiado dispersa).
Pero el concepto sí: zonas operacionales con características logísticas distintas.

```sql
CREATE TABLE zone (
    zone_id            TEXT PRIMARY KEY,
    nombre             TEXT NOT NULL,     -- "San Carlos Urbano", "Precordillera Pinto"
    tipo               TEXT NOT NULL,     -- URBANO | PERIURBANO | RURAL | RURAL_AISLADO
    comunas            TEXT NOT NULL,     -- CSV de comunas incluidas
    centroide_lat      REAL,
    centroide_lng      REAL,
    tiempo_acceso_min  INTEGER,          -- minutos desde Hospital San Carlos
    conectividad       TEXT,             -- BUENA | REGULAR | MALA | SIN_COBERTURA
    capacidad_dia      INTEGER           -- visitas posibles por profesional en esta zona
);
```

**Zonas operacionales de Ñuble:**

| Zona | Comunas | Acceso (min) | Conectividad | Visitas/prof/día |
|---|---|---|---|---|
| San Carlos Urbano | San Carlos (urbano) | 0-15 | buena | 6-8 |
| Punilla Periurbano | Coihueco, Ñiquén, San Nicolás | 15-30 | regular | 4-6 |
| Itata Rural | Ninhue, San Fabián | 30-60 | mala | 2-4 |
| Precordillera | Pinto (sectores altos), San Fabián (cordillera) | 60+ | sin cobertura | 1-2 |

La zona determina el `max_visitas_dia` efectivo: un profesional en zona
RURAL_AISLADO rinde 2 visitas donde en zona URBANO rendiría 7. Esto es análogo
al ajuste de surge pricing de Uber por hexágono H3, pero aplicado a capacidad
operacional en vez de precio.

---

### `supply_item` — insumos por visita

Delivery no necesita esto (el restaurant prepara el pedido). HODOM sí: el
profesional carga los insumos que necesita para cada visita. Es más parecido
al modelo de Instacart (shopper lleva los ítems) que al de Uber.

```sql
CREATE TABLE supply_item (
    item_id            TEXT PRIMARY KEY,
    nombre             TEXT NOT NULL,     -- "Set curación avanzada", "O2 portátil 2L"
    categoria          TEXT,             -- CURACION | MEDICAMENTO | EQUIPO | OXIGENO | DESCARTABLE
    peso_kg            REAL,             -- para restricciones de transporte
    requiere_vehiculo  BOOLEAN DEFAULT FALSE,
    stock_actual       INTEGER,
    umbral_reposicion  INTEGER
);
```

---

## Motor de matching: cómo asignar profesional a visita

### El problema

Lyft modela dispatch como **matching bipartito ponderado**: un conjunto de drivers,
un conjunto de riders, aristas pesadas entre cada par posible. El Hungarian algorithm
encuentra el matching óptimo global.

DoorDash va más lejos con DeepRed: genera ofertas candidatas, predice probabilidad
de aceptación con ML, y optimiza con programación lineal entera mixta (MIP).

En HODOM el problema es similar pero con restricciones duras de competencia:

```
PROFESIONALES DISPONIBLES          VISITAS SIN ASIGNAR (fecha D)
┌──────────────────────┐           ┌─────────────────────────────┐
│ Enf. María (auto)    │──────────→│ Curación Sr. Pérez (enf.)   │
│ Enf. Carla (moto)    │──╲   ╱──→│ Control Sra. Díaz (enf.)    │
│ Kine José (auto)     │───╲─╱───→│ Kine Sr. Muñoz (kine)       │
│ Fono Ana (transp.púb)│────╳────→│ Fono Sra. Rivas (fono)      │
│                      │───╱─╲───→│ Curación Sra. López (enf.)  │
│                      │──╱   ╲──→│ Control Sr. Soto (enf.)     │
└──────────────────────┘           └─────────────────────────────┘
        6 aristas válidas de 24 posibles (filtro por profesión)
```

### Scoring por arista

Cada arista válida se puntúa con 5 factores (inspirado en los edge weights de
Lyft pero con factores clínicos):

```python
def score_match(provider, visit, historico):
    """Puntúa la asignación de un profesional a una visita (0-1)."""

    # 1. Competencia (filtro duro ya pasó, esto puntúa profundidad)
    skills_pedidas = set(visit.order.competencia_requerida or [])
    skills_tiene = set(provider.competencias or [])
    s_skill = 1.0 if skills_pedidas <= skills_tiene else 0.5

    # 2. Distancia (como ETA de Uber — el factor más pesado en Lyft)
    km = haversine(provider.base_lat, provider.base_lng,
                   visit.patient.lat, visit.patient.lng)
    s_dist = max(0, 1.0 - km / MAX_KM_ZONA)

    # 3. Continuidad (no existe en delivery — es el factor diferencial de salud)
    visitas_previas = historico.count(provider.id, visit.patient_id)
    total_visitas = historico.count_all(visit.patient_id)
    s_cont = visitas_previas / max(total_visitas, 1)

    # 4. Carga de trabajo (como balance de Dashers en DoorDash MIP)
    asignadas_hoy = historico.visitas_hoy(provider.id, visit.fecha)
    s_carga = 1.0 - asignadas_hoy / provider.max_visitas_dia

    # 5. Logística (vehículo adecuado para insumos)
    necesita_vehiculo = visit.order.requiere_vehiculo
    tiene_vehiculo = provider.vehiculo in ('AUTO', 'MOTO')
    s_logistica = 1.0 if not necesita_vehiculo or tiene_vehiculo else 0.0

    # Ponderación
    return (0.25 * s_skill +
            0.25 * s_dist +
            0.25 * s_cont +
            0.15 * s_carga +
            0.10 * s_logistica)
```

### Override por continuidad

Si `service_order.requiere_continuidad = True` y existe un profesional con
historial > 3 visitas al paciente, ese profesional recibe score 1.0 automático
(como un "driver favorito" reservado). Esto no existe en Uber/DoorDash porque
delivery no tiene relación proveedor-cliente persistente.

---

## Optimización de rutas

### El problema formal

El Home Health Care Routing and Scheduling Problem (HHCRSP) es una extensión del
Vehicle Routing Problem with Time Windows (VRPTW), que es NP-hard. La formulación
matemática publicada en investigación académica:

```
Minimizar:  Σ c_ij · x_ijk    (costo total de viaje)
            para todo arco (i,j), todo profesional k

Sujeto a:
  - Cada paciente visitado exactamente una vez
  - Flujo conservado en cada nodo
  - Competencia: y_ik · RC_i ≤ Q_k  (skill del profesional ≥ requerimiento)
  - Carga: m ≤ Σ visitas_por_profesional ≤ n
  - Ventanas: e_i ≤ hora_llegada_i ≤ l_i
  - Propagación temporal: d_ik + t_ij ≤ a_jk + (1-x_ijk)·M
```

### Implementación pragmática para Ñuble

Con ~30 pacientes activos y ~5-8 profesionales, no se necesita el MIP completo
de DoorDash (que optimiza miles de Dashers). Un enfoque greedy + mejora local
alcanza:

```python
def build_routes(providers, visits, date, distance_fn):
    """Construye rutas diarias. Greedy por zona + mejora 2-opt."""

    # Paso 1: Agrupar visitas por zona
    by_zone = group_by(visits, key=lambda v: v.patient.zone_id)

    # Paso 2: Asignar zonas a profesionales (por cobertura)
    assignments = {}
    for zone_id, zone_visits in by_zone.items():
        eligible = [p for p in providers
                    if zone_id in p.comunas_cobertura
                    and p.visitas_restantes(date) > 0]
        # Distribuir visitas entre elegibles por capacidad
        assignments[zone_id] = distribute(zone_visits, eligible)

    # Paso 3: Ordenar visitas por nearest-neighbor dentro de cada ruta
    routes = []
    for provider_id, provider_visits in flatten(assignments):
        ordered = nearest_neighbor(provider_visits, start=provider.base)
        routes.append(Route(provider_id, date, ordered))

    # Paso 4: Mejora local 2-opt (intercambiar pares de visitas)
    for route in routes:
        route.visits = two_opt(route.visits, distance_fn)

    return routes
```

Para distancias reales: OSRM self-hosted con datos OpenStreetMap de Ñuble.
Alternativa sin servidor: precalcular una matriz de distancias entre las ~50
localidades activas (50×50 = 2,500 pares) y cachearla.

---

## KPIs: métricas de delivery aplicadas a HODOM

DoorDash descompone el tiempo de cada delivery en segmentos medibles y tiene
14,000 SLOs. HODOM puede adoptar una versión enfocada.

### Descomposición del tiempo de visita

Inspirado en la descomposición de DoorDash (order-to-kitchen, travel, parking,
wait, pickup, transit, dropoff):

```
                          TIEMPO TOTAL (orden → REM)
┌──────────┬──────────┬──────────┬──────────┬──────────┬──────────┬──────────┐
│ orden →  │asignación│despacho →│ viaje al │ atención │ documen- │ verifica-│
│asignación│→ despacho│  en_ruta │domicilio │ clínica  │ tación   │ ción     │
│          │          │          │          │          │          │ + REM    │
│  (sist.) │ (coord.) │  (prof.) │ (prof.)  │ (prof.)  │ (prof.)  │ (superv.)│
└──────────┴──────────┴──────────┴──────────┴──────────┴──────────┴──────────┘
  medible     medible   medible    GPS        EVV        app        workflow
  desde       desde     desde      desde      clock-in   timestamp  timestamp
  visit_event visit_event visit_event visit_event a        post-
                                               clock-out  atención
```

### Métricas operacionales

| Métrica | Cálculo | Meta | Análogo delivery |
|---|---|---|---|
| Cumplimiento de plan | visitas_completadas / visitas_planificadas | ≥ 90% | DoorDash completion rate |
| Puntualidad | visitas_en_ventana / visitas_totales | ≥ 85% | DoorDash OTD (on-time delivery) |
| Tiempo primera visita | horas desde orden hasta primera visita | ≤ 24h urgente | Uber ETA accuracy |
| Continuidad profesional | visitas_mismo_prof / total_visitas_paciente | ≥ 75% | — (no existe en delivery) |
| Eficiencia de ruta | minutos_atencion / (minutos_atencion + minutos_viaje) | ≥ 70% | DoorDash travel ratio |
| Documentación oportuna | docs_en_24h / total_visitas | ≥ 95% | — (post-delivery metric) |
| Verificación EVV | visitas_con_gps_valido / total | ≥ 98% | Uber GPS verification |
| Visitas perdidas | no_realizadas / programadas | ≤ 5% | DoorDash failed delivery rate |
| Carga equitativa | stddev(visitas_por_profesional) | ≤ 2.0 | Lyft driver fairness |

---

## Integración con el pipeline existente

### Stage 5: build_hodom_logistics.py

Se integra como una nueva etapa del pipeline, consumiendo la salida canónica:

```
Stage 4 (existente):  canonical/hospitalization_stay.csv
                      canonical/patient_master.csv
                          │
                          ▼
Stage 5 (nuevo):      build_hodom_logistics.py
                          │
                          ├── logistics/provider.csv
                          ├── logistics/provider_schedule.csv
                          ├── logistics/service_order.csv
                          ├── logistics/visit.csv
                          ├── logistics/route.csv
                          ├── logistics/visit_event.csv
                          ├── logistics/zone.csv
                          ├── logistics/supply_item.csv
                          └── logistics/kpi_daily.csv
```

### Derivación automática de service_orders

El stage 5 puede generar `service_order` automáticamente desde los datos existentes:

```python
# Mapeo: care_requirement_type → (service_type, profesion, competencia, frecuencia_default)
REQUIREMENT_TO_ORDER = {
    "CURACIONES":          ("CURACION",        "ENFERMERIA", "curaciones_avanzadas", "3X_SEMANA"),
    "TOMA_MUESTRAS":       ("TOMA_MUESTRA",    "ENFERMERIA", "toma_muestras",       "SEMANAL"),
    "TTO_EV":              ("TRATAMIENTO_EV",  "ENFERMERIA", None,                  "DIARIA"),
    "TTO_SC":              ("TRATAMIENTO_SC",  "ENFERMERIA", None,                  "DIARIA"),
    "TTO_IM":              ("TRATAMIENTO_IM",  "ENFERMERIA", None,                  "DIARIA"),
    "ELEMENTOS_INVASIVOS": ("MANEJO_INVASIVOS","ENFERMERIA", "elementos_invasivos",  "DIARIA"),
    "MANEJO_OSTOMIAS":     ("MANEJO_OSTOMIAS", "ENFERMERIA", "manejo_ostomias",      "2X_SEMANA"),
    "CSV":                 ("CONTROL_SIGNOS",  "ENFERMERIA", None,                  "DIARIA"),
    "EDUCACION":           ("EDUCACION",       "ENFERMERIA", None,                  "SEMANAL"),
    "REQUERIMIENTO_O2":    ("OXIGENOTERAPIA",  "ENFERMERIA", "oxigenoterapia",       "SEMANAL"),
}

# Mapeo: professional_need_type → service_order adicional
PROFESSIONAL_TO_ORDER = {
    "KINESIOLOGIA":   ("SESION_KINE",  "KINESIOLOGIA",   None, "3X_SEMANA"),
    "FONOAUDIOLOGIA": ("SESION_FONO",  "FONOAUDIOLOGIA",  None, "2X_SEMANA"),
    "MEDICO":         ("VISITA_MEDICA","MEDICO",          None, "SEMANAL"),
    "TRABAJO_SOCIAL": ("EVAL_SOCIAL",  "TRABAJO_SOCIAL",  None, "QUINCENAL"),
}
```

### Dashboard logístico: extensión de streamlit_admin_app.py

```
Tab: "Agenda"        → Calendario semanal por profesional con visitas asignadas
Tab: "Rutas"         → Mapa con rutas diarias (pydeck ya está en el stack)
Tab: "Cumplimiento"  → KPIs por período: completadas, perdidas, a tiempo
Tab: "Cobertura"     → Heatmap de visitas por zona vs demanda
```

---

## Resumen: qué tomamos de cada plataforma

| Plataforma | Concepto tomado | Adaptación HODOM |
|---|---|---|
| **Uber** | Trip entity + statechart lifecycle | `visit` con 12 estados + `visit_event` log |
| **Uber** | Supply entity (waypoint queue) | `route` como cola ordenada de visitas |
| **Uber** | H3 hexagonal zoning | `zone` con 4 niveles territoriales |
| **Uber** | Geofence arrival detection | GPS radius check para estado LLEGADA |
| **Lyft** | Bipartite weighted matching | `score_match()` con 5 factores ponderados |
| **Lyft** | RL-based driver value function | Override por continuidad (valor futuro del vínculo prof-paciente) |
| **DoorDash** | 3-layer dispatch (generate→predict→optimize) | Filtro duro → scoring → asignación global |
| **DoorDash** | Delivery time decomposition | 7 segmentos temporales medibles |
| **DoorDash** | SLO framework (14K métricas) | 9 KPIs operacionales enfocados |
| **Instacart** | Batch status lifecycle (31 webhooks) | `visit_event` como event stream |
| **Instacart** | Service option time slots | `provider_schedule` con slots por turno |
| **AlayaCare** | Visit entity (start_at, end_at, cancelled) | Estructura de `visit` con EVV |
| **FHIR** | Appointment → Encounter workflow | PROGRAMADA → EN_ATENCION → DOCUMENTADA |
| **EVV** | 6 data elements (Cures Act) | GPS + timestamp en clock-in/clock-out |
