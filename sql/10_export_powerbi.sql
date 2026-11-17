-- 10_export_powerbi.sql
-- Regenerate the CSV tables consumed by the Power BI report.
-- Run from the repository root, after the database and views exist:
--     psql -v ON_ERROR_STOP=1 -d olist -f sql/10_export_powerbi.sql
-- Ordering is explicit so repeated exports are byte-identical.

\copy (SELECT customer_unique_id, city, state FROM dim_customers ORDER BY customer_unique_id) TO 'exports/dim_customers.csv' WITH (FORMAT csv, HEADER true)

\copy (SELECT date, year, month, month_name, quarter, week FROM dim_date ORDER BY date) TO 'exports/dim_date.csv' WITH (FORMAT csv, HEADER true)

\copy (SELECT product_id, category_english FROM dim_products ORDER BY product_id) TO 'exports/dim_products.csv' WITH (FORMAT csv, HEADER true)

\copy (SELECT seller_id, city, state FROM dim_sellers ORDER BY seller_id) TO 'exports/dim_sellers.csv' WITH (FORMAT csv, HEADER true)

\copy (SELECT order_id, order_item_id, product_id, seller_id, customer_unique_id, order_date, price, freight_value, delivery_days, delay_days, is_late, review_score FROM fact_order_items ORDER BY order_id, order_item_id) TO 'exports/fact_order_items.csv' WITH (FORMAT csv, HEADER true)

\copy (SELECT cohort_month, month_number, cohort_size, active_customers, retention_pct FROM cohort_retention ORDER BY cohort_month, month_number) TO 'exports/olist_cohort_retention.csv' WITH (FORMAT csv, HEADER true)

\copy (SELECT segment, customers, customer_pct, revenue, revenue_pct, avg_spend, avg_recency_days FROM rfm_segment_summary ORDER BY customers DESC) TO 'exports/rfm_segment_summary.csv' WITH (FORMAT csv, HEADER true)
