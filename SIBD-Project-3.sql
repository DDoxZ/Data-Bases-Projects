-- ----------------------------------------------------------------------------
-- SIBD-2324-G10-E3
-- Afonso Santos - 59808 - T11 - TP16
-- Diogo Lopes - 60447 - T11 - TP16
-- Pedro Silva - 59886 - T11 - TP16
--
-- Contribuições: Cada membro do grupo contribuiu de forma igualitária para a resolução do trabalho. Todos os membros do grupo fizeram individualmente a resolução de todos os exercícios 1 a 3, e a resolução do exercício 4 foi feita em conjunto.
-- 
-- Esforço Individual:
-- Afonso Santos - 33.3%
-- Diogo Lopes - 33.3%
-- Pedro Silva - 33.3%
-- ----------------------------------------------------------------------------

-- ----------------------------------------------------------------------------

/* 
1. NIF, nome, e idade das motoristas femininas com apelido Afonso, que conduziram em viagens com três 
ou mais passageiros, em táxis com conforto luxuoso, durante o ano de 2023, incluindo o caso particular 
da noite da passagem de ano, em que uma viagem pode ter começado em 2022 e terminado já em 2023. 
A matrícula e a marca do(s) táxi(s) também devem ser mostradas. 
O resultado deve vir ordenado de forma ascendente pela idade e nome das motoristas, e de forma descendente 
pela marca e matrícula dos táxis. Nota: a extração do ano a partir de uma data pode ser feita usando 
TO_CHAR(data, 'YYYY').
Variantes com menor cotação: a) sem o cálculo da idade das motoristas; e b) sem a verificação do caso da 
noite da passagem de ano. 
*/

SELECT M.nif, M.nome, TO_CHAR(SYSDATE, 'YYYY') - M.nascimento AS idade, T.matricula, T.marca
  FROM motorista M, taxi T, viagem V
 WHERE (M.nif = V.motorista)
   AND (T.matricula = V.taxi)
   AND (UPPER(M.nome) LIKE '% AFONSO')
   AND (M.genero = 'F')
   AND (V.passageiros >= 3)
   AND (T.conforto = 'L')
   AND (TO_CHAR(V.fim, 'YYYY') = '2023')
 ORDER BY idade ASC, M.nome ASC, T.marca DESC, T.matricula DESC;

-- ----------------------------------------------------------------------------

/*
2. NIF e nome dos motoristas masculinos que, considerando apenas viagens iniciadas em
2022 (não deve ser considerada a data de fim das viagens), ou não conduziram táxis da
marca Lancia ou conduziram táxis dessa marca em até duas viagens. Adicionalmente, os
motoristas resultantes não podem ter conduzido táxis comprados antes de 2000, independentemente 
do ano das viagens. O resultado deve vir ordenado pelo nome dos motoristas de forma ascendente 
e pelo NIF de forma descendente.
Variantes com menor cotação: a) sem a verificação dos motoristas nunca terem conduzido
táxis comprados antes de 2000; e b) sem a verificação do número de viagens que conduziram em 2022.
*/

SELECT DISTINCT M.nif, M.nome
  FROM motorista M, viagem V, taxi T
 WHERE (M.nif = V.motorista)
   AND (V.taxi = T.matricula)
   AND (M.genero = 'M')

   -- Conta o número de viagens em que o motorista conduziu um Lancia em 2022.
   -- Se for maior que 2, não é incluído no resultado.
   AND ((SELECT COUNT(*)
           FROM viagem V2, taxi T2
          WHERE (V2.motorista = M.nif)
            AND (V2.taxi = T2.matricula)
            AND (TO_CHAR(V2.inicio, 'YYYY') = '2022')
            AND (T2.marca = 'Lancia')) <= 2)

   -- Se o motorista conduziu um táxi comprado antes de 2000, não é incluído no resultado.
   AND NOT EXISTS (SELECT 1
                     FROM taxi T3, viagem V3
                    WHERE (T3.matricula = V3.taxi)
                      AND (M.nif = V3.motorista)
                      AND (T3.ano < 2000))
 ORDER BY M.nome ASC, M.nif DESC;

-- ----------------------------------------------------------------------------

