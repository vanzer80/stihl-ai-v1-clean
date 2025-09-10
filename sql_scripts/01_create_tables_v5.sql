CREATE TABLE IF NOT EXISTS subst_tributaria (
    cod_material VARCHAR(32),
    descricao VARCHAR(36),
    s DECIMAL(12,2),
    t DECIMAL(12,2),
    ncm DECIMAL(12,2),
    PRIMARY KEY (cod_material)
);

CREATE TABLE IF NOT EXISTS outras_maquinas (
    unnamed_2 TEXT,
    codigo_material VARCHAR(13),
    preco_real DECIMAL(12,2),
    qtde_min DECIMAL(12,2),
    descricao VARCHAR(201),
    vazao_maxima_l_h VARCHAR(8),
    pressao_maxima_bar VARCHAR(225),
    pressao_de_trabalho_bar VARCHAR(55),
    potencia_kw VARCHAR(38),
    tipo_de_motor VARCHAR(46),
    peso_kg VARCHAR(13),
    comprimento_da_mangueira_m VARCHAR(26),
    cabecote_da_bomba VARCHAR(8),
    s DECIMAL(12,2),
    t DECIMAL(12,2),
    ipi DECIMAL(12,2),
    ncm_classif_fiscal DECIMAL(12,2),
    cod_barras DECIMAL(12,2),
    PRIMARY KEY (codigo_material)
);

CREATE TABLE IF NOT EXISTS materiais_pdv (
    unnamed_2 TEXT,
    codigo_material VARCHAR(13),
    preco_real DECIMAL(12,2),
    qtde_min INTEGER,
    item VARCHAR(40),
    descricao VARCHAR(157),
    s DECIMAL(12,2),
    t DECIMAL(12,2),
    ipi DECIMAL(12,2),
    classif_fiscal INTEGER,
    codigo_barras INTEGER,
    PRIMARY KEY (codigo_material)
);

CREATE TABLE IF NOT EXISTS outros (
    unnamed_2 TEXT,
    unnamed_4 DECIMAL(12,2),
    codigo_material VARCHAR(13),
    preco_real DECIMAL(12,2),
    qtde_min DECIMAL(12,2),
    descricao TEXT,
    unnamed_9 VARCHAR(31),
    utilizacao VARCHAR(102),
    unnamed_11 VARCHAR(58),
    unnamed_12 VARCHAR(7),
    s DECIMAL(12,2),
    t DECIMAL(12,2),
    ipi DECIMAL(12,2),
    ncm_classif_fiscal DECIMAL(12,2),
    codigo_barras DECIMAL(12,2),
    unnamed_18 DECIMAL(12,2),
    unnamed_19 DECIMAL(12,2),
    PRIMARY KEY (codigo_material)
);

CREATE TABLE IF NOT EXISTS conveniencia (
    unnamed_2 TEXT
);

CREATE TABLE IF NOT EXISTS ferr_basicas (
    descricao TEXT,
    observacao TEXT,
    codigo_stihl TEXT
);

CREATE TABLE IF NOT EXISTS ferramentas (
    codigo_material VARCHAR(13),
    preco_real DECIMAL(12,2),
    qtde_min INTEGER,
    descricao VARCHAR(40),
    modelos VARCHAR(200),
    origem INTEGER,
    t INTEGER,
    ipi DECIMAL(12,2),
    ncm_classif_fiscal INTEGER,
    codigo_barras INTEGER,
    ferramentas_basicas_para_oficina VARCHAR(17),
    PRIMARY KEY (codigo_material)
);

CREATE TABLE IF NOT EXISTS informativo_galoes (
    resolucao_inmetro_141_2019 TEXT
);

CREATE TABLE IF NOT EXISTS autonomia_baterias (
    unnamed_2 TEXT,
    unnamed_3 VARCHAR(30),
    bat_integrada VARCHAR(15),
    bateria_hsa_26 VARCHAR(3),
    as_2 VARCHAR(11),
    ak_10 VARCHAR(15),
    ak_20 VARCHAR(9),
    ak_30_s VARCHAR(9),
    ap_200_s VARCHAR(9),
    ap_300_s VARCHAR(9),
    ap_500_s VARCHAR(6)
);

CREATE TABLE IF NOT EXISTS medidas_correntes (
    codigo_dos_rolos_de_corrente_conforme_o_modelo_da_corrente VARCHAR(40),
    unnamed_3 VARCHAR(13),
    unnamed_4 VARCHAR(13),
    unnamed_5 VARCHAR(13),
    unnamed_6 VARCHAR(13),
    unnamed_7 VARCHAR(13),
    codigo_rolo VARCHAR(16),
    no_de_elos_por_rolo VARCHAR(13),
    no_de_dentes_por_rolo VARCHAR(13),
    ft_pes VARCHAR(22),
    metros DECIMAL(12,2)
);

CREATE TABLE IF NOT EXISTS pecas (
    codigo_material VARCHAR(13),
    preco_real DECIMAL(12,2),
    qtde_min INTEGER,
    descricao VARCHAR(40),
    modelos TEXT,
    origem INTEGER,
    t INTEGER,
    ipi DECIMAL(12,2),
    ncm_classif_fiscal INTEGER,
    codigo_barras INTEGER,
    PRIMARY KEY (codigo_material)
);

