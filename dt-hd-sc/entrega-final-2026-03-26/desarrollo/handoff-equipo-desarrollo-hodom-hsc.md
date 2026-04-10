# Handoff para Equipo de Desarrollo — HODOM OS
## Sistema Operativo de Hospitalización Domiciliaria · Hospital de San Carlos
### Versión 1.0 · Marzo 2026

---

# 1. Contexto que el equipo de desarrollo debe conocer

## 1.1 Qué es HODOM

La Unidad de Hospitalización Domiciliaria (HODOM) del Hospital de San Carlos provee atención clínica hospitalaria en el domicilio del paciente. Es una extensión funcional del hospital, no un programa comunitario.

**Números clave:**
- Hospital de 130 camas en San Carlos, Ñuble, Chile
- 2.135 pacientes atendidos (2023-2025), 0 fallecidos no esperados
- 20-25 cupos simultáneos, estada ~7 días
- 3 móviles (vehículos), equipo multidisciplinario (~15-20 personas)
- Radio operativo: 20 km (urbano + rural)
- Población objetivo: 67.034 adultos en 5 comunas

## 1.2 Problema central que el sistema resuelve

**Hoy HODOM opera con papel + planillas Excel + archivos sueltos en Google Drive + comunicación informal.** No existe sistema de información propio. Los médicos registran en papel; las enfermeras usan parcialmente el SGH hospitalario. No hay visibilidad compartida, trazabilidad ni capacidad de auditoría.

El sistema debe ser **la capa operativa completa** de la unidad: desde captación del paciente hasta alta y contrarreferencia a APS.

## 1.3 Quién es el usuario

| Perfil | Contexto técnico | Dispositivo |
|---|---|---|
| Enfermeras operativas | Uso básico de smartphone, registran en terreno | Celular |
| Kinesiólogos / Fonoaudióloga | Idem | Celular |
| TENS | Uso básico | Celular |
| Médicos | Registro actualmente en papel, poco acostumbrados a digital | Celular / PC |
| Enfermera coordinadora | Gestiona cupos, rutas, insumos | PC |
| Director Técnico (DT) | Power user, regulador clínico | PC + celular |
| Conductores | Uso básico de smartphone | Celular |
| Dirección hospitalaria | Solo lectura dashboards | PC |
| Médicos referentes (hospital) | Solicitan ingresos | PC |
| APS / CESFAM | Reciben contrarreferencia | PC |

**Realidad de terreno:**
- Señal 4G variable en zonas rurales (hasta 20 km del hospital)
- Celulares personales de gama media
- Guantes, sol, lluvia, casas sin buena iluminación
- Registran de pie, a veces con el celular en una mano
- Pacientes mayoritariamente geriátricos, FONASA A/B (bajos ingresos)

## 1.4 Normativa relevante

| Instrumento | Relevancia para el sistema |
|---|---|
| DS N°1/2022 | Reglamento HD: lo que la unidad debe cumplir |
| Norma Técnica HD 2024 | Estándares de personal, equipamiento, registros, protocolos |
| Ley 21.541 | Autoriza telemedicina |
| Norma Técnica N°237 | Estándares para atención remota |
| Ley 20.584 | Derechos del paciente (acceso a ficha, consentimiento) |
| Decreto 41 | Reglamento de fichas clínicas |
| Ley 19.628 | Protección de datos personales |
| Ley 21.668 | Interoperabilidad de fichas clínicas |

---

# 2. Decisiones de diseño ya tomadas (inamovibles)

Estas decisiones están validadas por el Director Técnico y no están abiertas a reinterpretación:

1. **Mobile-first.** Todo lo que se use en terreno debe funcionar perfectamente en smartphone.
2. **PWA, no app nativa.** Sin app store. Acceso por URL.
3. **Baja carga cognitiva.** Cada formulario debe ser el mínimo necesario. Si agrega complejidad sin valor claro, se rechaza.
4. **Una sola fuente de verdad.** Eliminar planillas paralelas.
5. **Registrar una vez, usar muchas.** Una captura que sirva para clínica, coordinación, impresión, indicadores y continuidad.
6. **Imprimible cuando se necesite.** El sistema debe poder generar versiones impresas compatibles con la ficha clínica papel.
7. **Visibilidad compartida.** La información crítica no puede vivir en un cuaderno o en una persona.
8. **Offline-capable.** El registro de signos vitales y evoluciones debe funcionar sin conexión y sincronizar al recuperar señal.
9. **Consentimientos digitales** con hash de integridad + timestamp.
10. **Teleatención ultraligera.** WebRTC en navegador. Sin app para el paciente. Acceso por link único.
11. **Datos en Chile.** Hosting on-premise o cloud institucional.
12. **Simplicidad radical.** Lo breve y usable vale más que lo perfecto e inutilizable.

