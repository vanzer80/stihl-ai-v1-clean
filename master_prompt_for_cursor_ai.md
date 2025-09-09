# Roteiro Completo para Implantação do Sistema STIHL AI v1 no Cursor AI

Este documento serve como um roteiro detalhado e estruturado para a IA do Cursor, permitindo a continuidade autônoma do projeto de implantação do Sistema STIHL AI v1. Cada seção representa uma tarefa específica, com todas as informações necessárias para sua execução, incluindo contexto, arquivos relevantes, credenciais e comandos.

## Contexto Geral do Projeto

O objetivo principal deste projeto é implantar um sistema de busca inteligente de produtos STIHL, utilizando um banco de dados no Supabase e uma aplicação Flask. O desenvolvimento foi dividido em fases, e a IA do Cursor assumirá a partir de um ponto onde o banco de dados foi parcialmente configurado e a importação de dados encontrou um obstáculo.

**Estado Atual:**

*   **Repositório GitHub**: Um novo repositório (`stihl-ai-v1-clean`) foi criado e contém os arquivos do projeto (versão 1, com informações sensíveis removidas). O repositório original foi descartado.
    *   **URL do Repositório**: `https://github.com/vanzer80/stihl-ai-v1-clean`
*   **Supabase**: As tabelas e funções do banco de dados foram criadas com sucesso (`01_create_tables_v5.sql` e `02_create_functions_v5.sql`).
*   **Importação de Dados**: A importação do `ms.csv` foi bem-sucedida. No entanto, a importação de `rocadeiras_e_impl.csv` falhou devido a valores nulos na coluna `codigo_material`, que possui uma restrição `NOT NULL`.

**Credenciais do Supabase (já utilizadas nos comandos anteriores e persistidas no ambiente):**

*   **Host**: `aws-1-sa-east-1.pooler.supabase.com`
*   **Porta**: `6543`
*   **Usuário**: `postgres.eclmgkajlhrstyyhejev`
*   **Senha**: `rBVm2mIQds3PneOy`
*   **Banco de Dados**: `postgres`

**Diretórios Importantes:**

*   **Arquivos do Projeto**: `/home/ubuntu/stihl-ai-v1-clean/` (já clonado no ambiente do Cursor)
*   **Arquivos CSV para Importação**: `/tmp/csv_data/` (já populado com os CSVs do `csv_outputs_v5.zip`)

---

## Tarefa 1: Análise e Resolução do Problema de Importação de Dados

**Objetivo:** Identificar a causa raiz do erro de importação do `rocadeiras_e_impl.csv` e implementar a solução adequada para permitir a importação de todos os dados CSV.

**Contexto Específico:** O erro `null value in column "codigo_material" of relation "rocadeiras_e_impl" violates not-null constraint` indica que o arquivo CSV `rocadeiras_e_impl.csv` contém linhas onde a coluna `codigo_material` está vazia, o que é incompatível com a definição da tabela `rocadeiras_e_impl` no Supabase (criada via `01_create_tables_v5.sql`). É crucial determinar se os CSVs fornecidos são da versão 1 ou da versão 5 do projeto, pois isso ditará a estratégia de correção.

**Passos a Serem Executados:**

1.  **Verificar a Estrutura da Tabela `rocadeiras_e_impl`:**
    *   **Comando:** `PGPASSWORD=rBVm2mIQds3PneOy psql 


"postgresql://postgres.eclmgkajlhrstyyhejev:rBVm2mIQds3PneOy@aws-1-sa-east-1.pooler.supabase.com:6543/postgres" -c "\d rocadeiras_e_impl"`
    *   **Objetivo:** Confirmar a estrutura da tabela e as restrições de `NOT NULL`.
    *   **Análise Esperada:** Observar a definição da coluna `codigo_material` e verificar se ela possui a restrição `NOT NULL`.

