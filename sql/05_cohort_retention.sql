-- ============================================================
-- 05_cohort_retention.sql
-- Monthly acquisition cohorts + retention matrix (% of cohort
-- still ordering N months after their first purchase)
--
-- NOTE: Olist is a low-repeat-purchase dataset (most customers
-- only order once in the observed window), so expect retention
-- to look thin after month 0 -- that's a real, defensible finding,
-- not a query bug. Worth calling out explicitly in your write-up.
-- ============================================================

-- 5a. First purchase month per customer (cohort assignment)
CREATE OR REPLACE VIEW customer_cohort AS
SELECT
    c.customer_unique_id,
    DATE_TRUNC('month', MIN(o.order_purchase_timestamp))::DATE AS cohort_month
FROM valid_orders o
JOIN customers c ON c.customer_id = o.customer_id
GROUP BY c.customer_unique_id;

-- 5b. Every (customer, order_month) pair, with months-since-cohort offset
CREATE OR REPLACE VIEW customer_activity AS
SELECT DISTINCT
    c.customer_unique_id,
    cc.cohort_month,
    DATE_TRUNC('month', o.order_purchase_timestamp)::DATE AS order_month,
    (DATE_PART('year', o.order_purchase_timestamp) - DATE_PART('year', cc.cohort_month)) * 12
      + (DATE_PART('month', o.order_purchase_timestamp) - DATE_PART('month', cc.cohort_month))
      AS months_since_first_purchase
FROM valid_orders o
JOIN customers c ON c.customer_id = o.customer_id
JOIN customer_cohort cc ON cc.customer_unique_id = c.customer_unique_id;

-- 5c. Cohort sizes (customers acquired per month)
CREATE OR REPLACE VIEW cohort_size AS
SELECT cohort_month, COUNT(DISTINCT customer_unique_id) AS cohort_customers
FROM customer_cohort
GROUP BY cohort_month;

-- 5d. Retention matrix: % of each cohort still active N months later
CREATE OR REPLACE VIEW retention_matrix AS
SELECT
    ca.cohort_month,
    ca.months_since_first_purchase,
    COUNT(DISTINCT ca.customer_unique_id) AS active_customers,
    cs.cohort_customers,
    ROUND(100.0 * COUNT(DISTINCT ca.customer_unique_id) / cs.cohort_customers, 2) AS retention_pct
FROM customer_activity ca
JOIN cohort_size cs ON cs.cohort_month = ca.cohort_month
GROUP BY ca.cohort_month, ca.months_since_first_purchase, cs.cohort_customers
ORDER BY ca.cohort_month, ca.months_since_first_purchase;

SELECT * FROM retention_matrix
WHERE months_since_first_purchase BETWEEN 0 AND 6
ORDER BY cohort_month, months_since_first_purchase;

-- 5e. Overall repeat purchase rate (headline KPI for the dashboard)
SELECT
    COUNT(*) FILTER (WHERE order_count > 1) AS repeat_customers,
    COUNT(*) AS total_customers,
    ROUND(100.0 * COUNT(*) FILTER (WHERE order_count > 1) / COUNT(*), 2) AS repeat_purchase_rate_pct
FROM (
    SELECT c.customer_unique_id, COUNT(DISTINCT o.order_id) AS order_count
    FROM valid_orders o
    JOIN customers c ON c.customer_id = o.customer_id
    GROUP BY c.customer_unique_id
) sub;
