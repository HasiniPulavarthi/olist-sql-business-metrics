-- ============================================================
-- 07_rfm_segmentation.sql
-- RFM (Recency, Frequency, Monetary) segmentation using NTILE
-- window functions, then bucketed into named business segments.
-- ============================================================

CREATE OR REPLACE VIEW customer_rfm_raw AS
WITH dataset_max_date AS (
    SELECT MAX(order_purchase_timestamp) AS max_date FROM valid_orders
),
customer_orders AS (
    SELECT
        c.customer_unique_id,
        MAX(o.order_purchase_timestamp) AS last_order_date,
        COUNT(DISTINCT o.order_id) AS frequency,
        SUM(orv.total_revenue) AS monetary
    FROM valid_orders o
    JOIN customers c ON c.customer_id = o.customer_id
    JOIN order_revenue orv ON orv.order_id = o.order_id
    GROUP BY c.customer_unique_id
)
SELECT
    co.customer_unique_id,
    dmd.max_date - co.last_order_date::DATE AS recency_days,
    co.frequency,
    co.monetary
FROM customer_orders co
CROSS JOIN dataset_max_date dmd;

CREATE OR REPLACE VIEW customer_rfm_scored AS
SELECT
    customer_unique_id,
    recency_days,
    frequency,
    monetary,
    -- Recency: LOWER days = better, so invert the tile (5 = most recent)
    (6 - NTILE(5) OVER (ORDER BY recency_days)) AS r_score,
    NTILE(5) OVER (ORDER BY frequency) AS f_score,
    NTILE(5) OVER (ORDER BY monetary) AS m_score
FROM customer_rfm_raw;

CREATE OR REPLACE VIEW customer_rfm_segment AS
SELECT
    *,
    (r_score + f_score + m_score) AS rfm_total,
    CASE
        WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4 THEN 'Champions'
        WHEN r_score >= 4 AND f_score <= 2 THEN 'New / Promising'
        WHEN r_score <= 2 AND f_score >= 4 THEN 'At Risk (used to buy often)'
        WHEN r_score <= 2 AND m_score >= 4 THEN 'At Risk (high value)'
        WHEN r_score <= 2 AND f_score <= 2 AND m_score <= 2 THEN 'Lost'
        ELSE 'Regular'
    END AS segment
FROM customer_rfm_scored;

-- 7a. Segment sizes and average monetary value -- headline for dashboard
SELECT
    segment,
    COUNT(*) AS customers,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS pct_of_customers,
    ROUND(AVG(monetary), 2) AS avg_monetary,
    ROUND(AVG(recency_days), 1) AS avg_recency_days
FROM customer_rfm_segment
GROUP BY segment
ORDER BY avg_monetary DESC;

SELECT * FROM customer_rfm_segment ORDER BY rfm_total DESC LIMIT 100;
