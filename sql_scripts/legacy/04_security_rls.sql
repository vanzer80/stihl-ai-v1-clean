-- =====================================================
-- CONFIGURAÇÃO DE SEGURANÇA E ROW LEVEL SECURITY (RLS)
-- Sistema de Busca Inteligente STIHL
-- =====================================================

-- =====================================================
-- HABILITAR RLS NAS TABELAS PRINCIPAIS
-- =====================================================
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
ALTER TABLE pricing ENABLE ROW LEVEL SECURITY;
ALTER TABLE technical_specifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE tax_information ENABLE ROW LEVEL SECURITY;
ALTER TABLE product_relationships ENABLE ROW LEVEL SECURITY;
ALTER TABLE campaigns ENABLE ROW LEVEL SECURITY;
ALTER TABLE campaign_products ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- POLÍTICAS PARA TABELA: products
-- =====================================================

-- Política para leitura pública de produtos ativos
CREATE POLICY "Public read access to active products" ON products
    FOR SELECT USING (status = 'active');

-- Política para administradores (acesso total)
CREATE POLICY "Admin full access to products" ON products
    FOR ALL USING (
        COALESCE(auth.jwt() ->> 'role', 'anonymous') = 'admin'
    );

-- Política para revendedores (leitura de produtos ativos)
CREATE POLICY "Dealer read access to products" ON products
    FOR SELECT USING (
        status = 'active' AND 
        COALESCE(auth.jwt() ->> 'role', 'anonymous') IN ('dealer', 'admin')
    );

-- =====================================================
-- POLÍTICAS PARA TABELA: pricing
-- =====================================================

-- Política para acesso público a preços sugeridos
CREATE POLICY "Public access to suggested retail prices" ON pricing
    FOR SELECT USING (
        is_active = true AND 
        price_type = 'suggested_retail'
    );

-- Política para revendedores (acesso a preços de atacado)
CREATE POLICY "Dealer access to wholesale prices" ON pricing
    FOR SELECT USING (
        is_active = true AND
        COALESCE(auth.jwt() ->> 'role', 'anonymous') IN ('dealer', 'admin')
    );

-- Política para administradores (acesso total)
CREATE POLICY "Admin full access to pricing" ON pricing
    FOR ALL USING (
        COALESCE(auth.jwt() ->> 'role', 'anonymous') = 'admin'
    );

-- Política para acesso regional a preços
CREATE POLICY "Regional pricing access" ON pricing
    FOR SELECT USING (
        is_active = true AND (
            region_code IS NULL OR 
            region_code = COALESCE(auth.jwt() ->> 'region', 'BR') OR
            COALESCE(auth.jwt() ->> 'role', 'anonymous') = 'admin'
        )
    );

-- =====================================================
-- POLÍTICAS PARA TABELA: technical_specifications
-- =====================================================

-- Política para leitura pública de especificações
CREATE POLICY "Public read access to specifications" ON technical_specifications
    FOR SELECT USING (true);

-- Política para administradores (acesso total)
CREATE POLICY "Admin full access to specifications" ON technical_specifications
    FOR ALL USING (
        COALESCE(auth.jwt() ->> 'role', 'anonymous') = 'admin'
    );

-- =====================================================
-- POLÍTICAS PARA TABELA: tax_information
-- =====================================================

-- Política para revendedores e administradores
CREATE POLICY "Dealer and admin access to tax info" ON tax_information
    FOR SELECT USING (
        COALESCE(auth.jwt() ->> 'role', 'anonymous') IN ('dealer', 'admin')
    );

-- Política para administradores (acesso total)
CREATE POLICY "Admin full access to tax info" ON tax_information
    FOR ALL USING (
        COALESCE(auth.jwt() ->> 'role', 'anonymous') = 'admin'
    );

-- Política para informações fiscais regionais
CREATE POLICY "Regional tax information access" ON tax_information
    FOR SELECT USING (
        COALESCE(auth.jwt() ->> 'role', 'anonymous') IN ('dealer', 'admin') OR
        (COALESCE(auth.jwt() ->> 'region', 'BR') IN ('RS', 'SP', 'PA') AND 
         (tax_substitution_rs = true OR tax_substitution_sp = true OR tax_substitution_pa = true))
    );

-- =====================================================
-- POLÍTICAS PARA TABELA: product_relationships
-- =====================================================

