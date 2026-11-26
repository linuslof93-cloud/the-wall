FROM docker.io/library/python:3.12-slim

WORKDIR /app

COPY requirements.txt .

RUN pip install --no-cache-dir -r requirements.txt

COPY app.py .

RUN chgrp -R 0 /app && chmod -R g=u /app

EXPOSE 8080

CMD ["sh", "-c", "python -c 'from app import initialize; initialize()' && exec gunicorn --bind 0.0.0.0:8080 app:app"]
