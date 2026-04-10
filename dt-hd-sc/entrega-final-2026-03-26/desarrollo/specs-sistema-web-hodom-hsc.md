# Especificaciones del Sistema Web HODOM HSC
## Sistema Operativo de la Unidad de Hospitalización Domiciliaria
### Hospital de San Carlos — Servicio de Salud Ñuble
### Versión 1.0 — Marzo 2026

---

## 1. Visión del producto

Un sistema web que funcione como **sistema operativo completo** de la Unidad HODOM: desde la captación del paciente hasta el alta y la contrarreferencia a APS, integrando todas las necesidades de los 12 grupos de actores identificados en 96 historias de usuario.

**No es un sistema clínico que reemplaza la ficha clínica hospitalaria.** Es una capa de gestión operativa y coordinación que se integra con los sistemas existentes del HSC (SIDRA, sistema de laboratorio, farmacia) y extiende la capacidad de gestión al domicilio.

---

## 2. Usuarios del sistema y roles

| Rol | Permisos | N° usuarios estimados |
|-----|----------|----------------------|
| `admin` | Configuración, usuarios, parámetros, auditoría | 1-2 |
| `medico_hodom` | Ingresos, indicaciones, evolución, alta, reportes | 2 |
| `enfermera_coord` | Gestión cupos, rutas, insumos, informes, coordinación red | 1 |
| `enfermero_op` | Evolución enfermería, procedimientos, educación, signos vitales | 4 |
| `tens` | Signos vitales, medicación oral, registro actividades | 2 |
| `kinesiologo` | Plan kinésico, evolución, procedimientos respiratorios/motores | 3 |
| `fonoaudiologo` | Plan fonoaudiológico, evolución, educación deglutoria | 1 |
| `trabajadora_social` | Evaluación sociosanitaria, consentimiento, gestión redes | 1 |
| `conductor` | Ruta asignada, registro km, estado móvil | 5 |
| `administrativo` | Registro sistema, estadísticas, informes | 1 |
| `medico_referente` | Solicitud ingreso, consulta estado paciente derivado | ~30 (UEA, Med, Cir, Traum) |
| `direccion` | Dashboard, KPIs, informes consolidados (solo lectura) | 3-5 |
| `ugp` | Cupos disponibles, liberación camas, indicadores (solo lectura) | 2-3 |
| `farmacia` | Recepción recetas HODOM, despacho, stock | 2-3 |
| `laboratorio` | Recepción muestras, resultados | 2-3 |
| `calidad_ocsp` | Auditoría, eventos adversos, reportes | 1-2 |
| `aps_cesfam` | Contrarreferencia, seguimiento post-alta (solo lectura + acuse) | 10-20 |

---

## 3. Módulos del sistema

### 3.1 MÓDULO DE CAPTACIÓN Y SCREENING

**HU cubiertas:** HU-P01, HU-P03, HU-MT01, HU-MT02, HU-MT03, HU-TS02

**Funcionalidad:**

| Feature | Descripción | Actor principal |
|---------|-------------|-----------------|
| Screening automatizado | Lista diaria de pacientes hospitalizados que cumplen criterios iniciales (diagnóstico compatible + categorización D1-D3/C2-C3 + ≥18 años + comuna elegible) extraída del sistema hospitalario | Sistema (automático) |
| Alerta de elegibilidad | Notificación push al médico referente cuando un paciente de su servicio cumple criterios | medico_referente |
| Formulario de solicitud (F1) | Formulario digital estandarizado con campos: diagnóstico, categorización, estabilidad clínica, indicaciones actuales, interconsultas pendientes | medico_referente |
| Bandeja de solicitudes | Cola de solicitudes entrantes con priorización (UEA >12h espera = prioridad alta) | medico_hodom |
| Evaluación clínica HODOM | Checklist digital de criterios de inclusión/exclusión con resolución (aceptado/rechazado + motivo) | medico_hodom |
| Evaluación sociosanitaria | Formulario digital: vivienda (servicios básicos, accesibilidad, higiene, mascotas), cuidador (disponibilidad, alfabetización, motivación), red de apoyo, distancia/tiempo al HSC | trabajadora_social |
| Verificación de cupo | Consulta en tiempo real de cupos HODOM disponibles (de 25) | enfermera_coord |

