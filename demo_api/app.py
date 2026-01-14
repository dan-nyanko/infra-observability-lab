import os
import random
import sys
import time

from flask import Flask
from prometheus_client import (
    CONTENT_TYPE_LATEST,
    CollectorRegistry,
    Counter,
    Histogram,
    generate_latest,
    multiprocess,
)


def create_app():
    # Create a fresh registry for each app instance (prevents duplicate metrics)
    registry = CollectorRegistry()

    # If using multiprocess mode (Gunicorn), load metrics correctly
    if "prometheus_multiproc_dir" in os.environ:
        multiprocess.MultiProcessCollector(registry)

    app = Flask(__name__)

    # Read VERSION at app creation time, not import time
    version = os.getenv("VERSION", "blue")
    latency_threshold = 1.0

    # Define metrics inside the factory so they bind to this registry
    http_requests_total = Counter(
        "http_requests_total",
        "Total HTTP requests",
        ["status", "version"],
        registry=registry,
    )

    http_request_latency_seconds = Histogram(
        "http_request_latency_seconds",
        "Request latency in seconds",
        ["version"],
        registry=registry,
    )

    slow_requests_total = Counter(
        "slow_requests_total",
        "Requests exceeding latency threshold",
        ["version"],
        registry=registry,
    )

    @app.route("/")
    def hello():
        start = time.time()
        duration = time.time() - start

        http_request_latency_seconds.labels(version=version).observe(duration)

        if duration > latency_threshold:
            slow_requests_total.labels(version=version).inc()

        http_requests_total.labels(status="200", version=version).inc()

        return f"Hello from demo-api {version}!"

    @app.route("/error")
    def error():
        if version == "red":
            http_requests_total.labels(status="500", version=version).inc()
            return "Simulated error!", 500

        http_requests_total.labels(status="200", version=version).inc()
        return f"No error this time {version}", 200

    @app.route("/crash")
    def crash():
        if version == "red":
            sys.exit(1)
        return f"No crash this time {version}", 200

    @app.route("/metrics")
    def metrics():
        return generate_latest(registry), 200, {"Content-Type": CONTENT_TYPE_LATEST}

    @app.route("/healthz")
    def healthz():
        return "OK", 200

    @app.route("/readyz")
    def readyz():
        return "Ready", 200

    return app


if __name__ == "__main__":
    app = create_app()
    app.run(host="0.0.0.0", port=5000)