/*
3. Todos os dados dos táxis da marca Lexus, com preço por minuto acima da média dos preços 
por minuto de todos os táxis (independentemente da marca), e que tenham sido alguma vez 
conduzidos por todos os motoristas de Lisboa na parte da manhã dos dias, mais
precisamente entre as 6h00 e as 11h59. Para simplificar, consideram-se apenas as viagens
iniciadas de manhã (a data de fim das viagens deve ser ignorada). O resultado deve vir
ordenado pelo preço por minuto dos táxis de forma descendente e pela matrícula dos táxis
de forma ascendente. Nota: a extração da hora do dia a partir de uma data pode ser feita
usando TO_CHAR(data, 'HH24').
Variantes com menor cotação: a) sem a verificação do preço por minuto dos táxis ser superior 
à média dos preços por minuto de todos os táxis; e b) sem as verificações da localidade dos
motoristas e da hora das viagens.
*/

SELECT T.matricula, T.ano, T.marca, T.conforto, T.eurosminuto
  FROM taxi T
 WHERE (T.marca = 'Lexus')
   AND (T.eurosminuto > (SELECT AVG(T2.eurosminuto)
                          FROM taxi T2))
   AND NOT EXISTS (SELECT M.nif
                     FROM motorista M
                    WHERE (M.localidade = 'Lisboa')
                      AND NOT EXISTS (SELECT 1
                                        FROM viagem V
                                       WHERE (V.motorista = M.nif)
                                         AND (V.taxi = T.matricula)
                                         AND (TO_CHAR(V.inicio, 'HH24') BETWEEN '06' AND '11')))
 ORDER BY T.eurosminuto DESC, T.matricula ASC;

-- ----------------------------------------------------------------------------

/*
4. NIF e nome dos motoristas que faturaram mais euros em viagens em cada ano, 
separadamente para motoristas masculinos e femininos, devendo o género dos motoristas e o total
faturado em cada ano também aparecer no resultado. Considere que o valor de faturação
de uma viagem corresponde ao preço por minuto do táxi, em euros, a multiplicar pelos
minutos que passaram entre o início e o fim da viagem. A ordenação do resultado deve ser
pelo ano de forma descendente e pelo género dos motoristas de forma ascendente. No caso
de haver mais do que um(a) motorista com o mesmo máximo de faturação num ano, devem ser
mostrados todos esses motoristas. Nota: para efeitos de determinação do ano de
faturação, deve ser considerada a data de fim de cada viagem (mesmo que a viagem tenha
começado no ano anterior). Nota: por conveniência, está disponível a função minutos_-
que_passaram, que calcula quantos minutos passaram entre duas datas.1
Variantes com menor cotação: a) mostrar o total faturado em viagens por cada motorista
em cada ano, sem verificar se foram os/as que mais faturaram; e b) sem a distinção entre
motoristas femininos e masculinos.
*/

SELECT F.nif, F.nome, F.genero, F.ano, F.faturacao
  -- Tabela de faturacoes anuais
  FROM (SELECT M.nif, M.nome, M.genero, TO_CHAR(V.fim, 'YYYY') as ano, SUM(T.eurosminuto * minutos_que_passaram(V.inicio, V.fim)) AS faturacao
          FROM motorista M, viagem V, taxi T
         WHERE (M.nif = V.motorista)
           AND (V.taxi = T.matricula)
         GROUP BY M.nif, TO_CHAR(V.fim, 'YYYY'), M.nome, M.genero) F
 -- Comparacao com o maximo faturado por ano e por genero
 WHERE F.faturacao = (SELECT MAX(faturacao)
                        FROM (SELECT M.nif, M.nome, M.genero, TO_CHAR(V.fim, 'YYYY') as ano, SUM(T.eurosminuto * minutos_que_passaram(V.inicio, V.fim)) AS faturacao
                                FROM motorista M, viagem V, taxi T
                               WHERE (M.nif = V.motorista)
                                 AND (V.taxi = T.matricula)
                               GROUP BY M.nif, TO_CHAR(V.fim, 'YYYY'), M.nome, M.genero
                               ORDER BY ano DESC) F2
                       WHERE (F2.ano = F.ano)
                         AND (F2.genero = F.genero))
 ORDER BY ano DESC, genero ASC;

-- ----------------------------------------------------------------------------