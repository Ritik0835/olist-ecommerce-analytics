#!/usr/bin/env bash
# Build the olist database from the raw Kaggle CSVs.
#
# Usage:
#   scripts/load.sh            # create the database if missing, refuse if it has tables
#   scripts/load.sh --reset    # drop and rebuild the database (destroys local data)
#
# Environment:
#   OLIST_DB   database name (default: olist)
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

DB="${OLIST_DB:-olist}"
RESET=0
if [[ "${1:-}" == "--reset" ]]; then
    RESET=1
elif [[ $# -gt 0 ]]; then
    echo "Unknown argument: $1" >&2
    echo "Usage: scripts/load.sh [--reset]" >&2
    exit 2
fi

if ! command -v psql >/dev/null 2>&1; then
    echo "psql not found; install PostgreSQL client tools first." >&2
    exit 1
fi

REQUIRED_FILES=(
    olist_customers_dataset.csv
    olist_sellers_dataset.csv
    olist_products_dataset.csv
    product_category_name_translation.csv
    olist_orders_dataset.csv
    olist_order_items_dataset.csv
    olist_order_payments_dataset.csv
    olist_order_reviews_dataset.csv
    olist_geolocation_dataset.csv
)
for file in "${REQUIRED_FILES[@]}"; do
    if [[ ! -f "data/$file" ]]; then
        echo "Missing data/$file. Download the Olist CSVs into data/ first." >&2
        exit 1
    fi
done

if [[ "$RESET" -eq 1 ]]; then
    echo "Dropping and recreating database '$DB'"
    dropdb --if-exists "$DB"
fi

if [[ "$(psql -d postgres -Atc "SELECT 1 FROM pg_database WHERE datname = '$DB'")" != "1" ]]; then
    echo "Creating database '$DB'"
    createdb "$DB"
fi

TABLE_COUNT="$(psql -d "$DB" -Atc \
    "SELECT count(*) FROM information_schema.tables WHERE table_schema = 'public'")"
if [[ "$TABLE_COUNT" -ne 0 ]]; then
    echo "Database '$DB' already contains $TABLE_COUNT tables." >&2
    echo "Run scripts/load.sh --reset to rebuild it from the raw CSVs." >&2
    exit 1
fi

run_sql() {
    echo "Running sql/$1"
    psql -X -v ON_ERROR_STOP=1 -d "$DB" -f "sql/$1" -o /dev/null
}

run_sql 01_schema.sql
run_sql 02_load.sql
run_sql 04_star_schema_views.sql
run_sql 07_cohort_retention.sql
run_sql 08_rfm_segmentation.sql

psql -X -d "$DB" -Atc "
    SELECT 'orders=' || count(*) FROM orders
    UNION ALL SELECT 'delivered_orders=' || count(*) FROM orders WHERE order_status = 'delivered'
    UNION ALL SELECT 'fact_order_items=' || count(*) FROM fact_order_items
    UNION ALL SELECT 'rfm_customers=' || count(*) FROM rfm_segments
"
echo "Loaded database '$DB'."
