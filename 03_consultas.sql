USE brasileirao;

-- 1) Campeão de cada temporada
-- pontos: vitória 3, empate 1; desempate: vitórias, saldo, gols pró
WITH resultados AS (
	-- cada partida vira 2 linhas: uma por clube
	SELECT temporada, mandante_id AS clube_id,
		placar_mandante AS gp, placar_visitante AS gc
	FROM partida
	UNION ALL
	SELECT temporada, visitante_id,
		placar_visitante, placar_mandante
	FROM partida
),
tabela AS (
	SELECT temporada, clube_id,
		SUM(CASE WHEN gp > gc THEN 3 WHEN gp = gc THEN 1 ELSE 0 END) AS pontos,
		SUM(gp > gc) AS vitorias,
		SUM(gp) - SUM(gc) AS saldo,
		SUM(gp) AS gols_pro
	FROM resultados
	GROUP BY temporada, clube_id
),
classificacao AS (
	SELECT t.*,
		ROW_NUMBER() OVER (
			PARTITION BY temporada
			ORDER BY pontos DESC, vitorias DESC, saldo DESC, gols_pro DESC
		) AS posicao
	FROM tabela t
)
SELECT cl.temporada, c.nome AS campeao, cl.pontos, cl.vitorias, cl.saldo
FROM classificacao cl
JOIN clube c ON c.id = cl.clube_id
WHERE cl.posicao = 1
ORDER BY cl.temporada;

-- 2) Top 10 artilheiros (2014–2024)
SELECT atleta, gols
FROM (
	SELECT atleta, COUNT(*) AS gols,
		RANK() OVER (ORDER BY COUNT(*) DESC) AS posicao
	FROM gol
	WHERE tipo IS NULL OR tipo <> 'Gol Contra'
	GROUP BY atleta
) t
WHERE posicao <= 10
ORDER BY gols DESC, atleta;

-- 3) Aproveitamento em casa por temporada
SELECT temporada,
	ROUND(100 * AVG(placar_mandante > placar_visitante), 1) AS pct_vitoria_mandante,
	ROUND(100 * AVG(placar_mandante = placar_visitante), 1) AS pct_empate,
	ROUND(100 * AVG(placar_mandante < placar_visitante), 1) AS pct_vitoria_visitante
FROM partida
GROUP BY temporada
ORDER BY temporada;

-- 4) Cartões por clube (2014-2024): amarelos, vermelhos e total por jogo
WITH jogos AS (
	SELECT clube_id, COUNT(*) AS jogos
	FROM (
		SELECT mandante_id AS clube_id FROM partida WHERE temporada >= 2014
		UNION ALL
		SELECT visitante_id FROM partida WHERE temporada >= 2014
	) j
	GROUP BY clube_id
),
cartoes AS (
	SELECT clube_id,
		SUM(tipo = 'Amarelo') AS amarelos,
		SUM(tipo = 'Vermelho') AS vermelhos,
		COUNT(*) AS total
	FROM cartao
	GROUP BY clube_id
)
SELECT c.nome, j.jogos,
	ca.amarelos, ca.vermelhos, ca.total,
	ROUND(ca.amarelos / j.jogos, 2) AS amarelos_por_jogo,
	ROUND(ca.vermelhos / j.jogos, 2) AS vermelhos_por_jogo,
	ROUND(ca.total / j.jogos, 2) AS total_por_jogo
FROM jogos j
JOIN cartoes ca ON ca.clube_id = j.clube_id
JOIN clube c ON c.id = j.clube_id
WHERE j.jogos >= 100	-- remove clubes com poucas temporadas
ORDER BY total DESC;

-- 5) Top 3 artilheiros de cada clube (2014–2024)
SELECT clube, atleta, gols
FROM (
	SELECT c.nome AS clube, g.atleta, COUNT(*) AS gols,
		RANK() OVER (PARTITION BY c.nome ORDER BY COUNT(*) DESC) AS posicao
	FROM gol g
	JOIN clube c ON c.id = g.clube_id
	WHERE g.tipo IS NULL OR g.tipo <> 'Gol contra'
	GROUP BY c.nome, g.atleta
) t
WHERE posicao <= 3
ORDER BY clube, gols DESC;