

tengo que migrar estos datos a una nueva base de datos

hdos






Mover a worktree

Confirmación




quedemos solo con lo que dice el rem. recuerda que este es un segundo dashboard. en resumen tendremos un dashboard enfocado en la migración y este nuevo a lo administrativo y estadístico hospitalario.



Procesado durante 4m 25s
Dejé un segundo dashboard separado del de migración.

Nuevo dashboard

streamlit_admin_app.py
Qué hace

está enfocado sólo en:
hospitalizaciones
pacientes
territorio/establecimientos
indicadores administrativos
REM A21/C1
no muestra:
issues
colas de revisión
conflictos de migración
semántica técnica del saneamiento
Vistas

Resumen
Hospitalizaciones
Pacientes
REM A21/C1
Territorio
Metodología
Características

listado de hospitalizaciones del período
vista de ingresos, egresos y activos
listado de pacientes y sus episodios
cálculo REM administrativo sobre los mismos datos enriquecidos
mapa territorial con localidades/episodios
explicación metodológica separada del dashboard de migración
Archivos añadidos

streamlit_admin_app.py
docs/dashboards/streamlit-admin-dashboard.md
run_streamlit_admin_dashboard.sh
Cómo correrlo

cd /Users/felixsanhueza/Developer/_workspaces/hdos
./scripts/run_streamlit_admin_dashboard.sh
o directo:

.venv/bin/streamlit run streamlit_admin_app.py
Validación

sintaxis OK:
python3 -m py_compile streamlit_admin_app.py
smoke test local OK:
respondió HTTP 200 en http://localhost:8503
Con esto ya tienes:

un dashboard para migración y saneamiento
y otro separado para uso institucional / administrativo / REM
Si quieres, el siguiente paso es pulir visualmente el dashboard administrativo para que se vea más “institucional hospitalario” y menos técnico.


3 archivos modificados
+632
-0
Deshacer
docs/dashboards/streamlit-admin-dashboard.md
scripts/run_streamlit_admin_dashboard.sh
streamlit_admin_app.py
Archivo adjunto del usuario
no se ve nada acá . desde rem si selecciono los ingresos, egresos, etc, debo poder acceder al listado que corresponde para verificar



Procesado durante 1m 21s
Corregí las dos cosas que estabas pidiendo en el dashboard administrativo:

1. Legibilidad del sidebar

El problema era CSS demasiado agresivo en el sidebar.
En streamlit_admin_app.py dejé:
labels y texto del sidebar en claro
valores dentro de inputs/select/date en oscuro
Eso evita el efecto “no se ve nada” del screenshot.
2. Verificación nominal desde REM

En el tab REM A21/C1 ahora agregué una sección:
Verificación nominal del REM
Puedes elegir el componente:
ingresos
personas_atendidas
dias_persona
altas
reingresos_hospitalizacion
fallecidos_total_inferidos
Y abajo aparece el listado correspondiente con columnas nominales para verificar:
episodio
paciente
RUT
sexo
edad
fechas
overlap
servicio
previsión
comuna
establecimiento
diagnóstico
motivo de egreso
origen derivación inferido
También dejé botón de descarga CSV por componente REM.
Lógica exacta de esa verificación

ingresos: episodios con ingreso_in_period = True
personas_atendidas: pacientes únicos con is_active_in_period = True
dias_persona: episodios con overlap_days > 0
altas: episodios con egreso_in_period = True y outcome = alta
reingresos_hospitalizacion: episodios con egreso_in_period = True y outcome = reingreso_hospitalizacion
fallecidos_total_inferidos: episodios con egreso_in_period = True y outcome = fallecido
Archivo

streamlit_admin_app.py
Validación

sintaxis OK:
python3 -m py_compile streamlit_admin_app.py
Cómo correr

cd /Users/felixsanhueza/Developer/_workspaces/hdos
./scripts/run_streamlit_admin_dashboard.sh
Si quieres, el siguiente paso en este dashboard es mejorar aún más la semántica REM:

quitar reingresos_hospitalizacion si no te convence como métrica oficial
o renombrarlo claramente como “reingreso por motivo textual registrado” para evitar ambigüedad.

1 archivo modificado
Deshacer
streamlit_admin_app.py
Archivo adjunto del usuario
Archivo adjunto del usuario
porque en la fecha 1 a 30 de septiembre 2029 salen filtrados estas hospitalizaciones fuera de rango ?



Procesado durante 3m 58s
Corregí eso en el dashboard administrativo.

Qué hice

Arreglé la legibilidad del sidebar:
inputs/selects/date inputs ahora tienen fondo claro y texto oscuro
labels y textos del sidebar se mantienen claros
Separé la semántica temporal del dashboard administrativo:
listas nominales: usan evento en rango
REM: usa solapamiento del episodio con el período
En el tab REM A21/C1:
mantuve el cálculo REM
agregué el listado nominal verificable por componente
y ese listado sale de la misma lógica que calcula la tabla REM
Los componentes verificables son:
ingresos
personas_atendidas
dias_persona
altas
reingresos_hospitalizacion
fallecidos_total_inferidos
Importante
Con esta corrección:

si en el dashboard administrativo eliges rango 2025-09-01 a 2025-09-30
las tablas administrativas ya no deberían arrastrar episodios 2023/2024 sólo por estar abiertos
pero el tab REM sí puede seguir usando solapamiento, porque esa es la semántica correcta para REM
Archivo

streamlit_admin_app.py
Validación

sintaxis OK:
python3 -m py_compile streamlit_admin_app.py
Cómo correr

cd /Users/felixsanhueza/Developer/_workspaces/hdos
./scripts/run_streamlit_admin_dashboard.sh
Ahora sí, en ese dashboard:

las listas administrativas y el REM no comparten exactamente la misma semántica temporal
y eso era necesario para que no vieras “hospitalizaciones fuera de rango” en el listado nominal mientras el REM sigue siendo correcto metodológicamente
Si quieres, el siguiente paso es revisar contigo un caso puntual de septiembre en el dashboard administrativo para confirmar que ya quedó bien.


1 archivo modificado
Deshacer
streamlit_admin_app.py
Archivo adjunto del usuario
pot que sale duplicdos ?  la de martin colliopor ejemplo?



Procesado durante 42s
Sí, en este caso sí es un duplicado lógico de hospitalización.

Para MARTIN COLLIO ANTIO encontré dos episodios distintos en episode_master.csv:

ep_b9849ffdade4f04c

