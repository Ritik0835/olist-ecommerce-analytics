-- 03_cleaning_checks.sql
-- Data quality checks on the raw Olist tables.
-- Raw data is never modified; every decision is recorded in the
-- ASSUMPTIONS section at the bottom.
-- Run:  psql -d olist -f sql/03_cleaning_checks.sql
-- After running, paste each output into the "Result:" line above its query.


-- 1. Row counts per table
-- Result: customers 99,441 | sellers 3,095 | products 32,951 | category_translation 71 | orders 99,441 | order_items 112,650 | order_payments 103,886 | order_reviews 99,224 | geolocation 1,000,163.
SELECT 'customers' AS table_name, COUNT(*) AS row_count FROM customers
UNION ALL SELECT 'sellers', COUNT(*) FROM sellers
UNION ALL SELECT 'products', COUNT(*) FROM products
UNION ALL SELECT 'category_translation', COUNT(*) FROM category_translation
UNION ALL SELECT 'orders', COUNT(*) FROM orders
UNION ALL SELECT 'order_items', COUNT(*) FROM order_items
UNION ALL SELECT 'order_payments', COUNT(*) FROM order_payments
UNION ALL SELECT 'order_reviews', COUNT(*) FROM order_reviews
UNION ALL SELECT 'geolocation', COUNT(*) FROM geolocation;


-- 2. NULL counts in key order columns
-- Result: 99,441 orders; no NULLs in order_id, customer_id, order_status or purchase date; delivered date filled for 96,476.
SELECT
    COUNT(*)                              AS total_orders,
    COUNT(order_id)                       AS order_id_filled,
    COUNT(customer_id)                    AS customer_id_filled,
    COUNT(order_status)                   AS order_status_filled,
    COUNT(order_purchase_timestamp)       AS purchase_date_filled,
    COUNT(order_delivered_customer_date)  AS delivered_date_filled
FROM orders;


-- 3. Orders without a delivery date, by status
-- Result: shipped 1,107 | canceled 619 | unavailable 609 | invoiced 314 | processing 301 | delivered 8 | created 5 | approved 2. Expected for non-delivered orders; 8 delivered orders are the real gap.
SELECT order_status, COUNT(*) AS orders_without_delivery_date
FROM orders
WHERE order_delivered_customer_date IS NULL
GROUP BY order_status
ORDER BY orders_without_delivery_date DESC;


-- 4. Duplicate order_id (sanity check, order_id is the primary key)
-- Result: 0 rows (no duplicate order_id).
SELECT order_id, COUNT(*) AS occurrence_count
FROM orders
GROUP BY order_id
HAVING COUNT(*) > 1;


-- 5. Orphan order_items: order missing
-- Result: 0.
SELECT COUNT(*) AS orphan_order_items
FROM order_items oi
LEFT JOIN orders o ON oi.order_id = o.order_id
WHERE o.order_id IS NULL;


-- 6. Orphan order_items: product missing
-- Result: 0.
SELECT COUNT(*) AS orphan_product_references
FROM order_items oi
LEFT JOIN products p ON oi.product_id = p.product_id
WHERE p.product_id IS NULL;


-- 7. Orphan order_items: seller missing
-- Result: 0.
SELECT COUNT(*) AS orphan_seller_references
FROM order_items oi
LEFT JOIN sellers s ON oi.seller_id = s.seller_id
WHERE s.seller_id IS NULL;


-- 8. Delivery date before purchase date
-- Result: 0.
SELECT COUNT(*) AS invalid_delivery_dates
FROM orders
WHERE order_delivered_customer_date IS NOT NULL
  AND order_purchase_timestamp IS NOT NULL
  AND order_delivered_customer_date < order_purchase_timestamp;


-- 9. Approval date before purchase date
-- Result: 0.
SELECT COUNT(*) AS invalid_approval_dates
FROM orders
WHERE order_approved_at IS NOT NULL
  AND order_purchase_timestamp IS NOT NULL
  AND order_approved_at < order_purchase_timestamp;


-- 10. Carrier handover date before purchase date
-- Result: 166 (carrier dates are not used in any metric).
SELECT COUNT(*) AS invalid_carrier_dates
FROM orders
WHERE order_delivered_carrier_date IS NOT NULL
  AND order_purchase_timestamp IS NOT NULL
  AND order_delivered_carrier_date < order_purchase_timestamp;


-- 11. Order status distribution
-- Result: delivered 96,478 | shipped 1,107 | canceled 625 | unavailable 609 | invoiced 314 | processing 301 | created 5 | approved 2.
SELECT order_status, COUNT(*) AS order_count
FROM orders
GROUP BY order_status
ORDER BY order_count DESC;


