-- =====================================================
-- Script de Importação de Dados CSV para Sistema STIHL AI
-- =====================================================
-- Este script importa dados de arquivos CSV normalizados
-- para as tabelas do banco de dados STIHL AI
-- 
-- Pré-requisitos:
-- 1. Tabelas já criadas (execute 01_create_tables.sql primeiro)
-- 2. Funções criadas (execute 02_create_functions.sql)
-- 3. Arquivos CSV disponíveis no servidor
-- 
-- Ordem de execução recomendada:
-- 1. 01_create_tables.sql
-- 2. 02_create_functions.sql  
-- 3. 05_import_csv_data.sql (este arquivo)
-- 4. 04_security_rls.sql
-- =====================================================

-- Configurações para importação
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;

-- =====================================================
-- SEÇÃO 1: PREPARAÇÃO PARA IMPORTAÇÃO
-- =====================================================

-- Desabilitar temporariamente as políticas RLS para importação
ALTER TABLE categories DISABLE ROW LEVEL SECURITY;
ALTER TABLE products DISABLE ROW LEVEL SECURITY;
ALTER TABLE technical_specifications DISABLE ROW LEVEL SECURITY;
ALTER TABLE pricing DISABLE ROW LEVEL SECURITY;
ALTER TABLE tax_information DISABLE ROW LEVEL SECURITY;
ALTER TABLE product_relationships DISABLE ROW LEVEL SECURITY;
ALTER TABLE stihl_technologies DISABLE ROW LEVEL SECURITY;
ALTER TABLE campaigns DISABLE ROW LEVEL SECURITY;

-- Limpar dados existentes (se houver)
TRUNCATE TABLE product_relationships CASCADE;
TRUNCATE TABLE pricing CASCADE;
TRUNCATE TABLE tax_information CASCADE;
TRUNCATE TABLE technical_specifications CASCADE;
TRUNCATE TABLE products CASCADE;
TRUNCATE TABLE categories CASCADE;
TRUNCATE TABLE stihl_technologies CASCADE;
TRUNCATE TABLE campaigns CASCADE;

-- =====================================================
-- SEÇÃO 2: IMPORTAÇÃO DE CATEGORIAS
-- =====================================================

-- Importar categorias de produtos
-- Arquivo esperado: categories.csv
-- Colunas: id,name,description,parent_category_id,category_type,display_order

\echo 'Importando categorias...'

COPY categories (id, name, description, parent_category_id, category_type, display_order)
FROM '/tmp/csv_data/categories.csv'
WITH (FORMAT csv, HEADER true, DELIMITER ',', ENCODING 'UTF8');

-- Verificar importação de categorias
SELECT COUNT(*) as total_categories FROM categories;

-- =====================================================
-- SEÇÃO 3: IMPORTAÇÃO DE TECNOLOGIAS STIHL
-- =====================================================

-- Importar tecnologias STIHL
-- Arquivo esperado: stihl_technologies.csv
-- Colunas: id,name,description,benefits,category

\echo 'Importando tecnologias STIHL...'

COPY stihl_technologies (id, name, description, benefits, category)
FROM '/tmp/csv_data/stihl_technologies.csv'
WITH (FORMAT csv, HEADER true, DELIMITER ',', ENCODING 'UTF8');

-- Verificar importação de tecnologias
SELECT COUNT(*) as total_technologies FROM stihl_technologies;

-- =====================================================
-- SEÇÃO 4: IMPORTAÇÃO DE CAMPANHAS
-- =====================================================

-- Importar campanhas promocionais
-- Arquivo esperado: campaigns.csv
-- Colunas: id,name,description,start_date,end_date,discount_percentage,is_active

\echo 'Importando campanhas...'

COPY campaigns (id, name, description, start_date, end_date, discount_percentage, is_active)
FROM '/tmp/csv_data/campaigns.csv'
WITH (FORMAT csv, HEADER true, DELIMITER ',', ENCODING 'UTF8');

-- Verificar importação de campanhas
SELECT COUNT(*) as total_campaigns FROM campaigns;

-- =====================================================
-- SEÇÃO 5: IMPORTAÇÃO DE PRODUTOS
-- =====================================================

-- Importar produtos principais
-- Arquivo esperado: products.csv
-- Colunas: id,name,model,description,category_id,brand,product_type,usage_type,power_source,weight_kg,is_active