fuente: INGRESOS(2).csv, fila 471
ingreso: 2025-09-29
egreso: 2025-10-06
diagnóstico: ITU
ep_a06ea35e69a8e4c7

fuente: EGRESOS OCTUBRE.csv, fila 13
ingreso: 2025-09-29
egreso: 2025-10-06
diagnóstico: CONVULSIONES
Mismo paciente, mismo rango de fechas, mismo estado, mismo servicio, mismo motivo de egreso. Lo único relevante que cambió fue el diagnóstico y algunos campos accesorios.

Por qué no se deduplicó
Porque el pipeline actual arma el dedupe_key usando también el diagnóstico. Entonces:

si dos fuentes describen la misma hospitalización
pero con diagnóstico distinto o redactado distinto
quedan como dos episodios separados
Eso explica por qué aparece duplicado en el dashboard administrativo.

En este caso concreto
Lo más probable es que:

INGRESOS(2).csv y EGRESOS OCTUBRE.csv
estén representando la misma hospitalización
pero una planilla la describe desde la mirada de ingreso y la otra desde egreso/cierre
Conclusión
No es que el dashboard esté repitiendo mal una misma fila.
Es que la capa enriquecida ya trae dos episodios distintos porque la deduplicación fue demasiado estricta para este tipo de caso.

Qué hay que hacer
Necesitamos una segunda capa de consolidación de hospitalización, algo como:

stay_key = paciente + fecha_ingreso + fecha_egreso
y luego decidir cuál diagnóstico / fuente gana dentro de ese mismo stay
Es decir:

mantener trazabilidad de ambos registros fuente
pero mostrar en el dashboard administrativo una sola hospitalización
Si quieres, lo siguiente que hago es justamente eso:

introducir una noción de hospitalization_stay o encounter_group
consolidar duplicados lógicos como este
y hacer que el dashboard administrativo muestre la hospitalización consolidada, no los dos episodios crudos.

ok. vamos con eso



Procesado durante 1m 48s
Ese duplicado de MARTIN COLLIO ANTIO venía de dos episodios fuente distintos que representaban la misma hospitalización lógica:

uno desde INGRESOS(2).csv
otro desde EGRESOS OCTUBRE.csv
Mismo paciente, mismas fechas, mismo servicio y mismo motivo de egreso. Solo cambiaban algunos atributos como el diagnóstico.

Qué hice
En el dashboard administrativo streamlit_admin_app.py ya no estoy mostrando directamente episode_master para las vistas administrativas principales, sino una capa derivada de hospitalización consolidada (stays):

agrupo por:
patient_id
fecha_ingreso
fecha_egreso
si ambas fechas existen, eso define una sola estancia/hospitalización
si no, el episodio queda solo
para cada stay:
elijo una fila representante
agrego:
source_episode_count
source_episode_ids
junto diagnósticos distintos en un mismo texto cuando hay más de una fuente
Resultado esperado
En el dashboard administrativo:

ya no deberías ver a MARTIN COLLIO ANTIO duplicado como dos hospitalizaciones distintas
deberías ver una sola hospitalización consolidada
y además podrás identificar que venía de más de una fuente con source_episode_count
Importante
Esto lo hice solo en el dashboard administrativo, que es donde tiene sentido operacional.
No eliminé esos duplicados lógicos de la capa enriquecida base, porque todavía sirven para trazabilidad de migración.

También corregí la semántica temporal

listas administrativas: usan evento en rango
REM: usa solapamiento en rango
Así que:

el problema de “hospitalizaciones fuera de rango” en listados administrativos también queda corregido conceptualmente
Archivo

streamlit_admin_app.py
Validación

sintaxis OK:
python3 -m py_compile streamlit_admin_app.py
Si quieres, el siguiente paso es hacer visible esa consolidación en la UI, por ejemplo:

renombrar Hospitalizaciones a Hospitalizaciones consolidadas
mostrar una columna fuentes
permitir abrir el detalle de source_episode_ids
Eso ayudaría a que la semántica quede aún más clara para estadística y gestión.


1 archivo modificado
Deshacer
streamlit_admin_app.py
Archivo adjunto del usuario
(Sin contenido)

Procesado durante 25s
Corregido.

El problema era que streamlit_admin_app.py intentaba importar migrate_hodom_csv desde la raíz, pero ese módulo vive en:

scripts/migrate_hodom_csv.py
Ya lo arreglé agregando el directorio scripts al sys.path antes del import.

Validación

sintaxis OK:
python3 -m py_compile streamlit_admin_app.py
Qué hacer ahora
Vuelve a levantar el dashboard administrativo:

cd /Users/felixsanhueza/Developer/_workspaces/hdos
./scripts/run_streamlit_admin_dashboard.sh
o:

.venv/bin/streamlit run streamlit_admin_app.py
Si aparece otro error al arrancar, sigo corrigiéndolo sobre la marcha.


1 archivo modificado
Deshacer
streamlit_admin_app.py
de los pacientes rescatados entre octubre y dieiembre 2025 no tenemos fechas de egreso y son muchos menos de los reales. revisa ese proceso de rescate y corrige

Voy a auditar específicamente el rescate de octubre-diciembre 2025: revisaré qué hojas/filas de la planilla de altas se están parseando, cuántos rescates salen por formulario vs por altas y por qué se están quedando sin fecha_egreso. Luego corrijo la lógica y regenero la capa enriquecida.

Se ejecutó python3 - <<'PY' import openpyxl wb=openpyxl.load_workbook('/Users/felixsanhueza/Downloads/PLANILLA DE ALTAS 26.xlsx', read_only=True, data_only=True) for name in wb.sheetnames[15:45]: print(name) PY


Se ejecutó .venv/bin/python - <<'PY' import pyogrio print('ok') PY


