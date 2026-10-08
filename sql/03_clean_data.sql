-- =====================================================================
-- 03_clean_data.sql
-- movie_data_raw (TEXT)  ->  movie_data (types stricts), puis création
-- des vues d'analyse réutilisées par les scripts 04, 05, 06 et Python.
-- =====================================================================

TRUNCATE movie_data RESTART IDENTITY;

INSERT INTO movie_data (
    movie_title, release_date, wikipedia_url, genre,
    director_1, director_2,
    cast_1, cast_2, cast_3, cast_4, cast_5,
    budget, revenue
)
SELECT
    BTRIM(movie_title),
    release_date::DATE,                                  -- '2016-03-08' (ISO)
    BTRIM(wikipedia_url),
    BTRIM(genre),
    BTRIM(director_1),
    NULLIF(BTRIM(director_2), ''),                       -- vide -> NULL
    BTRIM(cast_1),
    NULLIF(BTRIM(cast_2), ''),
    NULLIF(BTRIM(cast_3), ''),
    NULLIF(BTRIM(cast_4), ''),
    NULLIF(BTRIM(cast_5), ''),
    -- '$15,000,000.00' -> 15000000.00 : on retire tout sauf chiffres et point
    REGEXP_REPLACE(budget,  '[^0-9.]', '', 'g')::NUMERIC,
    REGEXP_REPLACE(revenue, '[^0-9.]', '', 'g')::NUMERIC
FROM movie_data_raw
ORDER BY BTRIM(movie_title);

-- ---------------------------------------------------------------------
-- Vue principale : métriques calculées par film
--   profit           = revenue - budget            (marge brute apparente, en $)
--   roi              = (revenue - budget) / budget (1.0 = +100 %)
--   revenue_multiple = revenue / budget
-- ---------------------------------------------------------------------
CREATE OR REPLACE VIEW v_movie_metrics AS
SELECT
    m.*,
    EXTRACT(YEAR  FROM m.release_date)::INT     AS release_year,
    EXTRACT(MONTH FROM m.release_date)::INT     AS release_month,
    m.revenue - m.budget                        AS profit,
    ROUND((m.revenue - m.budget) / m.budget, 4) AS roi,
    ROUND(m.revenue / m.budget, 4)              AS revenue_multiple,
    CASE
        WHEN m.budget <  10e6 THEN '1. < 10 M$'
        WHEN m.budget <  30e6 THEN '2. 10-30 M$'
        WHEN m.budget <  60e6 THEN '3. 30-60 M$'
        WHEN m.budget < 100e6 THEN '4. 60-100 M$'
        ELSE                       '5. >= 100 M$'
    END                                         AS tranche_budget
FROM movie_data m;

-- Format "long" des acteurs : 1 ligne par (film, acteur), rang de générique 1..5
CREATE OR REPLACE VIEW v_movie_cast AS
SELECT m.movie_id, m.movie_title, c.billing_order, c.actor
FROM movie_data m
CROSS JOIN LATERAL (VALUES
    (1, m.cast_1), (2, m.cast_2), (3, m.cast_3), (4, m.cast_4), (5, m.cast_5)
) AS c(billing_order, actor)
WHERE c.actor IS NOT NULL;

-- Format "long" des réalisateurs : 1 ligne par (film, réalisateur)
CREATE OR REPLACE VIEW v_movie_director AS
SELECT m.movie_id, m.movie_title, d.director_order, d.director
FROM movie_data m
CROSS JOIN LATERAL (VALUES
    (1, m.director_1), (2, m.director_2)
) AS d(director_order, director)
WHERE d.director IS NOT NULL;

-- Garde-fou : on s'arrête (ON_ERROR_STOP) si une ligne a été perdue.
DO $$
DECLARE
    n_raw   INT;
    n_clean INT;
BEGIN
    SELECT COUNT(*) INTO n_raw   FROM movie_data_raw;
    SELECT COUNT(*) INTO n_clean FROM movie_data;
    IF n_raw <> n_clean THEN
        RAISE EXCEPTION 'Nettoyage incomplet : % lignes brutes, % lignes propres', n_raw, n_clean;
    END IF;
    RAISE NOTICE 'OK : % lignes nettoyees', n_clean;
END $$;

SELECT movie_id, movie_title, release_date, genre, budget, revenue
FROM movie_data
ORDER BY movie_id
LIMIT 5;