2.  **Inspecionar o Arquivo `rocadeiras_e_impl.csv`:**
    *   **Comando:** `head -n 20 /tmp/csv_data/rocadeiras_e_impl.csv`
    *   **Objetivo:** Visualizar as primeiras linhas do arquivo CSV para entender seu formato e identificar possíveis linhas com `codigo_material` ausente ou nulo.
    *   **Análise Esperada:** Procurar por linhas onde a terceira coluna (correspondente a `codigo_material` na definição da tabela) esteja vazia ou contenha um valor que o PostgreSQL interprete como nulo (ex: `,,`).

3.  **Determinar a Versão dos Dados CSV:**
    *   **Contexto:** O projeto tem duas versões de dados e scripts (v1 e v5). O erro sugere uma incompatibilidade. É crucial determinar se os CSVs em `/tmp/csv_data/` são da v1 ou v5.
    *   **Ação:** Comparar a estrutura dos CSVs com a documentação da v1 (se disponível) e v5. Se os CSVs em `/tmp/csv_data/` forem da v1, será necessário:
        *   Obter os CSVs da v5 (se existirem e forem compatíveis com a estrutura da tabela v5).
        *   Ou, se a intenção for usar os dados da v1, adaptar os scripts de criação de tabela (`01_create_tables_v5.sql`) e importação (`05_import_csv_data_v5.sql`) para serem compatíveis com a estrutura e o conteúdo dos CSVs da v1. **Neste ponto, a instrução é focar na compatibilidade com a v5, assumindo que os scripts SQL (`_v5.sql`) são a referência correta.**
    *   **Hipótese Principal:** O erro indica que os CSVs em `/tmp/csv_data/` podem ser da versão 1, ou que há dados inconsistentes na versão 5.

4.  **Estratégia de Correção (Prioridade: Manter compatibilidade com v5):**
    *   **Opção A (Ideal): Obter CSVs v5 corretos.** Se houver uma fonte de CSVs da v5 que sejam compatíveis com a estrutura `NOT NULL` da tabela `rocadeiras_e_impl`, esses devem ser usados. (A IA deve perguntar ao usuário se há CSVs v5 alternativos, se não conseguir encontrá-los no ambiente).
    *   **Opção B (Adaptar CSV):** Se os CSVs atuais forem os únicos disponíveis e forem da v5, mas com dados inconsistentes, a IA deve tentar preencher os valores nulos de `codigo_material` com um valor padrão (ex: `N/A` ou `0000000000000`) antes da importação. Isso pode ser feito editando o CSV diretamente ou usando um script Python para pré-processamento.
        *   **Comando (Exemplo de pré-processamento Python para `rocadeiras_e_impl.csv`):**
            ```python
            import pandas as pd

            file_path = "/tmp/csv_data/rocadeiras_e_impl.csv"
            df = pd.read_csv(file_path, header=None) # Ler sem cabeçalho para facilitar a identificação da coluna

            # A coluna codigo_material é a terceira coluna (índice 2) no CSV, se o cabeçalho for ignorado
            # Substituir valores nulos na coluna de codigo_material (índice 2) por uma string vazia ou um valor padrão
            df[2] = df[2].fillna("N/A_V1") # Exemplo: preencher com 'N/A_V1' para identificar dados da v1

            # Salvar o CSV corrigido (pode ser em um novo arquivo ou sobrescrever o existente)
            df.to_csv(file_path, index=False, header=False) # Salvar sem cabeçalho para manter o formato original
            print(f"Arquivo {file_path} processado e salvo.")
            ```
            *   **Ação da IA:** A IA deve executar este script Python, se a análise do CSV indicar que `codigo_material` está vazio e não nulo (ou seja, `,,` em vez de `NULL`).

    *   **Opção C (Adaptar Tabela - Último Recurso):** Se as opções anteriores não forem viáveis e o usuário confirmar que os CSVs atuais devem ser usados, a IA pode considerar alterar a restrição `NOT NULL` da coluna `codigo_material` na tabela `rocadeiras_e_impl` para permitir valores nulos. **Esta opção deve ser evitada, pois pode comprometer a integridade dos dados e a lógica do sistema.**
        *   **Comando (Exemplo - NÃO RECOMENDADO sem confirmação do usuário):**
            `PGPASSWORD=rBVm2mIQds3PneOy psql "postgresql://postgres.eclmgkajlhrstyyhejev:rBVm2mIQds3PneOy@aws-1-sa-east-1.pooler.supabase.com:6543/postgres" -c "ALTER TABLE rocadeiras_e_impl ALTER COLUMN codigo_material DROP NOT NULL;"`

