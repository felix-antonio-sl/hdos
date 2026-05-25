# Especificacion de consolidacion de fuentes Drive HODOM

Fuente: https://drive.google.com/drive/folders/1P6ur0dHwmECADUluzwfVvA5g9uTO9oVe?usp=sharing
Generado: 2026-05-25T17:56:09+00:00

## Inventario

- Archivos inventariados: 53
- Datasets: {"ingresos_2026": 1, "ingresos_nominales": 3, "inventario_insumos": 1, "pacientes_docx": 1, "prestaciones_enfermeria": 16, "rem": 29, "resumen_hodom": 2}
- Años cubiertos: {"2023": 11, "2024": 25, "2025": 14, "2026": 2, "sin_anio": 1}

## Cobertura por dataset

- prestaciones_enfermeria: 2023-07, 2023-08, 2023-09, 2023-10, 2023-11, 2024-01, 2024-02, 2024-03, 2024-04, 2024-05, 2024-06, 2024-08, 2024-09, 2024-10, 2024-11, 2024-12
- rem: 2023-07, 2023-08, 2023-09, 2023-10, 2023-11, 2024-01, 2024-02, 2024-03, 2024-04, 2024-05, 2024-06, 2024-07, 2024-08, 2024-09, 2024-10, 2024-11, 2024-12, 2025-01, 2025-02, 2025-03, 2025-04, 2025-05, 2025-06, 2025-07, 2025-08, 2025-09, 2025-10, 2025-11, 2025-12

## Banderas de calidad

- [review] coverage_gap · dataset=prestaciones_enfermeria; year=2024; periods=["2024-07"] - Expected monthly source file was not found in the Drive inventory.
- [review] rem_outlier_personas_atendidas · period=2024-02; checks=["personas_atendidas=656 versus ingresos=59", "personas_atendidas=656 exceeds dias_persona=629"] - Validate this aggregate against the original REM workbook before migration.
- [review] rem_missing_metric · period=2024-11; fields=["fallecidos_esperados", "visitas_trabajador_social"] - Metric was blank or not located in the source workbook sample.
- [review] rem_missing_metric · period=2024-12; fields=["visitas_trabajador_social"] - Metric was blank or not located in the source workbook sample.
- [review] rem_missing_metric · period=2025-01; fields=["visitas_trabajador_social"] - Metric was blank or not located in the source workbook sample.
- [review] rem_missing_metric · period=2025-02; fields=["visitas_trabajador_social"] - Metric was blank or not located in the source workbook sample.
- [review] rem_missing_metric · period=2025-03; fields=["visitas_trabajador_social"] - Metric was blank or not located in the source workbook sample.
- [review] rem_missing_metric · period=2025-04; fields=["visitas_trabajador_social"] - Metric was blank or not located in the source workbook sample.
- [review] rem_missing_metric · period=2025-05; fields=["visitas_trabajador_social"] - Metric was blank or not located in the source workbook sample.
- [review] rem_missing_metric · period=2025-06; fields=["visitas_trabajador_social"] - Metric was blank or not located in the source workbook sample.
- [review] rem_missing_metric · period=2025-07; fields=["visitas_trabajador_social"] - Metric was blank or not located in the source workbook sample.
- [review] rem_missing_metric · period=2025-08; fields=["visitas_trabajador_social"] - Metric was blank or not located in the source workbook sample.
- [review] rem_missing_metric · period=2025-09; fields=["visitas_trabajador_social"] - Metric was blank or not located in the source workbook sample.
- [review] rem_missing_metric · period=2025-10; fields=["visitas_trabajador_social"] - Metric was blank or not located in the source workbook sample.
- [review] rem_missing_metric · period=2025-11; fields=["visitas_trabajador_social"] - Metric was blank or not located in the source workbook sample.
- [review] rem_missing_metric · period=2025-12; fields=["visitas_trabajador_social"] - Metric was blank or not located in the source workbook sample.

## REM A21 C.1 extraido

