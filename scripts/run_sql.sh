#!/usr/bin/env bash
# Exécute un ou plusieurs fichiers du dossier sql/ avec psql et sauvegarde
# la sortie dans results/reports/<nom>.txt (en l'affichant aussi à l'écran).
#
# Usage :  ./scripts/run_sql.sh 04_exploration.sql
#          ./scripts/run_sql.sh 01_create_tables.sql 02_import_data.sql
set -euo pipefail

# 1) Toujours se placer à la racine du projet (les chemins relatifs du SQL en dépendent)
cd "$(dirname "$0")/.."

if [[ $# -eq 0 ]]; then
  echo "Usage : $0 <fichier.sql> [autre.sql ...]   (fichiers du dossier sql/)" >&2
  exit 1
fi
command -v psql >/dev/null || { echo "psql introuvable : installez postgresql-client (voir docs/setup.md)" >&2; exit 1; }
[[ -f .env ]] || { echo "Fichier .env manquant : cp .env.example .env puis renseignez-le" >&2; exit 1; }

# 2) Charger .env et exporter les variables PGHOST, PGPORT, PGUSER, PGPASSWORD, PGDATABASE.
#    psql les lit automatiquement : aucune option -h/-U/-d à passer.
set -a
# shellcheck disable=SC1091
source .env
set +a

mkdir -p results/reports results/tables results/figures data/processed

for arg in "$@"; do
  f="${arg##*/}"                      # accepte "04_x.sql" ou "sql/04_x.sql"
  [[ -f "sql/$f" ]] || { echo "sql/$f introuvable" >&2; exit 1; }
  report="results/reports/${f%.sql}.txt"
  echo ">>> $f  ->  $report"
  # -X : ignore ~/.psqlrc | ON_ERROR_STOP : s'arrête à la 1re erreur
  # 2>&1 | tee : erreurs et notices comprises dans le rapport ; pipefail propage l'échec
  psql -X -v ON_ERROR_STOP=1 -f "sql/$f" 2>&1 | tee "$report"
done
