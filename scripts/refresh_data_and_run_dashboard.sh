#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."
.venv/bin/python scripts/build_hodom_enriched.py

# Paso 4: Generar capa canónica
.venv/bin/python scripts/build_hodom_canonical.py

echo "Iniciando dashboard en http://localhost:8502"
exec .venv/bin/streamlit run apps/streamlit_dashboard.py --server.port 8502 "$@"
