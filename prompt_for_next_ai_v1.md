# Prompt para Continuidade do Projeto STIHL AI v1

## Contexto do Projeto

Este projeto visa implantar o sistema STIHL AI (versão 1), que inclui a configuração de um banco de dados no Supabase, gerenciamento de código via GitHub e a implantação de uma aplicação Flask. O objetivo final é ter um sistema de busca inteligente de produtos STIHL funcional.

## Estado Atual do Projeto

Até o momento, as seguintes etapas foram concluídas:

1.  **Repositório GitHub**: Um novo repositório (`stihl-ai-v1-clean`) foi criado no GitHub e os arquivos do projeto (versão 1, com informações sensíveis removidas) foram enviados com sucesso. O repositório original (`stihl-ai-v1`) foi descartado devido a problemas com segredos no histórico do Git.
    *   **URL do Repositório**: `https://github.com/vanzer80/stihl-ai-v1-clean`

2.  **Configuração do Supabase**: A conectividade com o banco de dados Supabase foi testada e confirmada. Os scripts `01_create_tables_v5.sql` e `02_create_functions_v5.sql` foram executados com sucesso, criando as tabelas e funções necessárias no banco de dados.

3.  **Importação de Dados (Parcial)**: Foi feita uma tentativa de importar os dados CSV usando o script `05_import_csv_data_v5.sql`. O comando `\copy` foi ajustado para ser executado via `psql -c`. A importação do arquivo `ms.csv` foi bem-sucedida.

## Problema Encontrado

A importação do arquivo `rocadeiras_e_impl.csv` falhou com o seguinte erro:

```
ERROR:  null value in column "codigo_material" of relation "rocadeiras_e_impl" violates not-null constraint
DETAIL:  Failing row contains (null, null, null, 879.00, 2.00, null, null, null, null, null, null, null, null, null, null, null).
CONTEXT:  COPY rocadeiras_e_impl, line 90: ",,,879.0,2.0,,,,,,,,,,,"
```

Este erro indica que a coluna `codigo_material` na tabela `rocadeiras_e_impl` não pode ser nula, mas o arquivo CSV está fornecendo valores nulos para essa coluna em algumas linhas. Isso sugere uma possível incompatibilidade entre o formato do CSV fornecido e a estrutura da tabela `v5`, ou que o CSV em questão é da versão 1 do projeto e não da versão 5.

## Próximos Passos para a Próxima IA

A próxima IA (ou Manus) deve continuar o desenvolvimento do projeto a partir deste ponto, focando na resolução do problema de importação de dados e na conclusão da implantação. As etapas recomendadas são:

1.  **Análise e Validação dos Dados e Scripts**: 
    *   Verificar o arquivo `rocadeiras_e_impl.csv` e outros CSVs na pasta `/tmp/csv_data/` para confirmar se eles correspondem à estrutura esperada pela versão 5 do banco de dados. 
    *   Confirmar se os CSVs fornecidos são de fato da versão 5 ou se são da versão 1. Se forem da versão 1, será necessário obter os CSVs e scripts SQL corretos para a versão 5, ou adaptar os scripts existentes para a versão 1.
    *   Se os CSVs forem da versão 5, investigar por que a coluna `codigo_material` está vindo como nula e corrigir o arquivo CSV ou o script de importação (`05_import_csv_data_v5.sql`) para lidar com esses valores (por exemplo, preenchendo com um valor padrão ou ajustando a restrição da tabela, se apropriado e permitido).

2.  **Concluir a Importação de Dados**: Após resolver o problema com `rocadeiras_e_impl.csv`, continuar a importação dos demais arquivos CSV listados no script `05_import_csv_data_v5.sql`.

3.  **Aplicar Regras de Segurança (RLS)**: Executar o script `04_security_rls_v5.sql` para aplicar as políticas de Row Level Security (RLS) no banco de dados Supabase.

4.  **Preparar e Implantar a Aplicação Flask**: 
    *   Configurar o ambiente do servidor para a aplicação Flask (instalar dependências, etc.).
    *   Implantar a aplicação Flask (provavelmente `search_api_v5.py` ou `stihl_ai.py` dependendo da versão final a ser utilizada) no servidor.

5.  **Configurar Nginx e Gunicorn**: Configurar Nginx como proxy reverso e Gunicorn como servidor de aplicação para a aplicação Flask, garantindo que ela esteja acessível publicamente.

6.  **Testes de Integração e Validação**: Realizar testes completos para garantir que o sistema de busca esteja funcionando corretamente, que os dados estejam sendo consultados adequadamente e que as políticas de segurança estejam em vigor.

7.  **Documentação Final**: Atualizar a documentação do projeto com os passos finais da implantação e quaisquer observações relevantes.

## Arquivos Relevantes

Os arquivos do projeto estão localizados em `/home/ubuntu/stihl_ai_v1_consolidated_output/`. Os arquivos CSV estão em `/tmp/csv_data/`.

*   `execution_log_v1.txt`: Log completo dos comandos executados até o momento.
*   `01_create_tables_v5.sql`: Script para criação das tabelas.
*   `02_create_functions_v5.sql`: Script para criação das funções.
*   `05_import_csv_data_v5.sql`: Script para importação dos dados CSV (necessita de revisão).
*   `04_security_rls_v5.sql`: Script para configuração do RLS.
*   `ms.csv`, `rocadeiras_e_impl.csv`, etc.: Arquivos CSV para importação (localizados em `/tmp/csv_data/`).

**Credenciais do Supabase (para referência, já utilizadas nos comandos anteriores):**
*   **Host**: `aws-1-sa-east-1.pooler.supabase.com`
*   **Porta**: `6543`
*   **Usuário**: `postgres.eclmgkajlhrstyyhejev`
*   **Senha**: `rBVm2mIQds3PneOy`
*   **Banco de Dados**: `postgres`

Por favor, revise este prompt e os arquivos fornecidos para dar continuidade ao projeto. Boa sorte!

