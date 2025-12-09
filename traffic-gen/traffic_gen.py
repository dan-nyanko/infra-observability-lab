import os
import random
import time

import requests

SERVICE_URL = os.getenv(
    "SERVICE_URL", "http://demo-api.observability.svc.cluster.local"
)
BASE_INTERVAL = float(os.getenv("INTERVAL", "1.0"))  # seconds between requests
JITTER = float(os.getenv("INTERVAL_JITTER", "0.5"))  # max +/- variation
TRAFFIC_MODE = os.getenv("TRAFFIC_MODE", "good")  # "good", "error", or "crash"
CRASH_INTERVAL = int(
    os.getenv("CRASH_INTERVAL", "30")
)  # seconds between crash triggers
BURST_CHANCE = float(os.getenv("BURST_CHANCE", "0.1"))  # 10% chance to trigger a burst
BURST_SIZE = int(os.getenv("BURST_SIZE", "5"))  # number of extra requests in a burst

last_crash_time = 0


def sleep_with_jitter():
    delay = random.uniform(BASE_INTERVAL - JITTER, BASE_INTERVAL + JITTER)
    if delay < 0:  # safety guard
        delay = 0.1
    time.sleep(delay)


def send_request(route, label):
    url = f"{SERVICE_URL}{route}"
    try:
        resp = requests.get(url, timeout=5)
        print(f"[{label}] Hit {url} -> {resp.status_code}")
    except Exception as e:
        print(f"[{label}] Request failed: {e}")
    sleep_with_jitter()


def maybe_burst(route, label):
    if random.random() < BURST_CHANCE:
        print(f"[BURST] Triggering {BURST_SIZE} extra {label} requests")
        for _ in range(BURST_SIZE):
            send_request(route, f"{label}-BURST")


def good_traffic():
    send_request("/", "GOOD")
    maybe_burst("/", "GOOD")


def error_traffic():
    send_request("/error", "ERROR")
    maybe_burst("/error", "ERROR")


def crash_traffic():
    global last_crash_time
    now = time.time()

    # Always send some normal traffic
    send_request("/", "CRASH-NORMAL")
    maybe_burst("/", "CRASH-NORMAL")

    # Trigger a crash every CRASH_INTERVAL seconds
    if now - last_crash_time >= CRASH_INTERVAL:
        send_request("/crash", "CRASH-TRIGGER")
        last_crash_time = now


def main():
    print(f"Starting traffic generator in mode: {TRAFFIC_MODE}")
    while True:
        if TRAFFIC_MODE == "good":
            good_traffic()
        elif TRAFFIC_MODE == "error":
            error_traffic()
        elif TRAFFIC_MODE == "crash":
            crash_traffic()
        else:
            print(f"Unknown TRAFFIC_MODE={TRAFFIC_MODE}, defaulting to good traffic")
            good_traffic()


if __name__ == "__main__":
    main()
