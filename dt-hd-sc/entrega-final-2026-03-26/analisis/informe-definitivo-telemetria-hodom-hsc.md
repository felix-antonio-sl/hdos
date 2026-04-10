# Informe Definitivo — Análisis Operacional de Rutas HODOM HSC
## Telemetría GPS × Programación × Atenciones | Enero – Marzo 2026

**Hospital de San Carlos — Servicio de Salud Ñuble**

---

## 1. Resumen Ejecutivo

Se cruzaron **3 fuentes de datos independientes** para construir el análisis operacional más completo posible de la unidad HODOM HSC:

| Fuente | Registros | Período |
|---|---|---|
| Telemetría GPS (3 vehículos) | 7.586 eventos | 01/01 – 24/03/2026 |
| Planillas de ruta programada | 1.573 visitas en 81 hojas | Ene – Mar 2026 |
| Consolidado de atenciones profesionales | 2.029 atenciones | 83 días |

### Hallazgos principales

| Indicador | Valor |
|---|---|
| **Match programación ↔ GPS** | **87.0%** (1.369/1.573 visitas) |
| Match del análisis previo (colega) | 35.9% (564/1.573) |
| **Mejora en match** | **+805 visitas (+51 pp)** |
| Jornada formal HODOM | **08:00 – 20:00 (12 horas)** |
| Ventana operativa real (GPS) | **~08:30 – 17:30 (9 horas)** |
| **Jornada no operada** | **~2.5 h/día (17:30→20:00 + arranque tardío)** |
| % de jornada productivo (move+terreno) | **39.2%** sobre 12h |
| **Capacidad ociosa** | **60.8%** de la jornada formal (438 min/día/móvil) |
| Tiempo en base durante jornada | 182 min/día (25.2% de 12h) |
| Valle operacional 12:00-14:00 | Productividad cae al **23%** |
| Visitas/día promedio (GPS) | **8.1** por móvil |
| Km/día promedio | **73.2 km** |
| Velocidad máxima detectada | **130 kph** en ruta rural |
| **Capacidad ociosa flota (trimestre)** | **1.818 horas** |
| Capacidad recuperable estimada | **+8-12 visitas/día** sin recursos adicionales |

---

## 2. Metodología de Match

### 2.1 Evolución del algoritmo

| Versión | Estrategia | Visitas matched | % |
|---|---|---|---|
| Colega (baseline) | Match por bloque asignado, radio 1.5km, ventana 150min | 564 | 35.9% |
| v2 | Cross-device (buscar en 3 vehículos, no solo el asignado) | 963 | 62.5% |
| v3 | Multi-pass (4 pasadas con umbrales progresivos) | 1.278 | 82.9% |
| v4 | Consolidación por domicilio (mismo paciente = 1 parada) | 1.356 | 88.0% |
| v5 | Geo-learning (coordenadas aprendidas de otros días) | 1.369 | 88.8% |
| **v7 (definitivo)** | **CSV canónico + all stops + domicilios + geo-learning** | **1.369** | **87.0%** |

### 2.2 Claves de la mejora

1. **Cross-device**: los conductores rotan vehículos. Ningún líder usa el mismo vehículo >71% del tiempo
2. **Consolidación por domicilio**: 323 domicilios reciben >1 visita/día (KTM + enfermería + fono). El móvil para UNA vez
3. **Geo-learning**: si un paciente matcheó bien 7/10 días, uso esas coordenadas GPS reales para los 3 días que fallaron
4. **Umbrales rurales extendidos**: para geocoding de calidad "media" o "baja", amplié el radio a 2.5km

### 2.3 Distribución de confianza del match

| Nivel | Criterio | Domicilios | % |
|---|---|---|---|
| Alta | <200m del domicilio geocodificado | 243 | 21.9% |
| Media | 200-600m | 294 | 26.5% |
| Baja | 600-2500m | 284 | 25.6% |
| Tentativa | <5km, mejor candidato disponible | 142 | 12.8% |
| Geo-learned | Coordenadas aprendidas de otros días | 12 | 1.1% |
| Sin match | Sin parada GPS compatible | 136 | 12.2% |

### 2.4 Validación con consolidado de atenciones

En la mediana, los matches GPS capturan el **67% de las atenciones** reportadas en el consolidado. En los mejores días llega al 100%. El ratio <100% es coherente: el consolidado cuenta *atenciones profesionales* (varias por visita) y las planillas cuentan *visitas domiciliarias*.

---

## 3. Perfil de la Flota

### 3.1 Métricas globales por vehículo

