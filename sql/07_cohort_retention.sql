
-- COHORT RETENTION ANALYSIS

-- Q1. CUSTOMER COHORTS
-- Question: How many unique customers belong to each first-purchase month?
-- Approach: Find each customer's first delivered-order month using customer_unique_id.
-- Findings: Cohort sizes vary substantially
-- October 2016 had 262 customers, while September and December 2016 each had only 1 customer.

WITH delivered AS (
    SELECT DISTINCT
        c.customer_unique_id,
        DATE_TRUNC('month', o.order_purchase_timestamp)::date AS order_month
    FROM orders o
    JOIN customers c
        ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered'
      AND o.order_purchase_timestamp IS NOT NULL
),
cohorts AS (
    SELECT
        customer_unique_id,
        MIN(order_month) AS cohort_month
    FROM delivered
    GROUP BY customer_unique_id
)
SELECT
    cohort_month,
    COUNT(*) AS cohort_size
FROM cohorts
GROUP BY cohort_month
ORDER BY cohort_month;


-- Q2. MONTHLY COHORT RETENTION
-- Question: What percentage of each cohort returns in months 0 through 12?
-- Approach: Count distinct active customers by cohort and month number, then divide by cohort size.
-- Findings: October 2016 retention was 100% in month 0,
-- 0% in months 1-5; month 6 was 0.38%. 

WITH delivered AS (
    SELECT DISTINCT
        c.customer_unique_id,
        DATE_TRUNC('month', o.order_purchase_timestamp)::date AS order_month
    FROM orders o
    JOIN customers c
        ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered'
      AND o.order_purchase_timestamp IS NOT NULL
),
cohorts AS (
    SELECT
        customer_unique_id,
        MIN(order_month) AS cohort_month
    FROM delivered
    GROUP BY customer_unique_id
),
cohort_sizes AS (
    SELECT
        cohort_month,
        COUNT(*) AS cohort_size
    FROM cohorts
    GROUP BY cohort_month
),
activity AS (
    SELECT
        co.cohort_month,
        (
            EXTRACT(YEAR FROM AGE(d.order_month, co.cohort_month)) * 12
            + EXTRACT(MONTH FROM AGE(d.order_month, co.cohort_month))
        )::int AS month_number,
        COUNT(DISTINCT d.customer_unique_id) AS active_customers
    FROM cohorts co
    JOIN delivered d
        ON d.customer_unique_id = co.customer_unique_id
    GROUP BY co.cohort_month, month_number
),
last_month AS (
    SELECT MAX(order_month) AS max_order_month
    FROM delivered
),
cohort_periods AS (
    SELECT
        cs.cohort_month,
        cs.cohort_size,
        n.month_number
    FROM cohort_sizes cs
    CROSS JOIN generate_series(0, 12) AS n(month_number)
    CROSS JOIN last_month lm
    WHERE (
        cs.cohort_month + n.month_number * INTERVAL '1 month'
    )::date <= lm.max_order_month
)
SELECT
    cp.cohort_month,
    cp.month_number,
    cp.cohort_size,
    COALESCE(a.active_customers, 0) AS active_customers,
    ROUND(
        100.0 * COALESCE(a.active_customers, 0)
        / NULLIF(cp.cohort_size, 0),
        2
    ) AS retention_pct
FROM cohort_periods cp
LEFT JOIN activity a
    ON a.cohort_month = cp.cohort_month
   AND a.month_number = cp.month_number
ORDER BY cp.cohort_month, cp.month_number;
