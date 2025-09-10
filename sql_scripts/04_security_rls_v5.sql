-- =====================================================
-- Configuração de Segurança e RLS para Sistema STIHL AI v5
-- =====================================================
-- Este script configura Row Level Security (RLS), políticas de acesso,
-- auditoria e outras configurações de segurança para o banco de dados
-- STIHL AI v5
-- 
-- Pré-requisitos:
-- 1. Tabelas criadas (01_create_tables_v5.sql)
-- 2. Dados importados (05_import_csv_data_v5.sql)
-- 3. Funções criadas (02_create_functions_v5.sql)
-- =====================================================

-- Configurações
SET search_path TO public;

-- =====================================================
-- SEÇÃO 1: CRIAÇÃO DE ROLES E USUÁRIOS
-- =====================================================

-- Criar roles para diferentes tipos de usuário
DO $$
BEGIN
    -- Role para usuários de consulta (apenas leitura)
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'stihl_reader') THEN
        CREATE ROLE stihl_reader;
    END IF;
    
    -- Role para usuários de aplicação (leitura e escrita limitada)
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'stihl_app_user') THEN
        CREATE ROLE stihl_app_user;
    END IF;
    
    -- Role para administradores (acesso completo)
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'stihl_admin') THEN
        CREATE ROLE stihl_admin;
    END IF;
    
    -- Role para API de busca (acesso otimizado para consultas)
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'stihl_api') THEN
        CREATE ROLE stihl_api;
    END IF;
END
$$;

-- =====================================================
-- SEÇÃO 2: CONFIGURAÇÃO DE PERMISSÕES BÁSICAS
-- =====================================================

-- Permissões para role de leitura (stihl_reader)
GRANT USAGE ON SCHEMA public TO stihl_reader;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO stihl_reader;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO stihl_reader;

-- Permissões para role de aplicação (stihl_app_user)
GRANT USAGE ON SCHEMA public TO stihl_app_user;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO stihl_app_user;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO stihl_app_user;

-- Permissões para role de API (stihl_api)
GRANT USAGE ON SCHEMA public TO stihl_api;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO stihl_api;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO stihl_api;

-- Permissões para role de administrador (stihl_admin)
GRANT ALL PRIVILEGES ON SCHEMA public TO stihl_admin;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO stihl_admin;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO stihl_admin;
GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA public TO stihl_admin;

-- =====================================================
-- SEÇÃO 3: CRIAÇÃO DE TABELA DE AUDITORIA
-- =====================================================

-- Tabela para logs de auditoria
CREATE TABLE IF NOT EXISTS audit_log_v5 (
    id SERIAL PRIMARY KEY,
    table_name VARCHAR(64) NOT NULL,
    operation VARCHAR(16) NOT NULL,
    user_name VARCHAR(64) NOT NULL,
    user_role VARCHAR(64),
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    old_values JSONB,
    new_values JSONB,
    query TEXT,
    ip_address INET,
    user_agent TEXT,
    session_id VARCHAR(128),
    details TEXT
);

-- Índices para performance da auditoria
CREATE INDEX IF NOT EXISTS idx_audit_log_v5_timestamp ON audit_log_v5(timestamp);
CREATE INDEX IF NOT EXISTS idx_audit_log_v5_table_operation ON audit_log_v5(table_name, operation);
CREATE INDEX IF NOT EXISTS idx_audit_log_v5_user ON audit_log_v5(user_name);

-- =====================================================
-- SEÇÃO 4: CRIAÇÃO DE TABELA DE SESSÕES DE USUÁRIO
-- =====================================================

-- Tabela para controle de sessões
CREATE TABLE IF NOT EXISTS user_sessions_v5 (
    session_id VARCHAR(128) PRIMARY KEY,
    user_name VARCHAR(64) NOT NULL,
    user_role VARCHAR(64) NOT NULL,
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_activity TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    expires_at TIMESTAMP WITH TIME ZONE,
    is_active BOOLEAN DEFAULT TRUE,
    region VARCHAR(32),
    permissions JSONB
);

-- Índices para performance de sessões
CREATE INDEX IF NOT EXISTS idx_user_sessions_v5_user ON user_sessions_v5(user_name);
CREATE INDEX IF NOT EXISTS idx_user_sessions_v5_active ON user_sessions_v5(is_active, expires_at);
CREATE INDEX IF NOT EXISTS idx_user_sessions_v5_region ON user_sessions_v5(region);

