# Modelo de Dominio — Sistema HODOM HSC
## Hospital de San Carlos — Servicio de Salud Ñuble

**Fuente:** Evidencia operacional real (telemetría GPS, planillas, consolidado, legacy) + normativa HD vigente (DS 1/2022, NT 2024).

---

## 1. Entidades del Dominio

### 1.1 Mapa de entidades

```
┌─────────────┐     ┌──────────────┐     ┌─────────────────┐
│  PACIENTE    │────▸│  EPISODIO    │────▸│ VISITA          │
│             │  1:N │  HODOM       │  1:N│ DOMICILIARIA    │
└─────────────┘     └──────────────┘     └────────┬────────┘
       │                    │                      │
       │                    │                 N:1  │
       ▼                    ▼                      ▼
┌─────────────┐     ┌──────────────┐     ┌─────────────────┐
│  DOMICILIO   │     │ PLAN DE      │     │ ATENCIÓN        │
│             │     │ CUIDADOS     │     │ PROFESIONAL     │
└─────────────┘     └──────────────┘     └────────┬────────┘
                                                   │
                           ┌───────────────────────┤
                           │                       │
                           ▼                       ▼
                    ┌──────────────┐     ┌─────────────────┐
                    │ PROFESIONAL  │     │ PRESTACIÓN      │
                    │             │     │ (tipo visita)   │
                    └──────────────┘     └─────────────────┘

┌─────────────┐     ┌──────────────┐     ┌─────────────────┐
│  VEHÍCULO    │────▸│ BLOQUE DE    │────▸│ EVENTO GPS      │
│  (MÓVIL)    │  1:N│ RUTA         │  1:N│ (parada/mov)   │
└─────────────┘     └──────────────┘     └─────────────────┘
       │                    │
       │                    │
       ▼                    ▼
┌─────────────┐     ┌──────────────┐
│ CONDUCTOR    │     │ PROGRAMACIÓN │
│             │     │ DIARIA       │
└─────────────┘     └──────────────┘
```

---

### 1.2 PACIENTE

El sujeto del cuidado domiciliario.

| Atributo | Tipo | Fuente | Ejemplo |
|---|---|---|---|
| paciente_id | PK, string | Sistema (hoy PAC-XXX) | PAC-087 |
| rut | string, unique | Registro civil | 12.345.678-9 |
| nombre_completo | string | Planilla | LUIS PINCHEIRA ARIAS |
| fecha_nacimiento | date | Ficha | 1954-03-12 |
| sexo | enum(M,F,X) | Ficha | M |
| prevision | enum | Ficha | FONASA A |
| telefono_contacto | string | Planilla | 965044833 |
| telefono_cuidador | string | Planilla | — |
| domicilio_id | FK → DOMICILIO | Planilla/GPS | DOM-0042 |
| activo | bool | Estado actual | true |

**Hallazgo de datos reales:** Los pacientes se identifican hoy por nombre en las planillas. No hay RUT ni ID único en la operación diaria. El sistema necesita **normalización de identidad**.

---

### 1.3 DOMICILIO

Ubicación física donde se realiza la atención. Un paciente tiene un domicilio; un domicilio puede tener >1 paciente (ELEAM, hogares).

| Atributo | Tipo | Fuente | Ejemplo |
|---|---|---|---|
| domicilio_id | PK | Sistema | DOM-0042 |
| direccion_texto | string | Planilla | AGUA BUENA S/N X CAPE, SAN CARLOS |
| direccion_normalizada | string | Geocoder | AGUA BUENA SN X CAPE, SAN CARLOS |
| comuna | string | Geocoder/manual | San Carlos |
| localidad | string | Manual | Agua Buena |
| lat | decimal(8,6) | Geocoder/GPS aprendido | -36.414000 |
| lon | decimal(9,6) | Geocoder/GPS aprendido | -71.919000 |
| geocode_quality | enum(alta,media,baja,sin_match) | Geocoder | media |
| gps_lat_aprendido | decimal(8,6) | Centroide de paradas GPS | -36.413800 |
| gps_lon_aprendido | decimal(9,6) | Centroide de paradas GPS | -71.918500 |
| gps_observaciones | int | # de paradas GPS en este domicilio | 12 |
| macro_zona | enum(urbano,periurbano,rural_cerca,rural_lejos) | Calculado | rural_cerca |
| distancia_base_km | decimal(4,1) | Calculado | 8.4 |
| referencia_acceso | text | Operativo | "x Cape, camino de tierra 500m" |
| evaluacion_domicilio | FK → EVAL_DOMICILIO | NT 2024 art.X | — |

