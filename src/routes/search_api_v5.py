"""
API de Busca Inteligente STIHL AI v5
====================================

Este módulo implementa as rotas da API REST para o sistema de busca
inteligente STIHL AI v5, adaptado para a nova estrutura de banco de dados.

Endpoints disponíveis:
- POST /api/search/search - Busca inteligente principal
- GET /api/search/product/{code} - Busca por código de material
- GET /api/search/compatible/{model} - Busca produtos compatíveis
- GET /api/search/recommendations - Recomendações inteligentes
- GET /api/search/campaigns - Produtos em campanha
- GET /api/search/price-ranges - Faixas de preço por categoria
- GET /api/search/suggest - Sugestões de busca
- GET /api/search/analytics - Analytics de busca

Autor: Manus AI
Data: 2025-09-08
Versão: 5.0
"""

import os
import json
import time
from datetime import datetime
from typing import Dict, List, Optional, Any
from flask import Blueprint, request, jsonify, current_app
from flask_cors import cross_origin
import psycopg2
from psycopg2.extras import RealDictCursor

from ..models.intelligent_search_v5 import IntelligentSearchV5, SearchResult, SearchIntent

# Criar blueprint para as rotas de busca
search_bp = Blueprint('search_api_v5', __name__, url_prefix='/api/search')

# Instância global do sistema de busca (será inicializada no app)
search_engine: Optional[IntelligentSearchV5] = None

def init_search_engine(database_url: str):
    """Inicializa o motor de busca inteligente"""
    global search_engine
    search_engine = IntelligentSearchV5(database_url)

def log_search_analytics(query: str, results_count: int, response_time: float, user_ip: str = None):
    """
    Registra analytics de busca para análise posterior
    
    Args:
        query: Consulta realizada
        results_count: Número de resultados retornados
        response_time: Tempo de resposta em milissegundos
        user_ip: IP do usuário (opcional)
    """
    try:
        analytics_data = {
            'timestamp': datetime.now().isoformat(),
            'query': query,
            'results_count': results_count,
            'response_time_ms': response_time,
            'user_ip': user_ip,
            'user_agent': request.headers.get('User-Agent', '')
        }
        
        # Aqui você pode implementar o log em banco de dados ou arquivo
        # Por enquanto, apenas print para debug
        current_app.logger.info(f"Search Analytics: {json.dumps(analytics_data)}")
        
    except Exception as e:
        current_app.logger.error(f"Erro ao registrar analytics: {e}")

@search_bp.route('/search', methods=['POST'])
@cross_origin()
def intelligent_search():
    """
    Endpoint principal de busca inteligente
    
    Body JSON:
    {
        "query": "motosserra elétrica até R$ 1500",
        "max_results": 20,
        "include_details": true
    }
    
    Returns:
        JSON com resultados da busca
    """
    start_time = time.time()
    
    try:
        if not search_engine:
            return jsonify({
                'error': 'Sistema de busca não inicializado',
                'success': False
            }), 500
        
        # Validar dados de entrada
        data = request.get_json()
        if not data or 'query' not in data:
            return jsonify({
                'error': 'Campo "query" é obrigatório',
                'success': False
            }), 400
        
        query = data['query'].strip()
        if not query:
            return jsonify({
                'error': 'Query não pode estar vazia',
                'success': False
            }), 400
        
        max_results = data.get('max_results', 20)
        include_details = data.get('include_details', False)
        
        # Executar busca
        results = search_engine.search(query, max_results)
        
        # Preparar resposta
        response_data = {
            'success': True,
            'query': query,
            'total_results': len(results),
            'results': []
        }
        
        for result in results:
            result_data = {
                'source_table': result.source_table,
                'codigo_material': result.codigo_material,
                'descricao': result.descricao,
                'preco_real': result.preco_real,
                'categoria_produto': result.categoria_produto,
                'relevance_score': result.relevance_score
            }
            
            if include_details:
                result_data['modelos'] = result.modelos
                result_data['detalhes_tecnicos'] = result.detalhes_tecnicos
            
            response_data['results'].append(result_data)
        
        # Gerar resposta em linguagem natural se solicitado
        if data.get('natural_response', False):
            response_data['natural_response'] = search_engine.generate_natural_response(query, results)
        
        # Calcular tempo de resposta
        response_time = (time.time() - start_time) * 1000
        response_data['response_time_ms'] = round(response_time, 2)
        
        # Registrar analytics
        log_search_analytics(query, len(results), response_time, request.remote_addr)
        
        return jsonify(response_data)
        
    except Exception as e:
        current_app.logger.error(f"Erro na busca inteligente: {e}")
        return jsonify({
            'error': 'Erro interno do servidor',
            'success': False,
            'details': str(e) if current_app.debug else None
        }), 500