---

# 3. Arquitectura recomendada

## 3.1 Stack

| Capa | Tecnología | Justificación |
|---|---|---|
| Frontend | React / Next.js + PWA | Mobile-first, offline-capable |
| Backend | Node.js / NestJS o Python / FastAPI | API REST |
| Base de datos | PostgreSQL | Relacional, auditable |
| Auth | OAuth 2.0 + JWT | RBAC con roles granulares |
| Mapas | OpenStreetMap + Leaflet | Sin costo de licencia, tiles offline |
| Notificaciones | WebSocket + Push | Alertas en tiempo real |
| Almacenamiento docs | S3-compatible (MinIO on-premise) | Consentimientos, fotos heridas |
| Video (teleatención) | WebRTC | P2P cifrado, sin intermediario |

## 3.2 Infraestructura mínima

| Requisito | Spec |
|---|---|
| Servidor | 8 cores, 32 GB RAM, 500 GB SSD |
| Conectividad sede | ≥50 Mbps |
| Backup | Diario, retención 90 días, RPO ≤4h, RTO ≤2h |
| Disponibilidad | 99,5% en horario 08:00-20:00 |

## 3.3 Seguridad

| Control | Implementación |
|---|---|
| Autenticación | Credencial institucional + 2FA para roles clínicos |
| Autorización | RBAC por módulo |
| Auditoría | Log inmutable: quién, qué, cuándo, desde dónde |
| Cifrado | HTTPS tránsito, AES-256 reposo |
| Ley 19.628 | Datos de salud conforme normativa chilena |

---

# 4. Roles y permisos

| Rol | Permisos | Usuarios estimados |
|---|---|---|
| `admin` | Configuración, usuarios, parámetros, auditoría | 1-2 |
| `medico_hodom` | Ingresos, indicaciones, evolución, alta, reportes | 2 |
| `enfermera_coord` | Gestión cupos, rutas, insumos, informes | 1 |
| `enfermero_op` | Evolución enfermería, procedimientos, signos vitales | 4 |
| `tens` | Signos vitales, medicación oral, actividades | 2 |
| `kinesiologo` | Plan kinésico, evolución, procedimientos | 3 |
| `fonoaudiologo` | Plan fono, evolución, educación deglutoria | 1 |
| `trabajadora_social` | Evaluación sociosanitaria, gestión redes | 1 |
| `conductor` | Ruta asignada, km, estado móvil | 5 |
| `medico_referente` | Solicitud ingreso, consulta estado paciente | ~30 |
| `direccion` | Dashboard, KPIs (solo lectura) | 3-5 |
| `ugp` | Cupos, liberación camas, indicadores (solo lectura) | 2-3 |
| `farmacia` | Recetas, despacho, stock | 2-3 |
| `laboratorio` | Muestras, resultados | 2-3 |
| `calidad_ocsp` | Auditoría, eventos adversos | 1-2 |
| `aps_cesfam` | Contrarreferencia, seguimiento post-alta (lectura + acuse) | 10-20 |

---

# 5. Módulos del sistema (por orden de prioridad de desarrollo)

## 5.1 Sprint 0 — Semana 1 (arranque 1 de abril)

### M1. Panel General / Tablero Operativo
**Objetivo:** visibilidad compartida del estado de la unidad en tiempo real.

**Features:**
- Censo: pacientes activos, cupo ocupado/disponible (de 25)
- Lista de pacientes con: nombre, diagnóstico, día de estada, categorización (básico/medio/complejo), semáforo (verde/amarillo/naranja/rojo)
- Alertas activas
- Ingresos pendientes / altas pendientes
- Móviles: estado (en ruta/en base/mantención) + ruta del día
- Pendientes críticos del día

**Usuarios principales:** enfermera_coord, medico_hodom, direccion

