USE brasileirao;

-- tabela de classificação completa de cada temporada
CREATE OR REPLACE VIEW vw_classificacao AS
WITH jogos AS (
	SELECT temporada, mandante_id AS clube_id,
		placar_mandante AS gp, placar_visitante AS gc
	FROM partida
	UNION ALL
	SELECT temporada, visitante_id, placar_visitante, placar_mandante
	FROM partida
),
tabela AS (
	SELECT temporada, clube_id,
		SUM(CASE WHEN gp > gc THEN 3 WHEN gp = gc THEN 1 ELSE 0 END) AS pontos,
		COUNT(*) AS jogos,
		SUM(gp > gc) AS vitorias,
		SUM(gp = gc) AS empates,
		SUM(gp < gc) AS derrotas,
		SUM(gp) AS gols_pro,
		SUM(gc) AS gols_contra,
		SUM(gp) - SUM(gc) AS saldo
	FROM jogos
	GROUP BY temporada, clube_id
)
SELECT t.temporada,
	ROW_NUMBER() OVER (
		PARTITION BY t.temporada
		ORDER BY t.pontos DESC, t.vitorias DESC, t.saldo DESC, t.gols_pro DESC
	) AS posicao,
	c.nome AS clube,
	t.pontos, t.jogos, t.vitorias, t.empates, t.derrotas,
	t.gols_pro, t.gols_contra, t.saldo
FROM tabela t
JOIN clube c ON c.id = t.clube_id;

-- gols por atleta, clube e temporada (sem gols contra)
CREATE OR REPLACE VIEW vw_artilharia AS
SELECT p.temporada, c.nome AS clube, g.atleta, COUNT(*) AS gols
FROM gol g
JOIN partida p ON p.id = g.partida_id
JOIN clube c ON c.id = g.clube_id
WHERE g.tipo IS NULL OR g.tipo <> 'Gol Contra'
GROUP BY p.temporada, c.nome, g.atleta;