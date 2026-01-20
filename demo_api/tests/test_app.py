import pytest
from app import create_app


def test_root_endpoint():
    app = create_app()
    client = app.test_client()
    response = client.get("/")
    assert response.status_code == 200


def test_error_endpoint(monkeypatch):
    monkeypatch.setenv("VERSION", "red")
    app = create_app()
    client = app.test_client()
    response = client.get("/error")
    assert response.status_code == 500


def test_crash_endpoint_red(monkeypatch):
    monkeypatch.setenv("VERSION", "red")
    app = create_app()
    client = app.test_client()

    # Crash endpoint should return 500 and set crash flag
    response = client.get("/crash")
    assert response.status_code == 500
    assert b"Crashed!" in response.data

    # Health check should now fail
    health_response = client.get("/healthz")
    assert health_response.status_code == 500
    assert b"Crashed" in health_response.data


def test_crash_endpoint_blue_green(monkeypatch):
    monkeypatch.setenv("VERSION", "blue")
    app = create_app()
    client = app.test_client()

    # Crash endpoint should return 200 for non-red versions
    response = client.get("/crash")
    assert response.status_code == 200
    assert b"No crash this time blue" in response.data

    # Health check should still pass
    health_response = client.get("/healthz")
    assert health_response.status_code == 200
    assert b"OK" in health_response.data
