def test_health(client):
    r = client.get("/api/health")
    assert r.status_code == 200
    j = r.get_json()
    assert j.get("status") == "ok"

def test_search_health(client):
    r = client.get("/api/search/health")
    assert r.status_code == 200
    j = r.get_json()
    assert j.get("success") is True
