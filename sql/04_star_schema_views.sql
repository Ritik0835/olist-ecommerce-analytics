-- Olist E-Commerce Analytics


-- 1. CUSTOMER DIMENSION
-- Purpose: Keep one row per unique customer.
CREATE OR REPLACE VIEW dim_customers AS
SELECT DISTINCT ON (customer_unique_id)
    customer_unique_id,
    customer_city AS city,
    customer_state AS state
FROM customers
ORDER BY customer_unique_id, customer_id;




-- 2. PRODUCT DIMENSION
CREATE OR REPLACE VIEW dim_products AS
SELECT
    p.product_id,
    COALESCE(
        ct.product_category_name_english,
        p.product_category_name,
        'Unknown'
    ) AS category_english
FROM products p
LEFT JOIN category_translation ct
    ON p.product_category_name = ct.product_category_name;


-- 3. SELLER DIMENSION
CREATE OR REPLACE VIEW dim_sellers AS
SELECT
    seller_id,
    seller_city AS city,
    seller_state AS state
FROM sellers;


-- 4. DATE DIMENSION
CREATE OR REPLACE VIEW dim_date AS
SELECT
    d::date AS date,
    EXTRACT(YEAR FROM d)::integer AS year,
    EXTRACT(MONTH FROM d)::integer AS month,
    TO_CHAR(d, 'FMMonth') AS month_name,
    EXTRACT(QUARTER FROM d)::integer AS quarter,
    EXTRACT(WEEK FROM d)::integer AS week
FROM generate_series(
    DATE '2016-01-01',
    DATE '2018-12-31',
    INTERVAL '1 day'
) AS dates(d);


-- 5. FACT ORDER ITEMS
-- Assumption: only delivered orders are included (canceled, unavailable,
-- shipped etc. are not completed sales).
-- is_late: 1 = delivered after estimated date, 0 = on time/early,
-- NULL = delivery or estimate date missing (8 delivered orders).

DROP VIEW IF EXISTS fact_order_items;

CREATE VIEW fact_order_items AS
WITH latest_reviews AS (
    SELECT order_id, review_score
    FROM (
        SELECT
            order_id,
            review_score,
            ROW_NUMBER() OVER (
                PARTITION BY order_id
                ORDER BY review_creation_date DESC NULLS LAST,
                         review_id
            ) AS rn
        FROM order_reviews
    ) ranked_reviews
    WHERE rn = 1
)
SELECT
    oi.order_id,
    oi.order_item_id,
    oi.product_id,
    oi.seller_id,
    c.customer_unique_id,
    o.order_purchase_timestamp::date AS order_date,
    oi.price,
    oi.freight_value,

    CASE
        WHEN o.order_delivered_customer_date IS NOT NULL
        THEN o.order_delivered_customer_date::date
             - o.order_purchase_timestamp::date
        ELSE NULL
    END AS delivery_days,

    CASE
        WHEN o.order_delivered_customer_date IS NOT NULL
         AND o.order_estimated_delivery_date IS NOT NULL
        THEN o.order_delivered_customer_date::date
             - o.order_estimated_delivery_date::date
        ELSE NULL
    END AS delay_days,

    CASE
        WHEN o.order_delivered_customer_date IS NOT NULL
         AND o.order_estimated_delivery_date IS NOT NULL
        THEN CASE
                 WHEN o.order_delivered_customer_date::date
                      > o.order_estimated_delivery_date::date
                 THEN 1 ELSE 0
             END
        ELSE NULL
    END AS is_late,

    r.review_score

FROM order_items oi
JOIN orders o
    ON oi.order_id = o.order_id
JOIN customers c
    ON o.customer_id = c.customer_id
LEFT JOIN latest_reviews r
    ON oi.order_id = r.order_id
WHERE o.order_status = 'delivered';
