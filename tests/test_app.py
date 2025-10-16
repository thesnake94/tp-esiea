import os, sys
sys.path.append(os.path.dirname(os.path.dirname(__file__)))  # ajoute la racine du repo au PYTHONPATH

from app import app

def test_health_route():
    client = app.test_client()
    r = client.get("/health")
    assert r.status_code == 200
    assert r.get_json().get("health") == "pass"
