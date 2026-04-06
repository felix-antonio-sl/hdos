# Auditoria Del Repositorio Y Narrativa Del Historial

Fecha: 2026-04-05

## Objetivo

Normalizar la estructura del workspace, explicitar la separacion entre contenido activo y legado, corregir referencias obsoletas al layout anterior y reconstruir la evolucion funcional real del repositorio a partir del historial de commits.

## Hallazgos principales

### 1. La estructura objetivo ya estaba insinuada, pero incompleta

El repositorio habia migrado buena parte de su contenido hacia una topologia mas coherente:

- `apps/` para puntos de entrada Streamlit
- `docs/` para documentacion
- `input/` para fuentes y correcciones manuales
- `output/` para artefactos generados

Sin embargo, esa reorganizacion coexistia con:

- wrappers y README con rutas absolutas de una maquina concreta
- referencias textuales al layout viejo (`streamlit_app.py`, `streamlit_admin_app.py`, archivos en la raiz)
- ausencia de README por dominio que distinguieran claramente contenido activo versus legado

### 2. La mayor inconsistencia real no era semantica sino operacional

El codigo principal ya trabajaba casi por completo sobre rutas relativas al repositorio. Los problemas mas persistentes estaban en:

- scripts auxiliares con defaults clavados a `/Users/.../Downloads`
- wrappers de ejecucion mezclando `zsh`, `bash`, `cd` absolutos y relativos
- README generados por los pipelines con comandos no portables
- documentacion operativa sin frontera explicita entre estado vigente y bitacora historica

### 3. El historial muestra varias oleadas funcionales, no una secuencia lineal limpia

Los commits no siguen una narrativa estrictamente modular; alternan:

- construccion de pipeline
- correcciones manuales de pacientes
- ajustes de dashboard
- estabilizacion REM
- experimentos con SGH y posterior rollback

Por eso conviene reagruparlos en unidades semanticas en lugar de leerlos solo cronologicamente.

## Normalizacion aplicada

### Estructura y documentacion

- Se consolidaron README de dominio para `docs/`, `input/`, `output/` y `documentacion-legacy/`.
- El `README.md` raiz ahora describe la topologia activa y las convenciones del workspace.
- La documentacion operativa de dashboards se alinea al layout actual y a comandos portables.

### Portabilidad

- Los wrappers de Streamlit y del refresh usan `cd "$(dirname "$0")/.."` en lugar de rutas absolutas.
- Los scripts con defaults locales pasan a resolver `~/Downloads` via `Path.home()` y a referenciar el repo via `Path(__file__)`.
- Los README generados por pipeline dejaron de incrustar rutas absolutas del workspace.

### Frontera entre activo e historico

- `docs/sessions/` queda explicitamente como bitacora historica.
- `documentacion-legacy/` queda formalizada como respaldo no estable.
- La documentacion activa debe hablar del layout vigente; las referencias antiguas quedan encapsuladas como registro historico.

## Riesgos residuales

### 1. Artefactos generados con provenance absoluto

Varios CSV ya materializados en `output/` conservan rutas absolutas en columnas de procedencia. No se reescribieron en esta normalizacion para evitar alterar outputs de datos sin una regeneracion controlada completa.

### 2. Utilitarios clinicos siguen dependiendo de material externo

Aunque las rutas por defecto ya no estan clavadas a una maquina especifica, algunos utilitarios siguen asumiendo archivos de trabajo en `~/Downloads` o en `documentacion-legacy/`. Eso es coherente con su naturaleza exploratoria, pero no equivale a una interfaz estable.

## Narrativa funcional del historial

### Unidad 1. Fundacion del workspace y primer modelo de datos

Commits:

- `5f7e955` Initial commit: workspace hdos - Hospitalización Domiciliaria
- `9957652` Agregar esquema de datos para ingresos en hospitalización domiciliaria
- `eb93b16` Refactor code structure for improved readability and maintainability

Lectura funcional:

Se crea el workspace y se formaliza un primer lenguaje comun para el problema: ingesta de hospitalizacion domiciliaria, estructura de datos inicial y una primera limpieza de organizacion. Esta etapa todavia es fundacional; prepara el terreno para que aparezca un pipeline mas robusto.

### Unidad 2. Diseno del modelo canonico y dashboard administrativo

Commits:

- `12fcf01`
- `7d5e0c8`
- `7f50810`
- `f57029c`
- `28bbd32`
- `4e4914f`
- `f44e6f2`

Lectura funcional:

Se pasa de una idea de consolidacion a una arquitectura implementable: specs, plan de trabajo, tests, constructor canonico y refactor del dashboard administrativo para consumir la nueva capa. El cambio central es conceptual: el repo deja de ser solo una migracion CSV y empieza a comportarse como un sistema con capa operativa canonica.

### Unidad 3. Cierre manual de identidad y estabilizacion de estadias

Commits:

- `e718a10`
- `9609e63`
- `b747363`
- `0a61c59`
- `fa49347`
- `a5020b5`
- `bb6ea06`
- `cb8048c`
- `1b6f9ae`
- `3008d7f`
- `f348cfe`
- `65b0497`

Lectura funcional:

Aqui aparece la evolucion funcional mas importante del proyecto: la capa canonica deja de depender solo de deduplicacion tecnica y empieza a absorber criterio de negocio. Se integran correcciones manuales tempranas, se agregan pacientes faltantes, se reparan fechas clave y el consolidador aprende a fusionar estadias adyacentes y cruces por RUT/ingreso. El resultado es una nocion mucho mas realista de hospitalizacion.

### Unidad 4. Ajuste de explotacion analitica y superficie REM

Commits:

- `82a3f2c`
- `d11b577`
- `e481237`
- `b3bb898`
- `f746acd`
- `8c7c924`
- `769471f`
- `8896f7e`
- `25cb315`
- `80feae3`
- `f26c3a7`
- `09e0ec2`
- `80944aa`
- `8b5913e`
- `b55b217`

Lectura funcional:

La prioridad pasa desde consolidar datos a hacerlos explotables. El dashboard administrativo gana rendimiento y UX; el REM se vuelve mas fino en filtros y reglas; y una larga cola de correcciones nominales aterriza edad, sexo, fechas y estados clinicos. Esta etapa convierte una base coherente en una base utilizable para gestion y reporte.

### Unidad 5. Incursion SGH, rollback y rediseno estricto de hospitalizaciones

Commits:

- `f9d95ec`
- `7780a80`
- `54c48b7`
- `c80b2ef`
- `7d8644b`

Lectura funcional:

El historial muestra un experimento claro: incorporar SGH como fuente autoritativa. La primera version contamina correcciones previas y se revierte. A partir de ese aprendizaje, se reconstruye una via mas estricta para ingresos y egresos minimos, con matching guiado por el canonico y limpieza SGH. El ultimo commit cierra la brecha agregando pacientes faltantes al maestro de identidad. Esta unidad marca el paso desde reconciliacion amplia a una modelacion de hospitalizacion estricta orientada a migracion nominal.

## Secuencia logica recomendada

Si hubiera que contar la evolucion del repositorio como producto y no como cronologia cruda, la secuencia correcta seria:

1. Fundar workspace y modelar el dominio.
2. Construir pipeline intermedio y capa canonica verificable.
3. Volver operativa esa capa via dashboard administrativo.
4. Inyectar correcciones manuales y consolidar estadias reales.
5. Endurecer REM e indicadores administrativos.
6. Incorporar fuentes hospitalarias estrictas y cerrar identidad residual.

## Conclusiones

El repositorio ya habia convergido hacia una arquitectura razonable, pero seguia comunicando dos repositorios a la vez: uno nuevo, ordenado, y otro viejo, implicito en rutas, nombres y notas historicas. La normalizacion actual no cambia la intencion funcional del sistema; la vuelve legible, portable y semanticamente consistente.