Se ejecutó python3 - <<'PY' import csv from pathlib import Path base=Path('output/spreadsheet/enriched') for name in ['episode_rescue_candidate.csv','episode_request.csv','episode_discharge.csv','normalized_discharge_event.csv','reconciliation_report.csv']: path=base/name with path.open('r', encoding='utf-8', newline='') as fh: rows=list(csv.DictReader(fh)) print('\n===',name,len(rows),'===') if name=='episode_rescue_candidate.csv': subset=[r for r in rows if ((r['requested_at'] or r['fecha_egreso'] or r['fecha_ingreso'])[:7] in {'2025-10','2025-11','2025-12'})] print('subset oct-dec', len(subset)) for r in subset[:10]: print(r) elif name=='episode_discharge.csv': subset=[r for r in rows if (r['fecha_egreso'] or r['fecha_ingreso'])[:7] in {'2025-10','2025-11','2025-12'}] print('subset oct-dec', len(subset)) for r in subset[:10]: print(r) elif name=='normalized_discharge_event.csv': subset=[r for r in rows if (r['fecha_egreso'] or r['fecha_ingreso'])[:7] in {'2025-10','2025-11','2025-12'}] print('subset oct-dec', len(subset)) for r in subset[:15]: print(r) elif name=='episode_request.csv': subset=[r for r in rows if (r['submission_timestamp'] or '')[:7] in {'2025-10','2025-11','2025-12'}] print('subset oct-dec', len(subset)) print('counts', {k:sum(1 for x in subset if x['episode_origin']==k) for k in sorted(set(x['episode_origin'] for x in subset))}) else: for r in rows: print(r) PY


Voy a revisar la planilla de altas más allá de mayo 2025. Si hay hojas semanales hasta octubre-diciembre 2025, el parser no las está aprovechando; si no existen, entonces el rescate de egresos faltantes necesita otra fuente.

Se ejecutó python3 - <<'PY' import openpyxl wb=openpyxl.load_workbook('/Users/felixsanhueza/Downloads/PLANILLA DE ALTAS 26.xlsx', read_only=True, data_only=True) for i,name in enumerate(wb.sheetnames, start=1): if i>=40: print(i, name) PY


Ya confirmé que la planilla sí tiene hojas semanales para octubre, noviembre y diciembre 2025. Ahora voy a inspeccionar su layout real en esas semanas, porque el problema está en el parser, no en la ausencia de fuente.

Se ejecutó python3 - <<'PY' from itertools import islice import openpyxl wb=openpyxl.load_workbook('/Users/felixsanhueza/Downloads/PLANILLA DE ALTAS 26.xlsx', read_only=True, data_only=True) for name in ['ALTAS 29 - 05 DE OCTUBRE 2025','ALTAS 06 - 12 DE OCTUBRE 25','ALTAS 17- 23 DE NOVIEMBRE 2025','15 - 21 DE DICIEMBRE 2025']: # handle slight sheet name mismatch actual=next((s for s in wb.sheetnames if s.strip()==name.strip()), None) if not actual: actual=next((s for s in wb.sheetnames if name.strip() in s.strip() or s.strip() in name.strip()), None) print('\n===', name, '=>', actual, '===') ws=wb[actual] for i,row in enumerate(islice(ws.iter_rows(values_only=True),10), start=1): print(i,row) PY


Se ejecutó python3 - <<'PY' import csv from pathlib import Path path=Path('output/spreadsheet/enriched/normalized_discharge_event.csv') with path.open('r', encoding='utf-8', newline='') as fh: rows=list(csv.DictReader(fh)) months=sorted({(r['fecha_egreso'] or r['fecha_ingreso'])[:7] for r in rows if (r['fecha_egreso'] or r['fecha_ingreso'])}) print(months) PY


Ya encontré el problema: la planilla de altas sí trae octubre-diciembre 2025, pero el parser está convirtiendo las celdas fecha a texto antes de parsearlas, así que fecha_ingreso y fecha_egreso quedan vacías en la salida. Por eso no se están usando para rescatar ni para completar egresos. Lo corrijo ahora.

Editado
build_hodom_enriched.py
+9
-2
Voy a regenerar la capa enriquecida con el parser de altas corregido y luego reviso específicamente octubre-diciembre 2025 para ver cuántos rescates/egresos ya aparecen con fecha.

Se ejecutó python3 -m py_compile scripts/build_hodom_enriched.py


Se ejecutó .venv/bin/python scripts/build_hodom_enriched.py


La regeneración ya corre con el parser de altas corregido. Después de esto vuelvo a medir rescates y fechas de egreso para octubre-diciembre 2025.

Now inspect oct-dec counts.

Se ejecutó python3 - <<'PY' import csv from collections import Counter from pathlib import Path path=Path('output/spreadsheet/enriched/episode_discharge.csv') with path.open('r', encoding='utf-8', newline='') as fh: rows=list(csv.DictReader(fh)) subset=[r for r in rows if (r['fecha_egreso'] or r['fecha_ingreso'])[:7] in {'2025-10','2025-11','2025-12'}] print('match_status', Counter(r['match_status'] for r in subset)) print('episode_origin', Counter(r['episode_origin'] for r in subset)) PY


Se ejecutó python3 - <<'PY' import csv from pathlib import Path base=Path('output/spreadsheet/enriched') for name in ['normalized_discharge_event.csv','episode_discharge.csv','episode_rescue_candidate.csv','reconciliation_report.csv']: path=base/name with path.open('r', encoding='utf-8', newline='') as fh: rows=list(csv.DictReader(fh)) print('\n===',name,'===') if name in {'normalized_discharge_event.csv','episode_discharge.csv'}: subset=[r for r in rows if (r['fecha_egreso'] or r['fecha_ingreso'])[:7] in {'2025-10','2025-11','2025-12'}] print('subset oct-dec', len(subset)) for r in subset[:12]: print(r) elif name=='episode_rescue_candidate.csv': subset=[r for r in rows if ((r['requested_at'] or r['fecha_egreso'] or r['fecha_ingreso'])[:7] in {'2025-10','2025-11','2025-12'})] print('subset oct-dec', len(subset)) for r in subset[:12]: print(r) else: for r in rows: print(r) PY


El problema sigue siendo el parser de altas, no el rescate por formularios: las hojas de octubre-diciembre 2025 están ahí, pero no están entrando a normalized_discharge_event. Voy a medir exactamente qué meses está sacando y revisar la deduplicación/lectura de esas hojas.

Se ejecutó python3 - <<'PY' import csv from collections import Counter from pathlib import Path path=Path('output/spreadsheet/enriched/normalized_discharge_event.csv') with path.open('r', encoding='utf-8', newline='') as fh: rows=list(csv.DictReader(fh)) months=Counter((r['fecha_egreso'] or r['fecha_ingreso'])[:7] for r in rows if (r['fecha_egreso'] or r['fecha_ingreso'])) print(months.most_common(30)) for r in rows[:20]: print(r) PY


Se ejecutó python3 - <<'PY' from scripts.build_hodom_enriched import parse_discharge_workbook from pathlib import Path raw, norm = parse_discharge_workbook(Path('/Users/felixsanhueza/Downloads/PLANILLA DE ALTAS 26.xlsx')) print('raw', len(raw), 'norm', len(norm)) subset=[r for r in norm if (r['fecha_egreso'] or r['fecha_ingreso'])[:7] in {'2025-10','2025-11','2025-12'}] print('subset', len(subset)) for r in subset[:20]: print(r) PY


