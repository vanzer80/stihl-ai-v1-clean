"""
Rotas Flask para IA Autônoma de Construção de Banco de Dados STIHL
"""

import os
import json
from flask import Blueprint, request, jsonify, current_app
from werkzeug.utils import secure_filename
from src.models.stihl_ai import STIHLAIBuilder
import logging

# Configurar logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

ai_builder_bp = Blueprint('ai_builder', __name__)

# Configurações
UPLOAD_FOLDER = '/tmp/uploads'
ALLOWED_EXTENSIONS = {'xlsx', 'xls', 'csv'}
MAX_FILE_SIZE = 50 * 1024 * 1024  # 50MB

# Criar pasta de upload se não existir
os.makedirs(UPLOAD_FOLDER, exist_ok=True)

def allowed_file(filename):
    """Verifica se o arquivo é permitido"""
    return '.' in filename and \
           filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

@ai_builder_bp.route('/health', methods=['GET'])
def health_check():
    """Verificação de saúde da API"""
    return jsonify({
        'status': 'healthy',
        'service': 'STIHL AI Builder',
        'version': '1.0.0'
    })

@ai_builder_bp.route('/analyze-excel', methods=['POST'])
def analyze_excel():
    """
    Analisa a estrutura de um arquivo Excel
    """
    try:
        # Verificar se arquivo foi enviado
        if 'file' not in request.files:
            return jsonify({
                'success': False,
                'error': 'Nenhum arquivo foi enviado'
            }), 400
        
        file = request.files['file']
        
        if file.filename == '':
            return jsonify({
                'success': False,
                'error': 'Nenhum arquivo selecionado'
            }), 400
        
        if not allowed_file(file.filename):
            return jsonify({
                'success': False,
                'error': 'Tipo de arquivo não permitido. Use .xlsx, .xls ou .csv'
            }), 400
        
        # Salvar arquivo temporariamente
        filename = secure_filename(file.filename)
        file_path = os.path.join(UPLOAD_FOLDER, filename)
        file.save(file_path)
        
        # Verificar tamanho do arquivo
        if os.path.getsize(file_path) > MAX_FILE_SIZE:
            os.remove(file_path)
            return jsonify({
                'success': False,
                'error': f'Arquivo muito grande. Máximo permitido: {MAX_FILE_SIZE // (1024*1024)}MB'
            }), 400
        
        # Inicializar IA Builder
        ai_builder = STIHLAIBuilder()
        
        # Analisar estrutura
        analysis_result = ai_builder.analyze_excel_structure(file_path)
        
        # Limpar arquivo temporário
        os.remove(file_path)
        
        if analysis_result.success:
            return jsonify({
                'success': True,
                'analysis': analysis_result.data,
                'metadata': analysis_result.metadata
            })
        else:
            return jsonify({
                'success': False,
                'errors': analysis_result.errors
            }), 500
            
    except Exception as e:
        logger.error(f"Erro na análise do Excel: {e}")
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

@ai_builder_bp.route('/extract-data', methods=['POST'])
def extract_data():
    """
    Extrai dados do Excel de forma inteligente
    """
    try:
        # Verificar se arquivo foi enviado
        if 'file' not in request.files:
            return jsonify({
                'success': False,
                'error': 'Nenhum arquivo foi enviado'
            }), 400
        
        file = request.files['file']
        
        if not allowed_file(file.filename):
            return jsonify({
                'success': False,
                'error': 'Tipo de arquivo não permitido'
            }), 400
        
        # Salvar arquivo temporariamente
        filename = secure_filename(file.filename)
        file_path = os.path.join(UPLOAD_FOLDER, filename)
        file.save(file_path)
        
        # Inicializar IA Builder
        ai_builder = STIHLAIBuilder()
        
        # Primeiro analisar estrutura
        analysis_result = ai_builder.analyze_excel_structure(file_path)
        
        if not analysis_result.success:
            os.remove(file_path)
            return jsonify({
                'success': False,
                'errors': analysis_result.errors
            }), 500
        
        # Extrair dados
        extraction_result = ai_builder.extract_data_intelligently(file_path, analysis_result)
        
        # Limpar arquivo temporário
        os.remove(file_path)
        
        if extraction_result.success:
            return jsonify({
                'success': True,
                'data': extraction_result.data,
                'metadata': extraction_result.metadata
            })
        else:
            return jsonify({
                'success': False,
                'errors': extraction_result.errors
            }), 500
            
    except Exception as e:
        logger.error(f"Erro na extração de dados: {e}")
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

@ai_builder_bp.route('/generate-sql', methods=['POST'])
def generate_sql():
    """
    Gera scripts SQL baseados nos dados extraídos
    """
    try:
        data = request.get_json()
        
        if not data or 'extracted_data' not in data:
            return jsonify({
                'success': False,
                'error': 'Dados extraídos não fornecidos'
            }), 400
        
        # Inicializar IA Builder
        ai_builder = STIHLAIBuilder()
        
        # Simular ExtractionResult
        from src.models.stihl_ai import ExtractionResult
        extraction_result = ExtractionResult(
            success=True,
            data=data['extracted_data'],
            errors=[],
            metadata={}
        )
        
        # Gerar scripts SQL
        operations = ai_builder.generate_sql_scripts(extraction_result)
        
        # Converter para formato JSON serializável
        operations_data = []
        for op in operations:
            operations_data.append({
                'operation_type': op.operation_type,
                'description': op.description,
                'dependencies': op.dependencies,
                'sql_script': op.sql_script[:1000] + '...' if len(op.sql_script) > 1000 else op.sql_script,  # Truncar para resposta
                'script_length': len(op.sql_script)
            })
        
        return jsonify({
            'success': True,
            'operations': operations_data,
            'total_operations': len(operations)
        })
        
    except Exception as e:
        logger.error(f"Erro na geração de SQL: {e}")
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

