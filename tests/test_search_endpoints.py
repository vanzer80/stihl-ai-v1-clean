import pytest

@pytest.mark.parametrize("code", ["1148-200-0249", "4134-200-0367", "0000-007-1043"])
def test_get_product_by_code(client, code):
    r = client.get(f"/api/search/product/{code}")
    assert r.status_code == 200
    j = r.get_json()
    assert j.get("success") is True
    assert "product" in j
    assert j["product"]["codigo_material"] == code

def test_price_ranges(client):
    r = client.get("/api/search/price-ranges")
    assert r.status_code == 200
    j = r.get_json()
    assert j.get("success") is True
    assert isinstance(j["price_ranges"], list)

def test_suggest(client):
    r = client.get("/api/search/suggest?q=ms")
    assert r.status_code == 200
    j = r.get_json()
    assert j.get("success") is True
    assert isinstance(j["suggestions"], list)

def test_recommendations(client):
    r = client.get("/api/search/recommendations")
    assert r.status_code == 200
    j = r.get_json()
    assert j.get("success") is True
    assert isinstance(j["recommendations"], list)
