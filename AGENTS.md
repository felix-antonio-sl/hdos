# AGENTS.md

## Estado y alcance actual

Repositorio retirado y preservado como referencia histórica. El producto
continuable pertenece a `/home/felix/projects/hdapp`; dominio y decisiones a
`/home/felix/projects/hd-dt`. Trabaja aquí solo para consulta, preservación o
recuperación explícitamente solicitada. No reabras el desarrollo ni ejecutes
las recetas históricas por defecto. El contrato que sigue conserva su contexto
original y no concede autoridad clínica, institucional ni productiva nueva.

## Misión

Conservar los artefactos legados de base de datos HODOM como referencia histórica y técnica. Este repositorio no es el producto vigente ni una fuente para crear funcionalidad nueva.

## Entrada y alcance

- Lee `README.md`, `db/README.md` y `docs/README.md` según la tarea.
- Distingue esquema histórico, documentación explicativa y estado actual verificable.
- No supongas que una definición SQL histórica está desplegada o sigue siendo autoridad.
- Contrasta decisiones actuales con `../hd-dt` y la implementación vigente con `/home/felix/projects/hdapp` cuando corresponda.

## Reglas de trabajo

- Haz ediciones mínimas orientadas a preservación, aclaración o migración autorizada.
- No ejecutes SQL contra bases reales ni apliques migraciones sin autorización explícita y un destino exacto.
- No agregues pipelines, dashboards, servicios o dependencias a un repositorio documental legado.
- No incorpores PHI/PII, dumps, secretos ni credenciales.
- Conserva procedencia, fechas y contexto; no reescribas historia como estado presente.

## Verificación

- Comprueba sintaxis SQL solo con una herramienta local segura si la tarea lo exige; una validación de parseo no prueba compatibilidad con un servidor vivo.
- Verifica enlaces y referencias afectadas.
- Ejecuta `git diff --check` y declara cualquier comprobación operacional como `NOT_RUN` si no fue autorizada.
