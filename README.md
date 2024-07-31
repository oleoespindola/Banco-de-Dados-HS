<div align='center'><img src='https://media.giphy.com/media/EK5nB6wQKKN86j7GWx/giphy.gif?cid=ecf05e47ke7b3v035pgx3ocpwumqryhenbeuyja37etis5f7&ep=v1_stickers_search&rid=giphy.gif&ct=s' width='150px'></div>

# Banco de dados HS 

### **AA_HS**

- **TABELAS**
    - **aa_hs.notas** | Tabela de notas fiscais;
    - **aa_hs.notas1** | Produtos da nota;
    - **aa_hs.notas3** | Utilizo apenas para buscar os seguros Pitzi da nota (quando houver);
    - **aa_hs.clientes** | para os dados dos clientes;
    - **aa_hs.locais** | para as informações de loja que vem direto do sistema:
        - **hs.controle_celular_lojas** | Nomes das lojas formatados;
        - **hs.controle_celular_regionais** | Regionais;
    - **aa_hs.vendedores** | Informações sobre os vendedores;
    - **aa_hs.produtos** | cadastro de produtos
    - **aa_hs.contas1obs** | Observações da NF 
    - **aa_hs.motivoi** | Motivo da invalidação dos planos da nota (quando houver), essas invalidações são realizadas pela garantia de receita;
    - **aa_hs.notas1com** | Planos da NF
    - **aa_hs.planos** | Tabela de cadastro de plano (são cadastros no controle celular que é os sistemas em que laçamos as vendas – Essas são as nomenclaturas de cadastro de planos utilizado pela HS nos atendimentos);
    - **controleaa.planos** | Também é uma tabela de cadastro de planos, mas com as informações da operadora;
    - **controleclaro.comissao** | Uso para as movimentações de planos. Ex: Ativação, migração, upgrade, comissões adicionais...;
    - **controleclaro.planos** | Tabelas de planos residenciais (TV, Internet, Fone);


 - **VIEWS**
    - **aa_hs.RelVenDetalhadoMilhas_BI** | Relaciona várias das tabelas acima para sabermos as informações dos atendimentos;
    - **aa_hs.UtiMetaFeriados** | São os dias que as lojas não abriram;
    - **aa_hs.UtiMetaLocal** | Metas das lojas;
    - **aa_hs.UtiMetaVendedor** | Metas dos vendedores;
    - **aa_hs.UtiPedidoResidencial** | Também reúne algumas tabelas para entendermos as informações do formulário das vendas de serviços seriais;
    - **aa_hs.Uti_ClaroTroca_BI** | Informações de Caro Troca;

#

### **HS**

- **TABELAS**
    - **hs.controle_celular_lojas** | Nomes amigáveis de lojas e e-mails
        - Faz join com a view cad_locais do banco aa_hs
    - **hs.controle_celular_regionais** | Nomes amigáveis de regionais e e-mails

- **VIEWS**
    - **hs.DetalhadoMilhagem** | Semelhante a view `aa_hs.RelVenDetalhadoMilhas_BI`, mas está otimizada para o cálculo de premiação e ranking.
    - **hs.contrRankingClaro** | Ranking de Lojas Claro
    - **hs.PontuacoesTitulares** | É a view `DetalhadoMilhagem` filtrada para exiir apenas os planos titulares