# Handoff app censo calidad datos HODOM — 2026-05-26

## Estado actual

Se reviso la pantalla `/censo` de `hdos-app` luego de observar edades vacias (`a`), una edad implausible (`0a`), diagnosticos vacios y una columna `Alertas` que en realidad estaba mostrando tambien dias sin visita.

La fuente de la pantalla es `operational.v_tablero_coordinacion`, construida desde `clinical.estadia` y `clinical.paciente`. Para los casos visibles en el screenshot, la base confirmo:

| Caso | Hallazgo core | Respaldo INGRESOS 2026 |
| --- | --- | --- |
| Elisa Rodriguez Salinas | `fecha_nacimiento` nula | RUT con edad 84 y diagnostico ACV/ITU |
| Carmen Lema Palma | `fecha_nacimiento` nula y diagnostico activo vacio | RUT con edad 56 y diagnostico fractura acetabulo |
| Nestor Riquelme Bascur | diagnostico activo vacio | RUT con diagnostico sindrome intestino corto |
| Maria Labrin Acuna | `fecha_nacimiento = 2026-04-20`, edad core 0 | RUT con edad 77 y flag `EDAD_VS_NACIMIENTO_DISCREPANCIA` |

## Decisiones

- No se mutaron datos clinicos durante este corte. El cambio aplicado es de presentacion/consulta operativa en `hdos-app`.
- Para `/censo`, se usa `staging.hodom_ingreso_2026` como respaldo por RUT solo cuando el dato core falta o es implausible:
  - edad core valida: `1..120`;
  - si edad core falta/implausible, usar edad de INGRESOS activa;
  - diagnostico core no vacio prevalece;
  - si diagnostico core esta vacio, usar `diagnostico_egreso` de INGRESOS activa.
- El respaldo desde INGRESOS se marca con `*` en la edad para indicar que el dato fue completado desde fuente operativa y no debe interpretarse como correccion humana definitiva.
- La columna `Alertas` se renombro a `Riesgo` porque combina alertas activas y dias sin visita.
- La capitalizacion de nombres ahora usa regex Unicode para no dejar `AcuÑA` / `MuÑOz`.

## Artefactos modificados

Repo `hdos-app`:

- `src/lib/format.ts`
  - `titleCase` Unicode-aware.
  - `formatAge` para evitar renderizados tipo `a` cuando la edad es nula.
- `src/app/(app)/censo/page.tsx`
  - `LEFT JOIN LATERAL` a `staging.hodom_ingreso_2026` por `rut_normalizado`.
  - `edad_operativa` y `diagnostico_operativo`.
  - columna `Riesgo` con chips `N alertas`, `Sin visita Nd` o `Sin alerta`.
- `src/app/(app)/censo/export-button.tsx`
  - CSV tolera valores nulos.
- `src/app/(app)/ficha/[stayId]/page.tsx`
  - cabecera de ficha usa edad/diagnostico operativo desde INGRESOS cuando el core es insuficiente.

Repo `hdos`:

- `docs/specs/metricas-hodom/handoff-app-censo-calidad-datos-2026-05-26.md`

## Verificacion

- Consulta SQL de control mostro los valores operativos esperados:
  - Elisa: edad operativa 84.
  - Carmen: edad operativa 56, diagnostico operativo `FRACTURA DEL ACETABULO`.
  - Nestor: diagnostico operativo `SINDROME INTESTINO CORTO ( NTP)`.
  - Maria Labrin: edad operativa 77 aunque core calcula 0.
- `npm run build` en `/home/felix/projects/hdos-app` paso correctamente despues del ajuste final de censo/ficha.

## Pendientes

1. Revisar si corresponde una migracion DB posterior para corregir core, no solo presentacion:
   - completar `clinical.paciente.fecha_nacimiento` y `sexo` desde INGRESOS cuando RUT sea unico y no haya flags de calidad;
   - completar `clinical.estadia.diagnostico_principal` para estadias activas con diagnostico core vacio y respaldo INGRESOS por RUT;
   - no escribir fecha de nacimiento estimada para Maria Labrin: el DOB fuente esta marcado como discrepante, aunque la edad 77 sea operacionalmente usable.
2. Considerar mover la logica de `edad_operativa` / `diagnostico_operativo` a una vista DB normativa si se usara en mas pantallas.
3. Validar visualmente `/censo` y una ficha afectada en app desplegada despues del push/deploy.

## Supuestos

- `staging.hodom_ingreso_2026` existe en la base productiva porque es parte del cierre de migracion 2026.
- RUT es ancla fuerte para respaldo operativo de INGRESOS, aun cuando el nombre tenga variaciones.
- `diagnostico_egreso` en filas `ACTIVO` de INGRESOS representa diagnostico operativo actual de la planilla, aunque el nombre del campo venga heredado de la fuente.

## Riesgos

- La app queda acoplada a `staging.hodom_ingreso_2026` para `/censo` y cabecera de ficha. Si se despliega contra una DB sin staging, esas rutas fallaran.
- El `*` es solo una pista visual; no reemplaza una auditoria de datos ni una decision humana de correccion core.
- Maria Labrin sigue teniendo un DOB core incorrecto; la pantalla lo compensa con edad de INGRESOS, pero la deuda de datos permanece.

## Prompt de continuacion

Continuar desde `docs/specs/metricas-hodom/handoff-app-censo-calidad-datos-2026-05-26.md`.

Prioridad:

1. Revisar despliegue/app en `/censo` y fichas afectadas.
2. Proxima mejora: migracion DB acotada para completar core desde INGRESOS solo con RUT unico, sin flags de calidad, y dejando Maria Labrin como pendiente por discrepancia edad/DOB.
3. Considerar vista normativa DB para `edad_operativa` y `diagnostico_operativo` si se reutiliza fuera de censo/ficha.
