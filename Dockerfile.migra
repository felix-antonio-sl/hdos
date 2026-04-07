FROM python:3.12-slim
WORKDIR /app
RUN pip install --no-cache-dir streamlit pandas "psycopg[binary]>=3.1" pydeck
COPY apps/streamlit_migration_explorer.py ./apps/
EXPOSE 8501
CMD ["streamlit", "run", "apps/streamlit_migration_explorer.py", "--server.port=8501", "--server.headless=true"]
