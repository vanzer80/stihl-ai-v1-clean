"""
Modelo para IA Autônoma de Construção de Banco de dados STIHL
"""

import os
import json
import pandas as pd
import psycopg2
import openai
from typing import Dict, List, Any, Optional, Tuple
from datetime import datetime
import logging
from dataclasses import dataclass
from pathlib import Path
import hashlib
import re

# Configurar logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

@dataclass
class ExtractionResult:
    """Resultado da extração de dados"""
    success: bool
    data: Dict[str, Any]
    errors: List[str]
    metadata: Dict[str, Any]

@dataclass
class DatabaseOperation:
    """Operação de banco de dados"""
    operation_type: str  # 'create_table', 'insert_data', 'create_function', etc.
    sql_script: str
    description: str
    dependencies: List[str]
    success: bool = False
    error_message: Optional[str] = None

class STIHLAIBuilder:
    """
    IA Autônoma para construção de banco de dados STIHL
    """
    
    def __init__(self, supabase_url: str = None, supabase_key: str = None):
        self.supabase_url = supabase_url
        self.supabase_key = supabase_key
        self.openai_client = openai.OpenAI()
        self.operations_log: List[DatabaseOperation] = []
        
        # Configurações padrão
        self.supported_file_types = ['.xlsx', '.xls', '.csv']
        self.max_file_size_mb = 50
        
    def analyze_excel_structure(self, file_path: str) -> ExtractionResult:
        """
        Analisa a estrutura de um arquivo Excel usando IA
        """
        try:
            logger.info(f"Analisando estrutura do arquivo: {file_path}")
            
            # Verificar se arquivo existe
            if not os.path.exists(file_path):
                return ExtractionResult(
                    success=False,
                    data={},
                    errors=[f"Arquivo não encontrado: {file_path}"],
                    metadata={}
                )
            
            # Ler arquivo Excel
            excel_file = pd.ExcelFile(file_path)
            sheet_names = excel_file.sheet_names
            
            analysis_data = {
                'file_info': {
                    'path': file_path,
                    'size_mb': os.path.getsize(file_path) / (1024 * 1024),
                    'sheet_count': len(sheet_names),
                    'sheet_names': sheet_names
                },
                'sheets_analysis': {}
            }
            
            # Analisar cada aba
            for sheet_name in sheet_names:
                try:
                    df = pd.read_excel(file_path, sheet_name=sheet_name, nrows=20)
                    
                    sheet_analysis = {
                        'name': sheet_name,
                        'shape': df.shape,
                        'columns': list(df.columns),
                        'data_types': df.dtypes.to_dict(),
                        'sample_data': df.head(5).to_dict('records'),
                        'null_counts': df.isnull().sum().to_dict(),
                        'estimated_product_count': self._estimate_product_count(df)
                    }
                    
                    analysis_data['sheets_analysis'][sheet_name] = sheet_analysis
                    
                except Exception as e:
                    logger.warning(f"Erro ao analisar aba {sheet_name}: {e}")
                    analysis_data['sheets_analysis'][sheet_name] = {
                        'error': str(e)
                    }
            
            # Usar IA para classificar e entender a estrutura
            ai_analysis = self._ai_analyze_structure(analysis_data)
            analysis_data['ai_insights'] = ai_analysis
            
            return ExtractionResult(
                success=True,
                data=analysis_data,
                errors=[],
                metadata={
                    'analysis_timestamp': datetime.now().isoformat(),
                    'analyzer_version': '1.0'
                }
            )
            
        except Exception as e:
            logger.error(f"Erro na análise da estrutura: {e}")
            return ExtractionResult(
                success=False,
                data={},
                errors=[str(e)],
                metadata={}
            )
    
    def _estimate_product_count(self, df: pd.DataFrame) -> int:
        """Estima o número de produtos em uma aba"""
        # Procurar por colunas que parecem códigos de produto
        code_columns = [col for col in df.columns if 
                       any(keyword in str(col).lower() for keyword in 
                           ['código', 'code', 'material', 'produto', 'item'])]
        
        if code_columns:
            # Contar valores únicos não nulos na primeira coluna de código
            return df[code_columns[0]].dropna().nunique()
        
        # Fallback: contar linhas não completamente vazias
        return len(df.dropna(how='all'))
    
    def _ai_analyze_structure(self, analysis_data: Dict) -> Dict:
        """
        Usa IA para analisar e classificar a estrutura dos dados
        """
        try:
            # Preparar prompt para IA
            prompt = f"""
            Analise a estrutura do seguinte arquivo Excel de produtos STIHL:
            
            Informações do arquivo:
            - Número de abas: {analysis_data['file_info']['sheet_count']}
            - Nomes das abas: {', '.join(analysis_data['file_info']['sheet_names'])}
            
            Análise das abas:
            {json.dumps(analysis_data['sheets_analysis'], indent=2, default=str)}
            
            Por favor, forneça uma análise estruturada em JSON com:
            1. Classificação de cada aba (produtos, acessórios, preços, etc.)
            2. Identificação de colunas-chave (códigos, preços, descrições)
            3. Relacionamentos entre abas
            4. Sugestões de estrutura de banco de dados
            5. Prioridade de processamento das abas
            
            Responda apenas com JSON válido.
            """
            
            response = self.openai_client.chat.completions.create(
                model="gpt-4",
                messages=[
                    {"role": "system", "content": "Você é um especialista em análise de dados e design de banco de dados para catálogos de produtos."},
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
                    return {"error": "Não foi possível parsear resposta da IA", "raw_response": ai_response}
                    
        except Exception as e:
            logger.error(f"Erro na análise por IA: {e}")
            return {"error": str(e)}
    
    def extract_data_intelligently(self, file_path: str, analysis_result: ExtractionResult) -> ExtractionResult:
        """
        Extrai dados do Excel de forma inteligente baseada na análise prévia
        """
        try:
            logger.info("Iniciando extração inteligente de dados")
            
            if not analysis_result.success:
                return ExtractionResult(
                    success=False,
                    data={},
                    errors=["Análise prévia falhou"],
                    metadata={}
                )
            
            ai_insights = analysis_result.data.get('ai_insights', {})
            sheets_analysis = analysis_result.data.get('sheets_analysis', {})
            
            extracted_data = {
                'categories': [],
                'products': [],
                'technical_specifications': [],
                'pricing': [],
                'tax_information': [],
                'product_relationships': [],
                'stihl_technologies': [],
                'campaigns': []
            }
            
            # Processar cada aba baseado na análise da IA
            for sheet_name, sheet_info in sheets_analysis.items():
                if 'error' in sheet_info:
                    continue
                
                logger.info(f"Processando aba: {sheet_name}")
                
                # Determinar tipo de dados da aba
                sheet_type = self._classify_sheet_type(sheet_name, sheet_info, ai_insights)
                
                # Extrair dados baseado no tipo
                if sheet_type == 'products':
                    self._extract_products_data(file_path, sheet_name, extracted_data)
                elif sheet_type == 'accessories':
                    self._extract_accessories_data(file_path, sheet_name, extracted_data)
                elif sheet_type == 'campaigns':
                    self._extract_campaigns_data(file_path, sheet_name, extracted_data)
                elif sheet_type == 'technologies':
                    self._extract_technologies_data(file_path, sheet_name, extracted_data)
            
            return ExtractionResult(
                success=True,
                data=extracted_data,
                errors=[],
                metadata={
                    'extraction_timestamp': datetime.now().isoformat(),
                    'total_products': len(extracted_data['products']),
                    'total_categories': len(extracted_data['categories'])
                }
            )
            
        except Exception as e:
            logger.error(f"Erro na extração inteligente: {e}")
            return ExtractionResult(
                success=False,
                data={},
                errors=[str(e)],
                metadata={}
            )
    
    def _classify_sheet_type(self, sheet_name: str, sheet_info: Dict, ai_insights: Dict) -> str:
        """Classifica o tipo de dados de uma aba"""
        sheet_name_lower = sheet_name.lower()
        
        # Classificação baseada no nome da aba
        if any(keyword in sheet_name_lower for keyword in ['ms', 'motosserra', 'chainsaw']):
            return 'products'
        elif any(keyword in sheet_name_lower for keyword in ['sabre', 'corrente', 'chain', 'bar']):
            return 'accessories'
        elif any(keyword in sheet_name_lower for keyword in ['campanha', 'promo', 'campaign']):
            return 'campaigns'
        elif any(keyword in sheet_name_lower for keyword in ['tecnologia', 'technology', 'tech']):
            return 'technologies'
        elif any(keyword in sheet_name_lower for keyword in ['roça', 'trimmer', 'brush']):
            return 'products'
        elif any(keyword in sheet_name_lower for keyword in ['bateria', 'battery']):
            return 'products'
        else:
            return 'unknown'
    
    def _extract_products_data(self, file_path: str, sheet_name: str, extracted_data: Dict):
        """Extrai dados de produtos de uma aba específica"""
        try:
            # Ler dados da aba
            df = pd.read_excel(file_path, sheet_name=sheet_name, header=[6, 7] if 'MS' in sheet_name else None)
            
            # Processar baseado no tipo de produto
            if 'MS' in sheet_name:
                self._process_chainsaw_data(df, extracted_data, sheet_name)
            else:
                self._process_generic_product_data(df, extracted_data, sheet_name)
                
        except Exception as e:
            logger.error(f"Erro ao extrair dados de produtos da aba {sheet_name}: {e}")
    
    def _process_chainsaw_data(self, df: pd.DataFrame, extracted_data: Dict, sheet_name: str):
        """Processa dados específicos de motosserras"""
        # Implementação similar ao script extract_simple.py
        # Mapear colunas por posição
        column_mapping = {
            4: 'material_code',
            5: 'price',
            7: 'description',
            8: 'displacement_cc',
            9: 'power_kw',
            10: 'power_hp',
            11: 'bar_length',
            17: 'weight_kg',
            21: 'ncm_code',
            22: 'barcode'
        }
        
        # Criar categoria se não existir
        category_id = self._ensure_category(extracted_data, 'Motosserras', 'motosserras')
        
        for idx, row in df.iterrows():
            try:
                material_code = row.iloc[4] if len(row) > 4 else None
                description = row.iloc[7] if len(row) > 7 else None
                
                if pd.notna(material_code) and pd.notna(description):
                    material_code_str = str(material_code).strip()
                    description_str = str(description).strip()
                    
                    # Filtrar linhas de cabeçalho
                    if (material_code_str != 'Código Material' and 
                        description_str != 'Descrição' and
                        len(material_code_str) > 5):
                        
                        # Criar produto
                        product = self._create_product_record(row, column_mapping, category_id)
                        extracted_data['products'].append(product)
                        
                        # Criar especificações técnicas
                        tech_spec = self._create_tech_spec_record(row, column_mapping, product['id'])
                        extracted_data['technical_specifications'].append(tech_spec)
                        
                        # Criar preço
                        pricing = self._create_pricing_record(row, column_mapping, product['id'])
                        if pricing:
                            extracted_data['pricing'].append(pricing)
                        
                        # Criar informações fiscais
                        tax_info = self._create_tax_info_record(row, column_mapping, product['id'])
                        if tax_info:
                            extracted_data['tax_information'].append(tax_info)
                            
            except Exception as e:
                logger.warning(f"Erro ao processar linha {idx}: {e}")
    
    def _ensure_category(self, extracted_data: Dict, name: str, slug: str, parent_id: str = None) -> str:
        """Garante que uma categoria existe, criando se necessário"""
        # Verificar se categoria já existe
        for cat in extracted_data['categories']:
            if cat['slug'] == slug:
                return cat['id']
        
        # Criar nova categoria
        category_id = self._generate_uuid()
        category = {
            'id': category_id,
            'name': name,
            'slug': slug,
            'parent_id': parent_id,
            'level': 0 if parent_id is None else 1,
            'sort_order': len(extracted_data['categories']),
            'description': f'Categoria {name}',
            'is_active': True
        }
        
        extracted_data['categories'].append(category)
        return category_id
    
    def _generate_uuid(self) -> str:
        """Gera UUID único"""
        import uuid
        return str(uuid.uuid4())
    
    def _create_product_record(self, row: pd.Series, column_mapping: Dict, category_id: str) -> Dict:
        """Cria registro de produto"""
        material_code = str(row.iloc[column_mapping['material_code']]).strip()
        description = str(row.iloc[column_mapping['description']]).strip()
        
        # Extrair modelo
        model_match = re.search(r'MS\s*(\d+[A-Z]*(?:-[A-Z]+)*)', description)
        model = model_match.group(0) if model_match else None
        
        return {
            'id': self._generate_uuid(),
            'material_code': material_code,
            'name': description,
            'description': description,
            'brand': 'STIHL',
            'category_id': category_id,
            'model': model,
            'barcode': str(row.iloc[column_mapping.get('barcode', 22)]) if len(row) > 22 else None,
            'status': 'active',
            'search_keywords': f"{model} motosserra stihl" if model else "motosserra stihl"
        }
    
    def _create_tech_spec_record(self, row: pd.Series, column_mapping: Dict, product_id: str) -> Dict:
        """Cria registro de especificações técnicas"""
        return {
            'id': self._generate_uuid(),
            'product_id': product_id,
            'displacement_cc': self._safe_float(row.iloc[column_mapping.get('displacement_cc', 8)]),
            'power_kw': self._safe_float(row.iloc[column_mapping.get('power_kw', 9)]),
            'power_hp': self._safe_float(row.iloc[column_mapping.get('power_hp', 10)]),
            'weight_kg': self._safe_float(row.iloc[column_mapping.get('weight_kg', 17)]),
            'bar_length_cm': self._safe_int(row.iloc[column_mapping.get('bar_length', 11)]),
            'additional_specs': {}
        }
    
    def _create_pricing_record(self, row: pd.Series, column_mapping: Dict, product_id: str) -> Optional[Dict]:
        """Cria registro de preço"""
        price_value = self._safe_float(row.iloc[column_mapping.get('price', 5)])
        
        if price_value:
            return {
                'id': self._generate_uuid(),
                'product_id': product_id,
                'price_type': 'suggested_retail',
                'price_value': price_value,
                'currency': 'BRL',
                'minimum_quantity': 1,
                'is_active': True
            }
        return None
    
    def _create_tax_info_record(self, row: pd.Series, column_mapping: Dict, product_id: str) -> Optional[Dict]:
        """Cria registro de informações fiscais"""
        ncm_code = str(row.iloc[column_mapping.get('ncm_code', 21)]) if len(row) > 21 else None
        
        if ncm_code and ncm_code != 'nan':
            return {
                'id': self._generate_uuid(),
                'product_id': product_id,
                'ncm_code': ncm_code,
                'ipi_rate': 5.2,  # Valor padrão para motosserras
                'tax_substitution_rs': False,
                'tax_substitution_sp': False,
                'tax_substitution_pa': False,
                'tax_regime': 'normal'
            }
        return None
    
    def _safe_float(self, value) -> Optional[float]:
        """Converte valor para float de forma segura"""
        try:
            if pd.notna(value):
                return float(value)
        except (ValueError, TypeError):
            pass
        return None
    
    def _safe_int(self, value) -> Optional[int]:
        """Converte valor para int de forma segura"""
        try:
            if pd.notna(value):
                return int(float(value))
        except (ValueError, TypeError):
            pass
        return None
    
    def _process_generic_product_data(self, df: pd.DataFrame, extracted_data: Dict, sheet_name: str):
        """Processa dados genéricos de produtos"""
        # Implementação básica para outras abas
        logger.info(f"Processamento genérico para aba: {sheet_name}")
    
    def _extract_accessories_data(self, file_path: str, sheet_name: str, extracted_data: Dict):
        """Extrai dados de acessórios"""
        logger.info(f"Extraindo dados de acessórios da aba: {sheet_name}")
    
    def _extract_campaigns_data(self, file_path: str, sheet_name: str, extracted_data: Dict):
        """Extrai dados de campanhas"""
        logger.info(f"Extraindo dados de campanhas da aba: {sheet_name}")
    
    def _extract_technologies_data(self, file_path: str, sheet_name: str, extracted_data: Dict):
        """Extrai dados de tecnologias"""
        logger.info(f"Extraindo dados de tecnologias da aba: {sheet_name}")
    
    def generate_sql_scripts(self, extracted_data: ExtractionResult) -> List[DatabaseOperation]:
        """
        Gera scripts SQL baseados nos dados extraídos
        """
        operations = []
        
        if not extracted_data.success:
            return operations
        
        data = extracted_data.data
        
        # 1. Criar tabelas
        operations.append(DatabaseOperation(
            operation_type='create_tables',
            sql_script=self._load_sql_file('/home/ubuntu/01_create_tables.sql'),
            description='Criação de todas as tabelas do sistema',
            dependencies=[]
        ))
        
        # 2. Criar funções
        operations.append(DatabaseOperation(
            operation_type='create_functions',
            sql_script=self._load_sql_file('/home/ubuntu/02_create_functions.sql'),
            description='Criação de funções especializadas para IA',
            dependencies=['create_tables']
        ))
        
        # 3. Inserir dados
        insert_sql = self._generate_insert_statements(data)
        operations.append(DatabaseOperation(
            operation_type='insert_data',
            sql_script=insert_sql,
            description='Inserção dos dados extraídos',
            dependencies=['create_tables']
        ))
        
        # 4. Configurar segurança
        operations.append(DatabaseOperation(
            operation_type='setup_security',
            sql_script=self._load_sql_file('/home/ubuntu/04_security_rls.sql'),
            description='Configuração de segurança e RLS',
            dependencies=['create_tables', 'create_functions', 'insert_data']
        ))
        
        return operations
    
    def _load_sql_file(self, file_path: str) -> str:
        """Carrega conteúdo de arquivo SQL"""
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                return f.read()
        except Exception as e:
            logger.error(f"Erro ao carregar arquivo SQL {file_path}: {e}")
            return ""
    
    def _generate_insert_statements(self, data: Dict) -> str:
        """Gera statements SQL de inserção baseados nos dados extraídos"""
        sql_parts = []
        
        # Inserir categorias
        if data.get('categories'):
            sql_parts.append("-- Inserir categorias")
            for category in data['categories']:
                sql = f"""
INSERT INTO categories (id, name, slug, parent_id, level, sort_order, description, is_active) 
VALUES ('{category['id']}', '{category['name']}', '{category['slug']}', 
        {f"'{category['parent_id']}'" if category.get('parent_id') else 'NULL'}, 
        {category['level']}, {category['sort_order']}, '{category['description']}', {category['is_active']});
"""
                sql_parts.append(sql)
        
        # Inserir produtos
        if data.get('products'):
            sql_parts.append("\n-- Inserir produtos")
            for product in data['products']:
                sql = f"""
INSERT INTO products (id, material_code, name, description, brand, category_id, model, barcode, status, search_keywords) 
VALUES ('{product['id']}', '{product['material_code']}', '{product['name']}', 
        '{product['description']}', '{product['brand']}', '{product['category_id']}', 
        {f"'{product['model']}'" if product.get('model') else 'NULL'}, 
        {f"'{product['barcode']}'" if product.get('barcode') else 'NULL'}, 
        '{product['status']}', '{product['search_keywords']}');
"""
                sql_parts.append(sql)
        
        # Continuar com outras tabelas...
        
        return '\n'.join(sql_parts)
    
    def execute_database_operations(self, operations: List[DatabaseOperation], 
                                  connection_string: str) -> Tuple[bool, List[str]]:
        """
        Executa operações no banco de dados
        """
        success = True
        errors = []
        
        try:
            # Conectar ao banco
            conn = psycopg2.connect(connection_string)
            cursor = conn.cursor()
            
            # Executar operações em ordem de dependência
            for operation in operations:
                try:
                    logger.info(f"Executando: {operation.description}")
                    
                    # Dividir script em statements individuais
                    statements = self._split_sql_statements(operation.sql_script)
                    
                    for statement in statements:
                        if statement.strip():
                            cursor.execute(statement)
                    
                    conn.commit()
                    operation.success = True
                    logger.info(f"✓ Concluído: {operation.description}")
                    
                except Exception as e:
                    error_msg = f"Erro em {operation.description}: {e}"
                    logger.error(error_msg)
                    errors.append(error_msg)
                    operation.success = False
                    operation.error_message = str(e)
                    success = False
                    conn.rollback()
            
            cursor.close()
            conn.close()
            
        except Exception as e:
            error_msg = f"Erro de conexão com banco de dados: {e}"
            logger.error(error_msg)
            errors.append(error_msg)
            success = False
        
        return success, errors
    
    def _split_sql_statements(self, sql_script: str) -> List[str]:
        """Divide script SQL em statements individuais"""
        # Remover comentários
        lines = []
        for line in sql_script.split('\n'):
            if not line.strip().startswith('--'):
                lines.append(line)
        
        # Dividir por ponto e vírgula
        statements = '\n'.join(lines).split(';')
        return [stmt.strip() for stmt in statements if stmt.strip()]
    
    def build_database_autonomously(self, excel_file_path: str, 
                                  supabase_connection_string: str) -> Dict[str, Any]:
        """
        Constrói o banco de dados de forma completamente autônoma
        """
        logger.info("=== INICIANDO CONSTRUÇÃO AUTÔNOMA DO BANCO DE DADOS ===")
        
        result = {
            'success': False,
            'steps_completed': [],
            'errors': [],
            'metadata': {
                'start_time': datetime.now().isoformat(),
                'file_path': excel_file_path
            }
        }
        
        try:
            # Passo 1: Analisar estrutura do Excel
            logger.info("Passo 1: Analisando estrutura do arquivo Excel")
            analysis_result = self.analyze_excel_structure(excel_file_path)
            
            if not analysis_result.success:
                result['errors'].extend(analysis_result.errors)
                return result
            
            result['steps_completed'].append('analyze_structure')
            
            # Passo 2: Extrair dados inteligentemente
            logger.info("Passo 2: Extraindo dados do arquivo")
            extraction_result = self.extract_data_intelligently(excel_file_path, analysis_result)
            
            if not extraction_result.success:
                result['errors'].extend(extraction_result.errors)
                return result
            
            result['steps_completed'].append('extract_data')
            
            # Passo 3: Gerar scripts SQL
            logger.info("Passo 3: Gerando scripts SQL")
            operations = self.generate_sql_scripts(extraction_result)
            result['steps_completed'].append('generate_sql')
            
            # Passo 4: Executar no banco de dados
            logger.info("Passo 4: Executando scripts no banco de dados")
            db_success, db_errors = self.execute_database_operations(operations, supabase_connection_string)
            
            if db_errors:
                result['errors'].extend(db_errors)
            
            if db_success:
                result['steps_completed'].append('execute_database')
                result['success'] = True
            
            # Adicionar metadados finais
            result['metadata'].update({
                'end_time': datetime.now().isoformat(),
                'total_products': len(extraction_result.data.get('products', [])),
                'total_categories': len(extraction_result.data.get('categories', [])),
                'operations_executed': len([op for op in operations if op.success])
            })
            
            logger.info("=== CONSTRUÇÃO AUTÔNOMA CONCLUÍDA ===")
            
        except Exception as e:
            logger.error(f"Erro na construção autônoma: {e}")
            result['errors'].append(str(e))
        
        return result

