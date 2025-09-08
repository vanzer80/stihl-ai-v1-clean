"""
API de Busca Inteligente para Produtos STIHL
"""

import json
from flask import Blueprint, request, jsonify
from src.models.intelligent_search import IntelligentSearchEngine, SearchQuery, SearchType
import logging

# Configurar logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

search_api_bp = Blueprint('search_api', __name__)

# Cache para instância do motor de busca
_search_engine = None

def get_search_engine():
    """Obtém instância do motor de busca"""
    global _search_engine
    if _search_engine is None:
        # Em produção, isso viria de variáveis de ambiente
        database_url = "postgresql://user:pass@localhost:5432/db"  # Placeholder
        _search_engine = IntelligentSearchEngine(database_url)
    return _search_engine

@search_api_bp.route('/search', methods=['POST'])
def search_products():
    """
    Busca inteligente de produtos
    
    Body JSON:
    {
        "query": "string - consulta de busca",
        "type": "string - tipo de busca (opcional)",
        "filters": {
            "category": "string",
            "min_price": number,
            "max_price": number,
            "power_type": "string",
            "model": "string"
        },
        "limit": number (default: 20),
        "offset": number (default: 0)
    }
    """
    try:
        data = request.get_json()
        
        if not data or 'query' not in data:
            return jsonify({
                'success': False,
                'error': 'Campo "query" é obrigatório'
            }), 400
        
        # Determinar tipo de busca
        search_type_str = data.get('type', 'natural_language')
        try:
            search_type = SearchType(search_type_str)
        except ValueError:
            search_type = SearchType.NATURAL_LANGUAGE
        
        # Criar consulta estruturada
        query = SearchQuery(
            query_text=data['query'],
            search_type=search_type,
            filters=data.get('filters', {}),
            limit=data.get('limit', 20),
            offset=data.get('offset', 0),
            user_context={
                'user_id': request.headers.get('X-User-ID'),
                'session_id': request.headers.get('X-Session-ID'),
                'ip_address': request.remote_addr
            }
        )
        
        # Executar busca
        search_engine = get_search_engine()
        result = search_engine.search(query)
        
        # Registrar consulta para analytics
        search_engine.log_search_query(query, result)
        
        if result.success:
            return jsonify({
                'success': True,
                'results': result.results,
                'total_count': result.total_count,
                'query_time_ms': result.query_time_ms,
                'suggestions': result.suggestions,
                'metadata': result.metadata
            })
        else:
            return jsonify({
                'success': False,
                'error': result.error_message,
                'suggestions': result.suggestions
            }), 500
            
    except Exception as e:
        logger.error(f"Erro na busca: {e}")
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

@search_api_bp.route('/search/products', methods=['GET'])
def search_products_get():
    """
    Busca de produtos via GET (para URLs amigáveis)
    
    Query params:
    - q: consulta de busca
    - category: filtro de categoria
    - min_price, max_price: faixa de preço
    - limit, offset: paginação
    """
    try:
        query_text = request.args.get('q', '')
        
        if not query_text:
            return jsonify({
                'success': False,
                'error': 'Parâmetro "q" é obrigatório'
            }), 400
        
        # Construir filtros a partir dos query params
        filters = {}
        
        if request.args.get('category'):
            filters['category'] = request.args.get('category')
        
        if request.args.get('min_price'):
            try:
                filters['min_price'] = float(request.args.get('min_price'))
            except ValueError:
                pass
        
        if request.args.get('max_price'):
            try:
                filters['max_price'] = float(request.args.get('max_price'))
            except ValueError:
                pass
        
        if request.args.get('power_type'):
            filters['power_type'] = request.args.get('power_type')
        
        if request.args.get('model'):
            filters['model'] = request.args.get('model')
        
        # Criar consulta
        query = SearchQuery(
            query_text=query_text,
            search_type=SearchType.NATURAL_LANGUAGE,
            filters=filters,
            limit=int(request.args.get('limit', 20)),
            offset=int(request.args.get('offset', 0)),
            user_context={
                'user_id': request.headers.get('X-User-ID'),
                'session_id': request.headers.get('X-Session-ID'),
                'ip_address': request.remote_addr
            }
        )
        
        # Executar busca
        search_engine = get_search_engine()
        result = search_engine.search(query)
        
        # Registrar consulta
        search_engine.log_search_query(query, result)
        
        if result.success:
            return jsonify({
                'success': True,
                'results': result.results,
                'total_count': result.total_count,
                'query_time_ms': result.query_time_ms,
                'suggestions': result.suggestions,
                'metadata': result.metadata
            })
        else:
            return jsonify({
                'success': False,
                'error': result.error_message
            }), 500
            
    except Exception as e:
        logger.error(f"Erro na busca GET: {e}")
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

