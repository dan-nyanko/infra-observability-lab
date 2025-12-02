import os, sys
from flask import Flask
from prometheus_client import Counter, Histogram, generate_latest, CONTENT_TYPE_LATEST
import random, time

app = Flask(__name__)

# Track total requests by status/version
http_requests_total = Counter("http_requests_total", "Total HTTP requests", ["status", "version"])

# Histogram for latency distribution
http_request_latency_seconds = Histogram(
    "http_request_latency_seconds",
    "Request latency in seconds",
    ["version"]
)

# Counter for "slow" requests above threshold
slow_requests_total = Counter(
    "slow_requests_total",
    "Requests exceeding latency threshold",
    ["version"]
)

VERSION = os.getenv("VERSION", "blue")  # default to "blue" if not set
LATENCY_THRESHOLD = 1.0  # seconds

@app.route('/')
def hello():
    start = time.time()
    duration = time.time() - start

    # Record latency in histogram
    http_request_latency_seconds.labels(version=VERSION).observe(duration)

    # Increment slow counter if above threshold
    if duration > LATENCY_THRESHOLD:
        slow_requests_total.labels(version=VERSION).inc()

    # Always increment total requests
    #   NOTE: Prometheus labels are always strings. Even numeric values like HTTP 
    #   status codes should be stored as strings for consistency and compatibility
    #   with PromQL queries.
    http_requests_total.labels(status="200", version=VERSION).inc()

    return f"Hello from demo-api {VERSION}!"

@app.route("/error")
def error():
    # Only red version errors
    if VERSION == "red":
        http_requests_total.labels(status="500", version=VERSION).inc()
        return "Simulated error!", 500
    else:
        http_requests_total.labels(status="200", version=VERSION).inc()
        return f"No error this time {VERSION}", 200
    
@app.route("/crash")
def crash():
    # Only red version crashes
    #   NOTE: Application metrics (like request counts) require explicit instrumentation
    #    with .inc(). But container lifecycle metrics (like restarts or crash reasons)
    #    are automatically exported by Kubernetes and scraped by Prometheus. That’s why
    #    you’ll see crash loops in Grafana without adding .inc() in your code
    if VERSION == "red":
        sys.exit(1)  # force container exit
    return "No crash this time {VERSION}", 200

@app.route('/metrics')
def metrics():
    return generate_latest(), 200, {'Content-Type': CONTENT_TYPE_LATEST}

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)