**Hallazgo operacional:** Las direcciones rurales tipo "Agua Buena S/N x Cape" son difíciles de geocodificar. El sistema debe almacenar **coordenadas GPS aprendidas** (centroide de paradas reales) como fuente más precisa que el geocoder.

**Hallazgo normativo:** La NT 2024 exige evaluación formal del domicilio. El modelo lo vincula pero hoy no se registra digitalmente.

---

### 1.4 EPISODIO HODOM

Un período continuo de hospitalización domiciliaria para un paciente. Desde el ingreso hasta el egreso.

| Atributo | Tipo | Fuente | Ejemplo |
|---|---|---|---|
| episodio_id | PK | Sistema | EP-2026-0142 |
| paciente_id | FK → PACIENTE | Sistema | PAC-087 |
| domicilio_id | FK → DOMICILIO | Ingreso | DOM-0042 |
| fecha_ingreso | date | VM ingreso | 2026-01-04 |
| fecha_egreso | date | VM egreso | 2026-02-15 |
| origen_derivacion | enum | Planilla legacy | Medicina |
| diagnostico_principal | string | Epicrisis | ITU complicada |
| diagnostico_cie10 | string | Codificación | N39.0 |
| motivo_egreso | enum(alta,traslado,fallecimiento,abandono) | VM egreso | alta |
| estadia_dias | int, calc | egreso - ingreso | 42 |
| medico_tratante | FK → PROFESIONAL | Asignación | — |
| estado | enum(activo,egresado,suspendido) | Operativo | activo |
| consentimiento_firmado | bool | NT 2024 | true |
| evaluacion_social | bool | DS 1/2022 | true |

**Hallazgo legacy:** Los 1.795 registros del formulario 2025 no tenían identificador de episodio. Múltiples registros del mismo paciente no se podían vincular. **Este es el problema central que el sistema debe resolver.**

---

### 1.5 VISITA DOMICILIARIA

Una ida programada a un domicilio en un día específico. Puede incluir múltiples atenciones profesionales.

| Atributo | Tipo | Fuente | Ejemplo |
|---|---|---|---|
| visita_id | PK | Sistema | VIS-2026-01-31-B01-002 |
| episodio_id | FK → EPISODIO | Sistema | EP-2026-0142 |
| domicilio_id | FK → DOMICILIO | Hereda de episodio | DOM-0042 |
| fecha | date | Planilla | 2026-01-31 |
| hora_programada | time | Planilla | 08:00 |
| hora_real_inicio | time | GPS (stop start) | 08:36 |
| hora_real_fin | time | GPS (stop end) | 08:52 |
| bloque_id | FK → BLOQUE_RUTA | Planilla | BLQ-2026-01-31-B01 |
| vehiculo_id | FK → VEHICULO | GPS match | VEH-PFFF57 |
| estado | enum(programada,realizada,cancelada,reprogramada) | Operativo+GPS | realizada |
| match_gps_confianza | enum(alta,media,baja,tentativa,sin_match) | Algoritmo | alta |
| match_gps_distancia_m | decimal | Algoritmo | 142.3 |
| match_gps_stop_id | FK → EVENTO_GPS | Algoritmo | STOP-00287 |

