# Documentacion Legacy

Respaldo historico de planillas, formularios, entregas de turno, anexos clinicos y exportaciones no normalizadas.

## Uso esperado

- Preservar evidencia y contexto historico sin mezclarlo con la estructura operativa actual.
- Servir como fuente para scripts que extraen informacion retrospectiva.
- Mantener nombres originales cuando el valor archivistico o trazable sea mas importante que la prolijidad del nombre.

## Limite

No se documenta este arbol como API estable. Los pipelines activos deben consumir preferentemente `input/` y `output/`; cualquier dependencia a `documentacion-legacy/` debe explicitarse en el script correspondiente.