**Reglas de negocio:**
- No se puede aceptar paciente si cupos = 0
- No se puede aceptar paciente sin evaluación sociosanitaria aprobada
- No se puede aceptar paciente sin consentimiento informado firmado
- Tiempo máximo desde solicitud hasta resolución: 4 horas
- Paciente en UEA >12h → flag de prioridad automática
- Motivo de rechazo es obligatorio y se notifica al médico referente

---

### 3.2 MÓDULO DE INGRESO

**HU cubiertas:** HU-P02, HU-P04, HU-C01, HU-C04, HU-TS01, HU-TS04, HU-A01, HU-FA01

**Funcionalidad:**

| Feature | Descripción |
|---------|-------------|
| Consentimiento informado digital | Generación automática con datos del paciente, diagnóstico, plan. Firma digital o escaneada del paciente + cuidador. Almacenamiento con timestamp |
| Ficha de ingreso HODOM | Datos demográficos, diagnóstico, categorización (básico/medio/complejo-medio), comorbilidades, medicamentos actuales, alergias, dispositivos invasivos |
| Plan de tratamiento inicial | Indicaciones médicas digitales: medicamentos (vía, dosis, frecuencia), exámenes, imágenes, interconsultas, dieta, actividad, oxigenoterapia |
| Asignación de equipo | Asignación automática de enfermero(s), kinesiólogo, fonoaudiólogo según ruta y carga. El sistema sugiere asignación óptima |
| Despacho de farmacia | Generación automática de receta digital → notificación a farmacia → confirmación de despacho → registro de entrega |
| Preparación de maletín | Checklist de equipamiento e insumos por paciente según diagnóstico y plan |
| Orden de traslado | Asignación de móvil y conductor, hora estimada, dirección con coordenadas GPS |
| Activación en sistema | Cambio de estado: `solicitado` → `evaluado` → `aceptado` → `ingresado` → `en_domicilio` |
| Notificación a APS | Correo automático al CESFAM de origen informando ingreso a HODOM |
| Notificación a UGP | Alerta de cama liberada en servicio de origen |

---

### 3.3 MÓDULO DE ATENCIÓN DOMICILIARIA (núcleo operativo)

**HU cubiertas:** HU-P06 a HU-P12, HU-C02, HU-C03, HU-C05, HU-C06, HU-C08, HU-EO01 a HU-EO04, HU-T01, HU-T02, HU-K01 a HU-K03, HU-F01, HU-F02, HU-M03 a HU-M06

#### 3.3.1 Registro clínico diario

| Estamento | Campos de registro |
|-----------|-------------------|
| **Enfermería** | Signos vitales (PA, FC, FR, T°, SpO2, dolor EVA, Glasgow), procedimientos realizados (VVP, SNG, sonda urinaria, curación, administración EV/SC/IM, toma de muestras), plan de cuidados, evaluación de intervenciones, educación entregada |
| **Médico** | Evolución médica, ajuste de indicaciones, solicitud exámenes/imágenes/IC, recetas, certificados, licencias médicas, decisión de escalamiento o alta |
| **Kinesiología** | Evaluación funcional (TUG, Barthel, fuerza muscular), plan kinésico, procedimientos (KTR, KTM, aspiración, nebulización, O2), evolución, educación |
| **Fonoaudiología** | Evaluación deglutoria (FOIS, consistencias), evaluación habla/lenguaje/voz/cognición, plan, intervención, educación |
| **Trabajadora social** | Seguimiento red de apoyo, gestiones municipales, ayudas técnicas, coordinación con CESFAM, contención emocional |
| **TENS** | Signos vitales, administración medicamentos orales, cumplimiento plan enfermería, observaciones |