**Hallazgo del match:** 87% de las visitas programadas tienen un match GPS. El 13% restante queda como `sin_match` — el sistema debe permitir registrar la visita manualmente incluso sin evidencia GPS.

**Hallazgo de domicilios:** Cuando un paciente recibe KTM + enfermería + fono el mismo día, el móvil para UNA vez. El modelo distingue **visita** (ida al domicilio) de **atención** (cada prestación profesional).

---

### 1.6 ATENCIÓN PROFESIONAL

Cada prestación realizada por un profesional en una visita. Múltiples atenciones pueden ocurrir en una sola visita (mismo domicilio, misma parada).

| Atributo | Tipo | Fuente | Ejemplo |
|---|---|---|---|
| atencion_id | PK | Sistema | ATN-2026-01-31-001 |
| visita_id | FK → VISITA | Sistema | VIS-2026-01-31-B01-002 |
| profesional_id | FK → PROFESIONAL | Planilla | PROF-BRAYAN |
| tipo_prestacion | FK → PRESTACION | Planilla | KTM |
| duracion_estimada_min | int | — | 20 |
| observaciones | text | Registro clínico | — |
| estado | enum(realizada,no_realizada,parcial) | Operativo | realizada |

**Hallazgo del consolidado:** 2.029 atenciones en 83 días (24.4/día). Las 1.573 visitas contienen ~1.39 atenciones promedio por visita. Los domicilios multi-visita (323 casos) son el patrón de KTM+enfermería+fono en el mismo paciente.

---

### 1.7 PRESTACIÓN (Catálogo)

Tipos de prestación que se realizan en terreno.

| Atributo | Tipo | Fuente | Ejemplo |
|---|---|---|---|
| prestacion_codigo | PK | Catálogo | KTM |
| prestacion_nombre | string | — | Kinesiterapia motora |
| profesion_requerida | enum | — | kinesiologo |
| duracion_tipica_min | int | — | 20 |
| requiere_insumos | bool | — | false |
| categoria | enum(rehabilitacion,tratamiento,evaluacion,procedimiento,administrativo) | — | rehabilitacion |

**Hallazgo de planillas:** Se detectaron **>120 variantes de tipo_visita** en las planillas (KTM, KTR, TTO EV, CA, CS, VM INGRESO, VM EGRESO, NTP, ING ENF, etc.). Muchas son combinaciones (KTM + FONO, ING ENF + TTO EV + VM INGRESO). **El sistema necesita un catálogo normalizado** donde cada prestación es atómica y una visita puede tener N prestaciones.

---

### 1.8 PROFESIONAL

Persona del equipo HODOM.

| Atributo | Tipo | Fuente | Ejemplo |
|---|---|---|---|
| profesional_id | PK | Sistema | PROF-BRAYAN |
| nombre | string | Planilla | BRAYAN |
| profesion | enum(medico,enfermera,kinesiologo,fonoaudiologo,tens,psicologo,nutricionista) | — | kinesiologo |
| rut | string | RRHH | — |
| activo | bool | — | true |

**Hallazgo de planillas:** Los profesionales aparecen solo por nombre de pila en las columnas (BRAYAN, LAURA, LUIS, PIA, M. JOSÉ, etc.). No hay apellido ni RUT en la planilla operativa.

---

### 1.9 VEHÍCULO (MÓVIL)

Recurso de transporte con GPS.

| Atributo | Tipo | Fuente | Ejemplo |
|---|---|---|---|
| vehiculo_id | PK | Sistema | VEH-PFFF57 |
| patente | string | GPS | PFFF57 |
| nombre_operativo | string | GPS | RICARDO ALVIAL |
| tipo | enum(ambulancia,suv,camioneta) | — | camioneta |
| km_limite_diario | int | Restricción operativa | 100 |
| disponibilidad | enum(lun_dom,lun_vie) | Restricción | lun_dom |
| gps_device_id | string | Plataforma GPS | PFFF57- RICARDO ALVIAL |
| activo | bool | — | true |

