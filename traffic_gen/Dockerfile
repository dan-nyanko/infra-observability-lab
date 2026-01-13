FROM python:3.11-slim

WORKDIR /app
COPY traffic_gen.py .

COPY requirements.txt .
RUN pip install -r requirements.txt

CMD ["python", "traffic_gen.py"]