@ai_builder_bp.route('/build-database', methods=['POST'])
def build_database():
    """
    Constrói o banco de dados de forma completamente autônoma
    """
    try:
        # Verificar se arquivo foi enviado
        if 'file' not in request.files:
            return jsonify({
                'success': False,
                'error': 'Nenhum arquivo foi enviado'
            }), 400
        
        file = request.files['file']
        
        # Obter configurações do Supabase do formulário
        supabase_url = request.form.get('supabase_url')
        supabase_key = request.form.get('supabase_key')
        database_url = request.form.get('database_url')
        
        if not database_url:
            return jsonify({
                'success': False,
                'error': 'URL de conexão com banco de dados não fornecida'
            }), 400
        
        if not allowed_file(file.filename):
            return jsonify({
                'success': False,
                'error': 'Tipo de arquivo não permitido'
            }), 400
        
        # Salvar arquivo temporariamente
        filename = secure_filename(file.filename)
        file_path = os.path.join(UPLOAD_FOLDER, filename)
        file.save(file_path)
        
        try:
            # Inicializar IA Builder
            ai_builder = STIHLAIBuilder(supabase_url, supabase_key)
            
            # Construir banco de dados autonomamente
            result = ai_builder.build_database_autonomously(file_path, database_url)
            
            return jsonify(result)
            
        finally:
            # Limpar arquivo temporário
            if os.path.exists(file_path):
                os.remove(file_path)
            
    except Exception as e:
        logger.error(f"Erro na construção autônoma: {e}")
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

@ai_builder_bp.route('/validate-connection', methods=['POST'])
def validate_connection():
    """
    Valida conexão com banco de dados
    """
    try:
        data = request.get_json()
        
        if not data or 'database_url' not in data:
            return jsonify({
                'success': False,
                'error': 'URL de conexão não fornecida'
            }), 400
        
        database_url = data['database_url']
        
        # Tentar conectar
        import psycopg2
        try:
            conn = psycopg2.connect(database_url)
            cursor = conn.cursor()
            
            # Testar consulta simples
            cursor.execute("SELECT version();")
            version = cursor.fetchone()[0]
            
            cursor.close()
            conn.close()
            
            return jsonify({
                'success': True,
                'message': 'Conexão estabelecida com sucesso',
                'database_version': version
            })
            
        except psycopg2.Error as e:
            return jsonify({
                'success': False,
                'error': f'Erro de conexão: {str(e)}'
            }), 400
            
    except Exception as e:
        logger.error(f"Erro na validação de conexão: {e}")
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

@ai_builder_bp.route('/get-sample-data', methods=['GET'])
def get_sample_data():
    """
    Retorna dados de exemplo para demonstração
    """
    try:
        sample_data = {
            'categories': [
                {
                    'id': 'sample-cat-1',
                    'name': 'Motosserras',
                    'slug': 'motosserras',
                    'description': 'Motosserras STIHL para uso profissional'
                }
            ],
            'products': [
                {
                    'id': 'sample-prod-1',
                    'material_code': '1148-200-0249',
                    'name': 'MS 162 Motosserra',
                    'description': 'Motosserra leve para uso doméstico',
                    'brand': 'STIHL',
                    'model': 'MS 162'
                }
            ],
            'technical_specifications': [
                {
                    'id': 'sample-spec-1',
                    'product_id': 'sample-prod-1',
                    'displacement_cc': 30.1,
                    'power_kw': 1.3,
                    'weight_kg': 4.5
                }
            ]
        }
        
        return jsonify({
            'success': True,
            'sample_data': sample_data
        })
        
    except Exception as e:
        logger.error(f"Erro ao obter dados de exemplo: {e}")
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

@ai_builder_bp.route('/export-sql', methods=['POST'])
def export_sql():
    """
    Exporta scripts SQL gerados
    """
    try:
        data = request.get_json()
        
        if not data or 'operations' not in data:
            return jsonify({
                'success': False,
                'error': 'Operações não fornecidas'
            }), 400
        
        # Combinar todos os scripts SQL
        combined_sql = []
        combined_sql.append("-- =====================================================")
        combined_sql.append("-- SCRIPTS SQL GERADOS AUTOMATICAMENTE")
        combined_sql.append("-- Sistema de Busca Inteligente STIHL")
        combined_sql.append("-- =====================================================")
        combined_sql.append("")
        
        for operation in data['operations']:
            combined_sql.append(f"-- {operation['description']}")
            combined_sql.append(operation['sql_script'])
            combined_sql.append("")
        
        sql_content = '\n'.join(combined_sql)
        
        return jsonify({
            'success': True,
            'sql_content': sql_content,
            'filename': 'stihl_database_complete.sql'
        })
        
    except Exception as e:
        logger.error(f"Erro na exportação de SQL: {e}")
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

# Tratamento de erros
@ai_builder_bp.errorhandler(413)
def too_large(e):
    return jsonify({
        'success': False,
        'error': 'Arquivo muito grande'
    }), 413

@ai_builder_bp.errorhandler(500)
def internal_error(e):
    return jsonify({
        'success': False,
        'error': 'Erro interno do servidor'
    }), 500

