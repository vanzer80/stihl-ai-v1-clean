-- =====================================================
-- Funções SQL Especializadas para Sistema STIHL AI v5
-- =====================================================
-- Este script cria funções especializadas para busca inteligente
-- e operações avançadas no banco de dados STIHL AI v5
-- 
-- Pré-requisitos:
-- 1. Tabelas criadas (01_create_tables_v5.sql)
-- 2. Dados importados (05_import_csv_data_v5.sql)
-- 
-- Funcionalidades:
-- - Busca inteligente unificada em todas as tabelas
-- - Busca por compatibilidade de produtos
-- - Recomendações baseadas em uso
-- - Funções de análise de preços
-- - Busca por código de material
-- =====================================================

-- Configurações
SET search_path TO public;

-- =====================================================
-- SEÇÃO 1: FUNÇÕES DE BUSCA INTELIGENTE PRINCIPAL
-- =====================================================

-- Função principal de busca inteligente unificada
CREATE OR REPLACE FUNCTION intelligent_product_search_v5(
    search_query TEXT,
    max_results INTEGER DEFAULT 20,
    price_min DECIMAL DEFAULT NULL,
    price_max DECIMAL DEFAULT NULL,
    product_category TEXT DEFAULT NULL
)
RETURNS TABLE (
    source_table TEXT,
    codigo_material VARCHAR(32),
    descricao TEXT,
    preco_real DECIMAL(12,2),
    modelos_compatibilidade TEXT,
    categoria_produto TEXT,
    relevance_score REAL
) AS $$
BEGIN
    RETURN QUERY
    WITH search_results AS (
        -- Busca em Motosserras (MS)
        SELECT 
            'motosserras'::TEXT as source_table,
            m.codigo_material,
            m.descricao::TEXT as descricao,
            m.preco_real,
            COALESCE(m.cilindrada_cm3 || ' cm³', '')::TEXT as modelos_compatibilidade,
            'Motosserra'::TEXT as categoria_produto,
            ts_rank(
                to_tsvector('portuguese', COALESCE(m.descricao, '')),
                plainto_tsquery('portuguese', search_query)
            ) as relevance_score
        FROM ms m
        WHERE 
            (search_query IS NULL OR 
             to_tsvector('portuguese', COALESCE(m.descricao, '')) @@ plainto_tsquery('portuguese', search_query) OR
             m.codigo_material ILIKE '%' || search_query || '%' OR
             m.descricao ILIKE '%' || search_query || '%')
            AND (price_min IS NULL OR m.preco_real >= price_min)
            AND (price_max IS NULL OR m.preco_real <= price_max)
            AND (product_category IS NULL OR product_category ILIKE '%motosserra%')
            AND m.preco_real IS NOT NULL
            AND m.preco_real > 0

        UNION ALL

        -- Busca em Roçadeiras e Implementos
        SELECT 
            'rocadeiras'::TEXT as source_table,
            r.codigo_material,
            r.descricao::TEXT as descricao,
            r.preco_real,
            COALESCE(r.cilindrada_cm3 || ' cm³', '')::TEXT as modelos_compatibilidade,
            'Roçadeira'::TEXT as categoria_produto,
            ts_rank(
                to_tsvector('portuguese', COALESCE(r.descricao, '')),
                plainto_tsquery('portuguese', search_query)
            ) as relevance_score
        FROM rocadeiras_e_impl r
        WHERE 
            (search_query IS NULL OR 
             to_tsvector('portuguese', COALESCE(r.descricao, '')) @@ plainto_tsquery('portuguese', search_query) OR
             r.codigo_material ILIKE '%' || search_query || '%' OR
             r.descricao ILIKE '%' || search_query || '%')
            AND (price_min IS NULL OR r.preco_real >= price_min)
            AND (price_max IS NULL OR r.preco_real <= price_max)
            AND (product_category IS NULL OR product_category ILIKE '%roçadeira%')
            AND r.preco_real IS NOT NULL
            AND r.preco_real > 0

        UNION ALL

        -- Busca em Produtos a Bateria
        SELECT 
            'produtos_bateria'::TEXT as source_table,
            p.codigo_material,
            p.descricao::TEXT as descricao,
            p.preco_real,
            COALESCE(p.bateria_recomendada, '')::TEXT as modelos_compatibilidade,
            'Produto a Bateria'::TEXT as categoria_produto,
            ts_rank(
                to_tsvector('portuguese', COALESCE(p.descricao, '')),
                plainto_tsquery('portuguese', search_query)
            ) as relevance_score
        FROM produtos_a_bateria p
        WHERE 
            (search_query IS NULL OR 
             to_tsvector('portuguese', COALESCE(p.descricao, '')) @@ plainto_tsquery('portuguese', search_query) OR
             p.codigo_material ILIKE '%' || search_query || '%' OR
             p.descricao ILIKE '%' || search_query || '%')
            AND (price_min IS NULL OR p.preco_real >= price_min)
            AND (price_max IS NULL OR p.preco_real <= price_max)
            AND (product_category IS NULL OR product_category ILIKE '%bateria%')
            AND p.preco_real IS NOT NULL
            AND p.preco_real > 0

        UNION ALL

        -- Busca em Peças
        SELECT 
            'pecas'::TEXT as source_table,
            pe.codigo_material,
            pe.descricao::TEXT as descricao,
            pe.preco_real,
            COALESCE(pe.modelos, '')::TEXT as modelos_compatibilidade,
            'Peça'::TEXT as categoria_produto,
            ts_rank(
                to_tsvector('portuguese', COALESCE(pe.descricao, '') || ' ' || COALESCE(pe.modelos, '')),
                plainto_tsquery('portuguese', search_query)
            ) as relevance_score
        FROM pecas pe
        WHERE 
            (search_query IS NULL OR 
             to_tsvector('portuguese', COALESCE(pe.descricao, '') || ' ' || COALESCE(pe.modelos, '')) @@ plainto_tsquery('portuguese', search_query) OR
             pe.codigo_material ILIKE '%' || search_query || '%' OR
             pe.descricao ILIKE '%' || search_query || '%' OR
             pe.modelos ILIKE '%' || search_query || '%')
            AND (price_min IS NULL OR pe.preco_real >= price_min)
            AND (price_max IS NULL OR pe.preco_real <= price_max)
            AND (product_category IS NULL OR product_category ILIKE '%peça%')
            AND pe.preco_real IS NOT NULL
            AND pe.preco_real > 0

        UNION ALL

        -- Busca em Acessórios
        SELECT 
            'acessorios'::TEXT as source_table,
            a.codigo_material,
            a.descricao::TEXT as descricao,
            a.preco_real,
            COALESCE(a.modelos, '')::TEXT as modelos_compatibilidade,
            'Acessório'::TEXT as categoria_produto,
            ts_rank(
                to_tsvector('portuguese', COALESCE(a.descricao, '') || ' ' || COALESCE(a.modelos, '')),
                plainto_tsquery('portuguese', search_query)
            ) as relevance_score
        FROM acessorios a
        WHERE 
            (search_query IS NULL OR 
             to_tsvector('portuguese', COALESCE(a.descricao, '') || ' ' || COALESCE(a.modelos, '')) @@ plainto_tsquery('portuguese', search_query) OR
             a.codigo_material ILIKE '%' || search_query || '%' OR
             a.descricao ILIKE '%' || search_query || '%' OR
             a.modelos ILIKE '%' || search_query || '%')
            AND (price_min IS NULL OR a.preco_real >= price_min)
            AND (price_max IS NULL OR a.preco_real <= price_max)
            AND (product_category IS NULL OR product_category ILIKE '%acessorio%')
            AND a.preco_real IS NOT NULL
            AND a.preco_real > 0

        UNION ALL

        -- Busca em Sabres, Correntes, Pinhões e Limas
        SELECT 
            'sabres_correntes'::TEXT as source_table,
            s.codigo_material,
            s.descricao::TEXT as descricao,
            s.preco_real,
            COALESCE(s.modelos_maquinas, '')::TEXT as modelos_compatibilidade,
            'Sabre/Corrente/Pinhão/Lima'::TEXT as categoria_produto,
            ts_rank(
                to_tsvector('portuguese', COALESCE(s.descricao, '') || ' ' || COALESCE(s.modelos_maquinas, '')),
                plainto_tsquery('portuguese', search_query)
            ) as relevance_score
        FROM sabres_correntes_pinhoes_limas s
        WHERE 
            (search_query IS NULL OR 
             to_tsvector('portuguese', COALESCE(s.descricao, '') || ' ' || COALESCE(s.modelos_maquinas, '')) @@ plainto_tsquery('portuguese', search_query) OR
             s.codigo_material ILIKE '%' || search_query || '%' OR
             s.descricao ILIKE '%' || search_query || '%' OR
             s.modelos_maquinas ILIKE '%' || search_query || '%')
            AND (price_min IS NULL OR s.preco_real >= price_min)
            AND (price_max IS NULL OR s.preco_real <= price_max)
            AND (product_category IS NULL OR 
                 product_category ILIKE '%sabre%' OR 
                 product_category ILIKE '%corrente%' OR 
                 product_category ILIKE '%pinhao%' OR 
                 product_category ILIKE '%lima%')
            AND s.preco_real IS NOT NULL
            AND s.preco_real > 0

        UNION ALL

        -- Busca em Ferramentas
        SELECT 
            'ferramentas'::TEXT as source_table,
            f.codigo_material,
            f.descricao::TEXT as descricao,
            f.preco_real,
            COALESCE(f.modelos, '')::TEXT as modelos_compatibilidade,
            'Ferramenta'::TEXT as categoria_produto,
            ts_rank(
                to_tsvector('portuguese', COALESCE(f.descricao, '') || ' ' || COALESCE(f.modelos, '')),
                plainto_tsquery('portuguese', search_query)
            ) as relevance_score
        FROM ferramentas f
        WHERE 
            (search_query IS NULL OR 
             to_tsvector('portuguese', COALESCE(f.descricao, '') || ' ' || COALESCE(f.modelos, '')) @@ plainto_tsquery('portuguese', search_query) OR
             f.codigo_material ILIKE '%' || search_query || '%' OR
             f.descricao ILIKE '%' || search_query || '%' OR
             f.modelos ILIKE '%' || search_query || '%')
            AND (price_min IS NULL OR f.preco_real >= price_min)
            AND (price_max IS NULL OR f.preco_real <= price_max)
            AND (product_category IS NULL OR product_category ILIKE '%ferramenta%')
            AND f.preco_real IS NOT NULL
            AND f.preco_real > 0

        UNION ALL

        -- Busca em EPIs
        SELECT 
            'epis'::TEXT as source_table,
            e.codigo_material,
            e.descricao::TEXT as descricao,
            e.preco_real,
            COALESCE(e.material || ' - ' || e.protecao, '')::TEXT as modelos_compatibilidade,
            'EPI'::TEXT as categoria_produto,
            ts_rank(
                to_tsvector('portuguese', COALESCE(e.descricao, '') || ' ' || COALESCE(e.material, '') || ' ' || COALESCE(e.protecao, '')),
                plainto_tsquery('portuguese', search_query)
            ) as relevance_score
        FROM epis e
        WHERE 
            (search_query IS NULL OR 
             to_tsvector('portuguese', COALESCE(e.descricao, '') || ' ' || COALESCE(e.material, '') || ' ' || COALESCE(e.protecao, '')) @@ plainto_tsquery('portuguese', search_query) OR
             e.codigo_material ILIKE '%' || search_query || '%' OR
             e.descricao ILIKE '%' || search_query || '%')
            AND (price_min IS NULL OR e.preco_real >= price_min)
            AND (price_max IS NULL OR e.preco_real <= price_max)
            AND (product_category IS NULL OR product_category ILIKE '%epi%')
            AND e.preco_real IS NOT NULL
            AND e.preco_real > 0
    )
    SELECT 
        sr.source_table,
        sr.codigo_material,
        sr.descricao,
        sr.preco_real,
        sr.modelos_compatibilidade,
        sr.categoria_produto,
        sr.relevance_score
    FROM search_results sr
    WHERE sr.relevance_score > 0 OR search_query IS NULL
    ORDER BY sr.relevance_score DESC, sr.preco_real ASC
    LIMIT max_results;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- SEÇÃO 2: FUNÇÕES DE BUSCA POR CÓDIGO DE MATERIAL
