FROM python:3.11-slim

WORKDIR /app

# Copy api directory
COPY api/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY api/ .

# Create data directory for SQLite
RUN mkdir -p /app/data

EXPOSE 8000

CMD ["python", "main.py"]


# v9c48378