@search_api_bp.route('/search/categories', methods=['GET'])
def search_categories():
    """
    Busca de categorias
    """
    try:
        query_text = request.args.get('q', '')
        
        query = SearchQuery(
            query_text=query_text,
            search_type=SearchType.CATEGORY_SEARCH,
            filters={},
            limit=int(request.args.get('limit', 50)),
            offset=int(request.args.get('offset', 0))
        )
        
        search_engine = get_search_engine()
        result = search_engine.search(query)
        
        if result.success:
            return jsonify({
                'success': True,
                'categories': result.results,
                'total_count': result.total_count
            })
        else:
            return jsonify({
                'success': False,
                'error': result.error_message
            }), 500
            
    except Exception as e:
        logger.error(f"Erro na busca de categorias: {e}")
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

@search_api_bp.route('/search/recommendations', methods=['POST'])
def get_recommendations():
    """
    Obtém recomendações de produtos
    
    Body JSON:
    {
        "product_id": "string - ID do produto para recomendações similares (opcional)",
        "user_preferences": {
            "budget": number,
            "usage_type": "string",
            "experience_level": "string"
        },
        "limit": number
    }
    """
    try:
        data = request.get_json() or {}
        
        filters = {}
        if 'product_id' in data:
            filters['product_id'] = data['product_id']
        
        # Adicionar preferências do usuário aos filtros
        if 'user_preferences' in data:
            prefs = data['user_preferences']
            if 'budget' in prefs:
                filters['max_price'] = prefs['budget']
            if 'usage_type' in prefs:
                filters['usage_type'] = prefs['usage_type']
        
        query = SearchQuery(
            query_text="recomendações",
            search_type=SearchType.RECOMMENDATION,
            filters=filters,
            limit=data.get('limit', 10),
            offset=0,
            user_context={
                'user_id': request.headers.get('X-User-ID'),
                'session_id': request.headers.get('X-Session-ID')
            }
        )
        
        search_engine = get_search_engine()
        result = search_engine.search(query)
        
        if result.success:
            return jsonify({
                'success': True,
                'recommendations': result.results,
                'total_count': result.total_count,
                'metadata': result.metadata
            })
        else:
            return jsonify({
                'success': False,
                'error': result.error_message
            }), 500
            
    except Exception as e:
        logger.error(f"Erro ao obter recomendações: {e}")
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

@search_api_bp.route('/products/<product_id>', methods=['GET'])
def get_product_details(product_id):
    """
    Obtém detalhes completos de um produto
    """
    try:
        search_engine = get_search_engine()
        product = search_engine.get_product_details(product_id)
        
        if product:
            return jsonify({
                'success': True,
                'product': product
            })
        else:
            return jsonify({
                'success': False,
                'error': 'Produto não encontrado'
            }), 404
            
    except Exception as e:
        logger.error(f"Erro ao obter detalhes do produto: {e}")
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

