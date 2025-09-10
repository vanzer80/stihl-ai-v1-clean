import os, re
from decimal import Decimal

import psycopg2

DB_DSN = os.getenv("DATABASE_URL")
CODE_RE = re.compile(r"\b\d{4}-\d{3}-\d{4}\b")
MODEL_RE = re.compile(r"\b([A-Z]{2}\d{2,3})\b", re.I)
TYPE_WORDS = {"filtro", "carburador", "silenciador", "tampa", "luva"}
SPEC_TERMS = [
    "de ar", "do ar",
    "de oleo", "do oleo", "de óleo", "do óleo",
    "de combustivel", "do combustivel", "de combustível", "do combustível",
]

def _conn():
    if not DB_DSN:
        raise RuntimeError("DATABASE_URL não definido no ambiente")
    return psycopg2.connect(DB_DSN, connect_timeout=5)

def parse_query(q: str):
    s = (q or "").strip()
    code = None
    m = CODE_RE.search(s)
    if m:
        code = m.group(0)

    model = None
    m2 = MODEL_RE.search(s)
    if m2:
        model = m2.group(1).upper()

    low = s.lower()
    part_type = next((w for w in TYPE_WORDS if w in low), None)
    spec = next((t for t in SPEC_TERMS if t in low), None)

    return {"original": q, "normalized": s, "code": code, "model": model, "type": part_type, "spec": spec}

def _format_price(v):
    if v is None:
        return "R$ 0,00"
    if isinstance(v, Decimal):
        v = float(v)
    return f"R$ {v:,.2f}".replace(",", "X").replace(".", ",").replace("X", ".")

def _fetch(ent, limit=50):
    """
    Busca na VIEW public.pecas_public para evitar dependência de colunas internas.
    Colunas retornadas: codigo_material, descricao, preco_real, modelos
    """
    sql = """
    SELECT
      codigo_material,
      descricao,
      preco_real,
      COALESCE(modelos, '') AS modelos
    FROM public.pecas_public
    WHERE 1=1
    """
    params = []

    if ent["code"]:
        sql += " AND codigo_material = %s"
        params.append(ent["code"])

    if ent["model"]:
        sql += " AND modelos ILIKE %s"
        params.append(f"%{ent['model']}%")

    if ent["type"]:
        sql += " AND descricao ILIKE %s"
        params.append(f"%{ent['type']}%")

    if ent["spec"]:
        sql += " AND (descricao ILIKE %s OR modelos ILIKE %s)"
        params.extend([f"%{ent['spec']}%", f"%{ent['spec']}%"])

    # fallback: nenhuma pista? busca ampla no texto
    if len(params) == 0 and ent["normalized"]:
        sql += " AND (descricao ILIKE %s OR modelos ILIKE %s)"
        params.extend([f"%{ent['normalized']}%", f"%{ent['normalized']}%"])

    sql += " ORDER BY preco_real NULLS LAST, codigo_material LIMIT %s"
    params.append(limit)

    with _conn() as conn:
        with conn.cursor() as cur:
            cur.execute(sql, params)
            rows = cur.fetchall()

    result = []
    for codigo, desc, preco, modelos in rows:
        result.append(
            {
                "codigo": codigo,
                "descricao": desc,
                "preco": float(preco) if preco is not None else None,
                "modelos": modelos,
            }
        )
    return result

def search_and_format(q: str):
    ent = parse_query(q or "")
    items = _fetch(ent, limit=50)

    # Nenhum resultado
    if not items:
        texto = (
            "❌ **PEÇA NÃO ENCONTRADA**\n\n"
            f'Para: "{ent["normalized"]}"\n\n'
            "**🔧 Você quis dizer:**\n"
            "• filtro → filtro\n"
            "• carburador → carburador\n"
            "• silenciador → silenciador\n\n"
            "**📋 Ou peças similares:**\n"
            "• Pesquise por modelo (ex.: FS221) ou código (ex.: 4147-141-0300)\n\n"
            "💬 **Reformule sua pergunta ou envie mais detalhes.**"
        )
        return {"ok": True, "text": texto, "items": []}

    # Um resultado
    if len(items) == 1:
        it = items[0]
        texto = (
            "✅ **PEÇA ENCONTRADA**\n\n"
            f"**Código:** {it['codigo']}\n"
            f"**Descrição:** {it['descricao']}\n"
            f"**Valor:** {_format_price(it['preco'])}\n"
            f"**Estoque:** não informado\n"
            f"**Compatibilidade:** {it['modelos'] or '-'}\n\n"
            f"---\n*Consulta processada: \"{q}\" → \"{ent['normalized']}\"*"
        )
        return {"ok": True, "text": texto, "items": items[:1]}

    # Vários resultados (até 5 para exibir)
    top = items[:5]
    linhas = []
    for idx, it in enumerate(top, 1):
        linhas.append(
            f"**{idx}.** Código: {it['codigo']} | **{_format_price(it['preco'])}** | {it['descricao']}\n"
            f"   └ Compatible: {it['modelos'] or '-'}"
        )
    texto = (
        "🔍 **MÚLTIPLAS OPÇÕES ENCONTRADAS**\n\n"
        f'Para "{q}":\n\n' + "\n\n".join(linhas) + "\n\n"
        "💡 **Qual opção você gostaria de saber mais detalhes?**"
    )
    return {"ok": True, "text": texto, "items": top}