-- =====================================================
-- SEÇÃO 5: CONFIGURAÇÃO DE ROW LEVEL SECURITY (RLS)
-- =====================================================

-- Habilitar RLS nas tabelas principais
ALTER TABLE ms ENABLE ROW LEVEL SECURITY;
ALTER TABLE rocadeiras_e_impl ENABLE ROW LEVEL SECURITY;
ALTER TABLE produtos_a_bateria ENABLE ROW LEVEL SECURITY;
ALTER TABLE pecas ENABLE ROW LEVEL SECURITY;
ALTER TABLE acessorios ENABLE ROW LEVEL SECURITY;
ALTER TABLE sabres_correntes_pinhoes_limas ENABLE ROW LEVEL SECURITY;
ALTER TABLE ferramentas ENABLE ROW LEVEL SECURITY;
ALTER TABLE epis ENABLE ROW LEVEL SECURITY;
ALTER TABLE campanhas_stihl ENABLE ROW LEVEL SECURITY;
ALTER TABLE lancamentos ENABLE ROW LEVEL SECURITY;
ALTER TABLE outras_maquinas ENABLE ROW LEVEL SECURITY;
ALTER TABLE artigos_da_marca ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- SEÇÃO 6: POLÍTICAS RLS PARA LEITURA
-- =====================================================

-- Política de leitura para usuários autenticados (todas as tabelas principais)
CREATE POLICY IF NOT EXISTS "stihl_read_policy_ms" ON ms
    FOR SELECT
    TO stihl_reader, stihl_app_user, stihl_api, stihl_admin
    USING (true);

CREATE POLICY IF NOT EXISTS "stihl_read_policy_rocadeiras" ON rocadeiras_e_impl
    FOR SELECT
    TO stihl_reader, stihl_app_user, stihl_api, stihl_admin
    USING (true);

CREATE POLICY IF NOT EXISTS "stihl_read_policy_produtos_bateria" ON produtos_a_bateria
    FOR SELECT
    TO stihl_reader, stihl_app_user, stihl_api, stihl_admin
    USING (true);

CREATE POLICY IF NOT EXISTS "stihl_read_policy_pecas" ON pecas
    FOR SELECT
    TO stihl_reader, stihl_app_user, stihl_api, stihl_admin
    USING (true);

CREATE POLICY IF NOT EXISTS "stihl_read_policy_acessorios" ON acessorios
    FOR SELECT
    TO stihl_reader, stihl_app_user, stihl_api, stihl_admin
    USING (true);

CREATE POLICY IF NOT EXISTS "stihl_read_policy_sabres_correntes" ON sabres_correntes_pinhoes_limas
    FOR SELECT
    TO stihl_reader, stihl_app_user, stihl_api, stihl_admin
    USING (true);

CREATE POLICY IF NOT EXISTS "stihl_read_policy_ferramentas" ON ferramentas
    FOR SELECT
    TO stihl_reader, stihl_app_user, stihl_api, stihl_admin
    USING (true);

CREATE POLICY IF NOT EXISTS "stihl_read_policy_epis" ON epis
    FOR SELECT
    TO stihl_reader, stihl_app_user, stihl_api, stihl_admin
    USING (true);

CREATE POLICY IF NOT EXISTS "stihl_read_policy_campanhas" ON campanhas_stihl
    FOR SELECT
    TO stihl_reader, stihl_app_user, stihl_api, stihl_admin
    USING (true);

CREATE POLICY IF NOT EXISTS "stihl_read_policy_lancamentos" ON lancamentos
    FOR SELECT
    TO stihl_reader, stihl_app_user, stihl_api, stihl_admin
    USING (true);

CREATE POLICY IF NOT EXISTS "stihl_read_policy_outras_maquinas" ON outras_maquinas
    FOR SELECT
    TO stihl_reader, stihl_app_user, stihl_api, stihl_admin
    USING (true);

CREATE POLICY IF NOT EXISTS "stihl_read_policy_artigos_marca" ON artigos_da_marca
    FOR SELECT
    TO stihl_reader, stihl_app_user, stihl_api, stihl_admin
    USING (true);

-- =====================================================
-- SEÇÃO 7: POLÍTICAS RLS PARA ESCRITA (APENAS ADMIN)
-- =====================================================

