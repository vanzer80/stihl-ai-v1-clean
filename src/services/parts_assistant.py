import os, psycopg2
from decimal import Decimal
from typing import Dict, List, Tuple
from .text_normalizer import extract_entities

def _conn():
    dsn = os.getenv("DATABASE_URL")
    return psycopg2.connect(dsn)

def _fmt_brl(v) -> str:
    if v is None:
        return "R$ 0,00"
    if isinstance(v, str):
        try:
            v = Decimal(v)
        except Exception:
            return f"R$ {v}"
    s = f"{v:,.2f}"
    return "R$ " + s.replace(",", "X").replace(".", ",").replace("X", ".")

def _fetch_pecas(ent: Dict, limit: int = 20) -> List[Dict]:
    where = []
    params = {"limit": limit}

    if ent.get("code"):
        where.append("codigo_material = %(code)s")
        params["code"] = ent["code"]

    if ent.get("part_type"):
        where.append("unaccent(lower(descricao)) ILIKE unaccent(lower(%(part)s))")
        params["part"] = f"%{ent['part_type']}%"

    if ent.get("spec"):
        where.append("unaccent(lower(descricao)) ILIKE unaccent(lower(%(spec)s))")
        params["spec"] = f"%{ent['spec']}%"

    model_clauses = []
    for i, m in enumerate(ent.get("models") or []):
        key = f"m{i}"
        model_clauses.append(f"upper(modelos_compatibilidade) LIKE %({key})s")
        params[key] = f"%{m.upper()}%"
    if model_clauses:
        where.append("(" + " OR ".join(model_clauses) + ")")

    if not where:
        where.append("unaccent(lower(descricao)) ILIKE unaccent(lower(%(q)s))")
        params["q"] = f"%{ent['normalized']}%"

    sql = f"""
        SELECT
            codigo_material,
            descricao,
            preco_real,
            COALESCE(qtde_mir, 0) AS qtde_mir,
            COALESCE(modelos_compatibilidade, '') AS modelos_compatibilidade
        FROM public.pecas
        WHERE {' OR '.join(where)}
        LIMIT %(limit)s
    """

    out: List[Dict] = []
    with _conn() as conn, conn.cursor() as cur:
        cur.execute(sql, params)
        for r in cur.fetchall():
            out.append({
                "codigo_material": r[0],
                "descricao": r[1] or "",
                "preco_real": r[2],
                "qtde_mir": r[3],
                "modelos_compatibilidade": r[4] or "",
            })
    return out

def _score_item(ent: Dict, item: Dict) -> int:
    desc = (item["descricao"] or "").lower()
    comp = (item["modelos_compatibilidade"] or "").upper()
    score = 0

    has_type = bool(ent.get("part_type") and ent["part_type"] in desc)
    has_model = False
    sim_model = False

    models = ent.get("models") or []
    for m in models:
        if m.upper() in comp:
            has_model = True
            break

    if not has_model and models:
        try:
            import re
            want = models[0].upper()
            pref = want[:2]
            mnum = re.findall(r"\d+", want)
            if mnum:
                num = int(mnum[0])
                for token in comp.split():
                    if token.startswith(pref):
                        digits = re.findall(r"\d+", token)
                        if digits and abs(int(digits[0]) - num) <= 1:
                            sim_model = True
                            break
        except Exception:
            pass

    if has_type and has_model:
        score = max(score, 100)
    elif has_type and sim_model:
        score = max(score, 70)
    elif has_type:
        score = max(score, 50)
    elif has_model:
        score = max(score, 60)

    if (item.get("qtde_mir") or 0) > 0:
        score += 5

    return min(score, 100)

def _fmt_compat(item: Dict) -> str:
    comp = item.get("modelos_compatibilidade") or ""
    comp = comp.replace(";", ", ").replace("|", ", ").strip().strip(",")
    return comp or "—"