**Instrução para a IA do Cursor:**

*   **Priorize a Opção A.** Se não for possível obter CSVs v5 corretos, prossiga para a **Opção B**. **Evite a Opção C, a menos que seja explicitamente instruído pelo usuário.**
*   Após a correção, tente novamente a importação do `rocadeiras_e_impl.csv`.

---

## Tarefa 2: Concluir a Importação de Dados

**Objetivo:** Importar todos os arquivos CSV restantes para o banco de dados Supabase, utilizando o script `05_import_csv_data_v5.sql`.

**Contexto Específico:** O script `05_import_csv_data_v5.sql` contém comandos `\copy` para importar dados de várias tabelas. Após a resolução do problema com `rocadeiras_e_impl.csv`, a IA deve garantir que todos os outros arquivos CSV sejam importados com sucesso.

**Passos a Serem Executados:**

1.  **Executar o Script de Importação Completo:**
    *   **Comando:** `PGPASSWORD=rBVm2mIQds3PneOy psql "postgresql://postgres.eclmgkajlhrstyyhejev:rBVm2mIQds3PneOy@aws-1-sa-east-1.pooler.supabase.com:6543/postgres" -f /home/ubuntu/stihl_ai_v1_consolidated_output/05_import_csv_data_v5.sql`
    *   **Objetivo:** Importar todos os dados para as tabelas correspondentes.
    *   **Análise Esperada:** Observar a saída para quaisquer erros. Se ocorrerem novos erros de `NOT NULL` ou outros, a IA deve analisar o CSV e a definição da tabela correspondente e aplicar uma estratégia de correção similar à Tarefa 1.

2.  **Verificar a Contagem de Registros:**
    *   **Comando (Exemplo para uma tabela):** `PGPASSWORD=rBVm2mIQds3PneOy psql "postgresql://postgres.eclmgkajlhrstyyhejev:rBVm2mIQds3PneOy@aws-1-sa-east-1.pooler.supabase.com:6543/postgres" -c "SELECT COUNT(*) FROM nome_da_tabela;"`
    *   **Ação da IA:** A IA deve verificar a contagem de registros para todas as tabelas principais (`ms`, `rocadeiras_e_impl`, `pecas`, `acessorios`, etc.) para confirmar que os dados foram importados.

---

## Tarefa 3: Aplicar Regras de Segurança (RLS)

**Objetivo:** Implementar as políticas de Row Level Security (RLS) no banco de dados Supabase para garantir a segurança dos dados.

**Contexto Específico:** O script `04_security_rls_v5.sql` define as políticas de RLS que controlam o acesso aos dados com base nas permissões do usuário. É fundamental aplicar essas políticas para proteger as informações sensíveis e garantir que apenas usuários autorizados possam acessar determinados registros.

**Passos a Serem Executados:**

1.  **Executar o Script de RLS:**
    *   **Comando:** `PGPASSWORD=rBVm2mIQds3PneOy psql "postgresql://postgres.eclmgkajlhrstyyhejev:rBVm2mIQds3PneOy@aws-1-sa-east-1.pooler.supabase.com:6543/postgres" -f /home/ubuntu/stihl_ai_v1_consolidated_output/04_security_rls_v5.sql`
    *   **Objetivo:** Aplicar as políticas de segurança no banco de dados.
    *   **Análise Esperada:** A saída deve indicar que as políticas foram criadas ou alteradas com sucesso. Não devem ocorrer erros.