#### 3.3.2 Signos vitales y monitoreo

- **Registro estructurado:** PA sistólica/diastólica, FC, FR, T°, SpO2, dolor (EVA 0-10), Glasgow, diuresis, glucemia capilar (si aplica)
- **Alertas automáticas por rangos:** Configurable por patología y por paciente
  - SpO2 < 90% → alerta roja
  - PA sistólica < 90 o > 180 → alerta naranja
  - FC < 50 o > 120 → alerta naranja
  - T° > 38.5°C → alerta amarilla
  - Glasgow < 13 → alerta roja
- **Gráficos de tendencia:** Visualización temporal de signos vitales para detectar deterioro progresivo
- **Score de alerta temprana (NEWS2 adaptado):** Cálculo automático con cada registro de signos vitales

#### 3.3.3 Gestión de medicamentos

| Feature | Descripción |
|---------|-------------|
| Kardex digital | Lista de medicamentos activos con vía, dosis, frecuencia, hora programada |
| Registro de administración | Quién administró, hora real, vía, dosis. Firma digital |
| Alerta de horarios | Notificación al enfermero cuando se acerca hora de administración EV/SC |
| Control de stock domiciliario | Inventario de medicamentos dejados en domicilio, fecha de vencimiento |
| Reconciliación medicamentosa | Comparación medicamentos HODOM vs medicamentos crónicos del paciente (de APS) |
| Interacciones | Alerta de interacciones medicamentosas graves (integración con base farmacológica) |

#### 3.3.4 Planificación de rutas

| Feature | Descripción |
|---------|-------------|
| Mapa de pacientes activos | Visualización geográfica de todos los pacientes HODOM con ubicación, estado, próxima visita |
| Optimizador de rutas | Algoritmo que asigna pacientes a móviles minimizando tiempo de traslado y respetando restricciones (horarios de tratamiento EV, frecuencia de visitas según categorización) |
| Ruta del día | Vista por móvil/conductor: secuencia de pacientes, hora estimada de llegada, profesionales que van en cada visita, procedimientos programados |
| Registro de kilómetros | Km recorridos por móvil por día, por ruta. Automático si GPS disponible |
| Alertas de ruta | Aviso si un paciente no fue visitado según frecuencia programada |
| Tiempo estimado por visita | Según categorización y procedimientos: básico (30 min), medio (45 min), complejo (60 min) + tiempo de traslado |

#### 3.3.5 Comunicación equipo-paciente

| Feature | Descripción |
|---------|-------------|
| Canal de comunicación con cuidador | Mensajería dentro del sistema (texto) para consultas no urgentes entre visitas |
| Teléfono de contacto HODOM | Registro de llamadas entrantes del cuidador con motivo, resolución, profesional que atendió |
| Alertas del cuidador | Botón de alerta en app simplificada del cuidador: "Paciente con fiebre", "Paciente con dificultad respiratoria", "Necesito hablar con el equipo" |
| Protocolo de escalamiento digital | Flujo guiado: detección de signo de alarma → contacto médico HODOM → evaluación → decisión (ajuste telefónico / visita urgente / activar SAMU 131) |

---

### 3.4 MÓDULO DE ESCALAMIENTO Y SEGURIDAD

**HU cubiertas:** HU-P13, HU-P14, HU-P15, HU-EO04, HU-SAMU01, HU-OCSP01, HU-OCSP02, HU-EPI01