| Indicador | PFFF57 (Alvial) | RGHB14 (Navara) | SUV TZXS94 | Flota |
|---|---|---|---|---|
| **Límite km/día** | **100 km** | **100 km** | **80 km** | — |
| **Disponibilidad** | **Lun-Dom** | **Lun-Dom** | **Lun-Vie** | — |
| Días operativos | 83 | 83 | 58 | — |
| Km/día real | 73.9 | 81.2 | 63.2 | **73.2** |
| **% uso límite km** | **73.9%** | **81.2%** | **79.0%** | — |
| **Margen km/día** | **26.1 km** | **18.8 km** | **16.8 km** | — |
| Visitas/día (GPS) | 9.3 | 8.8 | 5.6 | **8.1** |
| Km/visita (P50) | 7.9 | 9.0 | 11.1 | — |
| Min traslado/visita (P50) | 12.1 | 14.4 | 20.6 | — |
| Ratio productivo (P50) | 40.8% | 37.0% | 31.5% | — |
| Retornos a base/día | 3.8 | 3.8 | 3.8 | **3.8** |
| % tiempo en base | 36.0% | 38.3% | 42.0% | **38.3%** |
| Max distancia promedio | 16.6 km | 16.3 km | 15.5 km | **16.2** |

### 3.1.1 Restricciones operativas de flota

- **SUV TZXS94 no opera fines de semana.** La flota cae de 3 a 2 móviles sábado-domingo, reduciendo la capacidad territorial en ~29%.
- **Los vehículos ya usan 74-81% de su límite kilométrico.** El margen para agregar visitas rurales lejanas es limitado (~2-3 visitas extra/día por km). La capacidad adicional viene principalmente del **tiempo** (horas no operadas), no de los km.
- **Fin de semana:** con solo 2 móviles (200 km/día de techo), las rutas rurales lejanas deben priorizarse cuidadosamente. Considerar agrupar todas las visitas lejanas en los 5 días con 3 móviles.

### 3.2 Distribución del tiempo (sobre jornada formal 08:00-20:00 = 12h)

```
                 En Base    En Terreno    Movimiento    Jornada no operada
PFFF57 (Alvial)  ██████     ███████       ████          █████████████
                  23.8%       25.7%        15.6%          35.0%

RGHB14 (Navara)  ███████    ██████        ████          ██████████
                  27.1%       25.0%        17.6%          30.3%

SUV TZXS94       ██████     █████         ████          ████████████████
                  24.9%       18.6%        15.0%          41.5%
```

**Sobre la jornada formal de 12 horas:**
- Solo el **39.2%** se usa productivamente (movimiento + atención en terreno)
- El **25.2%** se pasa en base (coordinación, registros, almuerzo, esperas)
- El **35.6%** de la jornada formal simplemente NO SE OPERA (antes de las 08:30 y después de las 17:30)
- **1.818 horas de capacidad vehicular ociosa en el trimestre** (3 móviles × 83 días)

### 3.3 Perfil horario (jornada formal 08:00-20:00)

| Franja | Productividad | Observación |
|---|---|---|
| 08:00–09:00 | **76%** | Salida a terreno, pero arranque tardío (~08:30) |
| 09:00–12:00 | **69-73%** | Bloque AM activo — mejor rendimiento del día |
| **12:00–13:00** | **45%** | Retorno masivo a base |
| **13:00–14:00** | **23%** | Almuerzo — mínima actividad |
| 14:00–16:00 | **65-73%** | Bloque PM activo |
| 16:00–17:30 | **64-67%** | Cierre operativo |
| **17:30–20:00** | **~0%** | ⚠️ **Jornada formal pero sin operación de ruta** |

> **Hallazgo crítico:** La jornada HODOM es de 08:00 a 20:00 (12h), pero la operación real de móviles se concentra entre 08:30 y 17:30 (~9h). Las **2.5 horas finales** de jornada (17:30-20:00) no generan visitas domiciliarias detectables en GPS. Esto representa **~150 min/día × 3 móviles = 7.5 horas/día de jornada formal sin ruta.**

---

## 4. Cumplimiento de Programación

### 4.1 Por líder de bloque

| Líder | Domicilios matched | Total | % | Vehículo principal |
|---|---|---|---|---|
| ANDRÉS/ANDRES | 227/266 | **85.3%** | PFFF57 (64-71%) |
| SERVANDO | 269/359 | **74.9%** | RGHB14 (63%) |
| CRISTOPHER | 199/318 | **62.6%** | SUV (57%) |
| HUGO | 172/307 | **56.0%** | RGHB14 (57%) |
| JOSE | 125/203 | **61.6%** | PFFF57 (62%) |

### 4.2 Brechas de cumplimiento (días con menor match)