-- =====================================================

-- Função para buscar produto específico por código
CREATE OR REPLACE FUNCTION get_product_by_code_v5(material_code TEXT)
RETURNS TABLE (
    source_table TEXT,
    codigo_material VARCHAR(32),
    descricao TEXT,
    preco_real DECIMAL(12,2),
    detalhes_tecnicos TEXT,
    modelos_compatibilidade TEXT,
    categoria_produto TEXT
) AS $$
BEGIN
    RETURN QUERY
    -- Busca em Motosserras
    SELECT 
        'motosserras'::TEXT as source_table,
        m.codigo_material,
        m.descricao::TEXT as descricao,
        m.preco_real,
        CONCAT(
            'Cilindrada: ', COALESCE(m.cilindrada_cm3, ''), ' cm³, ',
            'Potência: ', COALESCE(m.pot::TEXT, ''), ' kW, ',
            'Peso: ', COALESCE(m.peso_kg::TEXT, ''), ' kg, ',
            'Sabre: ', COALESCE(m.sabre, ''), ', ',
            'Corrente: ', COALESCE(m.corrente, '')
        )::TEXT as detalhes_tecnicos,
        COALESCE(m.cilindrada_cm3 || ' cm³', '')::TEXT as modelos_compatibilidade,
        'Motosserra'::TEXT as categoria_produto
    FROM ms m
    WHERE m.codigo_material = material_code

    UNION ALL

    -- Busca em Roçadeiras
    SELECT 
        'rocadeiras'::TEXT as source_table,
        r.codigo_material,
        r.descricao::TEXT as descricao,
        r.preco_real,
        CONCAT(
            'Cilindrada: ', COALESCE(r.cilindrada_cm3, ''), ' cm³, ',
            'Potência: ', COALESCE(r.pot::TEXT, ''), ' kW, ',
            'Peso: ', COALESCE(r.peso::TEXT, ''), ' kg, ',
            'Conjunto de corte: ', COALESCE(r.conjunto_de_corte, '')
        )::TEXT as detalhes_tecnicos,
        COALESCE(r.cilindrada_cm3 || ' cm³', '')::TEXT as modelos_compatibilidade,
        'Roçadeira'::TEXT as categoria_produto
    FROM rocadeiras_e_impl r
    WHERE r.codigo_material = material_code

    UNION ALL

    -- Busca em Produtos a Bateria
    SELECT 
        'produtos_bateria'::TEXT as source_table,
        p.codigo_material,
        p.descricao::TEXT as descricao,
        p.preco_real,
        CONCAT(
            'Bateria recomendada: ', COALESCE(p.bateria_recomendada, ''), ', ',
            'Tensão: ', COALESCE(p.tensao_nominal_bateria_v, ''), ', ',
            'Peso: ', COALESCE(p.peso_kg, ''), ' kg'
        )::TEXT as detalhes_tecnicos,
        COALESCE(p.bateria_recomendada, '')::TEXT as modelos_compatibilidade,
        'Produto a Bateria'::TEXT as categoria_produto
    FROM produtos_a_bateria p
    WHERE p.codigo_material = material_code

    UNION ALL

    -- Busca em Peças
    SELECT 
        'pecas'::TEXT as source_table,
        pe.codigo_material,
        pe.descricao::TEXT as descricao,
        pe.preco_real,
        'Peça de reposição original STIHL'::TEXT as detalhes_tecnicos,
        COALESCE(pe.modelos, '')::TEXT as modelos_compatibilidade,
        'Peça'::TEXT as categoria_produto
    FROM pecas pe
    WHERE pe.codigo_material = material_code

    UNION ALL

    -- Busca em Acessórios
    SELECT 
        'acessorios'::TEXT as source_table,
        a.codigo_material,
        a.descricao::TEXT as descricao,
        a.preco_real,
        'Acessório original STIHL'::TEXT as detalhes_tecnicos,
        COALESCE(a.modelos, '')::TEXT as modelos_compatibilidade,
        'Acessório'::TEXT as categoria_produto
    FROM acessorios a
    WHERE a.codigo_material = material_code

    UNION ALL

    -- Busca em Sabres, Correntes, Pinhões e Limas
    SELECT 
        'sabres_correntes'::TEXT as source_table,
        s.codigo_material,
        s.descricao::TEXT as descricao,
        s.preco_real,
        'Componente de corte original STIHL'::TEXT as detalhes_tecnicos,
        COALESCE(s.modelos_maquinas, '')::TEXT as modelos_compatibilidade,
        'Sabre/Corrente/Pinhão/Lima'::TEXT as categoria_produto
    FROM sabres_correntes_pinhoes_limas s
    WHERE s.codigo_material = material_code

    UNION ALL

    -- Busca em Ferramentas
    SELECT 
        'ferramentas'::TEXT as source_table,
        f.codigo_material,
        f.descricao::TEXT as descricao,
        f.preco_real,
        CASE 
            WHEN f.ferramentas_basicas_para_oficina IS NOT NULL 
            THEN 'Ferramenta básica para oficina: ' || f.ferramentas_basicas_para_oficina
            ELSE 'Ferramenta especializada STIHL'
        END::TEXT as detalhes_tecnicos,
        COALESCE(f.modelos, '')::TEXT as modelos_compatibilidade,
        'Ferramenta'::TEXT as categoria_produto
    FROM ferramentas f
    WHERE f.codigo_material = material_code

    UNION ALL

    -- Busca em EPIs
    SELECT 
        'epis'::TEXT as source_table,
        e.codigo_material,
        e.descricao::TEXT as descricao,
        e.preco_real,
        CONCAT(
            'Material: ', COALESCE(e.material, ''), ', ',
            'Proteção: ', COALESCE(e.protecao, ''), ', ',
            'CA: ', COALESCE(e.cod_ca, '')
        )::TEXT as detalhes_tecnicos,
        COALESCE(e.material || ' - ' || e.protecao, '')::TEXT as modelos_compatibilidade,
        'EPI'::TEXT as categoria_produto
    FROM epis e
    WHERE e.codigo_material = material_code;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- SEÇÃO 3: FUNÇÕES DE COMPATIBILIDADE E RELACIONAMENTOS
