CREATE OR REPLACE
VIEW hs.PontuacoesTitulares AS
SELECT
	-- Planos
	n.id,
	IF(n1.milhasc = 'N' 
	AND n1c.idnota1 > 0,
		0,
		IF(c_comissao.id = 6 AND aa_plan.codgrupo2 = 12 AND n1.codplanoa = 808 AND ccpe.descricao_id IN (1, 2) AND n1.nserie = 0,
			0,
			n1c.pontos
		)
	) as 'pontos'
FROM
	aa_hs.notas1com n1c
LEFT JOIN
	aa_hs.notas n ON n1c.idnota = n.id
LEFT JOIN 
	aa_hs.notas1 n1 ON n1.id = n1c.idnota1 -- Relaciona Produto/Descriçãos com planos
LEFT JOIN 
	aa_hs.planos plan ON plan.codigo = n1c.codplano -- Busca as informações de cadastro dos planos referente a HS
LEFT JOIN 
	controleaa.planos aa_plan ON aa_plan.codigo = plan.cg -- Busca as informações de cadastro dos planos móveis referente a OPERADORA
LEFT JOIN 
	controleclaro.comissao c_comissao on c_comissao.id = n1c.idcomissao	-- Identifica o tipo de atendimento (Ativação, migração, upgrade)
LEFT JOIN 
	hs.controle_celular_planos_tipo ccpe ON ccpe.planos_tipo_id = plan.codigo
WHERE 
	n.tipo = 'V'
	AND c_comissao.milhas = 'S'
	AND (
			(c_comissao.id = 6 AND aa_plan.codgrupo2 = 12 AND n1.codplanoa = 808)
			OR (c_comissao.descricao IN ('Ativação Pós', 'Migração Pré - Pós'))
	)


CREATE OR REPLACE 
VIEW hs.DetalhadoMilhagem AS	
SELECT 
	detal.`Data`,
	detal.`ID`,
	detal.`ID Loja`,
	detal.`ID Vendedor`,
	detal.`ID Cliente`,
	detal.`Produto/Descrição`,
	detal.`Plano`,
	detal.`milhas`,
	detal.`Valor`,
	detal.`Tipo`,
	detal.`Linha`,
	detal.`Quantidade`,
	detal.`Grupo`,
	detal.`IMEI`,
	detal.`Milhas Canceladas`,
	detal.`Classificação`,
	detal.`Pontos`
