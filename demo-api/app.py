import os
from flask import Flask
from prometheus_client import Counter, generate_latest, CONTENT_TYPE_LATEST

app = Flask(__name__)
http_requests_total = Counter('http_requests_total', 'Total HTTP requests')

VERSION = os.getenv("VERSION", "v1")  # default to v1 if not set

@app.route('/')
def hello():
    http_requests_total.inc()
    return f"Hello from demo-api {VERSION}!"

@app.route('/metrics')
def metrics():
    return generate_latest(), 200, {'Content-Type': CONTENT_TYPE_LATEST}

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)