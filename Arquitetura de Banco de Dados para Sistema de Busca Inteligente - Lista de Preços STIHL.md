# Arquitetura de Banco de Dados para Sistema de Busca Inteligente - Lista de Preços STIHL

**Autor:** Manus AI  
**Data:** Setembro 2025  
**Versão:** 1.0

## Resumo Executivo

Este documento apresenta o design completo da arquitetura de banco de dados para um sistema de busca inteligente baseado na Lista Sugerida de Preços STIHL de Julho 2025. O objetivo é criar uma estrutura robusta e escalável no Supabase que permita a uma IA realizar buscas confiáveis e precisas sobre produtos, preços, especificações técnicas e informações relacionadas.

A arquitetura proposta utiliza um modelo relacional normalizado que preserva a integridade dos dados enquanto otimiza as consultas para sistemas de busca baseados em IA. O design contempla múltiplas categorias de produtos, desde motosserras até acessórios e peças de reposição, mantendo a flexibilidade para futuras expansões do catálogo.

## Análise dos Dados de Origem

### Estrutura da Planilha Original

A planilha Excel fornecida contém 30 abas distintas, cada uma representando diferentes categorias de produtos e informações auxiliares. As principais categorias identificadas incluem:

**Produtos Principais:**
- Motosserras (MS)
- Sabres, Correntes, Pinhões e Limas
- Roçadeiras e Implementos
- Produtos a Bateria
- Outras Máquinas

**Produtos Complementares:**
- Acessórios
- Peças de Reposição
- Ferramentas Básicas
- Equipamentos de Proteção Individual (EPIs)
- Artigos da Marca
- Materiais de Ponto de Venda (PDV)

**Informações Auxiliares:**
- Tabelas de Substituição Tributária
- Códigos Alterados
- Tecnologias STIHL
- Campanhas Promocionais
- Calculadoras de Autonomia

### Características dos Dados

Cada categoria de produto apresenta estruturas de dados específicas, mas compartilha elementos comuns como código do material, preço, descrição e classificação fiscal. A análise detalhada da aba "MS" (Motosserras) revelou a seguinte estrutura típica:

- **Código Material:** Identificador único do produto no sistema STIHL
- **Preço Real:** Valor sugerido de venda
- **Quantidade Mínima:** Lote mínimo para pedidos
- **Descrição:** Nome completo e especificações do produto
- **Especificações Técnicas:** Cilindrada, potência, peso, capacidades
- **Informações de Corte:** Tipo de sabre, corrente, passo, espessura
- **Dados Fiscais:** IPI, NCM, código de barras
- **Classificações:** Substituição tributária, categorias




## Princípios de Design da Arquitetura

### Normalização e Integridade Referencial

A arquitetura proposta segue os princípios de normalização de banco de dados para eliminar redundâncias e garantir a integridade dos dados. O design utiliza principalmente a Terceira Forma Normal (3NF), com algumas exceções estratégicas para otimização de consultas específicas da IA.

A estrutura normalizada oferece várias vantagens críticas para um sistema de busca inteligente. Primeiro, elimina a duplicação de informações, reduzindo o espaço de armazenamento e minimizando inconsistências. Segundo, facilita a manutenção dos dados, permitindo atualizações centralizadas que se propagam automaticamente por todo o sistema. Terceiro, melhora a qualidade das respostas da IA ao garantir que informações contraditórias não existam na base de dados.

### Otimização para Consultas de IA

O design considera especificamente as necessidades de sistemas de busca baseados em IA, que frequentemente requerem acesso rápido a informações relacionadas e capacidade de realizar consultas complexas envolvendo múltiplas tabelas. Para isso, a arquitetura incorpora:

**Índices Estratégicos:** Criação de índices compostos em combinações de campos frequentemente consultados pela IA, como categoria + marca + modelo, ou preço + disponibilidade + região.

**Campos de Busca Textual:** Implementação de campos específicos para busca full-text, incluindo descrições concatenadas e palavras-chave derivadas que facilitam consultas em linguagem natural.

**Tabelas de Relacionamento Otimizadas:** Estruturas intermediárias que pré-calculam relacionamentos complexos, reduzindo o tempo de resposta para consultas que envolvem múltiplas categorias de produtos.

### Escalabilidade e Flexibilidade

A arquitetura é projetada para suportar o crescimento futuro do catálogo de produtos e a evolução das necessidades do sistema de busca. Isso inclui:

**Estrutura Modular:** Cada categoria de produto é representada por tabelas específicas que herdam de uma estrutura base comum, permitindo a adição de novas categorias sem impacto nas existentes.

**Campos Extensíveis:** Utilização de campos JSON para armazenar especificações técnicas variáveis, permitindo que diferentes produtos tenham conjuntos únicos de características sem necessidade de alterações no esquema.

**Versionamento de Dados:** Implementação de campos de controle de versão e histórico que permitem rastrear mudanças de preços e especificações ao longo do tempo.

## Modelo Entidade-Relacionamento

### Entidades Principais

A arquitetura é estruturada em torno de seis entidades principais que capturam os aspectos essenciais dos dados de produtos STIHL:

**1. Produtos (products)**
Esta é a entidade central que armazena informações básicas comuns a todos os produtos, independentemente da categoria. Inclui identificadores únicos, informações de classificação e metadados essenciais.

**2. Categorias (categories)**
Define a hierarquia de categorização dos produtos, permitindo classificações múltiplas e aninhadas. Suporta tanto categorias principais (Motosserras, Roçadeiras) quanto subcategorias (Motosserras a Combustão, Motosserras Elétricas).

**3. Especificações Técnicas (technical_specifications)**
Armazena características técnicas específicas de cada produto usando uma estrutura flexível que acomoda diferentes tipos de especificações para diferentes categorias de produtos.

**4. Preços e Disponibilidade (pricing)**
Gerencia informações de preços, incluindo preços sugeridos, descontos, quantidades mínimas e disponibilidade regional. Suporta múltiplas tabelas de preços e políticas de desconto.

**5. Informações Fiscais (tax_information)**
Centraliza dados fiscais como NCM, IPI, ICMS e informações de substituição tributária, essenciais para operações comerciais e compliance fiscal.

**6. Relacionamentos de Produtos (product_relationships)**
Define relacionamentos entre produtos, como compatibilidades (sabres compatíveis com motosserras), substitutos e complementos, facilitando recomendações inteligentes.


### Detalhamento das Tabelas Principais

#### Tabela: products
Esta tabela serve como o núcleo central do sistema, armazenando informações básicas que são comuns a todos os produtos no catálogo STIHL.

```sql
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
```

**Campos Principais:**
- `material_code`: Código único do material no sistema STIHL (ex: "1148-200-0249")
- `name`: Nome comercial do produto
- `description`: Descrição completa incluindo especificações resumidas
- `search_keywords`: Campo otimizado para busca textual, contendo palavras-chave derivadas
- `status`: Controle de disponibilidade (active, discontinued, seasonal)

#### Tabela: categories
Implementa uma estrutura hierárquica flexível para categorização de produtos, suportando múltiplos níveis de aninhamento.

