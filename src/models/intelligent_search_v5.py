"""
Sistema de Busca Inteligente STIHL AI v5
========================================

Este módulo implementa o sistema de busca inteligente adaptado para a nova
estrutura de banco de dados v5, baseada diretamente nas abas da planilha
original STIHL.

Funcionalidades:
- Busca unificada em todas as tabelas de produtos
- Processamento de linguagem natural em português
- Análise de intenções de busca
- Recomendações inteligentes
- Cache de resultados para performance
- Integração com OpenAI GPT-4 para análise semântica

Autor: Manus AI
Data: 2025-09-08
Versão: 5.0
"""

import os
import re
import json
import hashlib
from typing import Dict, List, Optional, Tuple, Any
from dataclasses import dataclass
from datetime import datetime, timedelta
import psycopg2
from psycopg2.extras import RealDictCursor
import openai
from openai import OpenAI

# Configuração do cliente OpenAI
client = OpenAI(
    api_key=os.getenv('OPENAI_API_KEY'),
    base_url=os.getenv('OPENAI_API_BASE', 'https://api.openai.com/v1')
)

@dataclass
class SearchResult:
    """Classe para representar um resultado de busca"""
    source_table: str
    codigo_material: str
    descricao: str
    preco_real: float
    modelos: str
    categoria_produto: str
    relevance_score: float
    detalhes_tecnicos: Optional[str] = None

@dataclass
class SearchIntent:
    """Classe para representar a intenção de busca analisada"""
    search_type: str  # PRODUCT_SEARCH, PRICE_RANGE, COMPATIBILITY, etc.
    product_category: Optional[str] = None
    model_name: Optional[str] = None
    price_min: Optional[float] = None
    price_max: Optional[float] = None
    usage_type: Optional[str] = None
    keywords: List[str] = None
    confidence: float = 0.0

