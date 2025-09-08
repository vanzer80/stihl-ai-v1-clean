# Guia de Importação de Dados CSV para Sistema STIHL AI

## Visão Geral

Este guia detalha como importar dados normalizados de arquivos CSV para o banco de dados do Sistema STIHL AI. O processo foi otimizado para trabalhar com dados já processados e organizados em arquivos CSV separados por categoria.

## Estrutura de Arquivos CSV Esperada

O sistema espera os seguintes arquivos CSV no diretório `/tmp/csv_data/`:

### 1. categories.csv
Contém as categorias de produtos organizadas hierarquicamente.

**Colunas obrigatórias:**
- `id` (integer): Identificador único da categoria
- `name` (varchar): Nome da categoria
- `description` (text): Descrição detalhada da categoria
- `parent_category_id` (integer, nullable): ID da categoria pai (para hierarquia)
- `category_type` (varchar): Tipo da categoria (main, sub, accessory)
- `display_order` (integer): Ordem de exibição

**Exemplo:**
```csv
id,name,description,parent_category_id,category_type,display_order
1,Motosserras,Equipamentos para corte de madeira,,main,1
2,Motosserras Elétricas,Motosserras alimentadas por energia elétrica,1,sub,1
3,Motosserras a Gasolina,Motosserras com motor a combustão,1,sub,2
```

### 2. stihl_technologies.csv
Tecnologias e inovações STIHL aplicadas aos produtos.

**Colunas obrigatórias:**
- `id` (integer): Identificador único da tecnologia
- `name` (varchar): Nome da tecnologia
- `description` (text): Descrição técnica
- `benefits` (text): Benefícios para o usuário
- `category` (varchar): Categoria da tecnologia

**Exemplo:**
```csv
id,name,description,benefits,category
1,2-MIX,Motor de dois tempos com baixa emissão,Reduz consumo de combustível em até 20%,motor
2,Easy2Start,Sistema de partida facilitada,Reduz força necessária para dar partida,ergonomia
```

### 3. campaigns.csv
Campanhas promocionais e ofertas especiais.

**Colunas obrigatórias:**
- `id` (integer): Identificador único da campanha
- `name` (varchar): Nome da campanha
- `description` (text): Descrição da campanha
- `start_date` (date): Data de início
- `end_date` (date): Data de término
- `discount_percentage` (decimal): Percentual de desconto
- `is_active` (boolean): Se a campanha está ativa

### 4. products.csv
Produtos principais do catálogo STIHL.

**Colunas obrigatórias:**
- `id` (integer): Identificador único do produto
- `name` (varchar): Nome completo do produto
- `model` (varchar): Modelo/código do produto
- `description` (text): Descrição detalhada
- `category_id` (integer): ID da categoria (FK)
- `brand` (varchar): Marca (geralmente STIHL)
- `product_type` (varchar): Tipo do produto
- `usage_type` (varchar): Tipo de uso (doméstico, profissional, etc.)
- `power_source` (varchar): Fonte de energia (elétrica, gasolina, bateria)
- `weight_kg` (decimal): Peso em quilogramas
- `is_active` (boolean): Se o produto está ativo no catálogo

**Exemplo:**
```csv
id,name,model,description,category_id,brand,product_type,usage_type,power_source,weight_kg,is_active
1,Motosserra STIHL MS 162,MS 162,Motosserra compacta para uso doméstico,3,STIHL,motosserra,doméstico,gasolina,3.5,true
```

### 5. technical_specifications.csv
Especificações técnicas detalhadas dos produtos.

**Colunas obrigatórias:**
- `id` (integer): Identificador único da especificação
- `product_id` (integer): ID do produto (FK)
- `specification_type` (varchar): Tipo da especificação (motor, dimensões, etc.)
- `specification_name` (varchar): Nome da especificação
- `specification_value` (varchar): Valor da especificação
- `unit_of_measure` (varchar): Unidade de medida

