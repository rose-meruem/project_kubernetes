from fastapi.testclient import TestClient

from main import app


client = TestClient(app)


def test_create_retrieve_and_get_link_stats():
    create_response = client.post(
        "/links",
        json={"original_url": "https://example.com"},
    )

    assert create_response.status_code == 201

    created_link = create_response.json()

    assert "code" in created_link
    assert created_link["original_url"] == "https://example.com/"

    code = created_link["code"]

    retrieve_response = client.get(f"/links/{code}")

    assert retrieve_response.status_code == 200
    assert retrieve_response.json()["code"] == code
    assert retrieve_response.json()["original_url"] == "https://example.com/"

    stats_response = client.get(f"/links/{code}/stats")

    assert stats_response.status_code == 200
    assert stats_response.json()["code"] == code
    assert stats_response.json()["accesses"] == 1
