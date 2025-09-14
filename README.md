# Sistema de Busca Inteligente STIHL AI v1 — Implantação (API + WhatsApp + Telegram + PDFs)

## 🎯 Visão Geral
O **STIHL AI v1** permite buscar **peças, códigos, preços e compatibilidades** de produtos STIHL via **API Flask**, **WhatsApp** e **Telegram**.  
Agora o sistema consulta **vistas explodidas em PDF** (manuais/catálogos) para **confirmar códigos e posições** de peças, citando **fonte e página**.

**Componentes**
- Backend: **Flask** (`intelligent_search_v5.py`) + Gunicorn
- Banco: **PostgreSQL (Supabase)** — tabelas catálogo + **pgvector** para PDFs
- Armazenamento: **Supabase Storage** (bucket `manuals/` para PDFs/imagens)
- Canais: **WhatsApp Business API** e **Telegram Bot**
- Proxy: **Caddy** (alternativa: Nginx)

**Repositório**: `https://github.com/vanzer80/stihl-ai-v1-clean`  
**VPS (padrão)**: `/home/ubuntu/stihl_ai_v1_consolidated_output/`

---

## 🧱 Estrutura de Pastas (VPS)
- `01_create_tables_v5.sql` — tabelas catálogo/peças  
- `02_create_functions_v5.sql` — funções/procedures  
- `04_security_rls_v5.sql` — políticas RLS catálogo  
- `05_import_csv_data_v5.sql` — importação CSV com `\copy`  
- `06_docs_schema.sql` — **NOVO**: esquema PDFs (docs/doc_pages/doc_chunks/part_refs)  
- `csv_data/` — CSVs originais  
- `requirements.txt` — dependências Python  
- `intelligent_search_v5.py` — **entrypoint** backend (validar no deploy)  
- `execution_log_v1.txt` — log de implantação  
- `prompt_for_next_ai_v1.md` / `master_prompt_for_cursor_ai.md` — contexto/roadmap

---

## 🔐 Variáveis de Ambiente (NUNCA no README público)
Crie um `.env` com:
SUPABASE_URL=...
SUPABASE_ANON_KEY=...
SUPABASE_SERVICE_ROLE_KEY=...
SUPABASE_DB_URL=postgres://<user>:<pass>@aws-1-sa-east-1.pooler.supabase.com:6543/postgres
EMBEDDINGS_PROVIDER=openai|azure|local
EMBEDDINGS_DIM=1536

bash
Copiar código

