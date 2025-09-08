-- =====================================================
-- FUNÇÕES SQL ESPECIALIZADAS PARA IA
-- Sistema de Busca Inteligente STIHL
-- =====================================================

-- =====================================================
-- FUNÇÃO: intelligent_product_search
-- Busca inteligente de produtos com múltiplos filtros
-- =====================================================
CREATE OR REPLACE FUNCTION intelligent_product_search(
    search_query TEXT DEFAULT NULL,
    category_filter TEXT DEFAULT NULL,
    price_range_min DECIMAL DEFAULT NULL,
    price_range_max DECIMAL DEFAULT NULL,
    include_specifications BOOLEAN DEFAULT true,
    include_relationships BOOLEAN DEFAULT false,
    max_results INTEGER DEFAULT 50
)
RETURNS JSONB AS $$
DECLARE
    result JSONB;
BEGIN
    -- Construir consulta base com busca textual e filtros
    WITH search_results AS (
        SELECT 
            p.id,
            p.material_code,
            p.name,
            p.description,
            p.model,
            p.search_keywords,
            c.name as category_name,
            c.slug as category_slug,
            pr.price_value,
            pr.currency,
            pr.minimum_quantity,
            -- Calcular relevância da busca textual
            CASE 
                WHEN search_query IS NOT NULL THEN
                    ts_rank_cd(
                        to_tsvector('portuguese', 
                            p.name || ' ' || 
                            COALESCE(p.description, '') || ' ' || 
                            COALESCE(p.search_keywords, '') || ' ' ||
                            COALESCE(p.model, '')
                        ), 
                        plainto_tsquery('portuguese', search_query)
                    )
                ELSE 1.0
            END as text_relevance_score
        FROM products p
        LEFT JOIN categories c ON p.category_id = c.id
        LEFT JOIN pricing pr ON p.id = pr.product_id 
            AND pr.is_active = true 
            AND pr.price_type = 'suggested_retail'
        WHERE p.status = 'active'
        AND (category_filter IS NULL OR 
             c.slug = category_filter OR 
             c.name ILIKE '%' || category_filter || '%')
        AND (price_range_min IS NULL OR pr.price_value >= price_range_min)
        AND (price_range_max IS NULL OR pr.price_value <= price_range_max)
        AND (search_query IS NULL OR 
             to_tsvector('portuguese', 
                p.name || ' ' || 
                COALESCE(p.description, '') || ' ' || 
                COALESCE(p.search_keywords, '') || ' ' ||
                COALESCE(p.model, '')
             ) @@ plainto_tsquery('portuguese', search_query))
        ORDER BY text_relevance_score DESC, p.name
        LIMIT max_results
    ),
    enriched_results AS (
        SELECT 
            sr.*,
            -- Incluir especificações técnicas se solicitado
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
                    'chain_pitch', ts.chain_pitch,
                    'chain_thickness_mm', ts.chain_thickness_mm,
                    'additional_specs', ts.additional_specs
                )
            ELSE NULL END as specifications,
            -- Incluir relacionamentos se solicitado
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
            'price_max', price_range_max,
            'include_specifications', include_specifications,
            'include_relationships', include_relationships
        ),
        'products', jsonb_agg(
            jsonb_build_object(
                'id', id,
                'material_code', material_code,
                'name', name,
                'description', description,
                'model', model,
                'category', jsonb_build_object(
                    'name', category_name,
                    'slug', category_slug
                ),
                'price', jsonb_build_object(
                    'value', price_value,
                    'currency', currency,
                    'minimum_quantity', minimum_quantity
                ),
                'relevance_score', text_relevance_score,
                'specifications', specifications,
                'relationships', relationships
            )
            ORDER BY text_relevance_score DESC
        )
    ) INTO result
    FROM enriched_results;
    
    RETURN COALESCE(result, '{"total_results": 0, "products": []}'::jsonb);
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- FUNÇÃO: get_product_recommendations
-- Recomendações inteligentes baseadas em relacionamentos
-- =====================================================
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
    SELECT 
        p.id,
        p.name, 
        p.material_code, 
        p.model,
        c.name as category_name, 
        ts.power_kw, 
        ts.displacement_cc,
        ts.weight_kg
    INTO base_product_info
    FROM products p
    LEFT JOIN categories c ON p.category_id = c.id
    LEFT JOIN technical_specifications ts ON p.id = ts.product_id
    WHERE p.id = base_product_id AND p.status = 'active';
    
    -- Se produto não encontrado, retornar erro
    IF base_product_info.id IS NULL THEN
        RETURN jsonb_build_object(
            'error', 'Produto não encontrado',
            'base_product_id', base_product_id
        );
    END IF;
    
    -- Gerar recomendações baseadas em relacionamentos diretos e similaridade
    WITH direct_relationships AS (
        SELECT 
            p.id,
            p.material_code,
            p.name,
            p.description,
            p.model,
            c.name as category_name,
            pr_rel.relationship_type,
            pr_rel.compatibility_notes,
            1.0 as relevance_score,
            'direct_relationship' as recommendation_source,
            pr.price_value
        FROM product_relationships pr_rel
        JOIN products p ON pr_rel.related_product_id = p.id
        LEFT JOIN categories c ON p.category_id = c.id
        LEFT JOIN pricing pr ON p.id = pr.product_id 
            AND pr.is_active = true 
            AND pr.price_type = 'suggested_retail'
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
            p.model,
            c.name as category_name,
            'similar_specifications' as relationship_type,
            'Produto com especificações similares' as compatibility_notes,
            -- Calcular similaridade baseada em especificações técnicas
            CASE 
                WHEN base_product_info.power_kw IS NOT NULL AND ts.power_kw IS NOT NULL THEN
                    GREATEST(0.1, 1.0 - ABS(base_product_info.power_kw - ts.power_kw) / 
                        GREATEST(base_product_info.power_kw, ts.power_kw))
                WHEN base_product_info.displacement_cc IS NOT NULL AND ts.displacement_cc IS NOT NULL THEN
                    GREATEST(0.1, 1.0 - ABS(base_product_info.displacement_cc - ts.displacement_cc) / 
                        GREATEST(base_product_info.displacement_cc, ts.displacement_cc))
                ELSE 0.5
            END as relevance_score,
            'similar_specifications' as recommendation_source,
            pr.price_value
        FROM products p
        LEFT JOIN categories c ON p.category_id = c.id
        LEFT JOIN technical_specifications ts ON p.id = ts.product_id
        LEFT JOIN pricing pr ON p.id = pr.product_id 
            AND pr.is_active = true 
            AND pr.price_type = 'suggested_retail'
        WHERE p.id != base_product_id
        AND p.status = 'active'
        AND c.name = base_product_info.category_name
        AND (ts.power_kw IS NOT NULL OR ts.displacement_cc IS NOT NULL)
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
            'id', base_product_info.id,
            'name', base_product_info.name,
            'material_code', base_product_info.material_code,
            'model', base_product_info.model,
            'category', base_product_info.category_name
        ),
        'total_recommendations', count(*),
        'recommendations', jsonb_agg(
            jsonb_build_object(
                'id', id,
                'material_code', material_code,
                'name', name,
                'description', description,
                'model', model,
                'category', category_name,
                'relationship_type', relationship_type,
                'compatibility_notes', compatibility_notes,
                'relevance_score', relevance_score,
                'recommendation_source', recommendation_source,
                'price', price_value
            )
            ORDER BY relevance_score DESC
        )
    ) INTO result
    FROM combined_recommendations
    LIMIT max_recommendations;
    
    RETURN COALESCE(result, jsonb_build_object(
        'base_product', jsonb_build_object(
            'id', base_product_info.id,
            'name', base_product_info.name,
            'material_code', base_product_info.material_code
        ),
        'total_recommendations', 0,
        'recommendations', '[]'::jsonb
    ));
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- FUNÇÃO: get_product_by_code
-- Busca produto por código de material
-- =====================================================
CREATE OR REPLACE FUNCTION get_product_by_code(
    material_code_param VARCHAR(50),
    include_full_details BOOLEAN DEFAULT true
)
RETURNS JSONB AS $$
DECLARE
    result JSONB;
