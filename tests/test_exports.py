"""Validate the committed Power BI exports without needing a database.

These tests protect the numbers the dashboard and README rely on. Run with:
    python -m unittest discover -s tests -v
"""
from __future__ import annotations

import csv
import unittest
from decimal import Decimal
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
EXPORTS = ROOT / "exports"

EXPECTED_ROWS = {
    "dim_customers.csv": 96096,
    "dim_date.csv": 1096,
    "dim_products.csv": 32951,
    "dim_sellers.csv": 3095,
    "fact_order_items.csv": 110197,
    "olist_cohort_retention.csv": 221,
    "rfm_segment_summary.csv": 6,
}

TOTAL_REVENUE = Decimal("13221498.11")
TOTAL_CUSTOMERS = 93358


def read(name: str) -> list[dict[str, str]]:
    with (EXPORTS / name).open(newline="", encoding="utf-8") as handle:
        return list(csv.DictReader(handle))


class ExportTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.fact = read("fact_order_items.csv")
        cls.customers = read("dim_customers.csv")
        cls.products = read("dim_products.csv")
        cls.sellers = read("dim_sellers.csv")
        cls.dates = read("dim_date.csv")
        cls.cohorts = read("olist_cohort_retention.csv")
        cls.rfm = read("rfm_segment_summary.csv")

    def test_row_counts_match_the_loaded_tables(self) -> None:
        actual = {
            "dim_customers.csv": len(self.customers),
            "dim_date.csv": len(self.dates),
            "dim_products.csv": len(self.products),
            "dim_sellers.csv": len(self.sellers),
            "fact_order_items.csv": len(self.fact),
            "olist_cohort_retention.csv": len(self.cohorts),
            "rfm_segment_summary.csv": len(self.rfm),
        }
        self.assertEqual(actual, EXPECTED_ROWS)

    def test_fact_keys_are_unique(self) -> None:
        keys = {(row["order_id"], row["order_item_id"]) for row in self.fact}
        self.assertEqual(len(keys), len(self.fact))

    def test_fact_revenue_matches_the_readme(self) -> None:
        revenue = sum(Decimal(row["price"]) for row in self.fact)
        self.assertEqual(revenue.quantize(Decimal("0.01")), TOTAL_REVENUE)

    def test_fact_references_existing_dimensions(self) -> None:
        product_ids = {row["product_id"] for row in self.products}
        seller_ids = {row["seller_id"] for row in self.sellers}
        customer_ids = {row["customer_unique_id"] for row in self.customers}

        self.assertEqual({row["product_id"] for row in self.fact} - product_ids, set())
        self.assertEqual({row["seller_id"] for row in self.fact} - seller_ids, set())
        self.assertEqual(
            {row["customer_unique_id"] for row in self.fact} - customer_ids, set()
        )

    def test_late_delivery_fields_are_consistent(self) -> None:
        null_delay = sum(1 for row in self.fact if row["delay_days"] == "")
        late_orders = {
            row["order_id"] for row in self.fact if row["is_late"] == "1"
        }
        self.assertEqual(null_delay, 8)
        self.assertEqual(len(late_orders), 6534)
        self.assertLessEqual(
            {row["is_late"] for row in self.fact}, {"", "0", "1"}
        )
        for row in self.fact:
            if row["delay_days"] == "":
                self.assertEqual(row["is_late"], "")

    def test_dimension_keys_are_unique(self) -> None:
        self.assertEqual(
            len({row["customer_unique_id"] for row in self.customers}),
            len(self.customers),
        )
        self.assertEqual(
            len({row["product_id"] for row in self.products}), len(self.products)
        )
        self.assertEqual(
            len({row["seller_id"] for row in self.sellers}), len(self.sellers)
        )
        self.assertEqual(len({row["date"] for row in self.dates}), len(self.dates))

    def test_date_dimension_covers_the_documented_window(self) -> None:
        dates = [row["date"] for row in self.dates]
        self.assertEqual(min(dates), "2016-01-01")
        self.assertEqual(max(dates), "2018-12-31")

    def test_cohort_table_is_complete_and_month_zero_is_100_percent(self) -> None:
        pairs = {
            (row["cohort_month"], row["month_number"]) for row in self.cohorts
        }
        self.assertEqual(len(pairs), len(self.cohorts))
        self.assertLessEqual(
            {int(row["month_number"]) for row in self.cohorts}, set(range(13))
        )
        month_zero = [row for row in self.cohorts if row["month_number"] == "0"]
        self.assertEqual(len(month_zero), 23)
        self.assertEqual({row["retention_pct"] for row in month_zero}, {"100.00"})

    def test_rfm_summary_reconciles_to_totals(self) -> None:
        segments = {row["segment"] for row in self.rfm}
        self.assertEqual(
            segments,
            {"One-time", "Big Spenders", "At Risk", "Lost", "Champions", "Loyal"},
        )
        self.assertEqual(sum(int(row["customers"]) for row in self.rfm), TOTAL_CUSTOMERS)
        revenue = sum(Decimal(row["revenue"]) for row in self.rfm)
        self.assertEqual(revenue.quantize(Decimal("0.01")), TOTAL_REVENUE)
        customer_pct = sum(Decimal(row["customer_pct"]) for row in self.rfm)
        revenue_pct = sum(Decimal(row["revenue_pct"]) for row in self.rfm)
        self.assertAlmostEqual(float(customer_pct), 100.0, delta=0.05)
        self.assertAlmostEqual(float(revenue_pct), 100.0, delta=0.05)


if __name__ == "__main__":
    unittest.main()