-- 12. Duplicate review_id values
-- Result: review_id repeats across rows (some appear 3 times). order_reviews has 99,224 rows but 98,410 distinct review_id, so review_id alone is not unique. Decision: primary key is (review_id, order_id).
SELECT review_id, COUNT(*) AS occurrence_count
FROM order_reviews
GROUP BY review_id
HAVING COUNT(*) > 1
ORDER BY occurrence_count DESC
LIMIT 10;


-- 13. Orders with more than one review (why the latest review is used)
-- Result: 547 orders have more than one review; the latest review is used.
SELECT COUNT(*) AS orders_with_multiple_reviews
FROM (
    SELECT order_id
    FROM order_reviews
    GROUP BY order_id
    HAVING COUNT(*) > 1
) t;


-- 14. Negative or zero price
-- Result: 0.
SELECT COUNT(*) AS non_positive_price_items
FROM order_items
WHERE price <= 0;


-- 15. Negative freight
-- Result: 0.
SELECT COUNT(*) AS negative_freight_items
FROM order_items
WHERE freight_value < 0;


-- 16. Products with NULL category
-- Result: 610.
SELECT COUNT(*) AS products_without_category
FROM products
WHERE product_category_name IS NULL;


-- 17. Categories missing an English translation
-- Result: 13.
SELECT COUNT(*) AS products_without_translation
FROM products p
LEFT JOIN category_translation ct
    ON p.product_category_name = ct.product_category_name
WHERE p.product_category_name IS NOT NULL
  AND ct.product_category_name IS NULL;


-- 18. Purchase date range
-- Result: 2016-09-04 21:15:19 to 2018-10-17 17:30:18.
SELECT
    MIN(order_purchase_timestamp) AS earliest_purchase,
    MAX(order_purchase_timestamp) AS latest_purchase
FROM orders;


-- 19. Month-wise order count (shows sparse start and end months)
-- Result: 2016 has only 4 (Sep), 324 (Oct), none in Nov, 1 (Dec). Jan 2017 = 800, growing to 7,544 in Nov 2017 and about 6,100-7,300 per month in 2018 (Aug 2018 = 6,512). Sep 2018 = 16 and Oct 2018 = 4, so both ends are sparse.
SELECT
    DATE_TRUNC('month', order_purchase_timestamp)::date AS order_month,
    COUNT(*) AS order_count
FROM orders
WHERE order_purchase_timestamp IS NOT NULL
GROUP BY 1
ORDER BY 1;


-- 20. Orders without any items
-- Result: 775.
SELECT COUNT(*) AS orders_without_items
FROM orders o
LEFT JOIN order_items oi ON o.order_id = oi.order_id
WHERE oi.order_id IS NULL;


-- 21. Delivered orders with a missing delivery date
-- Result: 8.
SELECT COUNT(*) AS delivered_without_delivery_date
FROM orders
WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NULL;


-- 22. Orders with more than one payment row (why payments are not joined to items)
-- Result: 2,961 orders have more than one payment row.
SELECT COUNT(*) AS orders_with_multiple_payments
FROM (
    SELECT order_id
    FROM order_payments
    GROUP BY order_id
    HAVING COUNT(*) > 1
) t;


-- ASSUMPTIONS / DECISIONS
--
-- 1. Revenue definition: SUM(order_items.price) for delivered orders only.
--    Freight is excluded. Payments are not used for revenue because one
--    order can have several payment rows (check 22), which would double
--    count revenue if joined to items.
--
-- 2. Order status: only 'delivered' orders count as completed sales.
--    Canceled, unavailable, shipped, invoiced, processing, created and
--    approved orders are excluded from the fact table.
--
-- 3. Missing delivery dates: raw NULLs are kept. A small number of
--    delivered orders have no delivery date; their delivery_days,
--    delay_days and is_late are NULL and excluded from late-delivery rates.
--
-- 4. Late definition: delivered date (date part) > estimated date
--    (date part). Used identically in views, SQL analysis and Power BI.
--
-- 5. Reviews: review_id is not unique in the raw data, so the primary key is
--    (review_id, order_id) and all 99,224 rows are loaded. 547 orders have
--    more than one review (check 13); the latest review per order is used
--    (review_creation_date DESC).
--
-- 6. Carrier-date anomalies: 166 orders have a carrier date earlier than
--    the purchase timestamp. Raw data is not changed; carrier dates are
--    not used in any metric.
--
-- 7. Missing categories: 610 products have a NULL category; shown as
--    'Unknown' in dim_products. 13 products have a category without an
--    English translation; the original Portuguese name is kept.
--
-- 8. Orders without items: 775 orders have no order_items rows. They are
--    retained in raw data and excluded from item-level analysis.
--
-- 9. Date range: the data runs from Sep 2016 to Oct 2018 but 2016 and the
--    last months are sparse. Trend charts use Jan 2017 to Aug 2018.
--    Cohort analysis uses cohorts from Jan 2017 to Aug 2018.
--
-- 10. Customer identity: customer_id changes per order; retention and RFM
--     use customer_unique_id.