-- Política para leitura pública de relacionamentos
CREATE POLICY "Public read access to relationships" ON product_relationships
    FOR SELECT USING (true);

-- Política para administradores (acesso total)
CREATE POLICY "Admin full access to relationships" ON product_relationships
    FOR ALL USING (
        COALESCE(auth.jwt() ->> 'role', 'anonymous') = 'admin'
    );

-- =====================================================
-- POLÍTICAS PARA TABELA: campaigns
-- =====================================================

-- Política para leitura pública de campanhas ativas
CREATE POLICY "Public read access to active campaigns" ON campaigns
    FOR SELECT USING (
        is_active = true AND 
        (start_date IS NULL OR start_date <= CURRENT_DATE) AND
        (end_date IS NULL OR end_date >= CURRENT_DATE)
    );

-- Política para administradores (acesso total)
CREATE POLICY "Admin full access to campaigns" ON campaigns
    FOR ALL USING (
        COALESCE(auth.jwt() ->> 'role', 'anonymous') = 'admin'
    );

-- =====================================================
-- POLÍTICAS PARA TABELA: campaign_products
-- =====================================================

-- Política para leitura pública de produtos em campanhas
CREATE POLICY "Public read access to campaign products" ON campaign_products
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM campaigns c 
            WHERE c.id = campaign_id 
            AND c.is_active = true
            AND (c.start_date IS NULL OR c.start_date <= CURRENT_DATE)
            AND (c.end_date IS NULL OR c.end_date >= CURRENT_DATE)
        )
    );

-- Política para administradores (acesso total)
CREATE POLICY "Admin full access to campaign products" ON campaign_products
    FOR ALL USING (
        COALESCE(auth.jwt() ->> 'role', 'anonymous') = 'admin'
    );

-- =====================================================
-- FUNÇÃO DE AUDITORIA GENÉRICA
-- =====================================================
CREATE OR REPLACE FUNCTION audit_trigger_function()
RETURNS TRIGGER AS $$
DECLARE
    user_id_val UUID;
    user_role_val VARCHAR(50);
BEGIN
    -- Extrair informações do usuário do JWT
    user_id_val := COALESCE((auth.jwt() ->> 'sub')::UUID, '00000000-0000-0000-0000-000000000000');
    user_role_val := COALESCE(auth.jwt() ->> 'role', 'anonymous');
    
    IF TG_OP = 'DELETE' THEN
        INSERT INTO audit_log (
            table_name, 
            record_id, 
            operation, 
            old_values, 
            user_id, 
            user_role,
            ip_address
        ) VALUES (
            TG_TABLE_NAME, 
            OLD.id, 
            TG_OP, 
            row_to_json(OLD), 
            user_id_val,
            user_role_val,
            inet_client_addr()
        );
        RETURN OLD;
    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO audit_log (
            table_name, 
            record_id, 
            operation, 
            old_values, 
            new_values, 
            user_id, 
            user_role,
            ip_address
        ) VALUES (
            TG_TABLE_NAME, 
            NEW.id, 
            TG_OP, 
            row_to_json(OLD), 
            row_to_json(NEW),
            user_id_val,
            user_role_val,
            inet_client_addr()
        );
        RETURN NEW;
    ELSIF TG_OP = 'INSERT' THEN
        INSERT INTO audit_log (
            table_name, 
            record_id, 
            operation, 
            new_values, 
            user_id, 
            user_role,
            ip_address
        ) VALUES (
            TG_TABLE_NAME, 
            NEW.id, 
            TG_OP, 
            row_to_json(NEW),
            user_id_val,
            user_role_val,
            inet_client_addr()
        );
        RETURN NEW;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- APLICAR TRIGGERS DE AUDITORIA
-- =====================================================
CREATE TRIGGER audit_products 
    AFTER INSERT OR UPDATE OR DELETE ON products
    FOR EACH ROW EXECUTE FUNCTION audit_trigger_function();

CREATE TRIGGER audit_pricing 
    AFTER INSERT OR UPDATE OR DELETE ON pricing
    FOR EACH ROW EXECUTE FUNCTION audit_trigger_function();

CREATE TRIGGER audit_technical_specifications 
    AFTER INSERT OR UPDATE OR DELETE ON technical_specifications
    FOR EACH ROW EXECUTE FUNCTION audit_trigger_function();

