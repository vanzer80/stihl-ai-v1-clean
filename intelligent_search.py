"""
Sistema de Busca Inteligente para Produtos STIHL
"""

import os
import json
import re
import psycopg2
import openai
from typing import Dict, List, Any, Optional, Tuple
from datetime import datetime
import logging
from dataclasses import dataclass
from enum import Enum

# Configurar logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class SearchType(Enum):
    """Tipos de busca disponíveis"""
    PRODUCT_SEARCH = "product_search"
    CATEGORY_SEARCH = "category_search"
    PRICE_RANGE = "price_range"
    TECHNICAL_SPECS = "technical_specs"
    RECOMMENDATION = "recommendation"
    NATURAL_LANGUAGE = "natural_language"

@dataclass
class SearchQuery:
    """Estrutura de uma consulta de busca"""
    query_text: str
    search_type: SearchType
    filters: Dict[str, Any]
    limit: int = 20
    offset: int = 0
    user_context: Optional[Dict[str, Any]] = None

@dataclass
class SearchResult:
    """Resultado de uma busca"""
    success: bool
    results: List[Dict[str, Any]]
    total_count: int
    query_time_ms: int
    suggestions: List[str]
    metadata: Dict[str, Any]
    error_message: Optional[str] = None

class IntelligentSearchEngine:
    """
    Motor de busca inteligente para produtos STIHL
    """
    
    def __init__(self, database_url: str):
        self.database_url = database_url
        self.openai_client = openai.OpenAI()
        
        # Padrões de busca comuns
        self.search_patterns = {
            'model_patterns': [
                r'MS\s*(\d+[A-Z]*(?:-[A-Z]+)*)',  # MS 162, MS 172 C-BE, etc.
                r'MSE\s*(\d+[A-Z]*(?:-[A-Z]+)*)', # MSE 141, MSE 170, etc.
            ],
            'price_patterns': [
                r'até\s*R?\$?\s*(\d+(?:\.\d{3})*(?:,\d{2})?)',
                r'menor\s*que\s*R?\$?\s*(\d+(?:\.\d{3})*(?:,\d{2})?)',
                r'máximo\s*R?\$?\s*(\d+(?:\.\d{3})*(?:,\d{2})?)',
                r'entre\s*R?\$?\s*(\d+(?:\.\d{3})*(?:,\d{2})?)\s*e\s*R?\$?\s*(\d+(?:\.\d{3})*(?:,\d{2})?)',
            ],
            'power_patterns': [
                r'(\d+(?:,\d+)?)\s*(?:cv|hp)',
                r'(\d+(?:,\d+)?)\s*(?:kw|kilowatt)',
            ],
            'category_patterns': [
                r'motosserra|chainsaw|serra',
                r'roçadeira|trimmer|brush',
                r'elétric[ao]|electric',
                r'bateria|battery',
                r'sabre|bar|guide',
                r'corrente|chain',
            ]
        }
        
        # Sinônimos e termos relacionados
        self.synonyms = {
            'motosserra': ['serra', 'chainsaw', 'motoserra'],
            'elétrica': ['eletrica', 'electric', '127v', '220v'],
            'combustão': ['combustao', 'gasolina', 'gas', '2t'],
            'leve': ['pequena', 'compacta', 'doméstica'],
            'profissional': ['pesada', 'industrial', 'comercial'],
            'potente': ['forte', 'alta potência', 'high power'],
            'barata': ['barato', 'econômica', 'em conta', 'preço baixo'],
            'cara': ['caro', 'premium', 'top de linha', 'preço alto']
        }
    
    def search(self, query: SearchQuery) -> SearchResult:
        """
        Executa uma busca inteligente
        """
        start_time = datetime.now()
        
        try:
            logger.info(f"Executando busca: {query.query_text}")
            
            # Analisar consulta com IA se for linguagem natural
            if query.search_type == SearchType.NATURAL_LANGUAGE:
                analyzed_query = self._analyze_natural_language_query(query.query_text)
                query = self._convert_to_structured_query(analyzed_query, query)
            
            # Executar busca baseada no tipo
            if query.search_type == SearchType.PRODUCT_SEARCH:
                results = self._search_products(query)
            elif query.search_type == SearchType.CATEGORY_SEARCH:
                results = self._search_categories(query)
            elif query.search_type == SearchType.PRICE_RANGE:
                results = self._search_by_price_range(query)
            elif query.search_type == SearchType.TECHNICAL_SPECS:
                results = self._search_by_specs(query)
            elif query.search_type == SearchType.RECOMMENDATION:
                results = self._get_recommendations(query)
            else:
                results = self._search_products(query)  # Default
            
            # Calcular tempo de execução
            end_time = datetime.now()
            query_time_ms = int((end_time - start_time).total_seconds() * 1000)
            
            # Gerar sugestões
            suggestions = self._generate_suggestions(query, results)
            
            return SearchResult(
                success=True,
                results=results,
                total_count=len(results),
                query_time_ms=query_time_ms,
                suggestions=suggestions,
                metadata={
                    'query_type': query.search_type.value,
                    'filters_applied': query.filters,
                    'timestamp': datetime.now().isoformat()
                }
            )
            
        except Exception as e:
            logger.error(f"Erro na busca: {e}")
            end_time = datetime.now()
            query_time_ms = int((end_time - start_time).total_seconds() * 1000)
            
            return SearchResult(
                success=False,
                results=[],
                total_count=0,
                query_time_ms=query_time_ms,
                suggestions=[],
                metadata={},
                error_message=str(e)
            )
    
    def _analyze_natural_language_query(self, query_text: str) -> Dict[str, Any]:
        """
        Analisa consulta em linguagem natural usando IA
        """
        try:
            prompt = f"""
            Analise a seguinte consulta sobre produtos STIHL e extraia informações estruturadas:
            
            Consulta: "{query_text}"
            
            Extraia e retorne em JSON:
            1. Tipo de produto mencionado (motosserra, roçadeira, etc.)
            2. Modelo específico se mencionado (MS 162, MSE 141, etc.)
            3. Características técnicas (potência, peso, tamanho do sabre, etc.)
            4. Faixa de preço se mencionada
            5. Uso pretendido (doméstico, profissional, etc.)
            6. Tipo de alimentação (elétrica, combustão, bateria)
            7. Intenção da busca (comprar, comparar, informações, etc.)
            
            Responda apenas com JSON válido no formato:
            {{
                "product_type": "string",
                "model": "string ou null",
                "technical_specs": {{}},
                "price_range": {{"min": number, "max": number}},
                "usage_type": "string",
                "power_type": "string",
                "search_intent": "string",
                "keywords": ["array", "de", "palavras-chave"]
            }}
            """
            
            response = self.openai_client.chat.completions.create(
                model="gpt-4",
                messages=[
                    {"role": "system", "content": "Você é um especialista em produtos STIHL e análise de consultas de busca."},
                    {"role": "user", "content": prompt}
                ],
                temperature=0.1
            )
            
            ai_response = response.choices[0].message.content
            
            # Tentar parsear JSON
            try:
                return json.loads(ai_response)
            except json.JSONDecodeError:
                # Se não conseguir parsear, extrair JSON do texto
                json_match = re.search(r'\{.*\}', ai_response, re.DOTALL)
                if json_match:
                    return json.loads(json_match.group())
                else:
                    return self._fallback_analysis(query_text)
                    
        except Exception as e:
            logger.error(f"Erro na análise por IA: {e}")
            return self._fallback_analysis(query_text)
    
    def _fallback_analysis(self, query_text: str) -> Dict[str, Any]:
        """
        Análise de fallback usando regex quando IA falha
        """
        analysis = {
            "product_type": None,
            "model": None,
            "technical_specs": {},
            "price_range": {},
            "usage_type": None,
            "power_type": None,
            "search_intent": "search",
            "keywords": []
        }
        
        query_lower = query_text.lower()
        
        # Detectar tipo de produto
        for pattern in self.search_patterns['category_patterns']:
            if re.search(pattern, query_lower):
                if 'motosserra' in pattern or 'chainsaw' in pattern:
                    analysis['product_type'] = 'motosserra'
                elif 'roçadeira' in pattern or 'trimmer' in pattern:
                    analysis['product_type'] = 'roçadeira'
                elif 'elétric' in pattern:
                    analysis['power_type'] = 'elétrica'
                elif 'bateria' in pattern:
                    analysis['power_type'] = 'bateria'
                break
        
        # Detectar modelo
        for pattern in self.search_patterns['model_patterns']:
            match = re.search(pattern, query_text, re.IGNORECASE)
            if match:
                analysis['model'] = match.group(0)
                break
        
        # Detectar faixa de preço
        for pattern in self.search_patterns['price_patterns']:
            match = re.search(pattern, query_lower)
            if match:
                if 'entre' in pattern:
                    analysis['price_range'] = {
                        'min': self._parse_price(match.group(1)),
                        'max': self._parse_price(match.group(2))
                    }
                else:
                    analysis['price_range'] = {
                        'max': self._parse_price(match.group(1))
                    }
                break
        
        # Detectar potência
        for pattern in self.search_patterns['power_patterns']:
            match = re.search(pattern, query_lower)
            if match:
                power_value = float(match.group(1).replace(',', '.'))
                if 'cv' in match.group(0) or 'hp' in match.group(0):
                    analysis['technical_specs']['power_hp'] = power_value
                elif 'kw' in match.group(0):
                    analysis['technical_specs']['power_kw'] = power_value
                break
        
        # Extrair palavras-chave
        words = re.findall(r'\b\w+\b', query_lower)
        analysis['keywords'] = [w for w in words if len(w) > 2]
        
        return analysis
    
    def _parse_price(self, price_str: str) -> float:
        """Converte string de preço para float"""
        # Remove pontos de milhares e converte vírgula decimal
        price_clean = price_str.replace('.', '').replace(',', '.')
        return float(price_clean)
    
    def _convert_to_structured_query(self, analysis: Dict[str, Any], original_query: SearchQuery) -> SearchQuery:
        """
        Converte análise de IA em consulta estruturada
        """
        filters = original_query.filters.copy()
        
        # Adicionar filtros baseados na análise
        if analysis.get('product_type'):
            filters['category'] = analysis['product_type']
        
        if analysis.get('model'):
            filters['model'] = analysis['model']
        
        if analysis.get('power_type'):
            filters['power_type'] = analysis['power_type']
        
        if analysis.get('price_range'):
            filters.update(analysis['price_range'])
        
        if analysis.get('technical_specs'):
            filters.update(analysis['technical_specs'])
        
        # Determinar tipo de busca
        search_type = SearchType.PRODUCT_SEARCH
        if analysis.get('search_intent') == 'compare':
            search_type = SearchType.RECOMMENDATION
        elif analysis.get('price_range'):
            search_type = SearchType.PRICE_RANGE
        elif analysis.get('technical_specs'):
            search_type = SearchType.TECHNICAL_SPECS
        
        return SearchQuery(
            query_text=original_query.query_text,
            search_type=search_type,
            filters=filters,
            limit=original_query.limit,
            offset=original_query.offset,
            user_context=original_query.user_context
        )
    
    def _search_products(self, query: SearchQuery) -> List[Dict[str, Any]]:
        """
        Busca produtos usando a função SQL inteligente
        """
        try:
            conn = psycopg2.connect(self.database_url)
            cursor = conn.cursor()
            
            # Preparar parâmetros para a função SQL
            search_text = query.query_text
            category_filter = query.filters.get('category')
            min_price = query.filters.get('min', query.filters.get('min_price'))
            max_price = query.filters.get('max', query.filters.get('max_price'))
            min_power = query.filters.get('power_kw', query.filters.get('min_power'))
            max_power = query.filters.get('max_power')
            
            # Chamar função SQL de busca inteligente
            cursor.execute("""
                SELECT * FROM intelligent_product_search(
                    p_search_text := %s,
                    p_category_filter := %s,
                    p_min_price := %s,
                    p_max_price := %s,
                    p_min_power := %s,
                    p_max_power := %s,
                    p_limit := %s,
                    p_offset := %s
                )
            """, (
                search_text,
                category_filter,
                min_price,
                max_price,
                min_power,
                max_power,
                query.limit,
                query.offset
            ))
            
            results = cursor.fetchall()
            
            # Converter resultados para dicionários
            columns = [desc[0] for desc in cursor.description]
            products = []
            
            for row in results:
                product = dict(zip(columns, row))
                # Converter tipos especiais para JSON serializável
                for key, value in product.items():
                    if hasattr(value, 'isoformat'):  # datetime
                        product[key] = value.isoformat()
                    elif isinstance(value, (list, dict)):  # JSON fields
                        product[key] = value
                products.append(product)
            
            cursor.close()
            conn.close()
            
            return products
            
        except Exception as e:
            logger.error(f"Erro na busca de produtos: {e}")
            return []
    
    def _search_categories(self, query: SearchQuery) -> List[Dict[str, Any]]:
        """
        Busca categorias
        """
        try:
            conn = psycopg2.connect(self.database_url)
            cursor = conn.cursor()
            
            cursor.execute("""
                SELECT * FROM get_categories_hierarchy()
                WHERE name ILIKE %s OR description ILIKE %s
                ORDER BY level, sort_order
                LIMIT %s OFFSET %s
            """, (
                f"%{query.query_text}%",
                f"%{query.query_text}%",
                query.limit,
                query.offset
            ))
            
            results = cursor.fetchall()
            columns = [desc[0] for desc in cursor.description]
            categories = [dict(zip(columns, row)) for row in results]
            
            cursor.close()
            conn.close()
            
            return categories
            
        except Exception as e:
            logger.error(f"Erro na busca de categorias: {e}")
            return []
    
    def _search_by_price_range(self, query: SearchQuery) -> List[Dict[str, Any]]:
        """
        Busca por faixa de preço
        """
        try:
            conn = psycopg2.connect(self.database_url)
            cursor = conn.cursor()
            
            min_price = query.filters.get('min', 0)
            max_price = query.filters.get('max', 999999)
            
            cursor.execute("""
                SELECT p.*, pr.price_value, c.name as category_name
                FROM products p
                JOIN pricing pr ON p.id = pr.product_id
                JOIN categories c ON p.category_id = c.id
                WHERE pr.is_active = true 
                AND pr.price_type = 'suggested_retail'
                AND pr.price_value BETWEEN %s AND %s
                ORDER BY pr.price_value
                LIMIT %s OFFSET %s
            """, (min_price, max_price, query.limit, query.offset))
            
            results = cursor.fetchall()
            columns = [desc[0] for desc in cursor.description]
            products = [dict(zip(columns, row)) for row in results]
            
            cursor.close()
            conn.close()
            
            return products
            
        except Exception as e:
            logger.error(f"Erro na busca por preço: {e}")
            return []
    
    def _search_by_specs(self, query: SearchQuery) -> List[Dict[str, Any]]:
        """
        Busca por especificações técnicas
        """
        try:
            conn = psycopg2.connect(self.database_url)
            cursor = conn.cursor()
            
            # Construir condições WHERE dinamicamente
            conditions = []
            params = []
            
            if 'power_kw' in query.filters:
                conditions.append("ts.power_kw >= %s")
                params.append(query.filters['power_kw'])
            
            if 'power_hp' in query.filters:
                conditions.append("ts.power_hp >= %s")
                params.append(query.filters['power_hp'])
            
            if 'weight_kg' in query.filters:
                conditions.append("ts.weight_kg <= %s")
                params.append(query.filters['weight_kg'])
            
            if 'displacement_cc' in query.filters:
                conditions.append("ts.displacement_cc >= %s")
                params.append(query.filters['displacement_cc'])
            
            where_clause = " AND ".join(conditions) if conditions else "1=1"
            
            cursor.execute(f"""
                SELECT p.*, ts.*, c.name as category_name
                FROM products p
                JOIN technical_specifications ts ON p.id = ts.product_id
                JOIN categories c ON p.category_id = c.id
                WHERE {where_clause}
                ORDER BY ts.power_kw DESC
                LIMIT %s OFFSET %s
            """, params + [query.limit, query.offset])
            
            results = cursor.fetchall()
            columns = [desc[0] for desc in cursor.description]
            products = [dict(zip(columns, row)) for row in results]
            
            cursor.close()
            conn.close()
            
            return products
            
        except Exception as e:
            logger.error(f"Erro na busca por especificações: {e}")
            return []
    
    def _get_recommendations(self, query: SearchQuery) -> List[Dict[str, Any]]:
        """
        Obtém recomendações de produtos
        """
        try:
            conn = psycopg2.connect(self.database_url)
            cursor = conn.cursor()
            
            # Se há um produto específico, buscar similares
            if 'product_id' in query.filters:
                cursor.execute("""
                    SELECT * FROM get_product_recommendations(%s, %s)
                """, (query.filters['product_id'], query.limit))
            else:
                # Recomendações gerais baseadas em popularidade e avaliações
                cursor.execute("""
                    SELECT p.*, pr.price_value, c.name as category_name,
                           ts.power_kw, ts.weight_kg
                    FROM products p
                    JOIN pricing pr ON p.id = pr.product_id
                    JOIN categories c ON p.category_id = c.id
                    LEFT JOIN technical_specifications ts ON p.id = ts.product_id
                    WHERE p.status = 'active' AND pr.is_active = true
                    ORDER BY pr.price_value, ts.power_kw DESC
                    LIMIT %s OFFSET %s
                """, (query.limit, query.offset))
            
            results = cursor.fetchall()
            columns = [desc[0] for desc in cursor.description]
            products = [dict(zip(columns, row)) for row in results]
            
            cursor.close()
            conn.close()
            
            return products
            
        except Exception as e:
            logger.error(f"Erro ao obter recomendações: {e}")
            return []
    
    def _generate_suggestions(self, query: SearchQuery, results: List[Dict[str, Any]]) -> List[str]:
        """
        Gera sugestões de busca baseadas nos resultados
        """
        suggestions = []
        
        try:
            if not results:
                # Sugestões quando não há resultados
                suggestions = [
                    "Tente buscar por 'motosserra elétrica'",
                    "Procure por modelos específicos como 'MS 162'",
                    "Busque por faixa de preço: 'até R$ 2000'",
                    "Tente 'motosserra para uso doméstico'"
                ]
            else:
                # Sugestões baseadas nos resultados
                categories = set()
                models = set()
                
                for result in results[:5]:  # Analisar apenas os primeiros 5
                    if 'category_name' in result and result['category_name']:
                        categories.add(result['category_name'])
                    if 'model' in result and result['model']:
                        models.add(result['model'])
                
                # Gerar sugestões de categorias relacionadas
                for category in list(categories)[:3]:
                    suggestions.append(f"Ver mais produtos em {category}")
                
                # Gerar sugestões de modelos relacionados
                for model in list(models)[:2]:
                    suggestions.append(f"Comparar com outros modelos {model}")
                
                # Sugestões de refinamento
                if len(results) > 10:
                    suggestions.append("Refinar busca por preço")
                    suggestions.append("Filtrar por potência")
        
        except Exception as e:
            logger.error(f"Erro ao gerar sugestões: {e}")
        
        return suggestions[:5]  # Máximo 5 sugestões
    
    def get_product_details(self, product_id: str) -> Optional[Dict[str, Any]]:
        """
        Obtém detalhes completos de um produto
        """
        try:
            conn = psycopg2.connect(self.database_url)
            cursor = conn.cursor()
            
            cursor.execute("""
                SELECT * FROM get_product_by_code(%s)
            """, (product_id,))
            
            result = cursor.fetchone()
            
            if result:
                columns = [desc[0] for desc in cursor.description]
                product = dict(zip(columns, result))
                
                # Converter tipos especiais
                for key, value in product.items():
                    if hasattr(value, 'isoformat'):
                        product[key] = value.isoformat()
                
                cursor.close()
                conn.close()
                return product
            
            cursor.close()
            conn.close()
            return None
            
        except Exception as e:
            logger.error(f"Erro ao obter detalhes do produto: {e}")
            return None
    
    def get_search_analytics(self) -> Dict[str, Any]:
        """
        Obtém analytics das buscas realizadas
        """
        try:
            conn = psycopg2.connect(self.database_url)
            cursor = conn.cursor()
            
            # Consultas mais populares
            cursor.execute("""
                SELECT query_type, COUNT(*) as count
                FROM query_metrics
                WHERE created_at >= NOW() - INTERVAL '30 days'
                GROUP BY query_type
                ORDER BY count DESC
                LIMIT 10
            """)
            
            popular_queries = cursor.fetchall()
            
            # Tempo médio de resposta
            cursor.execute("""
                SELECT AVG(execution_time_ms) as avg_time,
                       MIN(execution_time_ms) as min_time,
                       MAX(execution_time_ms) as max_time
                FROM query_metrics
                WHERE created_at >= NOW() - INTERVAL '7 days'
            """)
            
            performance_stats = cursor.fetchone()
            
            # Produtos mais buscados
            cursor.execute("""
                SELECT p.name, COUNT(*) as search_count
                FROM query_metrics qm
                JOIN products p ON (qm.query_parameters->>'product_id')::uuid = p.id
                WHERE qm.created_at >= NOW() - INTERVAL '30 days'
                GROUP BY p.name
                ORDER BY search_count DESC
                LIMIT 10
            """)
            
            popular_products = cursor.fetchall()
            
            cursor.close()
            conn.close()
            
            return {
                'popular_queries': [{'type': row[0], 'count': row[1]} for row in popular_queries],
                'performance': {
                    'avg_time_ms': float(performance_stats[0]) if performance_stats[0] else 0,
                    'min_time_ms': performance_stats[1] or 0,
                    'max_time_ms': performance_stats[2] or 0
                },
                'popular_products': [{'name': row[0], 'count': row[1]} for row in popular_products]
            }
            
        except Exception as e:
            logger.error(f"Erro ao obter analytics: {e}")
            return {}
    
    def log_search_query(self, query: SearchQuery, result: SearchResult):
        """
        Registra consulta de busca para analytics
        """
        try:
            conn = psycopg2.connect(self.database_url)
            cursor = conn.cursor()
            
            # Preparar parâmetros da consulta
            query_params = {
                'query_text': query.query_text,
                'filters': query.filters,
                'limit': query.limit,
                'offset': query.offset
            }
            
            cursor.execute("""
                INSERT INTO query_metrics (
                    query_type, query_parameters, execution_time_ms, 
                    result_count, user_id, session_id
                ) VALUES (%s, %s, %s, %s, %s, %s)
            """, (
                query.search_type.value,
                json.dumps(query_params),
                result.query_time_ms,
                result.total_count,
                query.user_context.get('user_id') if query.user_context else None,
                query.user_context.get('session_id') if query.user_context else None
            ))
            
            conn.commit()
            cursor.close()
            conn.close()
            
        except Exception as e:
            logger.error(f"Erro ao registrar consulta: {e}")

