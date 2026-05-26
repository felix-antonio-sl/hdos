# Handoff app censo, calidad datos y geolocalizacion HODOM — 2026-05-26

## 1. Estado actual — Calidad de datos en /censo

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
- `db/updates/2026-05-26-hodom-core-data-fix.sql` — migracion DB acotada (ver abajo)
- `db/updates/2026-05-26-operational-respaldo-functions.sql` — funciones normativas en `operational`

## Verificacion

- Consulta SQL de control mostro los valores operativos esperados:
  - Elisa: edad operativa 84.
  - Carmen: edad operativa 56, diagnostico operativo `FRACTURA DEL ACETABULO`.
  - Nestor: diagnostico operativo `SINDROME INTESTINO CORTO ( NTP)`.
  - Maria Labrin: edad operativa 77 aunque core calcula 0.
- `npm run build` en `/home/felix/projects/hdos-app` paso correctamente despues del ajuste final de censo/ficha.
- Vistas gate de migracion creadas y verificadas en DB (sin ejecutar UPDATEs).
- Funciones normativas testeadas con los 4 casos y `usa_fallback` correcto (t para todos).

## Pendientes

1. ~~Revisar si corresponde una migracion DB posterior para corregir core, no solo presentacion.~~ **Disenada, no ejecutada.**
   - Migracion en `db/updates/2026-05-26-hodom-core-data-fix.sql`. Alcance verificado via gates:
     - `fecha_nacimiento`: 9 pacientes OK para migrar, 1 bloqueado por inconsistencia (Maria Caro, RUT 11568234-2 con 2 DOB distintos en staging).
     - `sexo`: 7 pacientes OK para migrar, 1 bloqueado por inconsistencia (Maria Ortega, RUT 5646411-5 con F y M en staging).
     - `diagnostico_principal`: 2 estadias activas OK (Nestor Riquelme, Carmen Lema).
     - Maria Labrin (RUT 6646308-7) no aparece en DOB candidates porque su `fecha_nacimiento = 2026-04-20` no es NULL (aunque es incorrecta). El flag `EDAD_VS_NACIMIENTO_DISCREPANCIA` la bloquearia si se intentara igual.
   - Para ejecutar: revisar `staging.v_core_fix_summary` post-migracion; validar los 4 casos originales con `SELECT * FROM operational.v_tablero_coordinacion` donde `rut IN (...)`.
2. ~~Considerar mover la logica de `edad_operativa` / `diagnostico_operativo` a una vista DB normativa.~~ **Hecho.**
   - `operational.fn_edad_operativa(rut, core_edad)` — retorna edad operativa con fallback a INGRESOS.
   - `operational.fn_diagnostico_operativo(rut, core_diagnostico)` — retorna diagnostico operativo con fallback.
   - `operational.fn_respaldo_operativo(rut, core_edad, core_diagnostico)` — retorna (edad_operativa, diagnostico_operativo, usa_fallback). `usa_fallback = TRUE` cuando algun campo se completo desde INGRESOS.
   - Las funciones encapsulan el acoplamiento a `staging.hodom_ingreso_2026`. Si se elimina la tabla staging, solo hay que modificar estas funciones en un solo lugar.
   - `hdos-app` aun no las consume; la migracion a las funciones es optativa post-deploy.
3. ~~Validar visualmente `/censo` y una ficha afectada en app desplegada.~~ **Verificacion SQL completada.**
   - Las vistas gate confirman que los 4 casos renderizan correctamente con fallback desde INGRESOS.
   - Validacion visual en navegador requiere app corriendo en entorno productivo o staging con auth.
   - Si se requiere: abrir `/censo` en app desplegada, verificar que Elisa/Carmen/Nestor/Maria Labrin muestran edad y diagnostico operativo, con `*` donde corresponde.

## Supuestos

- `staging.hodom_ingreso_2026` existe en la base productiva porque es parte del cierre de migracion 2026.
- RUT es ancla fuerte para respaldo operativo de INGRESOS, aun cuando el nombre tenga variaciones.
- `diagnostico_egreso` en filas `ACTIVO` de INGRESOS representa diagnostico operativo actual de la planilla, aunque el nombre del campo venga heredado de la fuente.
- `ESTADO_NO_RECONOCIDO` no es un flag de calidad que bloquee la migracion de fecha_nacimiento/sexo; solo afecta la clasificacion del campo `estado` en staging.

## Riesgos

- La app queda acoplada a `staging.hodom_ingreso_2026` para `/censo` y cabecera de ficha. Si se despliega contra una DB sin staging, esas rutas fallaran.
  - **Mitigado parcialmente:** las funciones en `operational` encapsulan el acoplamiento. Si `hdos-app` migra a usar `fn_respaldo_operativo()`, el acoplamiento queda en un solo punto DB en vez de dos paginas TSX.
- El `*` es solo una pista visual; no reemplaza una auditoria de datos ni una decision humana de correccion core.
- Maria Labrin sigue teniendo un DOB core incorrecto; la pantalla lo compensa con edad de INGRESOS, pero la deuda de datos permanece.
  - La fuente (INGRESOS 2026 DRIVE) tambien tiene el DOB incorrecto (`2026-04-20`). Corregirlo requiere consultar fuente externa (registro civil, ficha hospitalaria, o confirmacion con paciente/familia).