\echo 'Importando produtos...'

COPY products (id, name, model, description, category_id, brand, product_type, usage_type, power_source, weight_kg, is_active)
FROM '/tmp/csv_data/products.csv'
WITH (FORMAT csv, HEADER true, DELIMITER ',', ENCODING 'UTF8');

-- Verificar importação de produtos
SELECT COUNT(*) as total_products FROM products;

-- =====================================================
-- SEÇÃO 6: IMPORTAÇÃO DE ESPECIFICAÇÕES TÉCNICAS
-- =====================================================

-- Importar especificações técnicas
-- Arquivo esperado: technical_specifications.csv
-- Colunas: id,product_id,specification_type,specification_name,specification_value,unit_of_measure

\echo 'Importando especificações técnicas...'

COPY technical_specifications (id, product_id, specification_type, specification_name, specification_value, unit_of_measure)
FROM '/tmp/csv_data/technical_specifications.csv'
WITH (FORMAT csv, HEADER true, DELIMITER ',', ENCODING 'UTF8');

-- Verificar importação de especificações
SELECT COUNT(*) as total_specifications FROM technical_specifications;

-- =====================================================
-- SEÇÃO 7: IMPORTAÇÃO DE PREÇOS
-- =====================================================

-- Importar informações de preços
-- Arquivo esperado: pricing.csv
-- Colunas: id,product_id,price_type,price_value,currency,region,effective_date,is_current

\echo 'Importando preços...'

COPY pricing (id, product_id, price_type, price_value, currency, region, effective_date, is_current)
FROM '/tmp/csv_data/pricing.csv'
WITH (FORMAT csv, HEADER true, DELIMITER ',', ENCODING 'UTF8');

-- Verificar importação de preços
SELECT COUNT(*) as total_pricing FROM pricing;

-- =====================================================
-- SEÇÃO 8: IMPORTAÇÃO DE INFORMAÇÕES FISCAIS
-- =====================================================

-- Importar informações fiscais
-- Arquivo esperado: tax_information.csv
-- Colunas: id,product_id,tax_type,tax_rate,tax_amount,region,effective_date

\echo 'Importando informações fiscais...'

COPY tax_information (id, product_id, tax_type, tax_rate, tax_amount, region, effective_date)
FROM '/tmp/csv_data/tax_information.csv'
WITH (FORMAT csv, HEADER true, DELIMITER ',', ENCODING 'UTF8');

-- Verificar importação de informações fiscais
SELECT COUNT(*) as total_tax_info FROM tax_information;

-- =====================================================
-- SEÇÃO 9: IMPORTAÇÃO DE RELACIONAMENTOS DE PRODUTOS
-- =====================================================

-- Importar relacionamentos entre produtos (compatibilidade, acessórios, etc.)
-- Arquivo esperado: product_relationships.csv
-- Colunas: id,primary_product_id,related_product_id,relationship_type,description,compatibility_notes

\echo 'Importando relacionamentos de produtos...'

COPY product_relationships (id, primary_product_id, related_product_id, relationship_type, description, compatibility_notes)
FROM '/tmp/csv_data/product_relationships.csv'
WITH (FORMAT csv, HEADER true, DELIMITER ',', ENCODING 'UTF8');

-- Verificar importação de relacionamentos
SELECT COUNT(*) as total_relationships FROM product_relationships;

-- =====================================================
-- SEÇÃO 10: REABILITAÇÃO DE POLÍTICAS RLS
-- =====================================================

-- Reabilitar as políticas RLS após importação
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
ALTER TABLE technical_specifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE pricing ENABLE ROW LEVEL SECURITY;
ALTER TABLE tax_information ENABLE ROW LEVEL SECURITY;
ALTER TABLE product_relationships ENABLE ROW LEVEL SECURITY;
ALTER TABLE stihl_technologies ENABLE ROW LEVEL SECURITY;
ALTER TABLE campaigns ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- SEÇÃO 11: ATUALIZAÇÃO DE SEQUÊNCIAS
-- =====================================================

