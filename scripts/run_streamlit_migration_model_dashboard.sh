#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."
exec .venv/bin/streamlit run apps/streamlit_migration_model_dashboard.py "$@"