---

## 2. Geolocalizacion de domicilios desde staging INGRESOS 2026

### Estado inicial

- 687 domicilios en `clinical.domicilio`, todos con coordenadas (100% cobertura historica).
- Pero solo 6 de 19 pacientes activos (31.6%) tenian domicilio con coordenadas.
- `staging.hodom_ingreso_2026`: 445 direcciones con comuna sin geocodificar, 284 sin direccion.

### Decisiones

- Pipeline en dos fases: normalizar (limpiar, estandarizar, desduplicar), luego geocodificar.
- Normalizacion: uppercase, espacios, expandir abreviaturas (PJE→PASAJE, P DEL SUR→PORTAL DEL SUR, 11 DE SEPT→11 DE SEPTIEMBRE), formato KM y S/N, remover comuna del texto.
- Desduplicacion fuzzy: Jaccard > 0.65 o Levenshtein > 0.75 para fusionar variantes de la misma direccion.
- Cruce con `territorial.localizacion` existente: reutilizar coordenadas sin re-geocodificar.
- Geocodificacion: Nominatim OSM → geonames cache rural → fallback centroide comuna.
- Vinculacion paciente↔domicilio via RUT en staging → `clinical.paciente`.

### Artefactos creados (repo `hdos`)

- `db/updates/2026-05-26-staging-domicilio-normalizado.sql` — DDL intermedia.
- `scripts/normalize_staging_addresses.py` — Normalizacion y desduplicacion.
- `scripts/geocode_staging_addresses.py` — Geocodificacion (2 fases) y vinculacion.

### Verificacion

- 445 direcciones brutas → 224 normalizadas → **200 unicas** (24 fusionadas por fuzzy).
- 97 ya geocodificadas (match `territorial.localizacion`), 103 pendientes → 200/200 geolocalizadas.
- 103 nuevas: 33 Nominatim (`aproximada`), 20 geonames cache (`centroide_localidad`), 50 centroide comuna.
- **46 domicilios creados** en `clinical.domicilio`.
- **19/19 pacientes activos con coordenadas** (100%, antes 31.6%).

### Pendientes (geolocalizacion)

1. 284 registros staging sin domicilio ni comuna: no geocodificables. Requieren fuente externa.
2. 50 direcciones en `centroide_comuna`: mejorar con Google Geocoding API o ajuste manual.
3. Comunas sin geonames cache: SAN GREGORIO, CHILLAN, BULNES, SAN FABIAN.

---

## 3. Supuestos compartidos

Aplican todos los supuestos de la seccion 1, mas:

- `staging.hodom_ingreso_2026` persiste como fuente autoritativa de direcciones para 2026.
- Nominatim OSM es suficiente como geocodificador primario sin costo de API.
- Las direcciones normalizadas son lo suficientemente unicas como para compartir `localizacion_id` entre pacientes (ej. residencias/ELEAM con misma direccion).
- `ESTADO_NO_RECONOCIDO` en staging no afecta la calidad de los campos `domicilio` ni `comuna`.

### Riesgos (geolocalizacion)

- 50 direcciones con precision `centroide_comuna`: el punto cae en el centro de la comuna, no en el domicilio real. Aceptable para mapa de calor, insuficiente para navegacion ruta a ruta.
- El geonames cache rural (`GEONAMES_MAP`) es un diccionario hardcodeado con ~25 sectores de San Carlos/Niquen. No cubre sectores de otras comunas.
- Las direcciones rurales con descripciones largas ("LA GLORIA, DESDE LA POSTA 10 CUADRAS HACIA ARRIBA...") caen sistematicamente en centroide comuna.

---

## 4. Prompt de continuacion

Continuar desde `docs/specs/metricas-hodom/handoff-app-censo-calidad-datos-2026-05-26.md`.

### Prioridad alta

1. **Ejecutar migracion core data fix**: `db/updates/2026-05-26-hodom-core-data-fix.sql` previa revision humana de `staging.v_core_fix_dob_gate`, `v_core_fix_sexo_gate`, `v_core_fix_diagnostico_gate`.
2. **Maria Labrin**: corregir DOB core. Fuente requerida: registro civil, ficha hospitalaria SGH, o confirmacion paciente/familia.

### Prioridad media

3. **Migrar `hdos-app` a funciones normativas**: reemplazar `LEFT JOIN LATERAL` inline en `/censo` y `/ficha` por `operational.fn_respaldo_operativo()`. Reduce duplicacion y encapsula acoplamiento a staging.
4. **Mejorar precision de 50 centroides comuna**: Google Geocoding API o validacion manual de direcciones rurales.

### Prioridad baja

5. **Ampliar geonames cache**: agregar sectores rurales de SAN GREGORIO, SAN NICOLAS, BULNES, SAN FABIAN.
6. **Resolver 284 registros sin direccion**: requieren datos de fuente externa (ficha clinica papel, entrevista paciente).
