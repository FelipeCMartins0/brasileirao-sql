CREATE DATABASE IF NOT EXISTS brasileirao
CHARACTER SET utf8mb4
COLLATE utf8mb4_0900_ai_ci;
USE brasileirao;

DROP TABLE IF EXISTS gol;
DROP TABLE IF EXISTS cartao;
DROP TABLE IF EXISTS estatistica;
DROP TABLE IF EXISTS partida;
DROP TABLE IF EXISTS clube;

CREATE TABLE clube(
	id INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
	nome VARCHAR(50) NOT NULL,
	estado CHAR(2) NOT NULL,
	CONSTRAINT uq_clube_nome UNIQUE (nome)
);

CREATE TABLE partida(
	id INT UNSIGNED PRIMARY KEY, -- ID vem do CSV
	rodada TINYINT UNSIGNED NOT NULL,
	temporada SMALLINT UNSIGNED NOT NULL,
	data_partida DATE NOT NULL,
	hora TIME NULL,
	mandante_id INT UNSIGNED NOT NULL,
	visitante_id INT UNSIGNED NOT NULL,
	vencedor_id INT UNSIGNED NULL, -- NULL = empate
	placar_mandante TINYINT UNSIGNED NOT NULL,
	placar_visitante TINYINT UNSIGNED NOT NULL,
	arena VARCHAR(100) NULL,
	formacao_mandante VARCHAR(10) NULL,
	formacao_visitante VARCHAR(10) NULL,
	tecnico_mandante VARCHAR(60) NULL,
	tecnico_visitante VARCHAR(60) NULL,
	CONSTRAINT fk_partida_mandante FOREIGN KEY (mandante_id) REFERENCES clube(id),
	CONSTRAINT fk_partida_visitante FOREIGN KEY (visitante_id) REFERENCES clube(id),
	CONSTRAINT fk_partida_vencedor FOREIGN KEY (vencedor_id) REFERENCES clube(id),
	CONSTRAINT ck_partida_times CHECK (mandante_id <> visitante_id),
	INDEX idx_partida_temporada (temporada)
);

CREATE TABLE gol(
	id INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
	partida_id INT UNSIGNED NOT NULL,
	clube_id INT UNSIGNED NOT NULL,
	atleta VARCHAR(80) NOT NULL,
	minuto TINYINT UNSIGNED NOT NULL,
	acrescimo TINYINT UNSIGNED NULL,
	tipo VARCHAR(20) NULL,
	CONSTRAINT fk_gol_partida FOREIGN KEY (partida_id) REFERENCES partida(id),
	CONSTRAINT fk_gol_clube FOREIGN KEY (clube_id) REFERENCES clube(id)
);

CREATE TABLE cartao(
	id INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
	partida_id INT UNSIGNED NOT NULL,
	clube_id INT UNSIGNED NOT NULL,
	tipo VARCHAR(10) NOT NULL,
	atleta VARCHAR(80) NOT NULL,
	num_camisa SMALLINT UNSIGNED NULL,
	posicao VARCHAR(30) NULL,
	minuto TINYINT UNSIGNED NOT NULL,
	acrescimo TINYINT UNSIGNED NULL,
	CONSTRAINT fk_cartao_partida FOREIGN KEY (partida_id) REFERENCES partida(id),
	CONSTRAINT fk_cartao_clube FOREIGN KEY (clube_id) REFERENCES clube(id)
);

CREATE TABLE estatistica(
	partida_id INT UNSIGNED NOT NULL,
	clube_id INT UNSIGNED NOT NULL,
	chutes TINYINT UNSIGNED NULL,
	chutes_no_alvo TINYINT UNSIGNED NULL,
	posse_bola TINYINT UNSIGNED NULL,
	passes SMALLINT UNSIGNED NULL,
	precisao_passes TINYINT UNSIGNED NULL,
	faltas TINYINT UNSIGNED NULL,
	cartao_amarelo TINYINT UNSIGNED NULL,
	cartao_vermelho TINYINT UNSIGNED NULL,
	impedimentos TINYINT UNSIGNED NULL,
	escanteios TINYINT UNSIGNED NULL,
	CONSTRAINT pk_estatistica PRIMARY KEY (partida_id, clube_id),
	CONSTRAINT fk_estatistica_partida FOREIGN KEY (partida_id) REFERENCES partida(id),
	CONSTRAINT fk_estatistica_clube FOREIGN KEY (clube_id) REFERENCES clube(id),
	CONSTRAINT ck_estatistica_posse CHECK (posse_bola <= 100),
	CONSTRAINT ck_estatistica_precisao CHECK (precisao_passes <= 100)
);