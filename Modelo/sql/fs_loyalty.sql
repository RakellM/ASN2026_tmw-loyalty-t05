
WITH tb_transacoes AS (
    SELECT
        *,
        DAYOFWEEK(DATE(DtCriacao)) AS DiaDaSemana, -- 1 = Domingo, 7 = Sábado
        DAYOFYEAR(DATE(DtCriacao)) AS DiaDoAno,
        MONTH(DATE(DtCriacao)) AS Mes,
        WEEKOFYEAR(DATE(DtCriacao)) AS SemanaDoAno,
        FLOOR(DATEDIFF('{date}', DATE(DtCriacao)) / 7) + 1 AS SemanaIdx -- 1 = most recent week, 4 = oldest week
    FROM workspace.tmw_loyalty.transacoes
    WHERE DtCriacao < '{date}' AND DtCriacao >= '{date}' - interval 28 days
),


tb_dia AS (
    SELECT
        IdCliente,
        COUNT(*) AS QtdeTotal,
-- Numerador: contagens por cliente × dia da semana
        COUNT(CASE WHEN DiaDaSemana = 1 THEN 1 END) AS QtdeDom,
        COUNT(CASE WHEN DiaDaSemana = 2 THEN 1 END) AS QtdeSeg,
        COUNT(CASE WHEN DiaDaSemana = 3 THEN 1 END) AS QtdeTer,
        COUNT(CASE WHEN DiaDaSemana = 4 THEN 1 END) AS QtdeQua,
        COUNT(CASE WHEN DiaDaSemana = 5 THEN 1 END) AS QtdeQui,
        COUNT(CASE WHEN DiaDaSemana = 6 THEN 1 END) AS QtdeSex,
        COUNT(CASE WHEN DiaDaSemana = 7 THEN 1 END) AS QtdeSab,

-- Numerador: contagens por cliente × semana relativa
        COUNT(CASE WHEN SemanaIdx = 1 THEN 1 END) AS QtdeSem1,
        COUNT(CASE WHEN SemanaIdx = 2 THEN 1 END) AS QtdeSem2,
        COUNT(CASE WHEN SemanaIdx = 3 THEN 1 END) AS QtdeSem3,
        COUNT(CASE WHEN SemanaIdx = 4 THEN 1 END) AS QtdeSem4
    FROM tb_transacoes
    GROUP BY IdCliente
),

tb_sasonalidade AS (
SELECT
    IdCliente,
    QtdeTotal,

    -- ---------- Shares por dia da semana (%) ----------
    ROUND(try_divide(QtdeDom * 100.0 , QtdeTotal), 2) AS ShareDomingo,
    ROUND(try_divide(QtdeSeg * 100.0 , QtdeTotal), 2) AS ShareSegunda,
    ROUND(try_divide(QtdeTer * 100.0 , QtdeTotal), 2) AS ShareTerca,
    ROUND(try_divide(QtdeQua * 100.0 , QtdeTotal), 2) AS ShareQuarta,
    ROUND(try_divide(QtdeQui * 100.0 , QtdeTotal), 2) AS ShareQuinta,
    ROUND(try_divide(QtdeSex * 100.0 , QtdeTotal), 2) AS ShareSexta,
    ROUND(try_divide(QtdeSab * 100.0 , QtdeTotal), 2) AS ShareSabado,

    -- ---------- Shares por semana relativa (%) ----------
    ROUND(try_divide(QtdeSem1 * 100.0 , QtdeTotal), 2) AS ShareSemana1,  -- mais recente
    ROUND(try_divide(QtdeSem2 * 100.0 , QtdeTotal), 2) AS ShareSemana2,
    ROUND(try_divide(QtdeSem3 * 100.0 , QtdeTotal), 2) AS ShareSemana3,
    ROUND(try_divide(QtdeSem4 * 100.0 , QtdeTotal), 2) AS ShareSemana4  -- mais antiga

FROM tb_dia
),