---

### 1.10 BLOQUE DE RUTA

Agrupación de visitas asignadas a un conductor/equipo en un día. Corresponde a una "columna" de la planilla diaria.

| Atributo | Tipo | Fuente | Ejemplo |
|---|---|---|---|
| bloque_id | PK | Sistema | BLQ-2026-01-31-B01 |
| fecha | date | Planilla | 2026-01-31 |
| secuencia | int | Planilla (orden columna) | 1 |
| lider | string | Planilla (cabecera) | ANDRES |
| vehiculo_asignado_id | FK → VEHICULO | Match GPS/manual | VEH-PFFF57 |
| confianza_asignacion | enum(asignado,reserva,ambiguo) | Algoritmo | asignado |
| medico | string | Planilla | — |
| enfermera | string | Planilla | — |
| kinesiologo | string | Planilla | BRAYAN |
| fonoaudiologo | string | Planilla | — |
| tens | string | Planilla | — |

**Hallazgo clave:** La asignación bloque→vehículo es ambigua en el 36% de los bloques (69 de 193). Los conductores rotan vehículos. **El sistema debe registrar explícitamente qué vehículo lleva cada bloque.**

---

### 1.11 EVENTO GPS

Registro telemétrico de un vehículo (parada o movimiento).

| Atributo | Tipo | Fuente | Ejemplo |
|---|---|---|---|
| evento_id | PK | GPS | GPS-00287 |
| stop_id | string, nullable | GPS | STOP-00287 |
| vehiculo_id | FK → VEHICULO | GPS | VEH-PFFF57 |
| fecha | date | GPS | 2026-01-09 |
| tipo | enum(detenido,movimiento) | GPS | detenido |
| inicio | datetime | GPS | 2026-01-09 08:33:31 |
| fin | datetime | GPS | 2026-01-09 09:21:00 |
| duracion_seg | int | GPS | 2849 |
| lat | decimal(8,6) | GPS | -36.434000 |
| lon | decimal(9,6) | GPS | -71.929000 |
| distancia_km | decimal(5,2) | GPS (movimiento) | — |
| vel_max_kph | int | GPS (movimiento) | — |
| vel_media_kph | int | GPS (movimiento) | — |
| es_base | bool | Algoritmo | false |
| es_candidato_visita | bool | Algoritmo | true |
| visita_matcheada_id | FK → VISITA, nullable | Algoritmo | VIS-2026-01-09-B01-002 |

---

### 1.12 PROGRAMACIÓN DIARIA

Vista consolidada de la operación de un día completo.

| Atributo | Tipo | Fuente | Ejemplo |
|---|---|---|---|
| programacion_id | PK | Sistema | PROG-2026-01-31 |
| fecha | date | — | 2026-01-31 |
| n_bloques | int | Planilla | 2 |
| n_visitas_programadas | int | Planilla | 17 |
| n_domicilios | int | Calculado | 12 |
| n_atenciones_consolidado | int | Consolidado | 23 |
| n_vehiculos_operativos | int | GPS | 3 |
| km_totales_flota | decimal | GPS | 159.5 |
| match_pct | decimal | Algoritmo | 85.0 |

---

## 2. Relaciones Clave

| Relación | Cardinalidad | Nota |
|---|---|---|
| PACIENTE → EPISODIO | 1:N | Un paciente puede tener múltiples episodios (reingreso) |
| PACIENTE → DOMICILIO | N:1 | Muchos pacientes pueden vivir en un mismo domicilio (ELEAM) |
| EPISODIO → VISITA | 1:N | Un episodio genera múltiples visitas |
| VISITA → ATENCIÓN | 1:N | Una visita puede tener múltiples atenciones (KTM+ENF+FONO) |
| VISITA → BLOQUE_RUTA | N:1 | Varias visitas pertenecen a un bloque |
| BLOQUE_RUTA → VEHICULO | N:1 | Un bloque usa un vehículo |
| BLOQUE_RUTA → PROGRAMACIÓN | N:1 | Varios bloques en una programación diaria |
| EVENTO_GPS → VEHICULO | N:1 | Muchos eventos por vehículo |
| VISITA ↔ EVENTO_GPS | 1:1 (match) | Una visita matchea con una parada GPS |
| DOMICILIO ↔ EVENTO_GPS | 1:N (aprendido) | Un domicilio acumula paradas GPS para mejorar geocoding |

