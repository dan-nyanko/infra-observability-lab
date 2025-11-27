FROM python:3.11-slim

WORKDIR /app

# Install dependencies
RUN pip install flask prometheus_client

# Copy app code
COPY app.py /app/app.py

# Run the app
CMD ["python", "app.py"]