def _reply_single(ent: Dict, item: Dict) -> Tuple[str, Dict]:
    txt = (
        "✅ *PEÇA ENCONTRADA*\n\n"
        f"*Código:* `{item['codigo_material']}`\n"
        f"*Descrição:* {item['descricao']}\n"
        f"*Valor:* {_fmt_brl(item['preco_real'])}\n"
        f"*Estoque:* {int(item['qtde_mir'])} unidade(s)\n"
        f"*Compatibilidade:* {_fmt_compat(item)}\n\n"
        f"---\n"
        f"_Consulta processada:_ \"{ent['original']}\" → \"{ent['normalized']}\""
    )
    return txt, {"type": "single", "item": item}

def _reply_multi(ent: Dict, items: List[Dict]) -> Tuple[str, Dict]:
    lines = [f"🔍 *MÚLTIPLAS OPÇÕES ENCONTRADAS*\n\nPara \"{ent['original']}\":\n"]
    for i, it in enumerate(items[:5], 1):
        lines.append(
            f"*{i}.* Código: `{it['codigo_material']}` | *{_fmt_brl(it['preco_real'])}* | {it['descricao']}\n"
            f"   └ Compatibilidade: {_fmt_compat(it)}\n"
        )
    lines.append("\n💡 *Qual opção você gostaria de saber mais detalhes?*")
    txt = "\n".join(lines)
    return txt, {"type": "multi", "items": items[:5]}

def _reply_none(ent: Dict, suggestions: List[Dict]) -> Tuple[str, Dict]:
    lines = [f"❌ *PEÇA NÃO ENCONTRADA*\n\nPara: \"{ent['original']}\"\n", "*🔧 Você quis dizer:*"]
    if ent.get("part_type"):
        lines.append(f"• {ent['part_type']} (verifique especificação)")
    if ent.get("models"):
        lines.append(f"• peças para {', '.join(ent['models'])}")
    if ent.get("spec"):
        lines.append(f"• {ent['spec']} (variações)")
    if suggestions:
        lines.append("\n*📋 Ou peças similares:*")
        for s in suggestions[:5]:
            lines.append(f"• `{s['codigo_material']}` - {s['descricao']} - {_fmt_brl(s['preco_real'])}")
    lines.append("\n💬 *Reformule sua pergunta ou escolha uma das opções acima.*")
    return "\n".join(lines), {"type": "none", "suggestions": suggestions[:5]}

def _reply_ambiguous(ent: Dict) -> Tuple[str, Dict]:
    base = ent['normalized']
    txt = (
        "🤔 *CONSULTA AMBÍGUA*\n\n"
        f"\"{base}\" pode se referir a:\n\n"
        "A) filtro de ar\n"
        "B) filtro de óleo\n"
        "C) filtro de combustível\n\n"
        "*Especifique qual tipo você procura para melhor resultado.*"
    )
    return txt, {"type": "ambiguous"}

def search_and_format(q: str) -> Dict:
    ent = extract_entities(q)
    if ent.get("part_type") == "filtro" and not ent.get("spec"):
        reply, meta = _reply_ambiguous(ent)
        return {"ok": True, "entities": ent, "reply_markdown": reply, "meta": meta}

    rows = _fetch_pecas(ent, limit=50)
    if not rows:
        suggestions = _fetch_pecas({**ent, "models": []}, limit=10) if ent.get("part_type") else []
        reply, meta = _reply_none(ent, suggestions)
        return {"ok": True, "entities": ent, "reply_markdown": reply, "meta": meta, "total": 0}

    scored = []
    for it in rows:
        s = _score_item(ent, it)
        scored.append((s, it))
    scored.sort(key=lambda x: x[0], reverse=True)

    top_score, top_item = scored[0]
    top_items = [it for s, it in scored if s >= max(60, top_score - 10)]

    if top_score >= 95 and len(top_items) == 1:
        reply, meta = _reply_single(ent, top_item)
        return {"ok": True, "entities": ent, "reply_markdown": reply, "meta": meta, "total": 1}

    reply, meta = _reply_multi(ent, top_items[:5])
    return {"ok": True, "entities": ent, "reply_markdown": reply, "meta": meta, "total": len(top_items)}
