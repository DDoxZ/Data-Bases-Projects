-- -----------------------------------------------------------------------------------------
-- SIBD-2324-G10-E2
-- Afonso Santos - 59808 - T11 - TP16
-- Diogo Lopes - 60447 - T11 - TP16
-- Pedro Silva - 59886 - T11 - TP16
--
-- Contribuições:
-- Em conjunto, discutimos a melhor forma de implementar as tabelas e as constraints. Em seguida, cada um de nós fez a sua implementação individualmente. Por fim, juntámos as nossas implementações e discutimos as diferenças, escolhendo a melhor implementação para cada caso.
--
-- Esforço Individual:
-- Afonso Santos - 33.3%
-- Diogo Lopes - 33.3%
-- Pedro Silva - 33.3%
--
-- RIA suportadas: 2, 5, 10, 11, 12, 15, 16, 17, 18, 19, 20
-- Não suportadas: 1, 3, 4, 6, 7, 8, 9, 13, 14, 21
-- -----------------------------------------------------------------------------------------

DROP TABLE taxis CASCADE CONSTRAINTS;
DROP TABLE periodos CASCADE CONSTRAINTS;
DROP TABLE pessoas CASCADE CONSTRAINTS;
DROP TABLE clientes CASCADE CONSTRAINTS;
DROP TABLE motoristas CASCADE CONSTRAINTS;
DROP TABLE turnos CASCADE CONSTRAINTS;
DROP TABLE viagens CASCADE CONSTRAINTS;
DROP TABLE moradas CASCADE CONSTRAINTS;
DROP TABLE percorre CASCADE CONSTRAINTS;


CREATE TABLE taxis (
    matricula           CHAR(8),
    ano_de_compra       INTEGER,
    marca               VARCHAR(20),
    modelo              VARCHAR(20),
    nivel_de_conforto   VARCHAR(7) NOT NULL,

    CONSTRAINT pk_taxis
        PRIMARY KEY (matricula),

    -- RIA-7
    -- CONSTRAINT ck_taxi_ano_de_compra
        -- Não suportada: Não conseguimos aceder ao ano do turno aqui,

    -- RIA-16
    CONSTRAINT ck_taxi_nivel_de_conforto
        CHECK (nivel_de_conforto IN ('basico', 'luxuoso'))
);

-- -----------------------------------------------------------------------------------------

CREATE TABLE periodos (
    inicio  TIMESTAMP(0) NOT NULL,
    fim     TIMESTAMP(0) NOT NULL,

    CONSTRAINT pk_periodos
        PRIMARY KEY (inicio, fim),

    -- RIA-5
    CONSTRAINT ck_periodos_inicio_fim
        CHECK (inicio < fim)
);

-- -----------------------------------------------------------------------------------------

CREATE TABLE clientes (
    nif NUMBER(9),
    genero  VARCHAR(9) NOT NULL,
    nome    VARCHAR(747),

    CONSTRAINT pk_clientes
        PRIMARY KEY (nif),

    -- RIA-11
    CONSTRAINT ck_clientes_genero
        CHECK (genero IN ('masculino', 'feminino'))
);

-- -----------------------------------------------------------------------------------------

CREATE TABLE moradas (
    id              INTEGER,
    rua             VARCHAR(50),
    numero_da_porta INTEGER,
    codigo_postal   VARCHAR(8),
    localidade      VARCHAR(20),

    CONSTRAINT pk_moradas
        PRIMARY KEY (id),

    -- RIA-15
    CONSTRAINT ck_moradas_id
        CHECK (id >= 1)
);

-- -----------------------------------------------------------------------------------------

CREATE TABLE motoristas (
    nif                 NUMBER(9),
    ano_de_nascimento   INTEGER,
    carta_de_conducao   CHAR(12) UNIQUE NOT NULL, -- RIA-12
    morada_id           INTEGER NOT NULL,
    genero  VARCHAR(9),
    nome    VARCHAR(747),

    -- RIA-6
    -- CONSTRAINT ck_motoristas_ano_de_nascimento
        -- Não suportada: Não conseguimos aceder ao ano atual aqui

    CONSTRAINT pk_motoristas
        PRIMARY KEY (nif),

    CONSTRAINT fk_motoristas_moradas
        FOREIGN KEY (morada_id)
        REFERENCES moradas
        ON DELETE NO ACTION,

    -- RIA-11
    CONSTRAINT ck_motoristas_genero
        CHECK (genero IN ('masculino', 'feminino'))
);

