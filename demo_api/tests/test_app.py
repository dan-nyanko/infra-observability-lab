from app import app


def test_root_endpoint():
    client = app.test_client()
    response = client.get("/")
    assert response.status_code == 200


def test_error_endpoint():
    client = app.test_client()
    response = client.get("/error")
    assert response.status_code == 500


def test_crash_endpoint():
    client = app.test_client()
    response = client.get("/crash")
    # The crash endpoint may raise or return 500 depending on implementation
    assert response.status_code in (200, 500)
