-- =====================================================
-- Script de Importação de Dados CSV para Sistema STIHL AI v5
-- =====================================================
-- Este script importa dados de arquivos CSV normalizados
-- para as tabelas do banco de dados STIHL AI baseado na estrutura v5
-- 
-- Pré-requisitos:
-- 1. Tabelas já criadas (execute 01_create_tables_v5.sql primeiro)
-- 2. Arquivos CSV disponíveis no servidor em /tmp/csv_data/
-- 
-- Ordem de execução recomendada:
-- 1. 01_create_tables_v5.sql
-- 2. 05_import_csv_data_v5.sql (este arquivo)
-- 3. 02_create_functions_v5.sql
-- 4. 04_security_rls_v5.sql
-- =====================================================

-- Configurações para importação
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;

-- =====================================================
-- SEÇÃO 1: PREPARAÇÃO PARA IMPORTAÇÃO
-- =====================================================

\echo '================================================='
\echo 'INICIANDO IMPORTAÇÃO DE DADOS CSV STIHL AI v5'
\echo '================================================='

-- Limpar dados existentes (se houver)
\echo 'Limpando dados existentes...'

TRUNCATE TABLE subst_tributaria CASCADE;
TRUNCATE TABLE outras_maquinas CASCADE;
TRUNCATE TABLE materiais_pdv CASCADE;
TRUNCATE TABLE outros CASCADE;
TRUNCATE TABLE conveniencia CASCADE;
TRUNCATE TABLE ferr_basicas CASCADE;
TRUNCATE TABLE ferramentas CASCADE;
TRUNCATE TABLE informativo_galoes CASCADE;
TRUNCATE TABLE autonomia_baterias CASCADE;
TRUNCATE TABLE medidas_correntes CASCADE;
TRUNCATE TABLE pecas CASCADE;
TRUNCATE TABLE cj_corte_fs CASCADE;
TRUNCATE TABLE sabres_correntes_pinhoes_limas CASCADE;
TRUNCATE TABLE lancamentos CASCADE;
TRUNCATE TABLE campanhas_stihl CASCADE;
TRUNCATE TABLE tabela_dif_icms_f_cd_rs CASCADE;
TRUNCATE TABLE tabela_dif_icms_f_cd_pa CASCADE;
TRUNCATE TABLE epis CASCADE;
TRUNCATE TABLE tabela_conj_de_corte_fs CASCADE;
TRUNCATE TABLE ms CASCADE;
TRUNCATE TABLE rocadeiras_e_impl CASCADE;
TRUNCATE TABLE tabela_dif_icms_f_cd_sp CASCADE;
TRUNCATE TABLE cod_alterados CASCADE;
TRUNCATE TABLE acessorios CASCADE;
TRUNCATE TABLE artigos_da_marca CASCADE;
TRUNCATE TABLE calculadora CASCADE;
TRUNCATE TABLE tecnologias_stihl CASCADE;
TRUNCATE TABLE produtos_a_bateria CASCADE;

-- =====================================================
-- SEÇÃO 2: IMPORTAÇÃO DE DADOS PRINCIPAIS
-- =====================================================

-- Importar Motosserras (MS)
\echo 'Importando dados de motosserras (ms.csv)...'
COPY ms (
    unnamed_2, codigo_material, preco_real, qtde_min, descricao, 
    cilindrada_cm3, pot, unnamed_10, sabre, corrente, 
    unnamed_13, unnamed_14, capacidade_do_tanque_de_combustivel_l, 
    capacidade_do_tanque_de_oleo_l, peso_kg, s, t, ipi, 
    ncm_classif_fiscal, cod_barras
)
FROM '/tmp/csv_data/ms.csv'
WITH (FORMAT csv, HEADER true, DELIMITER ',', ENCODING 'UTF8', NULL '');

-- Verificar importação de motosserras
SELECT COUNT(*) as total_motosserras FROM ms;

