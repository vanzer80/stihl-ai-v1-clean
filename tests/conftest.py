import os, pytest
from src.main import create_app

@pytest.fixture(scope="session")
def app():
    # usa .env da raiz (DATABASE_URL etc.) via create_app()
    return create_app()

@pytest.fixture()
def client(app):
    return app.test_client()