-- -----------------------------------------------------------------------------------------

CREATE TABLE turnos (
    motorista_nif NUMBER(9) NOT NULL,
    taxi_matricula CHAR(8) NOT NULL,
    periodo_inicio TIMESTAMP(0) NOT NULL,
    periodo_fim TIMESTAMP(0) NOT NULL,
    preco_por_minuto REAL NOT NULL,

    -- RIA-8
    -- CONSTRAINT ck_turnos_motorista_periodos
        -- Não suportada: Dois turnos do mesmo motorista ou com o mesmo táxi não podem ter períodos que se intersetem.

    -- RIA-17
    CONSTRAINT ck_turnos_preco_por_minuto
        CHECK (preco_por_minuto > 0),

    CONSTRAINT pk_turnos
        PRIMARY KEY (motorista_nif, taxi_matricula, periodo_inicio, periodo_fim),

    CONSTRAINT fk_turnos_motoristas
        FOREIGN KEY (motorista_nif)
        REFERENCES motoristas,

    CONSTRAINT fk_turnos_taxis
        FOREIGN KEY (taxi_matricula)
        REFERENCES taxis,

    CONSTRAINT fk_turnos_periodos
        FOREIGN KEY (periodo_inicio, periodo_fim)
        REFERENCES periodos
);

-- -----------------------------------------------------------------------------------------

CREATE TABLE viagens (
    sequencia INTEGER,
    motorista_nif NUMBER(9) NOT NULL,
    taxi_matricula CHAR(8) NOT NULL,
    turno_periodo_inicio TIMESTAMP(0) NOT NULL,
    turno_periodo_fim TIMESTAMP(0) NOT NULL,
    periodo_inicio TIMESTAMP(0) NOT NULL,
    periodo_fim TIMESTAMP(0) NOT NULL,
    morada_partida_id INTEGER NOT NULL,
    morada_chegada_id INTEGER NOT NULL,
    numero_de_pessoas INTEGER,

    CONSTRAINT pk_viagens
        PRIMARY KEY (sequencia, motorista_nif, taxi_matricula, turno_periodo_inicio, turno_periodo_fim),

    CONSTRAINT fk_viagens_turno
        FOREIGN KEY (motorista_nif, taxi_matricula, turno_periodo_inicio, turno_periodo_fim)
        REFERENCES turnos
        ON DELETE CASCADE,

    CONSTRAINT fk_viagens_periodo
        FOREIGN KEY (periodo_inicio, periodo_fim)
        REFERENCES periodos
        ON DELETE NO ACTION,

    CONSTRAINT fk_viagens_morada_partida
        FOREIGN KEY (morada_partida_id)
        REFERENCES moradas
        ON DELETE NO ACTION,

    CONSTRAINT fk_viagens_morada_chegada
        FOREIGN KEY (morada_chegada_id)
        REFERENCES moradas
        ON DELETE NO ACTION,
    
    -- RIA-2
    CONSTRAINT ck_viagens_periodo_turno
        CHECK (periodo_inicio >= turno_periodo_inicio AND periodo_fim <= turno_periodo_fim),

    -- RIA-18
    CONSTRAINT ck_viagens_sequencia
        CHECK (sequencia >= 1),

    -- RIA-19
    CONSTRAINT ck_viagens_numero_de_pessoas
        CHECK (numero_de_pessoas >= 1)
);

-- -----------------------------------------------------------------------------------------

CREATE TABLE percorre (
    partida_id              INTEGER NOT NULL,
    chegada_id              INTEGER NOT NULL,
    viagem_sequencia        INTEGER NOT NULL,
    motorista_nif NUMBER(9) NOT NULL,
    taxi_matricula CHAR(8) NOT NULL,
    turno_periodo_inicio TIMESTAMP(0) NOT NULL,
    turno_periodo_fim TIMESTAMP(0) NOT NULL,
    km_percorridos          INTEGER,

    -- RIA-20
    CONSTRAINT ck_percorre_km_percorridos
        CHECK (km_percorridos > 0),

    CONSTRAINT pk_percorre
        PRIMARY KEY (partida_id, chegada_id, viagem_sequencia),

    CONSTRAINT fk_percorre_partida
        FOREIGN KEY (partida_id)
        REFERENCES moradas,

    CONSTRAINT fk_percorre_chegada
        FOREIGN KEY (chegada_id)
        REFERENCES moradas,

    CONSTRAINT fk_percorre_viagens
        FOREIGN KEY (viagem_sequencia, motorista_nif, taxi_matricula, turno_periodo_inicio, turno_periodo_fim)
        REFERENCES viagens
);