-- Importar Roçadeiras e Implementos
\echo 'Importando dados de roçadeiras e implementos (rocadeiras_e_impl.csv)...'
COPY rocadeiras_e_impl (
    unnamed_2, unnamed_4, codigo_material, preco_real, qtde_min, 
    descricao, cilindrada_cm3, pot, unnamed_11, peso, 
    conjunto_de_corte, s, t, ipi, ncm_classif_fiscal, cod_barras
)
FROM '/tmp/csv_data/rocadeiras_e_impl.csv'
WITH (FORMAT csv, HEADER true, DELIMITER ',', ENCODING 'UTF8', NULL '');

-- Verificar importação de roçadeiras
SELECT COUNT(*) as total_rocadeiras FROM rocadeiras_e_impl;

-- Importar Peças
\echo 'Importando dados de peças (pecas.csv)...'
COPY pecas (
    codigo_material, preco_real, qtde_min, descricao, modelos, 
    origem, t, ipi, ncm_classif_fiscal, codigo_barras
)
FROM '/tmp/csv_data/pecas.csv'
WITH (FORMAT csv, HEADER true, DELIMITER ',', ENCODING 'UTF8', NULL '');

-- Verificar importação de peças
SELECT COUNT(*) as total_pecas FROM pecas;

-- Importar Acessórios
\echo 'Importando dados de acessórios (acessorios.csv)...'
COPY acessorios (
    codigo_material, preco_real, qtde_min, descricao, modelos, 
    origem, t, ipi, ncm_classif_fiscal, codigo_barras
)
FROM '/tmp/csv_data/acessorios.csv'
WITH (FORMAT csv, HEADER true, DELIMITER ',', ENCODING 'UTF8', NULL '');

-- Verificar importação de acessórios
SELECT COUNT(*) as total_acessorios FROM acessorios;

-- Importar Sabres, Correntes, Pinhões e Limas
\echo 'Importando dados de sabres, correntes, pinhões e limas...'
COPY sabres_correntes_pinhoes_limas (
    unnamed_1, codigo_material, preco_real, qtde_min, descricao, 
    modelos_maquinas, origem, t, ipi, ncm_classif_fiscal, codigo_barras
)
FROM '/tmp/csv_data/sabres_correntes_pinhoes_limas.csv'
WITH (FORMAT csv, HEADER true, DELIMITER ',', ENCODING 'UTF8', NULL '');

-- Verificar importação
SELECT COUNT(*) as total_sabres_correntes FROM sabres_correntes_pinhoes_limas;

-- Importar Produtos a Bateria
\echo 'Importando dados de produtos a bateria...'
COPY produtos_a_bateria (
    unnamed_1, unnamed_2, unnamed_3, codigo_material, preco_real, 
    descricao, qtde_min, bateria_recomendada, kit, tensao_carregador, 
    tensao_nominal_bateria_v, sabres_cm, corrente, velocidade_da_corrente_m_s, 
    peso_kg, s, t, ipi, ncm_classif_fiscal, cod_barras
)
FROM '/tmp/csv_data/produtos_a_bateria.csv'
WITH (FORMAT csv, HEADER true, DELIMITER ',', ENCODING 'UTF8', NULL '');

-- Verificar importação
SELECT COUNT(*) as total_produtos_bateria FROM produtos_a_bateria;

-- Importar Ferramentas
\echo 'Importando dados de ferramentas...'
COPY ferramentas (
    codigo_material, preco_real, qtde_min, descricao, modelos, 
    origem, t, ipi, ncm_classif_fiscal, codigo_barras, 
    ferramentas_basicas_para_oficina
)
FROM '/tmp/csv_data/ferramentas.csv'
WITH (FORMAT csv, HEADER true, DELIMITER ',', ENCODING 'UTF8', NULL '');

-- Verificar importação
SELECT COUNT(*) as total_ferramentas FROM ferramentas;