tb_cliente_agg AS (

    SELECT IdCliente,
        COUNT(distinct date(DtCriacao)) AS QtdeFrequencia,
        SUM(QtdePontos) AS QtdePontos,
        SUM(CASE WHEN QtdePontos > 0 THEN QtdePontos ELSE 0 END) AS QtdePontosPositivos,
        MIN(date_diff('{date}', DtCriacao)) AS Recencia,
        COUNT(idTransacao) AS QtdeTransacoes
    FROM tb_transacoes

    GROUP BY ALL
),

tb_cliente_produto AS (
    SELECT 
        t1.IdCliente,
        COUNT(t1.idTransacao) AS QtdeTransacoes,
        -- Percentual de transações por produto
        try_divide(COUNT(DISTINCT CASE WHEN t3.DescNomeProduto = 'ChatMessage' THEN t1.idTransacao ELSE NULL END) , COUNT(DISTINCT t1.idTransacao) ) AS pctTransacao_chat,
        try_divide(COUNT(DISTINCT CASE WHEN t3.DescNomeProduto = 'Lista de presença' THEN t1.idTransacao ELSE NULL END) , COUNT(DISTINCT t1.idTransacao) ) AS pctTransacao_presenca,
        try_divide(COUNT(DISTINCT CASE WHEN t3.DescNomeProduto = 'Presença Streak' THEN t1.idTransacao ELSE NULL END) , COUNT(DISTINCT t1.idTransacao) ) AS pctTransacao_streak,
        try_divide(COUNT(DISTINCT CASE WHEN t3.DescNomeProduto = 'Resgatar Ponei' THEN t1.idTransacao ELSE NULL END) , COUNT(DISTINCT t1.idTransacao) ) AS pctTransacao_ponei,
        try_divide(COUNT(DISTINCT CASE WHEN t3.DescNomeProduto = 'Troca de Pontos StreamElements' THEN t1.idTransacao ELSE NULL END) , COUNT(DISTINCT t1.idTransacao) ) AS pctTransacao_streamElements,
        try_divide(COUNT(DISTINCT CASE WHEN t3.DescNomeProduto NOT IN ('ChatMessage', 'Lista de presença', 'Presença Streak', 'Resgatar Ponei', 'Troca de Pontos StreamElements') OR t3.DescNomeProduto IS NULL THEN t1.idTransacao ELSE NULL END) , COUNT(DISTINCT t1.idTransacao) ) AS pctTransacao_outros,
        -- Percentual de pontos por produto
        try_divide(SUM(CASE WHEN t3.DescNomeProduto = 'ChatMessage' THEN ABS(t2.QtdeProduto * t2.vlProduto) ELSE NULL END) , SUM(ABS(t2.QtdeProduto * t2.vlProduto)) ) AS pctPontosAbs_chat,
        try_divide(SUM(CASE WHEN t3.DescNomeProduto = 'Lista de presença' THEN ABS(t2.QtdeProduto * t2.vlProduto) ELSE NULL END) , SUM(ABS(t2.QtdeProduto * t2.vlProduto)) ) AS pctPontosAbs_presenca,
        try_divide(SUM(CASE WHEN t3.DescNomeProduto = 'Presença Streak' THEN ABS(t2.QtdeProduto * t2.vlProduto) ELSE NULL END) , SUM(ABS(t2.QtdeProduto * t2.vlProduto)) ) AS pctPontosAbs_streak,
        try_divide(SUM(CASE WHEN t3.DescNomeProduto = 'Resgatar Ponei' THEN ABS(t2.QtdeProduto * t2.vlProduto) ELSE NULL END) , SUM(ABS(t2.QtdeProduto * t2.vlProduto)) ) AS pctPontosAbs_ponei,
        try_divide(SUM(CASE WHEN t3.DescNomeProduto = 'Troca de Pontos StreamElements' THEN ABS(t2.QtdeProduto * t2.vlProduto) ELSE NULL END) , SUM(ABS(t2.QtdeProduto * t2.vlProduto)) ) AS pctPontosAbs_streamElements,
        try_divide(SUM(CASE WHEN t3.DescNomeProduto NOT IN ('ChatMessage', 'Lista de presença', 'Presença Streak', 'Resgatar Ponei', 'Troca de Pontos StreamElements') OR t3.DescNomeProduto IS NULL THEN ABS(t2.QtdeProduto * t2.vlProduto) ELSE NULL END) , SUM(ABS(t2.QtdeProduto * t2.vlProduto)) ) AS pctPontosAbs_outros,
        -- Flag de Streak
        MAX( CASE WHEN t3.DescNomeProduto = 'Presença Streak' THEN 1 ELSE 0 END) AS flStreak,
        -- Dias desde o último Streak
        MIN(CASE WHEN t3.DescNomeProduto = 'Presença Streak' THEN date_diff('{date}', t1.DtCriacao) ELSE NULL END) AS diasDesdeUltimoStreak,
        -- Quantidade de produto distinto
        COUNT(DISTINCT t2.IdProduto) AS qtdeProdutoDistintos

    FROM tb_transacoes AS t1

    LEFT JOIN workspace.tmw_loyalty.transacao_produto AS t2
        ON t1.IdTransacao = t2.IdTransacao
    
    LEFT JOIN workspace.tmw_loyalty.produtos AS t3
        ON t2.IdProduto = t3.IdProduto
    
    WHERE t1.DtCriacao < '{date}' AND t1.DtCriacao >= '{date}' - interval 28 days
    GROUP BY ALL
),