Ya encontré el bug real del rescate de egresos: las hojas de octubre-diciembre 2025 cambian el encabezado de NOMBRE USUARIO a NOMBRE, y el parser estaba ignorando todas esas hojas. Lo corrijo ahora.

Editado
build_hodom_enriched.py
+8
-4
Voy a regenerar la capa enriquecida con el parser de altas corregido para las hojas 2025 y luego vuelvo a medir específicamente octubre-diciembre 2025.

Se ejecutó python3 -m py_compile scripts/build_hodom_enriched.py


Se ejecutó .venv/bin/python scripts/build_hodom_enriched.py


La regeneración ya está corriendo con el parser de altas corregido para las semanas 2025. Después medimos si ahora aparecen episode_discharge en octubre-diciembre y si los rescates salen con fecha_egreso.

Se ejecutó python3 - <<'PY' import csv from collections import Counter from pathlib import Path path=Path('output/spreadsheet/enriched/normalized_discharge_event.csv') with path.open('r', encoding='utf-8', newline='') as fh: rows=list(csv.DictReader(fh)) months=Counter((r['fecha_egreso'] or r['fecha_ingreso'])[:7] for r in rows if (r['fecha_egreso'] or r['fecha_ingreso'])) print(months.most_common(30)) subset=[r for r in rows if (r['fecha_egreso'] or r['fecha_ingreso'])[:7] in {'2025-10','2025-11','2025-12'}] print('subset', len(subset)) for r in subset[:20]: print(r) PY


Voy a probar el parser de altas en aislamiento desde el directorio scripts, porque el problema ahora no parece ser el archivo sino la lógica interna del parser sobre las hojas 2025.

Se ejecutó cd /Users/felixsanhueza/Developer/_workspaces/hdos/scripts && ../.venv/bin/python - <<'PY' from pathlib import Path import build_hodom_enriched as bhe raw, norm = bhe.parse_discharge_workbook(Path('/Users/felixsanhueza/Downloads/PLANILLA DE ALTAS 26.xlsx')) print('raw', len(raw), 'norm', len(norm)) subset=[r for r in norm if (r['fecha_egreso'] or r['fecha_ingreso'])[:7] in {'2025-10','2025-11','2025-12'}] print('subset', len(subset)) for r in subset[:20]: print(r) PY


Ya confirmé que el parser sigue sin leer las semanas 2025. Ahora voy a inspeccionar en qué hojas detecta header y en cuáles no, para ajustar exactamente la condición de detección.

Se ejecutó cd /Users/felixsanhueza/Developer/_workspaces/hdos/scripts && ../.venv/bin/python - <<'PY' import openpyxl from pathlib import Path import build_hodom_enriched as bhe wb=openpyxl.load_workbook('/Users/felixsanhueza/Downloads/PLANILLA DE ALTAS 26.xlsx', read_only=True, data_only=True) parsed=[] for ws in wb.worksheets: preview=list(ws.iter_rows(min_row=1,max_row=8,values_only=True)) header_row=None joined_rows=[] for idx,row in enumerate(preview, start=1): joined=' | '.join('' if v is None else str(v) for v in row) joined_rows.append((idx,joined)) if ( 'FECHA DE INGRESO' in joined and ('NOMBRE USUARIO' in joined or '| NOMBRE |' in f'| {joined} |' or 'NOMBRE' in joined) and 'RUT' in joined ): header_row=idx break if header_row: parsed.append((ws.title, header_row)) print('parsed sheets', len(parsed)) for item in parsed[-30:]: print(item) print('\nNot parsed around 2025-10 onward:') for ws in wb.worksheets[60:80]: if ws.title not in {p[0] for p in parsed}: print('\nSHEET', ws.title) preview=list(ws.iter_rows(min_row=1,max_row=5,values_only=True)) for idx,row in enumerate(preview, start=1): print(idx, row) PY


La evidencia muestra que esas hojas 2025 siguen quedando fuera del parser, así que voy a probar la condición de detección sobre una fila real de octubre para ver por qué no está entrando cuando debería.

Se ejecutó cd /Users/felixsanhueza/Developer/_workspaces/hdos/scripts && ../.venv/bin/python - <<'PY' joined='SERVICIO | NOMBRE | RUT | EDAD | DOMICILIO | TELEFONO | FECHA INGRESO | FECHA EGRESO | DIAGNOSTICO DE EGRESO | CONSULTORIO DERIVACION | OBSERVACIONES' cond=( 'FECHA DE INGRESO' in joined and ('NOMBRE USUARIO' in joined or '| NOMBRE |' in f'| {joined} |' or 'NOMBRE' in joined) and 'RUT' in joined ) print(cond) print('FECHA DE INGRESO' in joined) print('| NOMBRE |' in f'| {joined} |') print('NOMBRE' in joined) print('RUT' in joined) PY


El contexto se compactó automáticamente
Voy a revisar y corregir el rescate desde la planilla de altas, porque el síntoma encaja con un parser que está dejando fuera hojas de octubre-diciembre 2025. Después reejecuto el pipeline y verifico específicamente fecha_egreso y cobertura mensual de rescates.

Explorado(s) 1 archivo
Se ejecutó python3 - <<'PY' from pathlib import Path import re p=Path('output/spreadsheet/enriched/normalized_discharge_event.csv') if p.exists(): import csv from collections import Counter c=Counter() total=0 with p.open() as f: r=csv.DictReader(f) for row in r: total+=1 d=(row.get('fecha_egreso') or '')[:7] c[d]+=1 print('total', total) for k,v in sorted(c.items()): print(k,v) else: print('missing') PY


Se ejecutó python3 - <<'PY' from openpyxl import load_workbook wb=load_workbook('/Users/felixsanhueza/Downloads/PLANILLA DE ALTAS 26.xlsx', data_only=True) for name in wb.sheetnames: if 'OCT' in name.upper() or 'NOV' in name.upper() or 'DIC' in name.upper() or 'ENE' in name.upper(): ws=wb[name] rows=[] for row in ws.iter_rows(min_row=1, max_row=6, values_only=True): rows.append([str(v) if v is not None else '' for v in row[:12]]) print('\nSHEET:', name) for r in rows: print(r) PY


