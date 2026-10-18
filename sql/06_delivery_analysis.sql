-- DAY 6: DELIVERY ANALYSIS

-- Q1. LATE VS ON-TIME ORDERS
-- Question: How do late deliveries relate to order counts and review scores?
-- Approach: Classify delivered orders and use the latest review per order.
-- Findings: 6,534 orders (6.77%) were late with a 2.27 average review score; 89,936 (93.23%) were on time or early with a 4.29 average review score.

WITH latest_review AS (
    SELECT DISTINCT ON (order_id)
        order_id,
        review_score
    FROM order_reviews
    ORDER BY order_id, review_creation_date DESC NULLS LAST, review_id DESC
),
order_delivery AS (
    SELECT
        o.order_id,
        CASE
            WHEN o.order_delivered_customer_date::date
                 > o.order_estimated_delivery_date::date
                THEN 'Late'
            ELSE 'On time or early'
        END AS delivery_status
    FROM orders o
    WHERE o.order_status = 'delivered'
      AND o.order_delivered_customer_date IS NOT NULL
      AND o.order_estimated_delivery_date IS NOT NULL
)
SELECT
    d.delivery_status,
    COUNT(*) AS orders,
    ROUND(
        100.0 * COUNT(*) / SUM(COUNT(*)) OVER (),
        2
    ) AS order_percentage,
    ROUND(AVG(r.review_score), 2) AS avg_review_score
FROM order_delivery d
LEFT JOIN latest_review r ON r.order_id = d.order_id
GROUP BY d.delivery_status
ORDER BY d.delivery_status;


-- Q2. AVERAGE DELIVERY DAYS BY STATE
-- Question: Which customer states have the slowest average delivery?
-- Approach: Calculate calendar days from purchase to delivery once per order.
-- Findings: RR had the slowest average delivery (29.34 days); SP had the fastest (8.70 days).

SELECT
    c.customer_state AS state,
    COUNT(*) AS delivered_orders,
    ROUND(
        AVG(
            o.order_delivered_customer_date::date
            - o.order_purchase_timestamp::date
        ),
        2
    ) AS avg_delivery_days
FROM orders o
JOIN customers c ON c.customer_id = o.customer_id
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
GROUP BY c.customer_state
ORDER BY avg_delivery_days DESC;


-- Q3. DELIVERY DELAY BUCKETS VS REVIEW SCORE
-- Question: How do different delivery delays relate to customer review scores?
-- Approach: Bucket delivery delays and compare counts, percentages, and latest review scores.
-- Findings: On-time or early orders were 89,936 (93.23%) with a 4.29 average review. Scores declined as delays increased: 1–3 days late, 1,870 orders (1.94%), score 3.29; 4–7 days late, 1,802 (1.87%), score 2.10; 8+ days late, 2,862 (2.97%), score 1.69.

WITH latest_review AS (
    SELECT DISTINCT ON (order_id)
        order_id,
        review_score
    FROM order_reviews
    ORDER BY order_id, review_creation_date DESC NULLS LAST, review_id DESC
),
order_delay AS (
    SELECT
        o.order_id,
        CASE
            WHEN o.order_delivered_customer_date::date
                 <= o.order_estimated_delivery_date::date
                THEN 'On time or early'
            WHEN o.order_delivered_customer_date::date
                 - o.order_estimated_delivery_date::date <= 3
                THEN '1-3 days late'
            WHEN o.order_delivered_customer_date::date
                 - o.order_estimated_delivery_date::date <= 7
                THEN '4-7 days late'
            ELSE '8+ days late'
        END AS delay_bucket
    FROM orders o
    WHERE o.order_status = 'delivered'
      AND o.order_delivered_customer_date IS NOT NULL
      AND o.order_estimated_delivery_date IS NOT NULL
)
SELECT
    d.delay_bucket,
    COUNT(*) AS orders,
    ROUND(
        100.0 * COUNT(*) / SUM(COUNT(*)) OVER (),
        2
    ) AS order_percentage,
    ROUND(AVG(r.review_score), 2) AS avg_review_score
FROM order_delay d
LEFT JOIN latest_review r ON r.order_id = d.order_id
GROUP BY d.delay_bucket
ORDER BY CASE d.delay_bucket
    WHEN 'On time or early' THEN 1
    WHEN '1-3 days late' THEN 2
    WHEN '4-7 days late' THEN 3
    WHEN '8+ days late' THEN 4
END;

