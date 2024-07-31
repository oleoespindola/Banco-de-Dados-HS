CREATE OR REPLACE
VIEW hs.RankingClaro as
SELECT 
	ccl.loja_id,
	ccl.loja_nome,
	ccr.regional_nome,
	ROUND(SUM(dm.milhas)) as 'Milhas',
	SUM(IF(dm.`Classificação` IN ('Ativação - Pós', 'Ativação - Pós Convergente C/ Aparelho', 'Ativação Pós rentabilização com Aparelho', 'Ativação - Pós Convergente S/ Aparelho'), dm.pontos, 0)) as 'Pontos - Atv. Pós',
	SUM(IF(dm.`Classificação` IN ('Migração Controle - Pós', 'Migração Controle - Pós Convergente sem Aparelho', 'Migração Controle - Pós Convergente com Aparelho', 'Migração Controle - Pós Convergente S/ Aparelho', 'Migração Controle - Pós Convergente C/ Aparelho'), dm.pontos, 0)) as 'Pontos - Up. Pós',
	SUM(IF(dm.`Classificação` = 'Dependente', dm.pontos, 0)) as 'Pontos - Deps',
	SUM(IF(dm.`Classificação` = 'Ativação - Controle', dm.pontos, 0)) as 'Pontos - Controles',
	SUM(IF(dm.`Classificação` = 'VTA', 1, 0)) as 'VTA',
	SUM(IF(dm.`Classificação` = 'TV', 1, 0)) as 'TV',
	ROUND(SUM(IF(dm.`Classificação` = 'Acessórios', dm.milhas, 0))) as 'Acessórios',
	ROUND(SUM(IF(dm.`Classificação` = 'Seguro', dm.milhas, 0))) as 'Seguros',
	SUM(IF(dm.`Classificação` = 'Película de Entrada', dm.Quantidade , 0)) as 'Películas de Entrada',
	SUM(IF(dm.`Classificação` = 'Película Premium', dm.Quantidade , 0)) as 'Películas Premium',
	SUM(IF(dm.`Classificação` = 'Smartphone', dm.Quantidade, 0)) as 'Smartphones'
FROM
	hs.controle_celular_lojas ccl
JOIN
	hs.controle_celular_regionais ccr ON ccr.regional_id = ccl.regional_id 
JOIN
	hs.DetalhadoMilhagem dm ON dm.`ID Loja` = ccl.loja_id 
JOIN 
	aa_hs.locais l ON l.codigo = dm.`ID Loja`
WHERE
	YEAR(dm.`Data`) = 2024
	AND MONTH(dm.`Data`) = 	7
GROUP BY
	ccl.loja_id
ORDER BY
	ccr.regional_id,
	l.nome
	
SELECT 
	*
FROM 
	hs.RankingClaro