@search_api_bp.route('/search/suggest', methods=['GET'])
def get_search_suggestions():
    """
    Obtém sugestões de busca baseadas em texto parcial
    """
    try:
        partial_text = request.args.get('q', '')
        
        if len(partial_text) < 2:
            return jsonify({
                'success': True,
                'suggestions': []
            })
        
        # Sugestões básicas baseadas em padrões comuns
        suggestions = []
        
        # Sugestões de modelos
        if 'ms' in partial_text.lower():
            suggestions.extend([
                'MS 162 motosserra',
                'MS 172 motosserra',
                'MS 250 motosserra',
                'MS 260 motosserra'
            ])
        
        # Sugestões de categorias
        if any(word in partial_text.lower() for word in ['moto', 'serra']):
            suggestions.extend([
                'motosserra elétrica',
                'motosserra a combustão',
                'motosserra para poda',
                'motosserra profissional'
            ])
        
        # Sugestões de preço
        if any(word in partial_text.lower() for word in ['barato', 'preço', 'até']):
            suggestions.extend([
                'até R$ 1000',
                'até R$ 2000',
                'até R$ 3000'
            ])
        
        # Filtrar sugestões que contenham o texto parcial
        filtered_suggestions = [
            s for s in suggestions 
            if partial_text.lower() in s.lower()
        ][:10]
        
        return jsonify({
            'success': True,
            'suggestions': filtered_suggestions
        })
        
    except Exception as e:
        logger.error(f"Erro ao obter sugestões: {e}")
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

@search_api_bp.route('/search/analytics', methods=['GET'])
def get_search_analytics():
    """
    Obtém analytics das buscas (apenas para administradores)
    """
    try:
        # Em produção, verificar permissões de admin aqui
        
        search_engine = get_search_engine()
        analytics = search_engine.get_search_analytics()
        
        return jsonify({
            'success': True,
            'analytics': analytics
        })
        
    except Exception as e:
        logger.error(f"Erro ao obter analytics: {e}")
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

@search_api_bp.route('/search/filters', methods=['GET'])
def get_available_filters():
    """
    Obtém filtros disponíveis para busca
    """
    try:
        # Retornar filtros estáticos por enquanto
        # Em produção, isso poderia vir do banco de dados
        
        filters = {
            'categories': [
                {'value': 'motosserras', 'label': 'Motosserras'},
                {'value': 'rocadeiras', 'label': 'Roçadeiras'},
                {'value': 'produtos-bateria', 'label': 'Produtos a Bateria'},
                {'value': 'acessorios', 'label': 'Acessórios'}
            ],
            'power_types': [
                {'value': 'combustao', 'label': 'Combustão'},
                {'value': 'eletrica', 'label': 'Elétrica'},
                {'value': 'bateria', 'label': 'Bateria'}
            ],
            'price_ranges': [
                {'min': 0, 'max': 1000, 'label': 'Até R$ 1.000'},
                {'min': 1000, 'max': 2000, 'label': 'R$ 1.000 - R$ 2.000'},
                {'min': 2000, 'max': 5000, 'label': 'R$ 2.000 - R$ 5.000'},
                {'min': 5000, 'max': 999999, 'label': 'Acima de R$ 5.000'}
            ],
            'usage_types': [
                {'value': 'domestico', 'label': 'Uso Doméstico'},
                {'value': 'profissional', 'label': 'Uso Profissional'},
                {'value': 'industrial', 'label': 'Uso Industrial'}
            ]
        }
        
        return jsonify({
            'success': True,
            'filters': filters
        })
        
    except Exception as e:
        logger.error(f"Erro ao obter filtros: {e}")
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

@search_api_bp.route('/search/test', methods=['GET'])
def test_search():
    """
    Endpoint de teste para verificar se a API está funcionando
    """
    return jsonify({
        'success': True,
        'message': 'API de Busca Inteligente STIHL funcionando!',
        'version': '1.0.0',
        'endpoints': [
            'POST /search - Busca inteligente',
            'GET /search/products - Busca via GET',
            'GET /search/categories - Busca categorias',
            'POST /search/recommendations - Recomendações',
            'GET /products/<id> - Detalhes do produto',
            'GET /search/suggest - Sugestões de busca',
            'GET /search/analytics - Analytics (admin)',
            'GET /search/filters - Filtros disponíveis'
        ]
    })

# Tratamento de erros
@search_api_bp.errorhandler(400)
def bad_request(e):
    return jsonify({
        'success': False,
        'error': 'Requisição inválida'
    }), 400

@search_api_bp.errorhandler(404)
def not_found(e):
    return jsonify({
        'success': False,
        'error': 'Recurso não encontrado'
    }), 404

@search_api_bp.errorhandler(500)
def internal_error(e):
    return jsonify({
        'success': False,
        'error': 'Erro interno do servidor'
    }), 500