2.  **Verificar a Aplicação das Políticas de RLS (Opcional, mas recomendado):**
    *   **Comando (Exemplo para uma tabela):** `PGPASSWORD=rBVm2mIQds3PneOy psql "postgresql://postgres.eclmgkajlhrstyyhejev:rBVm2mIQds3PneOy@aws-1-sa-east-1.pooler.supabase.com:6543/postgres" -c "SELECT * FROM pg_policies WHERE tablename = 'nome_da_tabela';"`
    *   **Ação da IA:** A IA pode verificar se as políticas de RLS foram aplicadas corretamente para as tabelas principais.

---

## Tarefa 4: Preparar e Implantar a Aplicação Flask

**Objetivo:** Configurar o ambiente do servidor e implantar a aplicação Flask que interage com o banco de dados Supabase.

**Contexto Específico:** A aplicação Flask (`search_api_v5.py` ou `stihl_ai.py`) é o backend que fornecerá a funcionalidade de busca. Ela precisa de um ambiente Python configurado e das dependências instaladas.

**Passos a Serem Executados:**

1.  **Instalar Dependências Python:**
    *   **Comando:** `pip install -r /home/ubuntu/stihl_ai_v1_consolidated_output/requirements.txt`
    *   **Objetivo:** Instalar todas as bibliotecas Python necessárias para a aplicação Flask.
    *   **Análise Esperada:** A saída deve indicar a instalação bem-sucedida das dependências.

2.  **Identificar o Arquivo Principal da Aplicação Flask:**
    *   **Contexto:** Existem vários arquivos Python no projeto (`search_api.py`, `search_api_v5.py`, `stihl_ai.py`, `intelligent_search.py`, `intelligent_search_v5.py`, `main.py`). A IA precisa identificar qual é o ponto de entrada principal da aplicação Flask que interage com o banco de dados Supabase e que deve ser implantado.
    *   **Ação da IA:** A IA deve analisar o conteúdo desses arquivos para determinar qual deles é a aplicação Flask principal. Com base no nome `_v5`, `search_api_v5.py` ou `intelligent_search_v5.py` são os candidatos mais prováveis. A IA deve ler o conteúdo desses arquivos para confirmar.
        *   **Comando (Exemplo):** `cat /home/ubuntu/stihl_ai_v1_consolidated_output/search_api_v5.py`

3.  **Configurar Variáveis de Ambiente (se necessário):**
    *   **Contexto:** A aplicação Flask pode precisar de variáveis de ambiente para as credenciais do Supabase ou outras configurações. Embora as credenciais já estejam no prompt, é uma boa prática que a aplicação as leia de variáveis de ambiente.
    *   **Ação da IA:** A IA deve verificar o código da aplicação Flask identificada (passo 2) para ver como ela acessa as credenciais do banco de dados. Se ela as lê de variáveis de ambiente, a IA deve configurá-las no ambiente do servidor.
        *   **Comando (Exemplo):** `export DATABASE_URL="postgresql://postgres.eclmgkajlhrstyyhejev:rBVm2mIQds3PneOy@aws-1-sa-east-1.pooler.supabase.com:6543/postgres"`

4.  **Testar a Aplicação Flask Localmente:**
    *   **Comando (Exemplo, assumindo `search_api_v5.py` é o principal):** `python /home/ubuntu/stihl_ai_v1_consolidated_output/search_api_v5.py`
    *   **Objetivo:** Verificar se a aplicação Flask inicia sem erros e se consegue se conectar ao Supabase.
    *   **Análise Esperada:** A aplicação deve iniciar e talvez imprimir uma mensagem indicando que está ouvindo em uma porta (ex: `http://127.0.0.1:5000`). A IA deve ser capaz de identificar se a aplicação está funcionando corretamente.

---

## Tarefa 5: Configurar Nginx e Gunicorn

**Objetivo:** Configurar Nginx como proxy reverso e Gunicorn como servidor de aplicação para a aplicação Flask, tornando-a acessível publicamente.

