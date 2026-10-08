-- =====================================================================
-- 02_import_data.sql
-- Importe data/raw/movieData.csv dans movie_data_raw.
--
-- Le chemin est RELATIF à la racine du projet : scripts/run_sql.sh se place
-- toujours à la racine avant de lancer psql, donc aucun chemin personnel.
-- \copy (avec antislash) lit le fichier côté CLIENT : aucun droit spécial
-- n'est requis, contrairement à COPY qui lit côté serveur.
-- IMPORTANT : une commande \copy doit tenir sur UNE SEULE ligne.
-- =====================================================================

TRUNCATE movie_data_raw;

\copy movie_data_raw FROM 'data/raw/movieData.csv' WITH (FORMAT CSV, HEADER TRUE, ENCODING 'UTF8')

SELECT COUNT(*) AS lignes_importees FROM movie_data_raw;