| Fecha | Match | Visitas sin match | Observación |
|---|---|---|---|
| 2026-03-02 | 25.5% | 35 | Día con hojas duplicadas en planilla |
| 2026-01-19 | 26.7% | 11 | Bloque sin asignación GPS |
| 2026-01-21 | 29.4% | 12 | 3 direcciones sin geocodificación |
| 2026-02-23 | 39.0% | 36 | Día con 3 hojas superpuestas |
| 2026-02-09 | 40.0% | 39 | Día con 3 hojas duplicadas |

### 4.3 Días sin planilla pero con atenciones

**11 días** tienen atenciones registradas en el consolidado pero **sin planilla programada** → 267 atenciones no comparables.

---

## 5. Análisis Territorial

### 5.1 Distribución geográfica

| Zona | Rango | Visitas | % | Horas asistenciales |
|---|---|---|---|---|
| Urbana | <3 km | 1.062 | **58%** | 329h |
| Periurbana | 3-10 km | 298 | **16%** | 131h |
| Rural cercana | 10-18 km | 341 | **19%** | 129h |
| Rural lejana | >18 km | 124 | **7%** | 45h |

### 5.2 Cuellos de botella por localidad (del análisis del colega)

| Localidad | Desviación media | Visitas |
|---|---|---|
| Cachapoal | 1.137 m | 10 |
| San Carlos urbano | 604 m | 504 |
| Ñiquén | 474 m | 28 |
| San Nicolás | 402 m | 8 |
| San Gregorio | 143 m | 14 |

### 5.3 Macro-circuitos propuestos

- **Circuito A (Urbano):** <3 km, ~58% de visitas → 1 móvil dedicado
- **Circuito B (Oriente-Sur):** Cape, Arboledas, sector rural (~8-12 km)
- **Circuito C (Norte-NW):** San Gregorio, Cachapoal, Ñiquén, >15 km

---

## 6. Hallazgos Operacionales

### 6.1 Duración de visitas

| Visitas en domicilio | Parada GPS mediana | n |
|---|---|---|
| 1 visita | 16 min | 672 |
| 2 visitas (multi-profesional) | 17 min | 224 |
| 3+ visitas | 19 min | 45 |

**Interpretación:** Las prestaciones adicionales agregan poco tiempo marginal → equipos bien coordinados en terreno.

### 6.2 Micro-paradas

~1.083 micro-paradas (<3 min fuera de base) en el trimestre. Patrón: semáforos, búsqueda de dirección, GPS bounce. Impacto bajo (~7.5 min/día perdidos).

### 6.3 Paradas extra no asistenciales

**892 paradas >10 min** no asociadas a visita ni base (promedio 10.7/día). Posibles causas: carga de combustible, compras de insumos, esperas por coordinación, visitas no programadas.

### 6.4 Seguridad vial

Trayectos frecuentes con velocidad máxima >100 kph en rutas rurales (Cape, San Gregorio, sectores >10 km). **Riesgo: personal de salud y equipamiento a >100 kph en caminos rurales.**

---

## 7. Recomendaciones Priorizadas

### 🔴 Prioridad 1: Activar la jornada 17:30-20:00

| Acción | Impacto estimado |
|---|---|
| **Programar bloque PM tardío (17:30-19:30)** | **+120 min/día × 3 móviles = +6h/día** |
| Asignar visitas urbanas cortas al bloque tardío | +4-6 visitas/día adicionales |
| Turno partido o relevo PM si el equipo lo requiere | Cobertura real de la jornada formal |

> Este es el hallazgo de mayor impacto: **2.5 horas/día de jornada formal sin uso** equivalen a casi un móvil completo de capacidad perdida.

### 🔴 Prioridad 2: Reducir tiempo en base

| Acción | Impacto estimado |
|---|---|
| Almuerzo escalonado (turnos 12:00/13:00) | +80 min/día de flota activa |
| Hora de salida protocolizada ≤08:00 | +30 min/día |
| Registros clínicos en terreno (tablet) | -30-60 min/día en base |
| Coordinación matinal ≤15 min | Reducir tiempo pre-salida |

### 🟡 Prioridad 3: Asignación territorial

| Acción | Impacto estimado |
|---|---|
| Asignar macro-zona por móvil/día | -15% km redundantes |
| Agrupar visitas rurales lejanas en 1 bloque | Menos ida-vuelta larga |
| Llave explícita vehículo/bloque en planilla | Eliminar ambigüedades de asignación |

### 🟡 Prioridad 4: Estandarización de datos