tb_vida AS (
    SELECT
        t1.idCliente,
        MAX(date_diff('{date}', t1.dtCriacao)) AS diasPrimeiraTransacao,
        COUNT(DISTINCT DATE(DtCriacao)) AS freqVida,
        SUM(t1.QtdePontos) AS SaldoPontos
    FROM workspace.tmw_loyalty.transacoes AS t1
    WHERE DtCriacao < '{date}'
    GROUP BY ALL
),

tb_join AS (
    SELECT 
        t1.*,
        (t1.QtdePontosPositivos - (SELECT AVG(QtdePontosPositivos) FROM tb_cliente_agg) ) / (SELECT stddev(QtdePontosPositivos) FROM tb_cliente_agg) AS zScore,
        t3.diasPrimeiraTransacao,
        t3.freqVida,
        t3.SaldoPontos,
        t2.pctTransacao_chat,
        t2.pctTransacao_presenca,
        t2.pctTransacao_streak,
        t2.pctTransacao_ponei,
        t2.pctTransacao_streamElements,
        t2.pctTransacao_outros,
        t2.pctPontosAbs_chat,
        t2.pctPontosAbs_presenca,
        t2.pctPontosAbs_streak,
        t2.pctPontosAbs_ponei,
        t2.pctPontosAbs_streamElements,
        t2.pctPontosAbs_outros,
        t2.flStreak,
        t2.diasDesdeUltimoStreak,
        t2.qtdeProdutoDistintos,
        t4.ShareDomingo,
        t4.ShareSegunda,
        t4.ShareTerca,
        t4.ShareQuarta,
        t4.ShareQuinta,
        t4.ShareSexta,
        t4.ShareSabado,
        t4.ShareSemana1,
        t4.ShareSemana2,
        t4.ShareSemana3,
        t4.ShareSemana4

    FROM tb_cliente_agg AS t1

    LEFT JOIN tb_cliente_produto AS t2
        ON t1.idCliente = t2.idCliente

    LEFT JOIN tb_vida AS t3
        ON t1.idCliente = t3.idCliente

    LEFT JOIN tb_sasonalidade AS t4
        ON t1.idCliente = t4.idCliente
)

SELECT
    '{date}' AS dtRef,
    *
FROM tb_join

