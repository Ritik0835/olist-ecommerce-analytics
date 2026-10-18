-- REVENUE ANALYSIS
-- Olist E-Commerce Analytics



-- Q1. MONTHLY REVENUE, ORDERS AND AOV
-- Question: How do revenue, order volume and AOV change monthly?
-- Approach: Aggregate item sales by purchase month.
-- Findings: Revenue rose from R$134.97 in Sep 2016 to R$838,576.64 in Aug 2018. The highest monthly revenue was R$987,765.37 in Nov 2017; that month had 7,289 orders and an AOV of R$135.51.

SELECT
    DATE_TRUNC('month', f.order_date)::date AS month,
    ROUND(SUM(f.price), 2) AS revenue,
    COUNT(DISTINCT f.order_id) AS orders,
    ROUND(
        SUM(f.price) / NULLIF(COUNT(DISTINCT f.order_id), 0),
        2
    ) AS aov
FROM fact_order_items f
GROUP BY DATE_TRUNC('month', f.order_date)
ORDER BY month;


-- Q2. MONTH-OVER-MONTH REVENUE GROWTH
-- Question: How much does revenue grow or decline each month?
-- Approach: Compare monthly revenue with the previous month using LAG().
-- Findings: Nov 2017 had the largest positive month-over-month change among the reported months with a prior nonzero month (+52.37%). Nov 2016 showed -100.00% after Oct 2016, while Sep 2018 is also -100.00% because the generated calendar includes a month with no recorded revenue. Jan 2017 shows an unusually large percentage because Dec 2016 revenue was only R$10.90.

WITH calendar AS (
    SELECT generate_series(
        DATE '2016-09-01',
        DATE '2018-09-01',
        INTERVAL '1 month'
    )::date AS month
),
monthly AS (
    SELECT
        c.month,
        COALESCE(SUM(f.price), 0) AS revenue
    FROM calendar c
    LEFT JOIN fact_order_items f
        ON DATE_TRUNC('month', f.order_date)::date = c.month
    GROUP BY c.month
),
comparison AS (
    SELECT
        month,
        revenue,
        LAG(revenue) OVER (ORDER BY month) AS previous_revenue
    FROM monthly
)
SELECT
    month,
    ROUND(revenue, 2) AS revenue,
    ROUND(previous_revenue, 2) AS previous_revenue,
    ROUND(
        100.0 * (revenue - previous_revenue)
        / NULLIF(previous_revenue, 0),
        2
    ) AS mom_growth_pct
FROM comparison
ORDER BY month;




-- Q3. CUMULATIVE REVENUE
-- Question: How much revenue has accumulated over time?
-- Approach: Use SUM() OVER (ORDER BY month) on monthly revenue.
-- Findings: Cumulative revenue reached R$13,221,498.11 by Aug 2018. It passed R$6.00 million by Dec 2017 and R$9.68 million by Apr 2018.

WITH monthly_revenue AS (
    SELECT
        DATE_TRUNC('month', order_date)::date AS month,
        SUM(price) AS revenue
    FROM fact_order_items
    GROUP BY DATE_TRUNC('month', order_date)
)
SELECT
    month,
    ROUND(revenue, 2) AS monthly_revenue,
    ROUND(
        SUM(revenue) OVER (ORDER BY month),
        2
    ) AS cumulative_revenue
FROM monthly_revenue
ORDER BY month;


-- Q4. TOP 10 PRODUCT CATEGORIES BY REVENUE
-- Question: Which categories generate the most revenue and what is their share?
-- Approach: Aggregate item sales by category and divide by total item sales.
-- Findings: Health & Beauty led the displayed top 10 with R$1,233,131.72 (9.33% of revenue), followed by Watches & Gifts at R$1,166,176.98 (8.82%) and Bed Bath & Table at R$1,023,434.76 (7.74%).

WITH category_revenue AS (
    SELECT
        p.category_english AS category,
        SUM(f.price) AS revenue
    FROM fact_order_items f
    JOIN dim_products p
        ON f.product_id = p.product_id
    GROUP BY p.category_english
)
SELECT
    category,
    ROUND(revenue, 2) AS revenue,
    ROUND(
        100.0 * revenue / NULLIF(SUM(revenue) OVER (), 0),
        2
    ) AS revenue_share_pct
FROM category_revenue
ORDER BY revenue DESC
LIMIT 10;




-- Q5. STATE-WISE REVENUE AND ORDERS
-- Question: Which customer states generate the most revenue and orders?
-- Approach: Group item sales by customer state and count distinct orders.
-- Findings: São Paulo led state revenue at R$5,068,589.63 from 40,500 orders, followed by Rio de Janeiro at R$1,758,751.46 and Minas Gerais at R$1,552,357.35.

SELECT
    c.state,
    ROUND(SUM(f.price), 2) AS revenue,
    COUNT(DISTINCT f.order_id) AS orders
FROM fact_order_items f
JOIN dim_customers c
    ON f.customer_unique_id = c.customer_unique_id
GROUP BY c.state
ORDER BY revenue DESC;


-- Q6. OVERALL AVERAGE ORDER VALUE
-- Question: What is the average product-sales value per order?
-- Approach: Divide total item sales by the number of distinct orders.
-- Findings: Total revenue was R$13,221,498.11 across 96,478 distinct delivered orders, giving an average order value of R$137.04.

SELECT
    ROUND(SUM(price), 2) AS total_revenue,
    COUNT(DISTINCT order_id) AS total_orders,
    ROUND(
        SUM(price) / NULLIF(COUNT(DISTINCT order_id), 0),
        2
    ) AS average_order_value
FROM fact_order_items;


-- Q7. HIGHEST AND LOWEST REVENUE MONTHS
-- Question: Which months had the highest and lowest revenue?
-- Approach: Aggregate revenue by month and sort from highest to lowest.
-- Findings: Nov 2017 was the strongest month at R$987,765.37. Dec 2016 was the lowest month with recorded sales at R$10.90; months with no recorded sales are not returned by this query.

WITH monthly_revenue AS (
    SELECT
        DATE_TRUNC('month', order_date)::date AS month,
        SUM(price) AS revenue
    FROM fact_order_items
    GROUP BY DATE_TRUNC('month', order_date)
)
SELECT
    month,
    ROUND(revenue, 2) AS revenue
FROM monthly_revenue
ORDER BY revenue DESC;


-- Q8. MONTHLY ORDER AND ITEM VOLUME
-- Question: How many distinct orders and items were recorded each month?
-- Approach: Count distinct orders and individual order-item rows.
-- Findings: Nov 2017 had the highest monthly volume in the output, with 7,289 orders and 8,475 items sold. Oct 2016 recorded 265 orders and 313 items, while Aug 2018 had 6,351 orders and 7,142 items.

SELECT
    DATE_TRUNC('month', order_date)::date AS month,
    COUNT(DISTINCT order_id) AS orders,
    COUNT(*) AS items_sold
FROM fact_order_items
GROUP BY DATE_TRUNC('month', order_date)
ORDER BY month;
