-- Question: Which sellers generate the highest product-sales revenue?
-- Approach: Aggregate item price by seller across delivered orders and rank sellers by revenue.
-- Findings: The highest-revenue seller in the output generated R$226,987.93 across 1,124 delivered orders and 1,148 items sold.

SELECT
    s.seller_id,
    s.seller_city,
    s.seller_state,
    COUNT(DISTINCT oi.order_id) AS delivered_orders,
    COUNT(*) AS items_sold,
    ROUND(SUM(oi.price)::numeric, 2) AS revenue
FROM sellers s
JOIN order_items oi
    ON oi.seller_id = s.seller_id
JOIN orders o
    ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
GROUP BY
    s.seller_id,
    s.seller_city,
    s.seller_state
ORDER BY revenue DESC
LIMIT 20;


-- Question: Which sellers have the highest late-delivery percentage?
-- Approach: Calculate lateness once per seller-order pair and rank sellers with at least 30 delivered orders.
-- Findings: The highest late-delivery percentage shown was 34.88% (15 late orders out of 43 delivered orders). Because this seller has a relatively small order count, interpret the rate cautiously.

WITH seller_orders AS (
    SELECT
        oi.seller_id,
        o.order_id,
        MAX(
            CASE
                WHEN o.order_delivered_customer_date >
                     o.order_estimated_delivery_date THEN 1
                ELSE 0
            END
        ) AS is_late
    FROM order_items oi
    JOIN orders o
        ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
      AND o.order_delivered_customer_date IS NOT NULL
      AND o.order_estimated_delivery_date IS NOT NULL
    GROUP BY oi.seller_id, o.order_id
)
SELECT
    s.seller_id,
    s.seller_city,
    s.seller_state,
    COUNT(*) AS delivered_orders,
    SUM(so.is_late) AS late_orders,
    ROUND(
        100.0 * SUM(so.is_late) / COUNT(*),
        2
    ) AS late_delivery_pct
FROM seller_orders so
JOIN sellers s
    ON s.seller_id = so.seller_id
GROUP BY
    s.seller_id,
    s.seller_city,
    s.seller_state
HAVING COUNT(*) >= 30
ORDER BY late_delivery_pct DESC, delivered_orders DESC
LIMIT 20;


-- Question: Which sellers have low average customer review scores?
-- Approach: Use the latest review per order, aggregate at seller-order grain, and require at least 30 reviewed orders.
-- Findings: The lowest average review score shown was 2.39 across 107 reviewed orders; that seller had a 21.50% late-delivery rate.

WITH latest_reviews AS (
    SELECT DISTINCT ON (order_id)
        order_id,
        review_score
    FROM order_reviews
    WHERE review_score IS NOT NULL
    ORDER BY
        order_id,
        review_creation_date DESC NULLS LAST,
        review_id DESC
),
seller_orders AS (
    SELECT
        oi.seller_id,
        o.order_id,
        MAX(lr.review_score) AS review_score,
        MAX(
            CASE
                WHEN o.order_delivered_customer_date >
                     o.order_estimated_delivery_date THEN 1
                ELSE 0
            END
        ) AS is_late
    FROM order_items oi
    JOIN orders o
        ON o.order_id = oi.order_id
    LEFT JOIN latest_reviews lr
        ON lr.order_id = o.order_id
    WHERE o.order_status = 'delivered'
      AND o.order_delivered_customer_date IS NOT NULL
      AND o.order_estimated_delivery_date IS NOT NULL
    GROUP BY oi.seller_id, o.order_id
)
SELECT
    s.seller_id,
    s.seller_city,
    s.seller_state,
    COUNT(so.review_score) AS reviewed_orders,
    ROUND(AVG(so.review_score)::numeric, 2) AS avg_review_score,
    ROUND(
        100.0 * AVG(so.is_late),
        2
    ) AS late_delivery_pct
FROM seller_orders so
JOIN sellers s
    ON s.seller_id = so.seller_id
WHERE so.review_score IS NOT NULL
GROUP BY
    s.seller_id,
    s.seller_city,
    s.seller_state
HAVING COUNT(so.review_score) >= 30
ORDER BY avg_review_score ASC, reviewed_orders DESC
LIMIT 20;


-- Question: Which product categories combine high revenue with low reviews or frequent late deliveries?
-- Approach: Aggregate at category-order grain to avoid counting the same order's review or delivery outcome multiple times within a category.
-- Findings: Health & Beauty led category revenue at R$1,233,131.72 with a 4.23 average review score and 7.51% late delivery. Audio had the highest late-delivery rate in the output at 11.78% (348 orders), while Home Comfort was at 9.44%.

WITH category_orders AS (
    SELECT
        COALESCE(dp.category_english, 'Unknown') AS category,
        f.order_id,
        SUM(f.price) AS order_category_revenue,
        MAX(f.review_score) AS review_score,
        MAX(COALESCE(f.is_late, 0)) AS is_late
    FROM fact_order_items f
    JOIN dim_products dp
        ON dp.product_id = f.product_id
    GROUP BY
        COALESCE(dp.category_english, 'Unknown'),
        f.order_id
)
SELECT
    category,
    COUNT(*) AS orders,
    ROUND(SUM(order_category_revenue)::numeric, 2) AS revenue,
    ROUND(AVG(review_score)::numeric, 2) AS avg_review_score,
    ROUND(
        100.0 * AVG(is_late),
        2
    ) AS late_delivery_pct
FROM category_orders
GROUP BY category
HAVING COUNT(*) >= 30
ORDER BY revenue DESC;

