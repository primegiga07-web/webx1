FROM python:3.11-slim

# Install system dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Install Python dependencies
COPY ../requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy the shard app
COPY . .

# Collect static files
ENV DJANGO_SETTINGS_MODULE=shard.settings
RUN python manage.py collectstatic --noinput

EXPOSE 8000

CMD ["gunicorn", "shard.wsgi:application", "--bind", "0.0.0.0:8000", "--workers", "2", "--timeout", "60"]
