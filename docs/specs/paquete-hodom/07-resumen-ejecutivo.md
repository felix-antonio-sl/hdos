# Resumen Ejecutivo — Sistema Operativo HODOM HSC

Hospital de San Carlos Dr. Benicio Arzola Medina
Abril 2026

---

## El problema

La Unidad de Hospitalización Domiciliaria del Hospital de San Carlos opera con 20-25 cupos diarios, atiende ~600-850 pacientes/año y genera más de 10.000 visitas anuales. Toda esta operación se sostiene actualmente con:

- **8-10 planillas Excel** para programación, rutas, llamadas, turnos y estadística,
- **formularios Google** para postulación e ingreso,
- **registros en papel** para ficha clínica, enfermería, kinesiología y curaciones,
- **redigitación manual** del REM A21 cada mes.

Esta fragmentación genera:
- riesgo de pérdida de información clínica,
- imposibilidad de trazabilidad regulatoria completa,
- 2-3 días mensuales dedicados a consolidar REM,
- dificultad para coordinar 8+ profesionales y 3 móviles diarios,
- sin registro formal de teleatención ni regulación médica a distancia.

---

## La propuesta

Diseñar y construir un **sistema operativo de hospitalización domiciliaria** que integre en una sola plataforma:

1. **Admisión y elegibilidad** normativa (DS 1/2022)
2. **Ficha clínica electrónica** del episodio HODOM
3. **Programación y rutas** dinámicas
4. **Teleatención y regulación** con trazabilidad
5. **Generación automática de REM A21**

---

## Usuarios identificados

| Grupo | Roles | Cantidad estimada |
|-------|-------|-------------------|
| Clínico-operativo | Médicos, enfermeras, TENS, kinesiólogos, fonoaudiólogo, trabajo social, otros | ~12-15 |
| Administrativo-logístico | Coordinación, administrativo, gestor rutas, bodega, conductor, estadístico | ~5-6 |
| Institucional | Dirección Técnica, derivadores hospitalarios, APS/CESFAM | ~10+ |
| Beneficiarios | Pacientes y cuidadores | ~20-30 activos |

---

## Arquitectura recomendada

**Monolito modular** con núcleo de episodio, 7 módulos internos, soporte mobile/offline para terreno y capa analítica que derive REM automáticamente.

---

## MVP: qué reemplaza

| Hoy (manual) | MVP (sistema) |
|--------------|---------------|
| Planilla programación mensual | Tablero de coordinación en tiempo real |
| Google Form de postulación | Módulo de admisión con checklist normativo |
| Registros en papel por disciplina | Ficha clínica electrónica con registro móvil |
| Planilla de rutas diarias | Agenda con asignación de profesional, móvil y ruta |
| Planilla de llamadas | Bandeja de comunicaciones trazable |
| Redigitación REM mensual | Generación automática desde datos operacionales |

---

## Métricas de éxito esperadas

| Indicador | Hoy | Meta MVP |
|-----------|-----|----------|
| Tiempo generación REM | 2-3 días | < 1 hora |
| Registros clínicos en papel | ~80% | < 20% |
| Planillas Excel activas | 8-10 | 0 |
| Trazabilidad de llamadas | parcial | 100% |
| Visitas sin registro formal | ~10-15% | < 2% |

---

## Entregables producidos

Se generaron 5 documentos técnicos + 1 DDL ejecutable + este resumen:

1. Diseño del sistema con 19 usuarios identificados y sus necesidades
2. Matriz de roles y permisos (14 roles × 7 módulos)
3. Backlog MVP priorizado en 3 fases con 40+ capacidades
4. Wireframes de 5 pantallas principales + formulario de visita móvil
5. Modelo de datos PostgreSQL (14 tablas, 4 vistas, 3 funciones REM)

---

## Siguiente paso recomendado

1. Validar diseño y wireframes con equipo clínico real (coordinadora + 1 profesional terreno).
2. Decidir stack tecnológico y hosting.
3. Construir MVP Fase 1 (estimación: 6-8 semanas con equipo dedicado).