-- Importar EPIs
\echo 'Importando dados de EPIs...'
COPY epis (
    unnamed_1, codigo_material, preco_real, qtde_min, descricao, 
    material, protecao, s, t, ipi, ncm_classif_fiscal, 
    cod_ca, codigo_barras
)
FROM '/tmp/csv_data/epis.csv'
WITH (FORMAT csv, HEADER true, DELIMITER ',', ENCODING 'UTF8', NULL '');

-- Verificar importação
SELECT COUNT(*) as total_epis FROM epis;

-- =====================================================
-- SEÇÃO 3: IMPORTAÇÃO DE DADOS AUXILIARES
-- =====================================================

-- Importar Campanhas STIHL
\echo 'Importando campanhas STIHL...'
COPY campanhas_stihl (
    codigo, produto, preco_de_lista, preco_de_campanha, 
    desconto_de_campanha, quantidade_parcelas_sem_juros
)
FROM '/tmp/csv_data/campanhas_stihl.csv'
WITH (FORMAT csv, HEADER true, DELIMITER ',', ENCODING 'UTF8', NULL '');

-- Verificar importação
SELECT COUNT(*) as total_campanhas FROM campanhas_stihl;

-- Importar Lançamentos
\echo 'Importando lançamentos...'
COPY lancamentos (
    unnamed_2, unnamed_3, unnamed_4, codigo_material, preco_real, 
    descricao, qtde_min, bateria_recomendada, kit, tensao_carregador, 
    tensao_nominal_bateria_v, sabre, s, t, ipi, ncm_classif_fiscal, 
    cod_barras, unnamed_21
)
FROM '/tmp/csv_data/lancamentos.csv'
WITH (FORMAT csv, HEADER true, DELIMITER ',', ENCODING 'UTF8', NULL '');

-- Verificar importação
SELECT COUNT(*) as total_lancamentos FROM lancamentos;

-- Importar Outras Máquinas
\echo 'Importando outras máquinas...'
COPY outras_maquinas (
    unnamed_2, codigo_material, preco_real, qtde_min, descricao, 
    vazao_maxima_l_h, pressao_maxima_bar, pressao_de_trabalho_bar, 
    potencia_kw, tipo_de_motor, peso_kg, comprimento_da_mangueira_m, 
    cabecote_da_bomba, s, t, ipi, ncm_classif_fiscal, cod_barras
)
FROM '/tmp/csv_data/outras_maquinas.csv'
WITH (FORMAT csv, HEADER true, DELIMITER ',', ENCODING 'UTF8', NULL '');

-- Verificar importação
SELECT COUNT(*) as total_outras_maquinas FROM outras_maquinas;

-- Importar Artigos da Marca
\echo 'Importando artigos da marca...'
COPY artigos_da_marca (
    codigo_material, preco_real, qtde_min, descricao, modelos, 
    origem, t, ipi, ncm_classif_fiscal, codigo_barras
)
FROM '/tmp/csv_data/artigos_da_marca.csv'
WITH (FORMAT csv, HEADER true, DELIMITER ',', ENCODING 'UTF8', NULL '');

-- Verificar importação
SELECT COUNT(*) as total_artigos_marca FROM artigos_da_marca;

-- =====================================================
-- SEÇÃO 4: IMPORTAÇÃO DE DADOS INFORMATIVOS
-- =====================================================

-- Importar Conjunto de Corte FS
\echo 'Importando conjunto de corte FS...'
COPY cj_corte_fs (
    unnamed_1, codigo_material, preco_real, qtde_min, descricao, 
    modelo, comentario, s, t, ipi, classif_fiscal, codigo_barras
)
FROM '/tmp/csv_data/cj_corte_fs.csv'
WITH (FORMAT csv, HEADER true, DELIMITER ',', ENCODING 'UTF8', NULL '');

