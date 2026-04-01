# Snapshots Manuales De Localidades INE

El pipeline enriquecido busca automáticamente snapshots exportados manualmente desde las capas oficiales del INE para completar coordenadas de localidades.

## Archivos esperados

Coloca uno de estos formatos para cada capa:

- `ine_localidad_rural_nuble.geojson`
- `ine_localidad_rural_nuble.json`
- `ine_localidad_rural_nuble.csv`
- `ine_entidad_rural_nuble.geojson`
- `ine_entidad_rural_nuble.json`
- `ine_entidad_rural_nuble.csv`

## Fuente oficial

- `Localidad Rural Indeterminada Censo 2017 Región de Ñuble`
  https://geoine-ine-chile.opendata.arcgis.com/datasets/a38eda47692e43999559aea6e0d3f7cc_138

- `Entidad Rural Indeterminada Censo 2017 Región de Ñuble`
  https://geoine-ine-chile.opendata.arcgis.com/datasets/a38eda47692e43999559aea6e0d3f7cc_154

## Columnas esperadas si exportas CSV

El loader intenta reconocer automáticamente nombres como:

- `nombre`, `nombre_oficial`, `localidad`, `entidad`, `name`
- `comuna`, `nom_comuna`, `municipio`
- `latitud`, `lat`, `y`
- `longitud`, `lon`, `lng`, `x`

## Regeneración

Después de dejar los snapshots en esta carpeta:

```bash
python3 /Users/felixsanhueza/Developer/_workspaces/hdos/scripts/build_hodom_enriched.py
```
