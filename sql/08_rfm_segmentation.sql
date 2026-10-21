-- 08_rfm_segmentation.sql
-- RFM segmentation on delivered orders. Customer identity = customer_unique_id,
-- revenue = SUM(price). The logic is written once as two views and the three
-- queries below read from them (no repeated CTEs).
--
-- Rules
--   Recency   = days from the customer's last order to (last order date in data + 1)
--   Frequency = number of delivered orders, grouped by rule: 1, 2, 3+
--               (NTILE is NOT used: 97% of customers have exactly 1 order, so
--               NTILE would split identical values into different buckets.)
--   Monetary  = total item price
--   Recency and Monetary are scored 1-5 with NTILE(5) over all customers.
--   Limitation: the quintiles are computed across the whole customer base,
--   which is 97% one-time buyers, so thresholds describe the whole base and
--   not only repeat buyers.
--   Segments are checked in this order: One-time, Champions, Loyal,
--   Big Spenders, Lost, At Risk (everything else).
--
-- Run:  psql -d olist -f sql/08_rfm_segmentation.sql


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
    END AS segment,
    CASE
        WHEN frequency = 1 THEN '1 order'
        WHEN frequency = 2 THEN '2 orders'
        ELSE '3+ orders'
    END AS frequency_group
FROM scored;


-- Segment summary (6 rows), also exported for the Power BI Customer Segments page
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


-- Q1. TOP 20 CUSTOMERS BY SPEND
-- Question: Who are the highest-spending customers and how often do they buy?
-- Approach: Rank customers by total delivered item spend.
-- Findings: The top 20 customers spent between R$3,700 and R$13,440 (the best is R$13,440 on a single order). 18 of the top 20 placed only one order, so the highest spenders are mostly one-time buyers, not loyal ones.

SELECT
    customer_unique_id,
    recency_days,
    frequency,
    ROUND(monetary, 2) AS monetary
FROM rfm_segments
ORDER BY monetary DESC
LIMIT 20;


-- Q2. RFM SEGMENT SUMMARY
-- Question: How big is each segment and how much revenue does it bring?
-- Approach: Count customers and sum revenue per segment from the segment view.
-- Findings: One-time customers are 90,557 (97.00%) and bring 94.49% of revenue (R$137.96 average spend). The 2,801 repeat customers (3.00%) bring 5.51%: Big Spenders 1,991 (R$305.44 average), At Risk 527 (R$75.11), Lost 126 (R$67.12), Champions 114 (R$490.16, last order 93 days ago on average) and Loyal 43 (R$380.69).

SELECT *
FROM rfm_segment_summary
ORDER BY customers DESC;


-- Q3. CUSTOMER LIST BY SEGMENT
-- Question: Which customers belong to each segment?
-- Approach: Return every customer with its scores and segment, repeat segments first and highest spenders first.
-- Findings: The list covers 93,358 customers. Only 228 have 3 or more orders and 2,573 have exactly 2, which is why Champions (114) and Loyal (43) are so small and the frequency rule matters more than the NTILE scores.

SELECT
    customer_unique_id,
    recency_days,
    frequency,
    frequency_group,
    ROUND(monetary, 2) AS monetary,
    recency_score,
    monetary_score,
    segment
FROM rfm_segments
ORDER BY
    CASE segment
        WHEN 'Champions' THEN 1
        WHEN 'Loyal' THEN 2
        WHEN 'Big Spenders' THEN 3
        WHEN 'At Risk' THEN 4
        WHEN 'Lost' THEN 5
        ELSE 6
    END,
    monetary DESC;