```sql
CREATE TABLE categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) NOT NULL,
    slug VARCHAR(100) UNIQUE NOT NULL,
    parent_id UUID REFERENCES categories(id),
    level INTEGER DEFAULT 0,
    sort_order INTEGER DEFAULT 0,
    description TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

**Estrutura Hierárquica Exemplo:**
- Motosserras (nível 0)
  - Motosserras a Combustão (nível 1)
    - MS 162 (nível 2)
    - MS 172 (nível 2)
  - Motosserras Elétricas (nível 1)
- Acessórios para Corte (nível 0)
  - Sabres (nível 1)
  - Correntes (nível 1)

#### Tabela: technical_specifications
Utiliza uma abordagem híbrida com campos estruturados para especificações comuns e um campo JSON para características específicas de categoria.

```sql
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
```

**Campo JSONB para Flexibilidade:**
O campo `additional_specs` permite armazenar especificações específicas de categoria:
```json
{
  "cutting_speed": "15 m/s",
  "vibration_level": "3.2 m/s²",
  "noise_level": "108 dB",
  "starter_type": "ElastoStart",
  "anti_vibration": true,
  "quick_chain_tensioning": true
}
```

#### Tabela: pricing
Gerencia informações de preços com suporte a múltiplas políticas de preço e variações regionais.

```sql
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
```

**Tipos de Preço Suportados:**
- `suggested_retail`: Preço sugerido de venda
- `wholesale`: Preço atacado
- `promotional`: Preço promocional
- `dealer_cost`: Custo para revendedores

#### Tabela: tax_information
Centraliza todas as informações fiscais necessárias para operações comerciais no Brasil.

```sql
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
```

#### Tabela: product_relationships
Define relacionamentos entre produtos para facilitar recomendações e consultas de compatibilidade.

```sql
CREATE TABLE product_relationships (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID REFERENCES products(id) ON DELETE CASCADE,
    related_product_id UUID REFERENCES products(id) ON DELETE CASCADE,
    relationship_type VARCHAR(50) NOT NULL,
    compatibility_notes TEXT,
    is_bidirectional BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

**Tipos de Relacionamento:**
- `compatible_with`: Produtos compatíveis (ex: sabre compatível com motosserra)
- `substitute_for`: Produtos substitutos
- `complement_to`: Produtos complementares
- `upgrade_from`: Versões superiores
- `accessory_for`: Acessórios específicos


### Tabelas Auxiliares e de Suporte

#### Tabela: campaigns
Gerencia campanhas promocionais e ofertas especiais mencionadas na planilha original.

```sql
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
```

#### Tabela: campaign_products
Relaciona produtos específicos com campanhas promocionais.

```sql
CREATE TABLE campaign_products (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    campaign_id UUID REFERENCES campaigns(id) ON DELETE CASCADE,
    product_id UUID REFERENCES products(id) ON DELETE CASCADE,
    special_price DECIMAL(10,2),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

#### Tabela: stihl_technologies
Armazena informações sobre tecnologias específicas da STIHL mencionadas nos produtos.

```sql
CREATE TABLE stihl_technologies (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) NOT NULL,
    description TEXT,
    category VARCHAR(50),
    benefits TEXT[],
    technical_details JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

#### Tabela: product_technologies
Relaciona produtos com as tecnologias STIHL que incorporam.

```sql
CREATE TABLE product_technologies (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID REFERENCES products(id) ON DELETE CASCADE,
    technology_id UUID REFERENCES stihl_technologies(id) ON DELETE CASCADE,
    implementation_notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

### Estratégia de Indexação

A performance das consultas da IA é crítica para a experiência do usuário. A estratégia de indexação foi desenvolvida considerando os padrões de consulta mais comuns:

#### Índices Primários
```sql
-- Busca por código de material (consulta mais comum)
CREATE INDEX idx_products_material_code ON products(material_code);

-- Busca por categoria
CREATE INDEX idx_products_category ON products(category_id);

-- Busca textual otimizada
CREATE INDEX idx_products_search_keywords ON products USING gin(to_tsvector('portuguese', search_keywords));

-- Busca por nome e descrição
CREATE INDEX idx_products_name_desc ON products USING gin(to_tsvector('portuguese', name || ' ' || COALESCE(description, '')));
```

#### Índices Compostos para Consultas Complexas
```sql
-- Busca por categoria e status
CREATE INDEX idx_products_category_status ON products(category_id, status);

-- Busca por preço e disponibilidade
CREATE INDEX idx_pricing_active_price ON pricing(is_active, price_value) WHERE is_active = true;

-- Busca por especificações técnicas comuns
CREATE INDEX idx_tech_specs_power_weight ON technical_specifications(power_kw, weight_kg);

-- Relacionamentos bidirecionais
CREATE INDEX idx_relationships_bidirectional ON product_relationships(product_id, related_product_id, relationship_type);
```

#### Índices para Consultas de IA
```sql
-- Suporte a consultas semânticas
CREATE INDEX idx_products_full_text ON products USING gin(
    to_tsvector('portuguese', 
        name || ' ' || 
        COALESCE(description, '') || ' ' || 
        COALESCE(search_keywords, '')
    )
);

-- Busca por especificações em JSONB
CREATE INDEX idx_tech_specs_additional ON technical_specifications USING gin(additional_specs);

-- Consultas por faixa de preço
CREATE INDEX idx_pricing_range ON pricing(price_value, currency, is_active) WHERE is_active = true;
```

### Views Materializadas para Performance

Para otimizar consultas complexas frequentemente executadas pela IA, implementamos views materializadas que pré-calculam junções e agregações:

#### View: product_complete_info
```sql
CREATE MATERIALIZED VIEW product_complete_info AS
SELECT 
    p.id,
    p.material_code,
    p.name,
    p.description,
    p.search_keywords,
    c.name as category_name,
    c.slug as category_slug,
    ts.displacement_cc,
    ts.power_kw,
    ts.power_hp,
    ts.weight_kg,
    ts.additional_specs,
    pr.price_value as current_price,
    pr.currency,
    ti.ncm_code,
    ti.ipi_rate,
    array_agg(DISTINCT st.name) as technologies
FROM products p
LEFT JOIN categories c ON p.category_id = c.id
LEFT JOIN technical_specifications ts ON p.id = ts.product_id
LEFT JOIN pricing pr ON p.id = pr.product_id AND pr.is_active = true AND pr.price_type = 'suggested_retail'
LEFT JOIN tax_information ti ON p.id = ti.product_id
LEFT JOIN product_technologies pt ON p.id = pt.product_id
LEFT JOIN stihl_technologies st ON pt.technology_id = st.id
WHERE p.status = 'active'
GROUP BY p.id, p.material_code, p.name, p.description, p.search_keywords, 
         c.name, c.slug, ts.displacement_cc, ts.power_kw, ts.power_hp, 
         ts.weight_kg, ts.additional_specs, pr.price_value, pr.currency, 
         ti.ncm_code, ti.ipi_rate;

-- Índice para a view materializada
CREATE INDEX idx_product_complete_info_search ON product_complete_info 
USING gin(to_tsvector('portuguese', name || ' ' || COALESCE(description, '') || ' ' || COALESCE(search_keywords, '')));
```

#### View: product_relationships_expanded
```sql
CREATE MATERIALIZED VIEW product_relationships_expanded AS
SELECT 
    pr.product_id,
    p1.name as product_name,
    p1.material_code as product_code,
    pr.related_product_id,
    p2.name as related_product_name,
    p2.material_code as related_product_code,
    pr.relationship_type,
    pr.compatibility_notes,
    c1.name as product_category,
    c2.name as related_product_category
FROM product_relationships pr
JOIN products p1 ON pr.product_id = p1.id
JOIN products p2 ON pr.related_product_id = p2.id
LEFT JOIN categories c1 ON p1.category_id = c1.id
LEFT JOIN categories c2 ON p2.category_id = c2.id
WHERE p1.status = 'active' AND p2.status = 'active';
```


## Segurança e Controle de Acesso

### Row Level Security (RLS) no Supabase

O Supabase oferece recursos avançados de segurança através do Row Level Security (RLS) do PostgreSQL. Nossa arquitetura implementa políticas granulares de acesso que garantem que apenas usuários autorizados possam acessar informações específicas.

#### Políticas de Segurança para Produtos
```sql
-- Habilitar RLS nas tabelas principais
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
ALTER TABLE pricing ENABLE ROW LEVEL SECURITY;
ALTER TABLE technical_specifications ENABLE ROW LEVEL SECURITY;

-- Política para leitura pública de produtos ativos
CREATE POLICY "Public read access to active products" ON products
    FOR SELECT USING (status = 'active');

-- Política para administradores
CREATE POLICY "Admin full access" ON products
    FOR ALL USING (auth.jwt() ->> 'role' = 'admin');

-- Política para revendedores autorizados
CREATE POLICY "Dealer access to pricing" ON pricing
    FOR SELECT USING (
        auth.jwt() ->> 'role' IN ('dealer', 'admin') OR
        (auth.jwt() ->> 'role' = 'customer' AND price_type = 'suggested_retail')
    );
```

#### Controle de Acesso Baseado em Região
```sql
-- Política para acesso regional a preços
CREATE POLICY "Regional pricing access" ON pricing
    FOR SELECT USING (
        region_code IS NULL OR 
        region_code = auth.jwt() ->> 'region' OR
        auth.jwt() ->> 'role' = 'admin'
    );

-- Política para informações fiscais regionais
CREATE POLICY "Regional tax information" ON tax_information
    FOR SELECT USING (
        auth.jwt() ->> 'role' IN ('dealer', 'admin') OR
        (auth.jwt() ->> 'region' IN ('RS', 'SP', 'PA') AND 
         (tax_substitution_rs = true OR tax_substitution_sp = true OR tax_substitution_pa = true))
    );
```

### Auditoria e Logs

Para garantir rastreabilidade completa das operações, implementamos um sistema de auditoria automático:

#### Tabela de Auditoria
```sql
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

-- Índices para consultas de auditoria
CREATE INDEX idx_audit_log_table_record ON audit_log(table_name, record_id);
CREATE INDEX idx_audit_log_timestamp ON audit_log(timestamp);
CREATE INDEX idx_audit_log_user ON audit_log(user_id);
```

#### Triggers de Auditoria
```sql
-- Função genérica de auditoria
CREATE OR REPLACE FUNCTION audit_trigger_function()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'DELETE' THEN
        INSERT INTO audit_log (table_name, record_id, operation, old_values, user_id, user_role)
        VALUES (TG_TABLE_NAME, OLD.id, TG_OP, row_to_json(OLD), 
                (auth.jwt() ->> 'sub')::UUID, auth.jwt() ->> 'role');
        RETURN OLD;
    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO audit_log (table_name, record_id, operation, old_values, new_values, user_id, user_role)
        VALUES (TG_TABLE_NAME, NEW.id, TG_OP, row_to_json(OLD), row_to_json(NEW),
                (auth.jwt() ->> 'sub')::UUID, auth.jwt() ->> 'role');
        RETURN NEW;
    ELSIF TG_OP = 'INSERT' THEN
        INSERT INTO audit_log (table_name, record_id, operation, new_values, user_id, user_role)
        VALUES (TG_TABLE_NAME, NEW.id, TG_OP, row_to_json(NEW),
                (auth.jwt() ->> 'sub')::UUID, auth.jwt() ->> 'role');
        RETURN NEW;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Aplicar triggers nas tabelas principais
CREATE TRIGGER audit_products AFTER INSERT OR UPDATE OR DELETE ON products
    FOR EACH ROW EXECUTE FUNCTION audit_trigger_function();

CREATE TRIGGER audit_pricing AFTER INSERT OR UPDATE OR DELETE ON pricing
    FOR EACH ROW EXECUTE FUNCTION audit_trigger_function();
```

## Otimizações para IA e Busca Semântica

### Implementação de Busca Vetorial

Para suportar consultas semânticas avançadas, a arquitetura inclui suporte a embeddings vetoriais usando a extensão pgvector do Supabase:

```sql
-- Habilitar extensão pgvector
CREATE EXTENSION IF NOT EXISTS vector;

-- Tabela para armazenar embeddings de produtos
CREATE TABLE product_embeddings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID REFERENCES products(id) ON DELETE CASCADE,
    embedding vector(1536), -- OpenAI ada-002 dimension
    content_hash VARCHAR(64), -- Para detectar mudanças no conteúdo
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Índice para busca vetorial eficiente
CREATE INDEX idx_product_embeddings_vector ON product_embeddings 
USING ivfflat (embedding vector_cosine_ops) WITH (lists = 100);
```

#### Função para Busca Semântica
```sql
CREATE OR REPLACE FUNCTION semantic_product_search(
    query_embedding vector(1536),
    similarity_threshold float DEFAULT 0.7,
    max_results int DEFAULT 10
)
RETURNS TABLE (
    product_id UUID,
    material_code VARCHAR(50),
    name VARCHAR(255),
    description TEXT,
    similarity_score float
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        p.id,
        p.material_code,
        p.name,
        p.description,
        1 - (pe.embedding <=> query_embedding) as similarity_score
    FROM product_embeddings pe
    JOIN products p ON pe.product_id = p.id
    WHERE 1 - (pe.embedding <=> query_embedding) > similarity_threshold
    AND p.status = 'active'
    ORDER BY pe.embedding <=> query_embedding
    LIMIT max_results;
END;
$$ LANGUAGE plpgsql;
```

### Cache Inteligente para Consultas Frequentes

Implementamos um sistema de cache que aprende com os padrões de consulta da IA:

#### Tabela de Cache de Consultas
```sql
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

-- Índices para performance do cache
CREATE INDEX idx_query_cache_hash ON query_cache(query_hash);
CREATE INDEX idx_query_cache_expires ON query_cache(expires_at);
CREATE INDEX idx_query_cache_hits ON query_cache(hit_count DESC);
```

#### Função de Cache Inteligente
```sql
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
        SET hit_count = hit_count + 1, last_accessed = NOW()
        WHERE query_hash = query_hash_val;
        
        RETURN cached_result;
    END IF;
    
    -- Retornar NULL se não encontrado no cache
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;
```


## Integração com Sistemas de IA

### API de Consulta Otimizada para IA

A arquitetura inclui funções SQL especializadas que facilitam a integração com sistemas de IA, fornecendo respostas estruturadas e contextualizadas:

#### Função de Busca Inteligente de Produtos
```sql
CREATE OR REPLACE FUNCTION intelligent_product_search(
    search_query TEXT,
    category_filter TEXT DEFAULT NULL,
    price_range_min DECIMAL DEFAULT NULL,
    price_range_max DECIMAL DEFAULT NULL,
    include_specifications BOOLEAN DEFAULT true,
    include_relationships BOOLEAN DEFAULT false
)
RETURNS JSONB AS $$
DECLARE
    result JSONB;
    query_vector vector(1536);
BEGIN
    -- Construir consulta base
    WITH search_results AS (
        SELECT 
            p.id,
            p.material_code,
            p.name,
            p.description,
            p.search_keywords,
            c.name as category_name,
            pr.price_value,
            pr.currency,
            CASE 
                WHEN search_query IS NOT NULL THEN
                    ts_rank(to_tsvector('portuguese', p.name || ' ' || COALESCE(p.description, '') || ' ' || COALESCE(p.search_keywords, '')), 
                            plainto_tsquery('portuguese', search_query))
                ELSE 1
            END as text_relevance_score
        FROM products p
        LEFT JOIN categories c ON p.category_id = c.id
        LEFT JOIN pricing pr ON p.id = pr.product_id AND pr.is_active = true AND pr.price_type = 'suggested_retail'
        WHERE p.status = 'active'
        AND (category_filter IS NULL OR c.slug = category_filter OR c.name ILIKE '%' || category_filter || '%')
        AND (price_range_min IS NULL OR pr.price_value >= price_range_min)
        AND (price_range_max IS NULL OR pr.price_value <= price_range_max)
        AND (search_query IS NULL OR 
             to_tsvector('portuguese', p.name || ' ' || COALESCE(p.description, '') || ' ' || COALESCE(p.search_keywords, '')) 
             @@ plainto_tsquery('portuguese', search_query))
        ORDER BY text_relevance_score DESC
        LIMIT 50
    ),
    enriched_results AS (
        SELECT 
            sr.*,
            CASE WHEN include_specifications THEN
                jsonb_build_object(
                    'displacement_cc', ts.displacement_cc,
                    'power_kw', ts.power_kw,
                    'power_hp', ts.power_hp,
                    'weight_kg', ts.weight_kg,
                    'fuel_tank_capacity_l', ts.fuel_tank_capacity_l,
                    'oil_tank_capacity_l', ts.oil_tank_capacity_l,
                    'bar_length_cm', ts.bar_length_cm,
                    'chain_model', ts.chain_model,
                    'additional_specs', ts.additional_specs
                )
            ELSE NULL END as specifications,
            CASE WHEN include_relationships THEN
                (SELECT jsonb_agg(
                    jsonb_build_object(
                        'type', pr_rel.relationship_type,
                        'product_name', p_rel.name,
                        'product_code', p_rel.material_code,
                        'notes', pr_rel.compatibility_notes
                    )
                )
                FROM product_relationships pr_rel
                JOIN products p_rel ON pr_rel.related_product_id = p_rel.id
                WHERE pr_rel.product_id = sr.id AND p_rel.status = 'active')
            ELSE NULL END as relationships
        FROM search_results sr
        LEFT JOIN technical_specifications ts ON sr.id = ts.product_id
    )
    SELECT jsonb_build_object(
        'total_results', count(*),
        'search_query', search_query,
        'filters_applied', jsonb_build_object(
            'category', category_filter,
            'price_min', price_range_min,
            'price_max', price_range_max
        ),
        'products', jsonb_agg(
            jsonb_build_object(
                'id', id,
                'material_code', material_code,
                'name', name,
                'description', description,
                'category', category_name,
                'price', jsonb_build_object(
                    'value', price_value,
                    'currency', currency
                ),
                'relevance_score', text_relevance_score,
                'specifications', specifications,
                'relationships', relationships
            )
        )
    ) INTO result
    FROM enriched_results;
    
    RETURN result;
END;
$$ LANGUAGE plpgsql;
```

#### Função de Recomendação Inteligente
```sql
CREATE OR REPLACE FUNCTION get_product_recommendations(
    base_product_id UUID,
    recommendation_types TEXT[] DEFAULT ARRAY['compatible_with', 'complement_to', 'substitute_for'],
    max_recommendations INTEGER DEFAULT 10
)
RETURNS JSONB AS $$
DECLARE
    result JSONB;
    base_product_info RECORD;
BEGIN
    -- Obter informações do produto base
    SELECT p.name, p.material_code, c.name as category_name, ts.power_kw, ts.displacement_cc
    INTO base_product_info
    FROM products p
    LEFT JOIN categories c ON p.category_id = c.id
    LEFT JOIN technical_specifications ts ON p.id = ts.product_id
    WHERE p.id = base_product_id;
    
    -- Gerar recomendações baseadas em relacionamentos e similaridade
    WITH direct_relationships AS (
        SELECT 
            p.id,
            p.material_code,
            p.name,
            p.description,
            c.name as category_name,
            pr_rel.relationship_type,
            pr_rel.compatibility_notes,
            1.0 as relevance_score,
            'direct_relationship' as recommendation_source
        FROM product_relationships pr_rel
        JOIN products p ON pr_rel.related_product_id = p.id
        LEFT JOIN categories c ON p.category_id = c.id
        WHERE pr_rel.product_id = base_product_id
        AND pr_rel.relationship_type = ANY(recommendation_types)
        AND p.status = 'active'
    ),
    similar_specs AS (
        SELECT 
            p.id,
            p.material_code,
            p.name,
            p.description,
            c.name as category_name,
            'similar_specifications' as relationship_type,
            'Produto com especificações similares' as compatibility_notes,
            CASE 
                WHEN base_product_info.power_kw IS NOT NULL AND ts.power_kw IS NOT NULL THEN
                    1.0 - ABS(base_product_info.power_kw - ts.power_kw) / GREATEST(base_product_info.power_kw, ts.power_kw)
                ELSE 0.5
            END as relevance_score,
            'similar_specifications' as recommendation_source
        FROM products p
        LEFT JOIN categories c ON p.category_id = c.id
        LEFT JOIN technical_specifications ts ON p.id = ts.product_id
        WHERE p.id != base_product_id
        AND p.status = 'active'
        AND c.name = base_product_info.category_name
        AND ts.power_kw IS NOT NULL
        AND base_product_info.power_kw IS NOT NULL
        ORDER BY relevance_score DESC
        LIMIT 5
    ),
    combined_recommendations AS (
        SELECT * FROM direct_relationships
        UNION ALL
        SELECT * FROM similar_specs
    )
    SELECT jsonb_build_object(
        'base_product', jsonb_build_object(
            'id', base_product_id,
            'name', base_product_info.name,
            'material_code', base_product_info.material_code,
            'category', base_product_info.category_name
        ),
        'recommendations', jsonb_agg(
            jsonb_build_object(
                'id', id,
                'material_code', material_code,
                'name', name,
                'description', description,
                'category', category_name,
                'relationship_type', relationship_type,
                'compatibility_notes', compatibility_notes,
                'relevance_score', relevance_score,
                'recommendation_source', recommendation_source
            )
            ORDER BY relevance_score DESC
        )
    ) INTO result
    FROM combined_recommendations
    LIMIT max_recommendations;
    
    RETURN result;
END;
$$ LANGUAGE plpgsql;
```

### Monitoramento e Analytics

Para otimizar continuamente o desempenho do sistema de IA, implementamos um sistema de monitoramento abrangente:

#### Tabela de Métricas de Consulta
```sql
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

-- Índices para análise de performance
CREATE INDEX idx_query_metrics_type_time ON query_metrics(query_type, timestamp);
CREATE INDEX idx_query_metrics_execution_time ON query_metrics(execution_time_ms);
CREATE INDEX idx_query_metrics_satisfaction ON query_metrics(user_satisfaction_score);
```

#### View para Dashboard de Performance
```sql
CREATE VIEW query_performance_dashboard AS
SELECT 
    query_type,
    COUNT(*) as total_queries,
    AVG(execution_time_ms) as avg_execution_time_ms,
    PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY execution_time_ms) as p95_execution_time_ms,
    AVG(result_count) as avg_result_count,
    AVG(user_satisfaction_score) as avg_satisfaction_score,
    COUNT(*) FILTER (WHERE execution_time_ms > 1000) as slow_queries_count,
    DATE_TRUNC('hour', timestamp) as time_bucket
FROM query_metrics
WHERE timestamp >= NOW() - INTERVAL '24 hours'
GROUP BY query_type, DATE_TRUNC('hour', timestamp)
ORDER BY time_bucket DESC, query_type;
```

## Considerações de Performance e Escalabilidade

### Estratégias de Particionamento

Para lidar com o crescimento futuro dos dados, implementamos estratégias de particionamento:

#### Particionamento por Data para Auditoria
```sql
-- Criar tabela particionada para logs de auditoria
CREATE TABLE audit_log_partitioned (
    LIKE audit_log INCLUDING ALL
) PARTITION BY RANGE (timestamp);

-- Criar partições mensais
CREATE TABLE audit_log_2025_09 PARTITION OF audit_log_partitioned
    FOR VALUES FROM ('2025-09-01') TO ('2025-10-01');

CREATE TABLE audit_log_2025_10 PARTITION OF audit_log_partitioned
    FOR VALUES FROM ('2025-10-01') TO ('2025-11-01');

-- Função para criar partições automaticamente
CREATE OR REPLACE FUNCTION create_monthly_partition(table_name TEXT, start_date DATE)
RETURNS VOID AS $$
DECLARE
    partition_name TEXT;
    end_date DATE;
BEGIN
    partition_name := table_name || '_' || to_char(start_date, 'YYYY_MM');
    end_date := start_date + INTERVAL '1 month';
    
    EXECUTE format('CREATE TABLE IF NOT EXISTS %I PARTITION OF %I FOR VALUES FROM (%L) TO (%L)',
                   partition_name, table_name, start_date, end_date);
END;
$$ LANGUAGE plpgsql;
```

### Otimização de Consultas Complexas

#### Função de Análise de Performance
```sql
CREATE OR REPLACE FUNCTION analyze_query_performance(
    query_text TEXT,
    execute_query BOOLEAN DEFAULT false
)
RETURNS TABLE (
    execution_plan TEXT,
    estimated_cost NUMERIC,
    estimated_rows BIGINT,
    actual_time_ms NUMERIC
) AS $$
DECLARE
    plan_result TEXT;
    timing_start TIMESTAMP;
    timing_end TIMESTAMP;
BEGIN
    -- Obter plano de execução
    EXECUTE 'EXPLAIN (FORMAT JSON, ANALYZE ' || 
            CASE WHEN execute_query THEN 'true' ELSE 'false' END || 
            ') ' || query_text INTO plan_result;
    
    -- Extrair métricas do plano
    RETURN QUERY
    SELECT 
        plan_result,
        (plan_result::jsonb -> 0 -> 'Plan' ->> 'Total Cost')::NUMERIC,
        (plan_result::jsonb -> 0 -> 'Plan' ->> 'Plan Rows')::BIGINT,
        CASE WHEN execute_query THEN
            (plan_result::jsonb -> 0 -> 'Plan' ->> 'Actual Total Time')::NUMERIC
        ELSE NULL END;
END;
$$ LANGUAGE plpgsql;
```

### Backup e Recuperação

#### Estratégia de Backup Incremental
```sql
-- Tabela para controle de backups
CREATE TABLE backup_control (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    backup_type VARCHAR(50) NOT NULL, -- 'full', 'incremental', 'differential'
    table_name VARCHAR(100),
    last_backup_timestamp TIMESTAMP WITH TIME ZONE,
    backup_size_bytes BIGINT,
    backup_location TEXT,
    checksum VARCHAR(64),
    status VARCHAR(20) DEFAULT 'completed',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Função para identificar dados modificados desde último backup
CREATE OR REPLACE FUNCTION get_modified_records_since(
    table_name TEXT,
    since_timestamp TIMESTAMP WITH TIME ZONE
)
RETURNS SETOF RECORD AS $$
BEGIN
    RETURN QUERY EXECUTE format(
        'SELECT * FROM %I WHERE updated_at > %L ORDER BY updated_at',
        table_name, since_timestamp
    );
END;
$$ LANGUAGE plpgsql;
```

## Conclusão da Arquitetura

A arquitetura de banco de dados proposta oferece uma base sólida e escalável para o sistema de busca inteligente da STIHL. Os principais benefícios incluem:

**Flexibilidade:** A estrutura modular permite fácil adição de novas categorias de produtos e especificações técnicas sem impacto nas funcionalidades existentes.

**Performance:** Os índices estratégicos, views materializadas e sistema de cache garantem tempos de resposta rápidos mesmo com grandes volumes de dados.

**Segurança:** As políticas RLS e sistema de auditoria proporcionam controle granular de acesso e rastreabilidade completa das operações.

**Escalabilidade:** As estratégias de particionamento e otimização de consultas preparam o sistema para crescimento futuro significativo.

**Integração com IA:** As funções especializadas e suporte a busca vetorial facilitam a implementação de recursos avançados de inteligência artificial.

Esta arquitetura serve como fundação para as próximas fases do projeto, incluindo a criação dos scripts SQL de implementação e o desenvolvimento da IA de busca autônoma.