| Feature | Descripción |
|---------|-------------|
| Protocolo de escalamiento (Verde/Amarillo/Naranja/Rojo) | Flujo digital con tiempos máximos de respuesta, responsables, y registro de cada paso |
| Registro de eventos adversos | Formulario: tipo (caída, error medicación, infección, reacción adversa, deterioro no detectado), gravedad, acción tomada, outcome |
| Notificación automática OCSP | Evento adverso → notificación inmediata al encargado de calidad |
| Registro de escalamientos SAMU | Hora de activación, motivo, tiempo de respuesta, destino del paciente |
| Registro de reingresos | Paciente reingresado → motivo, servicio de destino, días desde ingreso HODOM |
| Dashboard de seguridad | Tasa de eventos adversos, reingresos, escalamientos, mortalidad — actualizado en tiempo real |
| Auditoría de fichas | Checklist de auditoría trimestral OCSP: consentimiento firmado, evoluciones completas, indicaciones actualizadas, plan de enfermería, educación registrada |

---

### 3.5 MÓDULO DE ALTA Y CONTRARREFERENCIA

**HU cubiertas:** HU-P16, HU-P17, HU-P18, HU-C09, HU-C10, HU-MT05, HU-APS01, HU-APS02

| Feature | Descripción |
|---------|-------------|
| Criterios de alta por patología | Checklist digital de criterios de alta estandarizados. No se puede dar alta sin cumplir mínimos |
| Epicrisis médica automática | Generación desde datos del sistema: diagnóstico, tratamiento realizado, evolución, indicaciones al alta, controles programados |
| Epicrisis de enfermería | Plan de cuidados al alta, educación entregada, estado de dispositivos, alertas para APS |
| Despacho de recetas al alta | Generación de recetas → despacho farmacia → registro de entrega |
| Programación de controles | Solicitud automática de horas en CAE y/o CESFAM. Registro de hora asignada |
| Gestión ayudas técnicas GES | Solicitud, seguimiento, entrega. Integración con formulario GES si corresponde |
| Contrarreferencia digital a APS | Documento estructurado enviado automáticamente al CESFAM de origen con: epicrisis, indicaciones, controles, alertas |
| Acuse de recepción APS | El CESFAM confirma recepción de la contrarreferencia en el sistema |
| Seguimiento post-alta 48h | Tarea automática generada para enfermera coordinadora: llamada telefónica a 48h, registro de resultado |
| Encuesta de satisfacción | Enviada al alta (digital o telefónica). Preguntas estandarizadas: satisfacción global, comunicación equipo, comodidad, recomendaría HODOM |
| Cierre de episodio | Cambio de estado: `en_domicilio` → `alta_médica` / `reingreso` / `fallecimiento` / `alta_administrativa` |

---

### 3.6 MÓDULO DE GESTIÓN DE RECURSOS

**HU cubiertas:** HU-E01, HU-E02, HU-CO01, HU-CO02, HU-CO03, HU-FA01, HU-FA02, HU-LAB01

#### 3.6.1 Insumos y medicamentos

| Feature | Descripción |
|---------|-------------|
| Inventario de bodega HODOM | Stock de insumos por tipo, cantidad, fecha vencimiento, punto de reorden |
| Hoja de cargo por paciente | Registro automático de insumos utilizados en cada visita |
| Solicitud de reposición | Generación automática cuando stock < punto de reorden → notificación a farmacia/abastecimiento |
| Informe mensual de consumo | Por tipo de insumo, por paciente, por diagnóstico |

#### 3.6.2 Flota de vehículos

| Feature | Descripción |
|---------|-------------|
| Estado de móviles | Disponible / en ruta / en mantención. Km acumulados, fecha próxima revisión técnica |
| Registro de combustible | Cargas, km recorridos, rendimiento |
| Alerta de mantención | Cuando km acumulados alcanzan intervalo de servicio |

#### 3.6.3 Equipamiento clínico

| Feature | Descripción |
|---------|-------------|
| Inventario de equipos | Monitor, ECG, DEA, oxímetro, electroestimulador, etc. — asignados a móvil o en domicilio del paciente |
| Préstamo a domicilio | Colchones antiescaras, oxímetros prestados → tracking de devolución al alta |
| Calibración y mantención | Fecha última calibración, próxima, responsable |

---

### 3.7 MÓDULO DE REPORTES Y DASHBOARD