---

## 3. Reglas de Negocio del Dominio

### Derivadas de normativa
1. Todo episodio requiere **consentimiento informado** firmado (DS 1/2022)
2. Todo episodio requiere **evaluación del domicilio** antes del ingreso (NT 2024)
3. La **estadía máxima informada** es 6-8 días según consentimiento actual (tensión: estadía real promedio es mayor)
4. La **visita médica de ingreso** y **egreso** son obligatorias (DS 1/2022 art. 5-6)
5. El **Director Técnico** debe supervisar el plan de cuidados (DS 1/2022 art. 7-10)

### Derivadas de operación real
6. Un domicilio/día = 1 parada GPS, independiente del número de atenciones
7. Los conductores rotan vehículos → la asignación bloque-vehículo debe ser explícita
8. Un paciente puede tener hasta 6 atenciones/día (KTM + KTR + FONO + ENF + VM + NTP)
9. Las visitas rurales lejanas (>18 km) consumen ~30-50 min de traslado ida
10. El horario formal es 08:00-20:00 pero la operación real es 08:30-17:30
11. Límite km: SUV 80 km/día (L-V), otros 100 km/día (L-D)
12. NTP (nutrición parenteral) se hace en terreno, en un domicilio recurrente

### Derivadas del match GPS
13. Match confianza ≥ media (<600m) se considera **visita confirmada**
14. Match tentativa (600m-5km) se considera **probable** — requiere validación manual
15. Sin match puede ser: visita cancelada, vehículo sin GPS, o error de geocoding
16. Las coordenadas GPS aprendidas (centroide) son más precisas que el geocoder para direcciones rurales

---

## 4. Agregados (DDD)

### Agregado 1: EPISODIO
- Root: Episodio
- Incluye: Visitas, Atenciones, Plan de Cuidados
- Invariante: episodio activo tiene ≥1 visita/semana

### Agregado 2: PROGRAMACIÓN DIARIA
- Root: Programación
- Incluye: Bloques, asignación de Vehículos, Visitas del día
- Invariante: cada bloque tiene exactamente 1 vehículo asignado

### Agregado 3: TELEMETRÍA
- Root: Evento GPS
- Incluye: Paradas, Movimientos, Match con Visitas
- Invariante: una parada solo puede matchear con 1 visita (pero 1 visita/domicilio puede cubrir N atenciones)

---

## 5. Brechas del Modelo Actual vs Propuesto

| Dimensión | Hoy (planillas Excel) | Propuesto |
|---|---|---|
| Identidad paciente | Nombre de pila en planilla | RUT + ID único de episodio |
| Domicilio | Texto libre, geocoding externo | Coordenadas GPS aprendidas + normalizadas |
| Visita vs Atención | Mezclados (1 fila = 1 atención) | Separados: 1 visita = N atenciones |
| Asignación vehículo | Implícita por conductor | Explícita: bloque → vehículo |
| Prestaciones | >120 variantes texto libre | Catálogo normalizado, combinaciones como N:N |
| Cumplimiento | No se mide | Match automático GPS ↔ programación |
| Horario real | No visible | GPS timestamp de inicio/fin de visita |
| Continuidad | No trazable (sin ID episodio) | Episodio como eje longitudinal |

---

*Modelo de dominio construido a partir de evidencia operacional real (7.586 eventos GPS, 1.573 visitas, 2.029 atenciones) y normativa HD vigente.*
*kora/salubrista-hah — 2026-03-25*