-- =====================================================

-- Função para buscar produtos compatíveis com um modelo específico
CREATE OR REPLACE FUNCTION get_compatible_products_v5(model_name TEXT)
RETURNS TABLE (
    source_table TEXT,
    codigo_material VARCHAR(32),
    descricao TEXT,
    preco_real DECIMAL(12,2),
    tipo_compatibilidade TEXT,
    categoria_produto TEXT
) AS $$
BEGIN
    RETURN QUERY
    -- Busca peças compatíveis
    SELECT 
        'pecas'::TEXT as source_table,
        pe.codigo_material,
        pe.descricao::TEXT as descricao,
        pe.preco_real,
        'Peça compatível'::TEXT as tipo_compatibilidade,
        'Peça'::TEXT as categoria_produto
    FROM pecas pe
    WHERE pe.modelos ILIKE '%' || model_name || '%'
        AND pe.preco_real IS NOT NULL
        AND pe.preco_real > 0

    UNION ALL

    -- Busca acessórios compatíveis
    SELECT 
        'acessorios'::TEXT as source_table,
        a.codigo_material,
        a.descricao::TEXT as descricao,
        a.preco_real,
        'Acessório compatível'::TEXT as tipo_compatibilidade,
        'Acessório'::TEXT as categoria_produto
    FROM acessorios a
    WHERE a.modelos ILIKE '%' || model_name || '%'
        AND a.preco_real IS NOT NULL
        AND a.preco_real > 0

    UNION ALL

    -- Busca sabres e correntes compatíveis
    SELECT 
        'sabres_correntes'::TEXT as source_table,
        s.codigo_material,
        s.descricao::TEXT as descricao,
        s.preco_real,
        'Componente de corte compatível'::TEXT as tipo_compatibilidade,
        'Sabre/Corrente/Pinhão/Lima'::TEXT as categoria_produto
    FROM sabres_correntes_pinhoes_limas s
    WHERE s.modelos_maquinas ILIKE '%' || model_name || '%'
        AND s.preco_real IS NOT NULL
        AND s.preco_real > 0

    UNION ALL

    -- Busca ferramentas compatíveis
    SELECT 
        'ferramentas'::TEXT as source_table,
        f.codigo_material,
        f.descricao::TEXT as descricao,
        f.preco_real,
        'Ferramenta compatível'::TEXT as tipo_compatibilidade,
        'Ferramenta'::TEXT as categoria_produto
    FROM ferramentas f
    WHERE f.modelos ILIKE '%' || model_name || '%'
        AND f.preco_real IS NOT NULL
        AND f.preco_real > 0

    ORDER BY preco_real ASC;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- SEÇÃO 4: FUNÇÕES DE ANÁLISE DE PREÇOS E CAMPANHAS