-- Políticas de escrita apenas para administradores
CREATE POLICY IF NOT EXISTS "stihl_write_policy_admin" ON ms
    FOR ALL
    TO stihl_admin
    USING (true)
    WITH CHECK (true);

CREATE POLICY IF NOT EXISTS "stihl_write_policy_admin_rocadeiras" ON rocadeiras_e_impl
    FOR ALL
    TO stihl_admin
    USING (true)
    WITH CHECK (true);

CREATE POLICY IF NOT EXISTS "stihl_write_policy_admin_produtos_bateria" ON produtos_a_bateria
    FOR ALL
    TO stihl_admin
    USING (true)
    WITH CHECK (true);

CREATE POLICY IF NOT EXISTS "stihl_write_policy_admin_pecas" ON pecas
    FOR ALL
    TO stihl_admin
    USING (true)
    WITH CHECK (true);

CREATE POLICY IF NOT EXISTS "stihl_write_policy_admin_acessorios" ON acessorios
    FOR ALL
    TO stihl_admin
    USING (true)
    WITH CHECK (true);

CREATE POLICY IF NOT EXISTS "stihl_write_policy_admin_sabres_correntes" ON sabres_correntes_pinhoes_limas
    FOR ALL
    TO stihl_admin
    USING (true)
    WITH CHECK (true);

CREATE POLICY IF NOT EXISTS "stihl_write_policy_admin_ferramentas" ON ferramentas
    FOR ALL
    TO stihl_admin
    USING (true)
    WITH CHECK (true);

CREATE POLICY IF NOT EXISTS "stihl_write_policy_admin_epis" ON epis
    FOR ALL
    TO stihl_admin
    USING (true)
    WITH CHECK (true);

-- =====================================================
-- SEÇÃO 8: FUNÇÕES DE AUDITORIA
-- =====================================================