Encontré el problema principal: la planilla de altas sí trae octubre-diciembre 2025, pero el parser está dejando fuera muchas hojas por una detección de encabezado demasiado rígida. Voy a corregir esa detección y reejecutar el pipeline para medir cuántos egresos y rescates se recuperan realmente.

Explorado(s) 1 archivo
Se ejecutó python3 - <<'PY' from openpyxl import load_workbook from pathlib import Path import re wb=load_workbook('/Users/felixsanhueza/Downloads/PLANILLA DE ALTAS 26.xlsx', data_only=True) parsed=[] not_parsed=[] for ws in wb.worksheets: preview=list(ws.iter_rows(min_row=1,max_row=8,values_only=True)) found=False for idx,row in enumerate(preview, start=1): joined=' | '.join('' if v is None else str(v) for v in row) cond=(('FECHA DE INGRESO' in joined) and (('NOMBRE USUARIO' in joined) or ('| NOMBRE |' in f'| {joined} |') or ('NOMBRE' in joined)) and ('RUT' in joined)) if cond: found=True break (parsed if found else not_parsed).append(ws.title) print('parsed', len(parsed)) for x in parsed: print('P', x) print('not_parsed', len(not_parsed)) for x in not_parsed: print('N', x) PY


Además del encabezado, detecté un segundo defecto: muchas hojas 2025/2026 no traen MOTIVO DE EGRESO, lo traen en OBSERVACIONES. Si no corrijo ambas cosas, seguiríamos rescatando pocos casos y sin fecha_egreso. Voy a endurecer el parser completo de altas antes de reejecutar.

Explorado(s) 1 búsqueda
Se ejecutó python3 - <<'PY' from openpyxl import load_workbook wb=load_workbook('/Users/felixsanhueza/Downloads/PLANILLA DE ALTAS 26.xlsx', data_only=True) for title in ['ALTAS 02-08 DIC 2024','ALTAS 29 - 05 DE OCTUBRE 2025','05 -11 DE ENERO 2026','15 - 21 DE DICIEMBRE 2025']: ws=wb[title] print('\n',title) for i,row in enumerate(ws.iter_rows(min_row=1,max_row=4,values_only=True), start=1): print(i,[None if v is None else str(v) for v in row[:12]]) PY


Voy a dejar el parser de altas compatible con los layouts reales que tiene la planilla: FECHA INGRESO sin “DE”, DIAGNOSTICO DE EGRESO, OBSERVACIONES como motivo, y el caso corrupto donde la columna del nombre aparece como 0. Eso debería destrabar los egresos de octubre-diciembre 2025 y los rescates derivados de altas.

Editado
build_hodom_enriched.py
+22
-11
Se ejecutó python3 - <<'PY' from pathlib import Path ns={} text=Path('scripts/build_hodom_enriched.py').read_text() start=text.index('def parse_discharge_workbook') end=text.index('\ndef fetch_establishment_reference') print(text[start:end]) PY


Se ejecutó python3 -m py_compile scripts/build_hodom_enriched.py


El parser ya quedó corregido y compila. Ahora voy a reprocesar toda la capa enriquecida y medir específicamente tres cosas: altas normalizadas Oct-Dic 2025, episodios rescatados desde altas y cuántos rescates ganan fecha_egreso.

Se ejecutó ./.venv/bin/python scripts/build_hodom_enriched.py


La corrida está en curso. Cuando termine, voy a comparar el antes/después contra octubre, noviembre y diciembre de 2025 para verificar que no sólo suban los rescates, sino que además traigan egresos reales desde la planilla de altas.

La primera corrección no alcanzó: ahora veo el síntoma claro. El parser dejó raw_discharge_sheet = 0, o sea, no está leyendo ninguna hoja de altas. Eso confirma que la detección depende de cómo canonical_text() normaliza los encabezados. Voy a ajustar esa lógica contra la normalización real del proyecto y rerun inmediato.

Explorado(s) 1 búsqueda
Se ejecutó python3 - <<'PY' import sys sys.path.insert(0,'scripts') import migrate_hodom_csv as base samples=['FECHA INGRESO','FECHA DE INGRESO','NOMBRE USUARIO','NOMBRE','APELLIDOS','0','DIAGNOSTICO DE EGRESO','OBSERVACIONES','RUT'] for s in samples: print(repr(s), '->', repr(base.canonical_text(s))) PY


Se ejecutó python3 - <<'PY' import sys sys.path.insert(0,'scripts') import migrate_hodom_csv as base from openpyxl import load_workbook wb=load_workbook('/Users/felixsanhueza/Downloads/PLANILLA DE ALTAS 26.xlsx', data_only=True) for title in ['ALTAS 29 - 05 DE OCTUBRE 2025','ALTAS 02-08 DIC 2024','05 -11 DE ENERO 2026','15 - 21 DE DICIEMBRE 2025']: ws=wb[title] print('\n',title) for idx,row in enumerate(ws.iter_rows(min_row=1,max_row=3,values_only=True), start=1): vals=[base.canonical_text(str(v or '')) for v in row] print(idx, vals) PY


Ya vi la causa exacta: canonical_text() del proyecto normaliza a mayúsculas, y mi detector estaba comparando en minúsculas. Además, en una hoja la cabecera del nombre viene como 0, pero al convertir con value or "" ese 0 se perdía. Corrijo ambas cosas y vuelvo a correr.

Editado
build_hodom_enriched.py
+13
-7
Se ejecutó python3 -m py_compile scripts/build_hodom_enriched.py


Se ejecutó python3 - <<'PY' import sys sys.path.insert(0,'scripts') import migrate_hodom_csv as base from openpyxl import load_workbook wb=load_workbook('/Users/felixsanhueza/Downloads/PLANILLA DE ALTAS 26.xlsx', data_only=True) parsed=[] for ws in wb.worksheets: preview=list(ws.iter_rows(min_row=1,max_row=8,values_only=True)) found=False for idx,row in enumerate(preview, start=1): normalized=[base.canonical_text('' if value is None else str(value)) for value in row] non_empty=[v for v in normalized if v] has_fecha_ingreso=any(v in {'FECHA INGRESO','FECHA DE INGRESO'} for v in non_empty) has_fecha_egreso=any(v in {'FECHA EGRESO','FECHA DE EGRESO'} for v in non_empty) has_rut='RUT' in non_empty has_name=any(v in {'NOMBRE','NOMBRE USUARIO','APELLIDOS','0'} for v in non_empty) second_column_blank=len(normalized)>1 and normalized[1]=='' if has_fecha_ingreso and has_fecha_egreso and has_rut and (has_name or second_column_blank): found=True break if found: parsed.append(ws.title) print('parsed_count', len(parsed)) print('sample_last12', parsed[-12:]) PY