| period | ingresos | personas_atendidas | dias_persona | altas | fallecidos_esperados | reingresos_hospitalizacion | visitas_medico | visitas_enfermera | visitas_kinesiologo | visitas_fonoaudiologo | visitas_trabajador_social | cupos_programados | cupos_utilizados | cupos_disponibles |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 2023-07 | 43 | 43 | 467 | 17 | 0 | 2 | 45 | 372 | 245 | 72 | 121 | 20 | 20 | 0 |
| 2023-08 | 54 | 54 | 639 | 48 | 0 | 2 | 27 | 366 | 241 | 91 | 54 | 20 | 746 | 620 |
| 2023-09 | 53 | 53 | 667 | 51 | 0 | 2 | 26 | 345 | 243 | 79 | 34 | 25 | 772 | 750 |
| 2023-10 | 81 | 81 | 996 | 79 | 7 | 3 | 42 | 531 | 245 | 115 | 155 | 25 | 996 | 775 |
| 2023-11 | 61 | 61 | 754 | 70 | 1 | 3 | 60 | 469 | 239 | 110 | 133 | 25 | 965 | 750 |
| 2024-01 | 57 | 57 | 664 | 59 | 1 | 2 | 92 | 467 | 264 | 94 | 120 | 25 | 708 | 775 |
| 2024-02 | 59 | 656 | 629 | 61 | 3 | 2 | 100 | 402 | 237 | 103 | 102 | 25 | 793 | 725 |
| 2024-03 | 67 | 67 | 688 | 68 | 2 | 2 | 87 | 498 | 264 | 99 | 103 | 25 | 896 | 775 |
| 2024-04 | 74 | 74 | 637 | 77 | 1 | 4 | 100 | 378 | 263 | 124 | 118 | 25 | 573 | 750 |
| 2024-05 | 100 | 100 | 586 | 94 | 3 | 2 | 84 | 296 | 278 | 117 | 143 | 25 | 843 | 775 |
| 2024-06 | 89 | 89 | 507 | 96 | 3 | 3 | 88 | 424 | 354 | 116 | 124 | 35 | 723 | 1050 |
| 2024-07 | 84 | 102 | 533 | 88 | 1 | 2 | 80 | 498 | 258 | 121 | 110 | 25 | 533 | 865 |
| 2024-08 | 83 | 83 | 456 | 74 | 1 | 3 | 176 | 362 | 268 | 114 | 107 | 25 | 860 | 775 |
| 2024-09 | 71 | 98 | 493 | 66 | 0 | 2 | 139 | 405 | 262 | 93 | 104 | 25 | 862 | 750 |
| 2024-10 | 71 | 96 | 498 | 75 | 0 | 2 | 142 | 405 | 266 | 91 | 89 | 25 | 686 | 775 |
| 2024-11 | 53 | 70 | 402 | 55 | None | 1 | 90 | 284 | 261 | 102 | None | 16 | 591 | 480 |
| 2024-12 | 44 | 67 | 411 | 49 | 1 | 3 | 102 | 269 | 220 | 105 | None | 16 | 681 | 496 |
| 2025-01 | 52 | 69 | 372 | 47 | 0 | 1 | 132 | 246 | 224 | 112 | None | 16 | 688 | 496 |
| 2025-02 | 47 | 21 | 349 | 46 | 1 | 2 | 132 | 246 | 226 | 115 | None | 16 | 576 | 448 |
| 2025-03 | 51 | 51 | 382 | 51 | 0 | 1 | 176 | 241 | 255 | 127 | None | 16 | 453 | 496 |
| 2025-04 | 56 | 56 | 404 | 43 | 3 | 2 | 176 | 250 | 241 | 104 | None | 16 | 608 | 480 |
| 2025-05 | 55 | 75 | 483 | 55 | 1 | 1 | 110 | 247 | 260 | 93 | None | 16 | 520 | 496 |
| 2025-06 | 52 | 69 | 398 | 53 | 0 | 3 | 97 | 244 | 253 | 110 | None | 16 | 399 | 480 |
| 2025-07 | 52 | 68 | 492 | 55 | 0 | 3 | 106 | 280 | 275 | 113 | None | 16 | 471 | 496 |
| 2025-08 | 45 | 62 | 434 | 54 | 0 | 2 | 93 | 274 | 270 | 112 | None | 16 | 426 | 496 |
| 2025-09 | 59 | 76 | 616 | 55 | 0 | 2 | 109 | 301 | 271 | 122 | None | 20 | 616 | 600 |
| 2025-10 | 62 | 78 | 510 | 61 | 1 | 2 | 90 | 285 | 263 | 117 | None | 20 | 461 | 620 |
| 2025-11 | 47 | 65 | 478 | 48 | 1 | 6 | 90 | 280 | 253 | 129 | None | 20 | 463 | 600 |
| 2025-12 | 50 | 66 | 562 | 61 | 0 | 3 | 79 | 290 | 273 | 114 | None | 20 | 562 | 620 |