CREATE TRIGGER audit_tax_information 
    AFTER INSERT OR UPDATE OR DELETE ON tax_information
    FOR EACH ROW EXECUTE FUNCTION audit_trigger_function();

CREATE TRIGGER audit_categories 
    AFTER INSERT OR UPDATE OR DELETE ON categories
    FOR EACH ROW EXECUTE FUNCTION audit_trigger_function();

-- =====================================================
-- FUNÇÃO DE CACHE INTELIGENTE
-- =====================================================
CREATE OR REPLACE FUNCTION get_cached_query_result(
    p_query_text TEXT,
    p_ttl_minutes INTEGER DEFAULT 60
)
RETURNS JSONB AS $$
DECLARE
    query_hash_val VARCHAR(64);
    cached_result JSONB;
BEGIN
    -- Gerar hash da consulta
    query_hash_val := encode(digest(p_query_text, 'sha256'), 'hex');
    
    -- Tentar recuperar do cache
    SELECT result_data INTO cached_result
    FROM query_cache
    WHERE query_hash = query_hash_val
    AND (expires_at IS NULL OR expires_at > NOW());
    
    IF cached_result IS NOT NULL THEN
        -- Atualizar estatísticas de hit
        UPDATE query_cache 
        SET hit_count = hit_count + 1, 
            last_accessed = NOW()
        WHERE query_hash = query_hash_val;
        
        RETURN cached_result;
    END IF;
    
    -- Retornar NULL se não encontrado no cache
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- FUNÇÃO PARA ARMAZENAR RESULTADO NO CACHE
-- =====================================================
CREATE OR REPLACE FUNCTION store_query_result_cache(
    p_query_text TEXT,
    p_result_data JSONB,
    p_ttl_minutes INTEGER DEFAULT 60
)
RETURNS VOID AS $$
DECLARE
    query_hash_val VARCHAR(64);
    expires_at_val TIMESTAMP WITH TIME ZONE;
BEGIN
    -- Gerar hash da consulta
    query_hash_val := encode(digest(p_query_text, 'sha256'), 'hex');
    
    -- Calcular expiração
    expires_at_val := NOW() + (p_ttl_minutes || ' minutes')::INTERVAL;
    
    -- Inserir ou atualizar cache
    INSERT INTO query_cache (
        query_hash, 
        query_text, 
        result_data, 
        expires_at
    ) VALUES (
        query_hash_val, 
        p_query_text, 
        p_result_data, 
        expires_at_val
    )
    ON CONFLICT (query_hash) DO UPDATE SET
        result_data = EXCLUDED.result_data,
        expires_at = EXCLUDED.expires_at,
        hit_count = query_cache.hit_count + 1,
        last_accessed = NOW();
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- FUNÇÃO PARA LIMPEZA AUTOMÁTICA DO CACHE
-- =====================================================
CREATE OR REPLACE FUNCTION cleanup_expired_cache()
RETURNS INTEGER AS $$
DECLARE
    deleted_count INTEGER;
BEGIN
    -- Remover entradas expiradas
    DELETE FROM query_cache 
    WHERE expires_at IS NOT NULL 
    AND expires_at < NOW();
    
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    
    -- Remover entradas antigas com poucos hits (manter apenas top 1000)
    DELETE FROM query_cache 
    WHERE id NOT IN (
        SELECT id FROM query_cache 
        ORDER BY hit_count DESC, last_accessed DESC 
        LIMIT 1000
    );
    
    RETURN deleted_count;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- FUNÇÃO PARA REGISTRAR MÉTRICAS DE CONSULTA
-- =====================================================
CREATE OR REPLACE FUNCTION log_query_metrics(
    p_query_type VARCHAR(100),
    p_query_parameters JSONB,
    p_execution_time_ms INTEGER,
    p_result_count INTEGER,
    p_user_satisfaction_score DECIMAL(3,2) DEFAULT NULL
)
RETURNS VOID AS $$
DECLARE
    user_id_val UUID;
    session_id_val VARCHAR(100);
BEGIN
    -- Extrair informações do contexto
    user_id_val := COALESCE((auth.jwt() ->> 'sub')::UUID, '00000000-0000-0000-0000-000000000000');
    session_id_val := COALESCE(auth.jwt() ->> 'session_id', 'anonymous');
    
    -- Inserir métricas
    INSERT INTO query_metrics (
        query_type,
        query_parameters,
        execution_time_ms,
        result_count,
        user_satisfaction_score,
        user_id,
        session_id
    ) VALUES (
        p_query_type,
        p_query_parameters,
        p_execution_time_ms,
        p_result_count,
        p_user_satisfaction_score,
        user_id_val,
        session_id_val
    );
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- VIEWS MATERIALIZADAS PARA PERFORMANCE
-- =====================================================