**Exemplo:**
```csv
id,product_id,specification_type,specification_name,specification_value,unit_of_measure
1,1,motor,Cilindrada,31.8,cm³
2,1,motor,Potência,1.3,kW
3,1,dimensões,Comprimento do sabre,30,cm
```

### 6. pricing.csv
Informações de preços dos produtos.

**Colunas obrigatórias:**
- `id` (integer): Identificador único do preço
- `product_id` (integer): ID do produto (FK)
- `price_type` (varchar): Tipo de preço (suggested, retail, wholesale)
- `price_value` (decimal): Valor do preço
- `currency` (varchar): Moeda (BRL, USD, etc.)
- `region` (varchar): Região de aplicação
- `effective_date` (date): Data de vigência
- `is_current` (boolean): Se é o preço atual

**Exemplo:**
```csv
id,product_id,price_type,price_value,currency,region,effective_date,is_current
1,1,suggested,1299.00,BRL,Brasil,2025-01-01,true
```

### 7. tax_information.csv
Informações fiscais e tributárias.

**Colunas obrigatórias:**
- `id` (integer): Identificador único da informação fiscal
- `product_id` (integer): ID do produto (FK)
- `tax_type` (varchar): Tipo de imposto (ICMS, IPI, etc.)
- `tax_rate` (decimal): Alíquota do imposto
- `tax_amount` (decimal): Valor do imposto
- `region` (varchar): Região de aplicação
- `effective_date` (date): Data de vigência

### 8. product_relationships.csv
Relacionamentos entre produtos (compatibilidade, acessórios, etc.).

**Colunas obrigatórias:**
- `id` (integer): Identificador único do relacionamento
- `primary_product_id` (integer): ID do produto principal (FK)
- `related_product_id` (integer): ID do produto relacionado (FK)
- `relationship_type` (varchar): Tipo de relacionamento (compatible, accessory, replacement)
- `description` (text): Descrição do relacionamento
- `compatibility_notes` (text): Notas sobre compatibilidade

**Exemplo:**
```csv
id,primary_product_id,related_product_id,relationship_type,description,compatibility_notes
1,1,15,accessory,Corrente para MS 162,Corrente Picco Micro 3 compatível
2,1,16,accessory,Sabre para MS 162,Sabre de 30cm recomendado
```

## Processo de Importação

### Passo 1: Preparação dos Arquivos

1. **Organize os arquivos CSV** no diretório `/tmp/csv_data/` do servidor
2. **Verifique a codificação** - todos os arquivos devem estar em UTF-8
3. **Valide os headers** - certifique-se de que as colunas estão corretas
4. **Verifique a integridade** - IDs referenciados devem existir

### Passo 2: Upload dos Arquivos para o Servidor

```bash
# Criar diretório para os CSVs
sudo mkdir -p /tmp/csv_data/
sudo chown postgres:postgres /tmp/csv_data/

# Copiar arquivos CSV para o servidor (exemplo usando scp)
scp categories.csv usuario@servidor:/tmp/csv_data/
scp stihl_technologies.csv usuario@servidor:/tmp/csv_data/
scp campaigns.csv usuario@servidor:/tmp/csv_data/
scp products.csv usuario@servidor:/tmp/csv_data/
scp technical_specifications.csv usuario@servidor:/tmp/csv_data/
scp pricing.csv usuario@servidor:/tmp/csv_data/
scp tax_information.csv usuario@servidor:/tmp/csv_data/
scp product_relationships.csv usuario@servidor:/tmp/csv_data/
```

### Passo 3: Execução dos Scripts SQL

Execute os scripts na ordem correta:

```bash
# 1. Criar estrutura do banco
PGPASSWORD=sua_senha psql -h host -U usuario -d database -f 01_create_tables.sql

# 2. Criar funções especializadas
PGPASSWORD=sua_senha psql -h host -U usuario -d database -f 02_create_functions.sql

# 3. Importar dados CSV
PGPASSWORD=sua_senha psql -h host -U usuario -d database -f 05_import_csv_data.sql

# 4. Configurar segurança
PGPASSWORD=sua_senha psql -h host -U usuario -d database -f 04_security_rls.sql
```