FROM (
		( 
		SELECT -- Subconsulta de Produto/Descriçãos
			n.`data` as 'Data',
			n.id as 'ID',
			n.codlocal as 'ID Loja',
			n.codvended as 'ID Vendedor',
			n.codmovimen as 'ID Cliente',
			IF( -- Verifica se é Produto/Descrição ou seguro
				n1.codigo = -1,
				n3.descricao,
				prod.descricao
			) as 'Produto/Descrição',
			IF( -- Se for venda de seguro, caracteriza o plano como seguro
				n1.codigo = -1,
				'Seguro',
				NULL
			) as 'Plano',
			IF( -- Torna as milhas negativas em caso de devolução
				n.tipo = 'D',
				-1,
				1
			) * n1.milhas as 'Milhas',
			IF( -- Torna a quantidade negativa em caso de devolução
				n1.tipo = 'V',
				1,
				-1
			) * ((n1.quantidade * n1.preco) - n1.desconto + n1.acrescimo) as 'Valor',
			IF( -- Identifica se a venda é uma subtitutiva para devolução
				n1.tipo = 'V' AND n1.devolvido = 'S',
				'VD',
				n1.tipo
			) as 'Tipo',
			CAST(n1.ntc as UNSIGNED) as 'Linha',
			IF(
				n.tipo = 'D',
				-1,
				1
			) * n1.quantidade as  'Quantidade',
			g.descricao as 'Grupo',
			CAST(n1.nserie as UNSIGNED) as 'IMEI',
			'N' as 'Milhas Canceladas', -- As milhas de Produto/Descriçãos nunca são canceladas
			CASE 
				WHEN prod.descricao IN ('PELICULA AMET NANO HD 3G', 'PELICULA AMET NANO GAMER FOSCA', 'PELICULA AMET GAMER FOSCA') THEN 'Película de Entrada'
				WHEN prod.descricao IN ('PELICULA AMET PRIVACIDADE', 'PELICULA AMET ULTRA  6 CAMADAS') THEN 'Película Premium'
				WHEN g.descricao IN ('ACESSORIOS DIVERSOS', 'CAIXA DE SOM - AUDIO', 'CARREGAMENTO', 'CARTOES DE MEMORIA', 'SMARTWATCH', 'TABLET 3G', 'TABLET WIFI', 'WEARABLES - FONES', 'MODEM/ROTEADOR', 'PROTECAO') THEN 'Acessórios'
				WHEN n1.codigo = -1 THEN 'Seguro'
				WHEN prod.codigo IN (4682, 9395, 10280, 10299) THEN 'CHIP'
				WHEN prod.codgrupo IN (1, 2, 5, 14) THEN 'Smartphone'
				WHEN prod.descricao LIKE 'RECARGA%' THEN 'Recarga'
				ELSE '#VERIFICAR'
			END as 'Classificação',
			NULL as 'Pontos'
		FROM
			aa_hs.notas1 n1 -- Tabela de Produto/Descriçãos da venda
		LEFT JOIN
			aa_hs.notas n ON n1.idnota = n.id -- Tabela com os dados principais da nota (ultilizar para obter dados de loja, Vendedores e Cliente)
		LEFT JOIN	
			aa_hs.clientes c ON c.codigo = n.codmovimen -- Relacionar clientes com nota
		LEFT JOIN 
			aa_hs.notas3 n3 ON n3.idregistro = IF(n1.tipo = 'D', n1.numero, n1.id) -- Relacionar clientes com nota
		LEFT JOIN 
			aa_hs.produtos prod ON prod.codigo = n1.codigo 
		LEFT JOIN
			aa_hs.grupos g ON g.codigo = prod.codgrupo
		WHERE
			n.tipo IN ('V', 'D')
			AND n1.codigo > -2
	) UNION ALL (
		SELECT -- Planos
			n.`data` as 'Data',
			n.id as 'ID',
			n.codlocal as 'ID Loja',
			n.codvended as 'ID Vendedor',
			n.codmovimen as 'ID Cliente',
			IF(
				c_comissao.id = 6
				AND aa_plan.codgrupo2 = 12
				AND n1.codplanoa = 808,
				'Migração Controle - Pós',
				c_comissao.descricao
			) as 'Produto/Descrição', -- Busca o tipo de movimentação do plano (Ativação, UP, Troca de Aparelho...)
			IF(
				c_comissao.servico = '',
					IF(
						n1c.empresa = 1,
						plan.descricao,
						aa_plan.descricao
					),
					c_comissao.servico
			) as 'Plano',
			IF(
				n1.milhasc = 'N'
				AND n1c.idnota > 0,
				0,
				n1c.milhas
			) as 'Milhas',
			NULL as 'Valor',
			IF(
				n1.devolvido = 'S',
				'VD',
				'V'
			) as 'Tipo',
			CAST(n1.ntc as UNSIGNED) as 'Linha',
			1 as 'Quantidade',
			NULL as 'Grupo',
			CAST(n1.nserie as UNSIGNED) as 'IMEI',
			IF(
				n1.milhasc = 'S',
				'N',
				'S'
			) as 'Milhas Canceladas',
			CASE
				WHEN c_comissao.servico <> '' THEN 'Outros'
				WHEN c_comissao.descricao = 'Ativação Pré' THEN 'Ativação - Pré'
				WHEN c_comissao.descricao = 'Troca de Apareho' THEN 'Troca de Apareho'
				WHEN c_comissao.descricao IN ('Ativação Controle', 'Migração Pré - Controle') THEN 'Ativação - Controle'
				WHEN c_comissao.descricao LIKE '%TV%' THEN 'TV'
				WHEN c_comissao.descricao LIKE '%Vírtua%' THEN 'VTA'
				WHEN plan.descricao LIKE '%DEP%' THEN 'Dependente'
				WHEN c_comissao.id = 6 AND aa_plan.codgrupo2 = 12 AND n1.codplanoa = 808 AND n1.nserie > 0 AND ccpe.descricao_id IN (1, 2) THEN 'Migração Controle - Pós Convergente C/ Aparelho'
				WHEN c_comissao.id = 6 AND aa_plan.codgrupo2 = 12 AND n1.codplanoa = 808 AND ccpe.descricao_id IN (1, 2) THEN 'Migração Controle - Pós Convergente S/ Aparelho'
				WHEN c_comissao.id = 6 AND aa_plan.codgrupo2 = 12 AND n1.codplanoa = 808 THEN 'Migração Controle - Pós'
				WHEN c_comissao.descricao IN ('Ativação Pós', 'Migração Pré - Pós') AND n1.nserie > 0 AND ccpe.descricao_id IN (1, 2) THEN 'Ativação - Pós Convergente C/ Aparelho'
				WHEN c_comissao.descricao IN ('Ativação Pós', 'Migração Pré - Pós') AND ccpe.descricao_id IN (1, 2) THEN 'Ativação - Pós Convergente S/ Aparelho'
				WHEN c_comissao.descricao IN ('Ativação Pós', 'Migração Pré - Pós') THEN 'Ativação - Pós'
				WHEN c_comissao.descricao = 'Upgrade de Plano' THEN 'Upgrade de Plano'
				WHEN c_comissao.descricao = 'Troca de Aparelho' THEN 'Troca de Aparelho'
				WHEN c_comissao.descricao = 'Downgrade de Plano' THEN 'Downgrade de Plano'
				ELSE '#VERIFICAR'
			END as 'Classificação',
			IF(n1.milhasc = 'N' AND n1c.idnota1 > 0,
				0, 
				IF(plan.descricao LIKE '%DEP%',
					pt_dep.pontos,
					IF(c_comissao.id = 6 AND aa_plan.codgrupo2 = 12 AND n1.codplanoa = 808 AND ccpe.descricao_id IN (1, 2) AND n1.nserie = 0,
						0,
						n1c.pontos
					)
				)
			) as 'Pontos'
		FROM
			aa_hs.notas1com n1c
		LEFT JOIN
			aa_hs.notas n ON n1c.idnota = n.id 
		LEFT JOIN 
			aa_hs.notas1 n1 ON n1.id = n1c.idnota1 -- Relaciona Produto/Descriçãos com planos
		LEFT JOIN 
			aa_hs.planos plan ON plan.codigo = n1c.codplano -- Busca as informações de cadastro dos planos referente a HS
		LEFT JOIN 
			controleaa.planos aa_plan ON aa_plan.codigo = plan.cg -- Busca as informações de cadastro dos planos móveis referente a OPERADORA
		LEFT JOIN 
			controleclaro.comissao c_comissao on c_comissao.id = n1c.idcomissao -- Identifica o tipo de atendimento (Ativação, migração, upgrade)
		LEFT JOIN
			controleclaro.planos aa_resid on n1c.codplano = aa_resid.codigo -- Busca as informações de pacotes/planos residenciais referente a OPERADORA
		LEFT JOIN 
			hs.PontuacoesTitulares pt_dep ON pt_dep.id = n.id
		LEFT JOIN 
			hs.controle_celular_planos_tipo ccpe ON ccpe.planos_tipo_id = plan.codigo
		WHERE 
			n.tipo = 'V'
			AND c_comissao.milhas = 'S'
	) UNION ALL (
		SELECT -- Devolução de Planos
			n.`data` as 'Data',
			n.id as 'ID',
			n.codlocal as 'ID Loja',
			n.codvended as 'ID Vendedor',
			n.codmovimen as 'ID Cliente',
			c_comissao.descricao as 'Produto/Descrição', -- Busca o tipo de movimentação do plano (Ativação, UP, Troca de Aparelho...)
			IF(
				c_comissao.servico IS NULL,
					IF(
						n1c.empresa = 1,
						plan.descricao,
						aa_resid.descricao
					),
					c_comissao.servico
			) as 'Plano',
			n1c.milhas * -1 as 'Milhas',
			NULL as 'Valor',
			'D' as 'Tipo',
			CAST(n1.ntc as UNSIGNED) as 'Linha',
			-1 as 'Quantidade',
			NULL as 'Grupo',
			CAST(n1.nserie as UNSIGNED) as 'IMEI',
			IF(
				n1.milhasc = 'S',
				'N',
				'S'
			) as 'Milhas Canceladas',
			CASE
				WHEN c_comissao.servico <> '' THEN 'Outros'
				WHEN c_comissao.descricao = 'Ativação Pré' THEN 'Ativação - Pré'
				WHEN c_comissao.descricao = 'Troca de Apareho' THEN 'Troca de Apareho'
				WHEN c_comissao.descricao IN ('Ativação Controle', 'Migração Pré - Controle') THEN 'Ativação - Controle'
				WHEN c_comissao.descricao LIKE '%TV%' THEN 'TV'
				WHEN c_comissao.descricao LIKE '%Vírtua%' THEN 'VTA'
				WHEN plan.descricao LIKE '%DEP%' THEN 'Dependente'
				WHEN c_comissao.id = 6 AND aa_plan.codgrupo2 = 12 AND n1.codplanoa = 808 AND n1.nserie > 0 AND ccpe.descricao_id IN (1, 2) THEN 'Migração Controle - Pós Convergente C/ Aparelho'
				WHEN c_comissao.id = 6 AND aa_plan.codgrupo2 = 12 AND n1.codplanoa = 808 AND ccpe.descricao_id IN (1, 2) THEN 'Migração Controle - Pós Convergente S/ Aparelho'
				WHEN c_comissao.id = 6 AND aa_plan.codgrupo2 = 12 AND n1.codplanoa = 808 THEN 'Migração Controle - Pós'
				WHEN c_comissao.descricao IN ('Ativação Pós', 'Migração Pré - Pós') AND n1.nserie > 0 AND ccpe.descricao_id IN (1, 2) THEN 'Ativação - Pós Convergente C/ Aparelho'
				WHEN c_comissao.descricao IN ('Ativação Pós', 'Migração Pré - Pós') AND ccpe.descricao_id IN (1, 2) THEN 'Ativação - Pós Convergente S/ Aparelho'
				WHEN c_comissao.descricao IN ('Ativação Pós', 'Migração Pré - Pós') THEN 'Ativação - Pós'
				WHEN c_comissao.descricao = 'Upgrade de Plano' THEN 'Upgrade de Plano'
				WHEN c_comissao.descricao = 'Troca de Aparelho' THEN 'Troca de Aparelho'
				WHEN c_comissao.descricao = 'Downgrade de Plano' THEN 'Downgrade de Plano'
				ELSE '#VERIFICAR'
			END as 'Classificação',
			IF( plan.descricao LIKE '%DEP%',
				pt_dep.pontos,
				IF(c_comissao.id = 6 AND aa_plan.codgrupo2 = 12 AND n1.codplanoa = 808 AND ccpe.descricao_id IN (1, 2) AND n1.nserie = 0,
					0,
					n1c.pontos
				)
			) * -1 as 'Pontos'
		FROM
			aa_hs.notas1com n1c
		LEFT JOIN 
			aa_hs.notas1 n1 ON n1.numero = n1c.idnota1 -- Relaciona Produto/Descriçãos com planos
		LEFT JOIN
			aa_hs.notas n ON n1.idnota = n.id 
		LEFT JOIN 
			aa_hs.planos plan ON plan.codigo = n1c.codplano -- Busca as informações de cadastro dos planos referente a HS
		LEFT JOIN 
			controleaa.planos aa_plan ON aa_plan.codigo = plan.cg -- Busca as informações de cadastro dos planos móveis referente a OPERADORA
		LEFT JOIN 
			controleclaro.comissao c_comissao on c_comissao.id = n1c.idcomissao -- Identifica o tipo de atendimento (Ativação, migração, upgrade)
		LEFT JOIN
			controleclaro.planos aa_resid on n1c.codplano = aa_resid.codigo -- Busca as informações de pacotes/planos residenciais referente a OPERADORA
		LEFT JOIN 
			hs.PontuacoesTitulares pt_dep ON pt_dep.id = n.id
		LEFT JOIN 
			hs.controle_celular_planos_tipo ccpe ON ccpe.planos_tipo_id = plan.codigo
		WHERE 
			n1.numero > 0
			AND n1.tipo = 'D'
			AND c_comissao.milhas = 'S'
	)
) as detal
ORDER BY
	detal.`ID`,
	detal.`Data`