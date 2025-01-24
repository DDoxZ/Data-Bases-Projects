-- -----------------------------------------------------------------------------------------
-- SIBD-2324-G10-E4
-- Afonso Santos - 59808 - T11 - TP16
-- Diogo Lopes - 60447 - T11 - TP16
-- Pedro Silva - 59886 - T11 - TP16
-- -----------------------------------------------------------------------------------------

CREATE OR REPLACE PACKAGE pkg_taxi IS

    PROCEDURE regista_motorista(nif_in IN NUMBER, nome_in IN VARCHAR, genero_in IN CHAR, nascimento_in IN NUMBER, localidade_in IN VARCHAR);

    PROCEDURE regista_taxi(matricula_in IN VARCHAR, ano_in IN NUMBER, marca_in IN VARCHAR, conforto_in IN CHAR, eurosminuto_in IN NUMBER);

    PROCEDURE regista_viagem(motorista_in IN NUMBER, inicio_in IN DATE, fim_in IN DATE, taxi_in IN VARCHAR, passageiros_in IN NUMBER);

    PROCEDURE remove_viagem(motorista_in IN NUMBER, data_in IN DATE);

    PROCEDURE remove_taxi(matricula_in IN VARCHAR);

    PROCEDURE remove_motorista(nif_in IN NUMBER);

    FUNCTION lista_taxis_mais_conduzidos(motorista_in IN NUMBER)
    RETURN SYS_REFCURSOR;

END pkg_taxi;