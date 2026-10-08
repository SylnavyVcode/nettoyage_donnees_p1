-- =====================================================================
-- 01_create_tables.sql
-- Crée les deux tables du projet :
--   movie_data_raw : zone de "staging", tout en TEXT (reçoit le CSV tel quel)
--   movie_data     : table propre et typée (alimentée par 03_clean_data.sql)
-- ATTENTION : ce script SUPPRIME puis recrée les tables (ré-exécutable).
-- =====================================================================

DROP TABLE IF EXISTS movie_data_raw CASCADE;
DROP TABLE IF EXISTS movie_data CASCADE;

-- Staging : on importe tout en TEXT pour qu'aucune ligne ne soit rejetée
-- à cause d'un format ("$15,000,000.00", date inattendue, etc.).
CREATE TABLE movie_data_raw (
    movie_title   TEXT,
    release_date  TEXT,
    wikipedia_url TEXT,
    genre         TEXT,
    director_1    TEXT,
    director_2    TEXT,
    cast_1        TEXT,
    cast_2        TEXT,
    cast_3        TEXT,
    cast_4        TEXT,
    cast_5        TEXT,
    budget        TEXT,
    revenue       TEXT
);

-- Table finale : types stricts + contraintes (le SGBD refuse les données invalides).
CREATE TABLE movie_data (
    movie_id      INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    movie_title   VARCHAR(255)  NOT NULL UNIQUE,
    release_date  DATE          NOT NULL,
    wikipedia_url TEXT          NOT NULL,
    genre         VARCHAR(100)  NOT NULL,
    director_1    VARCHAR(255)  NOT NULL,
    director_2    VARCHAR(255),
    cast_1        VARCHAR(255)  NOT NULL,
    cast_2        VARCHAR(255),
    cast_3        VARCHAR(255),
    cast_4        VARCHAR(255),
    cast_5        VARCHAR(255),
    budget        NUMERIC(15,2) NOT NULL CHECK (budget  > 0),
    revenue       NUMERIC(15,2) NOT NULL CHECK (revenue > 0)
);

\dt