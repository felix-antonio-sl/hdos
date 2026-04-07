# Paquete Consolidado — Sistema Operativo HODOM HSC

**Hospital de San Carlos Dr. Benicio Arzola Medina**
Fecha: 2026-04-07 (actualizado)
Fuentes: Paquete Allan Kelly (PO) + Paquete Fugaz (Ingeniería) — fusionados
BD objetivo: `hodom` existente (puerto 5555, PostgreSQL) — no se crea BD nueva

---

## Contenido

| # | Documento | Origen | Tamaño aprox. |
|---|-----------|--------|---------------|
| 00 | **Este índice** | Fusión | — |
| 01 | Diseño del sistema operativo HODOM HSC | Fugaz (base) + Allan (enriquecido) | ~22 KB |
| 02 | Usuarios del sistema (19 usuarios: 17 núcleo + 2 portal) | Allan (canónico) + Fugaz (portal) | ~18 KB |
| 03 | Historias de usuario núcleo (38 HU, 12 módulos) | Allan (canónico) + Fugaz (portal) | ~28 KB |
| 04 | Roles y permisos (RBAC) | Fugaz (base) + Allan (permisos) | ~9 KB |
| 05 | Backlog MVP priorizado (MoSCoW × P0/P1/P2) | Fugaz (base) + Allan (HU formales) | ~11 KB |
| 06 | Arquitectura de información (datos, FHIR, flujos, integraciones) | Allan (canónico) | ~20 KB |
| 07 | Wireframes y flujos P0 (19 pantallas = 16 núcleo + 3 portal) | Allan (canónico) + Fugaz (portal) | ~68 KB |
| 08 | Vista móvil y formulario offline-first | Fugaz (exclusivo) | ~8 KB |
| 09 | Modelo de datos funcional MVP (14 tablas + DDL PostgreSQL) | Fugaz (canónico) | ~33 KB |
| 10 | DDL ejecutable `hodom-mvp.sql` (referencia) | Fugaz (canónico) | ~23 KB |
| 11 | Resumen ejecutivo | Fugaz (base) + Allan (cifras) | ~4 KB |
| 12 | Análisis comparativo y decisiones de fusión | Fugaz | ~11 KB |
| 13 | **Portal paciente/cuidador (MVP)** — 7 HU, 4 tablas, 3 vistas | Fugaz | ~7 KB |
| 14 | **Adaptación BD existente** — vistas operativas + REM contra `hodom-pg` | Fugaz | ~17 KB |

**Total:** ~279 KB en 15 documentos.

---

## Cifras clave del sistema

- **19 usuarios** (6 clínicos + 3 gestión + 3 red + 3 supervisión + 2 no profesionales + **2 portal**)
- **38 historias de usuario** (15 P0 + 14 P1 + 5 P2 + **4 portal P0/P1**)
- **12 módulos funcionales** (11 núcleo + **1 portal paciente**)
- **19 pantallas P0** (16 núcleo + 3 portal)
- **BD existente como target**: 103 tablas en 8 schemas, 673 pacientes y 779 estadías migradas
- **18 tablas nuevas** (14 MVP + 4 portal) sobre BD existente
- **6 vistas operativas** + **3 vistas portal** + **3 funciones REM** = 12 vistas/funcs instaladas
- **25 recursos FHIR R4** mapeados
- **12 path equations** implementables como constraints
- **5 integraciones externas** (DEIS, APS, gestión camas, DAU/SGH, laboratorio)
- **6 métricas de éxito** con línea base y meta
- **Ocupación actual: 22/25 cupos (88%)**

---

## Fuentes integradas

### Normativa
- DS N° 1/2022, Reglamento de Hospitalización Domiciliaria
- Decreto Exento N° 31/2024, Norma Técnica HODOM
- Norma Técnica HODOM 2024
- Manual REM 2026 (DEIS/MINSAL), Serie A21 Sección C
- Ley 20.584 (Derechos y Deberes), Ley 19.628 (Datos Personales)

### Modelos formales
- ERD Modelo Integrado HODOM (43 tablas, 4 capas)
- FHIR R4 Resource References (37 recursos)
- Modelo OPM v2.5 (ISO/PAS 19450, SD–SD10)
- Modelo Categórico v4.1 (6 categorías, 27 fuentes)

### Datos reales
- Documentación legacy Drive HODOM HSC (2661 archivos)
- Datos empíricos HSC 2023-2025 (1698 episodios, 1231 pacientes)
- Formularios reales HSC (Ingreso Enfermería, Ciclo Vital, Curaciones, Kinesiología, CI 2026, Postulación)
- **BD migrada viva** (`hodom-pg-v4`, puerto 5555) con 673 pacientes, 779 estadías

---

## Secuencia de implementación

### Portal Paciente/Cuidador (inmediato, paralelo a Fase 1)
MVP mínimo accesible por navegador (no requiere app nativa):
- HU-P1: Acceso con invitación (email + contraseña)
- HU-P2: Dashboard: resumen episodio + próximas visitas + teléfonos
- HU-P3: Indicaciones vigentes (medicamentos, O₂, curaciones)
- HU-P4: Documento de emergencia descargable (PE-14, DS 1/2022 art. 22)
- HU-P5: Reportar síntoma / solicitar visita
- HU-P6: Historial de visitas
- HU-P7: Mensajes del equipo HODOM

### Fase 1 — MVP (15 HU P0)
Episodio completo punta a punta + REM automático.
- Censo de pacientes activos
- Flujo de admisión (postulación → elegibilidad → CI → ingreso)
- Ficha clínica (ingreso enfermería, signos vitales, narrativa)
- Prescripción y plan terapéutico
- Programación de visitas
- Egreso + epicrisis + contrarreferencia
- Generación REM A21

### Fase 2 — Operación completa (12 HU P1)
Cupos tiempo real, briefing matinal, rutas dinámicas, curaciones, kinesiología, seguimiento post-egreso, interconsultas.

### Fase 3 — Complementos (4 HU P2)
Teleatención estructurada, gestión de recursos, ejecución de ruta, texto interconsulta.

---

## Cómo usar este paquete

1. Empezar por este **índice**
2. Presentar **11-resumen-ejecutivo.md** a dirección
3. Revisar **02-usuarios** y **03-historias-usuario** con equipo clínico
4. Usar **07-wireframes** para validar diseño de pantallas
5. **BD ya existe**: usar `hodom-pg-v4` (puerto 5555) con vistas/funcs REM instaladas
6. Usar **14-vistas-rem-bd-existente.sql** como referencia de vistas adaptadas
7. Usar **13-portal-paciente-mvp.md** para diseñar el portal
8. Seguir **05-backlog-mvp** como guía de implementación