-- Importar Materiais PDV
\echo 'Importando materiais PDV...'
COPY materiais_pdv (
    unnamed_2, codigo_material, preco_real, qtde_min, item, 
    descricao, s, t, ipi, classif_fiscal, codigo_barras
)
FROM '/tmp/csv_data/materiais_pdv.csv'
WITH (FORMAT csv, HEADER true, DELIMITER ',', ENCODING 'UTF8', NULL '');

-- Importar Outros
\echo 'Importando outros produtos...'
COPY outros (
    unnamed_2, unnamed_4, codigo_material, preco_real, qtde_min, 
    descricao, unnamed_9, utilizacao, unnamed_11, unnamed_12, 
    s, t, ipi, ncm_classif_fiscal, codigo_barras, unnamed_18, unnamed_19
)
FROM '/tmp/csv_data/outros.csv'
WITH (FORMAT csv, HEADER true, DELIMITER ',', ENCODING 'UTF8', NULL '');

-- =====================================================
-- SEÇÃO 5: IMPORTAÇÃO DE DADOS FISCAIS E TRIBUTÁRIOS
-- =====================================================

-- Importar Substituição Tributária
\echo 'Importando dados de substituição tributária...'
COPY subst_tributaria (cod_material, descricao, s, t, ncm)
FROM '/tmp/csv_data/subst_tributaria.csv'
WITH (FORMAT csv, HEADER true, DELIMITER ',', ENCODING 'UTF8', NULL '');

-- Importar Tabelas de Diferencial de ICMS
\echo 'Importando tabelas de diferencial de ICMS...'

COPY tabela_dif_icms_f_cd_rs (
    produto_atualizado_novembro_2023, rs, sc_pr_sp_mg_rj, 
    unnamed_4, demais, unnamed_6, classificacao_fiscal
)
FROM '/tmp/csv_data/tabela_dif_icms_f_cd_rs.csv'
WITH (FORMAT csv, HEADER true, DELIMITER ',', ENCODING 'UTF8', NULL '');

COPY tabela_dif_icms_f_cd_pa (
    produto_atualizado_novembro_2023, pa, demais, 
    unnamed_4, classificacao_fiscal
)
FROM '/tmp/csv_data/tabela_dif_icms_f_cd_pa.csv'
WITH (FORMAT csv, HEADER true, DELIMITER ',', ENCODING 'UTF8', NULL '');

COPY tabela_dif_icms_f_cd_sp (
    produto_atualizado_novembro_2023, sp, sc_pr_rs_mg_rj, 
    unnamed_4, demais, unnamed_6, classificacao_fiscal
)
FROM '/tmp/csv_data/tabela_dif_icms_f_cd_sp.csv'
WITH (FORMAT csv, HEADER true, DELIMITER ',', ENCODING 'UTF8', NULL '');

-- =====================================================
-- SEÇÃO 6: IMPORTAÇÃO DE DADOS TÉCNICOS E INFORMATIVOS
-- =====================================================

-- Importar Códigos Alterados
\echo 'Importando códigos alterados...'
COPY cod_alterados (
    codigo_antigo, codigo_novo, descricao, data_alteracao, unnamed_7
)
FROM '/tmp/csv_data/cod_alterados.csv'
WITH (FORMAT csv, HEADER true, DELIMITER ',', ENCODING 'UTF8', NULL '');

-- Importar Calculadora
\echo 'Importando dados da calculadora...'
COPY calculadora (
    referencia, descricao, produtos, descricao_1, preco, observacao
)
FROM '/tmp/csv_data/calculadora.csv'
WITH (FORMAT csv, HEADER true, DELIMITER ',', ENCODING 'UTF8', NULL '');

-- Importar Autonomia de Baterias
\echo 'Importando dados de autonomia de baterias...'
COPY autonomia_baterias (
    unnamed_2, unnamed_3, bat_integrada, bateria_hsa_26, as_2, 
    ak_10, ak_20, ak_30_s, ap_200_s, ap_300_s, ap_500_s
)
FROM '/tmp/csv_data/autonomia_baterias.csv'
WITH (FORMAT csv, HEADER true, DELIMITER ',', ENCODING 'UTF8', NULL '');

