-- ============================================================
-- 08_seller_performance.sql
-- Top sellers by revenue, average delivery time, cancellation
-- rate, and review score -- a seller scorecard.
-- ============================================================

CREATE OR REPLACE VIEW seller_scorecard AS
WITH seller_orders AS (
    SELECT
        oi.seller_id,
        o.order_id,
        o.order_status,
        oi.price + oi.freight_value AS item_revenue,
        o.order_delivered_customer_date - o.order_purchase_timestamp AS delivery_days
    FROM order_items oi
    JOIN orders o ON o.order_id = oi.order_id  -- includes canceled to measure cancellation rate
),
seller_reviews AS (
    SELECT oi.seller_id, AVG(r.review_score) AS avg_review_score
    FROM order_items oi
    JOIN order_reviews r ON r.order_id = oi.order_id
    GROUP BY oi.seller_id
)
SELECT
    so.seller_id,
    s.seller_state,
    COUNT(DISTINCT so.order_id) AS total_orders,
    SUM(so.item_revenue) FILTER (WHERE so.order_status NOT IN ('canceled','unavailable')) AS total_revenue,
    ROUND(100.0 * COUNT(DISTINCT so.order_id) FILTER (WHERE so.order_status = 'canceled')
        / COUNT(DISTINCT so.order_id), 2) AS cancellation_rate_pct,
    ROUND(AVG(EXTRACT(EPOCH FROM so.delivery_days) / 86400.0)
        FILTER (WHERE so.delivery_days IS NOT NULL), 1) AS avg_delivery_days,
    ROUND(sr.avg_review_score, 2) AS avg_review_score
FROM seller_orders so
JOIN sellers s ON s.seller_id = so.seller_id
LEFT JOIN seller_reviews sr ON sr.seller_id = so.seller_id
GROUP BY so.seller_id, s.seller_state, sr.avg_review_score
HAVING COUNT(DISTINCT so.order_id) >= 5;   -- exclude tiny/one-off sellers from ranking noise

-- 8a. Top 20 sellers by revenue
SELECT * FROM seller_scorecard
ORDER BY total_revenue DESC NULLS LAST
LIMIT 20;

-- 8b. Worst 20 sellers by cancellation rate (min 10 orders, for stability)
SELECT * FROM seller_scorecard
WHERE total_orders >= 10
ORDER BY cancellation_rate_pct DESC
LIMIT 20;

-- 8c. Sellers with best revenue-to-review combo (top quartile revenue,
--     top quartile review score) -- a "reward these sellers" list
SELECT *
FROM seller_scorecard
WHERE total_revenue >= (SELECT PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY total_revenue) FROM seller_scorecard)
  AND avg_review_score >= (SELECT PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY avg_review_score) FROM seller_scorecard)
ORDER BY total_revenue DESC;