-- Exemplos

INSERT INTO taxis (matricula, ano_de_compra, marca, modelo, nivel_de_conforto) 
     VALUES ('AA-00-00', 2010, 'Mercedes', 'C220', 'luxuoso');

INSERT INTO taxis (matricula, ano_de_compra, marca, modelo, nivel_de_conforto)
     VALUES ('BB-11-11', 2015, 'BMW', 'A4', 'basico');

-- -----------------------------------------------------------------------------------------

INSERT INTO periodos (inicio, fim)
     VALUES ('2019-01-01 00:00:00', '2019-01-01 00:20:00');

INSERT INTO periodos (inicio, fim)
     VALUES ('2019-01-01 00:20:00', '2019-01-01 00:40:00');
     
-- -----------------------------------------------------------------------------------------

INSERT INTO clientes (nif, genero, nome)
     VALUES (123456789, 'masculino', 'Afonso');

INSERT INTO clientes (nif, genero, nome)
     VALUES (987654321, 'feminino', 'Diogo');
     
-- -----------------------------------------------------------------------------------------

INSERT INTO moradas (id, rua, numero_da_porta, codigo_postal, localidade)
     VALUES (1, 'Rua 1', 1, '1000-001', 'Lisboa');

INSERT INTO moradas (id, rua, numero_da_porta, codigo_postal, localidade)
     VALUES (2, 'Rua 2', 2, '2000-002', 'Porto');
     
-- -----------------------------------------------------------------------------------------

INSERT INTO motoristas (nif, ano_de_nascimento, carta_de_conducao, morada_id, genero, nome)
     VALUES (121212121, 1990, '123456789123', 1, 'masculino', 'Pedro');

INSERT INTO motoristas (nif, ano_de_nascimento, carta_de_conducao, morada_id, genero, nome)
     VALUES (123789456, 1995, '987654321987', 2, 'feminino', 'Maria');
    
-- -----------------------------------------------------------------------------------------

INSERT INTO turnos (motorista_nif, taxi_matricula, periodo_inicio, periodo_fim, preco_por_minuto)
     VALUES (121212121, 'AA-00-00', '2019-01-01 00:00:00', '2019-01-01 00:20:00', 0.5);

INSERT INTO turnos (motorista_nif, taxi_matricula, periodo_inicio, periodo_fim, preco_por_minuto)
     VALUES (121212121, 'AA-00-00', '2019-01-01 00:20:00', '2019-01-01 00:40:00', 0.5);
     
-- -----------------------------------------------------------------------------------------

INSERT INTO viagens (sequencia, motorista_nif, taxi_matricula, turno_periodo_inicio, turno_periodo_fim, periodo_inicio, periodo_fim, morada_partida_id, morada_chegada_id, numero_de_pessoas)
     VALUES (1, 121212121, 'AA-00-00', '2019-01-01 00:00:00', '2019-01-01 00:20:00', '2019-01-01 00:00:00', '2019-01-01 00:20:00', 1, 2, 1);

INSERT INTO viagens (sequencia, motorista_nif, taxi_matricula, turno_periodo_inicio, turno_periodo_fim, periodo_inicio, periodo_fim, morada_partida_id, morada_chegada_id, numero_de_pessoas)
     VALUES (2, 121212121, 'AA-00-00', '2019-01-01 00:20:00', '2019-01-01 00:40:00', '2019-01-01 00:20:00', '2019-01-01 00:40:00', 2, 1, 1);
      
-- -----------------------------------------------------------------------------------------

INSERT INTO percorre (partida_id, chegada_id, viagem_sequencia, motorista_nif, taxi_matricula, turno_periodo_inicio, turno_periodo_fim, km_percorridos)
     VALUES (1, 2, 1, 121212121, 'AA-00-00', '2019-01-01 00:00:00', '2019-01-01 00:20:00', 10);

INSERT INTO percorre (partida_id, chegada_id, viagem_sequencia, motorista_nif, taxi_matricula, turno_periodo_inicio, turno_periodo_fim, km_percorridos)
     VALUES (2, 1, 2, 121212121, 'AA-00-00', '2019-01-01 00:20:00', '2019-01-01 00:40:00', 10);
     
-- -----------------------------------------------------------------------------------------
