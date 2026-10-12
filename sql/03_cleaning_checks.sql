
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


-- 11: Carrier delivery date before purchase date
SELECT
    COUNT(*) AS invalid_carrier_dates
FROM orders
WHERE order_delivered_carrier_date IS NOT NULL
  AND order_purchase_timestamp IS NOT NULL
  AND order_delivered_carrier_date < order_purchase_timestamp;
