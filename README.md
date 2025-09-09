# Sistema de Busca Inteligente STIHL AI v1 - Implantação

## Visão Geral do Projeto

Este projeto tem como objetivo a implantação de um sistema de busca inteligente para produtos STIHL. Ele consiste em um backend baseado em Flask que interage com um banco de dados PostgreSQL hospedado no Supabase. O sistema foi projetado para permitir consultas eficientes sobre o catálogo de produtos STIHL, utilizando dados importados de arquivos CSV.

## Estrutura do Projeto

O diretório `/home/ubuntu/stihl_ai_v1_consolidated_output/` contém os seguintes arquivos e subdiretórios:

*   `01_create_tables_v5.sql`: Script SQL para a criação das tabelas do banco de dados.
*   `02_create_functions_v5.sql`: Script SQL para a criação de funções e procedimentos armazenados no banco de dados.
*   `04_security_rls_v5.sql`: Script SQL para a configuração de políticas de Row Level Security (RLS) no Supabase.
*   `05_import_csv_data_v5.sql`: Script SQL para a importação de dados de arquivos CSV para as tabelas do banco de dados. **Este script foi modificado para usar `\copy` em vez de `COPY` para compatibilidade com `psql -c` e para tentar resolver problemas de permissão.**
*   `csv_outputs_v5/`: Diretório contendo os arquivos CSV originais para importação.
*   `ms.csv`, `rocadeiras_e_impl.csv`, etc.: Arquivos CSV individuais (também presentes em `csv_outputs_v5/`).
*   `requirements.txt`: Lista de dependências Python para a aplicação Flask.
*   `search_api_v5.py` ou `intelligent_search_v5.py` (a ser confirmado): O arquivo principal da aplicação Flask (backend).
*   `execution_log_v1.txt`: Um log detalhado de todos os comandos e ações executadas durante o processo de implantação até o momento.
*   `prompt_for_next_ai_v1.md`: O prompt detalhado que foi fornecido para a próxima IA, contendo o contexto, o estado atual e os próximos passos.
*   `master_prompt_for_cursor_ai.md`: Este documento, que serve como o roteiro completo para a IA do Cursor.

## Configuração do Supabase

O banco de dados PostgreSQL está hospedado no Supabase. As tabelas e funções foram criadas com sucesso. As credenciais de conexão são:

*   **Host**: `aws-1-sa-east-1.pooler.supabase.com`
*   **Porta**: `6543`
*   **Usuário**: `postgres.eclmgkajlhrstyyhejev`
*   **Senha**: `rBVm2mIQds3PneOy`
*   **Banco de Dados**: `postgres`

## Importação de Dados

A importação inicial de dados foi realizada utilizando o script `05_import_csv_data_v5.sql`. A importação do arquivo `ms.csv` foi bem-sucedida. No entanto, a importação de `rocadeiras_e_impl.csv` falhou devido a uma restrição `NOT NULL` na coluna `codigo_material` da tabela `rocadeiras_e_impl`, indicando que o CSV pode conter valores nulos para essa coluna. Este é o principal ponto de parada atual do projeto e o foco da Tarefa 1 no `master_prompt_for_cursor_ai.md`.

Os arquivos CSV para importação estão localizados em `/tmp/csv_data/` (copiados do `csv_outputs_v5.zip`).

## Aplicação Flask

A aplicação Flask é o componente de backend responsável por interagir com o banco de dados e fornecer a funcionalidade de busca. O arquivo principal da aplicação ainda precisa ser confirmado (provavelmente `search_api_v5.py` ou `intelligent_search_v5.py`). As dependências Python estão listadas em `requirements.txt`.

## Configuração do Servidor (Nginx/Gunicorn)

Para a implantação em ambiente de produção, a aplicação Flask será servida por Gunicorn e exposta via Nginx como um proxy reverso. As configurações detalhadas para isso estão descritas na Tarefa 5 do `master_prompt_for_cursor_ai.md`.

## Como Usar (Próximos Passos)

Para continuar o desenvolvimento e a implantação deste projeto, siga as instruções detalhadas no arquivo `master_prompt_for_cursor_ai.md`. Ele descreve as tarefas restantes, incluindo:

1.  **Análise e Resolução do Problema de Importação de Dados**: Foco na correção do problema com `rocadeiras_e_impl.csv` e na importação dos demais CSVs.
2.  **Concluir a Importação de Dados**: Garantir que todos os dados sejam importados com sucesso.
3.  **Aplicar Regras de Segurança (RLS)**: Executar o script `04_security_rls_v5.sql`.
4.  **Preparar e Implantar a Aplicação Flask**: Instalar dependências, identificar o arquivo principal da aplicação e testá-la localmente.
5.  **Configurar Nginx e Gunicorn**: Configurar os servidores para acesso público da aplicação.
6.  **Testes de Integração e Validação**: Realizar testes completos para garantir a funcionalidade de ponta a ponta.
7.  **Documentação Final e Entrega**: (Esta etapa está sendo concluída agora).

## Credenciais

As credenciais do Supabase foram fornecidas no início deste documento e no `master_prompt_for_cursor_ai.md`.

## Próximos Passos/Melhorias

Após a conclusão da implantação básica, as seguintes melhorias podem ser consideradas:

*   Implementar um sistema de log mais robusto para a aplicação Flask.
*   Adicionar autenticação e autorização de usuários na aplicação Flask.
*   Desenvolver uma interface de usuário (frontend) para interagir com a API de busca.
*   Otimizar o desempenho das consultas SQL e da aplicação Flask.
*   Explorar a integração com outras funcionalidades do Supabase (ex: Realtime, Storage).

---

**Autor:** Manus AI
**Data:** Setembro de 2025