CREATE TABLE IF NOT EXISTS cj_corte_fs (
    unnamed_1 TEXT,
    codigo_material VARCHAR(13),
    preco_real DECIMAL(12,2),
    qtde_min DECIMAL(12,2),
    descricao VARCHAR(39),
    modelo VARCHAR(131),
    comentario DECIMAL(12,2),
    s DECIMAL(12,2),
    t DECIMAL(12,2),
    ipi DECIMAL(12,2),
    classif_fiscal DECIMAL(12,2),
    codigo_barras DECIMAL(12,2),
    PRIMARY KEY (codigo_material)
);

CREATE TABLE IF NOT EXISTS sabres_correntes_pinhoes_limas (
    unnamed_1 TEXT,
    codigo_material VARCHAR(13),
    preco_real DECIMAL(12,2),
    qtde_min DECIMAL(12,2),
    descricao VARCHAR(40),
    modelos_maquinas VARCHAR(84),
    origem DECIMAL(12,2),
    t DECIMAL(12,2),
    ipi DECIMAL(12,2),
    ncm_classif_fiscal DECIMAL(12,2),
    codigo_barras DECIMAL(12,2),
    PRIMARY KEY (codigo_material)
);

CREATE TABLE IF NOT EXISTS lancamentos (
    unnamed_2 TEXT,
    unnamed_3 VARCHAR(13),
    unnamed_4 DECIMAL(12,2),
    codigo_material VARCHAR(40),
    preco_real DECIMAL(12,2),
    descricao VARCHAR(48),
    qtde_min DECIMAL(12,2),
    bateria_recomendada VARCHAR(46),
    kit VARCHAR(235),
    tensao_carregador VARCHAR(51),
    tensao_nominal_bateria_v VARCHAR(44),
    sabre VARCHAR(44),
    s INTEGER,
    t INTEGER,
    ipi DECIMAL(12,2),
    ncm_classif_fiscal INTEGER,
    cod_barras INTEGER,
    unnamed_21 TEXT,
    PRIMARY KEY (codigo_material)
);

CREATE TABLE IF NOT EXISTS campanhas_stihl (
    codigo VARCHAR(13),
    produto VARCHAR(57),
    preco_de_lista DECIMAL(12,2),
    preco_de_campanha DECIMAL(12,2),
    desconto_de_campanha VARCHAR(22),
    quantidade_parcelas_sem_juros DECIMAL(12,2),
    PRIMARY KEY (codigo)
);

CREATE TABLE IF NOT EXISTS tabela_dif_icms_f_cd_rs (
    produto_atualizado_novembro_2023 VARCHAR(52),
    rs DECIMAL(12,2),
    sc_pr_sp_mg_rj DECIMAL(12,2),
    unnamed_4 DECIMAL(12,2),
    demais DECIMAL(12,2),
    unnamed_6 DECIMAL(12,2),
    classificacao_fiscal DECIMAL(12,2)
);

CREATE TABLE IF NOT EXISTS tabela_dif_icms_f_cd_pa (
    produto_atualizado_novembro_2023 VARCHAR(52),
    pa DECIMAL(12,2),
    demais DECIMAL(12,2),
    unnamed_4 DECIMAL(12,2),
    classificacao_fiscal DECIMAL(12,2)
);

CREATE TABLE IF NOT EXISTS epis (
    unnamed_1 TEXT,
    codigo_material VARCHAR(13),
    preco_real DECIMAL(12,2),
    qtde_min DECIMAL(12,2),
    descricao VARCHAR(54),
    material VARCHAR(213),
    protecao VARCHAR(173),
    s DECIMAL(12,2),
    t DECIMAL(12,2),
    ipi DECIMAL(12,2),
    ncm_classif_fiscal DECIMAL(12,2),
    cod_ca VARCHAR(45),
    codigo_barras DECIMAL(12,2),
    PRIMARY KEY (codigo_material)
);

CREATE TABLE IF NOT EXISTS tabela_conj_de_corte_fs (
    itens_em_negrito_representam_o_fio_de_corte_disponivel_no_codigo VARCHAR(31),
    codigo_de_referencia VARCHAR(13),
    indicacoes_de_uso VARCHAR(158),
    unnamed_5 VARCHAR(4),
    ferramenta_de_corte VARCHAR(4),
    perfil_do_fio_indicado VARCHAR(1),
    diametro_mm_comprimento_total_m VARCHAR(4),
    unnamed_9 VARCHAR(13),
    unnamed_10 VARCHAR(4),
    unnamed_11 VARCHAR(12),
    impl_km_fs_ka_fs VARCHAR(9),
    fs_38 VARCHAR(13),
    fs_55_r_fs_55_fs_80_fs_85_fs_120_fs_131_fr_220 VARCHAR(1),
    fs_161_fs_221_fs_291_fs_300_fs_351_fs_380_fs_460 VARCHAR(1),
    fsa_45 VARCHAR(1),
    fsa_57 VARCHAR(1),
    fsa_65_fsa_86 VARCHAR(1),
    fse_41 VARCHAR(1),
    fse_60 VARCHAR(1)
);

