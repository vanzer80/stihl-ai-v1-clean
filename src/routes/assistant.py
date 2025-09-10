from flask import Blueprint, request, jsonify
from ..services.parts_assistant import search_and_format

bp_assistant = Blueprint("assistant", __name__)

@bp_assistant.route("/api/search/assistant", methods=["POST"])
def assistant_search():
    data = request.get_json(force=True, silent=True) or {}
    q = (data.get("q") or "").strip()
    if not q:
        return jsonify({"ok": False, "error": "missing q"}), 400
    res = search_and_format(q)
    return jsonify(res)