**HU cubiertas:** HU-D01, HU-D02, HU-D03, HU-E04, HU-UGP01, HU-UGP02, HU-UGP03, HU-UPI01, HU-UPI03, HU-SSÑ01, HU-MIN02, HU-A02

#### 3.7.1 Dashboard en tiempo real (rol: dirección, UGP, enfermera_coord)

| Widget | Datos |
|--------|-------|
| Cupos HODOM | Ocupados / Disponibles / Total (barra) |
| Pacientes activos | Lista con nombre, diagnóstico, día de estada, categorización, semáforo (verde/amarillo/rojo) |
| Mapa de pacientes | Geolocalización de pacientes activos + móviles en ruta |
| KPIs del mes | Índice ocupacional, estada promedio, reingresos, mortalidad, satisfacción |
| Camas liberadas hoy | N° de camas liberadas en servicios del HSC por egresos a HODOM |
| Alertas activas | Eventos adversos no cerrados, pacientes sin visita programada, insumos bajo stock |

#### 3.7.2 Informes periódicos

| Informe | Periodicidad | Destinatario | Contenido |
|---------|-------------|-------------|-----------|
| Informe mensual operativo | Mensual | Dirección HSC | Producción (ingresos, altas, días-cama), KPIs, eventos adversos, reingresos, satisfacción, RRHH (visitas por estamento), insumos, km |
| Informe trimestral de calidad | Trimestral | OCSP, Dirección | Auditorías de fichas, cumplimiento protocolo PRO-002, eventos adversos con análisis de causa |
| Informe REM/DEIS | Mensual | MINSAL vía SS Ñuble | Producción estandarizada según formato ministerial |
| Informe de gestión de camas | Semanal | UGP | Cupos utilizados, días-cama liberados, impacto en oportunidad UEA |
| Informe financiero | Mensual | Finanzas, UPI | Costo por paciente, consumo insumos, RRHH, comparación con presupuesto |
| Informe a SS Ñuble | Trimestral | Referente HODOM SS Ñuble | Resumen ejecutivo: producción, seguridad, indicadores de red |

#### 3.7.3 Indicadores calculados automáticamente

| KPI | Fórmula | Meta |
|-----|---------|------|
| Índice ocupacional | Días-persona / (cupos × días) × 100 | ≥80% |
| Tasa reingresos | Reingresos / Egresos × 100 | ≤3% |
| Mortalidad no esperada | Fallecidos no esperados / Ingresos × 100 | 0% |
| Estada promedio | Días-persona / Egresos | 6-7 d |
| Tiempo solicitud→ingreso | Promedio horas desde F1 hasta traslado a domicilio | ≤12 h |
| Visitas/paciente/día | Total visitas / Días-persona | ≥1.5 |
| Satisfacción usuaria | Score promedio encuesta (1-5) | ≥4.2 |
| Cumplimiento protocolo | Auditorías OK / Total | ≥90% |
| Cobertura territorial rural | Pacientes fuera SC urbano / Total | ≥30% |

---

### 3.8 MÓDULO DE GESTIÓN DE PERSONAL

**HU cubiertas:** HU-RRHH01, HU-RRHH02, HU-RRHH03

| Feature | Descripción |
|---------|-------------|
| Turnos y cobertura | Calendario de cuarto turno modificado (largo-largo-libre-libre). Visualización de cobertura diaria por rol |
| Asignación de rutas | Qué profesionales van en cada móvil cada día |
| Registro de asistencia | Hora entrada/salida, ausencias, reemplazos |
| Carga de trabajo | N° pacientes asignados por enfermero, N° visitas realizadas, tiempo en terreno vs sede |
| Capacitación | Registro de actividades de educación continua, certificaciones |

---

### 3.9 MÓDULO DE INTEGRACIÓN

**HU cubiertas:** HU-LAB01, HU-LAB02, HU-IMG01, HU-FA01, HU-FA02

