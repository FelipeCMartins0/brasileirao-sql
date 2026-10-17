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
ORDER BY total_por_jogo DESC;

-- 5) Top 3 artilheiros de cada clube (2014–2024)
SELECT clube, atleta, gols
FROM (
	SELECT c.nome AS clube, g.atleta, COUNT(*) AS gols,
		RANK() OVER (PARTITION BY c.nome ORDER BY COUNT(*) DESC) AS posicao
	FROM gol g
	JOIN clube c ON c.id = g.clube_id
	WHERE g.tipo IS NULL OR g.tipo <> 'Gol Contra'
	GROUP BY c.nome, g.atleta
) t
WHERE posicao <= 3
ORDER BY clube, gols DESC;

-- 6) Posse de bola x resultado (2014–2024)
SELECT faixa_posse, COUNT(*) AS jogos,
	ROUND(100 * AVG(gp > gc), 1) AS pct_vitoria,
	ROUND(100 * AVG(gp = gc), 1) AS pct_empate,
	ROUND(100 * AVG(gp < gc), 1) AS pct_derrota
FROM (
	SELECT
		CASE
			WHEN e.posse_bola < 40 THEN '1. menos de 40%'
			WHEN e.posse_bola < 50 THEN '2. 40 a 49%'
			WHEN e.posse_bola < 60 THEN '3. 50 a 59%'
			ELSE '4. 60% ou mais'
		END AS faixa_posse,
		IF(e.clube_id = p.mandante_id, p.placar_mandante, p.placar_visitante) AS gp,
		IF(e.clube_id = p.mandante_id, p.placar_visitante, p.placar_mandante) AS gc
	FROM estatistica e
	JOIN partida p ON p.id = e.partida_id
	WHERE e.posse_bola IS NOT NULL
) t
GROUP BY faixa_posse
ORDER BY faixa_posse;

-- 7) Desempenho nos clássicos estaduais (20 clubes com mais jogos)
WITH top20 AS (
	SELECT clube_id
	FROM (
		SELECT mandante_id AS clube_id FROM partida
		UNION ALL
		SELECT visitante_id FROM partida
	) t
	GROUP BY clube_id
	ORDER BY COUNT(*) DESC
	LIMIT 20
),
jogos AS (
	SELECT mandante_id AS clube_id, visitante_id AS adversario_id,
		placar_mandante AS gp, placar_visitante AS gc
	FROM partida
	UNION ALL
	SELECT visitante_id, mandante_id, placar_visitante, placar_mandante
	FROM partida
)
SELECT c.nome, c.estado,
	COUNT(*) AS jogos,
	SUM(j.gp > j.gc) AS vitorias,
	SUM(j.gp = j.gc) AS empates,
	SUM(j.gp < j.gc) AS derrotas,
	ROUND(100 * SUM(CASE WHEN j.gp > j.gc THEN 3 WHEN j.gp = j.gc THEN 1 ELSE 0 END)
		/ (3 * COUNT(*)), 1) AS aproveitamento
FROM jogos j
JOIN top20 t ON t.clube_id = j.clube_id
JOIN clube c ON c.id = j.clube_id
JOIN clube a ON a.id = j.adversario_id
WHERE c.estado = a.estado          -- mesmo estado = clássico
GROUP BY c.nome, c.estado
HAVING COUNT(*) >= 30        -- mínimo de 30 clássicos
ORDER BY aproveitamento DESC;