**(VPS)**
```bash
# carregar env (exemplo)
set -a; source /path/to/.env; set +a
🗄️ Banco de Dados — Catálogo (Supabase)
Use 01_create_tables_v5.sql, 02_create_functions_v5.sql e 04_security_rls_v5.sql.

Problema conhecido: rocadeiras_e_impl.csv falha por codigo_material nulo.

Qualidade de Dados antes de importar
(Mint/WSL/PC)

bash
Copiar código
# ver nulos, linhas vazias e contagem distinta do codigo_material
csvcut -n rocadeiras_e_impl.csv | cat
# ajuste sugerido: preencher codigo_material ausente ou remover linhas inválidas
(Editor SQL do Supabase) – alternativa (forçar limpeza mínima, se optar):

sql
Copiar código
-- Permitir staging temporário sem NOT NULL, tratar e mover p/ tabela final.
-- Recomendado: concertar o CSV na origem. Não alterar constraint de produção.
(VPS)

bash
Copiar código
# Importar somente após saneamento
psql "$SUPABASE_DB_URL" -f 05_import_csv_data_v5.sql
📚 PDFs de Vistas Explodidas — Esquema e ETL
Extensões e Tabelas
(Editor SQL do Supabase)

sql
Copiar código
create extension if not exists pg_trgm;
create extension if not exists vector;

create table if not exists docs (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  model_norm text,              -- ex.: 'FS 220'
  source text,
  storage_path text not null,   -- 'manuals/.../arquivo.pdf'
  page_count int,
  created_at timestamptz default now()
);

create table if not exists doc_pages (
  doc_id uuid references docs(id) on delete cascade,
  page_no int not null,
  text_content text,
  image_path text,              -- 'manuals/.../pages/arquivo-pNN.png'
  primary key (doc_id, page_no)
);

-- Ajuste EMBEDDINGS_DIM conforme seu provedor (padrão 1536)
create table if not exists doc_chunks (
  id bigserial primary key,
  doc_id uuid references docs(id) on delete cascade,
  page_no int not null,
  chunk_no int not null,
  chunk_text text not null,
  embedding vector(1536)
);

create table if not exists part_refs (
  part_number text not null,
  doc_id uuid references docs(id) on delete cascade,
  page_no int not null,
  callout_label text,
  bbox jsonb,                   -- {"x":0.12,"y":0.34,"w":0.08,"h":0.07}
  notes text,
  primary key (part_number, doc_id, page_no, callout_label)
);

create index if not exists idx_docs_model on docs using gin (model_norm gin_trgm_ops);
create index if not exists idx_doc_pages_text on doc_pages using gin (text_content gin_trgm_ops);
create index if not exists idx_doc_chunks_doc_page on doc_chunks (doc_id, page_no);

-- exemplo de busca semântica (cosine)
create or replace function search_doc_chunks(q vector(1536), k int default 10)
returns table (doc_id uuid, page_no int, chunk_no int, chunk_text text, score float)
language sql stable as $$
  select c.doc_id, c.page_no, c.chunk_no, c.chunk_text,
         1 - (c.embedding <=> q) as score
  from doc_chunks c
  order by c.embedding <=> q
  limit k
$$;

-- RLS (ajuste conforme sua auth):
alter table docs enable row level security;
alter table doc_pages enable row level security;
alter table doc_chunks enable row level security;
alter table part_refs enable row level security;

create policy "public_read_docs"       on docs       for select using (true);
create policy "public_read_doc_pages"  on doc_pages  for select using (true);
create policy "public_read_doc_chunks" on doc_chunks for select using (true);
create policy "public_read_part_refs"  on part_refs  for select using (true);
Bucket no Storage
(Supabase Console → Storage)

Criar bucket manuals (leitura pública ou assinada, conforme estratégia).

storage_path: manuals/stihl/<modelo>/arquivo.pdf

image_path: manuals/stihl/<modelo>/pages/arquivo-pNN.png

ETL de PDFs (upload, render, OCR, chunks, embeddings)
(VPS)

bash
Copiar código
mkdir -p /opt/stihl-pdf-ingest && cd /opt/stihl-pdf-ingest
python3 -m venv .venv && source .venv/bin/activate
pip install pymupdf psycopg2-binary supabase Pillow tiktoken
(VPS)

bash
Copiar código
# Executar: python ingest_pdf.py /tmp/SR430.pdf "SR 430" "SR 430 - Exploded View" "stihl.com"
# O script deve:
# 1) subir PDF no bucket 'manuals'
# 2) gerar PNG por página
# 3) extrair texto
# 4) chunkear + gerar embeddings (dim == EMBEDDINGS_DIM)
# 5) popular docs/doc_pages/doc_chunks
Modelo CSV p/ part_refs (opcional)

sql
Copiar código
part_number,model_norm,doc_title,page_no,callout_label,bbox_json,notes
1234-567-8900,SR 430,SR 430 - Exploded View,3,"12","{""x"":0.12,""y"":0.34,""w"":0.08,""h"":0.07}","Impulsor"
(VPS)

bash
Copiar código
psql "$SUPABASE_DB_URL" -c "\copy part_refs FROM '/tmp/part_refs.csv' csv header"
🔎 Normalização e Regras de Busca
Modelos: FS220 → FS 220 (inserir espaço entre letras/números; prefixos em maiúsculas)

Ruído: remover sufixos como (110/220V), /C, etc.

Sinônimos: ex.: “cabeçote de corte” ≈ “autocut”; “carcaça do ventilador” ≈ “blower housing”

Rank fusion: combinar resultado do catálogo (precisão por código/descrição) com PDFs (confirmação por página/callout)

🧩 API — Endpoints
GET /api/parts/search?q=&model= → busca catálogo (código/descrição/compat)

GET /api/parts/refs?part_number= → onde aparece nos manuais (doc_id, page, callout, bbox)

GET /api/docs/search?q=&model=&k=10 → busca semântica em doc_chunks

GET /api/docs/page?doc_id=&page_no= → retorna texto + URLs (PDF e imagem da página)

Resposta deve sempre “CITAR A FONTE”: manual + página, e retornar link da página (Storage).

💬 Canais (WhatsApp / Telegram)
WhatsApp (cliente final): respostas curtas, preço/código, link da página; se ambíguo → pedir foto ou nº do item.

Telegram (técnico): listas, múltiplos resultados, anexar PDF ou imagem da página, detalhar especificações.

Escalonamento (mensagem padrão):

“Para garantir total precisão, vou conectar você com nosso especialista. Ele já receberá: [resumo das informações coletadas].”

🚀 Deploy do Backend
Dependências
(VPS)

bash
Copiar código
cd /home/ubuntu/stihl_ai_v1_consolidated_output
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
Execução local
(VPS)

bash
Copiar código
export FLASK_APP=intelligent_search_v5.py
flask run --host 0.0.0.0 --port 8000
Gunicorn (produção)
(VPS)

bash
Copiar código
pip install gunicorn
gunicorn -w 3 -b 127.0.0.1:8000 intelligent_search_v5:app
Caddy (reverse proxy)
(VPS)

bash
Copiar código
# Exemplo Caddyfile (ajuste domínio/https conforme tua infra)
:80 {
  route /api/* {
    reverse_proxy 127.0.0.1:8000
  }
  # Opcional: servir /healthz
}
(Alternativa Nginx disponível, mas preferimos Caddy por já estar na tua stack.)

✅ Testes Rápidos (smoke)
(VPS)

bash
Copiar código
curl "http://127.0.0.1:8000/api/parts/search?q=carcaca%20ventilador&model=SR%20430"
curl "http://127.0.0.1:8000/api/docs/search?q=carcaca%20ventilador&model=SR%20430&k=5"
curl "http://127.0.0.1:8000/api/parts/refs?part_number=1234-567-8900"
Critérios: resposta cita manual+página, traz link da imagem, e não inventa informação.

🔒 Segurança
RLS habilitado (catálogo e PDFs)

anon vs service-role:

Bots/API pública → anon com SELECT restrito

ETL → service-role (upload, inserções)

Segredos apenas no .env / gerenciador de segredos

Sanitizar inputs (SQL params, não string concat)

🗺️ Próximas Tarefas (ordem sugerida)
Sanear rocadeiras_e_impl.csv e concluir importação de todos os CSVs.

Criar bucket manuals/ e ingestar o PDF de exemplo.

Implementar get_embedding() no ETL (dim == EMBEDDINGS_DIM).

Publicar endpoints /api/docs/* e /api/parts/refs.

Ajustar respostas dos bots para citar manual+página e anexar imagem.

Configurar Webhooks: WhatsApp Business API e Telegram Bot.

Observabilidade: logs por canal + Uptime-Kuma.

Documentar sinônimos e regras de normalização (manter arquivo dedicado).

📌 Notas Finais
Se a IA não tiver certeza absoluta, não responde com suposição: pede mais detalhes ou escalona para humano.

Manter coerência de nomenclatura: repo, pasta VPS, entrypoint.

Todas as respostas devem ser auditáveis (citar fontes).
