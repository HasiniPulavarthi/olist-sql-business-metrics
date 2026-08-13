-- ============================================================
-- 04_revenue_trend.sql
-- Monthly revenue trend + MoM growth, and revenue by state
-- ============================================================

-- 4a. Monthly revenue with month-over-month % growth
CREATE OR REPLACE VIEW monthly_revenue AS
WITH monthly AS (
    SELECT
        DATE_TRUNC('month', o.order_purchase_timestamp)::DATE AS order_month,
        SUM(orv.total_revenue) AS revenue,
        COUNT(DISTINCT o.order_id) AS orders_count
    FROM valid_orders o
    JOIN order_revenue orv ON orv.order_id = o.order_id
    GROUP BY 1
)
SELECT
    order_month,
    revenue,
    orders_count,
    ROUND(
        100.0 * (revenue - LAG(revenue) OVER (ORDER BY order_month))
        / NULLIF(LAG(revenue) OVER (ORDER BY order_month), 0)
    , 2) AS mom_growth_pct
FROM monthly
ORDER BY order_month;

SELECT * FROM monthly_revenue;

-- 4b. Revenue by customer state (region), with % share of total
CREATE OR REPLACE VIEW revenue_by_state AS
SELECT
    c.customer_state,
    SUM(orv.total_revenue) AS revenue,
    COUNT(DISTINCT o.order_id) AS orders_count,
    ROUND(100.0 * SUM(orv.total_revenue) / SUM(SUM(orv.total_revenue)) OVER (), 2) AS pct_of_total_revenue
FROM valid_orders o
JOIN customers c ON c.customer_id = o.customer_id
JOIN order_revenue orv ON orv.order_id = o.order_id
GROUP BY c.customer_state
ORDER BY revenue DESC;

SELECT * FROM revenue_by_state;

-- 4c. Revenue by product category (English name), top 15
SELECT
    COALESCE(pct.product_category_name_english, p.product_category_name, 'unknown') AS category,
    SUM(oi.price + oi.freight_value) AS revenue,
    COUNT(DISTINCT oi.order_id) AS orders_count,
    ROUND(AVG(oi.price), 2) AS avg_item_price
FROM order_items oi
JOIN products p ON p.product_id = oi.product_id
LEFT JOIN product_category_translation pct ON pct.product_category_name = p.product_category_name
JOIN valid_orders o ON o.order_id = oi.order_id
GROUP BY 1
ORDER BY revenue DESC
LIMIT 15;
