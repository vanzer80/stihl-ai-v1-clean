from flask import Blueprint, request, jsonify, current_app
import os, requests
from src.services.parts_assistant import search_and_format

telegram_bp = Blueprint("telegram_bp", __name__, url_prefix="/bot/telegram")

@telegram_bp.get("/webhook/health")
def webhook_health():
    return jsonify({"ok": True, "message": "telegram webhook up"}), 200

def _check_secret():
    expected = os.getenv("TELEGRAM_SECRET_TOKEN") or os.getenv("TELEGRAM_WEBHOOK_SECRET")
    if not expected:
        return True
    got = request.headers.get("X-Telegram-Bot-Api-Secret-Token")
    return got == expected

def _send_message(token: str, chat_id: int | str, text: str):
    url = f"https://api.telegram.org/bot{token}/sendMessage"
    payload = {
        "chat_id": chat_id,
        "text": text,
        # Sem parse_mode para evitar erro de formatação por caracteres especiais
        # "parse_mode": "MarkdownV2",
        "disable_web_page_preview": True,
    }
    try:
        resp = requests.post(url, json=payload, timeout=10)
        if resp.status_code != 200:
            current_app.logger.error("TG sendMessage status=%s body=%s", resp.status_code, resp.text)
        return resp.status_code == 200
    except Exception as e:
        current_app.logger.exception("TG sendMessage exception: %s", e)
        return False

@telegram_bp.post("/webhook")
def telegram_webhook():
    if not _check_secret():
        return jsonify({"ok": False, "error": "unauthorized"}), 401

    token = os.getenv("TELEGRAM_BOT_TOKEN")
    if not token:
        current_app.logger.error("TELEGRAM_BOT_TOKEN ausente no ambiente")
        return jsonify({"ok": False, "error": "bot token missing"}), 500

    update = request.get_json(silent=True) or {}

    # Suporta mensagens padrão
    message = update.get("message") or update.get("edited_message") \
               or update.get("channel_post") or update.get("edited_channel_post")

    if not message:
        # Nada para responder — confirma 200 para Telegram não ficar reenviando
        return jsonify({"ok": True, "skipped": True}), 200

    chat = message.get("chat") or {}
    chat_id = chat.get("id")
    text = message.get("text") or ""

    # Comandos básicos
    if text.strip().lower() in ("/start", "/help"):
        help_text = (
            "Olá! 👋 Posso ajudar você a encontrar peças.\n\n"
            "Exemplos:\n"
            "• filtro de ar FS221\n"
            "• 4147-141-0300\n\n"
            "Envie o modelo, descrição ou código da peça."
        )
        if chat_id is not None:
            _send_message(token, chat_id, help_text)
        return jsonify({"ok": True}), 200

    # Integra com o assistente de peças
    try:
        result = search_and_format(text)
        answer = result.get("text") or "Não encontrei resultados para sua busca."
    except Exception as e:
        current_app.logger.exception("Erro no search_and_format: %s", e)
        answer = "Tive um erro ao processar sua solicitação. Tente novamente em instantes."

    if chat_id is not None:
        _send_message(token, chat_id, answer)

    # Sempre 200 para Telegram considerar entregue
    return jsonify({"ok": True}), 200
