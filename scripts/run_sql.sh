#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."          # toujours exécuter depuis la racine
set -a; source .env; set +a      # charge les variables PG*
mkdir -p results/reports
f="$1"                           # ex: 04_exploration.sql
psql -v ON_ERROR_STOP=1 -f "sql/$f" -o "results/reports/${f%.sql}.txt"
cat "results/reports/${f%.sql}.txt"