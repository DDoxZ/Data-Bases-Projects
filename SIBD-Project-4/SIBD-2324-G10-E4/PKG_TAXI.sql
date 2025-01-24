-- -----------------------------------------------------------------------------------------
-- SIBD-2324-G10-E4
-- Afonso Santos - 59808 - T11 - TP16
-- Diogo Lopes - 60447 - T11 - TP16
-- Pedro Silva - 59886 - T11 - TP16
--
-- Contribuições: Cada membro do grupo contribuiu de forma igualitária para a resolução do trabalho. 
-- Todos os membros do grupo fizeram individualmente a resolução de todos os pontos do projeto, 
-- e no final foi reunida toda a informação e discutida a melhor solução a implementar.
-- 
-- Esforço Individual:
-- Afonso Santos - 33.3%
-- Diogo Lopes - 33.3%
-- Pedro Silva - 33.3%
-- ----------------------------------------------------------------------------

DROP TABLE viagem;
DROP TABLE taxi;
DROP TABLE motorista;

-- ----------------------------------------------------------------------------

CREATE TABLE motorista (
  nif        NUMBER  (9),
  nome       VARCHAR (80) CONSTRAINT nn_motorista_nome       NOT NULL,
  genero     CHAR    (1)  CONSTRAINT nn_motorista_genero     NOT NULL,
  nascimento NUMBER  (4)  CONSTRAINT nn_motorista_nascimento NOT NULL,
  localidade VARCHAR (80) CONSTRAINT nn_motorista_localidade NOT NULL,
--
  CONSTRAINT pk_motorista
    PRIMARY KEY (nif),
--
  CONSTRAINT ck_motorista_nif  -- RIA 10.
    CHECK (nif BETWEEN 100000000 AND 999999999),
--
  CONSTRAINT ck_motorista_genero   -- RIA 11.
    CHECK (genero IN ('F', 'M')),  -- F(eminino), M(asculino).
--
  CONSTRAINT ck_motorista_nascimento  -- Não suporta RIA 6, mas
    CHECK (nascimento > 1900)         -- impede erros básicos.
);

-- ----------------------------------------------------------------------------

CREATE TABLE taxi (
  matricula   VARCHAR (6),
  ano         NUMBER  (4)   CONSTRAINT nn_taxi_ano         NOT NULL,
  marca       VARCHAR (20)  CONSTRAINT nn_taxi_marca       NOT NULL,
  conforto    CHAR    (1)   CONSTRAINT nn_taxi_conforto    NOT NULL,
  eurosminuto NUMBER  (4,2) CONSTRAINT nn_taxi_eurosminuto NOT NULL,
--
  CONSTRAINT pk_taxi
    PRIMARY KEY (matricula),
--
  CONSTRAINT ck_taxi_matricula
    CHECK (LENGTH(matricula) = 6),
--
  CONSTRAINT ck_taxi_ano  -- Não suporta RIA 7, mas
    CHECK (ano > 1900),   -- impede erros básicos.
--
  CONSTRAINT ck_taxi_conforto  -- RIA 16.
    CHECK (conforto IN ('B', 'L')),  -- B(ásico), L(uxuoso).
--
  CONSTRAINT ck_taxi_eurosminuto  -- RIA 17 (adaptada a esta tabela).
    CHECK (eurosminuto > 0.0)
);

-- ----------------------------------------------------------------------------

CREATE TABLE viagem (
  motorista,
  inicio      DATE,
  fim         DATE       CONSTRAINT nn_viagem_fim         NOT NULL,
  taxi                   CONSTRAINT nn_viagem_taxi        NOT NULL,
  passageiros NUMBER (1) CONSTRAINT nn_viagem_passageiros NOT NULL,
--
  CONSTRAINT pk_viagem
    PRIMARY KEY (motorista, inicio),  -- Simplificação.
--
  CONSTRAINT fk_viagem_motorista
    FOREIGN KEY (motorista)
    REFERENCES motorista (nif),
--
  CONSTRAINT fk_viagem_taxi
    FOREIGN KEY (taxi)
    REFERENCES taxi (matricula),
--
  CONSTRAINT ck_viagem_periodo  -- RIA 5 (adaptada a esta tabela).
    CHECK (inicio < fim),
--
  CONSTRAINT ck_viagem_passageiros  -- RIA 19.
    CHECK (passageiros BETWEEN 1 AND 8)
);

-- ----------------------------------------------------------------------------

-- Exemplo de uso de regista_motorista (nif, nome, genero, nascimento, localidade)

BEGIN pkg_taxi.regista_motorista (121212121, 'Antonio Almirante', 'M', 1998, 'Lisboa'); END;
/
BEGIN pkg_taxi.regista_motorista (121212126, 'Sofia Lmfao Afonso', 'F', 2004, 'Lisboa'); END;
/

