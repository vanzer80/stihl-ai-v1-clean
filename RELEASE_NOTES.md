# STIHL AI – Release v0.7.0 (2025-09-10)

## ✨ Destaques
- **feat(webhook-telegram):** blueprint dedicado com health check e suporte a header secreto `X-Telegram-Bot-Api-Secret-Token`.
- **fix(parts-assistant):** alinhamento ao esquema real da tabela `pecas`; remoção de colunas inexistentes/indesejadas.
- **sec/isolation:** isolamento do campo sensível `qtde_min` (mantido no banco, mas **não lido nem exposto** pela API).

## 🔧 Mudanças Técnicas
- `src/routes/telegram_webhook.py`
  - `GET /bot/telegram/webhook/health`
  - `POST /bot/telegram/webhook` com validação opcional via `TELEGRAM_SECRET_TOKEN` (ou `TELEGRAM_WEBHOOK_SECRET`).
- `src/services/parts_assistant.py`
  - Removidas referências a `qtde_mir` e `modelos_compatibilidade`.
  - Uso apenas de colunas existentes: `codigo_material`, `descricao`, `modelos`, `preco_real`.
  - **Não** consultar nem expor `qtde_min`.
- `src/routes/assistant.py`
  - Busca ajustada para normalização simples (código, descrição, modelos).

## 🛡️ Operação & Segurança
- Variável `TELEGRAM_SECRET_TOKEN` pode ser persistida em `/etc/stihl-ai.env`.
- Cloudflare Tunnel continua apontando para `127.0.0.1:5000`.

## 🗃️ Banco de Dados
- **Sem migração obrigatória**. Apenas padronização de consultas conforme o esquema atual.

## ✅ Testes Recomendados
- Health local/externo: `GET /api/health`
- Health do webhook: `GET /bot/telegram/webhook/health`
- Busca assistente:
  - Código exato: `{"q":"4147-141-0300"}`
  - Texto+modelo: `{"q":"filtro de ar FS221"}`
- Webhook Telegram com header secreto (POST) deve retornar `200` e não gerar exceções em log.

## 🔙 Reversão
- Checkout de tag anterior estável e restart do serviço.

## 📌 Notas
- Se no futuro precisar expor `qtde_min`, criar endpoint dedicado com **controle de acesso** e mascaramento.
