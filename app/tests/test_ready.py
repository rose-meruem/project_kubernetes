from fastapi.testclient import TestClient

from main import app


client = TestClient(app)


def test_ready_returns_ok_when_database_is_reachable():
    response = client.get("/ready")

    assert response.status_code == 200
    assert response.json()["status"] == "ok"
    assert response.json()["db"] == "reachable"
