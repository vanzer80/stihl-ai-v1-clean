-- =====================================================
-- SCRIPT DE INSERÇÃO DE DADOS
-- Sistema de Busca Inteligente STIHL
-- =====================================================

-- Inserir categorias principais
INSERT INTO categories (id, name, slug, parent_id, level, sort_order, description, is_active) VALUES
('550e8400-e29b-41d4-a716-446655440001', 'Motosserras', 'motosserras', NULL, 0, 1, 'Motosserras STIHL para uso profissional e doméstico', true),
('550e8400-e29b-41d4-a716-446655440002', 'Motosserras a Combustão', 'motosserras-combustao', '550e8400-e29b-41d4-a716-446655440001', 1, 1, 'Motosserras movidas a combustível', true),
('550e8400-e29b-41d4-a716-446655440003', 'Motosserras Elétricas', 'motosserras-eletricas', '550e8400-e29b-41d4-a716-446655440001', 1, 2, 'Motosserras elétricas com fio', true),
('550e8400-e29b-41d4-a716-446655440004', 'Acessórios para Corte', 'acessorios-corte', NULL, 0, 2, 'Sabres, correntes, pinhões e limas', true),
('550e8400-e29b-41d4-a716-446655440005', 'Sabres', 'sabres', '550e8400-e29b-41d4-a716-446655440004', 1, 1, 'Sabres para motosserras', true),
('550e8400-e29b-41d4-a716-446655440006', 'Correntes', 'correntes', '550e8400-e29b-41d4-a716-446655440004', 1, 2, 'Correntes para motosserras', true),
('550e8400-e29b-41d4-a716-446655440007', 'Roçadeiras e Multifuncionais', 'rocadeiras-multifuncionais', NULL, 0, 3, 'Roçadeiras e equipamentos multifuncionais', true),
('550e8400-e29b-41d4-a716-446655440008', 'Produtos a Bateria', 'produtos-bateria', NULL, 0, 4, 'Equipamentos movidos a bateria', true),
('550e8400-e29b-41d4-a716-446655440009', 'Outras Máquinas', 'outras-maquinas', NULL, 0, 5, 'Outras máquinas e equipamentos STIHL', true),
('550e8400-e29b-41d4-a716-446655440010', 'Acessórios', 'acessorios', NULL, 0, 6, 'Acessórios diversos para equipamentos STIHL', true),
('550e8400-e29b-41d4-a716-446655440011', 'Peças de Reposição', 'pecas-reposicao', NULL, 0, 7, 'Peças de reposição originais STIHL', true),
('550e8400-e29b-41d4-a716-446655440012', 'Equipamentos de Proteção Individual', 'epis', NULL, 0, 8, 'EPIs para uso seguro dos equipamentos', true);