BEGIN
    WITH product_data AS (
        SELECT 
            p.id,
            p.material_code,
            p.name,
            p.description,
            p.brand,
            p.model,
            p.barcode,
            p.status,
            c.name as category_name,
            c.slug as category_slug,
            ts.displacement_cc,
            ts.power_kw,
            ts.power_hp,
            ts.weight_kg,
            ts.fuel_tank_capacity_l,
            ts.oil_tank_capacity_l,
            ts.bar_length_cm,
            ts.chain_model,
            ts.chain_pitch,
            ts.chain_thickness_mm,
            ts.additional_specs,
            pr.price_value,
            pr.currency,
            pr.minimum_quantity,
            ti.ncm_code,
            ti.ipi_rate,
            ti.tax_substitution_rs,
            ti.tax_substitution_sp,
            ti.tax_substitution_pa
        FROM products p
        LEFT JOIN categories c ON p.category_id = c.id
        LEFT JOIN technical_specifications ts ON p.id = ts.product_id
        LEFT JOIN pricing pr ON p.id = pr.product_id 
            AND pr.is_active = true 
            AND pr.price_type = 'suggested_retail'
        LEFT JOIN tax_information ti ON p.id = ti.product_id
        WHERE p.material_code = material_code_param
        AND p.status = 'active'
    )
    SELECT jsonb_build_object(
        'found', CASE WHEN count(*) > 0 THEN true ELSE false END,
        'product', CASE WHEN count(*) > 0 THEN
            jsonb_build_object(
                'id', id,
                'material_code', material_code,
                'name', name,
                'description', description,
                'brand', brand,
                'model', model,
                'barcode', barcode,
                'status', status,
                'category', jsonb_build_object(
                    'name', category_name,
                    'slug', category_slug
                ),
                'specifications', CASE WHEN include_full_details THEN
                    jsonb_build_object(
                        'displacement_cc', displacement_cc,
                        'power_kw', power_kw,
                        'power_hp', power_hp,
                        'weight_kg', weight_kg,
                        'fuel_tank_capacity_l', fuel_tank_capacity_l,
                        'oil_tank_capacity_l', oil_tank_capacity_l,
                        'bar_length_cm', bar_length_cm,
                        'chain_model', chain_model,
                        'chain_pitch', chain_pitch,
                        'chain_thickness_mm', chain_thickness_mm,
                        'additional_specs', additional_specs
                    )
                ELSE NULL END,
                'pricing', jsonb_build_object(
                    'price_value', price_value,
                    'currency', currency,
                    'minimum_quantity', minimum_quantity
                ),
                'tax_info', CASE WHEN include_full_details THEN
                    jsonb_build_object(
                        'ncm_code', ncm_code,
                        'ipi_rate', ipi_rate,
                        'tax_substitution_rs', tax_substitution_rs,
                        'tax_substitution_sp', tax_substitution_sp,
                        'tax_substitution_pa', tax_substitution_pa
                    )
                ELSE NULL END
            )
        ELSE NULL END
    ) INTO result
    FROM product_data;
    
    RETURN COALESCE(result, '{"found": false, "product": null}'::jsonb);
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- FUNÇÃO: get_categories_hierarchy
-- Retorna hierarquia completa de categorias
-- =====================================================
CREATE OR REPLACE FUNCTION get_categories_hierarchy()
RETURNS JSONB AS $$
DECLARE
    result JSONB;
