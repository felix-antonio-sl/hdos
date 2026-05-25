# Especificacion de metricas anuales HODOM: atenciones y usuarios

Fuente Drive: https://drive.google.com/drive/folders/1P6ur0dHwmECADUluzwfVvA5g9uTO9oVe?usp=sharing
Generado: 2026-05-25T17:56:15+00:00

## Resultado principal desde REM

| Año | Periodos REM | Atenciones REM (visitas) | Usuarios REM (personas atendidas, suma mensual) | Ingresos REM | Días persona |
| --- | ---: | ---: | ---: | ---: | ---: |
| 2023 | 5 | 5048 | 292 | 292 | 3523 |
| 2024 | 12 | 12139 | 1559 | 852 | 6504 |
| 2025 | 12 | 9428 | 756 | 628 | 5480 |

## Usuarios unicos disponibles

| Año | Usuarios/ingresos con identificador unico | Fuente | Nota |
| --- | ---: | --- | --- |
| 2023 | 340 | Certificado PACIENTES 2023.docx | Ingresos segundo semestre; no entrega usuarios unicos anuales. |
| 2024 | 707 | Planillas nominales 2024 por RUT | 858 ingresos; 1 sin RUT. |
| 2025 | 559 | Base local clinical.estadia | 634 estadias ingresadas. Planilla nominal parcial: 500 ingresos, 445 RUT unicos, 2 sin RUT. |

## Contraste 2025

- HODOM 2025 resumen diario: 637 ingresos.
- Planilla nominal 2025 `INGRESOS 2025 (3).xlsx`: 500 ingresos con fecha 2025 y 445 RUT unicos.
- Base local 2025: 5457 filas en `operational.visita`, 523 usuarios con visita registrada.
- Base local 2025: 0 visitas en estados realizadas/REM; por eso no se usa como fuente principal de atenciones efectivas.

## Banderas de calidad

- [review] rem_coverage_gap · year=2023; missing_periods=['2023-01', '2023-02', '2023-03', '2023-04', '2023-05', '2023-06', '2023-12']
- [review] rem_personas_atendidas_outlier_high · period=2024-02; ingresos=59; personas_atendidas=656
- [review] rem_personas_atendidas_exceeds_dias · period=2024-02; personas_atendidas=656; dias_persona=629
- [review] rem_personas_atendidas_outlier_low · period=2025-02; ingresos=47; personas_atendidas=21
- [review] source_discrepancy_2024_ingresos · rem_ingresos=852; nominal_admissions=858
- [review] source_discrepancy_2025_ingresos · rem_ingresos=628; hodom_daily_admissions=637
- [review] nominal_2025_coverage_gap · missing_periods=['2025-11', '2025-12']; nominal_admissions=500
- [review] source_discrepancy_2025_nominal_vs_rem · rem_ingresos=628; nominal_admissions=500
- [info] db_visits_not_realized_for_rem · year=2025; visitas_rows=5457; visitas_realizadas=0

## Criterios

- `Atenciones REM` suma las visitas de la seccion C.2 por profesion.
- `Usuarios REM` es suma mensual de `Personas Atendidas`; no equivale a usuarios unicos anuales si una persona aparece en mas de un mes.
- Esta especificacion es la fuente normativa versionada para consultas agregadas previas a migracion.
- Las fuentes nominales se usan solo para conteo agregado; no se exportan RUT, nombres ni filas identificables.