-- Inserir produtos de motosserras baseados nos dados extraídos
INSERT INTO products (id, material_code, name, description, brand, category_id, model, barcode, status, search_keywords) VALUES
('650e8400-e29b-41d4-a716-446655440001', '1148-200-0249', 'MS 162 Motosserra,61PMM3', 'MS 162 Motosserra,61PMM3', 'STIHL', '550e8400-e29b-41d4-a716-446655440002', 'MS 162', '795711989866', 'active', 'MS 162 motosserra stihl combustão pequena leve'),
('650e8400-e29b-41d4-a716-446655440002', '1148-200-0244', 'MS 172 Motosserra,35cm/14",61PMM3', 'MS 172 Motosserra,35cm/14",61PMM3', 'STIHL', '550e8400-e29b-41d4-a716-446655440002', 'MS 172', '795711985431', 'active', 'MS 172 motosserra stihl combustão média'),
('650e8400-e29b-41d4-a716-446655440003', '1148-200-0245', 'MS 172 C-BE Motosserra,35cm/14",61PMM3', 'MS 172 C-BE Motosserra,35cm/14",61PMM3', 'STIHL', '550e8400-e29b-41d4-a716-446655440002', 'MS 172 C-BE', '795711985455', 'active', 'MS 172 C-BE motosserra stihl combustão elastostart'),
('650e8400-e29b-41d4-a716-446655440004', '1148-200-0246', 'MS 182 Motosserra,40cm/16",63PM3', 'MS 182 Motosserra,40cm/16",63PM3', 'STIHL', '550e8400-e29b-41d4-a716-446655440002', 'MS 182', NULL, 'active', 'MS 182 motosserra stihl combustão média potente'),
('650e8400-e29b-41d4-a716-446655440005', '1137-200-0338', 'MS 194 T 3/8"P P Motosserra,30cm/12"', 'MS 194 T 3/8"P P Motosserra,30cm/12"', 'STIHL', '550e8400-e29b-41d4-a716-446655440002', 'MS 194 T', NULL, 'active', 'MS 194 T motosserra stihl combustão poda arborista'),
('650e8400-e29b-41d4-a716-446655440006', '1148-200-0247', 'MS 212 Motosserra,40cm/16",63PM3', 'MS 212 Motosserra,40cm/16",63PM3', 'STIHL', '550e8400-e29b-41d4-a716-446655440002', 'MS 212', NULL, 'active', 'MS 212 motosserra stihl combustão média robusta'),
('650e8400-e29b-41d4-a716-446655440007', '1148-200-0248', 'MS 212 Motosserra,45cm/18",63PM3', 'MS 212 Motosserra,45cm/18",63PM3', 'STIHL', '550e8400-e29b-41d4-a716-446655440002', 'MS 212', NULL, 'active', 'MS 212 motosserra stihl combustão grande sabre'),
('650e8400-e29b-41d4-a716-446655440008', '1123-200-0864', 'MS 250 3/8"P P Motosserra,35cm/14",63PMC', 'MS 250 3/8"P P Motosserra,35cm/14",63PMC', 'STIHL', '550e8400-e29b-41d4-a716-446655440002', 'MS 250', NULL, 'active', 'MS 250 motosserra stihl combustão profissional'),
('650e8400-e29b-41d4-a716-446655440009', '1123-200-0865', 'MS 250 3/8"P P Motosserra,40cm/16",63PMC', 'MS 250 3/8"P P Motosserra,40cm/16",63PMC', 'STIHL', '550e8400-e29b-41d4-a716-446655440002', 'MS 250', NULL, 'active', 'MS 250 motosserra stihl combustão profissional grande'),
('650e8400-e29b-41d4-a716-446655440010', '1121-200-0407', 'MS 260 Motosserra,32cm/13",26RS', 'MS 260 Motosserra,32cm/13",26RS', 'STIHL', '550e8400-e29b-41d4-a716-446655440002', 'MS 260', NULL, 'active', 'MS 260 motosserra stihl combustão profissional potente'),
('650e8400-e29b-41d4-a716-446655440011', '1121-200-0429', 'MS 260 Motosserra,40cm/16",26RS', 'MS 260 Motosserra,40cm/16",26RS', 'STIHL', '550e8400-e29b-41d4-a716-446655440002', 'MS 260', NULL, 'active', 'MS 260 motosserra stihl combustão profissional grande sabre'),
('650e8400-e29b-41d4-a716-446655440012', 'MB01-200-0059', 'MS 363.0 Motosserra,40cm/16",36RS', 'MS 363.0 Motosserra,40cm/16",36RS', 'STIHL', '550e8400-e29b-41d4-a716-446655440002', 'MS 363', NULL, 'active', 'MS 363 motosserra stihl combustão profissional pesada'),
('650e8400-e29b-41d4-a716-446655440013', 'MB01-200-0060', 'MS 363.0 Motosserra,50cm/20",36RS', 'MS 363.0 Motosserra,50cm/20",36RS', 'STIHL', '550e8400-e29b-41d4-a716-446655440002', 'MS 363', NULL, 'active', 'MS 363 motosserra stihl combustão profissional pesada grande'),
('650e8400-e29b-41d4-a716-446655440014', '1119-200-0336', 'MS 382 3/8" R Motosserra,33cm/13",36RS', 'MS 382 3/8" R Motosserra,33cm/13",36RS', 'STIHL', '550e8400-e29b-41d4-a716-446655440002', 'MS 382', NULL, 'active', 'MS 382 motosserra stihl combustão profissional alta performance'),
('650e8400-e29b-41d4-a716-446655440015', '1142-200-0261', 'MS 462 Motosserra,40cm/16",36RS', 'MS 462 Motosserra,40cm/16",36RS', 'STIHL', '550e8400-e29b-41d4-a716-446655440002', 'MS 462', NULL, 'active', 'MS 462 motosserra stihl combustão profissional moderna'),
('650e8400-e29b-41d4-a716-446655440016', '1144-200-0485', 'MS 661 Motosserra,50cm/20",36RS', 'MS 661 Motosserra,50cm/20",36RS', 'STIHL', '550e8400-e29b-41d4-a716-446655440002', 'MS 661', NULL, 'active', 'MS 661 motosserra stihl combustão profissional máxima potência'),
('650e8400-e29b-41d4-a716-446655440017', '1208-200-0308', 'MSE 141 C-Q 127V Serra elétr.,30cm/12"', 'MSE 141 C-Q 127V Serra elétr.,30cm/12"', 'STIHL', '550e8400-e29b-41d4-a716-446655440003', 'MSE 141 C-Q', NULL, 'active', 'MSE 141 motosserra stihl elétrica 127V leve'),
('650e8400-e29b-41d4-a716-446655440018', '1208-200-0309', 'MSE 141 C-Q 220V Serra elétr.,30cm/12"', 'MSE 141 C-Q 220V Serra elétr.,30cm/12"', 'STIHL', '550e8400-e29b-41d4-a716-446655440003', 'MSE 141 C-Q', NULL, 'active', 'MSE 141 motosserra stihl elétrica 220V leve'),
('650e8400-e29b-41d4-a716-446655440019', '1209-200-0173', 'MSE 170 C-BQ 127V Serra elétr., 30cm/12"', 'MSE 170 C-BQ 127V Serra elétr., 30cm/12"', 'STIHL', '550e8400-e29b-41d4-a716-446655440003', 'MSE 170 C-BQ', NULL, 'active', 'MSE 170 motosserra stihl elétrica 127V potente'),
('650e8400-e29b-41d4-a716-446655440020', '1209-200-0174', 'MSE 170 C-BQ 220V Serra elétr., 30cm/12"', 'MSE 170 C-BQ 220V Serra elétr., 30cm/12"', 'STIHL', '550e8400-e29b-41d4-a716-446655440003', 'MSE 170 C-BQ', NULL, 'active', 'MSE 170 motosserra stihl elétrica 220V potente');