BEGIN
    WITH RECURSIVE category_tree AS (
        -- Categorias raiz (nível 0)
        SELECT 
            id,
            name,
            slug,
            parent_id,
            level,
            sort_order,
            description,
            is_active,
            ARRAY[name] as path,
            jsonb_build_object(
                'id', id,
                'name', name,
                'slug', slug,
                'level', level,
                'sort_order', sort_order,
                'description', description,
                'is_active', is_active,
                'children', '[]'::jsonb
            ) as category_json
        FROM categories 
        WHERE parent_id IS NULL AND is_active = true
        
        UNION ALL
        
        -- Categorias filhas (recursivo)
        SELECT 
            c.id,
            c.name,
            c.slug,
            c.parent_id,
            c.level,
            c.sort_order,
            c.description,
            c.is_active,
            ct.path || c.name,
            jsonb_build_object(
                'id', c.id,
                'name', c.name,
                'slug', c.slug,
                'level', c.level,
                'sort_order', c.sort_order,
                'description', c.description,
                'is_active', c.is_active,
                'children', '[]'::jsonb
            )
        FROM categories c
        INNER JOIN category_tree ct ON c.parent_id = ct.id
        WHERE c.is_active = true
    )
    SELECT jsonb_build_object(
        'total_categories', count(*),
        'hierarchy', jsonb_agg(category_json ORDER BY level, sort_order, name)
    ) INTO result
    FROM category_tree;
    
    RETURN COALESCE(result, '{"total_categories": 0, "hierarchy": []}'::jsonb);
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- FUNÇÃO: get_price_ranges_by_category
-- Retorna faixas de preço por categoria
-- =====================================================
CREATE OR REPLACE FUNCTION get_price_ranges_by_category(
    category_slug_param VARCHAR(100) DEFAULT NULL
)
RETURNS JSONB AS $$
DECLARE
    result JSONB;