-- ----------------------------------------------------------------------------

-- Exemplo de uso de regista_taxi (matricula, ano, marca, conforto, eurosminuto)

BEGIN pkg_taxi.regista_taxi ('AA44BB', 2001, 'Lancia', 'B', 3); END;
/
BEGIN pkg_taxi.regista_taxi ('AA55BB', 2020, 'Tesla', 'L', 7); END;
/

-- ----------------------------------------------------------------------------

-- Exemplo de uso de regista_viagem (motorista, inicio, fim, taxi, passageiros)

BEGIN pkg_taxi.regista_viagem (121212121, TO_DATE('2022-07-27 10:00:00', 'YYYY-MM-DD HH24:MI:SS'), TO_DATE('2022-07-27 11:00:00', 'YYYY-MM-DD HH24:MI:SS'), 'AA55BB', 3); END;
/
BEGIN pkg_taxi.regista_viagem (121212121, TO_DATE('2022-06-27 10:00:00', 'YYYY-MM-DD HH24:MI:SS'), TO_DATE('2022-06-28 10:00:00', 'YYYY-MM-DD HH24:MI:SS'), 'AA44BB', 5); END;
/

BEGIN pkg_taxi.regista_viagem (121212126, TO_DATE('2022-09-17 10:00:00', 'YYYY-MM-DD HH24:MI:SS'), TO_DATE('2022-09-17 11:00:00', 'YYYY-MM-DD HH24:MI:SS'), 'AA44BB', 3); END;
/
BEGIN pkg_taxi.regista_viagem (121212126, TO_DATE('2022-10-17 10:00:00', 'YYYY-MM-DD HH24:MI:SS'), TO_DATE('2022-10-18 10:00:00', 'YYYY-MM-DD HH24:MI:SS'), 'AA55BB', 5); END;
/

-- ----------------------------------------------------------------------------

-- Visualizar se todos os dados foram inseridos com sucesso

SELECT * FROM motorista;
SELECT * FROM taxi;
SELECT * FROM viagem;

-- ----------------------------------------------------------------------------

-- Exemplo de uso de lista_taxis_mais_conduzidos (motorista)

DECLARE
    matricula_viagem taxi.matricula%TYPE;
    marca_viagem taxi.marca%TYPE;
    conforto_viagem taxi.conforto%TYPE;
    total_minutos_viagem NUMBER;

    cursor_taxis SYS_REFCURSOR;

BEGIN
    cursor_taxis := pkg_taxi.lista_taxis_mais_conduzidos(121212126);

    LOOP
        FETCH cursor_taxis INTO matricula_viagem, marca_viagem, conforto_viagem, total_minutos_viagem;
        EXIT WHEN cursor_taxis%NOTFOUND;

        DBMS_OUTPUT.PUT_LINE('Matricula: ' || matricula_viagem || ', Marca: ' || marca_viagem || ', Conforto: ' || conforto_viagem || ', Total Minutos: ' || total_minutos_viagem);
    END LOOP;

    CLOSE cursor_taxis;

EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Erro: ' || SQLERRM);
END;
/


-- ----------------------------------------------------------------------------

-- Exemplo de uso de remove_viagem (motorista, inicio)

BEGIN pkg_taxi.remove_viagem (121212121, TO_DATE('2022-07-27 10:00:00', 'YYYY-MM-DD HH24:MI:SS')); END;
/
BEGIN pkg_taxi.remove_viagem (121212121, TO_DATE('2022-06-27 10:00:00', 'YYYY-MM-DD HH24:MI:SS')); END;
/
BEGIN pkg_taxi.remove_viagem (121212126, TO_DATE('2022-09-17 10:00:00', 'YYYY-MM-DD HH24:MI:SS')); END;
/
BEGIN pkg_taxi.remove_viagem (121212126, TO_DATE('2022-10-17 10:00:00', 'YYYY-MM-DD HH24:MI:SS')); END;
/

-- ----------------------------------------------------------------------------

-- Exemplo de uso de remove_taxi (matricula)

BEGIN pkg_taxi.remove_taxi ('AA44BB'); END;
/
BEGIN pkg_taxi.remove_taxi ('AA55BB'); END;
/

-- ----------------------------------------------------------------------------

-- Exemplo de uso de remove_motorista (nif)

BEGIN pkg_taxi.remove_motorista (121212121); END;
/
BEGIN pkg_taxi.remove_motorista (121212126); END;
/

-- ----------------------------------------------------------------------------

-- Visualizar se todos os dados foram removidos com sucesso

SELECT * FROM motorista;
SELECT * FROM taxi;
SELECT * FROM viagem;