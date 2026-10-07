
WITH 
tb_usario_curso AS (

    SELECT t1.idTMWCliente,
        t2.descSlugCurso,
        min(dtCriacao) AS dtInicioCurso,
        max(dtCriacao) AS dtUltimoEp,
        date_diff(max(dtCriacao), min(dtCriacao)) AS diasEntrePrimeUltimo,
        COUNT(*) AS qtEpCurso

    FROM workspace.tmw_education.usuarios_tmw AS t1

    LEFT JOIN workspace.tmw_education.cursos_episodios_completos AS T2
    on t1.idUsuario = t2.idUsuario

    WHERE t2.dtCriacao < '{date}'

    GROUP BY ALL
),

tb_curso AS (

    SELECT descSlugCurso,
           COUNT(*) AS qtEpsCurso
    FROM workspace.tmw_education.cursos_episodios
    GROUP BY ALL

),

tb_curso_avanco AS (

    SELECT t1.*,
        try_divide(t1.qtEpCurso , t2.qtepscurso) AS pctCursoCompleto

    FROM tb_usario_curso AS t1
    LEFT JOIN tb_curso AS t2
    ON t1.descslugcurso = t2.descslugcurso

),

tb_agg AS (

    SELECT
        idTMWCliente AS idCliente,
        COUNT(distinct descslugcurso) AS qtdCursosIniciados,
        COUNT(distinct CASE WHEN pctCursoCompleto = 1 THEN descslugcurso ELSE NULL END) AS qtdCursosFinalizados,
        SUM(CASE WHEN descslugcurso = 'python-2025' THEN pctCursoCompleto else 0 end) as python_2025,
        SUM(CASE WHEN descslugcurso = 'plataforma-ml-2026' THEN pctCursoCompleto else 0 end) as plataforma_ml_2026,
        SUM(CASE WHEN descslugcurso = 'mlflow-2025' THEN pctCursoCompleto else 0 end) as mlflow_2025,
        SUM(CASE WHEN descslugcurso = 'carreira' THEN pctCursoCompleto else 0 end) as carreira,
        SUM(CASE WHEN descslugcurso = 'nekt-2025' THEN pctCursoCompleto else 0 end) as nekt_2025,
        SUM(CASE WHEN descslugcurso = 'estatistica-2025' THEN pctCursoCompleto else 0 end) as estatistica_2025,
        SUM(CASE WHEN descslugcurso = 'coleta-dados-2024' THEN pctCursoCompleto else 0 end) as coleta_dados_2024,
        SUM(CASE WHEN descslugcurso = 'python-2024' THEN pctCursoCompleto else 0 end) as python_2024,
        SUM(CASE WHEN descslugcurso = 'lago-mago-2024' THEN pctCursoCompleto else 0 end) as lago_mago_2024,
        SUM(CASE WHEN descslugcurso = 'github-2025' THEN pctCursoCompleto else 0 end) as github_2025,
        SUM(CASE WHEN descslugcurso = 'trampar-lakehouse-2024' THEN pctCursoCompleto else 0 end) as trampar_lakehouse_2024,
        SUM(CASE WHEN descslugcurso = 'ds-databricks-2024' THEN pctCursoCompleto else 0 end) as ds_databricks_2024,
        SUM(CASE WHEN descslugcurso = 'sql-2020' THEN pctCursoCompleto else 0 end) as sql_2020,
        SUM(CASE WHEN descslugcurso = 'ds-pontos-2024' THEN pctCursoCompleto else 0 end) as ds_pontos_2024,
        SUM(CASE WHEN descslugcurso = 'streamlit-2025' THEN pctCursoCompleto else 0 end) as streamlit_2025,
        SUM(CASE WHEN descslugcurso = 'estatistica-2024' THEN pctCursoCompleto else 0 end) as estatistica_2024,
        SUM(CASE WHEN descslugcurso = 'ml-2024' THEN pctCursoCompleto else 0 end) as ml_2024,
        SUM(CASE WHEN descslugcurso = 'ragia' THEN pctCursoCompleto else 0 end) as ragia,
        SUM(CASE WHEN descslugcurso = 'sql-2025' THEN pctCursoCompleto else 0 end) as sql_2025,
        SUM(CASE WHEN descslugcurso = 'loyalty-predict-2025' THEN pctCursoCompleto else 0 end) as loyalty_predict_2025,
        SUM(CASE WHEN descslugcurso = 'go-2026' THEN pctCursoCompleto else 0 end) as go_2026,
        SUM(CASE WHEN descslugcurso = 'f1-lake' THEN pctCursoCompleto else 0 end) as f1_lake,
        SUM(CASE WHEN descslugcurso = 'ia-canal-2025' THEN pctCursoCompleto else 0 end) as ia_canal_2025,
        SUM(CASE WHEN descslugcurso = 'tse-analytics-2024' THEN pctCursoCompleto else 0 end) as tse_analytics_2024,
        SUM(CASE WHEN descslugcurso = 'machine-learning-2025' THEN pctCursoCompleto else 0 end) as machine_learning_2025,
        SUM(CASE WHEN descslugcurso = 'matchmaking-trampar-de-casa-2024' THEN pctCursoCompleto else 0 end) as matchmaking_trampar_de_casa_2024,
        SUM(CASE WHEN descslugcurso = 'pandas-2024' THEN pctCursoCompleto else 0 end) as pandas_2024,
        SUM(CASE WHEN descslugcurso = 'pandas-2025' THEN pctCursoCompleto else 0 end) as pandas_2025,
        SUM(CASE WHEN descslugcurso = 'speed-f1' THEN pctCursoCompleto else 0 end) as speed_f1,
        SUM(CASE WHEN descslugcurso = 'github-2024' THEN pctCursoCompleto else 0 end) as github_2024,
        AVG(diasEntrePrimeUltimo) AS avgTempoInicioUltimo,
        AVG(CASE WHEN pctCursoCompleto = 1 THEN diasEntrePrimeUltimo ELSE NULL END) AS avgTempoInicioFim

    FROM tb_curso_avanco

    GROUP BY ALL

)

SELECT '{date}' AS dtRef,
        *
FROM tb_agg