| Acción | Impacto |
|---|---|
| Normalizar direcciones antes de programar | Mejor geocoding y seguimiento |
| Identificador único de episodio | Trazabilidad paciente-visita-GPS |
| Digitalización de planilla en formato tabular único | Automatización de análisis |

### 🟢 Prioridad 5: Monitoreo continuo

| KPI | Meta | Actual | Periodicidad |
|---|---|---|---|
| Visitas/día/móvil | ≥9 | 8.1 | Semanal |
| % tiempo en terreno | ≥45% | 36.9% | Mensual |
| Tiempo en base diurno | ≤120 min | 182 min | Semanal |
| Km/visita | ≤8 | 10.6 | Mensual |
| Vel. máx >100 kph | 0 eventos | Frecuente | Mensual |
| Hora primer movimiento | ≤08:15 | 08:30 | Diario |
| Match programación/GPS | ≥90% | 87% | Mensual |

### 🟢 Prioridad 6: Seguridad vial

- Velocidad máxima operacional: **80 kph**
- Alerta telemática automática por exceso
- Evaluar si las altas velocidades reflejan presión de tiempo

---

## 8. Impacto Proyectado

| Mejora | Capacidad recuperable | Visitas extra/día | Restricción km |
|---|---|---|---|
| **Activar bloque 17:30-19:30** | **+120 min/día × 3 móviles** | **+6-8** | Solo urbanas (<3km), no consume km significativo |
| Almuerzo escalonado | +80 min/día | +3 | Neutro |
| Reducir base a 120 min/día | +62 min/día | +3 | Neutro |
| Salida a las 08:00 | +30 min/día | +1 | Neutro |
| Asignación territorial | -15% km redundantes | +1-2 | **Libera km** para más visitas rurales |
| **Total L-V (3 móviles)** | **~320 min/día** | **+12-16** | Dentro del techo 280 km/día |
| **Total S-D (2 móviles)** | **~210 min/día** | **+8-10** | Dentro del techo 200 km/día |

> **Sobre la jornada formal de 12h, la flota opera al 39% de su capacidad.** La holgura principal es de **tiempo** (horas no operadas y tiempo en base), no de km. Las visitas adicionales del bloque PM tardío deben ser **urbanas** (<3 km) para no estresar el límite kilométrico. Con estas medidas, la flota podría pasar de ~24 a ~36-40 visitas/día en semana (+50-67%) sin vehículos ni personal adicional.

> **Restricción de fin de semana:** sin el SUV, la capacidad cae a 2 móviles y 200 km/día. Las visitas rurales lejanas (>18 km) deben concentrarse de lunes a viernes cuando hay 3 móviles y 280 km/día de techo.

---

## 9. Visitas sin Match: Diagnóstico Final

Las **204 visitas** (13%) que no matchean se explican por:

| Causa | Visitas |
|---|---|
| 11 días sin planilla programada pero con atenciones | ~80-100 (estimado) |
| 3 direcciones sin geocodificación (Puelma 657, Casares 2, Vista Cordillera) | ~40 |
| Visitas canceladas o cambios de última hora | ~30-40 |
| Pacientes que nunca matchean (posible vehículo sin GPS) | ~30 |

---

## 10. Notas Metodológicas

- **Match definitivo:** algoritmo multi-pass (4 pasadas espaciales + 1 geo-learning) con consolidación por domicilio, cross-device y coordenadas aprendidas
- **Base hospitalaria:** -36.430, -71.960 (inferida por frecuencia y patrón nocturno)
- **Umbral de visita:** parada ≥45s fuera de base
- **Los análisis son de gestión operativa** y no reemplazan el juicio directivo ni clínico
- Pacientes anonimizados (PAC-XXX) en los datos de detalle

---

## 11. Fuentes y Créditos

| Componente | Fuente |
|---|---|
| Telemetría GPS | `drives_stops_report_2026-01-01_to_2026-03-25.csv` |
| Planillas programadas | `ENERO_2026.xlsx`, `FEBRERO_2026.xlsx`, `MARZO_2026.xlsx` |
| Consolidado atenciones | `Consolidado_atenciones_diarias.xlsx` |
| Geocodificación | Nominatim + ArcGIS (trabajo del colega) |
| Parseo de planillas | 7 CSVs canónicos (trabajo del colega) |
| Algoritmo de match y análisis profundo | kora/salubrista-hah |
| Datos crudos estructurados | Análisis colaborativo colega + salubrista-hah |

---

*Informe basado en 7.586 eventos GPS | 1.573 visitas programadas | 2.029 atenciones profesionales | 3 vehículos | 83 días operativos | Ene-Mar 2026*
*Copiloto HODOM HSC — kora/salubrista-hah — 2026-03-25*
