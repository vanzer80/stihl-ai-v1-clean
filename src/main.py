import os
import sys
from flask import Flask, jsonify, send_from_directory
from flask_cors import CORS

# Garantir import do pacote src/*
sys.path.insert(0, os.path.dirname(os.path.dirname(__file__)))

# Importa blueprint e inicializador do motor de busca v5
from routes.search_api_v5 import search_bp, init_search_engine

def create_app():
    app = Flask(__name__, static_folder=os.path.join(os.path.dirname(__file__), 'static'))
    app.config['SECRET_KEY'] = os.getenv('SECRET_KEY', 'change-me')
    app.config['MAX_CONTENT_LENGTH'] = 50 * 1024 * 1024  # 50MB

    # CORS global (ajuste origens via ENV, ex: "https://dominio.com, http://localhost:5173")
    CORS(app, resources={r"/api/*": {"origins": os.getenv("CORS_ORIGINS", "*").split(",")}})

    # Inicializa motor de busca (usa DATABASE_URL)
    database_url = os.getenv('DATABASE_URL')
    if database_url:
        init_search_engine(database_url)
    else:
        app.logger.warning("DATABASE_URL não definido; endpoints de busca podem falhar.")

    # Healthcheck simples
    @app.get("/api/health")
    def health():
        return jsonify({"status": "ok", "database_url": bool(database_url)}), 200

    # Config pública
    @app.get("/api/config")
    def config_public():
        return jsonify({
            "version": "5.0",
            "cors_origins": os.getenv("CORS_ORIGINS", "*"),
        }), 200

    # Registrar rotas de busca sob /api/search
    app.register_blueprint(search_bp)

    # Servir arquivos estáticos de src/static
    @app.route('/', defaults={'path': ''})
    @app.route('/<path:path>')
    def serve(path):
        static_folder_path = app.static_folder
        if static_folder_path is None:
            return "Static folder not configured", 404
        if path != "" and os.path.exists(os.path.join(static_folder_path, path)):
            return send_from_directory(static_folder_path, path)
        else:
            index_path = os.path.join(static_folder_path, 'index.html')
            if os.path.exists(index_path):
                return send_from_directory(static_folder_path, 'index.html')
            else:
                return "index.html not found", 404

    return app

if __name__ == "__main__":
    app = create_app()
    app.run(host='0.0.0.0', port=int(os.getenv("PORT", "5000")), debug=os.getenv("FLASK_ENV") != "production")
