FROM python:3.11-slim

WORKDIR /app
COPY traffic_gen.py .

RUN pip install requests

CMD ["python", "traffic_gen.py"]
