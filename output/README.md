# Output

## Subdirectorios

- `spreadsheet/`: materializaciones tabulares del pipeline intermedio, enriquecido, canonico y modelos auxiliares.
- `reports/`: reportes narrativos o analiticos derivados.
- `clinical/`: salidas clinicas puntuales construidas desde los datos materializados.
- `active_patient_packets_2026-04-01/`: paquete historico generado para pacientes activos.
- `scans/`: resultados de digitalizacion y OCR, cuando existan.

## Criterio

`output/` contiene solo artefactos generados o exportados. Si un archivo pasa a ser fuente estable de trabajo, debe moverse a `input/reference` o `documentacion-legacy` segun corresponda.