-- Função para registrar atividade de usuário
CREATE OR REPLACE FUNCTION log_user_activity_v5(
    p_table_name VARCHAR(64),
    p_operation VARCHAR(16),
    p_details TEXT DEFAULT NULL
)
RETURNS VOID AS $$
BEGIN
    INSERT INTO audit_log_v5 (
        table_name,
        operation,
        user_name,
        user_role,
        details,
        ip_address
    ) VALUES (
        p_table_name,
        p_operation,
        current_user,
        (SELECT current_setting('role', true)),
        p_details,
        inet_client_addr()
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Função para validar sessão de usuário
CREATE OR REPLACE FUNCTION validate_user_session_v5(p_session_id VARCHAR(128))
RETURNS BOOLEAN AS $$
DECLARE
    session_valid BOOLEAN := FALSE;
BEGIN
    -- Verificar se a sessão existe e está ativa
    SELECT 
        CASE 
            WHEN is_active = TRUE 
                AND expires_at > NOW() 
            THEN TRUE 
            ELSE FALSE 
        END INTO session_valid
    FROM user_sessions_v5
    WHERE session_id = p_session_id;
    
    -- Atualizar última atividade se sessão válida
    IF session_valid THEN
        UPDATE user_sessions_v5 
        SET last_activity = NOW()
        WHERE session_id = p_session_id;
    END IF;
    
    RETURN COALESCE(session_valid, FALSE);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Função para criar sessão de usuário
CREATE OR REPLACE FUNCTION create_user_session_v5(
    p_session_id VARCHAR(128),
    p_user_name VARCHAR(64),
    p_user_role VARCHAR(64),
    p_region VARCHAR(32) DEFAULT 'BR',
    p_expires_hours INTEGER DEFAULT 24
)
RETURNS BOOLEAN AS $$
BEGIN
    INSERT INTO user_sessions_v5 (
        session_id,
        user_name,
        user_role,
        ip_address,
        expires_at,
        region
    ) VALUES (
        p_session_id,
        p_user_name,
        p_user_role,
        inet_client_addr(),
        NOW() + (p_expires_hours || ' hours')::INTERVAL,
        p_region
    );
    
    -- Log da criação de sessão
    PERFORM log_user_activity_v5('user_sessions_v5', 'CREATE_SESSION', 
        'Sessão criada para usuário: ' || p_user_name);
    
    RETURN TRUE;
EXCEPTION
    WHEN OTHERS THEN
        RETURN FALSE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- SEÇÃO 9: TRIGGERS DE AUDITORIA
-- =====================================================

-- Função de trigger para auditoria automática
CREATE OR REPLACE FUNCTION audit_trigger_v5()
RETURNS TRIGGER AS $$
BEGIN
    -- Log para operações de INSERT
    IF TG_OP = 'INSERT' THEN
        PERFORM log_user_activity_v5(
            TG_TABLE_NAME,
            'INSERT',
            'Novo registro inserido'
        );
        RETURN NEW;
    END IF;
    
    -- Log para operações de UPDATE
    IF TG_OP = 'UPDATE' THEN
        PERFORM log_user_activity_v5(
            TG_TABLE_NAME,
            'UPDATE',
            'Registro atualizado'
        );
        RETURN NEW;
    END IF;
    
    -- Log para operações de DELETE
    IF TG_OP = 'DELETE' THEN
        PERFORM log_user_activity_v5(
            TG_TABLE_NAME,
            'DELETE',
            'Registro removido'
        );
        RETURN OLD;
    END IF;
    
    RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Aplicar triggers de auditoria nas tabelas principais
DROP TRIGGER IF EXISTS audit_trigger_ms ON ms;
CREATE TRIGGER audit_trigger_ms
    AFTER INSERT OR UPDATE OR DELETE ON ms
    FOR EACH ROW EXECUTE FUNCTION audit_trigger_v5();

DROP TRIGGER IF EXISTS audit_trigger_rocadeiras ON rocadeiras_e_impl;
CREATE TRIGGER audit_trigger_rocadeiras
    AFTER INSERT OR UPDATE OR DELETE ON rocadeiras_e_impl
    FOR EACH ROW EXECUTE FUNCTION audit_trigger_v5();

DROP TRIGGER IF EXISTS audit_trigger_produtos_bateria ON produtos_a_bateria;
CREATE TRIGGER audit_trigger_produtos_bateria
    AFTER INSERT OR UPDATE OR DELETE ON produtos_a_bateria
    FOR EACH ROW EXECUTE FUNCTION audit_trigger_v5();

-- =====================================================
-- SEÇÃO 10: CONFIGURAÇÕES DE CACHE E PERFORMANCE
-- =====================================================

-- Tabela para cache de consultas frequentes
CREATE TABLE IF NOT EXISTS query_cache_v5 (
    cache_key VARCHAR(256) PRIMARY KEY,
    query_result JSONB NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    hit_count INTEGER DEFAULT 0,
    last_accessed TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Índices para cache
CREATE INDEX IF NOT EXISTS idx_query_cache_v5_expires ON query_cache_v5(expires_at);
CREATE INDEX IF NOT EXISTS idx_query_cache_v5_hit_count ON query_cache_v5(hit_count DESC);

-- Função para limpar cache expirado
CREATE OR REPLACE FUNCTION cleanup_expired_cache_v5()
RETURNS INTEGER AS $$
DECLARE
    deleted_count INTEGER;
BEGIN
    DELETE FROM query_cache_v5 WHERE expires_at < NOW();
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    
    PERFORM log_user_activity_v5('query_cache_v5', 'CLEANUP', 
        'Cache expirado limpo: ' || deleted_count || ' registros removidos');
    
    RETURN deleted_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Função para obter/definir cache
CREATE OR REPLACE FUNCTION get_cached_result_v5(p_cache_key VARCHAR(256))
RETURNS JSONB AS $$
DECLARE
    result JSONB;
BEGIN
    SELECT query_result INTO result
    FROM query_cache_v5
    WHERE cache_key = p_cache_key
        AND expires_at > NOW();
    
    -- Atualizar estatísticas de acesso
    IF FOUND THEN
        UPDATE query_cache_v5 
        SET hit_count = hit_count + 1,
            last_accessed = NOW()
        WHERE cache_key = p_cache_key;
    END IF;
    
    RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION set_cached_result_v5(
    p_cache_key VARCHAR(256),
    p_result JSONB,
    p_ttl_minutes INTEGER DEFAULT 60
)
RETURNS VOID AS $$
BEGIN
    INSERT INTO query_cache_v5 (cache_key, query_result, expires_at)
    VALUES (p_cache_key, p_result, NOW() + (p_ttl_minutes || ' minutes')::INTERVAL)
    ON CONFLICT (cache_key) 
    DO UPDATE SET 
        query_result = EXCLUDED.query_result,
        expires_at = EXCLUDED.expires_at,
        created_at = NOW();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- SEÇÃO 11: CONFIGURAÇÕES DE MONITORAMENTO
-- =====================================================

-- Tabela para métricas de performance
CREATE TABLE IF NOT EXISTS performance_metrics_v5 (
    id SERIAL PRIMARY KEY,
    metric_name VARCHAR(64) NOT NULL,
    metric_value DECIMAL(12,4) NOT NULL,
    metric_unit VARCHAR(16),
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    details JSONB
);

-- Índices para métricas
CREATE INDEX IF NOT EXISTS idx_performance_metrics_v5_name_time ON performance_metrics_v5(metric_name, timestamp);

-- Função para registrar métrica de performance
CREATE OR REPLACE FUNCTION record_performance_metric_v5(
    p_metric_name VARCHAR(64),
    p_metric_value DECIMAL(12,4),
    p_metric_unit VARCHAR(16) DEFAULT 'ms',
    p_details JSONB DEFAULT NULL
)
RETURNS VOID AS $$
BEGIN
    INSERT INTO performance_metrics_v5 (metric_name, metric_value, metric_unit, details)
    VALUES (p_metric_name, p_metric_value, p_metric_unit, p_details);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- SEÇÃO 12: CONFIGURAÇÕES FINAIS E LIMPEZA
-- =====================================================

-- Função para limpeza automática de logs antigos
CREATE OR REPLACE FUNCTION cleanup_old_logs_v5(days_to_keep INTEGER DEFAULT 90)
RETURNS INTEGER AS $$
DECLARE
    deleted_count INTEGER;
BEGIN
    -- Limpar logs de auditoria antigos
    DELETE FROM audit_log_v5 
    WHERE timestamp < NOW() - (days_to_keep || ' days')::INTERVAL;
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    
    -- Limpar métricas antigas
    DELETE FROM performance_metrics_v5 
    WHERE timestamp < NOW() - (days_to_keep || ' days')::INTERVAL;
    
    -- Limpar sessões expiradas
    DELETE FROM user_sessions_v5 
    WHERE expires_at < NOW() OR last_activity < NOW() - '7 days'::INTERVAL;
    
    RETURN deleted_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Configurar permissões para funções de segurança
GRANT EXECUTE ON FUNCTION log_user_activity_v5(VARCHAR, VARCHAR, TEXT) TO stihl_app_user, stihl_api, stihl_admin;
GRANT EXECUTE ON FUNCTION validate_user_session_v5(VARCHAR) TO stihl_app_user, stihl_api, stihl_admin;
GRANT EXECUTE ON FUNCTION create_user_session_v5(VARCHAR, VARCHAR, VARCHAR, VARCHAR, INTEGER) TO stihl_app_user, stihl_api, stihl_admin;
GRANT EXECUTE ON FUNCTION get_cached_result_v5(VARCHAR) TO stihl_app_user, stihl_api, stihl_admin;
GRANT EXECUTE ON FUNCTION set_cached_result_v5(VARCHAR, JSONB, INTEGER) TO stihl_app_user, stihl_api, stihl_admin;
GRANT EXECUTE ON FUNCTION record_performance_metric_v5(VARCHAR, DECIMAL, VARCHAR, JSONB) TO stihl_app_user, stihl_api, stihl_admin;

-- Configurar permissões para tabelas de sistema
GRANT SELECT, INSERT ON audit_log_v5 TO stihl_app_user, stihl_api, stihl_admin;
GRANT SELECT, INSERT, UPDATE ON user_sessions_v5 TO stihl_app_user, stihl_api, stihl_admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON query_cache_v5 TO stihl_app_user, stihl_api, stihl_admin;
GRANT SELECT, INSERT ON performance_metrics_v5 TO stihl_app_user, stihl_api, stihl_admin;

-- Comentários para documentação
COMMENT ON TABLE audit_log_v5 IS 'Log de auditoria para todas as operações no sistema STIHL AI v5';
COMMENT ON TABLE user_sessions_v5 IS 'Controle de sessões de usuário com validação e expiração';
COMMENT ON TABLE query_cache_v5 IS 'Cache de consultas frequentes para otimização de performance';
COMMENT ON TABLE performance_metrics_v5 IS 'Métricas de performance e monitoramento do sistema';

-- Log de conclusão
SELECT 'Configuração de segurança e RLS para STIHL AI v5 concluída com sucesso!' as status;