-- Atualizar sequências para evitar conflitos em futuras inserções
SELECT setval('categories_id_seq', (SELECT MAX(id) FROM categories));
SELECT setval('products_id_seq', (SELECT MAX(id) FROM products));
SELECT setval('technical_specifications_id_seq', (SELECT MAX(id) FROM technical_specifications));
SELECT setval('pricing_id_seq', (SELECT MAX(id) FROM pricing));
SELECT setval('tax_information_id_seq', (SELECT MAX(id) FROM tax_information));
SELECT setval('product_relationships_id_seq', (SELECT MAX(id) FROM product_relationships));
SELECT setval('stihl_technologies_id_seq', (SELECT MAX(id) FROM stihl_technologies));
SELECT setval('campaigns_id_seq', (SELECT MAX(id) FROM campaigns));

-- =====================================================
-- SEÇÃO 12: CRIAÇÃO DE ÍNDICES ADICIONAIS PARA PERFORMANCE
-- =====================================================

-- Índices para otimizar consultas de busca
CREATE INDEX IF NOT EXISTS idx_products_search_vector ON products USING gin(to_tsvector('portuguese', name || ' ' || COALESCE(description, '') || ' ' || model));
CREATE INDEX IF NOT EXISTS idx_products_category_active ON products(category_id, is_active);
CREATE INDEX IF NOT EXISTS idx_pricing_current ON pricing(product_id, is_current) WHERE is_current = true;
CREATE INDEX IF NOT EXISTS idx_technical_specs_product ON technical_specifications(product_id, specification_type);
CREATE INDEX IF NOT EXISTS idx_product_relationships_primary ON product_relationships(primary_product_id, relationship_type);

-- =====================================================
-- SEÇÃO 13: ATUALIZAÇÃO DE ESTATÍSTICAS
-- =====================================================

-- Atualizar estatísticas do banco para otimizar planos de consulta
ANALYZE categories;
ANALYZE products;
ANALYZE technical_specifications;
ANALYZE pricing;
ANALYZE tax_information;
ANALYZE product_relationships;
ANALYZE stihl_technologies;
ANALYZE campaigns;

-- =====================================================
-- SEÇÃO 14: VERIFICAÇÃO FINAL E RELATÓRIO
-- =====================================================

\echo '================================================='
\echo 'RELATÓRIO DE IMPORTAÇÃO DE DADOS CSV'
\echo '================================================='

-- Relatório de contagem de registros importados
SELECT 
    'Categorias' as tabela,
    COUNT(*) as total_registros
FROM categories
UNION ALL
SELECT 
    'Produtos' as tabela,
    COUNT(*) as total_registros
FROM products
UNION ALL
SELECT 
    'Especificações Técnicas' as tabela,
    COUNT(*) as total_registros
FROM technical_specifications
UNION ALL
SELECT 
    'Preços' as tabela,
    COUNT(*) as total_registros
FROM pricing
UNION ALL
SELECT 
    'Informações Fiscais' as tabela,
    COUNT(*) as total_registros
FROM tax_information
UNION ALL
SELECT 
    'Relacionamentos' as tabela,
    COUNT(*) as total_registros
FROM product_relationships
UNION ALL
SELECT 
    'Tecnologias STIHL' as tabela,
    COUNT(*) as total_registros
FROM stihl_technologies
UNION ALL
SELECT 
    'Campanhas' as tabela,
    COUNT(*) as total_registros
FROM campaigns
ORDER BY tabela;

-- Verificação de integridade referencial
\echo 'Verificando integridade referencial...'

-- Produtos sem categoria
SELECT COUNT(*) as produtos_sem_categoria 
FROM products p 
LEFT JOIN categories c ON p.category_id = c.id 
WHERE c.id IS NULL;

-- Especificações sem produto
SELECT COUNT(*) as especificacoes_sem_produto 
FROM technical_specifications ts 
LEFT JOIN products p ON ts.product_id = p.id 
WHERE p.id IS NULL;

-- Preços sem produto
SELECT COUNT(*) as precos_sem_produto 
FROM pricing pr 
LEFT JOIN products p ON pr.product_id = p.id 
WHERE p.id IS NULL;

\echo '================================================='
\echo 'IMPORTAÇÃO CONCLUÍDA COM SUCESSO!'
\echo '================================================='

-- Comentários finais
COMMENT ON SCHEMA public IS 'Schema principal do Sistema STIHL AI - Dados importados de arquivos CSV normalizados';

-- Log de importação
INSERT INTO audit_log (table_name, operation, user_name, timestamp, details)
VALUES ('ALL_TABLES', 'CSV_IMPORT', current_user, NOW(), 'Importação completa de dados CSV realizada com sucesso');