### M2. Registro Móvil de Atención
**Objetivo:** captura clínica digital desde terreno, por disciplina.

**Features por estamento:**

| Estamento | Campos |
|---|---|
| Enfermería | PA, FC, FR, T°, SpO2, dolor EVA, Glasgow, procedimientos (VVP, SNG, curación, EV, toma muestras), nota |
| Médico | Evolución, ajuste indicaciones, solicitud exámenes, decisión escalamiento/alta |
| Kinesiología | Evaluación funcional (TUG, Barthel), plan, procedimientos (KTR, KTM, aspiración, nebulización, O₂) |
| Fonoaudiología | Evaluación deglutoria (FOIS), habla/lenguaje/voz, intervención |
| TENS | Signos vitales, administración medicamentos orales, observaciones |

**Alertas automáticas por rangos:**
- SpO₂ < 90% → alerta roja
- PA sistólica < 90 ó > 180 → alerta naranja
- FC < 50 ó > 120 → alerta naranja
- T° > 38,5°C → alerta amarilla
- Glasgow < 13 → alerta roja
- NEWS2 automático con cada registro

**Requisitos críticos:**
- Funcionar offline (sincronizar al recuperar señal)
- Formularios cortos (≤ 2 minutos de llenado)
- Imprimible en formato compatible con ficha papel
- Georreferencia automática opcional

### M3. Regulación Clínica de Casos
**Objetivo:** el DT como médico regulador decide sobre flujo de casos.

**Features:**
- Bandeja de ingresos propuestos
- Casos complejos / alertas activas
- Egresos posibles
- Rescates
- Decisión del regulador (aceptar/rechazar/escalar/egresar) con motivo
- Responsable y plazo
- Huella de decisión (auditable)

### M4. Briefing Digital
**Objetivo:** reemplazar coordinación informal por estructura diaria.

**Features:**
- Vista resumen del día: censo, alertas, prioridades
- Tareas asignadas por profesional
- Novedades del turno anterior
- Espacio para decisiones rápidas

## 5.2 Sprint 1 — Semana 2

### M5. Ingreso / Evaluación Domiciliaria
**Features:**
- Formulario de solicitud de ingreso (médico referente → HODOM)
- Checklist de elegibilidad clínica
- Evaluación sociosanitaria: vivienda, servicios básicos, cuidador, red de apoyo, accesibilidad, distancia
- Consentimiento informado digital
- Asignación de equipo y móvil
- Cambio de estado: solicitado → evaluado → aceptado → ingresado

**Reglas de negocio:**
- No aceptar si cupos = 0
- No aceptar sin evaluación sociosanitaria aprobada
- No aceptar sin consentimiento firmado
- Tiempo máximo solicitud→resolución: 4 horas
- Paciente en UEA > 12h → flag prioridad automática
- Motivo de rechazo obligatorio

### M6. Alta y Contrarreferencia
**Features:**
- Criterios de alta por patología (checklist)
- Epicrisis médica (generación desde datos del sistema)
- Epicrisis de enfermería
- Indicaciones al alta
- Contrarreferencia digital a CESFAM de origen
- Acuse de recepción por APS
- Seguimiento post-alta 48h (tarea automática)
- Encuesta de satisfacción
- Cierre de episodio

### M7. Escalamiento Clínico Digital
**Features:**
- Protocolo semáforo (Verde → Amarillo → Naranja → Rojo) con tiempos de respuesta
- NEWS2 automático desde signos vitales
- Registro de escalamiento: motivo, acción, decisión, resultado
- Registro de eventos adversos
- Dashboard de seguridad

### M8. Georreferenciación
**Features:**
- Mapa de pacientes activos con estado y semáforo
- Macrozonas operativas (urbano < 3km, periurbano 3-10, rural 10-18, rural lejano > 18)
- Asignación de móvil por zona/día
- Ruta sugerida con estimación de km y tiempo
- Apoyo a planificación diaria

## 5.3 Sprint 2 — Semana 3

### M9. Tablero de Indicadores
**KPIs automáticos:**