@search_bp.route('/product/<string:code>', methods=['GET'])
@cross_origin()
def get_product_by_code(code: str):
    """
    Busca produto específico por código de material
    
    Args:
        code: Código do material
        
    Returns:
        JSON com dados do produto
    """
    try:
        if not search_engine:
            return jsonify({
                'error': 'Sistema de busca não inicializado',
                'success': False
            }), 500
        
        # Executar busca por código
        result = search_engine.search_by_code(code)
        
        if not result:
            return jsonify({
                'success': False,
                'message': f'Produto com código {code} não encontrado'
            }), 404
        
        # Buscar produtos compatíveis
        compatible_products = search_engine.get_compatible_products(code)
        
        response_data = {
            'success': True,
            'product': {
                'source_table': result.source_table,
                'codigo_material': result.codigo_material,
                'descricao': result.descricao,
                'preco_real': result.preco_real,
                'categoria_produto': result.categoria_produto,
                'modelos': result.modelos,
                'detalhes_tecnicos': result.detalhes_tecnicos
            },
            'compatible_products': [
                {
                    'codigo_material': comp.codigo_material,
                    'descricao': comp.descricao,
                    'preco_real': comp.preco_real,
                    'categoria_produto': comp.categoria_produto,
                    'tipo_compatibilidade': comp.modelos
                }
                for comp in compatible_products[:10]  # Limitar a 10 produtos compatíveis
            ]
        }
        
        return jsonify(response_data)
        
    except Exception as e:
        current_app.logger.error(f"Erro na busca por código: {e}")
        return jsonify({
            'error': 'Erro interno do servidor',
            'success': False
        }), 500

@search_bp.route('/compatible/<string:model>', methods=['GET'])
@cross_origin()
def get_compatible_products(model: str):
    """
    Busca produtos compatíveis com um modelo específico
    
    Args:
        model: Nome do modelo (ex: MS 162, FS 220)
        
    Returns:
        JSON com produtos compatíveis
    """
    try:
        if not search_engine:
            return jsonify({
                'error': 'Sistema de busca não inicializado',
                'success': False
            }), 500
        
        # Executar busca de compatibilidade
        results = search_engine.get_compatible_products(model)
        
        response_data = {
            'success': True,
            'model': model,
            'total_compatible': len(results),
            'compatible_products': [
                {
                    'source_table': result.source_table,
                    'codigo_material': result.codigo_material,
                    'descricao': result.descricao,
                    'preco_real': result.preco_real,
                    'categoria_produto': result.categoria_produto,
                    'tipo_compatibilidade': result.modelos
                }
                for result in results
            ]
        }
        
        return jsonify(response_data)
        
    except Exception as e:
        current_app.logger.error(f"Erro na busca de compatibilidade: {e}")
        return jsonify({
            'error': 'Erro interno do servidor',
            'success': False
        }), 500

@search_bp.route('/recommendations', methods=['GET'])
@cross_origin()
def get_recommendations():
    """
    Obtém recomendações inteligentes baseadas em parâmetros
    
    Query Parameters:
        usage_type: Tipo de uso (domestico, profissional, poda)
        budget_max: Orçamento máximo
        product_type: Tipo de produto específico
        
    Returns:
        JSON com recomendações
    """
    try:
        if not search_engine:
            return jsonify({
                'error': 'Sistema de busca não inicializado',
                'success': False
            }), 500
        
        # Obter parâmetros da query string
        usage_type = request.args.get('usage_type', 'domestico')
        budget_max = request.args.get('budget_max', type=float)
        product_type = request.args.get('product_type')
        
        # Executar busca de recomendações
        results = search_engine.get_recommendations(usage_type, budget_max, product_type)
        
        response_data = {
            'success': True,
            'criteria': {
                'usage_type': usage_type,
                'budget_max': budget_max,
                'product_type': product_type
            },
            'total_recommendations': len(results),
            'recommendations': [
                {
                    'source_table': result.source_table,
                    'codigo_material': result.codigo_material,
                    'descricao': result.descricao,
                    'preco_real': result.preco_real,
                    'categoria_produto': result.categoria_produto,
                    'motivo_recomendacao': result.modelos,
                    'score_recomendacao': result.relevance_score
                }
                for result in results
            ]
        }
        
        return jsonify(response_data)
        
    except Exception as e:
        current_app.logger.error(f"Erro nas recomendações: {e}")
        return jsonify({
            'error': 'Erro interno do servidor',
            'success': False
        }), 500

@search_bp.route('/campaigns', methods=['GET'])
@cross_origin()
def get_campaign_products():
    """
    Obtém produtos em campanha com descontos
    
    Returns:
        JSON com produtos em campanha
    """
    try:
        if not search_engine:
            return jsonify({
                'error': 'Sistema de busca não inicializado',
                'success': False
            }), 500
        
        # Executar busca de campanhas
        campaigns = search_engine.get_campaign_products()
        
        response_data = {
            'success': True,
            'total_campaigns': len(campaigns),
            'campaigns': campaigns
        }
        
        return jsonify(response_data)
        
    except Exception as e:
        current_app.logger.error(f"Erro na busca de campanhas: {e}")
        return jsonify({
            'error': 'Erro interno do servidor',
            'success': False
        }), 500

