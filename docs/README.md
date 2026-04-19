# Base de Conocimiento HODOM -- Hospital de San Carlos

Documentacion tecnica del sistema de Hospitalizacion Domiciliaria, Hospital de San Carlos Dr. Benicio Arzola Medina, Servicio de Salud Nuble.

---

## Especificaciones y documentos operativos

| Documento | Contenido |
|-----------|-----------|
| [Cartera de prestaciones HSC 2024](specs/cartera-prestaciones-hsc-2024.md) | Prestaciones clinicas por estamento, patologias incluidas, criterios de inclusion/exclusion |
| [Indicadores operacionales HODOM](specs/indicadores-operacionales-hodom.md) | KPIs de gestion: estancia media, ocupacion, reingresos, produccion por estamento |
| [Resumen normativo HODOM](specs/legal/resumen-normativo-hodom.md) | Marco legal completo: DS 1/2022, NT HD 2024, NT 243/2025, Ley 20.584, DS 41, Ley 21.668, BIP, FONASA, NGT 237 |
| [Estructura REM A21 C.1](specs/rem-a21-c1-estructura-datos.md) | Estructura de datos del Resumen Estadistico Mensual para hospitalizacion domiciliaria |
| [Manual REM 2026](specs/manual-rem-2026.md) | Referencia operativa del REM: definiciones, reglas de registro, validaciones |
| [Vistas operativas SQL](specs/vistas-operativas-hodom.sql) | Vistas SQL auxiliares para consultas operativas sobre la base de datos |

### Legal (fuentes primarias XML)

| Documento | Contenido |
|-----------|-----------|
| [DS 1 Reglamento HD (XML)](specs/legal/decreto-1-reglamento-hospitalizacion-domiciliaria.xml) | Fuente primaria XML del Decreto Supremo 1/2022 |
| [MCC Implementacion (XML)](specs/legal/implementacion-modalidad-cobertura-complementaria.xml) | Fuente primaria XML de la Modalidad de Cobertura Complementaria |

---

## Modelos

| Documento | Contenido |
|-----------|-----------|
| [Modelo integrado HODOM](models/modelo-integrado-hodom.md) | Descripcion principal del modelo de datos integrado: entidades, relaciones, reglas de negocio |
| [Modelo OPM normativo (OPL)](models/opl-hodom-normativo.md) | Modelo Object-Process en lenguaje OPL-ES conforme a ISO/PAS 19450. Fuentes: DS 1/2022, NT 2024 |
| [Mapeo FHIR R4](models/FHIR_R4_Resource_References.md) | Mapeo de recursos FHIR R4 al modelo de datos HODOM para interoperabilidad |
| [ERD modelo integrado](models/erd-modelo-integrado-hodom.html) | Diagrama ERD navegable del modelo integrado (HTML) |
| [ERD FHIR HD](models/fhir-erd-hospitalizacion-domiciliaria.html) | Vista ERD orientada a interoperabilidad FHIR (HTML) |
| [OPL canonico (import)](models/hodom-canonico-import.opl) | Archivo OPL importable del modelo canonico |
| [OPL normativo (import)](models/hodom-normativo.opl) | Archivo OPL importable del modelo normativo |

---

## Base de datos

| Documento | Contenido |
|-----------|-----------|
| [Schema PostgreSQL](../db/hodom-integrado-pg-v4.sql) | Dump PostgreSQL versionado -- artefacto principal de la base de datos |

---

## Documentacion hdos-app

Documentacion tecnica y de diseno de la aplicacion web en `/home/felix/projects/hdos-app/docs/`.

### Especificaciones de producto

| Documento | Contenido |
|-----------|-----------|
| [00 Indice](../../hdos-app/docs/specs/00-INDICE.md) | Indice maestro de especificaciones |
| [01 Diseno sistema operativo](../../hdos-app/docs/specs/01-diseno-sistema-operativo-hodom-hsc.md) | Arquitectura del sistema operativo HODOM HSC |
| [02 Usuarios del sistema](../../hdos-app/docs/specs/02-usuarios-sistema-hodom-hsc.md) | Perfiles de usuario y personas |
| [03 Historias de usuario](../../hdos-app/docs/specs/03-historias-usuario-hodom-hsc.md) | Historias de usuario priorizadas |
| [04 Roles y permisos](../../hdos-app/docs/specs/04-roles-permisos-hodom-hsc.md) | Matriz de roles, permisos y acceso |
| [05 Backlog MVP](../../hdos-app/docs/specs/05-backlog-mvp-hodom-hsc.md) | Backlog priorizado del MVP |
| [06 Arquitectura de informacion](../../hdos-app/docs/specs/06-arquitectura-informacion-hodom-hsc.md) | IA: navegacion, taxonomias, estructura de contenido |
| [07 Wireframes y flujos P0](../../hdos-app/docs/specs/07-wireframes-flujos-p0-hodom-hsc.md) | Wireframes y flujos de interaccion prioridad 0 |
| [08 Vista movil offline-first](../../hdos-app/docs/specs/08-vista-movil-offline-first.md) | Diseno mobile con soporte offline |
| [09 Modelo datos funcional MVP](../../hdos-app/docs/specs/09-modelo-datos-funcional-mvp-hodom-hsc.md) | Modelo de datos funcional para el MVP |
| [11 Resumen ejecutivo](../../hdos-app/docs/specs/11-resumen-ejecutivo.md) | Resumen ejecutivo del proyecto |
| [12 Analisis comparativo](../../hdos-app/docs/specs/12-analisis-comparativo-y-decisiones.md) | Comparacion de alternativas y decisiones de diseno |
| [13 Portal paciente MVP](../../hdos-app/docs/specs/13-portal-paciente-mvp.md) | Especificacion del portal de acceso para pacientes |
| [Ficha clinica v2](../../hdos-app/docs/specs/ficha-clinica-v2-spec.md) | Especificacion de la ficha clinica electronica v2 |

### Analisis y auditorias

| Documento | Contenido |
|-----------|-----------|
| [Arquitectura aplicacion](../../hdos-app/docs/analisis/2026-04-10-arquitectura-aplicacion-hdos-app.md) | Analisis de arquitectura de la aplicacion |
| [Informe baseline](../../hdos-app/docs/analisis/2026-04-10-informe-baseline-hdos-app.md) | Informe baseline del estado de la aplicacion |
| [Auditoria UX 360](../../hdos-app/docs/auditorias/ux-360-2026-04-08.md) | Auditoria completa de experiencia de usuario |
| [Auditoria UX healthcare](../../hdos-app/docs/auditorias/ux-healthcare-audit-2026-04-09.md) | Auditoria UX con enfoque en estandares de salud |
| [Factibilidad vision UX](../../hdos-app/docs/factibilidad-vision-ux.md) | Analisis de factibilidad de la vision UX |
| [Vision UX desde cero](../../hdos-app/docs/vision-ux-desde-cero.md) | Diseno de vision UX completa |
| [Modelo OPM completo](../../hdos-app/docs/opm-hodom-completo.md) | Modelo Object-Process completo del sistema |

---

## Convenciones

- La documentacion de este directorio explica la base de datos actual, el modelo de datos o su contexto normativo directo.
- Material historico u operacional retirado no forma parte del alcance del repositorio.
- Las fuentes normativas autoritativas estan en la KB centralizada (`/home/felix/kora/artifacts/knowledge/salud/hodom/normativa/`).