CREATE TABLE IF NOT EXISTS ms (
    unnamed_2 TEXT,
    codigo_material VARCHAR(13),
    preco_real DECIMAL(12,2),
    qtde_min INTEGER,
    descricao VARCHAR(40),
    cilindrada_cm3 VARCHAR(4),
    pot DECIMAL(12,2),
    unnamed_10 DECIMAL(12,2),
    sabre VARCHAR(6),
    corrente VARCHAR(20),
    unnamed_13 VARCHAR(5),
    unnamed_14 DECIMAL(12,2),
    capacidade_do_tanque_de_combustivel_l VARCHAR(5),
    capacidade_do_tanque_de_oleo_l DECIMAL(12,2),
    peso_kg DECIMAL(12,2),
    s INTEGER,
    t INTEGER,
    ipi DECIMAL(12,2),
    ncm_classif_fiscal INTEGER,
    cod_barras INTEGER,
    PRIMARY KEY (codigo_material)
);

CREATE TABLE IF NOT EXISTS rocadeiras_e_impl (
    unnamed_2 TEXT,
    unnamed_4 DECIMAL(12,2),
    codigo_material VARCHAR(13),
    preco_real DECIMAL(12,2),
    qtde_min DECIMAL(12,2),
    descricao VARCHAR(165),
    cilindrada_cm3 VARCHAR(91),
    pot DECIMAL(12,2),
    unnamed_11 VARCHAR(6),
    peso DECIMAL(12,2),
    conjunto_de_corte VARCHAR(35),
    s DECIMAL(12,2),
    t DECIMAL(12,2),
    ipi DECIMAL(12,2),
    ncm_classif_fiscal DECIMAL(12,2),
    cod_barras DECIMAL(12,2),
    PRIMARY KEY (codigo_material)
);

CREATE TABLE IF NOT EXISTS tabela_dif_icms_f_cd_sp (
    produto_atualizado_novembro_2023 VARCHAR(52),
    sp DECIMAL(12,2),
    sc_pr_rs_mg_rj DECIMAL(12,2),
    unnamed_4 DECIMAL(12,2),
    demais DECIMAL(12,2),
    unnamed_6 DECIMAL(12,2),
    classificacao_fiscal DECIMAL(12,2)
);

CREATE TABLE IF NOT EXISTS cod_alterados (
    codigo_antigo VARCHAR(33),
    codigo_novo VARCHAR(35),
    descricao VARCHAR(47),
    data_alteracao VARCHAR(10),
    unnamed_7 VARCHAR(17)
);

CREATE TABLE IF NOT EXISTS acessorios (
    codigo_material VARCHAR(13),
    preco_real DECIMAL(12,2),
    qtde_min INTEGER,
    descricao VARCHAR(40),
    modelos VARCHAR(129),
    origem INTEGER,
    t INTEGER,
    ipi DECIMAL(12,2),
    ncm_classif_fiscal INTEGER,
    codigo_barras INTEGER,
    PRIMARY KEY (codigo_material)
);

CREATE TABLE IF NOT EXISTS artigos_da_marca (
    codigo_material VARCHAR(13),
    preco_real DECIMAL(12,2),
    qtde_min INTEGER,
    descricao VARCHAR(40),
    modelos VARCHAR(72),
    origem INTEGER,
    t INTEGER,
    ipi DECIMAL(12,2),
    ncm_classif_fiscal INTEGER,
    codigo_barras INTEGER,
    PRIMARY KEY (codigo_material)
);

CREATE TABLE IF NOT EXISTS calculadora (
    referencia INTEGER,
    descricao VARCHAR(45),
    produtos VARCHAR(13),
    descricao_1 VARCHAR(45),
    preco VARCHAR(7),
    observacao VARCHAR(38)
);

CREATE TABLE IF NOT EXISTS tecnologias_stihl (
    unnamed_3 TEXT
);

CREATE TABLE IF NOT EXISTS produtos_a_bateria (
    unnamed_1 TEXT,
    unnamed_2 TEXT,
    unnamed_3 TEXT,
    codigo_material VARCHAR(14),
    preco_real DECIMAL(12,2),
    descricao VARCHAR(48),
    qtde_min DECIMAL(12,2),
    bateria_recomendada VARCHAR(84),
    kit VARCHAR(82),
    tensao_carregador VARCHAR(171),
    tensao_nominal_bateria_v VARCHAR(25),
    sabres_cm VARCHAR(123),
    corrente VARCHAR(44),
    velocidade_da_corrente_m_s VARCHAR(44),
    peso_kg VARCHAR(6),
    s DECIMAL(12,2),
    t DECIMAL(12,2),
    ipi DECIMAL(12,2),
    ncm_classif_fiscal DECIMAL(12,2),
    cod_barras DECIMAL(12,2),
    PRIMARY KEY (codigo_material)
);
