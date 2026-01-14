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


def test_crash_endpoint(monkeypatch):
    monkeypatch.setenv("VERSION", "red")
    app = create_app()
    client = app.test_client()

    with pytest.raises(SystemExit):
        client.get("/crash")
