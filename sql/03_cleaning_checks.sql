
--  data quality checks here

--1: row counts ho rhi hai bsdk
SELECT 'customers' AS table_name, COUNT(*) AS row_count FROM customers
UNION ALL
SELECT 'sellers', COUNT(*) FROM sellers
UNION ALL
SELECT 'products', COUNT(*) FROM products
UNION ALL
SELECT 'category_translation', COUNT(*) FROM category_translation
UNION ALL
SELECT 'orders', COUNT(*) FROM orders
UNION ALL
SELECT 'order_items', COUNT(*) FROM order_items
UNION ALL
SELECT 'order_payments', COUNT(*) FROM order_payments
UNION ALL
SELECT 'order_reviews', COUNT(*) FROM order_reviews
UNION ALL
SELECT 'geolocation', COUNT(*) FROM geolocation;


--2:  checking fkin null values

SELECT
    COUNT(*) AS total_orders,
    COUNT(order_id) AS order_id_filled,
    COUNT(customer_id) AS customer_id_filled,
    COUNT(order_status) AS order_status_filled,
    COUNT(order_purchase_timestamp) AS purchase_date_filled,
    COUNT(order_delivered_customer_date) AS delivered_date_filled
FROM orders;



--3: null delivery date by order status

SELECT
    order_status,
    COUNT(*) AS orders_without_delivery_date
FROM orders
WHERE order_delivered_customer_date IS NULL
GROUP BY order_status
ORDER BY orders_without_delivery_date DESC;


--4: duplicate records here

SELECT
    order_id,
    COUNT(*) AS occurrence_count
FROM orders
GROUP BY order_id
HAVING COUNT(*) > 1;


--5: orphan order items

SELECT
    COUNT(*) AS orphan_order_items
FROM order_items oi
LEFT JOIN orders o
    ON oi.order_id = o.order_id
WHERE o.order_id IS NULL;


-- 6: Orphan order items: products
SELECT
    COUNT(*) AS orphan_product_references
FROM order_items oi
LEFT JOIN products p
    ON oi.product_id = p.product_id
WHERE p.product_id IS NULL;


-- 7: Orphan order items: sellers
SELECT
    COUNT(*) AS orphan_seller_references
FROM order_items oi
LEFT JOIN sellers s
    ON oi.seller_id = s.seller_id
WHERE s.seller_id IS NULL;


-- 8:  Delivery date before purchase date
SELECT
    COUNT(*) AS invalid_delivery_dates
FROM orders
WHERE order_delivered_customer_date IS NOT NULL
  AND order_purchase_timestamp IS NOT NULL
  AND order_delivered_customer_date < order_purchase_timestamp;


-- 9:  Approval date before purchase date
SELECT
    COUNT(*) AS invalid_approval_dates
FROM orders
WHERE order_approved_at IS NOT NULL
  AND order_purchase_timestamp IS NOT NULL
  AND order_approved_at < order_purchase_timestamp;


-- 10:  Carrier delivery date before purchase date
SELECT
    COUNT(*) AS invalid_carrier_dates
FROM orders
WHERE order_delivered_carrier_date IS NOT NULL
  AND order_purchase_timestamp IS NOT NULL
  AND order_delivered_carrier_date < order_purchase_timestamp;


-- 11: Order-status distribution
SELECT
    order_status,
    COUNT(*) AS order_count
FROM orders
GROUP BY order_status
ORDER BY order_count DESC;


-- 12:Duplicate review_id
SELECT
    review_id,
    COUNT(*) AS occurrence_count
FROM order_reviews
GROUP BY review_id
HAVING COUNT(*) > 1;


-- 13: Negative price
SELECT COUNT(*) AS negative_freight_count
FROM order_items
WHERE freight_value < 0;


-- 14: Negative freight
SELECT COUNT(*) AS negative_freight_count
FROM order_items
WHERE freight_value < 0;


-- 15: Products with NULL category
SELECT COUNT(*) AS products_without_category
FROM products
WHERE product_category_name IS NULL;


-- 16: Missing English category translation
SELECT COUNT(*) AS products_without_translation
FROM products p
LEFT JOIN category_translation ct
    ON p.product_category_name = ct.product_category_name
WHERE p.product_category_name IS NOT NULL
  AND ct.product_category_name IS NULL;


--17: Purchase date range
SELECT
    MIN(order_purchase_timestamp) AS earliest_purchase,
    MAX(order_purchase_timestamp) AS latest_purchase
FROM orders;


-- 18: Month-wise order count
 SELECT
    DATE_TRUNC('month', order_purchase_timestamp) AS order_month,
    COUNT(*) AS order_count
FROM orders
WHERE order_purchase_timestamp IS NOT NULL
GROUP BY 1
ORDER BY 1;


-- 19: Orders without items
SELECT COUNT(*) AS orders_without_items
FROM orders o
LEFT JOIN order_items oi
    ON o.order_id = oi.order_id
WHERE oi.order_id IS NULL;





-- ASSUMPTIONS / DECISIONS

-- 1. Order status:
-- Delivered orders will be used for revenue and delivery analysis.
-- Non-delivered statuses will not be treated as completed sales.

-- 2. Missing delivery dates:
-- NULL delivery dates are retained in the raw data.
-- Delivery-time analysis will require a valid delivery date.

-- 3. Carrier-date anomalies:
-- 166 orders have carrier dates earlier than purchase timestamps.
-- Raw data will not be modified. These records will be flagged/handled
-- appropriately when delivery timing is analyzed.

-- 4. Missing product categories:
-- 610 products have NULL category names.
-- NULL categories are retained; the analytical product dimension
-- will handle missing categories explicitly.

-- 5. Missing category translations:
-- 13 products have categories without an English translation.
-- Original category values are retained and English names are used
-- where a translation exists.

-- 6. Orders without items:
-- 775 orders have no corresponding order_items records.
-- These orders are retained in the raw data. Item-level analysis
-- will naturally include only orders with items.

-- 7. Sparse date periods:
-- The dataset spans September 2016 to October 2018.
-- Early and endpoint periods are treated cautiously because
-- the dataset is sparse/incomplete in those periods.