Listo, la detección ya reconoce 89 hojas de altas, incluyendo octubre-diciembre 2025 y enero 2026. Ahora sí reproceso; después voy a medir exactamente cuántos egresos 2025 entraron y cuánto subió el rescate real.

Se ejecutó ./.venv/bin/python scripts/build_hodom_enriched.py


La corrida ya cambió el panorama: entraron 1090 eventos de alta y el universo total subió a 1882 episodios. Ahora estoy midiendo el impacto exacto en octubre-diciembre 2025, porque ahí es donde importa si los rescates ganaron fecha_egreso y si el conteo se acerca más a los reales.

Se ejecutó python3 - <<'PY' import csv from collections import Counter p='output/spreadsheet/enriched/normalized_discharge_event.csv' c=Counter() with open(p) as f: r=csv.DictReader(f) total=0 for row in r: total+=1 c[(row['fecha_egreso'] or '')[:7]]+=1 print('total', total) for k,v in sorted(c.items()): if k >= '2025-09': print(k,v) PY


Se ejecutó python3 - <<'PY' import csv from collections import Counter rows=[] with open('output/spreadsheet/enriched/episode_rescue_candidate.csv') as f: r=csv.DictReader(f) for row in r: m=(row.get('event_date') or row.get('fecha_egreso') or row.get('fecha_ingreso') or '')[:7] if m in {'2025-10','2025-11','2025-12'}: rows.append(row) print('rescues_oct_dec', len(rows)) print('by_origin', Counter(row['episode_origin'] for row in rows)) print('with_egreso', sum(1 for row in rows if row.get('fecha_egreso'))) print('without_egreso', sum(1 for row in rows if not row.get('fecha_egreso'))) PY


Se ejecutó python3 - <<'PY' import csv path='output/spreadsheet/enriched/reconciliation_report.csv' with open(path) as f: r=csv.DictReader(f) for row in r: print(row) PY


Se ejecutó python3 - <<'PY' import csv count=0 with open('output/spreadsheet/enriched/episode_master.csv') as f: r=csv.DictReader(f) rows=[row for row in r if row['episode_origin'] in {'form_rescued','alta_rescued'} and (row['fecha_ingreso'][:7] in {'2025-10','2025-11','2025-12'} or row['fecha_egreso'][:7] in {'2025-10','2025-11','2025-12'})] print('episode_master_rescued_oct_dec', len(rows)) print('with_egreso', sum(1 for row in rows if row['fecha_egreso'])) print('alta_rescued', sum(1 for row in rows if row['episode_origin']=='alta_rescued')) print('form_rescued', sum(1 for row in rows if row['episode_origin']=='form_rescued')) print('sample_missing_egreso', rows[:10]) PY


La corrección ya recuperó mucho: octubre pasó a 67 episodios, noviembre a 61 y diciembre a 66, con 89 rescates por alta que ahora sí traen fecha_egreso. Pero todavía quedan 54 rescates form_rescued sin egreso en Oct-Dic 2025, así que ahora voy a revisar el matching entre formularios y altas para ver cuáles de esos deberían estar fusionándose.

Explorado(s) 1 archivo
Se ejecutó python3 - <<'PY' import csv from collections import Counter # Find likely form_rescued episodes Oct-Dec that have same patient and nearby discharge event but remained unmatched # Build discharges by patient/rut/name rows=[] with open('output/spreadsheet/enriched/episode_master.csv') as f: er=list(csv.DictReader(f)) with open('output/spreadsheet/enriched/normalized_discharge_event.csv') as f: dr=list(csv.DictReader(f)) for ep in er: if ep['episode_origin']!='form_rescued': continue if (ep['fecha_ingreso'] or '')[:7] not in {'2025-10','2025-11','2025-12'}: continue best=[] for d in dr: same_rut=ep['rut'] and d['rut_norm'] and ep['rut']==d['rut_norm'] same_name=(ep['nombre_completo'] and d['nombre_completo'] and ep['nombre_completo'].strip().upper()==d['nombre_completo'].strip().upper()) if not (same_rut or same_name): continue # days diff between episode ingreso and discharge ingreso di=ep['fecha_ingreso'] dj=d['fecha_ingreso'] if di and dj: diff=abs((__import__('datetime').date.fromisoformat(di)-__import__('datetime').date.fromisoformat(dj)).days) else: diff=999 if diff <= 14: best.append((diff,d)) if best: best.sort(key=lambda x:x[0]) rows.append((ep,best[:3])) print('form_rescued_with_candidate_discharge', len(rows)) for ep,best in rows[:20]: print('\nEP', ep['episode_id'], ep['nombre_completo'], ep['rut'], ep['fecha_ingreso'], ep['diagnostico_principal_texto']) for diff,d in best: print(' cand', diff, d['fecha_ingreso'], d['fecha_egreso'], d['nombre_completo'], d['rut_norm'], d['diagnostico'], d['motivo_egreso']) PY


Ya confirmé otro punto débil: el matching de altas contra episodios es bastante conservador. Ahora estoy buscando específicamente rescates de formulario que sí tengan una alta candidata cercana para convertirlos en episodios cerrados y no dejarlos colgando sin egreso.

Se ejecutó python3 - <<'PY' import csv with open('output/spreadsheet/enriched/episode_master.csv') as f: r=csv.DictReader(f) row=next(r) print(row.keys()) print(row) PY


Se ejecutó python3 - <<'PY' import csv with open('output/spreadsheet/enriched/patient_master.csv') as f: r=csv.DictReader(f) row=next(r) print(row.keys()) PY