| KPI | Fórmula | Meta |
|---|---|---|
| Índice ocupacional | Días-persona / (cupos × días) × 100 | ≥80% |
| Tasa reingresos | Reingresos / Egresos × 100 | ≤3% |
| Mortalidad no esperada | Fallecidos no esperados / Ingresos × 100 | 0% |
| Estada promedio | Días-persona / Egresos | 6-7 d |
| Tiempo solicitud→ingreso | Horas desde solicitud hasta traslado | ≤12h |
| Visitas/paciente/día | Total visitas / Días-persona | ≥1,5 |
| Satisfacción | Score promedio (1-5) | ≥4,2 |
| Cumplimiento protocolo | Auditorías OK / Total | ≥90% |

**Informes periódicos:**
- Mensual operativo → Dirección
- Trimestral calidad → OCSP
- Mensual REM/DEIS → MINSAL
- Semanal gestión de camas → UGP

### M10. Gestión de Recursos
- Inventario de insumos con punto de reorden
- Estado de móviles (disponible/en ruta/mantención, km)
- Equipamiento clínico (concentradores O₂, monitores, oxímetros)
- Préstamo de equipos a domicilio con tracking de devolución

### M11. Gestión de Personal
- Calendario cuarto turno (largo-largo-libre-libre)
- Cobertura diaria por rol
- Asignación profesional-móvil
- Carga de trabajo por enfermero

## 5.4 Sprint 3 — Semana 4

### M12. Telecontrol / Teleatención
**Decisiones críticas:**

| Componente | Decisión |
|---|---|
| Tipo | PWA mobile-first |
| Canal clínico | WebRTC cifrado + chat |
| Acceso paciente | Link único por SMS/WhatsApp (sin cuenta, sin app) |
| Acceso profesional | Desde panel HODOM con login |
| Registro post-sesión | Obligatorio: profesional, paciente, episodio, modalidad, motivo, hallazgos, plan, alerta |
| Consentimiento | Previo, trazable, revocable |
| Degradación | video → audio → chat |
| Grabación | No por defecto; solo con autorización adicional explícita |
| Integración | Panel HODOM, episodio activo, regulación clínica, impresión |

---

# 6. Datos del dominio clínico

## 6.1 Estados del episodio

```
solicitado → evaluado → aceptado → ingresado → en_domicilio → alta_médica
                                                             → reingreso
                                                             → fallecimiento
                                                             → alta_administrativa
        → rechazado (con motivo)
```

## 6.2 Categorización de pacientes

| Categoría | Complejidad | Frecuencia visitas |
|---|---|---|
| Básico | Monoprocedimiento simple (EV c/24h, curación, KTM) | 1/día |
| Medio | Multiprocedimiento o seguimiento más estrecho | 1-2/día |
| Complejo-medio | Polifarmacia, comorbilidades, O₂, riesgo de deterioro | 2/día |

## 6.3 Semáforo / escalamiento (NEWS2 adaptado)

| Color | NEWS2 | Acción | Tiempo respuesta |
|---|---|---|---|
| 🟢 Verde | 0-4 | Seguimiento habitual | Próxima visita programada |
| 🟡 Amarillo | 5-6 | Contacto médico HODOM | < 2 horas |
| 🟠 Naranja | ≥7 | Evaluación médica presencial | < 1 hora |
| 🔴 Rojo | ≥7 + red flag | Activar SAMU 131 / traslado hospital | Inmediato |

**Red flags (rojo directo):** compromiso de conciencia, shock, disnea severa, convulsiones, sangrado masivo, dolor torácico sugerente de SCA.

## 6.4 Diagnósticos más frecuentes (para catálogos)

| Diagnóstico | CIE-10 sugerido | % ingresos |
|---|---|---|
| ITU / IVU | N39.0 | 12,2% |
| Neumonía / BNM | J18.9 | 11,0% |
| ACV / Infarto cerebral | I63.9 | 3,5% |
| Insuficiencia respiratoria aguda | J96.0 | 1,9% |
| Fractura cuello fémur | S72.0 | 1,6% |
| Celulitis | L03.9 | 0,5% |
| Insuficiencia cardíaca | I50.9 | 0,6% |

## 6.5 Servicios derivadores

| Servicio | % derivaciones |
|---|---|
| Medicina | 42,7% |
| Urgencia (UEA) | 32,0% |
| Traumatología | 9,4% |
| Cirugía | 7,6% |
| UTI/UCI | 2,6% |
| Otros | 5,7% |

## 6.6 Flota vehicular