| Integración | Tipo | Descripción |
|------------|------|-------------|
| Sistema hospitalario (SIDRA u otro) | API / HL7 FHIR | Consulta datos demográficos, diagnósticos, indicaciones, resultados de exámenes |
| Farmacia | API bidireccional | Envío de recetas → confirmación despacho → registro de entrega |
| Laboratorio | API bidireccional | Registro de muestra enviada → recepción de resultados → inserción en ficha HODOM |
| Imagenología | Notificación | Solicitud de examen → programación de cita → resultado disponible |
| CESFAM / APS | API / Email estructurado | Contrarreferencia automática, notificación de ingreso/alta, acuse de recepción |
| REM / DEIS | Exportación | Generación de archivo en formato ministerial para reporte mensual |
| SAMU | Protocolo manual | Lista actualizada de pacientes HODOM activos compartida diariamente |

---

## 4. Arquitectura técnica

### 4.1 Stack tecnológico recomendado

| Capa | Tecnología | Justificación |
|------|-----------|---------------|
| Frontend | React / Next.js + PWA | Funciona como app en tablet de terreno, offline-capable para zonas sin señal rural |
| Backend | Node.js / NestJS o Python / FastAPI | API REST, escalable, mantenible |
| Base de datos | PostgreSQL | Relacional, robusto, auditabilidad |
| Autenticación | OAuth 2.0 + JWT | Roles, permisos, auditoría de acceso |
| Mapas/Rutas | OpenStreetMap + Leaflet | Sin costo de licencia, funciona offline con tiles descargados |
| Notificaciones | WebSocket + Push notifications | Alertas en tiempo real |
| Almacenamiento de documentos | S3-compatible (MinIO on-premise) | Consentimientos escaneados, fotos de heridas |
| Hosting | On-premise (servidor HSC) o cloud institucional SS Ñuble | Cumplimiento Ley 19.628, datos en territorio nacional |

### 4.2 Requisitos de infraestructura

| Requisito | Especificación |
|-----------|---------------|
| Servidor | 8 cores, 32 GB RAM, 500 GB SSD (o VPS equivalente) |
| Conectividad sede HODOM | Internet dedicado ≥50 Mbps |
| Tablets de terreno | 3-4 tablets Android/iPad con funda resistente, 4G con chip datos |
| Smartphones equipo | 2 smartphones con GPS, cámara, y app HODOM |
| Backup | Respaldo diario automatizado, retención 90 días, prueba de restauración trimestral |
| Disponibilidad | 99.5% uptime (permite ~44 hrs downtime/año) |
| Modo offline | La app PWA debe funcionar sin conexión para registro de signos vitales y evoluciones, sincronizando cuando recupere señal |

### 4.3 Seguridad y privacidad

| Control | Implementación |
|---------|---------------|
| Autenticación | Login con credencial institucional + 2FA para roles clínicos |
| Autorización | RBAC (role-based access control) con permisos granulares por módulo |
| Auditoría | Log de toda acción (quién, qué, cuándo, desde dónde) — inmutable |
| Cifrado | HTTPS en tránsito, AES-256 en reposo para datos sensibles |
| Ley 19.628 | Datos personales de salud tratados conforme a normativa chilena |
| Ley 20.584 | Acceso a ficha clínica controlado por rol, con registro de cada consulta |
| Backups cifrados | Respaldos cifrados almacenados en ubicación separada |
| Consentimiento digital | Almacenamiento con hash de integridad + timestamp |

---

## 5. Pantallas principales (wireframes conceptuales)