Se ejecutó python3 - <<'PY' import csv from datetime import date patients={} with open('output/spreadsheet/enriched/patient_master.csv') as f: for row in csv.DictReader(f): patients[row['patient_id']]=row with open('output/spreadsheet/enriched/episode_master.csv') as f: eps=list(csv.DictReader(f)) with open('output/spreadsheet/enriched/normalized_discharge_event.csv') as f: dis=list(csv.DictReader(f)) rows=[] for ep in eps: if ep['episode_origin']!='form_rescued': continue if (ep['fecha_ingreso'] or '')[:7] not in {'2025-10','2025-11','2025-12'}: continue p=patients.get(ep['patient_id'],{}) prut=p.get('rut','') pname=p.get('nombre_completo','') best=[] for d in dis: same_rut=prut and d['rut_norm'] and prut==d['rut_norm'] same_name=pname and d['nombre_completo'] and pname.strip().upper()==d['nombre_completo'].strip().upper() if not (same_rut or same_name): continue di=ep['fecha_ingreso'] dj=d['fecha_ingreso'] diff=999 if di and dj: diff=abs((date.fromisoformat(di)-date.fromisoformat(dj)).days) if diff<=21: best.append((diff,d)) if best: best.sort(key=lambda x:(x[0],x[1]['fecha_egreso'])) rows.append((ep,p,best[:3])) print('form_rescued_with_candidate_discharge', len(rows)) for ep,p,best in rows[:30]: print('\nEP', ep['episode_id'], p.get('nombre_completo'), p.get('rut'), ep['fecha_ingreso'], ep['diagnostico_principal_texto']) for diff,d in best: print(' cand', diff, d['fecha_ingreso'], d['fecha_egreso'], d['nombre_completo'], d['rut_norm'], d['diagnostico'], d['motivo_egreso']) PY


Explorado(s) 1 archivo,1 búsqueda
Encontré el defecto que explica por qué todavía quedaban tantos form_rescued sin egreso: las altas se estaban comparando sólo contra los episodios baseline, no contra los rescates creados desde formularios. Voy a reconstruir el índice de episodios después de procesar formularios y antes de procesar altas.

Editado
build_hodom_enriched.py
+9
-0
Se ejecutó python3 - <<'PY' from pathlib import Path import re text=Path('scripts/build_hodom_enriched.py').read_text() print('rebuild exists', 'Rebuild the episode lookup after form processing' in text) PY


Se ejecutó python3 -m py_compile scripts/build_hodom_enriched.py


Ahora sí el flujo quedó bien encadenado: formularios primero, luego reconstrucción del universo de episodios, y recién después las altas. Reproceso una vez más para medir cuántos rescates de formulario pasan a quedar cerrados con fecha_egreso.

Se ejecutó ./.venv/bin/python scripts/build_hodom_enriched.py


Se ejecutó python3 - <<'PY' import csv from collections import Counter with open('output/spreadsheet/enriched/reconciliation_report.csv') as f: for row in csv.DictReader(f): print(row) PY


Se ejecutó python3 - <<'PY' import csv from collections import Counter rows=[] with open('output/spreadsheet/enriched/episode_rescue_candidate.csv') as f: r=csv.DictReader(f) for row in r: m=(row.get('event_date') or row.get('fecha_egreso') or row.get('fecha_ingreso') or '')[:7] if m in {'2025-10','2025-11','2025-12'}: rows.append(row) print('rescues_oct_dec', len(rows)) print('by_origin', Counter(row['episode_origin'] for row in rows)) print('with_egreso', sum(1 for row in rows if row.get('fecha_egreso'))) print('without_egreso', sum(1 for row in rows if not row.get('fecha_egreso'))) PY


Se ejecutó python3 - <<'PY' import csv from collections import Counter p='output/spreadsheet/enriched/episode_discharge.csv' count=0 months=Counter() matched=Counter() rescued=Counter() with open(p) as f: for row in csv.DictReader(f): month=(row['fecha_egreso'] or row['fecha_ingreso'])[:7] if month in {'2025-10','2025-11','2025-12'}: count+=1 months[month]+=1 if row['match_status'] in {'matched_exact','matched_probable','matched_manual'}: matched[month]+=1 elif row['episode_origin']=='alta_rescued': rescued[month]+=1 print('episode_discharge_oct_dec', count) print('months', months) print('matched', matched) print('rescued', rescued) PY


Se ejecutó python3 - <<'PY' import csv rows=[] with open('output/spreadsheet/enriched/episode_master.csv') as f: r=csv.DictReader(f) for row in r: if row['episode_origin'] in {'form_rescued','alta_rescued'} and (row['fecha_ingreso'][:7] in {'2025-10','2025-11','2025-12'} or row['fecha_egreso'][:7] in {'2025-10','2025-11','2025-12'}): rows.append(row) print('episode_master_rescued_oct_dec', len(rows)) print('with_egreso', sum(1 for row in rows if row['fecha_egreso'])) print('alta_rescued', sum(1 for row in rows if row['episode_origin']=='alta_rescued')) print('form_rescued', sum(1 for row in rows if row['episode_origin']=='form_rescued')) PY


La mejora fuerte ya se produjo: los rescates materializados en episode_master para Oct-Dic bajaron de 143 candidatos dispersos a 43 episodios reales, y 35 de esos ya quedaron cerrados con fecha_egreso. Me queda revisar los 8 form_rescued que siguen sin egreso, para confirmar si son realmente casos sin alta o si todavía hay matching por afinar.

Se ejecutó python3 - <<'PY' import csv patients={} with open('output/spreadsheet/enriched/patient_master.csv') as f: for row in csv.DictReader(f): patients[row['patient_id']]=row rows=[] with open('output/spreadsheet/enriched/episode_master.csv') as f: for row in csv.DictReader(f): if row['episode_origin']=='form_rescued' and (row['fecha_ingreso'][:7] in {'2025-10','2025-11','2025-12'} or row['fecha_egreso'][:7] in {'2025-10','2025-11','2025-12'}): p=patients.get(row['patient_id'],{}) rows.append({ 'episode_id': row['episode_id'], 'patient': p.get('nombre_completo',''), 'rut': p.get('rut',''), 'fecha_ingreso': row['fecha_ingreso'], 'servicio': row['servicio_origen'], 'diagnostico': row['diagnostico_principal_texto'], 'gestora': row['gestora'], 'request_prestacion': row['request_prestacion'], 'requested_at': row['requested_at'], }) print('remaining_form_rescued', len(rows)) for row in rows: print(row) PY


