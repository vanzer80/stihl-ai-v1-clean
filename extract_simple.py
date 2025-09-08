#!/usr/bin/env python3
"""
Script simplificado para extrair dados da planilha MS
"""

import pandas as pd
import json
import uuid
import re

def extract_ms_data():
    file_path = '/home/ubuntu/upload/ListaSugeridadepreçosJULHO25.xlsx'
    
    # Ler aba MS
    df = pd.read_excel(file_path, sheet_name='MS', header=[6, 7])
    
    print("Colunas disponíveis:")
    for i, col in enumerate(df.columns):
        print(f"{i}: {col}")
    
    # Acessar colunas por índice
    products = []
    
    for idx, row in df.iterrows():
        # Código do material está na coluna 4
        material_code = row.iloc[4] if len(row) > 4 else None
        description = row.iloc[7] if len(row) > 7 else None
        price = row.iloc[5] if len(row) > 5 else None
        
        # Limpar e validar
        if pd.notna(material_code) and pd.notna(description):
            material_code_str = str(material_code).strip()
            description_str = str(description).strip()
            
            # Filtrar linhas de cabeçalho
            if (material_code_str != 'Código Material' and 
                description_str != 'Descrição' and
                material_code_str != 'nan' and
                description_str != 'nan' and
                len(material_code_str) > 5):  # Códigos STIHL têm formato específico
                
                product = {
                    'material_code': material_code_str,
                    'description': description_str,
                    'price': float(price) if pd.notna(price) and str(price).replace('.', '').replace(',', '').isdigit() else None,
                    'displacement_cc': row.iloc[8] if len(row) > 8 else None,
                    'power_kw': row.iloc[9] if len(row) > 9 else None,
                    'power_hp': row.iloc[10] if len(row) > 10 else None,
                    'bar_length': row.iloc[11] if len(row) > 11 else None,
                    'weight_kg': row.iloc[17] if len(row) > 17 else None,
                    'ncm_code': row.iloc[21] if len(row) > 21 else None,
                    'barcode': row.iloc[22] if len(row) > 22 else None
                }
                
                products.append(product)
                print(f"Produto extraído: {material_code_str} - {description_str}")
    
    print(f"\nTotal de produtos extraídos: {len(products)}")
    
    # Salvar em JSON
    with open('/home/ubuntu/ms_products.json', 'w', encoding='utf-8') as f:
        json.dump(products, f, ensure_ascii=False, indent=2, default=str)
    
    return products

if __name__ == "__main__":
    products = extract_ms_data()