-- Importar Medidas de Correntes
\echo 'Importando medidas de correntes...'
COPY medidas_correntes (
    codigo_dos_rolos_de_corrente_conforme_o_modelo_da_corrente, 
    unnamed_3, unnamed_4, unnamed_5, unnamed_6, unnamed_7, 
    codigo_rolo, no_de_elos_por_rolo, no_de_dentes_por_rolo, 
    ft_pes, metros
)
FROM '/tmp/csv_data/medidas_correntes.csv'
WITH (FORMAT csv, HEADER true, DELIMITER ',', ENCODING 'UTF8', NULL '');

-- Importar Tabela de Conjunto de Corte FS
\echo 'Importando tabela de conjunto de corte FS...'
COPY tabela_conj_de_corte_fs (
    itens_em_negrito_representam_o_fio_de_corte_disponivel_no_codigo,
    codigo_de_referencia, indicacoes_de_uso, unnamed_5, ferramenta_de_corte,
    perfil_do_fio_indicado, diametro_mm_comprimento_total_m, unnamed_9,
    unnamed_10, unnamed_11, impl_km_fs_ka_fs, fs_38,
    fs_55_r_fs_55_fs_80_fs_85_fs_120_fs_131_fr_220,
    fs_161_fs_221_fs_291_fs_300_fs_351_fs_380_fs_460,
    fsa_45, fsa_57, fsa_65_fsa_86, fse_41, fse_60
)
FROM '/tmp/csv_data/tabela_conj_de_corte_fs.csv'
WITH (FORMAT csv, HEADER true, DELIMITER ',', ENCODING 'UTF8', NULL '');

-- =====================================================
-- SEÇÃO 7: IMPORTAÇÃO DE DADOS ESPECIAIS
-- =====================================================

-- Importar Ferramentas Básicas (dados textuais)
\echo 'Importando ferramentas básicas...'
COPY ferr_basicas (descricao, observacao, codigo_stihl)
FROM '/tmp/csv_data/ferr_basicas.csv'
WITH (FORMAT csv, HEADER true, DELIMITER ',', ENCODING 'UTF8', NULL '');

-- Importar Conveniência (dados textuais)
\echo 'Importando dados de conveniência...'
COPY conveniencia (unnamed_2)
FROM '/tmp/csv_data/conveniencia.csv'
WITH (FORMAT csv, HEADER true, DELIMITER ',', ENCODING 'UTF8', NULL '');

-- Importar Informativo de Galões (dados textuais)
\echo 'Importando informativo de galões...'
COPY informativo_galoes (resolucao_inmetro_141_2019)
FROM '/tmp/csv_data/informativo_galoes.csv'
WITH (FORMAT csv, HEADER true, DELIMITER ',', ENCODING 'UTF8', NULL '');

-- Importar Tecnologias STIHL (dados textuais)
\echo 'Importando tecnologias STIHL...'
COPY tecnologias_stihl (unnamed_3)
FROM '/tmp/csv_data/tecnologias_stihl.csv'
WITH (FORMAT csv, HEADER true, DELIMITER ',', ENCODING 'UTF8', NULL '');

-- =====================================================
-- SEÇÃO 8: CRIAÇÃO DE ÍNDICES PARA PERFORMANCE
-- =====================================================

\echo 'Criando índices para otimização de performance...'

