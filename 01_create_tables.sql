-- =====================================================
-- SCRIPT DE CRIAÇÃO DE TABELAS PARA SUPABASE
-- Sistema de Busca Inteligente STIHL
-- =====================================================

-- Habilitar extensões necessárias
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";
CREATE EXTENSION IF NOT EXISTS "unaccent";

-- =====================================================
-- TABELA: categories
-- Estrutura hierárquica para categorização de produtos
-- =====================================================
CREATE TABLE categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) NOT NULL,
    slug VARCHAR(100) UNIQUE NOT NULL,
    parent_id UUID REFERENCES categories(id),
    level INTEGER DEFAULT 0,
    sort_order INTEGER DEFAULT 0,
    description TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Índices para categories
CREATE INDEX idx_categories_parent ON categories(parent_id);
CREATE INDEX idx_categories_slug ON categories(slug);
CREATE INDEX idx_categories_level ON categories(level);
CREATE INDEX idx_categories_active ON categories(is_active);

-- =====================================================
-- TABELA: products
-- Informações básicas dos produtos
-- =====================================================
CREATE TABLE products (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    material_code VARCHAR(50) UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    brand VARCHAR(100) DEFAULT 'STIHL',
    category_id UUID REFERENCES categories(id),
    model VARCHAR(100),
    barcode VARCHAR(50),
    status VARCHAR(20) DEFAULT 'active',
    search_keywords TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Índices para products
CREATE UNIQUE INDEX idx_products_material_code ON products(material_code);
CREATE INDEX idx_products_category ON products(category_id);
CREATE INDEX idx_products_status ON products(status);
CREATE INDEX idx_products_model ON products(model);
CREATE INDEX idx_products_brand ON products(brand);

-- Índice de busca textual
CREATE INDEX idx_products_search_text ON products 
USING gin(to_tsvector('portuguese', 
    name || ' ' || 
    COALESCE(description, '') || ' ' || 
    COALESCE(search_keywords, '') || ' ' ||
    COALESCE(model, '')
));

-- =====================================================
-- TABELA: technical_specifications
-- Especificações técnicas dos produtos
-- =====================================================
CREATE TABLE technical_specifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID REFERENCES products(id) ON DELETE CASCADE,
    displacement_cc DECIMAL(5,2),
    power_kw DECIMAL(4,2),
    power_hp DECIMAL(4,2),
    weight_kg DECIMAL(5,2),
    fuel_tank_capacity_l DECIMAL(4,2),
    oil_tank_capacity_l DECIMAL(4,2),
    bar_length_cm INTEGER,
    chain_model VARCHAR(100),
    chain_pitch VARCHAR(20),
    chain_thickness_mm DECIMAL(3,1),
    additional_specs JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Índices para technical_specifications
CREATE INDEX idx_tech_specs_product ON technical_specifications(product_id);
CREATE INDEX idx_tech_specs_power ON technical_specifications(power_kw);
CREATE INDEX idx_tech_specs_displacement ON technical_specifications(displacement_cc);
CREATE INDEX idx_tech_specs_weight ON technical_specifications(weight_kg);
CREATE INDEX idx_tech_specs_additional ON technical_specifications USING gin(additional_specs);

-- =====================================================
-- TABELA: pricing
-- Informações de preços e disponibilidade
-- =====================================================
CREATE TABLE pricing (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID REFERENCES products(id) ON DELETE CASCADE,
    price_type VARCHAR(50) DEFAULT 'suggested_retail',
    price_value DECIMAL(10,2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'BRL',
    minimum_quantity INTEGER DEFAULT 1,
    region_code VARCHAR(10),
    valid_from DATE DEFAULT CURRENT_DATE,
    valid_until DATE,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Índices para pricing
CREATE INDEX idx_pricing_product ON pricing(product_id);
CREATE INDEX idx_pricing_active ON pricing(is_active);
CREATE INDEX idx_pricing_type ON pricing(price_type);
CREATE INDEX idx_pricing_value ON pricing(price_value);
CREATE INDEX idx_pricing_region ON pricing(region_code);
CREATE INDEX idx_pricing_valid ON pricing(valid_from, valid_until);

-- =====================================================
-- TABELA: tax_information
-- Informações fiscais dos produtos
-- =====================================================
CREATE TABLE tax_information (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID REFERENCES products(id) ON DELETE CASCADE,
    ncm_code VARCHAR(20) NOT NULL,
    ipi_rate DECIMAL(5,2),
    icms_rate DECIMAL(5,2),
    pis_rate DECIMAL(5,2),
    cofins_rate DECIMAL(5,2),
    tax_substitution_rs BOOLEAN DEFAULT false,
    tax_substitution_sp BOOLEAN DEFAULT false,
    tax_substitution_pa BOOLEAN DEFAULT false,
    tax_regime VARCHAR(50),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Índices para tax_information
CREATE INDEX idx_tax_info_product ON tax_information(product_id);
CREATE INDEX idx_tax_info_ncm ON tax_information(ncm_code);
CREATE INDEX idx_tax_info_substitution ON tax_information(tax_substitution_rs, tax_substitution_sp, tax_substitution_pa);

-- =====================================================
-- TABELA: product_relationships
-- Relacionamentos entre produtos
-- =====================================================
CREATE TABLE product_relationships (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID REFERENCES products(id) ON DELETE CASCADE,
    related_product_id UUID REFERENCES products(id) ON DELETE CASCADE,
    relationship_type VARCHAR(50) NOT NULL,
    compatibility_notes TEXT,
    is_bidirectional BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Índices para product_relationships
CREATE INDEX idx_relationships_product ON product_relationships(product_id);
CREATE INDEX idx_relationships_related ON product_relationships(related_product_id);
CREATE INDEX idx_relationships_type ON product_relationships(relationship_type);
CREATE INDEX idx_relationships_bidirectional ON product_relationships(product_id, related_product_id, relationship_type);

-- =====================================================
-- TABELA: stihl_technologies
-- Tecnologias específicas da STIHL
-- =====================================================
CREATE TABLE stihl_technologies (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) NOT NULL,
    description TEXT,
    category VARCHAR(50),
    benefits TEXT[],
    technical_details JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Índices para stihl_technologies
CREATE INDEX idx_technologies_name ON stihl_technologies(name);
CREATE INDEX idx_technologies_category ON stihl_technologies(category);

-- =====================================================
-- TABELA: product_technologies
-- Relaciona produtos com tecnologias STIHL
-- =====================================================
CREATE TABLE product_technologies (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID REFERENCES products(id) ON DELETE CASCADE,
    technology_id UUID REFERENCES stihl_technologies(id) ON DELETE CASCADE,
    implementation_notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Índices para product_technologies
CREATE INDEX idx_product_tech_product ON product_technologies(product_id);
CREATE INDEX idx_product_tech_technology ON product_technologies(technology_id);

-- =====================================================
-- TABELA: campaigns
-- Campanhas promocionais
-- =====================================================
CREATE TABLE campaigns (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    campaign_type VARCHAR(50),
    start_date DATE,
    end_date DATE,
    discount_percentage DECIMAL(5,2),
    terms_and_conditions TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Índices para campaigns
CREATE INDEX idx_campaigns_active ON campaigns(is_active);
CREATE INDEX idx_campaigns_dates ON campaigns(start_date, end_date);

-- =====================================================
-- TABELA: campaign_products
-- Relaciona produtos com campanhas
-- =====================================================
CREATE TABLE campaign_products (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    campaign_id UUID REFERENCES campaigns(id) ON DELETE CASCADE,
    product_id UUID REFERENCES products(id) ON DELETE CASCADE,
    special_price DECIMAL(10,2),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Índices para campaign_products
CREATE INDEX idx_campaign_products_campaign ON campaign_products(campaign_id);
CREATE INDEX idx_campaign_products_product ON campaign_products(product_id);

-- =====================================================
-- TABELA: audit_log
-- Log de auditoria para rastreabilidade
-- =====================================================
CREATE TABLE audit_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    table_name VARCHAR(100) NOT NULL,
    record_id UUID NOT NULL,
    operation VARCHAR(10) NOT NULL, -- INSERT, UPDATE, DELETE
    old_values JSONB,
    new_values JSONB,
    user_id UUID,
    user_role VARCHAR(50),
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    ip_address INET,
    user_agent TEXT
);

-- Índices para audit_log
CREATE INDEX idx_audit_log_table_record ON audit_log(table_name, record_id);
CREATE INDEX idx_audit_log_timestamp ON audit_log(timestamp);
CREATE INDEX idx_audit_log_user ON audit_log(user_id);

-- =====================================================
-- TABELA: query_cache
-- Cache inteligente para consultas frequentes
-- =====================================================
CREATE TABLE query_cache (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    query_hash VARCHAR(64) UNIQUE NOT NULL,
    query_text TEXT NOT NULL,
    result_data JSONB NOT NULL,
    hit_count INTEGER DEFAULT 1,
    last_accessed TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    expires_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Índices para query_cache
CREATE INDEX idx_query_cache_hash ON query_cache(query_hash);
CREATE INDEX idx_query_cache_expires ON query_cache(expires_at);
CREATE INDEX idx_query_cache_hits ON query_cache(hit_count DESC);

-- =====================================================
-- TABELA: query_metrics
-- Métricas de performance das consultas
-- =====================================================
CREATE TABLE query_metrics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    query_type VARCHAR(100) NOT NULL,
    query_parameters JSONB,
    execution_time_ms INTEGER,
    result_count INTEGER,
    user_satisfaction_score DECIMAL(3,2), -- 0.00 to 5.00
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    user_id UUID,
    session_id VARCHAR(100)
);

-- Índices para query_metrics
CREATE INDEX idx_query_metrics_type_time ON query_metrics(query_type, timestamp);
CREATE INDEX idx_query_metrics_execution_time ON query_metrics(execution_time_ms);
CREATE INDEX idx_query_metrics_satisfaction ON query_metrics(user_satisfaction_score);

-- =====================================================
-- COMENTÁRIOS DAS TABELAS
-- =====================================================
COMMENT ON TABLE categories IS 'Estrutura hierárquica para categorização de produtos STIHL';
COMMENT ON TABLE products IS 'Informações básicas dos produtos do catálogo STIHL';
COMMENT ON TABLE technical_specifications IS 'Especificações técnicas detalhadas dos produtos';
COMMENT ON TABLE pricing IS 'Informações de preços e políticas comerciais';
COMMENT ON TABLE tax_information IS 'Dados fiscais e tributários dos produtos';
COMMENT ON TABLE product_relationships IS 'Relacionamentos e compatibilidades entre produtos';
COMMENT ON TABLE stihl_technologies IS 'Tecnologias proprietárias da STIHL';
COMMENT ON TABLE product_technologies IS 'Associação de produtos com tecnologias STIHL';
COMMENT ON TABLE campaigns IS 'Campanhas promocionais e ofertas especiais';
COMMENT ON TABLE campaign_products IS 'Produtos incluídos em campanhas promocionais';
COMMENT ON TABLE audit_log IS 'Log de auditoria para rastreabilidade de operações';
COMMENT ON TABLE query_cache IS 'Cache inteligente para otimização de consultas da IA';
COMMENT ON TABLE query_metrics IS 'Métricas de performance e satisfação das consultas';