### 5.1 Dashboard principal (enfermera coordinadora)
```
┌────────────────────────────────────────────────────────────┐
│  HODOM HSC — Dashboard                    [👤 EU Castillo] │
├──────────┬──────────┬──────────┬──────────┬────────────────┤
│ OCUPADOS │ DISPONIB │ INGRESOS │ ALTAS    │ ALERTAS        │
│   22/25  │    3     │   2 hoy  │  1 hoy   │ ⚠️ 2 activas   │
├──────────┴──────────┴──────────┴──────────┴────────────────┤
│                                                            │
│  🗺️ [MAPA DE PACIENTES]     📋 [LISTA DE PACIENTES]       │
│                                                            │
│  Paciente        │ Dx        │ Día │ Cat   │ Estado │ Móvil│
│  ─────────────── │ ───────── │ ─── │ ───── │ ────── │ ─────│
│  González, María │ NAC       │  3  │ Medio │ 🟢     │ M-1  │
│  Muñoz, Pedro    │ ICC desc  │  5  │ Medio │ 🟡     │ M-2  │
│  Soto, Carmen    │ Celulitis │  2  │ Básic │ 🟢     │ M-1  │
│  Vergara, Luis   │ EPOC      │  7  │ Comp  │ 🟠     │ M-3  │
│  ...             │           │     │       │        │      │
├────────────────────────────────────────────────────────────┤
│  📊 KPIs del mes: Ocupación 88% │ Estada 6.8d │ Reing 2% │
│  🚗 Rutas hoy: M-1 (6 pac) │ M-2 (5 pac) │ M-3 (4 pac)  │
│  📦 Stock: ⚠️ Ceftriaxona 1g: 5 unidades (punto reorden)  │
└────────────────────────────────────────────────────────────┘
```

### 5.2 Ficha del paciente (vista enfermero en tablet de terreno)
```
┌────────────────────────────────────────────────────────────┐
│  María González Pérez (72 años) │ RUN: 8.XXX.XXX-X       │
│  Dx: NAC + EPOC │ Día 3/7 │ Cat: Medio │ 🟢 Estable      │
├────────────────────────────────────────────────────────────┤
│  [Signos Vitales] [Evolución] [Medicamentos] [Educación]  │
├────────────────────────────────────────────────────────────┤
│  SIGNOS VITALES — Registrar:                               │
│  PA: [___/___] FC: [___] FR: [___] T°: [___] SpO2: [___] │
│  Dolor EVA: [___] Glasgow: [___] Glucemia: [___]          │
│  NEWS2 calculado: [automático]                             │
│                                                            │
│  📈 Tendencia SpO2: 94→95→93→96 (últimas 4 visitas)      │
│                                                            │
│  PROCEDIMIENTOS HOY:                                       │
│  ☑️ Administrar Ceftriaxona 1g EV (12:00)                  │
│  ☐ Curación herida pierna derecha                          │
│  ☐ Toma hemograma control                                  │
│                                                            │
│  INDICACIONES MÉDICAS VIGENTES:                            │
│  - Ceftriaxona 1g EV c/12h (día 3/7)                      │
│  - Paracetamol 1g VO c/8h SOS                             │
│  - O2 2L/min por naricera                                  │
│  - Reposo relativo, dieta blanda                           │
│                                                            │
│  [💾 Guardar] [⚠️ Escalar] [📞 Llamar médico]             │
└────────────────────────────────────────────────────────────┘
```

### 5.3 Vista del médico referente (solicitud de ingreso)
```
┌────────────────────────────────────────────────────────────┐
│  SOLICITUD DE INGRESO A HODOM                              │
├────────────────────────────────────────────────────────────┤
│  Paciente: [buscar por RUN o nombre]                       │
│  Servicio de origen: [UEA ▼]                               │
│  Diagnóstico principal: [NAC ▼]                            │
│  Categorización: [D2 ▼]                                    │
│  Estabilidad clínica: ☑️ Hemodinámicamente estable          │
│  Indicaciones actuales: [texto libre]                      │
│  IC pendientes: [texto libre]                              │
│  Observaciones: [texto libre]                              │
│                                                            │
│  VERIFICACIÓN AUTOMÁTICA:                                  │
│  ✅ Diagnóstico en cartera HODOM                            │
│  ✅ Edad ≥ 18 años                                          │
│  ✅ Comuna elegible (San Carlos)                            │
│  ⚠️ Cupos disponibles: 3                                   │
│                                                            │
│  [📤 Enviar solicitud]                                     │
└────────────────────────────────────────────────────────────┘
```

