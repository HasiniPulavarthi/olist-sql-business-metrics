-- ============================================================
-- 06_churn.sql
-- Olist has no subscription, so "churn" must be defined from
-- purchase-gap behavior. Approach:
--   1. Find the typical (median) gap between a customer's orders
--      among customers who DID reorder.
--   2. Use that as the churn window N (rounded to a clean number
--      of days) -- a customer is "churned" if more than N days
--      have passed since their last order with no new order.
-- This is a standard e-commerce churn proxy and is explicitly
-- called out as an assumption in the README.
-- ============================================================

-- 6a. Distribution of days-between-orders for repeat customers
--     (informs the churn window choice)
WITH order_gaps AS (
    SELECT
        c.customer_unique_id,
        o.order_purchase_timestamp,
        LAG(o.order_purchase_timestamp) OVER (
            PARTITION BY c.customer_unique_id ORDER BY o.order_purchase_timestamp
        ) AS prev_order_ts
    FROM valid_orders o
    JOIN customers c ON c.customer_id = o.customer_id
)
SELECT
    PERCENTILE_CONT(0.5) WITHIN GROUP (
        ORDER BY EXTRACT(EPOCH FROM (order_purchase_timestamp - prev_order_ts)) / 86400.0
    ) AS median_days_between_orders,
    AVG(EXTRACT(EPOCH FROM (order_purchase_timestamp - prev_order_ts)) / 86400.0) AS avg_days_between_orders
FROM order_gaps
WHERE prev_order_ts IS NOT NULL;

-- 6b. Churn flag per customer as of the dataset's max order date.
--     CHURN_WINDOW_DAYS: set from the median above, or use a
--     business-standard 90/180 days if the median is noisy
--     (Olist's repeat rate is low, so median can be skewed --
--     180 days is a reasonable, defensible default here).
CREATE OR REPLACE VIEW customer_churn_status AS
WITH last_order AS (
    SELECT
        c.customer_unique_id,
        MAX(o.order_purchase_timestamp) AS last_order_date,
        COUNT(DISTINCT o.order_id) AS total_orders
    FROM valid_orders o
    JOIN customers c ON c.customer_id = o.customer_id
    GROUP BY c.customer_unique_id
),
dataset_max_date AS (
    SELECT MAX(order_purchase_timestamp) AS max_date FROM valid_orders
)
SELECT
    lo.customer_unique_id,
    lo.last_order_date,
    lo.total_orders,
    dmd.max_date - lo.last_order_date::DATE AS days_since_last_order,
    CASE
        WHEN dmd.max_date - lo.last_order_date::DATE > 180 THEN TRUE
        ELSE FALSE
    END AS is_churned
FROM last_order lo
CROSS JOIN dataset_max_date dmd;

-- 6c. Headline churn rate
SELECT
    COUNT(*) FILTER (WHERE is_churned) AS churned_customers,
    COUNT(*) AS total_customers,
    ROUND(100.0 * COUNT(*) FILTER (WHERE is_churned) / COUNT(*), 2) AS churn_rate_pct
FROM customer_churn_status;

-- 6d. Churn rate by state -- useful for the "where is churn worst" cut
SELECT
    c.customer_state,
    COUNT(*) FILTER (WHERE ccs.is_churned) AS churned,
    COUNT(*) AS total,
    ROUND(100.0 * COUNT(*) FILTER (WHERE ccs.is_churned) / COUNT(*), 2) AS churn_rate_pct
FROM customer_churn_status ccs
JOIN customers c ON c.customer_unique_id = ccs.customer_unique_id
GROUP BY c.customer_state
HAVING COUNT(*) > 50   -- ignore tiny states with unstable rates
ORDER BY churn_rate_pct DESC;