-- Inserir especificações técnicas das motosserras
INSERT INTO technical_specifications (id, product_id, displacement_cc, power_kw, power_hp, weight_kg, fuel_tank_capacity_l, oil_tank_capacity_l, bar_length_cm, chain_model, chain_pitch, chain_thickness_mm) VALUES
('750e8400-e29b-41d4-a716-446655440001', '650e8400-e29b-41d4-a716-446655440001', 30.1, 1.3, 1.8, 4.5, 0.396, 0.28, 30, 'Picco Micro Mini', '0.375', 1.1),
('750e8400-e29b-41d4-a716-446655440002', '650e8400-e29b-41d4-a716-446655440002', 31.8, 1.5, 2.0, 4.5, 0.396, 0.28, 35, 'Picco Micro Mini', '3/8', 1.1),
('750e8400-e29b-41d4-a716-446655440003', '650e8400-e29b-41d4-a716-446655440003', 31.8, 1.5, 2.0, 4.8, 0.396, 0.28, 35, 'Picco Micro Mini', '3/8', 1.1),
('750e8400-e29b-41d4-a716-446655440004', '650e8400-e29b-41d4-a716-446655440004', 31.8, 1.5, 2.0, 4.6, 0.396, 0.28, 40, '63PM3', '3/8', 1.3),
('750e8400-e29b-41d4-a716-446655440005', '650e8400-e29b-41d4-a716-446655440005', 31.8, 1.4, 1.9, 3.3, 0.2, 0.15, 30, '3/8"P P', '3/8', 1.1),
('750e8400-e29b-41d4-a716-446655440006', '650e8400-e29b-41d4-a716-446655440006', 35.2, 1.6, 2.2, 4.7, 0.396, 0.28, 40, '63PM3', '3/8', 1.3),
('750e8400-e29b-41d4-a716-446655440007', '650e8400-e29b-41d4-a716-446655440007', 35.2, 1.6, 2.2, 4.7, 0.396, 0.28, 45, '63PM3', '3/8', 1.3),
('750e8400-e29b-41d4-a716-446655440008', '650e8400-e29b-41d4-a716-446655440008', 45.4, 2.3, 3.1, 4.6, 0.47, 0.26, 35, '63PMC', '3/8', 1.3),
('750e8400-e29b-41d4-a716-446655440009', '650e8400-e29b-41d4-a716-446655440009', 45.4, 2.3, 3.1, 4.6, 0.47, 0.26, 40, '63PMC', '3/8', 1.3),
('750e8400-e29b-41d4-a716-446655440010', '650e8400-e29b-41d4-a716-446655440010', 50.2, 2.6, 3.5, 5.2, 0.5, 0.22, 32, '26RS', '0.325', 1.6),
('750e8400-e29b-41d4-a716-446655440011', '650e8400-e29b-41d4-a716-446655440011', 50.2, 2.6, 3.5, 5.2, 0.5, 0.22, 40, '26RS', '0.325', 1.6),
('750e8400-e29b-41d4-a716-446655440012', '650e8400-e29b-41d4-a716-446655440012', 59.0, 3.4, 4.6, 6.4, 0.65, 0.33, 40, '36RS', '3/8', 1.6),
('750e8400-e29b-41d4-a716-446655440013', '650e8400-e29b-41d4-a716-446655440013', 59.0, 3.4, 4.6, 6.4, 0.65, 0.33, 50, '36RS', '3/8', 1.6),
('750e8400-e29b-41d4-a716-446655440014', '650e8400-e29b-41d4-a716-446655440014', 72.2, 4.0, 5.4, 6.6, 0.65, 0.33, 33, '36RS', '3/8', 1.6),
('750e8400-e29b-41d4-a716-446655440015', '650e8400-e29b-41d4-a716-446655440015', 72.2, 4.4, 6.0, 6.0, 0.65, 0.33, 40, '36RS', '3/8', 1.6),
('750e8400-e29b-41d4-a716-446655440016', '650e8400-e29b-41d4-a716-446655440016', 91.1, 5.4, 7.3, 7.4, 0.825, 0.36, 50, '36RS', '3/8', 1.6);

