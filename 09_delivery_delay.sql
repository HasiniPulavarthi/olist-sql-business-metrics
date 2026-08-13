-- ============================================================
-- 09_delivery_delay.sql
-- Delivery delay (actual vs estimated) by state, and its
-- relationship to review score -- the "ops affects satisfaction"
-- story that's unique to this dataset.
-- ============================================================

CREATE OR REPLACE VIEW order_delivery_delay AS
SELECT
    o.order_id,
    c.customer_state,
    o.order_purchase_timestamp,
    o.order_delivered_customer_date,
    o.order_estimated_delivery_date,
    EXTRACT(EPOCH FROM (o.order_delivered_customer_date - o.order_estimated_delivery_date)) / 86400.0
        AS delay_days,  -- positive = late, negative = early
    r.review_score
FROM valid_orders o
JOIN customers c ON c.customer_id = o.customer_id
LEFT JOIN order_reviews r ON r.order_id = o.order_id
WHERE o.order_delivered_customer_date IS NOT NULL
  AND o.order_delivered_customer_date >= o.order_purchase_timestamp;  -- exclude bad-data rows

-- 9a. Average delivery delay by state, worst first
SELECT
    customer_state,
    COUNT(*) AS delivered_orders,
    ROUND(AVG(delay_days), 2) AS avg_delay_days,
    ROUND(100.0 * COUNT(*) FILTER (WHERE delay_days > 0) / COUNT(*), 2) AS pct_late
FROM order_delivery_delay
GROUP BY customer_state
HAVING COUNT(*) > 30
ORDER BY avg_delay_days DESC;

-- 9b. Review score by delivery outcome bucket -- the headline insight
SELECT
    CASE
        WHEN delay_days > 7 THEN 'Very late (>7d)'
        WHEN delay_days > 0 THEN 'Late (0-7d)'
        WHEN delay_days > -7 THEN 'On time / slightly early'
        ELSE 'Very early (>7d early)'
    END AS delivery_bucket,
    COUNT(*) AS orders,
    ROUND(AVG(review_score), 2) AS avg_review_score
FROM order_delivery_delay
WHERE review_score IS NOT NULL
GROUP BY 1
ORDER BY avg_review_score DESC;

-- 9c. Correlation coefficient between delay and review score
--     (Postgres CORR() -- expect a negative value: more delay, lower score)
SELECT CORR(delay_days, review_score) AS delay_review_correlation
FROM order_delivery_delay
WHERE review_score IS NOT NULL;