### Passo 4: Verificação da Importação

Após a execução, verifique se os dados foram importados corretamente:

```sql
-- Verificar contagem de registros
SELECT 
    'Categorias' as tabela, COUNT(*) as total FROM categories
UNION ALL
SELECT 
    'Produtos' as tabela, COUNT(*) as total FROM products
UNION ALL
SELECT 
    'Especificações' as tabela, COUNT(*) as total FROM technical_specifications;

-- Verificar integridade referencial
SELECT COUNT(*) as produtos_sem_categoria 
FROM products p 
LEFT JOIN categories c ON p.category_id = c.id 
WHERE c.id IS NULL;
```

## Tratamento de Erros Comuns

### Erro de Codificação
```
ERROR: invalid byte sequence for encoding "UTF8"
```
**Solução:** Converta os arquivos CSV para UTF-8:
```bash
iconv -f ISO-8859-1 -t UTF-8 arquivo.csv > arquivo_utf8.csv
```

### Erro de Chave Estrangeira
```
ERROR: insert or update on table violates foreign key constraint
```
**Solução:** Verifique se os IDs referenciados existem nas tabelas pai.

### Erro de Formato de Data
```
ERROR: invalid input syntax for type date
```
**Solução:** Use o formato YYYY-MM-DD para datas.

### Erro de Permissão
```
ERROR: could not open file for reading: Permission denied
```
**Solução:** Ajuste as permissões do diretório:
```bash
sudo chmod 755 /tmp/csv_data/
sudo chmod 644 /tmp/csv_data/*.csv
```

## Otimizações de Performance

### Para Grandes Volumes de Dados

1. **Desabilite índices temporariamente:**
```sql
DROP INDEX IF EXISTS idx_products_search_vector;
-- Importe os dados
-- Recrie os índices
CREATE INDEX idx_products_search_vector ON products USING gin(to_tsvector('portuguese', name || ' ' || description));
```

2. **Use transações em lote:**
```sql
BEGIN;
-- Comandos COPY aqui
COMMIT;
```

3. **Ajuste configurações do PostgreSQL:**
```sql
SET maintenance_work_mem = '1GB';
SET checkpoint_segments = 32;
```

## Validação Pós-Importação

Execute estas consultas para validar a importação:

```sql
-- 1. Verificar produtos com preços
SELECT COUNT(*) FROM products p 
JOIN pricing pr ON p.id = pr.product_id 
WHERE pr.is_current = true;

-- 2. Verificar produtos com especificações
SELECT COUNT(*) FROM products p 
JOIN technical_specifications ts ON p.id = ts.product_id;

-- 3. Verificar relacionamentos válidos
SELECT COUNT(*) FROM product_relationships pr
JOIN products p1 ON pr.primary_product_id = p1.id
JOIN products p2 ON pr.related_product_id = p2.id;

-- 4. Testar busca inteligente
SELECT intelligent_product_search('motosserra elétrica', 5);
```

## Manutenção e Atualizações

### Atualizações Incrementais

Para atualizações de dados existentes, use o comando `COPY` com `ON CONFLICT`:

```sql
-- Exemplo para atualizar preços
COPY pricing_temp FROM '/tmp/csv_data/pricing_update.csv' WITH CSV HEADER;

INSERT INTO pricing SELECT * FROM pricing_temp
ON CONFLICT (product_id, price_type, region) 
DO UPDATE SET 
    price_value = EXCLUDED.price_value,
    effective_date = EXCLUDED.effective_date,
    is_current = EXCLUDED.is_current;
```

### Backup Antes da Importação

Sempre faça backup antes de importações grandes:

```bash
pg_dump -h host -U usuario -d database > backup_pre_import.sql
```

## Conclusão

Este processo de importação CSV garante que os dados normalizados sejam carregados de forma eficiente e consistente no banco de dados do Sistema STIHL AI, mantendo a integridade referencial e otimizando a performance para as consultas de busca inteligente.