-- Inserir preços dos produtos
INSERT INTO pricing (id, product_id, price_type, price_value, currency, minimum_quantity, is_active) VALUES
('850e8400-e29b-41d4-a716-446655440001', '650e8400-e29b-41d4-a716-446655440001', 'suggested_retail', 1199.00, 'BRL', 1, true),
('850e8400-e29b-41d4-a716-446655440002', '650e8400-e29b-41d4-a716-446655440002', 'suggested_retail', 1399.00, 'BRL', 1, true),
('850e8400-e29b-41d4-a716-446655440003', '650e8400-e29b-41d4-a716-446655440003', 'suggested_retail', 1498.99, 'BRL', 1, true),
('850e8400-e29b-41d4-a716-446655440004', '650e8400-e29b-41d4-a716-446655440004', 'suggested_retail', 1599.00, 'BRL', 1, true),
('850e8400-e29b-41d4-a716-446655440005', '650e8400-e29b-41d4-a716-446655440005', 'suggested_retail', 1899.00, 'BRL', 1, true),
('850e8400-e29b-41d4-a716-446655440006', '650e8400-e29b-41d4-a716-446655440006', 'suggested_retail', 1799.00, 'BRL', 1, true),
('850e8400-e29b-41d4-a716-446655440007', '650e8400-e29b-41d4-a716-446655440007', 'suggested_retail', 1899.00, 'BRL', 1, true),
('850e8400-e29b-41d4-a716-446655440008', '650e8400-e29b-41d4-a716-446655440008', 'suggested_retail', 2299.00, 'BRL', 1, true),
('850e8400-e29b-41d4-a716-446655440009', '650e8400-e29b-41d4-a716-446655440009', 'suggested_retail', 2399.00, 'BRL', 1, true),
('850e8400-e29b-41d4-a716-446655440010', '650e8400-e29b-41d4-a716-446655440010', 'suggested_retail', 2899.00, 'BRL', 1, true),
('850e8400-e29b-41d4-a716-446655440011', '650e8400-e29b-41d4-a716-446655440011', 'suggested_retail', 2999.00, 'BRL', 1, true),
('850e8400-e29b-41d4-a716-446655440012', '650e8400-e29b-41d4-a716-446655440012', 'suggested_retail', 4299.00, 'BRL', 1, true),
('850e8400-e29b-41d4-a716-446655440013', '650e8400-e29b-41d4-a716-446655440013', 'suggested_retail', 4499.00, 'BRL', 1, true),
('850e8400-e29b-41d4-a716-446655440014', '650e8400-e29b-41d4-a716-446655440014', 'suggested_retail', 5299.00, 'BRL', 1, true),
('850e8400-e29b-41d4-a716-446655440015', '650e8400-e29b-41d4-a716-446655440015', 'suggested_retail', 6299.00, 'BRL', 1, true),
('850e8400-e29b-41d4-a716-446655440016', '650e8400-e29b-41d4-a716-446655440016', 'suggested_retail', 8999.00, 'BRL', 1, true),
('850e8400-e29b-41d4-a716-446655440017', '650e8400-e29b-41d4-a716-446655440017', 'suggested_retail', 899.00, 'BRL', 1, true),
('850e8400-e29b-41d4-a716-446655440018', '650e8400-e29b-41d4-a716-446655440018', 'suggested_retail', 899.00, 'BRL', 1, true),
('850e8400-e29b-41d4-a716-446655440019', '650e8400-e29b-41d4-a716-446655440019', 'suggested_retail', 1199.00, 'BRL', 1, true),
('850e8400-e29b-41d4-a716-446655440020', '650e8400-e29b-41d4-a716-446655440020', 'suggested_retail', 1199.00, 'BRL', 1, true);

