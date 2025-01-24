-- -----------------------------------------------------------------------------------------
-- SIBD-2324-G10-E4
-- Afonso Santos - 59808 - T11 - TP16
-- Diogo Lopes - 60447 - T11 - TP16
-- Pedro Silva - 59886 - T11 - TP16
-- -----------------------------------------------------------------------------------------

CREATE OR REPLACE PACKAGE BODY pkg_taxi IS

    PROCEDURE regista_motorista(nif_in IN NUMBER, nome_in IN VARCHAR, genero_in IN CHAR, nascimento_in IN NUMBER, localidade_in IN VARCHAR) IS
        idade_motorista NUMBER;

    BEGIN
        -- Verificar se o motorista tem pelo menos 18 anos
        idade_motorista := TO_NUMBER(TO_CHAR(SYSDATE, 'YYYY')) - nascimento_in;

        IF idade_motorista < 18 THEN
            RAISE_APPLICATION_ERROR(-20000, 'O motorista deve ter pelo menos 18 anos.');
        END IF;

        -- Inserir os dados do motorista na tabela
        INSERT INTO motorista (nif, nome, genero, nascimento, localidade)
        VALUES (nif_in, nome_in, genero_in, nascimento_in, localidade_in);

    EXCEPTION
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20001, 'Erro ao registrar o motorista: ' || SQLERRM);

    END regista_motorista;

    PROCEDURE regista_taxi(matricula_in IN VARCHAR, ano_in IN NUMBER, marca_in IN VARCHAR, conforto_in IN CHAR, eurosminuto_in IN NUMBER) IS
        
    BEGIN
        UPDATE taxi SET eurosminuto = eurosminuto_in WHERE matricula = matricula_in;
        IF SQL%ROWCOUNT = 0 THEN
            -- Inserir os dados do taxi na tabela
            INSERT INTO taxi (matricula, ano, marca, conforto, eurosminuto)
            VALUES (matricula_in, ano_in, marca_in, conforto_in, eurosminuto_in);
        END IF;

    EXCEPTION
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20002, 'Erro ao registar taxi: ' || SQLERRM);

    END regista_taxi;

    PROCEDURE regista_viagem(motorista_in IN NUMBER, inicio_in IN DATE, fim_in IN DATE, taxi_in IN VARCHAR, passageiros_in IN NUMBER) IS
        ano_viagem NUMBER;
        contador   NUMBER;
        
    BEGIN
        -- Verificar se o taxi existe
        contador := 0;
        SELECT COUNT(1) INTO contador FROM taxi WHERE matricula = taxi_in;
        IF contador = 0 THEN
            RAISE_APPLICATION_ERROR(-20003, 'O taxi não existe.');
        END IF;

        -- Verificar se o motorista existe
        contador := 0;
        SELECT COUNT(1) INTO contador FROM motorista WHERE nif = motorista_in;
        IF contador = 0 THEN
            RAISE_APPLICATION_ERROR(-20004, 'O motorista não existe.');
        END IF;

        -- Verificar se o ano de compra do taxi é anterior à viagem
        SELECT ano INTO ano_viagem FROM taxi WHERE matricula = taxi_in;
        IF ano_viagem > TO_NUMBER(TO_CHAR(inicio_in, 'YYYY')) THEN
            RAISE_APPLICATION_ERROR(-20005, 'O ano de compra do taxi é posterior à viagem.');
        END IF;

        -- Verifica se a viagem interseta o período de outra viagem com o mesmo motorista
        contador := 0;
        SELECT COUNT(1) INTO contador FROM viagem WHERE motorista = motorista_in AND inicio <= fim_in AND fim >= inicio_in;
        IF contador > 0 THEN
            RAISE_APPLICATION_ERROR(-20006, 'A viagem interseta o período de outra viagem com o mesmo motorista.');
        END IF;

        -- Verifica se a viagem interseta o período de outra viagem com o mesmo taxi
        contador := 0;
        SELECT COUNT(1) INTO contador FROM viagem WHERE taxi = taxi_in AND inicio <= fim_in AND fim >= inicio_in;
        IF contador > 0 THEN
            RAISE_APPLICATION_ERROR(-20007, 'A viagem interseta o período de outra viagem com o mesmo taxi.');
        END IF;

        -- Inserir os dados da viagem na tabela
        INSERT INTO viagem (motorista, inicio, fim, taxi, passageiros)
        VALUES (motorista_in, inicio_in, fim_in, taxi_in, passageiros_in);

    EXCEPTION
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20008, 'Erro ao registar viagem: ' || SQLERRM);

    END regista_viagem;
    
    PROCEDURE remove_viagem(motorista_in IN NUMBER, data_in IN DATE) IS
    BEGIN
        -- Remover a viagem
        DELETE FROM viagem WHERE motorista = motorista_in AND inicio <= data_in AND fim >= data_in;

        -- Verificar se a viagem existe
        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20009, 'A viagem não existe.');
        END IF;

    EXCEPTION
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20010, 'Erro ao remover viagem: ' || SQLERRM);

    END remove_viagem;
    
    PROCEDURE remove_taxi(matricula_in IN VARCHAR) IS
    BEGIN
        -- Remover as viagens
        FOR viagem IN (SELECT * FROM viagem WHERE taxi = matricula_in) LOOP
            remove_viagem(viagem.motorista, viagem.inicio);
        END LOOP;

        -- Remover o taxi
        DELETE FROM taxi WHERE matricula = matricula_in;

        -- Verificar se o taxi existe
        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20011, 'O taxi não existe.');
        END IF;

    EXCEPTION
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20012, 'Erro ao remover taxi: ' || SQLERRM);

    END remove_taxi;

    PROCEDURE remove_motorista(nif_in IN NUMBER) IS
    BEGIN
        -- Remover as viagens
        FOR viagem IN (SELECT * FROM viagem WHERE motorista = nif_in) LOOP
            remove_viagem(viagem.motorista, viagem.inicio);
        END LOOP;

        -- Remover o motorista
        DELETE FROM motorista WHERE nif = nif_in;

        -- Verificar se o motorista existe
        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20013, 'O motorista não existe.');
        END IF;

    EXCEPTION
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20014, 'Erro ao remover motorista: ' || SQLERRM);

    END remove_motorista;
    
    FUNCTION lista_taxis_mais_conduzidos(motorista_in IN NUMBER) RETURN SYS_REFCURSOR IS
        cursor_taxis SYS_REFCURSOR;
        conta_motoristas NUMBER;

    BEGIN
        -- Verificar se o motorista existe
        SELECT COUNT(1) INTO conta_motoristas FROM motorista WHERE nif = motorista_in;
        IF conta_motoristas = 0 THEN
            RAISE_APPLICATION_ERROR(-20015, 'O motorista não existe.');
        END IF;

        -- Devolver um cursor com os taxis conduzidos pelo motorista
        OPEN cursor_taxis FOR
            SELECT DISTINCT T.matricula, T.marca, T.conforto, SUM(minutos_que_passaram(V.inicio, V.fim)) AS total_minutos
              FROM viagem V, taxi T
             WHERE V.motorista = motorista_in AND V.taxi = T.matricula
             GROUP BY T.matricula, T.marca, T.conforto
             ORDER BY total_minutos DESC;

        RETURN cursor_taxis;

    EXCEPTION
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20016, 'Erro ao listar taxis mais conduzidos: ' || SQLERRM);

    END lista_taxis_mais_conduzidos;
    
END pkg_taxi;