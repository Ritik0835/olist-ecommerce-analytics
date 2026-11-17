#!/usr/bin/env bash
# Regenerate the Power BI CSV exports from the database views.
# Requires a database built by scripts/load.sh.
#
# Environment:
#   OLIST_DB   database name (default: olist)
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

DB="${OLIST_DB:-olist}"

# Recreate the cohort view (07) and RFM views (08) so the export reflects the
# current SQL rather than whatever was last loaded.
psql -X -v ON_ERROR_STOP=1 -d "$DB" -f sql/07_cohort_retention.sql -o /dev/null
psql -X -v ON_ERROR_STOP=1 -d "$DB" -f sql/08_rfm_segmentation.sql -o /dev/null
psql -X -v ON_ERROR_STOP=1 -d "$DB" -f sql/10_export_powerbi.sql

echo "Exported:"
wc -l exports/*.csv
