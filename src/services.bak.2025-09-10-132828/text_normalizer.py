import re, unicodedata
from typing import Dict, List

PART_TYPES = [
    "filtro", "carburador", "silenciador", "tampa", "luva",
    "engrenagem", "plaqueta", "junta", "pistão", "pistao",
    "lâmina", "lamina", "corrente", "sabre", "pinhão", "pinhao",
]

TYPO_FIX = {
    "fitro": "filtro",
    "carbirador": "carburador",
    "silencador": "silenciador",
    "filt": "filtro",
    "carb": "carburador",
    "silenc": "silenciador",
}

SPEC_PATTERNS = [
    "de ar", "do ar",
    "de óleo", "do óleo", "de oleo", "do oleo",
    "de combustível", "do combustível", "de combustivel", "do combustivel",
]

CODE_RE = re.compile(r"\b\d{4}-\d{3}-\d{4}\b")
MODEL_RE = re.compile(r"\b([A-Z]{2}\d{2,3})\b", re.I)  # MS162, FS221, FR410 etc.

def _strip_accents(s: str) -> str:
    return "".join(
        c for c in unicodedata.normalize("NFD", s)
        if unicodedata.category(c) != "Mn"
    )

def normalize_input(q: str) -> str:
    s = _strip_accents(q or "").lower()
    s = re.sub(r"\s+", " ", s).strip()
    fixed = [TYPO_FIX.get(tok, tok) for tok in s.split()]
    s = " ".join(fixed)
    return s

def extract_entities(q: str) -> Dict:
    original = (q or "").strip()
    normalized = normalize_input(original)

    code = None
    m = CODE_RE.search(original)
    if m:
        code = m.group(0)

    models: List[str] = []
    for m in MODEL_RE.finditer(original.upper()):
        models.append(m.group(1))

    part_type = None
    for p in PART_TYPES:
        if p in normalized:
            part_type = p
            break

    spec = None
    for s in SPEC_PATTERNS:
        if s in normalized:
            spec = s.replace("oleo", "óleo").replace("combustivel", "combustível")
            break

    return {
        "original": original,
        "normalized": normalized,
        "code": code,
        "models": sorted(set(models)),
        "part_type": part_type,
        "spec": spec,
    }