-- View materializada com informações completas dos produtos
CREATE MATERIALIZED VIEW product_complete_info AS
SELECT 
    p.id,
    p.material_code,
    p.name,
    p.description,
    p.brand,
    p.model,
    p.barcode,
    p.status,
    p.search_keywords,
    c.name as category_name,
    c.slug as category_slug,
    c.level as category_level,
    ts.displacement_cc,
    ts.power_kw,
    ts.power_hp,
    ts.weight_kg,
    ts.fuel_tank_capacity_l,
    ts.oil_tank_capacity_l,
    ts.bar_length_cm,
    ts.chain_model,
    ts.additional_specs,
    pr.price_value as current_price,
    pr.currency,
    pr.minimum_quantity,
    ti.ncm_code,
    ti.ipi_rate,
    ti.tax_substitution_rs,
    ti.tax_substitution_sp,
    ti.tax_substitution_pa,
    array_agg(DISTINCT st.name) FILTER (WHERE st.name IS NOT NULL) as technologies,
    p.created_at,
    p.updated_at
FROM products p
LEFT JOIN categories c ON p.category_id = c.id
LEFT JOIN technical_specifications ts ON p.id = ts.product_id
LEFT JOIN pricing pr ON p.id = pr.product_id 
    AND pr.is_active = true 
    AND pr.price_type = 'suggested_retail'
LEFT JOIN tax_information ti ON p.id = ti.product_id
LEFT JOIN product_technologies pt ON p.id = pt.product_id
LEFT JOIN stihl_technologies st ON pt.technology_id = st.id
WHERE p.status = 'active'
GROUP BY 
    p.id, p.material_code, p.name, p.description, p.brand, p.model, 
    p.barcode, p.status, p.search_keywords, c.name, c.slug, c.level,
    ts.displacement_cc, ts.power_kw, ts.power_hp, ts.weight_kg,
    ts.fuel_tank_capacity_l, ts.oil_tank_capacity_l, ts.bar_length_cm,
    ts.chain_model, ts.additional_specs, pr.price_value, pr.currency,
    pr.minimum_quantity, ti.ncm_code, ti.ipi_rate, ti.tax_substitution_rs,
    ti.tax_substitution_sp, ti.tax_substitution_pa, p.created_at, p.updated_at;

-- Índices para a view materializada
CREATE INDEX idx_product_complete_info_search ON product_complete_info 
USING gin(to_tsvector('portuguese', 
    name || ' ' || 
    COALESCE(description, '') || ' ' || 
    COALESCE(search_keywords, '') || ' ' ||
    COALESCE(model, '')
));

CREATE INDEX idx_product_complete_info_category ON product_complete_info(category_slug);
CREATE INDEX idx_product_complete_info_price ON product_complete_info(current_price);
CREATE INDEX idx_product_complete_info_material_code ON product_complete_info(material_code);

-- =====================================================
-- FUNÇÃO PARA REFRESH DAS VIEWS MATERIALIZADAS
-- =====================================================
CREATE OR REPLACE FUNCTION refresh_materialized_views()
RETURNS VOID AS $$
BEGIN
    REFRESH MATERIALIZED VIEW CONCURRENTLY product_complete_info;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- COMENTÁRIOS DAS POLÍTICAS E FUNÇÕES
-- =====================================================
COMMENT ON FUNCTION audit_trigger_function IS 'Função genérica para auditoria de operações nas tabelas';
COMMENT ON FUNCTION get_cached_query_result IS 'Recupera resultado de consulta do cache inteligente';
COMMENT ON FUNCTION store_query_result_cache IS 'Armazena resultado de consulta no cache';
COMMENT ON FUNCTION cleanup_expired_cache IS 'Remove entradas expiradas do cache';
COMMENT ON FUNCTION log_query_metrics IS 'Registra métricas de performance das consultas';
COMMENT ON FUNCTION refresh_materialized_views IS 'Atualiza views materializadas para performance';

-- Refresh inicial da view materializada
SELECT refresh_materialized_views();