-- Índices para busca textual em português
CREATE INDEX IF NOT EXISTS idx_ms_search_text ON ms USING gin(to_tsvector('portuguese', COALESCE(descricao, '')));
CREATE INDEX IF NOT EXISTS idx_rocadeiras_search_text ON rocadeiras_e_impl USING gin(to_tsvector('portuguese', COALESCE(descricao, '')));
CREATE INDEX IF NOT EXISTS idx_pecas_search_text ON pecas USING gin(to_tsvector('portuguese', COALESCE(descricao, '') || ' ' || COALESCE(modelos, '')));
CREATE INDEX IF NOT EXISTS idx_acessorios_search_text ON acessorios USING gin(to_tsvector('portuguese', COALESCE(descricao, '') || ' ' || COALESCE(modelos, '')));
CREATE INDEX IF NOT EXISTS idx_sabres_search_text ON sabres_correntes_pinhoes_limas USING gin(to_tsvector('portuguese', COALESCE(descricao, '') || ' ' || COALESCE(modelos_maquinas, '')));
CREATE INDEX IF NOT EXISTS idx_produtos_bateria_search_text ON produtos_a_bateria USING gin(to_tsvector('portuguese', COALESCE(descricao, '')));
CREATE INDEX IF NOT EXISTS idx_ferramentas_search_text ON ferramentas USING gin(to_tsvector('portuguese', COALESCE(descricao, '') || ' ' || COALESCE(modelos, '')));
CREATE INDEX IF NOT EXISTS idx_epis_search_text ON epis USING gin(to_tsvector('portuguese', COALESCE(descricao, '') || ' ' || COALESCE(material, '') || ' ' || COALESCE(protecao, '')));

-- Índices para busca por código de material
CREATE INDEX IF NOT EXISTS idx_ms_codigo ON ms(codigo_material);
CREATE INDEX IF NOT EXISTS idx_rocadeiras_codigo ON rocadeiras_e_impl(codigo_material);
CREATE INDEX IF NOT EXISTS idx_pecas_codigo ON pecas(codigo_material);
CREATE INDEX IF NOT EXISTS idx_acessorios_codigo ON acessorios(codigo_material);
CREATE INDEX IF NOT EXISTS idx_sabres_codigo ON sabres_correntes_pinhoes_limas(codigo_material);
CREATE INDEX IF NOT EXISTS idx_produtos_bateria_codigo ON produtos_a_bateria(codigo_material);
CREATE INDEX IF NOT EXISTS idx_ferramentas_codigo ON ferramentas(codigo_material);
CREATE INDEX IF NOT EXISTS idx_epis_codigo ON epis(codigo_material);

-- Índices para busca por preço
CREATE INDEX IF NOT EXISTS idx_ms_preco ON ms(preco_real) WHERE preco_real IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_rocadeiras_preco ON rocadeiras_e_impl(preco_real) WHERE preco_real IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_pecas_preco ON pecas(preco_real) WHERE preco_real IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_acessorios_preco ON acessorios(preco_real) WHERE preco_real IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_sabres_preco ON sabres_correntes_pinhoes_limas(preco_real) WHERE preco_real IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_produtos_bateria_preco ON produtos_a_bateria(preco_real) WHERE preco_real IS NOT NULL;

-- Índices para campanhas
CREATE INDEX IF NOT EXISTS idx_campanhas_codigo ON campanhas_stihl(codigo);
CREATE INDEX IF NOT EXISTS idx_campanhas_preco ON campanhas_stihl(preco_de_campanha) WHERE preco_de_campanha IS NOT NULL;

-- =====================================================
-- SEÇÃO 9: ATUALIZAÇÃO DE ESTATÍSTICAS
-- =====================================================

\echo 'Atualizando estatísticas do banco de dados...'

ANALYZE ms;
ANALYZE rocadeiras_e_impl;
ANALYZE pecas;
ANALYZE acessorios;
ANALYZE sabres_correntes_pinhoes_limas;
ANALYZE produtos_a_bateria;
ANALYZE ferramentas;
ANALYZE epis;
ANALYZE campanhas_stihl;
ANALYZE lancamentos;
ANALYZE outras_maquinas;
ANALYZE artigos_da_marca;
ANALYZE cj_corte_fs;
ANALYZE materiais_pdv;
ANALYZE outros;
ANALYZE subst_tributaria;
ANALYZE tabela_dif_icms_f_cd_rs;
ANALYZE tabela_dif_icms_f_cd_pa;
ANALYZE tabela_dif_icms_f_cd_sp;
ANALYZE cod_alterados;
ANALYZE calculadora;
ANALYZE autonomia_baterias;
ANALYZE medidas_correntes;
ANALYZE tabela_conj_de_corte_fs;
ANALYZE ferr_basicas;
ANALYZE conveniencia;
ANALYZE informativo_galoes;
ANALYZE tecnologias_stihl;