-- =====================================================

-- Função para obter faixas de preço por categoria
CREATE OR REPLACE FUNCTION get_price_ranges_by_category_v5()
RETURNS TABLE (
    categoria TEXT,
    preco_minimo DECIMAL(12,2),
    preco_maximo DECIMAL(12,2),
    preco_medio DECIMAL(12,2),
    total_produtos BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        'Motosserras'::TEXT as categoria,
        MIN(m.preco_real) as preco_minimo,
        MAX(m.preco_real) as preco_maximo,
        ROUND(AVG(m.preco_real), 2) as preco_medio,
        COUNT(*) as total_produtos
    FROM ms m
    WHERE m.preco_real IS NOT NULL AND m.preco_real > 0

    UNION ALL

    SELECT 
        'Roçadeiras'::TEXT as categoria,
        MIN(r.preco_real) as preco_minimo,
        MAX(r.preco_real) as preco_maximo,
        ROUND(AVG(r.preco_real), 2) as preco_medio,
        COUNT(*) as total_produtos
    FROM rocadeiras_e_impl r
    WHERE r.preco_real IS NOT NULL AND r.preco_real > 0

    UNION ALL

    SELECT 
        'Produtos a Bateria'::TEXT as categoria,
        MIN(p.preco_real) as preco_minimo,
        MAX(p.preco_real) as preco_maximo,
        ROUND(AVG(p.preco_real), 2) as preco_medio,
        COUNT(*) as total_produtos
    FROM produtos_a_bateria p
    WHERE p.preco_real IS NOT NULL AND p.preco_real > 0

    UNION ALL

    SELECT 
        'Peças'::TEXT as categoria,
        MIN(pe.preco_real) as preco_minimo,
        MAX(pe.preco_real) as preco_maximo,
        ROUND(AVG(pe.preco_real), 2) as preco_medio,
        COUNT(*) as total_produtos
    FROM pecas pe
    WHERE pe.preco_real IS NOT NULL AND pe.preco_real > 0

    UNION ALL

    SELECT 
        'Acessórios'::TEXT as categoria,
        MIN(a.preco_real) as preco_minimo,
        MAX(a.preco_real) as preco_maximo,
        ROUND(AVG(a.preco_real), 2) as preco_medio,
        COUNT(*) as total_produtos
    FROM acessorios a
    WHERE a.preco_real IS NOT NULL AND a.preco_real > 0

    UNION ALL

    SELECT 
        'Sabres e Correntes'::TEXT as categoria,
        MIN(s.preco_real) as preco_minimo,
        MAX(s.preco_real) as preco_maximo,
        ROUND(AVG(s.preco_real), 2) as preco_medio,
        COUNT(*) as total_produtos
    FROM sabres_correntes_pinhoes_limas s
    WHERE s.preco_real IS NOT NULL AND s.preco_real > 0

    UNION ALL

    SELECT 
        'Ferramentas'::TEXT as categoria,
        MIN(f.preco_real) as preco_minimo,
        MAX(f.preco_real) as preco_maximo,
        ROUND(AVG(f.preco_real), 2) as preco_medio,
        COUNT(*) as total_produtos
    FROM ferramentas f
    WHERE f.preco_real IS NOT NULL AND f.preco_real > 0

    UNION ALL

    SELECT 
        'EPIs'::TEXT as categoria,
        MIN(e.preco_real) as preco_minimo,
        MAX(e.preco_real) as preco_maximo,
        ROUND(AVG(e.preco_real), 2) as preco_medio,
        COUNT(*) as total_produtos
    FROM epis e
    WHERE e.preco_real IS NOT NULL AND e.preco_real > 0

    ORDER BY preco_medio DESC;
END;
$$ LANGUAGE plpgsql;

-- Função para verificar produtos em campanha
CREATE OR REPLACE FUNCTION get_campaign_products_v5()
RETURNS TABLE (
    codigo VARCHAR(13),
    produto VARCHAR(57),
    preco_lista DECIMAL(12,2),
    preco_campanha DECIMAL(12,2),
    desconto_percentual DECIMAL(5,2),
    economia DECIMAL(12,2),
    parcelas_sem_juros DECIMAL(12,2)
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        c.codigo,
        c.produto,
        c.preco_de_lista,
        c.preco_de_campanha,
        ROUND(((c.preco_de_lista - c.preco_de_campanha) / c.preco_de_lista * 100), 2) as desconto_percentual,
        (c.preco_de_lista - c.preco_de_campanha) as economia,
        c.quantidade_parcelas_sem_juros
    FROM campanhas_stihl c
    WHERE c.preco_de_lista IS NOT NULL 
        AND c.preco_de_campanha IS NOT NULL
        AND c.preco_de_campanha < c.preco_de_lista
    ORDER BY desconto_percentual DESC;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- SEÇÃO 5: FUNÇÕES DE RECOMENDAÇÃO INTELIGENTE
-- =====================================================

-- Função para recomendações baseadas em uso
CREATE OR REPLACE FUNCTION get_product_recommendations_v5(
    usage_type TEXT DEFAULT 'domestico',
    budget_max DECIMAL DEFAULT NULL,
    product_type TEXT DEFAULT NULL
)
RETURNS TABLE (
    source_table TEXT,
    codigo_material VARCHAR(32),
    descricao TEXT,
    preco_real DECIMAL(12,2),
    categoria_produto TEXT,
    motivo_recomendacao TEXT,
    score_recomendacao INTEGER
) AS $$
BEGIN
    RETURN QUERY
    WITH recommendations AS (
        -- Recomendações de Motosserras
        SELECT 
            'motosserras'::TEXT as source_table,
            m.codigo_material,
            m.descricao::TEXT as descricao,
            m.preco_real,
            'Motosserra'::TEXT as categoria_produto,
            CASE 
                WHEN usage_type ILIKE '%domestico%' AND m.peso_kg <= 4.5 
                THEN 'Ideal para uso doméstico - leve e fácil de manusear'
                WHEN usage_type ILIKE '%profissional%' AND m.peso_kg > 4.5 
                THEN 'Recomendada para uso profissional - alta potência'
                WHEN usage_type ILIKE '%poda%' AND m.peso_kg <= 4.0 
                THEN 'Perfeita para poda - compacta e precisa'
                ELSE 'Motosserra versátil para diversos usos'
            END::TEXT as motivo_recomendacao,
            CASE 
                WHEN usage_type ILIKE '%domestico%' AND m.peso_kg <= 4.5 THEN 90
                WHEN usage_type ILIKE '%profissional%' AND m.peso_kg > 4.5 THEN 95
                WHEN usage_type ILIKE '%poda%' AND m.peso_kg <= 4.0 THEN 85
                ELSE 70
            END as score_recomendacao
        FROM ms m
        WHERE m.preco_real IS NOT NULL 
            AND m.preco_real > 0
            AND (budget_max IS NULL OR m.preco_real <= budget_max)
            AND (product_type IS NULL OR product_type ILIKE '%motosserra%')

        UNION ALL

        -- Recomendações de Roçadeiras
        SELECT 
            'rocadeiras'::TEXT as source_table,
            r.codigo_material,
            r.descricao::TEXT as descricao,
            r.preco_real,
            'Roçadeira'::TEXT as categoria_produto,
            CASE 
                WHEN usage_type ILIKE '%domestico%' AND r.peso <= 5.0 
                THEN 'Ideal para jardins domésticos - leve e eficiente'
                WHEN usage_type ILIKE '%profissional%' AND r.peso > 5.0 
                THEN 'Recomendada para uso profissional - alta performance'
                WHEN usage_type ILIKE '%limpeza%' 
                THEN 'Excelente para limpeza de terrenos'
                ELSE 'Roçadeira versátil para diversos usos'
            END::TEXT as motivo_recomendacao,
            CASE 
                WHEN usage_type ILIKE '%domestico%' AND r.peso <= 5.0 THEN 88
                WHEN usage_type ILIKE '%profissional%' AND r.peso > 5.0 THEN 92
                WHEN usage_type ILIKE '%limpeza%' THEN 85
                ELSE 75
            END as score_recomendacao
        FROM rocadeiras_e_impl r
        WHERE r.preco_real IS NOT NULL 
            AND r.preco_real > 0
            AND (budget_max IS NULL OR r.preco_real <= budget_max)
            AND (product_type IS NULL OR product_type ILIKE '%roçadeira%')

        UNION ALL

        -- Recomendações de Produtos a Bateria
        SELECT 
            'produtos_bateria'::TEXT as source_table,
            p.codigo_material,
            p.descricao::TEXT as descricao,
            p.preco_real,
            'Produto a Bateria'::TEXT as categoria_produto,
            CASE 
                WHEN usage_type ILIKE '%domestico%' 
                THEN 'Ideal para uso doméstico - sem emissões, silencioso'
                WHEN usage_type ILIKE '%ecologico%' 
                THEN 'Opção ecológica - zero emissões locais'
                WHEN usage_type ILIKE '%urbano%' 
                THEN 'Perfeito para áreas urbanas - baixo ruído'
                ELSE 'Produto a bateria versátil e sustentável'
            END::TEXT as motivo_recomendacao,
            CASE 
                WHEN usage_type ILIKE '%domestico%' THEN 85
                WHEN usage_type ILIKE '%ecologico%' THEN 95
                WHEN usage_type ILIKE '%urbano%' THEN 90
                ELSE 80
            END as score_recomendacao
        FROM produtos_a_bateria p
        WHERE p.preco_real IS NOT NULL 
            AND p.preco_real > 0
            AND (budget_max IS NULL OR p.preco_real <= budget_max)
            AND (product_type IS NULL OR product_type ILIKE '%bateria%')
    )
    SELECT 
        r.source_table,
        r.codigo_material,
        r.descricao,
        r.preco_real,
        r.categoria_produto,
        r.motivo_recomendacao,
        r.score_recomendacao
    FROM recommendations r
    WHERE r.score_recomendacao >= 70
    ORDER BY r.score_recomendacao DESC, r.preco_real ASC
    LIMIT 10;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- SEÇÃO 6: FUNÇÕES DE ESTATÍSTICAS E ANALYTICS
-- =====================================================

-- Função para obter estatísticas gerais do catálogo
CREATE OR REPLACE FUNCTION get_catalog_statistics_v5()
RETURNS TABLE (
    categoria TEXT,
    total_produtos BIGINT,
    produtos_com_preco BIGINT,
    preco_medio DECIMAL(12,2),
    produto_mais_caro TEXT,
    preco_mais_caro DECIMAL(12,2)
) AS $$
BEGIN
    RETURN QUERY
    -- Estatísticas de Motosserras
    SELECT 
        'Motosserras'::TEXT as categoria,
        COUNT(*) as total_produtos,
        COUNT(CASE WHEN preco_real IS NOT NULL AND preco_real > 0 THEN 1 END) as produtos_com_preco,
        ROUND(AVG(CASE WHEN preco_real IS NOT NULL AND preco_real > 0 THEN preco_real END), 2) as preco_medio,
        (SELECT descricao FROM ms WHERE preco_real = (SELECT MAX(preco_real) FROM ms WHERE preco_real IS NOT NULL) LIMIT 1)::TEXT as produto_mais_caro,
        (SELECT MAX(preco_real) FROM ms WHERE preco_real IS NOT NULL) as preco_mais_caro
    FROM ms

    UNION ALL

    -- Estatísticas de Roçadeiras
    SELECT 
        'Roçadeiras'::TEXT as categoria,
        COUNT(*) as total_produtos,
        COUNT(CASE WHEN preco_real IS NOT NULL AND preco_real > 0 THEN 1 END) as produtos_com_preco,
        ROUND(AVG(CASE WHEN preco_real IS NOT NULL AND preco_real > 0 THEN preco_real END), 2) as preco_medio,
        (SELECT descricao FROM rocadeiras_e_impl WHERE preco_real = (SELECT MAX(preco_real) FROM rocadeiras_e_impl WHERE preco_real IS NOT NULL) LIMIT 1)::TEXT as produto_mais_caro,
        (SELECT MAX(preco_real) FROM rocadeiras_e_impl WHERE preco_real IS NOT NULL) as preco_mais_caro
    FROM rocadeiras_e_impl

    UNION ALL

    -- Estatísticas de Peças
    SELECT 
        'Peças'::TEXT as categoria,
        COUNT(*) as total_produtos,
        COUNT(CASE WHEN preco_real IS NOT NULL AND preco_real > 0 THEN 1 END) as produtos_com_preco,
        ROUND(AVG(CASE WHEN preco_real IS NOT NULL AND preco_real > 0 THEN preco_real END), 2) as preco_medio,
        (SELECT descricao FROM pecas WHERE preco_real = (SELECT MAX(preco_real) FROM pecas WHERE preco_real IS NOT NULL) LIMIT 1)::TEXT as produto_mais_caro,
        (SELECT MAX(preco_real) FROM pecas WHERE preco_real IS NOT NULL) as preco_mais_caro
    FROM pecas

    UNION ALL

    -- Estatísticas de Produtos a Bateria
    SELECT 
        'Produtos a Bateria'::TEXT as categoria,
        COUNT(*) as total_produtos,
        COUNT(CASE WHEN preco_real IS NOT NULL AND preco_real > 0 THEN 1 END) as produtos_com_preco,
        ROUND(AVG(CASE WHEN preco_real IS NOT NULL AND preco_real > 0 THEN preco_real END), 2) as preco_medio,
        (SELECT descricao FROM produtos_a_bateria WHERE preco_real = (SELECT MAX(preco_real) FROM produtos_a_bateria WHERE preco_real IS NOT NULL) LIMIT 1)::TEXT as produto_mais_caro,
        (SELECT MAX(preco_real) FROM produtos_a_bateria WHERE preco_real IS NOT NULL) as preco_mais_caro
    FROM produtos_a_bateria

    ORDER BY total_produtos DESC;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- SEÇÃO 7: COMENTÁRIOS E DOCUMENTAÇÃO
-- =====================================================

-- Comentários nas funções para documentação
COMMENT ON FUNCTION intelligent_product_search_v5(TEXT, INTEGER, DECIMAL, DECIMAL, TEXT) IS 'Função principal de busca inteligente unificada em todas as tabelas do catálogo STIHL v5';
COMMENT ON FUNCTION get_product_by_code_v5(TEXT) IS 'Busca produto específico por código de material em todas as tabelas';
COMMENT ON FUNCTION get_compatible_products_v5(TEXT) IS 'Retorna produtos compatíveis com um modelo específico';
COMMENT ON FUNCTION get_price_ranges_by_category_v5() IS 'Análise de faixas de preço por categoria de produto';
COMMENT ON FUNCTION get_campaign_products_v5() IS 'Lista produtos em campanha com descontos e economia';
COMMENT ON FUNCTION get_product_recommendations_v5(TEXT, DECIMAL, TEXT) IS 'Recomendações inteligentes baseadas em tipo de uso e orçamento';
COMMENT ON FUNCTION get_catalog_statistics_v5() IS 'Estatísticas gerais do catálogo de produtos STIHL';

-- Log de criação
SELECT 'Funções SQL especializadas para STIHL AI v5 criadas com sucesso!' as status;

