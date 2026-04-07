# Resumen Ejecutivo Consolidado — Sistema Operativo HODOM HSC

Hospital de San Carlos Dr. Benicio Arzola Medina
Abril 2026

---

## El problema

La Unidad de Hospitalización Domiciliaria opera con 20-25 cupos diarios, ~600-850 pacientes/año y más de 10.000 visitas anuales. Toda esta operación se sostiene con 8-10 planillas Excel, formularios Google y registros en papel. Esto genera riesgo de pérdida de información clínica, imposibilidad de trazabilidad regulatoria, 2-3 días mensuales de redigitación REM y dificultad para coordinar 8+ profesionales y 3 móviles.

---

## La propuesta

Un **sistema operativo de hospitalización domiciliaria** que integre admisión, ficha clínica, programación, teleatención, logística y reportería REM en una sola plataforma.

---

## Cifras del diseño

| Dimensión | Valor |
|-----------|-------|
| Usuarios identificados | 17 (clínicos, operativos, institucionales, externos) |
| Historias de usuario formales | 31 (15 obligatorias + 12 críticas + 4 deseables) |
| Módulos funcionales | 11 |
| Pantallas diseñadas | 16 P0 + vista móvil + formulario offline |
| Modelo de datos MVP | 14 tablas (DDL PostgreSQL ejecutable) |
| Funciones REM automáticas | 3 (C.1.1, C.1.2, origen derivación) |
| Recursos FHIR mapeados | 25 |
| Integraciones externas | 5 (DEIS, APS, gestión camas, DAU/SGH, laboratorio) |

---

## Qué reemplaza el MVP

| Hoy (manual) | Sistema |
|--------------|---------|
| Planilla programación mensual | Tablero de coordinación en tiempo real |
| Google Form de postulación | Admisión con checklist normativo de 8 condiciones |
| Registros en papel por disciplina | Ficha clínica electrónica + registro móvil offline |
| Planilla de rutas diarias | Agenda con profesional, móvil y ruta |
| Planilla de llamadas | Bandeja de comunicaciones trazable |
| Redigitación REM mensual | Generación automática desde datos operacionales |
| Entrega de turno en Word | Entrega digital con datos del episodio |

---

## Métricas de éxito

| Indicador | Hoy | Meta |
|-----------|-----|------|
| Tiempo generación REM | 2-3 días | < 1 hora |
| Registros clínicos en papel | ~80% | < 20% |
| Planillas Excel activas | 8-10 | 0 |
| Trazabilidad de llamadas | parcial | 100% |
| Visitas sin registro formal | ~10-15% | < 2% |
| Tiempo admisión (postulación → episodio) | sin medición | medido y < 12h |

---

## Fases de implementación

**Fase 1 (MVP):** Episodio completo punta a punta. Censo, admisión, ficha clínica, prescripción, visitas, egreso, epicrisis, REM automático. 15 historias obligatorias.

**Fase 2:** Operación completa. Cupos tiempo real, rutas dinámicas, curaciones, kinesiología, seguimiento post-egreso, portal paciente. 12 historias críticas.

**Fase 3:** Complementos. Teleatención estructurada, gestión de recursos, interconsultas. 4 historias deseables.

---

## Arquitectura recomendada

Monolito modular con núcleo de episodio, soporte mobile/offline para terreno, PostgreSQL como motor, y capa analítica que derive REM automáticamente sin redigitación.

---

## Decisiones de infraestructura (2026-04-07)

| Decisión | Resolución |
|----------|-----------|
| BD | **Existente** (`hodom-pg-v4`, puerto 5555). 103 tablas, 673 pacientes, 779 estadías migradas |
| Repo app | `/home/felix/projects/hdos-app` (separado de migración `hdos/`) |
| Dominio | `hd.sanixai.com` |
| Stack | Next.js + PWA |
| Portal | Incluido desde MVP. 4 tablas + 3 vistas ya instaladas en BD |
| Vistas operativas | 6 vistas + 4 funciones REM ya instaladas y probadas con datos reales |
| Ocupación real | 22/25 cupos (88%) verificado contra BD |

---

## Siguiente paso

1. Validar diseño y wireframes con equipo clínico real (coordinadora + médico + profesional terreno).
2. Decidir stack tecnológico y hosting.
3. Construir MVP Fase 1.

---

## Entregables del paquete

13 documentos técnicos: índice, diseño del sistema, usuarios, historias de usuario, roles y permisos, backlog MVP, arquitectura de información, wireframes P0, vista móvil, modelo de datos, DDL ejecutable, resumen ejecutivo y análisis de decisiones.