@search_bp.route('/price-ranges', methods=['GET'])
@cross_origin()
def get_price_ranges():
    """
    Obtém faixas de preço por categoria
    
    Returns:
        JSON com estatísticas de preço
    """
    try:
        if not search_engine:
            return jsonify({
                'error': 'Sistema de busca não inicializado',
                'success': False
            }), 500
        
        # Executar análise de preços
        ranges = search_engine.get_price_ranges()
        
        response_data = {
            'success': True,
            'price_ranges': ranges
        }
        
        return jsonify(response_data)
        
    except Exception as e:
        current_app.logger.error(f"Erro na análise de preços: {e}")
        return jsonify({
            'error': 'Erro interno do servidor',
            'success': False
        }), 500

@search_bp.route('/suggest', methods=['GET'])
@cross_origin()
def get_search_suggestions():
    """
    Obtém sugestões de busca baseadas em termo parcial
    
    Query Parameters:
        q: Termo parcial para sugestão
        limit: Número máximo de sugestões (padrão: 10)
        
    Returns:
        JSON com sugestões
    """
    try:
        query_term = request.args.get('q', '').strip()
        limit = request.args.get('limit', 10, type=int)
        
        if not query_term or len(query_term) < 2:
            return jsonify({
                'success': True,
                'suggestions': []
            })
        
        # Sugestões pré-definidas baseadas em categorias e modelos comuns
        predefined_suggestions = [
            'motosserra elétrica',
            'motosserra a gasolina',
            'roçadeira profissional',
            'roçadeira doméstica',
            'produtos a bateria',
            'MS 162',
            'MS 250',
            'FS 220',
            'FS 55',
            'peças de reposição',
            'acessórios para motosserra',
            'sabres e correntes',
            'EPIs STIHL',
            'ferramentas básicas',
            'carburador',
            'filtro de ar',
            'vela de ignição',
            'corrente picco micro',
            'sabre 40cm',
            'óleo para corrente'
        ]
        
        # Filtrar sugestões que contêm o termo
        suggestions = [
            suggestion for suggestion in predefined_suggestions
            if query_term.lower() in suggestion.lower()
        ][:limit]
        
        response_data = {
            'success': True,
            'query': query_term,
            'suggestions': suggestions
        }
        
        return jsonify(response_data)
        
    except Exception as e:
        current_app.logger.error(f"Erro nas sugestões: {e}")
        return jsonify({
            'error': 'Erro interno do servidor',
            'success': False
        }), 500

@search_bp.route('/analytics', methods=['GET'])
@cross_origin()
def get_search_analytics():
    """
    Obtém analytics e estatísticas do sistema de busca
    
    Returns:
        JSON com estatísticas
    """
    try:
        if not search_engine:
            return jsonify({
                'error': 'Sistema de busca não inicializado',
                'success': False
            }), 500
        
        # Obter estatísticas do cache
        cache_stats = search_engine.get_cache_stats()
        
        # Aqui você pode adicionar mais estatísticas do banco de dados
        response_data = {
            'success': True,
            'cache_statistics': cache_stats,
            'system_status': {
                'search_engine_initialized': True,
                'database_connected': True,  # Você pode implementar uma verificação real
                'openai_configured': bool(os.getenv('OPENAI_API_KEY'))
            }
        }
        
        return jsonify(response_data)
        
    except Exception as e:
        current_app.logger.error(f"Erro nas analytics: {e}")
        return jsonify({
            'error': 'Erro interno do servidor',
            'success': False
        }), 500

@search_bp.route('/health', methods=['GET'])
@cross_origin()
def health_check():
    """
    Endpoint de verificação de saúde da API
    
    Returns:
        JSON com status da API
    """
    try:
        status = {
            'success': True,
            'status': 'healthy',
            'timestamp': datetime.now().isoformat(),
            'version': '5.0',
            'components': {
                'search_engine': search_engine is not None,
                'database': True,  # Implementar verificação real se necessário
                'openai': bool(os.getenv('OPENAI_API_KEY'))
            }
        }
        
        return jsonify(status)
        
    except Exception as e:
        return jsonify({
            'success': False,
            'status': 'unhealthy',
            'error': str(e)
        }), 500

# Handlers de erro
@search_bp.errorhandler(404)
def not_found(error):
    """Handler para erro 404"""
    return jsonify({
        'success': False,
        'error': 'Endpoint não encontrado',
        'message': 'Verifique a URL e tente novamente'
    }), 404

@search_bp.errorhandler(405)
def method_not_allowed(error):
    """Handler para erro 405"""
    return jsonify({
        'success': False,
        'error': 'Método não permitido',
        'message': 'Verifique o método HTTP utilizado'
    }), 405

@search_bp.errorhandler(500)
def internal_error(error):
    """Handler para erro 500"""
    return jsonify({
        'success': False,
        'error': 'Erro interno do servidor',
        'message': 'Tente novamente mais tarde'
    }), 500

