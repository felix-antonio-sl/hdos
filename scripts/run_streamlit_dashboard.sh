#!/usr/bin/env zsh
set -euo pipefail

cd /Users/felixsanhueza/Developer/_workspaces/hdos
exec .venv/bin/streamlit run streamlit_app.py "$@"