class IntelligentSearchV5:
    """
    Sistema de Busca Inteligente STIHL AI v5
    
    Esta classe implementa um sistema avançado de busca que combina:
    - Análise de linguagem natural usando GPT-4
    - Busca em múltiplas tabelas do banco de dados
    - Cache inteligente para performance
    - Recomendações baseadas em contexto
    """
    
    def __init__(self, database_url: str):
        """
        Inicializa o sistema de busca inteligente
        
        Args:
            database_url: URL de conexão com o banco de dados PostgreSQL
        """
        self.database_url = database_url
        self.cache = {}
        self.cache_ttl = timedelta(minutes=30)
        
        # Mapeamento de categorias para facilitar a busca
        self.category_mapping = {
            'motosserra': ['ms', 'motosserras'],
            'roçadeira': ['rocadeiras_e_impl', 'roçadeiras'],
            'bateria': ['produtos_a_bateria', 'produtos a bateria'],
            'peça': ['pecas', 'peças'],
            'acessorio': ['acessorios', 'acessórios'],
            'sabre': ['sabres_correntes_pinhoes_limas', 'sabres', 'correntes'],
            'corrente': ['sabres_correntes_pinhoes_limas', 'correntes'],
            'ferramenta': ['ferramentas'],
            'epi': ['epis', 'equipamento de proteção']
        }
        
        # Sinônimos para melhorar a busca
        self.synonyms = {
            'barato': ['economico', 'baixo custo', 'em conta'],
            'caro': ['premium', 'alto custo', 'profissional'],
            'leve': ['compacto', 'portatil', 'manusear'],
            'potente': ['forte', 'alta potencia', 'robusto'],
            'domestico': ['casa', 'residencial', 'jardim'],
            'profissional': ['comercial', 'industrial', 'trabalho']
        }

    def _get_db_connection(self):
        """Cria conexão com o banco de dados"""
        return psycopg2.connect(
            self.database_url,
            cursor_factory=RealDictCursor
        )

    def _generate_cache_key(self, query: str, filters: Dict) -> str:
        """Gera chave única para cache baseada na consulta e filtros"""
        cache_data = f"{query}_{json.dumps(filters, sort_keys=True)}"
        return hashlib.md5(cache_data.encode()).hexdigest()

    def _is_cache_valid(self, cache_entry: Dict) -> bool:
        """Verifica se entrada do cache ainda é válida"""
        if not cache_entry:
            return False
        
        created_at = cache_entry.get('created_at')
        if not created_at:
            return False
            
        return datetime.now() - created_at < self.cache_ttl

    def _analyze_search_intent(self, query: str) -> SearchIntent:
        """
        Analisa a intenção de busca usando GPT-4
        
        Args:
            query: Consulta em linguagem natural
            
        Returns:
            SearchIntent: Objeto com a intenção analisada
        """
        try:
            system_prompt = """
            Você é um especialista em análise de consultas para produtos STIHL.
            Analise a consulta do usuário e extraia as seguintes informações:
            
            1. Tipo de busca (PRODUCT_SEARCH, PRICE_RANGE, COMPATIBILITY, RECOMMENDATION)
            2. Categoria do produto (motosserra, roçadeira, peça, acessório, etc.)
            3. Nome do modelo (se mencionado, ex: MS 162, FS 220)
            4. Faixa de preço (se mencionada)
            5. Tipo de uso (doméstico, profissional, poda, etc.)
            6. Palavras-chave importantes
            
            Responda APENAS em formato JSON válido.
            """
            
            user_prompt = f"""
            Consulta: "{query}"
            
            Analise e responda em JSON com esta estrutura:
            {{
                "search_type": "PRODUCT_SEARCH",
                "product_category": "motosserra",
                "model_name": "MS 162",
                "price_min": 1000.0,
                "price_max": 2000.0,
                "usage_type": "domestico",
                "keywords": ["motosserra", "elétrica", "leve"],
                "confidence": 0.85
            }}
            """
            
            response = client.chat.completions.create(
                model="gpt-4",
                messages=[
                    {"role": "system", "content": system_prompt},
                    {"role": "user", "content": user_prompt}
                ],
                temperature=0.1,
                max_tokens=500
            )
            
            # Parse da resposta JSON
            intent_data = json.loads(response.choices[0].message.content)
            
            return SearchIntent(
                search_type=intent_data.get('search_type', 'PRODUCT_SEARCH'),
                product_category=intent_data.get('product_category'),
                model_name=intent_data.get('model_name'),
                price_min=intent_data.get('price_min'),
                price_max=intent_data.get('price_max'),
                usage_type=intent_data.get('usage_type'),
                keywords=intent_data.get('keywords', []),
                confidence=intent_data.get('confidence', 0.5)
            )
            
        except Exception as e:
            print(f"Erro na análise de intenção: {e}")
            # Fallback para análise simples baseada em regex
            return self._simple_intent_analysis(query)

    def _simple_intent_analysis(self, query: str) -> SearchIntent:
        """
        Análise simples de intenção usando regex (fallback)
        
        Args:
            query: Consulta em linguagem natural
            
        Returns:
            SearchIntent: Objeto com a intenção analisada
        """
        query_lower = query.lower()
        
        # Detectar categoria do produto
        product_category = None
        for category, aliases in self.category_mapping.items():
            if any(alias in query_lower for alias in aliases):
                product_category = category
                break
        
        # Detectar modelo específico
        model_patterns = [
            r'ms\s*(\d+)',  # MS 162, MS250, etc.
            r'fs\s*(\d+)',  # FS 220, FS55, etc.
            r'fsa\s*(\d+)', # FSA 45, etc.
            r'fse\s*(\d+)'  # FSE 60, etc.
        ]
        
        model_name = None
        for pattern in model_patterns:
            match = re.search(pattern, query_lower)
            if match:
                model_name = f"{pattern[:2].upper()} {match.group(1)}"
                break
        
        # Detectar faixa de preço
        price_min, price_max = None, None
        price_patterns = [
            r'até\s*r?\$?\s*(\d+(?:\.\d+)?)',
            r'abaixo\s*de\s*r?\$?\s*(\d+(?:\.\d+)?)',
            r'menos\s*de\s*r?\$?\s*(\d+(?:\.\d+)?)'
        ]
        
        for pattern in price_patterns:
            match = re.search(pattern, query_lower)
            if match:
                price_max = float(match.group(1))
                break
        
        # Detectar tipo de uso
        usage_type = None
        if any(word in query_lower for word in ['domestico', 'casa', 'jardim', 'residencial']):
            usage_type = 'domestico'
        elif any(word in query_lower for word in ['profissional', 'comercial', 'trabalho']):
            usage_type = 'profissional'
        elif any(word in query_lower for word in ['poda', 'podar', 'arvore']):
            usage_type = 'poda'
        
        # Extrair palavras-chave
        keywords = [word for word in query_lower.split() if len(word) > 2]
        
        return SearchIntent(
            search_type='PRODUCT_SEARCH',
            product_category=product_category,
            model_name=model_name,
            price_min=price_min,
            price_max=price_max,
            usage_type=usage_type,
            keywords=keywords,
            confidence=0.7
        )

    def search(self, query: str, max_results: int = 20) -> List[SearchResult]:
        """
        Executa busca inteligente principal
        
        Args:
            query: Consulta em linguagem natural
            max_results: Número máximo de resultados
            
        Returns:
            List[SearchResult]: Lista de resultados ordenados por relevância
        """
        # Verificar cache
        cache_key = self._generate_cache_key(query, {'max_results': max_results})
        if cache_key in self.cache and self._is_cache_valid(self.cache[cache_key]):
            return self.cache[cache_key]['results']
        
        # Analisar intenção da busca
        intent = self._analyze_search_intent(query)
        
        # Executar busca no banco de dados
        results = self._execute_database_search(intent, max_results)
        
        # Armazenar no cache
        self.cache[cache_key] = {
            'results': results,
            'created_at': datetime.now()
        }
        
        return results

    def _execute_database_search(self, intent: SearchIntent, max_results: int) -> List[SearchResult]:
        """
        Executa a busca no banco de dados baseada na intenção analisada
        
        Args:
            intent: Intenção de busca analisada
            max_results: Número máximo de resultados
            
        Returns:
            List[SearchResult]: Lista de resultados
        """
        try:
            with self._get_db_connection() as conn:
                with conn.cursor() as cursor:
                    # Usar a função SQL de busca inteligente
                    cursor.execute("""
                        SELECT * FROM intelligent_product_search_v5(%s, %s, %s, %s, %s)
                    """, (
                        ' '.join(intent.keywords) if intent.keywords else None,
                        max_results,
                        intent.price_min,
                        intent.price_max,
                        intent.product_category
                    ))
                    
                    rows = cursor.fetchall()
                    
                    results = []
                    for row in rows:
                        result = SearchResult(
                            source_table=row['source_table'],
                            codigo_material=row['codigo_material'],
                            descricao=row['descricao'],
                            preco_real=float(row['preco_real']) if row['preco_real'] else 0.0,
                            modelos=row['modelos'] or '',
                            categoria_produto=row['categoria_produto'],
                            relevance_score=float(row['relevance_score']) if row['relevance_score'] else 0.0
                        )
                        results.append(result)
                    
                    return results
                    
        except Exception as e:
            print(f"Erro na busca no banco de dados: {e}")
            return []

    def search_by_code(self, material_code: str) -> Optional[SearchResult]:
        """
        Busca produto específico por código de material
        
        Args:
            material_code: Código do material
            
        Returns:
            Optional[SearchResult]: Resultado encontrado ou None
        """
        try:
            with self._get_db_connection() as conn:
                with conn.cursor() as cursor:
                    cursor.execute("""
                        SELECT * FROM get_product_by_code_v5(%s)
                    """, (material_code,))
                    
                    row = cursor.fetchone()
                    
                    if row:
                        return SearchResult(
                            source_table=row['source_table'],
                            codigo_material=row['codigo_material'],
                            descricao=row['descricao'],
                            preco_real=float(row['preco_real']) if row['preco_real'] else 0.0,
                            modelos=row['modelos'] or '',
                            categoria_produto=row['categoria_produto'],
                            relevance_score=1.0,
                            detalhes_tecnicos=row['detalhes_tecnicos']
                        )
                    
                    return None
                    
        except Exception as e:
            print(f"Erro na busca por código: {e}")
            return None

    def get_compatible_products(self, model_name: str) -> List[SearchResult]:
        """
        Busca produtos compatíveis com um modelo específico
        
        Args:
            model_name: Nome do modelo (ex: MS 162, FS 220)
            
        Returns:
            List[SearchResult]: Lista de produtos compatíveis
        """
        try:
            with self._get_db_connection() as conn:
                with conn.cursor() as cursor:
                    cursor.execute("""
                        SELECT * FROM get_compatible_products_v5(%s)
                    """, (model_name,))
                    
                    rows = cursor.fetchall()
                    
                    results = []
                    for row in rows:
                        result = SearchResult(
                            source_table=row['source_table'],
                            codigo_material=row['codigo_material'],
                            descricao=row['descricao'],
                            preco_real=float(row['preco_real']) if row['preco_real'] else 0.0,
                            modelos=row['tipo_compatibilidade'],
                            categoria_produto=row['categoria_produto'],
                            relevance_score=0.8
                        )
                        results.append(result)
                    
                    return results
                    
        except Exception as e:
            print(f"Erro na busca de compatibilidade: {e}")
            return []

    def get_recommendations(self, usage_type: str = 'domestico', 
                          budget_max: Optional[float] = None,
                          product_type: Optional[str] = None) -> List[SearchResult]:
        """
        Obtém recomendações inteligentes baseadas em uso
        
        Args:
            usage_type: Tipo de uso (domestico, profissional, poda)
            budget_max: Orçamento máximo
            product_type: Tipo de produto específico
            
        Returns:
            List[SearchResult]: Lista de recomendações
        """
        try:
            with self._get_db_connection() as conn:
                with conn.cursor() as cursor:
                    cursor.execute("""
                        SELECT * FROM get_product_recommendations_v5(%s, %s, %s)
                    """, (usage_type, budget_max, product_type))
                    
                    rows = cursor.fetchall()
                    
                    results = []
                    for row in rows:
                        result = SearchResult(
                            source_table=row['source_table'],
                            codigo_material=row['codigo_material'],
                            descricao=row['descricao'],
                            preco_real=float(row['preco_real']) if row['preco_real'] else 0.0,
                            modelos=row['motivo_recomendacao'],
                            categoria_produto=row['categoria_produto'],
                            relevance_score=float(row['score_recomendacao']) / 100.0
                        )
                        results.append(result)
                    
                    return results
                    
        except Exception as e:
            print(f"Erro nas recomendações: {e}")
            return []

    def get_campaign_products(self) -> List[Dict]:
        """
        Obtém produtos em campanha com descontos
        
        Returns:
            List[Dict]: Lista de produtos em campanha
        """
        try:
            with self._get_db_connection() as conn:
                with conn.cursor() as cursor:
                    cursor.execute("SELECT * FROM get_campaign_products_v5()")
                    
                    rows = cursor.fetchall()
                    
                    campaigns = []
                    for row in rows:
                        campaign = {
                            'codigo': row['codigo'],
                            'produto': row['produto'],
                            'preco_lista': float(row['preco_lista']) if row['preco_lista'] else 0.0,
                            'preco_campanha': float(row['preco_campanha']) if row['preco_campanha'] else 0.0,
                            'desconto_percentual': float(row['desconto_percentual']) if row['desconto_percentual'] else 0.0,
                            'economia': float(row['economia']) if row['economia'] else 0.0,
                            'parcelas_sem_juros': int(row['parcelas_sem_juros']) if row['parcelas_sem_juros'] else 0
                        }
                        campaigns.append(campaign)
                    
                    return campaigns
                    
        except Exception as e:
            print(f"Erro na busca de campanhas: {e}")
            return []

    def get_price_ranges(self) -> List[Dict]:
        """
        Obtém faixas de preço por categoria
        
        Returns:
            List[Dict]: Estatísticas de preço por categoria
        """
        try:
            with self._get_db_connection() as conn:
                with conn.cursor() as cursor:
                    cursor.execute("SELECT * FROM get_price_ranges_by_category_v5()")
                    
                    rows = cursor.fetchall()
                    
                    ranges = []
                    for row in rows:
                        range_data = {
                            'categoria': row['categoria'],
                            'preco_minimo': float(row['preco_minimo']) if row['preco_minimo'] else 0.0,
                            'preco_maximo': float(row['preco_maximo']) if row['preco_maximo'] else 0.0,
                            'preco_medio': float(row['preco_medio']) if row['preco_medio'] else 0.0,
                            'total_produtos': int(row['total_produtos']) if row['total_produtos'] else 0
                        }
                        ranges.append(range_data)
                    
                    return ranges
                    
        except Exception as e:
            print(f"Erro na análise de preços: {e}")
            return []

    def generate_natural_response(self, query: str, results: List[SearchResult]) -> str:
        """
        Gera resposta em linguagem natural baseada nos resultados
        
        Args:
            query: Consulta original do usuário
            results: Resultados da busca
            
        Returns:
            str: Resposta em linguagem natural
        """
        if not results:
            return "Desculpe, não encontrei produtos que correspondam à sua busca. Tente usar termos diferentes ou consulte nosso catálogo completo."
        
        try:
            # Preparar dados dos resultados para o GPT
            results_data = []
            for result in results[:5]:  # Limitar a 5 resultados para o GPT
                results_data.append({
                    'codigo': result.codigo_material,
                    'descricao': result.descricao,
                    'preco': result.preco_real,
                    'categoria': result.categoria_produto,
                    'compatibilidade': result.modelos
                })
            
            system_prompt = """
            Você é um consultor especialista em produtos STIHL. Responda de forma natural e útil,
            incluindo informações sobre preços, compatibilidade e recomendações quando relevante.
            Seja conciso mas informativo. Use um tom profissional mas amigável.
            """
            
            user_prompt = f"""
            Pergunta do cliente: "{query}"
            
            Produtos encontrados:
            {json.dumps(results_data, indent=2, ensure_ascii=False)}
            
            Responda de forma natural, incluindo:
            1. Produto(s) recomendado(s)
            2. Preço(s)
            3. Código(s) do material
            4. Informações de compatibilidade se relevante
            5. Observações úteis
            """
            
            response = client.chat.completions.create(
                model="gpt-4",
                messages=[
                    {"role": "system", "content": system_prompt},
                    {"role": "user", "content": user_prompt}
                ],
                temperature=0.3,
                max_tokens=800
            )
            
            return response.choices[0].message.content
            
        except Exception as e:
            print(f"Erro na geração de resposta natural: {e}")
            # Fallback para resposta simples
            if len(results) == 1:
                result = results[0]
                return f"Encontrei o produto: {result.descricao} (Código: {result.codigo_material}) por R$ {result.preco_real:.2f}. {result.modelos}"
            else:
                return f"Encontrei {len(results)} produtos relacionados à sua busca. O primeiro é: {results[0].descricao} (Código: {results[0].codigo_material}) por R$ {results[0].preco_real:.2f}."

    def clear_cache(self):
        """Limpa o cache de resultados"""
        self.cache.clear()

    def get_cache_stats(self) -> Dict:
        """
        Obtém estatísticas do cache
        
        Returns:
            Dict: Estatísticas do cache
        """
        valid_entries = sum(1 for entry in self.cache.values() if self._is_cache_valid(entry))
        
        return {
            'total_entries': len(self.cache),
            'valid_entries': valid_entries,
            'expired_entries': len(self.cache) - valid_entries,
            'cache_ttl_minutes': self.cache_ttl.total_seconds() / 60
        }