**Contexto Específico:** Para que a aplicação Flask seja robusta e acessível na web, ela precisa ser servida por um servidor de aplicação (Gunicorn) e ter um proxy reverso (Nginx) para lidar com as requisições HTTP.

**Passos a Serem Executados:**

1.  **Instalar Gunicorn e Nginx:**
    *   **Comando:** `sudo apt-get update && sudo apt-get install -y gunicorn nginx`
    *   **Objetivo:** Instalar os servidores necessários.

2.  **Criar um Serviço Gunicorn:**
    *   **Comando (Exemplo para `search_api_v5.py`):**
        ```bash
        sudo tee /etc/systemd/system/stihl_ai.service > /dev/null <<EOF
        [Unit]
        Description=Gunicorn instance to serve STIHL AI Flask app
        After=network.target

        [Service]
        User=ubuntu
        Group=www-data
        WorkingDirectory=/home/ubuntu/stihl_ai_v1_consolidated_output/
        Environment="PATH=/usr/bin:/usr/local/bin:/usr/bin/python3.11"
        ExecStart=/usr/local/bin/gunicorn --workers 3 --bind unix:/home/ubuntu/stihl_ai_v1_consolidated_output/stihl_ai.sock -m 007 search_api_v5:app
        Restart=always

        [Install]
        WantedBy=multi-user.target
        EOF
        ```
    *   **Ação da IA:** A IA deve adaptar o `ExecStart` para apontar para o arquivo Python principal da aplicação Flask e o objeto `app` dentro dele (ex: `nome_do_arquivo_flask:nome_do_objeto_app`).

3.  **Habilitar e Iniciar o Serviço Gunicorn:**
    *   **Comando:** `sudo systemctl daemon-reload && sudo systemctl start stihl_ai && sudo systemctl enable stihl_ai`
    *   **Objetivo:** Iniciar o Gunicorn e configurá-lo para iniciar automaticamente no boot.

4.  **Configurar Nginx:**
    *   **Comando (Exemplo):**
        ```bash
        sudo tee /etc/nginx/sites-available/stihl_ai > /dev/null <<EOF
        server {
            listen 80;
            server_name your_domain_or_ip_address; # Substituir pelo domínio ou IP do servidor

            location / {
                include proxy_params;
                proxy_pass http://unix:/home/ubuntu/stihl_ai_v1_consolidated_output/stihl_ai.sock;
            }
        }
        EOF
        ```
    *   **Ação da IA:** A IA deve substituir `your_domain_or_ip_address` pelo IP público do servidor ou um domínio configurado. Se o IP não for conhecido, a IA pode usar `curl ifconfig.me` para obtê-lo.

5.  **Habilitar a Configuração do Nginx e Reiniciar:**
    *   **Comando:** `sudo ln -s /etc/nginx/sites-available/stihl_ai /etc/nginx/sites-enabled/ && sudo nginx -t && sudo systemctl restart nginx`
    *   **Objetivo:** Ativar a configuração do Nginx e reiniciar o serviço.

---

## Tarefa 6: Testes de Integração e Validação

**Objetivo:** Realizar testes abrangentes para garantir que todo o sistema (banco de dados, importação de dados, RLS, aplicação Flask, Nginx/Gunicorn) esteja funcionando corretamente.

**Contexto Específico:** É crucial verificar a funcionalidade de ponta a ponta, desde a acessibilidade da API até a precisão dos dados retornados e a aplicação das políticas de segurança.

**Passos a Serem Executados:**

1.  **Testar Acessibilidade da API:**
    *   **Comando (Exemplo, assumindo a API está em `/search`):** `curl http://your_domain_or_ip_address/search?query=motosserra`
    *   **Ação da IA:** A IA deve substituir `your_domain_or_ip_address` pelo IP ou domínio configurado no Nginx. Testar diferentes queries para verificar se a API responde e retorna dados.