## Observaciones de migracion

- Los archivos crudos se descargan a `.tmp/drive-consolidation/raw` y no se versionan.
- Esta especificacion vive bajo `docs/specs/metricas-hodom` y define el insumo normativo para staging previo a migracion.
- Los libros Office se tratan como fuentes primarias; el paso siguiente debe crear staging tables antes de tocar tablas clinicas.
- La planilla nativa `INGRESOS 2026 DRIVE` se exporta localmente como XLSX para inspeccion, manteniendo el ID de Drive como clave de provenance.
- Esta pasada produce metricas agregadas; no serializa filas nominales ni datos identificables.

## Archivos fuente

- `2023/PACIENTES 2023.docx` · dataset=pacientes_docx · sheets= · bytes=19507
- `2023/PRESTACIONES ENFERMERIA/AGOSTO.xlsx` · dataset=prestaciones_enfermeria · sheets=1 · bytes=98763
- `2023/PRESTACIONES ENFERMERIA/JULIO.xlsx` · dataset=prestaciones_enfermeria · sheets=1 · bytes=98719
- `2023/PRESTACIONES ENFERMERIA/NOVIEMBRE.xlsx` · dataset=prestaciones_enfermeria · sheets=1 · bytes=98169
- `2023/PRESTACIONES ENFERMERIA/OCTUBRE.xlsx` · dataset=prestaciones_enfermeria · sheets=1 · bytes=98939
- `2023/PRESTACIONES ENFERMERIA/SEPTIEMBRE.xlsx` · dataset=prestaciones_enfermeria · sheets=1 · bytes=96649
- `2023/REM/REM AGOSTO .xlsx` · dataset=rem · sheets=2 · bytes=36577
- `2023/REM/REM JULIO.xlsx` · dataset=rem · sheets=2 · bytes=36558
- `2023/REM/REM NOVIEMBRE.xlsx` · dataset=rem · sheets=2 · bytes=36580
- `2023/REM/REM OCTUBRE.xlsx` · dataset=rem · sheets=2 · bytes=36564
- `2023/REM/REM SEPTIEMBRE.xlsx` · dataset=rem · sheets=2 · bytes=36563
- `2024/INGRESOS ENE-OCT 2024.xlsx` · dataset=ingresos_nominales · sheets=13 · bytes=481272
- `2024/PLANILLA NOV DIC 2024.xlsx` · dataset=ingresos_nominales · sheets=3 · bytes=51357
- `2024/PRESTACIONES ENFERMERIA/ABRIL.xlsx` · dataset=prestaciones_enfermeria · sheets=1 · bytes=96889
- `2024/PRESTACIONES ENFERMERIA/AGOSTO.xlsx` · dataset=prestaciones_enfermeria · sheets=1 · bytes=100126
- `2024/PRESTACIONES ENFERMERIA/DICIEMBRE.xlsx` · dataset=prestaciones_enfermeria · sheets=1 · bytes=100305
- `2024/PRESTACIONES ENFERMERIA/ENERO.xlsx` · dataset=prestaciones_enfermeria · sheets=1 · bytes=98450
- `2024/PRESTACIONES ENFERMERIA/FEBRERO.xlsx` · dataset=prestaciones_enfermeria · sheets=1 · bytes=93146
- `2024/PRESTACIONES ENFERMERIA/JUNIO.xlsx` · dataset=prestaciones_enfermeria · sheets=1 · bytes=98069
- `2024/PRESTACIONES ENFERMERIA/MARZO.xlsx` · dataset=prestaciones_enfermeria · sheets=1 · bytes=98938
- `2024/PRESTACIONES ENFERMERIA/MAYO.xlsx` · dataset=prestaciones_enfermeria · sheets=1 · bytes=96690
- `2024/PRESTACIONES ENFERMERIA/NOVIEMBRE.xlsx` · dataset=prestaciones_enfermeria · sheets=1 · bytes=97937
- `2024/PRESTACIONES ENFERMERIA/OCTUBRE.xlsx` · dataset=prestaciones_enfermeria · sheets=1 · bytes=100039
- `2024/PRESTACIONES ENFERMERIA/SEPTIEMBRE .xlsx` · dataset=prestaciones_enfermeria · sheets=1 · bytes=98022
- `2024/REM/REM ABRIL 24.xlsx` · dataset=rem · sheets=2 · bytes=36577
- `2024/REM/REM AGOSTO .xlsx` · dataset=rem · sheets=2 · bytes=36562
- `2024/REM/REM DICIEMBRE.xlsx` · dataset=rem · sheets=2 · bytes=36604
- `2024/REM/REM ENERO.xlsx` · dataset=rem · sheets=2 · bytes=36562
- `2024/REM/REM FEBRERO.xlsx` · dataset=rem · sheets=2 · bytes=36601
- `2024/REM/REM JULIO .xlsx` · dataset=rem · sheets=2 · bytes=36572
- `2024/REM/REM JUNIO 24.xlsx` · dataset=rem · sheets=2 · bytes=36558
- `2024/REM/REM MARZO.xlsx` · dataset=rem · sheets=2 · bytes=36608
- `2024/REM/REM MAYO.xlsx` · dataset=rem · sheets=2 · bytes=36582
- `2024/REM/REM NOVIEMBRE 2024.xlsx` · dataset=rem · sheets=2 · bytes=36610
- `2024/REM/REM OCTUBRE 24.xlsx` · dataset=rem · sheets=2 · bytes=36566
- `2024/REM/REM SEPTIEMBRE.xlsx` · dataset=rem · sheets=2 · bytes=36587
- `2025/INGRESOS 2025 (3).xlsx` · dataset=ingresos_nominales · sheets=11 · bytes=310300
- `2025/REM ABRIL 25.xlsx` · dataset=rem · sheets=1 · bytes=19590
- `2025/REM AGOSTO 25.xlsx` · dataset=rem · sheets=1 · bytes=21035
- `2025/REM DICIEMBRE 2025.xlsx` · dataset=rem · sheets=1 · bytes=21116
- `2025/REM ENERO 2025.xlsx` · dataset=rem · sheets=2 · bytes=37211
- `2025/REM FEBRERO 2025.xlsx` · dataset=rem · sheets=2 · bytes=36962
- `2025/REM JULIO 25.xlsx` · dataset=rem · sheets=1 · bytes=19696
- `2025/REM JUNIO 25.xlsx` · dataset=rem · sheets=1 · bytes=19716
- `2025/REM MARZO 25.xlsx` · dataset=rem · sheets=1 · bytes=19598
- `2025/REM MAYO 25.xlsx` · dataset=rem · sheets=1 · bytes=19615
- `2025/REM NOVIEMBRE 2025.xlsx` · dataset=rem · sheets=1 · bytes=21090
- `2025/REM OCTUBRE 2025.xlsx` · dataset=rem · sheets=1 · bytes=21111
- `2025/REM SEPTIEMBRE 2025.xlsx` · dataset=rem · sheets=1 · bytes=21093
- `HOMOM 2025.xlsx` · dataset=resumen_hodom · sheets=14 · bytes=87339
- `HOMOM 2026.xlsx` · dataset=resumen_hodom · sheets=2 · bytes=27477
- `INGRESOS 2026 DRIVE` · dataset=ingresos_2026 · sheets=5 · bytes=142861
- `INVENTARIO INSUMOS.xlsx` · dataset=inventario_insumos · sheets=1 · bytes=21964
