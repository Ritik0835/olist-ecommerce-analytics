#!/usr/bin/env bash
# Re-run every analysis query against a loaded olist database.
# Fails on the first SQL error. Use scripts/load.sh first.
#
# Environment:
#   OLIST_DB   database name (default: olist)
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

DB="${OLIST_DB:-olist}"

if ! psql -d "$DB" -Atc "SELECT 1" >/dev/null 2>&1; then
    echo "Cannot connect to database '$DB'. Run scripts/load.sh first." >&2
    exit 1
fi

for file in \
    03_cleaning_checks.sql \
    05_revenue_analysis.sql \
    06_delivery_analysis.sql \
    07_cohort_retention.sql \
    08_rfm_segmentation.sql \
    09_seller_category.sql; do
    echo "===== sql/$file ====="
    psql -X -v ON_ERROR_STOP=1 -d "$DB" -f "sql/$file"
done
