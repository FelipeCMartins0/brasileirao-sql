USE brasileirao;

-- mesma ordem das colunas do CSV
DROP TABLE IF EXISTS stg_partida, stg_gol, stg_cartao, stg_estatistica;

CREATE TABLE stg_partida(
	id VARCHAR(10), rodata VARCHAR(5), data VARCHAR(10), hora VARCHAR(5),
	mandante VARCHAR(100), visitante VARCHAR(100),
	formacao_mandante VARCHAR(20), formacao_visitante VARCHAR(20),
	tecnico_mandante VARCHAR(100), tecnico_visitante VARCHAR(100),
	vencedor VARCHAR(100), arena VARCHAR(150),
	mandante_placar VARCHAR(5), visitante_placar VARCHAR(5),
	mandante_estado VARCHAR(5), visitante_estado VARCHAR(5)
);

CREATE TABLE stg_gol(
	partida_id VARCHAR(10), rodata VARCHAR(5), clube VARCHAR(100),
	atleta VARCHAR(150), minuto VARCHAR(10), tipo_de_gol VARCHAR(50)
);

CREATE TABLE stg_cartao(
	partida_id VARCHAR(10), rodata VARCHAR(5), clube VARCHAR(100),
	cartao VARCHAR(20), atleta VARCHAR(150), num_camisa VARCHAR(5),
	posicao VARCHAR(50), minuto VARCHAR(10)
);

CREATE TABLE stg_estatistica(
	partida_id VARCHAR(10), rodata VARCHAR(5), clube VARCHAR(100),
	chutes VARCHAR(5), chutes_no_alvo VARCHAR(5), posse_de_bola VARCHAR(10),
	passes VARCHAR(5), precisao_passes VARCHAR(10), faltas VARCHAR(5),
	cartao_amarelo VARCHAR(5), cartao_vermelho VARCHAR(5),
	impedimentos VARCHAR(5), escanteios VARCHAR(5)
);

-- carga
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/campeonato-brasileiro-full.csv'
INTO TABLE stg_partida CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
IGNORE 1 LINES;

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/campeonato-brasileiro-gols.csv'
INTO TABLE stg_gol CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
IGNORE 1 LINES;

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/campeonato-brasileiro-cartoes.csv'
INTO TABLE stg_cartao CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
IGNORE 1 LINES;

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/campeonato-brasileiro-estatisticas-full.csv'
INTO TABLE stg_estatistica CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
IGNORE 1 LINES;

-- conferência
SELECT 'partida', COUNT(*) FROM stg_partida
UNION ALL SELECT 'gol', COUNT(*) FROM stg_gol
UNION ALL SELECT 'cartao', COUNT(*) FROM stg_cartao
UNION ALL SELECT 'estatistica', COUNT(*) FROM stg_estatistica;