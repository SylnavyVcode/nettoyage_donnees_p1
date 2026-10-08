#!/usr/bin/env bash
# Pipeline complet : SQL 01 -> 06, puis analyse Python (stats + figures).
# Usage :  ./scripts/run_all.sh              (SQL + Python)
#          ./scripts/run_all.sh --sql-only   (SQL uniquement)
set -euo pipefail
cd "$(dirname "$0")/.."

for f in sql/0*.sql; do
  ./scripts/run_sql.sh "$(basename "$f")"
done

if [[ "${1:-}" != "--sql-only" ]]; then
  "${PYTHON:-python3}" scripts/analysis.py
fi
