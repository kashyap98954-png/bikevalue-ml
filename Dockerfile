# Force rebuild
FROM python:3.12.6-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install -r requirements.txt

COPY . .

EXPOSE 5000

CMD ["python", "ml_api.py"]