-- Inserir informações fiscais
INSERT INTO tax_information (id, product_id, ncm_code, ipi_rate) VALUES
('950e8400-e29b-41d4-a716-446655440001', '650e8400-e29b-41d4-a716-446655440001', '84678100', 5.2),
('950e8400-e29b-41d4-a716-446655440002', '650e8400-e29b-41d4-a716-446655440002', '84678100', 5.2),
('950e8400-e29b-41d4-a716-446655440003', '650e8400-e29b-41d4-a716-446655440003', '84678100', 5.2),
('950e8400-e29b-41d4-a716-446655440004', '650e8400-e29b-41d4-a716-446655440004', '84678100', 5.2),
('950e8400-e29b-41d4-a716-446655440005', '650e8400-e29b-41d4-a716-446655440005', '84678100', 5.2),
('950e8400-e29b-41d4-a716-446655440006', '650e8400-e29b-41d4-a716-446655440006', '84678100', 5.2),
('950e8400-e29b-41d4-a716-446655440007', '650e8400-e29b-41d4-a716-446655440007', '84678100', 5.2),
('950e8400-e29b-41d4-a716-446655440008', '650e8400-e29b-41d4-a716-446655440008', '84678100', 5.2),
('950e8400-e29b-41d4-a716-446655440009', '650e8400-e29b-41d4-a716-446655440009', '84678100', 5.2),
('950e8400-e29b-41d4-a716-446655440010', '650e8400-e29b-41d4-a716-446655440010', '84678100', 5.2),
('950e8400-e29b-41d4-a716-446655440011', '650e8400-e29b-41d4-a716-446655440011', '84678100', 5.2),
('950e8400-e29b-41d4-a716-446655440012', '650e8400-e29b-41d4-a716-446655440012', '84678100', 5.2),
('950e8400-e29b-41d4-a716-446655440013', '650e8400-e29b-41d4-a716-446655440013', '84678100', 5.2),
('950e8400-e29b-41d4-a716-446655440014', '650e8400-e29b-41d4-a716-446655440014', '84678100', 5.2),
('950e8400-e29b-41d4-a716-446655440015', '650e8400-e29b-41d4-a716-446655440015', '84678100', 5.2),
('950e8400-e29b-41d4-a716-446655440016', '650e8400-e29b-41d4-a716-446655440016', '84678100', 5.2),
('950e8400-e29b-41d4-a716-446655440017', '650e8400-e29b-41d4-a716-446655440017', '85098000', 0.0),
('950e8400-e29b-41d4-a716-446655440018', '650e8400-e29b-41d4-a716-446655440018', '85098000', 0.0),
('950e8400-e29b-41d4-a716-446655440019', '650e8400-e29b-41d4-a716-446655440019', '85098000', 0.0),
('950e8400-e29b-41d4-a716-446655440020', '650e8400-e29b-41d4-a716-446655440020', '85098000', 0.0);

