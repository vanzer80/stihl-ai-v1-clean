import os, requests
from flask import Blueprint, request, jsonify, current_app

telegram_bp = Blueprint("telegram_webhook", __name__)

TELEGRAM_BOT_TOKEN = os.getenv("TELEGRAM_BOT_TOKEN", "")
TELEGRAM_WEBHOOK_SECRET = os.getenv("TELEGRAM_WEBHOOK_SECRET", "")
INTERNAL_API_BASE = os.getenv("INTERNAL_API_BASE", "http://127.0.0.1:5000/api/search")

def tg_api(method: str):
    if not TELEGRAM_BOT_TOKEN:
        raise RuntimeError("TELEGRAM_BOT_TOKEN ausente")
    return f"https://api.telegram.org/bot{TELEGRAM_BOT_TOKEN}/{method}"

def send_message(chat_id: int, text: str):
    try:
        payload = {"chat_id": chat_id, "text": text, "parse_mode": "HTML", "disable_web_page_preview": True}
        r = requests.post(tg_api("sendMessage"), json=payload, timeout=10)
        r.raise_for_status()
    except Exception as e:
        current_app.logger.exception(f"Erro ao enviar msg Telegram: {e}")

@telegram_bp.get("/webhook/health")
def webhook_health():
    return jsonify({"ok": True, "message": "telegram webhook up"}), 200

@telegram_bp.post("/webhook")
def webhook():
    # Proteção opcional por secret
    if TELEGRAM_WEBHOOK_SECRET and request.headers.get("X-Telegram-Bot-Api-Secret-Token") != TELEGRAM_WEBHOOK_SECRET:
        return jsonify({"ok": False, "error": "invalid secret"}), 403

    data = request.get_json(silent=True) or {}
    message = data.get("message") or {}
    chat = message.get("chat") or {}
    chat_id = chat.get("id")
    text = (message.get("text") or "").strip()

    if not chat_id:
        return jsonify({"ok": True}), 200

    # Comandos básicos
    if text.startswith("/start"):
        send_message(chat_id, "Olá! Sou o assistente STIHL AI. Envie o que procura (ex.: \"motosserra MS 162\").")
        return jsonify({"ok": True}), 200
    if text.startswith("/help"):
        send_message(chat_id, "Use /buscar <texto> ou apenas digite sua dúvida.\nEx.: /buscar corrente 3/8 para MS 170")
        return jsonify({"ok": True}), 200
    if text.startswith("/buscar"):
        text = text.replace("/buscar", "", 1).strip()

    if not text:
        send_message(chat_id, "Digite sua consulta (ex.: \"corrente 3/8 para MS 162\" ou \"peça 0000-007-1043\").")
        return jsonify({"ok": True}), 200

    # Chama a API interna de busca existente
    try:
        import json
        import time
        payload = {"query": text, "max_results": 5, "include_details": True, "natural_response": True}
        r = requests.post(f"{INTERNAL_API_BASE}/search", json=payload, timeout=15)
        r.raise_for_status()
        j = r.json()
    except Exception as e:
        current_app.logger.exception(f"Erro ao consultar API interna: {e}")
        send_message(chat_id, "Desculpe, não consegui buscar agora. Tente novamente em instantes.")
        return jsonify({"ok": True}), 200

    parts = []
    if j.get("natural_response"):
        parts.append(j["natural_response"])

    results = j.get("results") or []
    if results:
        parts.append("<b>Top resultados:</b>")
        for r in results[:5]:
            cod = r.get("codigo_material", "-")
            desc = r.get("descricao", "")
            preco = r.get("preco_real")
            cat = r.get("categoria_produto") or r.get("source_table", "")
            if isinstance(preco, (int, float)):
                preco_txt = f"R$ {preco:,.2f}".replace(",", "X").replace(".", ",").replace("X", ".")
            else:
                preco_txt = "-"
            parts.append(f"• <b>{cod}</b> — {desc} ({cat}) — {preco_txt}")

    if not parts:
        parts = ["Não encontrei itens para sua consulta. Tente ser mais específico."]

    send_message(chat_id, "\n".join(parts))
    return jsonify({"ok": True}), 200