BEGIN
    WITH price_stats AS (
        SELECT 
            c.name as category_name,
            c.slug as category_slug,
            count(DISTINCT p.id) as product_count,
            min(pr.price_value) as min_price,
            max(pr.price_value) as max_price,
            avg(pr.price_value) as avg_price,
            percentile_cont(0.25) WITHIN GROUP (ORDER BY pr.price_value) as q1_price,
            percentile_cont(0.5) WITHIN GROUP (ORDER BY pr.price_value) as median_price,
            percentile_cont(0.75) WITHIN GROUP (ORDER BY pr.price_value) as q3_price
        FROM products p
        JOIN categories c ON p.category_id = c.id
        JOIN pricing pr ON p.id = pr.product_id
        WHERE p.status = 'active'
        AND pr.is_active = true
        AND pr.price_type = 'suggested_retail'
        AND (category_slug_param IS NULL OR c.slug = category_slug_param)
        GROUP BY c.id, c.name, c.slug
    )
    SELECT jsonb_build_object(
        'category_filter', category_slug_param,
        'price_ranges', jsonb_agg(
            jsonb_build_object(
                'category_name', category_name,
                'category_slug', category_slug,
                'product_count', product_count,
                'price_statistics', jsonb_build_object(
                    'min_price', min_price,
                    'max_price', max_price,
                    'avg_price', round(avg_price, 2),
                    'median_price', round(median_price, 2),
                    'q1_price', round(q1_price, 2),
                    'q3_price', round(q3_price, 2)
                )
            )
            ORDER BY category_name
        )
    ) INTO result
    FROM price_stats;
    
    RETURN COALESCE(result, '{"category_filter": null, "price_ranges": []}'::jsonb);
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- COMENTÁRIOS DAS FUNÇÕES
-- =====================================================
COMMENT ON FUNCTION intelligent_product_search IS 'Busca inteligente de produtos com múltiplos filtros e relevância textual';
COMMENT ON FUNCTION get_product_recommendations IS 'Gera recomendações inteligentes baseadas em relacionamentos e similaridade';
COMMENT ON FUNCTION get_product_by_code IS 'Busca produto específico por código de material com detalhes completos';
COMMENT ON FUNCTION get_categories_hierarchy IS 'Retorna hierarquia completa de categorias em formato JSON';
COMMENT ON FUNCTION get_price_ranges_by_category IS 'Calcula estatísticas de preços por categoria para filtros inteligentes';