| Vehículo | Patente | Límite km/día | Disponibilidad |
|---|---|---|---|
| Móvil 1 | PFFF57 | 100 km | Lun-Dom |
| Móvil 2 | RGHB14 | 100 km | Lun-Dom |
| SUV | TZXS94 | 80 km | Lun-Vie |

## 6.7 Territorio

| Zona | Rango | % visitas |
|---|---|---|
| Urbana | < 3 km | 58% |
| Periurbana | 3-10 km | 16% |
| Rural cercana | 10-18 km | 19% |
| Rural lejana | > 18 km | 7% |

---

# 7. Wireframes de referencia

## 7.1 Dashboard principal (enfermera coordinadora)

```
┌────────────────────────────────────────────────────────────┐
│  HODOM HSC — Dashboard                        [👤 Login]   │
├──────────┬──────────┬──────────┬──────────┬────────────────┤
│ OCUPADOS │ DISPONIB │ INGRESOS │ ALTAS    │ ALERTAS        │
│   22/25  │    3     │   2 hoy  │  1 hoy   │ ⚠️ 2 activas   │
├──────────┴──────────┴──────────┴──────────┴────────────────┤
│  🗺️ [MAPA]                    📋 [LISTA]                   │
│                                                            │
│  Paciente        │ Dx     │ Día │ Cat   │ 🚦 │ Móvil      │
│  González, María │ NAC    │  3  │ Medio │ 🟢 │ M-1        │
│  Muñoz, Pedro    │ ICC    │  5  │ Medio │ 🟡 │ M-2        │
│  Vergara, Luis   │ EPOC   │  7  │ Comp  │ 🟠 │ M-3        │
├────────────────────────────────────────────────────────────┤
│  📊 Ocup 88% │ Estada 6.8d │ Reing 2%                     │
│  🚗 M-1 (6 pac) │ M-2 (5 pac) │ M-3 (4 pac)              │
│  📦 ⚠️ Ceftriaxona: 5 uds (bajo stock)                     │
└────────────────────────────────────────────────────────────┘
```

## 7.2 Registro en terreno (smartphone, enfermero)

```
┌──────────────────────────────┐
│  María González (72a)        │
│  NAC │ Día 3 │ Medio │ 🟢    │
├──────────────────────────────┤
│  SIGNOS VITALES              │
│  PA [___/___] FC [___]       │
│  FR [___]  T° [___]         │
│  SpO2 [___] Dolor [___]     │
│  → NEWS2: [auto]            │
├──────────────────────────────┤
│  PROCEDIMIENTOS HOY          │
│  ☑ Ceftriaxona 1g EV 12:00  │
│  ☐ Curación pierna der       │
│  ☐ Hemograma control         │
├──────────────────────────────┤
│  NOTA BREVE                  │
│  [________________________]  │
│  [________________________]  │
├──────────────────────────────┤
│  [💾 Guardar] [⚠️ Escalar]   │
└──────────────────────────────┘
```

---

# 8. Integraciones futuras (no para Sprint 0-3)

| Sistema | Tipo | Descripción |
|---|---|---|
| SGH hospitalario (SIDRA u otro) | API / HL7 FHIR | Datos demográficos, diagnósticos, resultados |
| Farmacia | API bidireccional | Recetas → despacho → entrega |
| Laboratorio | API bidireccional | Muestra → resultado → ficha |
| CESFAM / APS | API o email estructurado | Contrarreferencia automática |
| REM / DEIS | Exportación | Formato ministerial mensual |

---

# 9. Requisitos no funcionales

| Requisito | Spec |
|---|---|
| Rendimiento | < 3 seg carga en 4G |
| Escalabilidad | 50 pacientes simultáneos, 100 usuarios concurrentes |
| Usabilidad | Interfaz táctil, fuente legible, ≤ 3 clics por flujo |
| Accesibilidad | WCAG 2.1 AA |
| Idioma | Español (Chile) |
| Compatibilidad | Chrome, Safari, Firefox (últimas 2). Android ≥10, iOS ≥15 |
| Modo offline | Registro signos vitales + evoluciones sin conexión |

---

# 10. Plan de sprints

