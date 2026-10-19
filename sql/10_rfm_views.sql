-- 10_rfm_views.sql
-- Packages the RFM segmentation from 08_rfm_segmentation.sql as two views
-- so Power BI can use the segment results.
-- Same rules as 08: delivered orders only, revenue = SUM(price),
-- customer identity = customer_unique_id, Recency and Monetary scored with
-- NTILE(5), Frequency by order count (1, 2, 3+).
-- Run:  psql -d olist -f sql/10_rfm_views.sql

-- Customer-level segments (one row per customer_unique_id)
CREATE OR REPLACE VIEW rfm_segments AS
WITH customer_orders AS (
    SELECT
        c.customer_unique_id,
        o.order_id,
        o.order_purchase_timestamp::date AS order_date,
        SUM(oi.price) AS order_value
    FROM orders o
    JOIN customers c ON c.customer_id = o.customer_id
    JOIN order_items oi ON oi.order_id = o.order_id
    WHERE o.order_status = 'delivered'
      AND o.order_purchase_timestamp IS NOT NULL
    GROUP BY c.customer_unique_id, o.order_id, o.order_purchase_timestamp::date
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
    monetary,
    recency_score,
    monetary_score,
    CASE
        WHEN frequency = 1 THEN 'One-time'
        WHEN recency_score >= 4 AND monetary_score >= 4 AND frequency >= 3 THEN 'Champions'
        WHEN recency_score >= 3 AND frequency >= 3 THEN 'Loyal'
        WHEN monetary_score >= 4 THEN 'Big Spenders'
        WHEN recency_score = 1 AND frequency >= 2 THEN 'Lost'
        ELSE 'At Risk'
    END AS segment
FROM scored;


-- Segment summary (6 rows) used by the Power BI RFM page
CREATE OR REPLACE VIEW rfm_segment_summary AS
SELECT
    segment,
    COUNT(*) AS customers,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS customer_pct,
    ROUND(SUM(monetary), 2) AS revenue,
    ROUND(100.0 * SUM(monetary) / SUM(SUM(monetary)) OVER (), 2) AS revenue_pct,
    ROUND(AVG(monetary), 2) AS avg_spend,
    ROUND(AVG(recency_days), 1) AS avg_recency_days
FROM rfm_segments
GROUP BY segment;