-- =====================================================
-- SEÇÃO 10: VERIFICAÇÃO FINAL E RELATÓRIO
-- =====================================================

\echo '================================================='
\echo 'RELATÓRIO DE IMPORTAÇÃO DE DADOS CSV v5'
\echo '================================================='

-- Relatório de contagem de registros importados
SELECT 
    'Motosserras (MS)' as tabela,
    COUNT(*) as total_registros
FROM ms
UNION ALL
SELECT 
    'Roçadeiras e Implementos' as tabela,
    COUNT(*) as total_registros
FROM rocadeiras_e_impl
UNION ALL
SELECT 
    'Peças' as tabela,
    COUNT(*) as total_registros
FROM pecas
UNION ALL
SELECT 
    'Acessórios' as tabela,
    COUNT(*) as total_registros
FROM acessorios
UNION ALL
SELECT 
    'Sabres, Correntes, Pinhões e Limas' as tabela,
    COUNT(*) as total_registros
FROM sabres_correntes_pinhoes_limas
UNION ALL
SELECT 
    'Produtos a Bateria' as tabela,
    COUNT(*) as total_registros
FROM produtos_a_bateria
UNION ALL
SELECT 
    'Ferramentas' as tabela,
    COUNT(*) as total_registros
FROM ferramentas
UNION ALL
SELECT 
    'EPIs' as tabela,
    COUNT(*) as total_registros
FROM epis
UNION ALL
SELECT 
    'Campanhas STIHL' as tabela,
    COUNT(*) as total_registros
FROM campanhas_stihl
UNION ALL
SELECT 
    'Lançamentos' as tabela,
    COUNT(*) as total_registros
FROM lancamentos
UNION ALL
SELECT 
    'Outras Máquinas' as tabela,
    COUNT(*) as total_registros
FROM outras_maquinas
UNION ALL
SELECT 
    'Artigos da Marca' as tabela,
    COUNT(*) as total_registros
FROM artigos_da_marca
ORDER BY total_registros DESC;

-- Verificação de dados com preços válidos
\echo 'Verificando produtos com preços válidos...'

SELECT 
    'Motosserras com preço' as categoria,
    COUNT(*) as total
FROM ms 
WHERE preco_real IS NOT NULL AND preco_real > 0
UNION ALL
SELECT 
    'Roçadeiras com preço' as categoria,
    COUNT(*) as total
FROM rocadeiras_e_impl 
WHERE preco_real IS NOT NULL AND preco_real > 0
UNION ALL
SELECT 
    'Peças com preço' as categoria,
    COUNT(*) as total
FROM pecas 
WHERE preco_real IS NOT NULL AND preco_real > 0
UNION ALL
SELECT 
    'Acessórios com preço' as categoria,
    COUNT(*) as total
FROM acessorios 
WHERE preco_real IS NOT NULL AND preco_real > 0;

-- Verificação de campanhas ativas
SELECT 
    'Campanhas com desconto' as categoria,
    COUNT(*) as total
FROM campanhas_stihl 
WHERE preco_de_campanha IS NOT NULL AND preco_de_campanha > 0;

\echo '================================================='
\echo 'IMPORTAÇÃO CONCLUÍDA COM SUCESSO!'
\echo 'Base de dados STIHL AI v5 pronta para uso.'
\echo '================================================='

-- Comentários finais
COMMENT ON SCHEMA public IS 'Schema principal do Sistema STIHL AI v5 - Dados importados de arquivos CSV normalizados baseados na estrutura original da planilha STIHL';