-- Inserir algumas tecnologias STIHL
INSERT INTO stihl_technologies (id, name, description, category, benefits) VALUES
('a50e8400-e29b-41d4-a716-446655440001', 'ElastoStart', 'Sistema de partida suave que reduz o esforço necessário para dar partida', 'Partida', ARRAY['Reduz esforço de partida', 'Maior conforto', 'Menos desgaste do cabo']),
('a50e8400-e29b-41d4-a716-446655440002', 'Anti-Vibração', 'Sistema que reduz significativamente as vibrações transmitidas ao operador', 'Conforto', ARRAY['Reduz fadiga', 'Maior precisão', 'Proteção das articulações']),
('a50e8400-e29b-41d4-a716-446655440003', 'Quick Chain Tensioning', 'Sistema de tensionamento rápido da corrente sem ferramentas', 'Manutenção', ARRAY['Ajuste rápido', 'Sem ferramentas', 'Maior produtividade']),
('a50e8400-e29b-41d4-a716-446655440004', 'M-Tronic', 'Sistema eletrônico de gerenciamento do motor', 'Motor', ARRAY['Partida fácil', 'Otimização automática', 'Menor consumo']),
('a50e8400-e29b-41d4-a716-446655440005', 'Ematic', 'Sistema de lubrificação automática da corrente', 'Lubrificação', ARRAY['Lubrificação otimizada', 'Economia de óleo', 'Maior vida útil da corrente']);

-- Inserir relacionamentos entre produtos (compatibilidades)
INSERT INTO product_relationships (id, product_id, related_product_id, relationship_type, compatibility_notes) VALUES
('b50e8400-e29b-41d4-a716-446655440001', '650e8400-e29b-41d4-a716-446655440002', '650e8400-e29b-41d4-a716-446655440003', 'similar_model', 'Modelos da mesma série MS 172 com diferentes características'),
('b50e8400-e29b-41d4-a716-446655440002', '650e8400-e29b-41d4-a716-446655440008', '650e8400-e29b-41d4-a716-446655440009', 'similar_model', 'Mesmo modelo MS 250 com diferentes tamanhos de sabre'),
('b50e8400-e29b-41d4-a716-446655440003', '650e8400-e29b-41d4-a716-446655440010', '650e8400-e29b-41d4-a716-446655440011', 'similar_model', 'Mesmo modelo MS 260 com diferentes tamanhos de sabre'),
('b50e8400-e29b-41d4-a716-446655440004', '650e8400-e29b-41d4-a716-446655440017', '650e8400-e29b-41d4-a716-446655440018', 'similar_model', 'Mesmo modelo MSE 141 com diferentes voltagens'),
('b50e8400-e29b-41d4-a716-446655440005', '650e8400-e29b-41d4-a716-446655440019', '650e8400-e29b-41d4-a716-446655440020', 'similar_model', 'Mesmo modelo MSE 170 com diferentes voltagens');

-- Inserir uma campanha de exemplo
INSERT INTO campaigns (id, name, description, campaign_type, start_date, end_date, discount_percentage, is_active) VALUES
('c50e8400-e29b-41d4-a716-446655440001', 'Promoção Motosserras Entrada', 'Desconto especial em motosserras de entrada', 'seasonal', '2025-07-01', '2025-09-30', 10.0, true);

-- Inserir produtos na campanha
INSERT INTO campaign_products (id, campaign_id, product_id, special_price) VALUES
('d50e8400-e29b-41d4-a716-446655440001', 'c50e8400-e29b-41d4-a716-446655440001', '650e8400-e29b-41d4-a716-446655440001', 1079.10),
('d50e8400-e29b-41d4-a716-446655440002', 'c50e8400-e29b-41d4-a716-446655440001', '650e8400-e29b-41d4-a716-446655440002', 1259.10),
('d50e8400-e29b-41d4-a716-446655440003', 'c50e8400-e29b-41d4-a716-446655440001', '650e8400-e29b-41d4-a716-446655440017', 809.10),
('d50e8400-e29b-41d4-a716-446655440004', 'c50e8400-e29b-41d4-a716-446655440001', '650e8400-e29b-41d4-a716-446655440018', 809.10);

-- Atualizar timestamps
UPDATE categories SET updated_at = NOW();
UPDATE products SET updated_at = NOW();
UPDATE technical_specifications SET updated_at = NOW();
UPDATE pricing SET updated_at = NOW();
UPDATE tax_information SET updated_at = NOW();

