## Guia de Deploy do Sistema STIHL AI

### Fase 1: Revisão do ambiente e pré-requisitos
- [x] Verificar versão do Ubuntu (24.04 LTS)
- [x] Verificar versão do Python (3.11+)
- [x] Listar pacotes de sistema necessários (git, curl, wget, build-essential, etc.)
- [x] Listar dependências Python (requirements.txt)
- [x] Listar variáveis de ambiente necessárias (OpenAI API Key, Supabase URLs, Database URL)

### Fase 2: Configuração do Supabase
- [x] Obter credenciais do Supabase (URL, Anon Key, Service Role Key)
- [x] **(Opcional) Limpar estruturas existentes no Supabase (se necessário)**
- [x] Executar scripts SQL para criação de tabelas (01_create_tables.sql)
- [x] Executar scripts SQL para criação de funções (02_create_functions.sql)
- [x] Executar scripts SQL para inserção de dados (03_insert_data.sql)
- [x] Executar scripts SQL para segurança e RLS (04_security_rls.sql)

### Fase 3: Preparação do servidor DigitalOcean
- [x] Conectar via SSH ao servidor
- [x] Atualizar pacotes do sistema
- [x] Instalar Python 3.11+ e pip
- [x] Instalar dependências de sistema para psycopg2
- [x] Criar usuário não-root para a aplicação
- [x] **(Opcional) Limpar estruturas existentes no servidor (se necessário)**
- [x] Configurar firewall (UFW)

### Fase 4: Implantação da aplicação Flask
- [x] Clonar o repositório da aplicação
- [x] Criar e ativar ambiente virtual Python
- [x] Instalar dependências Python (requirements.txt)
- [x] Configurar variáveis de ambiente no servidor
- [x] Testar a aplicação Flask localmente no servidor

### Fase 5: Configuração do Nginx e Gunicorn
- [x] Instalar Gunicorn
- [x] Criar arquivo de serviço Systemd para Gunicorn
- [x] Instalar Nginx
- [x] Configurar Nginx como proxy reverso
- [x] Configurar SSL com Certbot (opcional, mas recomendado)

### Fase 6: Testes de integração e validação
- [x] Testar acesso à API de busca via IP público
- [x] Testar a interface web da IA autônoma
- [x] Realizar testes de busca em linguagem natural
- [x] Validar inserção de dados e RLS
- [x] Testar endpoints de analytics

### Fase 7: Guia de uso da IA de busca e exemplos
- [x] Detalhar como usar a IA de busca (exemplos de consultas)
- [x] Explicar como usar a IA autônoma para novas planilhas
- [x] Fornecer exemplos de integração com Telegram/WhatsApp/Chatweb

### Fase 8: Entrega do guia completo
- [x] Compilar toda a documentação em um único guia
- [x] Entregar arquivos de código e scripts
- [x] Fornecer suporte para dúvidas adicionais


