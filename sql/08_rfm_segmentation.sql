-- Question: What are each customer's recency, frequency, and monetary value?
-- Approach: Aggregate delivered orders by customer_unique_id and calculate RFM metrics.
-- Findings: Pending execution; update this comment after reviewing the query output.

WITH customer_orders AS (
    SELECT
        c.customer_unique_id,
        o.order_id,
        o.order_purchase_timestamp::date AS order_date,
        SUM(oi.price) AS order_value
    FROM orders o
    JOIN customers c
        ON c.customer_id = o.customer_id
    JOIN order_items oi
        ON oi.order_id = o.order_id
    WHERE o.order_status = 'delivered'
      AND o.order_purchase_timestamp IS NOT NULL
    GROUP BY
        c.customer_unique_id,
        o.order_id,
        o.order_purchase_timestamp::date
),
snapshot AS (
    SELECT MAX(order_date) + 1 AS snapshot_date
    FROM customer_orders
)
SELECT
    co.customer_unique_id,
    (s.snapshot_date - MAX(co.order_date)) AS recency_days,
    COUNT(DISTINCT co.order_id) AS frequency,
    ROUND(SUM(co.order_value)::numeric, 2) AS monetary
FROM customer_orders co
CROSS JOIN snapshot s
GROUP BY co.customer_unique_id, s.snapshot_date
ORDER BY monetary DESC
LIMIT 20;


-- Question: How can customers be assigned to six actionable RFM segments?
-- Approach: Score recency and monetary with NTILE(5), classify frequency by order-count rules, then apply segment priority.
-- Findings: Pending execution; update this comment after reviewing the segment distribution.

WITH customer_orders AS (
    SELECT
        c.customer_unique_id,
        o.order_id,
        o.order_purchase_timestamp::date AS order_date,
        SUM(oi.price) AS order_value
    FROM orders o
    JOIN customers c
        ON c.customer_id = o.customer_id
    JOIN order_items oi
        ON oi.order_id = o.order_id
    WHERE o.order_status = 'delivered'
      AND o.order_purchase_timestamp IS NOT NULL
    GROUP BY
        c.customer_unique_id,
        o.order_id,
        o.order_purchase_timestamp::date
),
snapshot AS (
    SELECT MAX(order_date) + 1 AS snapshot_date
    FROM customer_orders
),
rfm AS (
    SELECT
        co.customer_unique_id,
        s.snapshot_date - MAX(co.order_date) AS recency_days,
        COUNT(DISTINCT co.order_id) AS frequency,
        SUM(co.order_value) AS monetary
    FROM customer_orders co
    CROSS JOIN snapshot s
    GROUP BY co.customer_unique_id, s.snapshot_date
),
scored AS (
    SELECT
        *,
        NTILE(5) OVER (ORDER BY recency_days DESC) AS recency_score,
        NTILE(5) OVER (ORDER BY monetary ASC) AS monetary_score,
        CASE
            WHEN frequency = 1 THEN '1 order'
            WHEN frequency = 2 THEN '2 orders'
            ELSE '3+ orders'
        END AS frequency_group
    FROM rfm
),
segmented AS (
    SELECT
        *,
        CASE
            WHEN frequency = 1 THEN 'One-time'
            WHEN recency_score >= 4
                 AND monetary_score >= 4
                 AND frequency >= 3 THEN 'Champions'
            WHEN recency_score >= 3
                 AND frequency >= 3 THEN 'Loyal'
            WHEN monetary_score >= 4 THEN 'Big Spenders'
            WHEN recency_score = 1
                 AND frequency >= 2 THEN 'Lost'
            WHEN recency_score <= 2
                 AND frequency >= 2 THEN 'At Risk'
            ELSE 'Others'
        END AS segment
    FROM scored
)
SELECT
    segment,
    COUNT(*) AS customers,
    ROUND(
        100.0 * COUNT(*) / SUM(COUNT(*)) OVER (),
        2
    ) AS customer_pct,
    ROUND(AVG(monetary)::numeric, 2) AS avg_customer_spend,
    ROUND(AVG(recency_days)::numeric, 2) AS avg_recency_days
FROM segmented
GROUP BY segment
ORDER BY customers DESC;


-- Question: Which customers belong to each RFM segment?
-- Approach: Reuse the same customer-level metrics and scoring rules to return the segment-level customer list.
-- Findings: Pending execution; update this comment after reviewing the output.

WITH customer_orders AS (
    SELECT
        c.customer_unique_id,
        o.order_id,
        o.order_purchase_timestamp::date AS order_date,
        SUM(oi.price) AS order_value
    FROM orders o
    JOIN customers c
        ON c.customer_id = o.customer_id
    JOIN order_items oi
        ON oi.order_id = o.order_id
    WHERE o.order_status = 'delivered'
      AND o.order_purchase_timestamp IS NOT NULL
    GROUP BY
        c.customer_unique_id,
        o.order_id,
        o.order_purchase_timestamp::date
),
snapshot AS (
    SELECT MAX(order_date) + 1 AS snapshot_date
    FROM customer_orders
),
rfm AS (
    SELECT
        co.customer_unique_id,
        s.snapshot_date - MAX(co.order_date) AS recency_days,
        COUNT(DISTINCT co.order_id) AS frequency,
        SUM(co.order_value) AS monetary
    FROM customer_orders co
    CROSS JOIN snapshot s
    GROUP BY co.customer_unique_id, s.snapshot_date
),
scored AS (
    SELECT
        *,
        NTILE(5) OVER (ORDER BY recency_days DESC) AS recency_score,
        NTILE(5) OVER (ORDER BY monetary ASC) AS monetary_score
    FROM rfm
)
SELECT
    customer_unique_id,
    recency_days,
    frequency,
    CASE
        WHEN frequency = 1 THEN '1 order'
        WHEN frequency = 2 THEN '2 orders'
        ELSE '3+ orders'
    END AS frequency_group,
    ROUND(monetary::numeric, 2) AS monetary,
    recency_score,
    monetary_score,
    CASE
        WHEN frequency = 1 THEN 'One-time'
        WHEN recency_score >= 4
             AND monetary_score >= 4
             AND frequency >= 3 THEN 'Champions'
        WHEN recency_score >= 3
             AND frequency >= 3 THEN 'Loyal'
        WHEN monetary_score >= 4 THEN 'Big Spenders'
        WHEN recency_score = 1
             AND frequency >= 2 THEN 'Lost'
        WHEN recency_score <= 2
             AND frequency >= 2 THEN 'At Risk'
        ELSE 'Others'
    END AS segment
FROM scored
ORDER BY
    CASE
        WHEN frequency = 1 THEN 6
        WHEN recency_score >= 4
             AND monetary_score >= 4
             AND frequency >= 3 THEN 1
        WHEN recency_score >= 3
             AND frequency >= 3 THEN 2
        WHEN monetary_score >= 4 THEN 3
        WHEN recency_score = 1
             AND frequency >= 2 THEN 5
        WHEN recency_score <= 2
             AND frequency >= 2 THEN 4
        ELSE 7
    END,
    monetary DESC;
