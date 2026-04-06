FROM python:3.12-slim
WORKDIR /app
RUN pip install --no-cache-dir streamlit pandas
COPY apps/streamlit_db_dashboard.py ./apps/
COPY db/schema.sql db/hdos.db ./db/
EXPOSE 8501
CMD ["streamlit", "run", "apps/streamlit_db_dashboard.py", "--server.port=8501", "--server.headless=true"]
