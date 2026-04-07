# Paquete de Diseño — Sistema Operativo HODOM HSC

Hospital de San Carlos Dr. Benicio Arzola Medina
Generado: 2026-04-07

---

## Contenido

| # | Archivo | Descripción |
|---|---------|-------------|
| 1 | `01-diseno-sistema-operativo-hodom-hsc.md` | Diseño general: usuarios, necesidades, módulos, flujos, teleatención, recomendación arquitectónica |
| 2 | `02-roles-permisos-hodom-hsc.md` | Matriz RBAC: 14 roles × 7 módulos con permisos CRUD+X, segregación de datos sensibles |
| 3 | `03-backlog-mvp-hodom-hsc.md` | Backlog priorizado MoSCoW en 3 fases: 25 capacidades MVP, métricas de éxito, dependencias |
| 4 | `04-blueprint-pantallas-hodom-hsc.md` | Wireframes ASCII de 5 pantallas + formulario de visita móvil offline-first |
| 5 | `05-modelo-datos-funcional-mvp-hodom-hsc.md` | Modelo de datos MVP: 14 tablas, 4 vistas, 3 funciones REM, DDL PostgreSQL |
| 6 | `06-hodom-mvp.sql` | DDL ejecutable en PostgreSQL (extraído del modelo de datos) |
| 7 | `07-resumen-ejecutivo.md` | Resumen ejecutivo de una página para presentación a dirección |

## Fuentes utilizadas

- DS N° 1/2022, Reglamento de Hospitalización Domiciliaria
- Decreto Exento N° 31/2024, Norma Técnica HODOM
- Norma Técnica HODOM 2024 (16 páginas)
- Manual REM 2026 (DEIS/MINSAL), Serie A21 Sección C
- Modelo OPM HODOM v2.5 (ISO/PAS 19450)
- Modelo Categórico HODOM v4.1
- Modelo Integrado HODOM (FHIR + Logística + OPM)
- Documentación legacy Drive HODOM HSC (2661 archivos)
- Datos operacionales reales 2023-2026

## Cómo usar

1. **Presentación**: compartir `07-resumen-ejecutivo.md` con dirección y equipo.
2. **Validación**: revisar `01-diseno` y `04-blueprint` con coordinadora y equipo clínico.
3. **Implementación**: usar `06-hodom-mvp.sql` como base de datos inicial.
4. **Desarrollo**: seguir `03-backlog-mvp` como guía de prioridades.