| Sprint | Semana | Módulos | Entregable |
|---|---|---|---|
| **0** | 1 (1 abril) | Panel general + Registro móvil + Regulación clínica + Briefing | Capa operativa mínima funcional |
| **1** | 2 | Ingreso/evaluación + Alta/contrarreferencia + Escalamiento + Georreferenciación | Ciclo completo del episodio |
| **2** | 3 | Indicadores + Recursos + Personal + Repositorio documental | Gestión y rendición |
| **3** | 4 | Telecontrol + Ajustes + Protocolo consolidado v1 | Teleatención operativa |

---

# 11. Documentos de referencia incluidos en esta entrega

| Documento | Contenido | Archivo |
|---|---|---|
| Consolidado estratégico | Diagnóstico + 3 horizontes + decisiones | `consolidado-estrategico-dt-hodom-hsc-2026-03-25.md` |
| HODOM OS v1 | Sistema operativo completo refactorizado | `hodom-os-v1.md` |
| Specs sistema web | 9 módulos, 17 roles, wireframes, stack | `specs-sistema-web-hodom-hsc.md` |
| Historias de usuario | 147 HU en 15 épicas, normativamente trazadas | `historias-usuario-hodom-hsc.md` |
| Criterios de aceptación | Criterios por HU | `criterios-aceptacion-hodom-hsc.md` |
| Backlog de producto | Backlog priorizado | `backlog-producto-hodom-hsc.md` |
| Modelo de dominio | Entidades + relaciones | `modelo-dominio-hodom-hsc.md` |
| Modelo FHIR | Mapeo a FHIR R4 | `modelo-dominio-fhir-hodom-hsc.md` |
| SNOMED-CT mapping | Codificación estándar | `snomed-ct-mapping-hodom.md` |
| Specs teleatención | Módulo de telecontrol detallado | `specs-teleatencion-hodom-hsc.md` |
| Marco rol DT | Autoridad y responsabilidades del DT | `marco-rol-dt-hodom-hsc.md` |
| Propuesta ideal | Modelo HODOM dimensionado | `propuesta-hodom-hsc-ideal.md` |
| Checklist normativo | 75 requisitos mapeados | `checklist-normativo-hodom-hsc.md` |
| Protocolos clínicos | 8 protocolos base | `protocolos-clinicos-por-patologia.md` |
| Informe telemetría | Análisis GPS × programación × atenciones | `informe-definitivo-telemetria-hodom-hsc.md` |
| Análisis datos legacy | 1.795 registros analizados | `analisis-datos-legacy-hodom-hsc.md` |
| Inventario e insights | Documentos institucionales procesados | `inventario-e-insights-hodom-hsc.md` |
| Plan capacitación | 5 módulos, 34 hrs | `plan-capacitacion-hodom-hsc.md` |
| Plan 90 días DT | Hoja de ruta del Director Técnico | `plan-90-dias-dt.md` |
| Guía escalamiento | Semáforo NEWS2 para terreno | `guia-escalamiento-terreno.md` |
| Formato briefing | Coordinación diaria | `formato-briefing-matinal.md` |
| Presentación Marp | Slides 18 slides | `presentacion-marp-dt-hodom-hsc.md` |
| Guión presentación | Guión slide por slide | `guion-presentacion-dt-hodom-hsc.md` |

---

# 12. Contactos

| Rol | Responsable | Canal |
|---|---|---|
| Director Técnico HODOM | Dr. Félix Sanhueza | Directo |
| Copiloto técnico HD | Salubrista-HaH (agente) | Este sistema |

---

# 13. Criterios de aceptación del Sprint 0

El Sprint 0 se considera exitoso si:

1. ☐ El DT puede ver censo de pacientes activos con cupos desde su celular
2. ☐ Un enfermero puede registrar signos vitales desde el celular en < 2 minutos
3. ☐ El registro genera alerta automática si SpO₂ < 90% o NEWS2 ≥ 7
4. ☐ El DT puede aceptar/rechazar un ingreso con motivo registrado
5. ☐ El briefing digital muestra: censo + alertas + pendientes + móviles
6. ☐ Todo queda registrado con auditoría (quién, qué, cuándo)
7. ☐ Funciona en Chrome mobile (Android) y Safari (iOS)
8. ☐ El formulario de registro es imprimible

---

*Handoff para equipo de desarrollo HODOM OS*
*Hospital de San Carlos · Marzo 2026*
*Preparado por: Copiloto técnico Salubrista-HaH + Director Técnico*