---

## 6. Fases de desarrollo

| Fase | Módulos | Duración | Entregable |
|------|---------|----------|------------|
| **MVP (v1.0)** | Captación + Ingreso + Atención (registro básico) + Alta + Dashboard simple | 3-4 meses | Sistema operativo mínimo para reemplazar planillas Excel |
| **v1.5** | Rutas + Medicamentos + Alertas de signos vitales + Informes mensuales | 2 meses | Gestión operativa completa |
| **v2.0** | Integración con sistemas HSC + Contrarreferencia APS + Auditoría OCSP | 3 meses | Interoperabilidad hospitalaria |
| **v2.5** | App cuidador (alertas) + Modo offline + Fotos de heridas | 2 meses | Extensión al domicilio |
| **v3.0** | Optimizador de rutas con IA + Predictor de deterioro (NEWS2) + Telemedicina | 3 meses | Inteligencia operativa |

**Costo estimado de desarrollo:** $40M-$80M CLP (dependiendo de modelo: equipo interno SS Ñuble vs licitación externa vs desarrollo open-source colaborativo).

---

## 7. Requisitos no funcionales

| Requisito | Especificación |
|-----------|---------------|
| Rendimiento | Tiempo de carga < 3 segundos en conexión 4G |
| Escalabilidad | Soportar hasta 50 pacientes simultáneos y 100 usuarios concurrentes |
| Usabilidad | Interfaz táctil para tablets de terreno, fuente legible, flujos en ≤3 clics |
| Accesibilidad | WCAG 2.1 AA (contraste, tamaño fuente, navegación por teclado) |
| Idioma | Español (Chile) |
| Disponibilidad | 99.5% uptime en horario de cobertura (08:00-20:00) |
| Backup | RPO ≤ 4 horas, RTO ≤ 2 horas |
| Auditoría | Toda acción registrada con usuario, timestamp, IP, acción, datos modificados |
| Compatibilidad | Chrome, Safari, Firefox (últimas 2 versiones). Android ≥10, iOS ≥15 |

---

## 8. Trazabilidad HU → Módulos

| Grupo de actores | HU | Módulos que las satisfacen |
|-----------------|-----|---------------------------|
| Paciente (21 HU) | HU-P01 a HU-P21 | Captación, Ingreso, Atención, Escalamiento, Alta |
| Cuidador (10 HU) | HU-C01 a HU-C10 | Ingreso, Atención (comunicación, educación), Alta |
| Equipo clínico (26 HU) | HU-M01 a HU-A02 | Captación, Ingreso, Atención, Escalamiento, Alta, Recursos, Personal |
| Médicos referentes (5 HU) | HU-MT01 a HU-MT05 | Captación (solicitud, retroalimentación) |
| Dirección (5 HU) | HU-D01 a HU-SDGC02 | Dashboard, Reportes |
| Unidades apoyo (8 HU) | HU-FA01 a HU-EPI01 | Integración, Escalamiento, Recursos |
| Red externa (6 HU) | HU-APS01 a HU-MUN02 | Alta (contrarreferencia), Integración |
| UGP (3 HU) | HU-UGP01 a HU-UGP03 | Dashboard, Reportes |
| Proyectos (3 HU) | HU-UPI01 a HU-UPI03 | Reportes |
| RRHH (3 HU) | HU-RRHH01 a HU-RRHH03 | Personal |
| Pacientes externos (2 HU) | HU-EXT01 a HU-EXT02 | Captación (reglas de exclusión territorial) |
| Reguladores (4 HU) | HU-MIN01 a HU-CGR01 | Reportes (REM/DEIS), Auditoría, Seguridad |

**Cobertura total: 96/96 HU mapeadas a módulos del sistema.**