Se ejecutó python3 - <<'PY' import csv from datetime import date patients={} with open('output/spreadsheet/enriched/patient_master.csv') as f: for row in csv.DictReader(f): patients[row['patient_id']]=row with open('output/spreadsheet/enriched/episode_master.csv') as f: eps=[row for row in csv.DictReader(f) if row['episode_origin']=='form_rescued' and (row['fecha_ingreso'][:7] in {'2025-10','2025-11','2025-12'} or row['fecha_egreso'][:7] in {'2025-10','2025-11','2025-12'})] with open('output/spreadsheet/enriched/normalized_discharge_event.csv') as f: dis=list(csv.DictReader(f)) for ep in eps: p=patients[ep['patient_id']] hits=[] for d in dis: same_rut=p['rut'] and d['rut_norm'] and p['rut']==d['rut_norm'] same_name=p['nombre_completo'] and d['nombre_completo'] and p['nombre_completo'].strip().upper()==d['nombre_completo'].strip().upper() if not(same_rut or same_name): continue diff=999 if ep['fecha_ingreso'] and d['fecha_ingreso']: diff=abs((date.fromisoformat(ep['fecha_ingreso'])-date.fromisoformat(d['fecha_ingreso'])).days) if diff<=30: hits.append((diff,d['fecha_ingreso'],d['fecha_egreso'],d['diagnostico'],d['motivo_egreso'])) print('\n',p['nombre_completo'],p['rut'],ep['fecha_ingreso'],ep['diagnostico_principal_texto']) print('hits',hits[:5]) PY


Se ejecutó python3 - <<'PY' import csv patients={} with open('output/spreadsheet/enriched/patient_master.csv') as f: for row in csv.DictReader(f): patients[row['patient_id']]=row all_eps=[] with open('output/spreadsheet/enriched/episode_master.csv') as f: all_eps=list(csv.DictReader(f)) remaining=[row for row in all_eps if row['episode_origin']=='form_rescued' and (row['fecha_ingreso'][:7] in {'2025-10','2025-11','2025-12'} or row['fecha_egreso'][:7] in {'2025-10','2025-11','2025-12'})] for ep in remaining: p=patients[ep['patient_id']] print('\nFORM_RESCUE', p['nombre_completo'], p['rut'], ep['fecha_ingreso'], ep['diagnostico_principal_texto']) others=[] for other in all_eps: if other['episode_id']==ep['episode_id']: continue po=patients.get(other['patient_id'],{}) same_rut=p['rut'] and po.get('rut')==p['rut'] same_name=po.get('nombre_completo')==p['nombre_completo'] if same_rut or same_name: others.append((other['episode_origin'], other['estado'], other['fecha_ingreso'], other['fecha_egreso'], other['diagnostico_principal_texto'], other['episode_id'])) for x in others[:10]: print(' other',x) PY


Veo un residuo adicional: todavía quedan algunos form_rescued abiertos aunque ya existe otro episodio del mismo paciente y la misma fecha de ingreso que sí quedó cerrado por alta. Eso ya no es falta de dato; es falta de consolidación. Voy a colapsar esos duplicados lógicos para que no queden rescates “colgando” sin egreso cuando el cierre ya existe en otro episodio del mismo stay.

Explorado(s) 1 archivo
Editado
build_hodom_enriched.py
+58
-0
Se ejecutó python3 -m py_compile scripts/build_hodom_enriched.py


Voy con una última corrida. El cambio nuevo no busca traer más altas, sino eliminar rescates de formulario redundantes cuando ya existe el mismo stay cerrado por alta, para que el resultado final no mezcle “abierto” y “cerrado” del mismo paciente/fecha.

Se ejecutó ./.venv/bin/python scripts/build_hodom_enriched.py


Se ejecutó python3 - <<'PY' import csv with open('output/spreadsheet/enriched/reconciliation_report.csv') as f: for row in csv.DictReader(f): print(row) PY


Se ejecutó python3 - <<'PY' import csv from collections import Counter rows=[] with open('output/spreadsheet/enriched/episode_rescue_candidate.csv') as f: r=csv.DictReader(f) for row in r: m=(row.get('event_date') or row.get('fecha_egreso') or row.get('fecha_ingreso') or '')[:7] if m in {'2025-10','2025-11','2025-12'}: rows.append(row) print('rescues_oct_dec', len(rows)) print('by_origin', Counter(row['episode_origin'] for row in rows)) print('with_egreso', sum(1 for row in rows if row.get('fecha_egreso'))) print('without_egreso', sum(1 for row in rows if not row.get('fecha_egreso'))) PY


Se ejecutó python3 - <<'PY' import csv rows=[] with open('output/spreadsheet/enriched/episode_master.csv') as f: r=csv.DictReader(f) for row in r: if row['episode_origin'] in {'form_rescued','alta_rescued'} and (row['fecha_ingreso'][:7] in {'2025-10','2025-11','2025-12'} or row['fecha_egreso'][:7] in {'2025-10','2025-11','2025-12'}): rows.append(row) print('episode_master_rescued_oct_dec', len(rows)) print('with_egreso', sum(1 for row in rows if row['fecha_egreso'])) print('alta_rescued', sum(1 for row in rows if row['episode_origin']=='alta_rescued')) print('form_rescued', sum(1 for row in rows if row['episode_origin']=='form_rescued')) for row in rows: if row['episode_origin']=='form_rescued': print(row['episode_id'], row['patient_id'], row['fecha_ingreso'], row['diagnostico_principal_texto']) PY


Quedaron dos residuos más que no son falta de egreso, sino identidad fragmentada: mismo paciente/rut y misma fecha de ingreso, pero con patient_id distinto entre el rescate de formulario y el cierre por alta. Voy a consolidarlos por rut/nombre + fecha_ingreso, no sólo por patient_id.

Editado
build_hodom_enriched.py
+7
-4
Se ejecutó python3 -m py_compile scripts/build_hodom_enriched.py


Última pasada. Con esta consolidación por identidad nominal/RUT + fecha de ingreso deberíamos eliminar los rescates abiertos que en realidad ya estaban cerrados en otra rama del mismo paciente.

Ejecutando el comandopara 3s
$ ./.venv/bin/python scripts/build_hodom_enriched.py

Output dir: /Users/felixsanhueza/Developer/_workspaces/hdos/output/spreadsheet/intermediate
rut_corrections_applied: 67
raw_source_file: 31
raw_source_row: 3774
normalized_row: 2998
patient_identity_candidate: 1696
patient_master: 1218
patient_identity_link: 1696
episode: 1696
episode_source_link: 2998
episode_diagnosis: 1696
episode_care_requirement: 4140
episode_professional_need: 1959
patient_contact_point: 1456
patient_address: 1570
episode_location_snapshot: 1696
data_quality_issue: 1844
catalog_value: 146
rut_correction_queue: 0

1 archivo modificado
+108
-10

Revisar
cambios
No te quedan mensajes de Codex
Para obtener más acceso ahora, envía una solicitud a tu administrador o espera hasta 10:22 a.m..
Ver uso




GPT-5.4

Alto



Local0 %

Acceso completo

main
Terminal
zsh
