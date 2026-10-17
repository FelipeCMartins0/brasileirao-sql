-- validação da carga: rodar após 01_schema.sql e 02_carga.sql
USE brasileirao;

-- staging: esperado 8785 / 9861 / 20953 / 17570
SELECT 'partida', COUNT(*) FROM stg_partida
UNION ALL SELECT 'gol', COUNT(*) FROM stg_gol
UNION ALL SELECT 'cartao', COUNT(*) FROM stg_cartao
UNION ALL SELECT 'estatistica', COUNT(*) FROM stg_estatistica;

-- tabelas finais: esperado 45 / 8785 / 9861 / 20953 / 17570
SELECT 'clube', COUNT(*) FROM clube
UNION ALL SELECT 'partida', COUNT(*) FROM partida
UNION ALL SELECT 'gol', COUNT(*) FROM gol
UNION ALL SELECT 'cartao', COUNT(*) FROM cartao
UNION ALL SELECT 'estatistica', COUNT(*) FROM estatistica;

-- partidas por temporada: esperado 552 (2003–04), 462 (2005), 380 (2006–24)
-- exceto 2016: 379 (Chapecoense x Atlético-MG não disputada)
SELECT temporada, COUNT(*) FROM partida GROUP BY temporada ORDER BY temporada;

-- datas não convertidas: esperado 0
SELECT COUNT(*) FROM partida WHERE data_partida IS NULL;

-- empates coerentes: as duas colunas devem ser iguais
SELECT
	SUM(vencedor_id IS NULL) AS sem_vencedor,
	SUM(placar_mandante = placar_visitante) AS placar_empate
FROM partida;

-- gols registrados x placar (2014+): esperado 0
SELECT COUNT(*) AS divergentes
FROM (
	SELECT p.id
	FROM partida p
	LEFT JOIN gol g ON g.partida_id = p.id
	WHERE p.temporada >= 2014
	GROUP BY p.id, p.placar_mandante, p.placar_visitante
	HAVING COUNT(g.id) <> p.placar_mandante + p.placar_visitante
) t;

-- tipos de cartão: esperado só Amarelo e Vermelho
SELECT tipo, COUNT(*) FROM cartao GROUP BY tipo;

-- camisas acima de 99: esperado 9 (verificadas, ver README)
SELECT COUNT(*) FROM cartao WHERE num_camisa > 99;

-- estatísticas sem dados (2003–2013 = 9212, + valores "None")
SELECT COUNT(*) FROM estatistica WHERE chutes IS NULL;

-- posse x passes: quem tem mais posse deve ter mais passes; esperado ~90% por temporada
-- (valida que a posse está associada ao time certo; ver consulta 6)
SELECT p.temporada,
	ROUND(100 * AVG((a.posse_bola > b.posse_bola) = (a.passes > b.passes)), 1) AS pct_coerente
FROM estatistica a
JOIN estatistica b ON b.partida_id = a.partida_id AND b.clube_id <> a.clube_id
JOIN partida p ON p.id = a.partida_id
WHERE a.posse_bola <> b.posse_bola AND a.passes <> b.passes
GROUP BY p.temporada
ORDER BY p.temporada;