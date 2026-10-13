-- REVENUE ANALYSIS
-- Olist E-Commerce Analytics



-- Q1. MONTHLY REVENUE, ORDERS AND AOV
-- Question: How do revenue, order volume and AOV change monthly?
-- Approach: Aggregate item sales by purchase month.
-- Findings: Record the actual trend after executing the query.

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
-- Findings: Record the months with the strongest growth or decline.

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
-- Findings: Record the cumulative revenue trend.

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
-- Findings: Record the leading categories and their revenue shares.

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
-- Findings: Record the top-performing states.

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
-- Findings: Record the overall AOV.

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
-- Findings: Record the strongest and weakest months in the available data.

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
-- Findings: Record changes in order volume and item volume.

SELECT
    DATE_TRUNC('month', order_date)::date AS month,
    COUNT(DISTINCT order_id) AS orders,
    COUNT(*) AS items_sold
FROM fact_order_items
GROUP BY DATE_TRUNC('month', order_date)
ORDER BY month;