2.  **Verificar Dados no Banco de Dados:**
    *   **Comando (Exemplo):** `PGPASSWORD=rBVm2mIQds3PneOy psql "postgresql://postgres.eclmgkajlhrstyyhejev:rBVm2mIQds3PneOy@aws-1-sa-east-1.pooler.supabase.com:6543/postgres" -c "SELECT * FROM ms LIMIT 5;"`
    *   **Objetivo:** Confirmar que os dados importados estão corretos e acessíveis.

3.  **Testar Políticas de RLS (se aplicável na aplicação):**
    *   **Contexto:** Se a aplicação Flask implementar diferentes níveis de acesso baseados em RLS, a IA deve simular esses cenários para garantir que as políticas estejam funcionando.
    *   **Ação da IA:** Se houver um mecanismo de autenticação/autorização na aplicação, a IA deve tentar acessar dados com diferentes credenciais para verificar se o RLS restringe o acesso conforme o esperado.

---

## Tarefa 7: Documentação Final e Entrega

**Objetivo:** Consolidar todas as informações da implantação em um README completo e entregar os resultados.

**Contexto Específico:** Um README bem documentado é essencial para a manutenção futura do projeto e para que outros desenvolvedores possam entender e trabalhar com o sistema.

**Passos a Serem Executados:**

1.  **Criar o Arquivo README.md:**
    *   **Ação da IA:** A IA deve criar um arquivo `README.md` no diretório raiz do projeto (`/home/ubuntu/stihl_ai_v1_consolidated_output/`) com as seguintes seções:
        *   **Título:** `Sistema de Busca Inteligente STIHL AI v1 - Implantação`
        *   **Visão Geral:** Breve descrição do projeto e seu propósito.
        *   **Estrutura do Projeto:** Descrição dos principais diretórios e arquivos.
        *   **Configuração do Supabase:** Detalhes sobre a conexão, tabelas, funções e RLS.
        *   **Importação de Dados:** Informações sobre os dados importados e quaisquer desafios/soluções.
        *   **Aplicação Flask:** Como iniciar, dependências, ponto de entrada.
        *   **Configuração do Servidor (Nginx/Gunicorn):** Detalhes da configuração para acesso público.
        *   **Como Usar:** Exemplos de como interagir com a API.
        *   **Próximos Passos/Melhorias:** Sugestões para o futuro desenvolvimento.
        *   **Credenciais:** (Opcional, mas útil para referência, se não for um ambiente público) Credenciais do Supabase.

2.  **Realizar Commit no Repositório GitHub:**
    *   **Comando:**
        ```bash
        cd /home/ubuntu/stihl_ai_v1_consolidated_output/
        git add README.md
        git commit -m "Adiciona README.md completo com detalhes da implantação"
        git push origin master
        ```
    *   **Objetivo:** Salvar o README no repositório.

3.  **Entregar os Resultados:**
    *   **Ação da IA:** A IA deve notificar o usuário sobre a conclusão do projeto, anexando o `README.md` e o `master_prompt_for_cursor_ai.md` (este próprio documento) para referência futura.

---

**Observações Finais para a IA do Cursor:**

*   **Autonomia:** Tente resolver os problemas de forma autônoma. Se encontrar um obstáculo intransponível ou precisar de uma decisão que exija intervenção humana (como a escolha entre Opção A, B ou C na Tarefa 1, se a análise não for conclusiva), utilize a ferramenta `message_ask_user` para solicitar orientação.
*   **Logs:** Mantenha um registro detalhado de todas as ações e saídas dos comandos para facilitar a depuração e a auditoria.
*   **Segurança:** Sempre priorize a segurança. Evite expor credenciais ou informações sensíveis em logs ou arquivos públicos, a menos que explicitamente instruído e justificado.
*   **Iteração:** O projeto pode exigir várias iterações para resolver todos os problemas. Seja persistente e analítico.

Com este roteiro, a IA do Cursor deve ter todas as informações necessárias para dar continuidade e concluir a implantação do Sistema STIHL AI v1. Boa sorte!

