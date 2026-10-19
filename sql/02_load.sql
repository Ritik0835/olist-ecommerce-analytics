-- 02_load.sql
-- Loads the 9 raw Olist CSV files into PostgreSQL.
-- Run from the repository root:
--     psql -d olist -f sql/02_load.sql
-- Load order respects foreign keys (parents before children).
-- Expected row counts (approx.): customers 99,441 | sellers 3,095 |
-- products 32,951 | category_translation 71 | orders 99,441 |
-- order_items 112,650 | order_payments 103,886 | order_reviews 99,224 |
-- geolocation 1,000,163

\copy customers FROM 'data/olist_customers_dataset.csv' WITH (FORMAT csv, HEADER true);
\copy sellers FROM 'data/olist_sellers_dataset.csv' WITH (FORMAT csv, HEADER true);
\copy products FROM 'data/olist_products_dataset.csv' WITH (FORMAT csv, HEADER true);
\copy category_translation FROM 'data/product_category_name_translation.csv' WITH (FORMAT csv, HEADER true);
\copy orders FROM 'data/olist_orders_dataset.csv' WITH (FORMAT csv, HEADER true);
\copy order_items FROM 'data/olist_order_items_dataset.csv' WITH (FORMAT csv, HEADER true);
\copy order_payments FROM 'data/olist_order_payments_dataset.csv' WITH (FORMAT csv, HEADER true);
\copy order_reviews FROM 'data/olist_order_reviews_dataset.csv' WITH (FORMAT csv, HEADER true);
\copy geolocation FROM 'data/olist_geolocation_dataset.csv' WITH (FORMAT csv, HEADER true);
