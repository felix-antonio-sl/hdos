#!/usr/bin/env zsh
set -euo pipefail

cd /Users/felixsanhueza/Developer/_workspaces/hdos
.venv/bin/python scripts/build_hodom_enriched.py

# Paso 4: Generar capa canónica
.venv/bin/python scripts/build_hodom_canonical.py

echo "Iniciando dashboard en http://localhost:8502"
exec .venv/bin/streamlit run streamlit_app.py --server.port 8502 "$@"
